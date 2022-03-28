# Print

A Dolphin Servie menu extension named after what it does.  Allows printing of
documents of various types. Simply that and nothing more.

## Documents types

Starting with 0.9.0 there is support for these document types:

* PDF (and other non editable formats)
* most of open document types (templates not included)
* plain text
* images

## Made of

The supported document formats are mostly defined via their respective
applications, such as KDE Dolphin, LibreOffice etc.

## Extras

All formats additionaly might go through a "nup" filter, that allows printing
resource friendly with two or more pages on a single sheet of paper.

## Extented

A submenu at the bottom of the submenu allows the user to print some rare
usages as e.g. print a landscape image in portrait (and vice versa), three
portrait formates docuemnts on just one piece of paper and so on...

## Internals

To some extend the printing command line are configurable




### images (pixels and vectors)
### that should be not too complicated ... get ratio and chose portrait or landscape mode
### if EXIF data is present .. and we do have the tools available, this migth be an option
### to respect these
### convert MyJpeg.jpg -print "Size: %wx%h\n"

### pdf and all office formats
### get orientation from file and choose ...

### ummm, basicly all pdfs, all office formats might have page orientations page by page
### or sheet per sheet. so printing shall be acommplished through the apps.


# NOT SEEN SO FAR BY XDG-MIME(1) or FILE(1)  these exists, but are they used in KDE?
# the wohle thing here is ... we do NOT control these associations. user may have
# set this up to his/her personal needs


# a reasonable source for usefull mime types are
# ~/.config/mimeapps.list
# ~/.config/kde-mimeapps.list
# ~/.local/share/applications/mimeapps.list
# /etc/xdg/mimeapps.list
# /etc/xdg/kde-mimeapps.list
# /usr/local/share/applications/mimeapps.list
# /usr/share/applications/mimeapps.list
