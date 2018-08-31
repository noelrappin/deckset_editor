module Update exposing (Message(..), update)

import Debug
import List.Extra as List
import Model exposing (Model, Presentation, Slide)
import Ports


type Message
    = AddSlideToEnd
    | AppendSlide Slide
    | CancelSlide Slide
    | EditSlide Slide
    | LoadPresentation String
    | OpenFileDialog
    | SavePresentation
    | SaveSlide Slide
    | SlideDown Slide
    | SlideTextChanged Slide String
    | SlideUp Slide


update : Message -> Model -> ( Model, Cmd Message )
update message model =
    case message of
        AddSlideToEnd ->
            ( { model
                | presentation =
                    onAppendSlide
                        (List.last model.presentation)
                        model.presentation
              }
            , Cmd.none
            )

        AppendSlide slide ->
            ( { model
                | presentation =
                    onAppendSlide (Just slide) model.presentation
              }
            , Cmd.none
            )

        CancelSlide slide ->
            ( { model
                | presentation = onCancelSlide slide model.presentation
              }
            , Cmd.none
            )

        EditSlide slide ->
            ( { model
                | presentation = onEditSlide slide model.presentation
              }
            , Cmd.none
            )

        LoadPresentation string ->
            ( { model
                | presentation = Model.textToPresentation string
              }
            , Cmd.none
            )

        OpenFileDialog ->
            ( model, Ports.openFileDialog () )

        SavePresentation ->
            ( model
            , Ports.savePresentationText
                (Model.presentationToString model.presentation)
            )

        SaveSlide slide ->
            ( { model
                | presentation = onSaveSlide slide model.presentation
              }
            , Cmd.none
            )

        SlideDown slide ->
            ( { model
                | presentation = onSlideDown slide model.presentation
              }
            , Cmd.none
            )

        SlideTextChanged slide string ->
            ( { model
                | presentation = onSlideTextChanged string slide model.presentation
              }
            , Cmd.none
            )

        SlideUp slide ->
            ( { model
                | presentation = onSlideUp slide model.presentation
              }
            , Cmd.none
            )


onSlideUp : Slide -> Presentation -> Presentation
onSlideUp slide presentation =
    swapSlides
        (Model.previousSlide slide presentation)
        (Just slide)
        presentation


onSlideDown : Slide -> Presentation -> Presentation
onSlideDown slide presentation =
    swapSlides (Model.nextSlide slide presentation) (Just slide) presentation


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


onEditSlide : Slide -> Presentation -> Presentation
onEditSlide slide presentation =
    updateSlideAt slide makeEditable presentation


updateEditText : String -> Slide -> Slide
updateEditText string slide =
    { slide | editText = string }


onSlideTextChanged : String -> Slide -> Presentation -> Presentation
onSlideTextChanged newEditText slide presentation =
    updateSlideAt slide (updateEditText newEditText) presentation


saveSlide : Slide -> Slide
saveSlide slide =
    { slide | mode = Model.Display, text = slide.editText }


onSaveSlide : Slide -> Presentation -> Presentation
onSaveSlide slide presentation =
    updateSlideAt slide saveSlide presentation


cancelSlide : Slide -> Slide
cancelSlide slide =
    { slide | mode = Model.Display }


onCancelSlide : Slide -> Presentation -> Presentation
onCancelSlide slide presentation =
    updateSlideAt slide cancelSlide presentation


onAppendSlide : Maybe Slide -> Presentation -> Presentation
onAppendSlide slide presentation =
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
