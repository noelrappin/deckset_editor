port module Ports exposing
    ( externalRedoMenuClicked
    , externalSaveMenuClicked
    , externalUndoMenuClicked
    , loadPresentationText
    , openFileDialog
    , savePresentationText
    , updateFileName
    , updateWindowTitle
    )

import Json.Encode as Encode exposing (Value)


port loadPresentationText : (Value -> msg) -> Sub msg


port openFileDialog : () -> Cmd msg


port savePresentationText : Encode.Value -> Cmd msg


port updateFileName : (Value -> msg) -> Sub msg


port updateWindowTitle : String -> Cmd msg


port externalSaveMenuClicked : (() -> msg) -> Sub msg


port externalUndoMenuClicked : (() -> msg) -> Sub msg


port externalRedoMenuClicked : (() -> msg) -> Sub msg
