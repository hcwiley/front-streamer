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

  #socket.emit 'getFrames', ''

  socket.on 'gotFrames', playFrames

  playFrames a.frames


currentFrame = 0
playFrames = (frames) ->
  a.frames = frames
  time = 60*60*1000
  a.delay = time / a.frames.length
  playFrame frames[currentFrame], ->
    if ++currentFrame < frames.length
      playFrames frames
    else
      window.location = window.location.pathname

playFrame = (frame, next) ->
  setTimeout ->
    image = new Image()
    $(image).load frameLoaded
    image.src = frame.src
    image.alt = new Date(frame.time).toLocaleString()
    next()
  , a.delay

frameLoaded = (img) ->
  $("#stillFrame").css 'background-image', "url('#{img.target.src}')"
  $("#time").text img.target.alt
