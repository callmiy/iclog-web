module Page
    exposing
        ( Page(..)
        , PageState(..)
        , getPage
        )

import Observation.Detail.App as ObservationDetail
import Observation.List as ObservationList
import Observation.New.App as ObservationNew


type Page
    = ObservationDetail ObservationDetail.Model
    | ObservationList ObservationList.Model
    | ObservationNew ObservationNew.Model


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
