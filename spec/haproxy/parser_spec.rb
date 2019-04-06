# frozen_string_literal: true

require "spec_helper"

describe "HAProxy::Parser" do
  context "kitchen sink" do
    let(:parser) { HAProxy::Parser.new }
    let!(:config) { parser.parse_file("spec/fixtures/haproxy.1.9.cfg")}

    it "parses global variables" do
      expect(config.global.size).to eq(6)
      expect(config.global["ca-base"]).to eq("/home/ca")
      expect(config.global["cpu-map"]).to eq([
        "auto:1/1-4   0-3",
        "auto:1/1-4   0-1 2-3",
        "auto:1/1-4   3 2 1 0",
      ])
      expect(config.global["daemon"]).to be_nil
      expect(config.global["profiling.tasks"]).to eq("on")
    end

    it "parses proxy sections" do
      expect(config.defaults.map(&:name)).to eq([nil, "foo"])
      expect(config.frontends.map(&:name)).to eq(["www", "api"])
      expect(config.backends.map(&:name)).to eq(["www_main", "logs"])
      expect(config.listeners.map(&:name)).to eq(["auth", "health"])
    end

    it "parses parameter keywords with all acceptable characters" do
      first_defaults = config.defaults.first
      expect(first_defaults["backlog"]).to_not be_nil
      expect(first_defaults["bind-process"]).to_not be_nil
      expect(first_defaults["default_backend"]).to_not be_nil
      expect(first_defaults["errorloc302"]).to_not be_nil
    end

    it "parses parameter values with all acceptable characters" do
      first_defaults = config.defaults.first
      expect(first_defaults["backlog"]).to eq("UPPER lower dash-under_score/slash:colon(arg) 49.1")
    end

    it "parses duplicate parameter names as array" do
      first_defaults = config.defaults.first
      expect(first_defaults["email-alert"]).to eq([
        "from dummy-value",
        "level dummy-value",
      ])
    end

    it "parses options into a hash" do
      defaults = config.defaults.first
      expect(defaults.options.size).to eq(4)
      expect(defaults.options["abortonclose"].enabled?).to be_truthy
      expect(defaults.options["accept-invalid-http-request"].enabled?).to be_falsey
      expect(defaults.options["allbackups"].enabled?).to be_truthy
      expect(defaults.options["forwardfor"].enabled?).to be_truthy
      expect(defaults.options["forwardfor"].value).to eq("if-none")
    end

    it "parses servers into a hash" do
      backend = config.backends.find { |b| b.name == 'www_main' }
      expect(backend.servers.size).to eq(6)

      expect(backend.servers['first'].value).to eq('10.1.1.1:1080 cookie first  check inter 1000')
      expect(backend.servers['second'].value).to eq('10.1.1.2:1080 cookie second check inter 1000')
      expect(backend.servers['transp'].value).to eq('ipv4@')
      expect(backend.servers['backup'].value).to eq('"${SRV_BACKUP}:1080" backup')
      expect(backend.servers['www1_dc1'].value).to eq('"${LAN_DC1}.101:80"')
      expect(backend.servers['www1_dc2'].value).to eq('"${LAN_DC2}.101:80"')
    end

    # TODO: this might be the same structure as server ... NamedParameters? Also: option, filter, log, cookie, ...
    # it "parses acls into a hash"

    # it "parses backslash at end of line as line extension"
    # it "does something with no prefix for log"
    # it "parses timeout into a hash"
    # it "parses tcp-response into a hash"

    it "parses userlists" do
      expect(config.userlists.map(&:name)).to eq(["groups_list_users", "users_list_groups"])

      ul1 = config.userlists.find { |ul| ul.name == "groups_list_users" }
      expect(ul1.users.size).to eq(3)
      expect(ul1.users.map(&:name)).to eq(["tiger", "scott", "xdb"])
      expect(ul1.users.map(&:password)).to eq([
        "password $6$k6y3o.eP$JlKBx9za9667qe4(...)xHSwRv6J.C0/D7cV91",
        "insecure-password elgato",
        "insecure-password hello",
      ])
      expect(ul1.users.map(&:groups)).to eq([[], [], []])

      expect(ul1.groups.size).to eq(2)
      expect(ul1.groups.map(&:name)).to eq(["G1", "G2"])
      expect(ul1.groups.map(&:users)).to eq([["scott", "tiger"], ["scott", "xdb"]])

      ul2 = config.userlists.find { |ul| ul.name == "users_list_groups" }
      expect(ul2.users.size).to eq(3)
      expect(ul2.users.map(&:name)).to eq(["tiger", "scott", "xdb"])
      expect(ul2.users.map(&:password)).to eq([
        "password $6$k6y3o.eP$JlKBx(...)xHSwRv6J.C0/D7cV91",
        "insecure-password elgato",
        "insecure-password hello",
      ])
      expect(ul2.users.map(&:groups)).to eq([["G1"], ["G1", "G2"], ["G2"]])

      expect(ul2.groups.size).to eq(2)
      expect(ul2.groups.map(&:name)).to eq(["G1", "G2"])
      expect(ul2.groups.map(&:users)).to eq([[], []])
    end

    it "parses cache"
    it "parses resolvers"
    it "parses peers"
    it "parses mailers"
  end

  # context "userlist config file" do
  #   before(:each) do
  #     @parser = HAProxy::Parser.new
  #     @config = @parser.parse_file("spec/fixtures/userlist.haproxy.cfg")
  #   end

  #   it "parses userlists" do
  #     expect(@config.userlists.map(&:name)).to eq(["groups_list_users", "users_list_groups"])

  #     ul1 = @config.userlists.find { |ul| ul.name == "groups_list_users" }
  #     expect(ul1.users.size).to eq(3)
  #     expect(ul1.users.map(&:name)).to eq(["tiger", "scott", "xdb"])
  #     expect(ul1.users.map(&:password)).to eq([
  #       "password $6$k6y3o.eP$JlKBx9za9667qe4(...)xHSwRv6J.C0/D7cV91",
  #       "insecure-password elgato",
  #       "insecure-password hello",
  #     ])
  #     expect(ul1.users.map(&:groups)).to eq([[], [], []])

  #     expect(ul1.groups.size).to eq(2)
  #     expect(ul1.groups.map(&:name)).to eq(["G1", "G2"])
  #     expect(ul1.groups.map(&:users)).to eq([["scott", "tiger"], ["scott", "xdb"]])

  #     ul2 = @config.userlists.find { |ul| ul.name == "users_list_groups" }
  #     expect(ul2.users.size).to eq(3)
  #     expect(ul2.users.map(&:name)).to eq(["tiger", "scott", "xdb"])
  #     expect(ul2.users.map(&:password)).to eq([
  #       "password $6$k6y3o.eP$JlKBx(...)xHSwRv6J.C0/D7cV91",
  #       "insecure-password elgato",
  #       "insecure-password hello",
  #     ])
  #     expect(ul2.users.map(&:groups)).to eq([["G1"], ["G1", "G2"], ["G2"]])

  #     expect(ul2.groups.size).to eq(2)
  #     expect(ul2.groups.map(&:name)).to eq(["G1", "G2"])
  #     expect(ul2.groups.map(&:users)).to eq([[], []])
  #   end
  # end

  # context "multi-pool config file" do
  #   before(:each) do
  #     @parser = HAProxy::Parser.new
  #     @config = @parser.parse_file("spec/fixtures/multi-pool.haproxy.cfg")
  #   end

  #   it "parses default_backend" do
  #     expect(@config.frontends.size).to eq(1)
  #     www_frontend = @config.frontend("www")
  #     expect(www_frontend.config["default_backend"]).to eq("www_main")
  #   end

  #   it "parses defaults" do
  #     expect(@config.defaults.size).to eq(1)

  #     defaults = @config.defaults.first
  #     expect(defaults.config["log"]).to eq("global")
  #     expect(defaults.config["mode"]).to eq("http")
  #     expect(defaults.config["retries"]).to eq("3")
  #     expect(defaults.config["redispatch"]).to be_nil
  #     expect(defaults.config["maxconn"]).to eq("10000")
  #     expect(defaults.config["contimeout"]).to eq("5000")
  #     expect(defaults.config["clitimeout"]).to eq("60000")
  #     expect(defaults.config["srvtimeout"]).to eq("60000")
  #     expect(defaults.config["stats"]).to eq("uri /haproxy-status")
  #     expect(defaults.config["cookie"]).to eq("SERVERID insert indirect nocache")

  #     expect(defaults.options.size).to eq(2)
  #     expect(defaults.options).to include("httplog")
  #     expect(defaults.options).to include("dontlognull")
  #   end

  #   it "parses a named backend from a config file" do
  #     expect(@config.backends.size).to eq(2)
  #     logs_backend = @config.backend("logs")

  #     expect(logs_backend.servers.size).to eq(4)

  #     server1 = logs_backend.servers["prd_log_1"]
  #     expect(server1.name).to eq("prd_log_1")
  #     expect(server1.host).to eq("10.245.174.75")
  #     expect(server1.port).to eq("8000")

  #     server2 = logs_backend.servers["fake_logger"]
  #     expect(server2.name).to eq("fake_logger")
  #     expect(server2.host).to eq("127.0.0.1")
  #     expect(server2.port).to eq("9999")

  #     server3 = logs_backend.servers["prd_log_2"]
  #     expect(server3.name).to eq("prd_log_2")
  #     expect(server3.host).to eq("10.215.157.10")
  #     expect(server3.port).to eq("8000")

  #     server3 = logs_backend.servers["prd_log_3"]
  #     expect(server3.name).to eq("prd_log_3")
  #     expect(server3.host).to eq("cloudloghost1")
  #     expect(server3.port).to eq("8000")
  #   end
  # end

  # context "basic 1.5 config file" do
  #   before(:each) do
  #     @parser = HAProxy::Parser.new
  #     @config = @parser.parse_file("spec/fixtures/simple.haproxy15.cfg")
  #   end

  #   it "parses structured configs" do
  #     defaults = config.defaults.first.config

  #     expect(defaults["timeout connect"]).to eq("5000ms")
  #     expect(defaults["timeout client"]).to eq("5000ms")
  #     expect(defaults["timeout server"]).to eq("5000ms")

  #     expect(defaults["errorfile 400"]).to eq("/etc/haproxy/errors/400.http")
  #     expect(defaults["errorfile 504"]).to eq("/etc/haproxy/errors/504.http")
  #   end
  # end

  # context "basic config file" do
  #   before(:each) do
  #     @parser = HAProxy::Parser.new
  #     @config = @parser.parse_file("spec/fixtures/simple.haproxy.cfg")
  #   end

  #   it "parses global variables from a config file" do
  #     expect(@config.global.size).to eq(3)

  #     expect(@config.global["maxconn"]).to eq("4096")
  #     expect(@config.global["daemon"]).to be_nil
  #     expect(@config.global["nbproc"]).to eq("4")
  #   end

  #   it "parses a default set from a config file" do
  #     expect(@config.defaults.size).to eq(1)

  #     defaults = @config.defaults.first
  #     expect(defaults.config["mode"]).to eq("http")
  #     expect(defaults.config["clitimeout"]).to eq("60000")
  #     expect(defaults.config["srvtimeout"]).to eq("30000")
  #     expect(defaults.config["contimeout"]).to eq("4000")

  #     expect(defaults.options.size).to eq(1)
  #     expect(defaults.options).to include("httpclose")
  #   end

  #   it "parses a listener from a config file" do
  #     expect(@config.listeners.size).to eq(1)

  #     listener = @config.listener("http_proxy")
  #     expect(listener.name).to eq("http_proxy")
  #     expect(listener.host).to eq("55.55.55.55")
  #     expect(listener.port).to eq("80")
  #     expect(listener.config["balance"]).to eq("roundrobin")

  #     expect(listener.options.size).to eq(2)
  #     expect(listener.options).to include("httpchk")
  #     expect(listener.options).to include("forwardfor")

  #     expect(listener.servers.size).to eq(3)

  #     server1 = listener.servers["web1"]
  #     expect(server1.name).to eq("web1")
  #     expect(server1.host).to eq("dnshost66")
  #     expect(server1.port).to eq("80")
  #     expect(server1.attributes["weight"]).to eq("1")
  #     expect(server1.attributes["maxconn"]).to eq("512")
  #     expect(server1.attributes["check"]).to eq(true)

  #     server2 = listener.servers["web2"]
  #     expect(server2.name).to eq("web2")
  #     expect(server2.host).to eq("77.77.77.77")
  #     expect(server2.port).to eq("80")
  #     expect(server2.attributes["weight"]).to eq("1")
  #     expect(server2.attributes["maxconn"]).to eq("512")
  #     expect(server2.attributes["check"]).to eq(true)

  #     server3 = listener.servers["web3"]
  #     expect(server3.name).to eq("web3")
  #     expect(server3.host).to eq("88.88.88.88")
  #     expect(server3.port).to eq("80")
  #     expect(server3.attributes).to be_empty
  #   end
  # end
end
