require 'mixlib/shellout'
module SpecHelper
  extend self
  def setup_server
    write_key
    configure_chef
    write_knife_config
    unless chef_zero_running?
      puts 'Starting chef-zero'
      start_chef_zero
    end
    sync_repo
  end

  def teardown_server
    FileUtils.rm_rf knife_dir
    if chef_zero_running?
      stop_chef_zero
      puts 'Stopped chef-zero'
    end
  end

  def chef_zero_running?
    begin
      TCPSocket.new(ip, 4000)
    rescue Errno::ECONNREFUSED
      return false
    end
    return true
  end

  def start_chef_zero
    @@chef_zero ||= ChefZero::Server.new(port: 4000, host: ip)
    @@chef_zero.start_background(15)
    until @@chef_zero.running?
      puts 'Waiting till chef-zero starts'
      sleep 1
    end
  end

  def stop_chef_zero
    @@chef_zero.stop
    sleep 3
  end

  def write_knife_config
    File.open(File.join(knife_dir, 'knife.rb'), 'w') do |f|
     f.puts "chef_server_url  'http://#{ip}:4000'"
     f.puts "node_name  'admin'"
     f.puts "client_key '#{knife_dir}/client.pem'"
     f.puts "validation_key '#{knife_dir}/client.pem'"
    end
  end

  def knife_dir  
    @@knife_dir ||= Dir.mktmpdir
  end

  def ip
    @@ip ||= UDPSocket.open {|s| s.connect("8.8.8.8", 1); s.addr.last}
  end

  def write_key
    File.open(File.join(knife_dir, 'client.pem'), 'w') do |f|
      f.write ChefZero::PRIVATE_KEY
    end
  end

  def configure_chef
    Chef::Config[:chef_server_url] = "http://#{ip}:4000"
    Chef::Config[:node_name] = 'admin'
    Chef::Config[:client_key] = File.join(knife_dir, 'client.pem')
    Chef::Config[:validation_key] = File.join(knife_dir, 'client.pem')
    Chef::Config[:file_cache_path] = File.join(knife_dir, 'cache')
  end

  def do_knife(klass, *args)
    puts "Executing knife: #{klass.name}"
    klass.load_deps
    plugin = klass.new
    plugin.name_args = args
    yield plugin.config if block_given?
    pid = fork do
      plugin.configure_chef if plugin.respond_to?(:configure_chef)
      plugin.run
    end
    Process.waitpid pid
    puts "Finished executing knife: #{klass.name}"# Status: #{status.exitstatus}"
  end

  def sync_repo
    do_knife Chef::Knife::Upload, '/' do |config|
      config[:chef_repo_path] =  File.expand_path('../..',__FILE__)
      puts "Setting repo to:#{config[:chef_repo_path]}"
      config[:force] = true
    end
  end

  def provision(name, run_list)
    ct = LXC::Container.new name
    ct.create('ubuntu',nil,0,['-r','precise'])
    ct.start
    while ct.ip_addresses.empty?
      sleep 1
      puts "Waiting for ip address allocation for '#{ct.name}' container"
    end
    ct.execute do
      shell_out!('apt-get update -yfq')
      shell_out!('apt-get -yqf install curl wget')
      shell_out!('curl -L https://www.opscode.com/chef/install.sh | bash')
    end

    do_knife Chef::Knife::Bootstrap, ct.ip_addresses.first do |config|
      config[:run_list] = Array(run_list)
      config[:ssh_user] = 'ubuntu'
      config[:ssh_password] = 'ubuntu'
      config[:chef_node_name] = ct.name
      config[:use_sudo] = true
      config[:host_key_verify] = false
      config[:use_sudo_password] = true
      config[:yes] = true
    end
  end

  def deprovision(name)
    ct = LXC::Container.new name
    do_knife Chef::Knife::NodeDelete, ct.name do |config|
      config[:yes] = true
    end
    do_knife Chef::Knife::ClientDelete, ct.name do |config|
      config[:yes] = true
    end
    ct.stop if ct.running?
    ct.destroy if ct.defined?
  end
  def shell_out!(cmd)
    command = Mixlib::ShellOut.new(cmd)
    command.live_stream = $stdout
    command.run_command
    raise "Failed to execute '#{cmd}'" unless command.exitstatus == 0
  end

  def knife_exec(cmd)
    puts ("bundle exec knife #{cmd} -c #{knife_dir}/knife.rb")
    binding.pry
    shell_out!("bundle exec knife #{cmd} -c #{knife_dir}/knife.rb")
  end
end
