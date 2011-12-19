require 'spec_helper'

describe "HAProxy::Config" do
  before(:each) do
    @config = HAProxy::Config.parse_file('spec/fixtures/simple.haproxy.cfg')
  end

  it 'can re-render a config file with a server removed' do
    l = @config.listener('http_proxy')
    l.servers.delete('web1')

    new_config_text = @config.render

    new_config = HAProxy::Parser.new.parse(new_config_text)
    new_config.listener('http_proxy').servers['web1'].should be_nil
  end

  it 'can re-render a config file with a server added' do
    l = @config.listener('http_proxy')
    new_server = l.servers['web1'].clone
    new_server.name = 'web4'
    new_server.host = '99.99.99.99'
    l.servers['web4'] = new_server

    new_config_text = @config.render

    new_config = HAProxy::Parser.new.parse(new_config_text)
    s = new_config.listener('http_proxy').servers['web4']
    s.should_not be_nil
    s.name.should == 'web4'
    s.host.should == '99.99.99.99'
    s.port.should == '80'
    s.attributes.should == 'weight 1 maxconn 512 check'
  end
end

