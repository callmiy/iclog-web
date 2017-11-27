module Sleep.Types
    exposing
        ( SleepWithComments
        , SleepId
        , PaginatedSleeps
        , Sleep
        , fromSleepId
        , toSleepId
        , sleepDecoder
        , sleepDuration
        )

import Date exposing (Date)
import Utils exposing (Pagination)
import Json.Decode as Jd exposing (Decoder)
import Json.Decode.Extra as Jde exposing ((|:))
import Comment exposing (Comment)
import Date.Extra.Duration as Duration


type alias SleepWithComments =
    { id : SleepId
    , start : Date
    , end : Date
    , comments : List Comment
    }


type alias Sleep =
    { id : SleepId
    , start : Date
    , end : Date
    }


type alias PaginatedSleeps =
    { entries : List Sleep
    , pagination : Pagination
    }


type SleepId
    = SleepId String


fromSleepId : SleepId -> String
fromSleepId (SleepId id_) =
    id_


toSleepId : String -> SleepId
toSleepId id_ =
    SleepId id_


sleepDecoder : Decoder Sleep
sleepDecoder =
    Jd.succeed Sleep
        |: (Jd.field "id" <| Jd.map toSleepId Jd.string)
        |: (Jd.field "start" Jde.date)
        |: (Jd.field "end" Jde.date)


sleepDuration : Date -> Date -> String
sleepDuration start end =
    let
        diff =
            Duration.diff end start

        hrStr =
            if diff.hour > 1 then
                " hrs, "
            else
                " hr, "

        minStr =
            if diff.minute > 1 then
                toString diff.minute ++ " mins"
            else
                "0 min"
    in
        toString diff.hour
            ++ hrStr
            ++ minStr
