# frozen_string_literal: true

module HAProxy
  module Treetop
    # Include this module to always strip whitespace from the text_value
    module StrippedTextContent
      def content
        text_value.strip
      end
    end

    class ProxyName < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    # Include this module if the node contains a config element.
    module ConfigBlockContainer
      def option_lines
        config_block.elements.select {|e| e.class == OptionLine}
      end

      def config_lines
        config_block.elements.select {|e| e.class == ConfigLine}
      end
    end

    # Include this module if the value is optional for the node.
    module OptionalValueElement
      def value
        elements.find {|e| e.class == Value}
      end
    end

    # Helper class for whitespace nodes
    class Whitespace < ::Treetop::Runtime::SyntaxNode
      def content
        text_value
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

    class Value < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class CommentText < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class CommentLine < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class BlankLine < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    # Helper class for config nodes
    class ConfigLine < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
      include OptionalValueElement

      def key
        keyword.content
      end

      def attribute
        value.content
      end
    end

    class OptionLine < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
      include OptionalValueElement
    end
  end
end
