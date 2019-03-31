# frozen_string_literal: true

require "haproxy/treetop/shared"
require "haproxy/treetop/service_address"
require "haproxy/treetop/server"
require "haproxy/treetop/userlist"

module HAProxy
  module Treetop
    # Helper class for the root config file node
    class ConfigurationFile < ::Treetop::Runtime::SyntaxNode
      def global
        elements.find { |e| e.class == GlobalSection }
      end

      def defaults
        elements.select { |e| e.class == DefaultsSection }
      end

      def listeners
        elements.select { |e| e.class == ListenSection }
      end

      def frontends
        elements.select { |e| e.class == FrontendSection }
      end

      def backends
        elements.select { |e| e.class == BackendSection }
      end

      def userlists
        elements.select { |e| e.class == UserlistSection }
      end
    end

    class DefaultsHeader < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent

      def proxy_name
        elements.find { |e| e.class == ProxyName }
      end
    end

    class DefaultsSection < ::Treetop::Runtime::SyntaxNode
      include ConfigBlockContainer
    end

    class GlobalSection < ::Treetop::Runtime::SyntaxNode
      include ConfigBlockContainer
    end

    class ListenHeader < ::Treetop::Runtime::SyntaxNode
      include ServiceAddressContainer
    end

    class ListenSection < ::Treetop::Runtime::SyntaxNode
      include ConfigBlockContainer
      include ServerContainer
    end

    class FrontendHeader < ::Treetop::Runtime::SyntaxNode
      include ServiceAddressContainer
    end

    class FrontendSection < ::Treetop::Runtime::SyntaxNode
      include ConfigBlockContainer
    end

    class BackendSection < ::Treetop::Runtime::SyntaxNode
      include ConfigBlockContainer
      include ServerContainer
    end
  end
end
