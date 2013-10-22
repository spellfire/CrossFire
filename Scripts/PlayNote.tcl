# PlayNote.tcl 20051028
#
# This file contains all the procedures for game notes.
#
# Copyright (c) 2000-2005 Larry Meadows and Dan Curtiss. All rights reserved.
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

# Game::CreateGameNotes --
#
#   Creates the game notes window.
#
# Parameters:
#   pw         : Game toplevel.
#   title      : Title for the window. (Game #)
#
# Returns:
#   Nothing.
#
proc Game::CreateGameNotes {pw title} {

    variable gameConfig

    set w [toplevel $pw.gameNotes]
    wm withdraw $w
    wm title $w "Notes - $title"
    wm protocol $w WM_DELETE_WINDOW "Game::ToggleView $pw GameNotes No"
    if {$Config::config(Online,geometry,GameNotes) != ""} {
        wm geometry $w $Config::config(Online,geometry,GameNotes)
    }

    PanedWindow::Create $w.top -width 300 -height 300 \
        -orient horizontal -size 0.35
    set pf1 [PanedWindow::Pane $w.top 1]
    set pf2 [PanedWindow::Pane $w.top 2]

    $pf1 configure -borderwidth 1 -relief raised

    frame $pf1.sel

    label $pf1.sel.l -text "Notes:"

    frame $pf1.sel.list
    listbox $pf1.sel.list.lb -width 20 -height 15 -selectmode single \
        -background white -foreground black -selectborderwidth 0 \
        -selectbackground blue -selectforeground white \
        -yscrollcommand "CrossFire::SetScrollBar $pf1.sel.list.sb"
    scrollbar $pf1.sel.list.sb \
        -command "$pf1.sel.list.lb yview"

    grid $pf1.sel.list.lb -sticky nsew
    grid rowconfigure $pf1.sel.list 0 -weight 1
    grid columnconfigure $pf1.sel.list 0 -weight 1

    set lbw $pf1.sel.list.lb
    set gameConfig($pw,gameNoteListBox) $lbw
    bind $lbw <Button-1> "+Game::UpdateGameNote $pw"
    bindtags $lbw "Listbox $lbw"

    grid $pf1.sel.l -sticky w -pady 5
    grid $pf1.sel.list -sticky nsew
    grid rowconfigure $pf1.sel 1 -weight 1
    grid columnconfigure $pf1.sel 0 -weight 1

    grid $pf1.sel -sticky nsew -padx 5 -pady 5
    grid rowconfigure $pf1 0 -weight 1
    grid columnconfigure $pf1 0 -weight 1

    $pf2 configure -borderwidth 1 -relief raised

    frame $pf2.note

    frame $pf2.note.author
    label $pf2.note.author.l1 -text "Author:"
    label $pf2.note.author.l2 -anchor w -relief sunken \
        -textvariable Game::gameConfig($pw,gameNoteAuthor) -borderwidth 1
    grid $pf2.note.author.l1 $pf2.note.author.l2 -sticky ew \
        -pady 5
    grid columnconfigure $pf2.note.author 1 -weight 1

    frame $pf2.note.text
    text $pf2.note.text.t -state disabled -width 0 -height 0 \
        -foreground black -background white -yscrollcommand \
        "CrossFire::SetScrollBar $pf2.note.text.sb"
    scrollbar $pf2.note.text.sb \
        -command "$pf2.note.text.t yview"

    grid $pf2.note.text.t -sticky nsew
    grid rowconfigure $pf2.note.text 0 -weight 1
    grid columnconfigure $pf2.note.text 0 -weight 1

    set gameConfig($pw,gameNoteTextBox) $pf2.note.text.t

    grid $pf2.note.author -sticky ew
    grid $pf2.note.text -sticky nsew
    grid rowconfigure $pf2.note 1 -weight 1
    grid columnconfigure $pf2.note 0 -weight 1

    grid $pf2.note -sticky nsew -padx 5 -pady 5
    grid rowconfigure $pf2 0 -weight 1
    grid columnconfigure $pf2 0 -weight 1

    grid $w.top -sticky nsew
    grid rowconfigure $w 0 -weight 1
    grid columnconfigure $w 0 -weight 1

    set gameConfig($pw,show,GameNotes) "No"
    set gameConfig($pw,viewTop,GameNotes) $w
    regsub "\[0-9\]*x\[0-9\]*" [wm geometry $w] "" \
        gameConfig($pw,viewPosition,GameNotes)

    return
}

# Game::AddGameNote --
#
#   Adds a new note to the game notes.
#
# Parameters:
#   pw         : Game toplevel.
#   title      : Note title.
#   author     : Who added the note.
#   msg        : The note.
#
# Returns:
#   Nothing.
#
proc Game::AddGameNote {pw title author msg} {

    variable gameConfig

    if {[info exists gameConfig($pw,$title,author)]} {
        # Already have the note.  It may be resent from an update command.
        return
    }

    $gameConfig($pw,gameNoteListBox) insert end $title
    set gameConfig($pw,$title,author) $author
    set gameConfig($pw,$title,text) $msg

    return
}

# Game::DeleteGameNote --
#
#   Removes a note from the game notes.
#
# Parameters:
#   pw         : Game toplevel.
#   title      : Title of the note.
#
# Returns:
#   Nothing.
#
proc Game::DeleteGameNote {pw title} {

    variable gameConfig

    set lbw $gameConfig($pw,gameNoteListBox)

    for {set i 0} {$i <= [$lbw index end]} {incr i} {
        if {$title == [$lbw get $i]} {
            $lbw delete $i
            $lbw selection clear 0 end
            set gameConfig($pw,gameNoteAuthor) ""
            Game::SetGameNoteText $pw ""
            unset gameConfig($pw,$title,author)
            unset gameConfig($pw,$title,text)
            break
        }
    }

    return
}

# Game::UpdateGameNote --
#
#   Called when a title is clicked on.  Updates the author and
#   text of the note.
#
# Parameters:
#   pw         : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::UpdateGameNote {pw} {

    variable gameConfig

    set lbw $gameConfig($pw,gameNoteListBox)
    set sel [$lbw curselection]
    if {$sel == ""} {
        return
    }
    set title [$lbw get $sel]
    set gameConfig($pw,gameNoteAuthor) $gameConfig($pw,$title,author)
    SetGameNoteText $pw $gameConfig($pw,$title,text)

    return
}

# Game::SetGameNoteText --
#
#   Replaces the text in the game note window.
#
# Parameters:
#   pw         : Game toplevel.
#   msg        : Text to display.
#
# Returns:
#   Nothing.
#
proc Game::SetGameNoteText {pw msg} {

    variable gameConfig

    set tbw $gameConfig($pw,gameNoteTextBox)
    $tbw configure -state normal
    $tbw delete 1.0 end
    $tbw insert end $msg
    $tbw configure -state disabled

    return
}

# Game::ComposeGameNote --
#
#   Creates the GUI for entering a new game note.
#
# Parameters:
#   pw         : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::ComposeGameNote {pw} {

    variable gameConfig

    set tw $pw.composeGameNote

    if {[winfo exists $tw]} {
        wm deiconify $tw
        raise $tw
        return
    }

    toplevel $tw
    wm title $tw "Compose Game Note"

    frame $tw.top -borderwidth 1 -relief raised

    frame $tw.top.compose

    frame $tw.top.compose.title
    label $tw.top.compose.title.l -text "Title:"
    entry $tw.top.compose.title.e -width 25 \
        -textvariable Game::gameConfig($pw,composeTitle)
    set gameConfig($pw,composeEntry) $tw.top.compose.title.e
    grid $tw.top.compose.title.l $tw.top.compose.title.e -sticky ew
    grid columnconfigure $tw.top.compose.title 1 -weight 1

    frame $tw.top.compose.note
    label $tw.top.compose.note.l -text "Text:"

    frame $tw.top.compose.note.text
    text $tw.top.compose.note.text.t -width 30 -height 10 \
        -yscrollcommand \
        "CrossFire::SetScrollBar $tw.top.compose.note.text.sb"
    scrollbar $tw.top.compose.note.text.sb \
        -command "$tw.top.compose.note.text.t yview"
    set gameConfig($pw,composeText) $tw.top.compose.note.text.t
    grid $tw.top.compose.note.text.t -sticky nsew
    grid rowconfigure $tw.top.compose.note.text 0 -weight 1
    grid columnconfigure $tw.top.compose.note.text 0 -weight 1

    grid $tw.top.compose.note.l -sticky w
    grid $tw.top.compose.note.text -sticky nsew
    grid rowconfigure $tw.top.compose.note 1 -weight 1
    grid columnconfigure $tw.top.compose.note 0 -weight 1

    grid $tw.top.compose.title -sticky ew
    grid $tw.top.compose.note -sticky nsew
    grid rowconfigure $tw.top.compose 1 -weight 1
    grid columnconfigure $tw.top.compose 0 -weight 1

    grid $tw.top.compose -sticky nsew -padx 5 -pady 5
    grid rowconfigure $tw.top 0 -weight 1
    grid columnconfigure $tw.top 0 -weight 1

    frame $tw.buttons -borderwidth 1 -relief raised
    button $tw.buttons.send -text "Send" \
        -command "Game::SendGameNote $pw"
    button $tw.buttons.close -text $CrossFire::close \
        -command "destroy $tw"
    grid $tw.buttons.send $tw.buttons.close -padx 3 -pady 5

    grid $tw.top -sticky nsew
    grid $tw.buttons -sticky ew
    grid rowconfigure $tw 0 -weight 1
    grid columnconfigure $tw 0 -weight 1

    focus $gameConfig($pw,composeEntry)

    return
}

# Game::SendGameNote --
#
#   Updates the player's game notes window, send the game note to all the
#   opponents, and prepares the remove note menu item.
#
# Parameters:
#   pw         : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::SendGameNote {pw} {

    variable gameConfig

    set title $gameConfig($pw,composeTitle)
    set msg [$gameConfig($pw,composeText) get 1.0 end]
    set author $gameConfig($pw,name)

    # Clear out the window for a new note.
    set gameConfig($pw,composeTitle) ""
    $gameConfig($pw,composeText) delete 1.0 end
    focus $gameConfig($pw,composeEntry)

    # Add to author's window
    AddGameNote $pw $title $author $msg

    # Create the menu item for removal of it
    $gameConfig($pw,removeMenu) add command \
        -label $title \
        -command "Game::RemoveGameNote $pw [list $title]"

    # Send note to other players.
    TellOpponents $pw "AddGameNote [list $title] [list $author] [list $msg]"
    TellOpponents $pw "Message posted note '$title'"

    return
}

# Game::RemoveGameNote --
#
#   Updates the player's game notes window, send the remove game note to
#   all the opponents, and removes the remove note menu item.
#
# Parameters:
#   pw         : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::RemoveGameNote {pw title} {

    variable gameConfig

    # Remove the note from the player's note pad.
    DeleteGameNote $pw $title

    # Remove from the remove menu
    $gameConfig($pw,removeMenu) delete $title

    # Remove from opponent's note pad.
    TellOpponents $pw "DeleteGameNote [list $title]"
    TellOpponents $pw "Message removed note '$title'"

    return
}
