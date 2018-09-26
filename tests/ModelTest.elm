module ModelTest exposing
    ( presentationOrder
    , presentationToString
    , textToPresentation
    )

import Debug
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import List
import Model
import Test exposing (..)


textToPresentation : Test
textToPresentation =
    describe "Text To Presentation"
        [ fuzz3 string string string "converts a text to multiple slides" <|
            \textA textB textC ->
                let
                    string =
                        textA ++ "\n\n---\n\n" ++ textB ++ "\n\n---\n\n" ++ textC
                in
                Model.textToPresentation string
                    |> List.length
                    |> Expect.equal 3
        , fuzz3 string string string "properly orders multiple Slides" <|
            \textA textB textC ->
                let
                    string =
                        textA ++ "\n\n---\n\n" ++ textB ++ "\n\n---\n\n" ++ textC
                in
                Model.textToPresentation string
                    |> List.map .order
                    |> Expect.equalLists [ 0, 1, 2 ]
        , fuzz2 string string "handles an extra dash in the delimiter" <|
            \textA textB ->
                let
                    string =
                        textA ++ "\n\n----\n\n" ++ textB
                in
                Model.textToPresentation string
                    |> List.map .text
                    |> Expect.equalLists [ String.trim textA, String.trim textB ]
        , fuzz2 string string "handles table headers without splitting" <|
            \textA textB ->
                let
                    string =
                        textA ++ "\n\n----\n\n" ++ textB ++ "|-----|"
                in
                Model.textToPresentation string
                    |> List.map .text
                    |> Expect.equalLists [ String.trim textA, String.trim (textB ++ "|-----|") ]
        ]


presentationToString : Test
presentationToString =
    describe "Presentation To String"
        [ fuzz2 string string "converts a presentation to string" <|
            \textA textB ->
                let
                    presentation =
                        [ Model.slideFromIntAndText 1 textA
                        , Model.slideFromIntAndText 0 textB
                        ]
                in
                Model.presentationToString presentation
                    |> Expect.equal
                        (String.trim textB
                            ++ "\n\n---\n\n"
                            ++ String.trim textA
                        )
        ]


presentationOrder : Test
presentationOrder =
    let
        slide0 =
            Model.slideFromIntAndText 0 "Slide 0"

        slide1 =
            Model.slideFromIntAndText 1 "Slide 1"

        slide2 =
            Model.slideFromIntAndText 2 "Slide 2"

        presentation =
            [ slide0, slide1, slide2 ]
    in
    describe "Various presentation order fun"
        [ test "can find the previous slide" <|
            \_ ->
                Model.previousSlide slide1 presentation
                    |> Expect.equal (Just slide0)
        , test "handles previous slide edge case" <|
            \_ ->
                Model.previousSlide slide0 presentation
                    |> Expect.equal Nothing
        , test "can find the next slide" <|
            \_ ->
                Model.nextSlide slide1 presentation
                    |> Expect.equal (Just slide2)
        , test "handles next slide edge case" <|
            \_ ->
                Model.nextSlide slide2 presentation
                    |> Expect.equal Nothing
        , test "is previous true case" <|
            \_ ->
                Expect.true "Is previous" (Model.isPreviousTo slide1 slide0)
        , test "is previous false case" <|
            \_ ->
                Expect.false "Is not previous" (Model.isPreviousTo slide0 slide2)
        , test "is next true case" <|
            \_ ->
                Expect.true "Is next" (Model.isNextAfter slide0 slide1)
        , test "is next false case" <|
            \_ ->
                Expect.false "Is not next" (Model.isNextAfter slide0 slide2)
        ]


newSlideAfterTest : Test
newSlideAfterTest =
    describe "new slide after"
        [ test ]
