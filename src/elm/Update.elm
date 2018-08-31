module Update exposing (Message(..), moveSlideDown, moveSlideUp, swapOrder, swapSlides, update)

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
                | presentation = makeEditable slide model.presentation
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
                | presentation = updateEditText slide string model.presentation
              }
            , Cmd.none
            )

        SaveSlide slide ->
            ( { model
                | presentation = saveSlide slide model.presentation
              }
            , Cmd.none
            )

        CancelSlide slide ->
            ( { model
                | presentation = cancelSlide slide model.presentation
              }
            , Cmd.none
            )

        AppendSlide slide ->
            ( { model
                | presentation =
                    appendSlide (Just slide) model.presentation
              }
            , Cmd.none
            )

        AddSlideToEnd ->
            ( { model
                | presentation =
                    appendSlide
                        (List.last model.presentation)
                        model.presentation
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


makeEditable : Slide -> Presentation -> Presentation
makeEditable slide presentation =
    presentation
        |> List.updateAt slide.order
            (\s ->
                { s
                    | mode = Model.Edit
                    , editText = s.text
                }
            )


updateEditText : Slide -> String -> Presentation -> Presentation
updateEditText slide newEditText presentation =
    presentation
        |> List.updateAt slide.order
            (\s -> { s | editText = newEditText })


saveSlide : Slide -> Presentation -> Presentation
saveSlide slide presentation =
    presentation
        |> List.updateAt slide.order
            (\s ->
                { s
                    | mode = Model.Display
                    , text = s.editText
                }
            )


cancelSlide : Slide -> Presentation -> Presentation
cancelSlide slide presentation =
    presentation
        |> List.updateAt slide.order
            (\s -> { s | mode = Model.Display })


appendSlide : Maybe Slide -> Presentation -> Presentation
appendSlide slide presentation =
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
