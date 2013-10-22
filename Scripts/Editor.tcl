# Editor.tcl 20051114
#
# This file contains the main procedures for the DeckIt! editor.
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

namespace eval Editor {

    variable windowTitle "DeckIt!"
    variable editorCount 0   ;# Counter for creating new toplevels.

    # Array to hold various info about each editor.  Format: (widget,index)
    # Indicies:
    #   size        : Maximum number of cards (55, 75, etc)
    #   newSize     : Maximum we want to change to.
    #   change      : Boolean. If deck has changes.
    #   cardSet     : ID of the current card set.
    #   selCardType : Name of the current card type to view.
    #   cardListBox : Widget path of the card selection list box.
    #   deckTextBox : Widget path of the deck text box.
    #   altTextBox  : Widget path of the possible cards text box.
    #   deck        : The deck.
    #   altCards    : List of possible cards.
    #   fileName    : File name for the deck.
    #   levelList   : List of champion levels.
    #   avatarList  : List of avatar levels.
    #   inInventory : Boolean. Is deck still in inventory?
    #   allSetsList : List of cards for "all card sets".
    #   diff*FileName : Used by deck differ. Two filenames to compare.
    #   diffEntry*  : Entry widget for each filename.
    #   diffTextBox : Widget path of the deck differ's text box.
    #   deckTitle   : Title of the deck. Optional.
    #   authorName  : Name of the author of deck. Optional.
    #   authorEmail : Email address of the author of the deck. Optional.
    variable storage

    set storage(groupList) {
        Totals           0 T
        {Card Type}      0 C
        Set              1 E
        World            0 W
        Rarity           0 R
	Digit            0 D
        {Support Card Usablity} 13 U
        {Banned Cards}   0 B
        {Allowed Cards}  0 A
    }
}

# Editor::SetChanged --
#
#   Changes the boolean flag for if a deck has changed.
#   Adjusts the title of the editor; adds a '*' indicating
#   that a change has been made.
#
# Parameters:
#   w          : Editor toplevel.
#   bool       : Boolean (true or false). Need to save?
#   args       : Extra things that are appended by a variable trace.
#
# Returns:
#   Nothing.
#
proc Editor::SetChanged {w bool args} {

    variable storage
    variable windowTitle

    set storage($w,change) $bool
    set sfn $storage($w,deckTitle)

    if {$sfn != ""} {
        set sfn "- $sfn "
    }

    if {[info exists storage($w,autoSaveAfterID)]} {
        after cancel $storage($w,autoSaveAfterID)
        unset storage($w,autoSaveAfterID)
    }

    set formatName $CrossFire::deckFormat($storage($w,size),name)
    set title "$windowTitle - $formatName $sfn"
    if {$bool == "true"} {
        wm title $w "${title}*"
        if {($storage($w,fileName) != "") &&
            ($Config::config(DeckIt,autoSave) == "Yes")} {
            if {$Config::config(DeckIt,autoSaveTime) > 0} {
                set delayTime \
                    [expr $Config::config(DeckIt,autoSaveTime) * 60000]
                set storage($w,autoSaveAfterID) \
                    [after $delayTime "Editor::SaveDeck $w"]
            }
        }
    } else {
        wm title $w $title
    }

    return
}

# Editor::Create --
#
#   Incrementally creates a new DeckIt! toplevel.
#
# Parameters:
#   args       : Optional deck file to load.
#
# Returns:
#   The path name of the toplevel widget.
#
proc Editor::Create {args} {

    variable editorCount
    variable storage
    variable windowTitle

    set w .editor[incr editorCount]
    CrossFire::Register DeckIt $w

    # Set configuration for this deck to the default configuration.
    set storage($w,size) $Config::config(DeckIt,deckSize)
    set storage($w,newSize) $Config::config(DeckIt,deckSize)
    set storage($w,allSetsList) $Config::config(DeckIt,setIDList)
    set storage($w,championMode) $Config::config(DeckIt,championMode)
    set storage($w,deckDisplayMode) $Config::config(DeckIt,deckDisplayMode)
    set storage($w,cardSet) $Config::config(DeckIt,startSetID)
    set storage($w,selCardType) $CrossFire::cardTypeXRef(0,name)
    set storage($w,selCardID) 0
    set storage($w,resultsListBox) ""
    set storage($w,diffTextBox) ""
    set storage($w,fileName) ""
    set storage($w,change) "false"
    set storage($w,inInventory) "true"
    set storage($w,deck1FileName) ""
    set storage($w,deck2FileName) ""
    set storage($w,embedCardView) $Config::config(DeckIt,embedCardView)
    set storage($w,cardFrame) ""

    if {[file isdirectory $Config::config(DeckIt,dir)]} {
        set storage($w,deckDir) $Config::config(DeckIt,dir)
    } else {
        set storage($w,deckDir) [file join $CrossFire::homeDir "Decks"]
    }

    toplevel $w
    wm title $w $windowTitle
    if {$Config::config(DeckIt,geometry) != ""} {
        wm geometry $w $Config::config(DeckIt,geometry)
    }

    # Trap closing window from window manager methods.
    wm protocol $w WM_DELETE_WINDOW "Editor::ExitEditor $w"

    AddMenuBar $w

    bind $w <Key-comma> "Editor::IncrCardSet $w -1"
    bind $w <Key-period> "Editor::IncrCardSet $w 1"

    # Card Set Selection text box
    set storage($w,cardSetSel) $w.setList
    CrossFire::CreateCardSetSelection $storage($w,cardSetSel) "all" \
        "Editor::SetCardSet $w setList"

    # Deck title
    frame $w.title
    frame $w.title.f
    label $w.title.f.l -text "Title:"
    entry $w.title.f.e -textvariable Editor::storage($w,deckTitle)
    bindtags $w.title.f.e "Entry"
    grid $w.title.f.l $w.title.f.e -sticky nsew
    grid columnconfigure $w.title.f 1 -weight 1
    grid $w.title.f -sticky nsew -padx 5 -pady 3
    grid columnconfigure $w.title 0 -weight 1
    grid rowconfigure $w.title 0 -weight 1

    PanedWindow::Create $w.listDisplay -height 4i \
        -sash $Config::config(DeckIt,selectSash)

    # Deck notes
    frame $w.listDisplay.pane1.notes

    frame $w.listDisplay.pane1.notes.f
    label $w.listDisplay.pane1.notes.f.l -text "Notes:"
    frame $w.listDisplay.pane1.notes.f.f
    set textw $w.listDisplay.pane1.notes.f.f.t
    set storage($w,deckInfoNotesW) $textw
    text $textw -height 4 -width 30 -wrap word -background white \
        -foreground black -yscrollcommand \
        "CrossFire::SetScrollBar $w.listDisplay.pane1.notes.f.f.sb"
    scrollbar $w.listDisplay.pane1.notes.f.f.sb -command "$textw yview"
    bind $textw <KeyPress> "Editor::CheckTextChange $w %A"
    #bind $textw <KeyPress> "Editor::CheckTextChange $w %A %K"
    bindtags $textw "$textw Text all"
    grid $textw -sticky nsew
    grid rowconfigure $w.listDisplay.pane1.notes.f.f 0 -weight 1
    grid columnconfigure $w.listDisplay.pane1.notes.f.f 0 -weight 1
    grid $w.listDisplay.pane1.notes.f.l -sticky nw
    grid $w.listDisplay.pane1.notes.f.f -sticky nsew -pady 3
    grid columnconfigure $w.listDisplay.pane1.notes.f 0 -weight 1
    grid rowconfigure $w.listDisplay.pane1.notes.f 1 -weight 1
    grid $w.listDisplay.pane1.notes.f -sticky nsew

    grid columnconfigure $w.listDisplay.pane1.notes 0 -weight 1
    grid rowconfigure $w.listDisplay.pane1.notes 0 -weight 1
    grid $w.listDisplay.pane1.notes -padx 5 -sticky nsew -pady 5

    grid columnconfigure $w.listDisplay.pane1 0 -weight 1
    grid rowconfigure $w.listDisplay.pane1 0 -weight 1

    # Card Selection
    frame $w.listDisplay.pane2.cardSelect
    frame $w.listDisplay.pane2.cardSelect.f

    label $w.listDisplay.pane2.cardSelect.f.l -text "Card Selection:" -anchor w
    grid $w.listDisplay.pane2.cardSelect.f.l -sticky w

    frame $w.listDisplay.pane2.cardSelect.f.list
    set lbw \
        [listbox $w.listDisplay.pane2.cardSelect.f.list.lb -selectmode single \
	     -width 30 -height 15 -exportselection 0 -background white \
             -foreground black -selectbackground blue -takefocus 1 \
             -selectforeground white -selectborderwidth 0 -yscrollcommand \
             "CrossFire::SetScrollBar $w.listDisplay.pane2.cardSelect.f.list.sb"]
    set storage($w,cardListBox) $lbw
    scrollbar $w.listDisplay.pane2.cardSelect.f.list.sb -takefocus 0 \
        -command "$lbw yview"
    grid $lbw -sticky nsew

    CrossFire::DragTarget $lbw RemoveCard "Editor::DragRemoveCard $w"

    bind $lbw <ButtonPress-1>   "Editor::ClickListBox $w %X %Y 1"
    bind $lbw <ButtonRelease-1> "CrossFire::CancelDrag $lbw"
    bind $lbw <Button-2>        "Editor::ClickListBox $w %X %Y 2"
    bind $lbw <ButtonPress-3>   "Editor::ClickListBox $w %X %Y 3"
    bind $lbw <Double-Button-1> "Editor::AddCard $w"
    bindtags $lbw "$lbw all"

    grid $w.listDisplay.pane2.cardSelect.f.list -sticky nsew -pady 3
    grid columnconfigure $w.listDisplay.pane2.cardSelect.f.list 0 -weight 1
    grid rowconfigure $w.listDisplay.pane2.cardSelect.f.list 0 -weight 1

    frame $w.listDisplay.pane2.cardSelect.f.search
    label $w.listDisplay.pane2.cardSelect.f.search.label -text "Search: " -bd 0
    entry $w.listDisplay.pane2.cardSelect.f.search.entry \
	-background white -foreground black -takefocus 0
    pack $w.listDisplay.pane2.cardSelect.f.search.entry -side right \
        -expand 1 -fill x
    pack $w.listDisplay.pane2.cardSelect.f.search.label -side left
    bind $w.listDisplay.pane2.cardSelect.f.search.entry <Key-Return> \
	"Editor::AddCard $w"
    bind $w.listDisplay.pane2.cardSelect.f.search.entry \
        <$CrossFire::accelBind-v> "Editor::ViewCard $w; break"
    CrossFire::InitSearch $w $w.listDisplay.pane2.cardSelect.f.search.entry \
	$lbw Editor

    grid $w.listDisplay.pane2.cardSelect.f.search -sticky ew

    grid $w.listDisplay.pane2.cardSelect.f -sticky nsew
    grid columnconfigure $w.listDisplay.pane2.cardSelect.f 0 -weight 1
    grid rowconfigure $w.listDisplay.pane2.cardSelect.f 1 -weight 1

    grid columnconfigure $w.listDisplay.pane2.cardSelect 0 -weight 1
    grid rowconfigure $w.listDisplay.pane2.cardSelect 0 -weight 1
    grid $w.listDisplay.pane2.cardSelect -sticky nsew -padx 5 -pady 5

    grid columnconfigure $w.listDisplay.pane2 0 -weight 1
    grid rowconfigure $w.listDisplay.pane2 0 -weight 1

    grid $w.setList      -sticky nsew -padx 5 -pady 5 -rowspan 3
    grid $w.title       -column 1 -row 0 -sticky ew
    grid $w.listDisplay -column 1 -row 1 -sticky nsew -rowspan 2

    # Buttons
    frame $w.buttons
    button $w.buttons.add -text "Add" -underline 0 -width 8 \
        -command "Editor::AddCard $w"
    button $w.buttons.consider -text "Consider" -width 8 \
	-command "Editor::AddCard $w alt"
    button $w.buttons.view -text "View" -underline 0 -width 8 \
        -command "Editor::ViewCard $w"
    button $w.buttons.remove -text "Remove" -underline 0 -width 8 \
        -command "Editor::RemoveCard $w"
    grid $w.buttons.add      -padx 5 -pady 7
    grid $w.buttons.consider -padx 5 -pady 7
    grid $w.buttons.view     -padx 5 -pady 7
    grid $w.buttons.remove   -padx 5 -pady 7

    grid $w.buttons -column 2 -row 0 -rowspan 3 -sticky nsew

    # The Deck
    PanedWindow::Create $w.deckDisplay \
        -sash $Config::config(DeckIt,deckSash)

    frame $w.deckDisplay.pane1.f

    label $w.deckDisplay.pane1.f.l -text "Deck:" -anchor w
    grid $w.deckDisplay.pane1.f.l -sticky w

    frame $w.deckDisplay.pane1.f.deck
    set tbw \
        [text $w.deckDisplay.pane1.f.deck.t -exportselection 0 -width 30 \
             -height 10 -wrap none -cursor {} -background white \
             -foreground black -takefocus 0 -spacing1 2 -yscrollcommand \
             "CrossFire::SetScrollBar $w.deckDisplay.pane1.f.deck.sb"]
    set storage($w,deckTextBox) $tbw
    $tbw tag configure cardTypeHeader -font {Times 14 bold}
    $tbw tag configure avatar -foreground "#00BB00"
    $tbw tag configure select -foreground white -background blue
    $tbw tag configure violation -foreground red
    scrollbar $w.deckDisplay.pane1.f.deck.sb -command "$tbw yview" -takefocus 0
    grid $tbw -sticky nsew
    grid columnconfigure $w.deckDisplay.pane1.f.deck 0 -weight 1
    grid rowconfigure $w.deckDisplay.pane1.f.deck 0 -weight 1

    CrossFire::DragTarget $tbw AddCard "Editor::DragAddCard $w"
    CrossFire::DragTarget $tbw RemoveCard "Editor::DragAddCard $w"

    bind $tbw <ButtonPress-1> "Editor::ClickTextBox $w %X %Y 1"
    bind $tbw <ButtonRelease-1> "CrossFire::CancelDrag $tbw"
    bind $tbw <Button-2> "Editor::ClickTextBox $w %X %Y 2"
    bind $tbw <ButtonPress-3> "Editor::ClickTextBox $w %X %Y 3"
    bind $tbw <Double-Button-1> "Editor::DoubleClickTextBox $w"
    bindtags $tbw "$tbw all"

    grid $w.deckDisplay.pane1.f.deck -sticky nsew -pady 3

    frame $w.deckDisplay.pane1.f.totals
    label $w.deckDisplay.pane1.f.totals.label1 -text "Cards:"
    label $w.deckDisplay.pane1.f.totals.totalCards \
        -textvariable Editor::storage($w,Total,qty,All)
    label $w.deckDisplay.pane1.f.totals.label2 -text "Levels:"
    label $w.deckDisplay.pane1.f.totals.totalLevels \
        -textvariable Editor::storage($w,Total,qty,Levels)
    pack $w.deckDisplay.pane1.f.totals.label1 \
	$w.deckDisplay.pane1.f.totals.totalCards -side left
    pack $w.deckDisplay.pane1.f.totals.totalLevels \
	$w.deckDisplay.pane1.f.totals.label2 -side right

    grid $w.deckDisplay.pane1.f.totals -sticky ew

    grid columnconfigure $w.deckDisplay.pane1.f 0 -weight 1
    grid rowconfigure $w.deckDisplay.pane1.f 1 -weight 1
    grid $w.deckDisplay.pane1.f -sticky nsew -padx 5 -pady 5

    grid columnconfigure $w.deckDisplay.pane1 0 -weight 1
    grid rowconfigure $w.deckDisplay.pane1 0 -weight 1

    # Alternate cards
    frame $w.deckDisplay.pane2.f

    label $w.deckDisplay.pane2.f.l -anchor w
    set storage($w,considering) $w.deckDisplay.pane2.f.l
    grid $w.deckDisplay.pane2.f.l -sticky w

    frame $w.deckDisplay.pane2.f.deck
    set tbw \
        [text $w.deckDisplay.pane2.f.deck.t -exportselection 0 -width 30 \
             -height 5 -wrap none -cursor {} -background white \
             -foreground black -takefocus 0 -spacing1 2 -yscrollcommand \
             "CrossFire::SetScrollBar $w.deckDisplay.pane2.f.deck.sb"]
    set storage($w,altTextBox) $tbw
    $tbw tag configure cardTypeHeader -font {Times 14 bold}
    $tbw tag configure select -foreground white -background blue
    scrollbar $w.deckDisplay.pane2.f.deck.sb -command "$tbw yview" -takefocus 0
    grid $tbw -sticky nsew
    grid columnconfigure $w.deckDisplay.pane2.f.deck 0 -weight 1
    grid rowconfigure $w.deckDisplay.pane2.f.deck 0 -weight 1

    CrossFire::DragTarget $tbw AddCard "Editor::DragAddAlt $w"
    CrossFire::DragTarget $tbw RemoveCard "Editor::DragAddAlt $w"

    bind $tbw <ButtonPress-1> "Editor::ClickTextBox $w %X %Y 1 alts"
    bind $tbw <ButtonRelease-1> "CrossFire::CancelDrag $tbw"
    bind $tbw <Button-2> "Editor::ClickTextBox $w %X %Y 2 alts"
    bind $tbw <ButtonPress-3> "Editor::ClickTextBox $w %X %Y 3 alts"
    bind $tbw <Double-Button-1> "Editor::DoubleClickTextBox $w"
    bindtags $tbw "$tbw all"

    grid $w.deckDisplay.pane2.f.deck -sticky nsew -pady 3

    grid columnconfigure $w.deckDisplay.pane2.f 0 -weight 1
    grid rowconfigure $w.deckDisplay.pane2.f 1 -weight 1
    grid $w.deckDisplay.pane2.f -sticky nsew -pady 5 -padx 5

    grid columnconfigure $w.deckDisplay.pane2 0 -weight 1
    grid rowconfigure $w.deckDisplay.pane2 0 -weight 1

    grid $w.deckDisplay -column 3 -row 0 -sticky nsew -rowspan 3
    grid columnconfigure $w.deckDisplay 0 -weight 1
    grid rowconfigure $w.deckDisplay {0 1} -weight 1

    # Optional embedded card viewer
    if {$storage($w,embedCardView) == "Yes"} {
	frame $w.cardView
	set storage($w,cardFrame) [ViewCard::CreateCardView $w.cardView.cv]
	grid $w.cardView.cv -sticky nsew -padx 5 -pady 5
	grid rowconfigure $w.cardView 0 -weight 1
	grid columnconfigure $w.cardView 0 -weight 1
	grid $w.cardView -column 4 -row 0 -sticky nsew -rowspan 3
	grid columnconfigure $w 4 -weight 2
    }

    grid rowconfigure $w 2 -weight 1
    grid columnconfigure $w 0 -weight 1
    grid columnconfigure $w {1 3} -weight 3

    # Some bindings for keyboard navigation of the editor.
    bind $w <Key-Home>  "Editor::Navigate $w home"
    bind $w <Key-End>   "Editor::Navigate $w end"
    bind $w <Key-Down>  "Editor::Navigate $w down"
    bind $w <Key-Up>    "Editor::Navigate $w up"
    bind $w <Key-Next>  "Editor::Navigate $w +25"
    bind $w <Key-Prior> "Editor::Navigate $w -25"
    bind $w <Key-Right> "Editor::Navigate $w add"
    bind $w <Key-Left>  "Editor::Navigate $w remove"

    ##bind $w <Control-a> "Editor::AddALLCardToDeck $w"

    UpdateCardSelection $w
    New $w
    SetChanged $w "false"
    Config::RecentFile "DeckIt" {}

    if {$args != ""} {
        if {[OpenDeck $w [lindex $args 0] "nocomplain"] == 0} {
            ExitEditor $w
            return
        }
    }

    wm deiconify $w
    raise $w

    if {$CrossFire::platform == "windows"} {
        focus $w
    }

    trace variable Editor::storage($w,deckTitle) w \
        "Editor::SetChanged $w true"

    return $w
}

# Editor::AddMenuBar --
#
#   Creates the menubar for the editor and sets up the
#   accelerator key bindings for the commands.
#
# Parameters:
#   w          : Toplevel of the new editor window.
#
# Returns:
#   Nothing.
#
proc Editor::AddMenuBar {w} {

    variable storage

    menu $w.menubar

    $w.menubar add cascade \
        -label "Deck" \
        -underline 0 \
        -menu $w.menubar.deck

    menu $w.menubar.deck -tearoff 0
    $w.menubar.deck add command \
        -label "New" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+N" \
        -command "Editor::NewDeck $w"
    $w.menubar.deck add command \
        -label "Open..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+O" \
        -command "Editor::OpenDeck $w {}"
    $w.menubar.deck add command \
        -label "Save" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+S" \
        -command "Editor::SaveDeck $w"
    $w.menubar.deck add command \
        -label "Save As..." \
        -underline 5 \
        -command "Editor::SaveDeckAs $w"

    $w.menubar.deck add separator
    $w.menubar.deck add command \
        -label "Information..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+I" \
        -command "Editor::SetDeckInformation $w"
    $w.menubar.deck add cascade \
        -label "Format" \
        -underline 2 \
        -menu $w.menubar.deck.size
    CrossFire::MakeDeckFormatMenu $w.menubar.deck.size \
        Editor::storage($w,newSize) "Editor::ChangeDeckSize $w"

    $w.menubar.deck add cascade \
        -label "Display By" \
        -underline 0 \
        -menu $w.menubar.deck.displayMode
    menu $w.menubar.deck.displayMode -tearoff 0
    $w.menubar.deck.displayMode add radiobutton \
        -label "Card Type" \
        -command "Editor::DisplayDeckAndAlt $w" \
        -variable Editor::storage($w,deckDisplayMode) \
        -value "Type"
    $w.menubar.deck.displayMode add radiobutton \
        -label "Set" \
        -command "Editor::DisplayDeckAndAlt $w" \
        -variable Editor::storage($w,deckDisplayMode) \
        -value "Set"
    $w.menubar.deck.displayMode add radiobutton \
        -label "World" \
        -command "Editor::DisplayDeckAndAlt $w" \
        -variable Editor::storage($w,deckDisplayMode) \
        -value "World"
    $w.menubar.deck.displayMode add radiobutton \
        -label "Rarity" \
        -command "Editor::DisplayDeckAndAlt $w" \
        -variable Editor::storage($w,deckDisplayMode) \
        -value "Rarity"
    $w.menubar.deck.displayMode add radiobutton \
        -label "Digit" \
        -command "Editor::DisplayDeckAndAlt $w" \
        -variable Editor::storage($w,deckDisplayMode) \
        -value "Digit"
    $w.menubar.deck add checkbutton \
        -label "Group Champions Together" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+G" \
        -command "Editor::ToggleChampionMode $w skip" \
        -variable Editor::storage($w,championMode) \
        -onvalue "Champion" -offvalue "Class"

    $w.menubar.deck add separator
    $w.menubar.deck add command \
        -label "Print..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+P" \
        -command "Editor::PrintDeck $w"
    $w.menubar.deck add separator

    set exitLabel "Close"
    set exitAccelerator "Alt+F4"
    if {$CrossFire::platform == "macintosh"} {
        # This is a Macintosh, so make the exit
        # accelerator more "Mac-ish"
        set exitLabel "Quit"
        set exitAccelerator "Command+Q"
    }
    $w.menubar.deck add command \
        -label $exitLabel \
        -underline 1 \
        -accelerator $exitAccelerator \
        -command "Editor::ExitEditor $w"

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
                -variable Editor::storage($w,selCardType) \
                -command "Editor::ChangeCardType $w $cardTypeID"
        }
    }

    $w.menubar.card add separator
    $w.menubar.card add command \
        -label "Find in Deck" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+F" \
        -command "Editor::FindCardInDeck $w"
    $w.menubar.card add command \
        -label "View" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+V" \
        -command "Editor::ViewCard $w"
    $w.menubar.card add separator
    $w.menubar.card add command \
        -label "Add" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+A" \
        -command "Editor::AddCard $w"
    $w.menubar.card add command \
        -label "Consider" \
        -underline 0 \
        -command "Editor::AddCard $w alt"
    $w.menubar.card add command \
        -label "Remove" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+R" \
        -command "Editor::RemoveCard $w"

    $w.menubar add cascade \
        -label "Utilities" \
        -underline 0 \
        -menu $w.menubar.window

    menu $w.menubar.window -tearoff 0
    $w.menubar.window add command \
        -label "Deck Differ..." \
        -underline 3 \
        -accelerator "$CrossFire::accelKey+K" \
        -command "Editor::DeckDiffer $w"
    $w.menubar.window add command \
	-label "Display Deck Key..." \
	-command "Editor::DisplayDeckKey $w"
    $w.menubar.window add command \
        -label "Deck Status..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+D" \
        -command "Editor::DeckStatus $w Totals"
    $w.menubar.window add command \
        -label "Old Deck Status..." \
        -underline 0 \
        -command "Editor::OldDeckStatus $w"
    $w.menubar.window add command \
        -label "Ultra Searcher..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+U" \
        -command "Searcher::Create $w"
    $w.menubar.window add separator
    $w.menubar.window add command \
        -label "Configure..." \
        -underline 0 \
        -command "Config::Create DeckIt"

    $w.menubar add cascade \
        -label "Help" \
        -underline 0 \
        -menu $w.menubar.help

    menu $w.menubar.help -tearoff 0
    $w.menubar.help add command \
        -label "Help..." \
        -underline 0 \
        -accelerator "F1" \
        -command "CrossFire::Help di_main.html"
    $w.menubar.help add separator
    $w.menubar.help add command \
        -label "About DeckIt..." \
        -underline 0 \
        -command "Editor::About $w"

    $w configure -menu $w.menubar

    # Deck menu bindings.
    bind $w <$CrossFire::accelBind-n> "Editor::NewDeck $w"
    bind $w <$CrossFire::accelBind-o> "Editor::OpenDeck $w {}"
    bind $w <$CrossFire::accelBind-s> "Editor::SaveDeck $w"
    bind $w <$CrossFire::accelBind-p> "Editor::PrintDeck $w"
    bind $w <$CrossFire::accelBind-i> "Editor::SetDeckInformation $w"
    bind $w <$CrossFire::accelBind-g> "Editor::ToggleChampionMode $w"

    if {$CrossFire::platform == "macintosh"} {
        bind $w <Command-q> "Editor::ExitEditor $w"
    } else {
        bind $w <Meta-x> "Editor::ExitEditor $w"
        bind $w <Alt-F4> "Editor::ExitEditor $w; break"
    }

    # Card menu bindings.
    bind $w <$CrossFire::accelBind-a> "Editor::AddCard $w"
    bind $w <$CrossFire::accelBind-v> "Editor::ViewCard $w"
    bind $w <$CrossFire::accelBind-r> "Editor::RemoveCard $w"

    # Utilities menu bindings.
    bind $w <$CrossFire::accelBind-k> "Editor::DeckDiffer $w"
    bind $w <$CrossFire::accelBind-d> "Editor::DeckStatus $w Totals"
    bind $w <$CrossFire::accelBind-u> "Searcher::Create $w"
    bind $w <$CrossFire::accelBind-f> "Editor::FindCardInDeck $w"

    # Help menu bindings.
    bind $w <Key-F1> "CrossFire::Help di_main.html"
    bind $w <Key-Help> "CrossFire::Help di_main.html"

    # menu for right click on card list
    menu $w.addMenu -tearoff 0
    $w.addMenu add command -label " Add" \
        -command "Editor::AddCard $w"
    $w.addMenu add separator
    $w.addMenu add command -label " Find In Deck" \
        -command "Editor::FindCardInDeck $w"
    $w.addMenu add command -label " View" \
        -command "Editor::ViewCard $w"

    # menu for right click on deck card name
    menu $w.removeMenu -tearoff 0
    $w.removeMenu add command -label " Remove" \
        -command "Editor::RemoveCard $w"
    $w.removeMenu add separator
    $w.removeMenu add command -label " Find In Deck" \
        -command "Editor::FindCardInDeck $w"
    $w.removeMenu add command -label " View" \
        -command "Editor::ViewCard $w"

    # menus for right click on deck card type
    menu $w.expandMenu -tearoff 0
    $w.expandMenu add command -label " Expand" \
        -command "Editor::DoubleClickTextBox $w"
    $w.expandMenu add separator
    $w.expandMenu add command -label " Remove" \
        -command "Editor::RemoveCard $w"
    menu $w.collapseMenu -tearoff 0
    $w.collapseMenu add command -label " Collapse" \
        -command "Editor::DoubleClickTextBox $w"
    $w.collapseMenu add separator
    $w.collapseMenu add command -label " Remove" \
        -command "Editor::RemoveCard $w"

    return
}

# Editor::SetCardSet --
#
#   Changes the selected set of cards.
#
# Parameter:
#    w        : Editor toplevel.
#
# Returns:
#    Nothing.
#
proc Editor::SetCardSet {w from args} {

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

# Editor::ExitEditor --
#
#   Gracefully closes the specified editor.  Checks if deck
#   needs to be saved before closing.
#
# Parameters:
#   w          : Widget name of the editor.
#
# Returns:
#   Returns 0 if exiting or -1 if exit canceled.
#
proc Editor::ExitEditor {w} {

    variable storage

    update
    update idletasks

    if {[CheckForSave $w] == 0} {

        foreach {ww hh x y} [split [wm geometry $w] "+x"] break
        set geometry "${ww}x${hh}"

        destroy $w

        UnLockFile $w

        if {[info exists storage($w,autoSaveAfterID)]} {
            after cancel $storage($w,autoSaveAfterID)
        }

        # Unset all the variables for the editor.
        foreach name [array names storage "${w},*"] {
            unset storage($name)
        }

        ViewCard::CleanUpCardViews $w
        CrossFire::UnRegister DeckIt $w

        Config::Set DeckIt,selectSash [PanedWindow::Position $w.listDisplay 1]
        Config::Set DeckIt,deckSash [PanedWindow::Position $w.deckDisplay 1]
        Config::Set DeckIt,geometry $geometry

        return 0
    } else {
        return -1
    }
}

# Editor::NewDeck --
#
#   Clears the current deck.  Checks if saved needed.
#
# Parameters:
#   w          : Editor toplevel path name.
#
# Returns:
#   Nothing.
#
proc Editor::NewDeck {w} {

    variable storage

    if {[CheckForSave $w] == -1} {
        return
    }

    New $w
    SetChanged $w "false"

    return
}

# Editor::New --
#
#   Procedure that actually clears the deck.  This was split from NewDeck
#   to account for CheckForSave being called twice when it should not be.
#   The changed status is *not* changed by this proc.
#
# Parameters:
#   w          : Editor toplevel.
#
# Returns:
#   Nothing.
#
proc Editor::New {w} {

    variable storage

    UnLockFile $w

    set storage($w,deck) {}
    set storage($w,altCards) {}
    set storage($w,fileName) {}
    set storage($w,levelList) {}
    set storage($w,avatarList) {}
    set storage($w,inInventory) "true"
    set storage($w,authorName) $Config::config(CrossFire,authorName)
    set storage($w,authorEmail) $Config::config(CrossFire,authorEmail)
    set storage($w,notes) ""
    $storage($w,deckInfoNotesW) delete 1.0 end
    set storage($w,deckTitle) ""
    set storage($w,hasDungeon) 0
    set storage($w,checkInv) "No"
    set storage($w,cardSet) $Config::config(DeckIt,startSetID)
    set storage($w,inventory) $Config::config(Warehouse,defaultInv)

    foreach data {All Avatars Chase Champions Levels} {
        set storage($w,Total,qty,$data) 0
    }
    set storage($w,Type,expand,Champions) 1
    set storage($w,Type,expandAlt,Champions) 1

    foreach cardTypeID $CrossFire::cardTypeIDList {
        if {($cardTypeID > 0) && ($cardTypeID < 99)} {
            set typeID $CrossFire::cardTypeXRef($cardTypeID,name)
            set storage($w,Type,qty,$typeID) 0
            set storage($w,Type,expand,$typeID) 1
            set storage($w,Type,expandAlt,$typeID) 1
        }
    }

    foreach setID "[CrossFire::CardSetIDList allPlain] FAN" {
        set storage($w,Set,qty,$setID) 0
        set storage($w,Set,expand,$setID) 1
        set storage($w,Set,expandAlt,$setID) 1
    }

    foreach worldID "$CrossFire::worldIDList FAN" {
        set storage($w,World,qty,$worldID) 0
        set storage($w,World,expand,$worldID) 1
        set storage($w,World,expandAlt,$worldID) 1
    }

    foreach rarityID $CrossFire::cardFreqIDList {
        set storage($w,Rarity,qty,$rarityID) 0
        set storage($w,Rarity,expand,$rarityID) 1
        set storage($w,Rarity,expandAlt,$rarityID) 1
    }

    foreach cardDigit $CrossFire::cardDigitList {
	set storage($w,Digit,qty,$cardDigit) 0
	set storage($w,Digit,expand,$cardDigit) 1
	set storage($w,Digit,expandAlt,$cardDigit) 1
    }
    set storage($w,Digit,avg) 0.0
    foreach dVar {
        vorpal ultrablast knockdown fates1 fates2 fates3
    } {
        set storage($w,Digit,$dVar) "0.0%"
    }

    foreach usable $CrossFire::usableCards(list) {
        set storage($w,Usable,$usable) 0
    }

    DisplayDeck $w
    DisplayAltCards $w
    SetCardSet $w "menu"

    return
}

# Editor::ChangeDeckSize --
#
#   Changes the deck size, if allowed.  Will not allow to change
#   to a size that would violate the card type maximums.
#
# Parameters:
#   w          : Widget name of the editor.
#
# Returns:
#   Nothing.
#
proc Editor::ChangeDeckSize {w} {

    variable storage

    set newSize $storage($w,newSize)
    set changeError "none"
    set fanSets [CrossFire::CardSetIDList "fan"]

    # Totals checking
    foreach data {All Champions Chase Levels} {
        set qtyKey "$w,Total,qty,$data"
        set maxKey "$newSize,Total,max,$data"
        if {$storage($qtyKey) > $CrossFire::deckFormat($maxKey)} {
            set msg "Quantity of Total $data ($storage($qtyKey)) exceeds "
            append msg "new limit ($CrossFire::deckFormat($maxKey))."
            set changeError "Total,$data"
            break
        }
    }

    # Check for any banned cards
    if {$changeError == "none"} {
        set bannedList $CrossFire::deckFormat($newSize,bannedList)
        foreach card $storage($w,deck) {
            set cardDesc [CrossFire::GetCardDesc $card]
            set cardID [lindex $cardDesc 0]
            if {[lsearch $bannedList $cardID] != -1} {
                set msg "[lindex $card 6] is banned!"
                set changeError "banned"
                break
            }
        }
    }

    # Check the qty of each card type, set, world, rarity for exceeding
    # the new maximums.
    if {$changeError == "none"} {
        foreach data {Type Set World Rarity} {
            foreach key [array names storage "$w,$data,qty,*"] {
                set which [lindex [split $key ","] 3]
                set maxKey "$newSize,$data,max,$which"

                # Skip testing fan sets and worlds.  They are lumped together.
                if {(($data == "Set") && ([lsearch $fanSets $which] != -1)) ||
                    (($data == "World") &&
                     ([lsearch $CrossFire::fanWorldIDList $which] != -1)) ||
                    ($which == "FAN")} {
                    continue
                }

                if {$storage($key) > $CrossFire::deckFormat($maxKey)} {
                    if {$data == "Set"} {
                        set which $CrossFire::setXRef($which,name)
                    } elseif {$data == "World"} {
                        set which $CrossFire::worldXRef($which,name)
                    } elseif {$data == "Rarity"} {
                        set which $CrossFire::cardFreqName($which)
                    }
                    set msg "Quantity of $data $which ($storage($key)) exceeds"
                    append msg " new limit ($CrossFire::deckFormat($maxKey))."
                    set changeError $which
                    break
                }
            }
            if {$changeError != "none"} {
                break
            }
        }
    }

    # Check number of copies of a card.  Save the current size and deck.
    # Add each card in and check if multiple is still ok by calling
    # CheckMultipleCards.
    if {$changeError == "none"} {
        set keepSize $storage($w,size)
        set storage($w,size) $storage($w,newSize)
        set keepDeck $storage($w,deck)
        set storage($w,deck) {}
        foreach card $keepDeck {
            if {[CheckMultipleCards $w $card] == ""} {
                # Card is OK to add
                lappend storage($w,deck) $card
            } else {
                # Was not able to add the card due to mulitples
                set msg "Card [lindex $card 6] violates the allowed"
                append msg " number of copies of a card."
                set changeError "multiples"
                break
            }
        }
        set storage($w,deck) $keepDeck
        set storage($w,size) $keepSize
    }

    # Check total number of cards from fan sets/worlds
    if {$changeError == "none"} {
        foreach data {Set World} {
            set max $CrossFire::deckFormat($newSize,$data,max,FAN)
            set num $storage($w,$data,qty,FAN)
            if {($changeError == "none") && ($num > $max)} {
                set changeError "fan$data"
                set msg "Number of cards from Fan ${data}s ($num) exceeds "
                append msg "new limit ($max)"
            }
        }
    }

    # Different deck sizes allow different number of free avatars.
    # This could result in a different level total.  Test the level
    # total as if the deck were the new size.
    if {$changeError == "none"} {
        set curSize $storage($w,size)
        set storage($w,size) $newSize
        set newLevels [CalcLevelTotal $w]
        if {$newLevels > $CrossFire::deckFormat($newSize,Total,max,Levels)} {
            set changeError "avatars"
            set msg "Due to Avatars, the level total exceeds the new limits."
            set storage($w,size) $curSize
        }
    }

    if {$changeError == "none"} {
        set storage($w,size) $newSize

        # Recalc level totals.
        set storage($w,Total,qty,Levels) [CalcLevelTotal $w]

        DisplayDeck $w
        UpdateDeckStatus $w Max
        SetChanged $w "true"

    } else {
        set storage($w,newSize) $storage($w,size)
        tk_messageBox -title "Error Changing Deck Format" \
            -icon error -message $msg -parent $w
    }

    return
}

# Editor::CheckMultipleCards --
#
#   Checks for 1) a card already in deck when multiple cards not allowed;
#   2) cards that state "Limit * per deck." for violation of the specified
#   limit; and 3) cards with "No limit per deck.".
#
# Parameters:
#   w          : Editor toplevel.
#   card       : Card to check.
#
# Returns:
#   Nothing if the card is ok, or an error message if not.
#
proc Editor::CheckMultipleCards {w card} {

    variable storage

    set msg ""
    set multipleOK 0
    set deckSize $storage($w,size)

    foreach {
        setID cardNumber bonus cardIcon world isAvatar cardName
        cardText rarity blueLine attrList usesList weight
    } $card break

    # A card is the same IFF the type and name are the same.
    set cardCount 0
    foreach testCard $storage($w,deck) {
        if {($cardIcon == [lindex $testCard 3]) &&
            ($cardName == [lindex $testCard 6])} {
            incr cardCount
        }
    }

    # With the introduction of InQuisition we added a limit line to the
    # bluelines, so add it to card text so it will be found.  It is added
    # first so it will match overriding any listed limit in the card text.
    set cardText "$blueLine $cardText"

    # There are some cards that have "No limit per deck.",
    # so we will check for them and allow any qty.
    if {[regexp -nocase "No limit per deck." $cardText]} {
        return ""
    }

    # Check for cards that have a specified limit per deck.
    # Stated as "Limit 3 per deck." or "Limit one per deck."
    if {[regexp -nocase "Limit (\[a-z0-9\]+) per deck." $cardText dummy max]} {
        if {$max == "one"} {
            set max 1
            set copy "copy"
        } else {
            set copy "copies"
        }
        if {$cardCount == $max} {
            return "Stated limit of $max $copy of \"$cardName\" reached."
        }

	# This fixes cards such as 3rd/256 Nomad Mercanaries that state
	# "Limit 3 per deck." because additional code was added for
	# allowing multiples.  This older test needs this update to conform.
        if {$max != 1} {
            set multipleOK 1
        }
    }

    # Check the card's type, set, world, and rarity to see if multiples
    # can be allowed for this card.  It is allowed if ANY of the
    # requirements are met.

    # Card type
    set typeName $CrossFire::cardTypeXRef($cardIcon,name)
    set max $CrossFire::deckFormat($deckSize,Type,mult,$typeName)
    if {($cardCount < $max)} {
        set multipleOK 1
    }

    # Set
    set setName $CrossFire::setXRef($setID,name)
    if {[lsearch [CrossFire::CardSetIDList "fan"] $setID] != -1} {
	# This is a Fan Set.  Fan set cards are all lumped into one
	# restriction.
        set max $CrossFire::deckFormat($deckSize,Set,mult,FAN)
    } else {
        set max $CrossFire::deckFormat($deckSize,Set,mult,$setID)
    }
    if {$cardCount < $max} {
        set multipleOK 1
    }

    # World
    set worldName $CrossFire::worldXRef($world,name)
    if {[lsearch $CrossFire::fanWorldIDList $world] != -1} {
        set max $CrossFire::deckFormat($deckSize,World,mult,FAN)
    } else {
        set max $CrossFire::deckFormat($deckSize,World,mult,$world)
    }
    if {$cardCount < $max} {
        set multipleOK 1
    }

    # Rarity
    set rarityName $CrossFire::cardFreqName($rarity)
    set max $CrossFire::deckFormat($deckSize,Rarity,mult,$rarity)
    if {$cardCount < $max} {
        set multipleOK 1
    }

    if {$multipleOK == 0} {
        if {$cardCount == 0} {
            set msg "$cardName is not permitted in this deck!"
        } else {
            set msg "$cardName already exists in the deck!"
        }
    }

    return $msg
}

# Editor::ToggleChampionMode --
#
#   Changes the champion display mode.
#
# Parameters:
#   w          : Editor toplevel name.
#
# Returns:
#   Nothing.
#
proc Editor::ToggleChampionMode {w {skip no}} {

    variable storage

    if {$skip == "no"} {
	if {$storage($w,championMode) == "Class"} {
	    set storage($w,championMode) "Champion"
	} else {
	    set storage($w,championMode) "Class"
	}
    }

    DisplayDeckAndAlt $w

    return
}

# Editor::UpdateCardSelection --
#
#   Changes the card set, updates selection list box.
#
# Parameters:
#   w          : Editor toplevel name.
#
# Returns:
#   Nothing.
#
proc Editor::UpdateCardSelection {w} {

    variable storage

    $w configure -cursor watch
    update
        
    set newSetName $storage($w,cardSet)

    if {$newSetName == "All"} {
        set listOfIDs $storage($w,allSetsList)
    } else {
        set listOfIDs $newSetName
    }

    $storage($w,cardListBox) delete 0 end
    foreach setID [CrossFire::CardSetIDList "allPlain"] { 
        if {[lsearch $listOfIDs $setID] != -1} {
            CrossFire::ReadCardDataBase $setID
            CrossFire::CardSetToListBox $CrossFire::cardDataBase \
                $storage($w,cardListBox) \
                $storage($w,selCardID) "append"
        }
    }

    ClickListBox $w m 0 0

    $w configure -cursor {}
    return
}

# Editor::ChangeCardType --
#
#   Changes the card type to view in the selection box.
#
# Parameters:
#   w          : Editor toplevel widget name.
#   typeID     : Numeric ID of the card type.
#
# Returns:
#   Nothing.
#
proc Editor::ChangeCardType {w typeID} {

    variable storage

    set storage($w,selCardID) $typeID
    UpdateCardSelection $w

    return
}

# Editor::GetSelectedCardID --
#
#   Returns the short ID of the selected card, if any.
#
# Parameters:
#   w          : Editor toplevel widget name.
#
# Returns:
#   The short ID if a card is selected, nothing otherwise.
#
proc Editor::GetSelectedCardID {w} {

    variable storage

    # Get and return the current selection's card ID.
    switch $storage($w,selectionAt) {
        "listbox" {
            # Card selection list box.
            set lbw $storage($w,cardListBox)
            if {[$lbw curselection] != ""} {
                return [lindex [$lbw get [$lbw curselection]] 0]
            } else {
                return ""
            }
        }
        "textbox" {
            # Deck text box.
            set tbw $storage($w,deckTextBox)
        }
	"alts" {
	    # Possible cards text box
	    set tbw $storage($w,altTextBox)
	}
        "differ" {
            # Deck differ text box.
            set tbw $storage($w,diffTextBox)
        }
    }

    # Get the selection from a text box.
    set start [lindex [$tbw tag ranges select] 0]
    if {$start == ""} {
        set selectedCard ""
    } else {
        set end [lindex [split $start "."] 0].end
        set selectedCard [$tbw get $start $end]
    }

    set first [lindex $selectedCard 0]
    if {$first == "Deck"} {
        set first ""
    }

    # Return the whole string if it is a card group.
    if {($first != "+") && ($first != "-")} {
        set selectedCard $first
    }

    return $selectedCard
}

# Editor::DisplayDeckAndAlt --
#
#   Redraws both the deck and possible cards.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Editor::DisplayDeckAndAlt {w} {

    DisplayDeck $w 0
    DisplayAltCards $w 0

    return
}

# Editor::DisplayDeck --
#
#   Wrapper procedure to display the deck.  Calls either DisplayDeckByType
#   or DisplayDeckBy.
#
#
# Parameters:
#   w          : Editor toplevel widget name.
#   args       : Optional line number to put at the top of the text box.
#                Normally, the current line will be redisplayed at the
#                top. OpenDeck calls this procedure with a 0 for line number.
#
# Returns:
#   Nothing.
#
proc Editor::DisplayDeck {w args} {

    variable storage

    $w configure -cursor watch
    update

    set tbw $storage($w,deckTextBox)

    if {$args != ""} {
        set yview [lindex $args 0]
    } else {
        set yview [expr int([$tbw index @0,0]) - 1]
    }

    $tbw delete 1.0 end

    set avatarList $storage($w,avatarList)
    if {$avatarList != {}} {
        set nfa $CrossFire::deckFormat($storage($w,size),Total,max,Avatars)
        set highestLevel \
            [lrange [lsort -int -dec $avatarList] 0 [expr $nfa - 1]]
        set hiliteAvatar $nfa
    } else {
        set highestLevel 0
        set hiliteAvatar 0
    }

    if {$storage($w,deckDisplayMode) == "Type"} {
        set nfa [DisplayDeckByType $w $yview $highestLevel $hiliteAvatar]
    } else {
        set nfa [DisplayDeckBy $storage($w,deckDisplayMode) $w $yview \
		     $highestLevel $hiliteAvatar]
    }

    set storage($w,Total,qty,Avatars) $nfa
    UpdateDeckStatus $w Color

    $tbw yview scroll $yview units
    $w configure -cursor {}
    update idletasks
    update

    return
}

# Editor::DisplayDeckByType --
#
#   Displays a deck sorted by card type in the text box.
#
# Parameters:
#   w          : Editor toplevel widget name.
#   yview      : Line number to put at the top of the text box.
#   highestLevel : Level(s) of the free avatar(s).
#   hiliteAvatar : Quantity of free avatars to hilite.
#
# Returns:
#   Nothing.
#
proc Editor::DisplayDeckByType {w yview highestLevel hiliteAvatar} {

    variable storage

    set tbw $storage($w,deckTextBox)
    set size $storage($w,size)
    set lineCount 0
    set nfa 0

    set tempDeck [lsort $storage($w,deck)]
    foreach cardTypeID $CrossFire::cardTypeIDList {
        set typeName $CrossFire::cardTypeXRef($cardTypeID,name)
        set displayedName 0

        foreach card $tempDeck {

            set testTypeID [lindex $card 3]
            if {$storage($w,championMode) == "Class"} {
                # Display champions under their class
                if {$testTypeID != $cardTypeID} {
                    continue
                }
            } else {
                # Display all champions under Champions label
                if {[lsearch $CrossFire::championList $testTypeID] != -1} {
                    if {$cardTypeID != 99} {
                        continue
                    }
                } else {
                    if {$testTypeID != $cardTypeID} {
                        continue
                    }
                }
            }

            if {$displayedName == 0} {

                incr lineCount
                if {$lineCount != 1} {
                    $tbw insert end "\n"
                }

                set tagList "cardTypeHeader"
                if {$typeName == "Champions"} {
                    set min $CrossFire::deckFormat($size,Total,min,$typeName)
                    set max $CrossFire::deckFormat($size,Total,max,$typeName)
                    set qty $storage($w,Total,qty,$typeName)
                } else {
                    set min $CrossFire::deckFormat($size,Type,min,$typeName)
                    set max $CrossFire::deckFormat($size,Type,max,$typeName)
                    set qty $storage($w,Type,qty,$typeName)
                }

                if {($qty < $min) || ($qty > $max)} {
                    lappend tagList "violation"
                }

                if {$storage($w,Type,expand,$typeName) == 1} {
                    $tbw insert end "- " $tagList
                } else {
                    $tbw insert end "+ " $tagList
                }

                set amount "$qty / $min - $max"
                $tbw insert end "$typeName : $amount " $tagList
                set displayedName 1
            }

            if {$storage($w,Type,expand,$typeName) == 1} {
                set desc [CrossFire::GetCardDesc $card]
                set thisLevel [lindex $card 2]
                if {$thisLevel == "?"} {
                    set thisLevel 0
                }
                $tbw insert end "\n    "
                if {($Config::config(DeckIt,showIcon) == "Yes")} {
                    $tbw image create end -image small$testTypeID
                    $tbw insert end " "
                }
                if {(($hiliteAvatar != 0) && ([lindex $card 5] == 1) &&
                     ([lsearch -exact $highestLevel $thisLevel] != -1))} {
                    regsub $thisLevel $highestLevel "" highestLevel
                    $tbw insert end $desc avatar
                    incr hiliteAvatar -1
                    incr nfa
                } else {
                    $tbw insert end $desc
                }
            }
        }
    }

    return $nfa
}

# Editor::DisplayDeckBy --
#
#   Displays a deck sorted by card set/rarity/world.
#
# Parameters:
#   w          : Editor toplevel widget name.
#   yview      : Line number to put at the top of the text box.
#   highestLevel : Level(s) of the free avatar(s).
#   hiliteAvatar : Quantity of free avatars to hilite.
#
# Returns:
#   Nothing.
#
proc Editor::DisplayDeckBy {which w yview highestLevel hiliteAvatar} {

    variable storage

    set tbw $storage($w,deckTextBox)
    set deckSize $storage($w,size)
    set lineCount 0
    set nfa 0
    set tempDeck [lsort $storage($w,deck)]

    if {$which == "Set"} {
        set idList [CrossFire::CardSetIDList "allPlain"]
        set field 0
    } elseif {$which == "Rarity"} {
        set idList $CrossFire::cardFreqIDList
        set field 8
    } elseif {$which == "World"} {
        set idList $CrossFire::worldIDList
        set field 4
    } elseif {$which == "Digit"} {
	set idList $CrossFire::cardDigitList
	set field 1
    }

    foreach id $idList {

        set displayedName 0

        # tid is used to group all fan created sets or worlds together
        set tid $id
        if {$which == "Set"} {
            set heading $CrossFire::setXRef($id,name)
            if {[lsearch [CrossFire::CardSetIDList "fan"] $id] != -1} {
                set tid "FAN"
            }
        } elseif {$which == "Rarity"} {
            set heading $CrossFire::cardFreqName($id)
        } elseif {$which == "World"} {
            set heading $CrossFire::worldXRef($id,name)
            if {[lsearch $CrossFire::fanWorldIDList $id] != -1} {
                set tid "FAN"
            }
        } elseif {$which == "Digit"} {
	    set heading $id
	}

        foreach card $tempDeck {

            set testTypeID [lindex $card 3]
	    set digit [string range [lindex $card 1] end end]

            if {($which == "Digit" && $digit == $id) ||
		[lindex $card $field] == $id} {

                if {$displayedName == 0} {
                    incr lineCount
                    if {$lineCount != 1} {
                        $tbw insert end "\n"
                    }

                    set tagList "cardTypeHeader"
                    set min $CrossFire::deckFormat($deckSize,$which,min,$tid)
                    set max $CrossFire::deckFormat($deckSize,$which,max,$tid)
                    set qty $storage($w,$which,qty,$id)

                    if {($qty < $min) || ($qty > $max)} {
                        lappend tagList "violation"
                    }

                    if {$storage($w,$which,expand,$id) == 1} {
                        $tbw insert end "- " $tagList
                    } else {
                        $tbw insert end "+ " $tagList
                    }

                    set amount "$qty / $min - $max"
                    $tbw insert end "$heading : $amount" $tagList
                    set displayedName 1
                }

                if {$storage($w,$which,expand,$id) == 1} {
                    set desc [CrossFire::GetCardDesc $card]
                    set thisLevel [lindex $card 2]
                    if {$thisLevel == "?"} {
                        set thisLevel 0
                    }
                    $tbw insert end "\n    "
                    if {($Config::config(DeckIt,showIcon) == "Yes")} {
                        $tbw image create end -image small$testTypeID
                        $tbw insert end " "
                    }
                    if {($hiliteAvatar != 0) && ([lindex $card 5] == 1) &&
                        ([lsearch -exact $highestLevel $thisLevel] != -1)} {
                        regsub $thisLevel $highestLevel "" highestLevel
                        $tbw insert end $desc avatar
                        incr hiliteAvatar -1
                        incr nfa
                    } else {
                        $tbw insert end $desc
                    }
                }
            }
        }
    }

    return $nfa
}

# Editor::DisplayAltCards --
#
#   Wrapper proc to display the list of considering cards.  Calls either
#   DisplayAltCardsByType or DisplayAltCardsBy
#
# Parameters:
#   w          : Editor toplevel widget name.
#   args       : Optional line number to put at the top of the text box.
#
# Returns:
#   Nothing.
#
proc Editor::DisplayAltCards {w args} {

    variable storage

    $w configure -cursor watch
    update

    set tbw $storage($w,altTextBox)

    if {$args != ""} {
        set yview [lindex $args 0]
    } else {
        set yview [expr int([$tbw index @0,0]) - 1]
    }

    $tbw delete 1.0 end

    if {$storage($w,deckDisplayMode) == "Type"} {
	DisplayAltCardsByType $w
    } else {
	DisplayAltCardsBy $storage($w,deckDisplayMode) $w
    }

    set numAltCards [llength $storage($w,altCards)]
    if {$numAltCards == 0} {
        set l "Considering Cards:"
    } else {
        set l "Considering Cards ($numAltCards):"
    }
    $storage($w,considering) configure -text $l

    $tbw yview scroll $yview units
    $w configure -cursor {}

    return
}

# Editor::DisplayAltCardsByType --
#
#   Displays the list of possible cards for a deck.
#
# Parameters:
#   w         : Editor toplevel.
#
# Returns:
#   Nothing.
#
proc Editor::DisplayAltCardsByType {w} {

    variable storage

    set tbw $storage($w,altTextBox)
    set lineCount 0
    set tagList "cardTypeHeader"
    set tempDeck [lsort $storage($w,altCards)]

    foreach cardTypeID $CrossFire::cardTypeIDList {
        set typeName $CrossFire::cardTypeXRef($cardTypeID,name)
        set cardList {}

        foreach card $tempDeck {

            set testTypeID [lindex $card 3]
            if {$storage($w,championMode) == "Class"} {
                # Display champions under their class
                if {$testTypeID != $cardTypeID} {
                    continue
                }
            } else {
                # Display all champions under Champions label
                if {[lsearch $CrossFire::championList $testTypeID] != -1} {
                    if {$cardTypeID != 99} {
                        continue
                    }
                } else {
                    if {$testTypeID != $cardTypeID} {
                        continue
                    }
                }
            }

            lappend cardList $card
        }

        if {$cardList != ""} {
            incr lineCount
            if {$lineCount != 1} {
                $tbw insert end "\n"
            }

            if {$storage($w,Type,expandAlt,$typeName) == 1} {
                $tbw insert end "- " $tagList
            } else {
                $tbw insert end "+ " $tagList
            }

            $tbw insert end "$typeName : [llength $cardList]" $tagList

            if {$storage($w,Type,expandAlt,$typeName) == 1} {
                foreach card $cardList {
                    set testTypeID [lindex $card 3]
                    set desc [CrossFire::GetCardDesc $card]
                    $tbw insert end "\n    "
                    if {($Config::config(DeckIt,showIcon) == "Yes")} {
                        $tbw image create end -image small$testTypeID
                        $tbw insert end " "
                    }
                    $tbw insert end $desc
                }
            }
        }
    }

    return
}

# Editor::DisplayAltDeckBy --
#
#   Displays considered cards sorted by card set/rarity/world.
#
# Parameters:
#   which      : Which field to sort by (Aet, World, Rarity)
#   w          : Editor toplevel widget name.
#
# Returns:
#   Nothing.
#
proc Editor::DisplayAltCardsBy {which w} {

    variable storage

    set tbw $storage($w,altTextBox)
    set lineCount 0
    set tempDeck [lsort $storage($w,altCards)]

    if {$which == "Set"} {
        set idList [CrossFire::CardSetIDList "allPlain"]
        set field 0
    } elseif {$which == "Rarity"} {
        set idList $CrossFire::cardFreqIDList
        set field 8
    } elseif {$which == "World"} {
        set idList $CrossFire::worldIDList
        set field 4
    } elseif {$which == "Digit"} {
	set idList $CrossFire::cardDigitList
	set field 0
    }

    foreach id $idList {

        set displayedName 0

        # tid is used to group all fan created sets or worlds together
        set tid $id
        if {$which == "Set"} {
            set heading $CrossFire::setXRef($id,name)
            if {[lsearch [CrossFire::CardSetIDList "fan"] $id] != -1} {
                set tid "FAN"
            }
        } elseif {$which == "Rarity"} {
            set heading $CrossFire::cardFreqName($id)
        } elseif {$which == "World"} {
            set heading $CrossFire::worldXRef($id,name)
            if {[lsearch $CrossFire::fanWorldIDList $id] != -1} {
                set tid "FAN"
            }
        } elseif {$which == "Digit"} {
	    set heading $id
	}

        set cardList {}
        foreach card $tempDeck {

	    set digit [string range [lindex $card 1] end end]

            if {($which == "Digit" && $digit == $id) ||
		[lindex $card $field] == $id} {
                lappend cardList $card
            }
        }

        if {$cardList != ""} {

            incr lineCount
            if {$lineCount != 1} {
                $tbw insert end "\n"
            }

            set tagList "cardTypeHeader"

            if {$storage($w,$which,expandAlt,$id) == 1} {
                $tbw insert end "- " $tagList
            } else {
                $tbw insert end "+ " $tagList
            }

            $tbw insert end "$heading : [llength $cardList]" $tagList
        }

        if {$storage($w,$which,expandAlt,$id) == 1} {
            foreach card $cardList {
                set testTypeID [lindex $card 3]
                set desc [CrossFire::GetCardDesc $card]
                $tbw insert end "\n    "
                if {($Config::config(DeckIt,showIcon) == "Yes")} {
                    $tbw image create end -image small$testTypeID
                    $tbw insert end " "
                }
                $tbw insert end $desc
            }
        }
    }

    return
}

# Editor::CalcLevelTotal --
#
#   Calculates the current total levels of all the champions
#   except the highest leveled avatar(s) (the "freebies").
#
# Parameters:
#   w          : Editor toplevel path name.
#
# Returns:
#   The total levels.
#
proc Editor::CalcLevelTotal {w} {

    variable storage

    # Add all the levels in the list of regular champions.
    set totalLevels 0
    foreach level $storage($w,levelList) {
        incr totalLevels $level
    }

    # Add all the levels except the last (highest) one(s) in
    # the list of avatars.
    set sort [lsort -int -dec $storage($w,avatarList)]
    set nfa $CrossFire::deckFormat($storage($w,size),Total,max,Avatars)
    foreach level [lrange $sort $nfa end] {
        incr totalLevels $level
    }

    return $totalLevels
}

# Editor::CheckInventory --
#
#   Checks if the card is in the inventory.
#
# Parameters:
#   w          : Editor toplevel.
#   card       : Card to check for.
#
# Returns:
#   1 if in inventory, -1 if not.
#
proc Editor::CheckInventory {w card} {

    variable storage

    set setID [lindex $card 0]
    set cardNum [lindex $card 1]
    set cardInv [lindex [Inventory::GetInvInfo $w inv$setID] $cardNum]
    if {[lindex $cardInv 1] == 0} {
        set msg "You do not have:\n[lindex $card 6]\nAdd anyway?"
        set answer \
            [tk_messageBox -icon question -type yesno -parent $w \
                 -message $msg -title "Error Adding Card" -default "yes"]
        if {$answer == "yes"} {
            set result 1
        } else {
            set result -1
        }
    } else {
        set result 1
    }

    return $result
}

# Editor::AddCardToDeck --
#
#   Adds a card to a deck.  First checks if all the requirements
#   and restrictions are met before adding the card.  Used by
#   OpenDeck and AddCard.
#
# Parameters:
#   w          : Editor toplevel path name.
#   card       : The card to add in standard card format.
#
# Returns:
#   1 if added, or 0 if not.
#
proc Editor::AddCardToDeck {w card} {

    variable storage

    set okToAdd 1

    # Do all the checks to see if we can add the card.

    foreach {
        setID cardNumber bonus cardTypeID world isAvatar cardName
        text rarity blueLine attrList usesList weight
    } $card break

    set cardType $CrossFire::cardTypeXRef($cardTypeID,name)
    set level 0
    set isChaseCard [expr $cardNumber > $CrossFire::setXRef($setID,setMax)]
    set worldName $CrossFire::worldXRef($world,icon)
    set rarityType $CrossFire::cardFreqName($rarity)
    set id $storage($w,size)
    set lastDigit [string range $cardNumber end end]
    set msg {}
    set cardID [lindex [CrossFire::GetCardDesc $card] 0]

    # Determine if this card is in the allowed cards list
    set allowed 0
    set allowedCards $CrossFire::deckFormat($id,allowedList)
    if {([lsearch $allowedCards $cardID] != -1) ||
	([lsearch $allowedCards "type:$cardTypeID"] != -1)} {
	set allowed 1
    }

    # Check for cards that do not exist.
    if {$cardName == "(no card)"} {
        set okToAdd 0
        set msg "This card does not exist."
    }

    # Check if card is banned via deck format.
    if {($okToAdd == 1) &&
        ([lsearch $CrossFire::deckFormat($id,bannedList) $cardID] != -1)} {
        set okToAdd 0
        set msg "$cardName is banned!"
    }

    # Check if card is in inventory.  Perform check only if user
    # wants check to be done.
    if {($okToAdd == 1) && ($storage($w,checkInv) == "Yes")} {
        set okToAdd [CheckInventory $w $card]
    }

    # Check multiple copies
    if {$okToAdd == 1} {
        set msg [CheckMultipleCards $w $card]
        if {$msg != ""} {
            set okToAdd 0
        }
    }

    # Check for cards that are not allowed to be in a deck together.
    # Basically, if the card being added is in one list, the cards in the
    # other list may not be in the deck.
    # ADDED: Now can also warn about putting cards together that really
    # do not make sense (DU/24 & IQ/48) because of unlikelyhood of use.
    if {$okToAdd == 1} {
	set check 0
	foreach {list1 list2 message mode} {
	    {NO/393 1st/393 2nd/393}
	    {DU/073}
	    {Disintigrate & Psionic Disintigration}
	    {disallow}

	    {NO/319 1st/319 2nd/319 3rd/319 4th/131}
	    {CH/072}
	    {The Caravan & Not So Fast}
	    {disallow}

	    {NO/100 1st/100 2nd/100 3rd/100 4th/120}
	    {CH/072}
	    {Good Fortune & Not So Fast}
	    {disallow}

	    {DU/024}
	    {IQ/048}
	    {The Azure Tower of Onad the Fallen & A Good Defense}
	    {warn}
	} {
	    if {[lsearch $list1 $cardID] != -1} {
		set check 1
		set checkFor $list2
	    } elseif {[lsearch $list2 $cardID] != -1} {
		set check 1
		set checkFor $list1
	    }
	    if {$check == 1} {
		set deckIDList {}
		foreach testCard $storage($w,deck) {
		    lappend deckIDList \
			[lindex [CrossFire::GetCardDesc $testCard] 0]
		}
		foreach testID $checkFor {
		    if {[lsearch $deckIDList $testID] != -1} {
			if {$mode == "disallow"} {
			    # Cards cannot be in deck together
			    set okToAdd 0
			    set msg "$message cannot be in a deck together."
			} else {
			    # Just a warning
			    set msg "$message do not work well together!"
			}
		    }
		}
		set check 0
	    }
	}
    }


    # Check for exceeding deck size. We don't need to do this test if
    # this is a Dungeon card (it doesn't count towards deck size).
    set max $CrossFire::deckFormat($id,Total,max,All)
    if {($storage($w,Total,qty,All) == $max) &&
        ($okToAdd == 1) && ($cardType != "Dungeon")} {
        set okToAdd 0
        set msg "Deck limit of $max cards reached."
    }

    # Check for exceeding limit of card type.
    set max $CrossFire::deckFormat($id,Type,max,$cardType)
    if {($storage($w,Type,qty,$cardType) >= $max) && ($okToAdd == 1)} {
        if {($max != 0) || ($allowed == 0)} {
            set okToAdd 0
            set msg "Card limit of $max for $cardType reached."
        }
    }

    # Check for exceeding limit of card set.
    if {[lsearch [CrossFire::CardSetIDList "fan"] $setID] != -1} {
        set qty $storage($w,Set,qty,FAN)
        set max $CrossFire::deckFormat($id,Set,max,FAN)
        set isFanSet 1
    } else {
        set qty $storage($w,Set,qty,$setID)
        set max $CrossFire::deckFormat($id,Set,max,$setID)
        set isFanSet 0
    }
    if {($qty >= $max) && ($okToAdd == 1)} {
        if {($max != 0) || ($allowed == 0)} {
            set okToAdd 0
            set setName $CrossFire::setXRef($setID,name)
            set msg "Set limit of $max for $setName reached."
        }
    }

    # Check for exceeding limit of card world.
    if {[lsearch $CrossFire::fanWorldIDList $world] != -1} {
        set qty $storage($w,World,qty,FAN)
        set max $CrossFire::deckFormat($id,World,max,FAN)
        set isFanWorld 1
    } else {
        set qty $storage($w,World,qty,$world)
        set max $CrossFire::deckFormat($id,World,max,$world)
        set isFanWorld 0
    }
    if {($qty >= $max) && ($okToAdd == 1)} {
        if {($max != 0) || ($allowed == 0)} {
            set okToAdd 0
            set msg "World limit of $max for $worldName reached."
        }
    }

    # Check for exceeding limit of card rarity.
    set max $CrossFire::deckFormat($id,Rarity,max,$rarity)
    if {($storage($w,Rarity,qty,$rarity) >= $max) && ($okToAdd == 1)} {
        if {($max != 0) || ($allowed == 0)} {
            set okToAdd 0
            set msg "Rarity limit of $max for $rarityType reached."
        }
    }

    # Check for exceeding limit of card digit.
    set max $CrossFire::deckFormat($id,Digit,max,$lastDigit)
    if {($storage($w,Digit,qty,$lastDigit) >= $max) && ($okToAdd == 1)} {
        if {($max != 0) || ($allowed == 0)} {
            set okToAdd 0
            set msg "Digit limit of $max for $lastDigit reached."
        }
    }

    # Since chase are not really a type, we must make a specific check
    # for exceeding chase card limits.
    if {($okToAdd == 1) && ($isChaseCard != 0) &&
        ($storage($w,Total,qty,Chase) >=
         $CrossFire::deckFormat($id,Total,max,Chase))} {
        if {($max != 0) || ($allowed == 0)} {
            set okToAdd 0
            set msg "Total number of chase cards reached."
        }
    }

    # If this is a champion, check total champion qty and level total.
    if {([lsearch $CrossFire::championList $cardTypeID] != -1) &&
        ($okToAdd == 1)} {

        if {$storage($w,Total,qty,Champions) ==
            $CrossFire::deckFormat($id,Total,max,Champions)} {
            set okToAdd 0
            set msg "Total number of champions reached."
        } else {

            set level [lindex [split $bonus "/"] 0]
            if {$level == "?"} {
                set level 0
            }
            set keepLevelList $storage($w,levelList)
            set keepAvatarList $storage($w,avatarList)

            if {$isAvatar} {
                lappend storage($w,avatarList) $level
            } else {
                lappend storage($w,levelList) $level
            }

            set testLevelTotal [CalcLevelTotal $w]
            set max $CrossFire::deckFormat($id,Total,max,Levels)
            if {$testLevelTotal > $max} {
                set storage($w,levelList) $keepLevelList
                set storage($w,avatarList) $keepAvatarList
                set okToAdd 0
                set msg "This champion will exceed the level limit of $max."
            }
        }
    }

    if {$okToAdd == 1} {

        lappend storage($w,deck) $card

        if {$cardType != "Dungeon"} {
            incr storage($w,Total,qty,All)
        } else {
            set storage($w,hasDungeon) 1
        }

        # Increase current quantity of this card set
        incr storage($w,Set,qty,$setID)
        if {$isFanSet == 1} {
            incr storage($w,Set,qty,FAN)
        }

        # Increase current quantity of this card type
        incr storage($w,Type,qty,$cardType)

        # Increase current quantity of the card's world
        incr storage($w,World,qty,$world)
        if {$isFanWorld == 1} {
            incr storage($w,World,qty,FAN)
        }

        # Increase current quantity of the card's rarity
        incr storage($w,Rarity,qty,$rarity)

        # This is a champion, increase level total and number of champions
        if {[lsearch $CrossFire::championList $cardTypeID] != -1} {
            set storage($w,Total,qty,Levels) $testLevelTotal
            incr storage($w,Total,qty,Champions)
        }

        # Add one to the chase total if this is a chase card.
        if {$isChaseCard != 0} {
            incr storage($w,Total,qty,Chase)
        }

	# Adjust the last digit totals
	incr storage($w,Digit,qty,$lastDigit)
	CalculateAverageLastDigit $w

        # Adjust all the usable cards totals
        set usesNew {}
        foreach id $usesList {
            if {[info exists CrossFire::usableCards(uses,$id)]} {
                lappend usesNew $CrossFire::usableCards(uses,$id)
            } else {
                lappend usesNew $id
            }
        }
        set usesList $usesNew
        foreach usable $usesList {
            incr storage($w,Usable,$usable)
        }

    }

    if {($okToAdd == 0) || ($msg != "")} {
	if {$okToAdd == 0} {
	    # We had an error!  Report it to the user.
	    tk_messageBox -message $msg -icon error \
		-title "Error Adding Card" -parent $w
	} else {
	    # Just a warning message
	    tk_messageBox -message $msg -icon warning \
		-title "Warning!" -parent $w
	}
    }

    return $okToAdd
}

# Editor::AddCard --
#
#   Attempts to add the selected card on the specified editor
#   toplevel to the deck.  Alerts user if no card is selected.
#   Actual adding of card is handled by AddCardToDeck.
#
# Parameters:
#   w          : Editor toplevel path name.
#
# Returns:
#   Nothing.
#
proc Editor::AddCard {w {to deck}} {

    variable storage

    set cardID ""
    if {($storage($w,selectionAt) != "textbox") &&
	($storage($w,selectionAt) != "alts")} {
        set cardID [GetSelectedCardID $w]
    } else {
        tk_messageBox -message "No Card Selected." -icon error \
            -parent $w -title "Error Adding Card"
        return
    }

    set card [CrossFire::GetCard $cardID]

    if {$to == "deck"} {
	# Only redisplay deck if we successfully add the card.
	if {[AddCardToDeck $w $card] == 1} {
	    DisplayDeck $w
	    SetChanged $w "true"
	}
    } else {
	DragAddAlt $w button $cardID
    }

    return
}

# Editor::DragAddCard --
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
proc Editor::DragAddCard {w from args} {

    variable storage

    # If we are receiving a card type group, we will add all
    # of those from one editor to another, otherwise just 
    # add the single card.
    set first [lindex $args 0]

    if {$first == ""} {
        return
    }

    set changed 0

    if {($first != "+") && ($first != "-")} {
	set card [CrossFire::GetCard $first]
	if {[AddCardToDeck $w $card]} {
	    set changed 1
	    if {$from == $storage($w,altTextBox)} {
		RemoveCardFromAlt $w $card
	    }
	}
    } else {
        set fw [winfo toplevel $from]

        set groupHeading [lrange $args 1 [expr [lsearch $args ":"] - 1]]
	if {$from == $storage($fw,altTextBox)} {
	    set cardList $storage($fw,altCards)
	} else {
	    set cardList $storage($fw,deck)
	}

        if {$storage($fw,deckDisplayMode) == "Type"} {
            if {($storage($fw,championMode) == "Champion") &&
		($groupHeading == "Champions")} {
                set testID $CrossFire::championList
            } else {
                set testID $CrossFire::cardTypeXRef($groupHeading)
            }
            set field 3
        } elseif {$storage($fw,deckDisplayMode) == "Set"} {
            set testID $CrossFire::setXRef($groupHeading)
            set field 0
        } elseif {$storage($fw,deckDisplayMode) == "Rarity"} {
            set testID $CrossFire::cardFreqXRef($groupHeading)
            set field 8
        } elseif {$storage($fw,deckDisplayMode) == "World"} {
            set testID $CrossFire::worldXRef($groupHeading)
            set field 4
        } elseif {$storage($fw,deckDisplayMode) == "Digit"} {
            set testID $groupHeading
            set field 0
	}

        foreach card $cardList {
	    set digit [string range [lindex $card 1] end end]
            if {(($storage($fw,deckDisplayMode) == "Digit") &&
		 ($digit == $testID)) ||
		[lsearch $testID [lindex $card $field]] != -1} {
		if {[AddCardToDeck $w $card]} {
		    set changed 1
		    if {$from == $storage($w,altTextBox)} {
			RemoveCardFromAlt $w $card
		    }
		}
            }
        }
    }

    if {$changed == 1} {
        SetChanged $w "true"
        DisplayDeck $w
	DisplayAltCards $w
    }

    return
}

# Editor::DragAddAlt --
#
#   Called when a card is dropped on the possible cards text box.
#
# Parameters:
#   w          : Editor toplevel
#   from       : Widget that send the cards
#   args       : Data.
#
# Returns:
#   Nothing.
#
proc Editor::DragAddAlt {w from args} {

    variable storage

    # If we are receiving a card type group, we will add all
    # of those from one editor to another, otherwise just 
    # add the single card.
    set first [lindex $args 0]

    if {$first == ""} {
        return
    }

    if {($first != "+") && ($first != "-")} {
	AddAltCard $w [CrossFire::GetCard $first]
    } else {
        set fw [winfo toplevel $from]

        set groupHeading [lrange $args 1 [expr [lsearch $args ":"] - 1]]
	if {$from == $storage($fw,altTextBox)} {
	    set cardList $storage($fw,altCards)
	} else {
	    set cardList $storage($fw,deck)
	}

        if {$storage($fw,deckDisplayMode) == "Type"} {
            if {($storage($fw,championMode) == "Champion") &&
		($groupHeading == "Champions")} {
                set testID $CrossFire::championList
            } else {
                set testID $CrossFire::cardTypeXRef($groupHeading)
            }
            set field 3
        } elseif {$storage($fw,deckDisplayMode) == "Set"} {
            set testID $CrossFire::setXRef($groupHeading)
            set field 0
        } elseif {$storage($fw,deckDisplayMode) == "Rarity"} {
            set testID $CrossFire::cardFreqXRef($groupHeading)
            set field 8
        } elseif {$storage($fw,deckDisplayMode) == "World"} {
            set testID $CrossFire::worldXRef($groupHeading)
            set field 4
        } elseif {$storage($fw,deckDisplayMode) == "Digit"} {
	    set testID $groupHeading
	    set field 0
	}

        foreach card $cardList {
	    set digit [string range [lindex $card 1] end end]
            if {(($storage($fw,deckDisplayMode) == "Digit") &&
		 ($digit == $testID)) ||
		[lsearch $testID [lindex $card $field]] != -1} {
                AddAltCard $w $card
            }
        }
    }

    if {$from == $storage($w,deckTextBox)} {
	DragRemoveCard $w $from "move"
    }

    SetChanged $w "true"
    DisplayAltCards $w

    return
}

# Editor::AddAltCard --
#
#   Adds a card to the list of possible cards.
#
# Parameters:
#   w         : Editor toplevel
#   card      : Card to add
#
# Returns:
#   Nothing.
#
proc Editor::AddAltCard {w card} {

    variable storage

    if {[lsearch $storage($w,altCards) $card] == -1} {
	lappend storage($w,altCards) $card
    } else {
	set msg "Card [CrossFire::GetCardDesc $card] is already "
	append msg "in the list of considered cards."
	tk_messageBox -parent $w -title "Problem Adding Card" \
	    -icon info -message $msg
    }

    return
}

# Editor::RemoveCardFromDeck --
#
#   Procedure that actually removes a card from the deck.
#   It also adjusts the level total and card quantities.
#
# Parameters:
#   w          : Editor toplevel path name.
#   card       : Card to remove
#
# Returns:
#   Nothing.
#
proc Editor::RemoveCardFromDeck {w card} {

    variable storage

    set pos [lsearch $storage($w,deck) $card]

    if {$pos != -1} {

        foreach {
            setID cardNumber bonus cardTypeID world isAvatar cardName
            text rarity blueLine attrList usesList weight
        } $card break

        set storage($w,deck) [lreplace $storage($w,deck) $pos $pos]
        set cardType $CrossFire::cardTypeXRef($cardTypeID,name)
        if {$bonus == "?"} {
            set bonus 0
        }

        # Decrease current quantity of card set
        incr storage($w,Set,qty,$setID) -1
        if {[lsearch [CrossFire::CardSetIDList "fan"] $setID] != -1} {
            incr storage($w,Set,qty,FAN) -1
        }

        # Decrease current quantity of card type
        incr storage($w,Type,qty,$cardType) -1

        # Decrease current quantity of the card's rarity
        incr storage($w,Rarity,qty,$rarity) -1

        # Decrease current quantity of the card's world
        incr storage($w,World,qty,$world) -1
        if {[lsearch $CrossFire::fanWorldIDList $world] != -1} {
            incr storage($w,World,qty,FAN) -1
        }

        # Remove one from the chase total if this is a chase card.
        if {$cardNumber > $CrossFire::setXRef($setID,setMax)} {
            incr storage($w,Total,qty,Chase) -1
        }

        # Dungeon cards do not count against the deck size,
        # so don't change the total number cards if this is one.
        if {$cardType != "Dungeon"} {
            incr storage($w,Total,qty,All) -1
        } else {
            set storage($w,hasDungeon) 0
        }

        # This is a champion, so we need to adjust the level
        # totals, number of champions, and remove the level
        # of this champion from the level list.
        if {([lsearch $CrossFire::championList $cardTypeID] != -1)} {

            set levelList $storage($w,levelList)
            set avatarList $storage($w,avatarList)

            incr storage($w,Total,qty,Champions) -1

            if {$isAvatar == 1} {
                set pos [lsearch $avatarList $bonus]
                set avatarList [lreplace $avatarList $pos $pos]
            } else {
                set pos [lsearch $levelList $bonus]
                set levelList [lreplace $levelList $pos $pos]
            }

            set storage($w,levelList) $levelList
            set storage($w,avatarList) $avatarList
            set storage($w,Total,qty,Levels) [CalcLevelTotal $w]
        }

	# Decrease the quantity for last digit
	set cardDigit [string range $cardNumber end end]
	incr storage($w,Digit,qty,$cardDigit) -1
	CalculateAverageLastDigit $w

        # Adjust all the usable cards totals
        set usesNew {}
        foreach id $usesList {
            if {[info exists CrossFire::usableCards(uses,$id)]} {
                lappend usesNew $CrossFire::usableCards(uses,$id)
            } else {
                lappend usesNew $id
            }
        }
        set usesList $usesNew
        foreach usable $usesList {
            incr storage($w,Usable,$usable) -1
        }

    } else {
        bell
    }

    return
}

# Editor::CalculateAverageLastDigit --
#
#   Calculates the average last digit for the deck... and many other last
#   digit calculations that may be useful!
#
# Parameters:
#   w          : Toplevel widget path
#
# Returns:
#   Nothing.
#
proc Editor::CalculateAverageLastDigit {w} {

    variable storage

    set total 0
    set gTotal 0
    foreach digit $CrossFire::cardDigitList {
        set q($digit) $storage($w,Digit,qty,$digit)
	incr total $q($digit)
	incr gTotal [expr $storage($w,Digit,qty,$digit) * $digit]
    }

    if {$total == 0} {
	set average 0
        set vorpal 0
        set ultrablast 0
        set knockdown 0
        set fates1 0
        set fates2 0
        set fates3 0
    } else {
	set average [expr $gTotal * 1.0 / $total]
        set vorpal [expr ($q(0) + $q(1) + $q(2) + $q(3)) * 100.0 / $total]
        set ultrablast [expr ($q(0) + $q(1) + $q(2)) * 100.0 / $total]
        set knockdown \
            [expr ($q(0) + $q(1) + $q(2) + $q(3) + $q(4)) * 100.0 / $total]
        set fates1 \
            [expr ($q(1) + $q(3) + $q(5) + $q(7) + $q(9)) * 100.0 / $total]
        set fates2 [expr ($q(2) + $q(4) + $q(6) + $q(8)) * 100.0 / $total]
        set fates3 [expr $q(0) * 100.0 / $total]
    }

    set storage($w,Digit,avg) [format "%0.1f" $average]
    set storage($w,Digit,vorpal) [format "%0.1f%%" $vorpal]
    set storage($w,Digit,ultrablast) [format "%0.1f%%" $ultrablast]
    set storage($w,Digit,knockdown) [format "%0.1f%%" $knockdown]
    set storage($w,Digit,fates1) [format "%0.1f%%" $fates1]
    set storage($w,Digit,fates2) [format "%0.1f%%" $fates2]
    set storage($w,Digit,fates3) [format "%0.1f%%" $fates3]

    return
}


# Editor::RemoveCardFromAlt --
#
#   Removes a card from the list of possible cards.
#
# Parameters:
#   w          : Editor toplevel
#   card       : card id to remove
#
# Returns:
#   Nothing.
#
proc Editor::RemoveCardFromAlt {w card} {

    variable storage

    set pos [lsearch $storage($w,altCards) $card]

    if {$pos != -1} {
        set storage($w,altCards) [lreplace $storage($w,altCards) $pos $pos]
    }

    return
}

# Editor::RemoveCard --
#
#   Removes the highlighted card or type of card from the deck.
#
# Parameters:
#   w          : Editor toplevel path name.
#   args       : Optional card ID, type, or set to remove.
#
# Returns:
#   Nothing.
#
proc Editor::RemoveCard {w args} {

    variable storage

    if {$args != "" && $args != "move"} {

        set first [lindex $args 0]
        if {($first == "+") || ($first == "-")} {
            set card $args
        } else {
            set card [CrossFire::GetCard $args]
        }

    } else {

        set card ""

        if {[$storage($w,cardListBox) curselection] == ""} {
            set cardID [GetSelectedCardID $w]
            if {([lindex $cardID 0] == "+") || ([lindex $cardID 0] == "-")} {
                set card $cardID
            } else {
                set card [CrossFire::GetCard $cardID]
            }
        }
    }

    if {$card == ""} {
        tk_messageBox -message "No card selected." -icon error \
            -title "Error Removing Card" -parent $w
        return
    }

    if {([lindex $card 0] == "+") || ([lindex $card 0] == "-")} {

        # Verify that the user wants to remove all of this group
	if {($storage($w,selectionAt) == "textbox") ||
            ($storage($w,selectionAt) == "alts")} {
	    set groupHeading [lrange $card 1 [expr [lsearch $card ":"] - 1]]
	} else {
	    set groupHeading [lrange $card 1 end]
	}

        if {$storage($w,deckDisplayMode) == "Type"} {
            set messagePart "of type $groupHeading"
            if {($storage($w,championMode) == "Champion") &&
		($groupHeading == "Champions")} {
                set testID $CrossFire::championList
            } else {
                set testID $CrossFire::cardTypeXRef($groupHeading)
            }
            set field 3
        } elseif {$storage($w,deckDisplayMode) == "Set"} {
            set messagePart "from the $groupHeading set"
            set testID $CrossFire::setXRef($groupHeading)
            set field 0
        } elseif {$storage($w,deckDisplayMode) == "Rarity"} {
            set messagePart "of rarity $groupHeading"
            set testID $CrossFire::cardFreqXRef($groupHeading)
            set field 8
        } elseif {$storage($w,deckDisplayMode) == "World"} {
            set messagePart "of world $groupHeading"
            set testID $CrossFire::worldXRef($groupHeading)
            set field 4
        } elseif {$storage($w,deckDisplayMode) == "Digit"} {
	    set messagePart "of digit $groupHeading"
	    set testID $groupHeading
	    set field 0
	}

	if {$args == "move"} {
	    set response "yes"
	} else {
	    set msg "Are you sure you want to remove all cards $messagePart?"
	    set response [tk_messageBox -icon question -title "Verify Remove" \
			      -message $msg -type yesno -default no -parent $w]
	}

        if {$response == "yes"} {
	    if {$storage($w,selectionAt) == "textbox"} {
		set cardList $storage($w,deck)
	    } else {
		set cardList $storage($w,altCards)
	    }
            foreach card $cardList {
		set digit [string range [lindex $card 1] end end]
		if {(($storage($w,deckDisplayMode) == "Digit") &&
		     ($digit == $testID)) ||
		    [lsearch $testID [lindex $card $field]] != -1} {
		    if {$storage($w,selectionAt) == "textbox"} {
			RemoveCardFromDeck $w $card
		    } else {
			RemoveCardFromAlt $w $card
		    }
                }
            }
        } else {
            return
        }
    } else {
	if {$storage($w,selectionAt) == "textbox"} {
	    RemoveCardFromDeck $w $card
	} else {
	    RemoveCardFromAlt $w $card
	}
    }

    SetChanged $w "true"
    DisplayDeck $w
    DisplayAltCards $w

    return
}

# Editor::DragRemoveCard --
#
#   Called when a dropped card is to be removed.  We must check the
#   'from' widget's toplevel against the the receiving, because we
#   do not want to allows removes from different editors.
#
# Parameters:
#   w          : Widget receiving the drop.
#   from       : Widget sending the data.
#   args       : Data.
#
# Returns:
#   Nothing.
#
proc Editor::DragRemoveCard {w from args} {

    # Get the toplevel name of the sender.
    set fw [winfo toplevel $from]

    if {$fw == $w} {
        eval RemoveCard $w $args
    }

    return
}

# Editor::ClickListBox --
#
#   Handles all clicking of the card selection list box.
#
# Parameters:
#   w          : Editor toplevel widget name.
#   X Y        : X and Y coordinates of the click (%X %Y)
#              : -or- m line for move to line.
#   btnNumber  : Button number pressed or 0 when called from
#                SearchListBox.
#   args       : Optional appended
#
# Returns:
#   Nothing.
#
proc Editor::ClickListBox {w X Y btnNumber args} {

    variable storage

    set lbw $storage($w,cardListBox)
    set storage($w,selectionAt) "listbox"

    # Remove selection from deck text box.
    $storage($w,deckTextBox) tag remove select 1.0 end
    $storage($w,altTextBox) tag remove select 1.0 end

    # Remove selection from deck differ text box.
    if {[winfo exists $storage($w,diffTextBox)]} {
        $storage($w,diffTextBox) tag remove select 1.0 end
    }

    CrossFire::ClickListBox $w $lbw $X $Y

    set tempID [GetSelectedCardID $w]
    if {$tempID != ""} {
	if {$storage($w,embedCardView) == "Yes"} {
	    ViewCard::UpdateCardView $storage($w,cardFrame) \
		[CrossFire::GetCard $tempID]
	} elseif {($Config::config(ViewCard,mode) == "Continuous")} {
	    ViewCard::View $w $tempID
	}
    }

    # Do various activities depending which button was pressed.
    switch -- $btnNumber {
        1 {
            # Start the drag-n-drop routines.
            CrossFire::StartDrag $lbw plus AddCard $tempID
        }

        2 {
            AddCard $w
        }

        3 {
            # Pop-up Menu
            tk_popup $w.addMenu $X $Y
        }
    }

    return
}

# Editor::ClickTextBox --
#
#   Adds a highlight bar to the line clicked on in a text box.
#   This is made to resemble a list box.
#
# Parameters:
#   w          : Toplevel of the editor.
#   X Y        : Coordinates clicked. (%X %Y)
#              : -or- m line for move to line.
#   btnNumber  : Button number pressed.
#   args       : Optionally appended differ from deck differ.
#
# Returns:
#   Nothing.
#
proc Editor::ClickTextBox {w X Y btnNumber {whom textbox}} {

    variable storage

    set storage($w,selectionAt) $whom

    # Set text widget and clear select from others
    if {$whom == "differ"} {
        set tw $storage($w,diffTextBox)
        $storage($w,deckTextBox) tag remove select 1.0 end
	$storage($w,altTextBox) tag remove select 1.0 end
    } elseif {$whom == "alts"} {
        set tw $storage($w,altTextBox)
        $storage($w,deckTextBox) tag remove select 1.0 end
        if {[winfo exists $storage($w,diffTextBox)]} {
            $storage($w,diffTextBox) tag remove select 1.0 end
        }
    } else {
        set tw $storage($w,deckTextBox)
	$storage($w,altTextBox) tag remove select 1.0 end
        if {[winfo exists $storage($w,diffTextBox)]} {
            $storage($w,diffTextBox) tag remove select 1.0 end
        }
    }

    $storage($w,cardListBox) selection clear 0 end

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

        # We only want to adjust focus if this was an actual click
        # on the deck box.
        if {$whom != "differ"} {
            focus $w
        }

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

    set tempID [GetSelectedCardID $w]
    set first [lindex $tempID 0]

    # First == "" when textbox is from the differ and the selection is
    # on the Deck 1 or Deck 2 label. Nothing else to do, so bail out.
    if {$first == ""} return

    if {($first != "+") && ($first != "-")} {
	if {$storage($w,embedCardView) == "Yes"} {
	    ViewCard::UpdateCardView $storage($w,cardFrame) \
		[CrossFire::GetCard $tempID]
	} elseif {($Config::config(ViewCard,mode) == "Continuous")} {
	    ViewCard::View $w $tempID
	}
    }

    # Do various activities depending which button was pressed.
    switch -- $btnNumber {
        1 {
            # Start the drag-n-drop routines.
            if {$whom != "differ"} {
                CrossFire::StartDrag $tw target RemoveCard $tempID
            } else {
                CrossFire::StartDrag $tw plus AddCard $tempID
            }
        }

        2 {
            if {$whom != "differ"} {
                RemoveCard $w
            } else {
		AddCard $w
            }
        }

        3 {
            # Pop-up Menu
            if {$whom != "differ"} {
                set cardID [lindex [GetSelectedCardID $w] 0]

                if {$cardID == "-"} {
                    set menu $w.collapseMenu
                } elseif {$cardID == "+"} {
                    set menu $w.expandMenu
                } else {
                    set menu $w.removeMenu
                }
            } else {
                set menu $w.addMenu
            }

            tk_popup $menu $X $Y
        }
    }

    return
}

# Editor::DoubleClickTextBox --
#
#   Displays a card or expands/collapses a group type.
#
# Parameters:
#   w          : Toplevel of the editor.
#
# Returns:
#   Nothing.
#
proc Editor::DoubleClickTextBox {w} {

    variable storage

    set cardID [GetSelectedCardID $w]
    set first [lindex $cardID 0]

    if {($first == "-") || ($first == "+")} {
        set cPos [lsearch $cardID ":"]
        set heading [lrange $cardID 1 [expr $cPos - 1]]
	if {$storage($w,selectionAt) == "textbox"} {
	    set v "expand"
	} else {
	    set v "expandAlt"
	}

	set mode $storage($w,deckDisplayMode)
	if {$mode == "Set"} {
	    set heading $CrossFire::setXRef($heading)
	} elseif {$mode == "Rarity"} {
	    set heading $CrossFire::cardFreqXRef($heading)
	} elseif {$mode == "World"} {
	    set heading $CrossFire::worldXRef($heading)
	}

        if {$first == "-"} {
            set storage($w,$mode,$v,$heading) 0
        } else {
            set storage($w,$mode,$v,$heading) 1
        }

	if {$storage($w,selectionAt) == "textbox"} {
	    DisplayDeck $w
	} else {
	    DisplayAltCards $w
	}
    } else {
        ViewCard::View $w $cardID
    }

    return
}

# Editor::Navigate --
#
#   Implements keyboard navigation of the editor.
#
# Parameters:
#   w          : Editor toplevel.
#   pos        : Position to move to (home, end, up, down, +/-x)
#
# Returns:
#   Nothing.
#
proc Editor::Navigate {w pos} {

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

    # Change the navigation back to the main listbox if it was at the
    # deck differ and that toplevel has been destroyed.
    if {($selectionAt == "differ") &&
        ([winfo exists $storage($w,diffTextBox)] == 0)} {
        set storage($w,selectionAt) "listbox"
        set selectionAt "listbox"
    }

    # Only allow add from either the card selection box or deck differ
    if {$pos == "add"} {
        if {$selectionAt != "textbox"} {
            AddCard $w
        }
        return
    }

    # Only allow remove from the deck and alts text boxes.
    if {$pos == "remove"} {
        if {$selectionAt == "textbox" || $selectionAt == "alts"} {
            RemoveCard $w
        }
        return
    }

    # Send the move command to the appropriate procedure depending
    # on which widget currently has the "focus".
    if {$selectionAt == "listbox"} {
        ClickListBox $w m $pos 0
    } elseif {$selectionAt == "differ"} {
        ClickTextBox $w m $pos 0 differ
    } elseif {$selectionAt == "alts"} {
	ClickTextBox $w m $pos 0 alts
    } else {
        ClickTextBox $w m $pos 0
    }

    return
}

# Editor::IncrCardSet --
#
#   Changes the selected card set.
#
# Parameters:
#   w          : Editor toplevel.
#   delta      : Amount to change set by.
#
# Returns:
#   Nothing.
#
proc Editor::IncrCardSet {w delta} {

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

# Editor::ViewCard --
#
#   Views the currently selected card.
#
# Parameters:
#   w          : Editor toplevel.
#
# Returns:
#   Nothing.
#
proc Editor::ViewCard {w} {

    ViewCard::View $w [GetSelectedCardID $w]

    return
}

