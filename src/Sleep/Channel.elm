module Sleep.Channel
    exposing
        ( ChannelState(..)
        , channel
        , list
        , create
        , get
        , comment
        , update
        )

import Phoenix.Channel as Channel exposing (Channel)
import Phoenix.Push as Push exposing (Push)
import Json.Encode as Je
import Sleep.Types as Types
    exposing
        ( SleepWithComments
        , PaginatedSleeps
        , SleepId
        , Sleep
        , toSleepId
        , fromSleepId
        , sleepDecoder
        )
import Comment
    exposing
        ( Comment
        , toCommentId
        , commentVarSpec
        , CommentValue
        , commentResponse
        )
import Json.Decode as Jd exposing (Decoder)
import GraphQL.Request.Builder as Grb
    exposing
        ( Document
        , Mutation
        , ValueSpec
        , Request
        , Query
        )
import GraphQL.Request.Builder.Arg as Arg
import GraphQL.Request.Builder.Variable as Var
    exposing
        ( VariableSpec
        , Variable
        )
import Utils
    exposing
        ( defaultPaginationVar
        , PaginationVars
        , graphQlEndpointHelper
        , paginationVarSpec
        , paginationGraphQlResponse
        , graphQlQueryParams
        )


channelName : String
channelName =
    "sleep:sleep"


type ChannelState
    = Joining
    | Joined (Result String PaginatedSleeps)
    | Leaving
    | Left
    | ListSucceeds (Result String PaginatedSleeps)
    | ListFails Je.Value
    | CreateSucceeds (Result String SleepId)
    | CreateFails Je.Value
    | SleepCreated (Result String Sleep)
    | GetSucceeds (Result String SleepWithComments)
    | GetFails Je.Value
    | UpdateSucceeds (Result String SleepWithComments)
    | UpdateFails Je.Value
    | SleepUpdated (Result String Sleep)
    | CommentSucceeds (Result String Comment)
    | CommentFails Je.Value


channel : Channel ChannelState
channel =
    let
        ( payLoad, response ) =
            listParams defaultPaginationVar

        ( _, _, createResponse ) =
            graphQlEndpointHelper
                createRequest
                { start = ""
                , comment = Nothing
                }

        updateResponse =
            Jd.decodeValue sleepDecoder
    in
        channelName
            |> Channel.init
            |> Channel.withPayload payLoad
            |> Channel.onRequestJoin Joining
            |> Channel.onJoin (Joined << response)
            |> Channel.onLeave (\_ -> Left)
            |> Channel.on "sleep_created" (SleepCreated << createResponse)
            |> Channel.on "sleep_updated" (SleepUpdated << updateResponse)
            |> Channel.withDebug



-- LIST SLEEPS, PAGINATING RESPONSE


list : PaginationVars -> Push ChannelState
list vars =
    let
        ( payLoad, response ) =
            listParams vars
    in
        Push.init channelName "list_sleeps"
            |> Push.withPayload payLoad
            |> Push.onOk (ListSucceeds << response)
            |> Push.onError ListFails


listParams :
    PaginationVars
    -> ( Je.Value, Jd.Value -> Result String PaginatedSleeps )
listParams vars =
    let
        ( query, params, response ) =
            graphQlEndpointHelper paginatedSleepsRequest vars

        payLoad =
            Je.object
                [ ( "query", Je.string query )
                , ( "params", params )
                ]
    in
        ( payLoad, response )


paginatedSleepsQueryName : String
paginatedSleepsQueryName =
    "paginatedSleeps"


paginatedSleepsResponse : ValueSpec Grb.NonNull Grb.ObjectType PaginatedSleeps vars
paginatedSleepsResponse =
    Grb.object PaginatedSleeps
        |> Grb.with (Grb.field "entries" [] <| Grb.list sleepResponse)
        |> Grb.with (Grb.field "pagination" [] paginationGraphQlResponse)


paginatedSleepsRequest :
    PaginationVars
    -> Request Query PaginatedSleeps
paginatedSleepsRequest params =
    let
        paginationVar =
            Var.required "pagination" .pagination paginationVarSpec

        queryRoot : Document Query PaginatedSleeps PaginationVars
        queryRoot =
            Grb.queryDocument <|
                Grb.extract <|
                    Grb.field
                        paginatedSleepsQueryName
                        [ ( "pagination", Arg.variable paginationVar ) ]
                        paginatedSleepsResponse
    in
        Grb.request params queryRoot



-- CREATE A SLEEP


create : CreateQueryVars -> Push ChannelState
create vars =
    let
        ( query, params ) =
            graphQlQueryParams <| createRequest vars

        idResponse =
            Jd.decodeValue <| Jd.field "id" <| Jd.map toSleepId Jd.string

        payLoad =
            Je.object
                [ ( "query", Je.string query )
                , ( "params", params )
                ]
    in
        Push.init channelName "new_sleep"
            |> Push.withPayload payLoad
            |> Push.onOk (CreateSucceeds << idResponse)
            |> Push.onError CreateFails


createMutationName : String
createMutationName =
    "sleep"


type alias CreateQueryVars =
    { start : String
    , comment : Maybe CommentValue
    }


createRequest : CreateQueryVars -> Request Mutation Sleep
createRequest ({ comment } as queryVars) =
    let
        startVar =
            Var.required "start" .start Var.string

        idResponse =
            Grb.extract <|
                Grb.field "id"
                    []
                    (Grb.map toSleepId Grb.id)

        mutation : Document Mutation Sleep CreateQueryVars
        mutation =
            Grb.mutationDocument <|
                Grb.extract <|
                    Grb.field
                        createMutationName
                        [ ( "start", Arg.variable startVar )
                        , ( "comment", Arg.variable commentVar )
                        ]
                        sleepResponse
    in
        Grb.request queryVars mutation



-- Get sleep by Id


get : String -> Push ChannelState
get id_ =
    let
        ( query, params, response ) =
            graphQlEndpointHelper sleepQueryRequest id_

        payLoad =
            Je.object
                [ ( "query", Je.string query )
                , ( "params", params )
                ]
    in
        Push.init channelName "get_sleep"
            |> Push.withPayload payLoad
            |> Push.onOk (GetSucceeds << response)
            |> Push.onError GetFails


sleepQueryName : String
sleepQueryName =
    "sleep"


sleepQueryRequest :
    String
    -> Request Query SleepWithComments
sleepQueryRequest id_ =
    let
        idVar =
            Var.required "id" (always id_) Var.id

        queryRoot : Document Query SleepWithComments String
        queryRoot =
            Grb.queryDocument <|
                Grb.extract <|
                    Grb.field
                        sleepQueryName
                        [ ( "id", Arg.variable idVar ) ]
                        sleepWithCommentResponse
    in
        Grb.request id_ queryRoot



-- update a sleep


update : UpdateParams -> Push ChannelState
update args =
    let
        ( query, params, response ) =
            graphQlEndpointHelper updateRequest args

        payLoad =
            Je.object
                [ ( "query", Je.string query )
                , ( "params", params )
                ]
    in
        Push.init channelName "update_sleep"
            |> Push.withPayload payLoad
            |> Push.onOk (UpdateSucceeds << response)
            |> Push.onError UpdateFails


type alias UpdateParams =
    { id : SleepId
    , start : Maybe String
    , end : Maybe String
    , comment : Maybe CommentValue
    }


updateMutationName : String
updateMutationName =
    "sleepUpdate"


updateRequest :
    UpdateParams
    -> Request Mutation SleepWithComments
updateRequest params =
    let
        idVar =
            Var.required "id" (.id >> fromSleepId) Var.id

        startVar =
            Var.required "start" .start (Var.nullable Var.string)

        endVar =
            Var.required "end" .end (Var.nullable Var.string)

        queryRoot : Document Mutation SleepWithComments UpdateParams
        queryRoot =
            Grb.mutationDocument <|
                Grb.extract <|
                    Grb.field
                        updateMutationName
                        [ ( "id", Arg.variable idVar )
                        , ( "start", Arg.variable startVar )
                        , ( "end", Arg.variable endVar )
                        , ( "comment", Arg.variable commentVar )
                        ]
                        sleepWithCommentResponse
    in
        Grb.request params queryRoot



-- create a sleep comment


comment : CommentParams -> Push ChannelState
comment args =
    let
        ( query, params, response ) =
            graphQlEndpointHelper commentRequest args

        payLoad =
            Je.object
                [ ( "query", Je.string query )
                , ( "params", params )
                ]
    in
        Push.init channelName "comment_sleep"
            |> Push.withPayload payLoad
            |> Push.onOk (CommentSucceeds << response)
            |> Push.onError CommentFails


type alias CommentParams =
    { text : String
    , sleepId : SleepId
    }


commentMutationName : String
commentMutationName =
    "sleepComment"


commentRequest :
    CommentParams
    -> Request Mutation Comment
commentRequest params =
    let
        textVar =
            Var.required "text" .text Var.string

        sleepIdVar =
            Var.required "sleepId" (.sleepId >> fromSleepId) Var.id

        queryRoot : Document Mutation Comment CommentParams
        queryRoot =
            Grb.mutationDocument <|
                Grb.extract <|
                    Grb.field
                        commentMutationName
                        [ ( "text", Arg.variable textVar )
                        , ( "sleepId", Arg.variable sleepIdVar )
                        ]
                        commentResponse
    in
        Grb.request params queryRoot



-------------------------------------------------------------------------


sleepResponse : ValueSpec Grb.NonNull Grb.ObjectType Sleep vars
sleepResponse =
    Grb.object Sleep
        |> Grb.with (Grb.field "id" [] (Grb.map Types.toSleepId Grb.id))
        |> Grb.with (Grb.field "start" [] Utils.dateTimeType)
        |> Grb.with (Grb.field "end" [] Utils.dateTimeType)


sleepWithCommentResponse : ValueSpec Grb.NonNull Grb.ObjectType SleepWithComments vars
sleepWithCommentResponse =
    Grb.object SleepWithComments
        |> Grb.with (Grb.field "id" [] (Grb.map Types.toSleepId Grb.id))
        |> Grb.with (Grb.field "start" [] Utils.dateTimeType)
        |> Grb.with (Grb.field "end" [] Utils.dateTimeType)
        |> Grb.with (Grb.field "comments" [] (Grb.list commentResponse))


commentVar : Variable { r | comment : Maybe CommentValue }
commentVar =
    Var.required
        "comment"
        .comment
        (Var.nullable commentVarSpec)
