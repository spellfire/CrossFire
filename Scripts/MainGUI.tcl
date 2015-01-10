# MainGUI.tcl 20051115
#
# This file contains all the procedures for the creating the main
# CrossFire window.
#
# Copyright (c) 1999-2005 Dan Curtiss. All rights reserved.
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

# CrossFire::MouseOverIcon --
#
#   Updates the help message and changes text color for text "icons".
#
# Parameters:
#   c          : Canvas command buttons are on.
#   tag        : Tag for the button.
#   msg        : Help message.
#   color      : Color to change text names to if no graphic available.
#
# Returns:
#   Nothing.
#
proc CrossFire::MouseOverIcon {c tag msg color} {

    variable config

    if {$msg != ""} {
        set config(activeTag) $tag
    } else {
	set config(activeTag) ""
    }

    if {$Config::config(Launcher,displayHelp) == "Yes"} {
        $c itemconfigure helpString -text $msg
    }

    if {[$c type $tag] == "text"} {
        $c itemconfigure $tag -fill $color
    }
    update

    return
}

# CrossFire::BeginPress --
#
#   Called when the user presses mouse button 1 on a button.
#
# Parameters:
#   c          : Canvas the buttons are on.
#   tag        : Tag for the button.
#   cmd        : Command to execute.
#
# Returns:
#   Nothing.
#
proc CrossFire::BeginPress {c tag cmd} {

    variable config

    set config(launchTag) $tag
    set config(launchCommand) $cmd

    $c move $tag 2 2
    update

    return
}

# CrossFire::EndPress --
#
#   Called when the user releases mouse button 1.  If still over the original
#   button on the GUI, it will be launched.
#
# Parameters:
#   c          : Canvas the buttons are on.
#
# Returns:
#   Nothing.
#
proc CrossFire::EndPress {c} {

    variable config

    if {$config(launchTag) == $config(activeTag)} {
        $c configure -cursor watch
        update
        eval $config(launchCommand)
        $c configure -cursor {}
    }

    set tag $config(launchTag)
    $c coords $tag $config(position,X,$tag) $config(position,Y,$tag)

    return
}

# CrossFire::ReadSkinConfig --
#
#   Reads a skin configuration file for placement of icons, help bar,
#   and size of main window.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc CrossFire::ReadSkinConfig {} {

    variable config

    set iconSet $Config::config(Launcher,iconSet)
    set skinConfig [file join $CrossFire::homeDir "Graphics" \
                        $iconSet "$iconSet.cfs"]

    foreach index [array names config "Skin,*"] {
        unset config($index)
    }

    if {[file exists $skinConfig] == 0} {
        return
    }

    set fid [open $skinConfig "r"]
    while {![eof $fid]} {
        gets $fid line
        foreach {bName params} $line break
        if {($params != "") && ([regexp "^#" $bName] == 0)} {
            foreach dataPair $params {
                foreach {var data} $dataPair break
                set config(Skin,$var,$bName) $data
            }
        }
    }
    close $fid

    return
}

# CrossFire::MakeButton --
#
#   Create a "button" for a command on the main CrossFire screen.
#
# Parameters:
#   fw         : Frame widget name that buttons are packed in to.
#   name       : Process Name.
#
# Returns:
#   Nothing.
#
proc CrossFire::MakeButton {fw name} {

    variable config
    variable XFprocess

    set bName $XFprocess(graphic,$name)
    set command "CrossFire::PlaySound DO$bName; $XFprocess(command,$name)"

    if {[info exists config(Skin,Show,$bName)]} {
        set show $config(Skin,Show,$bName)
    } else {
        set show ""
    }

    # Check if we should place the icon.
    if {($show == "No") ||
        (($show == "") &&
         ([lsearch $Config::config(Launcher,showIcon) $name] == -1))} {
        return
    }

    if {$Config::config(Launcher,menuType) == "Graphical"} {

        set gifFile \
            [file join $CrossFire::homeDir "Graphics" \
                 $Config::config(Launcher,iconSet) "${bName}.gif"]
        if {[file exists $gifFile] == 0} {
            set gifFile [file join $CrossFire::homeDir "Graphics" \
                             "XFire" "${bName}.gif"]
        }

        if {[file exists $gifFile]} {
            image create photo gf$bName -file $gifFile

            # Check skin data for X and Y coords.  If the data does
            # not exist, use the default location.
            if {[info exists config(Skin,X,$bName)]} {
                set X $config(Skin,X,$bName)
            } else {
                set X $config(buttonX)
            }
            if {[info exists config(Skin,Y,$bName)]} {
                set Y $config(Skin,Y,$bName)
            } else {
                set Y $config(buttonY)
            }

            $fw create image $X $Y -image gf$bName -anchor nw \
                -tags tag$bName
            set config(position,X,tag$bName) $X
            set config(position,Y,tag$bName) $Y
        } else {
            $fw create text $config(buttonX) $config(buttonSpacing) \
                -text $bName -anchor nw -tags tag$bName
            set config(position,X,tag$bName) $config(buttonX)
            set config(position,Y,tag$bName) $config(buttonSpacing)
        }

        foreach {x1 y1 x2 y2} [$fw bbox tag$bName] {
            set bWidth [expr $x2 - $x1]
            set bHeight [expr $y2 - $y1]
        }

        if {![info exists config(Skin,X,$bName)]} {
            set config(buttonX) \
                [expr $config(buttonX) + $config(buttonSpacing) + $bWidth]
            if {$bHeight > $config(maxHeight)} {
                set config(maxHeight) $bHeight
            }
        }

	if {$XFprocess(mlkey,$name) != ""} {
	    set msg [ML::str $XFprocess(mlkey,$name)]
	} else {
	    set msg $name
	}

	set enterCmd "CrossFire::MouseOverIcon $fw tag$bName [list $msg] red"
        $fw bind tag$bName <Enter> $enterCmd
        $fw bind tag$bName <Leave> \
            "CrossFire::MouseOverIcon $fw tag$bName {} black"

	# To fix a problem on Linux, the enterCmd is reissued when the user
	# presses a "button".  This provides the expected behavior. :)
        $fw bind tag$bName <ButtonPress-1> \
            "$enterCmd; CrossFire::BeginPress $fw tag$bName [list $command]"
        $fw bind tag$bName <ButtonRelease-1> \
            "CrossFire::EndPress $fw"
        $fw bind tag$bName <Double-Button-1> break
        $fw bind tag$bName <Triple-Button-1> break

    } else {

        set bw $fw.$bName

        # Create text main menu button
        label $bw -text $name -foreground $config(inactiveCommand) \
            -font {Times 14} -background $config(backGround)

        bind $bw <ButtonRelease-1> $command
        pack $bw -padx 5

        bind $bw <Enter> "$bw configure -foreground $config(activeCommand)"
        bind $bw <Leave> \
            "$bw configure -foreground $config(inactiveCommand)"

        # multi-clicking could cause some problems
        bind $bw <Double-Button-1> break
        bind $bw <Triple-Button-1> break
    }

    return
}

# CrossFire::Create --
#
#   Creates the CrossFire main screen.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc CrossFire::Create {} {

    variable crossFireVersion
    variable config
    variable platform
    variable XFprocess

    set config(activeCommand) red
    set config(inactiveCommand) black
    ReadSkinConfig

    if {[info exists config(Skin,Spacing,default)]} {
        set config(buttonSpacing) $config(Skin,Spacing,default)
    } else {
        set config(buttonSpacing) 8
    }

    if {[info exists config(Skin,X,default)]} {
        set config(buttonX) $config(Skin,X,default)
    } else {
        set config(buttonX) $config(buttonSpacing)
    }

    if {[info exists config(Skin,Y,default)]} {
        set config(buttonY) $config(Skin,Y,default)
    } else {
        set config(buttonY) 8
    }

    set config(maxHeight) 0
    set config(launchTag) "none"

    if {$Config::config(Launcher,menuType) == "Text"} {
        set config(backGround) grey
    } else {
        set config(backGround) [. cget -background]
    }

    set w .crossFire
    set config(top) $w

    # Save the window location, so it doesn't move around the screen
    if {[winfo exists $w]} {
        regsub "\[0-9\]*x\[0-9\]*" [wm geometry $w] "" geometry
        destroy $w
        update
    }

    # Create new toplevel.
    toplevel $w -background $config(backGround)
    wm withdraw $w
    if {[info exists geometry]} {
        PlaceWindow $w $geometry
        set needToPlace 0
    } else {
        set needToPlace 1
    }

    UpdateWindowTitle

    # Trap closing window from window manager methods.
    wm protocol $w WM_DELETE_WINDOW CrossFire::Exit

    AddMenuBar $w

    if {$Config::config(Launcher,menuType) == "Text"} {
        label $w.title -text "CrossFire" -font {Times 28 bold} \
            -foreground white -background $config(backGround)
        pack $w.title -padx 5 -pady 5
        frame $w.buttons -background $config(backGround)
    } else {
        canvas $w.buttons
    }

#    if {($Config::config(Launcher,showIcon) == "") &&
#        ($Config::config(Launcher,menuType) == "Graphical")} {
#        set Config::config(Launcher,showIcon) {Configure}
#    }

    foreach process $XFprocess(list) {
        MakeButton $w.buttons $process
    }
    pack $w.buttons

    if {$Config::config(Launcher,menuType) == "Graphical"} {

        set canvasHeight \
            [expr $config(maxHeight) + $config(buttonSpacing) * 2]
        if {([info exists config(Skin,Y,main)] == 1) &&
            ($config(Skin,Y,main) > $canvasHeight)} {
            set canvasHeight $config(Skin,Y,main)
        }

        set canvasWidth $config(buttonX)
        if {([info exists config(Skin,X,main)] == 1) &&
            ($config(Skin,X,main) > $config(buttonX))} {
            set canvasWidth $config(Skin,X,main)
        }

        # Place the mouse over help
        if {$Config::config(Launcher,displayHelp) == "Yes"} {
            if {[info exists config(Skin,X,helpString)]} {
                set X $config(Skin,X,helpString)
            } else {
                set X [expr $config(buttonX) / 2]
            }
            if {[info exists config(Skin,Y,helpString)]} {
                set Y $config(Skin,Y,helpString)
            } else {
                set Y $canvasHeight
            }
            if {[info exists config(Skin,Color,helpString)]} {
                set helpColor $config(Skin,Color,helpString)
            } else {
                set helpColor black
            }
            $w.buttons create text $X $Y -tags helpString -anchor n \
                -fill $helpColor
            $w.buttons itemconfigure helpString \
                -font "[$w.buttons itemcget helpString -font] 14 bold"

            if {![info exists config(Skin,Y,helpString)]} {
                # Add Height of text string if not placed by skin
                foreach {x1 y1 x2 y2} [$w.buttons bbox helpString] break
                incr canvasHeight [expr $y2 - $y1 + 2]
            }
        }

        $w.buttons configure -width $canvasWidth -height $canvasHeight

        # Load the background image if it is there.
        set gifFile \
            [file join $CrossFire::homeDir "Graphics" \
                 $Config::config(Launcher,iconSet) "background.gif"]
        if {[file exists $gifFile] == 0} {
            set gifFile [file join $CrossFire::homeDir "Graphics" \
                             "XFire" "background.gif"]
        }

        # Put the background image on the canvas. Tile if necessary.
        if {($Config::config(Launcher,displayBackGround) == "Yes") &&
            ([file exists $gifFile] == 1)} {
            image create photo imgBackGround -file $gifFile
            set bgW [image width imgBackGround]
            set bgH [image height imgBackGround]
            for {set x 0} {$x < $canvasWidth} {incr x $bgW} {
                for {set y 0} {$y < $canvasHeight} {incr y $bgH} {
                    $w.buttons create image $x $y -image imgBackGround \
                        -anchor nw -tags background
                }
            }
            $w.buttons lower background
        }

    }
    update

    if {$needToPlace} {
        PlaceWindow $w $Config::config(CrossFire,windowPosition)
    }

    bind $w "dev" {
	set ::developer [expr 1 - $::developer]
	CrossFire::UpdateWindowTitle
    }

    bind $w "debug" {
        set ::debug [expr 1 - $::debug]
	CrossFire::UpdateWindowTitle
    }

    bind $w "demo" PanedWindow::Demo

    bind $w "die" exit
    bind $w "exit" exit
    bind $w "quit" exit
    bind $w "doh" ThrowAnError

    update
    if {$Config::config(Launcher,menuType) == "Graphical"} {
        wm resizable $w 0 0
    } else {
        wm resizable $w 1 1
    }
    wm deiconify $w
    raise $w
    focus $w

    return
}

# CrossFire::UpdateWindowTitle --
#
#   Updates the main window's title to reflect developer and debug settings.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc CrossFire::UpdateWindowTitle {} {

    variable config
    variable crossFireVersion

    set t "CrossFire: $crossFireVersion"

    if {$::developer == 1} {
	append t " DEV"
    }
    if {$::debug == 1} {
	append t " DEBUG"
    }

    wm title $config(top) $t

    return
}

# CrossFire::AddMenuBar --
#
#   Creates the menubar for the CrossFire menu and sets up the
#   accelerator key bindings for the commands.
#
# Parameters:
#   w          : Toplevel of the CrossFire window.
#
# Returns:
#   Nothing.
#
proc CrossFire::AddMenuBar {w} {

    menu $w.menubar

    $w.menubar add cascade \
        -label "CrossFire" \
        -underline 0 \
        -menu $w.menubar.window

    menu $w.menubar.window -tearoff 0
    $w.menubar.window add command \
        -label "[ML::str ss,windowName]..." \
        -command "Searcher::Create" \
        -accelerator "$CrossFire::accelKey+U" \
        -underline 0
    $w.menubar.window add command \
        -label "DeckIt! Deck Editor..." \
        -command "Editor::Create" \
        -accelerator "$CrossFire::accelKey+D" \
        -underline 0
    $w.menubar.window add command \
        -label "Card Warehouse..." \
        -command "Inventory::Create" \
        -accelerator "$CrossFire::accelKey+W" \
        -underline 5
    $w.menubar.window add command \
        -label "Swap Shop..." \
        -command "SwapShop::Create" \
        -accelerator "$CrossFire::accelKey+S" \
        -underline 0
    $w.menubar.window add command \
        -label "Solitaire Game..." \
        -command "Game::Solitaire" \
        -accelerator "$CrossFire::accelKey+G" \
        -underline 10
    $w.menubar.window add command \
        -label "Fan Set Editor..." \
        -command "EditCard::Create" \
        -accelerator "$CrossFire::accelKey+F" \
        -underline 0
    $w.menubar.window add command \
        -label "ComboMan..." \
        -command "Combo::Create" \
        -accelerator "$CrossFire::accelKey+M" \
        -underline 5
    $w.menubar.window add command \
        -label "Online Chat..." \
        -command "Chat::Login" \
        -accelerator "$CrossFire::accelKey+H" \
        -underline 8
    $w.menubar.window add separator

    set exitLabel [ML::str close]
    set exitAccelerator "Alt+F4"
    if {$CrossFire::platform == "macintosh"} {
        # This is a Macintosh, so make the exit
        # accelerator more "Mac-ish"
        set exitLabel [ML::str quit]
        set exitAccelerator "Command+Q"
    }
    $w.menubar.window add command \
        -label $exitLabel \
        -command CrossFire::Exit \
        -underline 1 \
        -accelerator $exitAccelerator

    $w.menubar add cascade \
        -label "Utilities" \
        -underline 0 \
        -menu $w.menubar.util

    menu $w.menubar.util -tearoff 0
    $w.menubar.util add command \
        -label "[ML::str cv,windowName]..." \
        -command "ViewCard::Viewer" \
        -accelerator "$CrossFire::accelKey+V" \
        -underline 5
    $w.menubar.util add command \
        -label "Combo Viewer..." \
        -accelerator "$CrossFire::accelKey+I" \
        -command "Combo::Viewer" \
        -underline 7
    $w.menubar.util add command \
        -label "Chat Log Viewer..." \
        -accelerator "$CrossFire::accelKey+L" \
        -command "Chat::CreateLogViewer" \
        -underline 5
    $w.menubar.util add separator
    $w.menubar.util add command \
        -label "Deck Format Maker..." \
        -accelerator "$CrossFire::accelKey+T" \
        -command "FormatIt::Create" \
        -underline 10
    $w.menubar.util add separator
    $w.menubar.util add command \
        -label "Backup Files..." \
        -accelerator "$CrossFire::accelKey+B" \
        -command "BackUp::BackUp" \
        -underline 0
    $w.menubar.util add command \
        -label "Restore Files..." \
        -accelerator "$CrossFire::accelKey+R" \
        -command "BackUp::Restore" \
        -underline 0
    $w.menubar.util add separator
    $w.menubar.util add command \
        -label "[ML::str configure]..." \
        -command "Config::Create CrossFire" \
        -accelerator "$CrossFire::accelKey+O" \
        -underline 1

    $w.menubar add cascade \
        -label [ML::str help] \
        -underline 0 \
        -menu $w.menubar.help

    menu $w.menubar.help -tearoff 0
    $w.menubar.help add command \
        -label "[ML::str help]..." \
        -command "CrossFire::Help cf_main.html" \
        -accelerator "F1" \
        -underline 0
    $w.menubar.help add separator
    $w.menubar.help add command \
        -label "Tip of the Day..." \
        -command "Tip::Create"
    $w.menubar.help add separator
    $w.menubar.help add command \
        -label "About CrossFire..." \
        -command CrossFire::About \
        -accelerator "$CrossFire::accelKey+A" \
        -underline 0

    $w config -menu $w.menubar

    # CrossFire menu bindings.
    bind $w <$CrossFire::accelBind-v> "ViewCard::Viewer"
    bind $w <$CrossFire::accelBind-u> "Searcher::Create"
    bind $w <$CrossFire::accelBind-d> "Editor::Create"
    bind $w <$CrossFire::accelBind-w> "Inventory::Create"
    bind $w <$CrossFire::accelBind-s> "SwapShop::Create"
    bind $w <$CrossFire::accelBind-g> "Game::Solitaire"
    bind $w <$CrossFire::accelBind-f> "EditCard::Create"
    bind $w <$CrossFire::accelBind-m> "Combo::Create"
    bind $w <$CrossFire::accelBind-h> "Chat::Login"

    if {$CrossFire::platform == "macintosh"} {
        bind $w <Command-q> CrossFire::Exit
    } else {
        bind $w <Alt-F4> "CrossFire::Exit; break"
        bind $w <Meta-x> "CrossFire::Exit"
    }

    # Utilities menu bindings
    bind $w <$CrossFire::accelBind-b> "BackUp::BackUp"
    bind $w <$CrossFire::accelBind-r> "BackUp::Restore"
    bind $w <$CrossFire::accelBind-t> "FormatIt::Create"
    bind $w <$CrossFire::accelBind-l> "Chat::CreateLogViewer"
    bind $w <$CrossFire::accelBind-i> "Combo::Viewer"
    bind $w <$CrossFire::accelBind-o> "Config::Create CrossFire"

    # Help menu bindings
    bind $w <Key-F1> "CrossFire::Help cf_main.html"
    bind $w <Key-Help> "CrossFire::Help cf_main.html"
    bind $w <$CrossFire::accelBind-a> "CrossFire::About"

    return
}

# CrossFire::Exit --
#
#   Gracefully exits CrossFire. Calls Exit proc for each child.
#   If any return a non-zero, CrossFire will not exit.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc CrossFire::Exit {} {

    variable toplevelReg

    set result 0

    foreach {key procName} {
        DeckIt     Editor::ExitEditor
        Warehouse  Inventory::ExitInv
        SwapShop   SwapShop::ExitSwapShop
        ComboMan   Combo::ExitCombo
        CardEditor EditCard::ExitEditCard
        Chat       Chat::ExitChat
        Format     FormatIt::ExitEditor
    } {
        if {[info exists toplevelReg($key)]} {
            foreach child $toplevelReg($key) {
                if {$result == 0} {
                    set result [$procName $child]
                }
            }
        }
    }

    if {$result == 0} {
        Config::SaveOptions
        PlaySound CFStop
        exit
    }

    return
}

# CrossFire::About --
#
#   Creates the CrossFire about screen.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc CrossFire::About {} {

    variable config
    variable crossFireVersion

    set w .about

    if {[winfo exists $w]} {
        raise $w
        wm deiconify $w
        return
    }

    # Create new toplevel.
    toplevel $w -background $config(backGround)
    wm title $w "About CrossFire"

    frame $w.info -borderwidth 1 -relief raised \
        -background $config(backGround)
    label $w.info.title -text "CrossFire" \
        -font {Times 24 bold} -foreground white \
        -background $config(backGround)
    label $w.info.cfVersion -text $crossFireVersion \
        -font {Times 14 bold} -foreground blue \
        -background $config(backGround)
    label $w.info.tclVersion -foreground white \
        -text "Tcl/Tk: $::tcl_patchLevel" -background $config(backGround)
    text $w.info.t -relief flat -borderwidth 0 -cursor {} \
        -font {Courier 10} -width 50 -height 9 \
        -foreground black -background $config(backGround)
    $w.info.t tag configure center -justify center
    $w.info.t tag configure url -foreground blue -underline 1
    set homePage "http://crossfire.spellfire.net/"
    $w.info.t tag bind url <Enter> "$w.info.t configure -cursor hand2"
    $w.info.t tag bind url <Leave> "$w.info.t configure -cursor {}"
    $w.info.t tag bind url <ButtonRelease-1> \
        "CrossFire::OpenURL $homePage"
    $w.info.t insert end "Written by\n" center \
        "Dan Curtiss\n" center \
        "Steve Brazelton\n" center \
        "Stephen Thompson\n\n" center \
        "crossfire@spellfire.net\n\n" center \
        $homePage {url center}
    $w.info.t config -state disabled
    pack $w.info.title $w.info.cfVersion $w.info.tclVersion $w.info.t \
        -pady 5 -padx 5

    frame $w.buttons -borderwidth 1 -relief raised \
        -background $config(backGround)
    button $w.buttons.close -text $CrossFire::close \
        -command "destroy $w" -foreground black \
        -background $config(backGround)
    pack $w.buttons.close -pady 5

    pack $w.info -expand 1 -fill both
    pack $w.buttons -fill x

    # Centers the about window.
    wm withdraw $w
    update
    PlaceWindow $w center
    update
    wm deiconify $w

    return
}

