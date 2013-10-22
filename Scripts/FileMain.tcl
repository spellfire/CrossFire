# FileMain.tcl 20040715
#
# This file contains all the GUI procedures for the Card Warehouse.
#
# Copyright (c) 1998-2004 Dan Curtiss. All rights reserved.
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

namespace eval Inventory {

    variable windowTitle "Card Warehouse"
    variable invCount 0    ;# Counter for creating new toplevels.

    # Array to hold various info about each inventory window.
    # Format: (widget,index).
    # Indicies:
    #   fileName    : Current working file.
    #   reportFormat: Format of report. (HTML, Verbose, Brief)
    #   listDisplayMode : List display mode. Defined in Config.tcl.
    #   change      : Boolean for if change has been made.
    #   cardSet     : Current card set.
    #   cardListBox : Widget name of the card list box.
    #   max         : Maximum number wanted of card.
    #   qty         : Current quantity of card.
    #   qtyReg      : Desired max quantity of regular cards.
    #   qtyChase    : Desired max quantity of chase cards.
    #   inv*        : Inventory for each set. * = 1st, AR, BR, etc.
    #   countMin    : Minimum number of card counted.
    #   countMax    : Maximum number of card counted.
    #   countTotal  : Total number of cards counted.    
    variable invConfig

}

# Inventory::SetChanged --
#
#   Changes the boolean flag for if an inventory has changed.
#   Adjusts the title of the window; adds a '*' indicating
#   that a change has been made.
#
# Parameters:
#   w          : Inventory toplevel.
#   bool       : Boolean (true or false). Need to save?
#
# Returns:
#   Nothing.
#
proc Inventory::SetChanged {w bool} {

    variable invConfig
    variable windowTitle

    set invConfig($w,change) $bool
    set sfn [file tail $invConfig($w,fileName)]

    if {[info exists invConfig($w,autoSaveAfterID)]} {
        after cancel $invConfig($w,autoSaveAfterID)
        unset invConfig($w,autoSaveAfterID)
    }

    if {$sfn != ""} {
        set sfn "- $sfn "
    }

    set title "$windowTitle $sfn"
    if {$bool == "true"} {
        wm title $w "${title}*"
        if {$Config::config(Warehouse,autoSave) == "Yes"} {
            if {$Config::config(Warehouse,autoSaveTime) > 0} {
                set delayTime \
                    [expr $Config::config(Warehouse,autoSaveTime) * 60000]
                set invConfig($w,autoSaveAfterID) \
                    [after $delayTime "Inventory::SaveInv $w"]
            }
        }
    } else {
        wm title $w $title
    }

    return
}

# Inventory::Create --
#
#   Incrementally creates a new inventory toplevel.
#
# Parameters:
#   args       : Optional inventory file to open.
#
# Returns:
#   The path name of the toplevel.
#
proc Inventory::Create {args} {

    variable invConfig
    variable invCount
    variable infFileTypes
    variable windowTitle

    set w .inventory[incr invCount]
    CrossFire::Register Warehouse $w

    set invConfig($w,fileName) ""
    set invConfig($w,selCardID) 0
    set invConfig($w,selCardType) $CrossFire::cardTypeXRef(0,name)
    set invConfig($w,reportFormat) $Config::config(Warehouse,reportFormat)
    set invConfig($w,change) "false"
    set invConfig($w,allSetsList) $Config::config(Warehouse,setIDList)
    set invConfig($w,listDisplayMode) \
        $Config::config(Warehouse,listDisplayMode)
    set invConfig($w,embedCardView) $Config::config(Warehouse,embedCardView)
    set invConfig($w,cardFrame) ""

    if {[file exists $Config::config(Warehouse,invDir)]} {
        set invConfig($w,invDir) $Config::config(Warehouse,invDir)
    } else {
        set invConfig($w,invDir) [file join $CrossFire::homeDir "Inventory"]
    }

    if {[file exists $Config::config(Warehouse,reportDir)]} {
        set invConfig($w,reportDir) $Config::config(Warehouse,reportDir)
    } else {
        set invConfig($w,reportDir) [file join $CrossFire::homeDir "Reports"]
    }

    set invConfig($w,cardSet) [lindex $invConfig($w,allSetsList) 0]

    toplevel $w
    wm title $w $windowTitle

    # Trap closing window from window manager methods.
    wm protocol $w WM_DELETE_WINDOW "Inventory::ExitInv $w"

    AddMenuBar $w

    bind $w <Key-comma> "Inventory::IncrCardSet $w -1"
    bind $w <Key-period> "Inventory::IncrCardSet $w 1"

    # Card Set Selection text box
    set invConfig($w,cardSetSel) $w.setList
    CrossFire::CreateCardSetSelection $invConfig($w,cardSetSel) "realAll" \
        "Inventory::SetCardSet $w setList"

    # List of cards in the set.
    frame $w.cardList

    frame $w.cardList.list
    listbox $w.cardList.list.lb -selectmode multiple -width 30 -height 20 \
        -background white -foreground black -selectbackground blue \
        -selectforeground white -selectborderwidth 0 \
        -exportselection 0 -takefocus 0 \
        -yscrollcommand "CrossFire::SetScrollBar $w.cardList.list.sb"
    scrollbar $w.cardList.list.sb -command "$w.cardList.list.lb yview" \
         -takefocus 0
    grid $w.cardList.list.lb -sticky nsew
    grid columnconfigure $w.cardList.list 0 -weight 1
    grid rowconfigure $w.cardList.list 0 -weight 1

    frame $w.cardList.search
    label $w.cardList.search.label -text "Search: " -bd 0
    entry $w.cardList.search.entry -background white -foreground black \
        -takefocus 0
    bind $w.cardList.search.entry <$CrossFire::accelBind-v> \
        "Inventory::ViewCard $w; break"
    pack $w.cardList.search.entry -side right -expand 1 -fill x
    pack $w.cardList.search.label -side left
    CrossFire::InitSearch $w $w.cardList.search.entry \
        $w.cardList.list.lb Inventory

    set lbw $w.cardList.list.lb
    set invConfig($w,cardListBox) $lbw
    bind $lbw <B1-Leave> break
    bind $lbw <Shift-Button-1> "Inventory::SelectMultiple $w %X %Y"
    bind $lbw <Control-Button-1> "Inventory::ToggleSelection $w %X %Y"
    bind $w <Control-a> "$lbw selection set 0 end"
    CrossFire::InitListBox $w $lbw Inventory

    grid $w.cardList.list -sticky nsew
    grid $w.cardList.search -sticky nsew -pady 3
    grid columnconfigure $w.cardList 0 -weight 1
    grid rowconfigure $w.cardList 0 -weight 1

    button $w.inv -text "Inventory" -underline 0 -width 10 \
        -command "Inventory::Report $w inv" -takefocus 0
    button $w.wants -text "Wants" -underline 0 -width 10 \
        -command "Inventory::Report $w want" -takefocus 0
    button $w.extras -text "Extras" -underline 0 -width 10 \
        -command "Inventory::Report $w extra" -takefocus 0
    checkbutton $w.premium -text "Premium" -anchor w -takefocus 0 \
        -variable Inventory::invConfig($w,premium) \
        -command "Inventory::ChangeInv $w premium 0"

    frame $w.wanted
    label $w.wanted.maxl -text "Wanted:" -width 8 -anchor w
    entry $w.wanted.maxe -width 3 -justify right \
        -textvariable Inventory::invConfig($w,max)
    set invConfig($w,maxWidget) $w.wanted.maxe
    bind $w.wanted.maxe <Key-Return> "Inventory::ChangeInv $w max 0 move"
    bindtags $w.wanted.maxe "$w.wanted.maxe Entry"
    button $w.wanted.maxInc -text "+" -takefocus 0 \
        -command "Inventory::ChangeInv $w max 1"
    button $w.wanted.maxDec -text "-" -takefocus 0 \
        -command "Inventory::ChangeInv $w max -1"
    grid $w.wanted.maxl $w.wanted.maxe -sticky ew
    grid $w.wanted.maxDec $w.wanted.maxInc -padx 5 -pady 5

    frame $w.qty
    label $w.qty.qtyl -text "On Hand:" -width 8 -anchor w
    entry $w.qty.qtye -width 3 -justify right \
        -textvariable Inventory::invConfig($w,qty)
    set invConfig($w,qtyWidget) $w.qty.qtye
    bind $w.qty.qtye <Key-Return> "Inventory::ChangeInv $w qty 0 move"
    bindtags $w.qty.qtye "$w.qty.qtye Entry"
    button $w.qty.qtyInc -text "+" -takefocus 0 \
        -command "Inventory::ChangeInv $w qty 1"
    button $w.qty.qtyDec -text "-" -takefocus 0 \
        -command "Inventory::ChangeInv $w qty -1"
    grid $w.qty.qtyl   $w.qty.qtye   -sticky ew
    grid $w.qty.qtyDec $w.qty.qtyInc -padx 5 -pady 5

    frame $w.weight
    label $w.weight.l -text "Value:" -width 8 -anchor w
    entry $w.weight.e -width 3 -justify right -takefocus 0 \
        -textvariable Inventory::invConfig($w,weight)
    set invConfig($w,weightWidget) $w.weight.e
    bind $w.weight.e <Key-Return> "Inventory::ChangeInv $w weight 0 move"
    bindtags $w.weight.e "$w.weight.e Entry"
    grid $w.weight.l $w.weight.e -sticky ew
    grid columnconfigure $w.weight 1 -weight 1

    # Optional embedded card viewer
    if {$invConfig($w,embedCardView) == "Yes"} {
	frame $w.cardView
	set invConfig($w,cardFrame) [ViewCard::CreateCardView $w.cardView.cv]
	grid $w.cardView.cv -sticky nsew -padx 5 -pady 5
	grid rowconfigure $w.cardView 0 -weight 1
	grid columnconfigure $w.cardView 0 -weight 1
	grid $w.cardView -column 4 -row 0 -sticky nsew -rowspan 7
	grid columnconfigure $w 4 -weight 2
    }

    # These are several helpful key bindings to
    # adjust the on hand quantities.
    bind $w <Key-Right>  "Inventory::ChangeInv $w qty 1"
    bind $w <Key-KP_Add> "Inventory::ChangeInv $w qty 1"
    bind $w <Key-plus>   "Inventory::ChangeInv $w qty 1"
    bind $w <Key-equal>  "Inventory::ChangeInv $w qty 1"

    bind $w <Key-Left>   "Inventory::ChangeInv $w qty -1"
    bind $w <Key-minus>  "Inventory::ChangeInv $w qty -1"
    bind $w <Key-KP_Subtract> "Inventory::ChangeInv $w qty -1"

    grid $w.setList -row 0 -column 0 -sticky nsew -padx 5 -pady 5 -rowspan 7
    grid $w.cardList -row 0 -column 1 -sticky nsew -padx 5 -pady 5 -rowspan 7
    grid $w.inv     -row 0 -column 2 -sticky ew   -padx 5 -pady 3
    grid $w.wants   -row 1 -column 2 -sticky ew   -padx 5 -pady 3
    grid $w.extras  -row 2 -column 2 -sticky ew   -padx 5 -pady 3
    grid $w.premium -row 3 -column 2 -sticky ew   -padx 5 -pady 3
    grid $w.wanted  -row 4 -column 2 -sticky nsew -padx 5 -pady 3
    grid $w.qty     -row 5 -column 2 -sticky nsew -padx 5 -pady 3
    grid $w.weight  -row 6 -column 2 -sticky ew   -padx 5 -pady 3
    grid columnconfigure $w 0 -weight 1
    grid columnconfigure $w 1 -weight 3
    grid rowconfigure $w {0 1 2 3 4 5 6} -weight 1

    SetChanged $w "false"

    if {$args == ""} {
        OpenInv $w "default"
    } else {
        if {[OpenInv $w [lindex $args 0] "nocomplain"] == 0} {
            ExitInv $w
            return
        }
    }

    wm deiconify $w
    raise $w

    if {$CrossFire::platform == "windows"} {
        focus $w
    }

    return $w
}

# Inventory::AddMenuBar --
#
#   Creates the menubar for the inventory and sets up the
#   accelerator key bindings for the commands.
#
# Parameters:
#   w          : Toplevel of the new inventory window.
#
# Returns:
#   Nothing.
#
proc Inventory::AddMenuBar {w} {

    variable invConfig

    menu $w.menubar

    $w.menubar add cascade \
        -label "File" \
        -underline 0 \
        -menu $w.menubar.file

    menu $w.menubar.file -tearoff 0
    $w.menubar.file add command \
        -label "New" \
        -underline 2 \
        -accelerator "$CrossFire::accelKey-N" \
        -command "Inventory::NewInv $w"
    $w.menubar.file add command \
        -label "Open..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+O" \
        -command "Inventory::OpenInv $w"
    $w.menubar.file add command \
        -label "Save" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+S" \
        -command "Inventory::SaveInv $w"
    $w.menubar.file add command \
        -label "Save As..." \
        -underline 5 \
        -command "Inventory::SaveInvAs $w"

    $w.menubar.file add separator
    $w.menubar.file add cascade \
        -label "Deck" \
        -underline 0 \
        -menu $w.menubar.file.deck
    menu $w.menubar.file.deck -tearoff 0
    $w.menubar.file.deck add command \
        -label "Remove from Inventory" \
        -underline 0 \
        -command "Inventory::ConstructDeck $w"
    $w.menubar.file.deck add command \
        -label "Add to Inventory" \
        -underline 0 \
        -command "Inventory::DismantleDeck $w"

    $w.menubar.file add separator
    $w.menubar.file add cascade \
        -label "Import" \
        -underline 0 \
        -menu $w.menubar.file.import

    menu $w.menubar.file.import -tearoff 0
    $w.menubar.file.import add command \
        -label "Spellfire Collector" \
        -underline 0 \
        -command "Inventory::Import $w SFC"
    $w.menubar.file.import add command \
        -label "Spellfire Database v2.x" \
        -underline 10 \
        -command "Inventory::Import $w SFDB2.0"
    $w.menubar.file.import add separator
    $w.menubar.file.import add command \
        -label "Card Values" \
        -underline 5 \
        -command "Inventory::Import $w CFV"

    $w.menubar.file add cascade \
        -label "Export" \
        -underline 0 \
        -menu $w.menubar.file.export

    menu $w.menubar.file.export -tearoff 0
    $w.menubar.file.export add command \
        -label "Spellfire Collector" \
        -underline 0 \
        -command "Inventory::Export $w SFC"
    $w.menubar.file.export add command \
        -label "Spellfire Database v2.x" \
        -underline 10 \
        -command "Inventory::Export $w SFDB2.0"
    $w.menubar.file.export add separator
    $w.menubar.file.export add command \
        -label "Card Values" \
        -underline 5 \
        -command "Inventory::Export $w CFV"

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
        -command "Inventory::ExitInv $w"

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
                -variable Inventory::invConfig($w,selCardType) \
                -command "Inventory::ChangeCardType $w $cardTypeID"
        }
    }

    $w.menubar.card add separator
    $w.menubar.card add command \
        -label "View" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+V" \
        -command "Inventory::ViewCard $w"


    $w.menubar add cascade \
        -label "Report" \
        -underline 0 \
        -menu $w.menubar.report

    menu $w.menubar.report -tearoff 0
    $w.menubar.report add command \
        -label "Inventory" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey-I" \
        -command "Inventory::Report $w inv"
    $w.menubar.report add command \
        -label "Wanted Cards" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey-W" \
        -command "Inventory::Report $w want"
    $w.menubar.report add command \
        -label "Extra Cards" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey-E" \
        -command "Inventory::Report $w extra"
    $w.menubar.report add separator
    $w.menubar.report add cascade \
        -label "Format" \
        -underline 0 \
        -menu $w.menubar.report.type

    menu $w.menubar.report.type -tearoff 0
    $w.menubar.report.type add radiobutton \
        -label "Full" \
        -underline 0 \
        -variable Inventory::invConfig($w,reportFormat)
    $w.menubar.report.type add radiobutton \
        -label "Verbose" \
        -underline 0 \
        -variable Inventory::invConfig($w,reportFormat)
    $w.menubar.report.type add radiobutton \
        -label "Brief" \
        -underline 0 \
        -variable Inventory::invConfig($w,reportFormat) 
    $w.menubar.report.type add radiobutton \
        -label "HTML Tables" \
        -underline 0 \
        -variable Inventory::invConfig($w,reportFormat) \
        -value "HTML"

    $w.menubar.report add cascade \
        -label "Display Method" \
        -underline 0 \
        -menu $w.menubar.report.mode

    menu $w.menubar.report.mode -tearoff 0
    foreach displayMode $Config::displayModes(list) {
        set displayModeText $Config::displayModes($displayMode)
        $w.menubar.report.mode add radiobutton \
            -label $displayModeText -value $displayMode \
            -variable Inventory::invConfig($w,listDisplayMode)
    }

    $w.menubar add cascade \
        -label "Utilities" \
        -underline 0 \
        -menu $w.menubar.utility

    menu $w.menubar.utility -tearoff 0
    $w.menubar.utility add command \
        -label "Card Counter" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey-K" \
        -command "Inventory::CardCounter $w"
    $w.menubar.utility add command \
        -label "Change Wanted Quantity" \
        -underline 12 \
        -accelerator "$CrossFire::accelKey-U" \
        -command "Inventory::SetMaxQty $w"
    $w.menubar.utility add command \
        -label "Change Multiple Card Quantities" \
        -underline 7 \
        -accelerator "$CrossFire::accelKey-M" \
        -command "Inventory::ChangeMultipleCardsGUI $w"
    $w.menubar.utility add separator
    $w.menubar.utility add command \
        -label "Configure..." \
        -underline 0 \
        -command "Config::Create Warehouse"

    $w.menubar add cascade \
        -label "Help" \
        -underline 0 \
        -menu $w.menubar.help

    menu $w.menubar.help -tearoff 0
    $w.menubar.help add command \
        -label "Help..." \
        -underline 0 \
        -accelerator "F1" \
        -command "CrossFire::Help cw_main.html"
    $w.menubar.help add separator
    $w.menubar.help add command \
        -label "About Card Warehouse..." \
        -underline 0 \
        -command "Inventory::About $w"

    $w config -menu $w.menubar

    bind $w <Key-F1> "CrossFire::Help cw_main.html"
    bind $w <Key-Help> "CrossFire::Help cw_main.html"

    if {$CrossFire::platform == "macintosh"} {
        bind $w <Command-q> "Inventory::ExitInv $w"
    } else {
        bind $w <Meta-x> "Inventory::ExitInv $w"
        bind $w <Alt-F4> "Inventory::ExitInv $w; break"
    }

    bind $w <$CrossFire::accelBind-o> "Inventory::OpenInv $w"
    bind $w <$CrossFire::accelBind-s> "Inventory::SaveInv $w"
    bind $w <$CrossFire::accelBind-i> "Inventory::Report $w inv"
    bind $w <$CrossFire::accelBind-w> "Inventory::Report $w want"
    bind $w <$CrossFire::accelBind-e> "Inventory::Report $w extra"
    bind $w <$CrossFire::accelBind-t> "Inventory::Compare $w"
    bind $w <$CrossFire::accelBind-n> "Inventory::NewInv $w"
    bind $w <$CrossFire::accelBind-u> "Inventory::SetMaxQty $w"
    bind $w <$CrossFire::accelBind-k> "Inventory::CardCounter $w"
    bind $w <$CrossFire::accelBind-m> "Inventory::ChangeMultipleCardsGUI $w"
    bind $w <$CrossFire::accelBind-v> "Inventory::ViewCard $w"

    # menus for right click on card in listbox
    menu $w.popupMenu -tearoff 0
    $w.popupMenu add command -label " Increase On Hand" \
        -command "Inventory::ChangeInv $w qty 1"
    $w.popupMenu add command -label " Decrease On Hand" \
        -command "Inventory::ChangeInv $w qty -1"
    $w.popupMenu add separator
    $w.popupMenu add command -label " Increase Wanted" \
        -command "Inventory::ChangeInv $w max 1"
    $w.popupMenu add command -label " Decrease Wanted" \
        -command "Inventory::ChangeInv $w max -1"
    $w.popupMenu add separator
    $w.popupMenu add command -label " View" \
        -command "Inventory::ViewCard $w"

    return
}

# Inventory::AddCardSetMenu --
#
#   Adds or replaces the card set menu.
#
# Parameters:
#   w          : Toplevel widget.
#
# Returns:
#   Nothing.
#
proc Inventory::AddCardSetMenu {w} {

    variable invConfig

    CrossFire::CreateCardSetMenu $invConfig($w,cardSetMenu) "real" \
        Inventory::invConfig($w,cardSet) "Inventory::SetCardSet $w menu"

    return
}


# Inventory::UpdateQtyView --
#
#   Updates the quantities and premium status for the last
#   clicked on card.
#
# Parameters:
#   w          : Inventory toplevel.
#
# Returns:
#   Nothing.
#
proc Inventory::UpdateQtyView {w} {

    variable invConfig

    set itemNum $invConfig($w,lastClickAt)
    set cardInfo [$invConfig($w,cardListBox) get $itemNum]

    # Get the inventory information for the selected card and display it.
    if {[lindex $cardInfo 1] == "(no"} {
        set invConfig($w,max) "NA"
        set invConfig($w,qty) "NA"
        set invConfig($w,premium) 0
        set invConfig($w,weight) "NA"
    } else {
        set cardInfo [CrossFire::DecodeShortID [lindex $cardInfo 0]]
        set cardSet [lindex $cardInfo 0]
        set cardNumber [lindex $cardInfo 1]
        set invInfo [lindex $invConfig($w,inv$cardSet) $cardNumber]
        set invConfig($w,max) [lindex $invInfo 0]
        set invConfig($w,qty) [lindex $invInfo 1]
        set invConfig($w,premium) [lindex $invInfo 2]
    }
}

# Inventory::ClickListBox --
#
#   Highlight a card on the card selection listbox.
#
# Parameters:
#   w          : Inventory toplevel.
#   X, Y       : %X and %Y coordinates of mouse click.
#   btnNumber  : Button number pressed or 0 when moving.
#
# Returns:
#   Nothing.
#
proc Inventory::ClickListBox {w X Y btnNumber} {

    variable invConfig

    set lbw $invConfig($w,cardListBox)
    set itemNum [CrossFire::ClickListBox $w $lbw $X $Y]
    set invConfig($w,lastClickAt) $itemNum
    set cardInfo [$lbw get $itemNum]

    # Get the inventory information for the selected card and display it.
    if {([lindex $cardInfo 1] == "(no") || ($cardInfo == "")} {
        set invConfig($w,max) "NA"
        set invConfig($w,qty) "NA"
        set invConfig($w,premium) 0
        set invConfig($w,weight) "NA"
        return
    }

    set tempID [lindex $cardInfo 0]
    set cardInfo [CrossFire::DecodeShortID $tempID]
    set cardSet [lindex $cardInfo 0]
    set cardNumber [lindex $cardInfo 1]
    set invInfo [lindex $invConfig($w,inv$cardSet) $cardNumber]
    set invConfig($w,max) [lindex $invInfo 0]
    set invConfig($w,qty) [lindex $invInfo 1]
    set invConfig($w,premium) [lindex $invInfo 2]
    set invConfig($w,weight) [lindex $invInfo 3]

    if {$invConfig($w,embedCardView) == "Yes"} {
	ViewCard::UpdateCardView $invConfig($w,cardFrame) \
	    [CrossFire::GetCard $tempID]
    } elseif {$Config::config(ViewCard,mode) == "Continuous"} {
        ViewCard::View $w $cardSet $cardNumber
    }

    # Do various activities depending on which button was pressed.
    switch -- $btnNumber {
        2 {
            ViewCard::View $w $cardSet $cardNumber
        }

        3 {
            # Pop-up Menu
            tk_popup $w.popupMenu $X $Y
        }
    }

    return
}

# Inventory::SelectMultiple --
#
#   Adds the selection from the last clicked on card to the current
#   clicked card.  Called from shift-button-1 binding.  Allows for
#   multiple card selection.
#
# Parameters:
#   w          : Inventory toplevel.
#   X, Y       : X,Y coordinates of the click from %X %Y
#
# Returns:
#   Nothing.
#
proc Inventory::SelectMultiple {w X Y} {

    variable invConfig

    set lbw $invConfig($w,cardListBox)
    set line [$lbw nearest [expr [winfo pointery $lbw] \
                                - [winfo rooty $lbw]]]
    $lbw selection clear 0 end
    $lbw select set $line $invConfig($w,lastClickAt)
    set invConfig($w,lastClickAt) $line
    UpdateQtyView $w

    return
}

# Inventory::ToggleSelection --
#
#   Toggles the selection at the clicked line.  This is called from
#   control-button-1 binding.  Allows for multiple card selection.
#
# Parameters:
#   w          : Inventory toplevel.
#   X, Y       : X,Y coordinates of the click from %X %Y
#
# Returns:
#   Nothing.
#
proc Inventory::ToggleSelection {w X Y} {

    variable invConfig

    set lbw $invConfig($w,cardListBox)
    set line [$lbw nearest [expr [winfo pointery $lbw] \
                                - [winfo rooty $lbw]]]

    if {[lsearch [$lbw curselection] $line] > -1} {
        # Deselect the card
        $lbw selection clear $line

        # Check if no cards are selected.
        if {[llength [$lbw curselection]] == 0} {
            set invConfig($w,max) ""
            set invConfig($w,qty) ""
            set invConfig($w,premium) 0
            set invConfig($w,weight) ""
        }

    } else {
        # Select the card
        $lbw selection set $line
        set invConfig($w,lastClickAt) $line
        UpdateQtyView $w
    }

    return
}

# Inventory::IncrCardSet --
#
#   Changes the selected card set.
#
# Parameters:
#   w          : Inventory toplevel.
#   delta      : Amount to change set by.
#
# Returns:
#   Nothing.
#
proc Inventory::IncrCardSet {w delta} {

    variable invConfig

    set setList [CrossFire::CardSetIDList "real"]
    set last [expr [llength $setList] - 1]
    set index [lsearch $setList $invConfig($w,cardSet)]

    incr index $delta

    if {$index < 0} {
        set index 0
    }
    if {$index > $last} {
        set index $last
    }

    set newSet [lindex $setList $index]

    if {$newSet != $invConfig($w,cardSet)} {
        set invConfig($w,cardSet) $newSet
        SetCardSet $w "menu"
    }

    return
}

# Inventory::SetCardSet --
#
#   Changes the selected set of cards.
#
# Parameter:
#    w        : Inventory toplevel.
#
# Returns:
#    Nothing.
#
proc Inventory::SetCardSet {w from args} {

    variable invConfig

    # Change cursor to busy
    $w configure -cursor watch
    update

    set lbw $invConfig($w,cardListBox)
    $lbw delete 0 end

    if {$from == "menu"} {
        CrossFire::ClickCardSetSelection $invConfig($w,cardSetSel) \
            "m" $invConfig($w,cardSet)
    } elseif {$from == "setList"} {
        # Clicked on the set list
        set invConfig($w,cardSet) $args
    }

    if {$invConfig($w,cardSet) == "All"} {
        foreach setID [CrossFire::CardSetIDList "real"] {
            if {[lsearch $invConfig($w,allSetsList) $setID] != -1} {
                CrossFire::ReadCardDataBase $setID
                CrossFire::CardSetToListBox $CrossFire::cardDataBase \
                    $lbw $invConfig($w,selCardID) "append"
            }
        }
    } else {
        foreach setID $invConfig($w,cardSet) {
            CrossFire::ReadCardDataBase $setID
            CrossFire::CardSetToListBox $CrossFire::cardDataBase \
                $lbw $invConfig($w,selCardID) "append"
        }
    }

    ClickListBox $w m 0 0
    $w configure -cursor {}

    return
}

# Inventory::ChangeCardType --
#
#   Changes the card type to view in the selection box.
#
# Parameters:
#   w          : Inventory toplevel widget name.
#   typeID     : Numeric ID of the card type.
#
# Returns:
#   Nothing.
#
proc Inventory::ChangeCardType {w typeID} {

    variable invConfig

    set invConfig($w,selCardID) $typeID
    SetCardSet $w changeType

    return
}

# Inventory::ExitInv --
#
#   Gracefully closes the specified Inventory.  Checks if
#   the inventory needs to be saved before closing.
#
# Parameters:
#   w          : Widget name of the Inventory.
#
# Returns:
#   Returns 0 if exiting or -1 if exit canceled.
#
proc Inventory::ExitInv {w} {

    variable invConfig

    if {[CheckForSave $w] == 0} {
        destroy $w

        UnLockFile $w

        if {[info exists invConfig($w,autoSaveAfterID)]} {
            after cancel $invConfig($w,autoSaveAfterID)
        }

        # Unset all the variables for the inventory.
        foreach name [array names invConfig "${w},*"] {
            unset invConfig($name)
        }

        ViewCard::CleanUpCardViews $w
        CrossFire::UnRegister Warehouse $w

        return 0
    } else {
        return -1
    }
}

# Inventory::NewInv --
#
#   Creates a new inventory.  Checks if save needed first.
#   Calls New to actually create the new inventory.
#
# Parameters:
#   w          : Inventory toplevel.
#
# Returns:
#   Nothing.
#
proc Inventory::NewInv {w} {

    variable invConfig

    if {[CheckForSave $w] == -1} {
        return
    }

    New $w
    SetChanged $w "false"

    return
}

# Inventory::New --
#
#   Creates a new inventory. The blank inventory is read in and then
#   saved as the new inventory.
#
# Parameters:
#   w          : Inventory toplevel.
#
# Returns:
#   Nothing.
#
proc Inventory::New {w} {

    variable invConfig

    UnLockFile $w

    # Read the blank inventory file.
    set tempFileName \
        [file join $CrossFire::homeDir Scripts "BlankInv.tcl"]

    ReadInv $w $tempFileName
    foreach setID [CrossFire::CardSetIDList "real"] {
        set invConfig($w,inv$setID) [GetInvInfo $w inv$setID]
    }

    set invConfig($w,fileName) ""
    ClickListBox $w m 0 0

    return
}

# Inventory::ChangeInvData --
#
#   Changes the maximum desired qty, current on hand, premium, or weight
#   for a card in the inventory.
#
# Parameters:
#   w          : Inventory toplevel.
#   which      : Which value to set: weight, premium, max or qty.
#   delta      : Amount to change it by.
#   setID      : Card's set ID.
#   cardNumber : Card number.
#
# Returns:
#   The new quantity for the specified card's data.
#
proc Inventory::ChangeInvData {w which delta setID cardNumber} {

    variable invConfig

    set setInv $invConfig($w,inv$setID)
    set cardInv [lindex $setInv $cardNumber]

    switch -- $which {
        "max" {
            set invIndex 0
        }
        "qty" {
            set invIndex 1
        }
        "premium" {
            set invIndex 2
        }
        "weight" {
            set invIndex 3
        }
    }

    if {$delta == 0} {
        # User typed in a quantity
        set current [CrossFire::StripZeros $invConfig($w,$which)]
    } else {
        set current [lindex $cardInv $invIndex]
    }

    set oldQty [lindex $cardInv $invIndex]
    set newQty [expr $current + $delta]

    if {$newQty < 0} {
        set newQty 0
        if {$which == "qty"} {
            set msg "Attempted to change $setID/$cardNumber by $delta, "
            append msg "but only had $current!"
            tk_messageBox -icon error -parent $w -message $msg \
                -title "CrossFire Warning"
        }
    }

    set cardInv [lreplace $cardInv $invIndex $invIndex $newQty]
    set invConfig($w,inv$setID) \
        [lreplace $setInv $cardNumber $cardNumber $cardInv]

    return [list $oldQty $newQty]
}

# Inventory::ChangeInv --
#
#   Changes the maximum desired qty, current on hand, premium, or weight.
#   Calls ChangeInvData to do the actual change.
#
# Parameters:
#   w          : Inventory toplevel.
#   which      : Which value to set: weight, premium, max or qty.
#   delta      : Amount to change it by.
#
# Returns:
#   Nothing.
#
proc Inventory::ChangeInv {w which delta {move no}} {

    variable invConfig

    set itemNumList [$invConfig($w,cardListBox) curselection]
    set change "false"

    if {$itemNumList == ""} {
        tk_messageBox -icon error -parent $w \
            -title "Error Changing Quantity" \
            -message "You must select a card first."
        set invConfig($w,max) ""
        set invConfig($w,qty) ""
        set invConfig($w,weight) ""
        set invConfig($w,premium) 0
        focus $w
        return
    }

    foreach itemNum $itemNumList {

        set card [$invConfig($w,cardListBox) get $itemNum]

        if {[lindex $card 1] == "(no"} {
            if {[llength $itemNumList] == 1} {
                tk_messageBox -icon error -parent $w \
                    -title "Error Entering Quantity" \
                    -message "Card [lindex $card 0] does not exist."
                set invConfig($w,$which) "NA"
                focus $w
            }
        } else {

            if {$invConfig($w,$which) == ""} {
                set invConfig($w,$which) 0
            }

            foreach {setID cardNumber} \
                [CrossFire::DecodeShortID [lindex $card 0]] break
            foreach {old new} \
                [ChangeInvData $w $which $delta $setID $cardNumber] break
            #dputs "$which, Old: $old, New: $new, Move: $move"
            set invConfig($w,$which) $new

            if {$move == "no"} {
                focus $w
            }

            # Only change the change status if the value has changed.
            # Clicking in an entry causes this proc to be called once
            # focus is lost.
            if {$old != $new} {
                set change "true"
            }
        }
    }

    # Advance to the next card in the list.  This is done when pressing
    # enter in an entry.  Makes entering data for a bunch of cards easier.
    if {$move == "move"} {
        set item [expr [lindex $itemNumList end] + 1]
        set end [expr [$invConfig($w,cardListBox) index end] - 1]
        if {$item > $end} {
            set item $end
        }
        ClickListBox $w m $item 0
        focus $invConfig($w,${which}Widget)
    }

    if {$change == "true"} {
        SetChanged $w $change
    }

    return
}

# Inventory::GetSelectedCardID --
#
#   Returns the short ID of the selected card.
#
# Parameters:
#   w          : Inventory toplevel widget name.
#
# Returns:
#   The short ID of the selected card.
#
proc Inventory::GetSelectedCardID {w} {

    variable invConfig

    set lbw $invConfig($w,cardListBox)

    return [lindex [$lbw get [$lbw curselection]] 0]
}

# Inventory::ViewCard --
#
#   Views the currently selected card.
#
# Parameters:
#   w          : Inventory toplevel.
#
# Returns:
#   Nothing.
#
proc Inventory::ViewCard {w} {

    ViewCard::View $w [Inventory::GetSelectedCardID $w]

    return
}

