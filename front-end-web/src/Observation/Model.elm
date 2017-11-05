module Observation.Model
    exposing
        ( Model
        , Msg(..)
        , channel
        , init
        , update
        , view
        , queryStore
        )

import Form exposing (Form, FieldState)
import Form.Field as Field exposing (Field)
import Form.Validate as Validate exposing (Validation)
import Form.Input as Input exposing (Input)
import Phoenix
import Phoenix.Channel as Channel exposing (Channel)
import Phoenix.Push as Push exposing (Push)
import Json.Encode as Je
import Json.Decode as Jd exposing (Decoder)
import Json.Decode.Extra as Jde exposing ((|:))
import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Html.Events exposing (onClick, onSubmit)
import Views.FormUtils as FormUtils
import Set
import Css
import GraphQL.Request.Builder as Grb exposing (Document, Mutation, ValueSpec, Request)
import GraphQL.Request.Builder.Arg as Arg
import GraphQL.Request.Builder.Variable as Var exposing (VariableSpec, Variable)
import Store exposing (Store)


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style


type alias Model =
    { form : Form () FormValues
    , serverError : Maybe String
    , submitting : Bool
    }


type Msg
    = NoOp
    | FormMsg Form.Msg
    | ChannelMsg ChannelState
    | Submit
    | Reset


type alias FormValues =
    { comment : String
    , meta : Meta
    }


type alias Meta =
    { title : String
    , intro : Maybe String
    }


initialFields : List ( String, Field )
initialFields =
    []


init : Model
init =
    { form = Form.initial initialFields validate
    , serverError = Nothing
    , submitting = False
    }



-- UPDATE


type alias QueryStore =
    { websocketUrl : Maybe String }


queryStore : Store -> QueryStore
queryStore store =
    { websocketUrl = Store.getWebsocketUrl store }


update : Msg -> Model -> QueryStore -> ( Model, Cmd Msg )
update msg ({ form } as model) { websocketUrl } =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Submit ->
            let
                newForm =
                    Form.update validate Form.Submit form

                newModel =
                    { model | form = newForm }
            in
                case Form.getOutput newForm of
                    Just formValues ->
                        let
                            cmd =
                                formValues
                                    |> createNewObservation
                                    |> Phoenix.push (Maybe.withDefault "" websocketUrl)
                                    |> Cmd.map ChannelMsg
                        in
                            ( { newModel
                                | submitting = True
                              }
                            , cmd
                            )

                    Nothing ->
                        newModel ! []

        Reset ->
            let
                newForm =
                    Form.update validate (Form.Reset initialFields) form
            in
                { model
                    | form = newForm
                    , serverError = Nothing
                }
                    ! []

        FormMsg formMsg ->
            { model
                | form = Form.update validate formMsg form
                , serverError = Nothing
            }
                ! []

        ChannelMsg channelState ->
            let
                unSubmit : Model -> Model
                unSubmit updatedModel =
                    { updatedModel | submitting = False }

                unknownServerError : Model
                unknownServerError =
                    { model | serverError = Just "Something went wrong!" }
                        |> unSubmit
            in
                case channelState of
                    NewWithMetaSucceeds val ->
                        case decodeMutationResponseSuccess val of
                            Ok data ->
                                ( unSubmit model, Cmd.none )

                            Err err ->
                                let
                                    x =
                                        Debug.log "NewWithMetaSucceeds decode error" err
                                in
                                    unknownServerError ! []

                    NewWithMetaFails val ->
                        let
                            x =
                                Debug.log "NewWithMetaFails" val
                        in
                            unknownServerError ! []

                    _ ->
                        ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    Html.div [] [ viewForm model ]


viewForm : Model -> Html Msg
viewForm ({ form, serverError, submitting } as model) =
    let
        commentField =
            Form.getFieldAsString "comment" form

        titleField =
            Form.getFieldAsString "meta.title" form

        introField =
            Form.getFieldAsString "meta.intro" form

        label_ =
            case submitting of
                True ->
                    "Submitting.."

                False ->
                    "Submit"

        formIsEmpty =
            Set.isEmpty <| Form.getChangedFields form

        disableSubmitBtn =
            formIsEmpty
                || ([] /= Form.getErrors form)
                || (submitting == True)

        disableResetBtn =
            formIsEmpty
                || (submitting == True)
    in
        Html.form
            [ onSubmit Submit
            , Attr.novalidate True
            ]
            [ FormUtils.textualErrorBox serverError
            , FormUtils.formGrp
                Input.textArea
                commentField
                [ Attr.placeholder "Comment"
                , Attr.value (Maybe.withDefault "" commentField.value)
                ]
                Nothing
                FormMsg
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
            , Html.div
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
                    , onClick Reset
                    ]
                    [ Html.text "Reset" ]
                ]
            ]



-- FORM


nonEmpty : Int -> Validation () String
nonEmpty minLength =
    Validate.string
        |> Validate.andThen Validate.nonEmpty
        |> Validate.andThen (Validate.minLength minLength)


validate : Validation () FormValues
validate =
    Validate.map2 FormValues
        (Validate.field "comment" (nonEmpty 3))
        (Validate.field "meta" validateMeta)


validateMeta : Validation () Meta
validateMeta =
    Validate.map2 Meta
        (Validate.field "title" (nonEmpty 3))
        (Validate.field "intro" (Validate.maybe Validate.string))



-- CHANNEL


channelName : String
channelName =
    "observation:observation"


type ChannelState
    = Joining
    | Joined Je.Value
    | Leaving
    | Left
    | NewWithMetaSucceeds Je.Value
    | NewWithMetaFails Je.Value


channel : Channel ChannelState
channel =
    channelName
        |> Channel.init
        |> Channel.onRequestJoin Joining
        |> Channel.onJoin Joined
        |> Channel.onLeave (\_ -> Left)
        |> Channel.withDebug


createNewObservation : FormValues -> Push ChannelState
createNewObservation formValues =
    let
        query : String
        query =
            mutationRequest formValues
                |> Grb.requestBody

        params : Je.Value
        params =
            mutationRequest formValues
                |> Grb.jsonVariableValues
                |> Maybe.withDefault Je.null

        payLoad =
            Je.object
                [ ( "with_meta", Je.bool True )
                , ( "query", Je.string query )
                , ( "params", params )
                ]
    in
        Push.init channelName "new_observation"
            |> Push.withPayload payLoad
            |> Push.onOk NewWithMetaSucceeds
            |> Push.onError NewWithMetaFails



-- GRAPHQL


mutationName : String
mutationName =
    "observationWithMeta"


mutationRequest : FormValues -> Request Mutation FormValues
mutationRequest formValues =
    let
        commentVar : Variable FormValues
        commentVar =
            Var.required "comment" .comment Var.string

        metaVar : Variable FormValues
        metaVar =
            Var.required "meta" .meta graphqlVarMeta

        mutation : Document Mutation FormValues FormValues
        mutation =
            Grb.mutationDocument <|
                Grb.extract
                    (Grb.field mutationName
                        [ ( "comment", Arg.variable commentVar )
                        , ( "meta", Arg.variable metaVar )
                        ]
                        (Grb.object FormValues
                            |> Grb.with (Grb.field "comment" [] Grb.string)
                            |> Grb.with (Grb.field "meta" [] graphqlValueMeta)
                        )
                    )
    in
        Grb.request formValues mutation


graphqlValueMeta : ValueSpec Grb.NonNull Grb.ObjectType Meta var
graphqlValueMeta =
    Grb.object Meta
        |> Grb.with (Grb.field "title" [] Grb.string)
        |> Grb.with (Grb.field "intro" [] (Grb.nullable Grb.string))


graphqlVarMeta : VariableSpec Var.NonNull Meta
graphqlVarMeta =
    Var.object "Meta"
        [ Var.field "title" .title Var.string
        , Var.field "intro" .intro (Var.nullable Var.string)
        ]



-- DECODERS


metaDecoder : Decoder Meta
metaDecoder =
    Jd.succeed Meta
        |: (Jd.field "title" Jd.string)
        |: (Jd.field "intro" (Jd.nullable Jd.string))


decoder : Decoder FormValues
decoder =
    Jd.succeed FormValues
        |: (Jd.field "comment" Jd.string)
        |: (Jd.field "meta" metaDecoder)


decodeMutationResponseSuccess : Jd.Value -> Result String FormValues
decodeMutationResponseSuccess response =
    Jd.decodeValue (Jd.at [ "data", mutationName ] decoder) response
