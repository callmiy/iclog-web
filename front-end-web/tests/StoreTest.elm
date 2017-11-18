module StoreTest
    exposing
        ( addObservationTest
        , updateObservationTest
        )

import Test exposing (..)
import Expect
import Store
    exposing
        ( Store
        , addObservation
        , updatePaginatedObservations
        , updateObservation
        )
import Utils exposing (defaultPagination)
import Observation.Types exposing (Observation)
import Date.Extra.Create as CreateDate exposing (dateFromFields)
import Date


updateObservationTest : Test
updateObservationTest =
    describe "Store updateObservation"
        [ test "update an observation" <|
            \_ ->
                let
                    obs =
                        makeObservation 3

                    left_ =
                        (makeObservations 1 2)

                    right_ =
                        (makeObservations 4 3)

                    entries =
                        left_ ++ [ obs ] ++ right_

                    pgn =
                        { defaultPagination | totalEntries = 6 }

                    pgnObs =
                        { entries = entries
                        , pagination = pgn
                        }

                    updatedObs =
                        { obs
                            | comment = "updated comment"
                        }

                    updatedEntries =
                        [ updatedObs ] ++ left_ ++ right_

                    updatedPgnObs =
                        { pgnObs
                            | entries = updatedEntries
                        }

                    actual =
                        updatePaginatedObservations pgnObs emptyStore
                            |> updateObservation updatedObs

                    expected =
                        updatePaginatedObservations updatedPgnObs emptyStore
                in
                    Expect.equal actual expected
        ]


addObservationTest : Test
addObservationTest =
    describe "Store addObservation"
        [ test "add entries within same page" <|
            \_ ->
                let
                    entries =
                        makeObservations 1 9

                    newEntry =
                        makeObservation 10

                    pgn =
                        { defaultPagination | totalEntries = 9 }

                    pgnObs =
                        { entries = entries
                        , pagination = pgn
                        }

                    updatedPgn =
                        { defaultPagination
                            | totalPages = 1
                            , totalEntries = 10
                        }

                    updatedEntries =
                        List.take updatedPgn.pageSize <|
                            newEntry
                                :: entries

                    updatedPgnObs =
                        { entries = updatedEntries
                        , pagination = updatedPgn
                        }

                    actual =
                        updatePaginatedObservations pgnObs emptyStore
                            |> addObservation newEntry

                    expected =
                        updatePaginatedObservations updatedPgnObs emptyStore
                in
                    Expect.equal actual expected
        , test "add entries goes to next page same page" <|
            \_ ->
                let
                    entries =
                        makeObservations 1 10

                    newEntry =
                        makeObservation 11

                    pgn =
                        { defaultPagination | totalEntries = 10 }

                    pgnObs =
                        { entries = entries
                        , pagination = pgn
                        }

                    updatedPgn =
                        { defaultPagination
                            | totalPages = 2
                            , totalEntries = 11
                        }

                    updatedEntries =
                        List.take updatedPgn.pageSize <| newEntry :: entries

                    updatedPgnObs =
                        { entries = updatedEntries
                        , pagination = updatedPgn
                        }

                    actual =
                        updatePaginatedObservations pgnObs emptyStore
                            |> addObservation newEntry

                    expected =
                        updatePaginatedObservations updatedPgnObs emptyStore
                in
                    Expect.equal actual expected
        ]


makeObservation : Int -> Observation
makeObservation id_ =
    let
        id =
            toString id_
    in
        { id = id
        , comment = "comment" ++ id
        , insertedAt = dateFromFields 2017 Date.Nov id_ 7 9 20 10
        , meta = { id = id, title = "title" ++ id }
        }


makeObservations : Int -> Int -> List Observation
makeObservations start howMany =
    List.range 1 howMany
        |> List.map (\i -> makeObservation <| i + start - 1)


emptyStore : Store
emptyStore =
    Store.create
        { apiUrl = Nothing
        , websocketUrl = Nothing
        , timeZoneOffset = 0
        }
