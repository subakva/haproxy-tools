module HAProxy
  class Renderer

    attr_accessor :config, :source_tree

    def initialize(config, source_tree)
      self.config       = config
      self.source_tree  = source_tree
      @server_list      = {}
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
          @server_list[e.name] = e
          server = @context.servers[e.name]
          next if @context.servers[e.name].nil?
        end

        if e.elements && e.elements.size > 0
          render_node(e)
        else
          @config_text << e.text_value
        end
      end
      @config_text
    end

    protected

    def context_changed?
      @context.class.name != @prev_context.class.name
    end

    def handle_server_line
    end

    def handle_context_change
      if [HAProxy::Listener, HAProxy::Backend].include?(@prev_context.class)
        new_servers = @prev_context.servers.keys - @server_list.keys

        new_servers.each do |server_name|
          s = @prev_context.servers[server_name]
          @config_text << "\tserver #{s.name} #{s.host}:#{s.port} #{s.attributes}\n"
        end
      end
      @server_list = {}
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

