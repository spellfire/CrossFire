# ChatUtil.tcl 20030908
#
# This file contains additional procedures for the chatroom client.
#
# Copyright (c) 2000-2003 Dan Curtiss. All rights reserved.
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

# Chat::CreateNote --
#
#   Creates the GUI for the note editor.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::CreateNote {} {

    variable chatConfig

    set w $chatConfig(topw).userNote

    if {[winfo exists $w]} {
        wm deiconify $w
        raise $w
        return
    }

    toplevel $w
    wm title $w "Compose Chat Note"

    AddNoteMenuBar $w

    frame $w.note -borderwidth 1 -relief raised

    frame $w.note.f

    frame $w.note.f.name
    label $w.note.f.name.l -text "To:" -width 8 -anchor e
    set chatConfig(userNoteToEntryW) \
        [entry $w.note.f.name.e -width 30 \
             -textvariable Chat::chatConfig(userNoteName)]
    focus $chatConfig(userNoteToEntryW)
    grid $w.note.f.name.l $w.note.f.name.e -sticky ew
    grid $w.note.f.name -sticky ew
    grid columnconfigure $w.note.f.name 1 -weight 1

    frame $w.note.f.subject
    label $w.note.f.subject.l -text "Subject:" -width 8 -anchor e
    entry $w.note.f.subject.e -width 30 \
        -textvariable Chat::chatConfig(userNoteSubject)
    grid $w.note.f.subject.l $w.note.f.subject.e -sticky ew
    grid $w.note.f.subject -sticky ew -pady 5
    grid columnconfigure $w.note.f.subject 1 -weight 1

    frame $w.note.f.text
    frame $w.note.f.text.f
    set chatConfig(userNoteTextW) \
        [text $w.note.f.text.f.t -width 45 -height 8 -wrap word \
             -yscrollcommand "CrossFire::SetScrollBar $w.note.f.text.f.sb"]
    scrollbar $w.note.f.text.f.sb -command "$w.note.f.text.f.t yview"
    grid $w.note.f.text.f.t -sticky nsew
    grid $w.note.f.text.f -sticky nsew
    grid columnconfigure $w.note.f.text.f 0 -weight 1
    grid rowconfigure $w.note.f.text.f 0 -weight 1
    grid $w.note.f.text -sticky nsew
    grid columnconfigure $w.note.f.text 0 -weight 1
    grid rowconfigure $w.note.f.text 0 -weight 1

    grid $w.note.f -sticky nsew -padx 5 -pady 5
    grid columnconfigure $w.note.f 0 -weight 1
    grid rowconfigure $w.note.f 2 -weight 1

    grid $w.note -sticky nsew
    grid columnconfigure $w.note 0 -weight 1
    grid rowconfigure $w.note 0 -weight 1

    frame $w.buttons -borderwidth 1 -relief raised
    button $w.buttons.clear -text "Clear" -command "Chat::ClearNote"
    button $w.buttons.send -text "Send" -command "Chat::SendNote $w"
    button $w.buttons.close -text $CrossFire::close -command "destroy $w"
    grid $w.buttons.clear $w.buttons.send $w.buttons.close -padx 5 -pady 5
    grid $w.buttons -sticky nsew

    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 1

    return
}

# Chat::AddNoteMenuBar --
#
#   Adds the menu bar to the note editor window.
#
# Parameters:
#   w          : Note editor toplevel.
#
# Returns:
#   Nothing.
#
proc Chat::AddNoteMenuBar {w} {

    variable chatConfig

    menu $w.menubar

    $w.menubar add cascade \
        -label "Options" \
        -underline 0 \
        -menu $w.menubar.opt

    menu $w.menubar.opt -tearoff 0
    $w.menubar.opt add checkbutton \
        -label "CC Myself" \
        -onvalue "Yes" -offvalue "No" \
        -variable Chat::chatConfig(userNoteCC)

    $w.menubar.opt add cascade \
        -label "Width" \
        -menu $w.menubar.opt.width

    menu $w.menubar.opt.width -tearoff 0
    for {set width 40} {$width <= 60} {incr width 5} {
        $w.menubar.opt.width add radiobutton \
            -label $width -value $width \
            -variable Chat::chatConfig(userNoteWidth)
    }

    $w configure -menu $w.menubar

    return
}

# Chat::ClearNote --
#
#   Clears the note editor.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::ClearNote {} {

    variable chatConfig

    set chatConfig(userNoteName) ""
    set chatConfig(userNoteSubject) ""
    $chatConfig(userNoteTextW) delete 1.0 end
    focus $chatConfig(userNoteToEntryW)

    return
}

# Chat::SendNote --
#
#   Sends the note to the server.  Formats the text width.
#
# Parameters:
#   w          : Note editor toplevel.
#
# Returns:
#   Nothing.
#
proc Chat::SendNote {w} {

    variable chatConfig

    if {$chatConfig(userNoteCC) == "Yes"} {
        lappend chatConfig(userNoteName) $chatConfig(name)
    }

    # Create the note header
    SendToServer "note to [list $chatConfig(userNoteName)]"
    SendToServer "note subject [list $chatConfig(userNoteSubject)]"

    # Send the note data
    set width $chatConfig(userNoteWidth)
    set msg [string trim [$chatConfig(userNoteTextW) get 1.0 end]]
    foreach line [split [CrossFire::SplitLine $width $msg] "\n"] {
        SendToServer "note + [list $line]"
    }

    # Post it!
    SendToServer "note post"

    ClearNote
    destroy $w

    return
}

# Chat::AllyList --
#
#   Plug-In interface.  Returns a list of allies in the current realm.
#
# Parameters:
#   None.
#
# Returns:
#   List of allies.
#
proc Chat::AllyList {} {

    variable chatConfig

    return $chatConfig(allyList)
}

# Chat::PlayerName --
#
#   Plug-In interface.  Returns the player's name.
#
# Parameters:
#   None.
#
# Returns:
#   Name of player.
#
proc Chat::PlayerName {} {

    variable chatConfig

    return $chatConfig(name)
}

# Chat::ChatMessage --
proc Chat::ChatMessage {msg} {

    SendToServer "emote $msg"

    return
}

proc Chat::PlugInCommand {key opponent player command} {

    variable chatConfig

    SendToServer "tell $opponent $key $player $command"

    return
}
