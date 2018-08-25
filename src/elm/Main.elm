module Main exposing (Message(..), Model, init, main, subscriptions, update, view)

import Browser
import Bulma.Elements as BElements
import Html exposing (Html, div, h1, p, text)
import Html.Attributes exposing (class, style)
import Markdown
import String



-- MODEL


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



-- INIT


testString : String
testString =
    "# Title\n    ---\n## A second slide\n    ---\n## A third slide"


init : () -> ( Model, Cmd Message )
init _ =
    ( { presentation = textToPresentation testString }, Cmd.none )



-- VIEW


view : Model -> Html Message
view model =
    div []
        (List.map slideToBox model.presentation)


slideToBox : Slide -> BElements.Box Message
slideToBox slide =
    BElements.box
        []
        [ div [ class "content" ] [ Markdown.toHtml [] slide.text ] ]



-- MESSAGE


type Message
    = None



-- UPDATE


update : Message -> Model -> ( Model, Cmd Message )
update message model =
    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Message
subscriptions model =
    Sub.none



-- MAIN


main : Program () Model Message
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
