module View exposing (slideToBox, view)

import Bulma.Elements as BElements exposing (buttonModifiers)
import Bulma.Layout as BLayout
import Bulma.Modifiers as BModifiers
import Html exposing (Html, div, h1, p, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Markdown
import Model exposing (Model, Presentation, Slide)
import Ports exposing (openFileDialog)
import Update exposing (Message)


primaryButtonModifiers : BElements.ButtonModifiers msg
primaryButtonModifiers =
    { buttonModifiers | color = BModifiers.Primary }


primaryButton : String -> Html Message
primaryButton caption =
    BElements.button primaryButtonModifiers [] [ text caption ]


view : Model -> Html Message
view model =
    div []
        [ div []
            (Model.presentationInOrder model.presentation
                |> List.map slideToBox
            )
        , Html.br [] []
        , div
            [ onClick Update.OpenFileDialog ]
            [ primaryButton "Open Document" ]
        , div
            [ onClick Update.SavePresentation ]
            [ primaryButton "Save Document" ]
        ]


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
                        [ onClick (Update.SlideUp slide) ]
                        [ text "Up" ]
                    ]
                , BLayout.levelItem []
                    [ text "Edit" ]
                , BLayout.levelRight []
                    [ BLayout.levelItem
                        [ onClick (Update.SlideDown slide) ]
                        [ text "Down" ]
                    ]
                ]
            ]
        ]
