# SwapShop.tcl 20040820
#
# This file contains all the procedures for the Swap Shop.
#
# Copyright (c) 1998-2004 Steve Brazelton and Dan Curtiss. All rights reserved.
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

namespace eval SwapShop {

    variable windowTitle "Ye Ole' Swap Shop - BETA"
    variable swapShopCount 0  ;# Counter for creating new toplevels.
    
    # Array to hold various info about each editor.  Format: (widget,index).
    # Indicies:
    #   change      : Boolean. If trade has changes.
    #   cardSet     : ID of the current card set.
    #   cardListBox : Widget path of the card selection list box.
    #   outTextBox  : Widget path of the out text box.
    #   inTextBox   : Widget path of the in text box.
    #   fileName    : File name for the trade.
    variable swapShopConfig
}

# SetChanged --
#
#   Changes the boolean flag for if a trade has changed.
#   Adjusts the title of the window; adds a '*' indicating
#   that a change has been made.
#
# Parameters:
#   w     :  SwapShop toplevel.
#   bool  :  Boolean (true or false). Need to save?
#   args  :  Junk from trace
#
# Returns:
#   Nothing.
#
proc SwapShop::SetChanged {w bool args} {

    variable swapShopConfig
    variable windowTitle

    set swapShopConfig($w,change) $bool
    set sfn [file tail $swapShopConfig($w,fileName)]

    if {$sfn != ""} {
        set sfn "- $sfn "
    }

    if {[info exists swapShopConfig($w,autoSaveAfterID)]} {
        after cancel $swapShopConfig($w,autoSaveAfterID)
        unset swapShopConfig($w,autoSaveAfterID)
    }

    set title "$windowTitle $sfn"
    if {$bool == "true"} {
        wm title $w "${title}*"
        if {($swapShopConfig($w,fileName) != "") &&
            ($Config::config(SwapShop,autoSave) == "Yes")} {
            if {$Config::config(SwapShop,autoSaveTime) > 0} {
                set delayTime \
                    [expr $Config::config(SwapShop,autoSaveTime) * 60000]
                set swapShopConfig($w,autoSaveAfterID) \
                    [after $delayTime "SwapShop::SaveTrade $w"]
            }
        }
    } else {
        wm title $w $title
    }

    return
}

# Create --
#
#   Creates a new Swap Shop toplevel.
#
# Parameters:
#   args       : Optional filename to load.
#
# Returns:
#   Nothing.
#
proc SwapShop::Create {args} {

    variable swapShopCount
    variable swapShopConfig
    variable windowTitle

    if {[file exists $Config::config(Warehouse,defaultInv)] == 0} {
	Config::Create Warehouse
	tk_messageBox -icon info -title "Swap Shop Error!" \
	    -message "File $Config::config(Warehouse,defaultInv) does not exist.  You must configure the correct default inventory in Warehouse before using Swap Shop."
	return
    }

    set w .trader[incr swapShopCount]
    CrossFire::Register "SwapShop" $w

    # Set configuration for this trade to the default configuration.
    set swapShopConfig($w,change) "false"
    set swapShopConfig($w,fileName) ""
    set swapShopConfig($w,invEnabled) 1
    set swapShopConfig($w,invFileName) \
        [file tail $Config::config(Warehouse,defaultInv)]
    set swapShopConfig($w,disInvFile) $swapShopConfig($w,invFileName)
    set swapShopConfig($w,curInvDir) $Config::config(Warehouse,invDir)
    set swapShopConfig($w,tradeDir) $Config::config(SwapShop,dir)
    set swapShopConfig($w,allSetsList) $Config::config(SwapShop,setIDList)
    set swapShopConfig($w,traderName) "" 
    set swapShopConfig($w,traderEmail) "" 
    set setID [lindex $swapShopConfig($w,allSetsList) 0]
    set swapShopConfig($w,cardSet) $setID
    set swapShopConfig($w,cardSetName) $CrossFire::setXRef($setID,name)

    set swapShopConfig($w,selCardID) 0
    set swapShopConfig($w,outTextBox) $w.out.list.t
    set swapShopConfig($w,inTextBox) $w.in.list.t
    set swapShopConfig($w,inState) normal
    set swapShopConfig($w,outState) normal
    set swapShopConfig($w,buttonState) enabled
    set swapShopConfig($w,Sendable) yes
    set swapShopConfig($w,opening) 0
    set swapShopConfig($w,invTF1) ""
    set swapShopConfig($w,invTF2) ""
    set swapShopConfig($w,invTFLong1) ""
    set swapShopConfig($w,invTFLong2) ""
    set swapShopConfig($w,invTFBox1) ""
    set swapShopConfig($w,invTFBox2) ""
    set swapShopConfig($w,tfBox1) $w.finder.first.list.t
    set swapShopConfig($w,tfBox2) $w.finder.second.list.t
    set swapShopConfig($w,sentDate) 0
    set swapShopConfig($w,receivedDate) 0
    set swapShopConfig($w,highlightPos) ""

    toplevel $w
    wm title $w $windowTitle

    # Trap closing window from window manager methods.
    wm protocol $w WM_DELETE_WINDOW "SwapShop::ExitSwapShop $w"

    AddMenuBar $w

    bind $w <Key-comma> "SwapShop::IncrCardSet $w -1"
    bind $w <Key-period> "SwapShop::IncrCardSet $w 1"

    # First vertical panel: Cards to be sent "out" for trade.
    frame $w.out

    label $w.out.label -text "Outgoing Cards"
    frame $w.out.list
    text $w.out.list.t \
        -yscrollcommand "CrossFire::SetScrollBar $w.out.list.sb" \
        -width 25 -height 10 -exportselection 0 \
        -wrap none -cursor {} -bg white -fg black -spacing1 2
    $w.out.list.t tag configure cardSetHeader -font {Times 14 bold}
    $w.out.list.t tag configure cardSetSent -font {Times 14 bold} \
        -foreground LightGrey
    $w.out.list.t tag configure select -foreground white -background blue
    $w.out.list.t tag configure good
    $w.out.list.t tag configure last -foreground orange
    $w.out.list.t tag configure noextra -foreground red
    $w.out.list.t tag configure havenone -foreground purple
    $w.out.list.t tag configure greyit -foreground LightGrey
    scrollbar $w.out.list.sb -command "$w.out.list.t yview"
    grid $w.out.list.t -sticky nsew
    grid columnconfigure $w.out.list 0 -weight 1
    grid rowconfigure $w.out.list 0 -weight 1
    bind $w.out.list.t <ButtonPress-1> "SwapShop::ClickTextBox $w %X %Y 1 outTextBox"
    bind $w.out.list.t <ButtonRelease-1> "CrossFire::CancelDrag $w.out.list.t"
    bind $w.out.list.t <Button-2> "SwapShop::ClickTextBox $w %X %Y 2 outTextBox"
    bind $w.out.list.t <Button-3> "SwapShop::ClickTextBox $w %X %Y 3 outTextBox"
    bindtags $w.out.list.t "$w.out.list.t all"

    CrossFire::DragTarget $w.out.list.t AddCard "SwapShop::DragAddCard $w outTextBox"

    frame $w.out.totals
    label $w.out.totals.label1 -text "Cards:"
    label $w.out.totals.totalCards \
        -textvariable SwapShop::swapShopConfig($w,curOut)
    label $w.out.totals.label2 -text "PV:"
    label $w.out.totals.totalLevels \
        -textvariable SwapShop::swapShopConfig($w,curOutPV)
    pack $w.out.totals.label1 $w.out.totals.totalCards -side left
    pack $w.out.totals.totalLevels $w.out.totals.label2 -side right

    frame $w.out.button
    button $w.out.button.send -text "Send" -width 8 \
        -command "SwapShop::ChangeInventory $w outTextBox"
    grid $w.out.button.send 

    grid $w.out.label -sticky ew
    grid $w.out.list -sticky nsew
    grid $w.out.totals -pady 5 -sticky ew
    grid $w.out.button
    grid columnconfigure $w.out 0 -weight 1
    grid rowconfigure $w.out 1 -weight 1

    # Second vertical panel: Out Buttons
    frame $w.obuttons
    button $w.obuttons.add -text "<" -width 3 \
        -command "SwapShop::AddCard $w outTextBox"
    button $w.obuttons.remove -text ">" -width 3 \
        -command "SwapShop::RemoveCard $w outTextBox 1"
    button $w.obuttons.removeAll -text ">>" -width 3 \
        -command "SwapShop::RemoveCard $w outTextBox all"
    pack $w.obuttons.add $w.obuttons.remove $w.obuttons.removeAll -pady 10

    # Third vertical panel: List of cards in the set, card set selection option menu
    frame $w.cardList

    frame $w.cardList.label
    label $w.cardList.label.text -text "Inventory: "
    label $w.cardList.label.var -textvariable SwapShop::swapShopConfig($w,invFileName)
    pack $w.cardList.label.var -side right -fill x
    pack $w.cardList.label.text -side left

    set lbw [CrossFire::ScrolledListBox $w.cardList.list \
		-width 25 -height 20]
    set swapShopConfig($w,cardListBox) $lbw
     CrossFire::InitListBox $w $lbw SwapShop
     bind $lbw <ButtonRelease-1> "CrossFire::CancelDrag $lbw"
     bind $w <Key-Right> "SwapShop::AddCard $w inTextBox"
     bind $w <Key-Left> "SwapShop::AddCard $w outTextBox"

    frame $w.cardList.set
    label $w.cardList.set.text -text "Card Set: "
    label $w.cardList.set.var -textvariable SwapShop::swapShopConfig($w,cardSetName)
    pack $w.cardList.set.var -side right -fill x
    pack $w.cardList.set.text -side left

    frame $w.cardList.search
    label $w.cardList.search.label -text "Search: " -bd 0
    entry $w.cardList.search.entry -bg white -fg black
    pack $w.cardList.search.entry -side right -fill x
    pack $w.cardList.search.label -side left
    CrossFire::InitSearch $w $w.cardList.search.entry \
        $swapShopConfig($w,cardListBox) SwapShop

    grid $w.cardList.label -sticky ew
    grid $w.cardList.list -sticky nsew
    grid $w.cardList.set -sticky ew
    grid $w.cardList.search -sticky ew
    grid columnconfigure $w.cardList 0 -weight 1
    grid rowconfigure $w.cardList 1 -weight 1

    # Fourth vertical panel: In Buttons
    frame $w.ibuttons
    button $w.ibuttons.add -text ">" -width 3 \
        -command "SwapShop::AddCard $w inTextBox"
    button $w.ibuttons.remove -text "<" -width 3 \
        -command "SwapShop::RemoveCard $w inTextBox 1"
    button $w.ibuttons.removeAll -text "<<" -width 3 \
        -command "SwapShop::RemoveCard $w inTextBox all"
    pack $w.ibuttons.add $w.ibuttons.remove $w.ibuttons.removeAll -pady 10

    # Fith vertical panel: Cards to be received from trade.
    frame $w.in

    label $w.in.label -text "Incoming Cards"
    frame $w.in.list
    text $w.in.list.t \
        -yscrollcommand "CrossFire::SetScrollBar $w.in.list.sb" \
        -width 25 -height 10 -exportselection 0 \
        -wrap none -cursor {} -bg white -fg black -spacing1 2
    $w.in.list.t tag configure cardSetHeader -font {Times 14 bold}
    $w.in.list.t tag configure cardSetReceived -font {Times 14 bold} \
        -foreground LightGrey
    $w.in.list.t tag configure select -foreground white -background blue
    $w.in.list.t tag configure good
    $w.in.list.t tag configure noneed -foreground red
    $w.in.list.t tag configure greyit -foreground LightGrey
    scrollbar $w.in.list.sb -command "$w.in.list.t yview"
    grid $w.in.list.t -sticky nsew
    grid columnconfigure $w.in.list 0 -weight 1
    grid rowconfigure $w.in.list 0 -weight 1
    bind $w.in.list.t <ButtonPress-1> "SwapShop::ClickTextBox $w %X %Y 1 inTextBox"
    bind $w.in.list.t <ButtonRelease-1> "CrossFire::CancelDrag $w.in.list.t"
    bind $w.in.list.t <Button-2> "SwapShop::ClickTextBox $w %X %Y 2 inTextBox"
    bind $w.in.list.t <Button-3> "SwapShop::ClickTextBox $w %X %Y 3 inTextBox"
    bindtags $w.in.list.t "$w.in.list.t all"

    CrossFire::DragTarget $w.in.list.t AddCard "SwapShop::DragAddCard $w inTextBox"

    frame $w.in.totals
    label $w.in.totals.label1 -text "Cards:"
    label $w.in.totals.totalCards \
        -textvariable SwapShop::swapShopConfig($w,curIn)
    label $w.in.totals.label2 -text "PV:"
    label $w.in.totals.totalLevels \
        -textvariable SwapShop::swapShopConfig($w,curInPV)
    pack $w.in.totals.label1 $w.in.totals.totalCards -side left
    pack $w.in.totals.totalLevels $w.in.totals.label2 -side right
    frame $w.in.button
    button $w.in.button.receive -text "Receive" -width 8 \
        -command "SwapShop::ChangeInventory $w inTextBox"
    grid $w.in.button.receive

    grid $w.in.label -sticky ew
    grid $w.in.list -sticky nsew
    grid $w.in.totals -pady 5 -sticky ew
    grid $w.in.button
    grid columnconfigure $w.in 0 -weight 1
    grid rowconfigure $w.in 1 -weight 1

    # Grid the vertical panels
    grid $w.out -row 0 -column 0 -sticky nsew -padx 5 -pady 5
    grid $w.obuttons -row 0 -column 1
    grid $w.cardList -row 0 -column 2 -sticky nsew -padx 5 -pady 5
    grid $w.ibuttons -row 0 -column 3
    grid $w.in -row 0 -column 4 -sticky nsew -padx 5 -pady 5
    grid columnconfigure $w {0 2 4} -weight 1
    grid rowconfigure $w 0 -weight 1

    UpdateCardSelection $w
    New $w
    SetChanged $w "false"
    Config::RecentFile "SwapShop" {}

    if {$args != ""} {
        if {[OpenTrade $w [lindex $args 0] "nocomplain"] == 0} {
            ExitTrade $w
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

# AddMenuBar --
#
#   Creates the menubar for the trader and sets up the
#   accelerator key bindings for the commands.
#
# Parameters:
#   w          : Toplevel of the new trader window.
#
# Returns:
#   Nothing.
#
proc SwapShop::AddMenuBar {w} {

    variable swapShopConfig
    
    menu $w.menubar
    
    $w.menubar add cascade \
        -label "Trade" \
        -underline 0 \
        -menu $w.menubar.trade
    
    menu $w.menubar.trade -tearoff 0
    $w.menubar.trade add command \
        -label "New" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+N" \
        -command "SwapShop::NewTrade $w"
    $w.menubar.trade add command \
        -label "Open..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+O" \
        -command "SwapShop::OpenTrade $w {}"
    $w.menubar.trade add command \
        -label "Save" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+S" \
        -command "SwapShop::SaveTrade $w"
    $w.menubar.trade add command \
        -label "Save As..." \
        -underline 5 \
        -command "SwapShop::SaveTradeAs $w"

    $w.menubar.trade add separator
    $w.menubar.trade add command \
        -label "Information..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+I" \
        -command "SwapShop::TradeSettings $w"
    $w.menubar.trade add separator
    $w.menubar.trade add command \
        -label "Print..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+P" \
        -command "SwapShop::PrintTrade $w"
    $w.menubar.trade add separator

    set exitLabel "Close"
    set exitAccelerator "Alt+F4"
    if {$CrossFire::platform == "macintosh"} {
        # This is a Macintosh, so make the exit
        # accelerator more "Mac-ish"
        set exitLabel "Quit"
        set exitAccelerator "Command+Q"
    }
    $w.menubar.trade add command \
        -label $exitLabel \
        -underline 1 \
        -accelerator $exitAccelerator \
        -command "SwapShop::ExitSwapShop $w"

    $w.menubar add cascade \
        -label "Card Set" \
        -underline 0 \
        -menu $w.menubar.set

    menu $w.menubar.set -tearoff 0 -title "Card Set"
    set swapShopConfig($w,cardSetMenu) $w.menubar.set
    AddCardSetMenu $w

    $w.menubar add cascade \
        -label "Utilities" \
        -underline 0 \
        -menu $w.menubar.util

    menu $w.menubar.util -tearoff 0
    $w.menubar.util add command \
        -label "Trade Status" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+T" \
        -command "SwapShop::TradeStatus $w"
    $w.menubar.util add command \
        -label "Trade Finder" \
        -underline 6 \
        -accelerator "$CrossFire::accelKey+F" \
        -command "SwapShop::TradeFinder $w"
    if {$::developer == 1} {
	$w.menubar.util add command \
	    -label "Rate..." \
	    -underline 0 \
	    -accelerator "$CrossFire::accelKey+R" \
	    -command "SwapShop::TradeRater $w"
    }
    $w.menubar.util add separator
    $w.menubar.util add command \
        -label "Configure..." \
        -underline 0 \
        -command "Config::Create Swap Shop"

    $w.menubar add cascade \
        -label "Help" \
        -underline 0 \
        -menu $w.menubar.help

    menu $w.menubar.help -tearoff 0
    $w.menubar.help add command \
        -label "Help..." \
        -underline 0 \
        -accelerator "F1" \
        -command "CrossFire::Help ss_main.html"
    $w.menubar.help add separator
    $w.menubar.help add command \
        -label "About Swap Shop..." \
        -underline 0 \
        -command "SwapShop::About $w"

    $w config -menu $w.menubar

    # Trade menu bindings.
    bind $w <$CrossFire::accelBind-n> "SwapShop::NewTrade $w"
    bind $w <$CrossFire::accelBind-o> "SwapShop::OpenTrade $w {}"
    bind $w <$CrossFire::accelBind-s> "SwapShop::SaveTrade $w"
    bind $w <$CrossFire::accelBind-i> "SwapShop::TradeSettings $w"
    bind $w <$CrossFire::accelBind-p> "SwapShop::PrintTrade $w"
    if {$CrossFire::platform == "macintosh"} {
        bind $w <Command-q> "SwapShop::ExitSwapShop $w"
    } else {
        bind $w <Meta-x> "SwapShop::ExitSwapShop $w"
        bind $w <Alt-F4> "SwapShop::ExitSwapShop $w; break"
    }

    # Utilities menu bindings.
    bind $w <$CrossFire::accelBind-t> "SwapShop::TradeStatus $w"
    bind $w <$CrossFire::accelBind-f> "SwapShop::TradeFinder $w"
    if {$::developer == 1} {
	bind $w <$CrossFire::accelBind-r> "SwapShop::TradeRater $w"
    }

    # Help menu bindings.
    bind $w <Key-F1> "Help::Create .help {Swap Shop Help} ss_main.html"
    bind $w <Key-Help> "Help::Create .help {Swap Shop Help} ss_main.html"

    # menu for right click on card list
    menu $w.addMenu -tearoff 0
    $w.addMenu add command -label " Add to Outgoing" \
        -command "SwapShop::AddCard $w outTextBox"
    $w.addMenu add command -label " Add to Incoming" \
        -command "SwapShop::AddCard $w inTextBox"
    $w.addMenu add separator
    $w.addMenu add command -label " View" \
        -command "SwapShop::ViewCard $w"

    # menus for right click on inTextBox
    menu $w.inDelCardMenu -tearoff 0
    $w.inDelCardMenu add command -label " Reduce Quantity" \
        -command "SwapShop::RemoveCard $w inTextBox 1"
    $w.inDelCardMenu add command -label " Remove from Trade" \
        -command "SwapShop::RemoveCard $w inTextBox all"
    $w.inDelCardMenu add separator
    $w.inDelCardMenu add command -label " View" \
        -command "SwapShop::ViewCard $w inTextBox"

    menu $w.inDelSetMenu -tearoff 0
    $w.inDelSetMenu add command -label " Remove from Trade" \
        -command "SwapShop::RemoveCard $w inTextBox all"

    # menus for right click on outTextBox
    menu $w.outDelCardMenu -tearoff 0
    $w.outDelCardMenu add command -label " Reduce Quantity" \
        -command "SwapShop::RemoveCard $w outTextBox 1"
    $w.outDelCardMenu add command -label " Remove from Trade" \
        -command "SwapShop::RemoveCard $w outTextBox all"
    $w.outDelCardMenu add separator
    $w.outDelCardMenu add command -label " View" \
        -command "SwapShop::ViewCard $w outTextBox"

    menu $w.outDelSetMenu -tearoff 0
    $w.outDelSetMenu add command -label " Remove from Trade" \
        -command "SwapShop::RemoveCard $w inTextBox all"

    return
}

# AddCardSetMenu --
#
#   Adds the card set selection to the menubar.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc SwapShop::AddCardSetMenu {w} {

    variable swapShopConfig

    set m $swapShopConfig($w,cardSetMenu)
    CrossFire::CreateCardSetMenu $swapShopConfig($w,cardSetMenu) "real" \
        SwapShop::swapShopConfig($w,cardSet) \
        "SwapShop::UpdateCardSelection $w"

    return
}

# About --
#
#   Displays an about dialog for the SwapShop.
#
# Paramters:
#   w         : Parent toplevel for the pop-up dialog.
#
# Returns:
#   Nothing.
#
proc SwapShop::About {w} {
    set message "CrossFire Swap Shop (Trade Manager)\n"
    append message "\nby Steve Brazelton & Dan Curtiss\n"
    append message "\nTrading has never been easier!"
    tk_messageBox -icon info -title "About CrossFire Swap Shop" \
        -parent $w -message $message

    return
}

# NewTrade --
#
#   Checks if saved needed before clearing listboxes.
#
# Parameters:
#   w          : SwapShop toplevel path name.
#
# Returns:
#   Nothing.
#
proc SwapShop::NewTrade {w} {

    variable swapShopConfig

    if {[CheckForSave $w] == -1} {
        return -1
    }

    New $w
    SetChanged $w "false"

    return 0
}

# New --
#
#   Clears the current trade.
#
# Parameters:
#   w          : SwapShop toplevel path name.
#
# Returns:
#   Nothing.
#
proc SwapShop::New {w} {

    variable swapShopConfig

    UnLockFile $w

    set swapShopConfig($w,curOut) 0
    set swapShopConfig($w,curIn) 0
    set swapShopConfig($w,curOutPV) 0
    set swapShopConfig($w,curInPV) 0
    set swapShopConfig($w,fileName) {}
    set swapShopConfig($w,tradeinTextBox) {}
    set swapShopConfig($w,tradeoutTextBox) {}
    set swapShopConfig($w,traderName) "" 
    set swapShopConfig($w,traderEmail) "" 

    foreach freq $CrossFire::cardFreqIDList {
        set swapShopConfig($w,totalOut$freq) 0
        set swapShopConfig($w,totalIn$freq) 0
    }
    
    Disable $w $w.ibuttons.add 1
    Disable $w $w.ibuttons.remove 1
    Disable $w $w.ibuttons.removeAll 1
    $w.inDelCardMenu entryconfigure 0 -state normal
    $w.inDelCardMenu entryconfigure 1 -state normal
    $w.inDelSetMenu entryconfigure 0 -state normal
    $w.addMenu entryconfigure 1 -state normal
    Disable $w $w.in.button.receive 1
    set swapShopConfig($w,inState) normal
    Disable $w $w.obuttons.add 1
    Disable $w $w.obuttons.remove 1
    Disable $w $w.obuttons.removeAll 1
    $w.outDelCardMenu entryconfigure 0 -state normal
    $w.outDelCardMenu entryconfigure 1 -state normal
    $w.outDelSetMenu entryconfigure 0 -state normal
    $w.addMenu entryconfigure 0 -state normal
    Disable $w $w.out.button.send 1
    set swapShopConfig($w,outState) normal

    foreach cardTypeID $CrossFire::cardTypeIDList {
        set typeID $CrossFire::cardTypeXRef($cardTypeID,icon)
        set swapShopConfig($w,expand$typeID) 1
    }

    DisplayTrade $w inTextBox
    DisplayTrade $w outTextBox

    return
}

# UpdateCardSelection --
#
#   Changes the card set, updates selection list box.
#
# Parameters:
#   w          : SwapShop toplevel name.
#
# Returns:
#   Nothing.
#
proc SwapShop::UpdateCardSelection {w} {

    variable swapShopConfig

    $w config -cursor watch
    update

    set cardSetID $swapShopConfig($w,cardSet)
    set swapShopConfig($w,cardSetName) $CrossFire::setXRef($cardSetID,name)

    if {$cardSetID == "All"} {
        set listOfIDs $swapShopConfig($w,allSetsList)
    } else {
        set listOfIDs $cardSetID
    }

    $swapShopConfig($w,cardListBox) delete 0 end
    selection clear
    foreach setID $listOfIDs {
        CrossFire::ReadCardDataBase $setID
        foreach card [lrange $CrossFire::cardDataBase 1 end] {
            $swapShopConfig($w,cardListBox) insert end \
                [SwapShop::GetCardDesc $card]
        }
    }

    $w config -cursor {}
    return
}

# DisplayTrade --
#
#   Displays a trade in the text box.
#
# Parameters:
#   w          : SwapShop toplevel widget name.
#   location   : inBox or outBox.
#   args       : Optional line number to put at the top of the text box.
#                Normally, the current line will be redisplayed at the
#                top. OpenTrade calls this procedure with a 0 for line number.
#
# Returns:
#   Nothing.
#
proc SwapShop::DisplayTrade {w location args} {

    variable swapShopConfig

    set tbw $swapShopConfig($w,$location)
    set trade $swapShopConfig($w,trade$location)
    set lineCount 0
    set noneOf 0
    if {$args != ""} {
        set yview [lindex $args 0]
    } else {
        set yview [expr int([$tbw index @0,0]) - 1]
    }

    $tbw delete 1.0 end

    foreach cardSetID [CrossFire::CardSetIDList "real"] {
        set cardSetName $CrossFire::setXRef($cardSetID,name)
        set displayedName 0
        set swapShopConfig($w,expand$cardSetID) 1
        
        foreach cardAndInv $trade {
            set card [lindex $cardAndInv 0]
            set inv [lindex $cardAndInv 1]
            set wants [lindex $inv 0]
            set haves [lindex $inv 1]
            set quantity [lindex $inv 2]
            if {[lindex $card 0] == $cardSetID} {
                
                if {$displayedName == 0} {
                    
                    incr lineCount
                    if {$lineCount != 1} {
                        $tbw insert end "\n"
                    }
                    if {$location == "outTextBox"} {
                        if {$swapShopConfig($w,outState) == "disabled"} {
                            set state cardSetSent
                        } else {
                            set state cardSetHeader
                        }
                    } else {
                        if {$swapShopConfig($w,inState) == "disabled"} {
                            set state cardSetReceived
                        } else {
                            set state cardSetHeader
                        }
                    }
                    if {$swapShopConfig($w,expand$cardSetID) == 1} {
                        $tbw insert end "- " $state
                    } else {
                        $tbw insert end "+ " $state
                    }
                    
                    $tbw insert end "$cardSetName " $state
                    set displayedName 1
                }
                if {$swapShopConfig($w,expand$cardSetID) == 1} {
                    
                    set desc [SwapShop::GetCardDesc $card]

                    if {$location == "outTextBox"} {
                        if {$swapShopConfig($w,outState) == "disabled"} {
                            set scope greyit
                        } elseif {$swapShopConfig($w,invFileName) == "DISABLED"} {
                            set scope good
                        } else {
                            set virtualHaves [expr $haves - $quantity]
                            set extras [expr $virtualHaves - $wants + 1]
                            if {$virtualHaves < 0} {set extras 999}
                            if {$extras <= 0} {
                                set scope noextra
                            } elseif {$extras == 1} {
                                set scope last
                            } elseif {$extras == 999} {
                                set scope havenone
                                incr noneOf
                            } else {
                                set scope good
                            }
                        }
                    } else {
                        if {$swapShopConfig($w,inState) == "disabled"} {
                            set scope greyit
                        } elseif {$swapShopConfig($w,invFileName) == "DISABLED"} {
                            set scope good
                        } else {
                            set virtualHaves [expr $haves + $quantity]
                            set extras [expr $virtualHaves - $wants - 1]
                            if {$virtualHaves == 0} {set extras 999}
                            if {($extras >= 0) && ($extras <= 999)} {
                                set scope noneed
                            } else {
                                set scope good
                            }
                        }
                    }
                    $tbw insert end "\n[format {%2d} $quantity] $desc" \
                        $scope
                }
            }
        }
    }
    
    $tbw yview scroll $yview units
    $w configure -cursor {}

    # if there are cards in the outgoing list that are not in the 
    # currently selected inventory than set the flag to not allow
    # the send button to be pressed.
    if {$noneOf > 0} {
        set swapShopConfig($w,Sendable) no
    } else {
        set swapShopConfig($w,Sendable) yes
    }
    if {$swapShopConfig($w,highlightPos) != ""} {
	$tbw tag add select $swapShopConfig($w,highlightPos).0 [expr $swapShopConfig($w,highlightPos) + 1].0
    }

    return
}

# AddCardToTrade --
#
#   Adds a card to a trade.  First checks if all the requirements
#   and restrictions are met before adding the card.  Used by
#   OpenTrade and AddCard.
#
# Parameters:
#   w          : SwapShop toplevel path name.
#   card       : The card to add in standard card format.
#
# Returns:
#   1 if added, or 0 if not.
#
proc SwapShop::AddCardToTrade {w card location} {

    variable swapShopConfig
    set ndex 0
    set quantity 1
    set okToAdd 1
    set cardNo [lindex $card 1]
    set cardSet [lindex $card 0]
    if {$location == "inTextBox"} {
        set state inState
    } else {
        set state outState
    }
    # Do all the checks to see if we can add the card.

    # Check for cards that do not exist.
    if {[lindex $card 6] == "(no card)"} {
        set okToAdd 0
        set msg "This card does not exist."
    }

    # Check if card is duplicate in trade
    foreach cit $swapShopConfig($w,trade$location) {
        set tempCard [lindex $cit 0]
        if {($cardNo == [lindex $tempCard 1]) &&
            ($cardSet == [lindex $tempCard 0])} {
            set tempInv [lindex $cit 1]
            set addTo [lindex $tempInv 2]
            incr quantity $addTo
            break
        }
        incr ndex
    }

    if {$swapShopConfig($w,invFileName) == "DISABLED"} {
        set invInfo "0 0 $quantity"
        set extras 9999
        # Change to do this everytime a trade is loaded
    } elseif {$swapShopConfig($w,$state) == "disabled"} {
        set invInfo [SwapShop::GetInvInfo $w $card 0] 
        set extras 9999
        lappend invInfo $quantity
    } else {
        # Check the current Inventory file for extras/wants
        set invInfo [SwapShop::GetInvInfo $w $card 0] 
        set onhand [lindex $invInfo 1]
        set wanted [lindex $invInfo 0]
        set test [expr $onhand - $quantity + 1]
        lappend invInfo $quantity
        if {$test == 0} {
            set extras 999
        } else {
            set extras [expr $onhand - $wanted - $quantity + 1]
        }
    }
    set cardAndInv "\{$card\} \{$invInfo\}"
    
    if {($location == "outTextBox") && ($swapShopConfig($w,opening) < 1)} {
        if {$extras <= 0} {
            set msg "You have no Extras of this card.  Would you like to add it anyway?"
            set okToAdd [SwapShop::Confirm $w $msg]
        } elseif {$extras == 999} {
            set msg "You have none of this card"
            tk_messageBox -message $msg -icon error \
                -title "Error Adding Card" -parent $w
            set okToAdd 0
        }
    }
    
    if {$okToAdd == 1} {

        if {$quantity > 1} {
            set swapShopConfig($w,trade$location) \
                [lreplace $swapShopConfig($w,trade$location) $ndex $ndex $cardAndInv]
        } else {
            set swapShopConfig($w,trade$location) \
                [lsort [lappend swapShopConfig($w,trade$location) $cardAndInv]]
        }

        set cardFreq [lindex $card 8]
        if {$location == "outTextBox"} {
            incr swapShopConfig($w,curOut)
            incr swapShopConfig($w,totalOut${cardFreq})
        } else {
            incr swapShopConfig($w,curIn)
            incr swapShopConfig($w,totalIn${cardFreq})
        }

    }

    return $okToAdd
}

# AddCard --
#
#   Attempts to add the selected card on the specified trader
#   toplevel to the in/out box.  Alerts user if no card is selected.
#   Actual adding of card is handled by AddCardToTrade.
#
# Parameters:
#   w          : SwapShop toplevel path name.
#
# Returns:
#   Nothing.
#
proc SwapShop::AddCard {w location} {

    variable swapShopConfig
    if {$location == "inTextBox"} {
        set state inState
    } else {
        set state outState
    }
    if {$swapShopConfig($w,$state) == "disabled"} {
        return
    }
    set lbw $swapShopConfig($w,cardListBox)

    set selIndex [$lbw curselection]
    if {$selIndex == ""} {
        tk_messageBox -message "No Card Selected." -icon error \
            -title "Swap Shop Error"
    } else {
        set cardID [lindex [$lbw get $selIndex] 0]
        set card [CrossFire::GetCard $cardID]

        # Only redisplay in/out box if we successfully add the card.
        if {[AddCardToTrade $w $card $location] == 1} {
            DisplayTrade $w $location
            SetChanged $w "true"
            CalcPointValue $w
        }
    }

    return
}

# DragAddCard --
#
#   Called when one of the list boxes receives a drop.
#
# Parameters:
#   w          : SwapShop toplevel.
#   location   : Which textbox (outTextBox, inTextBox)
#   from       : Widget we received it from.
#   tbw        : Textbox receiving the drop.
#
# Returns:
#   Nothing.
#
proc SwapShop::DragAddCard {w location from tbw} {

    AddCard $w $location
    return
}

# RemoveCardFromTrade --
#
#   Procedure that actually removes a card from the in/out box.
#   It also adjusts card quantities.
#
# Parameters:
#   w          : SwapShop toplevel path name.
#
# Returns:
#   Nothing.
#
proc SwapShop::RemoveCardFromTrade {w card location} {

    variable swapShopConfig

    set pos -1
    set index 0
    set cardSetID [lindex $card 0]
    set cardNumber [lindex $card 1]
    foreach testCardAndInv $swapShopConfig($w,trade$location) {
        set testCard [lindex $testCardAndInv 0]
        if {($cardSetID == [lindex $testCard 0]) &&
            ($cardNumber == [lindex $testCard 1])} {
            set pos $index
            set testInv [lindex $testCardAndInv 1]
            break
        }
        incr index
    }

    set quantity [lindex $testInv 2]

    if {$pos != -1} {
        if {$quantity == 1} {
            set swapShopConfig($w,trade$location) \
                [lreplace $swapShopConfig($w,trade$location) $pos $pos]
	    set swapShopConfig($w,highlightPos) ""
        } else {
            incr quantity -1
            set testInv [lreplace $testInv 2 2 $quantity]
            set cardAndInv "\{$card\} \{$testInv\}"
            set swapShopConfig($w,trade$location) \
                [lreplace $swapShopConfig($w,trade$location) $pos $pos $cardAndInv]

        }
        set cardFreq [lindex $card 8]

        if {$location == "outTextBox"} {
            incr swapShopConfig($w,curOut) -1
            incr swapShopConfig($w,totalOut${cardFreq}) -1
        } else {
            incr swapShopConfig($w,curIn) -1
            incr swapShopConfig($w,totalIn${cardFreq}) -1
        }
        CalcPointValue $w

    } else {
        #tk_messageBox -message "RemoveCardFromTrade hosed:\ncard:$card\ntrade:$swapShopConfig($w,trade$location)"
    }

    return
}

# RemoveCard --
#
#   Removes the highlighted card or type of card from the in/out box.
#
# Parameters:
#   w          : SwapShop toplevel path name.
#
# Returns:
#   Nothing.
#
proc SwapShop::RemoveCard {w location amt} {

    variable swapShopConfig

    set card ""

    # We want a warning if the selection is on the card selection box,
    # so don't get a card if it is.
    if {[$swapShopConfig($w,cardListBox) curselection] == ""} {
        set cardID [GetSelectedCardID $w $location]
        if {([lindex $cardID 0] == "+") || ([lindex $cardID 0] == "-")} {
            set card $cardID
        } else {
            set card [CrossFire::GetCard $cardID]
        }
    }

    if {$card == ""} {
        tk_messageBox -message "No card selected." -icon error \
            -title "Error Removing Card" -parent $w
        return
    }

    if {([lindex $card 0] == "+") || ([lindex $card 0] == "-")} {

        # Verify that the user wants to remove all of this card type.
        set cardSetID [lreplace $card 0 0]
        set msg "Are you sure you want to remove all cards "
        append msg "from set $cardSetID?"
        set response [tk_messageBox -icon question -title "Verify Remove" \
                          -message $msg -type yesno -default no -parent $w]

        if {$response == "yes"} {

            foreach cardAndInv $swapShopConfig($w,trade$location) {
                set card [lindex $cardAndInv 0]
                set inv [lindex [lindex $cardAndInv 1] 2]
                set testSetID [lindex $card 0]
                if {$cardSetID == $CrossFire::setXRef($testSetID,name)} {
                    for {set i 0} {$i < $inv} {incr i} {
                        RemoveCardFromTrade $w $card $location
                    }
                }
            }

        } else {
            return
        }
        
    } elseif {$amt == "all"} {
        foreach cardAndInv $swapShopConfig($w,trade$location) {
            set testCard [lindex $cardAndInv 0]
            set inv [lindex [lindex $cardAndInv 1] 2]
            if {$testCard == $card} {
                for {set i 0} {$i < $inv} {incr i} {
                    RemoveCardFromTrade $w $card $location
                }
            }
        }
    } else {
        RemoveCardFromTrade $w $card $location
    }

    SetChanged $w "true"
    DisplayTrade $w $location

    return
}

proc SwapShop::GetInvInfo {w card method} {

    variable swapShopConfig

    set cardNo [lindex $card 1]

    set invFile [file join $swapShopConfig($w,curInvDir) $swapShopConfig($w,invFileName)]
    if {$invFile != ""} {
        if {$method == 0 && $swapShopConfig($w,opening) <= 1} {
            Inventory::ReadInv $w $invFile
        }
        set cardInv [lindex [Inventory::GetInvInfo $w inv[lindex $card 0]] $cardNo]
    }

    if {$swapShopConfig($w,opening) == 1} {
        incr swapShopConfig($w,opening)
    }

    if {$method == 0} {return [lrange $cardInv 0 1]}
    if {$method == 1} {return [lindex $cardInv 3]}
}

proc SwapShop::ClickListBox {w X Y btnNumber} {

    variable swapShopConfig

    set swapShopConfig($w,highlightPos) ""
    set lbw $swapShopConfig($w,cardListBox)

    CrossFire::ClickListBox $w $lbw $X $Y

    # Remove the highlight from the two text boxes
    $swapShopConfig($w,inTextBox) tag remove select 1.0 end
    $swapShopConfig($w,outTextBox) tag remove select 1.0 end

    set tempID [GetSelectedCardID $w]
    if {$Config::config(ViewCard,mode) == "Continuous"} {
        set first [lindex $tempID 0]
        if {($first != "+") && ($first != "-")} {
            ViewCard::View $w $tempID
        }
    }

    # Do various activities depending which button was pressed.
    switch -- $btnNumber {
        1 {
            # Start the drag-n-drop routines.
            #CrossFire::StartDrag $lbw plus AddCard $lbw
        }

        3 {
            # Pop-up Menu
            tk_popup $w.addMenu $X $Y
        }
    }

    return
}

# ClickTextBox --
#
#   Adds a highlight bar to the line clicked on in a text box.
#   This is made to resemble a list box.
#
# Parameters:
#   w          : Toplevel of the trader.
#   X Y        : Coordinates clicked. (%X %Y)
#   btnNumber  : Button number pressed.
#
# Returns:
#   Nothing.
#
proc SwapShop::ClickTextBox {w X Y btnNumber location} {

    variable swapShopConfig

    set tw $swapShopConfig($w,$location)

    # Remove the highlight from the two text boxes
    $swapShopConfig($w,inTextBox) tag remove select 1.0 end
    $swapShopConfig($w,outTextBox) tag remove select 1.0 end

    # Remove the selection from the selection list box.
    $swapShopConfig($w,cardListBox) selection clear 0 end

    # Translate X,Y coordinates to x,y of text box.
    set x [expr $X - [winfo rootx $tw]]
    set y [expr $Y - [winfo rooty $tw]]

    set pos [lindex [split [$tw index @$x,$y] .] 0]
    set swapShopConfig($w,highlightPos) $pos

    if {$swapShopConfig($w,$location) != {}} {
        $tw tag add select $pos.0 [expr $pos + 1].0
    }

    set tempID [GetSelectedCardID $w $location]
    set first [lindex $tempID 0]
    if {$Config::config(ViewCard,mode) == "Continuous"} {
        if {($first != "+") && ($first != "-")} {
            ViewCard::View $w $tempID
        }
    }

    switch -- $btnNumber {
        1 {
            # Start the drag-n-drop routines.
            # Commented out because it needs to be disabled after inventory
            # adjustments.
            #                CrossFire::StartDrag $tw pirate RemoveCard tempID
        }

        2 {
            RemoveCard $w $location 1
        }

        3 {
            # Pop-up Menu
            if {$location == "inTextBox"} {
                set loc "in"
            } else {
                set loc "out"
            }
            if {($first != "+") && ($first != "-")} {
                set type "Card"
            } else {
                set type "Set"
            }
            tk_popup $w.${loc}Del${type}Menu $X $Y
        }
    }


    return
}

# IncrCardSet --
#
#   Changes the selected card set.
#
# Parameters:
#   w          : SwapShop toplevel.
#   delta      : Amount to change set by.
#
# Returns:
#   Nothing.
#
proc SwapShop::IncrCardSet {w delta} {

    variable swapShopConfig

    set last [expr [llength $swapShopConfig($w,allSetsList)] -1]
    set index [lsearch $swapShopConfig($w,allSetsList) $swapShopConfig($w,cardSet)]

    incr index $delta

    if {$index < 0} {
        set index 0
    }
    if {$index > $last} {
        set index $last
    }

    set newSet [lindex $swapShopConfig($w,allSetsList) $index]

    if {$newSet != $swapShopConfig($w,cardSet)} {
        set swapShopConfig($w,cardSet) $newSet
        UpdateCardSelection $w
    }

    return
}

# TradeSettings --
#
#   Creates or raises the trade settings box for the trade
#   associated with the specified SwapShop toplevel.
#
# Parameters:
#   w          : SwapShop toplevel path name.
#
# Returns:
#   Nothing.
#
proc SwapShop::TradeSettings {w} {
    
    variable swapShopConfig

    set tsw $w.settings
    
    if {[winfo exists $tsw]} {

        wm deiconify $tsw
        raise $tsw

    } else {

        toplevel $tsw
        wm title $tsw "Trade Information"
        wm protocol $tsw WM_DELETE_WINDOW "$tsw.close invoke"
        bind $tsw <Key-Escape> "$tsw.close invoke"

        CrossFire::Transient $tsw

        frame $tsw.invinfo
        checkbutton $tsw.invinfo.cb -anchor w -text "Current Inventory:" \
            -variable SwapShop::swapShopConfig($w,invEnabled) \
            -command "SwapShop::SwapFile $w $tsw.invinfo.button"
        label $tsw.invinfo.tv -width 15 -anchor w \
            -textvariable SwapShop::swapShopConfig($w,invFileName)
        button $tsw.invinfo.button -anchor w -text "Select..." \
            -command "SwapShop::OpenInv $w"
        grid $tsw.invinfo.cb $tsw.invinfo.tv $tsw.invinfo.button -sticky w

        frame $tsw.optlabel
        label $tsw.optlabel.title -text "Optional SwapShop Info" -anchor center
        grid $tsw.optlabel.title -sticky ew
        
        frame $tsw.outinfo -relief groove -borderwidth 2
        label $tsw.outinfo.nlabel -text "Traders name:" -anchor w
        entry $tsw.outinfo.name -bg white -fg black \
            -textvariable SwapShop::swapShopConfig($w,traderName)
        trace variable SwapShop::swapShopConfig($w,traderName) w \
            "SwapShop::SetChanged $w true"
        grid $tsw.outinfo.nlabel $tsw.outinfo.name -sticky w
        #           grid rowconfigure $tsw.outinfo 0 -weight 1
        label $tsw.outinfo.elabel -text "Traders E-mail:" -anchor w
        entry $tsw.outinfo.email -bg white -fg black \
            -textvariable SwapShop::swapShopConfig($w,traderEmail)
        trace variable SwapShop::swapShopConfig($w,traderEmail) w \
            "SwapShop::SetChanged $w true"
        grid $tsw.outinfo.elabel $tsw.outinfo.email -sticky w
        #           grid rowconfigure $tsw.outinfo 0 -weight 1

        grid $tsw.invinfo  -padx 3 -pady 5
        #            grid $tsw.freq  -padx 3 -pady 10 -ipady 5
        grid $tsw.optlabel  -padx 3 -pady 5
        grid $tsw.outinfo -padx 3 -pady 5
        
        button $tsw.close -text $CrossFire::close \
            -command "SwapShop::CloseSettings $w"
        
        grid $tsw.close -pady 3
        
    }
    if {$swapShopConfig($w,invEnabled) == 0} {
        set state 0
    } else {
        set state 1
    }
    Disable $w $tsw.invinfo.button $state
    if {$swapShopConfig($w,inState) == "disabled" || $swapShopConfig($w,outState) == "disabled"} {
        Disable $w $tsw.invinfo.button 0
        Disable $w $tsw.invinfo.cb 0
    }
    return
}

proc SwapShop::CloseSettings {w} {
    destroy $w.settings
    trace vdelete SwapShop::swapShopConfig($w,traderName) w \
        "SwapShop::SetChanged $w true"
    trace vdelete SwapShop::swapShopConfig($w,traderEmail) w \
        "SwapShop::SetChanged $w true"
}

proc SwapShop::SwapFile {w button} {
    variable swapShopConfig
    
    if {$swapShopConfig($w,invEnabled) == 0} {
        set swapShopConfig($w,disInvFile) $swapShopConfig($w,invFileName)
        set swapShopConfig($w,invFileName) "DISABLED"
    } else {
        set swapShopConfig($w,invFileName) $swapShopConfig($w,disInvFile)
    }
    SetChanged $w "true"
    if {$swapShopConfig($w,invEnabled) == 0} {
        set state 0
    } else {
        set state 1
    }
    SwapShop::Disable $w $button $state
    DisplayTrade $w inTextBox
    DisplayTrade $w outTextBox
}

proc SwapShop::Disable {w button state} {
    variable swapShopConfig
    
    if {$state == 0} {
        $button configure -state disabled
    } else {
        $button configure -state normal
    }
}

# GetCardDesc --
#
#   Returns a short card description.  Mainly for use in a list box.
#
# Paramters:
#   card      : A card in standard card format.
#
# Returns:
#   A short card description.  ie: AR/045 Pegasus [+3]
#
proc SwapShop::GetCardDesc {card} {

    set cardDesc \
        [lindex [CrossFire::GetCardID [lindex $card 0] [lindex $card 1]] 0]
    append cardDesc " [lindex $card 6]"
    append cardDesc " ([lindex $card 8])"

    return $cardDesc
}

# GetSelectedCardID --
#
#   Returns the short ID of the selected card, if any.
#
# Parameters:
#   w          : SwapShop toplevel widget name.
#
# Returns:
#   The short ID if a card is selected, nothing otherwise.
#
proc SwapShop::GetSelectedCardID {w {location ""}} {

    variable swapShopConfig

    set lbw $swapShopConfig($w,cardListBox)

    # Determine if the selection is in the list box or text box.
    if {[$lbw curselection] != ""} {
        return [lindex [$lbw get [$lbw curselection]] 0]
    }

    set tbw $swapShopConfig($w,$location)

    set start [lindex [$tbw tag ranges select] 0]
    if {$start == ""} {
        set selectedCard ""
    } else {
        set end [lindex [split $start "."] 0].end
        set selectedCard [$tbw get $start $end]
    }

    set first [lindex $selectedCard 0]

    # Return the whole string if it is a card group.
    if {($first != "+") && ($first != "-")} {
        set selectedCard [lindex $selectedCard 1]
    }

    return $selectedCard
}


# CalcPointValue --
#
#   Calculates the total card point values.
#
# Parameters:
#   w :  Parent window
#
# Returns:
#   Nothing.
#
proc SwapShop::CalcPointValue {w args} {
    variable swapShopConfig
    if {$swapShopConfig($w,invEnabled) == 0} {
        set swapShopConfig($w,curInPV) 0
        set swapShopConfig($w,curOutPV) 0
        return;
    }
    foreach loc "In Out" {
        if {$loc == "In"} {set location "inTextBox"}
        if {$loc == "Out"} {set location "outTextBox"}
        set swapShopConfig($w,cur${loc}PV) 0
        foreach cardAndInv $swapShopConfig($w,trade$location) {
            set card [lindex $cardAndInv 0]
            set cardWeight [GetInvInfo $w $card 1]
            set qty [lindex [lindex $cardAndInv 1] 2]
            set swapShopConfig($w,cur${loc}PV) \
		[expr ($swapShopConfig($w,cur${loc}PV)) + ($qty * $cardWeight)]
        }
    }
    
    return
}

# Confirm --
#
#   Asks a question to confirm anything anomalyish
#
# Parameters:
#   w          : SwapShop toplevel
#
# Returns:
#    0 if no
#    1 if yes
#
proc SwapShop::Confirm {w msg} {

    variable swapShopConfig

    set result 0
    set answer [tk_messageBox -title "Swap Shop Warning" -icon question \
                    -message $msg -default no \
                    -type yesno -parent $w]
    
    if {$answer == "yes"} {
        set result 1
    }

    return $result
}

# ChangeInventory --
#
#   Adds the cards in the Incoming box to the inventory or
#   Removes the cards in the Outgoing box from the inventory 
#
# Parameters:
#   w        :  SwapShop toplevel
#   location :  Which textbox is being done.
#
# Returns:
#   Nothing.
#
proc SwapShop::ChangeInventory {w location} {
    variable swapShopConfig
    
    # Check the sendable flag to see that all cards are in the current
    # selected inventory.
    if {$swapShopConfig($w,Sendable) == "no"} {
        tk_messageBox -message "You cannot do this until the cards that are not in your inventory are removed from the outgoing box.  These are denoted by the purple color."
        return
    }

    # This procedure calls the Save procedure, so The current trade must be
    # saved before the button can be pressed.
    if {$swapShopConfig($w,fileName) == ""} {
        tk_messageBox -message "Trade must be saved before doing this!"
        return
    }

    set invFile [file join $swapShopConfig($w,curInvDir) $swapShopConfig($w,invFileName)]

    # This keeps the user from pressing the button when the inventory is
    # disabled.
    if {$swapShopConfig($w,invFileName) == "DISABLED"} {
        tk_messageBox -message "Why would you even think about pressing this button when you don't have an inventory specified?"
        return
    }

    if {$location == "inTextBox"} {
        set word "add cards to"
    } else {
        set word "remove cards from"
    }
    set msg "This button will $word your inventory and you will not be able to make any changes to this side of the trade again.  This cannot be undone.  Are you sure you want to do this?"
    set okToChange [SwapShop::Confirm $w $msg]
    if {$okToChange == "0"} {
        return
    }
    if {($invFile != "")} {
        Inventory::ReadInv $w $invFile
    } else {
        tk_messageBox -message "No inventory file was found!"
        return
    }

    $w config -cursor watch
    update
    foreach setID [CrossFire::CardSetIDList "real"] {
        set inv($setID) [Inventory::GetInvInfo $w inv[lindex $setID 0]]
    }

    foreach cardAndInv $swapShopConfig($w,trade$location) {
        set delta [lindex [lindex $cardAndInv 1] 2]
        if {$location == "outTextBox"} {set delta -$delta}
        set card [lindex $cardAndInv 0]
        set itemNum [lindex $card 1]
        set setID [lindex $card 0]
        set setInv $inv($setID)
        set cardInv [lindex $setInv $itemNum]
        set current [lindex $cardInv 1]
        set newQty [expr $current + $delta]
        set cardInv [lreplace $cardInv 1 1 $newQty]
        set inv($setID) [lreplace $setInv $itemNum $itemNum $cardInv]
    }

    set id [open $invFile "w"]
    puts $id "set tempInventory \{"
    foreach cardSet [CrossFire::CardSetIDList "real"] {
        set setInv $inv($cardSet)
        puts $id "    \{$cardSet\n"
        puts $id "        \{"
        puts -nonewline $id "            "
        
        set count 0
        foreach cardInv $setInv {
            puts -nonewline $id "\{$cardInv\} "
            incr count
            if {$count == 10} {
                puts -nonewline $id "\n            "
                set count 0
            }
        }

        puts $id "\n        \}"
        puts $id "    \}\n"
    }

    puts $id "\n\}"
    close $id
    SendReceive $w $location
    DisplayTrade $w $location
    if {$location == "outTextBox"} {
	set swapShopConfig($w,sentDate) \
	    [clock format [clock seconds] -format "%m/%d/%Y"]
    } elseif {$location == "inTextBox"} {
	set swapShopConfig($w,receivedDate) \
	    [clock format [clock seconds] -format "%m/%d/%Y"]
    }
    SaveTrade $w

    $w config -cursor {}

    return
}

# SendReceive --
#
#   Disables all associated buttons with the side of the trade
#   where the button was pushed.  If send was pushed it disables the
#   outgoing box from being altered and if received is pushed it
#   disables th incoming box from being altered.
#
# Parameters:
#   w          : Widget name of the trader.
#   location   : the box being disabled (inTextBox or outTextBox)
#
# Returns:
#   Returns nothing
#
proc SwapShop::SendReceive {w location} {
    variable swapShopConfig
    if {$location == "outTextBox"} {
        Disable $w $w.obuttons.add 0
        Disable $w $w.obuttons.remove 0
        Disable $w $w.obuttons.removeAll 0
        $w.outDelCardMenu entryconfigure 0 -state disabled
        $w.outDelCardMenu entryconfigure 1 -state disabled
        $w.outDelSetMenu entryconfigure 0 -state disabled
        $w.addMenu entryconfigure 0 -state disabled
        Disable $w $w.out.button.send 0
        set swapShopConfig($w,outState) disabled
    } elseif {$location == "inTextBox"} {
        Disable $w $w.ibuttons.add 0 
        Disable $w $w.ibuttons.remove 0
        Disable $w $w.ibuttons.removeAll 0
        $w.inDelCardMenu entryconfigure 0 -state disabled
        $w.inDelCardMenu entryconfigure 1 -state disabled
        $w.inDelSetMenu entryconfigure 0 -state disabled
        $w.addMenu entryconfigure 1 -state disabled
        Disable $w $w.in.button.receive 0
        set swapShopConfig($w,inState) disabled
    }
    if {[winfo exists $w.settings]} {
        Disable $w $w.settings.invinfo.cb 0
        Disable $w $w.settings.invinfo.button 0
    }

    return
}

# ExitSwapShop --
#
#   Gracefully closes the specified trader.  Checks if trade
#   needs to be saved before closing.
#
# Parameters:
#   w          : Widget name of the trader.
#
# Returns:
#   Returns 0 if exiting or -1 if exit canceled.
#
proc SwapShop::ExitSwapShop {w} {

    variable swapShopConfig

    if {[CheckForSave $w] == 0} {
        destroy $w

        UnLockFile $w

        if {[info exists swapShopConfig($w,autoSaveAfterID)]} {
            after cancel $swapShopConfig($w,autoSaveAfterID)
        }

        # Unset all the variables for the trader.
        foreach name [array names swapShopConfig "${w},*"] {
            unset swapShopConfig($name)
        }

        ViewCard::CleanUpCardViews $w
        CrossFire::UnRegister "SwapShop" $w

        return 0
    } else {
        return -1
    }
}

# SwapShop::ViewCard --
#
#   Views the currently selected card.
#
# Parameters:
#   w          : SwapShop toplevel.
#
# Returns:
#   Nothing.
#
proc SwapShop::ViewCard {w {location ""}} {

    ViewCard::View $w [GetSelectedCardID $w $location]

    return
}

