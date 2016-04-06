module Miller where

import Config exposing (..)

import Effects exposing (Effects, Never)
import Task

import Html exposing (..)
import Html.Attributes exposing (..)
--import Html.Events as Html
import Bootstrap.Html exposing (container_, containerFluid_, row_)
import Window

import Json.Decode as Decode
import Json.Decode exposing ((:=))
import Json.Encode as Encode

import List exposing (head, length, map, take, drop, tail, filter, member)

import MillerColumn
import MillerColumn exposing (MillerColumn)


-----------
-- MODEL --
-----------

type alias Model = Miller


-- Miller is a zipper list of Miller columns
type alias Miller =
  { focus : List MillerColumn
  , breadcrumbs : List MillerColumn
  , coll : String
  , height : Int
  }


init : String -> String -> Int -> (Model, Effects Action)
init coll' key' numColumns =
  let
    --columnList =
    (focus', focusFx) = MillerColumn.init coll' (Encode.object []) key'
    model = { focus = [focus']
            , breadcrumbs = []
            , coll = coll'
            , height = 100
            }
  in ( model
     , Effects.batch
         [ Effects.map Focus focusFx
         , sendInitial
         ]
     )

------------
-- UPDATE --
------------

type Action
  = Focus MillerColumn.Action
  | UpdateSize (Int, Int)
  --| SubMsg Int MillerColumn.Action
  --| UpdateSelected Int
  --| InsertColumn
  | NoOp


update : Action -> Model -> (Model, Effects Action)
update action model =
  let
    focus = Maybe.withDefault (MillerColumn "" [] [] "")
              <| head model.focus
    select = focus.selected

    aft = Maybe.withDefault [] <| tail model.focus
  in
    case action of
      Focus action ->
        let
          (focus', fx) = MillerColumn.update action focus
        in
          ( { model | focus = [focus'] }
          , Effects.map Focus fx
          )

      UpdateSize (h, w) ->
        ( { model | height = h }, Effects.none)

      NoOp -> (model, Effects.none)

----------
-- VIEW --
----------

(=>) : a -> b -> (a, b)
(=>) = (,)


view : Signal.Address Action -> Model -> Html
view address model =
  let
    focus =
      Maybe.withDefault (MillerColumn "" [] [] "") <| head model.focus

    styles =
      [ stylesheet <| Config.stylesheet ]

  in
    containerFluid_
    [ div [] styles
    , row_
        (List.map (elementView address) <| (List.reverse model.breadcrumbs) ++ model.focus)
    -- , select [ attribute "multiple" "multiple"
    --          , attribute "size" <| toString (40)
    --          ]
    --     <| map (\v -> option [] [text v]) (focus.values)
    ]

elementView : Signal.Address Action -> MillerColumn -> Html
elementView address model =
  MillerColumn.view (Signal.forwardTo address Focus) model


stylesheet : String -> Html
stylesheet href =
  let
    tag = "link"
    attrs =
      [ attribute "rel"       "stylesheet"
      , attribute "property"  "stylesheet"
      , attribute "href"      href
      ]
    children = []
  in
    node tag attrs children


-------------
-- EFFECTS --
-------------

-- getValues : String -> String -> Effects Action
-- getValues coll key =
--   let
--     valuesUrl =
--       Http.url (Config.db ++ coll ++ "/_aggrs/group")
--             [ "avars" => ("{'key': '$" ++ key ++ "'}")
--             , "hal" => "c"
--             ]

--     decodeValues =
--       Decode.at [ "_embedded", "rh:result" ] <| Decode.list decodeValue

--     decodeValue =
--       Decode.at [ "_id" ] Decode.string
--   in
--     Http.get decodeValues valuesUrl
--       |> flip Task.onError (always (Task.succeed [""]))
--       |> Task.map GetValues
--       |> Effects.task


appStartMailbox : Signal.Mailbox ()
appStartMailbox =
  Signal.mailbox ()


resizes : Signal Action
resizes =
  Signal.map UpdateSize Window.dimensions


firstResize : Signal Action
firstResize =
  Signal.sampleOn appStartMailbox.signal resizes


sendInitial : Effects Action
sendInitial =
  Signal.send appStartMailbox.address ()
    |> Task.map (always NoOp)
    |> Effects.task


parseArgs : Model -> Encode.Value
parseArgs model =
  Encode.object [("foo", Encode.string "bar")]
