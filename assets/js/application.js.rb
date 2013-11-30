require 'opal'
require 'browser'
require 'browser/socket'
require 'browser/storage'
require 'time'

module Kernel
  def prompt message
    `window.prompt(#{message}) || nil`
  end
end

module Browser; module DOM; class Element < Node
class Scroll
  def to(what)
    x   = what[:x] || self.x
    y   = what[:y] || self.y

    `#@native.scrollTop = #{y}`
    `#@native.scrollLeft = #{x}`

    self
  end

  def height
    `#@native.scrollHeight`
  end

  def width
    `#@native.scrollWidth`
  end
end
end; end; end

module Browser
class Socket

  def initialize(url, protocol = nil, &block)
    if native?(url)
      super(url)
    else
      p url
      super(protocol ? `new window.WebSocket(#{url.to_s}, #{protocol.to_n})` :
                       `new window.WebSocket(#{url.to_s})`)
    end

    if block.arity == 0
      instance_exec(&block)
    else
      block.call(self)
    end if block
  end

end
end

class Time
  def to_json
    "\"#{`self.toJSON()`}\""
  end
end

class Chat
  def initialize element
    @element  = element
    @scheme   = element.get('data-scheme')
    @messages = element.at_css('.messages')
    @message  = element.at_css('form.message')
    @host     = $document.location.host
    @message_input = message.at_css('input.text')

    stored_messages.each {|m| display_message m}

    socket.on(:open) { |message| send_message :server, "#{handle} joined the chat." }

    socket.on(:message) { |message| data = JSON.parse(message.data); self << data }

    message.on :submit do |event|
      event.stop!
      text = message_input.value
      send_message handle, text
      message_input.value = ''
    end
  end

  attr_reader :element, :scheme, :messages, :message, :host, :message_input, :scheme


  COLORS = %w[red green blue orange]

  def colors
    @colors ||= COLORS
    @colors = COLORS if @colors.empty?
    @colors
  end

  def handle_color handle
    @handle_colors ||= {}
    @handle_colors[handle] ||= colors.pop
  end


  def send_message handle, text
    socket.write({handle: handle, text: text}.to_json)
  end

  def << message
    message[:time] = Time.now
    store_message message
    display_message message
  end

  def store_message message
    stored_messages << message
    storage.save
  end

  def stored_messages
    storage[:messages] ||= []
  end

  def display_message message
    handle = message[:handle].to_s
    body   = message[:text].to_s
    now    = message[:time]
    p [:now, now]
    now    = `new Date(Date.parse(now))` if String === now
    color  = handle_color(handle)

    DOM {
      div(class: 'posted-message') {
        time     now.strftime('[%H:%M:%S]'), title: now.to_s
        author   handle, style: "color: #{color}"
        span.body body
      }
    }.append_to(messages)

    messages.scroll.to y: messages.scroll.height
  end

  def handle
    storage[:handle] ||= prompt('Please select an handle:')
  end

  def storage
    @storage ||= $window.storage(:chat)
  end

  def socket_url
    scheme + host + '/'
  end

  def socket
    @socket ||= Browser::Socket.new socket_url
  end
end

chat_element = $document.body.at_css('.chat-app')
$chat = Chat.new(chat_element)
