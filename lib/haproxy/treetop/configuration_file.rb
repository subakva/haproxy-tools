# frozen_string_literal: true

require "haproxy/treetop/shared"
require "haproxy/treetop/userlist"
# require "haproxy/treetop/service_address"

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
        elements.select { |e| e.class == Userlist::Section }
      end
    end

    class GlobalSection < ::Treetop::Runtime::SyntaxNode
      include ParameterContainer
    end

    class DefaultsSection < ::Treetop::Runtime::SyntaxNode
      include NamedSection
      include ParameterContainer
      include OptionContainer
    end

    class FrontendSection < ::Treetop::Runtime::SyntaxNode
      include NamedSection
      include ParameterContainer
    end

    class BackendSection < ::Treetop::Runtime::SyntaxNode
      include NamedSection
      include ParameterContainer
      include ServerContainer
    end

    class ListenSection < ::Treetop::Runtime::SyntaxNode
      include NamedSection
      include ParameterContainer
      include ServerContainer
    end
  end
end
