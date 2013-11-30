require 'opal'
require 'opal-parser'
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


module NamedStorage
  def storage
    @storage ||= $window.storage(storage_name)
  end

  def save
    storage.save
  end
end

class Chat
  include NamedStorage

  def initialize element
    @element  = element
    @scheme   = element.get('data-scheme')
    @messages = element.at_css('.messages')
    @message  = element.at_css('form.message')
    @host     = $document.location.host
    @message_input = message.at_css('input.text')

    stored_messages.each {|m| display_message m}

    socket.on(:open) do |message|
      send_message :server, "#{handle} joined the chat."
    end

    socket.on(:message) do |message|
      data = JSON.parse(message.data)
      self << data
    end

    message.on :submit do |event|
      event.stop!
      text = message_input.value
      send_message handle, text
      message_input.value = ''
    end
  end

  def robot= robot
    @robot = robot
    robot.on_speak do |handle, text|
      send_message handle, text
    end
  end

  def robot
    @robot
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
    robot.new_message message[:handle], message[:text] if robot
    message[:time] = Time.now
    store_message message
    display_message message
  end

  def store_message message
    stored_messages << message
    save
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

  def storage_name
    :chat
  end

  def socket_url
    scheme + host + '/'
  end

  def socket
    @socket ||= Browser::Socket.new socket_url
  end
end

class Robot
  include NamedStorage
  attr :element, :code, :textarea, :submit, :handle

  def initialize element, chat
    @chat     = chat
    @handle   = "#{chat.handle} (bot)"
    @element  = element
    @textarea = element.at_css('textarea')
    @submit   = element.at_css('input')

    submit.on :click do |event|
      puts textarea.value
      eval(`document.getElementsByTagName('textarea')[0].value || ""`)
    end

    chat.robot = self
  end

  def eval(code)
    `eval(Opal.compile(#{ code }))`
  end

  def listen &block
    @listen = block
  end

  def new_message handle, text
    @listen.call(handle, text) if @listen
  end

  def speak message
    @on_speak.call(@handle, message) if @on_speak
  end

  def on_speak &block
    @on_speak = block
  end

  def storage_name
    :robot
  end
end

chat_element = $document.body.at_css('.chat-app')
robot_element = chat_element.at_css('.users')

$chat = Chat.new(chat_element)
$r = Robot.new(robot_element, $chat)


