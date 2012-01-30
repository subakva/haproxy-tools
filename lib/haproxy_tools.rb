require 'polyglot'
require 'treetop'
require 'haproxy/treetop/config'
require 'haproxy/config'
require 'haproxy/renderer'
require 'haproxy/parser'

module HAProxy
  VERSION = File.read(File.join(File.dirname(__FILE__), '..', 'VERSION')).strip
end

