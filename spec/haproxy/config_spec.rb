require 'spec_helper'

describe "HAProxy::Config" do
  context 'basic config file parsing' do
    before(:each) do
      @parser = HAProxy::Config.new(:filename => 'spec/fixtures/simple.haproxy.cfg')
    end

    it "parses global variables from a config file" do
      config = @parser.parse

      config.global.size.should == 3
      config.global['maxconn'].should == ['4096']
      config.global['daemon'].should == []
      config.global['nbproc'].should == ['4']
    end

    it "parses default variables from a config file" do
      config = @parser.parse

      config.defaults.size.should == 7
      config.defaults['mode'].should == ['http']
      config.defaults['clitimeout'].should == ['60000']
      config.defaults['srvtimeout'].should == ['30000']
      config.defaults['contimeout'].should == ['4000']
      config.defaults['listen'].should == [['http_proxy', '55.55.55.55:80']]
      config.defaults['balance'].should == ['roundrobin']
      config.defaults['option'].should == ['httpclose','httpchk','forwardfor']
    end

    it "parses a default backends from a config file" do
      config = @parser.parse

      config.backends.size.should == 1

      pool = config.backends.first

      pool.servers.size.should == 3

      server1 = pool.servers['web1']
      server1.name.should == 'web1'
      server1.ip.should   == '66.66.66.66'
      server1.port.should == '80'

      server2 = pool.servers['web2']
      server2.name.should == 'web2'
      server2.ip.should   == '77.77.77.77'
      server2.port.should == '80'

      server3 = pool.servers['web3']
      server3.name.should == 'web3'
      server3.ip.should   == '88.88.88.88'
      server3.port.should == '80'
    end
  end
end
