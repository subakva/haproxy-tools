require 'spec_helper'

describe HAProxy::Treetop::ConfigParser do
  before(:each) do
    @parser = HAProxy::Treetop::ConfigParser.new
  end

  def parse_file(filename)
    @result = @parser.parse(File.read(filename))
    if @result.nil?
      puts
      puts "Failure Reason:  #{@parser.failure_reason}"
    end

    #HAProxy::Treetop.print_node(@result, 0, :max_depth => 3)
  end

  def parse_single_pool
    parse_file('spec/fixtures/simple.haproxy.cfg')
  end

  def parse_multi_pool
    parse_file('spec/fixtures/multi-pool.haproxy.cfg')
  end

  it "can parse servers from a backend server block" do
    parse_multi_pool

    backend = @result.backends.first
    backend.servers.size.should == 4
    backend.servers[0].name.should == 'prd_www_1'
    backend.servers[0].host.should == '10.214.78.95'
    backend.servers[0].port.should == '8000'
  end

  it 'can parse a service address from a frontend header' do
    parse_multi_pool

    frontend = @result.frontends.first
    frontend.frontend_header.service_address.host.content.should == '*'
    frontend.frontend_header.service_address.port.content.should == '85'
  end

  it 'can parse a service address from a listen header' do
    parse_single_pool

    listener = @result.listeners.first
    listener.listen_header.service_address.host.content.should == '55.55.55.55'
    listener.listen_header.service_address.port.content.should == '80'
  end

  it 'can parse a file with a listen section' do
    parse_single_pool

    @result.class.should == HAProxy::Treetop::ConfigurationFile
    @result.elements.size.should == 3

    @result.global.should == @result.elements[0]
    @result.elements[0].class.should == HAProxy::Treetop::GlobalSection

    @result.defaults[0].should == @result.elements[1]
    @result.elements[1].class.should == HAProxy::Treetop::DefaultsSection

    @result.listeners[0].should == @result.elements[2]
    @result.elements[2].class.should == HAProxy::Treetop::ListenSection
  end

  it 'can parse a file with frontend/backend sections' do
    parse_multi_pool

    @result.class.should == HAProxy::Treetop::ConfigurationFile
    @result.elements.size.should == 5

    @result.global.should == @result.elements[0]
    @result.elements[0].class.should == HAProxy::Treetop::GlobalSection

    @result.defaults[0].should == @result.elements[1]
    @result.elements[1].class.should == HAProxy::Treetop::DefaultsSection

    @result.frontends[0].should == @result.elements[2]
    @result.elements[2].class.should == HAProxy::Treetop::FrontendSection

    @result.backends[0].should == @result.elements[3]
    @result.backends[1].should == @result.elements[4]
    @result.elements[3].class.should == HAProxy::Treetop::BackendSection
    @result.elements[4].class.should == HAProxy::Treetop::BackendSection
  end

  it 'can parse userlist sections'
  it 'can parse valid units of time'
  it 'can parse strings with escaped spaces'
  it 'can parse files with escaped quotes'
  it 'can parse keywords with hyphens'
end

