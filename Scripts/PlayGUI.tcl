# PlayGUI.tcl 20051122
#
# This file contains all the procedures for creating and
# manipulating the game play GUI.
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

namespace eval Game {

    variable gameCount 0 ;# Counter for creating player toplevels.
    variable oppCount  0 ;# Counter for creating opponent toplevels.
    variable lbWidth  18

    set gameConfig(gameList) {}
    set gameConfig(solMode) 6
    set gameConfig(key) "!sf"

    foreach {key name} {
        6  {6 Realm Standard}
        6i {6 Realm Inverted}
        8  {8 Realm Standard}
        10 {10 Realm Standard}
    } {
        lappend gameConfig(formation,keyList) $key
        set gameConfig(formation,$key,name) $name
    }

    # 6 realm Formation layout
    set gameConfig(formation,6,normal) {
        A 0 2
        B 1 1
        C 1 3
        D 2 0
        E 2 2
        F 2 4
        phase 0 0
        extra 0 4
    }

    # 6 realm inverted Formation layout
    set gameConfig(formation,6i,normal) {
        A 0 0
        B 0 2
        C 0 4
        D 1 1
        E 1 3
        F 2 2
        phase 2 0
        extra 2 4
    }

    # 8 realm Formation layout
    set gameConfig(formation,8,normal) {
        A 0 2
        B 1 1
        C 1 3
        D 2 0
        E 2 2
        F 2 4
        G 3 1
        H 3 3
        phase 0 0
        extra 0 4
    }

    # 10 realm Formation layout
    set gameConfig(formation,10,normal) {
        A 0 3
        B 1 2
        C 1 4
        D 2 1
        E 2 3
        F 2 5
        G 3 0
        H 3 2
        I 3 4
        J 3 6
        phase 0 0
        extra 0 6
    }

    foreach key $gameConfig(formation,keyList) {

        # Store the last row and column for each formation
        set gameConfig(formation,$key,lastRow) 0
        set gameConfig(formation,$key,lastColumn) 0
        foreach {realm row column} $gameConfig(formation,$key,normal) {
            if {$row > $gameConfig(formation,$key,lastRow)} {
                set gameConfig(formation,$key,lastRow) $row
            }
            if {$column > $gameConfig(formation,$key,lastColumn)} {
                set gameConfig(formation,$key,lastColumn) $column
            }            
        }

        # Build the inverted formations
        set gameConfig(formation,$key,invert) ""
        foreach {realm row column} $gameConfig(formation,$key,normal) {
            set newRow [expr $gameConfig(formation,$key,lastRow) - $row]
            append gameConfig(formation,$key,invert) \
                "$realm $newRow $column "
        }
    }
}

# Game::ChangePhase --
#
#   Updates the phase.  Displays in combat total and updates opponents.
#
# Parameters:
#   w         : Game toplevel
#   phase     : New phase
#
# Returns:
#   Nothing.
#
proc Game::ChangePhase {w phase} {

    variable gameConfig

    set gameConfig($w,powTotalEntry) "Phase $phase"
    UpdateCombatTotal $w
    TellOpponents $w "Phase $phase"
    focus $w

    return
}

# Game::ToggleButton --
#
#   Toggles the warning highlight for the Draw and Knock button.
#   Also updates the right-click menu.
#
# Parameters:
#   w         : Usual toplevel
#   which     : Which button to update. Draw || Knock
#
# Returns:
#   Nothing.
#
proc Game::ToggleButton {w which} {

    variable gameConfig

    if {$gameConfig($w,${which}Reminder) == "off"} {
        $gameConfig($w,${which}Button) configure -background "red"
        $gameConfig($w,${which}ButtonMenu) entryconfigure end \
            -label "Reminder Off"
        set gameConfig($w,${which}Reminder) "on"
    } else {
        $gameConfig($w,${which}Button) configure -background \
            $gameConfig($w,${which}BGColor)
        $gameConfig($w,${which}ButtonMenu) entryconfigure end \
            -label "Reminder On"
        set gameConfig($w,${which}Reminder) "off"
    }

    return
}

# Game::CreateCardView --
#
#    Create the card view toplevel.  There really was not enough
#    room on the normal window for this to be included on it.
#
# Parameters:
#    w         : Toplevel widget name.
#
# Returns:
#    Nothing.
#
proc Game::CreateCardView {w {show Yes}} {

    variable gameConfig

    # If we are creating an opponent window and using single card view mode.
    # set up variables to point to parent's card viewer.
    if {($show == "Yes") && ($gameConfig($w,playerType) == "opponent") &&
	($gameConfig($w,cardViewMode) == "single")} {
	set pw $gameConfig($w,parent)
	set gameConfig($w,cardView) $gameConfig($pw,cardView)
	set gameConfig($w,viewTop,Card) $gameConfig($pw,viewTop,Card)
	set gameConfig($w,viewPosition,Card) $gameConfig($pw,viewPosition,Card)
	return
    }

    toplevel $w.cardView
    wm title $w.cardView "$gameConfig($w,name) - Game $gameConfig($w,gameNum)"
    wm protocol $w.cardView WM_DELETE_WINDOW "Game::ToggleView $w Card No"
    set gameConfig($w,show,Card) $Config::config(Online,showCardView)
    if {$Config::config(Online,geometry,Card) != ""} {
        CrossFire::PlaceWindow $w.cardView \
            $Config::config(Online,geometry,Card)
    }

    if {($gameConfig($w,show,Card) == "No") || ($show != "Yes")} {
        wm withdraw $w.cardView
    }

    set gameConfig($w,cardView) [ViewCard::CreateCardView $w.cardView.f]
    set gameConfig($w,viewTop,Card) $w.cardView
    pack $gameConfig($w,cardView) -expand 1 -fill both

    regsub "\[0-9\]*x\[0-9\]*" [wm geometry $w.cardView] "" \
        gameConfig($w,viewPosition,Card)

    return
}

# Game::ToggleView --
#
#    Toggles or sets a windowls view mode.
#
# Parameters:
#    w         : Toplevel widget name.
#    which     : Which window to show (card view, out of play, etc)
#    args      : Optional value to set the view mode to.
#
# Returns:
#    Nothing.
#
proc Game::ToggleView {w which args} {

    variable gameConfig

    if {$args != ""} {
        set gameConfig($w,show,$which) [lindex $args 0]
    }

    set tw $gameConfig($w,viewTop,$which)
    if {$gameConfig($w,show,$which) == "No"} {
        regsub "\[0-9\]*x\[0-9\]*" [wm geometry $tw] "" \
            gameConfig($w,viewPosition,$which)
        wm withdraw $tw
    } else {
        wm deiconify $tw
        raise $tw
        CrossFire::PlaceWindow $tw $gameConfig($w,viewPosition,$which)
    }

    return
}

# Game::ToggleEventDiscard --
#
#   Called when the player changes the discard location for events.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::ToggleEventDiscard {w} {

    variable gameConfig

    if {$gameConfig($w,eventsTo) == "abyss"} {
        set chatter "Abyss."
    } else {
        set chatter "discard pile."
    }

    TellOpponents $w "EventDiscard $gameConfig($w,eventsTo)"
    TellOpponents $w "Message will discard events to the $chatter"

    return
}

# Game::Initialize --
#
#   Initializes a couple variables.
#
# Parameters:
#   w         : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::Initialize {w} {

    variable gameConfig

    foreach var {
        handList poolList abyssList discardList limboList drawPile
        attachAList attachBList attachCList attachDList attachEList
        attachFList attachGList attachHList attachIList attachJList
        battlefieldList outOfPlayList cardID spoilsID
    } {
        set gameConfig($w,$var) ""
    }

    set gameConfig($w,hidePool) 0
    set gameConfig($w,handSize) 0
    set gameConfig($w,deckSize) 0
    set gameConfig($w,spoilsDrawn) 0

    return
}

# Game::Clear --
#
#   Clears a game window.  Used for refreshing the display or
#   restarting a game.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::Clear {w} {

    variable gameConfig

    foreach tbw $gameConfig($w,textBoxes) {
        $tbw delete 1.0 end
    }

    foreach listVar {
        poolList battlefieldList abyssList discardList limboList
	outOfPlayList
        attachAList attachBList attachCList attachDList attachEList
        attachFList attachGList attachHList attachIList attachJList
    } {
        set gameConfig($w,$listVar) ""
    }

    $gameConfig($w,dungeonLabel) configure -text "No Dungeon" -anchor c
    set gameConfig($w,dungeonCard) "none"
    $gameConfig($w,ruleLabel) configure -text "No Rule" -anchor c
    set gameConfig($w,ruleCard) "none"

    foreach rl $gameConfig($w,realmLabel) {
        set realm $gameConfig($rl)
        $rl configure -text "Realm [string range $realm end end]" -anchor c
        set gameConfig($w,${realm}Card) "none"
        SetRealmStatus $w $realm "unrazed" "clear"
    }

    set gameConfig($w,handSize) 0
    UpdateHandSize $w

    set gameConfig($w,deckSize) 0
    UpdateDeckSize $w

    set gameConfig($w,hidePool) 0
    set gameConfig($w,phase) 0

    return
}

# Game::RefreshOpponents --
#
#   Sends an update for each card on a player's window.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::RefreshOpponents {w} {

    variable gameConfig

    TellOpponents $w "Clear"

    # Text boxes - Pool, Battlefield, abyss, limbo, discard,
    #              attached, and outOfPlay
    foreach which {
        pool battlefield abyss discard limbo outOfPlay
        attachA attachB attachC attachD attachE
        attachF attachG attachH attachI attachJ
    } {
        DisplayList $w $which
    }

    # Dungeon and rule cards
    foreach which {dungeon rule} {
        DisplayLabel $w $which
    }

    # Realms
    foreach rl $gameConfig($w,realmLabel) {
        set realm $gameConfig($rl)
        DisplayLabel $w $realm
        SetRealmStatus $w $realm $gameConfig($w,${realm}Status)
    }

    TellOpponents $w "HandSize $gameConfig($w,handSize)"
    TellOpponents $w "DeckSize $gameConfig($w,deckSize)"
    TellOpponents $w "Phase $gameConfig($w,phase)"
    TellOpponents $w "HidePool $gameConfig($w,hidePool)"
    TellOpponents $w [list CombatTotal $gameConfig($w,powTotal)]

    # Game Notes.
    set m $gameConfig($w,removeMenu)
    set last [$m index end]
    if {$last != "none"} {
        for {set i 0} {$i <= $last} {incr i} {
            set title [$m entrycget $i -label]
            set player $gameConfig($w,$title,author)
            set msg $gameConfig($w,$title,text)
            TellOpponents $w "AddGameNote [list $title] $player [list $msg]"
        }
    }

    return
}

# Game::Restart --
#
#   Restarts the game for this player.  Optional declares it as a mulligan.
#
# Parameters:
#   w          : Game toplevel.
#   mulligan   : Optionally declare a mulligan.
#
# Returns:
#   Nothing.
#
proc Game::Restart {w {mulligan ""}} {

    variable gameConfig

    set response [tk_messageBox -icon warning -title "Are you sure?" \
		      -message "Are you sure you want to restart this game?" \
		      -type yesno]
    if {$response == "no"} return

    if {$mulligan != ""} {
        set hand $gameConfig($w,handList)
        if {[llength $hand] == 0} {
            set chatter "Message mulligans, but had no cards in hand..."
        } else {
            set idList {}
            foreach card $hand {
                lappend idList [lindex $card 0]
            }
            set chatter "Message mulligans!  Hand was: $idList ..."
        }
    } else {
	set chatter "Message restarts the game..."
    }

    TellOpponents $w $chatter

    Clear $w
    TellOpponents $w "Clear"

    ReadDeck $w

    return
}

# Game::RemoveOpponent --
#
#   Removes an opponent from the player.  Removes them from the lookup list and
#   greys out their window on the panes of war.
#
# Parameters:
#   ow         : Opponent toplevel.
#   confirm    : Should we ask before removing? (yes or no)
#
# Returns:
#   Nothing.
#
proc Game::RemoveOpponent {ow {confirm no}} {

    variable gameConfig

    set who [string tolower $gameConfig($ow,name)]

    if {$confirm != "no"} {
        set result [tk_messageBox -icon warning -title "Are You Sure?" \
                        -message "Are you sure you want to remove $who?" \
                        -type yesno -default no]
        if {$result == "no"} return
    }

    set pw [winfo parent $ow]
    if {[info exists gameConfig($pw,number,$gameConfig($ow,name))]} {
        # Will not exist for a watcher
	set key $gameConfig($pw,key,$gameConfig($ow,name))
        set num $gameConfig($pw,number,$gameConfig($ow,name))
        set gameConfig($pw,number,$num) ""
        SaveWindowSize $pw $key

	# Save paned window settings
	Config::Set Online,mainPane,$key \
	    [PanedWindow::Position $gameConfig($ow,mainPane) 1]
	Config::Set Online,formPane,$key \
	    [PanedWindow::Position $gameConfig($ow,formPane) 1]

        $gameConfig($pw,viewMenu) delete $gameConfig($ow,name)
        unset gameConfig($pw,number,$gameConfig($ow,name))
    }

    set pos [lsearch $gameConfig($pw,opponents) $ow]
    set gameConfig($pw,opponents) \
        [lreplace $gameConfig($pw,opponents) $pos $pos]
    set pos [lsearch $gameConfig($pw,names) $who]
    set gameConfig($pw,names) [lreplace $gameConfig($pw,names) $pos $pos]
    set tbw $gameConfig($ow,battlefield)
    $tbw delete 1.0 end
    $tbw configure -background grey

    if {$gameConfig(ot,$who) == "watcher"} {
        destroy $gameConfig($pw,warFrame,$gameConfig($ow,name))
    }

    unset gameConfig(tw,$who)
    unset gameConfig(ot,$who)
    destroy $ow

    if {[info exists gameConfig($pw,playerListBox)]} {
        set lbw $gameConfig($pw,playerListBox)
        set last [expr [$lbw index end] - 1]
        for {set lbIndex 0} {$lbIndex <= $last} {incr lbIndex} {
            if {$who == [string tolower [$lbw get $lbIndex]]} {
                $lbw delete $lbIndex
            }
        }
        TellOpponents $pw "Message is no longer watching $who"
    } else {
        TellOpponents $pw "Message removed $who from opponents"
    }

    return
}

# Game::ToggleChampionMode --
#
#   Changes the champion display mode.
#
# Parameters:
#   w          : Game toplevel name.
#
# Returns:
#   Nothing.
#
proc Game::ToggleChampionMode {w} {

    variable gameConfig

    if {$gameConfig($w,championMode) == "Class"} {
        set gameConfig($w,championMode) "Champion"
    } else {
        set gameConfig($w,championMode) "Class"
    }

    DisplayHand $w

    return
}

# Game::CreateOutOfPlay --
#
#   Creates a hideable toplevel to hold the cards that were sent
#   out of play.
#
# Parameters:
#   pw         : Game parent toplevel.
#
# Returns:
#   Nothing.
#
proc Game::CreateOutOfPlay {pw} {

    variable gameCount
    variable gameConfig

    # Hideable toplevel textbox of cards out of play
    set w [toplevel $pw.outOfPlay]
    set t "Out of Play (The Void)"
    wm title $w "$gameConfig($pw,name) - $t - Game $gameCount"
    wm withdraw $w
    wm protocol $w WM_DELETE_WINDOW "Game::ToggleView $pw OutOfPlay No"
    if {$Config::config(Online,geometry,OutOfPlay) != ""} {
        CrossFire::PlaceWindow $w $Config::config(Online,geometry,OutOfPlay)
    }

    frame $w.f -borderwidth 1 -relief raised

    frame $w.f.list
    text $w.f.list.t -height 8 -width 20 -spacing1 2 \
        -exportselection 0 -background white -foreground black \
        -yscrollcommand "CrossFire::SetScrollBar $w.f.list.sb" \
        -wrap none -cursor {} -takefocus 0
    set tbw $w.f.list.t
    $tbw tag configure select -foreground white -background blue
    set gameConfig($pw,outOfPlay) $tbw
    set gameConfig($tbw) "outOfPlay"
    lappend gameConfig($pw,textBoxes) $gameConfig($pw,outOfPlay)
    scrollbar $w.f.list.sb -command "$tbw yview"
    grid $w.f.list.t -sticky nsew

    grid $w.f.list -sticky nsew -padx 5 -pady 5
    grid columnconfigure $w.f.list 0 -weight 1
    grid rowconfigure $w.f.list 0 -weight 1

    grid $w.f -sticky nsew
    grid columnconfigure $w.f 0 -weight 1
    grid rowconfigure $w.f 0 -weight 1

    set gameConfig($pw,outOfPlay) $tbw
    set gameConfig($tbw) "outOfPlay"

    if {$gameConfig($pw,playerType) == "player"} {
	# Set up bindings to make the listbox a drag source and target
	CrossFire::DragTarget $tbw card "Game::MoveCard $pw outOfPlay"
    }
    bind $tbw <ButtonPress-1> "Game::ClickTextBox $pw %X %Y 1 outOfPlay"
    bind $tbw <ButtonPress-3> "Game::ClickTextBox $pw %X %Y 3 outOfPlay"
    bind $tbw <ButtonRelease-1> "CrossFire::CancelDrag $tbw"
    bindtags $tbw "$tbw all"

    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 1

    set gameConfig($pw,show,OutOfPlay) "No"
    set gameConfig($pw,viewTop,OutOfPlay) $w
    regsub "\[0-9\]*x\[0-9\]*" [wm geometry $w] "" \
        gameConfig($pw,viewPosition,OutOfPlay)

    bind $w <Key-Up>   "Game::MoveSelection $pw U"
    bind $w <Key-Down> "Game::MoveSelection $pw D"

    return
}

# Game::CreatePanesOfWar --
#
#   Creates the panes of war toplevel and adds the player.
#
# Parameters:
#   w          : Game toplevel
#
# Returns:
#   Nothing.
#
proc Game::CreatePanesOfWar {w {mode player}} {

    variable gameConfig

    set tw [toplevel $w.war]
    set gameConfig($w,warZone) $tw
    wm title $tw "Panes Of War - Game $gameConfig($w,gameNum)"
    wm protocol $tw WM_DELETE_WINDOW "Game::ToggleView $w Panes No"

    # Entry area for one's current level
    set f [frame $tw.total -borderwidth 2 -relief groove]
    frame $f.f
    label $f.f.l -text "Combat Total:"
    entry $f.f.e -textvariable Game::gameConfig($w,powTotalEntry)
    set gameConfig($w,powTotalEntryW) $f.f.e
    bind $f.f.e <Key-Return> "Game::UpdateCombatTotal $w"
    button $f.f.b -text "Update" -command "Game::UpdateCombatTotal $w"
    grid $f.f.l -column 0 -row 0
    grid $f.f.e -column 1 -row 0 -sticky ew -padx 5 -pady 5
    grid $f.f.b -column 2 -row 0 -padx 5
    grid columnconfigure $f.f 1 -weight 1
    grid $f.f -sticky ew
    grid columnconfigure $f 0 -weight 1
    grid $tw.total -row 1 -column 0 -sticky ew
    set gameConfig($w,powTotalFrame) $tw.total

    set gameConfig($w,paneCount) -1
    AddWarPane $w $gameConfig($w,name) $mode

    if {$Config::config(Online,geometry,Panes) != ""} {
        CrossFire::PlaceWindow $tw $Config::config(Online,geometry,Panes)
    }

    set gameConfig($w,show,Panes) "Yes"
    set gameConfig($w,viewTop,Panes) $tw
    regsub "\[0-9\]*x\[0-9\]*" [wm geometry $tw] "" \
        gameConfig($w,viewPosition,Panes)

    bind $tw <Key-Up>    "Game::MoveSelection $w U"
    bind $tw <Key-Down>  "Game::MoveSelection $w D"
    bind $tw <Key-Left>  "Game::MoveSelection $w L"
    bind $tw <Key-Right> "Game::MoveSelection $w R"

    return
}

# Game::AddWarPane --
#
#   Adds a new war pane with the name specified.
#
# Parameters:
#   w         : Game toplevel.
#   name      : Name to title it with.
#   which     : Opponent, player, or watcher
#
# Returns:
#   Nothing.
#
proc Game::AddWarPane {w name which} {

    variable gameConfig
    variable lbWidth

    if {$which == "opponent" || $which == "watcher"} {
        set pw [winfo parent $w]
        if {[info exists gameConfig($pw,warPane,$name)] &&
            [winfo exists $gameConfig($pw,warPane,$name)]} {
            set tbw $gameConfig($pw,warPane,$name)
            set gameConfig($w,battlefield) $tbw
            lappend gameConfig($w,textBoxes) $tbw
            if {$which == "opponent"} {
                $tbw configure -background white
            }
            bind $tbw <ButtonPress-1> \
                "Game::ClickTextBox $w %X %Y 1 battlefield $which"
            bind $tbw <ButtonPress-3> \
                "Game::ClickTextBox $w %X %Y 3 battlefield $which"
            set f $gameConfig($pw,warFrame,$name)
            $f.f.total configure -textvariable Game::gameConfig($w,powTotal)
            return
        }
    } else {
        set pw $w
    }

    set gameConfig($w,battlefieldList) {}

    if {$which == "opponent" || $which == "player"} {
        set col [incr gameConfig($pw,paneCount)]
        set f $gameConfig($pw,warZone).pane$col
    } else {
        set f $gameConfig($pw,warZone).pane$name
    }

    frame $f -borderwidth 2 -relief groove

    frame $f.f
    label $f.f.name -text "$name:" -anchor w
    label $f.f.total -foreground red -width 10 -anchor w \
	-textvariable Game::gameConfig($w,powTotal)

    frame $f.f.cards
    text $f.f.cards.t -height 10 -width $lbWidth -spacing1 2 \
        -exportselection 0 -background white -foreground black \
        -yscrollcommand "CrossFire::SetScrollBar $f.f.cards.sb" \
        -wrap none -cursor {} -takefocus 0
    set tbw $f.f.cards.t
    $tbw tag configure champion -font "[lindex [$tbw configure -font] 3] bold"
    $tbw tag configure event -foreground red \
        -font "[lindex [$tbw configure -font] 3] bold"
    $tbw tag configure select -foreground white -background blue
    set gameConfig($w,battlefield) $tbw
    lappend gameConfig($w,textBoxes) $tbw
    set gameConfig($pw,warPane,$name) $tbw
    set gameConfig($pw,warFrame,$name) $f
    scrollbar $f.f.cards.sb -command "$f.f.cards.t yview"

    bind $tbw <ButtonPress-1> \
        "Game::ClickTextBox $w %X %Y 1 battlefield $which"
    bind $tbw <ButtonPress-3> \
        "Game::ClickTextBox $w %X %Y 3 battlefield $which"
    bindtags $tbw "$tbw all"

    if {$which == "player"} {
        CrossFire::DragTarget $tbw card "Game::MoveCard $w battlefield"
        bind $tbw <ButtonRelease-1> "CrossFire::CancelDrag $tbw"
    } else {
        CrossFire::DragTarget $tbw card "Game::MoveCard $pw opponent,$name"
    }

    grid $f.f.cards.t -sticky nsew
    grid columnconfigure $f.f.cards 0 -weight 1
    grid rowconfigure $f.f.cards 0 -weight 1

    grid $f.f.name $f.f.total -sticky ew -pady 3
    grid $f.f.cards -columnspan 2 -sticky nsew
    grid columnconfigure $f.f 1 -weight 1
    grid rowconfigure $f.f 1 -weight 1

    grid $f.f -sticky nsew -padx 5 -pady 5
    grid columnconfigure $f 0 -weight 1
    grid rowconfigure $f 0 -weight 1

    if {$which == "opponent" || $which == "player"} {
        # Find the next open spot to place the frame
        set myCol 0
        while {[grid slaves $gameConfig($pw,warZone) -row 0 -column $myCol] != ""} {
            incr myCol
        }
        grid $f -row 0 -column $myCol -sticky nsew
        grid columnconfigure $gameConfig($pw,warZone) $myCol -weight 1
        grid rowconfigure $gameConfig($pw,warZone) 0 -weight 1
	grid $gameConfig($pw,powTotalFrame) -columnspan \
            [lindex [grid size $gameConfig($pw,warZone)] 0]
    }

    return
}

# Game::EndTurn --
#
#   Ends the player's turn.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::EndTurn {w} {

    variable gameConfig

    if {[llength $gameConfig($w,drawPile)] == 0} {
        if {$gameConfig($w,autoRecycleDiscards) == "Yes"} {
            TellOpponents $w \
                "Message is out of cards, so returning discards to draw pile"
            DiscardToDraw $w
        } else {
            set g "Game over, man! GAME OVER!!"
            TellOpponents $w \
                "Message is out of cards and declares ... $g"
        }
    }

    set gameConfig($w,powTotalEntry) ""
    UpdateCombatTotal $w
    focus $w

    TellOpponents $w "Message knocks"
    TellOpponents $w "Phase 0"
    set gameConfig($w,phase) 0

    return
}

# Game::About --
#
#   Displays an about dialog for Game play.
#
# Paramters:
#   w         : Parent toplevel for the pop-up dialog.
#
# Returns:
#   Nothing.
#
proc Game::About {w} {
    set message "CrossFire Online Spellfire\n"
    append message "\nby Dan Curtiss"
    tk_messageBox -icon info -title "About Online Spellfire" \
        -parent $w -message $message
    return
}

# Game::DrawDisabled --
#
#   Checks and warns if the draw button is in remind mode.
#   ### CURRENTLY UNUSED
#
# Parameters:
#   w         : Game toplevel
#
# Returns:
#   1 if disabled, 0 if normal.
#
proc Game::DrawDisabled {w} {

    variable gameConfig

    set disabled 0
    if {[$gameConfig($w,drawButton) cget -state] == "disabled"} {
        tk_messageBox -title "Ain't gonna do it!" \
            -icon error -parent $w \
            -message "Remember to do your Phase Zero actions!"
        set disabled 1
    }

    return $disabled
}

# Game::DrawCard --
#
#   Draws a card and sends it to either the hand or discard.
#   Discard is from noting the last digit; displays a message.
#
# Parameters:
#   w          : Game toplevel.
#   toWhere    : Target. (hand, discard, spoils, dSpoils, battlefield)
#   qty        : Optional
#
# Returns:
#   Nothing.
#
proc Game::DrawCard {w toWhere {qty 1}} {

    variable gameConfig

    ### if {[DrawDisabled $w]} return

    if {$toWhere == "hand"} {
        set count 0
        for {set i 1} {$i <= $qty} {incr i} {
            set gameConfig($w,cardID) "unknown"
            set cardID [lindex [lindex [MoveCard $w hand drawCard draw] 0] 0]
            if {$cardID == ""} {
                break
            }
            incr count
        }
        if {$count == 0} {
            set chatter "Message has no more cards to draw"
        } elseif {$count == 1} {
            set chatter "Message drew a card..."
        } else {
            set chatter "Message drew $count cards..."
        }
    } elseif {($toWhere == "discard") || ($toWhere == "battlefield") ||
              ($toWhere == "abyss")} {
        set gameConfig($w,cardID) "unknown"
        set cardID \
            [lindex [lindex [MoveCard $w $toWhere drawDiscard draw] 0] 0]
        if {$cardID == ""} {
            set chatter "Message has no more cards to draw"
        } else {
            set cardNum [string range $cardID end end]
            if {$cardNum == 8} {
                set a an
            } else {
                set a a
            }
            set cardDesc [CrossFire::GetCardDesc \
                              [CrossFire::GetCard $cardID]]
            if {$toWhere == "discard"} {
                set chatter "Message drew $a $cardNum - $cardDesc ..."
            } elseif {$toWhere == "battlefield"} {
                set chatter "Message drew and played $cardDesc ..."
            } else {
                set chatter ""
            }
        }
    } elseif {$toWhere == "spoils"} {
        set count 0
        set gameConfig($w,spoilsList) {}
        for {set i 1} {$i <= $qty} {incr i} {
            set gameConfig($w,cardID) "unknown"
            set cardID [lindex [lindex [MoveCard $w spoils dSpoils draw] 0] 0]
            if {$cardID == ""} {
                break
            }
            incr count
        }
        if {$count == 0} {
            set chatter "Message has no more cards to draw"
        } elseif {$count == 1} {
            set chatter "Message drew spoils..."
        } else {
            set chatter "Message drew $count spoils cards..."
        }
    } elseif {$toWhere == "dSpoils"} {
        set gameConfig($w,cardID) "unknown"
        set card [MoveCard $w battlefield dSpoils draw player none]
        set cardID [lindex [lindex $card 0] 0]
        if {$cardID == ""} {
            set chatter "Message has no more cards to draw"
        } else {
            set card [CrossFire::GetCard $cardID]
            set cardDesc [CrossFire::GetCardDesc $card]
            if {[lindex $card 3] == 13} {
                set gameConfig($w,cardID) $cardID
                MoveCard $w abyss dSpoils battlefield
                set chatter "Message drew realm $cardDesc for dungeon spoils"
                append chatter " (sent to the Abyss)..."
            } else {
                set chatter "Message drew $cardDesc for dungeon spoils..."
            }
        }
    } else {
        tk_messageBox -title "Internal Error" -icon error \
            -message "Tell Dan \"Game::DrawCard $toWhere\""
        set chatter "Message Error. Tell Dan \"Game::DrawCard $toWhere\""
    }

    if {$chatter != ""} {
        TellOpponents $w $chatter
    }

    return
}

# Game::DiscardFromHand --
#
#   Implements another player randomly drawing and discarding a card
#   from the player's hand.
#
# Parameters:
#   w          : Game toplevel of the player.
#   which      : Which mode to discard (Any or All)
#   discard    : Card type list or "Card" to discard
#
# Returns:
#   Nothing.
#
proc Game::DiscardFromHand {w which discard typeName} {

    variable gameConfig

    # seed the random number generator
    expr srand([clock clicks])

    set hand $gameConfig($w,handList)

    if {[llength $hand] == 0} {
        # Woo Hoo!!  No cards in hand means no lose a card!!
        TellOpponents $w "Message hand is empty"
        return
    }

    set handList {}
    foreach cardInfo $hand {
        lappend handList [lindex [lindex $cardInfo 0] 0]
    }

    if {$discard == "Card"} {
        # All cards in hand regardless of type.
        set cardList $handList
    } else {
        # All of a card type(s)
        set cardList {}
        foreach cardID $handList {
            set cardType [lindex [CrossFire::GetCard $cardID] 3]
            if {[lsearch $discard $cardType] != -1} {
                lappend cardList $cardID
            }
        }
    }

    if {$cardList == ""} {
        TellOpponents $w "Message has no $typeName in hand"
        return
    }

    if {$which == "All"} {
        set idList $cardList
    } else {
        # Pick a random one.
        set idList [lindex $cardList [expr int(rand() * [llength $cardList])]]
    }

    if {$which == "All"} {
        TellOpponents $w "Message discarded all $typeName from hand"
    } else {
        TellOpponents $w "Message discarded a random $typeName from hand"
    }

    set tbw $gameConfig($w,hand)
    foreach cardID $idList {
        set gameConfig($w,cardID) $cardID
        MoveCard $w discard loser hand
    }

    return
}

# Game::GetSelectedCardID --
#
#   Gets the selected card ID in a text box.
#
# Parameters:
#   w         : Game toplevel.
#   which     : Which text box to read.
#
# Returns:
#   The card in standard format.
#
proc Game::GetSelectedCardID {w which} {

    variable gameConfig

    set tbw $gameConfig($w,$which)
    set start [lindex [$tbw tag ranges select] 0]
    if {$start == ""} {
        set cardID ""
    } else {
        if {[lsearch [$tbw tag names $start] "cardTypeHeader"] > -1} {
            set cardID ""
        } else {
            set end [lindex [split $start "."] 0].end
            set cardID [lindex [$tbw get $start $end] end]
        }
    }

    return $cardID
}

# Game::RealmError --
#
#   Complains when a game has differing numbers of realms.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::RealmError {w} {

    set msg "It appears that an opponent is playing a "
    append msg "different number of realms than you!"
    tk_messageBox -icon error -title "Game Play Error" \
        -message $msg

    return
}

# Game::MoveCard --
#
#   Handles moving a card from one box to another.  This IS the proc from HELL!
#
# Parameters:
#   w          : Game toplevel.
#   to         : Where the card is going to.
#   sender     : Dummy for drag-&-drop or card ID when receiving from server.
#   from       : Where the card is coming from.
#   side       : Which side of the table (player or opponent).
#
# Returns:
#   The card.
#
proc Game::MoveCard {w to sender from {side player} {attachTo ""}} {

    variable gameConfig

    dputs "Game::MoveCard w:$w to:$to sender:$sender from:$from side:$side attachTo:$attachTo"

    if {([winfo exists $sender]) && ([regexp "^$w" $sender] == 0)} {
        # Card came from a different game toplevel!
        bell
        return
    }

    if {$gameConfig($w,cardID) == ""} {
        tk_messageBox -title "Whoa!!" -icon warning \
            -message "Please slow down your card moving!"
        return
    }

    set hiding [regexp "^hide(.+)\$" $from match from]
    if {$hiding == 1} {
        set hiding "hidden"
    } else {
        set hiding "normal"
    }

    # Get the card to move from the 'from' location.
    # Some require checks on the 'to' location, so the card is not
    # removed for those yet.
    switch -regexp $from {
        "abyss" - "attach*" - "battlefield" - "discard" - \
            "limbo" - "outOfPlay" - "pool" {
                if {[info exists gameConfig($w,$from)] == 0} {
                    RealmError $w
                    return
                }
                set testID $gameConfig($w,cardID)
                set found 0
                foreach cardList $gameConfig($w,${from}List) {
                    set id [lindex [lindex $cardList 0] 0]
                    if {$id == $testID} {
                        # Its a list of cards
                        set card $cardList
                        set found 1
                    }
                }
                if {$found == 0} {
                    # This was an attachment
                    if {$from == "pool"} {
                        foreach champList $gameConfig($w,${from}List) {
                            foreach cardList $champList {
                                set id [lindex [lindex $cardList 0] 0]
                                if {$id == $testID} {
                                    set card [list $cardList]
                                }
                            }
                        }
                    } else {
                        set card [list [list $testID "normal"]]
                    }
                }
            }
        "card" {
            set card [list [list $sender "normal"]]
        }
        "draw" {
            set card [GetNextCard $w]
            if {$card == ""} {
                set gameConfig($w,cardID) ""
                return ""
            }
            set cardID [lindex [CrossFire::GetCardDesc $card] 0]
            set card [list [list $cardID "normal"]]
        }
        "dungeon" - "rule" - "realm*" {
            if {[info exists gameConfig($w,${from}Card)] == 0} {
                RealmError $w
                return
            }
            if {([regexp "^realm." $from] == 1) &&
                ($gameConfig($w,${from}Status) == "hide")} {
                set card [list [list $gameConfig($w,${from}Card) "hidden"]]
            } else {
                set card [list [list $gameConfig($w,${from}Card) "normal"]]
            }
        }
        "hand" {
            set card [list [list $gameConfig($w,cardID) $hiding]]
        }
        default {
            set msg "Unknown from location of '$from'\nSomeone  "
            append msg "needs to download the latest version!!!"
            tk_messageBox -title "Oh NO!!!" -icon error \
                -message $msg
            TellOpponents $w "Message $msg"
            return
        }
    }

    if {([regexp "^(attach|pool|hand|realm)" $to] == 0) ||
        (([regexp "^attach" $from] == 1) && ([regexp "hand" $to] == 0)) ||
        (([regexp "^attach" $to] == 1) && ([regexp "hand" $from] == 0))} {
        # Change any hidden cards to normal
        regsub -all "hidden" $card "normal" card
        set hiding "normal"
    }
    set okToMove 1

    # Check if the card is legal to put in the 'to' location.
    switch -regexp $to {
        "abyss" - "attach*" - "discard" - "limbo" - "outOfPlay" {
            if {[info exists gameConfig($w,$to)] == 0} {
                RealmError $w
                return
            }
            foreach tempCard $card {
                set cardID [lindex $tempCard 0]
                set myCard [CrossFire::GetCard $cardID]
                set cardDesc [CrossFire::GetCardDesc $myCard]
                if {($to == "discard") && ([lindex $myCard 3] == 6) &&
                    ($gameConfig($w,eventsTo) == "abyss")} {
                    # Events are sent to the Abyss when discarded
                    if {$from == "abyss"} {
                        set okToMove 0
                    } else {
                        lappend gameConfig($w,abyssList) \
                            [list [list [lindex $tempCard 0] "normal"]]
                        DisplayList $w abyss
                    }
                } else {
                    if {$to == "outOfPlay"} {
                        set toopn "Out of Play (The Void)"
                        TellOpponents $w \
                            "Message sent $cardDesc to $toopn!!"
                    }
                    lappend gameConfig($w,${to}List) \
                        [list [list [lindex $tempCard 0] $hiding]]
                }
            }
            DisplayList $w $to
        }
        "battlefield" - "pool" {
            set champList $CrossFire::championList
            if {([llength $card] == 1) && ($attachTo == "")} {
                set tbw $gameConfig($w,$to)
                set x [expr [winfo pointerx $tbw] - [winfo rootx $tbw]]
                set y [expr [winfo pointery $tbw] - [winfo rooty $tbw]]
                set pos [expr int([$tbw index @$x,$y])]
                set droppedOn [$tbw get $pos.0 [expr $pos + 1].0]
                set attachTo [string trim [lindex $droppedOn end] "\n"]
                set tempCard [CrossFire::GetCard $attachTo]
                foreach {tx ty tw th} [$tbw bbox $pos.0] break
                if {$y >= [expr $ty + $th]} {
                    # Dropped on empty space
                    set attachTo ""
                }
            }
            set firstCard [CrossFire::GetCard [lindex [lindex $card 0] 0]]
            set cardType [lindex $firstCard 3]
            if {([lsearch $champList $cardType] != -1) ||
                ($attachTo == "")} {
                # Either a champion or a card acting like one
                lappend gameConfig($w,${to}List) $card
                if {($cardType == 6) && ($to == "battlefield")} {
                    # Event, play event sound
                    CrossFire::PlaySound "PlayEvent"
                }
            } else {
                set pl $gameConfig($w,${to}List)
                set cIndex -1
                set found 0
                foreach champList $pl {
                    set champCard [lindex $champList 0]
                    incr cIndex
                    set id [lindex $champCard 0]
                    if {$attachTo == $id} {
                        set found 1
                        append champList " $card"
                        set gameConfig($w,${to}List) \
                            [lreplace $pl $cIndex $cIndex $champList]
                        break
                    }
                }
                if {$found == 0} {
                    # User dropped onto an attachment
                    lappend gameConfig($w,${to}List) $card
                }
            }
            DisplayList $w $to
        }
        "deck" - "draw" {
            if {$to == "deck"} {
                set which [GetDeckDropPosition $w]
                if {$which == ""} {
                    # Player canceled the move.
                    set okToMove 0
                }
            } else {
                set which "top"
            }
            if {$okToMove == 1} {
                foreach tempInfo $card {
                    set tempCard [CrossFire::GetCard [lindex $tempInfo 0]]
                    set cardDesc [CrossFire::GetCardDesc $tempCard]
                    if {$which == "top"} {
                        set gameConfig($w,drawPile) \
                            [linsert $gameConfig($w,drawPile) 0 $tempCard]
                    } else {
                        lappend gameConfig($w,drawPile) $tempCard
                    }
                    if {($from == "hand") && ($to == "draw")} {
                        TellOpponents $w \
                            "Message returned a card from the hand to the draw pile"
                    } else {
                        TellOpponents $w \
                            "Message returned $cardDesc to $which of draw pile"
                    }
                }
                set gameConfig($w,deckSize) [llength $gameConfig($w,drawPile)]
                UpdateDeckSize $w
            }
        }
        "dungeon" {
            set cardID [lindex [lindex $card 0] 0]
            set tempCard [CrossFire::GetCard $cardID]
            if {[lindex $tempCard 3] == 21} {
                set gameConfig($w,dungeonCard) $cardID
                DisplayLabel $w dungeon
            } else {
                tk_messageBox -title "Card Move Error" -icon error \
                    -message "You can only move the dungeon card here!!"
                set okToMove 0
            }
        }
        "hand" {
            foreach tempInfo $card {
                lappend gameConfig($w,handList) $tempInfo
                set gameConfig($w,handSize) \
                    [llength $gameConfig($w,handList)]
            }
            DisplayHand $w [lindex [lindex [lindex $card 0] 0] 0]
        }
        "spoils" {
            foreach tempInfo $card {
                lappend gameConfig($w,spoilsList) $tempInfo
            }
        }
        "opponent*" {
            foreach {junk name} [split $to ","] break
            set idList {}
            foreach tempCard $card {
                set id [lindex $tempCard 0]
                lappend idList $id
                set tempCard [CrossFire::GetCard $id]
                set cardDesc [CrossFire::GetCardDesc $tempCard]
                TellOpponents $w "Message transfers card $cardDesc to $name"
                lappend gameConfig($w,outOfPlayList) [list [list $id "normal"]]
                DisplayList $w outOfPlay
            }
            TellOpponents $w "TransferCard $name $idList"
        }
        "realm*" {
            if {[info exists gameConfig($w,${to}Card)] == 0} {
                RealmError $w
                return
            }
            set cardID [lindex [lindex $card 0] 0]
            set tempCard [CrossFire::GetCard $cardID]
            # Only allow a realm card or Caer Allison (FR/3) in a realm spot.
            if {([lindex $tempCard 3] == 13) ||
                ([lrange $tempCard 0 1] == "FR 3")} {
                if {$gameConfig($w,${to}Card) != "none"} {
                    if {$gameConfig($w,${to}Status) != "razed"} {
                        tk_messageBox -title "Card Move Error" -icon error \
                            -message "You cannot replace an unrazed realm!"
                        set okToMove 0
                    } else {
                        # Send the current razed realm card to discards
                        set oldCardID $gameConfig($w,${to}Card)
                        set oldCard [CrossFire::GetCard $oldCardID]
                        lappend gameConfig($w,discardList) \
                            [list [list $oldCardID normal]]
                        DisplayList $w discard
                        SetRealmStatus $w $to "unrazed"
                    }
                }
                if {$okToMove != 0} {
                    set gameConfig($w,${to}Card) $cardID
                    if {$hiding != "normal"} {
                        SetRealmStatus $w $to "hide"
                    }
                    DisplayLabel $w $to
                }
            } else {
                tk_messageBox -title "Card Move Error" -icon error \
                    -message "You can only move a realm card here!!"
                set okToMove 0
            }
        }
        "rule" {
            set cardID [lindex [lindex $card 0] 0]
            set tempCard [CrossFire::GetCard $cardID]
            # Only allow rule cards amazingly enough!
            if {[lindex $tempCard 3] == 15} {
                if {$gameConfig($w,ruleCard) != "none"} {
                    # Send the current rule card to discards
                    set oldCardID $gameConfig($w,ruleCard)
                    set oldCard [CrossFire::GetCard $oldCardID]
                    lappend gameConfig($w,discardList) \
                        [list [list $oldCardID normal]]
                    DisplayList $w discard
                }
                set gameConfig($w,ruleCard) $cardID
                DisplayLabel $w rule
            } else {
                tk_messageBox -title "Card Move Error" -icon error \
                    -message "You can only move a rule card here!!"
                set okToMove 0
            }
        }
        default {
            set msg "Unknown to location of '$to'\nSomeone "
            append msg "needs to download the latest version!!!"
            tk_messageBox -title "Oh NO!!!" -icon error \
                -message $msg
            TellOpponents $w "Message $msg"
        }
    }

    # Return if the move was not allowed.
    if {$okToMove == 0} {
        return ""
    }

    # Remove the card from its original place.
    switch -regexp $from {
        "abyss" - "attach*" - "battlefield" - "discard" - "limbo" - \
            "outOfPlay" - "pool" {
                set pl $gameConfig($w,${from}List)
                set id [lindex [lindex $card 0] 0]
                set index -1
                set pos -1
                foreach cardList $pl {
                    incr index
                    if {[lindex [lindex $cardList 0] 0] == $id} {
                        set pos $index
                    }
                }
                if {$pos != -1} {
                    set pl [lreplace $pl $pos $pos]
                } else {
                    set index -1
                    foreach champList $pl {
                        incr index
                        set pos -1
                        set pindex -1
                        foreach cardList $champList {
                            incr pindex
                            if {[lindex [lindex $cardList 0] 0] == $id} {
                                set pos $pindex
                            }
                        }
                        if {$pos != -1} {
                            set champList [lreplace $champList $pos $pos]
                            set pl [lreplace $pl $index $index $champList]
                            break
                        }
                    }
                }
                set gameConfig($w,${from}List) $pl
                DisplayList $w $from
                if {$from == "outOfPlay"} {
                    set tempCard \
                        [CrossFire::GetCard [lindex [lindex $card 0] 0]]
                    set msg [CrossFire::GetCardDesc $tempCard]
		    set toopn "Out of Play (The Void)"
                    TellOpponents $w \
                        "Message returned card $msg from $toopn to $to!!!"
                    TellOpponents $w "Bell"
                }
            }
        "deck" - "draw" {
            set gameConfig($w,deckSize) [llength $gameConfig($w,drawPile)]
            UpdateDeckSize $w
        }
        "dungeon" - "realm*" - "rule" {
            set gameConfig($w,${from}Card) "none"
            DisplayLabel $w $from
            if {[regexp "realm*" $from]} {
                SetRealmStatus $w $from "unrazed"
            }
        }
        "hand" {
            set id [lindex [lindex $card 0] 0]
            set pos -1
            foreach handCard $gameConfig($w,handList) {
                incr pos
                if {[lindex $handCard 0] == $id} {
                    break
                }
            }
            set gameConfig($w,handList) \
                [lreplace $gameConfig($w,handList) $pos $pos]
            set gameConfig($w,handSize) [llength $gameConfig($w,handList)]
            DisplayHand $w
        }
    }

    if {$from != "card"} {
        foreach cardInfo $card {
            foreach {cardID status} $cardInfo break
            if {(($to == "hand") && ($from == "draw")) ||
                (($to == "deck") && ($from == "hand")) ||
                (($to == "spoils") && ($from == "draw"))} {
                # Shhh....don't tell them!
                set chatter ""
            } elseif {($gameConfig($w,hidePool) == 1) &&
                      ((($from == "hand") && ($to == "pool")) ||
                       (($from == "pool") && ($to == "hand")))} {
                # Dont want to tell the card ID if sending to a hidden pool,
                # returning to hand from a hidden pool
                set chatter "moved a hidden card from $from to $to"
            } elseif {$status != "normal"} {
                # Face down cards can go to Pool, Realm, Attach, or Hand
                if {$to == "pool"} {
                    set chatter "hides a card in the pool..."
                } elseif {[regexp "^(realm|attach)(.)\$" $to match \
                               which realm]} {
                    if {$which == "attach"} {
                        set chatter "hides a card under realm $realm"
                    } else {
                        set chatter "plays a realm face down at $realm"
                    }
                } elseif {$to == "hand"} {
                    regsub "^realm(.)" $from "realm \\1" from
                    set chatter "returns a hidden card from $from to the hand"
                }
            } else {
                set cardDesc \
                    [CrossFire::GetCardDesc [CrossFire::GetCard $cardID]]
                set chatter "moved card $cardDesc from $from to $to"
            }
            if {$chatter != ""} {
                TellOpponents $w "Message $chatter"
            }
        }
    }

    # Update opponents' handsize label when hand size changes (duh!)
    if {($to == "hand") || ($from == "hand")} {
        TellOpponents $w "HandSize $gameConfig($w,handSize)"
    }

    # Update opponents' decksize label
    if {($to == "deck") || ($from == "deck") ||
        ($to == "draw") || ($from == "draw")} {
        TellOpponents $w "DeckSize $gameConfig($w,deckSize)"
        
    }

    set gameConfig($w,cardID) ""
    if {$to != "hand"} {
        set gameConfig($w,selectionAt) ""
    }

    return $card
}

# Game::GetDeckDropPosition --
#
#   Asks user if the card should be placed on the top or bottom of
#   the draw pile.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   Either "top", "bottom", or null if canceled.
#
proc Game::GetDeckDropPosition {w} {

    variable gameConfig

    set gameConfig($w,deckDropPosition) "top"

    set tw [toplevel $w.getDeckDropPosition]
    wm title $tw "Choose Location"
    wm protocol $tw WM_DELETE_WINDOW "$tw.buttons.cancel invoke"

    frame $tw.top -borderwidth 1 -relief raised
    label $tw.top.l -text "Place card on:"
    radiobutton $tw.top.top -text "Top" -value "top" \
        -variable Game::gameConfig($w,deckDropPosition)
    radiobutton $tw.top.bottom -text "Bottom" -value "bottom" \
        -variable Game::gameConfig($w,deckDropPosition)
    grid $tw.top.l -sticky w -padx 3 -pady 8
    grid $tw.top.top -sticky w -padx 10 -pady 0
    grid $tw.top.bottom -sticky w -padx 10 -pady 8

    grid $tw.top -sticky nsew

    frame $tw.buttons -borderwidth 1 -relief raised
    button $tw.buttons.ok -text "OK" -width 8 \
        -command "set Game::gameConfig($w,getDeckDropPosition) ok"
    button $tw.buttons.cancel -text "Cancel" -width 8 \
        -command "set Game::gameConfig($w,getDeckDropPosition) cancel"
    grid $tw.buttons.ok $tw.buttons.cancel -padx 5 -pady 5

    grid $tw.buttons -sticky ew

    grid rowconfigure $tw 0 -weight 1
    grid columnconfigure $tw 0 -weight 1

    if {$CrossFire::platform == "windows"} {
        focus $tw
    }

    grab set $tw
    vwait Game::gameConfig($w,getDeckDropPosition)
    grab release $tw
    destroy $tw

    if {$gameConfig($w,getDeckDropPosition) == "cancel"} {
        set gameConfig($w,deckDropPosition) ""
    }

    return $gameConfig($w,deckDropPosition)
}

# Game::DiscardToDraw --
#
#   Returns all the cards in the discard pile to the draw pile and shuffles.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::DiscardToDraw {w {action ""}} {

    variable gameConfig

    set discards ""
    foreach cardInfo $gameConfig($w,discardList) {
        set id [lindex [lindex $cardInfo 0] 0]
        lappend discards [CrossFire::GetCard $id]
    }
    set gameConfig($w,discardList) ""
    DisplayList $w discard

    if {$action == ""} {
        set gameConfig($w,drawPile) "$discards $gameConfig($w,drawPile)"
        TellOpponents $w "Message has recycled the discard pile"
	ShuffleDrawPile $w "tell"
    } else {
        foreach card [ShuffleCards $discards] {
            set gameConfig($w,drawPile) \
                [linsert $gameConfig($w,drawPile) 0 $card]
        }
        TellOpponents $w "Message has returned discards to top of deck"
    }

    set gameConfig($w,deckSize) [llength $gameConfig($w,drawPile)]
    UpdateDeckSize $w
    TellOpponents $w "DeckSize $gameConfig($w,deckSize)"

    return
}

# Game::RandomDiscardToDraw --
#
#   Returns a random card in the discard pile to the draw pile and shuffles.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::RandomDiscardToDraw {w} {

    variable gameConfig

    # Pick a random card, remove from discard list, update displays
    set pos [expr int(rand() * [llength $gameConfig($w,discardList)])]
    set cardInfo [lindex $gameConfig($w,discardList) $pos]
    set gameConfig($w,discardList) \
	[lreplace $gameConfig($w,discardList) $pos $pos]
    DisplayList $w discard

    # Add to draw pile and update displays
    set id [lindex [lindex $cardInfo 0] 0]
    set card [CrossFire::GetCard $id]
    lappend gameConfig($w,drawPile) $card
    set gameConfig($w,deckSize) [llength $gameConfig($w,drawPile)]
    UpdateDeckSize $w
    TellOpponents $w "DeckSize $gameConfig($w,deckSize)"

    # Send message about what we did
    set cardDesc [CrossFire::GetCardDesc $card]
    set msg "Message has randomly picked $cardDesc from discards "
    append msg "and returned it to the deck"
    TellOpponents $w $msg
    ShuffleDrawPile $w tell

    return
}

# Game::ClickListBox --
#
#   Handles clicking a list box.  Updates the viewed card.
#
# Parameters:
#   w          : game toplevel name.
#   X, Y       : Click location from %X %Y in binding.
#   btnNumber  : Button number pressed.
#   which      : Listbox type.  (showHandLB, showDrawLB, seeDrawView)
#
# Returns:
#   Nothing.
#
proc Game::ClickListBox {w X Y btnNumber which {multi no}} {

    variable gameConfig

    set lbw $gameConfig($w,$which)

    focus [winfo toplevel $lbw]
    set line [$lbw nearest \
                  [expr [winfo pointery $lbw] - [winfo rooty $lbw]]]
    set cardID [lindex [$lbw get $line] end]

    if {$multi == "no"} {
        # Clear the list and highlight the line clicked.
        UpdateLBMultiSelect $w $which $cardID
        $lbw selection clear 0 end
        $lbw selection set $line
    } else {
        # Clear or set the selected line clicked.
        if {[lsearch [$lbw curselection] $line] != -1} {
            set lbSel $gameConfig($w,lbSel,$which)
            set pos [lsearch $lbSel $cardID]
            UpdateLBMultiSelect $w $which [lreplace $lbSel $pos $pos]
        } else {
            UpdateLBMultiSelect $w $which \
                "$gameConfig($w,lbSel,$which) $cardID"
        }
    }
    $lbw see $line

    if {$cardID == ""} {
        return
    }

    set gameConfig($w,cardID) $cardID
    if {$cardID != "Spellfire"} {
        ViewCard::UpdateCardView $gameConfig($w,view$lbw) \
            [CrossFire::GetCard $cardID]
    }

    return
}

# UpdateLBMultiSelect --
#
proc Game::UpdateLBMultiSelect {w which newList} {

    variable gameConfig

    set lbw $gameConfig($w,$which)

    # Cycle through the list box and change the selection numbers.
    # 1) If the card is in the original list, remove the selection number.
    # 2) If the card is in the new list, add the selection number.

    set oldList $gameConfig($w,lbSel,$which)
    set end [$lbw index end]
    for {set pos 0} {$pos < $end} {incr pos} {
        set line [$lbw get $pos]
        set testID [lindex $line end]
        if {[lsearch $oldList $testID] != -1} {
            $lbw delete $pos
            set line [lrange $line 2 end]
            $lbw insert $pos $line
            $lbw selection clear $pos
        }
        set num [lsearch $newList $testID]
        if {$num != -1} {
            $lbw delete $pos
            $lbw insert $pos "[incr num] - $line"
            $lbw selection set $pos
        }
    }

    set gameConfig($w,lbSel,$which) $newList

    return
}

# Game::MoveSelection --
#
#   Moves the selection up, down, or places card.
#
# Parameters:
#   w         : Game toplevel
#   dir       : U, D, R, or L
#
# Returns:
#   Nothing.
#
proc Game::MoveSelection {w dir} {

    variable gameConfig

    set which $gameConfig($w,selectionAt)
    if {$which == ""} {
        return
    }

    if {[focus] != [winfo toplevel $gameConfig($w,$which)]} return

    if {($dir == "U") || ($dir == "D")} {
        ClickTextBox $w "m" $dir 0 $which
        return
    }

    # Placing a card, get the card ID
    set cardID [GetSelectedCardID $w $which]

    if {$cardID != ""} {

        set card [CrossFire::GetCard $cardID]
        set cardType [lindex $card 3]
        set dest ""

        # Moving from the hand
        if {$which == "hand"} {
            if {$dir == "R"} {
                switch $cardType {
                    "21" {
                        set dest "dungeon"
                    }
                    "6" - "1" - "3" - "4" - "11" - "17" - "18" - "19" {
                        # Event, Ally, Blood Ability, Cleric Spell
                        # Psionic Power, Thief Ability, Unarmed Combat
                        # Wizard Spell
                        set dest "battlefield"
                    }
                    "8" {
                        # Holding. Must have an unrazed same world realm
                        # and no holding.
                        set hWorld [lindex $card 4]
                        foreach attach $gameConfig($w,attachList) {
                            regsub "attach" $attach "realm" realm
                            set rCardID $gameConfig($w,${realm}Card)

                            # Make sure we have an unrazed realm
                            if {($rCardID == "none") ||
                                ($gameConfig($w,${realm}Status) == "razed")} {
                                continue
                            }

                            # Make sure this is the same world
                            set rCard [CrossFire::GetCard $rCardID]
                            if {$hWorld != [lindex $rCard 4]} {
                                continue
                            }

                            set ok 1
                            foreach cardList $gameConfig($w,${attach}List) {
                                set id [lindex [lindex $cardList 0] 0]
                                set tCard [CrossFire::GetCard $id]
                                set type [lindex $tCard 3]
                                if {$type == "8"} {
                                    set ok 0
                                    break
                                }
                            }
                            if {$ok == 1} {
                                set dest $attach
                                break
                            }
                        }

                        if {$dest == ""} {
                            set msg "No where to place this holding!"
                            tk_messageBox -icon error -message $msg \
                                -parent $w -title "Place Holding Problem"
                        }
                    }
                    "13" {
                        # Realm. Look for first open realm slot. If none, look
                        # for first razed. Still none, yell!
                        foreach rl $gameConfig($w,realmLabel) {
                            set rn $gameConfig($rl)
                            if {$gameConfig($w,${rn}Card) == "none"} {
                                set dest $rn
                                break
                            }
                        }
                        if {$dest == ""} {
                            # Try for a raised
                            foreach rl $gameConfig($w,realmLabel) {
                                set rn $gameConfig($rl)
                                if {$gameConfig($w,${rn}Status) == "razed"} {
                                    set dest $rn
                                    break
                                }
                            }
                        }
                        if {$dest == ""} {
                            # Formation full of unrazed realms!
                            set msg "No where to place this realm!"
                            tk_messageBox -icon error -message $msg \
                                -parent $w -title "Place Realm Problem"
                        }
                    }
                    "15" {
                        set dest "rule"
                    }
                    "5" - "7" - "10" - "12" - "14" - "16" - "20" {
                        # Champion
                        set dest "pool"
                    }
                }
            } else {
                set dest "discard"
            }
        } elseif {$which == "pool"} {
            if {$dir == "R"} {
                switch $cardType {
                    "5" - "7" - "10" - "12" - "14" - "16" - "20" {
                        # Champion
                        set dest "battlefield"
                    }
                }
            } else {
                set dest "discard"
            }
        } elseif {$which == "battlefield"} {
            if {$dir == "R"} {
                switch $cardType {
                    "6" {
                        # Event
                        set dest "outOfPlay"
                    }
                    "5" - "7" - "10" - "12" - "14" - "16" - "20" {
                        # Champion
                        set dest "pool"
                    }
                    "13" {
                        # Realm. Look for first open realm slot. If none, look
                        # for first razed. Still none, yell!
                        foreach rl $gameConfig($w,realmLabel) {
                            set rn $gameConfig($rl)
                            if {$gameConfig($w,${rn}Card) == "none"} {
                                set dest $rn
                                break
                            }
                        }
                        if {$dest == ""} {
                            # Try for a raised
                            foreach rl $gameConfig($w,realmLabel) {
                                set rn $gameConfig($rl)
                                if {$gameConfig($w,${rn}Status) == "razed"} {
                                    set dest $rn
                                    break
                                }
                            }
                        }
                        if {$dest == ""} {
                            # Formation full of unrazed realms!
                            set msg "No where to place this realm!"
                            tk_messageBox -icon error -message $msg \
                                -parent $w -title "Place Realm Problem"
                        }
                    }
                    "15" {
                        set dest "rule"
                    }
                }
            } else {
                set dest "discard"
            }
        } elseif {$which == "discard"} {
            if {$dir == "R"} {
                set dest "pool"
            } else {
                set dest "hand"
            }
        } elseif {$which == "abyss"} {
            if {$dir == "R"} {
                set dest "pool"
            }
        } elseif {$which == "limbo"} {
            if {$dir == "R"} {
                set dest "pool"
            }
        }

        # We got a destination, so move that card!
        if {$dest != ""} {
            set gameConfig($w,cardID) $cardID
            MoveCard $w $dest $cardID $which
        }
    }

    return
}

# Game::ClickTextBox --
#
#   Handles clicking the a text box.  Updates the viewed card.
#
# Parameters:
#   w          : game toplevel name.
#   X, Y       : Click location from %X %Y in binding.
#   btnNumber  : Button number pressed.
#   which      : Textbox type.  (hand, pool)
#
# Returns:
#   Nothing.
#
proc Game::ClickTextBox {w X Y btnNumber which {side player}} {

    variable gameConfig

    if {$which == "hideHand"} {
        set which "hand"
        set hiding 1
    } else {
        set hiding 0
    }

    set tbw $gameConfig($w,$which)

    if {$X == "m"} {
        # Pressed either the up or down key. Move to next card (if any)
        set lastLine [expr int([$tbw index end]) - 1]
        set curSel [lindex [split [lindex [$tbw tag ranges select] 0] .] 0]
        if {$curSel == ""} {
            set curSel 1
        }

        set done 0
        if {$Y == "U"} {
            # Hand has a header at pos 1 always, so set min to 2
            # Not true anymore!
            if {($which == "hand") &&
                ($Config::config(Online,showCardTypeHeaders) == "Yes")} {
                set pos 2
            } else {
                set pos 1
            }
            while {$curSel > 1 && $done == 0} {
                incr curSel -1
                if {[lsearch [$tbw tag names $curSel.0] \
                         "cardTypeHeader"] == -1} {
                    set pos $curSel
                    set done 1
                }
            }
        } else {
            set pos $lastLine
            while {$curSel < $lastLine && $done == 0} {
                incr curSel
                if {[lsearch [$tbw tag names $curSel.0] \
                         "cardTypeHeader"] == -1} {
                    set pos $curSel
                    set done 1
                }
            }
        }
    } else {
        set x [expr $X - [winfo rootx $tbw]]
        set y [expr $Y - [winfo rooty $tbw]]
        set pos [expr int([$tbw index @$x,$y])]
    }

    if {[$tbw get 1.0 end] == "\n"} {
        return
    }

    ClearSelection $w
    set gameConfig($w,selectionAt) $which
    $tbw tag add select $pos.0 [expr $pos + 1].0
    $tbw see $pos.0

    if {[lsearch [$tbw tag names $pos.0] "cardTypeHeader"] > -1} {
        # This is not a card, but a header.
        return
    }

    set cardID [GetSelectedCardID $w $which]
    set gameConfig($w,cardID) $cardID

    if {$cardID != "Spellfire"} {
        ViewCard::UpdateCardView $gameConfig($w,cardView) \
            [CrossFire::GetCard $cardID]
    }

    # Do various activities depending which button was pressed.
    switch -- $btnNumber {
        1 {
            if {$side == "player"} {
                if {$hiding == 0} {
                    CrossFire::StartDrag $tbw target card $which
                } else {
                    CrossFire::StartDrag $tbw plus hideCard hide$which
                }
            }
        }

        2 {
        }

        3 {
            if {$cardID != "Spellfire"} {
		if {[regexp "attach*" $which] && ($side == "player")} {
		    MakeHoldingMenu $w $X $Y $which $cardID
		} elseif {($which == "pool") && ($side == "player")} {
                    MakePoolMenu $w $X $Y $cardID
                } elseif {($which == "pool") && ($side == "opponent")} {
		    MakeOpponentPoolMenu $w $X $Y $cardID
		} else {
		    MakeGenericMenu $w $X $Y $side $cardID $which
                }
            }
        }
    }

    return
}

# Game::MakeGenericMenu --
#
proc Game::MakeGenericMenu {w X Y side cardID which} {

    variable gameConfig

    if {[winfo exists $w.genMenu]} {
        destroy $w.genMenu
    }
    menu $w.genMenu -tearoff 0

    if {$side == "opponent"} {
	$w.genMenu add command -label "Select" \
	    -command "Game::SelectCard $w $cardID"
    } else {
	# player
	if {($which == "dungeon") || ($which == "rule")} {
	    set message "Message reminds us that the $which card "
	    set desc [CrossFire::GetCardDesc [CrossFire::GetCard $cardID]]
	    append message "$desc is in play."
	    $w.genMenu add command -label "Remind" \
		-command "Game::TellOpponents $w \{$message\}"
	}
    }

    if {($side == "player") && ($which == "battlefield")} {
        set card [CrossFire::GetCard $cardID]
        set typeID [lindex $card 3]
        if {[lsearch $CrossFire::championList $typeID] != -1} {
            $w.genMenu add command -label "Use Power" \
                -command "Game::UseCard $w $cardID {the power of }"
        } else {
            $w.genMenu add command -label "Use" \
                -command "Game::UseCard $w $cardID"
        }
        $w.genMenu add separator
    }

    $w.genMenu add command -label "View" \
	-command "ViewCard::View $w $cardID"

    tk_popup $w.genMenu $X $Y

    return
}

# Game::MakeHoldingMenu --
#
#   Makes the right-click pop-up menu for a holding.
#
# Parameters:
#   w          : Game toplevel.
#   X, Y       : Coordinates of the click from %X %Y
#   which      : Which holding (attachA, attachB, etc)
#   cardID     : The card ID for the holding.
#
# Returns:
#   Nothing.
#
proc Game::MakeHoldingMenu {w X Y which cardID} {

    variable gameConfig

    if {[winfo exists $w.holdingMenu]} {
        destroy $w.holdingMenu
    }
    menu $w.holdingMenu -tearoff 0

    foreach {
        setID cardNumber bonus cardTypeID world isAvatar cardName
        text rarity blueLine attrList usesList weight
    } [CrossFire::GetCard $cardID] break

    if {$CrossFire::cardTypeXRef($cardTypeID,name) == "Holding"} {
	# Make sure its a holding
	$w.holdingMenu add command -label "Use Holding" \
	    -command "Game::UseHolding $w $which $cardID"
	$w.holdingMenu add separator
	$w.holdingMenu add command \
	    -label "View" -command "ViewCard::View $w $cardID"

	tk_popup $w.holdingMenu $X $Y
    } else {
	# Just view the card if its not a holding
	ViewCard::View $w $cardID
    }

    return
}

# Game::UseHolding --
#
#   Sends a message about using a holding.
#
# Parameters:
#   w          : Game toplevel.
#   which      : Which holding (attachA, attachB, etc)
#   cardID     : The card ID for the holding.
#
# Returns:
#   Nothing.
#
proc Game::UseHolding {w which cardID} {

    set r [string range $which end end]
    set cardDesc \
	[CrossFire::GetCardDesc [CrossFire::GetCard $cardID]]
    set message "Message is using holding on realm $r - $cardDesc"
    TellOpponents $w $message

    return
}

# Game::SelectCard --
#
#   Sends a message about selecting an opponent's card.
#
# Parameters:
#   w          : Game toplevel.
#   cardID     : The card ID for the holding.
#
# Returns:
#   Nothing.
#
proc Game::SelectCard {w cardID {which none}} {

    variable gameConfig

    if {$cardID == "hidden"} {
	set cardDesc "hidden realm [string range $which end end]"
    } else {
	set cardDesc \
	    "card [CrossFire::GetCardDesc [CrossFire::GetCard $cardID]]"
    }

    set who $gameConfig($w,name)
    set message "Message selects ${who}'s $cardDesc"
    TellOpponents $w $message

    return
}

# Game::ClearSelection --
#
#   Clears the selection bar from the game window.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::ClearSelection {w} {

    variable gameConfig

    foreach tbw $gameConfig($w,textBoxes) {
        if {[winfo exists $tbw]} {
            $tbw tag remove select 1.0 end
        }
    }
    set gameConfig($w,selectionAt) ""

    update

    return
}

# Game::ClickLabel --
#
#   Handles clicking on a label (realm, rule, dungeon).
#
# Parameters:
#   w          : Game toplevel.
#   X, Y       : Coordinates of the click from %X %Y
#   btn        : Mouse button number.
#   which      : Which label was clicked.
#
# Returns:
#   Nothing.
#
proc Game::ClickLabel {w X Y btn which {side player}} {

    variable gameConfig

    set hiding [regexp "^hide(.+)\$" $which match which]

    if {$gameConfig($w,${which}Card) == "none"} {
        return
    }

    ClearSelection $w
    set cardID $gameConfig($w,${which}Card)
    set gameConfig($w,cardID) $cardID
    ViewCard::UpdateCardView $gameConfig($w,cardView) \
        [CrossFire::GetCard $cardID]

    switch $btn {
        1 {
            if {$side == "player"} {
                set lw $gameConfig($w,${which}Label)
                if {$hiding == 0} {
                    CrossFire::StartDrag $lw target card $which
                } else {
                    CrossFire::StartDrag $lw plus hideCard hide$which
                }
            }
        }

        2 {
        }

        3 {
            if {[regexp "realm*" $which]} {
		if {$side == "player"} {
		    MakeRealmMenu $w $X $Y $which $gameConfig($w,cardID)
		} else {
		    MakeOpponentRealmMenu $w $X $Y $which \
			$gameConfig($w,cardID)
		}
            } elseif {($which == "dungeon") && ($side == "opponent")} {
		MakeOpponentRealmMenu $w $X $Y $which \
		    $gameConfig($w,cardID)
	    } else {
		MakeGenericMenu $w $X $Y $side $gameConfig($w,cardID) $which
            }
        }
    }

    return
}

# Game::MakeOpponentRealmMenu --
#
#   Makes the right-click pop-up menu for an opponent's realm or dungeon.
#
# Parameters:
#   w          : Game toplevel.
#   X, Y       : Coordinates of the click from %X %Y
#   which      : Which realm (realmA, realmB, etc)
#   cardID     : The card ID for the realm.
#
# Returns:
#   Nothing.
#
proc Game::MakeOpponentRealmMenu {w X Y which cardID} {

    variable gameConfig

    if {[winfo exists $w.realmMenu]} {
        destroy $w.realmMenu
    }
    menu $w.realmMenu -tearoff 0

    if {$which == "dungeon"} {
	set status "dungeon"
	$w.realmMenu add command -label "Attack!" \
	    -command "Game::AttackRealm $w $which $cardID"
	$w.realmMenu add separator
    } else {
	set status $gameConfig($w,${which}Status)
	if {$status != "razed"} {
	    if {$status == "hide"} {
		set tCardID "hidden"
	    } else {
		set tCardID $cardID
	    }
	    $w.realmMenu add command -label "Attack!" \
		-command "Game::AttackRealm $w $which $tCardID"
	    $w.realmMenu add separator
	}
    }

    # Add Select
    if {$status == "hide"} {
	$w.realmMenu add command -label "Select" \
	    -command "Game::SelectCard $w hidden $which"
    } else {
	$w.realmMenu add command -label "Select" \
	    -command "Game::SelectCard $w $cardID"
    }

    # Add View, but disabled if hidden realm.
    $w.realmMenu add command \
        -label "View" -command "ViewCard::View $w $cardID"
    if {$status == "hide"} {
	$w.realmMenu entryconfigure end -state disabled
    }

    tk_popup $w.realmMenu $X $Y

    return
}

# Game::MakeRealmMenu --
#
#   Makes the right-click pop-up menu for a realm.  The menu will be either
#   Raze Realm or Unraze Realm.
#
# Parameters:
#   w          : Game toplevel.
#   X, Y       : Coordinates of the click from %X %Y
#   which      : Which realm (realmA, realmB, etc)
#   cardID     : The card ID for the realm.
#
# Returns:
#   Nothing.
#
proc Game::MakeRealmMenu {w X Y which cardID} {

    variable gameConfig

    if {[winfo exists $w.realmMenu]} {
        destroy $w.realmMenu
    }
    menu $w.realmMenu -tearoff 0

    if {$gameConfig($w,${which}Status) == "razed"} {
        $w.realmMenu add command -label "Unraze Realm" \
            -command "Game::SetRealmStatus $w $which unrazed"
    } else {
        $w.realmMenu add command -label "Raze Realm" \
            -command "Game::SetRealmStatus $w $which razed"
	$w.realmMenu add command -label "Use Realm" \
	    -command "Game::UseRealm $w $which $cardID"
        if {$gameConfig($w,${which}Status) == "unrazed"} {
            $w.realmMenu add command -label "Hide Realm" \
                -command "Game::SetRealmStatus $w $which hide"
        } else {
            $w.realmMenu add command -label "Reveal Realm" \
                -command "Game::SetRealmStatus $w $which reveal"
        }
    }
    $w.realmMenu add separator

    $w.realmMenu add command \
        -label "View" -command "ViewCard::View $w $cardID"

    tk_popup $w.realmMenu $X $Y

    return
}

# Game::UseRealm --
#
#   Sends a message about using a realm.
#
# Parameters:
#   w          : Game toplevel.
#   which      : Which realm (realmA, realmB, etc)
#   cardID     : The card ID for the realm.
#
# Returns:
#   Nothing.
#
proc Game::UseRealm {w which cardID} {

    set r [string range $which end end]
    set cardDesc \
	[CrossFire::GetCardDesc [CrossFire::GetCard $cardID]]
    set message "Message is using realm $r - $cardDesc"
    TellOpponents $w $message

    return
}

# Game::AttackRealm --
#
#   Sends a message about attacking a realm or dungeon
#
# Parameters:
#   w          : Game toplevel.
#   which      : Which realm (realmA, realmB, etc) or 'dungeon'
#   cardID     : The card ID for the realm.
#
# Returns:
#   Nothing.
#
proc Game::AttackRealm {w which cardID} {

    variable gameConfig

    if {$which != "dungeon"} {
	set which "realm [string range $which end end]"
    }

    if {$cardID == "hidden"} {
	set msg "hidden $which"
    } else {
	set msg "$which - "
	append msg \
	    [CrossFire::GetCardDesc [CrossFire::GetCard $cardID]]
    }
    set who $gameConfig($w,name)
    set message "Message is attacking ${who}'s $msg"
    TellOpponents $w $message

    return
}

# Game::MakePoolMenu --
#
#   Creates the context senisitive pop up menu for a card in the pool.
#
# Parameters:
#   w          : Game toplevel.
#   X, Y       : X,Y coordinates of the click
#   cardID     : Card ID clicked on.
#
# Returns:
#   Nothing.
#
proc Game::MakePoolMenu {w X Y cardID} {

    variable gameConfig

    if {[winfo exists $w.poolMenu]} {
        destroy $w.poolMenu
    }
    menu $w.poolMenu -tearoff 0

    $w.poolMenu add command \
        -label "Shuffle"\
        -command "Game::ShufflePool $w"

    regexp "$cardID (hidden|normal)" $gameConfig($w,poolList) \
        match which
    if {$which == "normal"} {
        $w.poolMenu add command \
            -label "Hide"\
            -command "Game::FlipPoolCard $w $cardID"
    } else {
        $w.poolMenu add command \
            -label "Reveal"\
            -command "Game::FlipPoolCard $w $cardID"
    }

    set card [CrossFire::GetCard $cardID]
    set typeID [lindex $card 3]
    if {[lsearch $CrossFire::championList $typeID] != -1} {
        $w.poolMenu add command \
            -label "Use Power" \
            -command "Game::UseCard $w $cardID {the special power of }"
        $w.poolMenu add command -label "Use to Play Card" -command \
            "Game::UseCard $w $cardID {} {to play the following card}"
    } else {
        $w.poolMenu add command \
            -label "Use" \
            -command "Game::UseCard $w $cardID"
    }

    $w.poolMenu add separator
    $w.poolMenu add command \
        -label "View" \
        -command "ViewCard::View $w $cardID"

    tk_popup $w.poolMenu $X $Y

    return
}

# Game::MakeOpponentPoolMenu --
#
#   Creates the context senisitive pop up menu for a card in the pool.
#
# Parameters:
#   w          : Game toplevel.
#   X, Y       : X,Y coordinates of the click
#   cardID     : Card ID clicked on.
#
# Returns:
#   Nothing.
#
proc Game::MakeOpponentPoolMenu {w X Y cardID} {

    variable gameConfig

    set card [CrossFire::GetCard $cardID]
    set testTypeID [lindex $card 3]

    if {[winfo exists $w.poolMenu]} {
	destroy $w.poolMenu
    }
    menu $w.poolMenu -tearoff 0

    if {[lsearch $CrossFire::championList $testTypeID] != -1} {
	$w.poolMenu add command \
	    -label "Attack!" \
	    -command "Game::AttackChampion $w $cardID"
	$w.poolMenu add separator
    }

    $w.poolMenu add command -label "Select" \
	-command "Game::SelectCard $w $cardID"
    $w.poolMenu add command \
	-label "View" \
	-command "ViewCard::View $w $cardID"
    tk_popup $w.poolMenu $X $Y

    return
}

# Game::AttackChampion --
#
#   Displays a message to the chat window that the player intends
#   to attack a champion in an opponent's pool.
#
# Parameters:
#   w          : Game toplevel.
#   cardID     : The card's ID.
#
# Returns:
#   Nothing.
#
proc Game::AttackChampion {w cardID} {

    variable gameConfig

    set cardDesc [CrossFire::GetCardDesc [CrossFire::GetCard $cardID]]
    set who $gameConfig($w,name)
    TellOpponents $w "Message is attacking $who's $cardDesc ..."

    return
}

# Game::UseCard --
#
#   Displays a message to the chat window that the player intends
#   to use the specified card.  Useful for cards like Hettman or cards
#   that are in a hidden pool.
#
# Parameters:
#   w          : Game toplevel.
#   cardID     : The card's ID.
#
# Returns:
#   Nothing.
#
proc Game::UseCard {w cardID {pre ""} {post ""}} {

    set cardDesc [CrossFire::GetCardDesc [CrossFire::GetCard $cardID]]

    TellOpponents $w "Message uses $pre$cardDesc $post..."

    return
}

# Game::ShufflePool --
#
#   Shuffles the position of the champions in a pool.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::ShufflePool {w} {

    variable gameConfig

    set pl {}
    foreach cardList [ShuffleCards $gameConfig($w,poolList)] {
        set out [list [lindex $cardList 0]]
        if {[llength $cardList] > 1} {
            foreach card [ShuffleCards [lrange $cardList 1 end]] {
                lappend out $card
            }
        }
        lappend pl $out
    }
    set gameConfig($w,poolList) $pl

    TellOpponents $w "Message has shuffled the pool around..."
    DisplayList $w pool

    return
}

# Game::FlipPoolCard --
#
#   Flips a card in the pool and redisplays the pool.
#
# Parameters:
#   w          : Game toplevel.
#   cardID     : ID of the card to flip.
#
# Returns:
#   Nothing.
#
proc Game::FlipPoolCard {w cardID} {

    variable gameConfig

#####
# Rework here. Add logic for "flipped" state

    regexp "$cardID (hidden|normal)" $gameConfig($w,poolList) \
        match state

    if {$state == "hidden"} {
        regsub "$cardID hidden" $gameConfig($w,poolList) \
            "$cardID normal" gameConfig($w,poolList)
        set cardDesc [CrossFire::GetCardDesc [CrossFire::GetCard $cardID]]
        set chatter "flips $cardDesc face up in the pool"
    } else {
        regsub "$cardID normal" $gameConfig($w,poolList) \
            "$cardID hidden" gameConfig($w,poolList)
        set chatter "flips a card face down in the pool"
    }

    TellOpponents $w "Message $chatter"
    DisplayList $w pool

    return
}

# Game::SetRealmStatus --
#
#   Changes a realm's status.  Changes the background color of the realm.
#
# Parameters:
#   w          : Game toplevel.
#   which      : Which realm. (realmA, realmB, etc)
#   status     : razed, unrazed, or hide
#
# Returns:
#   The status.
#
proc Game::SetRealmStatus {w which status {side player}} {

    variable gameConfig

    if {$status == "reveal"} {
        set status "unrazed"
        TellOpponents $w \
            "Message reveals realm at [string range $which end end]"
    } elseif {$side == "player"} {
        TellOpponents $w \
            "Message $status realm [string range $which end end]"
    }

    set gameConfig($w,${which}Status) $status
    if {$side == "player"} {
        DisplayLabel $w $which
        TellOpponents $w "Raze $which $status"
    } else {
        CardLabel $w $which ""
    }

    return $status
}

# Game::DisplayHand --
#
#   Displays the hand sorted by card type.
#
# Parameters:
#   w          : Game toplevel.
#   showCard   : Optional card to highlight and show.
#
# Returns:
#   Nothing.
#
proc Game::DisplayHand {w {showCard ""}} {

    variable gameConfig

    set tbw $gameConfig($w,hand)
    set yview [expr int([$tbw index @0,0]) - 1]
    $tbw delete 1.0 end

    set cardLine 0
    set lineCount 0
    set temp ""
    foreach tempCard [lsort $gameConfig($w,handList)] {
        lappend temp [CrossFire::GetCard [lindex $tempCard 0]]
    }
    foreach cardTypeID $CrossFire::cardTypeIDList {
        set cardTypeDesc $CrossFire::cardTypeXRef($cardTypeID,name)
        if {$Config::config(Online,showCardTypeHeaders) == "Yes"} {
            set displayedName 0
        } else {
            set displayedName 1
        }

        foreach card $temp {

            set testTypeID [lindex $card 3]
            if {$gameConfig($w,championMode) == "Class"} {
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

            if {$displayedName == 0} {
                if {$lineCount > 0} {
                    $tbw insert end "\n"
                }
                $tbw insert end $cardTypeDesc "cardTypeHeader"
                incr lineCount
                set displayedName 1
            }

            set desc [CrossFire::GetCardDesc $card end]
            if {$lineCount > 0} {
                if {$Config::config(Online,showCardTypeHeaders) == "Yes"} {
                    $tbw insert end "\n   "
                } else {
                    $tbw insert end "\n"
                }
            }
            if {$Config::config(Online,showIcon) == "Yes"} {
                $tbw image create end -image small$testTypeID
                $tbw insert end " "
            }
            $tbw insert end $desc
            incr lineCount

            if {[lindex $desc end] == $showCard} {
                set cardLine $lineCount
            }
        }
    }

    if {$showCard != ""} {
        # Highlight a specific card
        ClearSelection $w
        $tbw see $cardLine.0
        $tbw tag add select ${cardLine}.0 [expr $cardLine + 1].0
        set gameConfig($w,selectionAt) "hand"
        update
        ViewCard::UpdateCardView $gameConfig($w,cardView) \
            [CrossFire::GetCard $showCard]
    } else {
        # Move display to previous location
        $tbw yview scroll $yview units
    }

    UpdateHandSize $w

    return
}

# Game::DisplayLabel --
#
#   Update the name of one of the labels.
#
# Parameters:
#   w          : Game toplevel.
#   which      : rule, dungeon, realm*
#
# Returns:
#   Nothing.
#
proc Game::DisplayLabel {w which} {

    variable gameConfig

    set cardID $gameConfig($w,${which}Card)

    if {$cardID == "none"} {
	# Empty
        if {$which == "dungeon"} {
            set labelText "No Dungeon"
            set labelBGColor $Config::config(Online,color,dungeon)
            set labelFGColor $Config::config(Online,color,dungeonFG)
        } elseif {$which == "rule"} {
            set labelText "No Rule"
            set labelBGColor $Config::config(Online,color,rule)
            set labelFGColor $Config::config(Online,color,ruleFG)
        } else {
            set labelText "Realm [string range $which end end]"
            set labelBGColor $Config::config(Online,color,realm,unrazed)
            set labelFGColor $Config::config(Online,color,realm,unrazedFG)
        }
        set anchor "c"
    } else {
	# Placing a card
        if {$which == "dungeon"} {
            set labelBGColor $Config::config(Online,color,dungeon)
            set labelFGColor $Config::config(Online,color,dungeonFG)
        } elseif {$which == "rule"} {
            set labelBGColor $Config::config(Online,color,rule)
            set labelFGColor $Config::config(Online,color,ruleFG)
        } else {
	    # Realm that is displayed (un/razed)
            set state $gameConfig($w,${which}Status)
            set labelBGColor $Config::config(Online,color,realm,$state)
            set labelFGColor $Config::config(Online,color,realm,${state}FG)
        }
	set cardInfo [CrossFire::GetCard $cardID]
        set labelText [CrossFire::GetCardDesc $cardInfo end]
        set anchor "w"
    }

    $gameConfig($w,${which}Label) configure -anchor $anchor \
        -text $labelText -background $labelBGColor \
        -foreground $labelFGColor

    TellOpponents $w "DisplayLabel $which $cardID"

    return
}

# Game::DisplayList --
#
#   Draws the pool with champions in bold and their attachments
#   indented below them.
#
# Parameters:
#   w          : Game toplevel.
#   which      : pool, war, attachments, discard, abyss, limbo
#
# Returns:
#   Nothing.
#
proc Game::DisplayList {w which} {

    variable gameConfig

    if {![info exists gameConfig($w,$which)]} {
        # This would be realms 7-10 in a 6 realm game.
        return
    }

    set champList $CrossFire::championList
    set tbw $gameConfig($w,$which)
    set myList $gameConfig($w,${which}List)
    $tbw delete 1.0 end

    set lineCount 0
    foreach cardList $myList {

        incr lineCount
        if {$lineCount != 1} {
            $tbw insert end "\n"
        }

        foreach {firstCardID hiding} [lindex $cardList 0] break
        set firstCard [CrossFire::GetCard $firstCardID]
        set cardDesc [CrossFire::GetCardDesc $firstCard end]
        set cardType [lindex $firstCard 3]
        if {$Config::config(Online,showIcon) == "Yes"} {
            set i [$tbw image create end -image small$cardType]
            $tbw tag add $hiding [$tbw index $i]
            $tbw insert end " " $hiding
        }
        if {[lsearch $champList $cardType] != -1} {
            $tbw insert end $cardDesc "champion $hiding"
        } elseif {($cardType == 6) && ($which == "battlefield")} {
            $tbw insert end $cardDesc "event $hiding"
        } else {
            $tbw insert end $cardDesc $hiding
        }
        foreach attachment [lrange $cardList 1 end] {
            foreach {cardID hiding} $attachment break
            set card [CrossFire::GetCard $cardID]
            set cardDesc [CrossFire::GetCardDesc $card end]
            set cardType [lindex $card 3]
            $tbw insert end "\n   "
            if {$Config::config(Online,showIcon) == "Yes"} {
                set i [$tbw image create end -image small$cardType]
                $tbw tag add $hiding [$tbw index $i]
                $tbw insert end " " $hiding
            }
            $tbw insert end $cardDesc $hiding
        }
    }

    TellOpponents $w "DisplayList $which $myList"

    return
}

# Game::GetOpponent --
#
#   Creates a selection box of players that are in the realm, not oneself,
#   and are not already added.
#
# Parameters:
#   w          : Game toplevel.
#   type       : Opponent or Watcher
#
# Returns:
#   The selected player or nothing if canceled.
#
proc Game::GetOpponent {w type} {

    variable gameConfig

    # Get the list of names in the realm and remove those already added.
    # And do not allow the player to be listed.
    set allyList ""
    set pName [string tolower $gameConfig($w,name)]
    foreach champName $Chat::chatConfig(allyList) {
        set lName [string tolower $champName]
        if {([info exists gameConfig(tw,$lName)] == 0) &&
            ($lName != $pName)} {
            lappend allyList $champName
        }
    }

    # Some error checking.
    if {$allyList == ""} {
        tk_messageBox -title "Unable to Comply" -icon error \
            -message "No more players in this realm to add."
        return
    }

    # Get opponent to add
    set tw [toplevel $w.addOpponent]
    wm title $tw "Add $type"
    wm protocol $tw WM_DELETE_WINDOW "$tw.buttons.cancel invoke"

    frame $tw.top -relief raised -borderwidth 1

    frame $tw.top.sel
    label $tw.top.sel.l -text "Opponent:" -anchor e
    menubutton $tw.top.sel.mb -indicatoron 1 -width 20 \
        -menu $tw.top.sel.mb.menu -relief raised \
        -textvariable Game::gameConfig($w,addWho)
    menu $tw.top.sel.mb.menu -tearoff 0
    foreach opponent $allyList {
        $tw.top.sel.mb.menu add radiobutton \
            -label $opponent -value $opponent \
            -variable Game::gameConfig($w,addWho)
    }
    set gameConfig($w,addWho) [lindex $allyList 0]
    grid $tw.top.sel.l $tw.top.sel.mb -sticky ew -padx 3
    grid columnconfigure $tw.top.sel 1 -weight 1

    grid $tw.top.sel -sticky nsew -padx 5 -pady 5
    grid columnconfigure $tw.top 0 -weight 1
    grid rowconfigure $tw.top 0 -weight 1

    frame $tw.buttons -relief raised -borderwidth 1
    button $tw.buttons.show -text "Add" -width 8 \
        -command "set Game::gameConfig($w,addMode) ok"
    button $tw.buttons.cancel -text "Cancel" -width 8 \
        -command "set Game::gameConfig($w,addMode) cancel"
    grid $tw.buttons.show $tw.buttons.cancel -padx 5 -pady 5

    grid $tw.top -sticky nsew
    grid $tw.buttons -sticky ew
    grid columnconfigure $tw 0 -weight 1
    grid rowconfigure $tw 1 -weight 1

    update
    
    if {$CrossFire::platform == "windows"} {
        focus $tw
    }

    grab set $tw
    vwait Game::gameConfig($w,addMode)
    grab release $tw
    destroy $tw

    if {$gameConfig($w,addMode) == "cancel"} {
        set gameConfig($w,addWho) ""
    }

    return $gameConfig($w,addWho)
}

# Game::AddOpponent --
#
#   Creates a new opponent window.
#
# Parameters:
#   w
#
# Returns:
#   Nothing.
#
proc Game::AddOpponent {w {mode opponent}} {

    variable gameConfig

    set champName [GetOpponent $w Opponent]
    if {$champName == ""} return
    set name [string tolower $champName]
    for {set i 1} {$i <= 999} {incr i} {
        if {![info exists gameConfig($w,number,$i)]} {
            break
        } elseif {$gameConfig($w,number,$i) == ""} {
            break
        }
    }
    set key Opponent$i
    set ow [CreateOpponent $w $champName $gameConfig($w,numRealms) $key]

    lappend gameConfig($w,opponents) $ow
    lappend gameConfig($w,names) $name
    set gameConfig(tw,$name) $ow
    set gameConfig(ot,$name) "opponent"

    set gameConfig($w,viewTop,$key) $ow
    set gameConfig($w,number,$i) $key
    set gameConfig($w,key,$champName) $key
    set gameConfig($w,number,$champName) $i
    if {![info exists Config::config(Online,geometry,$key)]} {
        Config::Set Online,geometry,$key ""
    }
    if {$Config::config(Online,geometry,$key) != ""} {
        CrossFire::PlaceWindow $ow $Config::config(Online,geometry,$key)
    }

    if {$mode == "player"} {
        TellOpponents $w "Message is watching $champName"
    } else {
        TellOpponents $w "Message added $champName as an opponent"
    }

    return $champName
}

# Game::TellOpponents --
#
#   Sends a message to each of the opponents in the game.
#
# Parameters:
#   w
#   msg
#
# Returns:
#   Nothing.
#
proc Game::TellOpponents {w msg} {

    variable gameConfig

    if {$gameConfig($w,mode) == "Offline"} {
        if {[lindex $msg 0] == "Message"} {
            set tbw $gameConfig($w,solitaireMessages)
            regsub "^Message " $msg "" msg
            $tbw insert end "$msg\n"
            $tbw see end
        }
        return
    }

    set chatter ""

    switch -- [lindex $msg 0] {
        "Message" {
            regsub "^Message " $msg "" msg
            Chat::SendToServer "emote $msg"
        }
        "MoveFromDrawPile" {
            set opponent [lindex $msg 1]
            set out "tell $opponent $gameConfig(key) $gameConfig($w,name) "
            append out "MoveFromDrawPile [lrange $msg 2 end]"
            Chat::SendToServer $out
            set chatter "emote moves a card from $opponent's draw pile "
            append chatter "to [lindex $msg 3]"
        }
        "MoveFromHand" {
            set opponent [lindex $msg 1]
            set out "tell $opponent $gameConfig(key) $gameConfig($w,name) "
            append out "MoveFromHand [lrange $msg 2 end]"
            Chat::SendToServer $out
            set chatter "emote moves a card from $opponent's hand "
            append chatter "to [lindex $msg 3]"
        }
        "Raze" {
            foreach opponent $gameConfig($w,opponents) {
                set out "tell $gameConfig($opponent,name) $gameConfig(key) "
                append out "$gameConfig($w,name) $msg"
                Chat::SendToServer $out
            }
        }
        "ShowHand" {
            set opponent [lindex $msg 1]
            set out "tell $opponent $gameConfig(key) $gameConfig($w,name) "
            append out "ShowHand [lrange $msg 2 end]"
            Chat::SendToServer $out
        }
        "ShowDraw" {
            set opponent [lindex $msg 1]
            set out "tell $opponent $gameConfig(key) $gameConfig($w,name) "
            append out "ShowDraw [lrange $msg 2 end]"
            Chat::SendToServer $out
        }
        "TransferCard" {
            set opponent [lindex $msg 1]
            set out "tell $opponent $gameConfig(key) $gameConfig($w,name) "
            append out "TransferCard [lrange $msg 2 end]"
            Chat::SendToServer $out
        }
        default {
            foreach opponent $gameConfig($w,opponents) {
                set out "tell $gameConfig($opponent,name) $gameConfig(key) "
                append out "$gameConfig($w,name) $msg"
                Chat::SendToServer $out
            }
        }
    }

    if {$chatter != ""} {
        Chat::SendToServer $chatter
    }

    return
}

# Game::ReceiveOpponentCommand --
#
#   Handles receiving a command from a player.
#
# Parameters:
#   args       : The command.
#
# Returns:
#   Nothing.
#
proc Game::ReceiveOpponentCommand {args} {

    variable gameConfig

    set sender [lindex $args 1]
    set msg "emote received an online play command from "
    if {![info exists gameConfig(ot,[string tolower $sender])]} {
        append msg "non-player $sender!"
        Chat::SendToServer $msg
        return
    } elseif {$gameConfig(ot,[string tolower $sender]) == "watcher"} {
        append msg "Watcher $sender!"
        Chat::SendToServer $msg
        return
    }

    switch -- [lindex $args 2] {
        "AddGameNote" {
            #Received: !sf TestMan AddGameNote author title message
            foreach {dummy who cmd author title msg} $args break
            set w [winfo parent $gameConfig(tw,[string tolower $who])]
            AddGameNote $w $author $title $msg
        }
        "Bell" {
            bell
            after 250
            bell
        }
        "DisplayList" {
            #Received: !sf TestMan DisplayList which {cardID state} ...
            foreach {dummy who} $args break
            set w $gameConfig(tw,[string tolower [lindex $args 1]])
            eval CardList $w [lrange $args 3 end]
        }
        "DisplayLabel" {
            #Received: !sf TestMan DisplayLabel which cardID
            foreach {dummy who cmd which cardID} $args break
            set w $gameConfig(tw,[string tolower [lindex $args 1]])
            CardLabel $w $which $cardID
        }
        "Clear" {
            #Received: !sf TestMan Clear
            foreach {dummy who} $args break
            Clear $gameConfig(tw,[string tolower $who])
        }
	"CombatTotal" {
	    #Received: !sf TestMan CombatTotal total
            foreach {dummy who cmd total} $args break
	    set w $gameConfig(tw,[string tolower [lindex $args 1]])
	    set gameConfig($w,powTotal) $total
	}
        "DeckSize" {
            #Received: !sf TestMan DeckSize 4
            foreach {dummy who cmd size} $args break
            set w $gameConfig(tw,[string tolower $who])
            set gameConfig($w,deckSize) $size
            UpdateDeckSize $w
        }
        "DeleteGameNote" {
            #Received: !sf TestMan DeleteGameNote title
            foreach {dummy who cmd title} $args break
            set w [winfo parent $gameConfig(tw,[string tolower $who])]
            DeleteGameNote $w $title
        }
        "DiscardToDraw" {
            #Received: !sf TestMan DiscardToDraw
            foreach {dummy who} $args break
            set w $gameConfig(tw,[string tolower $who])
            $gameConfig($w,discard) delete 1.0 end
        }
        "EventDiscard" {
            #Received: !sf TestMan EventDiscard abyss
            foreach {dummy who cmd where} $args break
            set w $gameConfig(tw,[string tolower $who])
            set gameConfig($w,eventsTo) $where
        }
        "ExitGame" {
            #Received: !sf TestMan ExitGame
            foreach {dummy nWho} $args break
            set who [string tolower $nWho]
            set ow $gameConfig(tw,$who)
            RemoveOpponent $ow
        }
        "HandSize" {
            #Received: !sf TestMan HandSize 4
            foreach {dummy who cmd size} $args break
            set w $gameConfig(tw,[string tolower $who])
            set gameConfig($w,handSize) $size
            UpdateHandSize $w
        }
        "HidePool" {
            #Received: !sf TestMan HidePool 1
            foreach {dummy who cmd hide} $args break
            set w $gameConfig(tw,[string tolower $who])
            set gameConfig($w,hidePool) $hide
            CardList $w "pool" "HIDE"
        }
        "MoveFromDrawPile" {
            #Received: !sf TestMan MoveFromDrawPile cardID target
            foreach {dummy who cmd cardID target} $args break
            set w [winfo parent $gameConfig(tw,[string tolower $who])]
            MoveFromDrawPile $w $cardID $target $who
        }
        "MoveFromHand" {
            #Received: !sf TestMan MoveFromHand cardID target
            foreach {dummy who cmd cardID target} $args break
            set w [winfo parent $gameConfig(tw,[string tolower $who])]
            MoveFromHand $w $cardID $target $who
        }
        "Phase" {
            #Received: !sf TestMan Phase 2
            foreach {dummy who cmd phase} $args break
            set w $gameConfig(tw,[string tolower $who])
            set gameConfig($w,phase) $phase
            if {$phase == 0} {
                set pw [winfo parent $w]
            }
        }
        "Raze" {
            #Received: !sf TestMan Raze realmA razed
            foreach {dummy who cmd realm status} $args break
            set who [string tolower $who]
            SetRealmStatus $gameConfig(tw,$who) $realm $status "opponent"
        }
        "ShowDraw" {
            #Received: !sf TestMan ShowDraw cardID cardID ...
            eval ViewOpponentDraw [lindex $args 1] [lrange $args 3 end]
        }
        "ShowHand" {
            #Received: !sf TestMan ShowHand cardID cardID ...
            eval ViewOpponentHand [lindex $args 1] [lrange $args 3 end]
        }
        "TransferCard" {
            #Received: !sf TestMan TransferCard cardID cardID ...
            set w $gameConfig(tw,[string tolower [lindex $args 1]])
            set pw [winfo parent $w]
            set champID [lindex $args 3]
            set gameConfig($pw,cardID) $champID
            MoveCard $pw battlefield $champID "card" "player" "none"
            foreach cardID [lrange $args 4 end] {
                set gameConfig($pw,cardID) $cardID
                MoveCard $pw battlefield $cardID "card" "player" $champID
            }
        }
        default {
            foreach {dummy who cmd} $args break
            set w [winfo parent $gameConfig(tw,[string tolower $who])]
            set msg "Received unknown Online Play command!\n"
            append msg "All players MUST use the same version!!!"
            tk_messageBox -icon info \
                -title "Version Mismatch!!!" \
                -message $msg
            TellOpponents $w "Message $msg"
        }
    }

    return
}

# Game::CardList --
#
#   Display a list of cards for an opponents attachments, discards, etc.
#
# Parameters:
#   w          : Opponent toplevel.
#   which      : Which list to display.
#   args       : List of {cardID state} or HIDE to just redraw pool list.
#
# Returns:
#   Nothing.
#
proc Game::CardList {w which args} {

    variable gameConfig

    # Save list of card IDs that are already in the list so we don't spam the
    # players with event played sounds.
    set oldList {}
    foreach cardList $gameConfig($w,${which}List) {
        lappend oldList [lindex [lindex $cardList 0] 0]
    }

    if {$args != "HIDE"} {
        set gameConfig($w,${which}List) $args
    }

    set champList $CrossFire::championList
    set tbw $gameConfig($w,$which)
    set myList $gameConfig($w,${which}List)
    $tbw delete 1.0 end

    set lineCount 0
    foreach cardList $myList {

        incr lineCount
        if {$lineCount != 1} {
            $tbw insert end "\n"
        }

        if {($gameConfig($w,hidePool) == 1) && ($which == "pool")} {
	    # This will go away
            $tbw insert end "Spellfire" champion
            foreach attachment [lrange $cardList 1 end] {
                $tbw insert end "\n   Spellfire"
            }
        } else {
	    # Rework here.
            foreach {firstCardID hiding} [lindex $cardList 0] break
            set firstCard [CrossFire::GetCard $firstCardID]
            set cardDesc [CrossFire::GetCardDesc $firstCard end]
            set cardType [lindex $firstCard 3]
            if {$hiding != "normal"} {
                set cardDesc "Spellfire"
            } elseif {$Config::config(Online,showIcon) == "Yes"} {
                $tbw image create end -image small$cardType
                $tbw insert end " "
            }
            if {[lsearch $champList $cardType] != -1} {
                $tbw insert end $cardDesc champion
            } else {
                if {([lindex $firstCard 3] == 6) &&
                    ($which == "battlefield")} {
                    # Event, play event sound and color red
                    $tbw insert end $cardDesc event
                    if {[lsearch $oldList $firstCardID] == -1} {
                        CrossFire::PlaySound "PlayEvent"
                    }
                } else {
                    $tbw insert end $cardDesc
                }
            }
            foreach attachment [lrange $cardList 1 end] {
                foreach {cardID hiding} $attachment break
                if {$hiding == "normal"} {
                    set card [CrossFire::GetCard $cardID]
                    set cardDesc [CrossFire::GetCardDesc $card end]
                    set cardType [lindex $card 3]
                    $tbw insert end "\n   "
                    if {$Config::config(Online,showIcon) == "Yes"} {
                        $tbw image create end -image small$cardType
                        $tbw insert end " "
                    }
                    $tbw insert end $cardDesc
                } else {
                    $tbw insert end "\n   Spellfire"
                }
            }
        }
    }

    return
}

# Game::CardLabel --
#
#   Display a card label for an opponent's realms, dungeon, or rule.
#
# Parameters:
#   w          : Opponent toplevel.
#   which      : Which label to display.
#   cardID     : Card ID of the card.
#
# Returns:
#   Nothing.
#
proc Game::CardLabel {w which cardID} {

    variable gameConfig

    if {$cardID == ""} {
        set cardID $gameConfig($w,${which}Card)
    } else {
        set gameConfig($w,${which}Card) $cardID
    }

    if {$cardID == "none"} {
        if {$which == "dungeon"} {
            set labelText "No Dungeon"
            set labelBGColor $Config::config(Online,color,dungeon)
        } elseif {$which == "rule"} {
            set labelText "No Rule"
            set labelBGColor $Config::config(Online,color,rule)
        } else {
            set labelText "Realm [string range $which end end]"
            set labelBGColor $Config::config(Online,color,realm,unrazed)
        }
        set anchor "c"
    } else {
        set faceUp 1
        if {$which == "dungeon"} {
            set labelBGColor $Config::config(Online,color,dungeon)
        } elseif {$which == "rule"} {
            set labelBGColor $Config::config(Online,color,rule)
        } else {
            set state $gameConfig($w,${which}Status)
            set labelBGColor $Config::config(Online,color,realm,$state)
            if {$state == "hide"} {
                set faceUp 0
            }
        }
        if {$faceUp == 1} {
            set card [CrossFire::GetCard $cardID]
            set labelText [CrossFire::GetCardDesc $card end]
            set anchor "w"
        } else {
            set labelText "Spellfire"
            set anchor "c"
        }
    }
    $gameConfig($w,${which}Label) configure -anchor $anchor \
        -text $labelText -background $labelBGColor

    return
}

# Game::ShowHandToOpponent --
#
#   Shows the hand to an opponent.
#
# Parameters:
#   w         : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::ShowHandToOpponent {w} {

    variable gameConfig

    if {[llength $gameConfig($w,names)] == 0} {
        tk_messageBox -title "Unable to Comply" -icon error \
            -message "You have no opponents to show hand to!!"
        return
    }

    set idList ""
    foreach cardInfo $gameConfig($w,handList) {
        lappend idList [lindex [lindex $cardInfo 0] 0]
    }

    if {$idList == ""} {
        tk_messageBox -title "No Hand" -icon info \
            -message "You have no hand to show!"
        return
    }

    # Get opponent to show to
    set tw [toplevel $w.showCardsTo]
    wm title $tw "Show Hand To"
    wm protocol $tw WM_DELETE_WINDOW "$tw.buttons.cancel invoke"

    frame $tw.top -relief raised -borderwidth 1

    frame $tw.top.sel
    label $tw.top.sel.l -text "Opponent:" -anchor e
    menubutton $tw.top.sel.mb -indicatoron 1 -width 20 \
        -menu $tw.top.sel.mb.menu -relief raised \
        -textvariable Game::gameConfig($w,showWho)
    menu $tw.top.sel.mb.menu -tearoff 0
    foreach opponent $gameConfig($w,names) {
        $tw.top.sel.mb.menu add radiobutton \
            -label $opponent -value $opponent \
            -variable Game::gameConfig($w,showWho)
    }
    set gameConfig($w,showWho) [lindex $gameConfig($w,names) 0]
    grid $tw.top.sel.l $tw.top.sel.mb -sticky ew -padx 3
    grid columnconfigure $tw.top.sel 1 -weight 1

    grid $tw.top.sel -sticky nsew -padx 5 -pady 5
    grid columnconfigure $tw.top 0 -weight 1
    grid rowconfigure $tw.top 0 -weight 1

    frame $tw.buttons -relief raised -borderwidth 1
    button $tw.buttons.show -text "Show" \
        -command "set Game::gameConfig($w,showMode) ok"
    button $tw.buttons.cancel -text "Cancel" \
        -command "set Game::gameConfig($w,showMode) cancel"
    grid $tw.buttons.show $tw.buttons.cancel -padx 5 -pady 5

    grid $tw.top -sticky nsew
    grid $tw.buttons -sticky ew
    grid columnconfigure $tw 0 -weight 1
    grid rowconfigure $tw 1 -weight 1

    update
    
    if {$CrossFire::platform == "windows"} {
        focus $tw
    }

    grab set $tw
    vwait Game::gameConfig($w,showMode)
    grab release $tw

    destroy $tw

    if {$gameConfig($w,showMode) == "ok"} {
        set opponent $gameConfig($w,showWho)
        TellOpponents $w "ShowHand $opponent $idList"
        TellOpponents $w "Message shows hand to $opponent"
    }
    
    return
}

# Game::ViewOpponentHand --
#
#   Creates a popup list of an opponents hand
#
# Parameters:
#   who        : Opponent who's hand it is
#   args       : List of card IDs
#
# Returns:
#   Nothing.
#
proc Game::ViewOpponentHand {who args} {

    variable gameConfig

    set pw $gameConfig(tw,[string tolower $who])
    set w $pw.viewOpponentHand

    toplevel $w
    wm title $w "$who's Hand"
    wm protocol $w WM_DELETE_WINDOW "$w.buttons.close invoke"

    PanedWindow::Create $w.list -orient horizontal -size 0.35 \
        -width 400 -height 250
    set vohp1 [PanedWindow::Pane $w.list 1]
    set vohp2 [PanedWindow::Pane $w.list 2]

    $vohp1 configure -borderwidth 1 -relief raised

    frame $vohp1.cards
    set lbw $vohp1.cards.lb
    listbox $lbw -selectmode multiple -height 8 -exportselection 0 \
        -background white -foreground black -selectborderwidth 0 \
        -selectbackground blue -selectforeground white \
        -yscrollcommand "CrossFire::SetScrollBar $vohp1.cards.sb"
    scrollbar $vohp1.cards.sb -command "$vohp1.cards.lb yview"
    Balloon::Set $lbw "Hold down the 'control' key to select multiple cards."

    set gameConfig($pw,showHandLB) $lbw
    set gameConfig($pw,lbSel,showHandLB) ""
    bind $lbw <ButtonPress-1> \
        "Game::ClickListBox $pw %X %Y 1 showHandLB"
    bind $lbw <Control-ButtonPress-1> \
        "Game::ClickListBox $pw %X %Y 1 showHandLB yes"
    bindtags $lbw "$lbw all"

    grid $vohp1.cards.lb -sticky nsew
    grid columnconfigure $vohp1.cards 0 -weight 1
    grid rowconfigure $vohp1.cards 0 -weight 1

    grid $vohp1.cards -sticky nsew -padx 5 -pady 5
    grid columnconfigure $vohp1 0 -weight 1
    grid rowconfigure $vohp1 0 -weight 1

    $vohp2 configure -borderwidth 1 -relief raised
    set gameConfig($pw,view$lbw) [ViewCard::CreateCardView $vohp2.f]
    grid $vohp2.f -sticky nsew -padx 5 -pady 5
    grid columnconfigure $vohp2 0 -weight 1
    grid rowconfigure $vohp2 0 -weight 1

    frame $w.buttons -relief raised -borderwidth 1
    button $w.buttons.discard -text "Discard" \
        -command "Game::FinishViewOpponentHand $pw $w $who discard"
    button $w.buttons.close -text $CrossFire::close \
        -command "Game::FinishViewOpponentHand $pw $w $who ok"
    grid $w.buttons.discard $w.buttons.close -pady 5 -padx 5

    grid $w.list -sticky nsew 
    grid $w.buttons -sticky ew
    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 1

    $lbw delete 0 end
    foreach cardID $args {
        $lbw insert end \
            [CrossFire::GetCardDesc [CrossFire::GetCard $cardID] end]
    }

    if {$CrossFire::platform == "windows"} {
        focus $w
    }

    TellOpponents $pw "Message is viewing $who's hand..."

    return
}

# Game::FinishViewOpponentHand --
#
#   Called when user is finished viewing an opponent's hand.  Handles
#   discarding selected cards if necessary.
#
# Parameters:
#   pw         : Parent game toplevel
#   w          : Viewer toplevel
#   who        : Whos hand it is
#   cmd        : Which command button was pressed.
#
# Returns:
#   Nothing.
#
proc Game::FinishViewOpponentHand {pw w who cmd} {

    variable gameConfig

    if {$cmd == "discard"} {
        foreach cardID $gameConfig($pw,lbSel,showHandLB) {
            # Get the selected card ID and tell opponent to move 
            # from draw pile to new location
            TellOpponents [winfo parent $pw] \
                "MoveFromHand $who $cardID $cmd"
        }
    }

    destroy $w

    TellOpponents $pw "Message is finished viewing $who's hand"

    return
}

# Game::ShowDrawToOpponent --
#
#   Shows the draw pile to an opponent.
#
# Parameters:
#   w         : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::ShowDrawToOpponent {w} {

    variable gameConfig

    if {[llength $gameConfig($w,names)] == 0} {
        tk_messageBox -title "Unable to Comply" -icon error \
            -message "You have no opponents to show draw pile to!!"
        return
    }

    if {[llength $gameConfig($w,drawPile)] == 0} {
        tk_messageBox -title "No Draw" -icon info \
            -message "You have no draw pile to show!"
        return
    }

    # Get opponent to show to
    set tw [toplevel $w.showCardsTo]
    wm title $tw "Show Draw Pile To"
    wm protocol $tw WM_DELETE_WINDOW "$tw.buttons.cancel invoke"

    frame $tw.top -relief raised -borderwidth 1

    frame $tw.top.sel
    label $tw.top.sel.l -text "Opponent:"
    menubutton $tw.top.sel.mb -indicatoron 1 -width 20 \
        -menu $tw.top.sel.mb.menu -relief raised \
        -textvariable Game::gameConfig($w,showDrawWho)
    menu $tw.top.sel.mb.menu -tearoff 0
    foreach opponent $gameConfig($w,names) {
        $tw.top.sel.mb.menu add radiobutton \
            -label $opponent -value $opponent \
            -variable Game::gameConfig($w,showDrawWho)
    }
    set gameConfig($w,showDrawWho) [lindex $gameConfig($w,names) 0]
    grid $tw.top.sel.l $tw.top.sel.mb -sticky ew -padx 3
    grid columnconfigure $tw.top.sel 1 -weight 1

    grid $tw.top.sel -sticky nsew -padx 5 -pady 5

    if {![info exists gameConfig($w,viewDrawWhich)]} {
        set gameConfig($w,viewDrawWhich) "all"
        set gameConfig($w,viewDrawQty) 1
    }

    radiobutton $tw.top.all -text "All Cards" -value "all" \
        -variable Game::gameConfig($w,viewDrawWhich)

    frame $tw.top.some
    label $tw.top.some.l -text "Some Cards:" -anchor w
    radiobutton $tw.top.some.top -text "Top" -value "top" \
        -variable Game::gameConfig($w,viewDrawWhich)
    radiobutton $tw.top.some.bottom -text "Bottom" -value "bottom" \
        -variable Game::gameConfig($w,viewDrawWhich)
    menubutton $tw.top.some.mb -indicatoron 1 -width 3 \
        -menu $tw.top.some.mb.menu -relief raised \
        -textvariable Game::gameConfig($w,viewDrawQty)
    menu $tw.top.some.mb.menu -tearoff 0
    foreach qty {1 2 3 4 5 6 7 8 9} {
        $tw.top.some.mb.menu add radiobutton \
            -label $qty -value $qty \
            -variable Game::gameConfig($w,viewDrawQty)
    }
    
    grid $tw.top.some.l -columnspan 3 -sticky w
    grid $tw.top.some.top    -row 1 -column 0
    grid $tw.top.some.bottom -row 1 -column 1 -padx 5
    grid $tw.top.some.mb     -row 1 -column 2 -sticky ew
    grid columnconfigure $tw.top.some 2 -weight 1

    grid $tw.top.all  -sticky w -pady 5 -padx 5
    grid $tw.top.some -sticky w -pady 5 -padx 5

    grid columnconfigure $tw.top 0 -weight 1
    grid rowconfigure $tw.top {0 1 2} -weight 1

    frame $tw.buttons -relief raised -borderwidth 1
    button $tw.buttons.show -text "Show" \
        -command "set Game::gameConfig($w,showMode) ok"
    button $tw.buttons.cancel -text "Cancel" \
        -command "set Game::gameConfig($w,showMode) cancel"
    grid $tw.buttons.show $tw.buttons.cancel -padx 5 -pady 5

    grid $tw.top -sticky nsew
    grid $tw.buttons -sticky ew
    grid columnconfigure $tw 0 -weight 1
    grid rowconfigure $tw 0 -weight 1

    update

    if {$CrossFire::platform == "windows"} {
        focus $tw
    }

    grab set $tw
    vwait Game::gameConfig($w,showMode)
    grab release $tw

    destroy $tw

    set opponent $gameConfig($w,showDrawWho)

    if {$gameConfig($w,showMode) == "ok"} {
        set which $gameConfig($w,viewDrawWhich)
        set qty $gameConfig($w,viewDrawQty)
        if {$which == "all"} {
            set chatter "Message is showing $opponent the draw pile"
        } else {
            set s ""
            if {$qty > 1} {
                set s s
            }
            set chatter "Message is showing $opponent the $which "
            append chatter "$qty card$s from draw pile"
        }

        set drawPile $gameConfig($w,drawPile)
        set first 0
        set last end
        if {$which == "top"} {
            set last [expr $qty - 1]
        } elseif {$which == "bottom"} {
            set first [expr [llength $drawPile] - $qty]
        }
        set idList {}
        foreach card [lrange $drawPile $first $last] {
            lappend idList [lindex [CrossFire::GetCardDesc $card] 0]
        }

        TellOpponents $w $chatter
        TellOpponents $w "ShowDraw $opponent $idList"
    }

    return
}

# Game::ViewOpponentDraw --
#
#   Creates a popup list of an opponents draw pile.
#
# Parameters:
#   who        : Opponent who's draw pile it is
#   args       : List of card IDs
#
# Returns:
#   Nothing.
#
proc Game::ViewOpponentDraw {who args} {

    variable gameConfig

    set pw $gameConfig(tw,[string tolower $who])
    set w $pw.viewDraw

    toplevel $w
    wm title $w "$who's Draw Pile"
    wm protocol $w WM_DELETE_WINDOW "$w.buttons.close invoke"

    PanedWindow::Create $w.list -orient horizontal -size 0.35 \
        -width 400 -height 250
    set vodp1 [PanedWindow::Pane $w.list 1]
    set vodp2 [PanedWindow::Pane $w.list 2]

    $vodp1 configure -borderwidth 1 -relief raised

    frame $vodp1.cards
    set lbw $vodp1.cards.lb
    set gameConfig($pw,viewOpponentDrawLB) $lbw
    listbox $lbw -selectmode multiple -height 8 -exportselection 0 \
        -background white -foreground black -selectborderwidth 0 \
        -selectbackground blue -selectforeground white \
        -yscrollcommand "CrossFire::SetScrollBar $vodp1.cards.sb"
    scrollbar $vodp1.cards.sb -command "$vodp1.cards.lb yview"

    set gameConfig($pw,showDrawLB) $lbw
    set gameConfig($pw,lbSel,showDrawLB) ""
    bind $lbw <ButtonPress-1> \
        "Game::ClickListBox $pw %X %Y 1 showDrawLB"
    bind $lbw <Control-ButtonPress-1> \
        "Game::ClickListBox $pw %X %Y 1 showDrawLB yes"
    bindtags $lbw "$lbw all"

    grid $vodp1.cards.lb -sticky nsew
    grid columnconfigure $vodp1.cards 0 -weight 1
    grid rowconfigure $vodp1.cards 0 -weight 1

    grid $vodp1.cards -sticky nsew -padx 5 -pady 5
    grid columnconfigure $vodp1 0 -weight 1
    grid rowconfigure $vodp1 0 -weight 1

    $vodp2 configure -borderwidth 1 -relief raised
    set gameConfig($pw,view$lbw) [ViewCard::CreateCardView $vodp2.f]
    grid $vodp2.f -sticky nsew -padx 5 -pady 5
    grid columnconfigure $vodp2 0 -weight 1
    grid rowconfigure $vodp2 0 -weight 1

    frame $w.buttons -relief raised -borderwidth 1
    button $w.buttons.discard -text "Discard" \
        -command "Game::FinishViewOpponentDraw $pw $w $who discard"
    button $w.buttons.abyss -text "Abyss" \
        -command "Game::FinishViewOpponentDraw $pw $w $who abyss"
    button $w.buttons.top -text "Top" \
        -command "Game::FinishViewOpponentDraw $pw $w $who top"
    button $w.buttons.bottom -text "Bottom" \
        -command "Game::FinishViewOpponentDraw $pw $w $who bottom"
    button $w.buttons.close -text $CrossFire::close \
        -command "Game::FinishViewOpponentDraw $pw $w $who ok"
    grid $w.buttons.discard $w.buttons.abyss $w.buttons.top \
        $w.buttons.bottom $w.buttons.close -pady 5 -padx 3

    grid $w.list -sticky nsew 
    grid $w.buttons -sticky ew
    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 1

    $lbw delete 0 end
    foreach cardID $args {
        $lbw insert end \
            [CrossFire::GetCardDesc [CrossFire::GetCard $cardID] end]
    }

    if {$CrossFire::platform == "windows"} {
        focus $w
    }

    TellOpponents $pw "Message is viewing $who's draw pile..."

    return
}

# Game::FinishViewOpponentDraw --
#
#   Called when user is finished viewing an opponent's draw pile.
#   Handles moving selected cards to abyss, discards, or bottom.
#
# Parameters:
#   pw         : Parent game toplevel
#   w          : Viewer toplevel
#   who        : Whos hand it is
#   cmd        : Which command button was pressed.
#
# Returns:
#   Nothing.
#
proc Game::FinishViewOpponentDraw {pw w who cmd} {

    variable gameConfig

    set idList $gameConfig($pw,lbSel,showDrawLB)
    if {($cmd != "ok") && ($idList != "")} {

        # Reverse the list so the resultant moves to top are correct
        if {$cmd == "top"} {
            set newList ""
            foreach cardID $idList {
                set newList [linsert $newList 0 $cardID]
            }
            set idList $newList
        }

        foreach cardID $idList {
            # Get the selected card ID and tell opponent to move 
            # from draw pile to new location
            TellOpponents [winfo parent $pw] \
                "MoveFromDrawPile $who $cardID $cmd"
        }
    }

    destroy $w

    TellOpponents $pw "Message is finished viewing $who's draw pile"

    return
}

# Game::MoveFromDrawPile --
#
#   Move a specified card from the draw pile to another location.
#   Called when an opponent moves draw pile cards.
#
# Parameters:
#   w          : Game toplevel.
#   cardID     : Standard card id.
#   where      : Target location (abyss, discard, top, bottom)
#
# Returns:
#   Nothing.
#
proc Game::MoveFromDrawPile {w cardID where who} {

    variable gameConfig

    set card [CrossFire::GetCard $cardID]

    # Move it from its current location to its new one.
    set pos [lsearch $gameConfig($w,drawPile) $card]
    set gameConfig($w,drawPile) [lreplace $gameConfig($w,drawPile) $pos $pos]

    switch $where {
        "abyss" - "discard" {
            set gameConfig($w,cardID) $cardID
            MoveCard $w $where $cardID card
            set cardDesc [CrossFire::GetCardDesc $card]
            set chatter "card $cardDesc"
        }
        "top" {
            set gameConfig($w,drawPile) \
                [linsert $gameConfig($w,drawPile) 0 $card]
            set chatter "a card"
        }
        "bottom" {
            lappend gameConfig($w,drawPile) $card
            set chatter "a card"
        }
    }

    TellOpponents $w \
        "Message had $chatter moved from draw pile to $where by $who"

    return
}

# Game::MoveFromHand --
#
#   Move a specified card from the hand to another location.
#
# Parameters:
#   w          : Game toplevel.
#   cardID     : Standard card id.
#   where      : Target location (discard).
#
# Returns:
#   Nothing.
#
proc Game::MoveFromHand {w cardID where who} {

    variable gameConfig

    set card [CrossFire::GetCard $cardID]

    # Move it from its current location to its new one.
    set pos [lsearch $gameConfig($w,handList) $card]
    set gameConfig($w,handList) [lreplace $gameConfig($w,handList) $pos $pos]

    switch $where {
        "discard" {
            set gameConfig($w,cardID) $cardID
            MoveCard $w $where $cardID hand
            set cardDesc [CrossFire::GetCardDesc $card]
            set chatter "card $cardDesc"
        }
    }

    TellOpponents $w "Message had $chatter moved from hand to $where by $who"

    return
}

# Game::ViewDrawPile --
#
#   Creates the GUI for selecting which cards to view from draw pile.
#
# Parameters:
#   pw         : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::ViewDrawPile {pw} {

    variable gameConfig

    set w [toplevel ${pw}.viewDraw]
    wm title $w "View Draw Pile"
    wm protocol $w WM_DELETE_WINDOW "$w.buttons.cancel invoke"

    frame $w.select -borderwidth 1 -relief raised

    if {![info exists gameConfig($pw,viewWhich)]} {
        set gameConfig($pw,viewWhich) "all"
        set gameConfig($pw,viewQty) 1
    }
    radiobutton $w.select.all -text "All Cards" -value "all" \
        -variable Game::gameConfig($pw,viewWhich)

    frame $w.select.some
    label $w.select.some.l -text "Some Cards:" -anchor w
    radiobutton $w.select.some.top -text "Top" -value "top" \
        -variable Game::gameConfig($pw,viewWhich)
    radiobutton $w.select.some.bottom -text "Bottom" -value "bottom" \
        -variable Game::gameConfig($pw,viewWhich)
    menubutton $w.select.some.mb -indicatoron 1 -width 3 \
        -menu $w.select.some.mb.menu -relief raised \
        -textvariable Game::gameConfig($pw,viewQty)
    menu $w.select.some.mb.menu -tearoff 0
    foreach qty {1 2 3 4 5 6 7 8 9} {
        $w.select.some.mb.menu add radiobutton \
            -label $qty -value $qty \
            -variable Game::gameConfig($pw,viewQty)
    }
    
    grid $w.select.some.l -columnspan 3 -sticky w
    grid $w.select.some.top    -row 1 -column 0
    grid $w.select.some.bottom -row 1 -column 1 -padx 5
    grid $w.select.some.mb     -row 1 -column 2 -sticky ew
    grid columnconfigure $w.select.some 2 -weight 1

    grid $w.select.all  -sticky w -pady 5 -padx 5
    grid $w.select.some -sticky w -pady 5 -padx 5
    grid columnconfigure $w.select 0 -weight 1
    grid rowconfigure $w.select {0 1} -weight 1

    frame $w.buttons -borderwidth 1 -relief raised
    button $w.buttons.view -text "View" -width 6 \
        -command "set Game::gameConfig($pw,viewDraw) ok"
    button $w.buttons.cancel -text "Cancel" -width 6 \
        -command "set Game::gameConfig($pw,viewDraw) cancel"
    grid $w.buttons.view $w.buttons.cancel -padx 5 -pady 5

    grid $w.select -sticky nsew
    grid $w.buttons -sticky nsew

    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 1

    update

    if {$CrossFire::platform == "windows"} {
        focus $w
    }

    grab set $w
    vwait Game::gameConfig($pw,viewDraw)
    grab release $w
    destroy $w

    if {$gameConfig($pw,viewDraw) == "ok"} {
        SeeDrawPile $pw
    }

    return
}

# Game::SeeDrawPile --
#
#   Displays the requested number of cards from the draw pile and allows
#   for a selected card to be sent to the hand or top or bottom of draw pile.
#
# Parameters:
#   pw         : Game toplevel.
#
# Returns.
#   Nothing.
#
proc Game::SeeDrawPile {pw} {

    variable gameConfig

    set which $gameConfig($pw,viewWhich)
    set qty $gameConfig($pw,viewQty)
    if {$which == "all"} {
        set chatter "Message is viewing the draw pile..."
    } else {
        set s ""
        if {$qty > 1} {
            set s s
        }
        set chatter \
	    "Message is viewing the $which $qty card$s from draw pile"
    }

    TellOpponents $pw $chatter

    set w [toplevel ${pw}.showDraw]
    wm title $w "Draw Pile"
    wm protocol $w WM_DELETE_WINDOW "$w.buttons.cancel invoke"

    PanedWindow::Create $w.list -orient horizontal -size 0.35 \
        -width 400 -height 250
    set sdp1 [PanedWindow::Pane $w.list 1]
    set sdp2 [PanedWindow::Pane $w.list 2]

    $sdp1 configure -borderwidth 1 -relief raised

    frame $sdp1.cards

    frame $sdp1.cards.sel
    label $sdp1.cards.sel.l -text "View:"
    menubutton $sdp1.cards.sel.mb  -indicatoron 1 -width 10 \
        -menu $sdp1.cards.sel.mb.menu -relief raised \
        -textvariable Game::gameConfig($pw,selCardTypeName)
    set m [menu $sdp1.cards.sel.mb.menu -tearoff 0]
    foreach cardTypeID $CrossFire::cardTypeIDList {
        if {$cardTypeID <= 100} {
            $m add radiobutton \
                -label $CrossFire::cardTypeXRef($cardTypeID,name) \
                -variable Game::gameConfig($pw,selCardType) \
                -value $cardTypeID \
                -command "Game::ChangeShowDrawCardType $pw $cardTypeID"
        }
    }

    grid $sdp1.cards.sel.l $sdp1.cards.sel.mb -sticky ew
    grid columnconfigure $sdp1.cards.sel 1 -weight 1

    grid $sdp1.cards.sel -sticky ew

    set f [frame $sdp1.cards.list]
    set lbw $f.lb
    listbox $lbw -selectmode multiple -height 15 -exportselection 0 \
	-background white -foreground black -selectborderwidth 0 \
        -selectbackground blue -selectforeground white \
        -yscrollcommand "CrossFire::SetScrollBar $f.sb"
    Balloon::Set $lbw "Hold down the 'control' key to select multiple cards."
    scrollbar $f.sb -command "$lbw yview"
    grid $f.lb -sticky nsew

    set gameConfig($pw,seeDrawView) $lbw
    set gameConfig($pw,lbSel,seeDrawView) ""
    bind $lbw <ButtonPress-1> \
        "Game::ClickListBox $pw %X %Y 1 seeDrawView"
    bind $lbw <Control-ButtonPress-1> \
        "Game::ClickListBox $pw %X %Y 1 seeDrawView yes"
    bindtags $lbw "$lbw all"

    grid $f -sticky nsew -pady 3
    grid columnconfigure $f 0 -weight 1
    grid rowconfigure $f 0 -weight 1

    grid $sdp1.cards -sticky nsew -padx 5 -pady 5
    grid columnconfigure $sdp1.cards 0 -weight 1
    grid rowconfigure $sdp1.cards 1 -weight 1

    grid columnconfigure $sdp1 0 -weight 1
    grid rowconfigure $sdp1 0 -weight 1

    $sdp2 configure -borderwidth 1 -relief raised
    set gameConfig($pw,view$lbw) [ViewCard::CreateCardView $sdp2.f]
    grid $sdp2.f -sticky nsew -padx 5 -pady 5
    grid columnconfigure $sdp2 0 -weight 1
    grid rowconfigure $sdp2 0 -weight 1

    frame $w.buttons -borderwidth 1 -relief raised
    button $w.buttons.hand -text "Hand" -width 6 \
        -command "Game::FinishSeeDrawPile $pw $w $which hand"
    button $w.buttons.panes -text "Panes" -width 6 \
        -command "Game::FinishSeeDrawPile $pw $w $which panes"
    button $w.buttons.top -text "Top" -width 6 \
        -command "Game::FinishSeeDrawPile $pw $w $which top"
    button $w.buttons.top2 -text "Second" -width 6 \
        -command "Game::FinishSeeDrawPile $pw $w $which second"
    button $w.buttons.bottom -text "Bottom" -width 6 \
        -command "Game::FinishSeeDrawPile $pw $w $which bottom"
    button $w.buttons.abyss -text "Abyss" -width 6 \
        -command "Game::FinishSeeDrawPile $pw $w $which abyss"
    button $w.buttons.cancel -text $CrossFire::close -width 6 \
        -command "Game::FinishSeeDrawPile $pw $w $which cancel"
    grid $w.buttons.hand $w.buttons.panes $w.buttons.top $w.buttons.top2 \
	$w.buttons.bottom $w.buttons.abyss $w.buttons.cancel -padx 3 -pady 5

    grid $w.list -sticky nsew
    grid $w.buttons -sticky nsew
    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 1

    ChangeShowDrawCardType $pw 0

    if {$CrossFire::platform == "windows"} {
        focus $w
    }

    return
}

# Game::ChangeShowDrawCardType --
#
#   Updates the list of cards shown to displayed by card type.
#
# Parameters:
#   w         : toplevel
#   setTypeID : Card type ID to display
#
# Returns:
#   Nothing.
#
proc Game::ChangeShowDrawCardType {w selTypeID} {

    variable gameConfig

    set gameConfig($w,selCardType) $selTypeID
    set gameConfig($w,selCardTypeName) \
        $CrossFire::cardTypeXRef($selTypeID,name)
    set which $gameConfig($w,viewWhich)
    set qty $gameConfig($w,viewQty)
    set drawPile $gameConfig($w,drawPile)
    set first 0
    set last end
    if {$which == "top"} {
        set last [expr $qty - 1]
    } elseif {$which == "bottom"} {
        set first [expr [llength $drawPile] - $qty]
    }
    set cardList [lrange $drawPile $first $last]
    set championList $CrossFire::championList
    set lbw $gameConfig($w,seeDrawView)
    set gameConfig($w,lbSel,seeDrawView) ""

    $lbw delete 0 end
    foreach card $cardList {
        foreach {setID cardNumber trash typeID} $card {break}
        if {($selTypeID == 0) || ($selTypeID == $typeID) ||
            (($selTypeID == 99) && ([lsearch $championList $typeID] != -1)) ||
            (($selTypeID == 100) &&
             ($cardNumber > $CrossFire::setXRef($setID,setMax)))} {
            $lbw insert end [CrossFire::GetCardDesc $card end]
        }
    }

    return
}

# Game::FinishSeeDrawPile --
#
#   Called when user is finished viewing their draw pile.
#
# Parameters:
#   pw         : Parent game toplevel.
#   w          : Viewer toplevel.
#   which      : Which group of cards are being viewed.
#   cmd        : Which command button was pressed.
#
# Returns:
#   Nothing.
#
proc Game::FinishSeeDrawPile {pw w which cmd} {

    variable gameConfig

    if {$which == "all"} {
        ShuffleDrawPile $pw tell
    }

    set idList $gameConfig($pw,lbSel,seeDrawView)
    if {($cmd != "cancel") && ($idList != "")} {

        # Reverse the list so the resultant moves to top are correct
        if {($cmd == "top") || ($cmd == "second")} {
            set newList ""
            foreach cardID $idList {
                set newList [linsert $newList 0 $cardID]
            }
            set idList $newList
        }

        foreach cardID $idList {
            # find it in the draw pile list
            set card [CrossFire::GetCard $cardID]
            set pos [lsearch $gameConfig($pw,drawPile) $card]
            # Move it from its current location to its new one.
            set gameConfig($pw,drawPile) \
                [lreplace $gameConfig($pw,drawPile) $pos $pos]
            switch $cmd {
                "top" {
                    set gameConfig($pw,drawPile) \
                        [linsert $gameConfig($pw,drawPile) 0 $card]
		    set dest "top of draw pile"
                }
                "second" {
                    set gameConfig($pw,drawPile) \
                        [linsert $gameConfig($pw,drawPile) 1 $card]
		    set dest "second card in draw pile"
                }
                "hand" {
                    # Move it to the top then draw it
                    set gameConfig($pw,drawPile) \
                        [linsert $gameConfig($pw,drawPile) 0 $card]
                    DrawCard $pw hand
		    set dest "hand"
                }
		"panes" {
		    # Move it to the top, draw, and play to battlefield
		    set gameConfig($pw,drawPile) \
                        [linsert $gameConfig($pw,drawPile) 0 $card]
                    DrawCard $pw battlefield
		    set dest "panes of war"
		}
                "bottom" {
                    lappend gameConfig($pw,drawPile) $card
		    set dest "bottom of draw pile"
                }
		"abyss" {
		    # Move it to the top, draw, and play to abyss
		    set gameConfig($pw,drawPile) \
                        [linsert $gameConfig($pw,drawPile) 0 $card]
                    DrawCard $pw abyss
		    set dest "abyss"
		}
            }
        }

	set numCards [llength $idList]
	set s [expr {$numCards == 1 ? "" : "s"}]

        if {$dest != "abyss"} {
            TellOpponents $pw "Message moved $numCards card$s to the $dest"
        }
    }

    TellOpponents $pw "Message is finished viewing the draw pile"

    destroy $w

    return
}

# Game::UpdateHandSize --
#
#   Updates the hand size label on opponent GUIs.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::UpdateHandSize {w} {

    variable gameConfig

    if {$gameConfig($w,handSize) == 0} {
        set gameConfig($w,handLabel) "Hand Empty"
    } else {
        set gameConfig($w,handLabel) "Hand Size: $gameConfig($w,handSize)"
    }

    return
}

# Game::UpdateDeckSize --
#
#   Updates the deck size label for player and opponents.
#
# Parameteres:
#   w          : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::UpdateDeckSize {w} {

    variable gameConfig

    if {$gameConfig($w,deckSize) == 0} {
        set gameConfig($w,deckLabel) "Deck Empty"
    } else {
        set gameConfig($w,deckLabel) "Deck ($gameConfig($w,deckSize))"
    }

    return
}

# Game::HidePool --
#
#   Updates the opponents when a pool is hidden or revealed.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::HidePool {w} {

    variable gameConfig

    TellOpponents $w "HidePool $gameConfig($w,hidePool)"

    if {$gameConfig($w,hidePool)} {
        TellOpponents $w "Message hides pool"
    } else {
        TellOpponents $w "Message reveals pool"
    }

    return
}

# Game::AddWatcher --
#
#   Adds a game watcher.  This is basically an opponent without all the
#   windows for them.
#
# Parameters:
#   w          : Player toplevel.
#
# Returns:
#   Nothing.
#
proc Game::AddWatcher {w} {

    variable gameConfig

    set champName [GetOpponent $w Watcher]
    if {$champName == ""} return

    set name [string tolower $champName]
    set ow [CreateWatcher $w $champName]

    lappend gameConfig($w,opponents) $ow
    lappend gameConfig($w,names) $name
    set gameConfig(tw,$name) $ow
    set gameConfig(ot,$name) "watcher"

    TellOpponents $w "Message added $champName as a watcher"

}

# Game::CreateWatcher --
#
#   Creates a toplevel to represent the watcher.
#
# Parameters:
#   pw         : Parent toplevel.
#   name       : Name of watcher.
#
# Returns:
#   Nothing.
#
proc Game::CreateWatcher {pw name} {

    variable oppCount
    variable gameConfig

    incr oppCount

    set w [toplevel "${pw}.opponent$oppCount"]
    wm title $w "$name - Watching Game $gameConfig($pw,gameNum)"
    wm protocol $w WM_DELETE_WINDOW "$w.b invoke"

    button $w.b -text "Remove Watcher" \
        -command "Game::RemoveOpponent $w yes"
    grid $w.b -padx 5 -pady 5

    set gameConfig($w,name) $name
    set gameConfig($w,gameNum) $gameConfig($pw,gameNum)
    set gameConfig($w,opponents) ""
    set gameConfig($w,textBoxes) ""
    set gameConfig($w,mode) "Online"

    Initialize $w
    CreateCardView $w No
    AddWarPane $w $name watcher

    if {$CrossFire::platform == "windows"} {
        focus $w
    }

    return $w
}

# Game::Watch --
#
#   Creates a game watcher toplevel along with the game notes
#   and war panes windows.
#
# Parameters:
#   name       : Name of watcher.
#   numRealms  : Number of realms in the game.
#   mode       : is always online.
#
# Returns:
#   Nothing.
#
proc Game::Watch {name numRealms {mode Online}} {

    variable gameCount
    variable gameConfig

    incr gameCount

    set w [toplevel ".player$gameCount"]
    wm title $w "$name - Watch Game $gameCount"
    wm protocol $w WM_DELETE_WINDOW "Game::ExitGame $w"

    lappend gameConfig(gameList) $w
    set gameConfig($w,name) $name
    set gameConfig($w,gameNum) $gameCount
    set gameConfig($w,numRealms) $numRealms
    set gameConfig($w,names) ""
    set gameConfig($w,opponents) ""
    set gameConfig($w,textBoxes) ""
    set gameConfig($w,labels) ""
    set gameConfig($w,fileName) ""
    set gameConfig($w,mode) $mode
    set gameConfig($w,cardViewMode) $Config::config(Online,cardViewMode)

    AddWatcherMenuBar $w
    Initialize $w
    CreateCardView $w No
    CreatePanesOfWar $w "lurker"
    CreateGameNotes $w "Game $gameCount"

    frame $w.f
    label $w.f.l -text "Players:"

    frame $w.f.list
    listbox $w.f.list.lb -height 10 -width 20 \
        -exportselection 0 -selectborderwidth 0 -background white \
        -foreground black -selectbackground blue -selectforeground white \
        -yscrollcommand "CrossFire::SetScrollBar $w.f.list.sb"
    set gameConfig($w,playerListBox) $w.f.list.lb
    scrollbar $w.f.list.sb -command "$w.f.list.lb yview"
    grid $w.f.list.lb -sticky nsew
    grid columnconfigure $w.f.list 0 -weight 1
    grid rowconfigure $w.f.list 0 -weight 1

    grid $w.f.l -sticky w
    grid $w.f.list -sticky nsew
    grid columnconfigure $w.f 0 -weight 1
    grid rowconfigure $w.f 1 -weight 1

    grid $w.f -sticky nsew -padx 5 -pady 5
    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 1

    set msg "Message is watching a $numRealms realm game "
    append msg "using CrossFire $CrossFire::crossFireVersion"
    TellOpponents $w $msg

    return
}

# Game::AddWatcherMenuBar --
#
#   Creates the menu bar for a game watcher.
#
# Parameters:
#   w          : Watcher toplevel.
#
# Returns:
#   Nothing.
#
proc Game::AddWatcherMenuBar {w} {

    variable gameConfig

    menu $w.menubar

    $w.menubar add cascade \
        -label "Game" \
        -underline 0 \
        -menu $w.menubar.game

    menu $w.menubar.game -tearoff false
    $w.menubar.game add command \
        -label "Add Player..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+A" \
        -command "Game::AddPlayer $w"

    $w.menubar.game add separator
    set exitLabel "Close"
    set exitAccelerator "Alt+F4"
    if {$CrossFire::platform == "macintosh"} {
        # This is a Macintosh, so make the exit
        # accelerator more "Mac-ish"
        set exitLabel "Quit"
        set exitAccelerator "Command+Q"
    }
    $w.menubar.game add command \
        -label $exitLabel \
        -underline 1 \
        -accelerator $exitAccelerator \
        -command "Game::ExitGame $w"

    $w.menubar add cascade \
        -label "View" \
        -underline 0 \
        -menu $w.menubar.view
    menu $w.menubar.view -title "View"
    set gameConfig($w,viewMenu) $w.menubar.view
    $w.menubar.view add checkbutton \
        -label "Panes of War" \
        -underline 0 \
        -variable Game::gameConfig($w,show,Panes) \
        -onvalue "Yes" -offvalue "No" \
        -command "Game::ToggleView $w Panes"
    $w.menubar.view add checkbutton \
        -label "Game Notes" \
        -underline 0 \
        -variable Game::gameConfig($w,show,GameNotes) \
        -onvalue "Yes" -offvalue "No" \
        -command "Game::ToggleView $w GameNotes"
    $w.menubar.view add separator

    # This is a dummy menu, but needed!
    menu $w.menubar.notes -tearoff false
    set gameConfig($w,removeMenu) $w.menubar.notes

    $w config -menu $w.menubar

    # Game menu
    bind $w <$CrossFire::accelBind-a> "Game::AddPlayer $w"

    return
}

# Game::AddPlayer --
#
#   Called when adding a player to watch.  Gets the name
#   and adds it to the list of players.
#
# Parameters:
#   w          : Watcher toplevel.
#
# Returns:
#   Nothing.
#
proc Game::AddPlayer {w} {

    variable gameConfig

    set name [AddOpponent $w player]
    if {$name != ""} {
        $gameConfig($w,playerListBox) insert end $name
    }

    return
}

# Game::SaveWindowSize --
#
#   Save the position and size of one of the online play windows.
#
# Parameters:
#   w         : Game toplevel.
#   which     : Which window (Player, GameNotes, Panes, Opponent*)
#
# Returns:
#   Nothing.
#
proc Game::SaveWindowSize {w which} {

    variable gameConfig

    Config::Set Online,geometry,$which \
        [wm geometry $gameConfig($w,viewTop,$which)]

    return
}

# Game::UpdateCombatTotal --
#
#   Updates the player's total in the Panes of War
#
# Parameters:
#   w          : Game play top level
#
# Returns:
#   Nothing.
#
proc Game::UpdateCombatTotal {w} {

    variable gameConfig

    set total [string range $gameConfig($w,powTotalEntry) 0 14]
    set gameConfig($w,powTotalEntry) ""
    set gameConfig($w,powTotal) $total
    focus [winfo toplevel $gameConfig($w,powTotalEntryW)]
    TellOpponents $w [list CombatTotal $total]

    return
}

# Game::UpdateDrawQtyLabel --
#
#   In my neverending quest to rid the earth of programmers that cannot
#   understand the difference between 1 and more than 1, update the label
#   to be correct depending on the number of card(s) (HAHA) selected.
#
# Parameters:
#   w         : Game toplevel.
#
# Returns:
#   None.
#
proc Game::UpdateDrawQtyLabel {pw w} {

    variable gameConfig

    if {$gameConfig($pw,drawQty) == 1} {
        set gameConfig($pw,dsQtyText) " card for spoils."
    } else {
        set gameConfig($pw,dsQtyText) " cards for spoils."
    }

    update
    focus $pw
    focus $w

    return
}

# Game::DrawSpoils --
#
#   Find out how many cards the player can draw for spoils.  Draws that many
#   cards.  Then calls ViewDrawSpoils.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::DrawSpoils {pw} {

    variable gameConfig

    ### if {[DrawDisabled $w]} return

    set w $pw.dsStart

    toplevel $w
    wm title $w "Draw Spoils"
    wm protocol $w WM_DELETE_WINDOW "$w.buttons.cancel invoke"

    frame $w.top -borderwidth 1 -relief raised
    set f [frame $w.top.f]
    label $f.l1 -text "Draw "
    menubutton $f.mb -indicatoron 1 -width 2 \
        -menu $f.mb.menu -relief raised \
        -textvariable Game::gameConfig($pw,drawQty)
    menu $f.mb.menu -tearoff 0
    foreach qty {1 2 3 4 5 6 7 8 9} {
        $f.mb.menu add radiobutton -label $qty -value $qty \
            -variable Game::gameConfig($pw,drawQty) \
            -command "Game::UpdateDrawQtyLabel $pw $w"
    }
    set gameConfig($pw,qtyLabel) \
        [label $f.l2 -textvariable Game::gameConfig($pw,dsQtyText)]
    set gameConfig($pw,drawQty) 1
    UpdateDrawQtyLabel $pw $w
    grid $f.l1 $f.mb $f.l2
    grid columnconfigure $f 1 -weight 1

    grid $f -sticky ew -padx 5 -pady 5
    grid columnconfigure $w.top 0 -weight 1
    grid rowconfigure $w.top 0 -weight 1

    grid $w.top -sticky ew

    frame $w.buttons -borderwidth 1 -relief raised
    button $w.buttons.ok -text "OK" -width 8 \
        -command "set Game::gameConfig($pw,dsDone) ok"
    button $w.buttons.cancel -text "Cancel" -width 8 \
        -command "set Game::gameConfig($pw,dsDone) cancel"
    grid $w.buttons.ok $w.buttons.cancel -padx 5 -pady 5

    grid $w.buttons -sticky ew

    grid rowconfigure $w 0 -weight 1
    grid columnconfigure $w 0 -weight 1

    if {$CrossFire::platform == "windows"} {
        focus $w
    }

    grab set $w
    vwait Game::gameConfig($pw,dsDone)
    grab release $w
    destroy $w

    if {$gameConfig($pw,dsDone) == "ok"} {
        DrawCard $pw spoils $gameConfig($pw,drawQty)
        if {[llength $gameConfig($pw,spoilsList)]} {
            ViewDrawSpoils $pw
        }
    }

    return
}

# Game::UpdateSpoilsCardView --
#
#   Updates the displayed card when a radiobutton is selected or
#   the card title is clicked.
#
# Parameters:
#   pw        : Parent toplevel
#   cardID    : Card ID to display
#
# Returns:
#   Nothing.
#
proc Game::UpdateSpoilsCardView {pw cardID} {

    variable gameConfig

    ViewCard::UpdateCardView $gameConfig($pw,viewSpoilsCard) \
        [CrossFire::GetCard $cardID]

    return
}

# Game::ViewDrawSpoils --
#
#   Creates a popup list of cards drawn for spoils. The player can play
#   the card (first spoils only), keep in hand, or return to top of draw pile.
#
# Parameters:
#   pw        : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::ViewDrawSpoils {pw} {

    variable gameConfig

    set w $pw.viewSpoils

    toplevel $w
    wm title $w "View Spoils"
    wm protocol $w WM_DELETE_WINDOW "$w.buttons.ok invoke"

    frame $w.top -relief raised -borderwidth 1

    set count 0
    foreach cardInfo $gameConfig($pw,spoilsList) {

        set cardID [lindex $cardInfo 0]
        set card [CrossFire::GetCard $cardID]
        set cardDesc [CrossFire::GetCardDesc $card]
        incr count

        # Card name
        set f [frame $w.top.f$count]
        label $f.l -text $cardDesc
        bind $f.l <Button-1> "Game::UpdateSpoilsCardView $pw $cardID"
        grid $f.l -sticky w -columnspan 2

        # Flag the first drawn spoils. It is the only one allowed to be
        # played immediately.
        if {$count == 1} {
            set firstCardID $cardID
            set gameConfig($pw,spoilsCard,$cardID) "play"

            radiobutton $f.rbplay -text "Play immediately" -value "play" \
                -variable Game::gameConfig($pw,spoilsCard,$cardID) \
                -command "Game::UpdateSpoilsCardView $pw $cardID"
            grid $f.rbplay -sticky w -padx 10 -columnspan 2
        } else {
            set gameConfig($pw,spoilsCard,$cardID) "hand"
        }

        # Options to do with the card. To Hand or Draw.
        radiobutton $f.rbhand -text "Hand" \
            -variable Game::gameConfig($pw,spoilsCard,$cardID) \
            -value "hand" -command "Game::UpdateSpoilsCardView $pw $cardID"
        radiobutton $f.rbdraw -text "Draw Pile" \
            -variable Game::gameConfig($pw,spoilsCard,$cardID) \
            -value "draw" -command "Game::UpdateSpoilsCardView $pw $cardID"

        grid $f.rbhand $f.rbdraw -sticky w -padx 10
        grid columnconfigure $f 1 -weight 1

        grid $f -sticky nw -padx 3 -pady 3
    }

    grid rowconfigure $w.top $count -weight 1

    frame $w.view -relief raised -borderwidth 1
    set gameConfig($pw,viewSpoilsCard) [ViewCard::CreateCardView $w.view.f]
    UpdateSpoilsCardView $pw $firstCardID
    grid $gameConfig($pw,viewSpoilsCard) -sticky nsew
    grid columnconfigure $w.view 0 -weight 1
    grid rowconfigure $w.view 0 -weight 1

    frame $w.buttons -relief raised -borderwidth 1
    button $w.buttons.ok -text "OK" -width 8 \
        -command "Game::FinishViewSpoils $pw $w"
    grid $w.buttons.ok -pady 5 -padx 5

    grid $w.top $w.view -sticky nsew
    grid $w.buttons -sticky ew -columnspan 2
    grid columnconfigure $w 1 -weight 1
    grid rowconfigure $w 0 -weight 1

    if {$CrossFire::platform == "windows"} {
        focus $w
    }

    return
}

# Game::FinishViewSpoils --
#
#   Called when the player is finished deciding where the spoils card(s) are
#   going. Can be played (panes of war), draw pile, or hand.
#
# Parameters:
#   pw        : Parent game toplevel
#   w         : Spoils toplevel
#
# Returns:
#   Nothing.
#
proc Game::FinishViewSpoils {pw w} {

    variable gameConfig

    set sList $gameConfig($pw,spoilsList)
    set l [expr [llength $sList] - 1]
    set played  ""
    set numDraw 0
    set numHand 0

    for {set i $l} {$i >= 0} {incr i -1} {
        set cardInfo [lindex $sList $i]
        set cardID [lindex $cardInfo 0]
        set card [CrossFire::GetCard $cardID]
        set myCard [list $cardID "normal"]

        switch $gameConfig($pw,spoilsCard,$cardID) {
            "play" {
                lappend gameConfig($pw,battlefieldList) [list $myCard]
                DisplayList $pw "battlefield"
                set played $cardID
            }
            "draw" {
                set gameConfig($pw,drawPile) \
                    [linsert $gameConfig($pw,drawPile) 0 $card]
                incr numDraw
            }
            "hand" {
                lappend gameConfig($pw,handList) $myCard
                incr numHand
            }
        }
    }

    if {$played != ""} {
        set card [CrossFire::GetCard $played]
        set cardDesc [CrossFire::GetCardDesc $card]
        TellOpponents $pw "Message has played spoils card $cardDesc ..."
    }

    set message ""
    if {$numHand} {
        set gameConfig($pw,handSize) [llength $gameConfig($pw,handList)]
        TellOpponents $pw "HandSize $gameConfig($pw,handSize)"
        DisplayHand $pw $cardID
        set s [expr {$numHand > 1 ? "s" : ""}]
        append message "is keeping $numHand card$s in the hand"
    }

    if {$numDraw} {
        if {$numHand} {
            append message " and "
        }
        set s [expr {$numDraw > 1 ? "s" : ""}]
        append message "returned $numDraw card$s to the draw pile"
    }

    if {$message != ""} {
        TellOpponents $pw "Message $message"
    }

    destroy $w

    return
}