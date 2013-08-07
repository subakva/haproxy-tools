module HAProxy
  # Responsible for reading an HAProxy config file and building an HAProxy::Config instance.
  class Parser
    # Raised when an error occurs during parsing.
    Error = Class.new(StandardError)

    # haproxy 1.3
    SERVER_ATTRIBUTE_NAMES_1_3 = %w{
      addr backup check cookie disabled fall id inter fastinter downinter
      maxconn maxqueue minconn port redir rise slowstart source track weight
    }
    # Added in haproxy 1.4
    SERVER_ATTRIBUTE_NAMES_1_4 = %w{error-limit observe on-error}
    SERVER_ATTRIBUTE_NAMES = SERVER_ATTRIBUTE_NAMES_1_3 + SERVER_ATTRIBUTE_NAMES_1_4

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
      result = parse_config_text(config_text)
      self.parse_result = result
      build_config(result)
    end

    protected

    def parse_config_text(config_text)
      parser = HAProxy::Treetop::ConfigParser.new
      result = parser.parse(config_text)
      raise HAProxy::Parser::Error.new(parser.failure_reason) if result.nil?
      result
    end

    def build_config(result)
      HAProxy::Config.new(result).tap do |config|
        config.global = config_hash_from_config_section(result.global)

        config.frontends  += collect_frontends(result)
        config.backends   += collect_backends(result)
        config.listeners  += collect_listeners(result)
        config.defaults   += collect_defaults(result)
      end
    end

    def build_frontend(fs)
      Frontend.new.tap do |f|
        f.name        = try_send(fs.frontend_header, :proxy_name, :content)
        f.host        = try_send(fs.frontend_header, :service_address, :host, :content)
        f.port        = try_send(fs.frontend_header, :service_address, :port, :content)
        f.options     = options_hash_from_config_section(fs)
        f.config      = config_hash_from_config_section(fs)
      end
    end

    def build_backend(bs)
      Backend.new.tap do |b|
        b.name        = try_send(bs.backend_header, :proxy_name, :content)
        b.options     = options_hash_from_config_section(bs)
        b.config      = config_hash_from_config_section(bs)
        b.servers     = server_hash_from_config_section(bs)
      end
    end

    def build_listener(ls)
      Listener.new.tap do |l|
        l.name        = try_send(ls.listen_header, :proxy_name, :content)
        l.host        = try_send(ls.listen_header, :service_address, :host, :content)
        l.port        = try_send(ls.listen_header, :service_address, :port, :content)
        l.options     = options_hash_from_config_section(ls)
        l.config      = config_hash_from_config_section(ls)
        l.servers     = server_hash_from_config_section(ls)
      end
    end

    def build_default(ds)
      Default.new.tap do |d|
        d.name        = try_send(ds.defaults_header, :proxy_name, :content)
        d.options     = options_hash_from_config_section(ds)
        d.config      = config_hash_from_config_section(ds)
      end
    end

    def collect_frontends(result)
      result.frontends.map { |fs| build_frontend(fs) }
    end

    def collect_backends(result)
      result.backends.map { |bs| build_backend(bs) }
    end

    def collect_listeners(result)
      result.listeners.map { |ls| build_listener(ls) }
    end

    def collect_defaults(result)
      result.defaults.map { |ds| build_default(ds) }
    end


    def try_send(node, *method_names)
      method_name = method_names.shift
      if node.respond_to?(method_name)
        next_node = node.send(method_name)
        method_names.empty? ? next_node : try_send(next_node, *method_names)
      else
        nil
      end
    end

    def server_hash_from_config_section(cs)
      cs.servers.inject({}) do |ch, s|
        value = try_send(s, :value, :content)
        ch[s.name] = Server.new(s.name, s.host, s.port, parse_server_attributes(value))
        ch
      end
    end

    # Parses server attributes from the server value. I couldn't get manage to get treetop to do
    # this.
    #
    # Types of server attributes to support:
    # ipv4, boolean, string, integer, time (us, ms, s, m, h, d), url, source attributes
    #
    # BUG: If an attribute value matches an attribute name, the parser will assume that a new
    # attribute value has started. I don't know how haproxy itself handles that situation.
    def parse_server_attributes(value)
      parts = value.split(/\s/)
      current_name = nil
      pairs = parts.inject({}) do |pairs, part|
        if SERVER_ATTRIBUTE_NAMES.include?(part)
          current_name  = part
          pairs[current_name] = []
        elsif current_name.nil?
          raise "Invalid server attribute: #{part}"
        else
          pairs[current_name] << part
        end
        pairs
      end

      return clean_parsed_server_attributes(pairs)
    end

    # Converts attributes with no values to true, and combines everything else into space-
    # separated strings.
    def clean_parsed_server_attributes(pairs)
      pairs.each do |k,v|
        if v.empty?
          pairs[k] = true
        else
          pairs[k] = v.join(' ')
        end
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
