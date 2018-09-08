module View exposing (slideToBox, view)

import Bulma.Columns as BColumns exposing (columnsModifiers)
import Bulma.Elements as BElements exposing (buttonModifiers)
import Bulma.Form as BForm
import Bulma.Layout as BLayout
import Bulma.Modifiers as BModifiers
import Html exposing (Html, div, h1, p, text)
import Html.Attributes exposing (attribute, class, style, value)
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


slideToBox : Slide -> BElements.Box Message
slideToBox slide =
    BColumns.column BColumns.columnModifiers
        [ class "is-one-quarter" ]
        [ BElements.box
            (DragDrop.draggable Update.DragDropMsg slide.order
                ++ DragDrop.droppable Update.DragDropMsg slide.order
                ++ [ attribute "data-row" <| String.fromInt slide.order ]
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
        [ div [ class "content" ] [ Markdown.toHtml [] slide.text ]
        , BLayout.level
            [ class "is-mobile" ]
            [ BLayout.levelLeft []
                [ BElements.buttons
                    BModifiers.Left
                    [ class "has-addons" ]
                    [ editButton (Update.SlideUp slide) "⬆️"
                    , editButton (Update.SlideDown slide) "⬇️"
                    ]
                ]
            , BLayout.levelRight []
                [ BElements.buttons
                    BModifiers.Right
                    [ class "has-addons" ]
                    [ editButton (Update.EditSlide slide) "✏️"
                    , editButton (Update.RemoveSlide slide) "🗑"
                    , editButton (Update.AppendSlide slide) "➕"
                    ]
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
                [ BElements.buttons
                    BModifiers.Left
                    [ class "has-addons" ]
                    [ editButton (Update.SlideUp slide) "⬆️"
                    , editButton (Update.SlideDown slide) "⬇️"
                    ]
                ]
            , BLayout.levelRight []
                [ BElements.buttons
                    BModifiers.Right
                    [ class "has-addons" ]
                    [ editButton (Update.SaveSlide slide) "💾"
                    , editButton (Update.CancelSlide slide) "🚫"
                    ]
                ]
            ]
        ]
