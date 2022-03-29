#! /usr/bin/env bash

# vim: syntax=sh tabstop=4 softtabstop=0 expandtab shiftwidth=4 smarttab :

#
# 	servicemenus-print-it.sh Version 0.1.0
# 	Copyright (C) 2022 Christian Hartmann <hartmann.christian@gmail.com>
#
#       SPDX-FileCopyrightText: 2022 Christian Hartmann <hartmann.christian@gmail.com>
#
#       SPDX-License-Identifier: LicenseRef-KDE-Accepted-GPL
#
#       This program is free software; you can redistribute it and/or
#       modify it under the terms of the GNU General Public License as
#       published by the Free Software Foundation; either version 3 of
#       the license or (at your option) at any later version that is
#       accepted by the membership of KDE e.V. (or its successor
#       approved by the membership of KDE e.V.), which shall act as a
#       proxy as defined in Section 14 of version 3 of the license.
#
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#       GNU General Public License for more details.
#



### some useful helpers
MY_PATH="${BASH_SOURCE[0]}"
MY_FILE="${MY_PATH##*/}"
MY_NAME="${MY_FILE%%.*}"
#MY_FIRST_RUN="${MY_PATH}/${MY_NAME}.firstrun"
MY_FIRST_RUN="${MY_PATH%%.sh}.firstrun"
MY_CONFIG="${MY_NAME}.config"

### no arguments? quit!
(( $# == 0 )) && exit 128

### desktop notifications will vanish after seconds
notification_timeout=2000

### check if we run first time (diaply dialog until users select no display)
_check_first_run ()
{
#     ### is the $ME.firstrun file still present / delete on explicit user action
#     if [[ -f "$MY_FIRST_RUN" ]]; then
#         _message_text=$(cat "$MY_FIRST_RUN")
        _message_text="Proceed with 'Printing' or 'Cancel' printing this time"
#         kdialog --yes-label 'Print' --no-label 'Cancel' --warningyesno "$_message_text"
#         _show_dialog_next='Show this dialog next time'
#         _hide_dialog_next='Do not show this dialog next time'
#         choice=$(kdialog --title 'Print It' --ok-label 'Print' --cancel-label 'Cancel' --combobox "$_message_text" "$_show_dialog_next" "$_hide_dialog_next" --default "$_show_dialog_next")
#         kdialog --title 'Print It' --msgbox "$_message_text" --dontagain "${MY_CONFIG}:first_run"
        kdialog --title 'Print It' --yes-label 'Print' --no-label 'Cancel' --warningyesno "$_message_text" --dontagain "${MY_CONFIG}:first_run"
        if (( $? == 0 )); then
#             if [[ "$choice" == "$_show_dialog_next" ]]; then
#                 rm "$MY_FIRST_RUN"
#             fi
            return 0
        else
            ### bug or feature?  kdialog remembers OK or CANCEL last decision
            ### when do not display again option is cheched. so if user(in)
            ### checks "do not display again" _and_ Cancel the operation,
            ### kdialog will always return false on every next invocation.
            ### so we delete config file immediatly on Cancel and ensure
            ### dialog will pop up on next run.
            rm ~/.config/"$MY_CONFIG"
            return 1 # canceled
        fi
#     else
#         return 0
#     fi
}

### _notify
### wrapper that respects gui or cli mode
_notify ()
{
# 	$gui && notify-send --app-name="${MY_TITLE}" --icon=virtualbox --expire-time=$notification_timeout "$@"
# 	$cli && printf "\n$@\n" >&2
	notify-send --app-name="${MY_TITLE}" --icon=document-print --expire-time=$notification_timeout "$@"
}

### _error_exit
### even more simple error handling
_error_exit ()
{
	local error_str="$(gettext "ERROR")"
	$gui && kdialog --error "$error_str: $*" --ok-label "So Sad"
	$cli && printf "\n$error_str: $1\n\n" >&2
	exit ${2:-1}
}

### _canceled_exit
_canceled_exit ()
{
	_notify "printing canceled"
	exit 1
}

### _init_run_mode FD
### wrapper that sets gui or cli mode from terminal type
_init_run_mode ()
{
	local fd=$1
	if [[ ! -t $fd ]]; then
		# running via service menu
		gui=true
		cli=false
	else
		# running from command line
		gui=false
		cli=true
	fi
}

### find identify(1)
_init_identify ()
{
    _identify="$(which identify)"
    [[ -n "${_identify}" ]] && printf '%s' "${_identify}" && return
    _magick_dentify="$(which magick)"
    [[ -n "${_magick_identify}" ]] && printf '%s' "${_magick_dentify} identify" && return
    _gm_identify="$(which gm)"
    [[ -n "${_gm_identify}" ]] && printf '%s' "${_gm_identify} identify" && return
}

### find libreoffice
_init_libreoffice ()
{
    ### either straigt command, flatpack or snap may be installed
    ### /usr/bin/flatpak run --branch=stable --arch=x86_64 --command=libreoffice --file-forwarding org.libreoffice.LibreOffice --writer
    _libreoffice="$(which libreoffice)"
    [[ -n "${_libreoffice}" ]] && printf '%s' "${_libreoffice}" && return
    _soffice="$(which soffice)"
    [[ -n "${_soffice}" ]] && printf '%s' "${_soffice}" && return
    _libreoffice_fp="$(flatpak search --columns=application org.libreoffice.LibreOffice | head -1)"
    [[ -n "${_libreoffice_fp}" ]] && printf '%s' "flatpak run org.libreoffice.LibreOffice" && return
    ### if installed via snap, we only have to check for the executable
    _libreoffice_snap="/snap/bin/libreoffice"
    [[ -x "${_libreoffice_snap}" ]] && printf '%s' "${_libreoffice_snap}" && return
}


### find something suitabel to get the mime type of a file
### file(1) --brief --mime-type --dereference (follow symlinks)
### or xdg-mime(1) query <file> | default mimetype
### both shall be available in any standard Linux distribution
_get_mime_type () # <file>
{
    local _file="$1"
    # howto get output of file(1) and xdg-mime(1) in line?
    xdg-mime query filetype "$_file"
}

### every mime type comes with registered applicatiopn (not used here)
_get_default_app () # <mimetype>
{
    local _mt="$1"
    xdg-mime query default "$_mt"
}

### images havwe widht and height
### sample usage: _get_image_dimensions <file> | read width height
_get_image_dimensions () # <file>
{
    local _file="$1"
    _identify=$(_init_identify)
    if [[ -n "$_identify" ]]; then
        $_identify -format '%w %h' "$_file"
    fi
}

### images have an aspect (not used)
### sample usage: _get_image_aspect <file> | read aspect
_get_image_aspect ()
{
    local _file="$1"
    return
}

### images might be considered as portrait or landscape (saves trees)
### returns either landscape or portrait
### sample usage: _get_image_orientation <file> | read orientation
_get_image_orientation () # <file>
{
    local _file="$1"
    r=$(identify -format '%[fx:(h>w)]' "$_file")
    if (( r == 1 )); then
        printf '%s' 'portrait'
    else
        printf '%s' 'landscape'
    fi
}


### main function
_main ()
{
# 	# if running inside a terminal, stdin is connected to this terminal
# 	local stdin=0
# 	_init_run_mode $stdin

    _check_first_run || _canceled_exit

    ### altough this goes via %f it should be able to handle %F as well
    ### TODO rename _file to something more generic that includes directories. _node?

    for _file in "$@"; do
        _mime_type="$(_get_mime_type "$_file")"
        printf '%s\n' "file:$_file" "mime:$_mime_type" >&2
        case "$_mime_type" in
            inode/directory)
                kdialog --combobox "$_file"
                _enscript="$(which enscript)"
                if [[ -n "$_enscript" ]]; then
                    _dirname="$(basename "${_file}")" # remove trailing slash
                    ls -l -o -g --time-style=long-iso --human-readable "$_file" | $_enscript --header="/${_dirname}/|\$% / \$=|%D %C" --font='Courier@9/10' --output=- | lp # --pretty-print=de_DE.UTF-8 ?
                fi
            ;;
            text/html)
                ### treat this as source code or try to render this?
                kdialog --warning 'html support is not yet implemented. sorry'
                continue
            ;;
            text/markdown)
                _markdown="$(which markdown)"
                _html2ps="$(which html2ps)"
                [[ -n "$_markdown" ]] || kdialog --error 'markdown(1) not installed. must quit'
                [[ -n "$_html2ps" ]] || kdialog --error 'html2ps(1) not installed. must quit'
                $_markdown "$_file" | iconv --from 'UTF-8' --to 'ISO-8859-1' | $_html2ps | lp
                continue
            ;;
            text/*)
                lp "$_file"
                continue
            ;;
            image/svg+xml)
                ### any command line utility?
                ### convert(1) might do the job with the help of librsvg2-bin
                ### inkscape --without-gui --export-pdf=/dev/stdout foo.svg | lp
                ### orientation is relevant here as well
                kdialog --warning 'svg support is not yet implemented. sorry'
                continue
            ;;
            image/*)
                ### just printing works, but...
                ### small images are irreasonable scaled to paper size
                ### they should be centered
                ### there should be a reasonable margin to paper edges
                orientation="$(_get_image_orientation "$_file")"
                case "$orientation" in
                    portrait)
                        lp -o 'portrait' "$_file"
                    ;;
                    landscape)
                        lp -o 'landscape' "$_file"
                    ;;
                    *)
                        : # oops
                    ;;
                esac
                continue
            ;;
            application/pdf)
                lp "$_file"
                continue
            ;;
            application/rtf | \
            application/vnd.oasis.opendocument.text | \
            application/vnd.oasis.opendocument.spreadsheet | \
            application/vnd.oasis.opendocument.presentation | \
            application/vnd.oasis.opendocument.text | \
            application/vnd.oasis.opendocument.spreadsheet | \
            application/vnd.oasis.opendocument.presentation | \
            application/vnd.oasis.opendocument.graphics | \
            application/vnd.oasis.opendocument.formula | \
            application/msword | \
            application/msexcel | \
            application/excel | \
            application/mspowerpoint | \
            application/vnd.openxmlformats-officedocument.wordprocessingml.document | \
            application/vnd.openxmlformats-officedocument.spreadsheetml.sheet | \
            application/vnd.openxmlformats-officedocument.presentationml.presentation | \
            application/vnd.ms-word | \
            application/vnd.ms-excel | \
            application/vnd.ms-powerpoint \
            )
                ### get path to binary
                _libreoffice=$(_init_libreoffice)
                $_libreoffice --headless -p "$_file" # --writer? nope. --headless is also not required
            ;;
            application/x-shellscript | application/x-desktop)
                _enscript="$(which enscript)"
                _a2ps="$(which a2ps)"
                _e2ps="$(which e2ps)" # can handle unicode?
                if [[ -n "$_enscript" ]]; then
#                     $_enscript --nup=1 -r --fancy-header --no-job-header --borders --line-numbers --portrait --color=true --output=- "$_file" | lp # --pretty-print=de_DE.UTF-8 ?
                    $_enscript --header='$n|$% / $=|%D %C' --font='Courier@9/10' --output=- "$_file" | lp # --pretty-print=de_DE.UTF-8 ?
                elif [[ -n "$_a2ps" ]]; then
                    $_a2ps -nu --portrait --output=- "$_file" | lp # --pretty-print=de_DE.UTF-8 ?
                elif [[ -n "$_e2ps" ]]; then
                    $_e2ps --output=- "$_file" | lp # 1005 untested!
                else
                    lp "$_file" # very basic fallback
                fi
                continue
            ;;
            *)
                kdialog --error "sorry. support for mimetype not implemented yet: $_mime_type"
                continue
            ;;
        esac
        printf '\n'
    done
}

### call main with all remaining command line arguments
_main "$@"
