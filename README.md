# Print-It

A Dolphin Service menu extension named after what it does.  Allows printing of
documents of various types. Simply that and nothing more.


## Documents Types

Starting with 0.1.0 there is support for these document types:

* PDF
* Plain text
* Shell Scripts and a selection of source code file types
* Images
* Markdown texts (as this README)
* Office Formats (templates not included)
* Directory Listings

Probably this does not even cover all known source file types in KDE developement.

To avoid unexspected results this extension allows the allows printing of
explicitly white listed file types.

There is mimetypes.in file in the source, that might give you a glimpse of
supported file types. Fell free to contact, if something is missing.


## Start Using it

if you start using this extension, it is recommended to setup a PDF printer
and configure this as the *Default* printer. This should help you to save trees.
(Default CUPS configuration uses `~/PDF/` as target folder).

To avoid even more killed trees, you will be prompted the first and next times
using it, until you select to not display this dialog any longer. In case you
wanna reset this, delete file `~/.config/print-it.config` or set `first_run` to
`false`.


## Made Of

The supported document formats are mostly defined via their respective
applications, such as KDE Dolphin, LibreOffice etc.


## Notes

This Context Menu extension has little to none control of the mime types in use.
Therefore ist tries to respect all usual well known types. This is particulary
true for Office Software related ones. These files may help as a starting point
to gather information on your system:

```
~/.config/mimeapps.list
~/.config/kde-mimeapps.list
~/.local/share/applications/mimeapps.list
/etc/xdg/mimeapps.list
/etc/xdg/kde-mimeapps.list
/usr/local/share/applications/mimeapps.list
/usr/share/applications/mimeapps.list
```

## Extended version...

is planed and shall do this:

All formats additionaly might go through a "nup" filter, that allows printing
resource friendly with two or more pages on a single sheet of paper.

A submenu at the bottom of the submenu allows the user to print some rare
usages as e.g. print a landscape image in portrait (and vice versa), three
portrait formates docuemnts on just one piece of paper and so on...
