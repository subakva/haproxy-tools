# frozen_string_literal: true

require "spec_helper"

describe "HAProxy::Config" do
  describe "render multi-backend config" do
    before(:each) do
      @config = HAProxy::Config.parse_file("spec/fixtures/multi-pool.haproxy.cfg")
    end

    it "can re-render a config file with a server removed" do
      l = @config.backend("www_main")
      l.servers.delete("prd_www_1")

      new_config_text = @config.render

      new_config = HAProxy::Parser.new.parse(new_config_text)
      expect(new_config.backend("www_main").servers["prd_www_1"]).to be_nil
    end

    it "can re-render a config file with a server attribute added" do
      b = @config.backend("www_main")
      b.servers["prd_www_1"].attributes["disabled"] = true
      new_config_text = @config.render

      new_config = HAProxy::Parser.new.parse(new_config_text)
      s = new_config.backend("www_main").servers["prd_www_1"]
      expect(s).not_to be_nil
      expect(s.attributes["disabled"]).to be_truthy
    end

    it "can re-render a config file with a server added" do
      b = @config.backend("www_main")
      b.add_server("prd_www_4", "99.99.99.99", port: "8000", attributes: {weight: 128})

      new_config_text = @config.render

      new_config = HAProxy::Parser.new.parse(new_config_text)
      s = new_config.backend("www_main").servers["prd_www_4"]
      expect(s).not_to be_nil
      expect(s.name).to eq("prd_www_4")
      expect(s.host).to eq("99.99.99.99")
      expect(s.port).to eq("8000")
      expect(s.attributes.to_a).to eq([["weight", "128"]])
    end

    it "can re-render a config file with a server added based on template" do
      b = @config.backend("www_main")
      b.add_server("prd_www_4", "99.99.99.99", template: b.servers["prd_www_1"])

      new_config_text = @config.render

      new_config = HAProxy::Parser.new.parse(new_config_text)
      s = new_config.backend("www_main").servers["prd_www_4"]
      expect(s).not_to be_nil
      expect(s.name).to eq("prd_www_4")
      expect(s.host).to eq("99.99.99.99")
      expect(s.port).to eq("8000")
      expect(s.attributes.to_a).to eq([
        ["cookie", "i-prd_www_1"],
        ["check", true],
        ["inter", "3000"],
        ["rise", "2"],
        ["fall", "3"],
        ["maxconn", "1000"],
      ])
    end
  end

  describe "re-render multi-pool config" do
    before(:each) do
      @config = HAProxy::Config.parse_file("spec/fixtures/multi-pool.haproxy.cfg")
    end

    it "can re-render the config file" do
      original_text = File.read("spec/fixtures/multi-pool.haproxy.cfg")
      new_text = @config.render
      expect(new_text.squeeze(" ")).to eq(original_text.squeeze(" "))
    end
  end

  describe "render simple 1.5 config" do
    before(:each) do
      @config = HAProxy::Config.parse_file("spec/fixtures/simple.haproxy15.cfg")
    end

    it "can re-render a config file with an error page removed" do
      expect(@config.default.config).to have_key("errorfile 400")
      @config.default.config.delete("errorfile 400")

      new_config_text = @config.render

      new_config = HAProxy::Parser.new.parse(new_config_text)
      expect(new_config.default.config).not_to have_key("errorfile 400")
    end

    it "can re-render a config file with an error page added" do
      expect(@config.default.config).not_to have_key("errorfile 401")
      @config.default.config["errorfile 401"] = "/etc/haproxy/errors/401.http"

      new_config_text = @config.render

      new_config = HAProxy::Parser.new.parse(new_config_text)
      expect(new_config.default.config).to have_key("errorfile 401")
      expect(new_config.default.config["errorfile 401"]).to eq("/etc/haproxy/errors/401.http")
    end
  end

  describe "render simple config" do
    before(:each) do
      @config = HAProxy::Config.parse_file("spec/fixtures/simple.haproxy.cfg")
    end

    it "can re-render a config file with a config removed" do
      expect(@config.default.config).to have_key("clitimeout")
      @config.default.config.delete("clitimeout")

      new_config_text = @config.render

      new_config = HAProxy::Parser.new.parse(new_config_text)
      expect(new_config.default.config).not_to have_key("clitimeout")
    end

    it "can re-render a config file with a server removed" do
      l = @config.listener("http_proxy")
      l.servers.delete("web1")

      new_config_text = @config.render

      new_config = HAProxy::Parser.new.parse(new_config_text)
      expect(new_config.listener("http_proxy").servers["web1"]).to be_nil
    end

    it "can re-render a config file with a server added" do
      l = @config.listener("http_proxy")
      l.add_server("web4", "99.99.99.99", template: l.servers["web1"])

      new_config_text = @config.render

      new_config = HAProxy::Parser.new.parse(new_config_text)
      s = new_config.listener("http_proxy").servers["web4"]
      expect(s).not_to be_nil
      expect(s.name).to eq("web4")
      expect(s.host).to eq("99.99.99.99")
      expect(s.port).to eq("80")
      expect(s.attributes.to_a).to eq([
        ["weight", "1"],
        ["maxconn", "512"],
        ["check", true],
      ])
    end
  end
end
