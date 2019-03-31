# frozen_string_literal: true

module HAProxy
  module Treetop
    extend self

    def print_node(e, depth, options = nil)
      options ||= {}
      options = {max_depth: 2}.merge(options)

      puts if depth == 0
      print "--" * depth
      print " #{e.class.name.split("::").last}"
      print " [#{e.text_value}]" if e.class == ::Treetop::Runtime::SyntaxNode
      print " [#{e.content}]" if e.respond_to? :content
      puts
      if depth < options[:max_depth] && e.elements && !e.respond_to?(:content)
        e.elements.each do |child|
          print_node(child, depth + 1, options)
        end
      end
    end
  end
end
