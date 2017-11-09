module Observation.MetaAutocomplete
    exposing
        ( Model
        , Msg(SetAutoState)
        , view
        , init
        , update
        , subscriptions
        )

import Autocomplete
import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (..)
import String
import Json.Decode as Json
import Dom
import Task
import SharedStyles exposing (..)
import AutocompleteStyles exposing (autocompleteNamespace)
import Observation.Utils exposing (stringGt)
import Observation.Channel as Channel exposing (ChannelState)
import Observation.Types exposing (Meta, emptyMeta)
import Phoenix


{ id, class, classList } =
    autocompleteNamespace


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map SetAutoState Autocomplete.subscription


type alias Model =
    { metas : List Meta
    , autoState : Autocomplete.State
    , numShown : Int
    , query : String
    , selection : Maybe Meta
    , showMenu : Bool
    , editingAutocomp : Bool
    , websocketUrl : Maybe String
    }


metas : List Meta
metas =
    [ { title = "title1", id = "1" }
    , { title = "title2", id = "2" }
    , { title = "title3", id = "3" }
    ]


init : Model
init =
    { metas = []
    , autoState = Autocomplete.empty
    , numShown = 50
    , query = ""
    , selection = Nothing
    , showMenu = False
    , editingAutocomp = False
    , websocketUrl = Nothing
    }


type Msg
    = SetQuery String
    | SetAutoState Autocomplete.Msg
    | Wrap Bool
    | Reset
    | HandleEscape
    | SelectByKeyboard String
    | SelectByMouse String
    | PreviewSelection String
    | ChannelMsg ChannelState
    | OnFocus
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChannelMsg channelMsg ->
            case channelMsg of
                Channel.SearchMetaByTitleSucceeds result ->
                    let
                        metas =
                            case result of
                                Ok metas_ ->
                                    metas_

                                Err err ->
                                    let
                                        x =
                                            Debug.log "\n\nChannel.SearchMetaByTitleSucceeds " ( err, result )
                                    in
                                        model.metas
                    in
                        { model | metas = metas } ! []

                Channel.SearchMetaByTitleFails value ->
                    let
                        x =
                            Debug.log "\n\nChannel.SearchMetaByTitleSucceeds " value
                    in
                        model ! []

                _ ->
                    model ! []

        SetQuery newQuery ->
            let
                queryIsValid =
                    (stringGt newQuery 2)

                showMenu =
                    queryIsValid
                        && not
                            (List.isEmpty (acceptableMetas newQuery model.metas))

                cmd =
                    if queryIsValid then
                        Channel.searchMetaByTitle newQuery
                            |> Phoenix.push (Maybe.withDefault "" model.websocketUrl)
                            |> Cmd.map ChannelMsg
                    else
                        Cmd.none
            in
                { model
                    | query = newQuery
                    , editingAutocomp = True
                    , showMenu = queryIsValid
                    , selection = Nothing
                }
                    ! [ cmd ]

        SetAutoState autoMsg ->
            let
                ( newState, maybeMsg ) =
                    Autocomplete.update
                        updateConfig
                        autoMsg
                        model.numShown
                        model.autoState
                        (acceptableMetas model.query model.metas)

                newModel =
                    { model | autoState = newState }
            in
                case maybeMsg of
                    Nothing ->
                        newModel ! []

                    Just updateMsg ->
                        update updateMsg newModel

        HandleEscape ->
            let
                validOptions =
                    List.isEmpty (acceptableMetas model.query model.metas)
                        |> not

                handleEscape =
                    if validOptions then
                        model
                            |> removeSelection
                            |> resetMenu
                    else
                        resetInput model

                escapedModel =
                    case model.selection of
                        Just meta ->
                            if model.query == meta.title then
                                resetInput model
                            else
                                handleEscape

                        Nothing ->
                            handleEscape
            in
                escapedModel ! []

        Wrap toTop ->
            case model.selection of
                Just meta ->
                    update Reset model

                Nothing ->
                    if toTop then
                        { model
                            | autoState =
                                Autocomplete.resetToLastItem
                                    updateConfig
                                    (acceptableMetas model.query model.metas)
                                    model.numShown
                                    model.autoState
                            , selection =
                                List.head <|
                                    List.reverse <|
                                        List.take model.numShown <|
                                            (acceptableMetas model.query model.metas)
                        }
                            ! []
                    else
                        { model
                            | autoState =
                                Autocomplete.resetToFirstItem
                                    updateConfig
                                    (acceptableMetas model.query model.metas)
                                    model.numShown
                                    model.autoState
                            , selection =
                                List.head <|
                                    List.take model.numShown <|
                                        (acceptableMetas model.query model.metas)
                        }
                            ! []

        Reset ->
            { model
                | autoState =
                    Autocomplete.reset updateConfig model.autoState
                , selection = Nothing
            }
                ! []

        SelectByKeyboard id ->
            let
                newModel =
                    setQuery model id
                        |> resetMenu
            in
                newModel ! []

        SelectByMouse id ->
            let
                newModel =
                    setQuery model id
                        |> resetMenu
            in
                ( newModel
                , Task.attempt (\_ -> NoOp) (Dom.focus "select-meta-input")
                )

        PreviewSelection id ->
            { model
                | selection =
                    Just <| getMetaAtId model.metas id
            }
                ! []

        OnFocus ->
            model ! []

        NoOp ->
            model ! []


resetAutocompEdit : Model -> Model
resetAutocompEdit model =
    { model | editingAutocomp = False }


resetInput : Model -> Model
resetInput model =
    { model | query = "" }
        |> removeSelection
        |> resetMenu
        |> resetAutocompEdit


removeSelection : Model -> Model
removeSelection model =
    { model | selection = Nothing }


getMetaAtId : List Meta -> String -> Meta
getMetaAtId metas id =
    List.filter (\meta -> meta.title == id) metas
        |> List.head
        |> Maybe.withDefault emptyMeta


setQuery : Model -> String -> Model
setQuery ({ metas } as model) id =
    { model
        | query = .title <| getMetaAtId metas id
        , selection = Just <| getMetaAtId metas id
    }


resetMenu : Model -> Model
resetMenu model =
    { model
        | autoState = Autocomplete.empty
        , showMenu = False
    }
        |> resetAutocompEdit


view :
    Model
    -> ( List (Attribute Msg), List (Html Msg) )
view model =
    let
        options =
            { preventDefault = True, stopPropagation = False }

        dec =
            Json.andThen
                (\code ->
                    if code == 38 || code == 40 then
                        Json.succeed NoOp
                    else if code == 27 then
                        Json.succeed HandleEscape
                    else
                        Json.fail "not handling that key"
                )
                keyCode

        menu =
            if model.showMenu then
                [ viewMenu model ]
            else
                []

        query =
            case model.selection of
                Just meta ->
                    meta.title

                Nothing ->
                    model.query

        activeDescendant attributes =
            case model.selection of
                Just meta ->
                    (Attr.attribute "aria-activedescendant"
                        meta.title
                    )
                        :: attributes

                Nothing ->
                    attributes
    in
        ( activeDescendant
            [ onInput SetQuery
            , onFocus OnFocus
            , onWithOptions "keydown" options dec
            , Attr.value query
            , id "select-meta-input"
            , Attr.autocomplete False
            , Attr.attribute "aria-owns" "list-of-metas"
            , Attr.attribute "aria-expanded" <| String.toLower <| toString model.showMenu
            , Attr.attribute "aria-haspopup" <| String.toLower <| toString model.showMenu
            , Attr.attribute "role" "combobox"
            , Attr.attribute "aria-autocomplete" "list"
            ]
        , menu
        )


acceptableMetas :
    String
    -> List Meta
    -> List Meta
acceptableMetas query metas =
    let
        lowerQuery =
            String.toLower query
    in
        List.filter
            (String.contains lowerQuery << String.toLower << .title)
            metas


viewMenu : Model -> Html Msg
viewMenu model =
    div [ class [ AutocompleteMenu ] ]
        [ Html.map
            SetAutoState
            (Autocomplete.view
                viewConfig
                model.numShown
                model.autoState
                (acceptableMetas model.query model.metas)
            )
        ]


updateConfig : Autocomplete.UpdateConfig Msg Meta
updateConfig =
    Autocomplete.updateConfig
        { toId = .title
        , onKeyDown =
            \code maybeId ->
                if code == 38 || code == 40 then
                    Maybe.map PreviewSelection maybeId
                else if code == 13 then
                    Maybe.map SelectByKeyboard maybeId
                else
                    Just Reset
        , onTooLow = Just <| Wrap False
        , onTooHigh = Just <| Wrap True
        , onMouseEnter = \id -> Just <| PreviewSelection id
        , onMouseLeave = \_ -> Nothing
        , onMouseClick = \id -> Just <| SelectByMouse id
        , separateSelections = False
        }


viewConfig : Autocomplete.ViewConfig Meta
viewConfig =
    let
        customizedLi keySelected mouseSelected meta =
            { attributes =
                [ classList
                    [ ( AutocompleteItem, True )
                    , ( KeySelected, keySelected || mouseSelected )
                    ]
                , id meta.title
                ]
            , children = [ Html.text meta.title ]
            }
    in
        Autocomplete.viewConfig
            { toId = .title
            , ul = [ class [ AutocompleteList ] ]
            , li = customizedLi
            }
