module Observation.View exposing (view)

import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Html.Events exposing (onClick)
import Css
import Observation.App as Model exposing (Model, Msg(..), App(..), Showing(..))
import Observation.New.App as New
import Observation.List.App as ListApp


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style


view : Model -> Html Msg
view ({ showing } as model) =
    Html.div
        [ styles [ Css.height (Css.pct 100) ] ]
        [ Html.div
            [ styles
                [ Css.marginBottom (Css.rem 0.75)
                , Css.fontSize (Css.rem 1.3)
                ]
            ]
            [ changeViewIcon "New" "fa fa-plus-square" (ChangeDisplay NewApp)
            , changeViewIcon "List" "fa fa-list" (ChangeDisplay ListApp_)
            ]
        , viewPage model
        ]


viewPage : Model -> Html Msg
viewPage ({ showing } as model) =
    case showing of
        ShowNew subModel ->
            New.view subModel |> Html.map NewMsg

        ShowList subModel ->
            ListApp.view
                { observations = model.observations }
                subModel
                |> Html.map ListMsg


changeViewIcon : String -> String -> Msg -> Html Msg
changeViewIcon title classNames msg =
    Html.i
        [ Attr.class classNames

        -- , Attr.attribute "data-toggle" "tooltip"
        -- , Attr.attribute "data-placement" "bottom"
        , Attr.attribute "title" title
        , Attr.attribute "aria-hidden" "true"
        , onClick msg
        , styles
            [ Css.cursor Css.pointer
            , Css.paddingLeft (Css.px 0)
            , Css.display Css.inline
            , Css.marginRight (Css.rem 0.75)
            ]
        ]
        []
