module SpecHelper
  extend self
  def setup_server
    write_key
    configure_chef
    start_chef_zero unless chef_zero_running?
    sync_repo
  end

  def teardown_server
    FileUtils.rm_rf knife_dir
    stop_chef_zero if chef_zero_running?
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
    @@chef_zero = ChefZero::Server.new(port: 4000, host: ip)
    @@chef_zero.start_background
  end

  def stop_chef_zero
    @@chef_zero.stop
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
    pid = fork do
      klass.load_deps
      plugin = klass.new
      plugin.name_args = args
      yield plugin.config if block_given?
      plugin.configure_chef if plugin.respond_to?(:configure_chef)
      plugin.run
    end
    Process.waitpid pid, 0
  end

  def sync_repo
    do_knife Chef::Knife::Upload, '/' do |config|
      config[:chef_repo_path] =  '/home/ranjib/workspace/chef-repo'
      config[:force] = true
    end
  end

  def provision(name, run_list)
    ct = LXC::Container.new name
    ct.create('ubuntu',nil,0,['-r','precise'])
    ct.start
    while ct.ip_addresses.empty?
      puts "Waiting for ip address allocation for '#{ct.name}' container"
      sleep 1
    end

    ct.execute do
      puts `apt-get update -y`
      puts `apt-get install wget curl -y`
      puts `curl -L  https://www.opscode.com/chef/install.sh | bash`
    end

    do_knife Chef::Knife::Bootstrap, ct.ip_addresses.first do |config|
      config[:run_list] = Array(run_list)
      config[:ssh_user] = 'ubuntu'
      config[:ssh_password] = 'ubuntu'
      config[:chef_node_name] = ct.name
      config[:use_sudo] = true
      config[:host_key_verify] = false
      config[:use_sudo_password] = true
      config[:bootstrap_version] = '11.10.4'
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
end
