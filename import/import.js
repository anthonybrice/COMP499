// import.js

"use strict"

const MongoClient = require("mongodb").MongoClient
    , fs = require("fs")
    , dir = require("node-dir")
    , mm = require("musicmetadata")

    , url = "mongodb://localhost:27017/music"
    , musicDir = process.cwd() + "/music"

MongoClient.connect(url, (err, db) => {
  if (err) throw err
  db.collection("songs", (err, coll) => {
    if (err) throw err

    addMusicFiles(db, coll)
  })
})

function addMusicFiles(db, coll) {
  dir.files(musicDir, (err, files) => {
    if (err) throw err
    files = files.filter(file => /.*mp3|.*flac/.test(file))
    let count = files.length
    console.log(count)

    files.forEach(file => {
      mm(fs.createReadStream(file), (err, metadata) => {
        if (err) throw err

        coll.updateOne( metadata
                      , metadata
                      , { upsert: true }
                      , (err) => {
                        if (err) throw err
                        if (--count === 0) db.close()
                      }
                      )
      })
    })
  })
}
