# SwapUtil.tcl 20030908
#
# This file contains all the utilities for the Swap Shop.
#
# Copyright (c) 1998-2003 Steve Brazelton and Dan Curtiss. All rights reserved.
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

# TradeStatus --
#
#   Creates or raises the trade status box for the trade
#   associated with the specified trader toplevel.
#
# Parameters:
#   w          : SwapShop toplevel path name.
#
# Returns:
#   Nothing.
#
proc SwapShop::TradeStatus {w} {

    variable swapShopConfig

    set dswt $w.status

    if {[winfo exists $dswt]} {
        wm deiconify $dswt
        raise $dswt
        return
    } 

    toplevel $dswt
    wm title $dswt "Trade Status"
    wm protocol $dswt WM_DELETE_WINDOW "$dswt.buttons.close invoke"
    bind $dswt <Key-Escape> "$dswt.buttons.close invoke"

    CrossFire::Transient $dswt

    set dsw $dswt.top

    frame $dsw -borderwidth 1 -relief raised

    frame $dsw.label
    label $dsw.label.out -anchor w -text Outgoing
    label $dsw.label.label -anchor center -text Frequency
    label $dsw.label.in -anchor e -text Incoming
    grid $dsw.label.out -column 0 -row 0 -sticky w
    grid $dsw.label.label -column 1 -row 0 -sticky ew -padx 10
    grid $dsw.label.in -column 2 -row 0 -sticky e

    frame $dsw.weight
    set row 0
    foreach freqID $CrossFire::cardFreqIDList {

        set freqName $CrossFire::cardFreqName($freqID)
        label $dsw.weight.row${row}out  -anchor w \
            -textvariable SwapShop::swapShopConfig($w,totalOut$freqID)
        label $dsw.weight.row${row}label -anchor center -text $freqName
        label $dsw.weight.row${row}in  -anchor e \
            -textvariable SwapShop::swapShopConfig($w,totalIn$freqID)

        grid $dsw.weight.row${row}out -column 0 -row $row -sticky w
        grid $dsw.weight.row${row}label -column 1 -row $row -sticky ew -padx 10
        grid $dsw.weight.row${row}in -column 2 -row $row -sticky e

        incr row
    }

    frame $dsw.total
    label $dsw.total.out -anchor w \
        -textvariable SwapShop::swapShopConfig($w,curOut)
    label $dsw.total.label -anchor center -text "Total Cards"
    label $dsw.total.in  -anchor e \
        -textvariable SwapShop::swapShopConfig($w,curIn)
    grid $dsw.total.out -column 0 -row 0 -sticky w
    grid $dsw.total.label -column 1 -row 0 -sticky ew -padx 10
    grid $dsw.total.in -column 2 -row 0 -sticky e

    frame $dsw.pv
    label $dsw.pv.out -anchor w \
        -textvariable SwapShop::swapShopConfig($w,curOutPV)
    label $dsw.pv.label -anchor center -text "Point Value"
    label $dsw.pv.in  -anchor e \
        -textvariable SwapShop::swapShopConfig($w,curInPV)
    grid $dsw.pv.out -column 0 -row 0 -sticky w
    grid $dsw.pv.label -column 1 -row 0 -sticky ew -padx 10
    grid $dsw.pv.in -column 2 -row 0 -sticky e

    grid columnconfigure $dsw.label {0 1 2} -weight 1
    grid columnconfigure $dsw.weight {0 1 2} -weight 1
    grid columnconfigure $dsw.total {0 1 2} -weight 1
    grid columnconfigure $dsw.pv {0 1 2} -weight 1

    grid $dsw.label -padx 3 -pady 5 -sticky ew
    grid $dsw.weight -padx 3 -pady 5 -sticky ew
    grid $dsw.total -padx 3 -pady 5 -sticky ew
    grid $dsw.pv -padx 3 -pady 5 -sticky ew
    grid columnconfigure $dsw 0 -weight 1

    frame $dswt.buttons -borderwidth 1 -relief raised
    button $dswt.buttons.close -text $CrossFire::close \
        -command "destroy $dswt"
    pack $dswt.buttons.close -pady 5

    grid $dsw -sticky nsew
    grid $dswt.buttons -sticky ew
    grid rowconfigure $dswt 0 -weight 1
    grid columnconfigure $dswt 0 -weight 1

    return
}

# TradeFinder --
#
#   Compares 2 inventory files and suggests trades 
#
# Parameters:
#   w        :  SwapShop toplevel
#
# Returns:
#   Nothing.
#
proc SwapShop::TradeFinder {w} {
    
    variable swapShopCount
    variable swapShopConfig
    
    set tfw $w.finder
    
    if {[winfo exists $tfw]} {
        wm deiconify $tfw
        raise $tfw
        return
    }

    if {$swapShopConfig($w,invFileName) != "DISABLED"} {
        set swapShopConfig($w,invTF1) $swapShopConfig($w,invFileName)
        set swapShopConfig($w,invTFLong1) \
            [file join $swapShopConfig($w,curInvDir) $swapShopConfig($w,invFileName)]
    } else {
        set swapShopConfig($w,invTF1) "No Inventory Selected"
    }
    set swapShopConfig($w,invTF2) "No Inventory Selected"

    toplevel $tfw
    wm title $tfw "Trade Finder"
    bind $tfw <Key-Escape> "$tfw.buttons.close invoke"
    bind $tfw <Key-Return> "$tfw.buttons.doit invoke"

    CrossFire::Transient $tfw
    
    # First vertical panel: Cards needed by the 1st inventory
    frame $tfw.first    

    button $tfw.first.select -text "Select..." -width 9 \
        -command "SwapShop::TFOpenInv $w 1"
    label $tfw.first.label -textvariable SwapShop::swapShopConfig($w,invTF1)

    frame $tfw.first.list
    text $tfw.first.list.t \
        -yscrollcommand "CrossFire::SetScrollBar $tfw.first.list.sb" \
        -width 25 -height 10 -exportselection 0 \
        -wrap none -cursor {} -bg white -fg black -spacing1 2
    $tfw.first.list.t tag configure cardSetHeader -font {Times 14 bold}
    $tfw.first.list.t tag configure select -foreground white -background blue
    scrollbar $tfw.first.list.sb -command "$tfw.first.list.t yview"
    grid $tfw.first.list.t -sticky nsew
    grid columnconfigure $tfw.first.list 0 -weight 1
    grid rowconfigure $tfw.first.list 0 -weight 1
    bind $tfw.first.list.t <ButtonPress-1> \
        "SwapShop::TFClickTextBox $w %X %Y 1 tfBox1"
    bind $tfw.first.list.t <ButtonRelease-1> \
        "CrossFire::CancelDrag $tfw.first.list.t"
    bindtags $tfw.first.list.t "$tfw.first.list.t all"

    CrossFire::DragTarget $tfw.first.list.t AddCard \
        "SwapShop::DragAddCard $w tfBox1"

    grid $tfw.first.select
    grid $tfw.first.label
    grid $tfw.first.list -sticky nsew
    grid columnconfigure $tfw.first 0 -weight 1
    grid rowconfigure $tfw.first 2 -weight 1
        
    # Second vertical panel: Cards needed by the 2nd inventory
    frame $tfw.second

    button $tfw.second.select -text "Select..." -width 9 \
        -command "SwapShop::TFOpenInv $w 2"
    label $tfw.second.label -textvariable SwapShop::swapShopConfig($w,invTF2)

    frame $tfw.second.list
    text $tfw.second.list.t \
        -yscrollcommand "CrossFire::SetScrollBar $tfw.second.list.sb" \
        -width 25 -height 10 -exportselection 0 \
        -wrap none -cursor {} -bg white -fg black -spacing1 2
    $tfw.second.list.t tag configure cardSetHeader -font {Times 14 bold}
    $tfw.second.list.t tag configure select -foreground white -background blue
    scrollbar $tfw.second.list.sb -command "$tfw.second.list.t yview"
    grid $tfw.second.list.t -sticky nsew
    grid columnconfigure $tfw.second.list 0 -weight 1
    grid rowconfigure $tfw.second.list 0 -weight 1
    bind $tfw.second.list.t <ButtonPress-1> \
        "SwapShop::TFClickTextBox $w %X %Y 1 tfBox2"
    bind $tfw.second.list.t <ButtonRelease-1> \
        "CrossFire::CancelDrag $tfw.second.list.t"
    bindtags $tfw.second.list.t "$tfw.second.list.t all"

    CrossFire::DragTarget $tfw.second.list.t AddCard \
        "SwapShop::DragAddCard $w tfBox2"

    grid $tfw.second.select
    grid $tfw.second.label
    grid $tfw.second.list -sticky nsew
    grid columnconfigure $tfw.second 0 -weight 1
    grid rowconfigure $tfw.second 2 -weight 1

    frame $tfw.buttons
    button $tfw.buttons.doit -text "Find Trade" \
        -command "SwapShop::FindTrade $w $tfw" -width 12
    button $tfw.buttons.slurp -text "Add all cards" \
        -command "SwapShop::FinderToTrade $w $tfw" -width 12
    button $tfw.buttons.close -text $CrossFire::close \
        -command "destroy $tfw" -width 12
    grid $tfw.buttons.doit $tfw.buttons.slurp $tfw.buttons.close \
        -padx 3 -pady 5

    # Grid the vertical panels
    grid $tfw.first -row 0 -column 0 -sticky nsew -padx 5 -pady 5
    grid $tfw.second -row 0 -column 1 -sticky nsew -padx 5 -pady 5
    grid $tfw.buttons -columnspan 2 -sticky nsew -padx 5 -pady 5
    grid columnconfigure $tfw {0 1} -weight 1
    grid rowconfigure $tfw 0 -weight 1

    return
}

proc SwapShop::TFOpenInv {w num} {
    variable swapShopConfig

    set fileName [tk_getOpenFile -initialdir $swapShopConfig($w,curInvDir) \
                      -title "Open CrossFire Inventory" \
                      -defaultextension $CrossFire::extension(inv) \
                      -filetypes $CrossFire::invFileTypes]
    if {$fileName != ""} {
        set swapShopConfig($w,invTF$num) [file tail $fileName]
        set swapShopConfig($w,invTFLong$num) $fileName
        $w.finder.first.list.t delete 1.0 end
        $w.finder.second.list.t delete 1.0 end
        return $fileName
    }
    return
}

proc SwapShop::FinderToTrade {w tfw} {
    if {[NewTrade $w] == -1} {
        return
    }
    $tfw configure -cursor watch
    $w configure -cursor watch
    update
    variable swapShopConfig
    if {$swapShopConfig($w,invTFBox1) == "" && $swapShopConfig($w,invTFBox2) == ""} {
        tk_messageBox -parent $tfw -icon error \
            -title "SwapShop - Data Error" -type ok \
            -message "Cannot add cards unless there are cards to add"
        $tfw configure -cursor {}
        $w configure -cursor {}
        return
    }
    set testInv \
        [file join $swapShopConfig($w,curInvDir) $swapShopConfig($w,invFileName)]
    if {$swapShopConfig($w,invTFLong1) == $testInv} {
        set box1 1
        set box2 2
    } elseif {$swapShopConfig($w,invTFLong2) == $testInv} {
        set box1 2
        set box2 1
    } else {
        tk_messageBox -parent $tfw -icon error \
            -title "SwapShop - Inventory File Error" -type ok \
            -message "Cannot add cards to trade unless finder inventory ($swapShopConfig($w,invTF1) or $swapShopConfig($w,invTF2)) matches trade inventory ($swapShopConfig($w,disInvFile))."
        $tfw configure -cursor {}
        $w configure -cursor {}
        return
    }
    foreach cardNAmt $swapShopConfig($w,invTFBox$box1) {
        set card [lindex $cardNAmt 0]
        set qty [lindex $cardNAmt 1]
        for {set i 0} {$i < $qty} {incr i} {
            AddCardToTrade $w $card inTextBox
        }
    }
    foreach cardNAmt $swapShopConfig($w,invTFBox$box2) {
        set card [lindex $cardNAmt 0]
        set qty [lindex $cardNAmt 1]
        for {set i 0} {$i < $qty} {incr i} {
            AddCardToTrade $w $card outTextBox
        }
    }
    DisplayTrade $w inTextBox
    DisplayTrade $w outTextBox
    SetChanged $w "true"
    CalcPointValue $w
    $tfw configure -cursor {}
    $w configure -cursor {}
    return
}

proc SwapShop::FindTrade {w tfw} {
    
    $tfw configure -cursor watch
    update
    variable swapShopConfig

    $w.finder.first.list.t delete 1.0 end
    $w.finder.second.list.t delete 1.0 end
    set tfb1 $w.finder.first.list.t
    set tfb2 $w.finder.second.list.t
    set invFile1 $swapShopConfig($w,invTFLong1)
    set invFile2 $swapShopConfig($w,invTFLong2)
    set swapShopConfig($w,invTFBox1) ""
    set swapShopConfig($w,invTFBox2) ""
    set setID1 ""
    set cardList1 ""
    set setID2 ""
    set cardList2 ""
    
    if {$invFile1 == ""} {
        return
    } else {
        if {[Inventory::ReadInv $w $invFile1] == 0} {
            tk_messageBox -parent $tfw -icon error \
                -title "Error Loading Inventory" -type ok \
                -message "Unable to load inventory file \"$invFile1\"."
            return
        }
        foreach setID [CrossFire::CardSetIDList "real"] {
            set inv(1,inv$setID) [Inventory::GetInvInfo $w inv$setID]
        }
    }
    
    if {$invFile2 == ""} {
        return
    } else {
        if {[Inventory::ReadInv $w $invFile2] == 0} {
            tk_messageBox -parent $tfw -icon error \
                -title "Error Loading Inventory" -type ok \
                -message "Unable to load inventory file \"$invFile1\"."
            return
        }
        foreach setID [CrossFire::CardSetIDList "real"] {
            set inv(2,inv$setID) [Inventory::GetInvInfo $w inv$setID]
        }
    }

    foreach cardSetID [CrossFire::CardSetIDList "real"] {

        if {[lsearch $swapShopConfig($w,allSetsList) $cardSetID] == -1} {
            continue
        }

        set index 1

        foreach card1 [lrange $inv(1,inv$cardSetID) 1 end] {
            set extras1 [expr [lindex $card1 1] - [lindex $card1 0]]
            set card2 [lindex $inv(2,inv$cardSetID) $index]
            set extras2 [expr [lindex $card2 1] - [lindex $card2 0]]
            if {($extras1 > 0) && ($extras2 < 0)} {
                set wants [expr -1 * $extras2]
                set cardID [format "%s/%03d" $cardSetID $index]
                set card [CrossFire::GetCard $cardID]
                set amt [lindex [lsort -integer "$wants $extras1"] 0]
                set cardNAmt "\{$card\} \{$amt\}"
                lappend swapShopConfig($w,invTFBox2) $cardNAmt
            } elseif {($extras1 < 0) && ($extras2 > 0)} {
                set wants [expr -1 * $extras1]
                set cardID [format "%s/%03d" $cardSetID $index]
                set card [CrossFire::GetCard $cardID]
                set amt [lindex [lsort -integer "$wants $extras2"] 0]
                set cardNAmt "\{$card\} \{$amt\}"
                lappend swapShopConfig($w,invTFBox1) $cardNAmt
            }
            incr index
        }
    }
    #                   ******
    set lineCount 0
    foreach cardSetID $swapShopConfig($w,allSetsList) {
        set cardSetName $CrossFire::setXRef($cardSetID,name)
        set displayedName 0
        
        foreach cardNAmt $swapShopConfig($w,invTFBox1) {
            set card [lindex $cardNAmt 0]
            set quantity [lindex $cardNAmt 1]
            
            if {[lindex $card 0] == $cardSetID} {
                if {$displayedName == 0} {
                    incr lineCount
                    if {$lineCount != 1} {
                        $tfb1 insert end "\n"
                    }
                    $tfb1 insert end "$cardSetName "
                    set displayedName 1
                }
                set desc [SwapShop::GetCardDesc $card]
                $tfb1 insert end "\n[format {%2d} $quantity] $desc"
            }
        }
    }
    set lineCount 0
    foreach cardSetID $swapShopConfig($w,allSetsList) {
        set cardSetName $CrossFire::setXRef($cardSetID,name)
        set displayedName 0
        
        foreach cardNAmt $swapShopConfig($w,invTFBox2) {
            set card [lindex $cardNAmt 0]
            set quantity [lindex $cardNAmt 1]
            
            if {[lindex $card 0] == $cardSetID} {
                if {$displayedName == 0} {
                    incr lineCount
                    if {$lineCount != 1} {
                        $tfb2 insert end "\n"
                    }
                    $tfb2 insert end "$cardSetName "
                    set displayedName 1
                }
                set desc [SwapShop::GetCardDesc $card]
                $tfb2 insert end "\n[format {%2d} $quantity] $desc"
            }
        }
    }
    $tfw configure -cursor {}
}

# TFClickTextBox --
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
proc SwapShop::TFClickTextBox {w X Y btnNumber location} {

    variable swapShopConfig

    set tw $swapShopConfig($w,$location)

    # Remove the highlight from the two text boxes
    $swapShopConfig($w,tfBox1) tag remove select 1.0 end
    $swapShopConfig($w,tfBox2) tag remove select 1.0 end

    # Translate X,Y coordinates to x,y of text box.
    set x [expr $X - [winfo rootx $tw]]
    set y [expr $Y - [winfo rooty $tw]]

    set pos [lindex [split [$tw index @$x,$y] .] 0]

    if {$swapShopConfig($w,$location) != {}} {
        $tw tag add select $pos.0 [expr $pos + 1].0
    }
    switch -- $btnNumber {
        1 {
            # Start the drag-n-drop routines.
            # Commented out because it needs to be disabled after inventory
            # adjustments.
            #                CrossFire::StartDrag $tw pirate RemoveCard tempID
        }

        2 {
            #                 RemoveCard $w $location 1
        }

        3 {
            # Pop-up Menu
            if {$location == "tfBox1"} {
                tk_popup $w.finder.tfBox1Menu $X $Y
            } else {
                tk_popup $w.finder.tfBox2Menu $X $Y
            }
        }
    }


    return
}

# TradeRater --
#
#   Rates a trade based on Value, Timing, Ease of Trade, and Overall Rating 
#
# Parameters:
#   w        :  SwapShop toplevel
#
# Returns:
#   Nothing.
#
proc SwapShop::TradeRater {w} {
    
    variable swapShopConfig

    set tradeEase ""
    set tradeORating ""
    set swapShopConfig($w,daysPast) \
	[expr ([clock scan "$swapShopConfig($w,receivedDate)"] - \
                   [clock scan "$swapShopConfig($w,sentDate)"]) / 86400]
    set trw $w.rater
    
    if {[winfo exists $trw]} {
        wm deiconify $trw
        raise $trw
        return
    }

    toplevel $trw
    wm title $trw "Trade Rater"
    wm protocol $trw WM_DELETE_WINDOW "$trw.buttons.close invoke"
    bind $trw <Key-Escape> "$trw.buttons.close invoke"

    frame $trw.rate -borderwidth 1 -relief raised

    frame $trw.rate.name
    label $trw.rate.name.l -text "Trader's Name:" -width 15 -anchor e
    entry $trw.rate.name.e -width 30 \
        -textvariable SwapShop::swapShopConfig($w,traderName)
    grid $trw.rate.name.l $trw.rate.name.e -sticky ew
    grid columnconfigure $trw.rate.name 1 -weight 1
    grid $trw.rate.name -sticky ew -padx 5 -pady 5
    focus $trw.rate.name.l

    frame $trw.rate.email
    label $trw.rate.email.l -text "Trader's Email:" -width 15 -anchor e
    entry $trw.rate.email.e -width 30 \
        -textvariable SwapShop::swapShopConfig($w,traderEmail)
    grid $trw.rate.email.l $trw.rate.email.e -sticky ew
    grid columnconfigure $trw.rate.email 1 -weight 1
    grid $trw.rate.email -sticky ew -padx 5 -pady 5

    frame $trw.rate.f

    frame $trw.rate.f.value

    frame $trw.rate.f.value.you
    label $trw.rate.f.value.you.l  -text "Your Value:" -width 12 -anchor e
    label $trw.rate.f.value.you.v -background white -foreground black \
        -textvariable SwapShop::swapShopConfig($w,curOutPV) -width 3 \
        -anchor e
    grid $trw.rate.f.value.you.l $trw.rate.f.value.you.v -sticky ew
    grid $trw.rate.f.value.you -sticky ew -padx 5 -pady 5

    frame $trw.rate.f.value.them
    label $trw.rate.f.value.them.l -text "Their Value:" -width 12 -anchor e
    label $trw.rate.f.value.them.v -background white -foreground black \
        -textvariable SwapShop::swapShopConfig($w,curInPV) -width 3 \
        -anchor e
    grid $trw.rate.f.value.them.l $trw.rate.f.value.them.v -sticky ew
    grid $trw.rate.f.value.them -sticky ew -padx 5 -pady 5

    frame $trw.rate.f.value.timing
    label $trw.rate.f.value.timing.l -text "Days:" -width 12 -anchor e
    label $trw.rate.f.value.timing.v -background white -foreground black \
        -textvariable SwapShop::swapShopConfig($w,daysPast) -width 3 \
        -anchor e
    grid $trw.rate.f.value.timing.l $trw.rate.f.value.timing.v -sticky ew
    grid $trw.rate.f.value.timing -sticky ew -padx 5 -pady 5

    grid $trw.rate.f.value -sticky nw

    set f $trw.rate.f.rbs
    frame $f
    label $f.easeL -text "Ease:" -width 12 -anchor e
    label $f.packagingL -text "Packaging:" -width 12 -anchor e
    label $f.conditionL -text "Condition:" -width 12 -anchor e
    label $f.overallL -text "Overall:" -width 12 -anchor e
    frame $f.easeChoices
    frame $f.packaging
    frame $f.condition
    frame $f.overallChoices
    set maxScore 5
    for {set i 1} {$i <= $maxScore} {incr i} {
        radiobutton $f.easeChoices.easeRB$i -text $i -indicatoron 0 \
            -variable SwapShop::swapShopConfig($w,tradeEase) -value $i
        radiobutton $f.packaging.packRB$i -text $i -indicatoron 0 \
            -variable SwapShop::swapShopConfig($w,tradePacking) -value $i
        radiobutton $f.condition.condRB$i -text $i -indicatoron 0 \
            -variable SwapShop::swapShopConfig($w,tradeCondition) -value $i
        radiobutton $f.overallChoices.overallRB$i -text $i -indicatoron 0 \
            -variable SwapShop::swapShopConfig($w,tradeORating) -value $i
        pack $f.easeChoices.easeRB$i       -side left
        pack $f.packaging.packRB$i         -side left
        pack $f.condition.condRB$i         -side left
        pack $f.overallChoices.overallRB$i -side left
    }
    grid $f.easeL $f.easeChoices -pady 3
    grid $f.packagingL $f.packaging -pady 3
    grid $f.conditionL $f.condition -pady 3
    grid $f.overallL $f.overallChoices -pady 3

    grid $trw.rate.f.rbs -row 0 -column 1 -sticky e

    grid $trw.rate.f -sticky ew -padx 5 -pady 5
    grid columnconfigure $trw.rate.f {0 1} -weight 1

    frame $trw.rate.notes
    label $trw.rate.notes.l -text "Notes:"
    grid $trw.rate.notes.l -sticky w
    frame $trw.rate.notes.text
    text $trw.rate.notes.text.t -width 30 -height 4 -foreground black \
        -background white -wrap word \
        -yscrollcommand "CrossFire::SetScrollBar $trw.rate.notes.text.sb"
    set swapShopConfig($w,raterNotesW) $trw.rate.notes.text.t
    scrollbar $trw.rate.notes.text.sb -command "$trw.rate.notes.text.sb yview"
    grid $trw.rate.notes.text.t -sticky nsew
    grid columnconfigure $trw.rate.notes.text 0 -weight 1
    grid rowconfigure $trw.rate.notes.text 0 -weight 1
    grid $trw.rate.notes.text -sticky nsew
    grid $trw.rate.notes -sticky nsew -padx 5 -pady 5
    grid columnconfigure $trw.rate.notes 0 -weight 1
    grid rowconfigure $trw.rate.notes 1 -weight 1

    grid $trw.rate -sticky nsew
    grid columnconfigure $trw.rate 0 -weight 1
    grid rowconfigure $trw.rate 3 -weight 1

    frame $trw.buttons -borderwidth 1 -relief raised
    button $trw.buttons.save -text "Save" -state disabled \
        -command ""
    button $trw.buttons.close -text $CrossFire::close \
        -command "destroy $trw"
    grid $trw.buttons.save $trw.buttons.close -padx 5 -pady 5
    grid $trw.buttons -sticky ew

    grid columnconfigure $trw 0 -weight 1
    grid rowconfigure $trw 0 -weight 1

    return
}
