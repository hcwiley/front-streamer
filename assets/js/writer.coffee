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

  video = document.querySelector("#video")
  navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia || navigator.oGetUserMedia;
  
  if (navigator.getUserMedia)
    navigator.getUserMedia({video: true}, handleVideo, videoError);
  else
    $("#stillFrame").html "<h1 style='color: #c44;'>please use firefox or chrome</h1>"
    $("#stillFrame").css 'background-image', 'none'

handleVideo = (stream) ->
  video.src = window.URL.createObjectURL(stream)
  drawStill()

drawStill = ->
  setTimeout ->
    v = document.getElementById('video')
    canvas = document.getElementById('canvas')
    context = canvas.getContext('2d')
    context.drawImage(v,0,0,canvas.width,canvas.height)
    uri = canvas.toDataURL("image/png")
    $("#stillFrame").css 'background-image', "url('#{uri}')"
    if $("#record")[0].checked
      a.socket.emit 'image', uri
    drawStill()
  , 1000

videoError = (err) ->
  console.log err
