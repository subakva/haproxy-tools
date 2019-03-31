# frozen_string_literal: true

require "haproxy/treetop/shared"

module HAProxy
  module Treetop
    class UserlistSection < ::Treetop::Runtime::SyntaxNode
      include ConfigBlockContainer

      def users
        config_block.elements.select { |e| e.class == UserLine }
      end

      def groups
        config_block.elements.select { |e| e.class == GroupLine }
      end
    end

    class UserLine < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent

      def password
        secure_password = elements.find { |e| e.class == Password }
        insecure_password = elements.find { |e| e.class == InsecurePassword }
        [secure_password, insecure_password].compact.first.content
      end

      def group_names
        list = elements.find { |e| e.class == GroupNames }
        list ? list.name_list.values : []
      end
    end

    class GroupLine < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent

      def user_names
        list = elements.find { |e| e.class == UserNames }
        list ? list.name_list.values : []
      end
    end

    class GroupNames < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class UserNames < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class NameList < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent

      def values
        content.split(",").map(&:strip).sort
      end
    end

    class Name < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class Password < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class InsecurePassword < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end
  end
end
