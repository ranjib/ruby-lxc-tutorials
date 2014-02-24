require 'spec_helper'

describe 'role[db]' do

  before(:all) do
    SpecHelper.provision 'db', 'role[db]'
  end

  after(:all) do
    SpecHelper.deprovision 'db'
  end

  it 'should install mysql server package' do
    expect(package('mysql-server')).to be_installed
  end

  it 'should start mysql service' do
    expect(service('mysql')).to be_running
  end
end
