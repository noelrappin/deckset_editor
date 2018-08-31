module View exposing (slideToBox, view)

import Bulma.Columns as BColumns exposing (columnsModifiers)
import Bulma.Elements as BElements exposing (buttonModifiers)
import Bulma.Form as BForm
import Bulma.Layout as BLayout
import Bulma.Modifiers as BModifiers
import Html exposing (Html, div, h1, p, text)
import Html.Attributes exposing (attribute, class, style, value)
import Html.Events exposing (onClick, onInput)
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


multilineColumnsModifiers : BColumns.ColumnsModifiers
multilineColumnsModifiers =
    { columnsModifiers | multiline = True }


slideBoxes : Presentation -> List (Html Message)
slideBoxes presentation =
    List.map slideToBox <|
        Model.presentationInOrder presentation


displayPresentationSlides : Presentation -> Html Message
displayPresentationSlides presentation =
    BColumns.columns multilineColumnsModifiers
        []
    <|
        slideBoxes presentation
            ++ [ BColumns.column BColumns.columnModifiers
                    [ class "is-one-quarter" ]
                    [ div
                        [ onClick Update.AddSlideToEnd ]
                        [ primaryButton "+" ]
                    ]
               ]


view : Model -> Html Message
view model =
    div []
        [ displayPresentationSlides model.presentation
        , Html.br [] []
        , viewFooter
        ]


viewFooter : Html Message
viewFooter =
    BLayout.level [ class "is-mobile" ]
        [ BLayout.levelLeft []
            [ BLayout.levelItem
                [ onClick Update.OpenFileDialog ]
                [ primaryButton "Open Document" ]
            ]
        , BLayout.levelRight []
            [ BLayout.levelItem
                [ onClick Update.SavePresentation ]
                [ primaryButton "Save Document" ]
            ]
        ]


slideToBox : Slide -> BElements.Box Message
slideToBox slide =
    BColumns.column BColumns.columnModifiers
        [ class "is-one-quarter" ]
        [ BElements.box
            [ attribute "data-row" <| String.fromInt slide.order ]
            [ boxContents slide ]
        ]


boxContents : Slide -> Html Message
boxContents slide =
    case slide.mode of
        Model.Display ->
            displayModeContents slide

        Model.Edit ->
            editModeContents slide


displayModeContents : Slide -> Html Message
displayModeContents slide =
    div
        []
        [ div [ class "content" ] [ Markdown.toHtml [] slide.text ]
        , BLayout.level
            [ class "is-mobile" ]
            [ BLayout.levelLeft []
                [ BLayout.levelItem
                    [ onClick (Update.SlideUp slide) ]
                    [ text "Up" ]
                , BLayout.levelItem
                    [ onClick (Update.SlideDown slide) ]
                    [ text "Down" ]
                ]
            , BLayout.levelRight []
                [ BLayout.levelItem
                    [ onClick (Update.EditSlide slide) ]
                    [ text "Edit" ]
                , BLayout.levelItem
                    [ onClick (Update.RemoveSlide slide) ]
                    [ text "Remove" ]
                , BLayout.levelItem
                    [ onClick (Update.AppendSlide slide) ]
                    [ text "Append" ]
                ]
            ]
        ]


editModeContents : Slide -> Html Message
editModeContents slide =
    div []
        [ div
            []
            [ BForm.controlTextArea
                BForm.controlTextAreaModifiers
                []
                [ value slide.editText, onInput (Update.SlideTextChanged slide) ]
                []
            ]
        , BLayout.level
            [ class "is-mobile" ]
            [ BLayout.levelLeft []
                [ BLayout.levelItem
                    [ onClick (Update.SlideUp slide) ]
                    [ text "Up" ]
                ]
            , BLayout.levelItem
                [ onClick (Update.SaveSlide slide) ]
                [ text "Save" ]
            , BLayout.levelItem
                [ onClick (Update.CancelSlide slide) ]
                [ text "Cancel" ]
            , BLayout.levelRight []
                [ BLayout.levelItem
                    [ onClick (Update.SlideDown slide) ]
                    [ text "Down" ]
                ]
            ]
        ]
