module Miller where

import Config exposing (..)

import Effects exposing (Effects, Never)
import Task

import Html exposing (..)
import Html.Attributes exposing (..)
--import Html.Events as Html
import Bootstrap.Html exposing (container_, containerFluid_, row_)
import Window

import Json.Encode as Encode

import List exposing (head, length, map, take, drop, tail, filter, member
                     , repeat, unzip, map2, append)

import List.Extra exposing ((!!))

import MillerColumn
import MillerColumn exposing (MillerColumn)

import Debug exposing (..)

-----------
-- MODEL --
-----------

type alias Model = Miller


type alias ID = Int


-- Miller is a zipper list of Miller columns
type alias Miller =
  { millerColumns : List (ID, List (String, List String), MillerColumn)
  , nextID : ID
  , height : Int
  }


init : String -> Int -> (Model, Effects Action)
init key' numColumns =
  let
    (mills, millerColumnsFx) =
      unzip <| repeat numColumns (MillerColumn.init [] key')

    insertQuery (x, y) = (x, [], y)
    millerColumns' = map2 (,) [0..(numColumns - 1)] mills
                     |> map insertQuery

    model = { millerColumns = millerColumns'
            , nextID = numColumns
            , height = 100
            }

    mcFx = map2 Effects.map (map SubMsg [0..(numColumns - 1)]) millerColumnsFx
  in
    ( model
    , Effects.batch
        [ Effects.batch mcFx
        , sendInitial
        ]
    )

------------
-- UPDATE --
------------

type Action
  = SubMsg ID MillerColumn.Action
  | UpdateSize (Int, Int)
  | NoOp


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    SubMsg msgId msg ->
      let
        subUpdate ((id, q, mc) as entry) =
          if id == msgId then
            let
              (newMc, fx) = MillerColumn.update msg mc
            in
              ( (id, q, newMc)
              , Effects.map (SubMsg id) fx
              )
          else
            (entry, Effects.none)

        (newMcs, fxList) =
          model.millerColumns
            |> map subUpdate
            |> unzip
      in
        ( { model | millerColumns = newMcs }
        , Effects.batch fxList
        )
      -- let
      --   subUpdate ((id, mc) as entry) =
      --     if id == msgId then
      --       let
      --         q = if id > 0 then
      --               let
      --                 enc i = mc.values !! i |> Maybe.withDefault "" |> Encode.string
      --                 values = map enc mc.selected
      --               in
      --                 model.millerColumns !! (id - 1)
      --                 |> Maybe.withDefault (0, MillerColumn "" [] [] [])
      --                 |> snd |> .query
      --                 |> append [(mc.key, Encode.list values)]
      --             else
      --               mc.query

      --         (newMc, fx) = MillerColumn.update action { mc | query = q }
      --       in
      --         ( (id, newMc)
      --         , Effects.map (Modify id) fx
      --         )
      --     else
      --       (entry, Effects.none)

      --   (newMcList, fxList) =
      --     model.millerColumns
      --       |> map subUpdate
      --       |> unzip
      -- in
      --   ( { model | millerColumns = newMcList }
      --   , Effects.batch fxList
      --   )

    UpdateSize (h, w) ->
      ( { model | height = h }, Effects.none)

    NoOp -> (model, Effects.none)


----------
-- VIEW --
----------

-- (=>) : a -> b -> (a, b)
-- (=>) = (,)

(=>) : a -> b -> (a,b)
(=>) = (,)


view : Signal.Address Action -> Model -> Html
view address model =
  containerFluid_
  [ div [] [stylesheet Config.stylesheet]
  , row_
      (map (viewMillerColumn address) model.millerColumns)
  ]


viewMillerColumn : Signal.Address Action -> (ID, List (String, List String), MillerColumn) -> Html
viewMillerColumn address (id, query, model) =
  MillerColumn.view (Signal.forwardTo address (SubMsg id)) model


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
