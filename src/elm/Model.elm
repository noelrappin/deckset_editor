module Model exposing
    ( DragResult
    , Mode(..)
    , Model
    , Order
    , Presentation
    , Slide
    , UpdateType(..)
    , encodeFileInfo
    , init
    , isNextAfter
    , isPreviousTo
    , isSelected
    , loadFromValue
    , newSlideAfter
    , nextSlide
    , presentationInOrder
    , presentationToString
    , previousSlide
    , selectedSlide
    , selectedSlideExportInfo
    , slideAtOrder
    , slideFromIntAndText
    , textToPresentation
    , updateFilename
    , windowTitle
    )

import Debug
import Html5.DragDrop as DragDrop
import Json.Decode as Decode exposing (Decoder, float, int, string)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
import Json.Encode as Encode exposing (Value)
import List.Extra as List
import Regex
import Tuple
import Undo exposing (UndoState)


type Mode
    = Display
    | Edit


type Order
    = Order Int


type UpdateType
    = LeftClick
    | RightClick


type alias Slide =
    { text : String
    , order : Order
    , mode : Mode
    , editText : String
    }


type alias FileImport =
    { filename : String
    , body : String
    }


type alias Presentation =
    List Slide


type alias DragResult =
    Maybe ( Order, Order, DragDrop.Position )


type alias Model =
    { presentation : Presentation
    , filename : String
    , clean : Bool
    , dragDrop : DragDrop.Model Order Order
    , undoState : UndoState Presentation
    , selected : Maybe Int
    }


init : Model
init =
    { presentation = []
    , filename = ""
    , clean = True
    , dragDrop = DragDrop.init
    , undoState = Undo.initialUndoState
    , selected = Nothing
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
    , order = Order int
    , mode = Display
    , editText = ""
    }


slideOrder : Slide -> Int
slideOrder slide =
    let
        (Order int) =
            slide.order
    in
    int


orderToInt : Order -> Int
orderToInt (Order int) =
    int


previousOrder : Order -> Order
previousOrder (Order int) =
    Order (int - 1)


nextOrder : Order -> Order
nextOrder (Order int) =
    Order (int + 1)


slideDelimiterRegex : Regex.Regex
slideDelimiterRegex =
    Maybe.withDefault Regex.never <|
        Regex.fromStringWith
            { caseInsensitive = False
            , multiline = True
            }
            "^-{3,}"


textToPresentation : String -> Presentation
textToPresentation text =
    Regex.split slideDelimiterRegex text
        |> List.indexedMap slideFromIntAndText


presentationInOrder : Presentation -> Presentation
presentationInOrder presentation =
    presentation
        |> List.sortBy slideOrder


presentationToString : Presentation -> String
presentationToString presentation =
    presentationInOrder presentation
        |> List.map .text
        |> String.join "\n\n---\n\n"


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
    testSlide.order == previousOrder targetSlide.order


isNextAfter : Slide -> Slide -> Bool
isNextAfter targetSlide testSlide =
    testSlide.order == nextOrder targetSlide.order


newSlideAfter : Maybe Slide -> Slide
newSlideAfter slide =
    { text = ""
    , order =
        case slide of
            Nothing ->
                Order 0

            Just s ->
                nextOrder s.order
    , mode = Edit
    , editText = ""
    }


windowTitle : Model -> String
windowTitle model =
    "Deckset Editor: " ++ model.filename


encodeFileInfo : Model -> Value
encodeFileInfo model =
    Encode.object
        [ ( "filename", Encode.string model.filename )
        , ( "body"
          , Encode.string <| presentationToString model.presentation
          )
        ]


modeToString : Mode -> String
modeToString mode =
    case mode of
        Edit ->
            "edit"

        Display ->
            "display"


selectedSlideExportInfo : Model -> UpdateType -> Value
selectedSlideExportInfo model updateType =
    encodeSlideExportInfo updateType <| selectedSlide model


encodeSlideExportInfo : UpdateType -> Maybe Slide -> Value
encodeSlideExportInfo updateType maybeSlide =
    case maybeSlide of
        Nothing ->
            Encode.null

        Just slide ->
            Encode.object
                [ ( "order", Encode.int <| orderToInt slide.order )
                , ( "mode", Encode.string <| modeToString slide.mode )
                , ( "contextMenu", Encode.bool <| updateType == RightClick )
                ]


updateFilename : Value -> Model -> Model
updateFilename filenameValue model =
    let
        result =
            Decode.decodeValue Decode.string filenameValue
    in
    case result of
        Ok filename ->
            { model | filename = filename }

        Err _ ->
            model


isSelected : Model -> Slide -> Bool
isSelected model slide =
    case model.selected of
        Nothing ->
            False

        Just selectedInt ->
            slide.order == Order selectedInt


slideEqualsOrder : Maybe Int -> Slide -> Bool
slideEqualsOrder maybeOrder slide =
    case maybeOrder of
        Nothing ->
            False

        Just order ->
            slide.order == Order order


slideAtOrder : Maybe Int -> Model -> Maybe Slide
slideAtOrder order model =
    model.presentation
        |> List.filter (slideEqualsOrder order)
        |> List.head


selectedSlide : Model -> Maybe Slide
selectedSlide model =
    slideAtOrder model.selected model
