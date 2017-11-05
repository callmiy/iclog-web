module Store
    exposing
        ( Store
        , Flag
        , getWebsocketUrl
        , create
        )


type alias Flag =
    { apiUrl : Maybe String
    , websocketUrl : Maybe String
    }


type Store
    = Store
        { apiUrl : Maybe String
        , websocketUrl : Maybe String
        }


create : Flag -> Store
create flag =
    Store flag


getWebsocketUrl : Store -> Maybe String
getWebsocketUrl (Store { websocketUrl }) =
    websocketUrl
