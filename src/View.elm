module View exposing (view)

import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Html.Events exposing (onClick)
import Model exposing (Model, Msg(..))
import Page exposing (Page)
import Observation.Detail.App as ObservationDetail
import Observation.List as ObservationList
import Observation.New.App as ObservationNew
import Meal.Detail.View as MealDetailView
import Meal.List as MealList
import Meal.New as MealNew
import Router exposing (Route)
import Utils exposing ((=>))
import Css
import Sleep.List as SleepList
import Sleep.New as SleepNew
import Sleep.Detail.View as SleepDetailView
import Store


view : Model -> Html Msg
view ({ pageState } as model) =
    let
        page =
            Page.getPage pageState

        ( pageView, pageTitle ) =
            viewPage page model
    in
        Html.div [ Attr.class "dh" ]
            [ navigation model
            , Html.div
                [ Attr.class "et bmj" ]
                [ connectionError <| Store.getConnectionStatus model.store
                , Html.div
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


connectionError : Store.ConnectionStatus -> Html msg
connectionError status =
    let
        dom bgColor txt =
            Html.div
                [ styles
                    [ Css.backgroundColor bgColor
                    , Css.marginBottom (Css.px 10)
                    , Css.color (Css.rgb 255 255 255)
                    , Css.fontSize (Css.rem 1)
                    , Css.textAlign Css.center
                    ]
                ]
                [ Html.text txt ]
    in
        case status of
            Store.Disconnected ->
                dom (Css.rgb 243 142 101) "Searching for network..."

            Store.Connecting ->
                dom (Css.rgb 158 208 138) "Connecting..."

            Store.Connected ->
                Html.text ""


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

        Page.SleepList subModel ->
            (Html.map Model.SleepListMsg <|
                SleepList.view subModel (SleepList.queryStore store)
            )
                => "Sleep"

        Page.SleepNew subModel ->
            (Html.map Model.SleepNewMsg <| SleepNew.view subModel) => "Sleep"

        Page.SleepDetail subModel ->
            (Html.map Model.SleepDetailMsg <|
                SleepDetailView.view subModel
            )
                => "Sleep"


navigation : Model -> Html Msg
navigation model =
    Html.div [ Attr.class "en ble" ]
        [ Html.nav
            [ Attr.class "bll" ]
            [ Html.div
                [ Attr.class "blf" ]
                [ navCollapseControl model.showingMobileNav
                , Html.a
                    [ Attr.class "blh bmh", Attr.href "#" ]
                    [ Html.span [ Attr.class "bv-logo bch bli" ] [] ]
                ]
            , Html.div
                [ Attr.classList
                    [ ( "collapse bki", True )
                    , ( "show", model.showingMobileNav )
                    ]
                , Attr.id "nav-toggleable-md"
                ]
                [ navSearchForm
                , navLinks model.route
                , Html.hr [ Attr.class "bmi aah" ] []
                ]
            ]
        ]


navLinks : Route -> Html msg
navLinks route =
    let
        stringRoute =
            toString route

        mealActive =
            String.startsWith "Meal" stringRoute

        observationActive =
            String.startsWith "Observation" stringRoute

        sleepActive =
            String.startsWith "Sleep" stringRoute

        link_ route_ active text_ =
            Html.li
                [ Attr.class "lp" ]
                [ Html.a
                    [ Attr.classList [ ( "ln", True ), ( "active", active ) ]
                    , Router.href route_
                    ]
                    [ Html.text text_ ]
                ]
    in
        Html.ul
            [ Attr.class "nav lq nav-stacked st" ]
            [ Html.li
                [ Attr.class "asv" ]
                [ Html.text "Observables" ]
            , link_ Router.ObservationList observationActive "Observation"
            , link_ Router.MealList mealActive "Meal"
            , link_ Router.SleepList sleepActive "Sleep"
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


navCollapseControl : Bool -> Html Msg
navCollapseControl showingMobileNav =
    Html.button
        [ Attr.classList
            [ ( "bkb bkd blg", True )
            , ( "collapsed", not showingMobileNav )
            ]
        , Attr.type_ "button"
        , onClick ToggleShowingMobileNav
        ]
        [ Html.span
            [ Attr.class "yz" ]
            [ Html.text "Toggle nav" ]
        ]


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style
