module Observation.View exposing (view)

import Html.Events exposing (onClick, onSubmit)
import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Views.FormUtils as FormUtils
import Form exposing (Form)
import Form.Input as Input exposing (Input)
import Set
import Css
import SharedStyles exposing (..)
import Observation.Styles exposing (observationNamespace)
import Observation.Model as Model exposing (Model, Msg(..))
import Observation.Types exposing (CreateObservationWithMeta)
import Observation.MetaAutocomplete as MetaAutocomplete
import Observation.Utils exposing (stringGt)


{ id, class, classList } =
    observationNamespace


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style


view : Model -> Html Msg
view model =
    Html.div
        []
        [ viewFormToggler <| Maybe.andThen (\_ -> Just "") model.form
        , viewForm model
        ]


viewFormToggler : Maybe a -> Html Msg
viewFormToggler display =
    Html.i
        [ Attr.classList
            [ ( "fa", True )
            , ( "fa-plus-square", display == Nothing )
            , ( "fa-minus-square", display /= Nothing )
            ]
        , Attr.attribute "data-toggle" "tooltip"
        , Attr.attribute "data-placement" "bottom"
        , Attr.attribute "title" "New"
        , onClick ToggleForm
        , styles
            [ Css.paddingLeft (Css.px 0)
            , Css.marginBottom (Css.rem 0.75)
            , Css.fontSize (Css.rem 1.3)
            , Css.cursor Css.pointer
            ]
        ]
        []


viewForm : Model -> Html Msg
viewForm ({ serverError, submitting, metaAutoComp } as model) =
    case model.form of
        Nothing ->
            Html.text ""

        Just form_ ->
            let
                commentField =
                    Form.getFieldAsString "comment" form_

                label_ =
                    case submitting of
                        True ->
                            "Submitting.."

                        False ->
                            "Submit"

                formIsEmpty =
                    Set.isEmpty <| Form.getChangedFields form_

                showingQueryForm =
                    (not model.showingNewMetaForm)

                queryEmpty =
                    (not <| stringGt metaAutoComp.query 0)

                queryInvalid =
                    showingQueryForm
                        && ((not <| stringGt metaAutoComp.query 2)
                                || (metaAutoComp.selection == Nothing)
                           )

                disableSubmitBtn =
                    formIsEmpty
                        || queryInvalid
                        || ([] /= Form.getErrors form_)
                        || (submitting == True)

                disableResetBtn =
                    (queryEmpty && formIsEmpty)
                        || (submitting == True)
            in
                Html.form
                    [ onSubmit Submit
                    , Attr.novalidate True
                    ]
                    [ FormUtils.textualErrorBox serverError
                    , viewMeta form_ model
                    , Html.fieldset
                        []
                        [ FormUtils.formGrp
                            Input.textArea
                            commentField
                            [ Attr.placeholder "Comment"
                            , Attr.value (Maybe.withDefault "" commentField.value)
                            ]
                            Nothing
                            FormMsg
                        ]
                    , formBtns label_ disableSubmitBtn disableResetBtn
                    ]


viewMeta : Form () CreateObservationWithMeta -> Model -> Html Msg
viewMeta form_ ({ showingNewMetaForm } as model) =
    let
        viewing =
            if showingNewMetaForm == True then
                viewNewMeta form_
            else
                viewMetaSelect model
    in
        Html.div
            [ styles [ Css.marginTop (Css.rem 0.75) ] ]
            [ viewing ]


viewMetaSelect : Model -> Html Msg
viewMetaSelect ({ showingNewMetaForm, metaAutoComp } as model) =
    let
        isChanged =
            stringGt metaAutoComp.query 0

        nothingSelected =
            isChanged && (metaAutoComp.selection == Nothing)

        queryInvalid =
            isChanged && (not <| stringGt metaAutoComp.query 2)

        showingQuery =
            (not showingNewMetaForm) && isChanged

        ( isValid, isInvalid, error ) =
            case ( showingQuery, queryInvalid, nothingSelected ) of
                ( True, True, _ ) ->
                    ( False, True, Just "Type more than 3 chars to trigger autocomplete!" )

                ( True, False, True ) ->
                    ( False, True, Just "Select an option from autocomplete!" )

                ( True, False, False ) ->
                    ( True, False, Nothing )

                _ ->
                    ( False, False, Nothing )

        ( autoCompleteAttributes, menus_ ) =
            MetaAutocomplete.view model.metaAutoComp

        attributes =
            [ Attr.placeholder "Type to select title or click + to create"
            , Attr.classList
                [ ( "form-control", True )
                , ( "is-invalid", isInvalid )
                , ( "is-valid", isValid )
                ]
            , Attr.id "select-meta-input"
            ]
                ++ autoCompleteAttributes

        input =
            Html.map MetaAutocompleteMsg <| Html.input attributes []

        menus =
            List.map
                (\menu -> Html.map MetaAutocompleteMsg menu)
                menus_
    in
        Html.div
            [ Attr.class "meta-select" ]
            ([ Html.div
                [ Attr.class "blj input-group" ]
                [ input
                , Html.span
                    [ Attr.class "input-group-addon"
                    , styles [ Css.cursor Css.pointer ]
                    , onClick ToggleViewNewMeta
                    ]
                    [ Html.span [ Attr.class "fa fa-plus-square" ] [] ]
                ]
             ]
                ++ menus
                ++ [ FormUtils.textualError error ]
            )


viewNewMeta : Form () CreateObservationWithMeta -> Html Msg
viewNewMeta form_ =
    let
        titleField =
            Form.getFieldAsString "meta.title" form_

        introField =
            Form.getFieldAsString "meta.intro" form_
    in
        Html.div
            [ class [ NewMeta ] ]
            [ Html.div
                [ class [ NewMetaLegend ] ]
                [ Html.span
                    [ Attr.class "fa fa-minus-square"
                    , class [ NewMetaDismiss ]
                    , onClick ToggleViewNewMeta
                    ]
                    [ Html.span
                        [ styles [ Css.marginLeft (Css.px 5) ] ]
                        [ Html.text "New Meta" ]
                    ]
                ]
            , FormUtils.formGrp
                Input.textInput
                titleField
                [ Attr.placeholder "Title"
                , Attr.value (Maybe.withDefault "" titleField.value)
                ]
                Nothing
                FormMsg
            , FormUtils.formGrp
                Input.textArea
                introField
                [ Attr.placeholder "Intro"
                , Attr.value (Maybe.withDefault "" introField.value)
                ]
                Nothing
                FormMsg
            ]


formBtns : String -> Bool -> Bool -> Html Msg
formBtns label_ disableSubmitBtn disableResetBtn =
    Html.div
        [ styles [ Css.displayFlex ] ]
        [ Html.button
            [ styles [ Css.flex (Css.int 1) ]
            , Attr.class "btn btn-info"
            , Attr.type_ "submit"
            , Attr.disabled disableSubmitBtn
            ]
            [ Html.span
                [ Attr.class "fa fa-send"
                , styles
                    [ Css.display Css.inline
                    , Css.marginRight (Css.px 5)
                    ]
                ]
                []
            , Html.text label_
            ]
        , Html.button
            [ styles [ Css.marginLeft (Css.rem 4) ]
            , Attr.class "btn btn-outline-warning"
            , Attr.disabled disableResetBtn
            , Attr.type_ "button"
            , onClick Reset
            ]
            [ Html.text "Reset" ]
        ]
