module HAProxy
	class Parser
    class Error < Exception; end

    attr_accessor :verbose, :options, :parse_result

    def initialize(options = nil)
      options ||= {}
      options = { :verbose => false }.merge(options)

      self.options = options
      self.verbose = options[:verbose]
    end

    def parse_file(filename)
      config_text = File.read(filename)
      self.parse(config_text)
    end

    def parse(config_text)
      parser = HAProxy::Treetop::ConfigParser.new
      result = parser.parse(config_text)
      raise HAProxy::Parser::Error.new(parser.failure_reason) if result.nil?

      config = HAProxy::Config.new(result)
      config.global = config_hash_from_config_section(result.global)

      result.frontends.each do |fs|
        f = Frontend.new
        f.name        = try(fs.frontend_header, :proxy_name, :content)
        f.host        = try(fs.frontend_header, :service_address, :host, :content)
        f.port        = try(fs.frontend_header, :service_address, :port, :content)
        f.options     = options_hash_from_config_section(fs)
        f.config      = config_hash_from_config_section(fs)
        config.frontends << f
      end

      result.backends.each do |bs|
        b = Backend.new
        b.name        = try(bs.backend_header, :proxy_name, :content)
        b.options     = options_hash_from_config_section(bs)
        b.config      = config_hash_from_config_section(bs)
        b.servers     = server_hash_from_config_section(bs)
        config.backends << b
      end

      result.listeners.each do |ls|
        l = Listener.new
        l.name        = try(ls.listen_header, :proxy_name, :content)
        l.host        = try(ls.listen_header, :service_address, :host, :content)
        l.port        = try(ls.listen_header, :service_address, :port, :content)
        l.options     = options_hash_from_config_section(ls)
        l.config      = config_hash_from_config_section(ls)
        l.servers     = server_hash_from_config_section(ls)
        config.listeners << l
      end

      result.defaults.each do |ds|
        d = Default.new
        d.name        = try(ds.defaults_header, :proxy_name, :content)
        d.options     = options_hash_from_config_section(ds)
        d.config      = config_hash_from_config_section(ds)
        config.defaults << d
      end

      self.parse_result = result
      config
    end


    protected

    def try(node, *method_names)
      method_name = method_names.shift
      if node.respond_to?(method_name)
        next_node = node.send(method_name)
        method_names.empty? ? next_node : try(next_node, *method_names)
      else
        nil
      end
    end

    def server_hash_from_config_section(cs)
      cs.servers.inject({}) do |ch, s|
        ch[s.name] = Server.new(s.name, s.host, s.port, try(s, :value, :content))
        ch
      end
    end

    def options_hash_from_config_section(cs)
      cs.option_lines.inject({}) do |ch, l|
        ch[l.keyword.content] = l.value ? l.value.content : nil
        ch
      end
    end

    def config_hash_from_config_section(cs)
      cs.config_lines.reject{|l| l.keyword.content == 'option'}.inject({}) do |ch, l|
        ch[l.keyword.content] = l.value ? l.value.content : nil
        ch
      end
    end

  end
end

