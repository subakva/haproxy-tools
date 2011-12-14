module HAProxy::Treetop
  class Char < Treetop::Runtime::SyntaxNode; end
  class CommentText < Treetop::Runtime::SyntaxNode; end
  class LineBreak < Treetop::Runtime::SyntaxNode; end
  class BlankLine < Treetop::Runtime::SyntaxNode; end
  class CommentLine < Treetop::Runtime::SyntaxNode; end
  class UnknownLine < Treetop::Runtime::SyntaxNode; end
  class ServerLine < Treetop::Runtime::SyntaxNode; end
  class GlobalSection < Treetop::Runtime::SyntaxNode; end
  class DefaultsSection < Treetop::Runtime::SyntaxNode; end

  class ConfigurationNode < Treetop::Runtime::SyntaxNode
  end

  class BackendNode < Treetop::Runtime::SyntaxNode
    def servers
      elements.select { |e| e.class == HAProxy::Treetop::ServerNode }
    end
  end

  class BlankLineNode < Treetop::Runtime::SyntaxNode; end

  class CommentNode < Treetop::Runtime::SyntaxNode
    def comment_text
      elements[1].text_value
    end
  end

  class AttributeNode < Treetop::Runtime::SyntaxNode
    def content
      self.text_value.strip
    end
  end

  class ServerNode < Treetop::Runtime::SyntaxNode
    def name
      elements[2].text_value
    end

    def address
      elements[4].text_value
    end

    def params
      elements[6].elements.select {|e| e.text_value.strip != ''}.map {|e| e.text_value.strip }
    end
  end
end

