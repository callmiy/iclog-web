module View exposing (view)

import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Model exposing (Model, Msg)
import Page exposing (Page)
import Observation.Detail.App as ObservationDetail
import Observation.List as ObservationList
import Observation.New.App as ObservationNew
import Meal.Detail.View as MealDetailView
import Meal.List as MealList
import Meal.New as MealNew
import Router
import Utils exposing ((=>))
import Css


view : Model -> Html Msg
view ({ pageState } as model) =
    let
        page =
            Page.getPage pageState

        ( pageView, pageTitle ) =
            viewPage page model
    in
        Html.div [ Attr.class "dh" ]
            [ navigation
            , Html.div
                [ Attr.class "et bmj" ]
                [ Html.div
                    -- we display page headers in class "bls blu"
                    [ Attr.class "bls" ]
                    [ Html.div
                        [ Attr.class "blt global-page-titles" ]
                        [ Html.h6
                            [ Attr.class "blv global-title" ]
                            [ Html.text "Observables" ]
                        , Html.h4
                            [ Attr.class "blu page-title"
                            , styles
                                [ Css.margin3
                                    (Css.px 10)
                                    (Css.px 0)
                                    (Css.px 10)
                                ]
                            ]
                            [ Html.text pageTitle ]
                        ]
                    , Html.div
                        [ Attr.class "lf blw" ]
                        [ Html.div
                            [ Attr.class "asr bld" ]
                            []
                        ]
                    ]
                , pageView
                ]
            ]


viewPage : Page -> Model -> ( Html Msg, String )
viewPage page ({ store } as model) =
    case page of
        Page.Blank ->
            Html.text "" => ""

        Page.ObservationNew subModel ->
            (Html.map Model.ObservationNewMsg <|
                ObservationNew.view subModel
            )
                => "Observation"

        Page.ObservationList subModel ->
            (Html.map Model.ObservationListMsg <|
                ObservationList.view
                    subModel
                    (ObservationList.queryStore store)
            )
                => "Observation"

        Page.ObservationDetail subModel ->
            (Html.map Model.ObservationDetailMsg <|
                ObservationDetail.view subModel
            )
                => "Observation"

        Page.MealNew subModel ->
            (Html.map Model.MealNewMsg <| MealNew.view subModel) => "Meal"

        Page.MealList subModel ->
            (Html.map Model.MealListMsg <|
                MealList.view subModel (MealList.queryStore store)
            )
                => "Meal"

        Page.MealDetail subModel ->
            (Html.map Model.MealDetailMsg <|
                MealDetailView.view subModel
            )
                => "Meal"


navigation : Html msg
navigation =
    Html.div [ Attr.class "en ble" ]
        [ Html.nav
            [ Attr.class "bll" ]
            [ Html.div
                [ Attr.class "blf" ]
                [ navCollapseControl
                , Html.a
                    [ Attr.class "blh bmh", Attr.href "#" ]
                    [ Html.span [ Attr.class "bv-logo bch bli" ] [] ]
                ]
            , Html.div
                [ Attr.class "collapse bki", Attr.id "nav-toggleable-md" ]
                [ navSearchForm
                , navLinks
                , Html.hr [ Attr.class "bmi aah" ] []
                ]
            ]
        ]


navLinks : Html msg
navLinks =
    Html.ul
        [ Attr.class "nav lq nav-stacked st" ]
        [ Html.li
            [ Attr.class "asv" ]
            [ Html.text "Observables" ]
        , Html.li
            [ Attr.class "lp" ]
            [ Html.a
                [ Attr.class "ln"
                , Router.href Router.ObservationList
                ]
                [ Html.text "Observation" ]
            ]
        , Html.li
            [ Attr.class "lp" ]
            [ Html.a
                [ Attr.class "ln"
                , Router.href Router.MealList
                ]
                [ Html.text "Meal" ]
            ]
        ]


navSearchForm : Html msg
navSearchForm =
    Html.form
        [ Attr.class "blj" ]
        [ Html.input
            [ Attr.class "form-control"
            , Attr.type_ "text"
            , Attr.placeholder "Search..."
            ]
            []
        , Html.button
            [ Attr.type_ "submit", Attr.class "ku" ]
            [ Html.span [ Attr.class "bv bdb" ] [] ]
        ]


navCollapseControl : Html msg
navCollapseControl =
    Html.button
        [ Attr.class "bkb bkd blg"
        , Attr.type_ "button"
        , Attr.attribute "data-toggle" "collapse"
        , Attr.attribute "data-target" "#nav-toggleable-md"
        ]
        [ Html.span [ Attr.class "yz" ] [ Html.text "Toggle nav" ]
        ]


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style
