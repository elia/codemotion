require 'sinatra/base'
require 'opal-sprockets'

module ChatDemo
  class App < Sinatra::Base
    helpers do
      def scheme
        @scheme ||= ENV['RACK_ENV'] == "production" ? "wss://" : "ws://"
      end

      def opal(template, options = {}, locals = {}, &block)
        render(:opal, template, options, locals, &block)
      end

    end

    get "/" do
      haml :"index.html"
    end
  end
end
