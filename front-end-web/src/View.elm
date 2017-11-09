module View exposing (view)

import Html exposing (Html, div, text, nav, button, span, a, form, input, ul, li, hr, h2, h6)
import Html.Attributes as Attr exposing (class, type_, href, id, placeholder)
import Model exposing (Model, Msg)
import Page exposing (Page)
import Observation.View as ObservationView


view : Model -> Html Msg
view ({ pageState } as model) =
    let
        page =
            Page.getPage pageState
    in
        div [ class "dh" ]
            [ navigation
            , div
                [ class "et bmj" ]
                [ div
                    -- we display page headers in class "bls blu"
                    [ class "bls" ]
                    [ div
                        [ class "blt global-page-titles" ]
                        [ h6
                            [ class "blv global-title" ]
                            [ text "Observables" ]
                        , h2
                            [ class "blu page-title" ]
                            [ text "Observations" ]
                        ]
                    , div
                        [ class "lf blw" ]
                        [ div
                            [ class "asr bld" ]
                            []
                        ]
                    ]
                , div [ class "page-content iw" ] [ viewPage page model ]
                ]
            ]


viewPage : Page -> Model -> Html Msg
viewPage page model =
    case page of
        Page.Observation subModel ->
            Html.map Model.ObservationMsg <| ObservationView.view subModel


navigation : Html msg
navigation =
    div [ class "en ble" ]
        [ nav
            [ class "bll" ]
            [ div
                [ class "blf" ]
                [ navCollapseControl
                , a
                    [ class "blh bmh", href "#" ]
                    [ span [ class "bv-logo bch bli" ] [] ]
                ]
            , div
                [ class "collapse bki", id "nav-toggleable-md" ]
                [ navSearchForm
                , navLinks
                , hr [ class "bmi aah" ] []
                ]
            ]
        ]


navLinks : Html msg
navLinks =
    ul
        [ class "nav lq nav-stacked st" ]
        [ li
            [ class "asv" ]
            [ text "Observables" ]
        , li
            [ class "lp" ]
            [ a [ class "ln", href "#" ] [ text "Observation" ] ]
        , li
            [ class "lp" ]
            [ a [ class "ln", href "#" ] [ text "Sleep" ] ]
        ]


navSearchForm : Html msg
navSearchForm =
    form
        [ class "blj" ]
        [ input
            [ class "form-control", type_ "text", placeholder "Search..." ]
            []
        , button
            [ type_ "submit", class "ku" ]
            [ span [ class "bv bdb" ] [] ]
        ]


navCollapseControl : Html msg
navCollapseControl =
    button
        [ class "bkb bkd blg"
        , type_ "button"
        , Attr.attribute "data-toggle" "collapse"
        , Attr.attribute "data-target" "#nav-toggleable-md"
        ]
        [ span [ class "yz" ] [ text "Toggle nav" ]
        ]
