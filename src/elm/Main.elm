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
    ( Model.init, Cmd.none )


subscriptions : Model -> Sub Message
subscriptions model =
    Sub.batch
        [ Ports.loadPresentationText Update.LoadPresentation
        , Ports.updateFileName Update.UpdateFileName
        , Ports.externalSaveMenuClicked (always Update.SavePresentation)
        , Ports.externalUndoMenuClicked (always Update.Undo)
        , Ports.externalRedoMenuClicked (always Update.Redo)
        , Ports.externalUpMenuClicked
            (always <| Update.SlideUp <| Model.selectedSlide model)
        , Ports.externalDownMenuClicked
            (always <| Update.SlideDown <| Model.selectedSlide model)
        ]


main : Program () Model Message
main =
    Browser.element
        { init = init
        , view = view
        , update = Update.update
        , subscriptions = subscriptions
        }
