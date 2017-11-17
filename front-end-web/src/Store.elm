module Store
    exposing
        ( Store
        , Flag
        , TimeZoneOffset
        , getWebsocketUrl
        , create
        , getTimeZoneOffset
        , toTimeZoneVal
        )


type alias Flag =
    { apiUrl : Maybe String
    , websocketUrl : Maybe String
    , timeZoneOffset : Int
    }


type TimeZoneOffset
    = TimeZoneOffset Int


type Store
    = Store
        { apiUrl : Maybe String
        , websocketUrl : Maybe String
        , timeZoneOffset : TimeZoneOffset
        }


create : Flag -> Store
create { apiUrl, websocketUrl, timeZoneOffset } =
    Store
        { apiUrl = apiUrl
        , websocketUrl = websocketUrl
        , timeZoneOffset = TimeZoneOffset timeZoneOffset
        }


getWebsocketUrl : Store -> Maybe String
getWebsocketUrl (Store { websocketUrl }) =
    websocketUrl


getTimeZoneOffset : Store -> TimeZoneOffset
getTimeZoneOffset (Store { timeZoneOffset }) =
    timeZoneOffset


toTimeZoneVal : TimeZoneOffset -> Int
toTimeZoneVal (TimeZoneOffset val) =
    val
