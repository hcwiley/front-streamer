#= require jquery
# =require socket.io

@a = @a || {}
a = @a

video = ''

$(window).ready ->

  # set up the socket.io and OSC
  socket = io.connect() 
  a.socket = socket

  socket.on "connection", (msg) ->
    console.log "connected"
    socket.emit "hello", "world"

  socket.emit 'getFrames', ''

  socket.on 'gotFrames', playFrames


currentFrame = 0
playFrames = (frames) ->
  playFrame frames[currentFrame], ->
    if ++currentFrame < frames.length
      playFrames frames



playFrame = (frame, next) ->
  setTimeout ->
    $("#stillFrame").attr 'src', frame.src
    next()
  , 1000

