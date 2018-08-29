module Update exposing (Message(..), moveSlideDown, moveSlideUp, swapOrder, swapSlides, update)

import Model exposing (Model, Presentation, Slide)
import Ports


type Message
    = EditSlide Slide
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
            ( { model
                | presentation = Model.makeEditable slide model.presentation
              }
            , Cmd.none
            )

        OpenFileDialog ->
            ( model, Ports.openFileDialog () )

        LoadPresentation string ->
            ( { model
                | presentation = Model.textToPresentation string
              }
            , Cmd.none
            )

        SavePresentation ->
            ( model
            , Ports.savePresentationText
                (Model.presentationToString model.presentation)
            )

        SlideTextChanged slide string ->
            ( { model
                | presentation = Model.updateEditText slide string model.presentation
              }
            , Cmd.none
            )

        SaveSlide slide ->
            ( { model
                | presentation = Model.saveSlide slide model.presentation
              }
            , Cmd.none
            )


moveSlideUp : Slide -> Presentation -> Presentation
moveSlideUp slide presentation =
    swapSlides (Model.previousSlide slide presentation) (Just slide) presentation


moveSlideDown : Slide -> Presentation -> Presentation
moveSlideDown slide presentation =
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
