require 'sinatra/base'
require 'opal-sprockets'

module ChatDemo
  class App < Sinatra::Base
    helpers do
      def scheme
        @scheme ||= ENV['RACK_ENV'] == 'production' ? 'wss://' : 'ws://'
      end
    end

    get '/' do
      haml :index
    end
  end
end
