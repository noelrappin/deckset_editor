module Main exposing (Message(..), Model, init, main, subscriptions, update, view)

import Browser
import Bulma.Elements as BElements
import Bulma.Layout as BLayout
import Html exposing (Html, div, h1, p, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Markdown
import String


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


init : () -> ( Model, Cmd Message )
init _ =
    ( { presentation = textToPresentation testString }, Cmd.none )


view : Model -> Html Message
view model =
    div []
        (presentationInOrder model.presentation
            |> List.map slideToBox
        )


slideToBox : Slide -> BElements.Box Message
slideToBox slide =
    BElements.box
        []
        [ div
            []
            [ div [ class "content" ] [ Markdown.toHtml [] slide.text ]
            , BLayout.level [ class "is-mobile" ]
                [ BLayout.levelLeft []
                    [ BLayout.levelItem
                        [ onClick (SlideUp slide) ]
                        [ text "Up" ]
                    ]
                , BLayout.levelItem []
                    [ text "Edit" ]
                , BLayout.levelRight []
                    [ BLayout.levelItem
                        [ onClick (SlideDown slide) ]
                        [ text "Down" ]
                    ]
                ]
            ]
        ]


type Message
    = SlideUp Slide
    | SlideDown Slide
    | EditSlide Slide


update : Message -> Model -> ( Model, Cmd Message )
update message model =
    case message of
        SlideUp slide ->
            ( { model
                | presentation = moveSlideUp slide model.presentation
              }
            , Cmd.none
            )

        SlideDown slide ->
            ( { model
                | presentation = moveSlideDown slide model.presentation
              }
            , Cmd.none
            )

        EditSlide slide ->
            ( model, Cmd.none )


moveSlideUp : Slide -> Presentation -> Presentation
moveSlideUp slide presentation =
    swapSlides (previousSlide slide presentation) (Just slide) presentation


moveSlideDown : Slide -> Presentation -> Presentation
moveSlideDown slide presentation =
    swapSlides (nextSlide slide presentation) (Just slide) presentation


swapSlides : Maybe Slide -> Maybe Slide -> Presentation -> Presentation
swapSlides maybeSlideA maybeSlideB presentation =
    case maybeSlideA of
        Just slideA ->
            case maybeSlideB of
                Just slideB ->
                    presentation
                        |> List.map (swapOrder slideA.order slideB.order)

                Nothing ->
                    presentation

        Nothing ->
            presentation


swapOrder : Int -> Int -> Slide -> Slide
swapOrder a b slide =
    if slide.order == a then
        { slide | order = b }

    else if slide.order == b then
        { slide | order = a }

    else
        slide


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


presentationToString : Presentation -> String
presentationToString presentation =
    presentationInOrder presentation
        |> List.map .text
        |> String.join "\n---\n"


subscriptions : Model -> Sub Message
subscriptions model =
    Sub.none


main : Program () Model Message
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
