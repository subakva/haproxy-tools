module HAProxy::Treetop
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

