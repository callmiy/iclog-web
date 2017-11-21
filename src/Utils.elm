module Utils
    exposing
        ( (=>)
        , DateTimeType
        , dateTimeType
        , Pagination
        , paginationGraphQlResponse
        , PaginationParams
        , PaginationParamsVars
        , paginationVarSpec
        , makeDefaultPaginationParamsVar
        , defaultPaginationParamsVar
        , defaultPagination
        , nonBreakingSpace
        , toPaginationParamsVars
        , nonEmpty
        , unquoteString
        , unSubmit
        , unknownServerError
        , updatePaginationEntriesBy
        , graphQlEndpointHelper
        , decodeGraphQlResponse
        , formatDateForForm
        , formatDateISOWithTimeZone
        , graphQlQueryParams
        , decodeErrorMsg
        , (<=>)
        , focusEl
        )

import Date exposing (Date)
import GraphQL.Request.Builder as Grb
    exposing
        ( ValueSpec
        , NonNull
        , customScalar
        , Request
        )
import GraphQL.Request.Builder.Variable as Var
    exposing
        ( VariableSpec
        , Variable
        )
import Json.Decode as Jd exposing (Decoder)
import Form.Validate as Validate exposing (Validation)
import Json.Encode as Je
import Date.Format as DateFormat
import Date.Extra.Duration as Duration
import Task
import Dom


(=>) : a -> b -> ( a, b )
(=>) =
    (,)
infixl 0 =>


(<=>) : a -> b -> c -> ( a, b, c )
(<=>) a b c =
    ( a, b, c )


type DateTimeType
    = DateTimeType



-- GRAPHQL HELPERS


type alias Pagination =
    { pageNumber : Int
    , pageSize : Int
    , totalPages : Int
    , totalEntries : Int
    }


defaultPagination : Pagination
defaultPagination =
    { pageNumber = 1
    , pageSize = 10
    , totalPages = 0
    , totalEntries = 0
    }


updatePaginationEntriesBy : Int -> Pagination -> Pagination
updatePaginationEntriesBy howMany ({ pageSize, totalEntries } as pagination) =
    let
        totalEntries_ =
            totalEntries + howMany

        totalPages =
            ceiling (toFloat totalEntries_ / toFloat pageSize)
    in
        { pagination
            | totalEntries = totalEntries_
            , totalPages = totalPages
        }


paginationGraphQlResponse : ValueSpec Grb.NonNull Grb.ObjectType Pagination vars
paginationGraphQlResponse =
    Grb.object Pagination
        |> Grb.with (Grb.field "pageNumber" [] Grb.int)
        |> Grb.with (Grb.field "pageSize" [] Grb.int)
        |> Grb.with (Grb.field "totalPages" [] Grb.int)
        |> Grb.with (Grb.field "totalEntries" [] Grb.int)


type alias PaginationParams =
    { page : Int
    , pageSize : Maybe Int
    }


type alias PaginationParamsVars =
    -- This is the object that will be sent as variable to graphql endpoint
    { pagination : PaginationParams
    }


defaultPaginationParamsVar : PaginationParamsVars
defaultPaginationParamsVar =
    makeDefaultPaginationParamsVar 1 (Just 10)


makeDefaultPaginationParamsVar : Int -> Maybe Int -> PaginationParamsVars
makeDefaultPaginationParamsVar page maybePageSize =
    PaginationParamsVars <|
        PaginationParams page maybePageSize


paginationVarSpec : VariableSpec Var.NonNull PaginationParams
paginationVarSpec =
    Var.object
        "PaginationParams"
        [ Var.field "page" .page Var.int
        , Var.field "pageSize" .pageSize (Var.nullable Var.int)
        ]


toPaginationParamsVars : Pagination -> PaginationParamsVars
toPaginationParamsVars { pageNumber, pageSize } =
    PaginationParamsVars
        { page = pageNumber
        , pageSize = Just pageSize
        }


dateTimeType : ValueSpec NonNull DateTimeType Date vars
dateTimeType =
    Jd.string
        |> Jd.andThen
            (\date_ ->
                case Date.fromString date_ of
                    Ok date ->
                        Jd.succeed date

                    Err err ->
                        Jd.fail err
            )
        |> customScalar DateTimeType


nonBreakingSpace : String
nonBreakingSpace =
    " "


nonEmpty : Int -> Validation a String
nonEmpty minLength =
    Validate.string
        |> Validate.andThen Validate.nonEmpty
        |> Validate.andThen (Validate.minLength minLength)


{-| Given a quoted text, strip the quotes from the text.

Example:
unquoteString ""quoteted text"" == "quoted text"

    unquoteString "unqoted text" == "unquoted"

-}
unquoteString : String -> String
unquoteString text =
    case ( String.startsWith "\"" text, String.endsWith "\"" text ) of
        ( True, True ) ->
            text
                |> String.dropLeft 1
                |> String.dropRight 1

        _ ->
            text


unSubmit : { r | submitting : Bool } -> { r | submitting : Bool }
unSubmit updatedModel =
    { updatedModel | submitting = False }


unknownServerError :
    { r | serverError : Maybe String }
    -> { r | serverError : Maybe String }
unknownServerError model =
    { model | serverError = Just "Something went wrong!" }


graphQlQueryParams : Request operationType result -> ( String, Je.Value )
graphQlQueryParams request =
    let
        query : String
        query =
            Grb.requestBody request

        params : Je.Value
        params =
            Grb.jsonVariableValues request
                |> Maybe.withDefault Je.null
    in
        ( query, params )


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

        ( query, params ) =
            graphQlQueryParams request

        response =
            decodeGraphQlResponse responseDecoder
    in
        ( query, params, response )


decodeGraphQlResponse : Decoder a -> Jd.Value -> Result String a
decodeGraphQlResponse d response =
    Jd.decodeValue (Jd.at [ "data" ] d) response


formatDateForForm : Date -> String
formatDateForForm date =
    DateFormat.format "%a %d/%b/%y %I:%M %p" date


formatDateISOWithTimeZone :
    Int
    -> Date
    -> String
formatDateISOWithTimeZone tzOffset date =
    Duration.add Duration.Minute tzOffset date
        |> DateFormat.formatISO8601


decodeErrorMsg : msg -> String
decodeErrorMsg msg =
    "\n\nError decoding response " ++ toString msg


focusEl : String -> (() -> msg) -> Cmd msg
focusEl id_ msg =
    Task.attempt (Result.withDefault () >> msg) <|
        Dom.focus id_
