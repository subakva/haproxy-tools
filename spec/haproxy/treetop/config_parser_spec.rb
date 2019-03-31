# frozen_string_literal: true

require "spec_helper"

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

    # HAProxy::Treetop.print_node(@result, 0, :max_depth => 3)
  end

  def parse_single_pool
    parse_file("spec/fixtures/simple.haproxy.cfg")
  end

  def parse_multi_pool
    parse_file("spec/fixtures/multi-pool.haproxy.cfg")
  end

  it "can parse servers from a backend server block" do
    parse_multi_pool

    backend = @result.backends.first
    expect(backend.servers.size).to eq(4)
    expect(backend.servers[0].name).to eq("prd_www_1")
    expect(backend.servers[0].host).to eq("10.214.78.95")
    expect(backend.servers[0].port).to eq("8000")
  end

  it "can parse a service address from a frontend header" do
    parse_multi_pool

    frontend = @result.frontends.first
    expect(frontend.frontend_header.service_address.host.content).to eq("*")
    expect(frontend.frontend_header.service_address.port.content).to eq("85")
  end

  it "can parse a service address from a listen header" do
    parse_single_pool

    listener = @result.listeners.first
    expect(listener.listen_header.service_address.host.content).to eq("55.55.55.55")
    expect(listener.listen_header.service_address.port.content).to eq("80")
  end

  it "can parse a file with a listen section" do
    parse_single_pool

    @result.elements
    expect(@result.class).to eq(HAProxy::Treetop::ConfigurationFile)
    expect(@result.elements.size).to eq(5)

    expect(@result.elements[0].class).to eq(HAProxy::Treetop::CommentLine)
    expect(@result.elements[1].class).to eq(HAProxy::Treetop::BlankLine)

    expect(@result.global).to eq(@result.elements[2])
    expect(@result.elements[2].class).to eq(HAProxy::Treetop::GlobalSection)

    expect(@result.defaults[0]).to eq(@result.elements[3])
    expect(@result.elements[3].class).to eq(HAProxy::Treetop::DefaultsSection)

    expect(@result.listeners[0]).to eq(@result.elements[4])
    expect(@result.elements[4].class).to eq(HAProxy::Treetop::ListenSection)
  end

  it "can parse a file with frontend/backend sections" do
    parse_multi_pool

    expect(@result.class).to eq(HAProxy::Treetop::ConfigurationFile)
    expect(@result.elements.size).to eq(5)

    expect(@result.global).to eq(@result.elements[0])
    expect(@result.elements[0].class).to eq(HAProxy::Treetop::GlobalSection)

    expect(@result.defaults[0]).to eq(@result.elements[1])
    expect(@result.elements[1].class).to eq(HAProxy::Treetop::DefaultsSection)

    expect(@result.frontends[0]).to eq(@result.elements[2])
    expect(@result.elements[2].class).to eq(HAProxy::Treetop::FrontendSection)

    expect(@result.backends[0]).to eq(@result.elements[3])
    expect(@result.backends[1]).to eq(@result.elements[4])
    expect(@result.elements[3].class).to eq(HAProxy::Treetop::BackendSection)
    expect(@result.elements[4].class).to eq(HAProxy::Treetop::BackendSection)
  end

  it "can parse userlist sections"
  it "can parse valid units of time"
  it "can parse strings with escaped spaces"
  it "can parse files with escaped quotes"
  it "can parse keywords with hyphens"
end
