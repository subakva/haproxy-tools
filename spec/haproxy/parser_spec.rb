# frozen_string_literal: true

require "spec_helper"

describe "HAProxy::Parser" do
  context "multi-pool config file" do
    before(:each) do
      @parser = HAProxy::Parser.new
      @config = @parser.parse_file("spec/fixtures/multi-pool.haproxy.cfg")
    end

    it "parses default_backend" do
      expect(@config.frontends.size).to eq(1)
      www_frontend = @config.frontend("www")
      expect(www_frontend.config["default_backend"]).to eq("www_main")
    end

    it "parses defaults" do
      expect(@config.defaults.size).to eq(1)

      defaults = @config.defaults.first
      expect(defaults.config["log"]).to eq("global")
      expect(defaults.config["mode"]).to eq("http")
      expect(defaults.config["retries"]).to eq("3")
      expect(defaults.config["redispatch"]).to be_nil
      expect(defaults.config["maxconn"]).to eq("10000")
      expect(defaults.config["contimeout"]).to eq("5000")
      expect(defaults.config["clitimeout"]).to eq("60000")
      expect(defaults.config["srvtimeout"]).to eq("60000")
      expect(defaults.config["stats"]).to eq("uri /haproxy-status")
      expect(defaults.config["cookie"]).to eq("SERVERID insert indirect nocache")

      expect(defaults.options.size).to eq(2)
      expect(defaults.options).to include("httplog")
      expect(defaults.options).to include("dontlognull")
    end

    it "parses a named backend from a config file" do
      expect(@config.backends.size).to eq(2)
      logs_backend = @config.backend("logs")

      expect(logs_backend.servers.size).to eq(4)

      server1 = logs_backend.servers["prd_log_1"]
      expect(server1.name).to eq("prd_log_1")
      expect(server1.host).to eq("10.245.174.75")
      expect(server1.port).to eq("8000")

      server2 = logs_backend.servers["fake_logger"]
      expect(server2.name).to eq("fake_logger")
      expect(server2.host).to eq("127.0.0.1")
      expect(server2.port).to eq("9999")

      server3 = logs_backend.servers["prd_log_2"]
      expect(server3.name).to eq("prd_log_2")
      expect(server3.host).to eq("10.215.157.10")
      expect(server3.port).to eq("8000")

      server3 = logs_backend.servers["prd_log_3"]
      expect(server3.name).to eq("prd_log_3")
      expect(server3.host).to eq("cloudloghost1")
      expect(server3.port).to eq("8000")
    end
  end

  context "basic 1.5 config file" do
    before(:each) do
      @parser = HAProxy::Parser.new
      @config = @parser.parse_file("spec/fixtures/simple.haproxy15.cfg")
    end

    it "parses structured configs" do
      defaults = @config.defaults.first.config

      expect(defaults["timeout connect"]).to eq("5000ms")
      expect(defaults["timeout client"]).to eq("5000ms")
      expect(defaults["timeout server"]).to eq("5000ms")

      expect(defaults["errorfile 400"]).to eq("/etc/haproxy/errors/400.http")
      expect(defaults["errorfile 504"]).to eq("/etc/haproxy/errors/504.http")
    end
  end

  context "basic config file" do
    before(:each) do
      @parser = HAProxy::Parser.new
      @config = @parser.parse_file("spec/fixtures/simple.haproxy.cfg")
    end

    it "parses global variables from a config file" do
      expect(@config.global.size).to eq(3)
      expect(@config.global["maxconn"]).to eq("4096")
      expect(@config.global["daemon"]).to be_nil
      expect(@config.global["nbproc"]).to eq("4")
    end

    it "parses a default set from a config file" do
      expect(@config.defaults.size).to eq(1)

      defaults = @config.defaults.first
      expect(defaults.config["mode"]).to eq("http")
      expect(defaults.config["clitimeout"]).to eq("60000")
      expect(defaults.config["srvtimeout"]).to eq("30000")
      expect(defaults.config["contimeout"]).to eq("4000")

      expect(defaults.options.size).to eq(1)
      expect(defaults.options).to include("httpclose")
    end

    it "parses a listener from a config file" do
      expect(@config.listeners.size).to eq(1)

      listener = @config.listener("http_proxy")
      expect(listener.name).to eq("http_proxy")
      expect(listener.host).to eq("55.55.55.55")
      expect(listener.port).to eq("80")
      expect(listener.config["balance"]).to eq("roundrobin")

      expect(listener.options.size).to eq(2)
      expect(listener.options).to include("httpchk")
      expect(listener.options).to include("forwardfor")

      expect(listener.servers.size).to eq(3)

      server1 = listener.servers["web1"]
      expect(server1.name).to eq("web1")
      expect(server1.host).to eq("dnshost66")
      expect(server1.port).to eq("80")
      expect(server1.attributes["weight"]).to eq("1")
      expect(server1.attributes["maxconn"]).to eq("512")
      expect(server1.attributes["check"]).to eq(true)

      server2 = listener.servers["web2"]
      expect(server2.name).to eq("web2")
      expect(server2.host).to eq("77.77.77.77")
      expect(server2.port).to eq("80")
      expect(server2.attributes["weight"]).to eq("1")
      expect(server2.attributes["maxconn"]).to eq("512")
      expect(server2.attributes["check"]).to eq(true)

      server3 = listener.servers["web3"]
      expect(server3.name).to eq("web3")
      expect(server3.host).to eq("88.88.88.88")
      expect(server3.port).to eq("80")
      expect(server3.attributes).to be_empty
    end
  end
end
