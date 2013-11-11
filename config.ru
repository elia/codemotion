require 'bundler/setup'
Bundler.require

require './app'
require './chat_backend'
require 'opal/sprockets/server'

class Opal::Server::Index
  # Returns the html content for the root path. Supports ERB
  def html
    # @index_path ||= 'index.html'     if File.exist? 'index.html'
    # @index_path ||= 'index.html.erb' if File.exist? 'index.html.erb'
    #
    if @index_path
      raise "index does not exist: #{@index_path}" unless File.exist?(@index_path)
      Tilt.new(@index_path).render(self)
    else
      ::ERB.new(SOURCE).result binding
    end
  end
end

Opal::Processor.source_map_enabled = false
Opal::Processor.const_missing_enabled = false
server = Opal::Server.new do |s|
  s.main = 'application'
  Dir['./assets/*'].each { |path| s.append_path path }
end
map(server.source_maps.prefix) { run server.source_maps } if server.source_map_enabled
map('/assets') { run server.sprockets }
use ChatDemo::ChatBackend
run ChatDemo::App
