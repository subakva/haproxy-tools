# frozen_string_literal: true

require "haproxy/treetop/shared"

module HAProxy
  module Treetop
    # Include this module if the node contains a service address element.
    module ServiceAddressContainer
      def service_address
        elements.find {|e| e.class == ServiceAddress }
      end

      def host
        service_address.host.text_value.strip
      end

      def port
        service_address.port.text_value.strip
      end
    end

    class Host < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class Port < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end

    class ServiceAddress < ::Treetop::Runtime::SyntaxNode
      include StrippedTextContent
    end
  end
end
