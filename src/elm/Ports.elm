port module Ports exposing
    ( loadPresentationText
    , openFileDialog
    , savePresentationText
    , updateFileName
    , updateWindowTitle
    )

import Json.Encode as Encode exposing (Value)


port savePresentationText : Encode.Value -> Cmd msg


port openFileDialog : () -> Cmd msg


port loadPresentationText : (Value -> msg) -> Sub msg


port updateWindowTitle : String -> Cmd msg


port updateFileName : (Value -> msg) -> Sub msg
