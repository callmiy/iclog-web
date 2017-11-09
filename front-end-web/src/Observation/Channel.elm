module Observation.Channel
    exposing
        ( ChannelState(..)
        , createWithMeta
        , createNew
        , channel
        , searchMetaByTitle
        )

import Phoenix.Channel as Channel exposing (Channel)
import Phoenix.Push as Push exposing (Push)
import Json.Encode as Je
import Observation.Types exposing (Observation, Meta, CreateMeta, CreateObservationWithMeta, emptyCreateMeta)
import Json.Decode as Jd exposing (Decoder)
import GraphQL.Request.Builder as Grb exposing (Document, Mutation, ValueSpec, Request, Query)
import GraphQL.Request.Builder.Arg as Arg
import GraphQL.Request.Builder.Variable as Var exposing (VariableSpec, Variable)


channelName : String
channelName =
    "observation:observation"


type ChannelState
    = Joining
    | Joined Je.Value
    | Leaving
    | Left
    | CreateObservationSucceeds (Result String Observation)
    | CreateObservationFails Je.Value
    | SearchMetaByTitleSucceeds (Result String (List Meta))
    | SearchMetaByTitleFails Je.Value


channel : Channel ChannelState
channel =
    channelName
        |> Channel.init
        |> Channel.onRequestJoin Joining
        |> Channel.onJoin Joined
        |> Channel.onLeave (\_ -> Left)
        |> Channel.withDebug


createNew : CreateQueryVars -> Push ChannelState
createNew vars =
    let
        request =
            createRequest vars

        responseDecoder =
            Grb.responseDataDecoder request

        query : String
        query =
            Grb.requestBody request

        params : Je.Value
        params =
            Grb.jsonVariableValues request
                |> Maybe.withDefault Je.null

        payLoad =
            Je.object
                [ ( "query", Je.string query )
                , ( "params", params )
                ]
    in
        Push.init channelName "new_observation"
            |> Push.withPayload payLoad
            |> Push.onOk (CreateObservationSucceeds << decodeGraphQlResponse responseDecoder)
            |> Push.onError CreateObservationFails


createWithMeta : CreateObservationWithMeta -> Push ChannelState
createWithMeta vars =
    let
        request =
            createWithMetaRequest vars

        responseDecoder =
            Grb.responseDataDecoder request

        query : String
        query =
            Grb.requestBody request

        params : Je.Value
        params =
            Grb.jsonVariableValues request
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
            |> Push.onOk (CreateObservationSucceeds << decodeGraphQlResponse responseDecoder)
            |> Push.onError CreateObservationFails


searchMetaByTitle : String -> Push ChannelState
searchMetaByTitle title =
    let
        vars =
            { title = title }

        request =
            metaByTitleQueryRequest vars

        responseDecoder =
            Grb.responseDataDecoder request

        query : String
        query =
            Grb.requestBody request

        params : Je.Value
        params =
            Grb.jsonVariableValues request
                |> Maybe.withDefault Je.null

        payLoad =
            Je.object
                [ ( "query", Je.string query )
                , ( "params", params )
                ]
    in
        Push.init channelName "search_metas_by_title"
            |> Push.withPayload payLoad
            |> Push.onOk (SearchMetaByTitleSucceeds << decodeGraphQlResponse responseDecoder)
            |> Push.onError CreateObservationFails



-- GRAPHQL
-- CREATE OBSERVATION AND ITS META SIMULTANEOUSLY


createWithMetaMutationName : String
createWithMetaMutationName =
    "observationMutationWithMeta"


createWithMetaRequest : CreateObservationWithMeta -> Request Mutation Observation
createWithMetaRequest formValues =
    let
        commentVar : Variable CreateObservationWithMeta
        commentVar =
            Var.required "comment" .comment Var.string

        metaVar_ : VariableSpec Var.NonNull CreateMeta
        metaVar_ =
            Var.object
                "Meta"
                [ Var.field "title" .title Var.string
                , Var.field "intro" .intro (Var.nullable Var.string)
                ]

        metaVar : Variable CreateObservationWithMeta
        metaVar =
            Var.required "meta" .meta metaVar_

        mutation : Document Mutation Observation CreateObservationWithMeta
        mutation =
            Grb.mutationDocument <|
                Grb.extract <|
                    Grb.field createWithMetaMutationName
                        [ ( "comment", Arg.variable commentVar )
                        , ( "meta", Arg.variable metaVar )
                        ]
                        observationGraphQlResponse
    in
        Grb.request formValues mutation



-- CREATE NEW OBSERVATION WITHOUT CREATING META


type alias CreateQueryVars =
    { comment : String
    , metaId : String
    }


createMutationName : String
createMutationName =
    "observationMutation"


createRequest : CreateQueryVars -> Request Mutation Observation
createRequest queryVars =
    let
        commentVar : Variable CreateQueryVars
        commentVar =
            Var.required "comment" .comment Var.string

        metaIdVar : Variable CreateQueryVars
        metaIdVar =
            Var.required "metaId" .metaId Var.id

        mutation : Document Mutation Observation CreateQueryVars
        mutation =
            Grb.mutationDocument <|
                Grb.extract <|
                    Grb.field createMutationName
                        [ ( "comment", Arg.variable commentVar )
                        , ( "metaId", Arg.variable metaIdVar )
                        ]
                        observationGraphQlResponse
    in
        Grb.request queryVars mutation


metaByTitleQueryName : String
metaByTitleQueryName =
    "observationMetasByTitle"


type alias MetaByTitleQueryVars =
    { title : String }


metaByTitleQueryRequest :
    MetaByTitleQueryVars
    -> Request Query (List Meta)
metaByTitleQueryRequest params =
    let
        titleVar : Variable MetaByTitleQueryVars
        titleVar =
            Var.required "title" .title Var.string

        queryRoot : Document Query (List Meta) MetaByTitleQueryVars
        queryRoot =
            Grb.queryDocument <|
                Grb.extract <|
                    Grb.field
                        metaByTitleQueryName
                        [ ( "title", Arg.variable titleVar ) ]
                        (Grb.list metaInGraphQlResponse)
    in
        Grb.request params queryRoot


observationGraphQlResponse : ValueSpec Grb.NonNull Grb.ObjectType Observation vars
observationGraphQlResponse =
    Grb.object Observation
        |> Grb.with (Grb.field "id" [] Grb.id)
        |> Grb.with (Grb.field "comment" [] Grb.string)
        |> Grb.with (Grb.field "meta" [] metaInGraphQlResponse)


metaInGraphQlResponse : ValueSpec Grb.NonNull Grb.ObjectType Meta vars
metaInGraphQlResponse =
    Grb.object Meta
        |> Grb.with (Grb.field "id" [] Grb.id)
        |> Grb.with (Grb.field "title" [] Grb.string)


decodeGraphQlResponse : Decoder a -> Jd.Value -> Result String a
decodeGraphQlResponse d response =
    Jd.decodeValue (Jd.at [ "data" ] d) response
