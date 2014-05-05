
#= require jquery
# =require socket.io

@a = @a || {}
a = @a

video = ''

recording = false

$(window).ready ->

  # set up the socket.io and OSC
  socket = io.connect() 
  a.socket = socket
  a.delay = 1000

  socket.on "connection", (msg) ->
    console.log "connected"
    socket.emit "hello", "world"

  socket.on 'latestFront', playFrame
  socket.on 'gotFrames', playFrames
  socket.on 'gotUserFrames', playUserFrames

  $("[name='username']").unbind 'submit'
  $("[name='username']").submit (e)->
    e.preventDefault()
    false

  $("[name='username']").keypress (e)->
    setTimeout ->
      val = $("[name='username']").val()
      if val.length > 0 
        $(".after").text 'your link:'
      else
        $(".after").text 'after making a username you can go to'
      $(".mylink").attr 'href', "/fuckitshipit/#{val}"
      $(".mylink").text "art72.org/fuckitshipit/#{val}"
    , 10

  $(".getTime").click ->
    currentUserFrame = 0
    socket.emit 'getUserTime', a.username, $("[name='date']").val(), $("[name='time']").val()

  $("button.record").click ->
    if $("[name='username']").val() < 1
      $("[name='username']").parents('.form-group').addClass("has-error has-feedback")
      $("[name='username']").parents('.form-group').find('label').text "you need a username"
      $("[name='username']").focus()
    if recording
      $("button.record").text 'record'
      $("button.record").addClass 'btn-danger'
      $("button.record").removeClass 'btn-success'
    else
      $("button.record").text 'stop recording'
      $("button.record").removeClass 'btn-danger'
      $("button.record").addClass 'btn-success'
    recording = !recording

  if a.playback
    socket.emit 'getUser', a.username
    #socket.emit 'getFrames'
  else
    socket.emit 'getLatest'
    video = document.querySelector("#video")
    navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia || navigator.oGetUserMedia;
    
    if (navigator.getUserMedia)
      navigator.getUserMedia({video: true}, handleVideo, videoError);

handleVideo = (stream) ->
  $(".disabled").removeClass 'disabled'
  video.src = window.URL.createObjectURL(stream)
  drawStill()

drawStill = ->
  setTimeout ->
    v = document.getElementById('video')
    canvas = document.getElementById('canvas')
    context = canvas.getContext('2d')
    context.drawImage(v,0,0,canvas.width,canvas.height)
    uri = canvas.toDataURL("image/png")
    $("#userFrame").css 'background-image', "url('#{uri}')"
    if recording
      a.socket.emit 'userImage', $("[name='username']").val(), uri
    drawStill()
  , 1000

videoError = (err) ->
  console.log err


currentFrame = 1
playFrames = (frames) ->
  a.frames = frames
  #time = 60*60*1000
  #a.delay = time / a.frames.length
  $("#frontFrame").css 'background-image', "url('#{frames[0]?.src}')"
  $("#time").text new Date(frames[0]?.time).toLocaleString()
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
    next() if next?
  , a.delay

frameLoaded = (img) ->
  $("#frontFrame").css 'background-image', "url('#{img.srcElement.src}')"
  $("#time").text img.srcElement.alt
  $(".front-time").text img.srcElement.alt

currentUserFrame = 1
playUserFrames = (userFrames) ->
  a.userFrames = userFrames
  a.delay = 1000##time / a.userFrames
  $("#frontUseruserFrame").css 'background-image', "url('#{a.userFrames[0].src}')"
  $("#time").text new Date(a.userFrames[0]?.time).toLocaleString()
  playUserFrame a.userFrames[currentUserFrame], ->
    if ++currentUserFrame < a.userFrames.length
      playUserFrames a.userFrames
    else
      currentUserFrame = 0

playUserFrame = (userFrame, next) ->
  setTimeout ->
    a.socket.emit 'getNearest', userFrame.time
    image = new Image()
    image.onload = userFrameLoaded
    image.src = userFrame.src
    image.alt = new Date(userFrame.time).toLocaleString()
    next() if next?
  , a.delay

userFrameLoaded = (img) ->
  $("#userFrame").css 'background-image', "url('#{img.srcElement.src}')"
  $("#time").text img.srcElement.alt
  $(".user-time").text img.srcElement.alt
