module Page
    exposing
        ( Page(..)
        , PageState(..)
        , getPage
        )

import Observation.Model as ObservationPage


type Page
    = Observation ObservationPage.Model


type PageState
    = Loaded Page
    | RedirectingTo Page


getPage : PageState -> Page
getPage p =
    case p of
        Loaded page ->
            page

        RedirectingTo page ->
            page
