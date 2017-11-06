module Observation.Model
    exposing
        ( Model
        , Msg(..)
        , channel
        , init
        , update
        , queryStore
        , Observation
        , FormValues
        )

import Form exposing (Form, FieldState)
import Form.Field as Field exposing (Field)
import Form.Validate as Validate exposing (Validation)
import Phoenix
import Phoenix.Channel as Channel exposing (Channel)
import Phoenix.Push as Push exposing (Push)
import Json.Encode as Je
import Json.Decode as Jd exposing (Decoder)
import Json.Decode.Extra as Jde exposing ((|:))
import GraphQL.Request.Builder as Grb exposing (Document, Mutation, ValueSpec, Request)
import GraphQL.Request.Builder.Arg as Arg
import GraphQL.Request.Builder.Variable as Var exposing (VariableSpec, Variable)
import Store exposing (Store)


type alias Model =
    { form : Maybe (Form () FormValues)
    , serverError : Maybe String
    , submitting : Bool
    , showingNewMetaForm : Bool
    }


type Msg
    = NoOp
    | FormMsg Form.Msg
    | ChannelMsg ChannelState
    | Submit
    | Reset
    | ToggleForm
    | ToggleViewNewMeta


type alias FormValues =
    { comment : String
    , title : String
    , intro : Maybe String
    , selectMeta : String
    }


type alias Observation =
    { comment : String
    , meta : Maybe Meta
    }


type alias Meta =
    { title : String
    , intro : Maybe String
    }


emptyMeta : Meta
emptyMeta =
    { title = emptyMetaTitle
    , intro = Nothing
    }


emptyMetaTitle : String
emptyMetaTitle =
    ""


initialFields : List ( String, Field )
initialFields =
    []


emptyForm : Form () FormValues
emptyForm =
    Form.initial initialFields <| validate init.showingNewMetaForm


init : Model
init =
    { form = Nothing
    , serverError = Nothing
    , submitting = False
    , showingNewMetaForm = False
    }



-- UPDATE


type alias QueryStore =
    { websocketUrl : Maybe String }


queryStore : Store -> QueryStore
queryStore store =
    { websocketUrl = Store.getWebsocketUrl store }


update : Msg -> Model -> QueryStore -> ( Model, Cmd Msg )
update msg ({ form, showingNewMetaForm } as model) { websocketUrl } =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Submit ->
            let
                newForm =
                    Form.update (validate showingNewMetaForm) Form.Submit <|
                        Maybe.withDefault emptyForm form

                newModel =
                    { model | form = Just newForm }
            in
                case ( Form.getOutput newForm, showingNewMetaForm ) of
                    ( Just formValues, True ) ->
                        let
                            x =
                                Debug.log "form values = " ( formValues, extractValues )

                            extractValues : Observation
                            extractValues =
                                { comment = formValues.comment
                                , meta =
                                    Just
                                        { title = formValues.title
                                        , intro = formValues.intro
                                        }
                                }

                            cmd =
                                extractValues
                                    |> createNewObservation
                                    |> Phoenix.push (Maybe.withDefault "" websocketUrl)
                                    |> Cmd.map ChannelMsg
                        in
                            ( { newModel
                                | submitting = True
                              }
                            , cmd
                            )

                    ( Just formValues, False ) ->
                        newModel ! []

                    ( Nothing, _ ) ->
                        newModel ! []

        Reset ->
            let
                newForm =
                    Form.update (validate showingNewMetaForm) (Form.Reset initialFields) <|
                        Maybe.withDefault emptyForm form
            in
                { model
                    | form = Just newForm
                    , serverError = Nothing
                }
                    ! []

        FormMsg formMsg ->
            { model
                | form =
                    Just
                        (Form.update (validate showingNewMetaForm) formMsg <|
                            Maybe.withDefault emptyForm form
                        )
                , serverError = Nothing
            }
                ! []

        ToggleViewNewMeta ->
            { model | showingNewMetaForm = not model.showingNewMetaForm } ! []

        ToggleForm ->
            case form of
                Nothing ->
                    { model | form = Just emptyForm } ! []

                Just _ ->
                    { model | form = Nothing } ! []

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



-- FORM VALIDATION


nonEmpty : Int -> Validation () String
nonEmpty minLength =
    Validate.string
        |> Validate.andThen Validate.nonEmpty
        |> Validate.andThen (Validate.minLength minLength)


validate : Bool -> Validation () FormValues
validate showingNewMetaForm =
    let
        ( validateTitle, validateSelectMeta ) =
            if showingNewMetaForm == True then
                ( nonEmpty 3, Validate.succeed emptyMetaTitle )
            else
                ( Validate.succeed emptyMetaTitle, nonEmpty 3 )
    in
        Validate.map4 FormValues
            (Validate.field "comment" (nonEmpty 3))
            (Validate.field "title" validateTitle)
            (Validate.field "intro" (Validate.maybe Validate.string))
            (Validate.field "selectMeta" validateSelectMeta)



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


createNewObservation : Observation -> Push ChannelState
createNewObservation formValues =
    let
        query : String
        query =
            mutationWithMetaRequest formValues
                |> Grb.requestBody

        params : Je.Value
        params =
            mutationWithMetaRequest formValues
                |> Grb.jsonVariableValues
                |> Maybe.withDefault Je.null

        payLoad =
            Je.object
                [ ( "with_meta", Je.bool True )
                , ( "query", Je.string query )
                , ( "params", params )
                ]

        x =
            Debug.log "payload " payLoad
    in
        Push.init channelName "new_observation"
            |> Push.withPayload payLoad
            |> Push.onOk NewWithMetaSucceeds
            |> Push.onError NewWithMetaFails



-- GRAPHQL


mutationName : String
mutationName =
    "observationWithMeta"


mutationWithMetaRequest : Observation -> Request Mutation Observation
mutationWithMetaRequest formValues =
    let
        commentVar : Variable Observation
        commentVar =
            Var.required "comment" .comment Var.string

        metaVar : Variable Observation
        metaVar =
            Var.optional "meta" .meta graphqlVarMeta emptyMeta

        mutation : Document Mutation Observation Observation
        mutation =
            Grb.mutationDocument <|
                Grb.extract
                    (Grb.field mutationName
                        [ ( "comment", Arg.variable commentVar )
                        , ( "meta", Arg.variable metaVar )
                        ]
                        (Grb.object Observation
                            |> Grb.with (Grb.field "comment" [] Grb.string)
                            |> Grb.with (Grb.field "meta" [] graphqlValueMeta)
                        )
                    )
    in
        Grb.request formValues mutation


graphqlValueMeta : ValueSpec Grb.Nullable Grb.ObjectType (Maybe Meta) var
graphqlValueMeta =
    Grb.object Meta
        |> Grb.with (Grb.field "title" [] Grb.string)
        |> Grb.with (Grb.field "intro" [] (Grb.nullable Grb.string))
        |> Grb.nullable


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


decoder : Decoder Observation
decoder =
    Jd.succeed Observation
        |: (Jd.field "comment" Jd.string)
        |: (Jd.field "meta" (Jd.nullable metaDecoder))


decodeMutationResponseSuccess : Jd.Value -> Result String Observation
decodeMutationResponseSuccess response =
    Jd.decodeValue (Jd.at [ "data", mutationName ] decoder) response
