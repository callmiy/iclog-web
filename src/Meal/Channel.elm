module Meal.Channel
    exposing
        ( ChannelState(..)
        , channel
        , list
        , create
        , get
        , update
        )

import Phoenix.Channel as Channel exposing (Channel)
import Phoenix.Push as Push exposing (Push)
import Json.Encode as Je
import Meal.Types as Types
    exposing
        ( MealWithComments
        , PaginatedMeals
        , Comment
        , MealId
        , Meal
        , toMealId
        , fromMealId
        , mealDecoder
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
import GraphQL.Request.Builder.Variable as Var exposing (VariableSpec, Variable)
import Utils
    exposing
        ( defaultPaginationParamsVar
        , PaginationParamsVars
        , graphQlEndpointHelper
        , paginationVarSpec
        , paginationGraphQlResponse
        , graphQlQueryParams
        )


channelName : String
channelName =
    "meal:meal"


type ChannelState
    = Joining
    | Joined (Result String PaginatedMeals)
    | Leaving
    | Left
    | ListSucceeds (Result String PaginatedMeals)
    | ListFails Je.Value
    | CreateSucceeds (Result String MealId)
    | CreateFails Je.Value
    | MealCreated (Result String Meal)
    | GetSucceeds (Result String MealWithComments)
    | GetFails Je.Value
    | UpdateSucceeds (Result String MealWithComments)
    | UpdateFails Je.Value
    | MealUpdated (Result String Meal)


channel : Channel ChannelState
channel =
    let
        ( payLoad, response ) =
            listParams defaultPaginationParamsVar

        ( _, _, createResponse ) =
            graphQlEndpointHelper
                createRequest
                { meal = ""
                , time = ""
                , comment = Nothing
                }

        updateResponse =
            Jd.decodeValue mealDecoder
    in
        channelName
            |> Channel.init
            |> Channel.withPayload payLoad
            |> Channel.onRequestJoin Joining
            |> Channel.onJoin (Joined << response)
            |> Channel.onLeave (\_ -> Left)
            |> Channel.on "meal_created" (MealCreated << createResponse)
            |> Channel.on "meal_updated" (MealUpdated << updateResponse)
            |> Channel.withDebug



-- CREATE NEW MEAL


create : CreateQueryVars -> Push ChannelState
create vars =
    let
        ( query, params ) =
            graphQlQueryParams <| createRequest vars

        idResponse =
            Jd.decodeValue <| Jd.field "id" <| Jd.map toMealId Jd.string

        payLoad =
            Je.object
                [ ( "query", Je.string query )
                , ( "params", params )
                ]
    in
        Push.init channelName "new_meal"
            |> Push.withPayload payLoad
            |> Push.onOk (CreateSucceeds << idResponse)
            |> Push.onError CreateFails


type alias CreateQueryVars =
    { meal : String
    , time : String
    , comment : Maybe { text : String }
    }


createMutationName : String
createMutationName =
    "meal"


createRequest : CreateQueryVars -> Request Mutation Meal
createRequest ({ comment } as queryVars) =
    let
        mealVar =
            Var.required "meal" .meal Var.string

        timeVar =
            Var.required "time" .time Var.string

        commentVar_ =
            Var.object
                "Comment"
                [ Var.field "text" .text Var.string ]

        commentVar =
            Var.required "comment" .comment (Var.nullable commentVar_)

        idResponse =
            Grb.extract <|
                Grb.field "id"
                    []
                    (Grb.map toMealId Grb.id)

        mutation : Document Mutation Meal CreateQueryVars
        mutation =
            Grb.mutationDocument <|
                Grb.extract <|
                    Grb.field
                        createMutationName
                        [ ( "meal", Arg.variable mealVar )
                        , ( "time", Arg.variable timeVar )
                        , ( "comment", Arg.variable commentVar )
                        ]
                        mealResponse
    in
        Grb.request queryVars mutation



-- LIST MEALS, PAGINATING RESPONSE


list : PaginationParamsVars -> Push ChannelState
list vars =
    let
        ( payLoad, response ) =
            listParams vars
    in
        Push.init channelName "list_meals"
            |> Push.withPayload payLoad
            |> Push.onOk (ListSucceeds << response)
            |> Push.onError ListFails


listParams :
    PaginationParamsVars
    -> ( Je.Value, Jd.Value -> Result String PaginatedMeals )
listParams vars =
    let
        ( query, params, response ) =
            graphQlEndpointHelper paginatedMealsRequest vars

        payLoad =
            Je.object
                [ ( "query", Je.string query )
                , ( "params", params )
                ]
    in
        ( payLoad, response )


paginatedMealsQueryName : String
paginatedMealsQueryName =
    "paginatedMeals"


paginatedMealsResponse : ValueSpec Grb.NonNull Grb.ObjectType PaginatedMeals vars
paginatedMealsResponse =
    Grb.object PaginatedMeals
        |> Grb.with (Grb.field "entries" [] <| Grb.list mealResponse)
        |> Grb.with (Grb.field "pagination" [] paginationGraphQlResponse)


paginatedMealsRequest :
    PaginationParamsVars
    -> Request Query PaginatedMeals
paginatedMealsRequest params =
    let
        paginationVar =
            Var.required "pagination" .pagination paginationVarSpec

        queryRoot : Document Query PaginatedMeals PaginationParamsVars
        queryRoot =
            Grb.queryDocument <|
                Grb.extract <|
                    Grb.field
                        paginatedMealsQueryName
                        [ ( "pagination", Arg.variable paginationVar ) ]
                        paginatedMealsResponse
    in
        Grb.request params queryRoot



-- Get meal by Id


get : String -> Push ChannelState
get id_ =
    let
        ( query, params, response ) =
            graphQlEndpointHelper mealQueryRequest id_

        payLoad =
            Je.object
                [ ( "query", Je.string query )
                , ( "params", params )
                ]
    in
        Push.init channelName "get_meal"
            |> Push.withPayload payLoad
            |> Push.onOk (GetSucceeds << response)
            |> Push.onError GetFails


mealQueryName : String
mealQueryName =
    "meal"


mealQueryRequest :
    String
    -> Request Query MealWithComments
mealQueryRequest id_ =
    let
        idVar =
            Var.required "id" (always id_) Var.id

        queryRoot : Document Query MealWithComments String
        queryRoot =
            Grb.queryDocument <|
                Grb.extract <|
                    Grb.field
                        mealQueryName
                        [ ( "id", Arg.variable idVar ) ]
                        mealWithCommentResponse
    in
        Grb.request id_ queryRoot



-- update a meal


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
        Push.init channelName "update_meal"
            |> Push.withPayload payLoad
            |> Push.onOk (UpdateSucceeds << response)
            |> Push.onError UpdateFails


type alias UpdateParams =
    { id : MealId
    , meal : Maybe String
    , time : Maybe String
    }


updateMutationName : String
updateMutationName =
    "mealUpdate"


updateRequest :
    UpdateParams
    -> Request Mutation MealWithComments
updateRequest params =
    let
        idVar =
            Var.required "id" (.id >> fromMealId) Var.id

        mealVar =
            Var.required "meal" .meal (Var.nullable Var.string)

        timeVar =
            Var.required "time" .time (Var.nullable Var.string)

        queryRoot : Document Mutation MealWithComments UpdateParams
        queryRoot =
            Grb.mutationDocument <|
                Grb.extract <|
                    Grb.field
                        updateMutationName
                        [ ( "id", Arg.variable idVar )
                        , ( "meal", Arg.variable mealVar )
                        , ( "time", Arg.variable timeVar )
                        ]
                        mealWithCommentResponse
    in
        Grb.request params queryRoot



--------------------------------------------------------


mealResponse : ValueSpec Grb.NonNull Grb.ObjectType Meal vars
mealResponse =
    Grb.object Meal
        |> Grb.with (Grb.field "id" [] (Grb.map Types.toMealId Grb.id))
        |> Grb.with (Grb.field "meal" [] Grb.string)
        |> Grb.with (Grb.field "time" [] Utils.dateTimeType)


mealWithCommentResponse : ValueSpec Grb.NonNull Grb.ObjectType MealWithComments vars
mealWithCommentResponse =
    Grb.object MealWithComments
        |> Grb.with (Grb.field "id" [] (Grb.map Types.toMealId Grb.id))
        |> Grb.with (Grb.field "meal" [] Grb.string)
        |> Grb.with (Grb.field "time" [] Utils.dateTimeType)
        |> Grb.with (Grb.field "comments" [] (Grb.list commentResponse))


commentResponse : ValueSpec Grb.NonNull Grb.ObjectType Comment vars
commentResponse =
    Grb.object Comment
        |> Grb.with (Grb.field "id" [] (Grb.map Types.toCommentId Grb.id))
        |> Grb.with (Grb.field "text" [] Grb.string)
        |> Grb.with (Grb.field "insertedAt" [] Utils.dateTimeType)
