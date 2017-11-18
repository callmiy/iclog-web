module Observation.Utils exposing (stringGt)


stringGt : String -> Int -> Bool
stringGt string size =
    (>) (String.length string) size
