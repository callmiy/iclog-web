module Views.CreationSuccessAlert exposing (view)

import Html exposing (Html, Attribute)
import Html.Events exposing (onClick)
import Html.Attributes as Attr
import Css
import Router exposing (Route)
import Utils exposing ((<=>))


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style


type alias CreationSuccessAlert msg =
    { id : Maybe String
    , route : Maybe (String -> Route)
    , label : String
    , dismissMsg : Maybe msg
    }


view :
    CreationSuccessAlert msg
    -> Html msg
view { id, route, label, dismissMsg } =
    case id of
        Nothing ->
            Html.text ""

        Just id_ ->
            let
                ( action, dom, text ) =
                    case ( route, dismissMsg ) of
                        ( Just route_, _ ) ->
                            (<=>)
                                [ Router.href <| route_ id_ ]
                                (Just Html.a)
                                "Success! Click here for further details."

                        ( _, Just msg ) ->
                            (<=>)
                                [ onClick msg ]
                                (Just Html.div)
                                "Success! Click to dismiss."

                        _ ->
                            (<=>) [] Nothing ""

                attributes =
                    [ Attr.id ("new-" ++ label ++ "-created-info")
                    , Attr.class
                        ("new-" ++ label ++ "-created-info alert alert-success")
                    , Attr.attribute "role" "alert"
                    , styles [ Css.display Css.block ]
                    ]
                        ++ action
            in
                case dom of
                    Nothing ->
                        Html.text ""

                    Just dom_ ->
                        dom_ attributes [ Html.text text ]
