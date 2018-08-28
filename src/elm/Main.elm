module Main exposing (init, main, subscriptions)

import Browser
import Model exposing (Model, Presentation, Slide)
import Ports
import String
import Update exposing (Message)
import View exposing (view)


init : () -> ( Model, Cmd Message )
init _ =
    ( { presentation = Model.textToPresentation Model.testString }, Cmd.none )


subscriptions : Model -> Sub Message
subscriptions model =
    Sub.none


main : Program () Model Message
main =
    Browser.element
        { init = init
        , view = view
        , update = Update.update
        , subscriptions = subscriptions
        }
