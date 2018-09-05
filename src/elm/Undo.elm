module Undo exposing
    ( UndoState
    , initialUndoState
    , onStateChange
    , redo
    , undo
    )

import List


type alias UndoState a =
    { undoHistory : List a
    , redoHistory : List a
    , liveState : Maybe a
    }


initialUndoState : UndoState a
initialUndoState =
    { redoHistory = []
    , undoHistory = []
    , liveState = Nothing
    }


pushIf : Maybe a -> List a -> List a
pushIf maybe list =
    case maybe of
        Just value ->
            value :: list

        Nothing ->
            list


onStateChange : Maybe a -> UndoState a -> UndoState a
onStateChange maybeNewState undoState =
    case maybeNewState of
        Just newState ->
            { undoState
                | undoHistory = pushIf undoState.liveState undoState.undoHistory
                , redoHistory = []
                , liveState = Just newState
            }

        Nothing ->
            undoState


canUndo : UndoState a -> Bool
canUndo undoState =
    not (List.isEmpty undoState.undoHistory)


canRedo : UndoState a -> Bool
canRedo undoState =
    not (List.isEmpty undoState.redoHistory)


undo : UndoState a -> UndoState a
undo undoState =
    case undoState.undoHistory of
        head :: tail ->
            { undoState
                | liveState = Just head
                , redoHistory = pushIf undoState.liveState undoState.redoHistory
                , undoHistory = tail
            }

        [] ->
            undoState


redo : UndoState a -> UndoState a
redo undoState =
    case undoState.redoHistory of
        head :: tail ->
            { undoState
                | liveState = Just head
                , redoHistory = tail
                , undoHistory = pushIf undoState.liveState undoState.undoHistory
            }

        [] ->
            undoState
