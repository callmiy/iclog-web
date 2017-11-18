port module Stylesheets exposing (..)

import Css.File exposing (CssCompilerProgram, CssFileStructure)
import Observation.Styles as Observation
import AutocompleteStyles
import AppStyles


port files : CssFileStructure -> Cmd msg


fileStructure : CssFileStructure
fileStructure =
    Css.File.toFileStructure
        [ ( "src/style.css"
          , Css.File.compile
                [ Observation.css
                , AutocompleteStyles.css
                , AppStyles.css
                ]
          )
        ]


main : CssCompilerProgram
main =
    Css.File.compiler files fileStructure
