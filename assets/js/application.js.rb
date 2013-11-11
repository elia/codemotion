require 'opal'
require 'browser'
require 'browser/socket'
require 'browser/storage'


# `window.onerror = function(e){console.error(e);}`

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
end

end; end; end

class Chat
  COLORS = %w[red green blue orange]

  def initialize element
    @element  = element
    @scheme   = element.get('data-scheme')
    @messages = element.at_css('.messages')
    @message  = element.at_css('.message')
    @host     = $document.location.host
    @message_input = message.at_css('input.text')

    socket.on :open do |message|
      self << {handle: 'server', text: "Welcome #{handle}!"}
    end

    socket.on :message do |message|
      `console.log(#{message});`
      data = JSON.parse(message.data);
      `console.log(#{data});`
      self << data
    end

    message.on :submit do |event|
      event.stop!
      text = message_input.value
      socket.write({handle: handle, text: text}.to_json)
      message_input.value = ''
    end
  end

  attr_reader :element, :scheme, :messages, :message, :host, :message_input, :scheme

  def colors
    @colors ||= COLORS
    @colors = COLORS if @colors.empty?
    @colors
  end

  def handle_color handle
    @handle_colors ||= {}
    @handle_colors[handle] ||= colors.pop
  end

  def << message
    handle = message[:handle].to_s
    body   = message[:text].to_s
    color  = handle_color(handle)

    DOM {
      div(class: 'posted-message') {
        time     Time.now.strftime('[%H:%M:%S]')
        author   handle, style: "color: #{color}"
        span.body body
      }
    }.append_to(messages)

    messages.scroll.to y: messages.size.height
  end

  def handle
    storage[:handle] ||= prompt('Please select an handle:')
  end

  def storage
    @storage ||= $window.storage(:chat)
  end

  def socket
    @socket ||= Browser::Socket.new scheme + host + '/'
  end
end

element = $document.body.at_css('.chat-app')
chat = Chat.new(element)


# $("#input-form").on("submit", function(event) {
#   event.preventDefault();
#   var handle = $("#input-handle")[0].value;
#   var text   = $("#input-text")[0].value;
#   ws.send(JSON.stringify({ handle: handle, text: text }));
#   $("#input-text")[0].value = "";
# });
#
#
# # var uri      = scheme + window.document.location.host + "/";
# # var ws       = new WebSocket(uri);
# # ws.onmessage = function(message) {
# #   var data = JSON.parse(message.data);
# #   $("#chat-text").append("<div class='panel panel-default'><div class='panel-heading'>" + data.handle + "</div><div class='panel-body'>" + data.text + "</div></div>");
# #   $("#chat-text").stop().animate({
# #     scrollTop: $('#chat-text')[0].scrollHeight
# #   }, 800);
# # };
# #
# # $("#input-form").on("submit", function(event) {
# #   event.preventDefault();
# #   var handle = $("#input-handle")[0].value;
# #   var text   = $("#input-text")[0].value;
# #   ws.send(JSON.stringify({ handle: handle, text: text }));
# #   $("#input-text")[0].value = "";
# # });
