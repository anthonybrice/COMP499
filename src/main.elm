import Effects exposing (Never)
import Miller exposing (..)
import StartApp
import Task exposing (Task)
import Html exposing (Html)

app : StartApp.App Miller.Model
app =
  StartApp.start
    { init = init "songs" "albumartist" 2
    , update = update
    , view = view
    , inputs = [firstResize, resizes]
    }

main : Signal Html
main =
  app.html

port tasks : Signal (Task Never ())
port tasks =
  app.tasks

port title : String
port title =
  "Miller"
