# Config.tcl 20060106
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

namespace eval Config {

    # Array to hold all the configuration options.
    variable config
    variable configW
    variable configDef
    variable configFile ""

    set configW(processList) {
        {Back Up}        B 0 BackUp
        Chat             C 0 Chat
        ComboMan         M 5 ComboMan
        CrossFire        X 0 CrossFire
        DeckIt           D 0 DeckIt
        {Format Maker}   R 2 Format
        {Fan Set Editor} F 0 FanSetEditor
        Launcher         L 0 Launcher
        {Online Play}    O 0 Online
        {Printing Cards} P 0 Print
        {Swap Shop}      S 0 SwapShop
        Sounds           N 3 Sound
	Tooltips         T 0 Tooltips
        {Ultra Searcher} U 0 Searcher
        {Viewing Cards}  V 0 ViewCard
        Warehouse        W 0 Warehouse
    }

    if {($CrossFire::platform == "unix") || ($::developer == 1)} {
        append configW(processList) {
            Linux I 1 Linux
        }
    }
    if {($Registry::useRegistry == 1) || ($::developer == 1)} {
        append configW(processList) {
            Windows I 1 Windows
        }
    }

    # Sound extension list
    if {$::snackPackage == "Yes"} {
        set configW(soundExtList) {.mp3 .ogg .wav .au .aiff}
    } else {
        set configW(soundExtList) {.wav}
    }

    #
    # Configure default
    #
    set configW(process) "CrossFire"

    #
    # BackUp and Restore defaults.
    #
    set config(BackUp,dir) [file join $CrossFire::homeDir "BackUp"]
    set config(BackUp,auto) "No"
    set config(BackUp,autoDays) 7
    set config(BackUp,lastBackUp) \
	[clock format [clock seconds] -format "%m/%d/%Y"]
    set config(BackUp,autoPrompt) "Yes"

    #
    # Tooltips Help defaults
    #
    set config(Tooltips,mode) "On"
    set config(Tooltips,delay) 0.5
    set config(Tooltips,autoHide) "Off"
    set config(Tooltips,autoHideDelay) 4

    #
    # Chat defaults.
    #
    set config(Chat,userName) ""
    set config(Chat,password) ""
    set config(Chat,userNoteWidth) 50
    set config(Chat,userNoteCC) "No"
    set config(Chat,logDir) [file join $CrossFire::homeDir "ChatLogs"]
    set config(Chat,logFile) [file join $config(Chat,logDir) "default.cfl"]
    set config(Chat,autoLog) "Yes"
    set config(Chat,autoLogIn) "No"
    set config(Chat,actionFile) \
        [file join $CrossFire::homeDir "Scripts" "Actions.cfa"]
    set config(Chat,foreground) "black"
    set config(Chat,background) "white"
    set config(Chat,newChampion) "red"
    set config(Chat,urlColor) "blue"
    set config(Chat,arriveAlert) 1
    set config(Chat,leaveAlert) 1
    set config(Chat,timeStamp) 0
    set config(Chat,timeMode) 24
    set config(Chat,geometry) "450x350+20+20"
    set config(Chat,chatPane) 0.70
    set config(Chat,realmPane) 0.30
    set config(Chat,expandedView) "Yes"
    set config(Chat,useIMs) "Yes"
    # It would be nice if [option get ...] would return defaults from the
    # database to avoid creating a widget to destroy!
    text .temp
    set config(Chat,font) [lindex [.temp configure -font] 3]
    destroy .temp

    # Chat profile
    set config(Chat,profile,user) ""
    set config(Chat,profile,name) ""
    set config(Chat,profile,location) ""
    set config(Chat,profile,email) ""
    set config(Chat,profile,web) ""
    set config(Chat,profile,info) ""
    set config(Chat,progile,imageURL) ""
    set config(Chat,profile,champion) "Random"
    set config(Chat,profile,level) ""
    set config(Chat,profile,logon) "enters CrossFire chat"
    set config(Chat,profile,logoff) "has left CrossFire chat"
    set config(Chat,profile,enter) ""
    set config(Chat,profile,leave) ""
    set config(Chat,profile,home) "Main"
    set config(Chat,lastProfileChange) ""
    # More options for Chat in AddDefaultCrossFireServer below

    #
    # ComboMan defaults.
    #
    set config(ComboMan,dir) [file join $CrossFire::homeDir "Combos"]
    set config(ComboMan,setIDList) \
        [list 1st 3rd 4th PR RL DL FR AR PO UD RR BR DR NS DU IQ MI CH CQ]
    set config(ComboMan,autoSave) "Yes"
    set config(ComboMan,autoSaveTime) 5
    set config(ComboMan,recent) {}
    set config(ComboMan,printCardText) "Yes"
    set config(ComboMan,embedCardView) "Yes"
    set config(ComboMan,embedCardViewV) "Yes"

    #
    # CrossFire Options
    #
    set config(CrossFire,showSplashScreen) "Yes"
    set config(CrossFire,authorName) ""
    set config(CrossFire,authorEmail) ""
    set config(CrossFire,windowPosition) "+30+30"
    set config(CrossFire,showTips) "Yes"
    set config(CrossFire,shownTips) {}
    set config(CrossFire,listBoxFG) "black"
    set config(CrossFire,listBoxBG) "white"
    set config(CrossFire,listBoxSelectBG) "blue"
    set config(CrossFire,listBoxSelectFG) "white"
    set config(CrossFire,memoryMode) "Small"
    if {$CrossFire::platform == "unix"} {
        set config(CrossFire,transient) "Yes"
    } else {
        set config(CrossFire,transient) "No"
    }
    set config(CrossFire,serverMode) "Single"
    set config(CrossFire,language) "English"
    set config(CrossFire,autoResize) 0
    set config(CrossFire,showGrip) "y"

    #
    # DeckIt! Options
    #
    set config(DeckIt,dir) [file join $CrossFire::homeDir "Decks"]
    set config(DeckIt,deckSize) 55
    set config(DeckIt,printCardText) "No"
    set config(DeckIt,deckDisplayMode) "Type"
    set config(DeckIt,setIDList) \
        [list 1st 3rd 4th PR RL DL FR AR PO UD RR BR DR NS DU IQ MI CH CQ]
    set config(DeckIt,startSetID) "1st"
    set config(DeckIt,autoSave) "Yes"
    set config(DeckIt,autoSaveTime) 5
    set config(DeckIt,recent) {}
    set config(DeckIt,championMode) "Class"
    set config(DeckIt,embedCardView) "Yes"
    set config(DeckIt,selectSash) 0.2
    set config(DeckIt,deckSash) 0.6
    set config(DeckIt,geometry) ""
    set config(DeckIt,showIcon) "No"

    #
    # Format Maker defaults.
    #
    set config(Format,autoSave) "Yes"
    set config(Format,autoSaveTime) 5
    set config(Format,recent) {}

    #
    # Fan Set Editor defaults.
    #
    set config(FanSetEditor,dir) [file join $CrossFire::homeDir "FanSets"]
    set config(FanSetEditor,setID) [lindex [CrossFire::CardSetIDList fan] 0]
    set config(FanSetEditor,autoSave) 1
    set config(FanSetEditor,embedCardView) "Yes"

    #
    # Launcher Options
    #
    set config(Launcher,menuType) "Graphical"
    set config(Launcher,displayBackGround) "Yes"
    set config(Launcher,displayHelp) "Yes"
    set config(Launcher,iconSet) "XFire"
    set config(Launcher,showIcon) $CrossFire::XFprocess(list)

    #
    # Linux/Unix only option defaults
    #
    set config(Linux,webBrowser) "netscape"
    set config(Linux,lpr) "lpr"
    set config(Linux,playSound) {dd if=$soundFile of=/dev/audio}

    #
    # Online Play Defaults
    #
    set config(Online,invertOpponent) "Yes"
    set config(Online,showCardView) "Yes"
    set config(Online,showCardTypeHeaders) "Yes"
    set config(Online,championMode) "Class"
    set config(Online,geometry,GameNotes) ""
    set config(Online,geometry,Panes)     ""
    set config(Online,geometry,Player)    ""
    set config(Online,geometry,OutOfPlay) ""
    set config(Online,geometry,Card)      ""
    set config(Online,cardViewMode) "multi"
    set config(Online,mainPane) 0.30
    set config(Online,handPane) 0.40
    set config(Online,formPane) 0.70
    set config(Online,showIcon) "Yes"
    set config(Online,dir) [file join $CrossFire::homeDir "Games"]
    set config(Online,color,realm,unrazed)   "#00EE00"
    set config(Online,color,realm,unrazedFG) "#000000"
    set config(Online,color,realm,razed)     "#FF0000"
    set config(Online,color,realm,razedFG)   "#000000"
    set config(Online,color,realm,hide)      "#999999"
    set config(Online,color,realm,hideFG)    "#000000"
    set config(Online,color,rule)            "#FFFF77"
    set config(Online,color,ruleFG)          "#000000"
    set config(Online,color,dungeon)         "#FFEECC"
    set config(Online,color,dungeonFG)       "#000000"
    set config(Online,color,holding)         "#99CCFF"
    set config(Online,color,holdingFG)       "#000000"

    #
    # Ultra Searcher Options
    #
    set config(Searcher,setIDList) \
        [list 1st 3rd 4th PR RL DL FR AR PO UD RR BR DR NS DU IQ MI CH CQ]
    variable searchModes
    array set searchModes {
        RE  {Regular Expression (RE)}
        +/- {Search Engine (+/-)}
    }
    set config(Searcher,searchMode) "+/-"
    set config(Searcher,embedCardView) "Yes"
    set config(Searcher,geometry,3) "600 350"
    set config(Searcher,sashLoc,3) "0.25 0.75"
    set config(Searcher,geometry,4) "850 350"
    set config(Searcher,sashLoc,4) "0.15 0.55 0.75"

    #
    # Sounds
    #
    set config(Sound,play) "Yes"
    foreach {id name} {
        StartUp    {CrossFire: Start}
        DOquit     {CrossFire: Shutdown}
	ChatLogin  {Chat: Champion Logs In}
	ChatLogout {Chat: Champion Logs Out}
        ChatRcv    {Chat: Receive Message When Window Minimized}
        DOviewer   {Launch: Card Viewer}
        DOsearcher {Launch: Ultra Searcher}
        DOdeckIt   {Launch: DeckIt!}
        DOformat   {Launch: Format Maker}
        DOcardInv  {Launch: Card Warehouse}
        DOswapShop {Launch: Swap Shop}
        DOsolGame  {Launch: Solitaire Game}
        DOcardEdit {Launch: Fan Set Editor}
        DOcomboMan {Launch: ComboMan}
        DOcomboVue {Launch: Combo Viewer}
        DOchatRoom {Launch: Online Chat}
        DOlogView  {Launch: Chat Log Viewer}
        DObackUp   {Launch: Back Up Files}
        DOrestore  {Launch: Restore Files}
        DOconfig   {Launch: Configure}
        DOhelp     {Launch: Help}
        PlayEvent  {Online Game: Play Event}
    } {
        lappend configW(Sound,nameList) $name
        set configW(Sound,$name,id) $id
        set soundFile "None"
        foreach ext $configW(soundExtList) {
             set testFile [file join $CrossFire::homeDir "Sounds" $id$ext]
             if {[file exists $testFile]} {
                 set soundFile $testFile
                 break
             }
         }
        set config(Sound,$id,file) $soundFile
    }

    set speakerFile \
        [file join $CrossFire::homeDir "Graphics" "Icons" "speaker.gif"]
    if {[file exists $speakerFile]} {
        image create photo imgSpeaker -file $speakerFile
    }
    set noSoundFile \
        [file join $CrossFire::homeDir "Graphics" "Icons" "nosound.gif"]
    if {[file exists $noSoundFile]} {
        image create photo imgNoSound -file $noSoundFile
    }

    #
    # Swap Shop defaults.
    #
    set config(SwapShop,dir) [file join $CrossFire::homeDir "Trades"]
    set config(SwapShop,setIDList) [CrossFire::CardSetIDList "real"]
    set config(SwapShop,autoSave) "Yes"
    set config(SwapShop,autoSaveTime) 5
    set config(SwapShop,recent) {}
    set config(SwapShop,reminder) "Yes"
    set config(SwapShop,tolerance) 7

    #
    # Card Viewing Options
    #
    set config(ViewCard,mode) "Single"
    set config(ViewCard,typeMode) "Icon"
    set config(ViewCard,worldMode) "Icon"
    set config(ViewCard,closeButton) "No"
    set config(ViewCard,showBluelines) "Yes"
    set config(ViewCard,showAttributes) "Yes"
    set config(ViewCard,showUsable) "No"
    set config(ViewCard,showRuleText) "No"
    set config(ViewCard,showLevel) "No"
    set config(ViewCard,setIDList) [CrossFire::CardSetIDList "all"]
    set config(ViewCard,color,blueLine) "#0000FF"
    set config(ViewCard,color,attribute) "#CC00CC"
    set config(ViewCard,color,usable) "#FF7700"

    #
    # Card Printing Options
    #
    set config(Print,showRuleText) "No"
    set config(Print,show,blueline) "Yes"
    set config(Print,show,attributes) "Yes"
    set config(Print,show,usable) "No"
    set config(Print,color,blueline) "#0000FF"
    set config(Print,color,attributes) "#CC00CC"
    set config(Print,color,usable) "#FF7700"
    set config(Print,numPerPage) 25
    set config(Print,makeIndex) "Yes"

    #
    # Warehouse Options
    #
    set config(Warehouse,invDir) [file join $CrossFire::homeDir "Inventory"]
    set config(Warehouse,reportDir) [file join $CrossFire::homeDir "Reports"]
    set config(Warehouse,defaultInv) \
        [file join $config(Warehouse,invDir) "default.cfi"]
    set config(Warehouse,setIDList) [CrossFire::CardSetIDList "real"]
    set config(Warehouse,reportFormat) "Verbose"
    set config(Warehouse,autoSave) "Yes"
    set config(Warehouse,autoSaveTime) 5
    set config(Warehouse,recent) {}
    set config(Warehouse,listDisplayMode) "normal"
    set config(Warehouse,embedCardView) "Yes"

    variable displayModes
    foreach {mode modeLabel} {
        brief     {1, 2}
        expanded  {1, 1, 2}
        normal    {1(2), 2}
        normalV   {1(2), 2(1)}
        standard  {1(2), 2(1), 3(0)}
        inventory {1-02, 2-01}
        fullinv   {1-02, 2-01, 3-00}
    } {
        lappend displayModes(list) $mode
        set displayModes($mode) $modeLabel
    }

    #
    # Windows only options
    #
    set config(Windows,bind,.cfd) "unassigned"
    set config(Windows,bind,.cfc) "unassigned"
    set config(Windows,bind,.cft) "unassigned"
    set config(Windows,bind,.cfi) "unassigned"
    set config(Windows,bind,.cfl) "unassigned"

    # Save a default setting
    foreach key [array names config] {
	if {($config($key) != "") &&
	    ([regexp "^Windows,bind," $key] == 0)} {
	    set configDef($key) $config($key)
	}
    }

}

# Config::Set --
#
#   Allows for setting of a configuration variable from outside
#   of the Config namespace.
#
# Parameters:
#   var       : Name of the variable
#   value     : Value to set to
#
# Returns:
#   Nothing.
#
proc Config::Set {var value} {

    variable config

    set config($var) $value

    return
}

# Config::LoadOptions --
#
#   Loads the options for CrossFire.  Calls LoadWin32Options on
#   Windows versions that use the Registry.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::LoadOptions {{backUp no}} {

    variable config
    variable configFile

    if {($configFile == "registry") && ($backUp == "no")} {
        LoadWin32Options
    } else {
        if {$backUp == "no"} {
            source $configFile
        } else {
            set optFile [file join $backUp "options.cfg"]
            if {[file exists $optFile] == 1} {
                source $optFile
            }
        }
    }

    foreach {dirVar dirName} {
        BackUp,dir          BackUp
        Chat,logDir         ChatLogs
        ComboMan,dir        Combos
        DeckIt,dir          Decks
	FanSetEditor,dir    FanSets
        SwapShop,dir        Trades
        Warehouse,invDir    Inventory
        Warehouse,reportDir Reports
    } {
        if {[file exists $config($dirVar)] == 0} {
            set newDir [file join $CrossFire::homeDir $dirName]
            set msg "Default $dirName directory \"$config($dirVar)\" does "
            append msg "not exist. Changed to \"$newDir\"."
            tk_messageBox -title "CrossFire Startup Error" -icon error \
                -message $msg
            set config($dirVar) $newDir
        }
    }

    # Remove unused options
    foreach oldOption {
        CrossFire,awesome
        Format,dir
        ViewCard,makeIndex
        ViewCard,numPerPage
    } {
	if {[info exists config($oldOption)]} {
	    unset config($oldOption)
	}
    }
    return
}

# Config::SaveOptions --
#
#   Updates the settings file with the current defaults.  Calls
#   SaveWin32Options on version of Windows that use the Registry.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::SaveOptions {{backUp no}} {

    variable config
    variable configFile

    # Make sure each part has a set id list
    foreach key {
        ComboMan,setIDList DeckIt,setIDList Warehouse,setIDList
        Searcher,setIDList SwapShop,setIDList
    } {
        if {$config($key) == ""} {
            set config($key) "4th"
        }
    }

    # Save the position of the main CrossFire window.
    if {[info exists CrossFire::config(top)]} {
        regsub "\[0-9\]*x\[0-9\]*" [wm geometry $CrossFire::config(top)] "" \
            config(CrossFire,windowPosition)
    }

    if {($configFile == "registry") && ($backUp == "no")} {
        SaveWin32Options
    } else {

        if {$backUp == "no"} {
            set fileID [open $configFile "w"]
        } else {
            set fileID [open [file join $backUp "options.cfg"] "w"]
        }
        puts $fileID "# Generated file -- do not edit!!\n"
        foreach index [lsort [array names config]] {
            puts $fileID "set config($index) [list $config($index)]"
        }
        close $fileID

        if {($CrossFire::platform == "macos9") && ($backUp == "no")} {
            file attributes $configFile -creator $CrossFire::macCode(creator)
        }
    }

    return
}

# Config::LoadWin32Options --
#
#   Reads the configuration from the Windows Registry.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::LoadWin32Options {} {

    variable config
    variable registryKey

    foreach index [Registry::ItemList $registryKey] {
        set config($index) [Registry::Get $registryKey $index]
    }

    return
}

# Config::SaveWin32Options --
#
#   Saves the configuration in the Windows Registry.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::SaveWin32Options {} {

    variable config
    variable registryKey

    # Remove all previously saved settings
    Registry::Delete $registryKey

    # Write out all the current config settings
    foreach index [array names config] {
        Registry::Set $registryKey $index $config($index)
    }

    return
}

# Config::RecentFile --
#
#   Adds a file to the recent file list.
#
# Parameters:
#   process    : Process calling this proc.
#   file       : File to add.
#
# Returns:
#   Nothing.
#
proc Config::RecentFile {process file} {

    variable config

    set recentFiles $config($process,recent)

    # Don't need to do anything if there are no recent files and we
    # are not adding one, so return.
    if {($file == "") && ([llength $recentFiles] == 0)} {
        return
    }

    # Only need to make a change if the new file is not on the menu.
    foreach tempFile $recentFiles {
	if {[file split $tempFile] == [file split $file]} {
	    return
	}
    }

    # Remove any files that may have been moved or deleted
    foreach tempFile $recentFiles {
	if {![file exists $tempFile]} {
	    set p [lsearch -exact $recentFiles $tempFile]
	    set recentFiles [lreplace $recentFiles $p $p]
	    set config($process,recent) $recentFiles
	    SaveOptions
	}
    }

    # Add the new file to the beginning and limit the number
    # of entries on the list to 5.
    if {$file != ""} {
	set recentFiles [lrange [linsert $recentFiles 0 $file] 0 4]
	set config($process,recent) $recentFiles
	SaveOptions
    } else {
	if {[llength $recentFiles] == 0} return
    }

    foreach w [CrossFire::ToplevelList $process] {

	# Set the name of the menu widget, the keyword to
	# search for in the menu to insert after, and the
	# name of the open command.
	switch -- $process {
	    "DeckIt" {
		set m $w.menubar.deck
		set item "Print..."
		set openCommand "Editor::OpenDeck"
	    }
	    "Warehouse" {
		# Not coded into Warehouse yet.
		set m $w.menubar.inv
		set item "Export"
		set openCommand "Inventory::OpenInv"
	    }
	    "SwapShop" {
		set m $w.menubar.trade
		set item "Print..."
		set openCommand "SwapShop::OpenTrade"
	    }
	    "ComboMan" {
		set m $w.menubar.combo
		set item "Print..."
		set openCommand "Combo::OpenCombo"
	    }
            "Format" {
                set m $w.menubar.file
                set item "Save As..."
                set openCommand "FormatIt::Open"
            }
	}

	# Get the position in the menu
	set first [expr [$m index $item] + 2]
	set last [expr [$m index end] - 1]

	# Delete the current list of recent files
	if {$last > $first} {
	    $m delete $first $last
	}

	# Add the entries onto the menu.
	foreach tempFileName $recentFiles {
	    if {[string length $tempFileName] > 30} {
		set head [eval file join \
			      [lrange [file split $tempFileName] 0 1]]
		set shortFileName \
		    [file join $head "..." [file tail $tempFileName]]
	    } else {
		set shortFileName $tempFileName
	    }
	    $m insert $first command -label $shortFileName \
		-command "$openCommand $w \{$tempFileName\}"
	    incr first
	}
	$m insert $first separator
    }

    return
}

# Config::CheckFanCardSets --
#
#   Check the existing card set lists for fan sets that
#   have been removed by the user.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::CheckFanCardSets {} {

    variable config

    set masterIDList [CrossFire::CardSetIDList all]
    foreach cardSetList {
        Searcher,setIDList DeckIt,setIDList ComboMan,setIDList
    } {
        foreach setID $config($cardSetList) {
            if {[lsearch $masterIDList $setID] == -1} {
                set pos [lsearch $config($cardSetList) $setID]
                set config($cardSetList) \
                    [lreplace $config($cardSetList) $pos $pos]
            }
        }
    }

    return
}

# Config::AddChatColor --
#
#   Saves a color setting for a Champion in chat.
#
# Parameters:
#   tagName    : Champion's name in lower case.
#   nameFG     : Foreground color for Champion's name.
#   nameBG     : Background color for Champion's name.
#   textFG     : Foreground color for Champion's text.
#   textBG     : Background color for Champion's text.
#   font       : Font.
#
# Returns:
#   Nothing.
#
proc Config::AddChatColor {tagName nameFG nameBG textFG textBG font} {

    variable config

    set tagName [string tolower $tagName]
    set config(Chat,color,$tagName) \
        [list $tagName $nameFG $nameBG $textFG $textBG $font]

    return
}

# Config::GetChatColors --
#
#   Gets a list of all saved Champion chat colors.
#
# Parameters:
#   None.
#
# Returns:
#   A list of the list {tagName nameColor textColor etc} for each Champion.
#
proc Config::GetChatColors {} {

    variable config

    set colorList ""
    foreach tagName [array names config "Chat,color,*"] {
        lappend colorList "$config($tagName)"
    }

    return $colorList
}

# Config::AddDefaultCrossFireServer --
#
#   Adds the default CrossFire server to the look up list of servers
#   Called during initialization and when all servers have been deleted by user.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Config::AddDefaultCrossFireServer {} {

    variable config

    set config(Chat,server,host) "cfserver.spellfire.net"
    set config(Chat,server,port) "10000"
    set config(Chat,server,name) "CrossFire"
    set config(Chat,server,list) {
        CrossFire cfserver.spellfire.net 10000
    }

    return
}

namespace eval Config {

    AddDefaultCrossFireServer

    # Determine the file name of the user's settings. Create one in the user's
    # home directory (on Unix and Macintosh), the 
    # CrossFire Scripts directory (Windows 3.x), or the Windows Registry.
    if {($CrossFire::platform == "unix") ||
	($CrossFire::platform == "macintosh")} {
        set configFile [file join $env(HOME) ".CrossFire"]
    } else {
        # Windows.
        set configFile [file join $CrossFire::homeDir "Scripts" "Config.def"]
        if {$Registry::useRegistry == 1} {
            variable registryKey "CrossFire"
            set configFile "registry"
        }
    }

    if {($configFile != "registry") && ([file exists $configFile] == 0)} {
        SaveOptions
        if {$CrossFire::platform == "unix"} {
            file attributes $configFile -permissions 0600
        } elseif {$CrossFire::platform == "macintosh"} {
            file attributes $configFile -creator $CrossFire::macCode(creator)
        }
    }

}

