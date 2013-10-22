# Combo.tcl 20040809
#
# This file contains all the procedures for the Combo manager.
#
# Copyright (c) 1999-2004 Dan Curtiss. All rights reserved.
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

namespace eval Combo {

    variable windowTitle "ComboMan"
    variable comboCount 0   ;# Counter for creating new toplevels.

    # Array to hold various info about each combo.  Format: (widget,index).
    # Indicies:
    #   cardSet     : ID of the current card set.
    #   combo       : Cards used in the combo.
    #   comboTitle  : Title of the combo. Optional.
    #   authorName  : Name of the author of combo. Optional.
    #   authorEmail : Email address of the author of the combo. Optional.
    variable storage

}

# Combo::SetChanged --
#
#   Changes the boolean flag for if a combo has changed.
#   Adjusts the title of the combo; adds a '*' indicating
#   that a change has been made.
#
# Parameters:
#   w          : Combo toplevel.
#   bool       : Boolean (true or false). Need to save?
#   args       : Extra things that are appended by a variable trace.
#
# Returns:
#   Nothing.
#
proc Combo::SetChanged {w bool args} {

    variable storage
    variable windowTitle

    set storage($w,change) $bool
    set sfn $storage($w,comboTitle)

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
            ($Config::config(ComboMan,autoSave) == "Yes")} {
            if {$Config::config(ComboMan,autoSaveTime) > 0} {
                set delayTime \
                    [expr $Config::config(ComboMan,autoSaveTime) * 60000]
                set storage($w,autoSaveAfterID) \
                    [after $delayTime "Combo::SaveCombo $w"]
            }
        }
    } else {
        wm title $w $title
    }

    return
}

# Combo::Create --
#
#   Incrementally creates a new ComboMan toplevel.
#
# Parameters:
#   args       : Optional filename to load.
#
# Returns:
#   Nothing.
#
proc Combo::Create {args} {

    variable comboCount
    variable storage
    variable windowTitle

    set w .combo[incr comboCount]
    CrossFire::Register ComboMan $w

    # Set configuration for this combo to the default configuration.
    set storage($w,allSetsList) $Config::config(ComboMan,setIDList)

    set storage($w,cardSet) [lindex $storage($w,allSetsList) 0]
    set storage($w,selCardType) $CrossFire::cardTypeXRef(0,name)
    set storage($w,selCardID) 0
    set storage($w,selectListBox) $w.cardSelect.cardList.lb
    set storage($w,comboListBox) $w.comboDisplay.comboCards.lb
    set storage($w,comboTextBox) $w.comboDisplay.comboText.t
    set storage($w,fileName) ""
    set storage($w,change) "false"
    set storage($w,embedCardView) $Config::config(ComboMan,embedCardView)
    set storage($w,cardFrame) ""

    if {[file isdirectory $Config::config(ComboMan,dir)]} {
        set storage($w,comboDir) $Config::config(ComboMan,dir)
    } else {
        set storage($w,comboDir) \
            [file join $CrossFire::homeDir "Combos"]
    }

    toplevel $w
    wm title $w $windowTitle

    # Trap closing window from window manager methods.
    wm protocol $w WM_DELETE_WINDOW "Combo::ExitCombo $w"

    AddMenuBar $w

    bind $w <Key-comma> "Combo::IncrCardSet $w -1"
    bind $w <Key-period> "Combo::IncrCardSet $w 1"

    # Card Set Selection text box
    set storage($w,cardSetSel) $w.setList
    CrossFire::CreateCardSetSelection $storage($w,cardSetSel) "all" \
        "Combo::SetCardSet $w setList"
    grid $w.setList -sticky nsew -padx 5 -pady 5

    # Card Selection
    set fw $w.cardSelect
    frame $fw

    label $fw.selLabel -text "Card Selection:" -anchor w

    frame $fw.cardList
    listbox $fw.cardList.lb -selectmode single -width 30 -height 20 \
        -exportselection 0 -background white -foreground black \
        -selectbackground blue -selectforeground white -selectborderwidth 0 \
        -yscrollcommand "CrossFire::SetScrollBar $fw.cardList.sb"
    scrollbar $fw.cardList.sb -command "$fw.cardList.lb yview"
    grid $fw.cardList.lb -sticky nsew
    grid columnconfigure $fw.cardList 0 -weight 1
    grid rowconfigure $fw.cardList 0 -weight 1

    CrossFire::DragTarget $fw.cardList.lb RemoveCard "Combo::DragRemoveCard $w"

    bind $fw.cardList.lb <ButtonPress-1> \
        "Combo::ClickListBox $w %X %Y 1 select"
    bind $fw.cardList.lb <ButtonRelease-1> \
        "CrossFire::CancelDrag $fw.cardList.lb"
    bind $fw.cardList.lb <Button-2> "Combo::ClickListBox $w %X %Y 2 select"
    bind $fw.cardList.lb <ButtonPress-3> \
        "Combo::ClickListBox $w %X %Y 3 select"
    bind $fw.cardList.lb <Double-Button-1> "Combo::AddCard $w"
    bindtags $fw.cardList.lb "$fw.cardList.lb all"

    frame $fw.search
    label $fw.search.label -text "Search: " -bd 0
    entry $fw.search.entry -background white -foreground black
    pack $fw.search.entry -side right -expand 1 -fill x
    pack $fw.search.label -side left
    bind $fw.search.entry <Key-Return> "Combo::AddCard $w"
    bind $fw.search.entry <$CrossFire::accelBind-v> \
        "Combo::ViewCard $w; break"
    CrossFire::InitSearch $w $fw.search.entry $fw.cardList.lb Combo

    grid $fw.selLabel -sticky w    -padx 5
    grid $fw.cardList -sticky nsew -padx 5
    grid $fw.search   -sticky ew   -padx 5
    grid rowconfigure $fw 1 -weight 1
    grid columnconfigure $fw 0 -weight 1

    grid $fw -column 1 -row 0 -sticky nsew -pady 5

    # Buttons
    frame $w.buttons
    button $w.buttons.add -text "Add" -underline 0 -width 6 \
        -command "Combo::AddCard $w"
    button $w.buttons.view -text "View" -underline 0 -width 6 \
        -command "Combo::ViewCard $w"
    button $w.buttons.remove -text "Remove" -underline 0 -width 6 \
        -command "Combo::RemoveCard $w"
    pack $w.buttons.add $w.buttons.view $w.buttons.remove -pady 10

    grid $w.buttons -column 2 -row 0

    # The cards in the Combo
    set fw $w.comboDisplay
    frame $fw

    label $fw.cardLabel -text "Cards:" -anchor w

    frame $fw.comboCards
    listbox $fw.comboCards.lb -selectmode single -width 30 -height 5\
        -exportselection 0 -background white -foreground black \
        -selectbackground blue -selectforeground white -selectborderwidth 0 \
        -yscrollcommand "CrossFire::SetScrollBar $fw.comboCards.sb"
    scrollbar $fw.comboCards.sb -command "$fw.comboCards.lb yview"
    grid $fw.comboCards.lb -sticky nsew
    grid columnconfigure $fw.comboCards 0 -weight 1
    grid rowconfigure $fw.comboCards 0 -weight 1

    CrossFire::DragTarget $fw.comboCards.lb AddCard "Combo::DragAddCard $w"

    bind $fw.comboCards.lb <ButtonPress-1> \
        "Combo::ClickListBox $w %X %Y 1 combo"
    bind $fw.comboCards.lb <ButtonRelease-1> \
        "CrossFire::CancelDrag $fw.comboCards.lb"
    bind $fw.comboCards.lb <Button-2> "Combo::ClickListBox $w %X %Y 2 combo"
    bind $fw.comboCards.lb <ButtonPress-3> \
        "Combo::ClickListBox $w %X %Y 3 combo"
    bind $fw.comboCards.lb <Double-Button-1> "Combo::ViewCard $w"
    bindtags $fw.comboCards.lb "$fw.comboCards.lb all"

    # Text area to describe how the combo works.
    label $fw.comboRules -text "Instructions:" -anchor w

    frame $fw.comboText
    text $fw.comboText.t -exportselection 0 -width 10 -height 10 -spacing1 2 \
        -wrap word -background white -foreground black \
        -yscrollcommand "CrossFire::SetScrollBar $fw.comboText.sb"
    scrollbar $fw.comboText.sb -command "$fw.comboText.t yview"
    bind $fw.comboText.t <$CrossFire::accelBind-v> "Combo::ViewCard $w; break"
    bind $fw.comboText.t <KeyPress> "Combo::CheckTextChange $w %A"
    bindtags $fw.comboText.t "$fw.comboText.t Text all"

    grid $fw.comboText.t -sticky nsew
    grid columnconfigure $fw.comboText 0 -weight 1
    grid rowconfigure $fw.comboText 0 -weight 1

    # Optional embedded card viewer
    if {$storage($w,embedCardView) == "Yes"} {
	frame $w.cardView
	set storage($w,cardFrame) [ViewCard::CreateCardView $w.cardView.cv]
	grid $w.cardView.cv -sticky nsew -padx 5 -pady 5
	grid rowconfigure $w.cardView 0 -weight 1
	grid columnconfigure $w.cardView 0 -weight 1
	grid $w.cardView -column 4 -row 0 -sticky nsew -rowspan 2
	grid columnconfigure $w 4 -weight 2
    }

    grid $fw.cardLabel  -sticky w    -padx 5
    grid $fw.comboCards -sticky nsew -padx 5
    grid $fw.comboRules -sticky w    -padx 5
    grid $fw.comboText  -sticky nsew -padx 5

    grid rowconfigure $fw {1 3} -weight 1
    grid columnconfigure $fw 0 -weight 1

    grid $fw -column 3 -row 0 -sticky nsew -pady 5

    grid rowconfigure $w 0 -weight 1
    grid columnconfigure $w 0 -weight 1
    grid columnconfigure $w {1 3} -weight 3

    # Some bindings for keyboard navigation of the combo.
    bind $w <Key-Home>  "Combo::Navigate $w home"
    bind $w <Key-End>   "Combo::Navigate $w end"
    bind $w <Key-Down>  "Combo::Navigate $w down"
    bind $w <Key-Up>    "Combo::Navigate $w up"
    bind $w <Key-Next>  "Combo::Navigate $w +25"
    bind $w <Key-Prior> "Combo::Navigate $w -25"
    bind $w <Key-Right> "Combo::Navigate $w add"
    bind $w <Key-Left>  "Combo::Navigate $w remove"

    UpdateCardSelection $w
    New $w
    SetChanged $w "false"
    Config::RecentFile "ComboMan" {}

    if {$args != ""} {
        if {[OpenCombo $w [lindex $args 0] "nocomplain"] == 0} {
            ExitCombo $w
            return
        }
    }

    wm deiconify $w
    raise $w

    if {$CrossFire::platform == "windows"} {
        focus $w
    }

    return
}

# Combo::AddMenuBar --
#
#   Creates the menubar for the combo and sets up the
#   accelerator key bindings for the commands.
#
# Parameters:
#   w          : Toplevel of the new combo window.
#
# Returns:
#   Nothing.
#
proc Combo::AddMenuBar {w} {

    variable storage

    menu $w.menubar

    $w.menubar add cascade \
        -label "Combo" \
        -underline 0 \
        -menu $w.menubar.combo

    menu $w.menubar.combo -tearoff 0
    $w.menubar.combo add command \
        -label "New" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+N" \
        -command "Combo::NewCombo $w"
    $w.menubar.combo add command \
        -label "Open..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+O" \
        -command "Combo::OpenCombo $w {}"
    $w.menubar.combo add command \
        -label "Save" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+S" \
        -command "Combo::SaveCombo $w"
    $w.menubar.combo add command \
        -label "Save As..." \
        -underline 5 \
        -command "Combo::SaveComboAs $w"

    $w.menubar.combo add separator
    $w.menubar.combo add command \
        -label "Information..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+I" \
        -command "Combo::SetComboInformation $w"

    $w.menubar.combo add separator
    $w.menubar.combo add command \
        -label "Print..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+P" \
        -command "Combo::PrintCombo $w"
    $w.menubar.combo add separator

    set exitLabel "Close"
    set exitAccelerator "Alt+F4"
    if {$CrossFire::platform == "macintosh"} {
        # This is a Macintosh, so make the exit
        # accelerator more "Mac-ish"
        set exitLabel "Quit"
        set exitAccelerator "Command+Q"
    }
    $w.menubar.combo add command \
        -label $exitLabel \
        -underline 1 \
        -accelerator $exitAccelerator \
        -command "Combo::ExitCombo $w"

    $w.menubar add cascade \
        -label "Card" \
        -underline 0 \
        -menu $w.menubar.card
    menu $w.menubar.card -tearoff 0

    $w.menubar.card add cascade \
        -label "Type" \
        -menu $w.menubar.card.type

    menu $w.menubar.card.type -title "Card Type"
    foreach cardTypeID $CrossFire::cardTypeIDList {
        if {$cardTypeID <= 100} {
            $w.menubar.card.type add radiobutton \
                -label $CrossFire::cardTypeXRef($cardTypeID,name) \
                -variable Combo::storage($w,selCardType) \
                -command "Combo::ChangeCardType $w $cardTypeID"
        }
    }

    $w.menubar.card add separator
    $w.menubar.card add command \
        -label "View" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+V" \
        -command "Combo::ViewCard $w"
    $w.menubar.card add separator
    $w.menubar.card add command \
        -label "Add" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+A" \
        -command "Combo::AddCard $w"
    $w.menubar.card add command \
        -label "Remove" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+V" \
        -command "Combo::RemoveCard $w"

    $w.menubar add cascade \
        -label "Utilities" \
        -underline 0 \
        -menu $w.menubar.window

    menu $w.menubar.window -tearoff 0
    $w.menubar.window add command \
        -label "Viewer..." \
        -underline 0 \
        -command "Combo::Viewer"
    $w.menubar.window add separator
    $w.menubar.window add command \
        -label "Configure..." \
        -underline 0 \
        -command "Config::Create ComboMan"

    $w.menubar add cascade \
        -label "Help" \
        -underline 0 \
        -menu $w.menubar.help

    menu $w.menubar.help -tearoff 0
    $w.menubar.help add command \
        -label "Help..." \
        -underline 0 \
        -accelerator "F1" \
        -command "CrossFire::Help cm_main.html"
    $w.menubar.help add separator
    $w.menubar.help add command \
        -label "About ComboMan..." \
        -underline 0 \
        -command "Combo::About $w"

    $w config -menu $w.menubar

    # Combo menu bindings.
    bind $w <$CrossFire::accelBind-n> "Combo::NewCombo $w"
    bind $w <$CrossFire::accelBind-o> "Combo::OpenCombo $w {}"
    bind $w <$CrossFire::accelBind-s> "Combo::SaveCombo $w"
    bind $w <$CrossFire::accelBind-i> "Combo::SetComboInformation $w"
    bind $w <$CrossFire::accelBind-p> "Combo::PrintCombo $w"

    if {$CrossFire::platform == "macintosh"} {
        bind $w <Command-q> "Combo::ExitCombo $w"
    } else {
        bind $w <Meta-x> "Combo::ExitCombo $w"
        bind $w <Alt-F4> "Combo::ExitCombo $w; break"
    }

    # Card menu bindings.
    bind $w <$CrossFire::accelBind-a> "Combo::AddCard $w"
    bind $w <$CrossFire::accelBind-v> "Combo::ViewCard $w"
    bind $w <$CrossFire::accelBind-r> "Combo::RemoveCard $w"

    # Help menu bindings.
    bind $w <Key-F1> "CrossFire::Help cm_main.html"
    bind $w <Key-Help> "CrossFire::Help cm_main.html"

    # menu for right click on card list
    menu $w.addMenu -tearoff 0
    $w.addMenu add command -label " Add" \
        -command "Combo::AddCard $w"
    $w.addMenu add separator
    $w.addMenu add command -label " View" \
        -command "Combo::ViewCard $w"

    # menu for right click on combo card name
    menu $w.removeMenu -tearoff 0
    $w.removeMenu add command -label " Remove" \
        -command "Combo::RemoveCard $w"
    $w.removeMenu add separator
    $w.removeMenu add command -label " View" \
        -command "Combo::ViewCard $w"

    return
}

# Combo::SetCardSet --
#
#   Changes the selected set of cards.
#
# Parameter:
#    w        : Combo toplevel.
#
# Returns:
#    Nothing.
#
proc Combo::SetCardSet {w from args} {

    variable storage

    if {$from == "menu"} {
        CrossFire::ClickCardSetSelection $storage($w,cardSetSel) \
            "m" $storage($w,cardSet)
    } elseif {$from == "setList"} {
        # Clicked on the set list
        set storage($w,cardSet) $args
    }

    UpdateCardSelection $w

    return
}

# Combo::CheckTextChange --
#
#   Checks each key press on the text widget to see if it is
#   one that changes the text.  Just need to add a check for
#   paste somehow...
#
# Parameters:
#   char       : From %A binding = ASCII char, {} if special char.
#
# Returns:
#   Nothing.
#
proc Combo::CheckTextChange {w char} {

    if {$char != ""} {
        SetChanged $w "true"
    }

    return
}

# Combo::ExitCombo --
#
#   Gracefully closes the specified combo.  Checks if combo
#   needs to be saved before closing.
#
# Parameters:
#   w          : Widget name of the combo.
#
# Returns:
#   Returns 0 if exiting or -1 if exit canceled.
#
proc Combo::ExitCombo {w} {

    variable storage

    if {[CheckForSave $w] == 0} {
        destroy $w

        UnLockFile $w

        if {[info exists storage($w,autoSaveAfterID)]} {
            after cancel $storage($w,autoSaveAfterID)
        }

        # Unset all the variables for the combo.
        foreach name [array names storage "${w},*"] {
            unset storage($name)
        }

        ViewCard::CleanUpCardViews $w
        CrossFire::UnRegister ComboMan $w

        return 0
    } else {
        return -1
    }
}

# Combo::NewCombo --
#
#   Clears the current combo.  Checks if saved needed.
#
# Parameters:
#   w          : Combo toplevel path name.
#
# Returns:
#   Nothing.
#
proc Combo::NewCombo {w} {

    variable storage

    if {[CheckForSave $w] == -1} {
        return
    }

    New $w
    SetChanged $w "false"

    return
}

# Combo::New --
#
#   Procedure that actually clears the combo.  This was split from NewCombo
#   to account for CheckForSave being called twice when it should not be.
#   The changed status is *not* changed by this proc.
#
# Parameters:
#   w          : Combo toplevel.
#
# Returns:
#   Nothing.
#
proc Combo::New {w} {

    variable storage

    UnLockFile $w

    set storage($w,combo) {}
    set storage($w,fileName) {}
    set storage($w,authorName) $Config::config(CrossFire,authorName)
    set storage($w,authorEmail) $Config::config(CrossFire,authorEmail)
    set storage($w,comboTitle) ""
    $storage($w,comboTextBox) delete 1.0 end

    DisplayCombo $w
######
    SetCardSet $w "menu"

    return
}

# Combo::UpdateCardSelection --
#
#   Changes the card set, updates selection list box.
#
# Parameters:
#   w          : Combo toplevel name.
#
# Returns:
#   Nothing.
#
proc Combo::UpdateCardSelection {w} {

    variable storage

    $w config -cursor watch
    update

    set newSetName $storage($w,cardSet)

    if {$newSetName == "All"} {
        set listOfIDs $storage($w,allSetsList)
    } else {
        set listOfIDs $newSetName
    }

    $storage($w,selectListBox) delete 0 end
    foreach setID $listOfIDs {
        CrossFire::ReadCardDataBase $setID
        CrossFire::CardSetToListBox $CrossFire::cardDataBase \
            $storage($w,selectListBox) \
            $storage($w,selCardID) "append"
    }

    ClickListBox $w m 0 0 select

    $w config -cursor {}
    return
}

# Combo::ChangeCardType --
#
#   Changes the card type to view in the selection box.
#
# Parameters:
#   w          : Combo toplevel widget name.
#   typeID     : Numeric ID of the card type.
#
# Returns:
#   Nothing.
#
proc Combo::ChangeCardType {w typeID} {
    variable storage

    set storage($w,selCardID) $typeID
    UpdateCardSelection $w

    return
}

# Combo::GetSelectedCardID --
#
#   Returns the short ID of the selected card, if any.
#
# Parameters:
#   w          : Combo toplevel widget name.
#
# Returns:
#   The short ID if a card is selected, nothing otherwise.
#
proc Combo::GetSelectedCardID {w} {

    variable storage

    # Get and return the current selection's card ID.
    set which $storage($w,selectionAt)

    # Card selection list box.
    set lbw $storage($w,${which}ListBox)
    if {[$lbw curselection] != ""} {
        set selectedCard [lindex [$lbw get [$lbw curselection]] 0]
    } else {
        set selectedCard ""
    }

    return $selectedCard
}

# Combo::DisplayCombo --
#
#   Displays the cards in the combo.
#
# Parameters:
#   w          : Combo toplevel widget name.
#
# Returns:
#   Nothing.
#
proc Combo::DisplayCombo {w args} {

    variable storage

    $w configure -cursor watch
    update

    set lbw $storage($w,comboListBox)
    $lbw delete 0 end

    foreach card [lsort $storage($w,combo)] {
        $lbw insert end [CrossFire::GetCardDesc $card]
    }

    $w configure -cursor {}

    return
}

# Combo::GetComboText --
#
#   Returns the text in the text box without the annoying trailing
#   carriage return.  :)
#
# Parameters:
#   w          : Toplevel.
#
# Returns:
#   The text.
#
proc Combo::GetComboText {w} {

    variable storage

    set comboText [$storage($w,comboTextBox) get 1.0 end]
    set comboText [string trim $comboText "\n"]

    return $comboText
}

# Combo::AddCardToCombo --
#
#   Adds a card to a combo.  First checks if all the requirements
#   and restrictions are met before adding the card.  Used by
#   OpenCombo and AddCard.
#
# Parameters:
#   w          : Combo toplevel path name.
#   card       : The card to add in standard card format.
#
# Returns:
#   1 if added, or 0 if not.
#
proc Combo::AddCardToCombo {w card} {

    variable storage

    set okToAdd 1
    set cardName [lindex $card 6]

    # Check for cards that do not exist.
    if {$cardName == "(no card)"} {
        set okToAdd 0
        set msg "This card does not exist."
    }

    # Check for Disintigrate & Psionic Disintigration.
    # They are not allowed to be in a combo together!
    if {($okToAdd == 1) && ([regexp "Disintegrat" $cardName] == 1)} {
        foreach testCard $storage($w,combo) {
            set testCardName [lindex $testCard 6]
            if {([regexp "Disintegrat" $testCardName] == 1) &&
                ($testCard != $testCardName)} {
                set okToAdd 0
                set msg "Disintigrate & Psionic Disintigration "
                append msg "cannot be in a combo together."
                break
            }
        }
    }

    if {$okToAdd == 1} {
        lappend storage($w,combo) $card
    } elseif {$okToAdd == 0} {
        # We had an error!  Report it to the user.
        tk_messageBox -message $msg -icon error \
            -title "Error Adding Card" -parent $w
    }

    return $okToAdd
}

# Combo::AddCard --
#
#   Attempts to add the selected card on the specified combo
#   toplevel to the combo.  Alerts user if no card is selected.
#   Actual adding of card is handled by AddCardToCombo.
#
# Parameters:
#   w          : Combo toplevel path name.
#
# Returns:
#   Nothing.
#
proc Combo::AddCard {w} {

    variable storage

    set cardID ""
    if {$storage($w,selectionAt) != "textbox"} {
        set cardID [GetSelectedCardID $w]
    }

    if {$cardID == ""} {
        tk_messageBox -message "No Card Selected." -icon error \
            -parent $w -title "Error Adding Card"
        return
    }

    set card [CrossFire::GetCard $cardID]

    # Only redisplay combo if we successfully add the card.
    if {[AddCardToCombo $w $card] == 1} {
        DisplayCombo $w
        SetChanged $w "true"
    }

    return
}

# Combo::DragAddCard --
#
#   Called when a dropped card is about to be added. This is used 
#   because the drag-n-drop routines send the 'from' widget, which
#   is not needed for adding, because we get the card ID in args.
#
# Parameters:
#   w          : Widget receiving the drop.
#   from       : Widget sending the data.
#   args       : Data.
#
# Returns:
#   Nothing.
#
proc Combo::DragAddCard {w from args} {

    variable storage

    # If we are receiving a card type group, we will add all
    # of those from one combo to another, otherwise just 
    # add the single card.
    set first [lindex $args 0]

    if {$first == ""} {
        return
    }

    AddCardToCombo $w [CrossFire::GetCard $first]
    SetChanged $w "true"
    DisplayCombo $w

    return
}

# Combo::RemoveCardFromCombo --
#
#   Procedure that actually removes a card from the combo.
#
# Parameters:
#   w          : Combo toplevel path name.
#
# Returns:
#   Nothing.
#
proc Combo::RemoveCardFromCombo {w card} {

    variable storage

    set pos [lsearch $storage($w,combo) $card]

    if {$pos != -1} {
        set storage($w,combo) \
            [lreplace $storage($w,combo) $pos $pos]
    }

    return
}

# Combo::RemoveCard --
#
#   Removes the highlighted card from the combo.
#
# Parameters:
#   w          : Combo toplevel path name.
#   args       : Optional card ID to remove.
#
# Returns:
#   Nothing.
#
proc Combo::RemoveCard {w args} {

    variable storage

    if {$args != ""} {
        set card [CrossFire::GetCard $args]
    } else {

        set card ""

        # We want a warning if the selection is on the card selection box,
        # so don't get a card if it is.
        if {[$storage($w,selectListBox) curselection] == ""} {
            set cardID [GetSelectedCardID $w]
            set card [CrossFire::GetCard $cardID]
        }
    }

    if {$card == ""} {
        tk_messageBox -message "No card selected." -icon error \
            -title "Error Removing Card" -parent $w
        return
    } else {
        RemoveCardFromCombo $w $card
        SetChanged $w "true"
        DisplayCombo $w
    }

    return
}

# Combo::DragRemoveCard --
#
#   Called when a dropped card is to be removed.  We must check the
#   'from' widget's toplevel against the the receiving, because we
#   do not want to allows removes from different combos.
#
# Parameters:
#   w          : Widget receiving the drop.
#   from       : Widget sending the data.
#   args       : Data.
#
# Returns:
#   Nothing.
#
proc Combo::DragRemoveCard {w from args} {

    # Get the toplevel name of the sender.
    set fw [winfo toplevel $from]

    if {$fw == $w} {
        eval RemoveCard $w $args
    }

    return
}

# Combo::ClickListBox --
#
#   Handles all clicking of the card selection list box.
#
# Parameters:
#   w          : Combo toplevel widget name.
#   X Y        : X and Y coordinates of the click (%X %Y)
#              : -or- m line for move to line.
#   btnNumber  : Button number pressed or 0 when called from
#                SearchListBox.
#   which      : Which listbox. (select or combo)
#
# Returns:
#   Nothing.
#
proc Combo::ClickListBox {w X Y btnNumber {which select}} {

    variable storage

    set lbw $storage($w,${which}ListBox)
    set storage($w,selectionAt) $which

    if {$which == "select"} {
        $storage($w,comboListBox) selection clear 0 end
    } else {
        $storage($w,selectListBox) selection clear 0 end
    }

    CrossFire::ClickListBox $w $lbw $X $Y

    set tempID [GetSelectedCardID $w]
    if {$tempID != ""} {
	if {$storage($w,embedCardView) == "Yes"} {
	    ViewCard::UpdateCardView $storage($w,cardFrame) \
		[CrossFire::GetCard $tempID]
	} elseif {$Config::config(ViewCard,mode) == "Continuous"} {
	    ViewCard::View $w $tempID
	}
    }

    # Do various activities depending which button was pressed.
    switch -- $btnNumber {
        1 {
            # Start the drag-n-drop routines.
            if {$which == "select"} {
                CrossFire::StartDrag $lbw plus AddCard $tempID
            } else {
                CrossFire::StartDrag $lbw target RemoveCard $tempID
            }
        }

        2 {
            if {$which == "select"} {
                AddCard $w
            } else {
                ViewCard $w
            }
        }

        3 {
            # Pop-up Menu
            if {$which == "select"} {
                tk_popup $w.addMenu $X $Y
            } else {
                tk_popup $w.removeMenu $X $Y
            }
        }
    }

    return
}

# Combo::Navigate --
#
#   Implements keyboard navigation of the combo.
#
# Parameters:
#   w          : Combo toplevel.
#   pos        : Position to move to (home, end, up, down, +/-x)
#
# Returns:
#   Nothing.
#
proc Combo::Navigate {w pos} {

    variable storage

    switch -- $pos {
        "home" {
            set pos 0
        }
        "up"   {
            set pos "-1"
        }
        "down" {
            set pos "+1"
        }
    }

    set selectionAt $storage($w,selectionAt)

    # Only allow add from the card selection box
    if {$pos == "add"} {
        if {$selectionAt == "select" } {
            AddCard $w
        }
        return
    }

    # Only allow remove from the combo cards list box
    if {$pos == "remove"} {
        if {$selectionAt == "combo" } {
            RemoveCard $w
        }
        return
    }

    ClickListBox $w m $pos 0 $selectionAt

    return
}

# Combo::IncrCardSet --
#
#   Changes the selected card set.
#
# Parameters:
#   w          : Combo toplevel.
#   delta      : Amount to change set by.
#
# Returns:
#   Nothing.
#
proc Combo::IncrCardSet {w delta} {

    variable storage

    set last [expr [llength $storage($w,allSetsList)] -1]
    set index [lsearch $storage($w,allSetsList) $storage($w,cardSet)]

    incr index $delta

    if {$index < 0} {
        set index 0
    }
    if {$index > $last} {
        set index $last
    }

    set newSet [lindex $storage($w,allSetsList) $index]

    if {$newSet != $storage($w,cardSet)} {
        set storage($w,cardSet) $newSet
        UpdateCardSelection $w
    }

    return
}

# Combo::ViewCard --
#
#   Views the currently selected card.
#
# Parameters:
#   w          : Combo toplevel.
#
# Returns:
#   Nothing.
#
proc Combo::ViewCard {w} {

    ViewCard::View $w [Combo::GetSelectedCardID $w]

    return
}

# Combo::About --
#
#   Displays an about dialog for Comboman
#
# Paramters:
#   w         : Parent toplevel for the pop-up dialog.
#
# Returns:
#   Nothing.
#
proc Combo::About {w} {
    set message "CrossFire ComboMan\n"
    append message "\nby Dan Curtiss"
    tk_messageBox -icon info -title "About CrossFire ComboMan" \
        -parent $w -message $message
    return
}

