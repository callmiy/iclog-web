module Observation.List.App
    exposing
        ( Model
        , Msg(..)
        , update
        , view
        , init
        )

import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Observation.Channel as ObservationChannel exposing (PaginatedObservations)
import Observation.Types exposing (Observation)
import Date.Format as DateFormat
import Css


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style


type alias Model =
    ()


init : Model
init =
    ()


type Msg
    = NoOp


type alias FromParent =
    { observations : PaginatedObservations
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []


view : FromParent -> Model -> Html Msg
view ({ observations } as fromParent) model =
    Html.div [] [ viewTable observations.entries ]


viewTable : List Observation -> Html Msg
viewTable observations =
    Html.div
        [ Attr.class "iw" ]
        [ Html.table
            [ Attr.class "ck", Attr.attribute "data-sort" "table" ]
            [ viewHeader
            , Html.tbody [] (List.map viewObservationRow observations)
            ]
        ]


viewHeader : Html Msg
viewHeader =
    Html.thead
        []
        [ Html.tr
            []
            [ Html.th
                [ Attr.class "header headerSortDown" ]
                [ Html.input
                    [ Attr.class "bpa"
                    , Attr.id "selectAll"
                    , Attr.type_ "checkbox"
                    ]
                    []
                ]
            , Html.th
                [ Attr.class "header" ]
                [ Html.text "Title" ]
            , Html.th
                [ Attr.class "header" ]
                [ Html.text "Comment" ]
            , Html.th
                [ Attr.class "header" ]
                [ Html.text "Created On" ]
            ]
        ]


viewObservationRow : Observation -> Html Msg
viewObservationRow { comment, insertedAt, meta } =
    Html.tr
        [ styles [ Css.cursor Css.pointer ] ]
        [ Html.td []
            [ Html.input
                [ Attr.class "bpb", Attr.type_ "checkbox" ]
                []
            ]
        , Html.td []
            [ Html.div
                []
                [ Html.text meta.title ]
            ]
        , Html.td
            []
            [ Html.div
                []
                [ Html.text comment ]
            ]
        , Html.td
            []
            [ Html.text <| DateFormat.format "%a %d/%b/%y" insertedAt ]
        ]
