# Common.tcl 20060210
#
# This file defines the common routines used throughout CrossFire.
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

# CrossFire::DoNothing --
#
#   Actually, does nothing at all.
#
# Parameters:
#   None (and why would there be!)
#
# Returns:
#   Nothing, obviously!
#
proc CrossFire::DoNothing {} {
    # Yep this does nothing.  Imagine that!
    # It is used for WM_DELETE_WINDOW trapping when no action is desired.
    return
}

# CrossFire::SetClipboard --
#
#   Assigns text to the clipboard for pasting.
#
# Parameters:
#   msg        : Text to copy to clipboard
#
# Returns:
#   Nothing.
#
proc CrossFire::SetClipboard {msg} {

    clipboard clear
    clipboard append $msg

    return
}

# CrossFire::Help --
#
#   Opens a CrossFire help page.
#
# Arguments:
#   page      The filename of the HTML page.
#
# Results:
#   Nothing.
#
proc CrossFire::Help {page} {

    OpenURL $page help

    return
}

# CrossFire::Register --
#
#   Registers a new toplevel created by one of the subprocess with
#   CrossFire.  Used for tracking what toplevels are active for each
#   subprocess.  The UpdateConfig subroutine will be called for each
#   toplevel when a change is made to the process's configuration.
#
# Parameters:
#   process    : Name of the subprocess creating the toplevel.
#                (DeckIt, SwapShop, Warehouse, etc)
#   tlw        : Widget path of the new toplevel.
#
# Returns:
#   Nothing.
#
proc CrossFire::Register {process tlw} {

    variable toplevelReg

    lappend toplevelReg($process) $tlw

    return
}

# CrossFire::ToplevelList --
#
#   Returns a list of all toplevel that are registered for a process.
#
# Parameters:
#   process    : Name a process
#
# Returns:
#   The list of ids.
#
proc CrossFire::ToplevelList {process} {

    variable toplevelReg

    return $toplevelReg($process)
}

# CrossFire::UnRegister --
#
#   Un-registers a toplevel created by one of the subprocess with
#   CrossFire.
#
# Parameters:
#   process    : Name of the subprocess that created the toplevel.
#                (DeckIt, SwapShop, Warehouse, etc)
#   tlw        : Widget path of the toplevel.
#
# Returns:
#   Nothing.
#
proc CrossFire::UnRegister {process tlw} {

    variable toplevelReg

    set index [lsearch -exact $toplevelReg($process) $tlw]
    set toplevelReg($process) \
        [lreplace $toplevelReg($process) $index $index]

    return
}

# CrossFire::LockFile --
#
#   Attempts to "lock" a file.
#
# Parameters:
#   w          : Toplevel.
#   fileName   : Name of file to lock.
#   args       : Optional nocomplain which raises the owner of the file
#                if it is already in use.
#
# Returns:
#   Nothing.
#
proc CrossFire::LockFile {w fileName args} {

    variable fileLock

    set ok 1

    if {[info exists fileLock($fileName)]} {
        if {$fileLock($fileName) != $w} {
            # Another toplevel owns the file
            set ok 0

            if {[lindex $args 0] == "nocomplain"} {
                wm deiconify $w
                raise $w
            } else {
                # This is to gripe about it
                set short [file tail $fileName]
                set msg "The requested file \"$short\" is already in use."
                tk_messageBox -icon error -title "File In Use" -message $msg
            }
        }
    } else {
        set fileLock($fileName) $w
    }

    return $ok
}

# CrossFire::UnlockFile --
#
#   Unlocks a file if owned by the specified toplevel.
#
# Parameters:
#   w          : Toplevel.
#   fileName   : Name of file to lock.
#
# Returns:
#   Nothing.
#
proc CrossFire::UnlockFile {w fileName} {

    variable fileLock

    set ok 1
    if {[info exists fileLock($fileName)] && ($fileLock($fileName) == $w)} {
        unset fileLock($fileName)
    } else {
        # Strange...trying to unlock a file not locked by the widget.
        # This should never happen...
        set ok 0
    }

    return $ok
}

# CrossFire::AutoLoad --
#
#   Loads a file into a new editor of the appropriate type.
#
# Parameters:
#   fileName   : File to open.
#
# Returns:
#   Nothing.
#
proc CrossFire::AutoLoad {fileName} {

    variable extension

    set ext [string tolower [file extension $fileName]]
    if {$ext == $extension(deck)} {
        Editor::Create $fileName
    } elseif {$ext == $extension(inv)} {
        Inventory::Create $fileName
    } elseif {$ext == $extension(format)} {
        FormatIt::Create $fileName
    } elseif {$ext == $extension(trade)} {
        SwapShop::Create $fileName
    } elseif {$ext == $extension(combo)} {
        Combo::Create $fileName
    } elseif {$ext == $extension(log)} {
        Chat::CreateLogViewer $fileName
    } else {
        tk_messageBox -icon error \
            -message "No support for auto loading $fileName...yet!"
    }

    return
}

# CrossFire::InitializeFanSets --
#
#   Calls AddCardSet for each fan set.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc CrossFire::InitializeFanSets {} {

    variable extension
    variable homeDir

    set globPattern \
        [file join $homeDir "FanSets" "*$extension(config)"]

    foreach fileName [lsort [glob -nocomplain $globPattern]] {

        set fid [open $fileName "r"]
        set cfgData [read $fid]
        close $fid

        SetSafeVar attributes {}

        catch {
            safeInterp eval $cfgData
        }

        foreach var {
            setID setName numRegular numChase worldDef attributes
        } {
            set $var [GetSafeVar $var]
        }

        set tclFile ${setID}.tcl
        AddCardSet fan $setID $setName $numRegular $numChase \
            $tclFile na $attributes
        if {$worldDef != ""} {
            eval AddWorld fan $worldDef
        }
    }

    return
}

# CrossFire::SplitLine --
#
#   This procedure splits a line of text into multiple shorter lines.  This is
#   used for formatting card descriptions on a plain line printer.
#
# Parameters:
#   width      : Maximum width of each small line.
#   line       : Line of text to split.
#   args       : If present, the first arg is an indent amount.
#
# Returns:
#   The formatted line.
#
proc CrossFire::SplitLine {width line args} {

    variable spaces

    set indent 0

    if {$args != ""} {
        set indent [lindex $args 0]
    }

    set is [string repeat " " $indent]
    set lp $indent
    set out $is
    regsub -all "\n" $line " \n " line

    foreach word [split $line " "] {
        if {$word == "\n"} {
            append out "$word$is"
            set lp $indent
        } else {
            set len [string length $word]
            if {[expr $lp + $len] >= $width} {
                set lp $indent
                set word "\n$is$word"
            }
            if {$lp > $indent} {
                append out " "
                incr lp
            }
            incr lp $len
            append out $word
        }
    }

    return "[string trimright $out]\n"
}

# CrossFire::CenterString --
#
#   Centers a string by adding leading spaces.  Removes any
#   leading and/or trailing spaces.
#
# Parameters:
#   string     : The string to center.
#   width      : The width of the line. Defaults to 80.
#
# Returns:
#   The centered string.
#
proc CrossFire::CenterString {string {width 80}} {

    variable spaces

    set string [string trim $string " "]
    set len [string length $string]

    if {$len >= $width} {
        set centered $string
    } else {
        set pad [expr ($width - $len) / 2]
        set centered [string range $spaces 1 $pad]
        append centered $string
    }

    return $centered
}

# CrossFire::StripZeros --
#
#   Remove leading zeros from a number.  This is to eliminate
#   getting the error that 08 or 09 is not a number.
#
# Parameters:
#   number     : The number to convert
#
# Returns:
#   number without leading zeros.
#
proc CrossFire::StripZeros {number} {

    set number [string trimleft $number "0"]

    if {$number == ""} {
        return 0
    } else {
        return $number
    }
}

# CrossFire::GetCardID --
#
#   Gets the short card ID, short number, and maximum
#   for a card from a set ID and card number.
#
# Parameters:
#   setID      : The 2 or 3 character ID for the card set.
#   cardNumber : "Raw" card number.
#   mode       : Optional return method.
#
# Returns:
#   List of {short card ID} {short card number} {max cards}
#
# Example:
#   GetCardID FR 118       => FRc/18 18 25
#   GetCardID FR 118 split => FRc 18
#
proc CrossFire::GetCardID {setID rawCardNumber {mode "normal"}} {

    variable setXRef

    set cardNumber $rawCardNumber
    set numberLen 3  ;# For number padding.

    # Determine the "of x" number.
    if {$cardNumber > $setXRef($setID,setMax)} {
        # This is a chase card
        set numberLen 2
        set chase "c"
        # Change the card number by the last number limit.
        incr cardNumber -$setXRef($setID,setMax)
        set numLimit $setXRef($setID,chaseQty)
    } else {
        set chase ""
        foreach numLimit $setXRef($setID,numLimits) {
            if {$cardNumber <= $numLimit} {
                break
            }
        }
    }

    # Check for the few cards that are incorrectly numbered.
    # OK, so I am a stickler for detail!  :)
    if {($setID == "DR") && ($rawCardNumber == 16)} {
        # Draconomicon 16
        set numLimit 10
    } elseif {($setID == "4th") && ($rawCardNumber == 375)} {
        # Fourth Edition 375
        set numLimit 400
    }

    if {$mode == "normal"} {
        set out "$setID$chase/[format %0${numberLen}d $cardNumber]"
        append out " $cardNumber $numLimit"
    } elseif {$mode == "split"} {
        set out "$setID$chase $cardNumber"
    }

    return $out
}

# CrossFire::GetValidSetID --
#
#   Determines if a set ID is valid or not.  First checks the ID as given,
#   then all lower case (ex: 1st) and finally all upper case (ie: FR).
#
# Parameters:
#   setID      : Set ID to test.
#
# Returns:
#   The valid form of the ID if is exists or "" if not.
#
proc CrossFire::GetValidSetID {setID} {

    variable setXRef

    set validID ""
    set setIDlc [string tolower $setID]
    set setIDuc [string toupper $setID]

    if {[info exists setXRef($setID,name)]} {
        set validID $setID
    } elseif {[info exists setXRef($setIDlc,name)]} {
        set validID $setIDlc
    } elseif {[info exists setXRef($setIDuc,name)]} {
        set validID $setIDuc
    }

    return $validID
}

# CrossFire::DecodeShortID --
#
#   Decodes a short card ID into the set ID and card number.
#
# Parameters:
#   shortID    : The cards short ID.
#
# Returns:
#   The set ID and card number.
#
# Example:
#   DecodeShortID FRc/18  ==  FR 118
#
proc CrossFire::DecodeShortID {shortID} {

    variable setXRef

    set setNumber [split $shortID "/"]
    set setID [lindex $setNumber 0]
    set cardNumber [StripZeros [lindex $setNumber 1]]
    set validSetID [GetValidSetID $setID]

    if {($validSetID == "") && ([regexp -nocase "c\$" $setID] != 0)} {
        # This might be a chase card
        regsub -nocase "c\$" $setID "" chaseSetID
        set validSetID [GetValidSetID $chaseSetID]
        if {$validSetID != ""} {
            incr cardNumber $setXRef($validSetID,setMax)
        }
    }

    if {$validSetID == ""} {
        set validSetID $setID
    }

    return "$validSetID $cardNumber"
}

# CrossFire::GetCard --
#
#   Gets a card from the card database.
#
# Parameters:
#   Short ID   : A short card ID. (ie: FRc/18)
#     -or-
#   Set ID     : Card set ID. (ie: FR)
#   Number     : Raw card number (ie: 118)
#
# Returns:
#   The card if possible, "" if not.
#
proc CrossFire::GetCard {ID args} {

    variable cardDataBase
    variable setXRef
    variable homeDir
    variable cardCache

    set cache 1
    set first [lindex $ID 0]
    if {($first == "+") || ($first == "-") || ($first == "Deck")} {
        return ""
    }

    while {[regexp -- "^-" [lindex $args end]]} {
        switch -- [lindex $args end] {
            "-nocache" {
                set cache 0
            }
        }
        set args [lreplace $args end end]
    }

    set argCount [llength $args]

    switch -- $argCount {
        0 {
            # Short ID
            set ok 0  ;# Flag if we got the card.
            set shortID $ID

            # Test if this is really a shortID or not.
            if {[regexp "/" $shortID]} {
                set decodeInfo [DecodeShortID $shortID]
                set setID      [lindex $decodeInfo 0]
                set cardNumber [lindex $decodeInfo 1]
                set ok 1
            }

            if {$ok == 0} {
                return ""
            }
        }
        1 {
            # Set ID and number
            set setID $ID
            set cardNumber [lindex $args 0]
        }
    }

    if {[info exists cardCache($setID/$cardNumber)] && ($cache == 1)} {
        # Card has been previously cached
        set card $cardCache($setID/$cardNumber)
    } else {
        # Either not caching or first time accessed
        ReadCardDataBase $setID
        if {($cardDataBase != "") && ($cardNumber > 0)} {
            set card [lindex $cardDataBase $cardNumber]
            if {$Config::config(CrossFire,memoryMode) == "Medium"} {
                # Just caching cards as they are accessed.
                set cardCache($setID/$cardNumber) $card
            } elseif {$Config::config(CrossFire,memoryMode) == "Large"} {
                # Cache the entire card set.
                foreach tempCard [lrange $cardDataBase 1 end] {
                    set index "[lindex $tempCard 0]/[lindex $tempCard 1]"
                    set cardCache($index) $tempCard
                }
            }
        } else {
            set card ""
        }
    }

    return $card
}

# CrossFire::ReadCardDataBase --
#
#   Loads the specified card data base, or removes the
#   card data base from memory if no file specified.
#
# Parameters:
#   setID     : The ID of the file name to load card data base from
#
# Returns:
#   Nothing.
#
proc CrossFire::ReadCardDataBase {setID} {

    variable cardDataBase
    variable homeDir
    variable setXRef
    variable errorMsg

    if {($setID == "") || ($setID == "All")} {
        set cardDataBase ""
        return
    }

    # It is possible that a deck could contain a card from a card set
    # that no longer exists (especially with fan sets), so warn the user
    # when encountering such a set.  This warning is flagged so we don't
    # spam them with warnings. :)
    if {![info exists setXRef($setID,tclFile)]} {
        if {[info exists errorMsg($setID)] == 0} {
            set msg "Card Set $setID has been removed or typed incorrectly!"
            tk_messageBox -icon error -title "ACK! Missing File!" \
                -message $msg
            set errorMsg($setID) 1
        }
        set cardDataBase ""
        return
    }

    set fid [open $setXRef($setID,tclFile) "r"]
    set command [read $fid]
    close $fid

    catch {
        safeInterp eval $command
    }

    set cardDataBase [GetSafeVar CrossFire::cardDataBase]

    return
}

# CrossFire::GetCardDesc --
#
#   Returns a short card description.  Mainly for use in a list box.
#
# Paramters:
#   card      : A card in standard card format or {setID num}
#   idLoc     : Where should the card ID be. (front or end)
#
# Returns:
#   A short card description.  ie: AR/045 Pegasus, +3 (C)
#                               or Pegasus, +3 (C) AR/045
#
proc CrossFire::GetCardDesc {card {idLoc front}} {

    variable worldXRef

    # Change from {setID num} to regular card.
    if {[llength $card] == 2} {
        set card [eval GetCard $card]
    }

    set cardID [lindex [GetCardID [lindex $card 0] [lindex $card 1]] 0]
    set cardDesc [lindex $card 6]
    set world $worldXRef([lindex $card 4],shortName)
    set bonus [lindex $card 2]

    if {$bonus != ""} {
        if {$world == ""} {
            append cardDesc ", ($bonus)"
        } else {
            append cardDesc ", ($world/$bonus)"
        }
    } elseif {$world != ""} {
        append cardDesc ", ($world)"
    }

    # Rarity. Not sure why I felt the need for this.
    #append cardDesc ", [lindex $card 8]"

    if {$idLoc == "front"} {
        set cardDesc "$cardID $cardDesc"
    } else {
        append cardDesc " $cardID"
    }

    return $cardDesc
}

# CrossFire::ScrolledListBox --
#
proc CrossFire::ScrolledListBox {f args} {

    set title ""
    set titlevar ""
    set height 10
    set width 20
    set foreground $Config::config(CrossFire,listBoxFG)
    set background $Config::config(CrossFire,listBoxBG)
    set selectbackground $Config::config(CrossFire,listBoxSelectBG)
    set selectforeground $Config::config(CrossFire,listBoxSelectFG)
    set selectmode single
    set exportselection 0

    foreach {option value} $args {
        set [string range $option 1 end] $value
    }

    frame $f

    if {$title != "" || $titlevar != ""} {
        label $f.title -text $title -anchor w
        if {$titlevar != ""} {
            $f.title configure -textvariable $titlevar
            set $titlevar $title
        }
        grid $f.title - -sticky w
        set row 1
    } else {
        set row 0
    }

    frame $f.list
    set lbw $f.list.lb
    listbox $lbw -exportselection $exportselection \
        -yscrollcommand "CrossFire::SetScrollBar $f.list.sb" \
        -selectmode $selectmode -width $width -height $height \
        -background $background -selectbackground $selectbackground \
        -foreground $foreground -selectforeground $selectforeground
    scrollbar $f.list.sb -command "$lbw yview"
    grid $f.list.lb -sticky nsew
    grid columnconfigure $f.list 0 -weight 1
    grid rowconfigure $f.list 0 -weight 1

    grid $f.list -sticky nsew
    grid columnconfigure $f 0 -weight 1
    grid rowconfigure $f $row -weight 1

    return $lbw
}

# CrossFire::ScrolledCheckBox --
#
#   Creates a list box with a title, selection checkbutton,
#   and a scrollbar.
#
# Parameters:
#   w          : Frame widget name to create within.
#   varName    : Variable to associate with the checkbutton.
#   args       : Various options. -title, -side
#
# Returns:
#   Widget name of the listbox.
#
proc CrossFire::ScrolledCheckBox {w varName args} {

    frame $w

    set title "Selections:"
    set titleAlign "w"
    set height 10
    set width 10

    foreach {arg value} $args {
        switch -- $arg {
            -height { set height $value }
            -width  { set width $value  }
            -title  { set title $value  }
            -side {
                switch -- $value {
                    left   { set titleAlign "w"  }
                    center { set titleAlign "ew" }
                    right  { set titleAlign "e"  }
                }
            }
        }
    }

    checkbutton $w.cb -text $title -variable $varName -padx 0

    frame $w.list
    listbox $w.list.lb -exportselection 0 \
        -yscrollcommand "CrossFire::SetScrollBar $w.list.sb" \
        -selectmode multiple -width $width -height $height
    scrollbar $w.list.sb -command "$w.list.lb yview"
    grid $w.list.lb -sticky nsew
    grid rowconfigure $w.list 0 -weight 1
    grid columnconfigure $w.list 0 -weight 1

    grid $w.cb -sticky $titleAlign
    grid $w.list -sticky nsew
    grid rowconfigure $w 1 -weight 1
    grid columnconfigure $w 0 -weight 1

    return $w.list.lb
}

# CrossFire::CardSetToListBox --
#
#   Adds the short descriptions of each card that is of a specified
#   card type in a card set to a list box.
#
# Parameters:
#   cardSet    : A set of cards.
#   lbw        : List box widget to add to.
#   selTypeID  : Card type numeric ID to display.
#   mode       : 'clear', 'append', or 'deck'.  Clear and deck
#                delete the list box contents first, append does not.
#                Deck starts at index 0, clear and append start at 1.
#
# Returns:
#   Nothing.
#
proc CrossFire::CardSetToListBox {cardSet lbw selCardID mode} {

    variable championList
    variable setXRef

    set start 1
    if {($mode == "clear") || ($mode == "deck")} {
        $lbw delete 0 end
        if {$mode == "deck"} {
            set start 0
        }
    }

    for {set i $start} {$i < [llength $cardSet]} {incr i} {

        set card [lindex $cardSet $i]
        foreach {setID cardNumber trash typeID} $card {break}

        if {($selCardID == 0) || ($selCardID == $typeID) ||
            (($selCardID == 99) && ([lsearch $championList $typeID] != -1)) ||
            (($selCardID == 100) && ($cardNumber > $setXRef($setID,setMax)))} {
            $lbw insert end [GetCardDesc $card]
        }
    }

    return
}

# CrossFire::SetScrollBar --
#
#   Maps or unmaps a scrollbar as needed.  This is assumed to be a scrollbar
#   that is in a grid position of row=0 and column=1 as it should be!
#
# Parameters:
#   sbw        : Scrollbar widget name.
#   args       : Numbers from a yscrollcommand.
#
# Returns:
#   Nothing.
#
proc CrossFire::SetScrollBar {sbw args} {

    if {($args == "0 1") || ($args == "0 0")} {
        grid remove $sbw
    } else {
        grid $sbw -row 0 -column 1 -sticky ns
        eval $sbw set $args
    }

    return
}

# CrossFire::InitListBox --
#
#   Initializes a listbox's bindings for keyboard naviagtion.
#
# Parameters:
#   tw         : Toplevel widget name.
#   lbw        : Listbox widget name.
#   nameSpace  : Namespace the widgets were created in.
#
# Returns:
#   Nothing.
#
proc CrossFire::InitListBox {tw lbw nameSpace} {

    # Listbox and keyboard navigation bindings.
    foreach buttonNum "1 2 3" {
        bind $lbw <ButtonPress-$buttonNum> \
            "${nameSpace}::ClickListBox $tw %X %Y $buttonNum"
    }
    bindtags $lbw "$lbw all"

    # Some bindings for keyboard navigation of the card list.
    bind $tw <Key-Home>  "${nameSpace}::ClickListBox $tw m 0   0"
    bind $tw <Key-End>   "${nameSpace}::ClickListBox $tw m end 0"
    bind $tw <Key-Down>  "${nameSpace}::ClickListBox $tw m +1  0"
    bind $tw <Key-Up>    "${nameSpace}::ClickListBox $tw m -1  0"
    bind $tw <Key-Next>  "${nameSpace}::ClickListBox $tw m +25 0"
    bind $tw <Key-Prior> "${nameSpace}::ClickListBox $tw m -25 0"

    return
}

# CrossFire::InitSearch --
#
#   Initialize the variables and bindings needed for listbox searching.
#
# Parameters:
#   tw         : Toplevel widget name.
#   ew         : Entry widget search string will be typed in to.
#   lbw        : Listbox to search.
#   nameSpace  : Namespace the widgets were created in.
#
# Returns:
#   Nothing.
#
proc CrossFire::InitSearch {tw ew lbw nameSpace} {

    variable searchListBox

    set searchListBox($lbw,nameSpace) $nameSpace
    set searchListBox($lbw,lastWasRepeat) 0
    bind $ew <Key-Prior> "CrossFire::SearchListBox $tw $lbw -1"
    bind $ew <Key-Next> "CrossFire::SearchListBox $tw $lbw 1"
    $ew configure -textvariable CrossFire::searchListBox($lbw,searchFor)
    trace variable CrossFire::searchListBox($lbw,searchFor) w \
        "CrossFire::BeginSearch $tw $lbw"
    bindtags $ew "$ew Entry"

    return
}

# CrossFire::ClickListBox --
#
#   Moves the selection to the line clicked on or moved to.
#
# Parameters:
#   w          : Toplevel widget name.
#   lbw        : The listbox widget name.
#   X,Y        : %X,%Y of click or m (for move) and line.
#
# Returns:
#   The current line number of the selection.
#
proc CrossFire::ClickListBox {w lbw X Y {multi no}} {

    # Save the current selection in case ClickListBox was called
    # as a move command.
    set curSel [$lbw curselection]
    if {$curSel == ""} {
        set curSel -1
    }
    set curSel [lindex $curSel 0]

    # Determine which line was clicked/requested.
    # A line is requested by specifing m for the X coordinate.
    # The Y value will either contain on offset (+/- lines) or
    # an absolute line number (line).
    if {$X == "m"} {
        set first [string index $Y 0]
        if {$first == "-"} {
            set line [expr $curSel + $Y]
            if {$line < 0} {
                set line 0
            }
        } elseif {$first == "+"} {
            set line [expr $curSel + [string range $Y 1 end]]
            if {$line >= [$lbw index end]} {
                set line end
            }
        } else {
            set line $Y
        }
    } else {

        # We only want to adjust focus if this was an actual click
        # on the list box.
        focus [winfo toplevel $lbw]

        set line [$lbw nearest [expr [winfo pointery $lbw] \
                                    - [winfo rooty $lbw]]]
    }

    if {$multi == "no"} {
        # Clear the list and highlight the line clicked.
        $lbw selection clear 0 end
        $lbw selection set $line
    } else {
        # Clear or set the selected line clicked.
        if {[lsearch [$lbw curselection] $line] != -1} {
            $lbw selection clear $line $line
        } else {
            $lbw selection set $line
        }
    }
    $lbw see $line

    return $line
}

# CrossFire::BeginSearch --
#
#   Begins a search on a listbox.  This procedure is called every time the
#   trace variable is changed.  To improve the performance, we only
#   actually call the search routine after the user stops typing for
#   a half a second.
#
# Parameters:
#   tw         : Toplevel widgnet name.
#   lbw        : Listbox widget name.
#   args       : Contains extra information that trace adds to the command.
#
# Returns:
#   Nothing.
#
proc CrossFire::BeginSearch {tw lbw args} {

    variable searchListBox

    if {[info exists searchListBox($lbw,searchAfterID)]} {
        after cancel $searchListBox($lbw,searchAfterID)
        unset searchListBox($lbw,searchAfterID)
    }

    set searchListBox($lbw,searchAfterID) \
        [after 250 "CrossFire::SearchListBox $tw $lbw 0"]

    return
}

# CrossFire::SearchListBox --
#
#   Searches a listbox either backwards repeat, forwards for string,
#   or forward repeat string.
#
# Parameters:
#   lbw        : Listbox widget name.
#   mode       : Search direction. -1 = backwards, 0 = from current
#                posistion, 1 = forward from next position.
#
# Returns:
#   Nothing.
#
proc CrossFire::SearchListBox {tw lbw mode} {

    variable searchListBox

    if {[info exists searchListBox($lbw,searchAfterID)]} {
        unset searchListBox($lbw,searchAfterID)
    }

    # Test to see if the regular expression is valid.  Return if not.
    if {($searchListBox($lbw,searchFor) != "") &&
        [catch {regexp -nocase -- $searchListBox($lbw,searchFor) {} ok}]} {
        return
    }

    set keep [$lbw curselection]
    if {$keep == ""} {
        set keep 0
    }

    $lbw selection clear 0 end
    set found 0
    set start 0
    set stop [$lbw size]
    set step 1

    if {($searchListBox($lbw,lastWasRepeat) == 1) && ($mode == 0)} {
        set searchListBox($lbw,lastWasRepeat) 0
        set start [expr $keep + 1]
    }

    # Repeat search forward
    if {$mode == 1} {
        set start [expr $keep + 1]
        set searchListBox($lbw,lastWasRepeat) 1
    }

    # Repeat search backwards
    if {$mode == -1} {
        set start [expr $keep - 1]
        set step -1
        set stop -1
        set searchListBox($lbw,lastWasRepeat) 1
    }

    for {set index $start} {$index != $stop} {incr index $step} {
        if {[regexp -nocase -- $searchListBox($lbw,searchFor) \
                 [$lbw get $index]]} {
            set found 1
            set nameSpace $searchListBox($lbw,nameSpace)
            ${nameSpace}::ClickListBox $tw m $index 0
            $lbw see $index
            break
        }
    }

    if {$found == 0} {
        $lbw selection set $keep
    }

    return
}

# CrossFire::OpenURL --
#
#   Attempts to open a URL in a web browser.
#
# Parameters:
#   url        : The URL to open.
#
# Returns:
#   Nothing.
#
proc CrossFire::OpenURL {url {help 0}} {

    variable platform
    variable homeDir
    variable ie

    if {$help == 0} {
        if {([regexp "^http://" $url] == 0) &&
	    ([regexp "^mailto:" $url] == 0)} {
            set url "http://$url"
        }
    }

    switch $platform {
        "windows" {
	    set err {}
            if {$::tcl_platform(os) == "Windows 95"} {
                # Windows 95, 98, ME(?)
                if {$help != 0} {
                    set url [file join $homeDir "Help" $url]
                }
                if {$ie != ""} {
                    # Make sure current IE object is still alive.  If not,
                    # clear ie so a new one is created.
                    if {[catch {set alive [$ie Application]} err]} {
                        dputs "$ie is dead"
                        set ie ""
                    }
                }
                if {$ie == ""} {
                    set ie [::tcom::ref createobject \
                                "InternetExplorer.Application"]
                    $ie Visible 1
                    dputs "Create new IE $ie"
                }
                $ie Navigate $url
            } else {
                # Windows NT, XP
                regsub -all "&" $url "^&" url
                set command "[auto_execok start] {} [list $url]"
                if {$help == 0} {
                    if {[catch {eval exec $command &} err]} {
                        dputs "Error:$err"
                    }
                } else {
                    set cwd [pwd]
                    cd [file join $homeDir "Help"]
                    catch {eval exec $command &} err
                    cd $cwd
                }
            }
        }
        "macintosh" {
	    if {$help == 0} {
		catch {exec open $url} err
	    } else {
		set cwd [pwd]
		cd [file join $homeDir "Help"]
		catch {exec open $url} err
		cd $cwd
	    }
	}
        "unix" {
            set browser $Config::config(Linux,webBrowser)
            if [catch {exec $browser -remote "openURL($url)" >& /dev/null}] {
                if [catch {exec $browser $url &} error] {
                    puts "CrossFire cannot talk to $browser.  :("
                }
            }
        }
    }

    return
}

proc LISort {i equalProc a b} {

    # Sort on just lindex 1:
    #    lsort -command "LISort 1 {}" $list
    # Sort on lindex 1, then 2:
    #    lsort -command "LISort 1 {LISort 2{}}" $list

    set a1 [lindex $a $i]
    set b1 [lindex $b $i]
    if {$a1 == $b1} {
        if {$equalProc != ""} {
            return [eval $equalProc "{$a}" "{$b}"]
        } else {
            return 0
        }
    } elseif {$a1 < $b1} {
        return -1
    } else {
        return 1
    }
}

# CrossFire::GetIDListName --
#
#   Finds a suitable name for a list of card set IDs.  Boosters if all the
#   booster IDs are listed, etc.
#
# Parameters:
#   listOfIDs  : List of card set IDs.
#
# Returns:
#   The name.
#
proc CrossFire::GetIDListName {listOfIDs} {

    variable setClass

    if {[llength $listOfIDs] == 1} {
        # This is a setID
        set fname $listOfIDs
    } else {
        # Multiple set ids from a set class. Create a name or all the IDs,
        # then try to find the class name.
        regsub -all " " $listOfIDs "_" fname
        set setList [lsort $listOfIDs]
        foreach class $setClass(list) {
            set classSetList [lsort [CardSetIDList $class]]
            if {$classSetList == $setList} {
                regsub -all " " $setClass($class,name) "_" fname
            }
        }
    }

    return $fname
}

# CrossFire::CardSetClassList --
#
proc CrossFire::CardSetClassList {which} {

    variable setClass

    switch -- $which {
        "all" {
            set classes $setClass(list)
        }
        "allPlain" {
            # All the sets, without the "All"
            set classes "ed bost stik intl fan"
        }
        "real" {
            # Refers to just the real card sets, no fan sets
            set classes "ed bost stik intl"
        }
        "realAll" {
            # Refers to just the real card sets with "all" included
            set classes "all ed bost stik intl"
        }
        "english" {
            set classes "ed bost stik"
        }
        default {
            set classes $which
        }
    }

    return $classes
}


# CrossFire::CardSetIDList --
#
#   Returns a complete list of all set IDs that are
#   part of the requested type.
#
# Parameters:
#   which      : Which set types to include.
#                (all, real, baseAll, fan, ed, bost, intl, english)
#
# Returns:
#   A list a set IDs.
#
proc CrossFire::CardSetIDList {which} {

    variable setClass

    set idList {}
    foreach class [CardSetClassList $which] {
	append idList "$setClass($class,ids) "
    }

    return [string trim $idList]
}

# CrossFire::CreateCardSetMenu --
#
# Parameters:
#   m          : Menu widget name
#   which      : Which sets to include. (all, real, etc)
#   var        : Variable associated with the menu.
#   cmd        : Command to execute when called.
#
# Returns:
#   Nothing.
#
proc CrossFire::CreateCardSetMenu {m which var cmd} {

    variable setXRef
    variable setClass

    # Remove the old menu and its submenus
    $m delete 0 end
    foreach child [winfo children $m] {
        $child delete 0 end
        destroy $child
    }

    foreach class [CardSetClassList $which] {
        if {$class != "all"} {
            set sm $m.$class
            $m add cascade \
                -label $setClass($class,name) \
                -menu $sm
            menu $sm -tearoff 0
            set idList [CardSetIDList $class]
        } else {
            set sm $m
            set idList "All"
        }

        foreach setID $idList {
            set name $setXRef($setID,name)
            $sm add radiobutton \
                -label $name -value $setID \
                -variable $var -command $cmd
        }
    }

    return
}

# CrossFire::CreateCardSetSelection --
#
# Parameters:
#   w          : card set selection widget name
#   which      : Which sets to include. (all, real, etc)
#
# Returns:
#   Nothing.
#
proc CrossFire::CreateCardSetSelection {w which command {setID ""}} {

    variable setClass
    variable cardSetSel

    frame $w

    text $w.t -exportselection 0 -width 20 -height 10 -spacing1 2 \
        -wrap none -cursor {} -background white -foreground black \
        -yscrollcommand "CrossFire::SetScrollBar $w.sb" -takefocus 0
    set cardSetSel($w,text) $w.t
    $w.t tag configure className -font {Times 14 bold}
    $w.t tag configure select -foreground white -background blue
    scrollbar $w.sb -command "$w.t yview" -takefocus 0
    grid $w.t -sticky nsew
    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 1

    foreach buttonNum "1 2 3" {
        bind $w.t <ButtonPress-$buttonNum> \
            "CrossFire::ClickCardSetSelection $w %X %Y"
        bind $w.t <Control-ButtonPress-$buttonNum> \
            "CrossFire::ClickCardSetSelection $w %X %Y toggle"
        bind $w.t <Double-Button-$buttonNum> "break"
    }
    bindtags $w.t "$w.t all"

    set cardSetSel($w,which) $which
    set cardSetSel($w,command) $command
    set cardSetSel($w,selectedID) $setID

    DisplayCardSetSelection $w

    return $w
}

# CrossFire::DisplayCardSetSelection --
#
# Parameters:
#   w          : card set selection widget name
#
# Returns:
#   Nothing.
#
proc CrossFire::DisplayCardSetSelection {w} {

    variable setXRef
    variable setClass
    variable cardSetSel

    set tbw $cardSetSel($w,text)

    # Remove the old selection
    $tbw delete 1.0 end
    $tbw tag remove select 1.0 end

    set pos 0
    set savePos ""

    foreach class [CardSetClassList $cardSetSel($w,which)] {
        if {$class != "all"} {
            $tbw insert end "\n"
            set className $setClass($class,name)
            $tbw insert end $className className
            set idList [CardSetIDList $class]
            incr pos
            if {$cardSetSel($w,selectedID) == $class} {
                lappend savePos $pos
            }
            set cardSetSel($w,$class) $pos
            set cardSetSel($w,$className) $class
        } else {
            set idList "All"
        }

        foreach setID $idList {

            # Track where we are for inserting newlines and for
            # moving the highlight to a specific set.
            if {$pos > 0} {
                $tbw insert end "\n"
            }
            incr pos
            set cardSetSel($w,$setID) $pos

            set name $setXRef($setID,name)
            if {$idList == "All"} {
                $tbw insert end "$name" className
            } else {
                $tbw insert end "   $name"
            }

            if {$cardSetSel($w,selectedID) == $setID} {
                lappend savePos $pos
            }
        }
    }

    if {$savePos != ""} {
        foreach pos $savePos {
            $tbw tag add select $pos.0 [expr $pos + 1].0
        }
    }

    return
}

# CrossFire::ClickCardSetSelection --
#
proc CrossFire::ClickCardSetSelection {w X Y {mode normal}} {

    variable cardSetSel
    variable setXRef

    set tbw $cardSetSel($w,text)

    # Determine which line was clicked/requested.
    # A line is requested by specifing m for the X coordinate.
    # The Y value will contain a set ID.
    if {$X == "m"} {
        if {$Y == "all"} { set Y "All" }
        set pos $cardSetSel($w,$Y)
    } else {
        # Translate X,Y to x,y of text box and determine line number.
        set x [expr $X - [winfo rootx $tbw]]
        set y [expr $Y - [winfo rooty $tbw]]
        set pos [expr int([$tbw index @$x,$y])]
    }

    if {$mode == "normal"} {
        # remove the current selection
        $tbw tag remove select 1.0 end
        set cardSetSel($w,selectedID) {}
    }

    if {$pos != ""} {

        if {($mode != "normal") && \
                ([lsearch [$tbw tag names $pos.0] select] != -1)} {
            set action "remove"
        } else {
            set action "add"
        }

        if {$action == "add"} {
            $tbw tag add select $pos.0 [expr $pos + 1].0
        } else {
            $tbw tag remove select $pos.0 [expr $pos + 1].0
        }
	$tbw see $pos.0

        set setName [string trim [$tbw get $pos.0 [expr $pos + 1].0]]

        if {[info exists setXRef($setName)]} {
            set setID $setXRef($setName)
            if {$mode == "normal"} {
                set cardSetSel($w,selectedID) $setID
            } else {
                if {$action == "add"} {
                    lappend cardSetSel($w,selectedID) $setID
                } else {
                    set setPos [lsearch $cardSetSel($w,selectedID) $setID]
                    set cardSetSel($w,selectedID) \
                        [lreplace $cardSetSel($w,selectedID) $setPos $setPos]
                }
            }
        } else {
            foreach setID [CardSetIDList $cardSetSel($w,$setName)] {
                if {$action == "add"} {
                    lappend cardSetSel($w,selectedID) $setID
                } else {
                    set setPos [lsearch $cardSetSel($w,selectedID) $setID]
                    set cardSetSel($w,selectedID) \
                        [lreplace $cardSetSel($w,selectedID) $setPos $setPos]
                }
            }
        }
        eval $cardSetSel($w,command) $cardSetSel($w,selectedID)
    }

    return
}

# CrossFire::GetSafeVar --
#
#   Gets a value from a variable in the safe interpreter.
#
# Parameters:
#   varName    : Name of the var.
#
# Returns:
#   The value of the var.
#
proc CrossFire::GetSafeVar {varName} {

    if {[catch {set value [safeInterp eval "set $varName"]} err]} {
        set value ""
    }

    return $value
}

# CrossFire::SetSafeVar --
#
#   Sets a value from a variable in the safe interpreter.
#
# Parameters:
#   varName    : Name of the var.
#   value      : Value to set.
#
# Returns:
#   Nothing.
#
proc CrossFire::SetSafeVar {varName value} {

    safeInterp eval "set $varName [list $value]"

    return
}

# CrossFire::MakeDeckFormatMenu --
#
#   Creates a cascading menu to the available deck formats.
#
# Parameters:
#   m         : Menu path to create.
#   var       : Global variable to associate.
#   command   : Command to execute when selected. supports $deckFormatID
#
# Returns:
#   Nothing.
#
proc CrossFire::MakeDeckFormatMenu {m var command} {

    variable deckFormat

    menu $m -tearoff 0

    set parent() $m
    set groups [array names deckFormat "IDList,*"]
    set counter 0

    foreach group [lsort -dictionary $groups] {
        regsub "^IDList," $group "" id
        set pList [split $id ","]
        set me [lindex $pList end]
        if {$me == ""} {
            set mw $m
        } else {
            set pName [join [lrange $pList 0 end-1] ","]
            set mw $parent($pName).g[incr counter]
            set parent($id) $mw
            set index end
            set end [$parent($pName) index end]
            for {set tIndex 0} {$tIndex <= $end} {incr tIndex} {
                if {[$parent($pName) type $tIndex] != "cascade"} {
                    set index $tIndex
                    break
                }
            }
            $parent($pName) insert $index cascade -label $me -menu $mw
            menu $mw -tearoff 0
        }

        foreach deckFormatID [lsort $deckFormat($group)] {
            set tCommand $command
            set tCommand [subst $tCommand]
            $mw add radiobutton \
                -variable $var -value $deckFormatID -command $tCommand \
                -label $deckFormat($deckFormatID,menuName)
        }
    }

    return
}

# CrossFire::ReadDeckFormat --
#
#   Reads a deck format file.
#
# Parameters:
#   group     : Number of cards group.
#   deckFormatFile : Name of the file.
#
# Returns:
#   Nothing.
#
proc CrossFire::ReadDeckFormat {group deckFormatFile} {

    # Hold the name and a list of limits for each deck size.
    # Indexed by deck size ID (55, 75, 110, 999, 55NC, etc) and the following:
    #   name        : Size name.
    #
    #   $id,<group>,<data>,$which
    #
    #      group ::= Type | World | Total | Rarity
    #         Type  : card type name
    #         World : world name
    #         Total ::= Avatar | All | Champions | Levels | Chase
    #         Rarity : card rarity
    #
    #      data  ::= min | max | mult
    #         min  : Minimum
    #         max  : Maximum
    #         mult : Number of multiple copies

    variable deckFormat

    set fid [open $deckFormatFile "r"]
    set formatCommand [read $fid]
    close $fid

    # Just in case this is an older deck format
    SetSafeVar tempDeckFormatAllowed {}
    SetSafeVar tempDeckFormatInfo {}

    catch {
        safeInterp eval $formatCommand
    } err

    set id [string toupper [file rootname [file tail $deckFormatFile]]]

    # Will exist already if we are overwriting a format definition
    # This occurs when using Format Maker and saving
    if {[lsearch $deckFormat(IDList) $id] == -1} {
        lappend deckFormat(IDList) $id
        lappend deckFormat(IDList,$group) $id
    }

    set deckFormat($id,name) [GetSafeVar tempDeckFormatTitle]
    set deckFormat($id,bannedList) [GetSafeVar tempDeckFormatBanned]
    set deckFormat($id,allowedList) [GetSafeVar tempDeckFormatAllowed]
    set deckFormat($id,information) [GetSafeVar tempDeckFormatInfo]
    set deckFormat($id,fileName) $deckFormatFile

    foreach {which min max} [GetSafeVar tempDeckFormatTotal] {
        set deckFormat($id,Total,min,$which) $min
        set deckFormat($id,Total,max,$which) $max
    }

    foreach {type varName} {
        Type   tempDeckFormatLimits
        Rarity tempDeckFormatRarity
        World  tempDeckFormatWorld
        Set    tempDeckFormatSet
	Digit  tempDeckFormatDigit
    } {
        foreach {which min max mult} [GetSafeVar $varName] {
            set deckFormat($id,$type,min,$which) $min
            set deckFormat($id,$type,max,$which) $max
            set deckFormat($id,$type,mult,$which) $mult
        }
    }

    # Create menuName
    set menuName $deckFormat($id,name)
    foreach chunk [split $group ","] {
        if {[regsub "^$chunk " $menuName "" menuName] == 0} {
            break
        }
    }
    if {$menuName == ""} {
        # Just in case we "eat" all of the name, set it to original.
        # This shouldn't happen because there needs to be a space
        # after the dir name in the format name to match.  But, CYA!
        set deckFormat($id,menuName) $deckFormat($id,name)
    } else {
        set deckFormat($id,menuName) $menuName
    }

    return $id
}

# CrossFire::ReadDeckFormatDirectory --
#
#   Reads a deck format directory to file .cff files and recurses
#   through sub-directories.
#
# Parameters:
#   dfDir      : Deck format directory under Formats.
#
# Returns:
#   Nothing.
#
proc CrossFire::ReadDeckFormatDirectory {dfDir} {

    variable homeDir
    variable deckFormat

    set fp [file join $homeDir "Formats" $dfDir "*"]

    foreach fileName [glob -nocomplain $fp] {
	if {[file isdirectory $fileName]} {
	    ReadDeckFormatDirectory \
                [file join $dfDir [file tail $fileName]]
	} else {
            set groupName ""
            foreach dirChunk [file split $dfDir] {
                if {$groupName != ""} {
                    append groupName ","
                }
                append groupName $dirChunk
            }
	    set id [ReadDeckFormat $groupName $fileName]
	}
    }

    return
}

# CrossFire::InitializeDeckFormats --
#
#   Reads all of the deck format files.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc CrossFire::InitializeDeckFormats {} {

    variable homeDir
    variable deckFormat

    set deckFormat(IDList) ""

    ReadDeckFormatDirectory ""

    if {$deckFormat(IDList) == ""} {
        tk_messageBox -title "Houston, we have a problem!" -icon error \
            -message "For some reason, you do not have any deck format files."
    } else {
        # Make sure the default deck format still exists
        set dff $Config::config(DeckIt,deckSize)
        if {[lsearch $deckFormat(IDList) $dff] == -1} {
            Config::Set DeckIt,deckSize [lindex $deckFormat(IDList) 0]
        }
    }

    # Sticker Boosters can and will be created after a deck format is made.
    # Rather than requiring all deck formats to be fixed, we will set the
    # limits for undefined SBs to InQuisition's values.
    foreach setID [CardSetIDList "stik"] {
	if {$setID != "IQ"} {
	    foreach dfid $deckFormat(IDList) {
		if {![info exists deckFormat($dfid,Set,min,$setID)]} {
		    set deckFormat($dfid,Set,min,$setID) \
			$deckFormat($dfid,Set,min,IQ)
		    set deckFormat($dfid,Set,max,$setID) \
			$deckFormat($dfid,Set,max,IQ)
		    set deckFormat($dfid,Set,mult,$setID) \
			$deckFormat($dfid,Set,mult,IQ)
		}
	    }
	}
    }

    return
}

# CrossFire::PlaySound --
#
proc CrossFire::PlaySound {id} {

    variable platform
    variable homeDir

    if {[info exists Config::config(Sound,$id,file)]} {
        set soundFile $Config::config(Sound,$id,file)
    } else {
        return 0
    }

    if {($soundFile == "None") || (![file exists $soundFile]) ||
        ($Config::config(Sound,play) == "No")} {
        return 0
    }

    if {$::snackPackage == "Yes"} {
        # Using the very amazing Snack extension!
        set sID [snack::sound -load $soundFile]
        $sID play -command "$sID destroy"
    } else {
        # Old method - puke, barf, gag...
        dputs "You should get ActiveState Tcl for real sound playing!"
        switch -- $platform {
            "windows" {
                catch {
                    exec sndrec32.exe /play /close /embedding $soundFile &
                }
            }
            "unix" {
                catch {set cmd [subst $Config::config(Linux,playSound)]}
                catch {eval exec $cmd 2> /dev/null &} err
            }
        }
    }

    return 1
}

# CrossFire::CreateYogilandLink --
#
#   Create link to Yogiland Reference page via Shift-Click.
#   Currently supported sets are:
#      DR - Draconomicon
#      IQ - Inquisition
#      MI - Millenium
#      CH - Chaos
#      CQ - Conquest
#
# Parameters:
#   w         : Toplevel widget
#   cardID    : Card ID such as IQ/024
#   textTag   : Indicator for if this is a text widget tag
#
# Returns:
#   Nothing.
#
proc CrossFire::CreateYogilandLink {w cardID {textTag label}} {

    variable setXRef
    variable yogiSets

    foreach {setID cardNum} [DecodeShortID $cardID] break

    if {[lsearch $yogiSets $setID] != -1} {

        set cmd [CreateYogilandCommand $setID $cardNum]
	if {$textTag == "label"} {
	    bind $w <Shift-Button-1> "$cmd; break"
	} else {
	    # Text widget tag (chat window)
	    $w tag bind $textTag <Shift-Button-1> "$cmd; break"
	}
    }

    return
}

# CrossFire::CreateYogilandCommand --
#
#   Creates the actual command to be invoked to bring up the Yogiland
#   web page.  Note the pre-testing of setID must be done!
#
# Parameters:
#   setID     : Card set ID
#   cardNum   : Card number (raw)
#
# Returns:
#   Executable command
#
proc CrossFire::CreateYogilandCommand {setID cardNum} {

    variable setXRef

    # There are 25 cards per page, so calc the page number.
    set pageNum [expr ($cardNum - 1) / 25]

    # Convert the page number to its letter equivalent. ie: 0=A, 1=B, etc
    set page [format "%c" [expr $pageNum + 65]]

    # Scale down chase card numbers.  ie: FR 118 => 18
    if {$cardNum > $setXRef($setID,setMax)} {
        set cardNum [expr $cardNum - $setXRef($setID,setMax)]
    }

    set yogiURL "http://www.geocities.com/Yogiland_Central/Rev-"
    append yogiURL "${setID}-${page}.html#$cardNum"

    return "CrossFire::OpenURL $yogiURL"
}