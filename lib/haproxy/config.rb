module HAProxy
  Default   = Struct.new(:name, :options, :config)
  Backend   = Struct.new(:name, :options, :config, :servers)
  Listener  = Struct.new(:name, :host, :port, :options, :config, :servers)
  Frontend  = Struct.new(:name, :host, :port, :options, :config)
  Server    = Struct.new(:name, :host, :port, :attributes)

  # Contains shared methods for config objects that contain a list of servers. The including class
  # is expected to have an instance variable called :servers that contains a hash of server
  # configurations.
  module ServerList
    def add_server(name, host, options)
      options ||= {}
      new_server = options[:template] ? options[:template].clone : Server.new
      new_server.name       = name
      new_server.host       = host
      new_server.port       = options[:port] if options[:port]
      new_server.attributes ||= options[:attributes] || []
      self.servers[name] = new_server
      new_server
    end
  end


  # Represents a listener configuration block.
  class Listener
    include ServerList
  end

  # Represents a backend configuration block.
  class Backend
    include ServerList
  end

  # Represents an haproxy configuration file.
  class Config
    attr_accessor :original_parse_tree, :listeners, :backends, :frontends, :global, :defaults

    def initialize(parse_tree)
      self.original_parse_tree = parse_tree
      self.backends   = []
      self.listeners  = []
      self.frontends  = []
      self.defaults   = []
      self.global     = {}
    end

    def listener(name)
      self.listeners.find { |l| l.name == name }
    end

    def backend(name)
      self.backends.find { |b| b.name == name }
    end

    def frontend(name)
      self.frontends.find { |f| f.name == name }
    end

    def default(name=nil)
      self.defaults.find { |d| d.name == name }
    end

    def render
      renderer = HAProxy::Renderer.new(self, self.original_parse_tree)
      renderer.render
    end

    protected

    class << self
      def parse_file(filename)
        HAProxy::Parser.new.parse_file(filename)
      end
    end
  end
end

