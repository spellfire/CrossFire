# FileIO.tcl 20031031
#
# This file contains all the I/O procedures for the Card Warehouse.
#
# Copyright (c) 1998-2003 Dan Curtiss. All rights reserved.
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

# Inventory::CheckForSave --
#
#   Checks if the deck needs to be saved.  If it does, alerts
#   user and asks if it should be saved.
#
# Parameters:
#   w          : Inv toplevel of deck.
#
# Returns:
#    0 if no need to save.
#   -1 if needed to save, but canceled.
#
proc Inventory::CheckForSave {w} {

    variable invConfig

    set result 0
    if {$invConfig($w,change) == "true"} {
        wm deiconify $w
        raise $w
        set msg "Current inventory not saved.  Would you like to save it?"
        set answer \
            [tk_messageBox -title "Card Warehouse Warning" -icon question \
                 -message $msg -type yesnocancel -parent $w -default yes]

        switch -- $answer {
            "yes" {
                set result [SaveInv $w]
            }
            "cancel" {
                set result -1
            }
        }
    }

    return $result
}

# Inventory::UnLockFile --
#
#   Unlocks the current inventory file, if there is one.  Calls
#   the CrossFire::UnlockFile procedure to do the unlocking.
#
# Parameters:
#   w          : Inventory toplevel.
#
# Returns:
#   Nothing.
#
proc Inventory::UnLockFile {w} {

    variable invConfig

    if {$invConfig($w,fileName) != ""} {
        # Done with the previous inventory, unlock it.
        CrossFire::UnlockFile $w $invConfig($w,fileName)
    }

    return
}

# Inventory::OpenInv --
#
#   Opens an inventory. Checks if current needs to be saved first.
#
# Parameters:
#   w          : Inventory toplevel.
#   args       : Optional 'default' to load the default inventory,
#                'nocomplain' for auto-loading or a filename to load.
#
# Returns:
#   1 if successful, 0 if not.
#
proc Inventory::OpenInv {w args} {

    variable invConfig

    if {[CheckForSave $w] == -1} {
        return 0
    }

    set default 0
    set nocomplain ""
    set loadFile ""

    foreach arg $args {
        switch -- $arg {
            "default" {
                set default 1
            }
            "nocomplain" {
                set nocomplain $arg
            }
            default {
                set loadFile $arg
            }
        }
    }

    if {$default == 1} {
        set defaultFileName $Config::config(Warehouse,defaultInv)
        # Loading the specified default inventory file.
        if {[file exists $defaultFileName] == 0} {
            # Does not exist, change name to CrossFire default.
            set idir $Config::config(Warehouse,invDir)
            set fileName [file join $idir "default.cfi"]
            set msg "Default Inventory: \"$defaultFileName\" does not exist."
            append msg " Warehouse will use \"$fileName\" as the Default."
            if {$defaultFileName != $fileName} {
                tk_messageBox -title "Card Warehouse Startup" \
                    -message $msg -icon info
                Config::Set Warehouse,defaultInv $fileName
            }
        } else {
            set fileName $defaultFileName
        }

        if {[file exists $fileName] == 0} {
            set tempFileName \
                [file join $CrossFire::homeDir "Scripts" "BlankInv.tcl"]
            tk_messageBox -title "Card Warehouse Startup" -icon info \
                -message "Creating Default Inventory:\n$fileName"
            file copy $tempFileName $fileName
        }

        ReadInv $w $fileName
        foreach setID [CrossFire::CardSetIDList "real"] {
            set invConfig($w,inv$setID) [GetInvInfo $w inv$setID]
        }

        set lockResult [CrossFire::LockFile $w $fileName]
        if {$lockResult == 1} {
            set invConfig($w,fileName) $fileName
        } else {
            set invConfig($w,fileName) ""
        }
        SetCardSet $w "menu"
        SetChanged $w "false"
        ClickListBox $w m 0 0
    } else {
        if {$loadFile == ""} {
            set fileName \
                [tk_getOpenFile -initialdir $invConfig($w,invDir) \
                     -defaultextension $CrossFire::extension(inv) \
                     -title "Open Card Inventory" \
                     -filetypes $CrossFire::invFileTypes]
            if {($fileName == $invConfig($w,fileName)) || ($fileName == "")} {
                return 0
            }
            set setCardSet 0
        } else {
            set fileName [lindex $args 0]
            set setCardSet 1
        }

        set lockResult [CrossFire::LockFile $w $fileName $nocomplain]
        if {($fileName != "") && ($lockResult == 1)} {

            set invConfig($w,invDir) [file dirname $fileName]

            if {[ReadInv $w $fileName] == 0} {
                tk_messageBox -parent $w -icon error \
                    -title "Error Loading Inventory" -type ok \
                    -message "Unable to load inventory file."
                CrossFire::UnlockFile $w $fileName
            } else {

                UnLockFile $w

                foreach setID [CrossFire::CardSetIDList "real"] {
                    set invConfig($w,inv$setID) [GetInvInfo $w inv$setID]
                }

                set invConfig($w,fileName) $fileName
                SetChanged $w "false"

                if {$setCardSet == 1} {
                    SetCardSet $w "menu"
                }

                ClickListBox $w m 0 0
            }
        }
    }

    return $lockResult
}

# Inventory::SaveInv --
#
#   Saves the current inventory.
#
# Parameters:
#   w          : Inventory toplevel.
#
# Returns:
#   Nothing.
#
proc Inventory::SaveInv {w} {

    variable invConfig

    set fileName $invConfig($w,fileName)

    if {$fileName == ""} {
        set fileName \
            [tk_getSaveFile -initialdir $invConfig($w,invDir) \
                 -title "Save Card Inventory As" \
                 -defaultextension $CrossFire::extension(inv) \
                 -filetypes $CrossFire::invFileTypes]
    }
        
    if {($fileName == "") || ([CrossFire::LockFile $w $fileName] == 0)} {
        return -1
    }

    set invConfig($w,invDir) [file dirname $fileName]
    set invConfig($w,fileName) $fileName

    # Change selection to first card if more than one is currently selected.
    if {[llength [$invConfig($w,cardListBox) curselection]] > 1} {
        ClickListBox $w m 0 1
    }

    # Make sure all the entry widgets are updated before saving
    ChangeInv $w max 0
    ChangeInv $w qty 0
    ChangeInv $w weight 0

    foreach setID [CrossFire::CardSetIDList "real"] {
        SetInvInfo $w inv$setID $invConfig($w,inv$setID)
    }

    if {[WriteInv $w $fileName] != 0} {
        SetChanged $w "false"
    }

    return 0
}

# Inventory::SaveInvAs --
#
#   Saves the current inventory with a new filename.
#
# Parameters:
#   w          : Inventory toplevel.
#
# Returns:
#   Nothing.
#
proc Inventory::SaveInvAs {w} {

    variable invConfig

    set tempFileName \
        [tk_getSaveFile -initialdir $invConfig($w,invDir) \
             -defaultextension $CrossFire::extension(inv) \
             -title "Save Card Inventory As" \
             -filetypes $CrossFire::invFileTypes]

    if {($tempFileName != "") &&
        ([CrossFire::LockFile $w $tempFileName] == 1)} {
        if {$invConfig($w,fileName) != ""} {
            CrossFire::UnlockFile $w $invConfig($w,fileName)
        }
        set invConfig($w,fileName) $tempFileName
        SaveInv $w
    }

    return
}

# Inventory::Import --
#
#   Wrapper procedure for all inventory importing. Gets the inventory
#   filename (or directory) to import from and calls the appropriate
#   import procedure.
#
# Parameters:
#   w          : Inventory toplevel.
#   invType    : Type of inventory to import. (SFDB2.0, etc)
#
# Returns:
#   Nothing.
#
proc Inventory::Import {w invType} {

    variable invConfig

    if {$invType != "CFV"} {
        if {[CheckForSave $w] == -1} {
            return
        }
    }

    switch -- $invType {
        "CFV" {
            set title "Select CrossFire Card Weights"
            set ftypes {{{CrossFire Card Weights} {.cfv}}}
            if {$invConfig($w,fileName) != ""} {
                set base [file rootname [file tail $invConfig($w,fileName)]]
            } else {
                set base "default"
            }
            set initFile "${base}.cfv"
            set iDir $Config::config(Warehouse,invDir)
        }
        "SFC" {
            set title "Select Spellfire Collector Export"
            set ftypes {{{Spellfire Collector Export} {.exp}}}
            set iDir $CrossFire::homeDir 
        }
        "SFDB2.0" {
            set title "Select Spellfire Database v2.x Backup"
            set ftypes {
                {{Backup}    {.bck}}
                {{CSV Files} {.csv}}
            }
            set iDir $CrossFire::homeDir 
        }
    }

    set fileName \
        [tk_getOpenFile -title $title -filetypes $ftypes \
             -initialdir $iDir]
    if {$fileName == ""} {
        return
    }

    $w configure -cursor watch
    update

    switch -- $invType {
        "CFV" {
            ImportCardWeights $w $fileName
        }
        "SFC" {
            ImportSpellfireCollector $w $fileName
        }
        "SFDB2.0" {
            ImportSpellfireDB $w $fileName
        }
    }

    $w configure -cursor {}
    SetChanged $w "true"
    ClickListBox $w m 0 0

    return
}

# Inventory::ImportCardWeights --
#
#   Imports card weights.
#
# Parameters:
#   w          : Inventory toplevel.
#   fileName   : Name of export file.
#
# Returns:
#   Nothing.
#
proc Inventory::ImportCardWeights {w fileName} {

    variable invConfig

    set fileID [open $fileName "r"]

    while {[eof $fileID] == 0} {

        foreach {setID number weight} [gets $fileID] break

        set setInv $invConfig($w,inv$setID)
        set cardInv [lindex $setInv $number]
        set cardInv [lreplace $cardInv 3 3 $weight]
        set setInv [lreplace $setInv $number $number $cardInv]
        set invConfig($w,inv$setID) $setInv
        
    }

    close $fileID
    return
}

# Inventory::ImportSpellfireCollector --
#
#   Imports an inventory from Spellfire Collector.
#
# Parameters:
#   w          : Inventory toplevel.
#   fileName   : Name of export file.
#
# Returns:
#   Nothing.
#
proc Inventory::ImportSpellfireCollector {w fileName} {

    variable invConfig

    # Clear the current inventory.
    SetChanged $w "false"
    New $w

    set fileID [open $fileName "r"]

    while {[eof $fileID] == 0} {

        foreach {id num wanted onHand weight} \
            [split [gets $fileID] ","] break
        foreach {setID number} [CrossFire::DecodeShortID "$id/$num"] break

        set setInv $invConfig($w,inv$setID)
        set cardInv [list $wanted $onHand 0 $weight]
        set setInv [lreplace $setInv $number $number $cardInv]
        set invConfig($w,inv$setID) $setInv
        
    }

    close $fileID

    return
}

# Inventory::ImportSpellfireDB --
#
#   Imports an inventory from a Spellfire Database 2.x back up file.
#
# Paramters:
#   w          : Inventory toplevel.
#   fileName   : Filename to import from.
#
# Returns:
#   Nothing.
#
proc Inventory::ImportSpellfireDB {w fileName} {

    variable invConfig

    # Clear the current inventory.
    SetChanged $w "false"
    New $w

    set ext [file extension $fileName]
    set fileID [open $fileName "r"]

    while {[eof $fileID] == 0} {

        gets $fileID cardLine

        # Ignore the description line and blank lines.
        if {[regexp "Card#" $cardLine] || ($cardLine == "")} {
            continue
        }

        # Convert the CSV data to a Tcl list.
        regsub -all {[\",]} $cardLine " " cardLine

        if {$ext == ".csv"} {
            set shortLine [lrange $cardLine 1 end]
            set qtyPos [lsearch -regexp $shortLine "^\[0-9\]"]
            set qty [lindex $shortLine $qtyPos]
            set setIndex [lindex $cardLine end]
        } else {
            set qty [lindex $cardLine 1]
            set setIndex [lindex $cardLine 2]
        }

        if {[regexp "Chase" $setIndex]} {
            regsub "Chase" $setIndex "" setIndex
            if {$setIndex == "1stEdition"} {
                set add 440
            } else {
                set add 100
            }
        } else {
            set add 0
        }

        set cardNumber [expr [lindex $cardLine 0] + $add]
        set setID $CrossFire::setXRef($setIndex)
        set setInv $invConfig($w,inv$setID)
        set cardInv [lindex $setInv $cardNumber]
        set cardInv [lreplace $cardInv 1 1 $qty]
        set setInv [lreplace $setInv $cardNumber $cardNumber $cardInv]
        set invConfig($w,inv$setID) $setInv
    }

    close $fileID

    return
}

# Inventory::Export --
#
#   Wrapper procedure for all inventory exporting. Gets the inventory
#   filename (or directory) to export to and calls the appropriate
#   export procedure.
#
# Parameters:
#   w          : Inventory toplevel.
#   invType    : Type of inventory to export. (SFDB2.0, etc)
#
# Returns:
#   Nothing.
#
proc Inventory::Export {w invType} {

    variable invConfig

    switch -- $invType {
        "CFV" {
            set title "Select CrossFire Card Weights"
            set ftypes {{{CrossFire Card Weights} {.cfv}}}
            if {$invConfig($w,fileName) != ""} {
                set base [file rootname [file tail $invConfig($w,fileName)]]
            } else {
                set base "default"
            }
            set initFile "${base}.cfv"
            set iDir $Config::config(Warehouse,invDir)
        }
        "SFC" {
            set title "Select Spellfire Collector Export"
            set ftypes {{{Spellfire Collector Export} {.exp}}}
            set initFile "collection.exp"
            set iDir $CrossFire::homeDir 
        }
        "SFDB2.0" {
            set title "Select Spellfire Database v2.x Backup"
            set ftypes {{{Backup} {.bck}}}
            set initFile "spellfire.bck"
            set iDir $CrossFire::homeDir 
        }
    }

    set fileName \
        [tk_getSaveFile -title $title -filetypes $ftypes \
             -initialfile $initFile -initialdir $iDir]
    if {$fileName == ""} {
        return
    }

    $w configure -cursor watch
    update

    switch -- $invType {
        "CFV" {
            ExportCardWeights $w $fileName
        }
        "SFC" {
            ExportSpellfireCollector $w $fileName
        }
        "SFDB2.0" {
            ExportSpellfireDB $w $fileName
        }
    }

    $w configure -cursor {}

    return
}

# Inventory::ExportCardWeights --
#
#   Exports the weight of each file.
#
# Parameters:
#   w          : Inventory toplevel.
#   fileName   : Name of export file.
#
# Returns:
#   Nothing.
#
proc Inventory::ExportCardWeights {w fileName} {

    variable invConfig

    set fileID [open $fileName "w"]

    foreach setID [CrossFire::CardSetIDList "real"] {

        set last $CrossFire::setXRef($setID,lastNumber)

        for {set i 1} {$i <= $last} {incr i} {
            set weight [lindex [lindex $invConfig($w,inv$setID) $i] 3]
            puts $fileID "$setID $i $weight"
        }
    }

    close $fileID

    return
}

# Inventory::ExportSpellfireCollector --
#
#   Exports the current inventory to Spellfire Collector.
#   This format is shared by CrossFire.
#   SetID,CardNumber,Wanted,OnHand,Weight
#   Note that chase are listed as FRc,18 not FR,118
#
# Parameters:
#   w          : Inventory toplevel.
#   fileName   : Name of export file.
#
# Returns:
#   Nothing.
#
proc Inventory::ExportSpellfireCollector {w fileName} {

    variable invConfig

    set fileID [open $fileName "w"]

    foreach setID [CrossFire::CardSetIDList "real"] {

        for {set i 1} {$i <= $CrossFire::setXRef($setID,lastNumber)} {incr i} {
            foreach {wanted onHand premium weight} \
                [lindex $invConfig($w,inv$setID) $i] {break}
            foreach {id number} [CrossFire::GetCardID $setID $i split] {break}
            puts $fileID "$id,$number,$wanted,$onHand,$weight"
        }
    }

    close $fileID

    return
}

# Inventory::ExportSpellfireDB --
#
#   Exports an inventory to a Spellfire Database 2.0 back up file.
#
# Paramters:
#   w          : Inventory toplevel.
#   fileName   : Filename to import from.
#
# Returns:
#   Nothing.
#
proc Inventory::ExportSpellfireDB {w fileName} {

    variable invConfig

    set fileID [open $fileName "w"]

    foreach setID "1st 2nd 3rd 4th AR BR DR DL DU FR NS NO PO PR RL RR UD" {
        set setName $CrossFire::setXRef($setID,sfdbID)
        CrossFire::ReadCardDataBase $setID

        if {$setName != "na"} {

            set setInv $invConfig($w,inv$setID)
            set regularLimit $CrossFire::setXRef($setID,setMax)
            set last $CrossFire::setXRef($setID,lastNumber)

            for {set i 1} {$i <= $last} {incr i} {

                set card [lindex $CrossFire::cardDataBase $i]
                set cardName [lindex $card 6]

                if {$cardName == "(no card)"} {
                    continue
                }

                set cardInv [lindex $setInv $i]
                set cardQty [lindex $cardInv 1]

                if {$i <= $regularLimit} {
                    puts $fileID "$i,$cardQty,\"$setName\""
                } else {
                    set newI [expr $i - $regularLimit]
                    puts $fileID "$newI,$cardQty,\"${setName}Chase\""
                }
            }
        }
    }

    close $fileID

    return
}

# Inventory::ConstructDeck --
#
#   Removes the cards in a deck from the inventory.  Checks that all cards
#   are available before removing them.
#
# Parameters:
#   w          : Inventory toplevel.
#
# Returns:
#   Nothing.
#
proc Inventory::ConstructDeck {w} {

    variable invConfig

    set deckFileName \
        [tk_getOpenFile  -initialdir $Config::config(DeckIt,dir) \
             -title "Select CrossFire Deck" \
             -defaultextension $CrossFire::extension(deck) \
             -filetypes $CrossFire::deckFileTypes]

    if {($deckFileName == "") || ([CrossFire::LockFile $w $deckFileName] == 0)} {
        return
    }

    if {[Editor::ReadDeck $w $deckFileName] == 0} {
        tk_messageBox -title "Error Opening Deck" -icon error \
            -parent $w -message "$deckFileName is not a valid deck!"
        CrossFire::UnlockFile $w $deckFileName
        return
    }

    if {[Editor::GetDeckInfo $w inInventory] == "false"} {
        tk_messageBox -parent $w -icon error \
            -title "Card Warehouse Warning" -type ok \
            -message "$deckFileName already removed from inventory."
    } else {

        $w configure -cursor watch
        update

        # Check if any quantity will go negative.
        set changeErrors 0
        set fanSets [CrossFire::CardSetIDList "fan"]
        foreach cardID [Editor::GetDeckInfo $w deck] {
            foreach {setID cardNumber} $cardID break

            if {[lsearch $fanSets $setID] == -1} {
                set card [CrossFire::GetCard $setID $cardNumber]

                if {[info exists tempInv($setID,$cardNumber)] == 0} {
                    set cardInv [lindex $invConfig($w,inv$setID) $cardNumber]
                    set current [lindex $cardInv 1]
                    set tempInv($setID,$cardNumber) $current
                }

                if {$tempInv($setID,$cardNumber) == 0} {
                    set changeErrors 1
                    set cardDesc [CrossFire::GetCardDesc $card]
                    tk_messageBox -parent $w -icon error -message \
                        "You do not have enough $cardDesc in your inventory."
                    break
                }

                incr tempInv($setID,$cardNumber) -1
            }
        }

        if {$changeErrors == 0} {

            # Remove each card from the inventory.
            foreach cardID [Editor::GetDeckInfo $w deck] {
                foreach {setID cardNumber} $cardID break
                if {[lsearch $fanSets $setID] == -1} {
                    ChangeInvData $w qty -1 $setID $cardNumber
                }
            }

            SaveInv $w

            Editor::SetDeckInfo $w inInventory "false"
            Editor::WriteDeck $w $deckFileName
        }

        $w configure -cursor {}
    }

    CrossFire::UnlockFile $w $deckFileName
    ClickListBox $w m 0 0

    return
}

# Inventory::DismantleDeck --
#
#   Adds the cards in a deck to the inventory.
#
# Parameters:
#   w          : Inventory toplevel.
#
# Returns:
#   Nothing.
#
proc Inventory::DismantleDeck {w} {

    variable invConfig

    set deckFileName \
        [tk_getOpenFile  -initialdir $Config::config(DeckIt,dir) \
             -title "Open CrossFire Deck" \
             -defaultextension $CrossFire::extension(deck) \
             -filetypes $CrossFire::deckFileTypes]

    if {($deckFileName == "") ||
        ([CrossFire::LockFile $w $deckFileName] == 0)} {
        return
    }

    if {[Editor::ReadDeck $w $deckFileName] == 0} {
        tk_messageBox -title "Error Opening Deck" -icon error \
            -parent $w -message "$deckFileName is not a valid deck!"
        CrossFire::UnlockFile $w $deckFileName
        return
    }

    if {[Editor::GetDeckInfo $w inInventory] == "true"} {
        tk_messageBox -parent $w -icon error \
            -title "Card Warehouse Warning" -type ok \
            -message "$deckFileName already in inventory."
    } else {

        $w configure -cursor watch
        update

        set fanSets [CrossFire::CardSetIDList "fan"]

        # Add each card back in to the inventory.
        foreach cardID [Editor::GetDeckInfo $w deck] {
            foreach {setID cardNumber} $cardID break
            if {[lsearch $fanSets $setID] == -1} {
                ChangeInvData $w qty 1 $setID $cardNumber
            }
        }

        SaveInv $w

        Editor::SetDeckInfo $w inInventory "true"
        Editor::WriteDeck $w $deckFileName

        $w configure -cursor {}
    }

    CrossFire::UnlockFile $w $deckFileName
    ClickListBox $w m 0 0

    return
}

# Inventory::ReadInv --
#
#   A proc callable from any part of CrossFire to properly read an
#   inventory.  Call Inventory::GetInvInfo to get the information.
#
# Parameters:
#   w          : Toplevel calling this proc.
#   fileName   : Inventory to open.
#
# Returns:
#   1 if successfully read, or 0 if not.
#
proc Inventory::ReadInv {w fileName} {

    variable invStorage

    if {[file readable $fileName] == 0} {
        return 0
    }

    set fid [open $fileName "r"]
    set invCommand [read $fid]
    close $fid

    # Eval the inv in the safe interpreter
    catch {
        safeInterp eval $invCommand
    }

    foreach inv [CrossFire::GetSafeVar tempInventory] {
        set setID [lindex $inv 0]
        set invStorage($w,inv$setID) [lindex $inv 1]
    }

    # Check for missing data for sticker boosters.
    foreach setID [CrossFire::CardSetIDList "stik"] {
	if {![info exists invStorage($w,inv$setID)]} {
	    set tempInv {}
	    set max [expr $CrossFire::setXRef($setID,setMax) \
			 + $CrossFire::setXRef($setID,chaseQty)]
	    for {set i 0} {$i <= $max} {incr i} {
		if {$i <= $CrossFire::setXRef($setID,setMax)} {
		    # Regular card, so desired qty of 2
		    lappend tempInv [list 2 0 0 1]
		} else {
		    # "Chase" (??) card, so qty of 1
		    lappend tempInv [list 1 0 0 1]
		}
	    }
	    set invStorage($w,inv$setID) $tempInv
	}
    }

    return 1
}

# Inventory::GetInvInfo --
#
#   Called after ReadInv has been called this returns one of the inv datums.
#
# Parameters:
#   w          : Toplevel.
#   var        : Which of the datums to get.
#
# Returns:
#   The info if it exists.
#
proc Inventory::GetInvInfo {w var} {

    variable invStorage

    if {[info exists invStorage($w,$var)]} {
        set info $invStorage($w,$var)
    } else {
        set info ""
    }

    return $info
}

# Inventory::SetInvInfo --
#
#   Called after ReadInv has been called this sets one of the inv datums.
#
# Parameters:
#   w          : Toplevel.
#   var        : Which of the datums to get.
#   data       : Data to set var to.
#
# Returns:
#   Nothing.
#
proc Inventory::SetInvInfo {w var data} {

    variable invStorage

    set invStorage($w,$var) $data

    return
}

# Inventory::WriteInv --
#
#   Writes out a inv.
#
# Parameters:
#   w          : Toplevel.
#   fileName   : Filename to save to.
#
# Returns:
#   1 if successfully written, 0 otherwise.
#
proc Inventory::WriteInv {w fileName} {

    variable invStorage

    set fileID 0
    catch {
        set fileID [open $fileName "w"]
    } err
    if {$err != $fileID} {
        tk_messageBox -title "Error Saving Inventory"\
            -message "ERROR: '$err'" -icon error
        return 0
    }

    puts $fileID "set tempInventory \{"

    foreach cardSet [CrossFire::CardSetIDList "real"] {
        set setInv $invStorage($w,inv$cardSet)
        puts $fileID "  \{$cardSet"
        puts $fileID "    \{"
        puts -nonewline $fileID "      "

        set count 0
        set last $CrossFire::setXRef($cardSet,lastNumber)
        for {set i 0} {$i <= $last} {incr i} {
            set cardInv [lindex $setInv $i]
            puts -nonewline $fileID "\{$cardInv\} "
            incr count
            if {$count == 8} {
                puts -nonewline $fileID "\n      "
                set count 0
            }
        }

        puts $fileID "\n    \}"
        puts $fileID "  \}\n"
    }

    puts $fileID "\}"
    close $fileID

    if {$CrossFire::platform == "macos9"} {
        file attributes $fileName -type $CrossFire::macCode(inv) \
            -creator $CrossFire::macCode(creator)
    }

    return 1
}
