module Model exposing
    ( DragResult
    , Model
    , Order
    , Slide
    , Slides
    , UndoStatus
    , UpdateType(..)
    , encodeFileInfo
    , explodeSlideStrings
    , fitify
    , init
    , initialMetadata
    , initialUndoStatus
    , isNextAfter
    , isPreviousTo
    , isSelected
    , loadFromImport
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
    , selectedSlideExportInfo
    , selectedSlides
    , slideAtOrder
    , slideFromIntAndText
    , slideOrder
    , textToPresentation
    , toUndoStatus
    , updateFilename
    , updateFooter
    , windowTitle
    )

import Debug
import Html5.DragDrop as DragDrop
import Json.Decode as Decode exposing (Decoder, float, int, string)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
import Json.Encode as Encode exposing (Value)
import List.Extra as List
import Maybe.Extra as Maybe
import Regex
import String.Extra as String
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


type alias Slides =
    List Slide


type alias DragResult =
    Maybe ( Order, Order, DragDrop.Position )


type alias Model =
    { presentation : Slides
    , filename : Maybe String
    , clean : Bool
    , dragDrop : DragDrop.Model Order Order
    , undoState : UndoState UndoStatus
    , selected : List Order
    , theme : Maybe String
    , metadata : Metadata
    }


type alias UndoStatus =
    { metadata : Metadata
    , presentation : Slides
    }


type alias Metadata =
    { footer : Maybe String
    , slideNumbers : Bool
    , autoscale : Bool
    , buildLists : Bool
    }


initialMetadata : Metadata
initialMetadata =
    { footer = Nothing
    , slideNumbers = False
    , autoscale = False
    , buildLists = False
    }


initialUndoStatus : UndoStatus
initialUndoStatus =
    { presentation = [], metadata = initialMetadata }


init : Model
init =
    { presentation = []
    , filename = Nothing
    , clean = True
    , dragDrop = DragDrop.init
    , undoState = Undo.initialUndoState
    , selected = []
    , theme = Nothing
    , metadata = initialMetadata
    }


toUndoStatus : Model -> UndoStatus
toUndoStatus model =
    { metadata = model.metadata, presentation = model.presentation }


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


updateFooter : String -> Metadata -> Metadata
updateFooter string metadata =
    { metadata
        | footer =
            String.split "footer:" string
                |> List.last
    }


loadFromImport : FileImport -> Model -> Model
loadFromImport fileImport model =
    let
        lines =
            String.lines fileImport.body
    in
    case lines of
        first :: rest ->
            if String.startsWith "footer:" first then
                { model | metadata = updateFooter first model.metadata }
                    |> loadFromImport { fileImport | body = String.join "\n" rest }

            else
                { model
                    | presentation = textToPresentation fileImport.body
                    , filename = Just fileImport.filename
                }

        [] ->
            model


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


textToPresentation : String -> Slides
textToPresentation text =
    Regex.split slideDelimiterRegex text
        |> List.indexedMap slideFromIntAndText


presentationInOrder : Slides -> Slides
presentationInOrder presentation =
    presentation
        |> List.sortBy slideOrder


metadataToString : Metadata -> String
metadataToString metadata =
    case metadata.footer of
        Just string ->
            "footer: " ++ string ++ "\n\n"

        Nothing ->
            ""


presentationToString : Slides -> String
presentationToString presentation =
    presentationInOrder presentation
        |> List.map .text
        |> String.join "\n\n---\n\n"


previousSlide : Maybe Slide -> Slides -> Maybe Slide
previousSlide maybeSlide presentation =
    case maybeSlide of
        Just slide ->
            presentation
                |> List.filter (isPreviousTo slide)
                |> List.head

        Nothing ->
            Nothing


nextSlide : Maybe Slide -> Slides -> Maybe Slide
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
          , Encode.string <|
                metadataToString model.metadata
                    ++ presentationToString model.presentation
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
    encodeSlideExportInfo updateType <| selectedSlides model



-- todo: make this return a list


encodeSlideExportInfo : UpdateType -> Slides -> Value
encodeSlideExportInfo updateType slides =
    case List.head slides of
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
        [] ->
            False

        selectedOrder :: _ ->
            slide.order == selectedOrder


slideEqualsOrder : Maybe Order -> Slide -> Bool
slideEqualsOrder maybeOrder slide =
    case maybeOrder of
        Nothing ->
            False

        Just order ->
            slide.order == order


slideAtOrder : Model -> Order -> Maybe Slide
slideAtOrder model order =
    model.presentation
        |> List.filter (slideEqualsOrder <| Just order)
        |> List.head


selectedSlides : Model -> List Slide
selectedSlides model =
    model.selected
        |> List.map (slideAtOrder model)
        |> Maybe.values


explodeSlideStrings : Maybe Slide -> List String
explodeSlideStrings slideMaybe =
    case slideMaybe of
        Just slide ->
            String.split "\n" slide.text
                |> List.filter (not << (String.trim >> String.isEmpty))

        Nothing ->
            []


fitifyString : String -> String
fitifyString string =
    if String.isBlank string then
        string

    else
        Regex.replace fitHeaderRegex (\_ -> "") string
            |> (++) "# [fit] "


fitHeaderRegex : Regex.Regex
fitHeaderRegex =
    Maybe.withDefault Regex.never <|
        Regex.fromStringWith
            { caseInsensitive = False
            , multiline = False
            }
            "#+\\s*(\\[fit\\])?\\s*"


fitify : Slide -> Slide
fitify slide =
    { slide
        | text =
            String.split "\n" slide.text
                |> List.map fitifyString
                |> String.join "\n"
    }
