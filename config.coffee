exports.loggerFormat = "dev"
exports.useErrorHandler = true
exports.enableEmailLogin = true
exports.mongodb = process.env.MONGO_DB || "mongodb://localhost/front-streamer"
exports.sessionSecret = "super duper bowls"

exports.s3 =
  key: process.env.S3KEY
  secret: process.env.S3SECRET
  bucket: process.env.S3BUCKET || 'front-streamer'

