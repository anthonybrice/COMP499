module Config where

webapp : String
webapp = "//localhost:8000/"

api : String
api = "//localhost:8080/api/"

db : String
db = api ++ "music/"

stylesheet : String
stylesheet = webapp ++ "static/css/app.min.css"
