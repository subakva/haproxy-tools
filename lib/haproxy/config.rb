module HAProxy
  Backend   = Struct.new(:name, :servers)
  Frontend  = Struct.new(:name, :ip, :port)
  Server    = Struct.new(:name, :ip, :port, :options)

  class Config
    attr_accessor :options, :backends, :frontends, :option_groups
    
    def initialize(options = nil)
      self.options = options || {}
      self.backends = []
      self.frontends = []
      self.option_groups = {'global' => {}, 'defaults' => {}}
    end

    def global
      option_groups['global']
    end

    def defaults
      option_groups['defaults']
    end

    def backend(name)
      self.backends.find { |b| b.name == name }
    end
  end
end
