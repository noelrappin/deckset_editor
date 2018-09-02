module Model exposing
    ( Mode(..)
    , Model
    , Presentation
    , Slide
    , isNextAfter
    , isPreviousTo
    , loadFromValue
    , newSlideAfter
    , nextSlide
    , presentationInOrder
    , presentationToString
    , previousSlide
    , slideFromIntAndText
    , textToPresentation
    , windowTitle
    )

import Debug
import Json.Decode as Decode exposing (Decoder, float, int, string)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
import Json.Encode exposing (Value)
import List.Extra as List
import Tuple


type Mode
    = Display
    | Edit


type alias Slide =
    { text : String
    , order : Int
    , mode : Mode
    , editText : String
    }


type alias FileImport =
    { filename : String
    , body : String
    }


type alias Presentation =
    List Slide


type alias Model =
    { presentation : Presentation
    , filename : String
    , clean : Bool
    }


fileImportDecoder : Decoder FileImport
fileImportDecoder =
    Decode.succeed FileImport
        |> required "filename" string
        |> required "body" string


decodeFileImport : Value -> Result Decode.Error FileImport
decodeFileImport value =
    Decode.decodeValue fileImportDecoder value


loadFromValue : Value -> Model -> Model
loadFromValue value model =
    case decodeFileImport value of
        Ok fileImport ->
            loadFromImport fileImport model

        Result.Err error ->
            model


loadFromImport : FileImport -> Model -> Model
loadFromImport fileImport model =
    { model
        | presentation = textToPresentation fileImport.body
        , filename = fileImport.filename
    }


slideFromIntAndText : Int -> String -> Slide
slideFromIntAndText int text =
    { text = String.trim text
    , order = int
    , mode = Display
    , editText = ""
    }


textToPresentation : String -> Presentation
textToPresentation text =
    String.split "---" text
        |> List.indexedMap slideFromIntAndText


presentationInOrder : Presentation -> Presentation
presentationInOrder presentation =
    presentation
        |> List.sortBy .order


presentationToString : Presentation -> String
presentationToString presentation =
    presentationInOrder presentation
        |> List.map .text
        |> String.join "\n---\n"


previousSlide : Slide -> Presentation -> Maybe Slide
previousSlide slide presentation =
    presentation
        |> List.filter (isPreviousTo slide)
        |> List.head


nextSlide : Slide -> Presentation -> Maybe Slide
nextSlide slide presentation =
    presentation
        |> List.filter (isNextAfter slide)
        |> List.head


isPreviousTo : Slide -> Slide -> Bool
isPreviousTo targetSlide testSlide =
    testSlide.order == (targetSlide.order - 1)


isNextAfter : Slide -> Slide -> Bool
isNextAfter targetSlide testSlide =
    testSlide.order == (targetSlide.order + 1)


newSlideAfter : Maybe Slide -> Slide
newSlideAfter slide =
    { text = ""
    , order =
        case slide of
            Nothing ->
                0

            Just s ->
                s.order + 1
    , mode = Edit
    , editText = ""
    }


windowTitle : Model -> String
windowTitle model =
    "Deckset Editor: " ++ model.filename
