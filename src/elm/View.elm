module View exposing (slideToBox, view)

import Bulma.Columns as BColumns exposing (columnsModifiers)
import Bulma.Elements as BElements exposing (buttonModifiers)
import Bulma.Form as BForm
import Bulma.Layout as BLayout
import Bulma.Modifiers as BModifiers
import Html exposing (Html, div, h1, p, text)
import Html.Attributes exposing (attribute, class, classList, style, value)
import Html.Events exposing (onClick, onInput)
import Html5.DragDrop as DragDrop
import Markdown
import Model exposing (Model, Presentation, Slide)
import Ports exposing (openFileDialog)
import Undo
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


slideBoxes : Model -> List (Html Message)
slideBoxes model =
    List.map (slideToBox model) <|
        Model.presentationInOrder model.presentation


displayPresentationSlides : Model -> Html Message
displayPresentationSlides model =
    BColumns.columns multilineColumnsModifiers
        []
    <|
        slideBoxes model
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
        [ displayPresentationSlides model

        -- , Html.br [] []
        -- , viewFooter model
        ]


showIf : Bool -> Html.Attribute msg
showIf boolean =
    if boolean then
        class ""

    else
        BModifiers.invisible


viewFooter : Model -> Html Message
viewFooter model =
    BLayout.level [ class "is-mobile" ]
        [ BLayout.levelLeft []
            [ BLayout.levelItem
                [ onClick Update.OpenFileDialog ]
                [ primaryButton "Open Document" ]
            , BLayout.levelItem
                [ onClick Update.SavePresentation ]
                [ primaryButton "Save Document" ]
            ]
        , BLayout.levelRight []
            [ BLayout.levelItem
                [ onClick Update.Undo
                , showIf (Undo.canUndo model.undoState)
                ]
                [ primaryButton "Undo" ]
            , BLayout.levelItem
                [ onClick Update.Redo
                , showIf (Undo.canRedo model.undoState)
                ]
                [ primaryButton "Redo" ]
            ]
        ]


slideToBox : Model -> Slide -> BElements.Box Message
slideToBox model slide =
    BColumns.column BColumns.columnModifiers
        [ class "is-one-quarter" ]
        [ BElements.box
            (DragDrop.draggable Update.DragDropMsg slide.order
                ++ DragDrop.droppable Update.DragDropMsg slide.order
                ++ [ attribute "data-row" <| String.fromInt slide.order ]
                ++ [ classList
                        [ ( "has-background-primary"
                          , Model.isSelected model slide
                          )
                        ]
                   ]
            )
            [ boxContents slide ]
        ]


boxContents : Slide -> Html Message
boxContents slide =
    case slide.mode of
        Model.Display ->
            displayModeContents slide

        Model.Edit ->
            editModeContents slide


editButtonModifiers : BElements.ButtonModifiers msg
editButtonModifiers =
    { buttonModifiers
        | color = BModifiers.Light
        , size = BModifiers.Small
    }


editButton : Message -> String -> Html Message
editButton message caption =
    BElements.button editButtonModifiers [ onClick message ] [ text caption ]


displayModeContents : Slide -> Html Message
displayModeContents slide =
    div
        []
        [ div
            [ class "content"
            , onClick (Update.SetSelected slide)
            ]
            [ Markdown.toHtml [] slide.text ]
        , BLayout.level
            [ class "is-mobile" ]
            [ BLayout.levelLeft []
                [ BElements.buttons
                    BModifiers.Left
                    [ class "has-addons" ]
                    [ editButton (Update.SlideUp (Just slide)) "⬆️"
                    , editButton (Update.SlideDown (Just slide)) "⬇️"
                    ]
                ]
            , BLayout.levelRight []
                [ BElements.buttons
                    BModifiers.Right
                    [ class "has-addons" ]
                    [ editButton (Update.EditSlide (Just slide)) "✏️"
                    , editButton (Update.RemoveSlide (Just slide)) "🗑"
                    , editButton (Update.AppendSlide (Just slide)) "➕"
                    ]
                ]
            ]
        ]


editModeContents : Slide -> Html Message
editModeContents slide =
    div []
        [ div
            [ onClick (Update.SetSelected slide) ]
            [ BForm.controlTextArea
                BForm.controlTextAreaModifiers
                []
                [ value slide.editText, onInput (Update.SlideTextChanged slide) ]
                []
            ]
        , BLayout.level
            [ class "is-mobile" ]
            [ BLayout.levelLeft []
                [ BElements.buttons
                    BModifiers.Left
                    [ class "has-addons" ]
                    [ editButton (Update.SlideUp (Just slide)) "⬆️"
                    , editButton (Update.SlideDown (Just slide)) "⬇️"
                    ]
                ]
            , BLayout.levelRight []
                [ BElements.buttons
                    BModifiers.Right
                    [ class "has-addons" ]
                    [ editButton (Update.SaveSlide (Just slide)) "💾"
                    , editButton (Update.CancelSlide (Just slide)) "🚫"
                    ]
                ]
            ]
        ]
