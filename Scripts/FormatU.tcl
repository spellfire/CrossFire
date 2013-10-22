# FormatU.tcl 20050803
#
# This file contains all the utility procedures for editing deck formats.
#
# Copyright (c) 2005 Dan Curtiss. All rights reserved.
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

# Editor::About --
#
#   Displays an about dialog for the Format Maker
#
# Paramters:
#   w         : Parent toplevel for the pop-up dialog.
#
# Returns:
#   Nothing.
#
proc FormatIt::About {w} {
    set message "CrossFire Format Maker is a simple utility for\n"
    append message "editing DeckIt! Deck Formats.\n"
    append message "\nby Dan Curtiss"
    tk_messageBox -icon info -title "About CrossFire Format Maker" \
        -parent $w -message $message
    return
}

# FormatIt::ErrorCheck --
#
#   Does some checks for errors in a deck format file:
#   1) Cards in Allowed and Banned lists.
#   2) Invalid range on minium, maximum, copies - auto fixed
#   3) Dungeon max = 0,1 - auto fixed
#   4) Num champion type > max num champions - auto fixed
#   5) All entries are an integer number - auto fixed
#
# Parameters:
#   w         : Toplevel
#
# Returns:
#   Nothing.
#
proc FormatIt::ErrorCheck {w} {

    variable storage

    set numErrors 0
    set numFixes 0

    # Cards in Allowed and Banned lists
    foreach cardID $storage($w,bannedList) {
        if {[lsearch $storage($w,allowedList) $cardID] != -1} {
            set card [CrossFire::GetCard $cardID]
            set message "Card [CrossFire::GetCardDesc $card]\n"
            append message "is in both the Allowed and Banned lists!"
            tk_messageBox -parent $w -icon error -title "Card Error" \
                -message $message
            incr numErrors
        }
    }

    set gList {Total Limits Rarity World Set Digit}
    set wList {min max mult}
    set deckSize $storage($w,Total,All,max)

    # Check that all data is integer
    foreach var [array names storage "$w,*,*,m*"] {
        if {![string is digit $storage($var)]} {
            set storage($var) 0
            incr numFixes
            dputs "$numFixes) not a number ($var)"
        } elseif {![string is integer $storage($var)]} {
            set storage($var) [expr int($storage($var))]
            incr numFixes
            dputs "$numFixes) not an integer ($var)"
        }
    }

    # Check maximum := deckSize >= max >= 0
    foreach var [array names storage "$w,*,*,max"] {
        if {$storage($var) < 0} {
            set storage($var) 0
            incr numFixes
            dputs "$numFixes) max < 0 ($var)"
        }
        # Dont want to mess with champion level max!
        if {$var == "$w,Total,Levels,max"} continue
        if {$storage($var) > $deckSize} {
            set storage($var) $deckSize
            incr numFixes
            dputs "$numFixes) max > max ($var)"
        }
    }

    # Check dungeon max = 1 (or 0 from above)
    set var "$w,Limits,Dungeon,max"
    if {$storage($var) > 1} {
        set storage($var) 1
        incr numFixes
        dputs "$numFixes) dungeon max > 1 ($var)"
    }

    # Check num champion type <= max num champions
    set cMax $storage($w,Total,Champions,max)
    foreach cType {
        Cleric Hero Monster Psionicist Regent Thief Wizard
    } {
        if {$storage($w,Limits,$cType,max) > $cMax} {
            set storage($w,Limits,$cType,max) $cMax
            incr numFixes
            dputs "$numFixes) champ type max > champ max ($var)"
        }
    }

    # Check minimum := max >= min >= 0
    foreach var [array names storage "$w,*,*,min"] {
        foreach {junk group id junk} [split $var ","] break
        set maxVar "$w,$group,$id,max"
        if {$storage($var) < 0} {
            set storage($var) 0
            incr numFixes
            dputs "$numFixes) min < 0 ($var)"
        }
        if {$storage($var) > $storage($maxVar)} {
            set storage($var) $storage($maxVar)
            incr numFixes
            dputs "$numFixes) min > max ($var)"
        }
    }

    # Check for mult < 1
    foreach var [array names storage "$w,*,*,mult"] {
        if {[regexp "^$w,Total" $var]} continue
        if {$storage($var) < 1} {
            set storage($var) 1
            incr numFixes
            dputs "$numFixes) mult < 1 ($var)"
        }
    }

    if {$numFixes != 0} {
        set s [expr {$numFixes == 1 ? " was" : "s were"}]
        tk_messageBox -parent $w -icon info -title "Sweet!" \
            -message "A total of $numFixes error$s automatically fixed."
    }

    if {$numErrors == 0 && $numFixes == 0} {
        tk_messageBox -parent $w -icon info -title "Congratulations!" \
            -message "No errors were found in this deck format!"
    }

    return
}

# FormatIt::CheckTextChange --
#
#   Checks each key press on the text widget to see if it is
#   one that changes the text. 
#
# Parameters:
#   w          : toplevel.
#   char       : From %A binding = ASCII char, {} if special char.
#
# Returns:
#   Nothing.
#
proc FormatIt::CheckTextChange {w char} {

    if {$char != ""} {
        SetChanged $w "true"
    }

    return
}
