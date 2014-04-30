
config    = require './config'
mongoose  = require 'mongoose'
knox      = require 'knox'

Schema    = mongoose.Schema
Mixed     = Schema.Types.Mixed
s3Client  = knox.createClient config.s3

Frame = new Schema
  time:
    type: Date
    default: new Date()
  src: String

Frame.static "saveImage", (buffer, next) ->
  me = new exports.Frame time: new Date()
  folder = "#{me.time.getFullYear()}-#{me.time.getMonth()}-#{me.time.getDate()}"
  path = "#{folder}/#{me.time.toJSON()}.png"
  me.src = "https://s3.amazonaws.com/#{config.s3.bucket}/#{path}"
  headers = 
    'x-amz-acl': 'public-read'
    'Content-Length': buffer.length
    'Content-Type': 'image/png'
  s3Client.putBuffer buffer, path, headers, (err, res) ->
    if err?
      return console.log err
    me.save next

exports.Frame = mongoose.model 'Frame', Frame
