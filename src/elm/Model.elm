module Model exposing (Model, Presentation, Slide, isNextAfter, isPreviousTo, nextSlide, presentationInOrder, presentationToString, previousSlide, slideFromIntAndText, testString, textToPresentation)


type alias Slide =
    { text : String, order : Int }


type alias Presentation =
    List Slide


type alias Model =
    { presentation : Presentation }


slideFromIntAndText : Int -> String -> Slide
slideFromIntAndText int text =
    { text = text, order = int }


textToPresentation : String -> Presentation
textToPresentation text =
    String.split "---" text
        |> List.indexedMap slideFromIntAndText


presentationInOrder : Presentation -> Presentation
presentationInOrder presentation =
    presentation
        |> List.sortBy .order


testString : String
testString =
    "# Title\n    ---\n## A second slide\n    ---\n## A third slide"


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
