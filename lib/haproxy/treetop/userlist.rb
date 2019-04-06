# frozen_string_literal: true

require "haproxy/treetop/shared"

module HAProxy
  module Treetop
    module Userlist
      class Password < ::Treetop::Runtime::SyntaxNode; end
      class InsecurePassword < ::Treetop::Runtime::SyntaxNode; end

      class Section < ::Treetop::Runtime::SyntaxNode
        include NamedSection
        include ParameterContainer

        def users
          'single'
          @users ||= userlist_block.elements.select { |e| e.class == UserLine }
        end

        def groups
          @groups ||= userlist_block.elements.select { |e| e.class == GroupLine }
        end
      end

      class NameList < ::Treetop::Runtime::SyntaxNode
        def values
          userlist_name_list.text_value.split(",").map(&:strip).sort
        end
      end

      class UserLine < ::Treetop::Runtime::SyntaxNode
        include LineWithComment

        def name
          userlist_name.text_value
        end

        def password
          secure_password = elements.find { |e| e.class == Password }
          insecure_password = elements.find { |e| e.class == InsecurePassword }
          [secure_password, insecure_password].compact.first.text_value
        end

        def groups
          list = elements.find { |e| e.class == NameList }
          list ? list.values : []
        end

        def inspect
          "[UserLine] name: \"#{name}\", password: \"#{password}\", groups: \"#{groups.join(",")}\", comment: \"#{comment_text}\""
        end
      end

      class GroupLine < ::Treetop::Runtime::SyntaxNode
        include LineWithComment

        def name
          userlist_name.text_value
        end

        def users
          list = elements.find { |e| e.class == NameList }
          list ? list.values : []
        end

        def inspect
          "[GroupLine] name: \"#{name}\", users: \"#{users.join(",")}\", comment: \"#{comment_text}\""
        end
      end
    end
  end
end
