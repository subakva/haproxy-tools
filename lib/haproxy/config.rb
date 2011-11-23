module HAProxy
  Backend = Struct.new(:name, :servers)
  Server = Struct.new(:name, :ip, :port)

  class Config
    attr_accessor :options, :backends, :frontends, :config_sections
    
    def initialize(options = nil)
      self.options = options || {}
      self.backends = []
      self.frontends = []
      self.config_sections = {}
    end

    def global
      config_sections['global']
    end

    def defaults
      config_sections['defaults']
    end

    def backend(name)
      self.backends.find { |b| b.name == name }
    end

    def parse
      # This is starting to suck. Try treetop.
      lines = File.readlines(self.options[:filename])

      current_backend = start_backend('default')
      current_section = nil

      lines.each do |line|
        line.strip!
        case line.strip
        when /^global$/
          current_section = start_config_section('global')
        when /^defaults$/
          current_section = start_config_section('defaults')
        when /^frontend\W+([^\W]+)\W+([^\W:]+):(\d+)/
          current_section == 'frontend'
          current_frontend = start_frontend($1)
        when /^backend\W+([^\W]+)/
          current_section == 'backend'
          current_backend = start_backend($1)
        when /^server\W+([^\W]+)\W+([\d\.]+):(\d+)/
          name  = $1
          ip    = $2
          port  = $3
          current_backend.servers[name] = Server.new(name, ip, port)
        when /^([^\W]+)([^#]*)/ # match other name/value pairs; ignore comments
          name = $1
          values = $2.strip.split
          values = values.first if values.size <= 1
          current_section[name] ||= []
          current_section[name] << values unless values.nil?
        else
          # puts "- Skipped #{line}"
        end
      end
      self
    end

    def start_config_section(name)
      section = {}
      config_sections[name] = section
      section
    end

    def start_backend(name)
      backend = Backend.new(name, {})
      self.backends << backend
      backend
    end
  end
end
