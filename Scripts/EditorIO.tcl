# EditorIO.tcl 20060104
#
# This file contains all the I/O procedures for the DeckIt! editor.
#
# Copyright (c) 1998-2006 Dan Curtiss. All rights reserved.
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

# BBcode additions made by Simon Dorfman 12/2005.

# Editor::CheckForSave --
#
#   Checks if the deck needs to be saved.  If it does, alerts
#   user and asks if it should be saved.
#
# Parameters:
#   w          : Editor toplevel of deck.
#
# Returns:
#    0 if no need to save.
#   -1 if needed to save, but canceled.
#
proc Editor::CheckForSave {w} {

    variable storage

    set result 0
    if {$storage($w,change) == "true"} {
        wm deiconify $w
        raise $w
        set answer \
            [tk_messageBox -title "DeckIt! Warning" -icon question \
                 -message "Deck not saved.  Would you like to save it?" \
                 -type yesnocancel -parent $w -default yes]

        switch -- $answer {
            "yes" {
                set result [SaveDeck $w]
            }
            "cancel" {
                set result -1
            }
        }
    }

    return $result
}

# Editor::UnLockFile --
#
#   Unlocks the current deck file, if there is one.  Calls the
#   CrossFire::UnlockFile procedure to do the unlocking.
#
# Parameters:
#   w          : Editor toplevel.
#
# Returns:
#   Nothing.
#
proc Editor::UnLockFile {w} {

    variable storage

    if {$storage($w,fileName) != ""} {
        # Done with the previous deck, unlock it.
        CrossFire::UnlockFile $w $storage($w,fileName)
    }

    return
}

# Editor::OpenDeck --
#
#   Loads a deck from a file.  Checks if current
#   deck needs to be saved first.
#
# Parameters:
#   w          : Editor toplevel.
#   file       : File name to automatically load.
#   args       : Optional nocomplain
#
# Returns:
#   1 if successful, 0 if not (canceled, unable to lock)
#
proc Editor::OpenDeck {w file args} {

    variable storage

    if {[CheckForSave $w] == -1} {
        return 0
    }

    if {$file == ""} {
        set fileName [tk_getOpenFile \
                          -initialdir $storage($w,deckDir) \
                          -title "Open CrossFire Deck" \
                          -defaultextension $CrossFire::extension(deck) \
                          -filetypes $CrossFire::deckFileTypes]
    } else {
        set fileName $file
    }

    if {($fileName == "")} {
        return 0
    }
    if {($fileName == $storage($w,fileName))} {
        set storage($w,fileName) ""
    }

    set lockResult [CrossFire::LockFile $w $fileName $args]
    if {$lockResult == 1} {

        if {[ReadDeck $w $fileName] == 0} {
            tk_messageBox -title "Error Opening Deck" -icon error \
                -parent $w -message "$fileName is not a valid deck!"
            CrossFire::UnlockFile $w $fileName
            return
        }

        set storage($w,deckDir) [file dirname $fileName]
        set storage($w,size) [GetDeckInfo $w size]
        set storage($w,newSize) [GetDeckInfo $w size]

        New $w

        set storage($w,fileName) $fileName

        foreach var {
            inInventory authorName authorEmail deckTitle
            checkInv inventory deckDisplayMode notes
        } {
            set storage($w,$var) [GetDeckInfo $w $var]
        }
	$storage($w,deckInfoNotesW) insert end $storage($w,notes)

        OpenInventory $w

	# Deck cards
        foreach card [GetDeckInfo $w deck] {
            set card [eval CrossFire::GetCard $card]
            if {$card != ""} {
                AddCardToDeck $w $card
            }
        }

	# Alternate cards
        foreach card [GetDeckInfo $w altCards] {
            set card [eval CrossFire::GetCard $card]
            if {$card != ""} {
                AddAltCard $w $card
            }
        }

        SetChanged $w "false"
        DisplayDeck $w 0
	DisplayAltCards $w 0
        UpdateDeckStatus $w Max
        Config::RecentFile "DeckIt" $fileName
    }

    return $lockResult
}

# Editor::SaveDeck --
#
#   Saves a deck in CrossFire Format.
#
# Parameters:
#   w          : Editor toplevel path name of deck.
#
# Returns:
#   0 if saved, -1 if canceled.
#
proc Editor::SaveDeck {w} {

    variable storage

    set fileName $storage($w,fileName)

    if {$fileName == ""} {
        set fileName \
            [tk_getSaveFile -initialdir $storage($w,deckDir) \
                 -title "Save CrossFire Deck As" \
                 -defaultextension $CrossFire::extension(deck) \
                 -filetypes $CrossFire::deckFileTypes]
    }

    if {($fileName == "") || ([CrossFire::LockFile $w $fileName] == 0)} {
        return -1
    }

    set storage($w,deckDir) [file dirname $fileName]

    if {$storage($w,deckTitle) == ""} {
        set storage($w,deckTitle) [file tail $fileName]
    }

    set storage($w,notes) \
	[string trim [$storage($w,deckInfoNotesW) get 1.0 end]]
    foreach var {
        size inInventory authorName authorEmail notes altCards
        deckTitle checkInv inventory deckDisplayMode deck
    } {
        SetDeckInfo $w $var $storage($w,$var)
    }

    set result 0
    if {[WriteDeck $w $fileName] == 1} {
        set storage($w,fileName) $fileName
        Config::RecentFile "DeckIt" $fileName
        SetChanged $w "false"
    } else {
        set result -1
    }

    return $result
}

# Editor::SaveDeckAs --
#
#   Implements a save as feature.
#
# Paramters:
#   w         : Editor toplevel path name for deck.
#
# Returns:
#   Nothing.
#
proc Editor::SaveDeckAs {w} {

    variable storage

    set newFileName \
        [tk_getSaveFile -initialdir $storage($w,deckDir) \
             -defaultextension $CrossFire::extension(deck) \
             -title "Save CrossFire Deck As" \
             -filetypes $CrossFire::deckFileTypes]

    if {($newFileName != "") && ([CrossFire::LockFile $w $newFileName] == 1)} {

        if {$storage($w,fileName) != ""} {
            CrossFire::UnlockFile $w $storage($w,fileName)
        }

        set holdFileName $storage($w,fileName)
        set storage($w,fileName) $newFileName
        if {[SaveDeck $w] == -1} {
            set storage($w,fileName) $holdFileName
            if {$storage($w,fileName) != ""} {
                CrossFire::UnlockFile $w $storage($w,fileName)
            }
        }
    }

    return
}

# Editor::PrintDeck --
#
#   Checks if there is a deck.
#
# Parameters:
#   w          : Editor toplevel.
#
# Returns:
#   Nothing.
#
proc Editor::PrintDeck {w} {

    variable storage

    if {$storage($w,deck) == {}} {
        tk_messageBox -title "Error Printing Deck" -icon info \
            -message "No cards in deck!" -parent $w
        return
    }

    if {[Print::GetExportFile $w $storage($w,fileName) "Print Deck"] == "cancel"} {
        return
    }

    Print $w

    return
}

# Editor::Print --
#
#   Prints a CrossFire deck.  On Unix, it uses the lpr command and
#   on Windows or Macintosh, it creates an RTF, HTML, BBcode or text file
#   that can be printed from Word, et al.
#
# Parameters:
#   w          : Editor toplevel path name.
#
# Returns:
#   Nothing.
#
proc Editor::Print {w} {

    variable storage

    $w configure -cursor watch
    update

    set deckTitle $storage($w,deckTitle)

    # File heading
    Print::Head $w $deckTitle

    # Deck title
    Print::Title $w $deckTitle

    # Number of cards and total levels
    set tCards "Total Cards: $storage($w,Total,qty,All)"
    if {$storage($w,hasDungeon) == 1} {
        append tCards " + Dungeon Card"
    }
    Print::Center $w $tCards

    set tLevels "Total Levels: $storage($w,Total,qty,Levels)"
    Print::Center $w $tLevels

    Print::Blank $w

    # Author's name and email
    Print::Author $w $storage($w,authorName)
    Print::Email $w $storage($w,authorEmail)

    # Separator and deck notes
    Print::Separator $w

    set notes "[string trim [$storage($w,deckInfoNotesW) get 1.0 end]]\n"
    if {$notes != "\n"} {
        Print::Notes $w $notes
        Print::Separator $w
    }

    set tempDeck [lsort $storage($w,deck)]
    if {$storage($w,deckDisplayMode) == "Type"} {

        # Print the cards by card type, then in sorted order.
        foreach cardTypeID $CrossFire::cardTypeIDList {
            set cardTypeName $CrossFire::cardTypeXRef($cardTypeID,name)
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

                # Group heading
                if {$displayedName == 0} {
                    if {$cardTypeName == "Champions"} {
                        set qty $storage($w,Total,qty,$cardTypeName)
                    } else {
                        set qty $storage($w,Type,qty,$cardTypeName)
                    }
                    set heading "$cardTypeName ($qty)"
                    Print::Heading $w $heading
                    set displayedName 1
                }

                # Card
                if {$Config::config(DeckIt,printCardText) == "Yes"} {
                    set printText 1
                } else {
                    set printText 0
                }
                Print::Card $w $card -text $printText
            }
        }
    } else {
        # Printing in Set, Rarity, World, or Last Digit
        set which $storage($w,deckDisplayMode)
        if {$which == "Set"} {
            set idList [CrossFire::CardSetIDList "all"]
            set field 0
        } elseif {$which == "Rarity"} {
            set idList $CrossFire::cardFreqIDList
            set field 8
        } elseif {$which == "World"} {
            set idList $CrossFire::worldIDList
            set field 4
        } elseif {$which == "Digit"} {
            set idList $CrossFire::cardDigitList
            set field -1
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
                set heading "Digit $id"
            }

            foreach card $tempDeck {

                set lastDigit [string range [lindex $card 1] end end]

                if {($which == "Digit" && $lastDigit == $id) ||
                    [lindex $card $field] == $id} {

                    # Group heading
                    if {$displayedName == 0} {
                        append heading " ($storage($w,$which,qty,$id))"
                        Print::Heading $w $heading
                        set displayedName 1
                    }

                    # Card
                    if {$Config::config(DeckIt,printCardText) == "Yes"} {
                        set printText 1
                    } else {
                        set printText 0
                    }
                    Print::Card $w $card -text $printText
                }
            }
        }
    }

    # End of file text
    Print::Tail $w

    Print::Print $w

    $w configure -cursor {}
    return
}

# Editor::OpenInventory --
#
#   Reads a new inventory file.  Checks all cards against
#   the new inventory.  This is called when changing the
#   specified inventory file or when changing the check flag.
#
# Parameters:
#   w          : Editor toplevel.
#
# Returns:
#   Nothing.
#
proc Editor::OpenInventory {w} {

    variable storage

    if {$storage($w,checkInv) == "No"} {
        return
    }

    if {[Inventory::ReadInv $w $storage($w,inventory)] == 0} {
        tk_messageBox -parent $w -icon error \
            -title "Error Loading Inventory" -type ok \
            -message "Unable to load inventory file."
        set storage($w,checkInv) "No"
    } else {

        set storage($w,levelList) ""
        set storage($w,avatarList) ""

        foreach data {All Avatars Chase Champions Levels} {
            set storage($w,Total,qty,$data) 0
        }

        foreach cardTypeID $CrossFire::cardTypeIDList {
            if {($cardTypeID > 0) && ($cardTypeID < 99)} {
                set typeID $CrossFire::cardTypeXRef($cardTypeID,name)
                set storage($w,Type,qty,$typeID) 0
            }
        }

        foreach setID "[CrossFire::CardSetIDList all] FAN" {
            set storage($w,Set,qty,$setID) 0
        }

        foreach worldID "$CrossFire::worldIDList FAN" {
            set storage($w,World,qty,$worldID) 0
        }

        foreach rarityID $CrossFire::cardFreqIDList {
            set storage($w,Rarity,qty,$rarityID) 0
        }

        set deck $storage($w,deck)
        set storage($w,deck) ""
        DisplayDeck $w
        foreach card $deck {
            AddCardToDeck $w $card
        }
        DisplayDeck $w
    }

    return
}

# Editor::SelectInventory --
#
#   Changes the selected inventory to check if cards are owned.
#
# Parameters:
#   w          : Editor toplevel.
#
# Returns:
#   Nothing.
#
proc Editor::SelectInventory {w} {

    variable storage

    set fileName \
        [tk_getOpenFile -initialdir $Config::config(Warehouse,invDir) \
             -defaultextension $CrossFire::extension(inv) \
             -title "Open Card Inventory" \
             -filetypes $CrossFire::invFileTypes]

    if {($fileName != "") && ($fileName != $storage($w,inventory))} {
        set storage($w,inventory) $fileName
        OpenInventory $w
    }

    return
}

# A Deck has the following infomation stored:
#
#   size            - Deck size ID (55, 75, etc as defined in Limits.tcl)
#   inInventory     - If the deck is still in the inventory. (true|false)
#   authorName      - Author's name.
#   authorEmail     - Author's email address.
#   notes           - Optional notes about the deck.
#   deckTitle       - Text title of the deck.
#   checkInv        - Check for cards in inv when adding. (true|false)
#   inventory       - Inventory to check for cards against.
#   deckDisplayMode - How the deck is displayed. (Type|Set)
#   deck            - List of {setID cardNum}
#   altCards        - List of {setID cardNum}

# Editor::ReadDeck --
#
#   A proc callable from any part of CrossFire to properly read a deck.
#   Call Editor::GetDeckInfo to get the deck information.
#
# Parameters:
#   w          : Toplevel calling this proc.
#   fileName   : Deck to open.
#
# Returns:
#   1 if successfully read, or 0 if not.
#
proc Editor::ReadDeck {w fileName} {

    variable deckStorage

    # Set up dummy contents in case any var is missing or damaged.
    CrossFire::SetSafeVar tempDeckSize $Config::config(DeckIt,deckSize)
    CrossFire::SetSafeVar tempInInventory "No"
    CrossFire::SetSafeVar tempAuthorName \
        $Config::config(CrossFire,authorName)
    CrossFire::SetSafeVar tempAuthorEmail \
        $Config::config(CrossFire,authorEmail)
    CrossFire::SetSafeVar tempNotes ""
    CrossFire::SetSafeVar tempDeckTitle ""
    CrossFire::SetSafeVar tempCheckInv "No"
    CrossFire::SetSafeVar tempInventory $Config::config(Warehouse,defaultInv)
    CrossFire::SetSafeVar tempDeckDisplayMode \
        $Config::config(DeckIt,deckDisplayMode)
    CrossFire::SetSafeVar tempDeck ""
    CrossFire::SetSafeVar tempAltCards ""

    if {[file readable $fileName] == 0} {
        return 0
    }

    set fid [open $fileName "r"]
    set deckCommand [read $fid]
    close $fid

    # Eval the deck in the safe interpreter
    catch {
        safeInterp eval $deckCommand
    } err

    set tempDeckSize [string toupper [CrossFire::GetSafeVar tempDeckSize]]
    if {![info exists CrossFire::deckFormat($tempDeckSize,name)]} {
        tk_messageBox -icon error -title "Unable to Comply" -message \
            "Deck uses an unknown deck format of $tempDeckSize."
        return 0
    }

    set deckStorage($w,size)        $tempDeckSize
    set deckStorage($w,inInventory) [CrossFire::GetSafeVar tempInInventory]
    set deckStorage($w,authorName)  [CrossFire::GetSafeVar tempAuthorName]
    set deckStorage($w,authorEmail) [CrossFire::GetSafeVar tempAuthorEmail]
    set deckStorage($w,deckTitle)   [CrossFire::GetSafeVar tempDeckTitle]
    set deckStorage($w,notes)       [CrossFire::GetSafeVar tempNotes]
    set deckStorage($w,checkInv)    [CrossFire::GetSafeVar tempCheckInv]
    set deckStorage($w,inventory)   [CrossFire::GetSafeVar tempInventory]
    set deckStorage($w,deckDisplayMode) \
        [CrossFire::GetSafeVar tempDeckDisplayMode]

    set deckStorage($w,deck) {}
    foreach card [CrossFire::GetSafeVar tempDeck] {
        lappend deckStorage($w,deck) [lrange $card 0 1]
    }

    set deckStorage($w,altCards) {}
    foreach card [CrossFire::GetSafeVar tempAltCards] {
        lappend deckStorage($w,altCards) [lrange $card 0 1]
    }

    return 1
}

# Editor::GetDeckInfo --
#
#   Called after ReadDeck has been called this returns one of the deck datums.
#
# Parameters:
#   w          : Toplevel.
#   var        : Which of the datums to get.
#
# Returns:
#   The info if it exists.
#
proc Editor::GetDeckInfo {w var} {

    variable deckStorage

    if {[info exists deckStorage($w,$var)]} {
        set info $deckStorage($w,$var)
    } else {
        dputs "Bogus: Tried to read deck info $w,$var"
        set info ""
    }

    return $info
}

# Editor::SetDeckInfo --
#
#   Called after ReadDeck has been called this sets one of the deck datums.
#
# Parameters:
#   w          : Toplevel.
#   var        : Which of the datums to get.
#   data       : Data to set var to.
#
# Returns:
#   Nothing.
#
proc Editor::SetDeckInfo {w var data} {

    variable deckStorage

    set deckStorage($w,$var) $data

    return
}

# Editor::WriteDeck --
#
#   Writes out a deck.
#
# Parameters:
#   w          : Toplevel.
#   fileName   : Filename to save to.
#
# Returns:
#   1 if successfully written, 0 otherwise.
#
proc Editor::WriteDeck {w fileName} {

    variable deckStorage

    set fileID 0
    catch {
        set fileID [open $fileName "w"]
    } err
    if {$err != $fileID} {
        tk_messageBox -title "Error Saving Deck"\
            -message "ERROR: '$err'" -icon error
        return 0
    }

    puts $fileID "set tempDeckSize [list $deckStorage($w,size)]"
    puts $fileID "set tempInInventory [list $deckStorage($w,inInventory)]"
    puts $fileID "set tempAuthorName [list $deckStorage($w,authorName)]"
    puts $fileID "set tempAuthorEmail [list $deckStorage($w,authorEmail)]"
    puts $fileID "set tempNotes [list $deckStorage($w,notes)]"
    puts $fileID "set tempDeckTitle [list $deckStorage($w,deckTitle)]"
    puts $fileID "set tempCheckInv [list $deckStorage($w,checkInv)]"
    puts $fileID "set tempInventory [list $deckStorage($w,inventory)]"
    puts $fileID \
        "set tempDeckDisplayMode [list $deckStorage($w,deckDisplayMode)]"

    # Deck cards
    puts -nonewline $fileID "set tempDeck \{\n  "
    set lineCount 0
    foreach card $deckStorage($w,deck) {
        set out [format "\{%-3s %3d\}" [lindex $card 0] [lindex $card 1]]
        puts -nonewline $fileID " $out"
        incr lineCount
        if {$lineCount == 7} {
            puts -nonewline $fileID "\n  "
            set lineCount 0
        }
    }
    puts $fileID "\n\}"

    # Alternate cards
    puts -nonewline $fileID "set tempAltCards \{\n  "
    set lineCount 0
    foreach card $deckStorage($w,altCards) {
        set out [format "\{%-3s %3d\}" [lindex $card 0] [lindex $card 1]]
        puts -nonewline $fileID " $out"
        incr lineCount
        if {$lineCount == 7} {
            puts -nonewline $fileID "\n  "
            set lineCount 0
        }
    }
    puts $fileID "\n\}"

    close $fileID
    if {$CrossFire::platform == "macos9"} {
        file attributes $fileName -type $CrossFire::macCode(deck) \
            -creator $CrossFire::macCode(creator)
    }

    return 1
}

