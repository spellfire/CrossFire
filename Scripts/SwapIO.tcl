# SwapIO.tcl 20040807
#
# This file contains all the I/O procedures for the Swap Shop.
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

# SwapShop::UnLockFile --
#
#   Unlocks the current trade file, if there is one.  Calls the
#   CrossFire::UnlockFile procedure to do the unlocking.
#
# Parameters:
#   w          : SwapShop toplevel.
#
# Returns:
#   Nothing.
#
proc SwapShop::UnLockFile {w} {

    variable swapShopConfig

    if {$swapShopConfig($w,fileName) != ""} {
        # Done with the previous trade, unlock it.
        CrossFire::UnlockFile $w $swapShopConfig($w,fileName)
    }

    return
}

# OpenTrade --
#
#   Loads a trade from a file.  Checks if current
#   trade needs to be saved first.
#
# Parameters:
#   w          : SwapShop toplevel.
#   file       : File name to automatically load.
#   args       : Optional nocomplain.
#
# Returns:
#   1 if successful, 0 if not.
#
proc SwapShop::OpenTrade {w file args} {

    variable swapShopConfig

    set sent 0
    set received 0
    set tempSwapShopName ""
    set tempSwapShopEmail ""
    set changed 0

    if {[CheckForSave $w] == -1} {
        return 0
    }

    if {$file == ""} {
        set fileName \
            [tk_getOpenFile -initialdir $swapShopConfig($w,tradeDir) \
                 -title "Open CrossFire Trade" \
                 -defaultextension $CrossFire::extension(trade) \
                 -filetypes $CrossFire::tradeFileTypes]
    } else {
        set fileName $file
    }

    if {($fileName == $swapShopConfig($w,fileName)) || ($fileName == "")} {
        return 0
    }

    set lockResult [CrossFire::LockFile $w $fileName $args]
    if {($fileName != "") && ($lockResult == 1)} {

        if {[catch "source \{$fileName\}"] != 0} {
            tk_messageBox -title "Error Opening Trade" -icon error \
                -parent $w -message "$fileName is not a valid trade!"
            CrossFire::UnlockFile $w $fileName
            return
        }

        $w configure -cursor watch
        update
	if {[file exists $invUsed] == 0} {
	    tk_messageBox -icon info -title "Swap Shop Error!" \
		-message "File $invUsed used in this trade cannot be found.  Please identify the correct inventory or this trade cannot be opened."
	    set tmpinvUsed \
		[tk_getOpenFile -initialdir $swapShopConfig($w,curInvDir) \
		     -title "Open CrossFire Inventory" \
		     -defaultextension $CrossFire::extension(inv) \
		     -filetypes $CrossFire::invFileTypes]
	    if {$tmpinvUsed == ""} {
		CrossFire::UnlockFile $w $fileName
		$w configure -cursor {}
		return
	    } else {
		set invUsed $tmpinvUsed
		set changed 1
	    }
	}
	
        New $w
        set swapShopConfig($w,fileName) $fileName
	set swapShopConfig($w,sentDate) $sent
	set swapShopConfig($w,receivedDate) $received
        if {$sent != 0} {
            SendReceive $w outTextBox
        }
        if {$received != 0} {
            SendReceive $w inTextBox
        }

        set swapShopConfig($w,disInvFile) $swapShopConfig($w,invFileName)
        set swapShopConfig($w,invFileName) [file tail $invUsed]
        set swapShopConfig($w,curInvDir) [file dirname $invUsed]
        
        if {$swapShopConfig($w,invFileName) == "DISABLED"} {
            set swapShopConfig($w,invEnabled) 0
        } else {
            set swapShopConfig($w,invEnabled) 1
        }
        
        set swapShopConfig($w,traderName) $tempSwapShopName
        set swapShopConfig($w,traderEmail) $tempSwapShopEmail
        set swapShopConfig($w,opening) 1
        
        foreach cardAndQty $outGoingTrade {
            set card [lindex $cardAndQty 0]
            set qty [lindex $cardAndQty 1]
            for {set i 0} {$i < $qty} {incr i} {
                AddCardToTrade $w $card outTextBox
            }
        }
        
        foreach cardAndQty $inComingTrade {
            set card [lindex $cardAndQty 0]
            set qty [lindex $cardAndQty 1]
            for {set i 0} {$i < $qty} {incr i} {
                AddCardToTrade $w $card inTextBox
            }
        }
        
        set swapShopConfig($w,opening) 0
        
	if {$changed} {
	    SetChanged $w "true"
	} else {
	    SetChanged $w "false"
	}
        CalcPointValue $w
        DisplayTrade $w inTextBox
        DisplayTrade $w outTextBox
        Config::RecentFile "SwapShop" $fileName
    }

    $w configure -cursor {}
    return $lockResult
}

# OpenInv --
#
#   Loads an inventory from a file.
#
# Parameters:
#   w          : SwapShop toplevel.
#
# Returns:
#   Nothing.
#
proc SwapShop::OpenInv {w} {

    variable swapShopConfig

    set fileName [tk_getOpenFile -initialdir $swapShopConfig($w,curInvDir) \
                      -title "Open CrossFire Inventory" \
                      -defaultextension $CrossFire::extension(inv) \
                      -filetypes $CrossFire::invFileTypes]

    if {$fileName == ""} {
        return
    }

    set swapShopConfig($w,invFileName) [file tail $fileName]
    set swapShopConfig($w,curInvDir) [file dirname $fileName]

    if {($swapShopConfig($w,tradeinTextBox) != "") &&
        ($swapShopConfig($w,tradeoutTextBox) != "")} {

        $w configure -cursor watch
        $w.settings configure -cursor watch
        update

        set tempInTextBox $swapShopConfig($w,tradeinTextBox) 
        set tempOutTextBox $swapShopConfig($w,tradeoutTextBox) 
        set tempFileName $swapShopConfig($w,fileName)
        New $w
        
        set swapShopConfig($w,opening) 1

        foreach cardAndInv $tempOutTextBox {
            set card [lindex $cardAndInv 0]
            set qty [lindex [lindex $cardAndInv 1] 2]
            for {set i 0} {$i < $qty} {incr i} {
                AddCardToTrade $w $card outTextBox
            }
        }
        foreach cardAndInv $tempInTextBox {
            set card [lindex $cardAndInv 0]
            set qty [lindex [lindex $cardAndInv 1] 2]
            for {set i 0} {$i < $qty} {incr i} {
                AddCardToTrade $w $card inTextBox
            }
        }
        
        set swapShopConfig($w,opening) 0

        set swapShopConfig($w,fileName) $tempFileName
        DisplayTrade $w inTextBox
        DisplayTrade $w outTextBox
        SetChanged $w "true"
        CalcPointValue $w
    }
    $w configure -cursor {}
    $w.settings configure -cursor {}

    return
}

# SaveTrade --
#
#   Saves a Trade in CrossFire Format.
#
# Parameters:
#   w          : SwapShop toplevel.
#
# Returns:
#   Nothing.
#
proc SwapShop::SaveTrade {w} {

    variable swapShopConfig

    set fileName $swapShopConfig($w,fileName)

    if {$fileName == ""} {
	if {$swapShopConfig($w,traderEmail) != ""} {
	    set baseEmail [lindex [split $swapShopConfig($w,traderEmail) @] 0]
	    set tmpFileName $baseEmail[clock format [clock seconds] -format "%Y%m%d"]
	} else {
	    set tmpFileName ""
	}
        set fileName \
            [tk_getSaveFile -initialdir $swapShopConfig($w,tradeDir) \
                 -title "Save CrossFire Trade As" \
                 -defaultextension $CrossFire::extension(trade) \
                 -filetypes $CrossFire::tradeFileTypes \
		 -initialfile $tmpFileName]
    }

    if {($fileName == "") || ([CrossFire::LockFile $w $fileName] == 0)} {
        return -1
    }

    Config::RecentFile "SwapShop" $fileName
    set fileID [open $fileName "w"]
    # If the trade has been sent
    if {$swapShopConfig($w,outState) == "disabled"} {
        puts $fileID "set sent [list $swapShopConfig($w,sentDate)]"
    }
    # If the trade has been received
    if {$swapShopConfig($w,inState) == "disabled"} {
        puts $fileID "set received [list $swapShopConfig($w,receivedDate)]"
    }

    set invFile [file join $swapShopConfig($w,curInvDir) $swapShopConfig($w,invFileName)]
    puts $fileID "set invUsed [list $invFile]"

    puts $fileID "set tempSwapShopName [list $swapShopConfig($w,traderName)]"
    puts $fileID "set tempSwapShopEmail [list $swapShopConfig($w,traderEmail)]"

    puts $fileID "set outGoingTrade \{"
    foreach cardAndInv $swapShopConfig($w,tradeoutTextBox) {
        set card [lindex $cardAndInv 0]
        set qty [lindex [lindex $cardAndInv 1] 2]
        puts $fileID "  \{\{$card\} \{$qty\}\}"
    }
    puts $fileID "\}"
    puts $fileID "set inComingTrade \{"
    foreach cardAndInv $swapShopConfig($w,tradeinTextBox) {
        set card [lindex $cardAndInv 0]
        set qty [lindex [lindex $cardAndInv 1] 2]
        puts $fileID "  \{\{$card\} \{$qty\}\}"
    }
    puts $fileID "\}"

    close $fileID
    if {$CrossFire::platform == "macos9"} {
        file attributes $fileName -type $CrossFire::macCode(trade) \
            -creator $CrossFire::macCode(creator)
    }

    set swapShopConfig($w,fileName) $fileName
    SetChanged $w "false"

    return 0
}

# SaveTradeAs --
#
#   Implements a save as feature.
#
# Paramters:
#   w         : SwapShop toplevel.
#
# Returns:
#   Nothing.
#
proc SwapShop::SaveTradeAs {w} {

    variable swapShopConfig

    set newFileName \
        [tk_getSaveFile -initialdir $swapShopConfig($w,tradeDir) \
             -title "Save CrossFire Trade As"  \
             -defaultextension $CrossFire::extension(trade) \
             -filetypes $CrossFire::tradeFileTypes]

    if {($newFileName != "") && ([CrossFire::LockFile $w $newFileName] == 1)} {
        if {$swapShopConfig($w,fileName) != ""} {
            CrossFire::UnlockFile $w $swapShopConfig($w,fileName)
        }
        set swapShopConfig($w,fileName) $newFileName
        SaveTrade $w
        Config::RecentFile "SwapShop" $newFileName
    }

    return
}

# PrintTrade --
#
#   Prints a CrossFire trade.  On Unix, it uses the lpr command and
#   on Windows or Macintosh, it creates an RTF file that can be
#   printed from Word, et al.
#
# Parameters:
#   w          : SwapShop toplevel path name.
#
# Returns:
#   Nothing.
#
proc SwapShop::PrintTrade {w} {
    
    variable swapShopConfig
    
    set printCR 0
    set out ""
    set unix 0
    set lineCount 0
    set fileName $swapShopConfig($w,fileName)
    set inbox $swapShopConfig($w,tradeinTextBox)
    set outbox $swapShopConfig($w,tradeoutTextBox)
    if {($inbox == {}) && ($outbox == {})} {
        tk_messageBox -title "Error Printing Trade" -icon error \
            -message "No cards in trade!" -parent $w
        return
    }
    
#    if {$CrossFire::platform == "unix"} {
#        set unix 1
#    } else {
        
        set tempRTFFile "[file rootname $fileName].rtf"
        if {$tempRTFFile == ".rtf"} {
            set tempRTFFile ""
        }
        
        set rtfFile [tk_getSaveFile -defaultextension ".rtf" \
                         -title "Print To File" \
                         -initialfile $tempRTFFile \
                         -filetypes {{{Rich Text Format} {.rtf}}}]
        if {$rtfFile == ""} {
            return
        }
#    }
    
    $w configure -cursor watch
    update
    
    if {$unix == 0} {
        
        set fileID [open $rtfFile "w"]
        
        # Print RTF format header information. I don't know what
        # it all means, though.  I copied it from Write...
        puts $fileID "\{\\rtf1\\ansi\\deff0\\deftab720"
        puts $fileID "\{\\fonttbl\{\\f0\\fnil MS Sans Serif;\}"
        puts $fileID "\{\\f1\\fnil\\fcharset2 Symbol;\}"
        puts $fileID "\{\\f2\\fswiss\\fprq2 System;\}"
        puts $fileID "\{\\f3\\fnil Times New Roman;\}\}\n"
        puts $fileID "\{\\colortbl\\red0\\green0\\blue0;\}\n"

    }
    
    if {($swapShopConfig($w,traderName) != "") || ($swapShopConfig($w,traderEmail) != "")} {
        if {$unix} {
            append out "Trade for:  "
        } else {
            puts $fileID "\\deflang1033\\pard\\plain\\f3\\fs32 Trade for:  "
        }
    }
    if {$swapShopConfig($w,traderName) != ""} {
        if {$unix} {
            append out "$swapShopConfig($w,traderName) "
        } else {
            puts $fileID "$swapShopConfig($w,traderName) "
        }
        set printCR 1
    }
    if {$swapShopConfig($w,traderEmail) != ""} {
        if {$unix} {
            append out "($swapShopConfig($w,traderEmail))"
        } else {
            puts $fileID "($swapShopConfig($w,traderEmail))"
        }
        set printCR 1
    }
    if {$printCR == 1} {
        if {$unix} {
            append out "\n\n"
        } else {
            puts $fileID "\\par \\par"
        }
    }
    foreach box "outTextBox inTextBox" {
        if {$box == "outTextBox"} {
            set label "Cards to be sent out:"
        } else {
            set label "Cards to be expecting in:"
        }
        if {$unix} {
            append out "$label\n"
        } else {
            puts $fileID "\\deflang1033\\pard\\plain\\f3\\fs28 $label\n"
        }
        foreach cardSetID [CrossFire::CardSetIDList "real"] {
            set setNamePrinted($cardSetID) 0
        }

        foreach cardAndInv $swapShopConfig($w,trade$box) {
            set card [lindex $cardAndInv 0]
            set inv [lindex [lindex $cardAndInv 1] 2]
            
            set cardSetID [lindex $card 0]
            set cardSetName $CrossFire::setXRef($cardSetID,name)
            set cardText [lindex $card 7]
            set cardName [SwapShop::GetCardDesc $card]

            if {$unix} {
                if {$setNamePrinted($cardSetID) == 0} {
                    append out "$cardSetName\n"
                }
                append out "  [format {%2d} $inv]  $cardName\n"

            } else {
                if {$setNamePrinted($cardSetID) == 0} {
                    puts $fileID "\\par \\pard\\plain\\f3\\fs24    $cardSetName"
                }
                puts $fileID "\\par \\pard\\plain\\f3\\fs20 \\tab [format {%2d} $inv] $cardName"
            }
            incr setNamePrinted($cardSetID)
        }
        if {$unix} {
            append out "\n"
        } else {
            puts $fileID "\\par \\par"
        }
    }
    if {$unix} {
        # Print final comments on page
        append out "\n\nThis printout created using CrossFire - Swap Shop (The Final Word in Trading)\n"

        # Call lpr to print the trade
#       puts $out
        exec echo $out | lpr
    } else {
        # Print RTF format tail info and close
        puts $fileID "\\par \\par \\pard\\plain\\f3\\fs20 This printout created using CrossFire - Swap Shop (The Final Word in Trading)\n \\par \}\n "
        close $fileID
    }
    
    $w configure -cursor {}
    return
}

# CheckForSave --
#
#   Checks if the trade needs to be saved.  If it does, alerts
#   user and asks if it should be saved.
#
# Parameters:
#   w          : SwapShop toplevel.
#
# Returns:
#    0 if no need to save.
#   -1 if needed to save, but canceled.
#
proc SwapShop::CheckForSave {w} {

    variable swapShopConfig

    set result 0
    if {$swapShopConfig($w,change) == "true"} {
        wm deiconify $w
        raise $w
        set answer \
            [tk_messageBox -title "Swap Shop Warning" -icon question \
                 -message "Current trade not saved.  Would you like to save it?" \
                 -type yesnocancel -parent $w]

        switch -- $answer {
            "yes" {
                set result [SaveTrade $w]
            }
            "cancel" {
                set result -1
            }
        }
    }

    return $result
}

