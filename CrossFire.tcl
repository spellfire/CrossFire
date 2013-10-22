#!/bin/sh
# the next line restarts using wish \
   exec wish "$0" "$@"

# CrossFire.tcl 20060227
#
# This file is the main startup file for CrossFire.  It handles the splash
# screen, creates the program selection toplevel, and loads in all the
# support files.
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

# Hide the unneeded root window.
wm withdraw .

# Gotta have Tcl/Tk 8.4 or higher.
if {$tcl_version < 8.4} {
    tk_dialog .msg "Error" "CrossFire requires Tcl/Tk 8.4 or higher." \
        error 0 "Doh!"
    exit
}

# Shift --
#
#   Loosely mimics perl's shift command...hence the clever name. :)
#
# Parameters:
#   None (reads argv)
#
# Returns:
#   The next arg or SHIFT_ERROR if no more args.
#
proc Shift {} {
    global argv
    if {[llength $argv] == 0} {
        set shift "SHIFT_ERROR"
    } else {
        set shift [lindex $argv 0]
        set argv [lrange $argv 1 end]
    }
    return $shift
}

set debug 0
set developer 0

# Process any command line options
# Currently we have:
#   -debug      : Enables printing of all proc calls
#   -dev        : Enables developer mode
#
while {([llength $argv] > 0) && ([regexp -- "^-" [lindex $argv 0]])} {
    set option [Shift]
    switch -- $option {
        "-debug" {
            set debug 1
        }
        "-dev" {
            set developer 1
        }
    }
}

# dputs --
#
#   Does a puts to the debug output window.
#
# Parameters:
#   Any.
#
# Returns:
#   Nothing.
#
proc dputs {msg args} {

    if {($::debug == 0) && ([lindex $args 0] != "force")} {
        return
    }

    set w .debug

    if {![winfo exists $w]} {
        # Setup a debug window
        toplevel $w
        wm title $w "CrossFire Debug"

        frame $w.text
        text $w.text.t -yscrollcommand "$w.text.sb set" -font {Courier 10}
        scrollbar $w.text.sb -command "$w.text.t yview"
        grid $w.text.t $w.text.sb -sticky nsew
        grid columnconfigure $w.text 0 -weight 1
        grid rowconfigure $w.text 0 -weight 1

        frame $w.buttons -relief raised -borderwidth 1
        button $w.buttons.clear -text "Clear" \
            -command "$w.text.t delete 1.0 end"
        grid $w.buttons.clear -pady 5

        grid $w.text -sticky nsew
        grid $w.buttons -sticky ew
        grid columnconfigure $w 0 -weight 1
        grid rowconfigure $w 0 -weight 1
    }

    $w.text.t insert end "$msg\n"
    $w.text.t see end
    update

    return
}

# The following is for debuging CrossFire.  It changes all the
# procs so that they print their name when they are executed.
if {$debug == 1} {
    rename proc _proc
    _proc proc {procName argList procBody} {
        set nameSpace [uplevel 1 namespace current]
        if {$nameSpace == "::"} {
            set fullName "$procName"
        } else {
            set fullName [string trimleft "${nameSpace}::$procName" ":"]
        }
        set arguments ""
        foreach arg $argList {
            append arguments "[lindex $arg 0]=\$[lindex $arg 0] "
        }

        if {$nameSpace != "::" || [regexp "::" $procName]} {
            set procBody "
dputs \"$fullName $arguments\"
$procBody"
        }

        eval "_proc $fullName \{$argList\} \{$procBody\}"
    }
}

# Check for the totally uber snack package!  w00t!!
if {[lsearch [package names] "snack"] != -1} {
    package require snack
    set snackPackage "Yes"
} else {
    set snackPackage "No"
}

# Make the highlight border the background color. This probably
# only makes a difference on a Linux/Unix machine.
option add *HighlightBackground [. cget -background]

# These are just some variables that are needed before doing
# just about anything else. Hence, they are here and not in
# Scripts/CommonV.tcl.
namespace eval CrossFire {

    # The CrossFire version number is the date of the build.
    # This date will correspond with the whats new
    # page on the CrossFire home page.
    variable crossFireVersion "24 Feb 2006 (Kalidnay)"

    # platform is the platform we are running on (windows, macintosh, unix)
    variable platform $tcl_platform(platform)

    if {$platform == "macintosh"} {
	# This is pre-OSX which is no longer supported
	tk_messageBox -title "Doh!" -icon info \
	    -message "I am sorry, but this computer is no longer supported."
	exit
    } elseif {($platform == "unix") && ($tcl_platform(os) == "Darwin")} {
        # Mac OSX reports that it is unix, but we need to behave differently
        # than unix, so change to mac.
        set platform "macintosh"
    }

    # Change to the CrossFire directory.
    set script [info script]
    if {$platform == "unix"} {
        # Unix/Linux Platform.  This works even if CrossFire is a link
        if {[file type $script] == "file"} {
            cd [file dirname $script]
        } else {
            cd [file dirname [file readlink $script]]
        }
    } else {
        # Windows or Mac
        cd [file dirname $script]
    }

    # homeDir is the base directory CrossFire is running from.
    variable homeDir [pwd]

    # Perform a quick check if installation was correct. If the files
    # are extracted without preserving the directory structure, we
    # will not be able to run.  This is a common problem!
    if {[file exists [file join $homeDir XFire.cfs]]} {
        set msg "It appears that CrossFire was extracted without preserving "
        append msg "directory structure.  Please remove the files in this "
        append msg "directory:\n$homeDir\nand extract properly."
        tk_messageBox -icon error -message $msg \
            -title "Unable to run CrossFire!"
        exit
    }

    # Make sure all the normally expected directories exist.
    set cfDirs {
        ChatLogs Combos DataBase Decks FanSets Graphics
	Help Inventory Reports Scripts Trades BackUp Formats
	Sounds Languages Games
    }
    foreach gSubDir {Icons XFire Cards} {
        lappend cfDirs [file join "Graphics" $gSubDir]
    }
    foreach subDir $cfDirs {
        set dirName [file join $homeDir $subDir]
        if {![file exists $dirName]} {
            file mkdir $dirName
        }
    }

    # Do some Mac only things.
    if {$platform == "macintosh"} {

        # This makes all Button-3 bindings Ctrl-Button-1 on Mac
        bind all <Control-ButtonPress-1> {
            event generate %W <ButtonPress-3> \
                -x %x -y %y -rootx %X -rooty %Y -button 3 -time %t
        }

        # These options change the text boxes so that they have a border.
        # (Makes them "visible".)
        option add *Text.relief solid
        option add *Text.borderWidth 1
    }
}

# Create a safe interp for loading decks, inventories, chat cmds, etc
interp create -safe safeInterp
safeInterp eval {
    namespace eval CrossFire {}
}

# Load the most needed parts.
foreach script {
    CommonV.tcl Common.tcl CommonUI.tcl Registry.tcl Config.tcl
    Server.tcl MultiLang.tcl
} {
    source [file join $CrossFire::homeDir "Scripts" $script]
}

# Load the user's preferences
Config::LoadOptions

# Check the file server status
Server::Start

# Initialize language files
ML::Initialize

# Load in all the support scripts.
foreach script {
    Balloon.tcl ConfigUI.tcl ViewCard.tcl
    SSearch.tcl USearch.tcl
    MainGUI.tcl FontSel.tcl Print.tcl EditCard.tcl
    BackUp.tcl PanedWin.tcl TipOfDay.tcl DragDrop.tcl
    Play.tcl PlayerGUI.tcl PlayGUI.tcl PlayNote.tcl PlayIO.tcl
    Chat.tcl ChatLog.tcl ChatPro.tcl ChatUtil.tcl
    Editor.tcl EditorIO.tcl EditorU.tcl
    SwapShop.tcl SwapIO.tcl SwapUtil.tcl
    Combo.tcl ComboIO.tcl ComboU.tcl ComboVue.tcl
    FileMain.tcl FileIO.tcl FileUtil.tcl
    Format.tcl FormatIO.tcl FormatU.tcl
} {
    source [file join $CrossFire::homeDir "Scripts" $script]
}

# SplashScreen --
#
#   Displays a graphic centered on the screen for 2.5 seconds.
#
# Parameters:
#   w          : Toplevel name to display image in.
#   imageFile  : Full filename of the graphic.
#
# Returns:
#   Nothing.
#
proc SplashScreen {w imageFile} {
    toplevel $w -borderwidth 3 -relief raised
    wm withdraw $w
    wm overrideredirect $w 1
    image create photo splash -file $imageFile
    label $w.l -image splash -borderwidth 1 -relief sunken -background black
    pack $w.l
    update
    CrossFire::PlaceWindow $w center
    wm deiconify $w
    update

    # View splash screen for 2.5 seconds.
    after 2500 "destroy $w; image delete splash"

    return
}

if {$Config::config(CrossFire,showSplashScreen) == "Yes" && $debug == 0} {
    set splashFile [file join $CrossFire::homeDir "Graphics" "xfLogo.gif"]
    if {[file exists $splashFile]} {
        SplashScreen .splash $splashFile
    }
}

# Initialize fan sets.  Check the card sets lists that have access to
# the fan sets to see if any of them have been removed.
CrossFire::InitializeFanSets
Config::CheckFanCardSets

# Initialize the deck formats
CrossFire::InitializeDeckFormats

# Do some clean-up of old stuff
set fileList {}
set deckDir [file join $CrossFire::homeDir "Decks"]
foreach fName [glob -nocomplain [file join $deckDir "1st Edition*.cfd"]] {
    lappend fileList $fName
}
lappend fileList [file join $deckDir "gencon.cfd"]
lappend fileList \
    [file join $CrossFire::homeDir "Graphics" "Icons" "copyright.gif"]
foreach fileName $fileList {
    if {[file exists $fileName]} {
	catch {file delete $fileName}
    }
}

# Check for img package!  Woot!!
if {[lsearch [package names] "Img"] != -1} {
    package require Img
    set imgPackage "Yes"
} else {
    set imgPackage "No"
}

# Load the http package
package require http

# Load the tcom package on windows
set useWord 0
if {$CrossFire::platform == "windows"} {
    package require tcom

#     # Check for MS Word
#     if {[catch {set tWord [::tcom::ref createobj "Word.Application"]}]} {
#         dputs "Word not available"
#     } else {
#         $tWord Quit [expr 0]
#         set useWord 1
#     }
}

CrossFire::Create
BackUp::CheckForAutoBackUp
Tip::InitTips [file join $CrossFire::homeDir "Help" "CrossFire.totd"]
Registry::AssociateFiles
CrossFire::PlaySound StartUp

# OK, we are all done with the CrossFire startup.  Now, load any
# CrossFire files that may have been specified on the command line.
foreach fileName $argv {
    CrossFire::AutoLoad $fileName
}
