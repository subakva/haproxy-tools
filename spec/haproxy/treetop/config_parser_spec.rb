require 'spec_helper'
require 'polyglot'
require 'treetop'
require 'haproxy/treetop/config'

describe 'HAProxy::Treetop::ConfigParser' do
  before(:each) do
    @parser = HAProxy::Treetop::ConfigParser.new
  end

  it 'should parse a backend server block' do
    # puts File.read("spec/fixtures/simple.haproxy.cfg")
    result = @parser.parse(File.read("spec/fixtures/simple.haproxy.cfg"))
#    result = @parser.parse %{
## server web1 66.66.66.66:80 weight 1 maxconn 512 check
#server web1 66.66.66.66:80 weight 1 maxconn 512 check
#server web2 66.77.66.66:80 weight 2 maxconn 512 check
#
#}

    if result.nil?
      puts
      puts @parser.failure_reason
    end
    result.class.name.should == 'HAProxy::Treetop::ConfigurationNode'

    puts
    result.elements.each do |e|
      puts "#{e.class.name} #{e.text_value.strip}"
    end
    require 'pp'
    # pp result
    result.elements.size.should == 4
    result.servers.size.should == 2
    result.servers[0].name.should == 'web1'
    result.servers[1].name.should == 'web2'
  end

end

