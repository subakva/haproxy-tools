require 'spec_helper'
require 'polyglot'
require 'treetop'
require 'haproxy/treetop/config'

describe 'HAProxy::Treetop::ConfigParser' do
  before(:each) do
    @parser = HAProxy::Treetop::ConfigParser.new
    @result = @parser.parse(File.read("spec/fixtures/multi-pool.haproxy.cfg"))
    if @result.nil?
      puts
      puts "Failure Reason:  #{@parser.failure_reason}"
    end

    HAProxy::Treetop.print_node(@result, 0, :max_depth => 3)
  end

  it "should parse a backend server block" do
    pending
    backend = @result.backends.first
    backend.servers.size.should == 4
    backend.servers[0].name.should == 'prd_www_1'
    backend.servers[0].address.should == '10.214.78.95'
  end

  it 'should parse a file with multiple sections' do
    @result.class.should == HAProxy::Treetop::ConfigurationFile
    @result.elements.size.should == 5

    @result.global.should == @result.elements[0]
    @result.elements[0].class.should == HAProxy::Treetop::GlobalSection

    @result.defaults.should == @result.elements[1]
    @result.elements[1].class.should == HAProxy::Treetop::DefaultsSection

    @result.frontends[0].should == @result.elements[2]
    @result.elements[2].class.should == HAProxy::Treetop::FrontendSection

    @result.backends[0].should == @result.elements[3]
    @result.backends[1].should == @result.elements[4]
    @result.elements[3].class.should == HAProxy::Treetop::BackendSection
    @result.elements[4].class.should == HAProxy::Treetop::BackendSection
  end

end

