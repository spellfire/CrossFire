# FormatIO.tcl 20050824
#
# This file contains all the procedures for reading/wrinting deck format files.
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

# FormatIt::UnLockFile --
#
#   Unlocks the current format file, if there is one.  Calls the
#   CrossFire::UnlockFile procedure to do the unlocking.
#
# Parameters:
#   w          : FormatIt toplevel.
#
# Returns:
#   Nothing.
#
proc FormatIt::UnLockFile {w} {

    variable storage

    if {$storage($w,fileName) != ""} {
        CrossFire::UnlockFile $w $storage($w,fileName)
    }

    return
}

# FormatIt::Open --
#
#   Reads a deck format file.
#
# Parameters:
#   w          : Toplevel
#   file       : Name of the file to open or "" to get a filename.
#   agrs       : Not sure why this is here.
#
# Returns:
#   0 if successful, -1 elsewise.
#
proc FormatIt::Open {w file args} {

    variable storage

    if {[CheckForSave $w] == -1} {
        return 0
    }

    if {$file == ""} {
        set fileName [tk_getOpenFile \
                          -initialdir $storage($w,formatDir) \
                          -title "Open CrossFire Deck Format" \
                          -defaultextension $CrossFire::extension(format) \
                          -filetypes $CrossFire::formatFileTypes]
    } else {
        set fileName $file
    }

    if {($fileName == "")} {
        return -1
    }
    if {($fileName == $storage($w,fileName))} {
        set storage($w,fileName) ""
    }

    set lockResult [CrossFire::LockFile $w $fileName $args]
    if {$lockResult == 1} {

        set fid [open $fileName "r"]
        set formatCommand [read $fid]
        close $fid

        # Just in case this is an older deck format
        CrossFire::SetSafeVar tempDeckFormatAllowed {}
        CrossFire::SetSafeVar tempDeckFormatInfo {}

        catch {
            safeInterp eval $formatCommand
        } err

        set storage($w,name) [CrossFire::GetSafeVar tempDeckFormatTitle]
        set storage($w,fullName) $storage($w,name)
        set storage($w,bannedList) [CrossFire::GetSafeVar tempDeckFormatBanned]
        set storage($w,allowedList) \
            [CrossFire::GetSafeVar tempDeckFormatAllowed]
        set information [CrossFire::GetSafeVar tempDeckFormatInfo]

        set storage($w,fileName) $fileName

        foreach {which min max} [CrossFire::GetSafeVar tempDeckFormatTotal] {
            set storage($w,Total,$which,min) $min
            set storage($w,Total,$which,max) $max
            set storage($w,Total,$which,mult) 0
        }

        foreach {type varName} {
            Limits tempDeckFormatLimits
            Rarity tempDeckFormatRarity
            World  tempDeckFormatWorld
            Set    tempDeckFormatSet
            Digit  tempDeckFormatDigit
        } {
            foreach {which min max mult} [CrossFire::GetSafeVar $varName] {
                set storage($w,$type,$which,min) $min
                set storage($w,$type,$which,max) $max
                set storage($w,$type,$which,mult) $mult
            }
        }

        UpdateBannedAllowed $w banned
        UpdateBannedAllowed $w allowed

        $storage($w,infoTB) delete 1.0 end
        $storage($w,infoTB) insert end $information

        SetChanged $w "false"
        Config::RecentFile "Format" $fileName
    }

    return $lockResult
}

# FormatIt::SaveAs --
#
#   Gets a new filename to save the current format as.  Calls Save.
#
# Parameters:
#   w          : As usual, the toplevel!
#
# Returns:
#   Nothing.
#
proc FormatIt::SaveAs {w} {

    variable storage

    set newFileName \
        [tk_getSaveFile -initialdir $storage($w,formatDir) \
             -defaultextension $CrossFire::extension(format) \
             -title "Save Deck Format As" \
             -filetypes $CrossFire::formatFileTypes]

    if {($newFileName != "") && ([CrossFire::LockFile $w $newFileName] == 1)} {

        if {$storage($w,fileName) != ""} {
            CrossFire::UnlockFile $w $storage($w,fileName)
        }

        set holdFileName $storage($w,fileName)
        set storage($w,fileName) $newFileName
        if {[Save $w] == -1} {
            set storage($w,fileName) $holdFileName
            if {$storage($w,fileName) != ""} {
                CrossFire::UnlockFile $w $storage($w,fileName)
            }
        }
    }

    return
}

# FormatIt::Save --
#
#   Saves a deck format file.
#
# Parameters:
#   w         : Toplevel
#
# Returns:
#   0 for success, -1 for failure
#
proc FormatIt::Save {w} {

    variable storage

    set fileName $storage($w,fileName)

    if {$fileName == ""} {
        set fileName \
            [tk_getSaveFile -initialdir $storage($w,formatDir) \
                 -title "Save Deck Format As" \
                 -defaultextension $CrossFire::extension(format) \
                 -filetypes $CrossFire::formatFileTypes]
    }

    if {($fileName == "") || ([CrossFire::LockFile $w $fileName] == 0)} {
        return -1
    }

    set storage($w,fileName) $fileName
    set fid [open $storage($w,fileName) "w"]

    puts $fid "set tempDeckFormatTitle \{$storage($w,name)\}"

    set formatInfo [string trim [$storage($w,infoTB) get 1.0 end]]
    puts $fid "set tempDeckFormatInfo \{$formatInfo\}"

    foreach {gName width} {
        Total 10 Limits 16 Rarity 2
        World 3 Set 3 Digit 1
    } {
        switch $gName {
            "Total" {
                set idList {All Avatars Chase Champions Levels}
            }
            "Limits" {
                set idList {}
                foreach id $CrossFire::cardTypeIDList {
                    if {($id > 0) && ($id < 99)} {
                        lappend idList $id
                    }
                }
            }
            "Set" {
                set idList "[CrossFire::CardSetIDList real] FAN"
            }
            "World" {
                set idList "$CrossFire::worldXRef(IDList,Base) FAN"
            }
            "Rarity" {
                set idList $CrossFire::cardFreqIDList
            }
            "Digit" {
                set idList $CrossFire::cardDigitList
            }
        }
        puts $fid "set tempDeckFormat$gName \{"
        foreach id $idList {
            set vid $id
            if {$gName == "Limits"} {
                set vid $CrossFire::cardTypeXRef($id,name)
            }
            set fvid [list $vid]
            if {$gName == "Total"} {
                puts $fid [format "    %-${width}s %3d %3d" \
                               $fvid $storage($w,$gName,$vid,min) \
                               $storage($w,$gName,$vid,max)]
            } else {
                puts $fid [format "    %-${width}s %3d %3d %3d" \
                               $fvid $storage($w,$gName,$vid,min) \
                               $storage($w,$gName,$vid,max) \
                               $storage($w,$gName,$vid,mult)]
            }
        }
        puts $fid "\}"
    }

    foreach {group name} {banned Banned allowed Allowed} {
        puts $fid "set tempDeckFormat$name \{"
        set count 0
        puts -nonewline $fid "    "
        foreach cardID [lsort $storage($w,${group}List)] {
            puts -nonewline $fid "$cardID "
            incr count
            if {$count == 10} {
                set count 0
                puts -nonewline $fid "\n    "
            }
        }
        puts $fid "\n\}"
    }

    close $fid

    # Register with CrossFire
    set dirSplit [file split $storage($w,fileName)]
    set fIndex [expr [lsearch $dirSplit "Formats"] + 1]
    set groupName [join [lrange $dirSplit $fIndex end-1] ","]
    CrossFire::ReadDeckFormat $groupName $storage($w,fileName)

    Config::RecentFile "Format" $fileName
    SetChanged $w "false"
    focus $w

    return 0
}

# FormatIt::CheckForSave --
#
#   Checks if the format needs to be saved.  If it does, alerts
#   user and asks if it should be saved.
#
# Parameters:
#   w          : toplevel
#
# Returns:
#    0 if no need to save.
#   -1 if needed to save, but canceled.
#
proc FormatIt::CheckForSave {w} {

    variable storage

    set result 0
    if {$storage($w,change) == "true"} {
        wm deiconify $w
        raise $w
        set answer \
            [tk_messageBox -title "Format Maker Warning" -icon question \
                 -message "Format not saved.  Would you like to save it?" \
                 -type yesnocancel -parent $w -default yes]

        switch -- $answer {
            "yes" {
                set result [Save $w]
            }
            "cancel" {
                set result -1
            }
        }
    }

    return $result
}
