module Main exposing (init, main, subscriptions)

import Browser
import Html5.DragDrop as DragDrop
import Model exposing (Model, Presentation, Slide)
import Ports
import String
import Update exposing (Message)
import View exposing (view)


init : () -> ( Model, Cmd Message )
init _ =
    ( { presentation = []
      , filename = ""
      , clean = True
      , dragDrop = DragDrop.init
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Message
subscriptions model =
    Sub.batch
        [ Ports.loadPresentationText Update.LoadPresentation
        , Ports.updateFileName Update.UpdateFileName
        ]


main : Program () Model Message
main =
    Browser.element
        { init = init
        , view = view
        , update = Update.update
        , subscriptions = subscriptions
        }
