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
    | AppendSlide (Maybe Slide)
    | CancelSlide (Maybe Slide)
    | DragDropMsg (DragDrop.Msg Model.Order Model.Order)
    | DuplicateSlide (Maybe Slide)
    | EditSlide (Maybe Slide)
    | ExplodeSlide (Maybe Slide)
    | FooterTextChanged String
    | LoadPresentation Value
    | MergeSlideBackward (Maybe Slide)
    | MergeSlideForward (Maybe Slide)
    | OpenFileDialog
    | Redo
    | RemoveSlide (Maybe Slide)
    | SavePresentation
    | SaveSlide (Maybe Slide)
    | SetSelected Slide
    | SlideDown (Maybe Slide)
    | SlideTextChanged Slide String
    | SlideUp (Maybe Slide)
    | SlideContextMenu (Maybe Slide)
    | Undo
    | UpdateFileName Value
    | UpdateWindowTitle
    | UpdateSelectedSlideInfo Model.UpdateType


update : Message -> Model -> ( Model, Cmd Message )
update message model =
    case message of
        AddSlideToEnd ->
            ( onAddSlideToEnd model |> onStateChange, Cmd.none )

        AppendSlide slide ->
            ( onAppendSlide slide model |> onStateChange, Cmd.none )

        CancelSlide slide ->
            onCancelSlide slide model
                |> update (UpdateSelectedSlideInfo Model.LeftClick)

        DragDropMsg dragDropMessage ->
            ( onDragDrop dragDropMessage model, Cmd.none )

        DuplicateSlide slide ->
            ( onDuplicateSlide slide model |> onStateChange, Cmd.none )

        EditSlide slide ->
            onEditSlide slide model
                |> update (UpdateSelectedSlideInfo Model.LeftClick)

        ExplodeSlide maybeSlide ->
            ( onExplodeSlide maybeSlide model |> onStateChange, Cmd.none )

        FooterTextChanged string ->
            ( onFooterTextChanged string model |> onStateChange, Cmd.none )

        LoadPresentation value ->
            Model.loadFromValue value model
                |> onStateReset
                |> onStateChange
                |> update UpdateWindowTitle

        MergeSlideBackward maybeSlide ->
            ( onMergeSlideBackward maybeSlide model |> onStateChange, Cmd.none )

        MergeSlideForward maybeSlide ->
            ( onMergeSlideForward maybeSlide model |> onStateChange, Cmd.none )

        OpenFileDialog ->
            ( model, Ports.openFileDialog () )

        Redo ->
            ( onRedo model, Cmd.none )

        RemoveSlide slide ->
            ( onRemoveSlide slide model |> onStateChange, Cmd.none )

        SavePresentation ->
            let
                newModel =
                    onSavePresentation model
            in
            ( newModel
            , Ports.savePresentationText (Model.encodeFileInfo newModel)
            )

        SaveSlide slide ->
            onSaveSlide slide model
                |> onStateChange
                |> update (UpdateSelectedSlideInfo Model.LeftClick)

        SetSelected slide ->
            onSetSelected (Just slide) model
                |> update (UpdateSelectedSlideInfo Model.LeftClick)

        SlideContextMenu slide ->
            onSetSelected slide model
                |> update (UpdateSelectedSlideInfo Model.RightClick)

        SlideDown slide ->
            ( onSlideDown slide model |> onStateChange, Cmd.none )

        SlideTextChanged slide string ->
            ( onSlideTextChanged string slide model, Cmd.none )

        SlideUp slide ->
            ( onSlideUp slide model |> onStateChange, Cmd.none )

        Undo ->
            ( onUndo model, Cmd.none )

        UpdateFileName filename ->
            Model.updateFilename filename model
                |> update UpdateWindowTitle

        UpdateWindowTitle ->
            ( model, Ports.updateWindowTitle (Model.windowTitle model) )

        UpdateSelectedSlideInfo updateType ->
            ( model
            , Ports.selectedSlideInfo <| Model.selectedSlideExportInfo model updateType
            )


onSlideUp : Maybe Slide -> Model -> Model
onSlideUp maybeSlide model =
    case maybeSlide of
        Nothing ->
            model

        Just slide ->
            { model
                | presentation =
                    swapSlides
                        (Model.previousSlide maybeSlide model.presentation)
                        (Just slide)
                        model.presentation
                , selected = Just (Model.previousOrder slide.order)
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
                        (Model.nextSlide maybeSlide model.presentation)
                        maybeSlide
                        model.presentation
                , selected = Just (Model.nextOrder slide.order)
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


swapOrder : Model.Order -> Model.Order -> Slide -> Slide
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
    { slide | editText = Just slide.text }


onEditSlide : Maybe Slide -> Model -> Model
onEditSlide maybeSlide model =
    case maybeSlide of
        Nothing ->
            model

        Just slide ->
            { model
                | presentation =
                    updateSlideAt slide makeEditable model.presentation
                , selected = Just slide.order
            }


updateEditText : String -> Slide -> Slide
updateEditText string slide =
    { slide | editText = Just string }


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
    case slide.editText of
        Just string ->
            { slide | text = string, editText = Nothing }

        Nothing ->
            slide


savePresentation : Presentation -> Presentation
savePresentation presentation =
    List.map saveSlide presentation


onSavePresentation : Model -> Model
onSavePresentation model =
    { model | presentation = savePresentation model.presentation }


onSaveSlide : Maybe Slide -> Model -> Model
onSaveSlide maybeSlide model =
    case maybeSlide of
        Nothing ->
            model

        Just slide ->
            { model
                | presentation =
                    updateSlideAt slide saveSlide model.presentation
            }


cancelSlide : Slide -> Slide
cancelSlide slide =
    { slide | editText = Nothing }


onCancelSlide : Maybe Slide -> Model -> Model
onCancelSlide maybeSlide model =
    case maybeSlide of
        Nothing ->
            model

        Just slide ->
            { model
                | presentation =
                    updateSlideAt slide cancelSlide model.presentation
            }


onAddSlideToEnd : Model -> Model
onAddSlideToEnd model =
    { model
        | presentation =
            appendSlideToPresentation (List.last model.presentation) "" model.presentation
    }


onAppendSlide : Maybe Slide -> Model -> Model
onAppendSlide slide model =
    { model
        | presentation =
            appendSlideToPresentation slide "" model.presentation
    }


appendSlideToPresentation : Maybe Slide -> String -> Presentation -> Presentation
appendSlideToPresentation slideAfter newSlideText presentation =
    let
        increaseFunction =
            Maybe.map .order slideAfter
                |> increaseOrderIfAfter
    in
    presentation
        |> List.map increaseFunction
        |> List.append [ Model.newSlideAfter slideAfter newSlideText ]
        |> List.sortBy Model.slideOrder


onDuplicateSlide : Maybe Slide -> Model -> Model
onDuplicateSlide slideMaybe model =
    case slideMaybe of
        Just slide ->
            { model
                | presentation =
                    appendSlideToPresentation slideMaybe slide.text model.presentation
            }

        Nothing ->
            model


increaseOrderIfAfter : Maybe Model.Order -> Slide -> Slide
increaseOrderIfAfter index slide =
    if Model.slideOrder slide > Model.maybeOrderToInt index then
        { slide | order = Model.nextOrder slide.order }

    else
        slide


decreaseOrderIfAfter : Model.Order -> Slide -> Slide
decreaseOrderIfAfter index slide =
    if Model.orderToInt slide.order > Model.orderToInt index then
        { slide | order = Model.previousOrder slide.order }

    else
        slide


sameOrder : Model.Order -> Slide -> Bool
sameOrder order slide =
    order == slide.order


onRemoveSlide : Maybe Slide -> Model -> Model
onRemoveSlide maybeSlide model =
    { model
        | presentation =
            removeSlideFromPresentation maybeSlide model.presentation
    }


removeSlideFromPresentation : Maybe Slide -> Presentation -> Presentation
removeSlideFromPresentation maybeSlide presentation =
    case maybeSlide of
        Nothing ->
            presentation

        Just slide ->
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
        case compare (Model.orderToInt dragOrder) (Model.orderToInt dropOrder) of
            LT ->
                if
                    Model.orderToInt slide.order
                        > Model.orderToInt dragOrder
                        && Model.orderToInt slide.order
                        <= Model.orderToInt dropOrder
                then
                    { slide | order = Model.previousOrder slide.order }

                else
                    slide

            GT ->
                if
                    Model.orderToInt slide.order
                        < Model.orderToInt dragOrder
                        && Model.orderToInt slide.order
                        >= Model.orderToInt dropOrder
                then
                    { slide | order = Model.nextOrder slide.order }

                else
                    slide

            EQ ->
                slide


onStateChange : Model -> Model
onStateChange model =
    { model
        | undoState =
            Undo.onStateChange
                (Just (Model.toUndoStatus model))
                model.undoState
    }


onStateReset : Model -> Model
onStateReset model =
    { model | undoState = Undo.initialUndoState }


newUndoState : Undo.UndoState Model.UndoStatus -> Model -> Model
newUndoState undoState model =
    let
        liveState =
            Maybe.withDefault Model.initialUndoStatus undoState.liveState
    in
    { model
        | undoState = undoState
        , presentation = liveState.presentation
        , metadata = liveState.metadata
    }


onUndo : Model -> Model
onUndo model =
    newUndoState (Undo.undo model.undoState) model


onRedo : Model -> Model
onRedo model =
    newUndoState (Undo.redo model.undoState) model


onSetSelected : Maybe Slide -> Model -> Model
onSetSelected maybeSlide model =
    case maybeSlide of
        Nothing ->
            { model | selected = Nothing }

        Just slide ->
            { model | selected = Just slide.order }


onMergeSlideBackward : Maybe Slide -> Model -> Model
onMergeSlideBackward maybeSlide model =
    { model
        | presentation =
            mergeSlides
                maybeSlide
                (Model.nextSlide maybeSlide model.presentation)
                model.presentation
    }


onMergeSlideForward : Maybe Slide -> Model -> Model
onMergeSlideForward maybeSlide model =
    { model
        | presentation =
            mergeSlides
                (Model.previousSlide maybeSlide model.presentation)
                maybeSlide
                model.presentation
    }


mergeSlides : Maybe Slide -> Maybe Slide -> Presentation -> Presentation
mergeSlides slideMaybeFrom slideMaybeTo presentation =
    case ( slideMaybeFrom, slideMaybeTo ) of
        ( Just slideFrom, Just slideTo ) ->
            presentation
                |> removeSlideFromPresentation slideMaybeTo
                |> updateSlideAt
                    slideFrom
                    (updateEditText <| slideFrom.text ++ "\n\n" ++ slideTo.text)

        _ ->
            presentation


appendSlidesToPresentation : Maybe Slide -> List String -> Presentation -> Presentation
appendSlidesToPresentation slideMaybe stringList presentation =
    case stringList of
        [] ->
            presentation

        head :: tail ->
            presentation
                |> appendSlidesToPresentation slideMaybe tail
                |> appendSlideToPresentation slideMaybe head


onExplodeSlide : Maybe Slide -> Model -> Model
onExplodeSlide slideMaybe model =
    { model
        | presentation =
            model.presentation
                |> appendSlidesToPresentation
                    slideMaybe
                    (Model.explodeSlideStrings slideMaybe)
                |> removeSlideFromPresentation slideMaybe
    }


onFooterTextChanged : String -> Model -> Model
onFooterTextChanged string model =
    { model | metadata = Model.updateFooter string model.metadata }
