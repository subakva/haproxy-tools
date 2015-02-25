module HAProxy
  # Responsible for rendering an HAProxy::Config instance to a string.
  class Renderer

    attr_accessor :config, :source_tree

    def initialize(config, source_tree)
      self.config       = config
      self.source_tree  = source_tree
      @server_list      = {}
      @config_list      = {}
      @context          = self.config
      @prev_context     = self.config
      @config_text      = ''
    end

    def render
      render_node(self.source_tree)
      handle_context_change
      @config_text
    end

    def render_node(node)
      node.elements.each do |e|
        update_render_context(e)

        handle_context_change if context_changed?

        if e.class == HAProxy::Treetop::ServerLine
          # Keep track of the servers that we've seen, so that we can detect and render new ones.
          @server_list[e.name] = e
          # Don't render the server element if it's been deleted from the config.
          next if @context.servers[e.name].nil?
        end

        if e.class == HAProxy::Treetop::ConfigLine and @context.class == HAProxy::Default
          # Keep track of the configs in this config block we've seen, so that we can detect and render new ones.
          @config_list[e.key] = e
          # Don't render the config *if* it's been removed from the config block.
          next if @context.config[e.key].nil?
        end

        if e.class == HAProxy::Treetop::ServerLine
          # Use a custom rendering method for servers, since we allow them to be
          # added/removed/changed.
          render_server_element(e)
        elsif e.class== HAProxy::Treetop::ConfigLine and @context.class == HAProxy::Default
          # Use a custom rendering method for configs, since we allow them to be
          # added/removed/changed.
          render_config_line_element(e)
        elsif e.elements && e.elements.size > 0
          render_node(e)
        else
          @config_text << e.text_value
        end
      end
      @config_text
    end

    protected

    def context_changed?
      @context != @prev_context
    end

    def render_config_line_element(e)
      config_key = e.key.gsub(/\s+/, ' ')
      config_value = @context.config[e.key]
      config_value = config_value.gsub(/\s+/, ' ') if not config_value.nil?
      render_config_line(config_key, config_value)
    end

    def render_config_line(key, value)
      @config_text << "\t#{key} #{value}\n"
    end

    def render_server_element(e)
      server = @context.servers[e.name]
      render_server(server)
    end

    def render_server(server)
      attribute_string = render_server_attributes(server.attributes)
      @config_text << "\tserver #{server.name} #{server.host}:#{server.port} #{attribute_string}\n"
    end

    def handle_context_change
      if [HAProxy::Default].include?(@prev_context.class)
        # Render any configs which were added
        new_configs = @prev_context.config.keys - @config_list.keys

        new_configs.each do |config_name|
          config_value = @prev_context.config[config_name]
          render_config_line(config_name, config_value)
        end
      end

      if [HAProxy::Listener, HAProxy::Backend].include?(@prev_context.class)
        # Render any servers that were added
        new_servers = @prev_context.servers.keys - @server_list.keys

        new_servers.each do |server_name|
          server = @prev_context.servers[server_name]
          render_server(server)
        end
      end
      @server_list = {}
    end

    def render_server_attributes(attributes)
      attribute_string = ""
      attributes.each do |name, value|
        attribute_string << name
        attribute_string << " "
        if value && value != true
          attribute_string << value
          attribute_string << " "
        end
      end
      attribute_string
    end

    def update_render_context(e)
      @prev_context = @context
      case e.class.name
      when 'HAProxy::Treetop::GlobalSection'
        @context = @config.global
      when 'HAProxy::Treetop::DefaultsSection'
        section_name = e.defaults_header.proxy_name ? e.defaults_header.proxy_name.content : nil
        @context = @config.default(section_name)
      when 'HAProxy::Treetop::ListenSection'
        section_name = e.listen_header.proxy_name ? e.listen_header.proxy_name.content : nil
        @context = @config.listener(section_name)
      when 'HAProxy::Treetop::FrontendSection'
        section_name = e.frontend_header.proxy_name ? e.frontend_header.proxy_name.content : nil
        @context = @config.frontend(section_name)
      when 'HAProxy::Treetop::BackendSection'
        section_name = e.backend_header.proxy_name ? e.backend_header.proxy_name.content : nil
        @context = @config.backend(section_name)
      else
        @context = @prev_context
      end
    end
  end
end

