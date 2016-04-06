module MillerColumn where

import Effects exposing (Effects, Never)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Html
import Bootstrap.Html exposing (container_, containerFluid_, colXs_)

import Json.Decode as Decode
import Json.Decode exposing ((:=))
import Json.Encode as Encode

import Task
import Http

import List.Extra exposing ((!!))

import Config

import Debug


keys : List String
keys = [ "albumartist"
       , "album"
       , "year"
       ]


type alias Model = MillerColumn


type alias MillerColumn =
  { key : String
  , selected : List Int
  , values : List String
  , coll : String
  }


init : String -> Encode.Value -> String -> (Model, Effects Action)
init coll' query key' =
  ( { key = key', selected = [], values = [], coll = coll' }
  , getValues coll' query key'
  )


type Action
  = NewValues (List String)
  | UpdateValues
  | UpdateKey Int


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    NewValues values' ->
      ( { model | values = values', selected = [] }, Effects.none)

    UpdateValues ->
      let
        query = Encode.object []
      in
        (model, getValues model.coll query model.key)

    UpdateKey int ->
      let
        key' = Maybe.withDefault "" <| keys !! int
      in
        ( { model | key = key' }, Effects.task <| Task.succeed UpdateValues)


(=>) : a -> b -> (a, b)
(=>) = (,)


view : Signal.Address Action -> Model -> Html
view address model =
  let
    newKeyEvent =
      Html.on "change" decodeChange
      (Signal.message address << UpdateKey)

    decodeChange =
      Decode.at ["target", "selectedIndex"] Decode.int
  in
    colXs_ 1
    [ select [newKeyEvent] <| List.map (\v -> option [] [text v]) keys
    , select [ attribute "multiple" "multiple"
             , attribute "size" <| toString (40)
             ]
        <| List.map (\v -> option [] [text v]) (model.values)
    ]


getValues : String -> Encode.Value -> String -> Effects Action
getValues coll query key =
  let
    valuesUrl =
      Http.url (Config.db ++ coll ++ "/_aggrs/group2")
            [ "avars" => ("{'key': '$" ++ key ++ "',"
                         ++ "'matchQuery': " ++ Encode.encode 0 query ++ "}"
                         )
            , "hal" => "c"
            ]

    decodeValues =
      Decode.at [ "_embedded", "rh:result" ] <| Decode.list decodeValue

    decodeValue =
      Decode.at [ "_id" ] Decode.string
  in
    Http.get decodeValues valuesUrl
      |> flip Task.onError (always (Task.succeed [""]))
      |> Task.map NewValues
      |> Effects.task
