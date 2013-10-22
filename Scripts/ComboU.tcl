# ComboU.tcl 20030908
#
# This file contains utility procedures for the Combo manager.
#
# Copyright (c) 1999-2003 Dan Curtiss. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

# Combo::SetComboInformation --
#
#   Allows for change of some additional (optional) infomation
#   about the combo
#
# Parameters:
#   w          : ComboMan toplevel.
#
# Returns:
#   Nothing.
#
proc Combo::SetComboInformation {w} {

    variable storage

    set tw $w.comboInfo
    if {[winfo exists $tw]} {
        wm deiconify $tw
        raise $tw
        return
    }

    toplevel $tw
    wm title $tw "Combo Information"
    wm protocol $tw WM_DELETE_WINDOW "$tw.buttons.close invoke"
    bind $tw <Key-Escape> "$tw.buttons.close invoke"

    CrossFire::Transient $tw

    frame $tw.info -relief raised -borderwidth 1

    frame $tw.info.title
    label $tw.info.title.l -text "Combo Title:"
    entry $tw.info.title.e -textvariable Combo::storage($w,comboTitle)
    grid $tw.info.title.l $tw.info.title.e -sticky nsew -padx 5 -pady 5
    grid columnconfigure $tw.info.title 1 -weight 1

    frame $tw.info.author
    label $tw.info.author.l -text "Author's Name:"
    entry $tw.info.author.e -textvariable Combo::storage($w,authorName)
    grid $tw.info.author.l $tw.info.author.e -sticky nsew -padx 5 -pady 5
    grid columnconfigure $tw.info.author 1 -weight 1

    frame $tw.info.email
    label $tw.info.email.l -text "Author's Email:"
    entry $tw.info.email.e -textvariable Combo::storage($w,authorEmail)
    grid $tw.info.email.l $tw.info.email.e -sticky nsew -padx 5 -pady 5
    grid columnconfigure $tw.info.email 1 -weight 1

    grid $tw.info.title -sticky nsew
    grid $tw.info.author -sticky nsew
    grid $tw.info.email -sticky nsew
    grid columnconfigure $tw.info 0 -weight 1
    grid rowconfigure $tw.info {0 1 2} -weight 1

    frame $tw.buttons -relief raised -borderwidth 1
    button $tw.buttons.close -text $CrossFire::close \
        -command "Combo::CloseComboInformation $w"
    grid $tw.buttons.close -pady 5

    grid $tw.info -sticky nsew
    grid $tw.buttons -sticky nsew
    grid columnconfigure $tw 0 -weight 1
    grid rowconfigure $tw 0 -weight 1

    foreach var "authorName comboTitle authorEmail" {
        trace variable Combo::storage($w,$var) w \
            "Combo::SetChanged $w true"
    }

    return
}

# Combo::CloseComboInformation --
#
#   Closes the combo information window and removes the trace
#   from the variables.
#
# Parameters:
#   w          : Combo toplevel.
#
# Returns:
#   Nothing.
#
proc Combo::CloseComboInformation {w} {

    variable storage

    destroy $w.comboInfo
    foreach var "authorName comboTitle authorEmail" {
        trace vdelete Combo::storage($w,$var) w \
            "Combo::SetChanged $w true"
    }

    return
}
