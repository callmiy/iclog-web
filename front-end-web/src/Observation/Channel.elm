module Observation.Channel
    exposing
        ( ChannelState(..)
        , createWithMeta
        , createNew
        , channel
        , searchMetaByTitle
        , PaginatedObservations
        )

import Phoenix.Channel as Channel exposing (Channel)
import Phoenix.Push as Push exposing (Push)
import Json.Encode as Je
import Observation.Types exposing (Observation, Meta, CreateMeta, CreateObservationWithMeta, emptyCreateMeta)
import Json.Decode as Jd exposing (Decoder)
import GraphQL.Request.Builder as Grb exposing (Document, Mutation, ValueSpec, Request, Query)
import GraphQL.Request.Builder.Arg as Arg
import GraphQL.Request.Builder.Variable as Var exposing (VariableSpec, Variable)
import Utils as GUtils


channelName : String
channelName =
    "observation:observation"


type ChannelState
    = Joining
    | Joined (Result String PaginatedObservations)
    | Leaving
    | Left
    | CreateObservationSucceeds (Result String Observation)
    | CreateObservationFails Je.Value
    | SearchMetaByTitleSucceeds (Result String (List Meta))
    | SearchMetaByTitleFails Je.Value
    | ListObservationsSucceeds (Result String PaginatedObservations)
    | ListObservationsFails Je.Value


channel : Channel ChannelState
channel =
    let
        ( payLoad, response ) =
            listObservationsChannelParams GUtils.defaultPaginationParamsVar
    in
        channelName
            |> Channel.init
            |> Channel.withPayload payLoad
            |> Channel.onRequestJoin Joining
            |> Channel.onJoin (Joined << response)
            |> Channel.onLeave (\_ -> Left)
            |> Channel.withDebug


createNew : CreateQueryVars -> Push ChannelState
createNew vars =
    let
        ( query, params, response ) =
            graphQlEndpointHelper createRequest vars

        payLoad =
            Je.object
                [ ( "query", Je.string query )
                , ( "params", params )
                ]
    in
        Push.init channelName "new_observation"
            |> Push.withPayload payLoad
            |> Push.onOk (CreateObservationSucceeds << response)
            |> Push.onError CreateObservationFails


createWithMeta : CreateObservationWithMeta -> Push ChannelState
createWithMeta vars =
    let
        ( query, params, response ) =
            graphQlEndpointHelper createWithMetaRequest vars

        payLoad =
            Je.object
                [ ( "with_meta", Je.bool True )
                , ( "query", Je.string query )
                , ( "params", params )
                ]
    in
        Push.init channelName "new_observation"
            |> Push.withPayload payLoad
            |> Push.onOk (CreateObservationSucceeds << response)
            |> Push.onError CreateObservationFails


searchMetaByTitle : String -> Push ChannelState
searchMetaByTitle title =
    let
        ( query, params, response ) =
            graphQlEndpointHelper metaByTitleQueryRequest { title = title }

        payLoad =
            Je.object
                [ ( "query", Je.string query )
                , ( "params", params )
                ]
    in
        Push.init channelName "search_metas_by_title"
            |> Push.withPayload payLoad
            |> Push.onOk (SearchMetaByTitleSucceeds << response)
            |> Push.onError SearchMetaByTitleFails


listObservationsChannelParams :
    GUtils.PaginationParamsVars
    -> ( Je.Value, Jd.Value -> Result String PaginatedObservations )
listObservationsChannelParams vars =
    let
        ( query, params, response ) =
            graphQlEndpointHelper paginatedObservationsQueryRequest vars

        payLoad =
            Je.object
                [ ( "query", Je.string query )
                , ( "params", params )
                ]
    in
        ( payLoad, response )


listObservations : GUtils.PaginationParamsVars -> Push ChannelState
listObservations vars =
    let
        ( payLoad, response ) =
            listObservationsChannelParams vars
    in
        Push.init channelName "list_observations"
            |> Push.withPayload payLoad
            |> Push.onOk (ListObservationsSucceeds << response)
            |> Push.onError ListObservationsFails



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


graphQlEndpointHelper :
    (a -> Request operationType result)
    -> a
    -> ( String, Je.Value, Jd.Value -> Result String result )
graphQlEndpointHelper queryRequest vars =
    let
        request =
            queryRequest vars

        responseDecoder =
            Grb.responseDataDecoder request

        query : String
        query =
            Grb.requestBody request

        params : Je.Value
        params =
            Grb.jsonVariableValues request
                |> Maybe.withDefault Je.null

        response =
            decodeGraphQlResponse responseDecoder
    in
        ( query, params, response )



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



-- SEARCH FOR OBSERVATION META BY TITLE


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



-- LIST OBSERVATIONS, PAGINATING RESPONSE


paginatedObservationsQueryName : String
paginatedObservationsQueryName =
    "paginatedObservations"


type alias PaginatedObservations =
    { entries : List Observation
    , pagination : GUtils.Pagination
    }


paginatedObservationResponse : ValueSpec Grb.NonNull Grb.ObjectType PaginatedObservations vars
paginatedObservationResponse =
    Grb.object PaginatedObservations
        |> Grb.with (Grb.field "entries" [] <| Grb.list observationGraphQlResponse)
        |> Grb.with (Grb.field "pagination" [] GUtils.paginationGraphQlResponse)


paginatedObservationsQueryRequest :
    GUtils.PaginationParamsVars
    -> Request Query PaginatedObservations
paginatedObservationsQueryRequest params =
    let
        paginationVar =
            Var.required "pagination" .pagination GUtils.paginationVarSpec

        queryRoot : Document Query PaginatedObservations GUtils.PaginationParamsVars
        queryRoot =
            Grb.queryDocument <|
                Grb.extract <|
                    Grb.field
                        paginatedObservationsQueryName
                        [ ( "pagination", Arg.variable paginationVar ) ]
                        paginatedObservationResponse
    in
        Grb.request params queryRoot


observationGraphQlResponse : ValueSpec Grb.NonNull Grb.ObjectType Observation vars
observationGraphQlResponse =
    Grb.object Observation
        |> Grb.with (Grb.field "id" [] Grb.id)
        |> Grb.with (Grb.field "comment" [] Grb.string)
        |> Grb.with (Grb.field "meta" [] metaInGraphQlResponse)
        |> Grb.with (Grb.field "insertedAt" [] GUtils.dateTimeType)


metaInGraphQlResponse : ValueSpec Grb.NonNull Grb.ObjectType Meta vars
metaInGraphQlResponse =
    Grb.object Meta
        |> Grb.with (Grb.field "id" [] Grb.id)
        |> Grb.with (Grb.field "title" [] Grb.string)


decodeGraphQlResponse : Decoder a -> Jd.Value -> Result String a
decodeGraphQlResponse d response =
    Jd.decodeValue (Jd.at [ "data" ] d) response
