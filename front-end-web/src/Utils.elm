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
        , viewPagination
        , toPaginationParamsVars
        , nonEmpty
        , unquoteString
        , unSubmit
        , unknownServerError
        )

import Date exposing (Date)
import GraphQL.Request.Builder as Grb exposing (ValueSpec, NonNull, customScalar)
import GraphQL.Request.Builder.Variable as Var exposing (VariableSpec, Variable)
import Json.Decode as Jd exposing (Decoder)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events exposing (onClick)
import Form.Validate as Validate exposing (Validation)


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


viewPagination :
    Pagination
    -> (Pagination -> msg)
    -> Html msg
viewPagination ({ pageNumber, totalPages } as pagination) nextPageMsg =
    Html.div
        [ Attr.style [ ( "text-align", "center" ) ] ]
        [ Html.div
            [ Attr.class "btn-group" ]
            [ Html.button
                [ Attr.type_ "button"
                , Attr.class "btn btn-outline-secondary"
                , Attr.disabled <| pageNumber < 2
                , onClick <|
                    nextPageMsg { pagination | pageNumber = pageNumber - 1 }
                , Attr.id "pagination-previous-page-arrow"
                ]
                [ Html.text "<" ]
            , Html.button
                [ Attr.type_ "button"
                , Attr.class "btn btn-outline-secondary"
                , Attr.disabled <| pageNumber == totalPages
                , onClick <|
                    nextPageMsg { pagination | pageNumber = pageNumber + 1 }
                , Attr.id "pagination-next-page-arrow"
                ]
                [ Html.text ">" ]
            ]
        , Html.div
            []
            [ Html.text <|
                "Page "
                    ++ (toString pageNumber)
                    ++ " of "
                    ++ (toString totalPages)
            ]
        ]


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
