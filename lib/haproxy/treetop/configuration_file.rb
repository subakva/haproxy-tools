# frozen_string_literal: true

require "haproxy/treetop/shared"
# require "haproxy/treetop/service_address"
# require "haproxy/treetop/server"
# require "haproxy/treetop/userlist"

module HAProxy
  module Treetop
    # Helper class for the root config file node
    class ConfigurationFile < ::Treetop::Runtime::SyntaxNode
      def global
        elements.find { |e| e.class == GlobalSection }
      end

      # def defaults
      #   elements.select { |e| e.class == DefaultsSection }
      # end

      # def listeners
      #   elements.select { |e| e.class == ListenSection }
      # end

      # def frontends
      #   elements.select { |e| e.class == FrontendSection }
      # end

      # def backends
      #   elements.select { |e| e.class == BackendSection }
      # end

      def userlists
        elements.select { |e| e.class == UserlistSection }
      end
    end

    # class DefaultsHeader < ::Treetop::Runtime::SyntaxNode
    #   include StrippedTextContent

    #   def proxy_name
    #     elements.find { |e| e.class == ProxyName }
    #   end
    # end

    class DefaultsSection < ::Treetop::Runtime::SyntaxNode
    end

    class NamedHeader < ::Treetop::Runtime::SyntaxNode
      include LineWithComment

      def render
        text_value
      end

      def keyword
        elements[1].text_value
      end

      def name
        section_name.text_value.strip
      end

      def inspect
        "[NamedHeader] keyword: \"#{keyword}\", name: \"#{name}\", comment: \"#{comment_text}\""
      end
    end

    class GlobalHeader < ::Treetop::Runtime::SyntaxNode
      include LineWithComment

      def render
        text_value
      end

      def inspect
        "[GlobalHeader] keyword: \"global\", comment: \"#{comment_text}\""
      end
    end

    class GlobalSection < ::Treetop::Runtime::SyntaxNode
      def parameters
        @parameters ||= parameter_block.elements.select { |e| e.class == ParameterLine }
      end

      def size
        parameters.size
      end

      def [](key)
        params = parameters.select { |p| p.key == key }
        return nil if params.empty?

        values = params.map { |p| p.value == "" ? nil : p.value }
        return values.first if params.length == 1
        values
      end
    end

    class UserlistSection < ::Treetop::Runtime::SyntaxNode
      class NameList < ::Treetop::Runtime::SyntaxNode
        def values
          userlist_name_list.text_value.split(",").map(&:strip).sort
        end
      end

      def parameters
        @parameters ||= parameter_block.elements.select { |e| e.class == ParameterLine }
      end

      def name
        userlist_header.name
      end

      def users
        @users ||= userlist_block.elements.select { |e| e.class == UserLine }
      end

      def groups
        @groups ||= userlist_block.elements.select { |e| e.class == GroupLine }
      end
    end

    class UserLine < ::Treetop::Runtime::SyntaxNode
      include LineWithComment

      class Password  < ::Treetop::Runtime::SyntaxNode; end
      class InsecurePassword  < ::Treetop::Runtime::SyntaxNode; end

      def name
        userlist_name.text_value
      end

      def password
        secure_password = elements.find { |e| e.class == Password }
        insecure_password = elements.find { |e| e.class == InsecurePassword }
        [secure_password, insecure_password].compact.first.text_value
      end

      def groups
        list = elements.find { |e| e.class == UserlistSection::NameList }
        list ? list.values : []
      end

      def inspect
        "[UserLine] name: \"#{name}\", password: \"#{password}\", groups: \"#{groups.join(',')}\", comment: \"#{comment_text}\""
      end
    end

    class GroupLine < ::Treetop::Runtime::SyntaxNode
      include LineWithComment

      def name
        userlist_name.text_value
      end

      def users
        list = elements.find { |e| e.class == UserlistSection::NameList }
        list ? list.values : []
      end

      def inspect
        "[GroupLine] name: \"#{name}\", users: \"#{users.join(',')}\", comment: \"#{comment_text}\""
      end
    end

    # class ListenHeader < ::Treetop::Runtime::SyntaxNode
    #   include ServiceAddressContainer
    # end

    # class ListenSection < ::Treetop::Runtime::SyntaxNode
    #   include ConfigBlockContainer
    #   include ServerContainer
    # end

    # class FrontendHeader < ::Treetop::Runtime::SyntaxNode
    #   include ServiceAddressContainer
    # end

    # class FrontendSection < ::Treetop::Runtime::SyntaxNode
    #   include ConfigBlockContainer
    # end

    # class BackendSection < ::Treetop::Runtime::SyntaxNode
    #   include ConfigBlockContainer
    #   include ServerContainer
    # end
  end
end
