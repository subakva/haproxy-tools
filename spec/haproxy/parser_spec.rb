require 'spec_helper'

describe "HAProxy::Parser" do

  context 'multi-pool config file' do
    before(:each) do
      @parser = HAProxy::Parser.new
      @config = @parser.parse_file('spec/fixtures/multi-pool.haproxy.cfg')
    end

    it "parses a named backend from a config file" do
      @config.backends.size.should == 2
      logs_backend = @config.backend('logs')

      logs_backend.servers.size.should == 4

      server1 = logs_backend.servers['prd_log_1']
      server1.name.should == 'prd_log_1'
      server1.host.should   == '10.245.174.75'
      server1.port.should == '8000'

      server2 = logs_backend.servers['fake_logger']
      server2.name.should == 'fake_logger'
      server2.host.should   == '127.0.0.1'
      server2.port.should == '9999'

      server3 = logs_backend.servers['prd_log_2']
      server3.name.should == 'prd_log_2'
      server3.host.should   == '10.215.157.10'
      server3.port.should == '8000'

      server3 = logs_backend.servers['prd_log_3']
      server3.name.should == 'prd_log_3'
      server3.host.should   == 'cloudloghost1'
      server3.port.should == '8000'
    end
  end

  context 'basic 1.5 config file' do
    before(:each) do
      @parser = HAProxy::Parser.new
      @config = @parser.parse_file('spec/fixtures/simple.haproxy15.cfg')
    end

    it "parses structured configs" do
      defaults = @config.defaults.first.config

      defaults['timeout connect'].should == '5000ms'
      defaults['timeout client'].should == '5000ms'
      defaults['timeout server'].should == '5000ms'

      defaults['errorfile 400'].should == '/etc/haproxy/errors/400.http'
      defaults['errorfile 504'].should == '/etc/haproxy/errors/504.http'

    end

  end

  context 'basic config file' do
    before(:each) do
      @parser = HAProxy::Parser.new
      @config = @parser.parse_file('spec/fixtures/simple.haproxy.cfg')
    end

    it "parses global variables from a config file" do
      @config.global.size.should == 3
      @config.global['maxconn'].should == '4096'
      @config.global['daemon'].should == nil
      @config.global['nbproc'].should == '4'
    end

    it "parses a default set from a config file" do
      @config.defaults.size.should == 1

      defaults = @config.defaults.first
      defaults.config['mode'].should == 'http'
      defaults.config['clitimeout'].should == '60000'
      defaults.config['srvtimeout'].should == '30000'
      defaults.config['contimeout'].should == '4000'

      defaults.options.size.should == 1
      defaults.options.should include('httpclose')
    end

    it 'parses a listener from a config file' do
      @config.listeners.size.should == 1

      listener = @config.listener('http_proxy')
      listener.name.should == 'http_proxy'
      listener.host.should == '55.55.55.55'
      listener.port.should == '80'
      listener.config['balance'].should == 'roundrobin'

      listener.options.size.should == 2
      listener.options.should include('httpchk')
      listener.options.should include('forwardfor')

      listener.servers.size.should == 3

      server1 = listener.servers['web1']
      server1.name.should == 'web1'
      server1.host.should   == 'dnshost66'
      server1.port.should == '80'
      server1.attributes['weight'].should == '1'
      server1.attributes['maxconn'].should == '512'
      server1.attributes['check'].should == true

      server2 = listener.servers['web2']
      server2.name.should == 'web2'
      server2.host.should   == '77.77.77.77'
      server2.port.should == '80'
      server2.attributes['weight'].should == '1'
      server2.attributes['maxconn'].should == '512'
      server2.attributes['check'].should == true

      server3 = listener.servers['web3']
      server3.name.should == 'web3'
      server3.host.should   == '88.88.88.88'
      server3.port.should == '80'
      server3.attributes.should be_empty
    end
  end
end

