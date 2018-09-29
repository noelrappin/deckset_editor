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
    let
        selectedSlide =
            Model.selectedSlide model
    in
    Sub.batch
        [ Ports.loadPresentationText Update.LoadPresentation
        , Ports.updateFileName Update.UpdateFileName
        , Ports.externalSaveMenuClicked (always Update.SavePresentation)
        , Ports.externalUndoMenuClicked (always Update.Undo)
        , Ports.externalRedoMenuClicked (always Update.Redo)
        , Ports.externalUpMenuClicked
            (always <| Update.SlideUp <| selectedSlide)
        , Ports.externalDownMenuClicked
            (always <| Update.SlideDown <| selectedSlide)
        , Ports.externalEditMenuClicked
            (always <| Update.EditSlide <| selectedSlide)
        , Ports.externalAppendMenuClicked
            (always <| Update.AppendSlide <| selectedSlide)
        , Ports.externalDeleteMenuClicked
            (always <| Update.RemoveSlide <| selectedSlide)
        , Ports.externalKeepChangesMenuClicked
            (always <| Update.SaveSlide <| selectedSlide)
        , Ports.externalDiscardChangesMenuClicked
            (always <| Update.CancelSlide <| selectedSlide)
        , Ports.externalDuplicateMenuClicked
            (always <| Update.DuplicateSlide <| selectedSlide)
        , Ports.externalMergeForwardMenuClicked
            (always <| Update.MergeSlideForward <| selectedSlide)
        , Ports.externalMergeBackwardMenuClicked
            (always <| Update.MergeSlideBackward <| selectedSlide)
        , Ports.externalExplodeMenuClicked
            (always <| Update.ExplodeSlide <| selectedSlide)
        ]


main : Program () Model Message
main =
    Browser.element
        { init = init
        , view = view
        , update = Update.update
        , subscriptions = subscriptions
        }
