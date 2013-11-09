require 'sinatra/base'
# require 'sinatra-websocket'
require 'opal-sprockets'
# require 'thread_safe'

module ChatDemo
  class App < Sinatra::Base
    # set :sockets, ThreadSafe::Array.new

    helpers do
      def opal(template, options = {}, locals = {}, &block)
        render(:opal, template, options, locals, &block)
      end

      # def sockets
      #   settings.sockets
      # end
      #
      # def chat request
      #   request.websocket do |ws|
      #     ws.onopen do
      #       ws.send({handle: 'server', text: 'welcome!'}.to_json)
      #       sockets << ws
      #     end
      #
      #     ws.onmessage do |msg|
      #       EM.next_tick { sockets.each{|s| s.send(msg) } }
      #     end
      #
      #     ws.onclose do
      #       warn('wetbsocket closed')
      #       sockets.delete(ws)
      #     end
      #   end
      # end
    end

    get '/' do
      haml :index
      # if request.websocket?
      #   chat(request)
      # else
      # end
    end
  end
end
