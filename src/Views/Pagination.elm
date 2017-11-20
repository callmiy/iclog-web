module Views.Pagination exposing (viewPagination)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events exposing (onClick)
import Utils exposing (Pagination)


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
