port module Ports exposing (loadPresentationText, openFileDialog, savePresentationText)


port savePresentationText : String -> Cmd msg


port openFileDialog : () -> Cmd msg


port loadPresentationText : (String -> msg) -> Sub msg
