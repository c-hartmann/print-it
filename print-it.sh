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

### TODO libreoffice



### no arguments? quit!
(( $# == 0 )) && exit 128

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
    _libreoffice_snap="$(snap search libreoffice)"
    [[ -n "${_libreoffice_snap}" ]] && printf '%s' "/snap/bin/libreoffice" && return
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
    ### get path to binary
    _libreoffice=$(_init_libreoffice)

    ### altough this goes via %f it should be able to handle %F as well
    for _file in "$@"; do
        _mime_type="$(_get_mime_type "$_file")"
        printf '%s\n' "file:$_file" "mime:$_mime_type" >&2
        case "$_mime_type" in
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
            application/x-shellscript | application/x-desktop:org)
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
