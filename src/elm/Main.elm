module Main exposing (Message(..), Model, init, main, subscriptions, update, view)

import Browser
import Html exposing (Html, h1, text)
import Html.Attributes exposing (style)
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
    "# Title\n    ---\n    ## A second slide\n    ---\n    ## A third slide"


init : () -> ( Model, Cmd Message )
init _ =
    ( { presentation = textToPresentation testString }, Cmd.none )



-- VIEW


view : Model -> Html Message
view model =
    h1 [ style "display" "flex", style "justify-content" "center" ]
        [ text "Hello Elm!" ]



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
