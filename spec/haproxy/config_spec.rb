require 'spec_helper'

describe "HAProxy::Config" do
  describe 'render multi-backend config' do
    before(:each) do
      @config = HAProxy::Config.parse_file('spec/fixtures/multi-pool.haproxy.cfg')
    end

    it 'can re-render a config file with a server removed' do
      l = @config.backend('www_main')
      l.servers.delete('prd_www_1')

      new_config_text = @config.render

      new_config = HAProxy::Parser.new.parse(new_config_text)
      new_config.backend('www_main').servers['prd_www_1'].should be_nil
    end

    it 'can re-render a config file with a server attribute added' do
      b = @config.backend('www_main')
      b.servers['prd_www_1'].attributes['disabled'] = true
      new_config_text = @config.render

      new_config = HAProxy::Parser.new.parse(new_config_text)
      s = new_config.backend('www_main').servers['prd_www_1']
      s.should_not be_nil
      s.attributes['disabled'].should be_truthy
    end

    it 'can re-render a config file with a server added' do
      b = @config.backend('www_main')
      b.add_server('prd_www_4', '99.99.99.99', :port => '8000')

      new_config_text = @config.render

      new_config = HAProxy::Parser.new.parse(new_config_text)
      s = new_config.backend('www_main').servers['prd_www_4']
      s.should_not be_nil
      s.name.should == 'prd_www_4'
      s.host.should == '99.99.99.99'
      s.port.should == '8000'
      s.attributes.to_a.should == []
    end

    it 'can re-render a config file with a server added based on template' do
      b = @config.backend('www_main')
      b.add_server('prd_www_4', '99.99.99.99', :template => b.servers['prd_www_1'])

      new_config_text = @config.render

      new_config = HAProxy::Parser.new.parse(new_config_text)
      s = new_config.backend('www_main').servers['prd_www_4']
      s.should_not be_nil
      s.name.should == 'prd_www_4'
      s.host.should == '99.99.99.99'
      s.port.should == '8000'
      s.attributes.to_a.should == [
        ['cookie','i-prd_www_1'],
        ['check',true],
        ['inter','3000'],
        ['rise','2'],
        ['fall','3'],
        ['maxconn','1000']
      ]
    end
  end

  describe 'render simple 1.5 config' do
    before(:each) do
      @config = HAProxy::Config.parse_file('spec/fixtures/simple.haproxy15.cfg')
    end

    it 'cen re-render a config file with an error page removed' do
      @config.default.config.should have_key('errorfile 400')
      @config.default.config.delete('errorfile 400')

      new_config_text = @config.render

      new_config = HAProxy::Parser.new.parse(new_config_text)
      new_config.default.config.should_not have_key('errorfile 400')
    end

    it 'can re-render a config file with an error page added' do
      @config.default.config.should_not have_key('errorfile 401')
      @config.default.config['errorfile 401'] = '/etc/haproxy/errors/401.http'

      new_config_text = @config.render

      new_config = HAProxy::Parser.new.parse(new_config_text)
      new_config.default.config.should have_key('errorfile 401')
      new_config.default.config['errorfile 401'].should == '/etc/haproxy/errors/401.http'
    end

  end

  describe 'render simple config' do
    before(:each) do
      @config = HAProxy::Config.parse_file('spec/fixtures/simple.haproxy.cfg')
    end

    it 'can re-render a config file with a config removed' do
      @config.default.config.should have_key('clitimeout')
      @config.default.config.delete('clitimeout')

      new_config_text = @config.render

      new_config = HAProxy::Parser.new.parse(new_config_text)
      new_config.default.config.should_not have_key('clitimeout')

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
      l.add_server('web4', '99.99.99.99', :template => l.servers['web1'])

      new_config_text = @config.render

      new_config = HAProxy::Parser.new.parse(new_config_text)
      s = new_config.listener('http_proxy').servers['web4']
      s.should_not be_nil
      s.name.should == 'web4'
      s.host.should == '99.99.99.99'
      s.port.should == '80'
      s.attributes.to_a.should == [
        ['weight','1'],
        ['maxconn','512'],
        ['check',true]
      ]
    end
  end
end

