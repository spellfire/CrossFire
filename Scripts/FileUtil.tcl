# FileUtil.tcl 20051122
#
# This file contains all the Utility procedures for Card Warehouse.
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

# Inventory::About --
#
#   Displays an about dialog for the CrossFire Inventory.
#
# Paramters:
#   w         : Parent toplevel for the pop-up dialog.
#
# Returns:
#   Nothing.
#
proc Inventory::About {w} {
    set message "CrossFire Card Warehouse\n"
    append message "\nby Dan Curtiss"
    tk_messageBox -icon info -parent $w -message $message \
        -title "About Card Warehouse"

    return
}

# Inventory::ConvertCardList --
#
#   Converts a regular or chase card list into the requested list type.
#
# Parameters:
#   w          : Inventory toplevel.
#   type       : Type of report to generate.
#   cardList   : List of cards.
#
# Returns:
#   List of cards in requested list type.
#
proc Inventory::ConvertCardList {w type cardList} {

    variable invConfig

    set cardListOut ""

    foreach cardNumberQty $cardList {

        foreach {cardNumber qty} $cardNumberQty {break}
        if {$qty < 0} {
            set qty 0
        }

        set cardInfo ""
        switch $invConfig($w,listDisplayMode) {
            "standard" {
                set cardInfo "${cardNumber}($qty)"
            }
            "normalV"  {
                if {$qty > 0} {
                    set cardInfo "${cardNumber}($qty)"
                }
            }
            "normal" {
                if {$qty > 0} {
                    set cardInfo $cardNumber
                    if {$qty != 1} {
                        append cardInfo "($qty)"
                    }
                }
            }
            "brief" {
                if {$qty > 0} {
                    set cardInfo $cardNumber
                }
            }
            "inventory" {
                if {$qty != 0} {
                    set cardInfo "${cardNumber}-[format %02d $qty]"
                }
            }
            "fullinv" {
                set cardInfo "${cardNumber}-[format %02d $qty]"
            }
            "expanded" {
                for {set i 1} {$i <= $qty} {incr i} {
                    lappend cardInfo $cardNumber
                }
            }
        }

        if {$cardInfo != ""} {
            if {$cardListOut != ""} {
                append cardListOut " $cardInfo"
            } else {
                set cardListOut $cardInfo
            }
        }
    }

    regsub -all " " $cardListOut ", " cardListOut

    return $cardListOut
}

# Inventory::CreateCardList --
#
#   Calls ConvertCardList on each list (regular and chase) and then
#   merges them into a list if report is brief or all card sets.
#
# Parameters:
#   w          : Inventory toplevel.
#   type       : Type of report to generate.
#   regular    : List of regular cards.
#   chase      : List of chase cards.
#
# Returns:
#   Two element list of requested list types.
#
proc Inventory::CreateCardList {w type regular chase} {

    variable invConfig

    set regularListOut [ConvertCardList $w $type "$regular"]
    set chaseListOut [ConvertCardList $w $type "$chase"]

    if {($invConfig($w,cardSet) != "All") &&
        ($invConfig($w,reportFormat) == "Brief")} {
        if {$regularListOut == ""} {
            set regularListOut $chaseListOut
        } elseif {$chaseListOut != ""} {
            set regularListOut "$regularListOut, $chaseListOut"
        }
        set chaseListOut ""
    }

    return [list $regularListOut $chaseListOut]
}

# Inventory::ProcessSet --
#
#   This procedure creates a list of cards (in "expanded" mode) that
#   matches the report type.  Extras, Wants, etc.  Calls CreateCardList
#   to convert the list to the specified mode.
#
# Parameters:
#   w          : Inventory toplevel.
#   cardSet    : Card set ID to process.
#   type       : Type of report to generate.
#
# Returns:
#   Nothing.
#
proc Inventory::ProcessSet {w cardSet type} {

    variable invConfig

    set tbw $invConfig($w,reportTextBox)
    set setInv $invConfig($w,inv$cardSet)
    set max $CrossFire::setXRef($cardSet,setMax)
    set setName $CrossFire::setXRef($cardSet,name)
    set regularList ""
    set chaseList ""

    CrossFire::ReadCardDataBase $cardSet

    # Check the inventory for each card and add to the appropriate list
    # the expanded quantity of the card.
    foreach card [lrange $CrossFire::cardDataBase 1 end] {

        set cardNumber [lindex $card 1]

        # Skip non-existant cards.
        if {[lindex $card 6] == "(no card)"} {
            continue
        }

        set cardQty [lindex $setInv $cardNumber]
        set wanted [lindex $cardQty 0]
        set onHand [lindex $cardQty 1]
        set premium [lindex $cardQty 2]
        set cardNumberText $cardNumber

        # Add the leading c for chase cards depending on the format.
        if {$cardNumber > $max} {
            if {$invConfig($w,reportFormat) == "HTML"} {
                set cardNumberText "[expr $cardNumber - $max]"
            } else {
                set cardNumberText "c[expr $cardNumber - $max]"
            }
        }

        if {$premium == 1} {
            if {$invConfig($w,reportFormat) == "HTML"} {
                set cardNumberText "<B>$cardNumber</B>"
            } else {
                set cardNumberText "*$cardNumber"
            }
        }

        if {$type == "inv"} {
            set qty $onHand
        } elseif {$type == "want"} {
            set qty [expr $wanted - $onHand]
        } elseif {$type == "extra"} {
            set qty [expr $onHand - $wanted]
        }

        if {$cardNumber <= $max} {
            lappend regularList "$cardNumberText $qty"
        } else {
            lappend chaseList "$cardNumberText $qty"
        }
    }

    set tempFormat $invConfig($w,reportFormat)
    # All done; insert into text box.
    if {$tempFormat != "Verbose" && $tempFormat != "Full"} {
        set newLists [CreateCardList $w $type "$regularList" "$chaseList"]
        set regularList [CrossFire::SplitLine 48 [lindex $newLists 0]]
        set chaseList [CrossFire::SplitLine 48 [lindex $newLists 1]]

        if {($regularList != "") || ($chaseList !="")} {

            if {$invConfig($w,reportFormat) == "HTML"} {
                $tbw insert end "<TABLE BORDER=1 CELLPADDING=3 WIDTH=\"100%\">\n"
                $tbw insert end "<TR><TH COLSPAN=2 ALIGN=left>$setName\n"
                if {$regularList != ""} {
                    $tbw insert end \
                        "<TR><TD WIDTH=\"15%\">Regular<TD WIDTH=\"85%\">\n"
                    $tbw insert end "$regularList\n"
                }
                if {$chaseList != ""} {
                    $tbw insert end \
                        "<TR><TD WIDTH=\"15%\">Chase<TD WIDTH=\"85%\">\n"
                    $tbw insert end "$chaseList\n"
                }
                $tbw insert end "</TABLE><BR><BR>\n"

            } else {
                if {($invConfig($w,cardSet) == "All") ||
                    ([llength $invConfig($w,cardSet)] > 1)} {
                    if {$regularList != ""} {
                        $tbw insert end "Set: $setName\n"
                        $tbw insert end "$regularList\n"
                    }
                    if {$chaseList != ""} {
                        $tbw insert end "Set: $setName Chase\n"
                        $tbw insert end "$chaseList\n"
                    }
                } else {
                    $tbw insert end "$regularList\n"
                }
            }
            $tbw insert end "\n"
        }
    } else {
        # Verbose format
        set printedHeader 0
        foreach cardNumberQty "$regularList $chaseList" {

            foreach {tempCardNumber qty} $cardNumberQty break
            if {$qty < 0} {
                set qty 0
            }

            # Check for and remove leading * (identifies premium cards)
            set premium [regsub {\*} $tempCardNumber "" tempCardNumber]

            # Adjust card number if it is a chase card.
            if {[regexp "c" $tempCardNumber] != 0} {
                regsub "c" $tempCardNumber "" cardNumber
                set cardNumber [expr $cardNumber + $max]
            } else {
                set cardNumber $tempCardNumber
            }

            # Add * back on to the card number for premium cards
            if {$premium == 1} {
                set tempCardNumber "*[format %3s $tempCardNumber]"
            }

            if {($qty != 0) ||
                (($qty == 0) && ($type == "inv") && ($tempFormat == "Full"))} {
                if {$printedHeader == 0} {
                    if {($invConfig($w,cardSet) == "All") ||
                        ([llength $invConfig($w,cardSet)] > 1)} {
                        $tbw insert end "Set: $setName\n"
                    }
                    $tbw insert end \
			[format "%3s %-30.30s %-14.14s %-2s  %3s\n" \
			     "#" "Name" "Type" "Rarity" "Qty"]
                    set printedHeader 1
                }
                set card [lindex $CrossFire::cardDataBase $cardNumber]
                set cardName [lindex $card 6]
		set cardType $CrossFire::cardTypeXRef([lindex $card 3],name)
                set rarity [lindex $card 8]
                $tbw insert end \
                    [format "%3s %-30.30s %-14.14s   %-2s    %3d\n" \
                         $tempCardNumber $cardName $cardType $rarity $qty]
            }
        }

        if {$printedHeader == 1} {
            $tbw insert end "\n"
        }
    }

    return
}

# Inventory::Report --
#
#   Creates the report window and calls ProcessSet for each set.
#
# Parameters:
#   w          : Inventory toplevel.
#   type       : Type of report to generate. (inv, extra, want)
#
# Returns:
#   Nothing.
#
proc Inventory::Report {w type} {

    variable invConfig

    $w config -cursor watch
    update

    set tw $w.report

    if {[winfo exists $tw]} {
        wm deiconify $tw
        raise $tw
        $tw.buttons.save configure -command \
	    "Inventory::SaveReport $w [list $invConfig($w,cardSet)] $type"
    } else {
        toplevel $tw

        CrossFire::Transient $tw

        frame $tw.list -borderwidth 1 -relief raised
        text $tw.list.t -font {Courier 10} -width 63 -height 20 \
            -yscrollcommand "CrossFire::SetScrollBar $tw.list.sb"
        scrollbar $tw.list.sb -command "$tw.list.t yview"
        grid $tw.list.t $tw.list.sb -sticky nsew
        grid columnconfigure $tw.list 0 -weight 1
        grid rowconfigure $tw.list 0 -weight 1
        grid $tw.list -sticky nsew

        frame $tw.buttons -borderwidth 1 -relief raised
        button $tw.buttons.close -text $CrossFire::close \
            -command "destroy $tw"
        button $tw.buttons.save -text "Save" -command \
	    "Inventory::SaveReport $w [list $invConfig($w,cardSet)] $type"
        grid $tw.buttons.save $tw.buttons.close -pady 5 -padx 5

        grid $tw.buttons -sticky nsew

        grid columnconfigure $tw 0 -weight 1
        grid rowconfigure $tw 0 -weight 1

        bind $tw <Key-Escape> "$tw.buttons.close invoke"
        bind $tw <Key-Return> "$tw.buttons.save invoke"
    }

    set tbw $tw.list.t
    set invConfig($w,reportTextBox) $tbw
    $tbw delete 1.0 end

    # Label the window depending on the type of report.
    set fileName [file tail $invConfig($w,fileName)]
    if {$type == "want"} {
        wm title $tw "Wanted Cards - $fileName"
        set title "Wanted Cards"
    } elseif {$type == "extra"} {
        wm title $tw "Extra Cards - $fileName"
        set title "Extra Cards"
    } else {
        wm title $tw "Inventory - $fileName"
        set title "Inventory"
    }

    set authorName $Config::config(CrossFire,authorName)
    set authorEmail $Config::config(CrossFire,authorEmail)

    # Add the header infomation for HTML reports.
    if {$invConfig($w,reportFormat) == "HTML"} {
        $tbw insert end "<HTML>\n<HEAD>\n<TITLE>"
        if {$authorName != ""} {
            $tbw insert end "$authorName's "
        }
        $tbw insert end "$title</TITLE>\n</HEAD>\n<BODY>\n"
        $tbw insert end "<H2 ALIGN=center>$title</H2>\n\n"
    }

    # Call ProcessSet for the specified set or for each
    # set (selected in configure) if "All card sets" selected.
    if {$invConfig($w,cardSet) == "All"} {
        foreach cardSet [CrossFire::CardSetIDList "real"] {
            if {[lsearch $invConfig($w,allSetsList) $cardSet] != -1} {
                ProcessSet $w $cardSet $type
            }
        }
    } else {
        foreach setID $invConfig($w,cardSet) {
            ProcessSet $w $setID $type
        }
    }

    if {$invConfig($w,reportFormat) == "HTML"} {
        if {$authorEmail != ""} {
            if {$authorName != ""} {
                set printedName $authorName
            } else {
                set printedName $authorEmail
            }
            $tbw insert end "<BR>\n<CENTER>Email: "
            $tbw insert end "<A HREF=\"mailto:$authorEmail\">"
            $tbw insert end "$printedName</A><CENTER>\n"
        }
        $tbw insert end "</BODY>\n</HTML>"
    }

    $w config -cursor {}

    return
}

# Inventory::SaveReport --
#
#   Saves a generated report.
#
# Parameters:
#   w          : Inventory toplevel.
#   cardSet    : Card set ID(s)
#   type       : Type of report to generate. (inv, extra, want)
#
# Returns:
#   Nothing.
#
proc Inventory::SaveReport {w cardSet type} {

    variable invConfig

    if {$CrossFire::platform == "macintosh"} {
        if {$invConfig($w,reportFormat) == "HTML"} {
            set reportFileTypes {
                {{HTML Files} {} TEXT}
                {{All Files} *}
            }
        } else {
            set reportFileTypes {
                {{Report Files} {} TEXT}
                {{All Files} *}
            }
        }
    } else {
        if {$invConfig($w,reportFormat) == "HTML"} {
            set reportFileTypes {
                {{HTML Files} {.html}}
                {{All Files} *}
            }
        } else {
            set reportFileTypes {
                {{Report Files} {.txt}}
                {{All Files} *}
            }
        }
    }

    # Suggest a filename based on card set and type of report.
    if {$invConfig($w,reportFormat) == "HTML"} {
        set ext ".html"
    } else {
        set ext ".txt"
    }

    set tempFileName "[CrossFire::GetIDListName $cardSet]_$type$ext"

    set fileName \
        [tk_getSaveFile -initialdir $invConfig($w,reportDir) \
             -initialfile $tempFileName \
             -defaultextension $ext \
             -title "Save Inventory Report" \
             -filetypes $reportFileTypes]

    if {$fileName == ""} {
        return
    }

    set invConfig($w,reportDir) [file dirname $fileName]
    set report [$invConfig($w,reportTextBox) get 1.0 end]
    set fid [open $fileName "w"]
    puts -nonewline $fid $report
    close $fid

    return
}

# Inventory::SetMaxQty --
#
#   Creates a window for setting the maximum desired number of
#   cards for both regular and chase cards.  This will be done
#   for a specific set of cards or all sets.  A call is made to
#   ChangeMaxQty to actually make the change.
#
# Parameters:
#   w          : Inventory toplevel.
#
# Returns:
#   Nothing.
#
proc Inventory::SetMaxQty {w} {

    variable invConfig

    set tw $w.setmax

    if {[winfo exists $tw]} {
        wm deiconify $tw
        raise $tw
        return
    }

    toplevel $tw
    wm title $tw "Change Wanted Quantity"

    CrossFire::Transient $tw

    foreach setID [CrossFire::CardSetIDList "realAll"] {
        lappend cardSets $CrossFire::setXRef($setID,name)
    }

    foreach className {Edition Booster International} {
        lappend cardSets $className
    }

    frame $tw.top -borderwidth 1 -relief raised
    label $tw.top.lSet -text "Card Set:"
    menubutton $tw.top.selectMenu -indicatoron 1 \
        -menu $tw.top.selectMenu.menu -relief raised \
        -textvariable Inventory::invConfig($w,changeQtySelection)
    menu $tw.top.selectMenu.menu -tearoff 0
    foreach cardSet $cardSets {
        $tw.top.selectMenu.menu add radiobutton \
            -value $cardSet -label $cardSet -command "focus $tw" \
            -variable Inventory::invConfig($w,changeQtySelection)
    }
    $tw.top.selectMenu configure -width 18
    if {[llength $invConfig($w,cardSet)] == 1} {
        set invConfig($w,changeQtySelection) \
            $CrossFire::setXRef($invConfig($w,cardSet),name)
    } else {
        set invConfig($w,changeQtySelection) \
            [CrossFire::GetIDListName $invConfig($w,cardSet)]
    }

    label $tw.top.lReg -text "Regular:"
    entry $tw.top.eReg -width 3 -justify right \
        -textvariable Inventory::invConfig($w,qtyReg)
    set invConfig($w,qtyReg) ""

    label $tw.top.lChase -text "Chase:"
    entry $tw.top.eChase -width 3 -justify right \
        -textvariable Inventory::invConfig($w,qtyChase)
    set invConfig($w,qtyChase) ""

    grid $tw.top.lSet $tw.top.selectMenu -sticky w -pady 3 -padx 3
    grid $tw.top.lReg $tw.top.eReg -sticky w -pady 3 -padx 3
    grid $tw.top.lChase $tw.top.eChase -sticky w -pady 3 -padx 3

    frame $tw.buttons -borderwidth 1 -relief raised
    button $tw.buttons.doit -text "Change" \
        -command "Inventory::ChangeMaxQty $w"
    button $tw.buttons.quit -text $CrossFire::close \
        -command "destroy $tw"
    grid $tw.buttons.doit $tw.buttons.quit -pady 5 -padx 5

    grid $tw.top -sticky nsew
    grid $tw.buttons -sticky nsew

    grid columnconfigure $tw 0 -weight 1
    grid rowconfigure $tw 0 -weight 1

    bind $tw <Key-Escape> "$tw.buttons.quit invoke"
    bind $tw <Key-Return> "$tw.buttons.doit invoke"

    return
}

# Inventory::ChangeMaxQty --
#
#   Changes the maximum desired quantity of cards for both
#   regular and chase cards for a specific set or all sets.
#
# Parameters:
#   w          : Inventory toplevel SetMaxQty is a child of.
#
# Returns:
#   Nothing.
#
proc Inventory::ChangeMaxQty {w} {

    variable invConfig

    if {$invConfig($w,qtyReg) == ""} {
        set invConfig($w,qtyReg) "+0"
    }

    if {$invConfig($w,qtyChase) == ""} {
        set invConfig($w,qtyChase) "+0"
    }

    set maxRegular $invConfig($w,qtyReg)
    set maxChase $invConfig($w,qtyChase)

    if {[info exists CrossFire::setXRef($invConfig($w,changeQtySelection))]} {
        set setID $CrossFire::setXRef($invConfig($w,changeQtySelection))
    } else {
        set classID $CrossFire::setClass($invConfig($w,changeQtySelection))
        set setID [CrossFire::CardSetIDList $classID]
    }

    # If "All card sets" is selected, change the list to all
    # of the available sets.
    if {$setID == "All"} {
        set setID $invConfig($w,allSetsList)
    }

    foreach tempSetID $setID {

        set setInv $invConfig($w,inv$tempSetID)
        set setMax $CrossFire::setXRef($tempSetID,setMax)
        set cardNum 0

        set maxQty $maxRegular
        foreach cardInv [lrange $setInv 1 end] {
            incr cardNum

            if {$cardNum > $setMax} {
                set maxQty $maxChase
            }

            set firstChar [string range $maxQty 0 0]
            if {($firstChar == "+") || ($firstChar == "-")} {
                set max [lindex $cardInv 0]
                set max [expr $max + int($maxQty)]
            } else {
                set max $maxQty
            }

            if {$max < 0} {
                set max 0
            }

            set cardInv [lreplace $cardInv 0 0 $max]
            set setInv [lreplace $setInv $cardNum $cardNum $cardInv]
        }
        set invConfig($w,inv$tempSetID) $setInv
    }

    ClickListBox $w m 0 0
    SetChanged $w "true"

    return
}

# Inventory::CardCounter --
#
#   Creates a window for counting the number of cards in a set
#   or all sets combined.  Has a checkbutton to select if the
#   minimum quantity of cards should include chase or not.  A
#   call is made to CountCards to actually do the counting.
#
# Parameters:
#   w          : Inventory toplevel.
#
# Returns:
#   Nothing.
#
proc Inventory::CardCounter {w} {

    variable invConfig

    set tw $w.cardCount

    if {[winfo exists $tw]} {
        wm deiconify $tw
        raise $tw
        return
    }

    toplevel $tw
    wm title $tw "Card Counter"

    CrossFire::Transient $tw

    foreach setID [CrossFire::CardSetIDList "realAll"] {
        lappend cardSets $CrossFire::setXRef($setID,name)
    }

    foreach className {Edition Booster International} {
        lappend cardSets $className
    }

    frame $tw.top -borderwidth 1 -relief raised

    frame $tw.top.set
    label $tw.top.set.l -text "Card Set:"
    menubutton $tw.top.set.selectMenu -indicatoron 1 \
        -menu $tw.top.set.selectMenu.menu -relief raised \
        -textvariable Inventory::invConfig($w,countSelection)
    menu $tw.top.set.selectMenu.menu -tearoff 0
    foreach cardSet $cardSets {
        $tw.top.set.selectMenu.menu add radiobutton \
            -value $cardSet -label $cardSet -command "focus $tw" \
            -variable Inventory::invConfig($w,countSelection)
    }
    $tw.top.set.selectMenu configure -width 18
    if {[llength $invConfig($w,cardSet)] == 1} {
        set invConfig($w,countSelection) \
            $CrossFire::setXRef($invConfig($w,cardSet),name)
    } else {
        set invConfig($w,countSelection) \
            [CrossFire::GetIDListName $invConfig($w,cardSet)]
    }
    grid $tw.top.set.l $tw.top.set.selectMenu

    set entryWidth 6

    frame $tw.top.max
    label $tw.top.max.l -text "Maximum:" -width 8 -anchor e
    entry $tw.top.max.e -width $entryWidth -justify right -state disabled \
        -textvariable Inventory::invConfig($w,countMax) -cursor {}
    grid $tw.top.max.l $tw.top.max.e

    frame $tw.top.min
    label $tw.top.min.l -text "Minimum:" -width 8 -anchor e
    entry $tw.top.min.e -width $entryWidth -justify right -state disabled \
        -textvariable Inventory::invConfig($w,countMin) -cursor {}
    checkbutton $tw.top.min.cb -text "Include Chase" \
        -variable Inventory::invConfig($w,includeChase)
    set invConfig($w,includeChase) 1
    grid $tw.top.min.l $tw.top.min.e $tw.top.min.cb

    frame $tw.top.total
    label $tw.top.total.l -text "Total:" -width 8 -anchor e
    entry $tw.top.total.e -width $entryWidth -justify right -cursor {} \
        -textvariable Inventory::invConfig($w,countTotal) -state disabled
    grid $tw.top.total.l $tw.top.total.e

    frame $tw.top.value
    label $tw.top.value.l -text "Value:" -width 8 -anchor e
    entry $tw.top.value.e -width $entryWidth -justify right -cursor {} \
        -textvariable Inventory::invConfig($w,countValue) -state disabled
    grid $tw.top.value.l $tw.top.value.e

    frame $tw.top.score
    label $tw.top.score.l -text "Score:" -width 8 -anchor e
    entry $tw.top.score.e -width $entryWidth -justify right -cursor {} \
        -textvariable Inventory::invConfig($w,countScore) -state disabled
    label $tw.top.score.of -text "of"
    entry $tw.top.score.eMax -width $entryWidth -justify right -cursor {} \
        -textvariable Inventory::invConfig($w,countScoreMax) -state disabled
    grid $tw.top.score.l $tw.top.score.e $tw.top.score.of \
        $tw.top.score.eMax -sticky ew
    grid columnconfigure $tw.top.score {1 3} -weight 1

    grid $tw.top.set   -sticky w -pady 3 -padx 3
    grid $tw.top.max   -sticky w -pady 3 -padx 3
    grid $tw.top.min   -sticky w -pady 3 -padx 3
    grid $tw.top.total -sticky w -pady 3 -padx 3
    grid $tw.top.value -sticky w -pady 3 -padx 3
    grid $tw.top.score -sticky w -pady 3 -padx 3

    grid columnconfigure $tw.top 0 -weight 1

    frame $tw.buttons -borderwidth 1 -relief raised
    button $tw.buttons.doit -text "Count" \
        -command "Inventory::CountCards $w"
    button $tw.buttons.quit -text $CrossFire::close -command "destroy $tw"
    grid $tw.buttons.doit $tw.buttons.quit -pady 5 -padx 5

    grid $tw.top -sticky nsew
    grid $tw.buttons -sticky nsew

    grid columnconfigure $tw 0 -weight 1
    grid rowconfigure $tw 0 -weight 1

    bind $tw <Key-Escape> "$tw.buttons.quit invoke"
    bind $tw <Key-Return> "$tw.buttons.doit invoke"

    return
}

# Inventory::CountCards --
#
#   Counts the total number of cards and the most and least
#   quantities of a card.  Optionally includes chase cards
#   in the calculation of least quantity.
#
# Parameters:
#   w          : Inventory toplevel CardCounter is a child of.
#
# Returns:
#   Nothing.
#
proc Inventory::CountCards {w} {

    variable invConfig

    if {[info exists CrossFire::setXRef($invConfig($w,countSelection))]} {
        set setID $CrossFire::setXRef($invConfig($w,countSelection))
    } else {
        set classID $CrossFire::setClass($invConfig($w,countSelection))
        set setID [CrossFire::CardSetIDList $classID]
    }

    # If "All card sets" is selected, change the list to all
    # of the available sets.
    if {$setID == "All"} {
        set setID $invConfig($w,allSetsList)
    }

    set totalCards 0
    set maxQty 0
    set minQty 1000
    set totalValue 0
    set totalScore 0
    set maxScore 0

    foreach tempSetID $setID {

        set setInv $invConfig($w,inv$tempSetID)
        set setMax $CrossFire::setXRef($tempSetID,setMax)
        set cardNum 0

        CrossFire::ReadCardDataBase $tempSetID
        foreach card [lrange $CrossFire::cardDataBase 1 end] {

            # Skip cards that do not exist
            if {[lindex $card 6] == "(no card)"} {
                continue
            }

            set cardNum [lindex $card 1]
            set cardInv [lindex $setInv $cardNum]
            set wanted [lindex $cardInv 0]
            set cardQty [lindex $cardInv 1]
            set value [lindex $cardInv 3]
            incr totalCards $cardQty
            incr totalValue [expr $value * $cardQty]
            incr maxScore [expr $value * $wanted]
            if {$cardQty > $wanted} {
                incr totalScore [expr $wanted * $value]
            } else {
                incr totalScore [expr $cardQty * $value]
            }

            if {$cardQty > $maxQty} {
                set maxQty $cardQty
            }
            if {$cardQty < $minQty} {
                if {$invConfig($w,includeChase) == 0} {
                    if {$cardNum <= $setMax} {
                        set minQty $cardQty
                    }
                } else {
                    set minQty $cardQty
                }
            }
        }
    }

    # Update the display with the results.
    set invConfig($w,countTotal) $totalCards
    set invConfig($w,countMax) $maxQty
    set invConfig($w,countMin) $minQty
    set invConfig($w,countValue) $totalValue
    set invConfig($w,countScore) $totalScore
    set invConfig($w,countScoreMax) $maxScore

    return
}

# Inventory::ChangeMultipleCardsGUI --
#
#   Create a dialog to accept a string to change multiple cards
#   by different quantities quickly.  ie: 23+4,56-2,C02-1,C04+1
#   Calls ChangeMultipleCards to do the actual change.
#
# Parameters:
#   w          : Inventory toplevel.
#
# Returns:
#   Nothing.
#
proc Inventory::ChangeMultipleCardsGUI {w} {

    variable invConfig

    if {([llength $invConfig($w,cardSet)] != 1) ||
        ($invConfig($w,cardSet) == "All")} {
        tk_messageBox -title "Unable to Comply" -icon info \
            -message "This command only works on individual card sets."
        return
    }

    set tw $w.changeMulti
    toplevel $tw
    wm title $tw "Change Multiple Card Quantities"
    wm protocol $tw WM_DELETE_WINDOW "$tw.buttons.cancel invoke"

    CrossFire::Transient $tw

    frame $tw.top -borderwidth 1 -relief raised
    label $tw.top.l -text "Changes:"
    entry $tw.top.e -width 35 \
        -textvariable Inventory::invConfig($w,changes)
    set invConfig($w,changes) ""
    bind $tw.top.e <Return> "set Inventory::invConfig(changeMulti) ok"
    grid $tw.top.l $tw.top.e -padx 5 -pady 5
    grid columnconfigure $tw.top 1 -weight 1
    grid $tw.top -sticky nsew

    frame $tw.buttons -borderwidth 1 -relief raised
    button $tw.buttons.ok -text "Change" \
        -command "set Inventory::invConfig(changeMulti) ok"
    button $tw.buttons.cancel -text "Cancel" \
        -command "set Inventory::invConfig(changeMulti) cancel"
    grid $tw.buttons.ok $tw.buttons.cancel -padx 5 -pady 5

    grid $tw.buttons -sticky nsew
    grid columnconfigure $tw 0 -weight 1
    grid rowconfigure $tw 0 -weight 1

    bind $tw <Key-Escape> "$tw.buttons.cancel invoke"
    bind $tw <Key-Return> "$tw.buttons.ok invoke"

    focus $tw.top.e

    update
    grab set $tw
    vwait Inventory::invConfig(changeMulti)
    grab release $tw

    destroy $tw

    if {$invConfig(changeMulti) == "ok" && $invConfig($w,changes) != ""} {
        ChangeMultipleCards $w
    }

    return
}

# Inventory::ChangeMultipleCards --
#
#   Changes multiple cards in the current inventory.
#
# Parameters:
#   w          : Inventory toplevel.
#
# Returns:
#   Nothing.
#
proc Inventory::ChangeMultipleCards {w} {

    variable invConfig

    # Manipulate the input to be a list of card number delta number delta...
    # ie: 23+4,5-1,c4+1 => 24 4 5 -1 c4 1
    regsub -all "\[^-+,cC0-9\]" $invConfig($w,changes) "" changes
    regsub -all "\[,+\]" $changes " " changes
    regsub -all -- "-" $changes " -" changes

    set setID $invConfig($w,cardSet)
    set setMax $CrossFire::setXRef($setID,lastNumber)

    foreach {cardNumber delta} $changes {

        # Determine if chase card and change number if so.
        set chase [regsub -nocase "c" $cardNumber "" cardNumber]
        set cardNumber [CrossFire::StripZeros $cardNumber]
        if {$chase == 1} {
            incr cardNumber $CrossFire::setXRef($setID,setMax)
        }

        # Check in card number is within range...just in case.
        if {$cardNumber < 1 || $cardNumber > $setMax} {
            tk_messageBox -icon error -title "CrossFire Warning" -parent $w \
                -message "Card number $cardNumber is out of range."
        } else {
            ChangeInvData $w "qty" $delta $setID $cardNumber
            SetChanged $w "true"
        }
    }

    # Update the clicked on card in case it is one the was changed.
    UpdateQtyView $w

    return
}

