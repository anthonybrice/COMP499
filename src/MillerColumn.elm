module MillerColumn where

import Effects exposing (Effects, Never)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Html
import Bootstrap.Html exposing (container_, containerFluid_, colXs_)

import Json.Decode as Decode
import Json.Decode exposing ((:=))
import Json.Encode as Encode
import Json.Encode exposing (Value)

import Task
import Http

import List exposing (..)
import List.Extra exposing ((!!))

import Config

--import Debug


type alias Model = MillerColumn


type alias MillerColumn =
  { key : String
  , selected : List Int
  , values : List String
  , keys : List String
  }


init : List (String, Value) -> String -> (Model, Effects Action)
init query' key' =
  ( { key = key', selected = [], values = [], keys = [] }
  , getKeys query'
  )


type Action
  = NewValues (List String)
  | NewKeys (List String)
  | UpdateValues (List (String, List String))
  | UpdateKey Int


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    NewValues values' ->
      ( { model | values = values', selected = [] }, Effects.none)

    NewKeys keys' ->
      ( { model | keys = keys' }
      , Effects.task <| Task.succeed <| UpdateKey 0
      )

    UpdateValues query ->
        (model, getValues query model.key)

    UpdateKey int ->
      let
        key' = Maybe.withDefault "" <| model.keys !! int
      in
        ( { model | key = key' }, Effects.none)


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
    [ select [newKeyEvent] <| map (\v -> option [] [text v]) model.keys
    , select [ attribute "multiple" "multiple"
             , attribute "size" <| toString (40)
             ]
        <| map (\v -> option [] [text v]) model.values
    ]


getValues : List (String, List String) -> String -> Effects Action
getValues query key =
  let
    --query' = Encode.object query |> Encode.encode 0
    query' =
      map (\ (k, v) -> (k, map Encode.string v |> Encode.list)) query
        |> Encode.object
        |> Encode.encode 0
    valuesUrl =
      Http.url (Config.coll ++ "_aggrs/group2")
            [ "avars" => ("{ key: { " ++ key ++ ": 1 },"
                            ++ " matchQuery: " ++ query' ++ ","
                            ++ " groupBy: '$" ++ key ++ "'}"
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

getKeys : List (String, Value) -> Effects Action
getKeys query =
  let
    query' = Encode.object query |> Encode.encode 0
    keysUrl =
      Http.url (Config.coll ++ "_aggrs/getKeys")
            [ "avars" => ("{ query: " ++ query' ++ " }")
            , "hal" => "c"
            ]

    decodeKeys =
      Decode.at [ "_embedded", "rh:result" ] <| Decode.list decodeKey

    decodeKey =
      Decode.at [ "_id" ] Decode.string
  in
    Http.get decodeKeys keysUrl
      |> flip Task.onError (always (Task.succeed [""]))
      |> Task.map NewKeys
      |> Effects.task
