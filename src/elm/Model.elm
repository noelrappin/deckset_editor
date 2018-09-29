module Model exposing
    ( DragResult
    , Model
    , Order
    , Presentation
    , Slide
    , UpdateType(..)
    , encodeFileInfo
    , explodeSlideStrings
    , init
    , isNextAfter
    , isPreviousTo
    , isSelected
    , loadFromValue
    , maybeOrderToInt
    , newSlideAfter
    , nextOrder
    , nextSlide
    , orderToInt
    , presentationInOrder
    , presentationToString
    , previousOrder
    , previousSlide
    , selectedSlide
    , selectedSlideExportInfo
    , slideAtOrder
    , slideFromIntAndText
    , slideOrder
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


type Order
    = Order Int


type UpdateType
    = LeftClick
    | RightClick


type alias Slide =
    { text : String
    , order : Order
    , editText : Maybe String
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
    , filename : Maybe String
    , clean : Bool
    , dragDrop : DragDrop.Model Order Order
    , undoState : UndoState Presentation
    , selected : Maybe Order
    }


init : Model
init =
    { presentation = []
    , filename = Nothing
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
        , filename = Just fileImport.filename
    }


slideFromIntAndText : Int -> String -> Slide
slideFromIntAndText int text =
    { text = String.trim text
    , order = Order int
    , editText = Nothing
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


maybeOrderToInt : Maybe Order -> Int
maybeOrderToInt maybeOrder =
    case maybeOrder of
        Nothing ->
            -1

        Just order ->
            orderToInt order


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


previousSlide : Maybe Slide -> Presentation -> Maybe Slide
previousSlide maybeSlide presentation =
    case maybeSlide of
        Just slide ->
            presentation
                |> List.filter (isPreviousTo slide)
                |> List.head

        Nothing ->
            Nothing


nextSlide : Maybe Slide -> Presentation -> Maybe Slide
nextSlide maybeSlide presentation =
    case maybeSlide of
        Just slide ->
            presentation
                |> List.filter (isNextAfter slide)
                |> List.head

        Nothing ->
            Nothing


isPreviousTo : Slide -> Slide -> Bool
isPreviousTo targetSlide testSlide =
    testSlide.order == previousOrder targetSlide.order


isNextAfter : Slide -> Slide -> Bool
isNextAfter targetSlide testSlide =
    testSlide.order == nextOrder targetSlide.order


newSlideAfter : Maybe Slide -> String -> Slide
newSlideAfter slide newText =
    { text = newText
    , order =
        case slide of
            Nothing ->
                Order 0

            Just s ->
                nextOrder s.order
    , editText = Just newText
    }


windowTitle : Model -> String
windowTitle model =
    "Deckset Editor: " ++ Maybe.withDefault "" model.filename


encodeFileInfo : Model -> Value
encodeFileInfo model =
    Encode.object
        [ ( "filename", Encode.string <| Maybe.withDefault "" model.filename )
        , ( "body"
          , Encode.string <| presentationToString model.presentation
          )
        ]


modeToString : Slide -> String
modeToString slide =
    case slide.editText of
        Just _ ->
            "edit"

        Nothing ->
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
                , ( "mode", Encode.string <| modeToString slide )
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
            { model | filename = Just filename }

        Err _ ->
            model


isSelected : Model -> Slide -> Bool
isSelected model slide =
    case model.selected of
        Nothing ->
            False

        Just selectedOrder ->
            slide.order == selectedOrder


slideEqualsOrder : Maybe Order -> Slide -> Bool
slideEqualsOrder maybeOrder slide =
    case maybeOrder of
        Nothing ->
            False

        Just order ->
            slide.order == order


slideAtOrder : Maybe Order -> Model -> Maybe Slide
slideAtOrder order model =
    model.presentation
        |> List.filter (slideEqualsOrder order)
        |> List.head


selectedSlide : Model -> Maybe Slide
selectedSlide model =
    slideAtOrder model.selected model


explodeSlideStrings : Maybe Slide -> List String
explodeSlideStrings slideMaybe =
    case slideMaybe of
        Just slide ->
            String.split "\n" slide.text
                |> List.filter (not << (String.trim >> String.isEmpty))

        Nothing ->
            []
