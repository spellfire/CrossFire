# ComboIO.tcl 20060104
#
# This file contains all the I/O procedures for the combo manager.
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

# Combo::CheckForSave --
#
#   Checks if the combo needs to be saved.  If it does, alerts
#   user and asks if it should be saved.
#
# Parameters:
#   w          : Combo toplevel of combo.
#
# Returns:
#    0 if no need to save.
#   -1 if needed to save, but canceled.
#
proc Combo::CheckForSave {w} {

    variable storage

    set result 0
    if {$storage($w,change) == "true"} {
        wm deiconify $w
        raise $w
        set answer \
            [tk_messageBox -title "ComboMan Warning" -icon question \
                 -message "Combo not saved.  Would you like to save it?" \
                 -type yesnocancel -parent $w -default yes]

        switch -- $answer {
            "yes" {
                set result [SaveCombo $w]
            }
            "cancel" {
                set result -1
            }
        }
    }

    return $result
}

# Combo::UnLockFile --
#
#   Unlocks the current combo file, if there is one.  Calls the
#   CrossFire::UnlockFile procedure to do the unlocking.
#
# Parameters:
#   w          : Combo toplevel.
#
# Returns:
#   Nothing.
#
proc Combo::UnLockFile {w} {

    variable storage

    if {$storage($w,fileName) != ""} {
        # Done with the previous combo, unlock it.
        CrossFire::UnlockFile $w $storage($w,fileName)
    }

    return
}

# Combo::OpenCombo --
#
#   Loads a combo from a file.  Checks if current
#   combo needs to be saved first.
#
# Parameters:
#   w          : Combo toplevel.
#   file       : File name to automatically load.
#   args       : Optional nocomplain.
#
# Returns:
#   1 if successful, 0 if not.
#
proc Combo::OpenCombo {w file args} {

    variable storage

    if {[CheckForSave $w] == -1} {
        return 0
    }

    if {$file == ""} {
        set fileName [tk_getOpenFile -initialdir $storage($w,comboDir) \
                          -title "Open CrossFire Combo" \
                          -defaultextension $CrossFire::extension(combo) \
                          -filetypes $CrossFire::comboFileTypes]
    } else {
        set fileName $file
    }

    if {($fileName == $storage($w,fileName)) || ($fileName == "")} {
        return 0
    }

    set lockResult [CrossFire::LockFile $w $fileName $args]
    if {($fileName != "") && ($lockResult == 1)} {

        if {[ReadCombo $w $fileName] == 0} {
            tk_messageBox -title "Error Opening Combo" -icon error \
                -parent $w -message "$fileName is not a valid combo!"
            CrossFire::UnlockFile $w $fileName
            return
        }

        New $w

        set storage($w,comboDir) [file dirname $fileName]
        set storage($w,fileName) $fileName

        foreach var {
            authorName authorEmail comboTitle comboText
        } {
            set storage($w,$var) [GetComboInfo $w $var]
        }

        $storage($w,comboTextBox) insert end $storage($w,comboText)

        foreach card [GetComboInfo $w combo] {
            set card [eval CrossFire::GetCard $card]
            if {$card != ""} {
                AddCardToCombo $w $card
            }
        }

        SetChanged $w "false"
        DisplayCombo $w 0
        Config::RecentFile "ComboMan" $fileName
    }

    return $lockResult
}

# Combo::SaveCombo --
#
#   Saves a combo in CrossFire Format.
#
# Parameters:
#   w          : Combo toplevel path name of combo.
#
# Returns:
#   0 if saved, -1 if canceled.
#
proc Combo::SaveCombo {w} {

    variable storage

    set fileName $storage($w,fileName)

    if {$fileName == ""} {
        set fileName \
            [tk_getSaveFile -initialdir $storage($w,comboDir) \
                 -title "Save CrossFire Combo As" \
                 -defaultextension $CrossFire::extension(combo) \
                 -filetypes $CrossFire::comboFileTypes]
    }

    if {($fileName == "") || ([CrossFire::LockFile $w $fileName] == 0)} {
        return -1
    }

    set storage($w,comboDir) [file dirname $fileName]

    if {$storage($w,comboTitle) == ""} {
        set storage($w,comboTitle) [file tail $fileName]
    }

    set comboText \
        [string trim [$storage($w,comboTextBox) get 1.0 end] "\n"]
    SetComboInfo $w comboText $comboText
    foreach var {
        authorName authorEmail comboTitle combo
    } {
        SetComboInfo $w $var $storage($w,$var)
    }

    set result 0
    if {[WriteCombo $w $fileName] == 1} {
        set storage($w,fileName) $fileName
        Config::RecentFile "ComboMan" $fileName
        SetChanged $w "false"
    } else {
        set result -1
    }

    return $result
}

# Combo::SaveComboAs --
#
#   Implements a save as feature.
#
# Paramters:
#   w         : Combo toplevel path name for combo.
#
# Returns:
#   Nothing.
#
proc Combo::SaveComboAs {w} {

    variable storage

    set newFileName \
        [tk_getSaveFile -initialdir $storage($w,comboDir) \
             -defaultextension $CrossFire::extension(combo) \
             -title "Save CrossFire Combo As" \
             -filetypes $CrossFire::comboFileTypes]

    if {($newFileName != "") && ([CrossFire::LockFile $w $newFileName] == 1)} {

        set holdFileName $storage($w,fileName)
        set storage($w,fileName) $newFileName
        if {[SaveCombo $w] == -1} {
            set storage($w,fileName) $holdFileName
            if {$storage($w,fileName) != ""} {
                CrossFire::UnlockFile $w $storage($w,fileName)
            }
        }
    }

    return
}

# Combo::PrintCombo --
#
#   First checks if there is a combo.  First, asks users
#   what form of print they want (plain text, RTF document, etc.)
#
# Parameters:
#   w          : Combo toplevel.
#
# Returns:
#   Nothing.
#
proc Combo::PrintCombo {w} {

    variable storage

    if {$storage($w,combo) == {}} {
        tk_messageBox -title "Error Printing Combo" -icon info \
            -message "No cards in combo!" -parent $w
        return
    }

    if {[Print::GetExportFile $w $storage($w,fileName)] == "cancel"} {
        return
    }

    Print $w

    return
}

# Combo::Print --
#
#   Prints a CrossFire combo.  On Unix, it uses the lpr command and
#   on Windows or Macintosh, it creates an RTF file that can be
#   printed from Word, et al.
#
# Parameters:
#   w          : Combo toplevel path name.
#
# Returns:
#   Nothing.
#
proc Combo::Print {w} {

    variable storage

    $w configure -cursor watch
    update

    set comboTitle $storage($w,comboTitle)

    # File heading
    Print::Head $w $comboTitle

    # Combo title
    Print::Title $w $comboTitle

    # Author's name and email
    Print::Author $w $storage($w,authorName)
    Print::Email $w $storage($w,authorEmail)

    Print::Separator $w

    # Card list heading
    Print::Heading $w "Cards Used:"

    # Print the cards in sorted order.
    foreach card [lsort $storage($w,combo)] {
        if {$Config::config(ComboMan,printCardText) == "Yes"} {
            set printText 1
        } else {
            set printText 0
        }
        Print::Card $w $card -text $printText
    }

    # Text on how to make the combo work.
    set comboText [GetComboText $w]
    Print::Heading $w "How the Combo Works:"
    Print::Notes $w [GetComboText $w]

    # File tail
    Print::Tail $w

    Print::Print $w

    $w configure -cursor {}
    return
}

# A Combo has the following infomation stored:
#
#   authorName      - Author's name.
#   authorEmail     - Author's email address.
#   comboTitle      - Text title of the combo.
#   combo           - List of {setID cardNum}
#   comboText       - Text describing how the combo works.

# Combo::ReadCombo --
#
#   A proc callable from any part of CrossFire to properly read a combo.
#   Call Combo::GetComboInfo to get the combo information.
#
# Parameters:
#   w          : Toplevel calling this proc.
#   fileName   : Combo to open.
#
# Returns:
#   1 if successfully read, or 0 if not.
#
proc Combo::ReadCombo {w fileName} {

    variable comboStorage

    # Set up dummy contents in case any var is missing or damaged.
    CrossFire::SetSafeVar tempAuthorName \
        $Config::config(CrossFire,authorName)
    CrossFire::SetSafeVar tempAuthorEmail \
        $Config::config(CrossFire,authorEmail)
    CrossFire::SetSafeVar tempComboTitle ""
    CrossFire::SetSafeVar tempComboText ""
    CrossFire::SetSafeVar tempCombo ""

    if {[file readable $fileName] == 0} {
        return 0
    }

    set fid [open $fileName "r"]
    set comboCommand [read $fid]
    close $fid

    # Eval the combo in the safe interpreter
    catch {
        safeInterp eval $comboCommand
    }

    set comboStorage($w,authorName) [CrossFire::GetSafeVar tempAuthorName]
    set comboStorage($w,authorEmail) [CrossFire::GetSafeVar tempAuthorEmail]
    set comboStorage($w,comboTitle) [CrossFire::GetSafeVar tempComboTitle]
    set comboStorage($w,comboText) [CrossFire::GetSafeVar tempComboText]
    set comboStorage($w,combo) {}
    foreach card [CrossFire::GetSafeVar tempCombo] {
        lappend comboStorage($w,combo) [lrange $card 0 1]
    }

    return 1
}

# Combo::GetComboInfo --
#
#   Called after ReadCombo has been called this returns one of the
#   combo datums.
#
# Parameters:
#   w          : Toplevel.
#   var        : Which of the datums to get.
#
# Returns:
#   The info if it exists.
#
proc Combo::GetComboInfo {w var} {

    variable comboStorage

    if {[info exists comboStorage($w,$var)]} {
        set info $comboStorage($w,$var)
    } else {
        dputs "Bogus: Tried to read combo info $w,$var"
        set info ""
    }

    return $info
}

# Combo::SetComboInfo --
#
#   Called after ReadCombo has been called this sets one of the combo datums.
#
# Parameters:
#   w          : Toplevel.
#   var        : Which of the datums to get.
#   data       : Data to set var to.
#
# Returns:
#   Nothing.
#
proc Combo::SetComboInfo {w var data} {

    variable comboStorage

    set comboStorage($w,$var) $data

    return
}

# Combo::WriteCombo --
#
#   Writes out a combo.
#
# Parameters:
#   w          : Toplevel.
#   fileName   : Filename to save to.
#
# Returns:
#   1 if successfully written, 0 otherwise.
#
proc Combo::WriteCombo {w fileName} {

    variable comboStorage

    set fileID 0
    catch {
        set fileID [open $fileName "w"]
    } err
    if {$err != $fileID} {
        tk_messageBox -title "Error Saving Combo"\
            -message "ERROR: '$err'" -icon error
        return 0
    }

    puts $fileID "set tempAuthorName \{$comboStorage($w,authorName)\}"
    puts $fileID "set tempAuthorEmail \{$comboStorage($w,authorEmail)\}"
    puts $fileID "set tempComboTitle \{$comboStorage($w,comboTitle)\}"
    puts $fileID "set tempComboText \{$comboStorage($w,comboText)\}"

    puts -nonewline $fileID "set tempCombo \{\n  "
    set lineCount 0
    foreach card $comboStorage($w,combo) {
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
        file attributes $fileName -type $CrossFire::macCode(combo) \
            -creator $CrossFire::macCode(creator)
    }

    return 1
}

