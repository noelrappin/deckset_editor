module Update exposing (Message(..), update)

import Debug
import Html5.DragDrop as DragDrop
import Json.Encode exposing (Value)
import List.Extra as List
import Model exposing (Model, Presentation, Slide)
import Ports
import Undo


type Message
    = AddSlideToEnd
    | AppendSlide Slide
    | CancelSlide Slide
    | DragDropMsg (DragDrop.Msg Model.Order Model.Order)
    | EditSlide Slide
    | LoadPresentation Value
    | OpenFileDialog
    | Redo
    | RemoveSlide Slide
    | SavePresentation
    | SaveSlide Slide
    | SetSelected Slide
    | SlideDown (Maybe Slide)
    | SlideTextChanged Slide String
    | SlideUp (Maybe Slide)
    | Undo
    | UpdateFileName Value
    | UpdateWindowTitle


update : Message -> Model -> ( Model, Cmd Message )
update message model =
    case message of
        AddSlideToEnd ->
            ( onAddSlideToEnd model |> onStateChange, Cmd.none )

        AppendSlide slide ->
            ( onAppendSlide slide model |> onStateChange, Cmd.none )

        CancelSlide slide ->
            ( onCancelSlide slide model, Cmd.none )

        DragDropMsg dragDropMessage ->
            ( onDragDrop dragDropMessage model, Cmd.none )

        EditSlide slide ->
            ( onEditSlide slide model, Cmd.none )

        LoadPresentation value ->
            Model.loadFromValue value model
                |> onStateReset
                |> onStateChange
                |> update UpdateWindowTitle

        OpenFileDialog ->
            ( model, Ports.openFileDialog () )

        Redo ->
            ( onRedo model, Cmd.none )

        RemoveSlide slide ->
            ( onRemoveSlide slide model |> onStateChange, Cmd.none )

        SavePresentation ->
            ( model
            , Ports.savePresentationText
                (Model.encodeFileInfo model)
            )

        SaveSlide slide ->
            ( onSaveSlide slide model |> onStateChange, Cmd.none )

        SetSelected slide ->
            ( onSetSelected slide model, Cmd.none )

        SlideDown slide ->
            ( onSlideDown slide model |> onStateChange, Cmd.none )

        SlideTextChanged slide string ->
            ( onSlideTextChanged string slide model
            , Cmd.none
            )

        SlideUp slide ->
            ( onSlideUp slide model |> onStateChange, Cmd.none )

        Undo ->
            ( onUndo model, Cmd.none )

        UpdateFileName filename ->
            Model.updateFilename filename model
                |> update UpdateWindowTitle

        UpdateWindowTitle ->
            ( model, Ports.updateWindowTitle (Model.windowTitle model) )


onSlideUp : Maybe Slide -> Model -> Model
onSlideUp maybeSlide model =
    case maybeSlide of
        Nothing ->
            model

        Just slide ->
            { model
                | presentation =
                    swapSlides
                        (Model.previousSlide slide model.presentation)
                        (Just slide)
                        model.presentation
                , selected = Just (slide.order - 1)
            }


onSlideDown : Maybe Slide -> Model -> Model
onSlideDown maybeSlide model =
    case maybeSlide of
        Nothing ->
            model

        Just slide ->
            { model
                | presentation =
                    swapSlides
                        (Model.nextSlide slide model.presentation)
                        (Just slide)
                        model.presentation
                , selected = Just (slide.order + 1)
            }


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


updateSlideAt : Slide -> (Slide -> Slide) -> Presentation -> Presentation
updateSlideAt slide =
    List.updateIf <| \s -> slide.order == s.order


makeEditable : Slide -> Slide
makeEditable slide =
    { slide | mode = Model.Edit, editText = slide.text }


onEditSlide : Slide -> Model -> Model
onEditSlide slide model =
    { model
        | presentation = updateSlideAt slide makeEditable model.presentation
    }


updateEditText : String -> Slide -> Slide
updateEditText string slide =
    { slide | editText = string }


onSlideTextChanged : String -> Slide -> Model -> Model
onSlideTextChanged newEditText slide model =
    { model
        | presentation =
            updateSlideAt
                slide
                (updateEditText newEditText)
                model.presentation
    }


saveSlide : Slide -> Slide
saveSlide slide =
    { slide | mode = Model.Display, text = slide.editText }


onSaveSlide : Slide -> Model -> Model
onSaveSlide slide model =
    { model
        | presentation = updateSlideAt slide saveSlide model.presentation
    }


cancelSlide : Slide -> Slide
cancelSlide slide =
    { slide | mode = Model.Display }


onCancelSlide : Slide -> Model -> Model
onCancelSlide slide model =
    { model
        | presentation = updateSlideAt slide cancelSlide model.presentation
    }


onAddSlideToEnd : Model -> Model
onAddSlideToEnd model =
    { model
        | presentation =
            appendSlideToPresentation
                (List.last model.presentation)
                model.presentation
    }


onAppendSlide : Slide -> Model -> Model
onAppendSlide slide model =
    { model
        | presentation =
            appendSlideToPresentation (Just slide) model.presentation
    }


appendSlideToPresentation : Maybe Slide -> Presentation -> Presentation
appendSlideToPresentation slide presentation =
    let
        increaseFunction =
            Maybe.map .order slide
                |> increaseOrderIfAfter
    in
    presentation
        |> List.map increaseFunction
        |> List.append [ Model.newSlideAfter slide ]
        |> List.sortBy .order


increaseOrderIfAfter : Maybe Int -> Slide -> Slide
increaseOrderIfAfter index slide =
    if slide.order > Maybe.withDefault -1 index then
        { slide | order = slide.order + 1 }

    else
        slide


decreaseOrderIfAfter : Int -> Slide -> Slide
decreaseOrderIfAfter index slide =
    if slide.order > index then
        { slide | order = slide.order - 1 }

    else
        slide


sameOrder : Int -> Slide -> Bool
sameOrder order slide =
    order == slide.order


onRemoveSlide : Slide -> Model -> Model
onRemoveSlide slide model =
    { model
        | presentation = removeSlideFromPresentation slide model.presentation
    }


removeSlideFromPresentation : Slide -> Presentation -> Presentation
removeSlideFromPresentation slide presentation =
    presentation
        |> List.filterNot (sameOrder slide.order)
        |> List.map (decreaseOrderIfAfter slide.order)


onDragDrop : DragDrop.Msg Model.Order Model.Order -> Model -> Model
onDragDrop dragDropMessage model =
    let
        ( dragModel, dragResult ) =
            DragDrop.update dragDropMessage model.dragDrop
    in
    { model | dragDrop = dragModel }
        |> dragDropComplete dragResult


dragDropComplete : Model.DragResult -> Model -> Model
dragDropComplete dragResult model =
    case dragResult of
        Nothing ->
            model

        Just ( dragId, dropId, position ) ->
            { model
                | presentation = dragPresentation dragResult model.presentation
                , selected = Just dropId
            }
                |> onStateChange


dragPresentation : Model.DragResult -> Presentation -> Presentation
dragPresentation result presentation =
    case result of
        Nothing ->
            presentation

        Just ( dragOrder, dropOrder, position ) ->
            List.map
                (updateSlideOnDrag dragOrder dropOrder)
                presentation


updateSlideOnDrag : Model.Order -> Model.Order -> Model.Slide -> Model.Slide
updateSlideOnDrag dragOrder dropOrder slide =
    if slide.order == dragOrder then
        { slide | order = dropOrder }

    else
        case compare dragOrder dropOrder of
            LT ->
                if slide.order > dragOrder && slide.order <= dropOrder then
                    { slide | order = slide.order - 1 }

                else
                    slide

            GT ->
                if slide.order < dragOrder && slide.order >= dropOrder then
                    { slide | order = slide.order + 1 }

                else
                    slide

            EQ ->
                slide


onStateChange : Model -> Model
onStateChange model =
    { model
        | undoState =
            Undo.onStateChange
                (Just model.presentation)
                model.undoState
    }


onStateReset : Model -> Model
onStateReset model =
    { model | undoState = Undo.initialUndoState }


newUndoState : Undo.UndoState Presentation -> Model -> Model
newUndoState undoState model =
    { model
        | undoState = undoState
        , presentation = Maybe.withDefault [] undoState.liveState
    }


onUndo : Model -> Model
onUndo model =
    newUndoState (Undo.undo model.undoState) model


onRedo : Model -> Model
onRedo model =
    newUndoState (Undo.redo model.undoState) model


onSetSelected : Slide -> Model -> Model
onSetSelected slide model =
    { model | selected = Just slide.order }
