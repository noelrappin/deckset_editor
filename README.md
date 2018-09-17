# Deckset File Editor

## Summary

This application enables you to edit markdown files for use with
[Deckset](http://decksetapp.com), allowing you to treat each slide
individually, edit slides, remove slides, reorder slides, and
save the file again.

## Current Status

This is something I wrote for my own amusement and use, that you may
find useful. But it probably has some flaws I don't know about yet.

It absolutely may have bugs that cause your presentation to be garbled.

### __Use at your own risk__

The UI is a little ugly at the moment (particularly since I haven't
hooked up a menu bar, but it's basically functional). There are a
couple of parse bugs that will proabably affect some presentation files.

This is my first project using Electron and Elm together, so the code
is undoubtedly not-optimal in spots.

## Installation

I haven't installed this cold, so I'm not sure how this will go.

You need to install [Electron](https://electronjs.org) and
[Elm](http://elm-lang.com). Elm uses version 0.19.

You need to install dependencies with `yarn install`. Elm dependencies
should load on first build.

This still runs within the Electron shell rather than standalone.

`yarn run start` will build the elm files and start the electron app.


## Use

You can load a file from Open in the menu, you can save from the menu. There's no `Save As..`
yet, saving a file with a known location saves the file to that location.

Saving a file saves all open slides in edit mode.

The `+` button at the top creates a new slide.

Once you have slides, they will display in somewhat rendered markdown.

Each slide can be moved up or down with the errors. Clicking the pencil
opens an edit box for the slide. Clicking the trash can deletes the slide.
Clicking append adds a new slide after that slide. The edit menu and right 
click menu will give you the same set of options

An edited slide can be saved or canceled with disk emoji button or the
x emoji button.

Slides can also be dragged and dropped to move their location in the
presentation.

## Known Issues

### Parsing bugs

* Metadata isn't handled at all and will stay attached to the slide it
  comes with
* Tables are misparsed (the `---` in the header is interpreted as a new
  slide).

### Missing features

* Save as to a new file
* Protection for overwriting unsaved data
* Optional autosave on change

### Look and feel

* The vertical size of the slides is weird, especially with images
* Long text can overrun the width of the slide
