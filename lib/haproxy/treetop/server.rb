# frozen_string_literal: true

require "haproxy/treetop/shared"
require "haproxy/treetop/service_address"

module HAProxy
  module Treetop
    # Include this module if the node contains a server elements.
    module ServerContainer
      def servers
        config_block.elements.select {|e| e.class == ServerLine}
      end
    end

    # Helper class for server nodes
    class ServerLine < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
      include ServiceAddressContainer
      include OptionalValueElement

      def name
        server_name.content
      end
    end

    class ServerName < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end
  end
end
