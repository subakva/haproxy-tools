module HAProxy
  Default   = Struct.new(:name, :options, :config)
  Backend   = Struct.new(:name, :options, :config, :servers)
  Listener  = Struct.new(:name, :host, :port, :options, :config, :servers)
  Frontend  = Struct.new(:name, :host, :port, :options, :config)
  Server    = Struct.new(:name, :host, :port, :attributes)

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

    def default(name)
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

