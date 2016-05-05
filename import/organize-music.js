// organize music

"use strict"

const fs = require("fs")
    , path = require("path")
    , dir = require("node-dir")
    , mm = require("musicmetadata")

dir.files(process.cwd(), handleFiles)

const musicDir = process.cwd() + "/music"

function handleFiles(err, files) {
  if (err) throw err
  files = files.filter(file => /.*mp3|.*flac/.test(file))

  files.forEach(function (file) {
    mm(fs.createReadStream(file), function (err, metadata) {
      if (err) throw err

      const artistDir = musicDir + "/" + metadata.albumartist
          , albumDir = artistDir + "/" + metadata.album

      if (!fs.existsSync(artistDir)) fs.mkdirSync(artistDir)
      if (!fs.existsSync(albumDir)) fs.mkdirSync(albumDir)

      const newFile = albumDir + "/" + path.basename(file)

      fs.rename(file, newFile)
    })
  })
}
