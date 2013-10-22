# EditorU.tcl 20051122
#
# This file contains all the utility procedures for the DeckIt! editor.
#
# Copyright (c) 1998-2005 Dan Curtiss. All rights reserved.
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

# Editor::About --
#
#   Displays an about dialog for the DeckIt! Deck Editor
#
# Paramters:
#   w         : Parent toplevel for the pop-up dialog.
#
# Returns:
#   Nothing.
#
proc Editor::About {w} {
    set message "CrossFire DeckIt! Deck Editor\n"
    append message "\nby Dan Curtiss"
    tk_messageBox -icon info -title "About CrossFire DeckIt!" \
        -parent $w -message $message
    return
}

# Editor::ScanForCard --
#
#   Scans all of the deck files in a directory for decks that contain the
#   card in either the deck list or considering cards list.
#
# Parameters:
#   w          : toplevel
#   dir        : Directory to scan
#
# Returns:
#   Nothing.
#
proc Editor::ScanForCard {w id dir} {

    variable storage

    set ext $CrossFire::extension(deck)

    foreach fileName [glob -nocomplain [file join $dir "*"]] {
        set fType [file type $fileName]
        if {$fType == "link"} {
            ScanForCard $w $id [file readlink $fileName]
        } elseif {$fType == "directory"} {
            ScanForCard $w $id $fileName
        } elseif {($fType == "file") &&
                  ([file extension $fileName] == $ext)} {
            ReadDeck $w $fileName
            set deckCards [GetDeckInfo $w deck]
            set altCards  [GetDeckInfo $w altCards]
            set deckTitle [GetDeckInfo $w deckTitle]
            if {[lsearch $deckCards $storage($w,$id,searchCardID)] != -1} {
                lappend storage($w,$id,findDeckList) \
                    [list $deckTitle $fileName]
            }
            if {[lsearch $altCards $storage($w,$id,searchCardID)] != -1} {
                lappend storage($w,$id,findAltList) [list $deckTitle $fileName]
            }
        }
    }

    return
}

# Editor::FindCardInDeck --
#
#   Searches for a specific card in decks.  Calls ScanForCard to do the
#   scanning and then creates a toplevel to display the results.
#
# Paramters:
#   w         : Parent toplevel for the pop-up dialog.
#
# Returns:
#   Nothing.
#
proc Editor::FindCardInDeck {w} {

    variable storage

    # Get card info on our card of interest
    set cardID [GetSelectedCardID $w]
    set searchID [CrossFire::DecodeShortID $cardID]
    set card [CrossFire::GetCard $cardID]
    set cardDesc [CrossFire::GetCardDesc $card]

    # Create the UI
    set fID "find[clock seconds]"
    set tl [toplevel $w.$fID]
    wm title $tl "Find $cardDesc"

    set exitCommand "$tl.buttons.close invoke"
    wm protocol $tl WM_DELETE_WINDOW $exitCommand
    bind $tl <Key-Escape> $exitCommand

    # add a menu
    set m [menu $tl.menubar]
    $m add cascade \
        -label "Window" \
        -underline 0 \
        -menu $m.window

    menu $m.window -tearoff 0
    if {$CrossFire::platform == "macintosh"} {
        set exitLabel "Quit"
        set exitAccelerator "Command+Q"
        bind $tl <Command-q> $exitCommand
    } else {
        set exitLabel "Close"
        set exitAccelerator "Alt+F4"
        bind $tl <Meta-x> $exitCommand
        bind $tl <Alt-F4> $exitCommand
    }
    $m.window add command \
        -label $exitLabel \
        -underline 1 \
        -accelerator $exitAccelerator \
        -command $exitCommand

    $tl configure -menu $m

    # Create an embedded card view window
    set fw [frame $tl.cardView -borderwidth 2 -relief groove]
    set storage($w,$fID,cardFrame) [ViewCard::CreateCardView $fw.cv]
    grid $fw.cv -sticky nsew -padx 3 -pady 3
    grid rowconfigure $fw 0 -weight 1
    grid columnconfigure $fw 0 -weight 1
    grid $fw -sticky nsew
    ViewCard::UpdateCardView $storage($w,$fID,cardFrame) $card

    # Create the 2 listboxes
    set f [frame $tl.top -borderwidth 2 -relief groove]

    foreach {which var} {
        Deck        findDeckList
        Considering findAltList
    } {
        set fw [frame $f.f$which]
        label $fw.l -text "Contained in $which Cards:"
        frame $fw.f
        set lbw \
            [listbox $fw.f.lb -selectmode single \
                 -width 50 -height 8 -exportselection 0 -background white \
                 -foreground black -selectbackground blue -takefocus 0 \
                 -selectforeground white -selectborderwidth 0 -yscrollcommand \
                 "CrossFire::SetScrollBar $fw.f.sb"]
        set storage($w,$fID,lb$var) $lbw
        scrollbar $fw.f.sb -takefocus 0 -command "$lbw yview"
        grid $fw.l -sticky w
        grid $lbw -sticky nsew
        grid columnconfigure $fw.f 0 -weight 1
        grid rowconfigure $fw.f 0 -weight 1

        bind $lbw <Double-Button-1> "Editor::OpenFoundDeck $w $fID $var"

        grid $fw.f -sticky nsew
        grid columnconfigure $fw  0 -weight 1
        grid rowconfigure $fw 1 -weight 1

        grid $fw -sticky nsew -padx 3 -pady 3
    }

    grid columnconfigure $f 0 -weight 1
    grid rowconfigure $f {0 1} -weight 1
    grid $f -sticky nsew -column 1 -row 0

    # command buttons
    set fw [frame $tl.buttons -borderwidth 2 -relief groove]
    button $fw.close -text $CrossFire::close -width 8 \
        -command "Editor::CloseDeckFinder $w $fID"
    grid $fw.close -padx 5 -pady 5
    grid $fw -sticky ew -columnspan 2

    grid columnconfigure $tl 1 -weight 1
    grid rowconfigure $tl 0 -weight 1

    # Search!
    set storage($w,$fID,searchCardID) $searchID
    set storage($w,$fID,findDeckList) {}
    set storage($w,$fID,findAltList) {}

    # Scan the deck directory and sub-dirs
    ScanForCard $w $fID $Config::config(DeckIt,dir)

    # Populate the listboxes
    foreach which {findDeckList findAltList} {
        foreach deckInfo $storage($w,$fID,$which) {
            foreach {deckName deckFile} $deckInfo break
            $storage($w,$fID,lb$which) insert end $deckName
            set storage($w,$fID,file,$deckName) $deckFile
        }
    }

    focus $tl

    return
}

# Editor::OpenFoundDeck --
#
#   Opens a deck from the find card in deck window.
#
# Parameters:
#   w          : Editor toplevel
#   id         : Find window id
#   which      : Which list was selected (findDeckList, findAltList)
#
# Returns:
#   Nothing.
#
proc Editor::OpenFoundDeck {w id which} {

    variable storage

    set lbw $storage($w,$id,lb$which)
    set deckName [$lbw get [$lbw curselection]]
    Create $storage($w,$id,file,$deckName)

    return
}

# Editor::CloseDeckFinder --
#
#   Clears all the variables and destroys the window.
#
# Parameters:
#   w          : Editor toplevel
#   id         : Find window id
#
# Returns:
#   Nothing.
#
proc Editor::CloseDeckFinder {w fID} {

    variable storage

    foreach varName [array names "$w,$fID,*"] {
        unset storage($varName)
    }
    destroy $w.$fID

    return
}

# Editor::UpdateDeckStatus --
#
#   Updates the deck status window's label colors or maximums and banned.
#   Color updates all quantites and label colors.  Max updates all colors
#   and redraws the list of banned & allowed cards.
#
# Parameters:
#   w          : Editor toplevel.
#   which      : Color or Max.
#
# Returns:
#   Nothing.
#
proc Editor::UpdateDeckStatus {w which} {

    variable storage

    if {[winfo exists $w.deckStatus] == 0} {
        return
    }

    set df $storage($w,size)

    foreach {fName gName} {
        total  Total
        type   Type
        set    Set
        world  World
        rarity Rarity
	digit  Digit
    } {
        set fw $storage($w,${fName}Frame).${fName}

        # Get the list of IDs to check
        switch $gName {
            "Total" {
                set idList {All Chase Champions Levels Avatars}
            }
            "Type" {
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

        foreach id $idList {
            set var $id
            switch $gName {
                "Type" {
                    set var $CrossFire::cardTypeXRef($id,name)
                }
            }

            set qty $storage($w,$gName,qty,$var)
            set min $CrossFire::deckFormat($df,$gName,min,$var)
            set max $CrossFire::deckFormat($df,$gName,max,$var)
            if {($qty < $min) || ($qty > $max)} {
                $fw$var.title configure -foreground red
            } else {
                $fw$var.title configure -foreground black
            }
            if {$gName != "Total"} {
                set detail [format "/ %3d - %3d x %2d" $min $max \
                                $CrossFire::deckFormat($df,$gName,mult,$var)]
            } else {
                set detail [format "/ %3d - %3d" $min $max]
            }
            $fw$var.detail configure -text $detail
        }
    }

    if {$which == "Color"} return

    # Update the list of banned and allowed cards
    foreach group {banned allowed} {

        set tbw $storage($w,${group}TextBox)
        $tbw configure -state normal
        $tbw delete 1.0 end
        set lineCount 0

        set tempList ""
        set typeList ""
        foreach cardID [lsort $CrossFire::deckFormat($df,${group}List)] {
            if {[regexp "type:(.*)" $cardID dummy typeID]} {
                lappend typeList $typeID
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
            foreach id $typeList {
                incr lineCount
                if {$lineCount != 1} {
                    $tbw insert end "\n"
                }
                set typeName $CrossFire::cardTypeXRef($id,name)
                $tbw insert end "$typeName Cards" "setHeader"
            }
        }

        $tbw configure -state disabled
    }

    # Update the infomation text box
    set tbw $storage($w,infoTB)
    $tbw configure -state normal
    $tbw delete 1.0 end
    $tbw insert end $CrossFire::deckFormat($df,information)
    $tbw configure -state disabled

    return
}

# Editor::ChangeGroup --
#
#   Called when changing the group of information to display on the
#   deck status window.
#
# Parameters:
#   
#
# Returns:
#   Nothing.
#
proc Editor::ChangeGroup {w {which ""}} {

    variable storage

    set dsw $storage($w,deckStatus)
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
    set fw $dsw.optionView.opt[lindex $which 0]
    grid forget [grid slaves $dsw.optionView]
    grid $fw -sticky nsew -row 0 -column 0

    wm title $dsw "Deck Status - $which"
    return
}

# Editor::DeckStatus --
#
#   Creates the deck status window.  This shows all of the deck format
#   information.  Any violations are displayed in red.
#
# Parameters:
#   w          : Editor toplevel.
#
# Returns:
#   Nothing.
#
proc Editor::DeckStatus {w {which ""}} {

    variable storage

    set dsw $w.deckStatus

    if {[winfo exists $dsw]} {
        wm deiconify $dsw
        raise $dsw
        return
    }

    set storage($w,deckStatus) $dsw

    toplevel $dsw
    wm withdraw $dsw
    bind $dsw <Key-Escape> "destroy $dsw"
    wm title $dsw "Deck Status"
    CrossFire::Transient $dsw
    AddDeckStatusMenuBar $w

    # List of all the groups
    frame $dsw.groupSel -relief raised -borderwidth 1
    frame $dsw.groupSel.list
    listbox $dsw.groupSel.list.lb -selectmode single -width 20 \
        -height 1 -background white -foreground black \
        -selectbackground blue -selectforeground white \
        -selectborderwidth 0 -takefocus 0 -exportselection 0 \
        -yscrollcommand "CrossFire::SetScrollBar $dsw.groupSel.list.sb"
    scrollbar $dsw.groupSel.list.sb -takefocus 0 \
        -command "$dsw.groupSel.list.lb yview"
    grid $dsw.groupSel.list.lb -sticky nsew
    grid columnconfigure $dsw.groupSel.list 0 -weight 1
    grid rowconfigure $dsw.groupSel.list 0 -weight 1
    grid $dsw.groupSel.list -padx 5 -pady 5 -sticky nsew
    grid columnconfigure $dsw.groupSel 0 -weight 1
    grid rowconfigure $dsw.groupSel 0 -weight 1

    set lb $dsw.groupSel.list.lb
    set storage($w,groupSelBox) $lb
    foreach {group x x} $storage(groupList) {
        $lb insert end $group
        set storage($w,groupIndex,$group) [expr [$lb index end] - 1]
    }
    bind $lb <ButtonRelease-1> "+Editor::ChangeGroup $w"

    # Frame for the group's options
    frame $dsw.optionView
    grid columnconfigure $dsw.optionView 0 -weight 1
    grid rowconfigure $dsw.optionView 0 -weight 1

    CreatePane $w Totals total  Total
    CreatePane $w Card   type   Type
    CreatePane $w Set    set    Set
    CreatePane $w World  world  World
    CreatePane $w Rarity rarity Rarity
    CreatePane $w Digit  digit  Digit
    CreateUsablePane $w $dsw.optionView.optSupport
    CreateBannedPane $w $dsw.optionView.optBanned
    CreateAllowedPane $w $dsw.optionView.optAllowed

    # Grid the whole screen
    grid $dsw.groupSel -row 0 -column 0 -sticky nsew
    grid $dsw.optionView -row 0 -column 1 -sticky nsew
    grid $dsw.optionView.optTotals -sticky nsew
    grid columnconfigure $dsw 1 -weight 1
    grid rowconfigure $dsw 0 -weight 1

    # Draw the window with the the biggest options window
    # and then lock the size of it with the propagate command.
    ChangeGroup $w "Set"
    update
    grid propagate $dsw 0
    ChangeGroup $w $which
    wm deiconify $dsw
    UpdateDeckStatus $w Max

    if {$CrossFire::platform == "windows"} {
        focus $dsw
    }

    return
}

# Editor::AddDeckStatusMenuBar --
#
#   Adds a simple menu bar to the deck status window.
#
# Parameters:
#   w          : Editor toplevel.
#
# Returns:
#   Nothing.
#
proc Editor::AddDeckStatusMenuBar {w} {

    variable storage

    set dsw $storage($w,deckStatus)

    menu $dsw.menubar

    $dsw.menubar add cascade \
        -label "View" \
        -underline 0 \
        -menu $dsw.menubar.view

    menu $dsw.menubar.view -title "Status Group" -tearoff 1

    foreach {group index hotKey} $storage(groupList) {
        $dsw.menubar.view add command \
            -label $group \
            -command "Editor::ChangeGroup $w [list $group]" \
            -underline $index \
            -accelerator "$CrossFire::accelKey+$hotKey"
        bind $dsw <$CrossFire::accelBind-[string tolower $hotKey]> \
            "Editor::ChangeGroup $w [list $group]"
    }

    $dsw.menubar.view add separator
    set exitLabel "Close"
    set exitAccelerator "Alt+F4"
    if {$CrossFire::platform == "macintosh"} {
        # This is a Macintosh, so make the exit
        # accelerator more "Mac-ish"
        set exitLabel "Quit"
        set exitAccelerator "Command+Q"
    }
    $dsw.menubar.view add command \
        -label $exitLabel \
        -underline 1 \
        -accelerator $exitAccelerator \
        -command "destroy $dsw"

    $dsw config -menu $dsw.menubar

    return
}

# Editor::CreatePane --
#
proc Editor::CreatePane {w oName fName gName} {

    variable storage

    set dsw $storage($w,deckStatus)
    set fw [frame $dsw.optionView.opt$oName -relief raised -borderwidth 1]
    set f [frame $fw.$fName]
    set storage($w,${fName}Frame) $f

    switch $gName {
        "Total" {
            set idList {All Chase Champions Levels Avatars}
        }
        "Type" {
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
        switch $gName {
            "Total" {
                foreach {key name} {
                    All       {All Cards}
                    Chase     Chase
                    Champions Champions
                    Levels    {Total Levels}
                    Avatars   {Free Avatars}
                } {
                    if {$key == $id} {
                        break
                    }
                }
            }
            "Type" {
                set var $CrossFire::cardTypeXRef($id,name)
                set name $CrossFire::cardTypeXRef($id,name)
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

        frame $f.${fName}$var
        label $f.${fName}$var.title -text $name -width 18 -anchor w \
            -foreground black -pady 0
        label $f.${fName}$var.qty -width 3 -anchor e -pady 0 \
            -textvariable Editor::storage($w,$gName,qty,$var)
        label $f.${fName}$var.detail -width 16 -pady 0 -anchor w
        grid $f.${fName}$var.title $f.${fName}$var.qty \
            $f.${fName}$var.detail -sticky ew
        grid $f.${fName}$var -sticky ew
        incr rowC
        grid columnconfigure $f.${fName}$var 0 -weight 1
    }

    if {$gName == "Digit"} {
	set py 5
	foreach {vName tName} {
            avg {Average Last Digit}
            vorpal {Vorpal Blade / Poison Defeat}
            ultrablast {Ultrablast Defeat}
            knockdown {Knockdown Defeat}
            fates1 {The Fates Draw Cards}
            fates2 {The Fates Discard Cards}
            fates3 {The Fates Discard None}
        } {
	    frame $f.digit$vName
	    label $f.digit${vName}.title -text $tName -width 24 -anchor w \
		-foreground black -pady 0
	    label $f.digit${vName}.data -width 8 -anchor e -pady 0 \
		-textvariable Editor::storage($w,Digit,$vName)
	    grid $f.digit${vName}.title $f.digit${vName}.data
	    grid $f.digit$vName -pady $py -sticky w
	    set py 0
	}
    }

    # Create the information text box
    if {$gName == "Total"} {
        frame $f.notes

        frame $f.notes.f
        label $f.notes.f.l -text "Information:"
        frame $f.notes.f.f
        set textw $f.notes.f.f.t
        set storage($w,infoTB) $textw
        text $textw -height 8 -wrap word -state disabled -cursor {} \
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

# Editor::CreateUsablePane --
#
# Parameteres:
#   w          : Editor toplevel
#   fw         : Frame path to create in
#
# Returns:
#   Nothing.
#
proc Editor::CreateUsablePane {w fw} {

    variable storage

    frame $fw -relief raised -borderwidth 1
    set f [frame $fw.f]
    set count 0
    set py 5
    foreach usable [lsort $CrossFire::usableCards(list)] {
        set myF [frame $f.usable[incr count]]
        label $myF.title -text $usable -width 25 -anchor w \
            -foreground black -pady 0
        label $myF.data -width 3 -anchor e -pady 0 \
            -textvariable Editor::storage($w,Usable,$usable)
        grid $myF.title $myF.data 
        grid $myF -sticky w
        set py 0
    }

    grid columnconfigure $f 0 -weight 1
    grid rowconfigure $f $count -weight 1

    grid $f -sticky nsew -padx 5 -pady 5
    grid columnconfigure $fw 0 -weight 1
    grid rowconfigure $fw 0 -weight 1

    return
}

# Editor::CreateBannedPane --
#
#   Creates the pane for listing of banned cards
#
# Parameteres:
#   w          : Editor toplevel
#   fw         : Frame path to create in
#
# Returns:
#   Nothing.
#
proc Editor::CreateBannedPane {w fw} {

    variable storage

    frame $fw -relief raised -borderwidth 1

    frame $fw.banned
    text $fw.banned.t -width 25 -height 12 -wrap none -cursor {} \
        -background white -foreground black -state disabled -spacing1 2 \
        -takefocus 0 -exportselection 0 -yscrollcommand \
        "CrossFire::SetScrollBar $fw.banned.sb"
    $fw.banned.t tag configure setHeader -font {Times 14 bold}
    set storage($w,bannedTextBox) $fw.banned.t
    scrollbar $fw.banned.sb -takefocus 0 -command "$fw.banned.t yview"
    grid $fw.banned.t -sticky nsew
    grid columnconfigure $fw.banned 0 -weight 1
    grid rowconfigure $fw.banned 0 -weight 1

    grid $fw.banned -padx 5 -pady 5 -sticky nsew
    grid columnconfigure $fw 0 -weight 1
    grid rowconfigure $fw 0 -weight 1

    return
}

# Editor::CreateAllowedPane --
#
#   Creates the pane for listing of allowed cards
#
# Parameteres:
#   w          : Editor toplevel
#   fw         : Frame path to create in
#
# Returns:
#   Nothing.
#
proc Editor::CreateAllowedPane {w fw} {

    variable storage

    frame $fw -relief raised -borderwidth 1

    frame $fw.allowed
    text $fw.allowed.t -width 25 -height 12 -wrap none -cursor {} \
        -background white -foreground black -state disabled -spacing1 2 \
        -takefocus 0 -exportselection 0 -yscrollcommand \
        "CrossFire::SetScrollBar $fw.allowed.sb"
    $fw.allowed.t tag configure setHeader -font {Times 14 bold}
    set storage($w,allowedTextBox) $fw.allowed.t
    scrollbar $fw.allowed.sb -takefocus 0 -command "$fw.allowed.t yview"
    grid $fw.allowed.t -sticky nsew
    grid columnconfigure $fw.allowed 0 -weight 1
    grid rowconfigure $fw.allowed 0 -weight 1

    grid $fw.allowed -padx 5 -pady 5 -sticky nsew
    grid columnconfigure $fw 0 -weight 1
    grid rowconfigure $fw 0 -weight 1

    return
}

# Editor::OldDeckStatus --
#
#   Creates or raises the old deck status box for the deck
#   associated with the specified editor toplevel.
#
# Parameters:
#   w          : Editor toplevel path name.
#
# Returns:
#   Nothing.
#
proc Editor::OldDeckStatus {w} {

    variable storage

    set dsw $w.status

    if {[winfo exists $dsw]} {
        wm deiconify $dsw
        raise $dsw
        return
    }

    toplevel $dsw
    bind $dsw <Key-Escape> "$dsw.buttons.close invoke"
    wm title $dsw "Older Deck Status"

    CrossFire::Transient $dsw

    frame $dsw.top -relief raised -borderwidth 1
    set row 0
    set id $storage($w,size)

    foreach cardTypeID $CrossFire::cardTypeIDList {

        set typeName $CrossFire::cardTypeXRef($cardTypeID,name)
        set totalName $CrossFire::cardTypeXRef($cardTypeID,icon)
        if {$cardTypeID > 0 && $cardTypeID < 99} {
            set maxVar $id,Type,max,$typeName
            set qtyVar $w,Type,qty,$typeName
        } else {
            set maxVar $id,Total,max,$totalName
            set qtyVar $w,Total,qty,$totalName
        }

        label $dsw.top.row${row}label -text $typeName -anchor w -pady 0
        label $dsw.top.row${row}current -width 3 -anchor e -borderwidth 0 \
            -textvariable Editor::storage($qtyVar)

        grid $dsw.top.row${row}label -column 0 -row $row -sticky w
        grid $dsw.top.row${row}current -column 1 -row $row -sticky e

        grid rowconfigure $dsw.top $row -weight 1
        incr row
    }

    grid columnconfigure $dsw.top {0 1 2} -weight 1
    grid $dsw.top -sticky nsew

    frame $dsw.buttons -relief raised -borderwidth 1
    button $dsw.buttons.close -text $CrossFire::close \
        -command "destroy $dsw"
    grid $dsw.buttons.close -pady 5
    grid $dsw.buttons -sticky ew

    grid columnconfigure $dsw 0 -weight 1
    grid rowconfigure $dsw 0 -weight 1

    return
}


# Editor::SharedCards --
#
#   Builds a list of cards that are common to two decks.
#
# Parameters:
#   deckList1  : List of cards from deck 1.
#   deckList2  : List of cards from deck 2.
#
# Returns:
#   List of shared cards.
#
proc Editor::SharedCards {deckList1 deckList2} {

    set same ""

    foreach card $deckList1 {
        if {([lsearch -exact $deckList2 $card] != -1) &&
            ([lsearch -exact $same $card] == -1)} {
            lappend same $card
        }
    }

    return $same
}

# Editor::UniqueCards --
#
#   Builds a list of cards that are not common to two decks.
#
# Parameters:
#   deckList1  : List of cards from deck 1.
#   deckList2  : List of cards from deck 2.
#
# Returns:
#   A list of two lists. List one contains cards in deck 1, but not
#   in deck 2. List two contains cards in deck 2, but not in deck 1.
#
proc Editor::UniqueCards {deckList1 deckList2} {

    set uniqDeck1 ""
    set uniqDeck2 ""

    # Make list of cards in deck 1 that are not in deck 2.
    foreach card $deckList1 {
        if {([lsearch -exact $deckList2 $card] == -1) &&
            ([lsearch -exact $uniqDeck1 $card] == -1)} {
            lappend uniqDeck1 $card
        }
    }

    # Make list of cards in deck 2 that are not in deck 1.
    foreach card $deckList2 {
        if {([lsearch -exact $deckList1 $card] == -1) &&
            ([lsearch -exact $uniqDeck2 $card] == -1)} {
            lappend uniqDeck2 $card
        }
    }

    return [list $uniqDeck1 $uniqDeck2]
}

# Editor::DeckDiffer --
#
#   Creates a toplevel for "diffing" two decks.  This will either
#   display the cards that are in both of two decks or the cards
#   that are only in one deck.
#
# Parameters:
#   w          : Editor toplevel.
#
# Returns:
#   Nothing.
#
proc Editor::DeckDiffer {w} {

    variable storage

    set tw $w.diff
    if {[winfo exists $tw]} {
        wm deiconify $tw
        raise $tw
        return
    }

    toplevel $tw
    wm title $tw "Deck Differ"
    bind $tw <Key-Escape> "$tw.buttons.close invoke"

    CrossFire::Transient $tw

    set storage($w,differ) $tw

    menu $tw.menubar
    $tw configure -menu $tw.menubar

    $tw.menubar add cascade \
        -label "Window" \
        -underline 0 \
        -menu $tw.menubar.window

    menu $tw.menubar.window -tearoff 0
    set exitLabel "Close"
    set exitAccelerator "Alt+F4"
    if {$CrossFire::platform == "macintosh"} {
        # This is a Macintosh, so make the exit
        # accelerator more "Mac-ish"
        set exitLabel "Quit"
        set exitAccelerator "Command+Q"
    }
    $tw.menubar.window add command \
        -label $exitLabel \
        -underline 1 \
        -accelerator $exitAccelerator \
        -command "destroy $tw"

    if {$CrossFire::platform == "macintosh"} {
        bind $tw <Command-q> "destroy $tw"
    } else {
        bind $tw <Meta-x> "destroy $tw"
        bind $tw <Alt-F4> "destroy $tw"
    }

    set ttw $tw.top
    frame $tw.top -relief raised -borderwidth 1

    # Create the two deck filename entries.
    for {set i 1} {$i <= 2} {incr i} {
        frame $ttw.deck$i
        label $ttw.deck$i.l -text "Deck $i:"
        entry $ttw.deck$i.e -background white -foreground black \
            -textvariable Editor::storage($w,deck${i}FileName) \
            -state disabled
        set storage($w,diffEntry$i) $ttw.deck$i.e
        button $ttw.deck$i.b -text "Select..." \
            -command "Editor::SelectDeckFile $w $i"
        grid $ttw.deck$i.l -sticky nsew -row 0 -column 0
        grid $ttw.deck$i.e -sticky ew -padx 5 -row 0 -column 1
        grid $ttw.deck$i.b -sticky nsew -row 0 -column 2
        grid columnconfigure $ttw.deck$i 1 -weight 1
        grid $ttw.deck$i -padx 5 -pady 5 -sticky ew
    }

    # Diff type selection.
    frame $ttw.diffType
    label $ttw.diffType.l -text "Find Cards That Are:"
    menubutton $ttw.diffType.mb -width 10 -relief raised \
        -indicatoron 1 -menu $ttw.diffType.mb.types -takefocus 1 \
        -textvariable Editor::storage($w,diffType)
    grid $ttw.diffType.l $ttw.diffType.mb \
        -sticky ew -padx 5 -pady 5
    grid columnconfigure $ttw.diffType 1 -weight 1
    menu $ttw.diffType.mb.types -tearoff 0
    foreach diffType "Shared Unique" {
        $ttw.diffType.mb.types add command -label $diffType \
            -command "Editor::ChangeDiffType $w $diffType; focus $tw"
    }
    set storage($w,diffType) "Shared"
    grid $ttw.diffType -sticky nsew

    # Text box to display results in.
    frame $ttw.results
    text $ttw.results.t -width 50 -height 10 -wrap none \
        -yscrollcommand "CrossFire::SetScrollBar $ttw.results.sb" \
        -exportselection 0 -selectborderwidth 0 -cursor {} \
        -selectbackground blue -selectforeground white \
        -background white -foreground black -takefocus 0
    $ttw.results.t tag configure select -foreground white -background blue
    $ttw.results.t tag configure title -font {Times 14 bold}
    scrollbar $ttw.results.sb -command "$ttw.results.t yview"
    grid $ttw.results.t -sticky nsew
    grid columnconfigure $ttw.results 0 -weight 1
    grid rowconfigure $ttw.results 0 -weight 1
    grid $ttw.results -sticky nsew -padx 5 -pady 5
    set storage($w,diffTextBox) $ttw.results.t

    bind $ttw.results.t <ButtonPress-1> \
        "Editor::ClickTextBox $w %X %Y 1 differ"
    bind $ttw.results.t <ButtonRelease-1> \
        "CrossFire::CancelDrag $ttw.results.t"
    bind $ttw.results.t <Button-2> "Editor::ClickTextBox $w %X %Y 2 differ"
    bind $ttw.results.t <Button-3> "Editor::ClickTextBox $w %X %Y 3 differ"
    bind $ttw.results.t <Double-Button-1> \
        "Editor::ClickTextBox $w %X %Y 2 differ"
    bindtags $ttw.results.t "$ttw.results.t all"

    bind $tw <Key-Down>  "Editor::Navigate $w down"
    bind $tw <Key-Up>    "Editor::Navigate $w up"
    bind $tw <Key-Right> "Editor::Navigate $w add"
    bind $tw <Key-Home>  "Editor::Navigate $w home"
    bind $tw <Key-End>   "Editor::Navigate $w end"
    bind $tw <Key-Next>  "Editor::Navigate $w +25"
    bind $tw <Key-Prior> "Editor::Navigate $w -25"

    grid columnconfigure $ttw 0 -weight 1
    grid rowconfigure $ttw 3 -weight 1
    grid $ttw -sticky nsew

    # Command buttons
    frame $tw.buttons -relief raised -borderwidth 1
    button $tw.buttons.close -text $CrossFire::close \
        -command "destroy $tw"
    grid $tw.buttons.close -pady 5
    grid $tw.buttons -sticky nsew

    grid columnconfigure $tw 0 -weight 1
    grid rowconfigure $tw 0 -weight 1

    return
}

# Editor::ChangeDiffType --
#
#  Changes the requested type of diff to either Shared or Unique.
#  If both deck file names exist, DoDeckDiff will be called to
#  update the displayed diff so it matches what the user wants.
#
# Parameters:
#   w          : Editor toplevel.
#   diffType   : Diff type to change to (Shared, Unique).
#
# Returns:
#   Nothing.
#
proc Editor::ChangeDiffType {w diffType} {

    variable storage

    set storage($w,diffType) $diffType
    DoDeckDiffer $w

    return
}

# Editor::SelectDeckFile --
#
#   Sets the file name for the specified deck number.
#
# Parameters:
#   w          : Editor toplevel.
#   i          : Deck number. (1 or 2)
#
# Returns:
#   Nothing.
#
proc Editor::SelectDeckFile {w i} {

    variable storage

    set fileName [tk_getOpenFile -initialdir $storage($w,deckDir) \
                      -title "Select CrossFire Deck" \
                      -defaultextension $CrossFire::extension(deck) \
                      -filetypes $CrossFire::deckFileTypes]

    if {$fileName != ""} {
        set storage($w,deck${i}FileName) $fileName
        $storage($w,diffEntry$i) xview end
        DoDeckDiffer $w
    }

    return
}

# Editor::DoDeckDiffer --
#
#   Calls the appropriate diff routine and displays the result
#   in the text box.
#
# Parameters:
#   w          : Editor toplevel.
#
# Returns:
#   Nothing.
#
proc Editor::DoDeckDiffer {w} {

    variable storage

    # Make sure we have the two file names!
    if {($storage($w,deck1FileName) == "") ||
        ($storage($w,deck2FileName) == "")} {
        return
    }

    foreach widget "differ diffEntry1 diffEntry2" {
        $storage($w,$widget) configure -cursor watch
    }
    update

    # Read the decks in. Check for errors.
    for {set i 1} {$i <= 2} {incr i} {
        set deckFile $storage($w,deck${i}FileName)
        if {[Editor::ReadDeck $storage($w,differ) $deckFile] == 1} {
            set deck$i [Editor::GetDeckInfo $storage($w,differ) deck]
        } else {
            tk_messageBox -title "Error Opening Deck" -icon error -parent $w \
                -message "$deckFile is not a valid deck!"
            return
        }
    }

    set diffResults [$storage($w,diffType)Cards $deck1 $deck2]
    set tbw $storage($w,diffTextBox)
    $tbw delete 1.0 end

    # Display the results of the diff in the text box.
    # Not too fancy yet, but works!
    if {$storage($w,diffType) == "Shared"} {
        set nlFlag 0
        foreach cardID [lsort $diffResults] {
            if {$nlFlag == 1} {
                $tbw insert end "\n"
            }
            set card [CrossFire::GetCard [lindex $cardID 0] [lindex $cardID 1]]
            $tbw insert end [CrossFire::GetCardDesc $card]
            set nlFlag 1
        }
    } else {
        foreach {title number} {{Deck 1} 0 {Deck 2} 1} {
            if {$number == 1} {
                $tbw insert end "\n"
            }
            $tbw insert end $title title
            foreach cardID [lsort [lindex $diffResults $number]] {
                set card [CrossFire::GetCard \
                              [lindex $cardID 0] [lindex $cardID 1]]
                $tbw insert end "\n   [CrossFire::GetCardDesc $card]"
            }
        }
    }

    foreach widget "differ diffEntry1 diffEntry2" {
        $storage($w,$widget) configure -cursor {}
    }

    return
}

# Editor::SetDeckInformation --
#
#   Allows for change of some additional (optional) infomation
#   about the deck.
#
# Parameters:
#   w          : Editor toplevel.
#
# Returns:
#   Nothing.
#
proc Editor::SetDeckInformation {w} {

    variable storage

    set tw $w.deckInfo
    if {[winfo exists $tw]} {
        wm deiconify $tw
        raise $tw
        return
    }

    toplevel $tw
    wm title $tw "Deck Information"
    bind $tw <Key-Escape> "$tw.buttons.close invoke"
    wm protocol $tw WM_DELETE_WINDOW "$tw.buttons.close invoke"

    CrossFire::Transient $tw

    frame $tw.info -relief raised -borderwidth 1

    frame $tw.info.author
    label $tw.info.author.l -text "Name:" -width 6 -anchor e
    entry $tw.info.author.e -textvariable Editor::storage($w,authorName)
    grid $tw.info.author.l $tw.info.author.e -sticky nsew -padx 5 -pady 5
    grid columnconfigure $tw.info.author 1 -weight 1

    frame $tw.info.email
    label $tw.info.email.l -text "Email:" -width 6 -anchor e
    entry $tw.info.email.e -textvariable Editor::storage($w,authorEmail)
    grid $tw.info.email.l $tw.info.email.e -sticky nsew -padx 5 -pady 5
    grid columnconfigure $tw.info.email 1 -weight 1

    frame $tw.info.inv
    checkbutton $tw.info.inv.cb -text "Check Inventory:" \
        -variable Editor::storage($w,checkInv) \
        -onvalue "Yes" -offvalue "No" -command "Editor::OpenInventory $w"
    label $tw.info.inv.l -foreground black -background white -anchor w \
        -width 25 -textvariable Editor::storage($w,inventory)
    button $tw.info.inv.b -text "Select..." \
        -command "Editor::SelectInventory $w"
    grid $tw.info.inv.cb $tw.info.inv.l $tw.info.inv.b \
        -sticky ew -padx 5 -pady 5
    grid columnconfigure $tw.info.inv 1 -weight 1

    frame $tw.info.inInv
    checkbutton $tw.info.inInv.l -text "Deck In Inventory" \
        -onvalue "true" -offvalue "false" \
        -variable Editor::storage($w,inInventory)
    grid $tw.info.inInv.l -sticky w -padx 5 -pady 5
    grid columnconfigure $tw.info.inInv 0 -weight 1

    grid $tw.info.author -sticky nsew
    grid $tw.info.email -sticky nsew
    grid $tw.info.inv -sticky nsew
    grid $tw.info.inInv -sticky nsew
    grid columnconfigure $tw.info 0 -weight 1
    grid rowconfigure $tw.info {0 1 2 3 4} -weight 1

    frame $tw.buttons -relief raised -borderwidth 1
    button $tw.buttons.close -text $CrossFire::close \
        -command "Editor::CloseDeckInformation $w"
    grid $tw.buttons.close -pady 5

    grid $tw.info -sticky nsew
    grid $tw.buttons -sticky nsew
    grid columnconfigure $tw 0 -weight 1
    grid rowconfigure $tw 0 -weight 1

    foreach var {
        authorName authorEmail inInventory checkInv inventory
    } {
        trace variable Editor::storage($w,$var) w \
            "Editor::SetChanged $w true"
    }

    return
}

# Editor::CheckTextChange --
#
#   Checks each key press on the text widget to see if it is
#   one that changes the text.  Just need to add a check for
#   paste somehow...
#
# Parameters:
#   w          : Editor toplevel.
#   char       : From %A binding = ASCII char, {} if special char.
#
# Returns:
#   Nothing.
#
proc Editor::CheckTextChange {w char {sym -}} {

#     if {$::developer} {
#         dputs "Editor::CheckTextChange w=$w char=$char keysym=$sym" force
#     }

    if {$char != ""} {
        SetChanged $w "true"
    }

    return
}

# Editor::CloseDeckInformation --
#
#   Closes the deck information window and removes the trace
#   from the variables.
#
# Parameters:
#   w          : Editor toplevel.
#
# Returns:
#   Nothing.
#
proc Editor::CloseDeckInformation {w} {

    variable storage

    destroy $w.deckInfo
    foreach var {
        authorName authorEmail inInventory checkInv inventory
    } {
        trace vdelete Editor::storage($w,$var) w \
            "Editor::SetChanged $w true"
    }

    return
}

# Editor::GetDeckKey --
#
#   Generates a deck key for a list of cards.
#
# Parameters:
#   fid        : Format ID for compliance testing.
#   deck       : List of cards.
#
# Returns:
#   The deck key.
#
proc Editor::GetDeckKey {fid deck} {

    set setTotal 0
    set numTotal 0
    set typeTotal 0
    set worldTotal 0
    set idList [CrossFire::CardSetIDList "all"]

    foreach data {All Champions Chase} {
        set total(Total,$data) 0
    }

    foreach type $CrossFire::cardTypeIDList {
        if {($type > 0) && ($type < 99)} {
            set total(Type,$type) 0
        }
    }

    set setIDList [CrossFire::CardSetIDList "real"]
    foreach setID $setIDList {
        set total(Set,$setID) 0
    }
    set total(Set,FAN) 0

    foreach world $CrossFire::worldIDList {
        if {[lsearch $CrossFire::fanWorldIDList $world] == -1} {
            set total(World,$world) 0
        }
    }
    set total(World,FAN) 0

    foreach rarity $CrossFire::cardFreqIDList {
        set total(Rarity,$rarity) 0
    }

    # Calculate totals for world, card number, type, set
    foreach card $deck {

        foreach {
            setID num bonus type world isAvatar cardName
            text rarity blueLine attrList usesList weight
        } $card break

        incr setTotal [lsearch $idList $setID]
        incr numTotal $num
        incr typeTotal [lsearch $CrossFire::cardTypeIDList $type]
        incr worldTotal [lsearch $CrossFire::worldIDList $world]

        incr total(Total,All)
        if {[lsearch $CrossFire::championList $type] != -1} {
            incr total(Total,Champions)
        }
        if {$num > $CrossFire::setXRef($setID,setMax)} {
            incr total(Total,Chase)
        }

        # Storage for minimum compliance testing
        incr total(Type,$type)
        if {[lsearch $setIDList $setID] == -1} {
            incr total(Set,FAN)
        } else {
            incr total(Set,$setID)
        }
        if {[lsearch $CrossFire::fanWorldIDList $world] == -1} {
            incr total(World,$world)
        } else {
            incr total(World,FAN)
        }
        incr total(Rarity,$rarity)
    }

    # Once DeckIt allows for exceeding limits, we will need a creative
    # way to check against exceeding maximums esp with allowed cards.
    # Suggestion: gen the totals above better.  ####

    # Test for deck compliance
    set cTotal 1  ;# This is Total ### need to add Levels
    foreach totalKey [array names total "Total,*"] {
        set totalID [lindex [split $totalKey ","] 1]
        if {($total(Total,$totalID) <
             $CrossFire::deckFormat($fid,Total,min,$totalID))} {
            set cTotal 0
        }
    }
    set comply $cTotal

    set cType 1
    foreach typeKey [array names total "Type,*"] {
        set typeID [lindex [split $typeKey ","] 1]
        set type $CrossFire::cardTypeXRef($typeID,name)
        if {($total(Type,$typeID) <
             $CrossFire::deckFormat($fid,Type,min,$type))} {
            set cType 0
        }
    }
    append comply $cType

    set cSet 1
    foreach setKey [array names total "Set,*"] {
        set setID [lindex [split $setKey ","] 1]
        if {($total(Set,$setID) <
             $CrossFire::deckFormat($fid,Set,min,$setID))} {
            set cSet 0
        }
    }
    append comply $cSet

    set cWorld 1
    foreach worldKey [array names total "World,*"] {
        set world [lindex [split $worldKey ","] 1]
        if {($total(World,$world) <
             $CrossFire::deckFormat($fid,World,min,$world))} {
            set cWorld 0
        }
    }
    append comply $cWorld

    set cRarity 1
    foreach rarity $CrossFire::cardFreqIDList {
        if {($total(Rarity,$rarity) <
             $CrossFire::deckFormat($fid,Rarity,min,$rarity))} {
            set cRarity 0
        }
    }
    append comply $cRarity

    return "$worldTotal-$numTotal-$typeTotal-$setTotal-$comply"
}

# Editor::DisplayDeckKey --
#
#   Displays the current deck key
#
# Parameters:
#   w          : Editor toplevel
#
# Returns:
#   Nothing.
#
proc Editor::DisplayDeckKey {w} {

    variable storage

    set key [GetDeckKey $storage($w,size) $storage($w,deck)]

    set tw [toplevel $w.deckKey]
    wm title $tw "Display Deck Key"
    wm protocol $tw WM_DELETE_WINDOW "$tw.buttons.ok invoke"

    frame $tw.top -borderwidth 1 -relief raised
    label $tw.top.l -text "Deck Key: $key"
    bind $tw.top.l <Double-Button-1> \
	"CrossFire::SetClipboard \{$key\}"
    grid $tw.top.l -sticky w -padx 3 -pady 8
    grid $tw.top -sticky nsew

    frame $tw.buttons -borderwidth 1 -relief raised
    button $tw.buttons.ok -text "Thanks!" -width 8 \
        -command "set Editor::storage($w,viewDeckKey) ok"
    grid $tw.buttons.ok -padx 5 -pady 5
    grid $tw.buttons -sticky ew

    grid rowconfigure $tw 0 -weight 1
    grid columnconfigure $tw 0 -weight 1

    grab set $tw
    vwait Editor::storage($w,viewDeckKey)
    grab release $tw
    destroy $tw

    return
}

proc Editor::AddALLCardToDeck {w} {

    variable storage

    foreach setID {
        1st 3rd 4th PR RL DL FR AR PO UD RR BR DR NS DU IQ MI CH CQ
    } {
        CrossFire::ReadCardDataBase $setID
dputs "Read $setID ..." force
        foreach card [lrange $CrossFire::cardDataBase 1 end] {
            if {[lindex $card 6] != "(no card)"} {
                AddCardToDeck $w $card
            }
        }
    }
    DisplayDeck $w

    return
}
