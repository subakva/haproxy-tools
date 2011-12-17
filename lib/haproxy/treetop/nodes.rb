module HAProxy::Treetop
  extend self

  module StrippedTextContent
    def content
      self.text_value.strip
    end
  end

  class Whitespace < Treetop::Runtime::SyntaxNode
    def content; self.text_value; end
  end
  class LineBreak < Treetop::Runtime::SyntaxNode; end
  class Char < Treetop::Runtime::SyntaxNode; include StrippedTextContent; end
  class Keyword < Treetop::Runtime::SyntaxNode; include StrippedTextContent; end
  class Value < Treetop::Runtime::SyntaxNode; include StrippedTextContent; end
  class CommentText < Treetop::Runtime::SyntaxNode; include StrippedTextContent; end
  class BlankLine < Treetop::Runtime::SyntaxNode; include StrippedTextContent; end
  class ConfigLine < Treetop::Runtime::SyntaxNode; include StrippedTextContent; end
  class CommentLine < Treetop::Runtime::SyntaxNode; include StrippedTextContent; end

  class ServerLine < Treetop::Runtime::SyntaxNode
    include StrippedTextContent
    def name
      nil
    end

    def address
      nil
    end
  end

  class GlobalHeader < Treetop::Runtime::SyntaxNode; include StrippedTextContent; end
  class DefaultsHeader < Treetop::Runtime::SyntaxNode; include StrippedTextContent; end
  class FrontendHeader < Treetop::Runtime::SyntaxNode; include StrippedTextContent; end
  class BackendHeader < Treetop::Runtime::SyntaxNode; include StrippedTextContent; end

  class ConfigBlock < Treetop::Runtime::SyntaxNode; end

  class DefaultsSection < Treetop::Runtime::SyntaxNode; end
  class GlobalSection < Treetop::Runtime::SyntaxNode; end
  class FrontendSection < Treetop::Runtime::SyntaxNode; end

  class BackendSection < Treetop::Runtime::SyntaxNode
    def servers
       self.config_block.elements.select {|e| e.class == ServerLine}
    end

    def config_block
      self.elements.select {|e| e.class == ConfigBlock}
    end
  end

  class ConfigurationFile < Treetop::Runtime::SyntaxNode
    def global
      self.elements.select {|e| e.class == GlobalSection}.first
    end

    def defaults
      self.elements.select {|e| e.class == DefaultsSection}.first
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
    print " [#{e.text_value}]" if e.class == Treetop::Runtime::SyntaxNode
    print " [#{e.content}]" if e.respond_to? :content
    puts
    e.elements.each do |child|
      print_node(child, depth + 1, options)
    end if depth < options[:max_depth] && e.elements && !e.respond_to?(:content)
  end
end

