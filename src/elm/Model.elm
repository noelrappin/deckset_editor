module Model exposing (Mode(..), Model, Presentation, Slide, appendSlide, cancelSlide, isNextAfter, isPreviousTo, makeEditable, nextSlide, presentationInOrder, presentationToString, previousSlide, saveSlide, slideFromIntAndText, textToPresentation, updateEditText)

import Debug
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


type alias Presentation =
    List Slide


type alias Model =
    { presentation : Presentation }


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


makeEditable : Slide -> Presentation -> Presentation
makeEditable slide presentation =
    presentation
        |> List.updateAt slide.order
            (\s ->
                { s
                    | mode = Edit
                    , editText = s.text
                }
            )


updateEditText : Slide -> String -> Presentation -> Presentation
updateEditText slide newEditText presentation =
    presentation
        |> List.updateAt slide.order
            (\s -> { s | editText = newEditText })


saveSlide : Slide -> Presentation -> Presentation
saveSlide slide presentation =
    presentation
        |> List.updateAt slide.order
            (\s ->
                { s
                    | mode = Display
                    , text = s.editText
                }
            )


cancelSlide : Slide -> Presentation -> Presentation
cancelSlide slide presentation =
    presentation
        |> List.updateAt slide.order
            (\s -> { s | mode = Display })


appendSlide : Maybe Slide -> Presentation -> Presentation
appendSlide slide presentation =
    let
        increaseFunction =
            Maybe.map .order slide
                |> increaseOrderIfAfter
    in
    presentation
        |> List.map increaseFunction
        |> List.append [ newSlideAfter slide ]
        |> List.sortBy .order


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


increaseOrderIfAfter : Maybe Int -> Slide -> Slide
increaseOrderIfAfter index slide =
    if slide.order > Maybe.withDefault -1 index then
        { slide | order = slide.order + 1 }

    else
        slide
