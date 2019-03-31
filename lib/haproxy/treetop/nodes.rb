# frozen_string_literal: true
module HAProxy
  module Treetop
    extend self

    # Include this module to always strip whitespace from the text_value
    module StrippedTextContent
      def content
        self.text_value.strip
      end
    end

    # Include this module if the node contains a config element.
    module ConfigBlockContainer
      def option_lines
        self.config_block.elements.select {|e| e.class == OptionLine}
      end

      def config_lines
        self.config_block.elements.select {|e| e.class == ConfigLine}
      end
    end

    # Include this module if the node contains a service address element.
    module ServiceAddressContainer
      def service_address
        self.elements.find {|e| e.class == ServiceAddress }
      end

      def host
        self.service_address.host.text_value.strip
      end

      def port
        self.service_address.port.text_value.strip
      end
    end

    # Include this module if the node contains a server elements.
    module ServerContainer
      def servers
        self.config_block.elements.select {|e| e.class == ServerLine}
      end
    end

    # Include this module if the value is optional for the node.
    module OptionalValueElement
      def value
        self.elements.find {|e| e.class == Value}
      end
    end

    class Whitespace < ::Treetop::Runtime::SyntaxNode
      def content
        self.text_value
      end
    end

    class LineBreak < ::Treetop::Runtime::SyntaxNode
    end

    class Char < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class Keyword < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class ProxyName < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class ServerName < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class Host < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class Port < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class Value < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class CommentText < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class ServiceAddress < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class CommentLine < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class BlankLine < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class ConfigLine < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
      include OptionalValueElement

      def key
        self.keyword.content
      end

      def attribute
        self.value.content
      end

    end

    class OptionLine < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
      include OptionalValueElement
    end

    class ServerLine < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
      include ServiceAddressContainer
      include OptionalValueElement

      def name
        self.server_name.content
      end
    end

    class GlobalHeader < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class DefaultsHeader < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
      def proxy_name
        self.elements.select {|e| e.class == ProxyName}.first
      end
    end

    class UserlistHeader < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class BackendHeader < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class FrontendHeader < ::Treetop::Runtime::SyntaxNode
      include ServiceAddressContainer
    end

    class ListenHeader < ::Treetop::Runtime::SyntaxNode
      include ServiceAddressContainer
    end

    class ConfigBlock < ::Treetop::Runtime::SyntaxNode
    end

    class DefaultsSection < ::Treetop::Runtime::SyntaxNode
      include ConfigBlockContainer
    end

    class GlobalSection < ::Treetop::Runtime::SyntaxNode
      include ConfigBlockContainer
    end

    class UserlistSection < ::Treetop::Runtime::SyntaxNode
      include ConfigBlockContainer
    end

    class FrontendSection < ::Treetop::Runtime::SyntaxNode
      include ConfigBlockContainer
    end

    class ListenSection < ::Treetop::Runtime::SyntaxNode
      include ConfigBlockContainer
      include ServerContainer
    end

    class BackendSection < ::Treetop::Runtime::SyntaxNode
      include ConfigBlockContainer
      include ServerContainer
    end

    class ConfigurationFile < ::Treetop::Runtime::SyntaxNode
      def global
        self.elements.select {|e| e.class == GlobalSection}.first
      end

      def defaults
        self.elements.select {|e| e.class == DefaultsSection}
      end

      def listeners
        self.elements.select {|e| e.class == ListenSection}
      end

      def frontends
        self.elements.select {|e| e.class == FrontendSection}
      end

      def backends
        self.elements.select {|e| e.class == BackendSection}
      end
    end

    def print_node(e, depth, options = nil)
      options ||= {}
      options = {:max_depth => 2}.merge(options)

      puts if depth == 0
      print "--" * depth
      print " #{e.class.name.split('::').last}"
      print " [#{e.text_value}]" if e.class == ::Treetop::Runtime::SyntaxNode
      print " [#{e.content}]" if e.respond_to? :content
      puts
      e.elements.each do |child|
        print_node(child, depth + 1, options)
      end if depth < options[:max_depth] && e.elements && !e.respond_to?(:content)
    end
  end
end
