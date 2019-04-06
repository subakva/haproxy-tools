# frozen_string_literal: true

module HAProxy
  module Treetop
    module LineWithComment
      def comment_text
        node = elements.find { |e| e.class == CommentText }
        node && node.text_value
      end
    end

    module ParameterContainer
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

    module OptionContainer
      def options
        @options ||= parameter_block.elements.select { |e| e.class == OptionLine }.each_with_object({}) do |l, hash|
          hash[l.key] = l
        end
      end
    end

    module ServerContainer
      def servers
        @servers ||= parameter_block.elements.select { |e| e.class == ServerLine }.each_with_object({}) do |l, hash|
          hash[l.key] = l
        end
      end
    end

    module NamedSection
      def name
        header = elements.find { |e| e.class == NamedHeader }
        section_name = header.elements.find { |e| e.class == SectionName }
        section_name && section_name.text_value.strip
      end
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
        section_name = elements.find { |e| e.class == SectionName }
        section_name && section_name.text_value.strip
      end

      def inspect
        "[NamedHeader] keyword: \"#{keyword}\", name: \"#{name}\", comment: \"#{comment_text}\""
      end
    end

    class SectionName < ::Treetop::Runtime::SyntaxNode
      def inspect
        "[SectionName] #{text_value}"
      end
    end

    class CommentText < ::Treetop::Runtime::SyntaxNode
      def inspect
        "[CommentText] #{text_value}"
      end
    end

    class Negation < ::Treetop::Runtime::SyntaxNode; end

    class ParameterLine < ::Treetop::Runtime::SyntaxNode
      include LineWithComment

      def key
        keyword.text_value
      end

      def value
        parameter_value.text_value.strip
      end

      def inspect
        "[ParameterLine] key: \"#{key}\", value: \"#{value}\", comment: \"#{comment_text}\""
      end
    end

    class OptionLine < ParameterLine
      def enabled?
        elements.none? { |e| e.class == Negation }
      end

      def inspect
        "[OptionLine] key: \"#{key}\", enabled: \"#{enabled?}\", value: \"#{value}\", comment: \"#{comment_text}\""
      end
    end

    class ServerLine < ParameterLine
      alias name key
      def inspect
        "[ServerLine] name: \"#{name}\", value: \"#{value}\", comment: \"#{comment_text}\""
      end
    end

    class CommentLine < ::Treetop::Runtime::SyntaxNode
      def inspect
        "[CommentLine] comment: \"#{comment_text.text_value}\""
      end
    end

    class BlankLine < ::Treetop::Runtime::SyntaxNode
      def inspect
        "[BlankLine]"
      end
    end
  end
end
