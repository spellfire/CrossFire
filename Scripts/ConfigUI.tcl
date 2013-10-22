# ConfigUI.tcl 20060106
#
# This file contains all the routines for changing and saving options
# for all the programs of CrossFire.
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

# Config::Create --
#
#   Create the toplevel used to change the default behavior
#   of CrossFire.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::Create {args} {

    variable config
    variable configW

    set w .config
    set configW(top) $w

    if {[winfo exists $w]} {
        wm deiconify $w
        raise $w
    } else {

        toplevel $w
        wm title $w "Configure CrossFire"
        wm withdraw $w

        AddMenuBar $w

        bind $w <Key-Escape> "destroy $w"
        bind $w <Key-Return> "Config::SaveOptions"

        # List of all the processes
        frame $w.processSel -relief raised -borderwidth 1
        frame $w.processSel.list
        listbox $w.processSel.list.lb -selectmode single -width 16 \
            -height 1 -background white -foreground black \
            -selectbackground blue -selectforeground white \
            -selectborderwidth 0 -takefocus 0 -exportselection 0 \
            -yscrollcommand "CrossFire::SetScrollBar $w.processSel.list.sb"
        scrollbar $w.processSel.list.sb -takefocus 0 \
            -command "$w.processSel.list.lb yview"
        grid $w.processSel.list.lb -sticky nsew
        grid columnconfigure $w.processSel.list 0 -weight 1
        grid rowconfigure $w.processSel.list 0 -weight 1
        grid $w.processSel.list -padx 5 -pady 3 -sticky nsew
        grid columnconfigure $w.processSel 0 -weight 1
        grid rowconfigure $w.processSel 0 -weight 1

        set lb $w.processSel.list.lb
        set configW(processSelBox) $lb
        foreach {process x x x} $configW(processList) {
            $lb insert end $process
            set configW(processIndex,$process) [expr [$lb index end] - 1]
        }
        bind $lb <ButtonRelease-1> "+Config::ChangeProcess"

	frame $w.default -relief raised -borderwidth 1
	button $w.default.default -text "Default" \
	    -command Config::RestoreDefaults
	grid $w.default.default -pady 3

        # Frame for the process's options
        set configW(optFrame) [frame $w.optionView]
	foreach {name x x key} $configW(processList) {
	    set dummy [Create${key}]
	}
	# This is needed as a placeholder
        grid $dummy -sticky nsew
        grid columnconfigure $w.optionView 0 -weight 1
        grid rowconfigure $w.optionView 0 -weight 1

        # Grid the whole screen
        grid $w.processSel -row 0 -column 0 -sticky nsew
	grid $w.default    -row 1 -column 0 -sticky nsew
        grid $w.optionView -row 0 -column 1 -sticky nsew -rowspan 2
        grid columnconfigure $w 1 -weight 1
        grid rowconfigure $w 0 -weight 1

        # Draw the window with the the biggest options window
        # and then lock the size of it with the propagate command.
        ChangeProcess Chat
        update
        grid propagate $w 0
        wm deiconify $w

        if {$CrossFire::platform == "windows"} {
            focus $w
        }
    }

    eval ChangeProcess "$args"

    return
}

# Config::AddMenuBar --
#
#   Adds a menu bar to the configure window.
#
# Parameters:
#   w          : Configure toplevel
#
# Returns:
#   Nothing.
#
proc Config::AddMenuBar {w} {

    variable configW

    menu $w.menubar

    $w.menubar add cascade \
        -label "Configure" \
        -underline 0 \
        -menu $w.menubar.configure

    menu $w.menubar.configure -tearoff 0

    $w.menubar.configure add command \
        -label "Save" \
        -command "Config::SaveOptions"
    $w.menubar.configure add separator
    foreach {process hotKey index x} $configW(processList) {
        $w.menubar.configure add command \
            -label $process \
            -command "Config::ChangeProcess $process" \
            -underline $index \
            -accelerator "$CrossFire::accelKey+$hotKey"
        bind $w <$CrossFire::accelBind-[string tolower $hotKey]> \
            "Config::ChangeProcess $process"
    }

    $w.menubar.configure add separator
    set exitLabel "Close"
    set exitAccelerator "Alt+F4"
    if {$CrossFire::platform == "macintosh"} {
        # This is a Macintosh, so make the exit
        # accelerator more "Mac-ish"
        set exitLabel "Quit"
        set exitAccelerator "Command+Q"
    }
    $w.menubar.configure add command \
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
        -command "CrossFire::Help config.html"
    $w.menubar.help add separator
    $w.menubar.help add command \
        -label "About Configure..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+A" \
        -command "Config::About $w"
    $w config -menu $w.menubar

    bind $w <Key-F1> "CrossFire::Help config.html"
    bind $w <Key-Help> "CrossFire::Help config.html"

    if {$CrossFire::platform == "macintosh"} {
        bind $w <Command-q> "destroy $w"
    } else {
        bind $w <Meta-x> "destroy $w"
        bind $w <Alt-F4> "destroy $w; break"
    }

    bind $w <$CrossFire::accelBind-s> "Config::SaveOptions"
    bind $w <$CrossFire::accelBind-a> "Config::About $w"

    if {$CrossFire::platform == "windows"} {
        focus $w
    }

    return
}

# Config::RestoreDefaults --
#
#   Restores settings to default values for a process.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::RestoreDefaults {} {

    variable config
    variable configW
    variable configDef

    set which $configW(process)
    set response \
	[tk_messageBox -icon warning -parent $configW(top) \
	     -title "Restore $which Default Settings" -type yesno \
	     -message "Are you sure you want to restore the default settings?"]

    if {$response == "yes"} {

	foreach {name x x key} $configW(processList) {
	    if {$which == $name} {
		set groupKey $key
	    }
	}

	foreach key [array names configDef "$groupKey,*"] {
	    set config($key) $configDef($key)
	}

	# Destroy the frame of options and recreate to update all settings
	set w $configW(optFrame).opt$groupKey
	destroy $w
	Create$groupKey
	grid $w -sticky nsew -row 0 -column 0

	# Redraw the Launcher window if necessary
	if {$groupKey == "Launcher"} {
	    CrossFire::Create
	}
    }

    return
}

# Config::SelectDirectory --
#
#   Changes a default directory.
#
# Parameters:
#   dirVar     : Config's variable for the directory.
#   args       : Optional label for the toplevel.
#
# Returns:
#   Nothing.
#
proc Config::SelectDirectory {dirVar args} {

    variable config

    if {[file isdirectory $config($dirVar)]} {
        set curDir $config($dirVar)
    } else {
        # Somehow got a bogus directory!
        set curDir $CrossFire::homeDir
    }

    if {$args != ""} {
        set topLabel "Select $args Directory"
    } else {
        set topLabel "Select Directory"
    }

    set newDir [tk_chooseDirectory -title $topLabel -mustexist 1 \
                    -initialdir $curDir]

    if {$newDir != ""} {
        set config($dirVar) $newDir
    }

    return
}

# Config::SelectFile --
#
#   Changes a default file.
#
# Parameters:
#   fileVar    : Config's variable for the file.
#
# Returns:
#   Nothing.
#
proc Config::SelectFile {fileVar type} {

    variable config
    variable configW

    if {$type == "inv"} {
        set ftypes $CrossFire::invFileTypes
        set idir [file dirname $config($fileVar)]
    } elseif {$type == "log"} {
        set ftypes $CrossFire::logFileTypes
	if {$config($fileVar) == ""} {
	    set idir $config(Chat,logDir)
	} else {
	    set idir [file dirname $config($fileVar)]
	}
    } elseif {$type == "action"} {
        set ftypes $CrossFire::actionFileTypes
        set idir [file dirname $config($fileVar)]
    } elseif {$type == "all"} {
        set ftypes {{{All Files} *}}
        set idir [file dirname $config($fileVar)]
    } elseif {$type == "audio"} {
        if {$::snackPackage == "Yes"} {
            set ftypes {
                {{All Supported Audio Files} {*.aiff *.au *.mp3 *.ogg *.wav}}
                {{All Files} *}
            }
        } else {
            if {$CrossFire::platform == "windows"} {
                set ftypes {{{Windows Audio Files} *.wav}}
            } elseif {$CrossFire::platform == "unix"} {
                set ftypes {{{Audio Files} *.au}}
            } else {
                set ftypes {{{All Files} *}}
            }
        }
        if {$configW($fileVar) == "None"} {
            set idir $configW(Sound,previousDir)
        } else {
            set idir [file dirname $configW($fileVar)]
        }
    } else {
        bell
    }

    # Just to make sure we have a directory!
    if {$idir == ""} {
	set idir $CrossFire::homeDir
    }

    if {$type == "log"} {
	set tempFile [tk_getSaveFile -parent $configW(top) \
			  -initialdir $idir -filetypes $ftypes]
    } else {
	set tempFile [tk_getOpenFile -parent $configW(top) \
			  -initialdir $idir -filetypes $ftypes]
    }

    if {$tempFile != ""} {
        if {$type == "audio"} {
            set configW($fileVar) $tempFile
        } else {
            set config($fileVar) $tempFile
        }
    }

    return 
}

# Config::CreateCrossFire --
#
# Options for CrossFire (and Config).
#
# Returns:
#   Frame widget path.
#
proc Config::CreateCrossFire {} {

    variable config
    variable configW

    set maxWidth 14
    set fw [frame $configW(optFrame).optCrossFire \
		-relief raised -borderwidth 1]

    # Default Author's Name.
    frame $fw.name
    label $fw.name.l -text "Name:" -width $maxWidth -anchor e
    entry $fw.name.e -textvariable Config::config(CrossFire,authorName)
    grid $fw.name.l $fw.name.e -sticky ew -padx 3
    grid columnconfigure $fw.name 1 -weight 1

    # Default Author's Email.
    frame $fw.email
    label $fw.email.l -text "Email Address:" -width $maxWidth -anchor e
    entry $fw.email.e -textvariable Config::config(CrossFire,authorEmail)
    grid $fw.email.l $fw.email.e -sticky ew -padx 3
    grid columnconfigure $fw.email 1 -weight 1

    # Memory Usage
    frame $fw.memoryMode
    label $fw.memoryMode.l -text "Memory Usage:" -width $maxWidth -anchor e
    menubutton $fw.memoryMode.mb -indicatoron 1 -width 15 \
        -menu $fw.memoryMode.mb.menu -relief raised \
        -textvariable Config::config(CrossFire,memoryMode)
    menu $fw.memoryMode.mb.menu -tearoff 0
    foreach memoryMode "Small Medium Large" {
        $fw.memoryMode.mb.menu add radiobutton \
            -label $memoryMode -value $memoryMode \
            -variable Config::config(CrossFire,memoryMode)
    }
    grid $fw.memoryMode.l $fw.memoryMode.mb -sticky ew -padx 3
    grid columnconfigure $fw.memoryMode 1 -weight 1

    # Language Selection
    frame $fw.language
    label $fw.language.l -text "Language:" -width $maxWidth -anchor e
    menubutton $fw.language.mb -indicatoron 1 -width 15 \
        -menu $fw.language.mb.menu -relief raised \
        -textvariable Config::config(CrossFire,language)
    menu $fw.language.mb.menu -tearoff 0
    foreach language $::ML::languageList {
        $fw.language.mb.menu add radiobutton \
            -label $language -value $language \
            -variable Config::config(CrossFire,language) \
	    -command "CrossFire::Create"
    }
    grid $fw.language.l $fw.language.mb -sticky ew -padx 3
    grid columnconfigure $fw.language 1 -weight 1

    # Single CrossFire instance mode
    frame $fw.serverMode
    checkbutton $fw.serverMode.cb -text "Allow Multiple CrossFires" \
        -variable Config::config(CrossFire,serverMode) \
        -onvalue "Multiple" -offvalue "Single"
    grid $fw.serverMode.cb

    # Display splash screen
    frame $fw.splashScreen
    checkbutton $fw.splashScreen.cb -text "Display Splash Screen" \
        -variable Config::config(CrossFire,showSplashScreen) \
        -onvalue "Yes" -offvalue "No"
    grid $fw.splashScreen.cb

    # Resize Paned Windows continuously?
    frame $fw.autoResize
    checkbutton $fw.autoResize.cb -text "Continuously Resize Paned Windows" \
        -variable Config::config(CrossFire,autoResize) \
        -onvalue 1 -offvalue 0
    grid $fw.autoResize.cb

    # Show grip on Paned Windows?
    frame $fw.showGrip
    checkbutton $fw.showGrip.cb -text "Display Grip on Paned Windows" \
        -variable Config::config(CrossFire,showGrip) \
        -onvalue "y" -offvalue "n"
    grid $fw.showGrip.cb

    # Grid the CrossFire Options
    grid $fw.name         -pady 3 -padx 5 -sticky new
    grid $fw.email        -pady 3 -padx 5 -sticky new
    grid $fw.memoryMode   -pady 3 -padx 5 -sticky nw
    grid $fw.language     -pady 3 -padx 5 -sticky nw
    grid $fw.serverMode   -pady 3 -padx 5 -sticky nw
    grid $fw.splashScreen -pady 3 -padx 5 -sticky nw
    grid $fw.autoResize   -pady 3 -padx 5 -sticky nw
    grid $fw.showGrip     -pady 3 -padx 5 -sticky nw
    grid columnconfigure $fw 0 -weight 1
    grid rowconfigure $fw 8 -weight 1

    return $fw
}

# Config::CreateTooltips --
#
#   Options for tooltips.
#
# Parameters:
#   None.
#
# Returns:
#   Frame widget path
proc Config::CreateTooltips {} {

    variable config
    variable configW

    set fw [frame $configW(optFrame).optTooltips \
		-relief raised -borderwidth 1]

    # Enable Tooltips Help?
    frame $fw.tooltips
    checkbutton $fw.tooltips.cb -text "Enable Tooltips" \
        -variable Config::config(Tooltips,mode) \
        -onvalue "On" -offvalue "Off" \
	-command {
	    Balloon::Mode $Config::config(Tooltips,mode)
	    Config::UpdateTooltipFriends
	}
    grid $fw.tooltips.cb

    # Enable automatic hide?
    frame $fw.autoHide
    checkbutton $fw.autoHide.cb -text "Automatically hide after " \
        -variable Config::config(Tooltips,autoHide) \
        -onvalue "On" -offvalue "Off" \
	-command {
	    Balloon::AutoHide $Config::config(Tooltips,autoHide)
	    Config::UpdateTooltipFriends
	}
    set configW(Tooltips,autoHide) $fw.autoHide.cb
    menubutton $fw.autoHide.mb -indicatoron 1  \
        -menu $fw.autoHide.mb.menu -relief raised \
        -textvariable Config::config(Tooltips,autoHideDelay)
    set configW(Tooltips,autoHideDelay) $fw.autoHide.mb
    menu $fw.autoHide.mb.menu -tearoff 0
    foreach viewMode "1 2 3 4 5 10" {
        $fw.autoHide.mb.menu add radiobutton \
            -label $viewMode -value $viewMode \
            -variable Config::config(Tooltips,autoHideDelay) \
	    -command {
		Balloon::HideDelay $Config::config(Tooltips,autoHideDelay)
	    }
    }
    label $fw.autoHide.l -text " seconds"
    grid $fw.autoHide.cb -row 0 -column 0
    grid $fw.autoHide.mb -row 0 -column 1
    grid $fw.autoHide.l  -row 0 -column 2

    # Grid all the parts in
    grid $fw.tooltips -pady 3 -padx 5 -sticky nw
    grid $fw.autoHide -pady 3 -padx 5 -sticky nw
    grid columnconfigure $fw 0 -weight 1
    grid rowconfigure $fw 2 -weight 1

    UpdateTooltipFriends

    return $fw
}

# Config::UpdateTooltipFriends --
#
#   Updates the various option on the Tooltips menu.  Enable/disable
#   a little more complicated due to multi layers of dependancies.
#
# Paramters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::UpdateTooltipFriends {} {

    variable config

    if {$config(Tooltips,mode) == "Off"} {
	Config::UpdateFriends Tooltips,mode On \
	    Tooltips,autoHide Tooltips,autoHideDelay
    } else {
	Config::UpdateFriends Tooltips,mode On \
	    Tooltips,autoHide
	Config::UpdateFriends Tooltips,autoHide On \
	    Tooltips,autoHideDelay
    }

    return
}

# Config::CreateSound --
#
proc Config::CreateSound {} {

    variable config
    variable configW

    set configW(Sound,previousDir) [file join $CrossFire::homeDir "Sounds"]

    set fw [frame $configW(optFrame).optSound -relief raised -borderwidth 1]

    # Play Sounds?
    frame $fw.playSounds
    checkbutton $fw.playSounds.cb -text "Enable Sounds" \
        -variable Config::config(Sound,play) \
        -onvalue "Yes" -offvalue "No"
    grid $fw.playSounds.cb

    # List of sound event names
    frame $fw.soundList
    listbox $fw.soundList.lb -exportselection 0 -width 20 \
        -yscrollcommand "CrossFire::SetScrollBar $fw.soundList.sb" \
        -foreground black -background white
    set configW(Sound,lbw) $fw.soundList.lb
    bind $fw.soundList.lb <ButtonRelease-1> "Config::UpdateSoundFile"
    scrollbar $fw.soundList.sb -command "$fw.soundList.lb yview"
    grid $fw.soundList.lb -sticky nsew
    grid columnconfigure $fw.soundList 0 -weight 1
    grid rowconfigure $fw.soundList 0 -weight 1

    foreach soundName $configW(Sound,nameList) {
        $configW(Sound,lbw) insert end $soundName
    }

    # Sound file name
    frame $fw.soundFile
    label $fw.soundFile.l -text "Sound:"
    entry $fw.soundFile.file -textvariable Config::configW(Sound,File) \
        -relief groove -width 25 -state disabled
    button $fw.soundFile.test -text "Test" -command "Config::TestSound"
    if {[lsearch [image names] imgSpeaker] != -1} {
        $fw.soundFile.test configure -image imgSpeaker
    }
    button $fw.soundFile.sel -text "Select..." -command "Config::SelectSound"
    button $fw.soundFile.none -text "No Sound" \
        -command "Config::SelectSound None"
    if {[lsearch [image names] imgNoSound] != -1} {
        $fw.soundFile.none configure -image imgNoSound
    }
    grid $fw.soundFile.file $fw.soundFile.test \
        $fw.soundFile.sel $fw.soundFile.none -sticky nsew -padx 3
    grid columnconfigure $fw.soundFile 0 -weight 1

    grid $fw.playSounds -pady 3 -padx 5 -sticky w
    grid $fw.soundList  -pady 0 -padx 5 -sticky nsew
    grid $fw.soundFile  -pady 3 -padx 5 -sticky nsew

    grid columnconfigure $fw 0 -weight 1
    grid rowconfigure $fw 1 -weight 1

    return $fw
}

# Config::UpdateSoundFile --
#
proc Config::UpdateSoundFile {} {

    variable config
    variable configW

    set name [$configW(Sound,lbw) get [$configW(Sound,lbw) cursel]]
    set id $configW(Sound,$name,id)
    set configW(Sound,File) $config(Sound,$id,file)

    return
}

# Config::SelectSound --
#
proc Config::SelectSound {{none ""}} {

    variable config
    variable configW

    set cur [$configW(Sound,lbw) cursel]
    if {$cur == ""} {
        tk_messageBox -title "Huh?" -icon error \
            -message "You must first select which sound above!!"
        return
    }

    set name [$configW(Sound,lbw) get $cur]
    set id $configW(Sound,$name,id)

    if {$none == ""} {
        SelectFile Sound,File audio
    } else {
        set msg "Are you sure you want to remove this sound?"
        set response [tk_messageBox -title "Really?" -icon question \
                          -message $msg -type yesno -default yes]
        if {$response == "yes"} {
            set configW(Sound,File) "None"
        }
    }

    if {$configW(Sound,File) != "None"} {
        set configW(Sound,previousDir) [file dirname $configW(Sound,File)]
    } else {
        set configW(Sound,previousDir) [file join $CrossFire::homeDir "Sounds"]
    }

    set config(Sound,$id,file) $configW(Sound,File)

    return
}

# Config::TestSound --
#
proc Config::TestSound {} {

    variable config
    variable configW

    set cur [$configW(Sound,lbw) cursel]
    if {$cur != ""} {
        set name [$configW(Sound,lbw) get $cur]
        CrossFire::PlaySound $configW(Sound,$name,id)
    }

    return
}

# Config::CreateLauncher --
#
#   Create the options for the program launcher.
#
# Returns:
#   Nothing.
#
proc Config::CreateLauncher {} {

    variable config
    variable configW

    set fw [frame $configW(optFrame).optLauncher -relief raised -borderwidth 1]

    # Graphical Main Menu?
    frame $fw.mainMenuType
    checkbutton $fw.mainMenuType.gr -text "Graphical Main Menu" \
        -variable Config::config(Launcher,menuType) \
        -onvalue "Graphical" -offvalue "Text" \
        -command {
            CrossFire::Create
            Config::UpdateFriends Launcher,menuType Graphical \
                Launcher,displayBackGround \
                Launcher,displayHelp \
                Launcher,iconSet
        }
    checkbutton $fw.mainMenuType.bg -text "Background Image" \
        -variable Config::config(Launcher,displayBackGround) \
        -onvalue "Yes" -offvalue "No" -command "CrossFire::Create"
    set configW(Launcher,displayBackGround) $fw.mainMenuType.bg
    checkbutton $fw.mainMenuType.hs -text "Mouse-Over Help" \
        -variable Config::config(Launcher,displayHelp) \
        -onvalue "Yes" -offvalue "No" -command "CrossFire::Create"
    set configW(Launcher,displayHelp) $fw.mainMenuType.hs

    # Main Menu Icon Set
    frame $fw.mainMenuType.is
    label $fw.mainMenuType.is.l -text "Icon Set:" -anchor e
    menubutton $fw.mainMenuType.is.mb -indicatoron 1 -width 10 \
        -menu $fw.mainMenuType.is.mb.menu -relief raised \
        -textvariable Config::config(Launcher,iconSet)
    set configW(Launcher,iconSet) $fw.mainMenuType.is.mb
    menu $fw.mainMenuType.is.mb.menu -tearoff 0
    set baseDir [file join $CrossFire::homeDir "Graphics"]
    set fileList {}
    foreach tempFile [glob [file join $baseDir "*"]] {
        lappend fileList [file tail $tempFile]
    }
    foreach fname [lsort $fileList] {
        set tempFile [file join $baseDir $fname]
        if {([file isdirectory $tempFile] == 1) &&
            ($fname != "Icons") && ($fname != "Cards")} {
            $fw.mainMenuType.is.mb.menu add radiobutton \
                -label $fname -value $fname \
                -variable Config::config(Launcher,iconSet) \
                -command "CrossFire::Create"
        }
    }
    grid $fw.mainMenuType.is.l $fw.mainMenuType.is.mb -sticky ew -padx 3
    grid columnconfigure $fw.mainMenuType.is 1 -weight 1

    grid $fw.mainMenuType.gr -sticky w -pady 2
    grid $fw.mainMenuType.bg -sticky w -padx 20 -pady 2
    grid $fw.mainMenuType.hs -sticky w -padx 20 -pady 2
    grid $fw.mainMenuType.is -sticky w -padx 20 -pady 2

    # CrossFire Process Icon Selection
    set pl $fw.processList
    frame $pl
    label $pl.lbl -anchor w -text "Show Icons For:"
    frame $pl.sel
    listbox $pl.sel.lb -exportselection 0 -selectmode multiple -width 20 \
        -yscrollcommand "CrossFire::SetScrollBar $pl.sel.sb"
    set configW(processListBox) $pl.sel.lb
    bind $pl.sel.lb <ButtonRelease-1> "Config::UpdateProcessList"
    scrollbar $pl.sel.sb -command "$pl.sel.lb yview"
    grid $pl.sel.lb -sticky nsew
    grid columnconfigure $pl.sel 0 -weight 1
    grid rowconfigure $pl.sel 0 -weight 1
    grid $pl.lbl -columnspan 2 -sticky w
    grid $pl.sel -sticky nsew
    grid columnconfigure $pl 0 -weight 1
    grid rowconfigure $pl 1 -weight 1

    # Add the list of all CrossFire processes to the listbox
    foreach processName $CrossFire::XFprocess(list) {
        $pl.sel.lb insert end $processName
        if {[lsearch $config(Launcher,showIcon) $processName] != -1} {
            $pl.sel.lb selection set end
        }
    }

    grid $fw.mainMenuType -pady 3 -padx 5 -sticky nw
    grid $fw.processList -row 0 -column 1 -pady 3 -padx 5 -sticky nsew \
        -rowspan 2

    grid columnconfigure $fw 1 -weight 1
    grid rowconfigure $fw 1 -weight 1

    UpdateFriends Launcher,menuType Graphical Launcher,displayBackGround \
        Launcher,displayHelp Launcher,iconSet

    return $fw
}

# Config::About --
#
#   Silly little about dialog for the configuration.
#
# Paramters:
#   w        : Parent toplevel.
#
# Returns:
#   Nothing.
#
proc Config::About {w} {
    set message "CrossFire Configuration\n"
    append message "\nby Dan Curtiss"
    tk_messageBox -icon info -title "About Configure" \
        -parent $w -message $message
    return
}

# Config::UpdateProcessList --
#
#   Updates the list of processes to show icons for and redraws the
#   CrossFire main menu window.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::UpdateProcessList {} {

    variable config
    variable configW

    set lbw $configW(processListBox)
    set config(Launcher,showIcon) {}
    foreach lbIndex [$lbw curselection] {
        lappend config(Launcher,showIcon) [$lbw get $lbIndex]
    }

    CrossFire::Create

    return
}

# Config::UpdateFriends --
#
#   Updates the state of widgets dependent upon another.
#
# Parameters:
#   var        : Variable that has changed.
#   onValue    : The "on" value for the var
#   args       : List of widgets to change
#
# Returns:
#   Nothing.
#
proc Config::UpdateFriends {var onValue args} {

    variable config
    variable configW

    foreach w $args {
        if {$config($var) == $onValue} {
            $configW($w) configure -state normal
        } else {
            $configW($w) configure -state disabled
        }
    }

    return
}

# Config::CreateViewCard --
#
#   Options for viewing cards
#
# Returns:
#   Nothing.
#
proc Config::CreateViewCard {} {

    variable config
    variable configW

    set fw [frame $configW(optFrame).optViewCard -relief raised \
		-borderwidth 1]

    # Card view choice
    frame $fw.cardView
    label $fw.cardView.l -text "Card View Mode:"
    menubutton $fw.cardView.mb -indicatoron 1 -width 10 \
        -menu $fw.cardView.mb.menu -relief raised \
        -textvariable Config::config(ViewCard,mode)
    menu $fw.cardView.mb.menu -tearoff 0
    foreach viewMode "Single Multiple Continuous" {
        $fw.cardView.mb.menu add radiobutton \
            -label $viewMode -value $viewMode \
            -variable Config::config(ViewCard,mode)
    }
    grid $fw.cardView.l  -row 0 -column 0
    grid $fw.cardView.mb -row 0 -column 1 -padx 3

    # View Card Type and world as icon or text.
    frame $fw.graphical
    label $fw.graphical.l -text "Graphical:"
    checkbutton $fw.graphical.type -text "Card Type" \
        -onvalue "Icon" -offvalue "Text" \
        -variable Config::config(ViewCard,typeMode)
    checkbutton $fw.graphical.world -text "World" \
        -onvalue "Icon" -offvalue "Text" \
        -variable Config::config(ViewCard,worldMode)
    grid $fw.graphical.l -sticky w
    grid $fw.graphical.type $fw.graphical.world -sticky w -padx 10

    # Display Bluelines, Attributes, Usables?
    frame $fw.display
    grid [label $fw.display.l -text "Display:"] -sticky w
    foreach {which title configVar} {
	blueLine  Bluelines      showBluelines
	attribute Attributes     showAttributes
	usable    {Usable Cards} showUsable
    } {
        set f "ViewCard,${which}Select"
	checkbutton $fw.display.$which -text $title \
	    -onvalue "Yes" -offvalue "No" \
            -command "Config::UpdateFriends ViewCard,$configVar Yes $f" \
	    -variable Config::config(ViewCard,$configVar) \
	    -foreground $Config::config(ViewCard,color,$which) \
	    -activeforeground $Config::config(ViewCard,color,$which)
	set configW(ViewCard,$which) $fw.display.$which
	button $fw.display.${which}Select -text "Color..." -command \
            "Config::SelectCardTextColor ViewCard $which [list $title]"
        set configW($f) $fw.display.${which}Select
	grid $fw.display.$which $fw.display.${which}Select \
	    -sticky w -padx 5
        Config::UpdateFriends ViewCard,$configVar Yes $f
    }

    # Add Close Button?
    frame $fw.addCloseButton
    checkbutton $fw.addCloseButton.cb -text "Add Close Button" \
        -onvalue "Yes" -offvalue "No" \
        -variable Config::config(ViewCard,closeButton)
    grid $fw.addCloseButton.cb

    # Always display icon level?
    frame $fw.displayIcon
    checkbutton $fw.displayIcon.cb -text "Always Show Icon Level" \
        -onvalue "Yes" -offvalue "No" \
        -variable Config::config(ViewCard,showLevel)
    grid $fw.displayIcon.cb

    # Display rule card instructions on every single rule card ever made?
    frame $fw.displayRule
    checkbutton $fw.displayRule.cb -text "Show Rule Card Instructional Text" \
        -onvalue "Yes" -offvalue "No" \
        -variable Config::config(ViewCard,showRuleText)
    grid $fw.displayRule.cb

    # Card Viewer "All Cards" set Selection
    set vcsl $fw.viewerSets
    frame $vcsl
    label $vcsl.lbl -anchor w -text "All Card Sets:"
    frame $vcsl.sel
    listbox $vcsl.sel.lb -exportselection 0 \
        -yscrollcommand "CrossFire::SetScrollBar $vcsl.sel.sb" \
        -selectmode multiple -width 20
    set configW(CSLB,viewCard) $vcsl.sel.lb
    bind $vcsl.sel.lb <ButtonRelease-1> "Config::UpdateSetList viewCard"
    scrollbar $vcsl.sel.sb -command "$vcsl.sel.lb yview"
    grid $vcsl.sel.lb -sticky nsew
    grid columnconfigure $vcsl.sel 0 -weight 1
    grid rowconfigure $vcsl.sel 0 -weight 1
    grid $vcsl.lbl -columnspan 2 -sticky w
    grid $vcsl.sel -sticky nsew
    grid columnconfigure $vcsl 0 -weight 1
    grid rowconfigure $vcsl 1 -weight 1

    # Add the list of viewer card sets to the listbox.
    foreach setID [CrossFire::CardSetIDList "allPlain"] {
        $vcsl.sel.lb insert end $CrossFire::setXRef($setID,name)
        if {[lsearch $config(ViewCard,setIDList) $setID] != -1} {
            $vcsl.sel.lb selection set end
        }
    }

    grid $fw.cardView       -pady 3 -padx 5 -sticky nw
    grid $fw.graphical      -pady 3 -padx 5 -sticky nw
    grid $fw.display        -pady 3 -padx 5 -sticky nw
    grid $fw.addCloseButton -pady 3 -padx 5 -sticky nw
    grid $fw.displayIcon    -pady 3 -padx 5 -sticky nw
    grid $fw.displayRule    -pady 3 -padx 5 -sticky nw
    grid $vcsl              -pady 3 -padx 5 -sticky nsew -row 0 -column 1 \
        -rowspan 6

    grid columnconfigure $fw 1 -weight 1
    grid rowconfigure $fw 5 -weight 1

    return $fw
}
# Config::CreatePrint --
#
#   Options for printing.
#
# Returns:
#   Nothing.
#
proc Config::CreatePrint {} {

    variable config
    variable configW

    set fw [frame $configW(optFrame).optPrint -relief raised \
		-borderwidth 1]

    # Display Bluelines, Attributes, Usables?
    frame $fw.display
    grid [label $fw.display.l -text "Print:"] -sticky w
    foreach {which title} {
	blueline   Bluelines
	attributes Attributes
	usable     {Usable Cards}
    } {
        set f "Print,${which}Select"
	checkbutton $fw.display.$which -text $title \
	    -onvalue "Yes" -offvalue "No" \
            -command "Config::UpdateFriends Print,show,$which Yes $f" \
	    -variable Config::config(Print,show,$which) \
	    -foreground $Config::config(Print,color,$which) \
	    -activeforeground $Config::config(Print,color,$which)
	set configW(Print,$which) $fw.display.$which
	button $fw.display.${which}Select -text "Color..." -command \
            "Config::SelectCardTextColor Print $which [list $title]"
        set configW($f) $fw.display.${which}Select
	grid $fw.display.$which $fw.display.${which}Select \
	    -sticky w -padx 5
        Config::UpdateFriends Print,show,$which Yes $f
    }

    # Display rule card instructions on every single rule card ever made?
    frame $fw.displayRule
    checkbutton $fw.displayRule.cb \
        -text "Print Rule Card Instructional Text" \
        -onvalue "Yes" -offvalue "No" \
        -variable Config::config(Print,showRuleText)
    grid $fw.displayRule.cb

    # For exporting HTML
    frame $fw.export
    checkbutton $fw.export.cb -text "Create HTML Index" -onvalue "Yes" \
        -offvalue "No" -variable Config::config(Print,makeIndex) -command \
        "Config::UpdateFriends Print,makeIndex Yes Print,numPerPage"
    menubutton $fw.export.mb -width 3 -indicatoron 1 \
        -menu $fw.export.mb.menu -relief raised \
        -textvariable Config::config(Print,numPerPage)
    set configW(Print,numPerPage) $fw.export.mb
    menu $fw.export.mb.menu -tearoff 0
    foreach pageSize "5 10 25 50 100" {
        $fw.export.mb.menu add radiobutton \
            -value $pageSize -label $pageSize \
            -variable Config::config(Print,numPerPage)
    }
    label $fw.export.l -text "     Cards Per Page: "
    grid $fw.export.cb - -sticky w 
    grid $fw.export.l    -sticky w -row 1 -column 0
    grid $fw.export.mb   -sticky w -row 1 -column 1
    UpdateFriends Print,makeIndex Yes Print,numPerPage

    grid $fw.display        -pady 3 -padx 5 -sticky nw
    grid $fw.displayRule    -pady 3 -padx 5 -sticky nw
    grid $fw.export         -pady 3 -padx 5 -sticky nw

    grid columnconfigure $fw 1 -weight 1
    grid rowconfigure $fw 2 -weight 1

    return $fw
}

# Config::SelectCardTextColor --
#
#   Allows for setting the card text color for bluelines, attributes,
#   and usable cards.
#
# Parameters:
#   group      : Options group (Print or ViewCard)
#   which      : Which card text to change.
#   title      : Title to put in title bar.
#
# Returns:
#   Nothing.
#
proc Config::SelectCardTextColor {group which title} {

    variable config
    variable configW

    set color [tk_chooseColor \
		   -initialcolor $config($group,color,$which) \
                   -parent $configW(top) -title "Select $title Color"]

    if {$color == ""} {
        return
    }

    set config($group,color,$which) $color
    $configW($group,$which) configure \
	-foreground $color -activeforeground $color

    return
}

# Config::CreateSearcher --
#
#   Options for the Ultra Searcher
#
# Returns:
#   Nothing.
#
proc Config::CreateSearcher {} {

    variable config
    variable configW
    variable searchModes

    set fw [frame $configW(optFrame).optSearcher -relief raised -borderwidth 1]

    frame $fw.searchMode
    label $fw.searchMode.l -text "Search Mode:"
    menubutton $fw.searchMode.mb -width 24 -indicatoron 1 \
        -menu $fw.searchMode.mb.menu -relief raised \
        -textvariable Config::configW(searchModeText)
    menu $fw.searchMode.mb.menu -tearoff 0
    foreach searchMode [array names searchModes] {
        $fw.searchMode.mb.menu add radiobutton \
            -value $searchMode -label $searchModes($searchMode) \
            -variable Config::config(Searcher,searchMode) \
            -command "Config::UpdateSearchMode"
    }
    grid $fw.searchMode.l $fw.searchMode.mb
    Config::UpdateSearchMode

    # Embedded card view toggle
    frame $fw.embedCard
    checkbutton $fw.embedCard.cb -text "Integrated Card Viewer" \
	-variable Config::config(Searcher,embedCardView) \
	-onvalue "Yes" -offvalue "No"
    grid $fw.embedCard.cb -sticky w -padx 3

    # Card set Selection
    set ecsl $fw.searcherSet
    frame $ecsl
    label $ecsl.lbl -anchor w -text "Card Sets:"
    frame $ecsl.sel
    listbox $ecsl.sel.lb -exportselection 0 \
        -yscrollcommand "CrossFire::SetScrollBar $ecsl.sel.sb" \
        -selectmode multiple -width 20
    set configW(CSLB,searcher) $ecsl.sel.lb
    bind $ecsl.sel.lb <ButtonRelease-1> "Config::UpdateSetList searcher"
    scrollbar $ecsl.sel.sb -command "$ecsl.sel.lb yview"
    grid $ecsl.sel.lb -sticky nsew
    grid columnconfigure $ecsl.sel 0 -weight 1
    grid rowconfigure $ecsl.sel 0 -weight 1
    grid $ecsl.lbl -columnspan 2 -sticky w
    grid $ecsl.sel -sticky nsew
    grid columnconfigure $ecsl 0 -weight 1
    grid rowconfigure $ecsl 1 -weight 1

    # Add the list of searcher card sets to the listbox.
    foreach setID [CrossFire::CardSetIDList "allPlain"] {
        $ecsl.sel.lb insert end $CrossFire::setXRef($setID,name)
        if {[lsearch $config(Searcher,setIDList) $setID] != -1} {
            $ecsl.sel.lb selection set end
        }
    }

    grid $fw.searchMode -pady 3 -padx 5 -sticky w
    grid $fw.embedCard  -pady 3 -padx 5 -sticky nw
    grid $ecsl -sticky nsew -pady 3 -padx 5
    grid columnconfigure $fw 0 -weight 1
    grid rowconfigure $fw 2 -weight 1

    return $fw
}

# Config::UpdateSearchMode --
#
#   Updates the text displayed for the search mode.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::UpdateSearchMode {} {

    variable config
    variable configW
    variable searchModes

    set configW(searchModeText) $searchModes($config(Searcher,searchMode))

    return
}

# Config::CreateDeckIt --
#
#   Options for DeckIt!
#
# Returns:
#   Nothing.
#
proc Config::CreateDeckIt {} {

    variable config
    variable configW

    set fw [frame $configW(optFrame).optDeckIt -relief raised -borderwidth 1]

    # Deck Size
    frame $fw.deckSize
    label $fw.deckSize.l -text "Deck Format:"
    menubutton $fw.deckSize.mb -indicatoron 1 -width 18 \
        -menu $fw.deckSize.mb.menu -relief raised \
        -textvariable Config::configW(deckSizeName)
    CrossFire::MakeDeckFormatMenu $fw.deckSize.mb.menu \
        Config::config(DeckIt,deckSize) \
        {Config::ChangeDeckSize $deckFormatID}
    ChangeDeckSize $config(DeckIt,deckSize)

    grid $fw.deckSize.l $fw.deckSize.mb -sticky ew -padx 3
    grid columnconfigure $fw.deckSize 1 -weight 1

    # Starting Set
    frame $fw.startSet
    label $fw.startSet.l -text "Starting Set:"
    menubutton $fw.startSet.mb -indicatoron 1 -width 18 \
        -menu $fw.startSet.mb.menu -relief raised \
        -textvariable Config::configW(startSetName)
    menu $fw.startSet.mb.menu -tearoff 0
    foreach group [CrossFire::CardSetClassList "all"] {
        $fw.startSet.mb.menu add radiobutton \
            -label $CrossFire::setClass($group,name) \
            -command "Config::ChangeDeckItStartSet $group"
    }
    $fw.startSet.mb.menu add separator
    foreach setID [CrossFire::CardSetIDList "allPlain"] {
        $fw.startSet.mb.menu add radiobutton \
            -label $CrossFire::setXRef($setID,name) \
            -command "Config::ChangeDeckItStartSet $setID"
    }
    ChangeDeckItStartSet $config(DeckIt,startSetID)

    grid $fw.startSet.l $fw.startSet.mb -sticky ew -padx 3
    grid columnconfigure $fw.startSet 1 -weight 1

    # Toggle printing of card text
    frame $fw.printText
    checkbutton $fw.printText.cb -text "Print Card Text" \
        -variable Config::config(DeckIt,printCardText) \
        -onvalue "Yes" -offvalue "No"
    grid $fw.printText.cb -sticky w -padx 3

    # Embedded card view toggle
    frame $fw.embedCard
    checkbutton $fw.embedCard.cb -text "Integrated Card Viewer" \
	-variable Config::config(DeckIt,embedCardView) \
	-onvalue "Yes" -offvalue "No"
    grid $fw.embedCard.cb -sticky w -padx 3

    # Display Mode of the deck.
    frame $fw.displayMode
    label $fw.displayMode.l -text "Display By Card:"
    menubutton $fw.displayMode.mb -indicatoron 1 \
        -menu $fw.displayMode.mb.menu -relief raised \
        -textvariable Config::config(DeckIt,deckDisplayMode)
    menu $fw.displayMode.mb.menu -tearoff 0
    foreach displayMode "Type Set World Rarity" {
        $fw.displayMode.mb.menu add radiobutton \
            -label $displayMode -value $displayMode \
            -variable Config::config(DeckIt,deckDisplayMode)
    }
    grid $fw.displayMode.l $fw.displayMode.mb -sticky ew -padx 3
    grid columnconfigure $fw.displayMode 1 -weight 1

    # Toggle for displaying all champions together
    frame $fw.championMode
    checkbutton $fw.championMode.cb -text "Group Champions Together" \
        -variable Config::config(DeckIt,championMode) \
        -onvalue "Champion" -offvalue "Class"
    grid $fw.championMode.cb -sticky w -padx 3

    # Toggle for showing the card icons
    frame $fw.showIcon
    checkbutton $fw.showIcon.cb -onvalue "Yes" -offvalue "No" \
        -text "Show Card Icons" \
        -variable Config::config(DeckIt,showIcon)
    grid $fw.showIcon.cb -sticky w -padx 3

    # Auto save on/off and delay time.
    frame $fw.autoSave
    checkbutton $fw.autoSave.cb -variable Config::config(DeckIt,autoSave) \
        -text "Auto Save after" -onvalue "Yes" -offvalue "No" \
        -command {
            Config::UpdateFriends DeckIt,autoSave Yes deckIt,saveTime
        }
    entry $fw.autoSave.e -width 3 -justify right \
        -textvariable Config::config(DeckIt,autoSaveTime)
    set configW(deckIt,saveTime) $fw.autoSave.e
    label $fw.autoSave.l2 -text "minute(s)"
    grid $fw.autoSave.cb $fw.autoSave.e $fw.autoSave.l2 -sticky ew -padx 3
    grid columnconfigure $fw.autoSave 1 -weight 1

    # Default Deck Directory.
    frame $fw.deckDir
    label $fw.deckDir.l -text "Deck Directory:"
    entry $fw.deckDir.dir -textvariable Config::config(DeckIt,dir) \
        -relief groove -width 25 -state disabled
    button $fw.deckDir.sel -text "Select..." \
        -command "Config::SelectDirectory DeckIt,dir Deck"
    grid $fw.deckDir.l $fw.deckDir.dir $fw.deckDir.sel -sticky nsew -padx 3
    grid columnconfigure $fw.deckDir 1 -weight 1

    # Editor Card set Selection
    set ecsl $fw.editorSet
    frame $ecsl
    label $ecsl.lbl -anchor w -text "All Card Sets:"
    frame $ecsl.sel
    listbox $ecsl.sel.lb -exportselection 0 \
        -yscrollcommand "CrossFire::SetScrollBar $ecsl.sel.sb" \
        -selectmode multiple -width 20
    set configW(CSLB,editor) $ecsl.sel.lb
    bind $ecsl.sel.lb <ButtonRelease-1> "Config::UpdateSetList editor"
    scrollbar $ecsl.sel.sb -command "$ecsl.sel.lb yview"
    grid $ecsl.sel.lb -sticky nsew
    grid columnconfigure $ecsl.sel 0 -weight 1
    grid rowconfigure $ecsl.sel 0 -weight 1
    grid $ecsl.lbl -columnspan 2 -sticky w
    grid $ecsl.sel -sticky nsew
    grid columnconfigure $ecsl 0 -weight 1
    grid rowconfigure $ecsl 1 -weight 1

    # Add the list of editor card sets to the listbox.
    foreach setID [CrossFire::CardSetIDList "allPlain"] {
        $ecsl.sel.lb insert end $CrossFire::setXRef($setID,name)
        if {[lsearch $config(DeckIt,setIDList) $setID] != -1} {
            $ecsl.sel.lb selection set end
        }
    }

    # Grid the DeckIt Options
    grid $fw.deckSize     -pady 3 -padx 5 -sticky nsew
    grid $fw.startSet     -pady 3 -padx 5 -sticky nsew
    grid $fw.displayMode  -pady 3 -padx 5 -sticky nsew
    grid $fw.championMode -pady 3 -padx 5 -sticky nw
    grid $fw.printText    -pady 3 -padx 5 -sticky nw
    grid $fw.embedCard    -pady 3 -padx 5 -sticky nw
    grid $fw.showIcon     -pady 3 -padx 5 -sticky nw
    grid $fw.autoSave     -pady 3 -padx 5 -sticky new
    grid $ecsl            -pady 3 -padx 5 -sticky nsew -row 0 -column 1 \
        -rowspan 8
    grid $fw.deckDir -    -pady 3 -padx 5 -sticky nsew
    grid columnconfigure $fw {0 1} -weight 1
    grid rowconfigure $fw 7 -weight 1

    UpdateFriends DeckIt,autoSave Yes deckIt,saveTime

    return $fw
}

# Config::ChangeDeckSize --
#
#   Changes the default deck size.
#
# Parameters:
#   size       : New deck size.
#
# Returns:
#   Nothing.
#
proc Config::ChangeDeckSize {size} {

    variable config
    variable configW

    set config(DeckIt,deckSize) $size
    set configW(deckSizeName) $CrossFire::deckFormat($size,name)

    return
}

# Config::ChangeDeckItStartSet --
#
#   Changes the default starting set.
#
# Parameters:
#   which     : New starting set or group.
#
# Returns:
#   Nothing.
#
proc Config::ChangeDeckItStartSet {which} {

    variable config
    variable configW

    set config(DeckIt,startSetID) $which
    if {[info exists CrossFire::setXRef($which,name)]} {
        set name $CrossFire::setXRef($which,name)
    } else {
        set name $CrossFire::setClass($which,name)
    }

    set configW(startSetName) $name

    return
}

# Config::CreateWarehouse --
#
# Options for Warehouse
#
# Returns:
#   Nothing.
#
proc Config::CreateWarehouse {} {

    variable config
    variable configW
    variable displayModes

    set fw [frame $configW(optFrame).optWarehouse \
		-relief raised -borderwidth 1]

    # Report format choice
    frame $fw.reportFormat
    label $fw.reportFormat.l -text "Report Format:"
    menubutton $fw.reportFormat.mb -indicatoron 1 \
        -menu $fw.reportFormat.mb.menu -relief raised \
        -textvariable Config::config(Warehouse,reportFormat)
    menu $fw.reportFormat.mb.menu -tearoff 0
    foreach viewMode "Full Verbose Brief HTML" {
        $fw.reportFormat.mb.menu add radiobutton \
            -label $viewMode -value $viewMode \
            -variable Config::config(Warehouse,reportFormat)
    }

    grid $fw.reportFormat.l $fw.reportFormat.mb -sticky ew -padx 3
    grid columnconfigure $fw.reportFormat 1 -weight 1

    # List display method.
    frame $fw.listDisplayMode
    label $fw.listDisplayMode.l -text "Display Method:"
    menubutton $fw.listDisplayMode.mb -indicatoron 1 -width 16 \
        -menu $fw.listDisplayMode.mb.menu -relief raised \
        -textvariable Config::configW(displayModeText)
    menu $fw.listDisplayMode.mb.menu -tearoff 0
    foreach displayMode $displayModes(list) {
        set displayModeText $displayModes($displayMode)
        $fw.listDisplayMode.mb.menu add radiobutton \
            -label $displayModeText -value $displayMode \
            -variable Config::config(Warehouse,listDisplayMode) \
            -command "Config::ChangeDisplayMode $displayMode"
    }
    Config::ChangeDisplayMode $config(Warehouse,listDisplayMode)

    grid $fw.listDisplayMode.l $fw.listDisplayMode.mb -sticky ew -padx 3
    grid columnconfigure $fw.listDisplayMode 1 -weight 1

    # Auto save on/off and delay time.
    frame $fw.autoSave
    checkbutton $fw.autoSave.cb -variable Config::config(Warehouse,autoSave) \
        -text "Auto Save after" -onvalue "Yes" -offvalue "No" \
        -command {
            Config::UpdateFriends Warehouse,autoSave Yes warehouse,saveTime
        }
    entry $fw.autoSave.e -width 3 -justify right \
        -textvariable Config::config(Warehouse,autoSaveTime)
    set configW(warehouse,saveTime) $fw.autoSave.e
    label $fw.autoSave.l2 -text "minute(s)"
    grid $fw.autoSave.cb $fw.autoSave.e $fw.autoSave.l2 -sticky ew -padx 3
    grid columnconfigure $fw.autoSave 1 -weight 1

    # Embedded card view toggle
    frame $fw.embedCard
    checkbutton $fw.embedCard.cb -text "Integrated Card Viewer" \
	-variable Config::config(Warehouse,embedCardView) \
	-onvalue "Yes" -offvalue "No"
    grid $fw.embedCard.cb -sticky w -padx 3

    # Warehouse card set selection
    set icsl $fw.invSet
    frame $icsl
    label $icsl.lbl -anchor w -text "All Card Sets:"
    frame $icsl.sel
    listbox $icsl.sel.lb -exportselection 0 \
        -yscrollcommand "CrossFire::SetScrollBar $icsl.sel.sb" \
        -selectmode multiple -width 20
    set configW(CSLB,inv) $icsl.sel.lb
    bind $icsl.sel.lb <ButtonRelease-1> "Config::UpdateSetList inv"
    scrollbar $icsl.sel.sb -command "$icsl.sel.lb yview"
    grid $icsl.sel.lb -sticky nsew
    grid columnconfigure $icsl.sel 0 -weight 1
    grid rowconfigure $icsl.sel 0 -weight 1
    grid $icsl.lbl -columnspan 2 -sticky w
    grid $icsl.sel -sticky nsew
    grid columnconfigure $icsl 0 -weight 1
    grid rowconfigure $icsl 1 -weight 1

    # Add the list of warehouse card sets to the listbox.
    foreach setID [CrossFire::CardSetIDList "real"] {
        $icsl.sel.lb insert end $CrossFire::setXRef($setID,name)
        if {[lsearch $config(Warehouse,setIDList) $setID] != -1} {
            $icsl.sel.lb selection set end
        }
    }

    # Default Warehouse Directory.
    frame $fw.invDir
    label $fw.invDir.l -text "Inventory Directory:" -width 20 -anchor e
    entry $fw.invDir.dir -textvariable Config::config(Warehouse,invDir) \
        -relief groove -width 25 -state disabled
    button $fw.invDir.sel -text "Select..." \
        -command "Config::SelectDirectory Warehouse,invDir Inventory"
    grid $fw.invDir.l $fw.invDir.dir $fw.invDir.sel -sticky nsew -padx 3
    grid columnconfigure $fw.invDir 1 -weight 1

    # Default Inventory file.
    frame $fw.defaultInv
    label $fw.defaultInv.l -text "Default Inventory:" -width 20 -anchor e
    entry $fw.defaultInv.dir -relief groove -width 25 -state disabled \
        -textvariable Config::config(Warehouse,defaultInv)
    button $fw.defaultInv.sel -text "Select..." \
        -command "Config::SelectFile Warehouse,defaultInv inv"
    grid $fw.defaultInv.l $fw.defaultInv.dir $fw.defaultInv.sel \
        -sticky nsew -padx 3
    grid columnconfigure $fw.defaultInv 1 -weight 1

    # Default Reports Directory.
    frame $fw.reportDir
    label $fw.reportDir.l -text "Report Directory:" -width 20 -anchor e
    entry $fw.reportDir.dir -textvariable Config::config(Warehouse,reportDir) \
        -relief groove -width 25 -state disabled
    button $fw.reportDir.sel -text "Select..." \
        -command "Config::SelectDirectory Warehouse,reportDir Report"
    grid $fw.reportDir.l $fw.reportDir.dir $fw.reportDir.sel \
        -sticky nsew -padx 3
    grid columnconfigure $fw.reportDir 1 -weight 1

    # Grid the warehouse Options
    grid $fw.reportFormat    -pady 3 -padx 5 -sticky nsew
    grid $fw.listDisplayMode -pady 3 -padx 5 -sticky nsew
    grid $fw.autoSave        -pady 3 -padx 5 -sticky nw
    grid $fw.embedCard       -pady 3 -padx 5 -sticky nw
    grid $icsl               -pady 3 -padx 5 -sticky nsew -row 0 -column 1 \
        -rowspan 4
    grid $fw.invDir     -    -pady 3 -padx 5 -sticky nsew
    grid $fw.defaultInv -    -pady 3 -padx 5 -sticky nsew
    grid $fw.reportDir  -    -pady 3 -padx 5 -sticky nsew
    grid columnconfigure $fw 1 -weight 1
    grid rowconfigure $fw 3 -weight 1

    UpdateFriends Warehouse,autoSave Yes warehouse,saveTime

    return $fw
}

# Config::ChangeDisplayMode --
#
#   Updates the display mode for Card Warehouse.
#
# Parameters:
#   displayMode : Mode to change to.
#
# Returns:
#   Nothing.
#
proc Config::ChangeDisplayMode {displayMode} {

    variable configW
    variable displayModes

    set configW(displayModeText) $displayModes($displayMode)

    return
}

# Config::CreateSwapShop --
#
# Swap Shop Options.
#
# Returns:
#   Nothing.
#
proc Config::CreateSwapShop {} {

    variable config
    variable configW

    set fw [frame $configW(optFrame).optSwapShop -relief raised -borderwidth 1]

    # Auto save on/off and delay time.
    frame $fw.autoSave
    checkbutton $fw.autoSave.cb -variable Config::config(SwapShop,autoSave) \
        -text "Auto Save after" -onvalue "Yes" -offvalue "No" \
        -command {
            Config::UpdateFriends SwapShop,autoSave Yes swapShop,saveTime
        }
    entry $fw.autoSave.e -width 3 -justify right \
        -textvariable Config::config(SwapShop,autoSaveTime)
    set configW(swapShop,saveTime) $fw.autoSave.e
    label $fw.autoSave.l2 -text "minute(s)"
    grid $fw.autoSave.cb $fw.autoSave.e $fw.autoSave.l2 -sticky ew -padx 3
    grid columnconfigure $fw.autoSave 1 -weight 1

    # Trade reminder
    frame $fw.reminder
    checkbutton $fw.reminder.cb -variable Config::config(SwapShop,reminder) \
        -text "Check Trades after " \
        -onvalue "Yes" -offvalue "No" -command {
            Config::UpdateFriends SwapShop,reminder Yes swapShop,tolerance
        }
    entry $fw.reminder.e -width 3 -justify right \
        -textvariable Config::config(SwapShop,tolerance)
    set configW(swapShop,tolerance) $fw.reminder.e
    label $fw.reminder.l -text "day(s)"
    grid $fw.reminder.cb $fw.reminder.e $fw.reminder.l -sticky ew -padx 3
    grid columnconfigure $fw.reminder 1 -weight 1

    # Swap Shop card set selection
    set csl $fw.traderSet
    frame $csl
    label $csl.lbl -anchor w -text "All Card Sets:"
    frame $csl.sel
    listbox $csl.sel.lb -exportselection 0 \
        -yscrollcommand "CrossFire::SetScrollBar $csl.sel.sb" \
        -selectmode multiple -width 20
    set configW(CSLB,swapShop) $csl.sel.lb
    bind $csl.sel.lb <ButtonRelease-1> "Config::UpdateSetList swapShop"
    scrollbar $csl.sel.sb -command "$csl.sel.lb yview"
    grid $csl.sel.lb -sticky nsew
    grid columnconfigure $csl.sel 0 -weight 1
    grid rowconfigure $csl.sel 0 -weight 1
    grid $csl.lbl -columnspan 2 -sticky w
    grid $csl.sel -sticky nsew
    grid columnconfigure $csl 0 -weight 1
    grid rowconfigure $csl 1 -weight 1

    # Add the list of Swap Shop card sets to the listbox.
    foreach setID [CrossFire::CardSetIDList "real"] {
        $csl.sel.lb insert end $CrossFire::setXRef($setID,name)
        if {[lsearch $config(SwapShop,setIDList) $setID] != -1} {
            $csl.sel.lb selection set end
        }
    }

    # Default Trade Directory.
    frame $fw.tradeDir
    label $fw.tradeDir.l -text "Trade Directory:"
    entry $fw.tradeDir.dir -textvariable Config::config(SwapShop,dir) \
        -relief groove -width 25 -state disabled
    button $fw.tradeDir.sel -text "Select..." \
        -command "Config::SelectDirectory SwapShop,dir Trade"
    grid $fw.tradeDir.l $fw.tradeDir.dir $fw.tradeDir.sel -sticky nsew -padx 3
    grid columnconfigure $fw.tradeDir 1 -weight 1

    # Grid the Swap Shop options.
    grid $fw.autoSave   -pady 3 -padx 5 -sticky new
    grid $fw.reminder   -pady 3 -padx 5 -sticky new
    grid $csl           -pady 3 -padx 5 -sticky nsew -row 0 -column 1 \
        -rowspan 2
    grid $fw.tradeDir - -pady 3 -padx 5 -sticky nsew
    grid columnconfigure $fw 1 -weight 1
    grid rowconfigure $fw 1 -weight 1

    UpdateFriends SwapShop,autoSave Yes swapShop,saveTime
    UpdateFriends SwapShop,reminder Yes swapShop,tolerance

    return $fw
}

# Config::CreateFanSetEditor --
#
#   Options for the Fan Set Editor
#
# Returns:
#   Nothing.
#
proc Config::CreateFanSetEditor {} {

    variable config
    variable configW

    set fanSetList [CrossFire::CardSetIDList "fan"]
    if {[lsearch $fanSetList $config(FanSetEditor,setID)] == -1} {
        set config(FanSetEditor,setID) [lindex $fanSetList 0]
    }

    set fw [frame $configW(optFrame).optFanSetEditor \
		-relief raised -borderwidth 1]

    checkbutton $fw.autoSave -text "Automatically Save Card Changes" \
        -variable Config::config(FanSetEditor,autoSave)

    # Embedded card view toggle
    checkbutton $fw.embedCard -text "Integrated Card Viewer" \
	-variable Config::config(FanSetEditor,embedCardView) \
	-onvalue "Yes" -offvalue "No"

    # Default card set to edit
    set ecsl $fw.set
    frame $ecsl
    label $ecsl.lbl -anchor w -text "Default Set To Edit:"
    frame $ecsl.sel
    listbox $ecsl.sel.lb -exportselection 0 \
        -yscrollcommand "CrossFire::SetScrollBar $ecsl.sel.sb" \
        -selectmode single -width 20
    bind $ecsl.sel.lb <ButtonRelease-1> \
        "Config::ChangeFanSetDefault $ecsl.sel.lb"
    scrollbar $ecsl.sel.sb -command "$ecsl.sel.lb yview"
    grid $ecsl.sel.lb -sticky nsew
    grid columnconfigure $ecsl.sel 0 -weight 1
    grid rowconfigure $ecsl.sel 0 -weight 1
    grid $ecsl.lbl -columnspan 2 -sticky w
    grid $ecsl.sel -sticky nsew
    grid columnconfigure $ecsl 0 -weight 1
    grid rowconfigure $ecsl 1 -weight 1

    # Add the list of fanSetEditor card sets to the listbox.
    foreach setID [CrossFire::CardSetIDList "fan"] {
        $ecsl.sel.lb insert end $CrossFire::setXRef($setID,name)
        if {$setID == $Config::config(FanSetEditor,setID)} {
            $ecsl.sel.lb selection set end
        }
    }

    grid $fw.autoSave  -pady 3 -padx 5 -sticky w
    grid $fw.embedCard -pady 3 -padx 5 -sticky w
    grid $ecsl         -pady 3 -padx 5 -sticky nsew
    grid columnconfigure $fw 0 -weight 1
    grid rowconfigure $fw 2 -weight 1

    return $fw
}

# Config::ChangeFanSetDefault --
#
#   Changes the default set ID for the Fan Set Editor.
#
# Parameters:
#   lbw        : List box
#
# Returns:
#   Nothing.
#
proc Config::ChangeFanSetDefault {lbw} {

    variable config

    set setName [$lbw get [$lbw cursel]]
    set config(FanSetEditor,setID) $CrossFire::setXRef($setName)

    return
}

# Config::CreateComboMan --
#
#   Options for the Combo Manager.
#
# Returns:
#   Nothing.
#
proc Config::CreateComboMan {} {

    variable config
    variable configW

    set fw [frame $configW(optFrame).optComboMan \
		-relief raised -borderwidth 1]

    # Auto save on/off and delay time.
    frame $fw.autoSave
    checkbutton $fw.autoSave.cb -variable Config::config(ComboMan,autoSave) \
        -text "Auto Save after" -onvalue "Yes" -offvalue "No" \
        -command {
            Config::UpdateFriends ComboMan,autoSave Yes combo,saveTime
        }
    entry $fw.autoSave.e -width 3 -justify right \
        -textvariable Config::config(ComboMan,autoSaveTime)
    set configW(combo,saveTime) $fw.autoSave.e
    label $fw.autoSave.l2 -text "minute(s)"
    grid $fw.autoSave.cb $fw.autoSave.e $fw.autoSave.l2 -sticky ew -padx 3
    grid columnconfigure $fw.autoSave 1 -weight 1

    # Toggle printing of card text
    frame $fw.printText
    checkbutton $fw.printText.cb -text "Print Card Text" \
        -variable Config::config(ComboMan,printCardText) \
        -onvalue "Yes" -offvalue "No"
    grid $fw.printText.cb -sticky w -padx 3

    # Embedded card view toggle
    frame $fw.embedCard
    checkbutton $fw.embedCard.cb -text "Integrated Card Viewer in Editor" \
	-variable Config::config(ComboMan,embedCardView) \
	-onvalue "Yes" -offvalue "No"
    grid $fw.embedCard.cb -sticky w -padx 3

    # Embedded card view toggle for viewer
    frame $fw.embedCardV
    checkbutton $fw.embedCardV.cb -text "Integrated Card Viewer in Viewer" \
	-variable Config::config(ComboMan,embedCardViewV) \
	-onvalue "Yes" -offvalue "No"
    grid $fw.embedCardV.cb -sticky w -padx 3

    # Combo man card set selection
    set csl $fw.comboSet
    frame $csl
    label $csl.lbl -anchor w -text "All Card Sets:"
    frame $csl.sel
    listbox $csl.sel.lb -exportselection 0 \
        -yscrollcommand "CrossFire::SetScrollBar $csl.sel.sb" \
        -selectmode multiple -width 20
    set configW(CSLB,comboMan) $csl.sel.lb
    bind $csl.sel.lb <ButtonRelease-1> "Config::UpdateSetList comboMan"
    scrollbar $csl.sel.sb -command "$csl.sel.lb yview"
    grid $csl.sel.lb -sticky nsew
    grid columnconfigure $csl.sel 0 -weight 1
    grid rowconfigure $csl.sel 0 -weight 1
    grid $csl.lbl -columnspan 2 -sticky w
    grid $csl.sel -sticky nsew
    grid columnconfigure $csl 0 -weight 1
    grid rowconfigure $csl 1 -weight 1

    # Add the list of comboman card sets to the listbox.
    foreach setID [CrossFire::CardSetIDList "allPlain"] {
        $csl.sel.lb insert end $CrossFire::setXRef($setID,name)
        if {[lsearch $config(ComboMan,setIDList) $setID] != -1} {
            $csl.sel.lb selection set end
        }
    }

    # Default Combo Directory.
    frame $fw.comboDir
    label $fw.comboDir.l -text "Combo Directory:"
    entry $fw.comboDir.dir -textvariable Config::config(ComboMan,dir) \
        -relief groove -width 25 -state disabled
    button $fw.comboDir.sel -text "Select..." \
        -command "Config::SelectDirectory ComboMan,dir Combo"
    grid $fw.comboDir.l $fw.comboDir.dir $fw.comboDir.sel \
	-sticky nsew -padx 3
    grid columnconfigure $fw.comboDir 1 -weight 1

    grid $fw.autoSave   -pady 3 -padx 5 -sticky nw
    grid $fw.printText  -pady 3 -padx 5 -sticky nw
    grid $fw.embedCard  -pady 3 -padx 5 -sticky nw
    grid $fw.embedCardV -pady 3 -padx 5 -sticky nw
    grid $csl           -pady 3 -padx 5 -sticky nsew -row 0 -column 1 \
	-rowspan 4
    grid $fw.comboDir - -pady 3 -padx 5 -sticky nsew
    grid columnconfigure $fw 1 -weight 1
    grid rowconfigure $fw 3 -weight 1

    UpdateFriends ComboMan,autoSave Yes combo,saveTime

    return $fw
}

# Config::CreateChat --
#
#   Options for the Chat client.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::CreateChat {} {

    variable config
    variable configW

    set fw [frame $configW(optFrame).optChat -relief raised -borderwidth 1]

    # Default user name.
    frame $fw.name
    label $fw.name.l -text "Name:" -width 10 -anchor e
    entry $fw.name.e -textvariable Config::config(Chat,userName)
    button $fw.name.p -text " Profile... " -command {
        Chat::EditProfile offline
    }
    grid $fw.name.l $fw.name.e $fw.name.p -sticky ew -padx 3
    grid columnconfigure $fw.name 1 -weight 1

    # Default password.
    frame $fw.passwd
    label $fw.passwd.l -text "Password:" -width 10 -anchor e
    entry $fw.passwd.e -textvariable Config::config(Chat,password) -show "*"
    grid $fw.passwd.l $fw.passwd.e -sticky ew -padx 3
    grid columnconfigure $fw.passwd 1 -weight 1

    # Server
    frame $fw.server
    label $fw.server.l -text "Server:" -width 10 -anchor e
    menubutton $fw.server.mb -indicatoron 1 -width 15 \
        -menu $fw.server.mb.menu -relief raised \
        -textvariable Config::config(Chat,server,name)
    menu $fw.server.mb.menu -tearoff 0
    set configW(serverMenu) $fw.server.mb.menu
    UpdateServerList
    button $fw.server.add -text " Add " \
        -command Config::AddServer
    button $fw.server.edit -text " Edit " \
        -command "Config::AddServer Edit"
    button $fw.server.del -text "Delete" \
        -command Config::DeleteServer
    grid $fw.server.l $fw.server.mb $fw.server.add $fw.server.edit \
	$fw.server.del -sticky ew -padx 3
    grid columnconfigure $fw.server 1 -weight 1

    # Default chat window colors
    frame $fw.color
    label $fw.color.l -text "Text:" -width 10 -anchor e
    label $fw.color.newChamp -foreground $config(Chat,newChampion) \
        -background $config(Chat,background) -text "<Newbie>" \
        -font $config(Chat,font)
    set configW(newChamp) $fw.color.newChamp
    label $fw.color.chatText -text "I need" \
        -background $config(Chat,background) \
        -foreground $config(Chat,foreground) -anchor w \
        -font $config(Chat,font)
    set configW(chatText) $fw.color.chatText
    label $fw.color.chatURL -text "FRc/18" \
        -background $config(Chat,background) \
        -foreground $config(Chat,urlColor) -anchor w \
        -font $config(Chat,font)
    set configW(chatURL) $fw.color.chatURL
    button $fw.color.change -text " Change... " \
        -command "Config::ChangeChatText"
    grid $fw.color.l -row 0 -column 0 -padx 3
    grid $fw.color.newChamp -row 0 -column 1
    grid $fw.color.chatText -row 0 -column 2
    grid $fw.color.chatURL  -row 0 -column 3 -sticky ew
    grid $fw.color.change   -row 0 -column 4 -padx 3
    grid columnconfigure $fw.color 3 -weight 1

    # Beep when champion arrives or leaves
    frame $fw.alert
    label $fw.alert.header -text "Alert when Champion:" -anchor w
    checkbutton $fw.alert.arrive -variable Config::config(Chat,arriveAlert) \
        -text "Arrives" -anchor w
    checkbutton $fw.alert.leave -variable Config::config(Chat,leaveAlert) \
        -text "Leaves" -anchor w
    grid $fw.alert.header $fw.alert.arrive $fw.alert.leave \
        -sticky w -padx 3 -pady 3

    # Display Time Stamps
    frame $fw.timeStamp
    checkbutton $fw.timeStamp.cb -variable Config::config(Chat,timeStamp) \
        -text "Display Time Stamps" -anchor w \
        -command {
            Config::UpdateFriends Chat,timeStamp 1 chat,12hour chat,24hour
        }
    radiobutton $fw.timeStamp.rb12 -variable Config::config(Chat,timeMode) \
        -text "12 Hour" -value 12 -anchor w
    set configW(chat,12hour) $fw.timeStamp.rb12
    radiobutton $fw.timeStamp.rb24 -variable Config::config(Chat,timeMode) \
        -text "24 Hour" -value 24 -anchor w
    set configW(chat,24hour) $fw.timeStamp.rb24
    grid $fw.timeStamp.cb $fw.timeStamp.rb12 $fw.timeStamp.rb24 \
        -sticky ew -padx 3
    grid columnconfigure $fw.timeStamp 0 -weight 1

    # Start in expanded view toggle
    frame $fw.exView
    checkbutton $fw.exView.cb -text "Champion List Open at Start" \
	-variable Config::config(Chat,expandedView) \
	-onvalue "Yes" -offvalue "No"
    grid $fw.exView.cb -sticky w -padx 3

    # Use IM windows for whispers toggle
    frame $fw.useIM
    checkbutton $fw.useIM.cb -text "Use Private Chat Windows for Whispers" \
	-variable Config::config(Chat,useIMs) \
	-onvalue "Yes" -offvalue "No"
    grid $fw.useIM.cb -sticky w -padx 3

    # Automatic MOTD, Logging, and Log In Toggles
    frame $fw.autoVar
    label $fw.autoVar.l -text "Automatically:"
    checkbutton $fw.autoVar.logIn -variable Config::config(Chat,autoLogIn) \
        -text "Log In" -anchor w -onvalue "Yes" -offvalue "No"
    checkbutton $fw.autoVar.chatLog -variable Config::config(Chat,autoLog) \
        -text "Start Chat Log" -anchor w -onvalue "Yes" -offvalue "No"
    grid $fw.autoVar.l $fw.autoVar.logIn $fw.autoVar.chatLog \
	-sticky w -padx 3

    # Default Log Directory.
    frame $fw.logDir
    label $fw.logDir.l -text "Log Folder:" -anchor e -width 10
    entry $fw.logDir.e -textvariable Config::config(Chat,logDir) \
        -relief groove -width 25 -state disabled
    button $fw.logDir.sel -text " Select... " \
        -command "Config::SelectDirectory Chat,logDir Log"
    grid $fw.logDir.l $fw.logDir.e $fw.logDir.sel \
        -sticky nsew -padx 3
    grid columnconfigure $fw.logDir 1 -weight 1

    # Default Log File.
    frame $fw.logFile
    label $fw.logFile.l -text "Log File:" -anchor e -width 10
    entry $fw.logFile.e -textvariable Config::config(Chat,logFile) \
        -relief groove -width 25 -state disabled
    button $fw.logFile.sel -text " Select... " \
        -command "Config::SelectFile Chat,logFile log"
    grid $fw.logFile.l $fw.logFile.e $fw.logFile.sel \
        -sticky nsew -padx 3
    grid columnconfigure $fw.logFile 1 -weight 1

    # Actions File.
    frame $fw.actionFile
    label $fw.actionFile.l -text "Action File:" -anchor e -width 10
    entry $fw.actionFile.e -textvariable Config::config(Chat,actionFile) \
        -relief groove -width 25 -state disabled
    button $fw.actionFile.sel -text " Select... " \
        -command {
            Config::SelectFile Chat,actionFile action
            Chat::AddActionMenu
        }
    grid $fw.actionFile.l $fw.actionFile.e $fw.actionFile.sel \
        -sticky nsew -padx 3
    grid columnconfigure $fw.actionFile 1 -weight 1

    grid $fw.name       -pady 3 -padx 5 -sticky nsew
    grid $fw.passwd     -pady 3 -padx 5 -sticky nsew
    grid $fw.server     -pady 3 -padx 5 -sticky nsew
    grid $fw.color      -pady 3 -padx 5 -sticky nsew
    grid $fw.alert      -pady 3 -padx 5 -sticky w
    grid $fw.timeStamp  -pady 3 -padx 5 -sticky w
    grid $fw.exView     -pady 3 -padx 5 -sticky w
    grid $fw.useIM      -pady 3 -padx 5 -sticky w
    grid $fw.autoVar    -pady 3 -padx 5 -sticky w
    grid $fw.logDir     -pady 3 -padx 5 -sticky nsew
    grid $fw.logFile    -pady 3 -padx 5 -sticky nsew
    grid $fw.actionFile -pady 3 -padx 5 -sticky new

    grid columnconfigure $fw 0 -weight 1
    grid rowconfigure $fw 11 -weight 1

    UpdateFriends Chat,timeStamp 1 chat,12hour chat,24hour

    return $fw
}

# Config::UpdateServerConfig --
#
#   Updates the host and port settings for the default.
#
# Parameters:
#   host      : New host setting.
#   port      : New port setting.
#
# Returns:
#   Nothing.
#
proc Config::UpdateServerConfig {host port} {

    variable config

    set config(Chat,server,host) $host
    set config(Chat,server,port) $port

    return
}

# Config::AddServer --
#
#   Creates a GUI to enter new server information.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::AddServer {{mode Add}} {

    variable config
    variable configW

    set w $configW(top).addServer

    if {[winfo exists $w]} {
        wm deiconify $w
        raise $w
        return
    }

    if {$mode == "Add"} {
        set configW(server,name) {}
        set configW(server,host) {}
        set configW(server,port) {}
    } else {
        set pos [lsearch $config(Chat,server,list) $config(Chat,server,name)]
        set configW(server,name) $config(Chat,server,name)
        set configW(server,host) [lindex $config(Chat,server,list) \
                                      [expr $pos + 1]]
        set configW(server,port) [lindex $config(Chat,server,list) \
                                      [expr $pos + 2]]
    }

    toplevel $w
    wm title $w "$mode Server"

    frame $w.top -borderwidth 1 -relief raised
    label $w.top.lname -text "Name:"
    entry $w.top.ename -width 25 -textvariable Config::configW(server,name)
    label $w.top.lhost -text "Host:"
    entry $w.top.ehost -width 25 -textvariable Config::configW(server,host)
    label $w.top.lport -text "Port:"
    entry $w.top.eport -width 25 -textvariable Config::configW(server,port)
    grid $w.top.lname $w.top.ename -padx 5 -pady 3
    grid $w.top.lhost $w.top.ehost -padx 5 -pady 3
    grid $w.top.lport $w.top.eport -padx 5 -pady 3
    grid columnconfigure $w.top 1 -weight 1
    grid rowconfigure $w.top {0 1 2}  -weight 1
    grid $w.top -sticky nsew

    frame $w.buttons -borderwidth 1 -relief raised
    button $w.buttons.add -text "Save" \
        -command "Config::AddServerToList; destroy $w"
    button $w.buttons.cancel -text "Cancel" -command "destroy $w"
    grid $w.buttons.add $w.buttons.cancel -padx 5 -pady 3
    grid $w.buttons -sticky ew

    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 1

    focus $w.top.ename

    return
}

# Config::AddServerToList --
#
#   Adds a new server to the server list.  Will not allows
#   an already existing server to be added again.
#
# Parameters:
#   None. Read from configW array.
#
# Returns:
#   Nothing.
#
proc Config::AddServerToList {} {

    variable config
    variable configW

    set server $configW(server,name)
    set pos [lsearch $config(Chat,server,list) $server]
    if {$pos != -1} {
        set config(Chat,server,list) \
            [lreplace $config(Chat,server,list) $pos [expr $pos + 2]]
    }

    lappend config(Chat,server,list) $server $configW(server,host) \
        $configW(server,port)
    UpdateServerList

    return
}

# Config::DeleteServer --
#
#   Removes a server from the list of servers.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::DeleteServer {} {

    variable config

    set server $config(Chat,server,name)

    if {[tk_messageBox -type yesno -title "Delete Server $server" \
             -message "Are you sure you want to delete server $server?"] == "yes"} {
        set pos [lsearch $config(Chat,server,list) $server]
        set config(Chat,server,list) \
            [lreplace $config(Chat,server,list) $pos [expr $pos + 2]]
        UpdateServerList
    }

    return
}

# Config::UpdateServerList --
#
#   Updates the menu button list of servers.  Called by
#   either AddServer or DeleteServer.
#
# Paramters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::UpdateServerList {} {

    variable config
    variable configW

    set m $configW(serverMenu)
    set active $config(Chat,server,name)
    set current 0

    if {[llength $config(Chat,server,list)] == 0} {
        # Add back in default server
        AddDefaultCrossFireServer
    }

    $m delete 0 end
    foreach {sName host port} $config(Chat,server,list) {
        $m add radiobutton \
            -label $sName -value $sName \
            -variable Config::config(Chat,server,name) \
            -command "Config::UpdateServerConfig $host $port"
        if {$active == $sName} {
            set current 1
            set config(Chat,server,host) $host
            set config(Chat,server,port) $port
        }
    }

    if {$current == 0} {
        foreach {
            config(Chat,server,name)
            config(Chat,server,host)
            config(Chat,server,port)
        } $config(Chat,server,list) {break}
    }

    return
}

# Config::ChangeChatText --
#
#   Changes the default colors of the chat room.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::ChangeChatText {} {

    variable config
    variable configW

    set w $configW(top).chatText
    if {[winfo exists $w]} {
        wm deiconify $w
        raise $w
        return
    }

    set configW(chatColor) $w
    toplevel $w
    wm title $w "Change Chat Text"

    frame $w.select -borderwidth 1 -relief raised
    foreach {var type title} {
        Chat,font        Font  {Text Font}
        Chat,newChampion Color {New Champion's Name Color}
        Chat,foreground  Color {Text Color}
        Chat,urlColor    Color {Link Color}
        Chat,background  Color {Background Color}
    } {
        button $w.select.b$var -text $title \
            -command "Config::SetChat$type $var"
        grid $w.select.b$var -padx 5 -pady 3 -sticky ew
    }
    grid columnconfigure $w.select 0 -weight 1

    frame $w.buttons -borderwidth 1 -relief raised
    button $w.buttons.default -text "Defaults" \
        -command "Config::SetDefaultChatText"
    button $w.buttons.close -text $CrossFire::close \
        -command "destroy $w"
    grid $w.buttons.default $w.buttons.close -padx 5 -pady 3

    grid $w.select -sticky nsew
    grid $w.buttons -sticky ew

    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 1

    return
}

# Config::SetDefaultChatText --
#
#   Restores the chat colors back to the defaults.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::SetDefaultChatText {} {

    variable config
    variable configDef

    foreach var {
        Chat,foreground
        Chat,background
        Chat,newChampion
        Chat,font
    } {
        set config($var) $configDef($var)
    }

    UpdateChatText
    Chat::UpdateBoxColors

    return
}

# Config::SetChatColor --
#
#   Updates the color for chat defaults.
#
# Parameters:
#   var        : Variable to change (Chat,foreground, etc)
#
# Returns:
#   Nothing.
#
proc Config::SetChatColor {var} {

    variable config
    variable configW

    set color [tk_chooseColor -initialcolor $config($var) \
                   -parent $configW(chatColor)]

    if {$color != ""} {
        set config($var) $color
        UpdateChatText
        Chat::UpdateBoxColors
    }

    return
}

# Config::SetChatFont --
#
#   Updates the font for chat.
#
# Parameters:
#   var        : Variable to change (Chat,font)
#
# Returns:
#   Nothing.
#
proc Config::SetChatFont {var} {

    variable config
    variable configW

    set font [tk_chooseFont -initialfont $config($var) \
                   -parent $configW(chatColor)]

    if {$font != ""} {
        set config($var) $font
        UpdateChatText
        Chat::UpdateBoxColors
    }

    return
}

# Config::UpdateChatText --
#
#   Updates the configure GUI example display of the chat colors and font.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::UpdateChatText {} {

    variable config
    variable configW

    $configW(chatText) configure \
        -foreground $config(Chat,foreground) \
        -background $config(Chat,background) \
        -font $config(Chat,font)
    $configW(chatURL) configure \
        -foreground $config(Chat,urlColor) \
        -background $config(Chat,background) \
        -font $config(Chat,font)
    $configW(newChamp) configure \
        -foreground $config(Chat,newChampion) \
        -background $config(Chat,background) \
        -font $config(Chat,font)

    return
}

# Config::CreateBackUp --
#
#   Options for back up and restore.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::CreateBackUp {} {

    variable config
    variable configW

    set fw [frame $configW(optFrame).optBackUp -relief raised -borderwidth 1]

    # Auto back up on/off and number of days.
    frame $fw.autoBackUp
    checkbutton $fw.autoBackUp.cb -variable Config::config(BackUp,auto) \
        -text "Automatically Back Up every " -onvalue "Yes" -offvalue "No" \
        -command {
            Config::UpdateFriends BackUp,auto Yes backUp,days backUp,auto \
                backUp,selectDir
        }
    entry $fw.autoBackUp.e -width 3 -justify right \
        -textvariable Config::config(BackUp,autoDays)
    set configW(backUp,days) $fw.autoBackUp.e
    label $fw.autoBackUp.l2 -text "day(s)"
    grid $fw.autoBackUp.cb $fw.autoBackUp.e $fw.autoBackUp.l2 \
        -sticky ew -padx 3

    # Toggle for prompting before automatic back up
    frame $fw.prompt
    checkbutton $fw.prompt.cb -onvalue "Yes" -offvalue "No" \
        -text "Prompt Before Automatically Backing Up" \
        -variable Config::config(BackUp,autoPrompt)
    grid $fw.prompt.cb -sticky w -padx 3
    set configW(backUp,auto) $fw.prompt.cb

    # Default back Up Directory.
    frame $fw.dir
    label $fw.dir.l -text "Back Up Directory:"
    entry $fw.dir.dir -textvariable Config::config(BackUp,dir) \
        -relief groove -width 25 -state disabled
    button $fw.dir.sel -text "Select..." \
        -command "Config::SelectDirectory BackUp,dir Deck"
    set configW(backUp,selectDir) $fw.dir.sel
    grid $fw.dir.l -sticky w -padx 3
    grid $fw.dir.dir $fw.dir.sel -sticky nsew -padx 3
    grid columnconfigure $fw.dir 0 -weight 1

    grid $fw.autoBackUp -pady 3 -padx 5 -sticky w
    grid $fw.prompt     -pady 3 -padx 5 -sticky w
    grid $fw.dir        -pady 3 -padx 5 -sticky new

    grid columnconfigure $fw 0 -weight 1
    grid rowconfigure $fw 2 -weight 1

    UpdateFriends BackUp,auto Yes backUp,days backUp,auto backUp,selectDir

    return $fw
}

# Config::CreateOnline --
#
#   Options for online game play.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::CreateOnline {} {

    variable config
    variable configW

    set fw [frame $configW(optFrame).optOnline -relief raised -borderwidth 1]

    # Toggle for inverting opponent formation
    frame $fw.invert
    checkbutton $fw.invert.cb -onvalue "Yes" -offvalue "No" \
        -text "Invert Opponent Formation" \
        -variable Config::config(Online,invertOpponent)
    grid $fw.invert.cb -sticky w -padx 3

    # Toggle for showing the card view upon start-up
    frame $fw.showViewer
    checkbutton $fw.showViewer.cb -onvalue "Yes" -offvalue "No" \
        -text "Show Card Viewer" \
        -variable Config::config(Online,showCardView)
    grid $fw.showViewer.cb -sticky w -padx 3

    # Toggle for displaying a single card view window
    frame $fw.cardViewMode
    checkbutton $fw.cardViewMode.cb \
        -onvalue "single" -offvalue "multi" \
        -text "Single Card View Window" \
        -variable Config::config(Online,cardViewMode)
    grid $fw.cardViewMode.cb -sticky w -padx 3

    # Toggle for showing the card icons
    frame $fw.showIcon
    checkbutton $fw.showIcon.cb -onvalue "Yes" -offvalue "No" \
        -text "Show Card Icons" \
        -variable Config::config(Online,showIcon)
    grid $fw.showIcon.cb -sticky w -padx 3

    # Toggle for showing the card type headers
    frame $fw.showHeaders
    checkbutton $fw.showHeaders.cb -onvalue "Yes" -offvalue "No" \
        -text "Show Card Type Headers in Hand" \
        -variable Config::config(Online,showCardTypeHeaders)
    grid $fw.showHeaders.cb -sticky w -padx 3

    # Toggle for grouping champions
    frame $fw.championMode
    checkbutton $fw.championMode.cb \
        -onvalue "Champion" -offvalue "Class" \
        -text "Group Champions in Hand" \
        -variable Config::config(Online,championMode)
    grid $fw.championMode.cb -sticky w -padx 3

    grid $fw.invert       -pady 3 -padx 3 -sticky w
    grid $fw.showViewer   -pady 0 -padx 3 -sticky w
    grid $fw.cardViewMode -pady 3 -padx 3 -sticky w
    grid $fw.showIcon     -pady 0 -padx 3 -sticky w
    grid $fw.showHeaders  -pady 3 -padx 3 -sticky w
    grid $fw.championMode -pady 0 -padx 3 -sticky w

    # All the various label background colors
    set yPad 3
    foreach {lName vName} {
        {Normal Realm} realm,unrazed
        {Razed Realm}  realm,razed
        {Hidden Realm} realm,hide
        Dungeon dungeon
        Rule    rule
        Holding holding
    } {
        set cfw [frame $fw.color$vName]
        label $cfw.l -width 20 -anchor w \
            -text "$lName Color"
        set configW(label,$vName) $cfw.l
        UpdateLabelColor $vName
        button $cfw.fg -text "Foreground..." \
            -command "Config::ChangeLabelColor [list $lName] $vName 1"
        button $cfw.bg -text "Background..." \
            -command "Config::ChangeLabelColor [list $lName] $vName"
        grid $cfw.l $cfw.fg $cfw.bg -sticky ew -padx 3

        grid $cfw -pady $yPad -padx 3 -sticky w
        set yPad [expr 3 - $yPad]
    }

    grid columnconfigure $fw 0 -weight 1
    grid rowconfigure $fw 12 -weight 1

    return $fw
}

# Config::ChangeLabelColor --
#
#   Allows the user to select a new background color for a label.
#
# Parameters:
#   name      : Display name
#   which     : Which label to change
#
# Returns:
#   Nothing.
#
proc Config::ChangeLabelColor {name which {fg 0}} {

    variable config
    variable configW

    if {$fg} {
        set g "Foreground"
        set v "Online,color,${which}FG"
    } else {
        set g "Background"
        set v "Online,color,$which"
    }

    set newColor \
        [tk_chooseColor -title "Select New $name $g Color" \
             -parent $configW(top) \
             -initialcolor $config($v)]

    if {$newColor != ""} {
        set config($v) $newColor
        UpdateLabelColor $which
    }

    return
}

# Config::UpdateLabelColor --
#
#   Updates the label widget background with the new color.
#
# Parameters:
#   which     : Which label to update
#
# Returns:
#   Nothing.
#
proc Config::UpdateLabelColor {which} {

    variable config
    variable configW

    $configW(label,$which) configure \
        -background $config(Online,color,$which) \
        -foreground $config(Online,color,${which}FG)

    return
}

# Config::CreateLinux --
#
#   Options for Unix/Linux machines.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::CreateLinux {} {

    variable config
    variable configW

    set fw [frame $configW(optFrame).optLinux -relief raised -borderwidth 1]

    # Web Browser selection
    frame $fw.browser
    label $fw.browser.l -text "Web Browser:" -width 14 -anchor e
    entry $fw.browser.e -textvariable Config::config(Linux,webBrowser) \
        -width 25
    button $fw.browser.b -text "Select..." \
        -command "Config::SelectFile Linux,webBrowser all"
    grid $fw.browser.l $fw.browser.e $fw.browser.b -sticky ew -padx 3
    grid columnconfigure $fw.browser 1 -weight 1

    # Print command entry
    frame $fw.lpr
    label $fw.lpr.l -text "Print Command:" -width 14 -anchor e
    entry $fw.lpr.e -textvariable Config::config(Linux,lpr) \
        -width 25
    button $fw.lpr.b -text "Select..." \
        -command "Config::SelectFile Linux,lpr all"
    grid $fw.lpr.l $fw.lpr.e $fw.lpr.b -sticky ew -padx 3
    grid columnconfigure $fw.lpr 1 -weight 1

    # How to play a sound
    frame $fw.playSound
    if {$::snackPackage == "No"} {
        label $fw.playSound.l -text "Audio Command:" -width 14 -anchor e
        entry $fw.playSound.e -textvariable Config::config(Linux,playSound) \
            -width 25
        grid $fw.playSound.l $fw.playSound.e -sticky nsew -padx 3
        grid columnconfigure $fw.playSound 1 -weight 1
    }

    grid $fw.browser   -pady 3 -padx 5 -sticky ew
    grid $fw.lpr       -pady 3 -padx 5 -sticky new
    grid $fw.playSound -pady 3 -padx 5 -sticky new

    grid columnconfigure $fw 0 -weight 1
    grid rowconfigure $fw 2 -weight 1

    return $fw
}

# Config::CreateWindows --
#
#   Options for Windows machines.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::CreateWindows {} {

    variable config
    variable configW

    set fw [frame $configW(optFrame).optWindows -relief raised -borderwidth 1]

    label $fw.l -text "Windows Explorer Auto-File Associations:"
    grid $fw.l -sticky w -padx 5 -pady 3
    foreach {ext title} {
        cfc Combo
        cfd Deck
        cfi Inventory
        cfl ChatLog
        cft Trade
        cff Format
    } {
        frame $fw.$ext
        label $fw.$ext.l -text "$title ($ext):" -anchor e -width 18
        label $fw.$ext.l2 -background white -foreground black \
            -textvariable Config::config(Windows,bind,.$ext)
        set configW(Windows,bind,$ext) $fw.$ext.l2
        if {$config(Windows,bind,.$ext) != "CrossFire${title}File"} {
            $fw.$ext.l2 configure -foreground red
        }
        button $fw.$ext.b -text "Associate" \
            -command "Config::AssociateFileType $ext $title"
        grid $fw.$ext.l  -row 0 -column 0
        grid $fw.$ext.l2 -row 0 -column 1 -sticky ew -padx 5
        grid $fw.$ext.b  -row 0 -column 2
        grid columnconfigure $fw.$ext 1 -weight 1

        grid $fw.$ext -sticky ew -padx 5 -pady 3
    }

    grid columnconfigure $fw 0 -weight 1
    grid rowconfigure $fw 7 -weight 1

    return $fw
}

# Config::AssociateFileType --
#
#   Verifies action with user.  Calls the registry command to update
#   a file association.
#
# Parameters:
#   ext        : Extension of the file type
#   which      : Name of the type
#
# Returns:
#   Nothing.
#
proc Config::AssociateFileType {ext which} {

    variable config
    variable configW

    set response "yes"
    if {$config(Windows,bind,.$ext) != "CrossFire${which}File"} {
        set msg "This will override the previously assigned file association "
        append msg "and change it to run CrossFire.  This cannot be undone "
        append msg "with CrossFire.  Are you sure you want to do this?"
        set response [tk_messageBox -icon question -message $msg \
                          -title "Caution Young Padawan!" -type yesno]
    }

    if {$response == "yes"} {
        Registry::AssociateFileType ".$ext" 1
        $configW(Windows,bind,$ext) configure -foreground black
    }

    return
}

# Config::UpdateSetList --
#
#   Updates the list of card sets. Activated when one
#   of the selection list boxes is clicked on.
#
# Parameters:
#   lbw        : Widget name of the listbox.
#   which      : Textual name (editor, inv, swapShop, searcher).
#
# Returns:
#   Nothing.
#
proc Config::UpdateSetList {which} {

    variable config
    variable configW

    set lbw $configW(CSLB,$which)
    set tempSetList {}
    foreach lbIndex [$lbw curselection] {
        set setName [$lbw get $lbIndex]
        lappend tempSetList $CrossFire::setXRef($setName)
    }

    if {$which == "editor"} {
        set config(DeckIt,setIDList) $tempSetList
    } elseif {$which == "inv"} {
        set config(Warehouse,setIDList) $tempSetList
    } elseif {$which == "swapShop"} {
        set config(SwapShop,setIDList) $tempSetList
    } elseif {$which == "searcher"} {
        set config(Searcher,setIDList) $tempSetList
    } elseif {$which == "comboMan"} {
        set config(ComboMan,setIDList) $tempSetList
    } elseif {$which == "viewCard"} {
        set config(ViewCard,setIDList) $tempSetList
    } else {
        bell
    }

    return
}

# Config::ChangeProcess --
#
#   Called when the process selection is changed. Sets the namespace
#   variable and updates the screen with the new frame of options.
#
# Parameters:
#   args       : Name of the process changing to.
#
# Returns:
#   Nothing.
#
proc Config::ChangeProcess {args} {

    variable config
    variable configW

    set lb $configW(processSelBox)
    if {$args == ""} {
        # Clicked the listbox process selection.
        set args [$lb get [$lb curselection]]
    } else {
        # Update the listbox to highlight the requested process
        $lb selection clear 0 end
        $lb selection set $configW(processIndex,$args)
    }

    set configW(process) $args

    foreach {name x x key} $configW(processList) {
	if {$args == $name} {
	    set groupKey $key
	}
    }

    # Update the viewed set of options
    set w $configW(optFrame).opt$groupKey
    grid forget [grid slaves $configW(optFrame)]
    grid $w -sticky nsew -row 0 -column 0

    # Change the title
    wm title $configW(top) "Configure - $args"

    return
}

# Config::CreateFormat --
#
#   Options for format maker.
#
# Parameters:
#   None.
#
# Returns:
#   Frame widget path
#
proc Config::CreateFormat {} {

    variable config
    variable configW

    set fw [frame $configW(optFrame).optFormat \
		-relief raised -borderwidth 1]

    # Auto save on/off and delay time.
    frame $fw.autoSave
    checkbutton $fw.autoSave.cb -variable Config::config(Format,autoSave) \
        -text "Auto Save after" -onvalue "Yes" -offvalue "No" \
        -command {
            Config::UpdateFriends Format,autoSave Yes format,saveTime
        }
    entry $fw.autoSave.e -width 3 -justify right \
        -textvariable Config::config(Format,autoSaveTime)
    set configW(format,saveTime) $fw.autoSave.e
    label $fw.autoSave.l2 -text "minute(s)"
    grid $fw.autoSave.cb $fw.autoSave.e $fw.autoSave.l2 -sticky ew -padx 3
    grid columnconfigure $fw.autoSave 1 -weight 1

    grid $fw.autoSave -pady 3 -padx 5 -sticky w

    grid columnconfigure $fw 0 -weight 1
    grid rowconfigure $fw 7 -weight 1

    Config::UpdateFriends Format,autoSave Yes format,saveTime

    return $fw
}
