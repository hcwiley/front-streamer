###
Module dependencies.
###
config            = require("./config")
express           = require("express")
lessMiddleware    = require('less-middleware')
path              = require("path")
http              = require("http")
socketIo          = require("socket.io")
path              = require('path')
pubDir            = path.join(__dirname, 'public')
child             = require('child_process')
fs                = require 'fs' 
mongoose          = require 'mongoose'

Frame = require('./models').Frame
UserFrame = require('./models').UserFrame

mongoose.connect config.mongodb

# create app, server, and web sockets
app = express()
server = http.createServer(app)
io = socketIo.listen(server)

# Make socket.io a little quieter
io.set "log level", 1

app.configure ->
  bootstrapPath = path.join(__dirname, 'assets','css', 'bootstrap')
  app.set "port", process.env.PORT or 3000
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  
  # use the connect assets middleware for Snockets sugar
  app.use require("connect-assets")()
  app.use express.favicon()
  app.use express.logger(config.loggerFormat)
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser(config.sessionSecret)
  app.use express.session(secret: "shhhh")
  app.use app.router
  app.use lessMiddleware
        src: path.join(__dirname,'assets','css')
        paths  : bootstrapPath
        dest: path.join(__dirname,'public','css')
        prefix: '/css'
        compress: true
  app.use express.static(pubDir)
  app.use express.errorHandler()  if config.useErrorHandler


io.sockets.on "connection",  (socket) ->

  socket?.emit "connection", "I am your father"

  socket.on "disconnect", ->
    console.log "disconnected"

  socket.on "lock", (data) ->
    console.log "lock!"

  socket.on 'getLatest', ->
    console.log 'get latest frames'
    Frame.find().sort('-time').limit(1).exec (err, frames) ->
      return console.log err  if err?
      console.log 'got dat frame'
      socket.emit 'latestFront', frames[0]

  socket.on 'getNearest', (time) ->
    console.log "get nearest frames: #{time}"
    Frame.find({time:{$lte:time}}).sort('-time').limit(1).exec (err, frames) ->
      return console.log err  if err?
      if frames.length > 0
        socket.emit 'latestFront', frames[0]

  socket.on 'getFrames', ->
    console.log 'get them frames'
    Frame.find({}).sort("time").exec (err, frames) ->
      return console.log err  if err?
      console.log 'got dem frames'
      socket.emit 'gotFrames', frames

  socket.on 'getUser', (username)->
    console.log "get them user frames: #{username}"
    UserFrame.find username:username, (err, frames) ->
      return console.log err  if err?
      socket.emit 'gotUserFrames', frames

  socket.on 'getUserTime', (username, date, time)->
    console.log "get them user frames: #{username}, #{date}, #{time}"
    time = new Date("2014-5-#{date} #{time}")
    UserFrame.find(username:username, time:{$gte:time} ).sort('time').exec (err, frames) ->
      return console.log err  if err?
      console.log 'got user time'
      socket.emit 'gotUserFrames', frames

  socket.on 'image', (uri) ->
    base64Data = uri.replace(/^data:image\/png;base64,/,"")
    buffer = new Buffer(base64Data, 'base64')
    Frame.saveImage buffer, (err, frame) ->
      io.sockets.emit 'latestFront', frame

  socket.on 'userImage', (username, uri) ->
    base64Data = uri.replace(/^data:image\/png;base64,/,"")
    buffer = new Buffer(base64Data, 'base64')
    UserFrame.saveImage username, buffer, (err, frame) ->
      console.log 'saved it'
      #io.sockets.emit 'latestFront', frame

      
# you need to be signed for this business!
app.all "/auth/login", (req, res) ->
  if process.env.NODE_ENV =='dev' || req.body.password?.match(process.env.STUDIO_PASSWORD)
    req.session['auth'] = 'so-good'
    return res.redirect('/record')
  return res.redirect '/login'

# UI routes
app.get "/login", (req, res) ->
  if process.env.NODE_ENV =='dev'
    req.session['auth'] = 'so-good'
    return res.redirect('/record')
  return res.render 'auth/login'


app.get "/", (req, res) ->
  Frame.find({}).sort("time").exec (err, frames) ->
    str = JSON.stringify(frames).replace(/&quot;/g,'\"')
    res.render "index.jade", frames: str

app.get "/gyro", (req, res) ->
  res.render "gyro.jade"

app.get "/fuckitshipit", (req, res) ->
  res.render "fuckit.jade"

app.get "/fuckitshipit/:username", (req, res) ->
  res.render "playback.jade", username:req.params.username

app.get "/record", (req, res) ->
  if !req.session.auth?.match('so-good')
    return res.redirect '/login'
  res.render "writer.jade"

server.listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")

