require 'opal'
require 'browser'
`console.log(#{$document.body});`
chat     = $document.body.css('.chat-app')
`console.log(#{chat});`

scheme   = chat.get('data-scheme')
messages = chat.at_css('> .messages')
message  = chat.at_css('> .message')
host     = $document.location[:host]
message_input = message.at_css('> input.text')

socket = Browser::Socket.new scheme + host + '/'
socket.on :message do |message|
  log "Received #{message.data}"
  data = JSON.parse(message.data);
  DOM {
    div(class: 'panel panel-default') {
      div(class: 'panel-heading') { data[:handle] }
      div(class: 'panel-body') { data[:text] }
    }
  }.append_to(messages)

  messages.scroll.to y: messages.height
end

def handle
  @handle ||= $window.prompt('Please select an handle:')
end

message.on :submit do |event|
  event.stop!
  text = message_input.value
  socket.write(handle: handle, text: text)
  message_input.value = ''
end

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
