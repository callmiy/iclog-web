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
        )

import Date exposing (Date)
import GraphQL.Request.Builder as Grb exposing (ValueSpec, NonNull, customScalar)
import GraphQL.Request.Builder.Variable as Var exposing (VariableSpec, Variable)
import Json.Decode as Jd exposing (Decoder)


(=>) : a -> b -> ( a, b )
(=>) =
    (,)
infixl 0 =>


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


paginationGraphQlResponse : ValueSpec Grb.NonNull Grb.ObjectType Pagination vars
paginationGraphQlResponse =
    Grb.object Pagination
        |> Grb.with (Grb.field "pageNumber" [] Grb.int)
        |> Grb.with (Grb.field "pageSize" [] Grb.int)
        |> Grb.with (Grb.field "totalPages" [] Grb.int)
        |> Grb.with (Grb.field "totalEntries" [] Grb.int)


type alias PaginationParams =
    { pageNumber : Int
    , pageSize : Maybe Int
    , totalPages : Maybe Int
    , totalEntries : Maybe Int
    }


type alias PaginationParamsVars =
    -- This is the object that will be sent as variable to graphql endpoint
    { pagination : PaginationParams
    }


defaultPaginationParamsVar : PaginationParamsVars
defaultPaginationParamsVar =
    makeDefaultPaginationParamsVar 1 (Just 10)


makeDefaultPaginationParamsVar : Int -> Maybe Int -> PaginationParamsVars
makeDefaultPaginationParamsVar pageNumber maybePageSize =
    PaginationParamsVars <|
        PaginationParams pageNumber maybePageSize Nothing Nothing


paginationVarSpec : VariableSpec Var.NonNull PaginationParams
paginationVarSpec =
    Var.object
        "PaginationParams"
        [ Var.field "pageNumber" .pageNumber Var.int
        , Var.field "pageSize" .pageSize (Var.nullable Var.int)
        , Var.field "totalPages" .totalPages (Var.nullable Var.int)
        , Var.field "totalEntries" .totalEntries (Var.nullable Var.int)
        ]


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
