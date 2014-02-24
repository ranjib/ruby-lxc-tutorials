
require 'rspec'
$:.unshift(File.expand_path("../..",  __FILE__))


require 'chef_zero'
require 'chef'
require 'lxc/extra'
require 'chef_zero/server'
require 'chef/knife/upload'
require 'chef/knife/bootstrap'
require 'chef/knife/node_delete'
require 'chef/knife/client_delete'
require 'lib/helpers'
require 'pry'
require 'serverspec'

include SpecInfra::Helper::Lxc
include SpecInfra::Helper::Debian


RSpec.configure do |config|
  config.backtrace_exclusion_patterns = []
  config.lxc = "db"
  config.before(:suite) do
    SpecHelper.setup_server
  end
  config.after(:suite) do
    SpecHelper.teardown_server
  end
end
