module HAProxy
	class Parser
    attr_accessor :verbose, :options
    attr_accessor :current_backend, :current_section, :current_frontend, :current_section_name

    def initialize(options = nil)
      options ||= {}
      options = { :verbose => false }.merge(options)

      self.options = options
      self.verbose = options[:verbose]
      reset_parser_flags
    end

    def reset_parser_flags
      self.current_section   = nil
      self.current_backend   = nil
      self.current_frontend  = nil
    end

    # This is starting to suck. Try treetop.
    def parse(filename)
      self.reset_parser_flags

      config = HAProxy::Config.new
      start_backend(config, 'default')
      start_frontend(config, 'default')

      lines = File.readlines(filename)
      lines.each do |line|
        line.strip!
        case line.strip
        when /^(global|defaults)$/
          start_section(config, $1)
        when /^frontend\W+([^\W]+)\W+([^\W:]+):(\d+)/
          start_section(config, 'frontend')
          start_frontend(config, $1)
        when /^backend\W+([^\W]+)/
          start_section(config, 'backend')
          start_backend(config, $1)
        when /^server\W+([^\W]+)\W+([\d\.]+):(\d+)(.*)/
          append_server($1, $2, $3, $4)
        when /^([^\W]+)([^#]*)/ # match other name/value pairs; ignore comments
          append_option($1, $2)
        when /^$/
        when /^#.*/
          puts " => Ignoring comment: #{line}" if verbose
        else
          puts " => Skipping non-matching line: #{line}" if verbose
        end
      end

      config
    end

    def normalize_option_string(option_string)
      normalized_options = option_string.strip.split
      normalized_options = normalized_options.first if normalized_options.size <= 1
      normalized_options
    end

    def append_option(name, option_string)
      normalized_options = normalize_option_string(option_string)

      puts " => Adding #{current_section_name} option : #{name} = #{normalized_options.inspect}" if verbose

      current_section[name] ||= []
      self.current_section[name] << normalized_options unless normalized_options.nil?
    end

    def append_server(name, ip, port, option_string)
      puts " => Adding server: #{name}" if verbose

      server_options = normalize_option_string(option_string)
      self.current_backend.servers[name] = Server.new(name, ip, port, server_options)
    end

    def start_section(config, name)
      puts " => Starting option_group: #{name}" if verbose

      config.option_groups[name] ||= {}
      self.current_section_name = name
      self.current_section = config.option_groups[name]
    end

    def start_frontend(config, name)
      puts " => Starting frontend: #{name}" if verbose

      self.current_frontend = Frontend.new(name, {})
      config.frontends << self.current_frontend
    end

    def start_backend(config, name)
      puts " => Starting backend: #{name}" if verbose

      self.current_backend = Backend.new(name, {})
      config.backends << self.current_backend
    end
	end
end
