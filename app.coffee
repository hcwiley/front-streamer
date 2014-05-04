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

  socket.on 'getFrames', ->
    console.log 'get them frames'
    Frame.find {}, (err, frames) ->
      return console.log err  if err?
      console.log 'got dem frames'
      socket.emit 'gotFrames', frames


  socket.on 'image', (uri) ->
    base64Data = uri.replace(/^data:image\/png;base64,/,"")
    buffer = new Buffer(base64Data, 'base64')
    Frame.saveImage buffer

      
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
  res.render "index.jade"

app.get "/record", (req, res) ->
  if !req.session.auth?.match('so-good')
    return res.redirect '/login'
  res.render "writer.jade"

server.listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port")

