port module Ports exposing
    ( loadPresentationText
    , openFileDialog
    , savePresentationText
    , updateWindowTitle
    )

import Json.Encode exposing (Value)


port savePresentationText : String -> Cmd msg


port openFileDialog : () -> Cmd msg


port loadPresentationText : (Value -> msg) -> Sub msg


port updateWindowTitle : String -> Cmd msg
