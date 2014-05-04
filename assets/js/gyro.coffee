#= require jquery
#= require socket.io
#= require gyrojs

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

  socket.on 'gotFrames', (frames)->
    $("#stillFrame").css 'background-image', "url('#{frames[0]?.src}')"
    #$("#time").text new Date(frames[0]?.time).toLocaleString()
    a.frames = frames

  a.readyForNext = true

  currentFrame = 1

  gyro.startTracking (o) ->
    if a.readyForNext
      #if Math.abs(o.alpha) > 45
        #val = o.y
      #else
        #val = o.x
      val = o.x
      if val > 0
        if ++currentFrame >= a.frames.length
          currentFrame = 0
      if val < 0
        if --currentFrame == -1
          currentFrame = a.frames.length
      $("#time").html "#{o.x}<br>#{o.y}"
      if Math.abs(val) > 1
        a.delay = (7 / Math.abs(val)) * 500
        playFrame a.frames[currentFrame], ->
          a.readyForNext = true



playFrames = (frames) ->
  time = 60*60*1000
  a.delay = time / a.frames.length
  $("#stillFrame").css 'background-image', "url('#{frames[0]?.src}')"
  #$("#time").text new Date(frames[0]?.time).toLocaleString()
  playFrame frames[currentFrame], ->
    if ++currentFrame < frames.length
      playFrames frames
    else
      window.location = window.location.pathname

playFrame = (frame, next) ->
  setTimeout ->
    image = new Image()
    image.onload = frameLoaded
    image.src = frame.src
    image.alt = new Date(frame.time).toLocaleString()
    next()
  , a.delay

frameLoaded = (img) ->
  $("#stillFrame").css 'background-image', "url('#{img.srcElement.src}')"
  #$("#time").text img.srcElement.alt
