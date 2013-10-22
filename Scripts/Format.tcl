# Format.tcl 20050907
#
# This file contains all the gui procedures for editing deck formats.
#
# Copyright (c) 2005 Dan Curtiss. All rights reserved.
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

namespace eval FormatIt {

    variable windowTitle "Deck Format Maker"
    variable editorCount 0   ;# Counter for creating new toplevels.

    variable storage

}

# FormatIt::Create --
#
#   Incrementally creates a new format editor toplevel.
#
# Parameters:
#   args       : Optional deck format file to load.
#
# Returns:
#   The path name of the toplevel widget.
#
proc FormatIt::Create {args} {

    variable editorCount
    variable storage
    variable windowTitle

    set w .format[incr editorCount]
    CrossFire::Register Format $w

    set storage($w,fileName) ""
    set storage($w,change) "false"
    set storage($w,name) ""
    set storage($w,allowedList) {}
    set storage($w,bannedList) {}
    set storage($w,formatDir) [file join $CrossFire::homeDir "Formats"]

    toplevel $w
    wm withdraw $w
    wm title $w $windowTitle

    # Trap closing window from window manager methods.
    wm protocol $w WM_DELETE_WINDOW "FormatIt::ExitEditor $w"

    AddMenuBar $w

    # Name of the format
    frame $w.formatName -relief raised -borderwidth 1
    frame $w.formatName.n
    label $w.formatName.n.l -text "Title: "
    entry $w.formatName.n.e -textvariable FormatIt::storage($w,name)
    grid $w.formatName.n.l $w.formatName.n.e -sticky ew
    grid columnconfigure $w.formatName.n 1 -weight 1
    grid $w.formatName.n -padx 5 -pady 5 -sticky nsew
    grid columnconfigure $w.formatName 0 -weight 1

    # List of all the groups
    frame $w.groupSel -relief raised -borderwidth 1
    frame $w.groupSel.list
    listbox $w.groupSel.list.lb -selectmode single -width 16 \
        -height 1 -background white -foreground black \
        -selectbackground blue -selectforeground white \
        -selectborderwidth 0 -takefocus 0 -exportselection 0 \
        -yscrollcommand "CrossFire::SetScrollBar $w.groupSel.list.sb"
    scrollbar $w.groupSel.list.sb -takefocus 0 \
        -command "$w.groupSel.list.lb yview"
    grid $w.groupSel.list.lb -sticky nsew
    grid columnconfigure $w.groupSel.list 0 -weight 1
    grid rowconfigure $w.groupSel.list 0 -weight 1
    grid $w.groupSel.list -padx 5 -pady 5 -sticky nsew
    grid columnconfigure $w.groupSel 0 -weight 1
    grid rowconfigure $w.groupSel 0 -weight 1

    set lb $w.groupSel.list.lb
    set storage($w,groupSelBox) $lb
    foreach {group x x} $Editor::storage(groupList) {
        if {$group == "Support Card Usablity"} continue
        $lb insert end $group
        set storage($w,groupIndex,$group) [expr [$lb index end] - 1]
    }
    bind $lb <ButtonRelease-1> "+FormatIt::ChangeGroup $w"

    # Frame for the group's options
    frame $w.optionView
    grid columnconfigure $w.optionView 0 -weight 1
    grid rowconfigure $w.optionView 0 -weight 1

    CreatePane $w Totals total  Total
    CreatePane $w Card   type   Limits
    CreatePane $w Set    set    Set
    CreatePane $w World  world  World
    CreatePane $w Rarity rarity Rarity
    CreatePane $w Digit  digit  Digit
    CreateBannedPane $w $w.optionView.optBanned
    CreateAllowedPane $w $w.optionView.optAllowed

    bind $w <Key-Up>    "FormatIt::ClickTextBox $w m -1  1 find"
    bind $w <Key-Down>  "FormatIt::ClickTextBox $w m +1  1 find"
    bind $w <Key-Home>  "FormatIt::ClickTextBox $w m 0   1 find"
    bind $w <Key-End>   "FormatIt::ClickTextBox $w m end 1 find"
    bind $w <Key-Prior> "FormatIt::ClickTextBox $w m -25 1 find"
    bind $w <Key-Next>  "FormatIt::ClickTextBox $w m +25 1 find"

    # Grid the whole screen
    grid $w.formatName -row 0 -column 0 -sticky ew   -columnspan 2
    grid $w.groupSel   -row 1 -column 0 -sticky nsew
    grid $w.optionView -row 1 -column 1 -sticky nsew
    grid $w.optionView.optTotals -sticky nsew
    grid columnconfigure $w 1 -weight 1
    grid rowconfigure $w 1 -weight 1

    # Draw the window with the the biggest options window
    # and then lock the size of it with the propagate command.
    ChangeGroup $w "Set"
    update
    grid propagate $w 0
    ChangeGroup $w "Totals"
    New $w 0
    Config::RecentFile "Format" {}

    if {$args != ""} {
        if {[Open $w [lindex $args 0] "nocomplain"] == 0} {
            Exit $w
            return
        }
    }
    wm deiconify $w
    raise $w

    if {$CrossFire::platform == "windows"} {
        focus $w
    }

    trace variable FormatIt::storage($w,name) w \
        "FormatIt::SetChanged $w true"

    return
}

# FormatIt::AddMenuBar --
#
#   Adds a simple menu bar to the deck status window.
#
# Parameters:
#   w          : Editor toplevel.
#
# Returns:
#   Nothing.
#
proc FormatIt::AddMenuBar {w} {

    variable storage

    menu $w.menubar

    $w.menubar add cascade \
        -label "File" \
        -underline 0 \
        -menu $w.menubar.file

    menu $w.menubar.file -tearoff 0
    $w.menubar.file add cascade \
        -label "New" \
        -underline 0 \
        -menu $w.menubar.file.new
    set m [menu $w.menubar.file.new -tearoff 0]
    foreach deckSize {55 75 110} {
        $m add command \
            -label "$deckSize Card" \
            -underline 0 \
            -command "FormatIt::New $w $deckSize"
    }
    $m add command \
        -label "Blank" \
        -accelerator "$CrossFire::accelKey+N" \
        -command "FormatIt::New $w 0"

    $w.menubar.file add command \
        -label "Open..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+O" \
        -command "FormatIt::Open $w {}"
    $w.menubar.file add command \
        -label "Save" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+S" \
        -command "FormatIt::Save $w"
    $w.menubar.file add command \
        -label "Save As..." \
        -underline 5 \
        -command "FormatIt::SaveAs $w"

    $w.menubar.file add separator
    $w.menubar.file add command \
        -label "Check for Errors" \
        -underline 10 \
        -command "FormatIt::ErrorCheck $w"

    $w.menubar.file add separator
    set exitLabel "Close"
    set exitAccelerator "Alt+F4"
    if {$CrossFire::platform == "macintosh"} {
        # This is a Macintosh, so make the exit
        # accelerator more "Mac-ish"
        set exitLabel "Quit"
        set exitAccelerator "Command+Q"
    }
    $w.menubar.file add command \
        -label $exitLabel \
        -underline 1 \
        -accelerator $exitAccelerator \
        -command "FormatIt::ExitEditor $w"

    $w.menubar add cascade \
        -label "View" \
        -underline 0 \
        -menu $w.menubar.view

    menu $w.menubar.view -title "Status Group" -tearoff 1

    foreach {group index hotKey} $Editor::storage(groupList) {
        if {$group == "Support Card Usablity"} continue
        $w.menubar.view add command \
            -label $group \
            -command "FormatIt::ChangeGroup $w [list $group]" \
            -underline $index \
            -accelerator "$CrossFire::accelKey+$hotKey"
        bind $w <$CrossFire::accelBind-[string tolower $hotKey]> \
            "FormatIt::ChangeGroup $w [list $group]"
    }

    $w.menubar add cascade \
        -label "Help" \
        -underline 0 \
        -menu $w.menubar.help

    menu $w.menubar.help -tearoff 0
    $w.menubar.help add command \
        -label "Help..." \
        -underline 0 \
        -accelerator "F1" \
        -command "CrossFire::Help ${CrossFire::wikiURL}FormatMaker"
    $w.menubar.help add separator
    $w.menubar.help add command \
        -label "About Format Maker..." \
        -underline 0 \
        -command "FormatIt::About $w"

    # File menu bindings.
    bind $w <$CrossFire::accelBind-n> "FormatIt::New $w 0"
    bind $w <$CrossFire::accelBind-o> "FormatIt::Open $w {}"
    bind $w <$CrossFire::accelBind-s> "FormatIt::Save $w"

    # Help menu bindings.
    bind $w <Key-F1> "CrossFire::Help ${CrossFire::wikiURL}FormatMaker"
    bind $w <Key-Help> "CrossFire::Help ${CrossFire::wikiURL}FormatMaker"

    $w config -menu $w.menubar

    return
}

# FormatIt::CreatePane --
#
#   Creates one of the panes of information.
#
# Parameters:
#   w         : Toplevel
#   oName     : Option name (Totals, Card,   Set, World, Rarity, Digit)
#   fName     : Frame name  (total,  type,   set, world, rarity, digit)
#   gName     : Group name  (Total,  Limits, Set, World, Rarity, Digit)
#
# Returns:
#   Nothing.
#
proc FormatIt::CreatePane {w oName fName gName} {

    variable storage

    set fw [frame $w.optionView.opt$oName -relief raised -borderwidth 1]
    set f [frame $fw.$fName]
    set storage($w,${fName}Frame) $f

    switch $gName {
        "Total" {
            set idList {All Chase Champions Levels Avatars}
        }
        "Limits" {
            set idList {}
            foreach id $CrossFire::cardTypeIDList {
                if {($id > 0) && ($id < 99)} {
                    lappend idList $id
                }
            }
        }
        "Set" {
            set idList "[CrossFire::CardSetIDList real] FAN"
        }
        "World" {
            set idList "$CrossFire::worldXRef(IDList,Base) FAN"
        }
        "Rarity" {
            set idList $CrossFire::cardFreqIDList
        }
	"Digit" {
	    set idList $CrossFire::cardDigitList
	}
    }

    set rowC -1
    foreach id $idList {

        set var $id
        set vid $id

        switch $gName {
            "Total" {
                foreach {key name} {
                    All       {All Cards}
                    Avatars   {Free Avatars}
                    Chase     Chase
                    Champions Champions
                    Levels    {Total Levels}
                } {
                    if {$key == $id} {
                        break
                    }
                }
            }
            "Limits" {
                set var $CrossFire::cardTypeXRef($id,name)
                set name $CrossFire::cardTypeXRef($id,name)
                set vid $name
            }
            "Set" {
                if {$id == "FAN"} {
                    set name "Fan Created"
                } else {
                    set name $CrossFire::setXRef($id,name)
                }
            }
            "World" {
                if {$id == "FAN"} {
                    set name "Fan Created"
                } else {
                    set name $CrossFire::worldXRef($id,name)
                }
            }
            "Rarity" {
                set name $CrossFire::cardFreqName($id)
            }
	    "Digit" {
		set name "Digit $id"
	    }
        }

        set tf [frame $f.${fName}$var]

        label $tf.title -text $name -width 18 -anchor w \
            -foreground black -pady 0
        entry $tf.min -width 3 -justify r -relief flat -bd 0 \
            -textvariable FormatIt::storage($w,$gName,$vid,min)
        label $tf.dash -text " - "
        entry $tf.max -width 3 -justify r -relief flat -bd 0 \
            -textvariable FormatIt::storage($w,$gName,$vid,max)
        label $tf.slash -text " x "
        entry $tf.mult -width 3 -justify r -relief flat -bd 0 \
            -textvariable FormatIt::storage($w,$gName,$vid,mult)

        foreach var {min max mult} {
            trace variable FormatIt::storage($w,$gName,$vid,$var) w \
                "FormatIt::SetChanged $w true"
        }

        if {$gName == "Total"} {
            grid $tf.title $tf.min $tf.dash $tf.max \
                -sticky ew
        } else {
            grid $tf.title $tf.min $tf.dash $tf.max $tf.slash $tf.mult \
                -sticky ew
        }
        grid $tf -sticky ew
        incr rowC
        grid columnconfigure $tf 0 -weight 1
    }

    # Create the information text box
    if {$gName == "Total"} {
        frame $f.notes

        frame $f.notes.f
        label $f.notes.f.l -text "Notes:"
        frame $f.notes.f.f
        set textw $f.notes.f.f.t
        set storage($w,infoTB) $textw
        text $textw -height 8 -wrap word \
            -wrap word -background white -foreground black \
            -yscrollcommand "CrossFire::SetScrollBar $f.notes.f.f.sb"
        scrollbar $f.notes.f.f.sb -command "$textw yview"
        bind $textw <KeyPress> "FormatIt::CheckTextChange $w %A"
        bindtags $textw "$textw Text all"
        grid $textw -sticky nsew
        grid rowconfigure $f.notes.f.f 0 -weight 1
        grid columnconfigure $f.notes.f.f 0 -weight 1
        grid $f.notes.f.l -sticky nw
        grid $f.notes.f.f -sticky nsew
        grid columnconfigure $f.notes.f 0 -weight 1
        grid rowconfigure $f.notes.f 1 -weight 1
        grid $f.notes.f -sticky nsew

        grid columnconfigure $f.notes 0 -weight 1
        grid rowconfigure $f.notes 0 -weight 1
        grid $f.notes -sticky nsew -pady 5
        incr rowC
    }

    if {$gName == "Total"} {
        grid $f -padx 5 -pady 5 -sticky nsew
        grid rowconfigure $f $rowC -weight 1
    } else {
        grid $f -padx 5 -pady 5 -sticky new
    }
    grid columnconfigure $f 0 -weight 1

    grid rowconfigure $fw 0 -weight 1
    grid columnconfigure $fw 0 -weight 1

    return
}

# FormatIt::CreateBannedPane --
#
#   Creates the pane for listing of banned cards
#
# Parameteres:
#   w          : FormatIt toplevel
#   fw         : Frame path to create in
#
# Returns:
#   Nothing.
#
proc FormatIt::CreateBannedPane {w fw} {

    variable storage

    frame $fw -relief raised -borderwidth 1

    frame $fw.banned
    set tbw $fw.banned.t
    text $tbw -width 25 -height 12 -wrap none -cursor {} -exportselection 0 \
        -background white -foreground black -state disabled -spacing1 2 \
        -takefocus 0 -yscrollcommand "CrossFire::SetScrollBar $fw.banned.sb"
    $tbw tag configure setHeader -font {Times 14 bold}
    $tbw tag configure select -foreground white -background blue
    set storage($w,bannedTextBox) $tbw
    scrollbar $fw.banned.sb -takefocus 0 -command "$tbw yview"
    grid $fw.banned.t -sticky nsew
    grid columnconfigure $fw.banned 0 -weight 1
    grid rowconfigure $fw.banned 0 -weight 1

    CrossFire::DragTarget $tbw AddCard "FormatIt::DragAddCard $w"
    CrossFire::DragTarget $tbw RemoveCard "FormatIt::DragAddCard $w"

    bind $tbw <ButtonPress-1> "FormatIt::ClickTextBox $w %X %Y 1 banned"
    bind $tbw <ButtonPress-2> "FormatIt::ClickTextBox $w %X %Y 2 banned"
    bind $tbw <ButtonPress-3> "FormatIt::ClickTextBox $w %X %Y 3 banned"
    bindtags $tbw "$tbw all"

    grid $fw.banned -padx 5 -pady 5 -sticky nsew
    grid columnconfigure $fw 0 -weight 1
    grid rowconfigure $fw 0 -weight 1

    return
}

# FormatIt::CreateAllowedPane --
#
#   Creates the pane for listing of allowed cards
#
# Parameteres:
#   w          : FormatIt toplevel
#   fw         : Frame path to create in
#
# Returns:
#   Nothing.
#
proc FormatIt::CreateAllowedPane {w fw} {

    variable storage

    frame $fw -relief raised -borderwidth 1

    frame $fw.allowed
    set tbw $fw.allowed.t
    text $tbw -width 25 -height 12 -wrap none -cursor {} -exportselection 0 \
        -background white -foreground black -state disabled -spacing1 2 \
        -takefocus 0 -yscrollcommand "CrossFire::SetScrollBar $fw.allowed.sb"
    $tbw tag configure setHeader -font {Times 14 bold}
    $tbw tag configure select -foreground white -background blue
    set storage($w,allowedTextBox) $tbw
    scrollbar $fw.allowed.sb -takefocus 0 -command "$tbw yview"
    grid $tbw -sticky nsew
    grid columnconfigure $fw.allowed 0 -weight 1
    grid rowconfigure $fw.allowed 0 -weight 1

    CrossFire::DragTarget $tbw AddCard "FormatIt::DragAddCard $w"
    CrossFire::DragTarget $tbw RemoveCard "FormatIt::DragAddCard $w"

    bind $tbw <ButtonPress-1> "FormatIt::ClickTextBox $w %X %Y 1 allowed"
    bind $tbw <ButtonPress-2> "FormatIt::ClickTextBox $w %X %Y 2 allowed"
    bind $tbw <ButtonPress-3> "FormatIt::ClickTextBox $w %X %Y 3 allowed"
    bindtags $tbw "$tbw all"

    frame $fw.type
    button $fw.type.add -text "Add Card Type" \
        -command "FormatIt::AddAllowType $w"
    grid $fw.type.add

    grid $fw.allowed -padx 5 -pady 5 -sticky nsew
    grid $fw.type -padx 5 -pady 5
    grid columnconfigure $fw 0 -weight 1
    grid rowconfigure $fw 0 -weight 1

    return
}

# FormatIt::AddAllowType --
#
#   Creates a window to select a card type to add to the allow list.
#
# Parameters:
#   w          : Topleve
#
# Returns:
#   Nothing.
#
proc FormatIt::AddAllowType {w} {

    variable storage

    set tw [toplevel $w.getAllowedType]
    wm title $tw "Select Card Type(s)"
    wm protocol $tw WM_DELETE_WINDOW "$tw.buttons.cancel invoke"

    frame $tw.top -borderwidth 1 -relief raised
    frame $tw.top.l
    listbox $tw.top.l.lb -exportselection 0 -selectmode multiple -width 30 \
        -height 10 -yscrollcommand "CrossFire::SetScrollBar $tw.top.l.sb"
    set lbw $tw.top.l.lb
    scrollbar $tw.top.l.sb -command "$lbw yview"
    grid $lbw -sticky nsew
    grid columnconfigure $tw.top.l 0 -weight 1
    grid rowconfigure $tw.top.l 0 -weight 1
    grid $tw.top.l -padx 5 -pady 5 -sticky nsew
    grid columnconfigure $tw.top 0 -weight 1
    grid rowconfigure $tw.top 0 -weight 1
    grid $tw.top -sticky nsew

    foreach id $CrossFire::cardTypeIDList {
        set tempId "type:$id"
        if {($id > 0) && ($id < 99) &&
            ([lsearch $storage($w,allowedList) $tempId] == -1)} {
            $lbw insert end $CrossFire::cardTypeXRef($id,name)
        }
    }

    frame $tw.buttons -borderwidth 1 -relief raised
    button $tw.buttons.ok -width 8 -text "Add" \
        -command "set FormatIt::storage($w,getAllowedType) ok"
    button $tw.buttons.cancel -width 8 -text "Cancel" \
        -command "set FormatIt::storage($w,getAllowedType) cancel"
    grid $tw.buttons.ok $tw.buttons.cancel -padx 5 -pady 5

    grid $tw.buttons -sticky ew

    grid rowconfigure $tw 0 -weight 1
    grid columnconfigure $tw 0 -weight 1

    grab set $tw
    vwait FormatIt::storage($w,getAllowedType)
    grab release $tw

    # snag the list from the listbox and add the types
    set added 0
    foreach lbIndex [$lbw curselection] {
        set name [$lbw get $lbIndex]
        set id "type:$CrossFire::cardTypeXRef($name)"
        if {[lsearch $storage($w,allowedList) $id] == -1} {
            lappend storage($w,allowedList) $id
            set added 1
        }
    }

    if {$added} {
        UpdateBannedAllowed $w allowed
        SetChanged $w "true"
    }

    destroy $tw

    return
}

# FormatIt::UpdateBannedAllowed --
#
#   Redraws the display of either the Banned or Allowed cards.  Cards are
#   grouped by card set.
#
# Parameters:
#   w          : Toplevel
#   group      : banned or allowed
#
# Returns:
#   Nothing.
#
proc FormatIt::UpdateBannedAllowed {w group} {

    variable storage

    set tbw $storage($w,${group}TextBox)
    set yview [expr int([$tbw index @0,0]) - 1]
    $tbw configure -state normal
    $tbw delete 1.0 end
    set lineCount 0

    set tempList ""
    set typeList ""
    foreach cardID [lsort $storage($w,${group}List)] {
        if {[regexp "type:(.*)" $cardID dummy typeID]} {
            set typeName $CrossFire::cardTypeXRef($typeID,name)
            lappend typeList "$typeName Cards"
        } else {
            lappend tempList [CrossFire::GetCard $cardID]
        }
    }

    foreach id [CrossFire::CardSetIDList "all"] {
        set displayedName 0
        set heading $CrossFire::setXRef($id,name)
        foreach card $tempList {
            if {[lindex $card 0] == $id} {
                if {$displayedName == 0} {
                    incr lineCount
                    if {$lineCount != 1} {
                        $tbw insert end "\n"
                    }
                    $tbw insert end $heading "setHeader"
                    set displayedName 1
                }
                set desc [CrossFire::GetCardDesc $card]
                $tbw insert end "\n  $desc"
            }
        }
    }

    if {$typeList != ""} {
        foreach typeName [lsort $typeList] {
            incr lineCount
            if {$lineCount != 1} {
                $tbw insert end "\n"
            }
            $tbw insert end $typeName "setHeader"
        }
    }

    $tbw yview scroll $yview units
    $tbw configure -state disabled

    return
}

# FormatIt::ChangeGroup --
#
#   Called when changing the group of information to display on the
#   format editor window.
#
# Parameters:
#   w         : Toplevel
#   which     : Optional group to change to (click does not send this).
#
# Returns:
#   Nothing.
#
proc FormatIt::ChangeGroup {w {which ""}} {

    variable storage

    set lb $storage($w,groupSelBox)

    if {$which == ""} {
        # Clicked the listbox process selection.
        set which [$lb get [$lb curselection]]
    } else {
        # Update the listbox to highlight the requested process
        $lb selection clear 0 end
        $lb selection set $storage($w,groupIndex,$which)
    }

    # Update the viewed set of options
    set fw $w.optionView.opt[lindex $which 0]
    grid forget [grid slaves $w.optionView]
    grid $fw -sticky nsew -row 0 -column 0

    set storage($w,viewing) [lindex $which 0]

    return
}

# FormatIt::ExitEditor --
#
#   Exits the format editor.  Performs clean up of stored data and tells
#   CrossFire to not worry about me anymore!
#
# Parameters:
#   w         : That silly toplevel again
#
# Returns:
#   0 if successful, -1 elsewise.
#
proc FormatIt::ExitEditor {w} {

    variable storage

    if {[CheckForSave $w] == 0} {
        destroy $w

        UnLockFile $w

        if {[info exists storage($w,autoSaveAfterID)]} {
            after cancel $storage($w,autoSaveAfterID)
        }

        # Unset all the variables for the editor.
        foreach name [array names storage "${w},*"] {
            unset storage($name)
        }

        CrossFire::UnRegister Format $w

        return 0
    } else {
        return -1
    }
}

# FormatIt::New --
#
#   Starts a new deck format.
#
# Parameters:
#   w          :  toplevel path name.
#
# Returns:
#   Nothing.
#
proc FormatIt::New {w deckSize} {

    variable storage

    if {[CheckForSave $w] == -1} {
        return
    }

    UnLockFile $w

    set storage($w,name) ""
    set storage($w,allowedList) {}
    set storage($w,bannedList) {}
    $storage($w,infoTB) delete 1.0 end

    foreach group {min max mult} {
        foreach var [array names storage "${w},*,$group"] {
            if {$group == "mult"} {
                set storage($var) 1
            } else {
                set storage($var) 0
            }
        }
    }

    UpdateBannedAllowed $w banned
    UpdateBannedAllowed $w allowed

    if {$deckSize != 0} {
        foreach var [array names CrossFire::deckFormat "$deckSize,*"] {
            foreach {dfTrash dfGroup dfVar dfWhich} [split $var ","] break
            if {$dfGroup == "Type"} {
                set dfGroup "Limits"
            }
            set storage($w,$dfGroup,$dfWhich,$dfVar) \
                $CrossFire::deckFormat($var)
        }
    }

    SetChanged $w "false"

    return
}

# FormatIt::SetChanged --
#
#   Changes the boolean flag for if a format has changed.
#   Adjusts the title of the editor; adds a '*' indicating
#   that a change has been made.
#
# Parameters:
#   w          : FormatIt toplevel.
#   bool       : Boolean (true or false). Need to save?
#   args       : Extra things that are appended by a variable trace.
#
# Returns:
#   Nothing.
#
proc FormatIt::SetChanged {w bool args} {

    variable storage
    variable windowTitle

    set storage($w,change) $bool
    set sfn $storage($w,name)

    if {$sfn != ""} {
        set sfn "- $sfn "
    }

    if {[info exists storage($w,autoSaveAfterID)]} {
        after cancel $storage($w,autoSaveAfterID)
        unset storage($w,autoSaveAfterID)
    }

    set title "$windowTitle $sfn"
    if {$bool == "true"} {
        wm title $w "${title}*"
        if {($storage($w,fileName) != "") &&
            ($Config::config(Format,autoSave) == "Yes")} {
            if {$Config::config(Format,autoSaveTime) > 0} {
                set delayTime \
                    [expr $Config::config(Format,autoSaveTime) * 60000]
                set storage($w,autoSaveAfterID) \
                    [after $delayTime "FormatIt::Save $w"]
            }
        }
    } else {
        wm title $w $title
    }

    return
}

# FormatIt::DragAddCard --
#
#   Called when a dropped card is about to be added.
#
# Parameters:
#   w          : Widget receiving the drop.
#   from       : Widget sending the data.
#   args       : Data.
#
# Returns:
#   Nothing.
#
proc FormatIt::DragAddCard {w from args} {

    variable storage

    set first [lindex $args 0]

    if {$first == ""} {
        return
    }

    set card [CrossFire::GetCard $first]

    if {$card != ""} {
        if {$storage($w,viewing) == "Banned"} {
            set which "banned"
        } else {
            set which "allowed"
        }

        if {[lsearch $storage($w,${which}List) $first] == -1} {
            lappend storage($w,${which}List) $first
            UpdateBannedAllowed $w $which
            SetChanged $w "true"
       }
    } else {
        tk_messageBox -parent $w -title "What?" -icon info \
            -message "Please only drop cards for now!"
    }

    return
}

# FormatIt::GetSelectedCardID --
#
#   Returns the short ID of the selected card, if any.
#
# Parameters:
#   w          : FormatIt toplevel widget name.
#
# Returns:
#   The short ID if a card is selected, nothing otherwise.
#
proc FormatIt::GetSelectedCardID {w who} {

    variable storage

    set tbw $storage($w,${who}TextBox)

    # Get the selection from a text box.
    set start [lindex [$tbw tag ranges select] 0]
    if {$start == ""} {
        set selectedCard ""
    } else {
        set end [lindex [split $start "."] 0].end
        set selectedCard [$tbw get $start $end]
    }

    if {[lsearch [$tbw tag names $start] "setHeader"] == -1} {
        set selectedCard [lindex $selectedCard 0]
        set type "card"
    } else {
        set type "group"
    }

    return [list $selectedCard $type]
}

# FormatIt::ClickTextBox --
#
#   Adds a highlight bar to the line clicked on in a text box.
#   This is made to resemble a list box.
#
# Parameters:
#   w          : Toplevel
#   X Y        : Coordinates clicked. (%X %Y)
#   btnNumber  : Button number pressed.
#
# Returns:
#   Nothing.
#
proc FormatIt::ClickTextBox {w X Y btnNumber which} {

    variable storage

    if {$which == "find"} {
        if {$storage($w,viewing) == "Banned"} {
            set which "banned"
        } elseif {$storage($w,viewing) == "Allowed"} {
            set which "allowed"
        } else {
            return
        }
    }

    set tw $storage($w,${which}TextBox)

    # Determine which line was clicked/requested.
    # A line is requested by specifing m for the X coordinate.
    # The Y value will either contain on offset (+/- lines) or
    # an absolute line number (line).
    if {$X == "m"} {
        set lastLine [expr int([$tw index end]) - 1]
        set curSel [lindex [split [lindex [$tw tag ranges select] 0] .] 0]
        if {$curSel == ""} {
            set curSel 0
        }

        set first [string index $Y 0]
        if {$first == "-"} {
            set pos [expr $curSel + $Y]
        } elseif {$first == "+"} {
            set pos [expr $curSel + [string range $Y 1 end]]
            if {$pos > $lastLine} {
                set pos $lastLine
            }
        } else {
            if {$Y == "end"} {
                set pos $lastLine
            } else {
                set pos $Y
            }
        }

        if {$pos < 1} {
            set pos 1
        }
    } else {
        # Translate X,Y coordinates to x,y of text box, determine line number.
        set x [expr $X - [winfo rootx $tw]]
        set y [expr $Y - [winfo rooty $tw]]
        set pos [expr int([$tw index @$x,$y])]
    }

    # Remove current selection, if any.
    $tw tag remove select 1.0 end

    if {[$tw get 1.0 end] == "\n"} {
        return
    }

    $tw tag add select $pos.0 [expr $pos + 1].0
    $tw see $pos.0

    foreach {cardID type} [GetSelectedCardID $w $which] break

    if {$type == "card"} {
        if {($Config::config(ViewCard,mode) == "Continuous")} {
 	    ViewCard::View $w $cardID
            focus $w
 	}
    }

    # Do various activities depending which button was pressed.
    switch -- $btnNumber {
        1 {
            # Start the drag-n-drop routines.
            #CrossFire::StartDrag $tw target RemoveCard $cardID
        }

        2 {
            if {($type == "group") && ($which == "banned")} {
                # nada
            } else {
                RemoveCard $w $which $cardID $type
            }
        }

        3 {
            # Pop-up Menu
            if {[winfo exists $w.removeMenu]} "destroy $w.removeMenu"

            if {($type == "group") && ($which == "banned")} {
                # Not doing bulk set removal (yet) -- Button 2 also!
            } else {

                menu $w.removeMenu -tearoff 0
                $w.removeMenu add command -label " Remove" -command \
                    "FormatIt::RemoveCard $w $which [list $cardID] $type"
                if {$type == "card"} {
                    $w.removeMenu add separator
                    $w.removeMenu add command -label " View" \
                        -command "ViewCard::View $w $cardID"
                }

                tk_popup $w.removeMenu $X $Y
            }
        }
    }

    return
}

# FormatIt::ViewCard --
#
#   Views the currently selected card.
#
# Parameters:
#   w          : FormatIt toplevel.
#
# Returns:
#   Nothing.
#
proc FormatIt::ViewCard {w} {

    ViewCard::View $w [lindex [GetSelectedCardID $w] 0]

    return
}

# FormatIt::RemoveCard --
#
#   Removes a card, set of cards, or card type from either the 
#   allowed or banned list.
#
# Parameters:
#   w          : Ever present toplevel
#   which      : banned or allowed
#   cardID     : Normal card ID or group heading
#   type       : card or group
#
# Returns:
#   Nothing.
#
proc FormatIt::RemoveCard {w which cardID type} {

    variable storage

    set cList $storage($w,${which}List)
    if {$type == "group"} {
        if {$which == "allowed"} {
            # Create a new cardID that is our key for a card type
            set cType [lrange $cardID 0 end-1]
            set typeID $CrossFire::cardTypeXRef($cType)
            set cardID "type:$typeID"
        } else {
            # banned list card set. not implemented yet.
            bell
            return
        }
    }

    set pos [lsearch $cList $cardID]
    set cList [lreplace $cList $pos $pos]
    set storage($w,${which}List) $cList

    UpdateBannedAllowed $w $which
    SetChanged $w "true"

    return
}
