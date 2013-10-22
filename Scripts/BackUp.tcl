# BackUp.tcl 20040816
#
# This file contains the procedures for backing up and restoring CF files.
#
# Copyright (c) 1999-2004 Dan Curtiss. All rights reserved.
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

namespace eval BackUp {

    variable backUp

    # Build a cross reference table for the various file types.
    foreach {type dirVar ext} {
        Deck      DeckIt,dir       .cfd
        Inventory Warehouse,invDir .cfi
        Trade     SwapShop,dir     .cft
        Combo     ComboMan,dir     .cfc
	FanSetCFG FanSetEditor,dir .cfg
	FanSetTCL FanSetEditor,dir .tcl
    } {
        lappend backUp(typeList) $type
        set backUp($type,dirVar) $dirVar
        set backUp($type,ext) $ext
        set backUp($ext,dirVar) $dirVar
    }

    set backUp(restoreDir) $Config::config(BackUp,dir)
    set backUp(backUpDir) $Config::config(BackUp,dir)

}

# BackUp::About --
#
#   The silly little about box for back up or restore.
#
# Parameters:
#   w          : Parent toplevel.
#   which      : Back Up or Restore.
#
# Returns:
#   Nothing.
#
proc BackUp::About {w which} {

    set message "CrossFire $which\n"
    append message "\nby Dan Curtiss"
    tk_messageBox -icon info -parent $w -message $message \
        -title "About $which"

    return
}

# BackUp::BackUp --
#
#   Creates the back up GUI.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc BackUp::BackUp {} {

    variable backUp

    set w .backUp

    if {[winfo exists $w]} {
        wm deiconify $w
        raise $w
        return
    }

    toplevel $w
    wm title $w "CrossFire BackUp"

    AddBackUpMenuBar $w

    frame $w.fileList -relief raised -borderwidth 1

    label $w.fileList.l ;# We set this after reading the list of files.

    # List of files to back up
    frame $w.fileList.list
    text $w.fileList.list.t -width 80 -height 20 -takefocus 0 \
        -background white -foreground black -state disabled -cursor {} \
        -yscrollcommand "CrossFire::SetScrollBar $w.fileList.list.sb"
    set backUp(backUpTextBox) $w.fileList.list.t
    scrollbar $w.fileList.list.sb -command "$w.fileList.list.t yview" \
        -takefocus 0
    grid $w.fileList.list.t -sticky nsew
    grid columnconfigure $w.fileList.list 0 -weight 1
    grid rowconfigure $w.fileList.list 0 -weight 1

    grid $w.fileList.l -sticky w -padx 5 -pady 3
    grid $w.fileList.list -sticky nsew -padx 5 -pady 3
    grid columnconfigure $w.fileList 0 -weight 1
    grid rowconfigure $w.fileList 1 -weight 1

    grid $w.fileList -sticky nsew

    # BackUp directory.
    frame $w.dir -relief raised -borderwidth 1
    frame $w.dir.d
    label $w.dir.d.l -text "Back Up To:"
    entry $w.dir.d.e -state disabled -relief groove \
        -textvariable BackUp::backUp(backUpDir)
    button $w.dir.d.b -text "Select..." -command "BackUp::SetBackUpDir"
    grid $w.dir.d.l -sticky w -padx 5
    grid $w.dir.d.e $w.dir.d.b -sticky nsew -padx 5
    grid columnconfigure $w.dir.d 0 -weight 1
    grid $w.dir.d -sticky nsew -pady 3
    grid columnconfigure $w.dir 0 -weight 1
    grid rowconfigure $w.dir 0 -weight 1

    grid $w.dir -sticky ew

    # BackUp Command buttons
    frame $w.buttons -relief raised -borderwidth 1
    button $w.buttons.backUp -text "Back Up" -command "BackUp::DoBackUp"
    button $w.buttons.close -text $CrossFire::close -command "destroy $w"
    grid $w.buttons.backUp $w.buttons.close -padx 5 -pady 5

    grid $w.buttons -sticky ew

    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 1

    set t $backUp(backUpTextBox)
    $t configure -state normal
    set count 0
    foreach fileName [BackUpFileList] {
        set backUp(backUpTag,$fileName) file[incr count]
        $t tag configure $backUp(backUpTag,$fileName) -foreground black
        $t insert end "$fileName\n" $backUp(backUpTag,$fileName)
    }
    $t configure -state disabled

    $w.fileList.l configure -text "Files to back up ($count):"

    bind $w <Key-Return> "$w.buttons.backUp invoke"
    bind $w <Key-Escape> "$w.buttons.close invoke"

    return
}

# BackUp::AddBackUpMenuBar --
#
#   Adds a menu bar to the back up window.
#
# Parameters:
#   w
#
# Returns:
#   Nothing.
#
proc BackUp::AddBackUpMenuBar {w} {

    menu $w.menubar

    $w.menubar add cascade \
        -label "Back Up" \
        -underline 0 \
        -menu $w.menubar.backUp

    menu $w.menubar.backUp -tearoff 0

    $w.menubar.backUp add command \
        -label "Back Up" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+B" \
        -command "BackUp::DoBackUp"

    $w.menubar.backUp add separator
    $w.menubar.backUp add command \
        -label "Configure..." \
        -underline 1 \
        -accelerator "$CrossFire::accelKey+O" \
        -command "Config::Create Back Up"

    $w.menubar.backUp add separator
    set exitLabel "Close"
    set exitAccelerator "Alt+F4"
    if {$CrossFire::platform == "macintosh"} {
        # This is a Macintosh, so make the exit
        # accelerator more "Mac-ish"
        set exitLabel "Quit"
        set exitAccelerator "Command+Q"
    }
    $w.menubar.backUp add command \
        -label $exitLabel \
        -underline 1 \
        -accelerator $exitAccelerator \
        -command "destroy $w"

    $w.menubar add cascade \
        -label "Help" \
        -underline 0 \
        -menu $w.menubar.help

    menu $w.menubar.help -tearoff 0

    $w.menubar.help add command \
        -label "Help..." \
        -underline 0 \
        -accelerator "F1" \
        -command "CrossFire::Help backup.html"
    $w.menubar.help add separator
    $w.menubar.help add command \
        -label "About Back Up..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+A" \
        -command "BackUp::About $w {Back Up}"
    $w config -menu $w.menubar

    bind $w <Key-F1> "CrossFire::Help backup.html"
    bind $w <Key-Help> "CrossFire::Help backup.html"

    if {$CrossFire::platform == "macintosh"} {
        bind $w <Command-q> "destroy $w"
    } else {
        bind $w <Meta-x> "destroy $w"
        bind $w <Alt-F4> "destroy $w; break"
    }

    bind $w <$CrossFire::accelBind-a> "BackUp::About $w {Back Up}"
    bind $w <$CrossFire::accelBind-b> "BackUp::DoBackUp"
    bind $w <$CrossFire::accelBind-o> "Config::Create Back Up"

    if {$CrossFire::platform == "windows"} {
        focus $w
    }

    return
}

# BackUp::SetBackUpDir --
#
#   Changes the back up directory.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc BackUp::SetBackUpDir {} {

    variable backUp

    set topLabel "Select Back Up Directory"
    set newDir [tk_chooseDirectory -title $topLabel -mustexist 1 \
                    -initialdir $backUp(backUpDir)]

    if {$newDir != ""} {
        set backUp(backUpDir) $newDir
    }

    return
}

# BackUp::BackUpFileList --
#
#   Generates a list of filenames to back up.  This is done by searching
#   in each of the default directories for CrossFire files.
#
# Parameters:
#   None.
#
# Returns:
#   List of files to backup.
#
proc BackUp::BackUpFileList {} {

    variable backUp

    set fileList {}

    foreach fileType $backUp(typeList) {
        set dir $Config::config($backUp($fileType,dirVar))
        set ext $backUp($fileType,ext)
        foreach fileName [glob -nocomplain [file join $dir "*$ext"]] {
            lappend fileList $fileName
        }
    }

    return $fileList
}

# BackUp::DoBackUp --
#
#   Copies all the back up files to the back up directory.  Reports any
#   errors that occur.  Successfully copied files' color is changed to blue
#   in the list of files.
#
# Parameters:
#   auto
#
# Returns:
#   Nothing.
#
proc BackUp::DoBackUp {{auto 0}} {

    variable backUp

    set qty 0

    foreach fileName [BackUpFileList] {

        catch {file copy -force $fileName $backUp(backUpDir)} err

        if {$err != ""} {
            tk_messageBox -icon error -title "Back Up Error" \
                -message "An Error Occured for\n$fileName:\n$err"
        } else {
            incr qty
            if {$auto == 0} {
                $backUp(backUpTextBox) tag configure \
                    $backUp(backUpTag,$fileName) -foreground blue
            }
        }
    }

    # Save a hard copy of configuration.
    Config::SaveOptions $backUp(backUpDir)

    if {$qty > 1} {
        set s s
    } else {
        set s ""
    }
    tk_messageBox -icon info -title "Back Up Complete" \
        -message "$qty file$s successfully backed up."

    Config::Set BackUp,lastBackUp \
	[clock format [clock seconds] -format "%m/%d/%Y"]

    return
}

# BackUp::CheckForAutoBackUp --
#
#   Checks to see if it is time to do an automatic back up.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc BackUp::CheckForAutoBackUp {} {

    if {$Config::config(BackUp,auto) == "No"} {
        return
    }

    set lastBackUp $Config::config(BackUp,lastBackUp)
    if {[catch {clock scan $lastBackUp}]} {
	# Previously, CrossFire had a bug here if the user had a date
	# format is use other than mm/dd/yyyy, so update those users.
	set lastBackUp \
	    [clock format [clock seconds] -format "%m/%d/%Y"]
	Config::Set BackUp,lastBackUp $lastBackUp
    }

    set numDays $Config::config(BackUp,autoDays)

    if {$numDays < 1} {
        set numDays 1
    }

    if {[clock scan "today 00:00:00"] < \
            [clock scan "$lastBackUp + $numDays days"]} {
        # Not time to do back up yet.
        return
    }

    set result yes
    if {$Config::config(BackUp,autoPrompt) == "Yes"} {
        set msg "It is time to back up your files!\nBack up now?"
        set result \
            [tk_messageBox -type yesno -icon question -default yes \
                 -message $msg -title "Auto Back Up"]
    }

    if {$result == "yes"} {
        DoBackUp 1
    }

    return
}

# BackUp::Restore --
#
#   Creates the restore GUI.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc BackUp::Restore {} {

    variable backUp

    set w .restore

    if {[winfo exists $w]} {
        wm deiconify $w
        raise $w
        return
    }

    toplevel $w
    wm title $w "CrossFire Restore"

    AddRestoreMenuBar $w

    frame $w.options -relief raised -borderwidth 1
    checkbutton $w.options.optcb -variable ::BackUp::backUp(restoreOptions) \
        -text "Restore Options Configuration"
    set backUp(restoreOptions) 0
    grid $w.options.optcb -sticky w -padx 5 -pady 3
    grid columnconfigure $w.options 0 -weight 1
    grid $w.options -sticky ew

    frame $w.fileList -relief raised -borderwidth 1

    label $w.fileList.l ;# We set this after reading the list of files.
    set backUp(restoreLabel) $w.fileList.l

    # List of files to restore
    frame $w.fileList.list
    text $w.fileList.list.t -width 80 -height 20 -takefocus 0 \
        -background white -foreground black -state disabled -cursor {} \
        -yscrollcommand "CrossFire::SetScrollBar $w.fileList.list.sb"
    set backUp(restoreTextBox) $w.fileList.list.t
    scrollbar $w.fileList.list.sb -command "$w.fileList.list.t yview" \
        -takefocus 0
    grid $w.fileList.list.t -sticky nsew
    grid columnconfigure $w.fileList.list 0 -weight 1
    grid rowconfigure $w.fileList.list 0 -weight 1

    grid $w.fileList.l -sticky w -padx 5 -pady 3
    grid $w.fileList.list -sticky nsew -padx 5 -pady 3
    grid columnconfigure $w.fileList 0 -weight 1
    grid rowconfigure $w.fileList 1 -weight 1

    grid $w.fileList -sticky nsew

    # BackUp directory.
    frame $w.dir -relief raised -borderwidth 1
    frame $w.dir.d
    label $w.dir.d.l -text "Restore From:"
    entry $w.dir.d.e -state disabled -relief groove \
        -textvariable BackUp::backUp(restoreDir)
    button $w.dir.d.b -text "Select..." -command "BackUp::SetRestoreDir"
    grid $w.dir.d.l -sticky w -padx 5
    grid $w.dir.d.e $w.dir.d.b -sticky nsew -padx 5
    grid columnconfigure $w.dir.d 0 -weight 1
    grid $w.dir.d -sticky nsew -pady 3
    grid columnconfigure $w.dir 0 -weight 1
    grid rowconfigure $w.dir 0 -weight 1
    grid $w.dir -sticky ew

    # BackUp Command buttons
    frame $w.buttons -relief raised -borderwidth 1
    button $w.buttons.restore -text "Restore" -command "BackUp::DoRestore"
    button $w.buttons.close -text $CrossFire::close -command "destroy $w"
    grid $w.buttons.restore $w.buttons.close -padx 5 -pady 5

    grid $w.buttons -sticky ew

    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 1

    ShowRestoreFiles

    bind $w <Key-Return> "$w.buttons.restore invoke"
    bind $w <Key-Escape> "$w.buttons.close invoke"

    return
}

# BackUp::AddRestoreMenuBar --
#
#   Adds a menu bar to the back up window.
#
# Parameters:
#   w
#
# Returns:
#   Nothing.
#
proc BackUp::AddRestoreMenuBar {w} {

    menu $w.menubar

    $w.menubar add cascade \
        -label "Restore" \
        -underline 0 \
        -menu $w.menubar.restore

    menu $w.menubar.restore -tearoff 0

    $w.menubar.restore add command \
        -label "Restore" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+R" \
        -command "BackUp::DoRestore"

    $w.menubar.restore add separator
    $w.menubar.restore add command \
        -label "Configure..." \
        -underline 1 \
        -accelerator "$CrossFire::accelKey+O" \
        -command "Config::Create Back Up"

    $w.menubar.restore add separator
    set exitLabel "Close"
    set exitAccelerator "Alt+F4"
    if {$CrossFire::platform == "macintosh"} {
        # This is a Macintosh, so make the exit
        # accelerator more "Mac-ish"
        set exitLabel "Quit"
        set exitAccelerator "Command+Q"
    }
    $w.menubar.restore add command \
        -label $exitLabel \
        -underline 1 \
        -accelerator $exitAccelerator \
        -command "destroy $w"

    $w.menubar add cascade \
        -label "Help" \
        -underline 0 \
        -menu $w.menubar.help

    menu $w.menubar.help -tearoff 0

    $w.menubar.help add command \
        -label "Help..." \
        -underline 0 \
        -accelerator "F1" \
        -command "CrossFire::Help restore.html"
    $w.menubar.help add separator
    $w.menubar.help add command \
        -label "About Restore..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+A" \
        -command "BackUp::About $w Restore"
    $w config -menu $w.menubar

    bind $w <Key-F1> "CrossFire::Help restore.html"
    bind $w <Key-Help> "CrossFire::Help restore.html"

    if {$CrossFire::platform == "macintosh"} {
        bind $w <Command-q> "destroy $w"
    } else {
        bind $w <Meta-x> "destroy $w"
        bind $w <Alt-F4> "destroy $w; break"
    }

    bind $w <$CrossFire::accelBind-a> "BackUp::About $w Restore"
    bind $w <$CrossFire::accelBind-r> "BackUp::DoRestore"
    bind $w <$CrossFire::accelBind-o> "Config::Create Back Up"

    if {$CrossFire::platform == "windows"} {
        focus $w
    }

    return
}

# BackUp::SetRestoreDir --
#
#   Sets the directory to restore from and updates the list of files.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc BackUp::SetRestoreDir {} {

    variable backUp

    set topLabel "Select Back Up Directory"
    set newDir [tk_chooseDirectory -title $topLabel -mustexist 1 \
                    -initialdir $backUp(restoreDir)]

    if {($newDir != "") && ($newDir != $backUp(restoreDir))} {
        set backUp(restoreDir) $newDir
        ShowRestoreFiles
    }

    return
}

# BackUp::RestoreFileList --
#
#   Returns a list of files to restore from the back up directory.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc BackUp::RestoreFileList {} {

    variable backUp

    set fileList {}
    foreach filePattern {*.cf* *.tcl} {
	set globPattern [file join $backUp(restoreDir) $filePattern]
	foreach fileName [glob -nocomplain $globPattern] {
	    # Exclude the options.cfg file (configuration backup)
	    # because it is handled specifically.
	    if {[file tail $fileName] != "options.cfg"} {
		lappend fileList $fileName
	    }
	}
    }

    return $fileList
}

# BackUp::ShowRestoreFiles --
#
#   Adds the list of files to restore to the text box and changes the
#   label to reflect the number of files to restore.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc BackUp::ShowRestoreFiles {} {

    variable backUp

    set t $backUp(restoreTextBox)
    $t configure -state normal
    $t delete 1.0 end
    set count 0
    foreach fileName [RestoreFileList] {
        set backUp(restoreTag,$fileName) file[incr count]
        SetRestoreFileColor $fileName black
        $t insert end "$fileName\n" $backUp(restoreTag,$fileName)
    }
    $t configure -state disabled

    $backUp(restoreLabel) configure -text "Files to restore ($count):"

    return
}

# BackUp::DoRestore --
#
#   Checks each file to see if it needs to be restored.  If so,
#   copies it and changes the color to blue.  Back up files that are
#   older than the current version will require permission from the user
#   to overwrite.  Those that are not are colored green.  Files of the
#   same date will not be copied and the color will be chaged to dark blue.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc BackUp::DoRestore {} {

    variable backUp

    set qty 0
    foreach fileName [RestoreFileList] {

        set ext [file extension $fileName]
        if {[info exists backUp($ext,dirVar)] == 0} {
            # A strange file has appeared in the back up directory.
            # Seems to have a CrossFire file extension, but is unknown.
            SetRestoreFileColor $fileName purple
            continue
        }

        set restoreDir $Config::config($backUp($ext,dirVar))
        set newFile [file join $restoreDir [file tail $fileName]]
        set backDate [file mtime $fileName]

        # The file to copy the back up to exists.  Check the file mod dates
        # to see if they are the same, or if back up is older than destination
        # ask user for permission to overwrite (can lose changes!)
        if {[file exists $newFile]} {
            set newDate [file mtime $newFile]
            if {$backDate == $newDate} {
                # No need to copy...dates match.
                incr qty
                SetRestoreFileColor $fileName purple
                continue
            } elseif {$newDate > $backDate} {
                # Destination newer than back up.
                set msg "The current file:\n\n$newFile\n\nis newer "
                append msg "than the back up file:\n\n$fileName\n\n"
                append msg "Do you want to replace it with the back up?"
                set response [tk_messageBox -icon question -default no \
                                  -message $msg -type yesno \
                                  -title "Replace File"]
                if {$response == "no"} {
                    # Change color to green to indicate back up needs to be
                    # for this file.
                    SetRestoreFileColor $fileName green
                    continue
                }
            }
        }

        catch {file copy -force $fileName $newFile} err

        if {$err != ""} {
            tk_messageBox -icon error -title "Restore Error" \
                -message "An Error Occured for\n$fileName:\n$err"
            SetRestoreFileColor $fileName red
        } else {
            incr qty
            SetRestoreFileColor $fileName blue
        }
    }

    # Restore options and save
    if {$backUp(restoreOptions) == 1} {
        Config::LoadOptions $backUp(restoreDir)
        SetRestoreFileColor [file join $backUp(restoreDir) "options.cfg"] blue
        Config::SaveOptions
    }

    if {$qty > 1} {
        set s s
    } else {
        set s ""
    }
    set msg "$qty file$s "
    if {$backUp(restoreOptions) == 1} {
        append msg "and options "
    }
    append msg "successfully restored."
    tk_messageBox -icon info -title "Restore Complete" \
        -message $msg

    return
}

# BackUp::SetRestoreFileColor --
#
#   Changes the color of a restore file.
#
# Parameters:
#   fileName   : Filename whose color needs to be changed.
#   color      : The color to change it to.
#
# Returns:
#   Nothing.
#
proc BackUp::SetRestoreFileColor {fileName color} {

    variable backUp

    $backUp(restoreTextBox) tag configure \
        $backUp(restoreTag,$fileName) -foreground $color

    return
}

