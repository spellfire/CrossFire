# PlayerGUI.tcl 20051206
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

# Game::Create --
#
#   Creates a new game toplevel.
#
# Parameters:
#   name       : Name of player.
#   numRealms  : Number of realms in the game.
#
# Returns:
#   Nothing.
#
proc Game::Create {name numRealms {mode Online}} {

    variable gameCount
    variable gameConfig
    variable lbWidth

    incr gameCount

    set w [toplevel ".player$gameCount"]
    if {$mode == "Offline"} {
        wm title $w "Solitaire Game $gameCount"
    } else {
        wm title $w "$name - Online Spellfire Game $gameCount"
    }
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
    set gameConfig($w,playerType) "player"
    set gameConfig($w,cardViewMode) $Config::config(Online,cardViewMode)
    set gameConfig($w,autoRecycleDiscards) "Yes"
    set gameConfig($w,parent) $w

    AddPlayerMenuBar $w
    Initialize $w
    CreateCardView $w
    CreatePanesOfWar $w
    CreateGameNotes $w "Game $gameCount"
    CreateOutOfPlay $w

    if {$mode == "Offline"} {
        set tw [toplevel $w.solNotes]
        wm title $tw "Game Messages - Game $gameCount"
        wm protocol $tw WM_DELETE_WINDOW CrossFire::DoNothing

        frame $tw.msg
        text $tw.msg.t -height 15 -width 60 -spacing1 2 \
            -exportselection 0 -background white -foreground black \
            -yscrollcommand "CrossFire::SetScrollBar $tw.msg.sb" \
            -wrap word -cursor {} -takefocus 0
        set tbw $tw.msg.t
        set gameConfig($w,solitaireMessages) $tbw
        scrollbar $tw.msg.sb -command "$tw.msg.t yview"

        grid $tw.msg.t -sticky nsew
        grid columnconfigure $tw.msg 0 -weight 1
        grid rowconfigure $tw.msg 0 -weight 1

        grid $tw.msg -sticky nsew -padx 3 -pady 3
        grid rowconfigure $tw 0 -weight 1
        grid columnconfigure $tw 0 -weight 1
    }

    # Main panes to divide hand & pool / formation & discards
    PanedWindow::Create $w.main -orient "h" -width 5i -height 4i \
	-size $Config::config(Online,mainPane)
    set gameConfig($w,mainPane) $w.main
    set mp1 [PanedWindow::Pane $w.main 1]
    set mp2 [PanedWindow::Pane $w.main 2]

    #
    # The left side holds the hand and pool.
    #
    PanedWindow::Create $mp1.left \
	-size $Config::config(Online,handPane)
    set gameConfig($w,handPane) $mp1.left
    set hp1 [PanedWindow::Pane $mp1.left 1]
    set hp2 [PanedWindow::Pane $mp1.left 2]

    $hp1 configure -relief raised -borderwidth 1
    $hp2 configure -relief raised -borderwidth 1

    # Hand pane.  Includes Draw button and Deck drop zone.
    set hf [frame $hp1.hand]

    label $hf.l -anchor w \
        -textvariable Game::gameConfig($w,handLabel)
    UpdateHandSize $w
    frame $hf.list
    text $hf.list.t -height 8 -width 20 -spacing1 2 \
        -exportselection 0 -background white -foreground black \
        -yscrollcommand "CrossFire::SetScrollBar $hf.list.sb" \
        -wrap none -cursor {} -takefocus 0
    set tbw $hf.list.t
    $tbw tag configure cardTypeHeader \
        -font "[lindex [$tbw configure -font] 3] bold"
    $tbw tag configure select -foreground white -background blue
    set gameConfig($w,hand) $tbw
    lappend gameConfig($w,textBoxes) $gameConfig($w,hand)
    scrollbar $hf.list.sb -command "$hf.list.t yview"
    grid $hf.list.t -sticky nsew
    grid columnconfigure $hf.list 0 -weight 1
    grid rowconfigure $hf.list 0 -weight 1

    bind $tbw <ButtonPress-1> "Game::ClickTextBox $w %X %Y 1 hand"
    bind $tbw <Shift-ButtonPress-1> \
        "Game::ClickTextBox $w %X %Y 1 hideHand"
    bind $tbw <ButtonPress-3> "Game::ClickTextBox $w %X %Y 3 hand"
    bindtags $tbw "$tbw all"

    CrossFire::DragTarget $tbw card "Game::MoveCard $w hand"
    CrossFire::DragTarget $tbw hideCard "Game::MoveCard $w hand"
    bind $tbw <ButtonRelease-1> "CrossFire::CancelDrag $tbw"

    grid $hf.l -sticky w
    grid $hf.list -sticky nsew

    # Draw Button and Draw Pile drop zone
    set df $hf.draw
    frame $df
    set gameConfig($w,drawButton) $df.b
    set gameConfig($w,drawReminder) "off"
    button $gameConfig($w,drawButton) -text "Draw" -underline 0 -width 6 \
        -takefocus 0 -command "Game::DrawCard $w hand"
    set gameConfig($w,drawBGColor) [$df.b cget -background]
    bind $gameConfig($w,drawButton) <ButtonPress-3> \
        "tk_popup $w.drawMulti %X %Y"

    set gameConfig($w,drawButtonMenu) [menu $w.drawMulti -tearoff 0]
    foreach qty {1 2 3 4 5 6 7 8 9} {
        $w.drawMulti add command \
            -label "Draw $qty" \
            -command "Game::DrawCard $w hand $qty"
    }
    $w.drawMulti add separator
    $w.drawMulti add command \
        -label "Reminder On" \
        -command "Game::ToggleButton $w draw"

    label $df.l -relief groove -foreground white -background maroon \
        -width 11 -textvariable Game::gameConfig($w,deckLabel)
    UpdateDeckSize $w
    CrossFire::DragTarget $df.l card "Game::MoveCard $w deck"

    grid $df.b $df.l -padx 3 -sticky ns
    grid $df -pady 3

    grid $hf -sticky nsew -padx 3 -pady 3
    grid columnconfigure $hf 0 -weight 1
    grid rowconfigure $hf 1 -weight 1

    grid columnconfigure $hp1 0 -weight 1
    grid rowconfigure $hp1 0 -weight 1

    # The Pool pane.  Include Knock button
    set pf [frame $hp2.pool]

    label $pf.l -text "Pool:" -anchor w 
    set gameConfig($w,poolLabel) $pf.l
    frame $pf.list
    text $pf.list.t -height 8 -width 20 -spacing1 2 \
        -exportselection 0 -background white -foreground black \
        -yscrollcommand "CrossFire::SetScrollBar $pf.list.sb" \
        -wrap none -cursor {} -takefocus 0
    set tbw $pf.list.t
    $tbw tag configure champion \
	-font "[lindex [$tbw configure -font] 3] bold"
    $tbw tag configure select -foreground white -background blue
    $tbw tag configure hidden -foreground black -background grey
    set gameConfig($w,pool) $tbw
    lappend gameConfig($w,textBoxes) $gameConfig($w,pool)
    scrollbar $pf.list.sb -command "$pf.list.t yview"
    grid $pf.list.t -sticky nsew
    grid columnconfigure $pf.list 0 -weight 1
    grid rowconfigure $pf.list 0 -weight 1

    bind $tbw <ButtonPress-1> "Game::ClickTextBox $w %X %Y 1 pool"
    bind $tbw <ButtonPress-3> "Game::ClickTextBox $w %X %Y 3 pool"
    bindtags $tbw "$tbw all"

    CrossFire::DragTarget $tbw card "Game::MoveCard $w pool"
    CrossFire::DragTarget $tbw hideCard "Game::MoveCard $w pool"
    bind $tbw <ButtonRelease-1> "CrossFire::CancelDrag $tbw"

    grid $pf.l -sticky w
    grid $pf.list -sticky nsew
    grid columnconfigure $pf 0 -weight 1
    grid rowconfigure $pf 1 -weight 1

    grid $pf -sticky nsew -padx 3 -pady 3
    grid columnconfigure $pf 0 -weight 1
    grid rowconfigure $pf 1 -weight 1

    grid columnconfigure $hp2 0 -weight 1
    grid rowconfigure $hp2 0 -weight 1

    grid $mp1.left -sticky nsew
    grid columnconfigure $mp1 0 -weight 1
    grid rowconfigure $mp1 0 -weight 1

    #
    # The right side holds the formation and discards.
    #
    PanedWindow::Create $mp2.right \
	-size $Config::config(Online,formPane)
    set gameConfig($w,formPane) $mp2.right
    set fp1 [PanedWindow::Pane $mp2.right 1]
    set fp2 [PanedWindow::Pane $mp2.right 2]

    $fp1 configure -relief raised -borderwidth 1
    $fp2 configure -relief raised -borderwidth 1

    #
    # Build the formation of realms
    #
    set ff [frame $fp1.formation]

    set lastRealmColumn $gameConfig(formation,$numRealms,lastColumn)
    set lastRealmRow $gameConfig(formation,$numRealms,lastRow)
    set formation $gameConfig(formation,$numRealms,normal)

    foreach {realm row column} $formation {

        if {$realm == "phase"} {
            set phaseRow $row
            set phaseCol $column
            continue
        } elseif {$realm == "extra"} {
            set extraRow $row
            set extraCol $column
            continue
        }

        frame $ff.f$realm

        set rl $ff.f$realm.realm
        label $rl -relief groove -width $lbWidth -text "Realm $realm" \
            -background $Config::config(Online,color,realm,unrazed) \
            -foreground $Config::config(Online,color,realm,unrazedFG)
        lappend gameConfig($w,realmLabel) $rl
        set gameConfig($rl) "realm$realm"
        set gameConfig($w,realm${realm}Label) $rl
        set gameConfig($w,realm${realm}Card) "none"
        set gameConfig($w,realm${realm}Status) "unrazed"

        set lw $ff.f$realm.realm
        bind $lw <ButtonPress-1> "Game::ClickLabel $w %X %Y 1 realm$realm"
        bind $lw <Shift-ButtonPress-1> \
            "Game::ClickLabel $w %X %Y 1 hiderealm$realm"
        bind $lw <ButtonPress-3> "Game::ClickLabel $w %X %Y 3 realm$realm"

        CrossFire::DragTarget $lw card "Game::MoveCard $w realm$realm"
        CrossFire::DragTarget $lw hideCard "Game::MoveCard $w realm$realm"
        bind $lw <ButtonRelease-1> "CrossFire::CancelDrag $lw"

        frame $ff.f$realm.attach
        set tbw $ff.f$realm.attach.t
        text $tbw -height 3 -width 20 -spacing1 2 -exportselection 0 \
            -foreground $Config::config(Online,color,holdingFG) \
            -background $Config::config(Online,color,holding) \
            -wrap none -cursor {} -takefocus 0 -yscrollcommand \
            "CrossFire::SetScrollBar $ff.f$realm.attach.sb"
        $tbw tag configure select -foreground white -background blue
        $tbw tag configure hidden -foreground black -background grey
        lappend gameConfig($w,attachList) "attach$realm"
        set gameConfig($w,attach$realm) $tbw
        set gameConfig($tbw) "attach$realm"
        lappend gameConfig($w,textBoxes) $gameConfig($w,attach$realm)
        scrollbar $ff.f$realm.attach.sb -command "$tbw yview"
        grid $ff.f$realm.attach.t -sticky nsew
        grid columnconfigure $ff.f$realm.attach 0 -weight 1
        grid rowconfigure $ff.f$realm.attach 0 -weight 1

        bind $tbw <ButtonPress-1> \
	    "Game::ClickTextBox $w %X %Y 1 attach$realm"
        bind $tbw <ButtonPress-3> \
	    "Game::ClickTextBox $w %X %Y 3 attach$realm"
        bindtags $tbw "$tbw all"

        CrossFire::DragTarget $tbw card "Game::MoveCard $w attach$realm"
        CrossFire::DragTarget $tbw hideCard "Game::MoveCard $w attach$realm"
        bind $tbw <ButtonRelease-1> "CrossFire::CancelDrag $tbw"

        grid $ff.f$realm.realm -sticky ew
        grid $ff.f$realm.attach -sticky nsew
        grid $ff.f$realm -row $row -column $column -columnspan 2 \
            -sticky nsew -padx 3 -pady 3
        grid columnconfigure $ff.f$realm 0 -weight 1
        grid rowconfigure $ff.f$realm 1 -weight 1
    }

    # Phase buttons.
    frame $ff.phase

    label $ff.phase.l -text "Phase:" -anchor w
    grid $ff.phase.l -sticky w -columnspan 6
    foreach phase {0 1 2 3 4 5} {
        radiobutton $ff.phase.phase$phase -width 2 \
            -text $phase -value $phase -indicatoron 0 -takefocus 0 \
            -variable Game::gameConfig($w,phase) \
            -command "Game::ChangePhase $w $phase"
        grid $ff.phase.phase$phase -row 1 -column $phase -sticky ew
        grid columnconfigure $ff.phase $phase -weight 1
    }
    set gameConfig($w,phase) 0

    # Knock button
    set gameConfig($w,knockButton) $ff.phase.knock
    set gameConfig($w,knockReminder) "off"
    grid [button $gameConfig($w,knockButton) -text "Knock" -underline 0 \
              -takefocus 0 -width 6 -command "Game::EndTurn $w"] \
        -pady 5 -columnspan 6
    set gameConfig($w,knockBGColor) [$ff.phase.knock cget -background]
    bind $gameConfig($w,knockButton) <ButtonPress-3> \
        "tk_popup $w.knockMulti %X %Y"

    set gameConfig($w,knockButtonMenu) [menu $w.knockMulti -tearoff 0]
    $w.knockMulti add command \
        -label "Reminder On" \
        -command "Game::ToggleButton $w knock"

    # Put the Rule and Dungeon cards to right of realm A
    frame $ff.extra

    # Dungeon Card
    label $ff.extra.dungeon -foreground black \
        -background $Config::config(Online,color,dungeon) \
        -foreground $Config::config(Online,color,dungeonFG) \
        -text "No Dungeon" -relief groove -width $lbWidth
    set gameConfig($w,dungeonLabel) $ff.extra.dungeon
    set gameConfig($w,dungeonCard) "none"

    set lw $ff.extra.dungeon
    bind $lw <ButtonPress-1> "Game::ClickLabel $w %X %Y 1 dungeon"
    bind $lw <ButtonPress-3> "Game::ClickLabel $w %X %Y 3 dungeon"
    bind $lw <ButtonRelease-1> "CrossFire::CancelDrag $lw"

    CrossFire::DragTarget $lw card "Game::MoveCard $w dungeon"
    bind $lw <ButtonRelease-1> "CrossFire::CancelDrag $lw"

    # Rule Card
    label $ff.extra.rule -foreground black \
        -background $Config::config(Online,color,rule) \
        -foreground $Config::config(Online,color,ruleFG) \
        -text "No Rule" -relief groove -width $lbWidth
    set gameConfig($w,ruleLabel) $ff.extra.rule
    set gameConfig($w,ruleCard) "none"

    set lw $ff.extra.rule
    bind $lw <ButtonPress-1> "Game::ClickLabel $w %X %Y 1 rule"
    bind $lw <ButtonPress-3> "Game::ClickLabel $w %X %Y 3 rule"

    CrossFire::DragTarget $lw card "Game::MoveCard $w rule"
    bind $lw <ButtonRelease-1> "CrossFire::CancelDrag $lw"

    grid $ff.extra.dungeon -sticky ew
    grid $ff.extra.rule -sticky ew -pady 3
    grid columnconfigure $ff.extra 0 -weight 1

    grid $ff.phase -row $phaseRow -column $phaseCol -columnspan 2 \
        -sticky new -padx 3 -pady 3

    grid $ff.extra -row $extraRow -column $extraCol -columnspan 2 \
        -sticky new -padx 3 -pady 3

    set rowList ""
    for {set i 0} {$i <= $lastRealmRow} {incr i} {
        lappend rowList $i
    }

    set columnList ""
    for {set i 0} {$i <= [expr $lastRealmColumn + 1]} {incr i} {
        lappend columnList $i
    }
    grid $ff -sticky nsew -padx 3 -pady 3
    grid rowconfigure $ff $rowList -weight 1
    grid columnconfigure $ff $columnList -weight 1

    grid columnconfigure $fp1 0 -weight 1
    grid rowconfigure $fp1 0 -weight 1

    #
    # The various discard type places
    #
    set df $fp2.discard
    frame $df

    # Discard pile
    frame $df.discard
    label $df.discard.l -text "Discard:" -anchor w
    frame $df.discard.list
    text $df.discard.list.t -height 8 -width 20 -spacing1 2 \
        -exportselection 0 -background white -foreground black \
        -yscrollcommand "CrossFire::SetScrollBar $df.discard.list.sb" \
        -wrap none -cursor {} -takefocus 0
    set tbw $df.discard.list.t
    $tbw tag configure select -foreground white -background blue
    set gameConfig($w,discard) $tbw
    set gameConfig($tbw) "discard"
    lappend gameConfig($w,textBoxes) $gameConfig($w,discard)
    scrollbar $df.discard.list.sb -command "$tbw yview"
    grid $df.discard.list.t -sticky nsew
    grid columnconfigure $df.discard.list 0 -weight 1
    grid rowconfigure $df.discard.list 0 -weight 1

    bind $tbw <ButtonPress-1> "Game::ClickTextBox $w %X %Y 1 discard"
    bind $tbw <ButtonPress-3> "Game::ClickTextBox $w %X %Y 3 discard"
    bindtags $tbw "$tbw all"

    CrossFire::DragTarget $tbw card "Game::MoveCard $w discard"
    bind $tbw <ButtonRelease-1> "CrossFire::CancelDrag $tbw"

    grid $df.discard.l -sticky w
    grid $df.discard.list -sticky nsew
    grid columnconfigure $df.discard 0 -weight 1
    grid rowconfigure $df.discard 1 -weight 1

    # The Abyss
    frame $df.abyss
    label $df.abyss.l -text "Abyss:" -anchor w
    frame $df.abyss.list
    text $df.abyss.list.t -height 8 -width 20 -spacing1 2 \
        -exportselection 0 -background white -foreground black \
        -yscrollcommand "CrossFire::SetScrollBar $df.abyss.list.sb" \
        -wrap none -cursor {} -takefocus 0
    set tbw $df.abyss.list.t
    $tbw tag configure select -foreground white -background blue
    set gameConfig($w,abyss) $tbw
    set gameConfig($tbw) "abyss"
    lappend gameConfig($w,textBoxes) $gameConfig($w,abyss)
    scrollbar $df.abyss.list.sb -command "$tbw yview"
    grid $df.abyss.list.t -sticky nsew
    grid columnconfigure $df.abyss.list 0 -weight 1
    grid rowconfigure $df.abyss.list 0 -weight 1

    bind $tbw <ButtonPress-1> "Game::ClickTextBox $w %X %Y 1 abyss"
    bind $tbw <ButtonPress-3> "Game::ClickTextBox $w %X %Y 3 abyss"
    bindtags $tbw "$tbw all"

    CrossFire::DragTarget $tbw card "Game::MoveCard $w abyss"
    bind $tbw <ButtonRelease-1> "CrossFire::CancelDrag $tbw"

    grid $df.abyss.l -sticky w
    grid $df.abyss.list -sticky nsew
    grid columnconfigure $df.abyss 0 -weight 1
    grid rowconfigure $df.abyss 1 -weight 1

    # Limbo
    frame $df.limbo
    label $df.limbo.l -text "Limbo:" -anchor w
    frame $df.limbo.list
    text $df.limbo.list.t -height 8 -width 20 -spacing1 2 \
        -exportselection 0 -background white -foreground black \
        -yscrollcommand "CrossFire::SetScrollBar $df.limbo.list.sb" \
        -wrap none -cursor {} -takefocus 0
    set tbw $df.limbo.list.t
    $tbw tag configure select -foreground white -background blue
    set gameConfig($w,limbo) $tbw
    set gameConfig($tbw) "limbo"
    lappend gameConfig($w,textBoxes) $gameConfig($w,limbo)
    scrollbar $df.limbo.list.sb -command "$tbw yview"
    grid $df.limbo.list.t -sticky nsew
    grid columnconfigure $df.limbo.list 0 -weight 1
    grid rowconfigure $df.limbo.list 0 -weight 1

    bind $tbw <ButtonPress-1> "Game::ClickTextBox $w %X %Y 1 limbo"
    bind $tbw <ButtonPress-3> "Game::ClickTextBox $w %X %Y 3 limbo"
    bindtags $tbw "$tbw all"

    CrossFire::DragTarget $tbw card "Game::MoveCard $w limbo"
    bind $tbw <ButtonRelease-1> "CrossFire::CancelDrag $tbw"

    grid $df.limbo.l -sticky w
    grid $df.limbo.list -sticky nsew
    grid columnconfigure $df.limbo 0 -weight 1
    grid rowconfigure $df.limbo 1 -weight 1

    # Out of Play
    label $df.outOfPlay -background black -foreground yellow \
        -text "Out of Play (The Void)" -width $lbWidth
    CrossFire::DragTarget $df.outOfPlay card \
        "Game::MoveCard $w outOfPlay"
    bind $df.outOfPlay <Double-Button-1> \
        "Game::ToggleView $w OutOfPlay Yes"

    grid $df.discard -column 0 -row 0 -sticky nsew -padx 3 \
        -pady 3 -rowspan 2
    grid $df.abyss   -column 1 -row 0 -sticky nsew -padx 3 \
        -pady 3 -rowspan 2
    grid $df.limbo   -column 2 -row 0 -sticky nsew -padx 3 -pady 3
    grid $df.outOfPlay -column 2 -row 1 -sticky ew -padx 3 -pady 3

    grid $df -sticky nsew -padx 3 -pady 3
    grid columnconfigure $df {0 1 2} -weight 1
    grid rowconfigure $df 0 -weight 1

    grid columnconfigure $fp2 0 -weight 1
    grid rowconfigure $fp2 0 -weight 1

    grid $mp2.right -sticky nsew
    grid columnconfigure $mp2 0 -weight 1
    grid rowconfigure $mp2 0 -weight 1

    #
    # Grid the parts together
    #
    grid $w.main -sticky nsew
    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 1

    bind $w <Key-Up>    "Game::MoveSelection $w U"
    bind $w <Key-Down>  "Game::MoveSelection $w D"
    bind $w <Key-Right> "Game::MoveSelection $w R"
    bind $w <Key-Left>  "Game::MoveSelection $w L"

    set gameConfig($w,selectionAt) ""

    if {$CrossFire::platform == "windows"} {
        focus $w
    }

    set gameConfig($w,viewTop,Player) $w
    if {$Config::config(Online,geometry,Player) != ""} {
        CrossFire::PlaceWindow $w $Config::config(Online,geometry,Player)
    }

    set name $gameConfig(formation,$numRealms,name)
    set chatter "Message has started a $name game "
    append chatter "using CrossFire $CrossFire::crossFireVersion"
    TellOpponents $w $chatter

    return
}

# Game::AddPlayerMenuBar --
#
#   Creates the menubar for the game and sets up the
#   accelerator key bindings for the commands.
#
# Parameters:
#   w          : Toplevel of the new game window.
#
# Returns:
#   Nothing.
#
proc Game::AddPlayerMenuBar {w} {

    variable gameConfig

    menu $w.menubar

    $w.menubar add cascade \
        -label "Game" \
        -underline 0 \
        -menu $w.menubar.game

    menu $w.menubar.game -tearoff false
    if {$gameConfig($w,mode) == "Online"} {
        $w.menubar.game add command \
            -label "Add Opponent..." \
            -underline 0 \
            -accelerator "$CrossFire::accelKey+A" \
            -command "Game::AddOpponent $w"
        $w.menubar.game add command \
            -label "Add Watcher..." \
            -underline 4 \
            -accelerator "$CrossFire::accelKey+W" \
            -command "Game::AddWatcher $w"
        $w.menubar.game add separator
    }
    $w.menubar.game add command \
        -label "Open Deck..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+O" \
        -command "Game::OpenDeck $w"

    $w.menubar.game add separator
    $w.menubar.game add command \
        -label "Restart" \
        -underline 0 \
        -command "Game::Restart $w"
    $w.menubar.game add command \
        -label "Mulligan" \
        -underline 0 \
        -command "Game::Restart $w mulligan"
    if {$gameConfig($w,mode) == "Online"} {
        $w.menubar.game add command \
            -label "Refresh Opponents" \
            -underline 2 \
            -accelerator "$CrossFire::accelKey+F" \
            -command "Game::RefreshOpponents $w"
    }

    $w.menubar.game add separator
    $w.menubar.game add command \
        -label "Save" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+S" \
        -command "Game::Save $w"
    $w.menubar.game add command \
        -label "Load" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+L" \
        -command "Game::Load $w"

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
        -label "Options" \
        -underline 0 -menu [menu $w.menubar.opt -tearoff false]
    $w.menubar.opt add checkbutton \
        -label "Events Go To Discards" \
        -underline 0 \
        -onvalue "discard" -offvalue "abyss" \
        -variable Game::gameConfig($w,eventsTo) \
        -command "Game::ToggleEventDiscard $w"
    set gameConfig($w,eventsTo) "abyss"
    $w.menubar.opt add checkbutton \
        -label "Automatically Recycle Discards" \
        -underline 0 \
        -onvalue "Yes" -offvalue "No" \
        -variable Game::gameConfig($w,autoRecycleDiscards)
    $w.menubar.opt add checkbutton \
        -label "Group Champions in Hand" \
        -underline 0 -accelerator "$CrossFire::accelKey+G" \
        -onvalue "Champion" -offvalue "Class" \
        -variable Game::gameConfig($w,championMode) \
        -command "Game::DisplayHand $w"
    set gameConfig($w,championMode) $Config::config(Online,championMode)

    $w.menubar add cascade \
        -label "View" \
        -underline 0 \
        -menu [menu $w.menubar.view -tearoff false]
    set gameConfig($w,viewMenu) $w.menubar.view
    $w.menubar.view add checkbutton \
        -label "Card" \
        -underline 0 \
        -variable Game::gameConfig($w,show,Card) \
        -onvalue "Yes" -offvalue "No" \
        -command "Game::ToggleView $w Card"
    $w.menubar.view add checkbutton \
        -label "Out of Play (The Void)" \
        -underline 0 \
        -variable Game::gameConfig($w,show,OutOfPlay) \
        -onvalue "Yes" -offvalue "No" \
        -command "Game::ToggleView $w OutOfPlay"
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

    $w.menubar add cascade \
        -label "Notes" \
        -underline 0 \
        -menu $w.menubar.notes

    menu $w.menubar.notes -tearoff false
    $w.menubar.notes add command \
        -label "New..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+N" \
        -command "Game::ComposeGameNote $w"
    $w.menubar.notes add cascade \
        -label "Remove" \
        -underline 0 \
        -menu $w.menubar.notes.remove

    # If this -tearoff is changed to true, the RefreshOpponent and ExitGame
    # procs will need to be change to skip index 0.
    menu $w.menubar.notes.remove -tearoff false
    set gameConfig($w,removeMenu) $w.menubar.notes.remove

    $w.menubar add cascade \
        -label "Hand" \
        -underline 0 \
        -menu $w.menubar.hand

    menu $w.menubar.hand -tearoff false
    $w.menubar.hand add cascade \
        -label "Discard All" \
        -underline 8 \
        -menu $w.menubar.hand.all
    menu $w.menubar.hand.all -tearoff 0
    $w.menubar.hand.all add command \
        -label "Cards" \
        -underline 0 \
        -command "Game::DiscardFromHand $w All Card Cards"
    $w.menubar.hand.all add separator
    $w.menubar.hand.all add command \
        -label "Allies" \
        -underline 0 \
        -command "Game::DiscardFromHand $w All 1 Allies"
    $w.menubar.hand.all add command \
        -label "Champions" \
        -underline 0 -command \
        [subst {
            Game::DiscardFromHand $w All [list $CrossFire::championList] \
                Champions
        }]
    $w.menubar.hand.all add command \
        -label "Events" \
        -underline 0 \
        -command "Game::DiscardFromHand $w All 6 Events"
    $w.menubar.hand.all add command \
        -label "Spells" \
        -underline 0 \
        -command "Game::DiscardFromHand $w All {4 19} Spells"
    $w.menubar.hand add cascade \
        -label "Discard Random" \
        -underline 8 \
        -menu $w.menubar.hand.random
    menu $w.menubar.hand.random -tearoff 0
    $w.menubar.hand.random add command \
        -label "Card" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+C" \
        -command "Game::DiscardFromHand $w Any Card Card"
    $w.menubar.hand.random add separator
    $w.menubar.hand.random add command \
        -label "Psionic Power or Spell" \
        -underline 0 -command \
        "Game::DiscardFromHand $w Any {11 4 19} {Psionic Power or Spell}"
    $w.menubar.hand.random add command \
        -label "Realm" \
        -underline 0 -command "Game::DiscardFromHand $w Any 13 Realm"

    if {$gameConfig($w,mode) == "Online"} {
        $w.menubar.hand add separator
        $w.menubar.hand add command \
            -label "Show To Opponent..." \
            -underline 0 \
            -command "Game::ShowHandToOpponent $w"
    }

    $w.menubar add cascade \
        -label "Pool" \
        -underline 0 \
        -menu $w.menubar.pool

    menu $w.menubar.pool -tearoff false
    $w.menubar.pool add command \
	-label "Shuffle" \
	-underline 0 \
	-command "Game::ShufflePool $w"
    $w.menubar.pool add checkbutton \
        -label "Hidden" \
        -underline 0 \
        -variable Game::gameConfig($w,hidePool) \
        -command "Game::HidePool $w"
    $w.menubar.pool add separator
    $w.menubar.pool add cascade \
        -label "Pick Random" \
        -underline 0 \
        -menu $w.menubar.pool.pick

    menu $w.menubar.pool.pick -tearoff 0
    $w.menubar.pool.pick add command \
        -label "Card" \
        -underline 0 \
        -command "Game::PickPoolCard $w Card"
    $w.menubar.pool.pick add command \
        -label "Champion" \
        -underline 1 \
        -command "Game::PickPoolCard $w Champion"
    $w.menubar.pool.pick add separator
    $w.menubar.pool.pick add command \
        -label "Artifact" \
        -underline 0 \
        -command "Game::PickPoolCard $w 2 Artifact"
    $w.menubar.pool.pick add command \
        -label "Hero" \
        -underline 0 \
        -command "Game::PickPoolCard $w 7 Hero"
    $w.menubar.pool.pick add command \
        -label "Magical Item" \
        -underline 0 \
        -command "Game::PickPoolCard $w 9 {Magical Item}"
    $w.menubar.pool.pick add command \
        -label "Magical Item or Artifact" \
        -underline 0 \
        -command "Game::PickPoolCard $w {2 9} {Magical Item or Artifact}"
    $w.menubar.pool.pick add command \
        -label "Monster" \
        -underline 1 \
        -command "Game::PickPoolCard $w 10 Monster"
    $w.menubar.pool.pick add command \
        -label "Psionicist" \
        -underline 0 \
        -command "Game::PickPoolCard $w 12 Psionicist"
    $w.menubar.pool.pick add command \
        -label "Regent" \
        -underline 0 \
        -command "Game::PickPoolCard $w 14 Regent"
    $w.menubar.pool.pick add command \
        -label "Wizard" \
        -underline 0 \
        -command "Game::PickPoolCard $w 20 Wizard"

    $w.menubar.pool add separator
    $w.menubar.pool add command \
        -label "Con Game DU/082" \
        -underline 0 \
        -command "Game::ConGame $w"

    $w.menubar add cascade \
        -label "Deck" \
        -underline 0 \
        -menu $w.menubar.draw

    menu $w.menubar.draw -tearoff false
    $w.menubar.draw add cascade \
        -label "Draw" \
        -underline 0 \
        -menu $w.menubar.draw.draw
    menu $w.menubar.draw.draw -tearoff 0
    $w.menubar.draw.draw add command \
        -label "Card" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+D" \
        -command "Game::DrawCard $w hand"
    $w.menubar.draw.draw add command \
        -label "And Discard" \
        -underline 0 \
        -command "Game::DrawCard $w discard"
    $w.menubar.draw.draw add command \
        -label "To Panes of War" \
        -underline 3 \
        -accelerator "$CrossFire::accelKey+P" \
        -command "Game::DrawCard $w battlefield"
    $w.menubar.draw.draw add separator
    $w.menubar.draw.draw add command \
        -label "Spoils" \
        -underline 0 \
        -command "Game::DrawSpoils $w"
    $w.menubar.draw.draw add command \
        -label "Dungeon Spoils" \
        -underline 0 \
        -command "Game::DrawCard $w dSpoils"
    #$w.menubar.draw add separator
    $w.menubar.draw add command \
        -label "Shuffle" \
        -underline 0 \
        -command "Game::ShuffleDrawPile $w tell"
    #$w.menubar.draw add separator
    $w.menubar.draw add command \
        -label "View..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+V" \
        -command "Game::ViewDrawPile $w"
    if {$gameConfig($w,mode) == "Online"} {
        $w.menubar.draw add command \
            -label "Show To Opponent..." \
            -underline 0 \
            -command "Game::ShowDrawToOpponent $w"
    }
    $w.menubar.draw add separator
    $w.menubar.draw add command \
        -label "Bag of Beans NSc/11" \
        -underline 0 \
        -command "Game::BagOfBeans $w"
    $w.menubar.draw add command \
        -label "Mithril Hall FR/022, 4th/076" \
        -underline 0 \
        -command "Game::MithrilHall $w"
    $w.menubar.draw add command \
        -label "Set Traps NS/058" \
        -underline 0 \
        -command "Game::SetTraps $w"
    $w.menubar.draw add command \
        -label "Undermountain DU/005" \
        -underline 0 \
        -command "Game::Undermountain $w"
    $w.menubar.draw add separator
    $w.menubar.draw add command \
        -label "Cut" \
        -underline 0 \
        -command "Game::CutDeck $w"

    $w.menubar add cascade \
        -label "Discards" \
        -underline 2 \
        -menu $w.menubar.discard

    menu $w.menubar.discard -tearoff false

    $w.menubar.discard add cascade \
        -label "Recycle" \
        -underline 0 \
        -menu $w.menubar.discard.recycle
    menu $w.menubar.discard.recycle -tearoff false
    $w.menubar.discard.recycle add command \
        -label "All Cards" \
        -accelerator "$CrossFire::accelKey+R" \
        -command "Game::DiscardToDraw $w"
    $w.menubar.discard.recycle add separator
    $w.menubar.discard.recycle add command \
        -label "Elves" \
        -underline 0 \
        -command "Game::RecallCards $w elves 14 attr"
    $w.menubar.discard.recycle add command \
        -label "Spells" \
        -underline 0 \
        -command "Game::RecallCards $w spells {4 19}"

    $w.menubar.discard add command \
        -label "To Top Of Deck" \
        -underline 0 \
        -command "Game::DiscardToDraw $w top"
    $w.menubar.discard add command \
        -label "Random To Deck" \
        -underline 0 \
        -command "Game::RandomDiscardToDraw $w"

    $w.menubar add cascade \
	-label "Dice" \
	-underline 1 \
	-menu $w.menubar.dice

    menu $w.menubar.dice -tearoff false

    foreach qty {1 2 3} {
	foreach sides {4 6 10} {
	    if {$qty == 1} {
		set key "d${sides}"
		set uLoc 1
	    } else {
		set key "${qty}d${sides}"
		set uLoc 2
	    }
	    $w.menubar.dice add command \
		-label "$key" \
		-underline $uLoc \
		-command "Game::RollDice $w $qty $sides"
	}
	$w.menubar.dice add separator
    }
    $w.menubar.dice add command \
	-label "Custom..." \
	-underline 0 \
	-command "Game::RollCustom $w"

    $w.menubar add cascade \
        -label "Help" \
        -underline 1 \
        -menu $w.menubar.help

    menu $w.menubar.help -tearoff false
    $w.menubar.help add command \
        -label "Help..." \
        -accelerator "F1" \
        -underline 0 \
        -command "CrossFire::Help online.html"
    $w.menubar.help add separator
    $w.menubar.help add command \
        -label "About Online Spellfire..." \
        -underline 0 \
        -command "Game::About $w"

    $w config -menu $w.menubar

    bind $w <$CrossFire::accelBind-k> "Game::EndTurn $w"

    # Game menu bindings
    bind $w <$CrossFire::accelBind-f> "Game::RefreshOpponents $w"
    bind $w <$CrossFire::accelBind-a> "Game::AddOpponent $w"
    bind $w <$CrossFire::accelBind-w> "Game::AddWatcher $w"
    bind $w <$CrossFire::accelBind-o> "Game::OpenDeck $w"
    bind $w <$CrossFire::accelBind-s> "Game::Save $w"
    bind $w <$CrossFire::accelBind-l> "Game::Load $w"
    if {$CrossFire::platform == "macintosh"} {
        bind $w <Command-q> "Game::ExitGame $w"
    } else {
        bind $w <Meta-x> "Game::ExitGame $w"
        bind $w <Alt-F4> "Game::ExitGame $w; break"
    }

    # Options menu bindings
    bind $w <$CrossFire::accelBind-g> "Game::ToggleChampionMode $w"

    # Notes menu binding
    bind $w <$CrossFire::accelBind-n> "Game::ComposeGameNote $w"

    # Hand menu bindings
    bind $w <$CrossFire::accelBind-c> \
	"Game::DiscardFromHand $w Any Card Card"

    # Deck menu bindings
    bind $w <$CrossFire::accelBind-d> "Game::DrawCard $w hand"
    bind $w <$CrossFire::accelBind-p> "Game::DrawCard $w battlefield"
    bind $w <$CrossFire::accelBind-v> "Game::ViewDrawPile $w"

    # Discards menu binding
    bind $w <$CrossFire::accelBind-r> "Game::DiscardToDraw $w"

    # Help menu bindings
    bind $w <Key-F1> "CrossFire::Help online.html"
    bind $w <Key-Help> "CrossFire::Help online.html"

    return
}

# Game::CreateOpponent --
#
# Returns:
#   Nothing.
#
proc Game::CreateOpponent {pw name numRealms key} {

    variable oppCount
    variable gameConfig
    variable lbWidth

    set invert $Config::config(Online,invertOpponent)

    incr oppCount

    set w [toplevel "${pw}.opponent$oppCount"]
    wm title $w "$name - Online Spellfire Game $gameConfig($pw,gameNum)"
    wm protocol $w WM_DELETE_WINDOW "Game::ToggleView $pw $name No"

    set gameConfig($pw,show,$name) "Yes"
    set gameConfig($pw,viewTop,$name) $w
    regsub "\[0-9\]*x\[0-9\]*" [wm geometry $w] "" \
        gameConfig($pw,viewPosition,$name)
    $gameConfig($pw,viewMenu) add checkbutton \
        -label $name \
        -variable Game::gameConfig($pw,show,$name) \
        -onvalue "Yes" -offvalue "No" \
        -command "Game::ToggleView $pw $name"

    AddOpponentMenuBar $w

    set gameConfig($w,name) $name
    set gameConfig($w,gameNum) $gameConfig($pw,gameNum)
    set gameConfig($w,opponents) ""
    set gameConfig($w,textBoxes) ""
    set gameConfig($w,mode) "Online"
    set gameConfig($w,playerType) "opponent"
    set gameConfig($w,cardViewMode) $gameConfig($pw,cardViewMode)
    set gameConfig($w,parent) $pw

    Initialize $w
    CreateCardView $w
    CreateOutOfPlay $w
    AddWarPane $w $name opponent

    if {![info exists Config::config(Online,mainPane,$key)]} {
	Config::Set Online,mainPane,$key 0.30
	Config::Set Online,formPane,$key 0.30
    }

    # Main panes to divide hand & pool / formation & discards
    PanedWindow::Create $w.main -orient "h" -width 5i -height 4i \
	-size $Config::config(Online,mainPane,$key)
    set gameConfig($w,mainPane) $w.main
    set mp1 [PanedWindow::Pane $w.main 1]
    set mp2 [PanedWindow::Pane $w.main 2]

    $mp1 configure -relief raised -borderwidth 1

    #
    # The left side holds the pool.
    #
    set hf $mp1.left
    frame $hf

    frame $hf.top
    label $hf.top.handSize -anchor w \
        -textvariable Game::gameConfig($w,handLabel)
    UpdateHandSize $w
    label $hf.top.deckSize -anchor w \
        -textvariable Game::gameConfig($w,deckLabel)
    UpdateDeckSize $w

    # Dummy hand so MoveCard has a target for hand
    text $hf.hand
    set gameConfig($w,hand) $hf.hand

    if {$gameConfig($pw,cardViewMode) == "single"} {
	set cw $pw
    } else {
	set cw $w
    }
    checkbutton $hf.top.cardViewer -text "Card Viewer" \
        -variable Game::gameConfig($cw,show,Card) \
        -onvalue "Yes" -offvalue "No" \
        -command "Game::ToggleView $cw Card"

    grid $hf.top.cardViewer -sticky w
    grid $hf.top.handSize -sticky w
    grid $hf.top.deckSize -sticky w
    grid $hf.top -sticky nsew
    grid columnconfigure $hf.top 0 -weight 1

    # The Pool
    frame $hf.bottom
    frame $hf.bottom.pool
    label $hf.bottom.pool.l -text "Pool:" -anchor w
    set gameConfig($w,poolLabel) $hf.bottom.pool.l

    frame $hf.bottom.pool.list
    text $hf.bottom.pool.list.t -height 8 -width 20 -spacing1 2 \
        -exportselection 0 -background white -foreground black \
        -yscrollcommand "CrossFire::SetScrollBar $hf.bottom.pool.list.sb" \
        -wrap none -cursor {} -takefocus 0
    set tbw $hf.bottom.pool.list.t
    set gameConfig($w,pool) $tbw
    lappend gameConfig($w,textBoxes) $gameConfig($w,pool)
    $tbw tag configure champion -font "[lindex [$tbw configure -font] 3] bold"
    $tbw tag configure select -foreground white -background blue
    scrollbar $hf.bottom.pool.list.sb -command "$tbw yview"
    grid $hf.bottom.pool.list.t -sticky nsew
    grid columnconfigure $hf.bottom.pool.list 0 -weight 1
    grid rowconfigure $hf.bottom.pool.list 0 -weight 1

    bind $tbw <ButtonPress-1> "Game::ClickTextBox $w %X %Y 1 pool opponent"
    bind $tbw <ButtonPress-3> "Game::ClickTextBox $w %X %Y 3 pool opponent"
    bindtags $tbw "$tbw all"

    grid $hf.bottom.pool.l -sticky w
    grid $hf.bottom.pool.list -sticky nsew
    grid columnconfigure $hf.bottom.pool 0 -weight 1
    grid rowconfigure $hf.bottom.pool 1 -weight 1

    grid $hf.bottom.pool -sticky nsew -padx 3 -pady 3
    grid columnconfigure $hf.bottom 0 -weight 1
    grid rowconfigure $hf.bottom 0 -weight 1
    grid $hf.bottom -sticky nsew

    grid $hf -sticky nsew
    grid columnconfigure $hf 0 -weight 1
    grid rowconfigure $hf 1 -weight 1

    grid columnconfigure $mp1 0 -weight 1
    grid rowconfigure $mp1 0 -weight 1

    #
    # The right side holds the formation and discards.
    #
    PanedWindow::Create $mp2.right \
	-size $Config::config(Online,formPane,$key)
    set gameConfig($w,formPane) $mp2.right
    set fp1 [PanedWindow::Pane $mp2.right 1]
    set fp2 [PanedWindow::Pane $mp2.right 2]

    $fp1 configure -relief raised -borderwidth 1
    $fp2 configure -relief raised -borderwidth 1

    #
    # Build the formation of 6 realms
    #
    if {$invert == "No"} {
	set ff $fp1.formation
    } else {
	set ff $fp2.formation
    }
    frame $ff

    set lastRealmColumn $gameConfig(formation,$numRealms,lastColumn)
    set lastRealmRow $gameConfig(formation,$numRealms,lastRow)

    if {$invert == "No"} {
        set formation $gameConfig(formation,$numRealms,normal)
    } else {
        set formation $gameConfig(formation,$numRealms,invert)
    }

    foreach {realm row column} $formation {

        if {$realm == "phase"} {
            set phaseRow $row
            set phaseCol $column
            continue
        } elseif {$realm == "extra"} {
            set extraRow $row
            set extraCol $column
            continue
        }

        frame $ff.f$realm

        set rl $ff.f$realm.realm
        label $rl -background $Config::config(Online,color,realm,unrazed) \
            -foreground $Config::config(Online,color,realm,unrazedFG) \
            -text "Realm $realm" -width $lbWidth \
            -relief groove
        lappend gameConfig($w,realmLabel) $rl
        set gameConfig($rl) "realm$realm"
        set gameConfig($w,realm${realm}Label) $rl
        set gameConfig($w,realm${realm}Card) "none"
        set gameConfig($w,realm${realm}Status) "unrazed"

        set lw $ff.f$realm.realm
        bind $lw <ButtonPress-1> \
            "Game::ClickLabel $w %X %Y 1 realm$realm opponent"
        bind $lw <ButtonPress-3> \
            "Game::ClickLabel $w %X %Y 3 realm$realm opponent"

        frame $ff.f$realm.attach
        set tbw $ff.f$realm.attach.t
        text $tbw -height 3 -width 20 -spacing1 2 -exportselection 0 \
            -foreground black \
            -background $Config::config(Online,color,holding) \
            -wrap none -cursor {} -takefocus 0 -yscrollcommand \
            "CrossFire::SetScrollBar $ff.f$realm.attach.sb"
        $tbw tag configure select -foreground white -background blue
        set gameConfig($w,attach$realm) $tbw
        lappend gameConfig($w,textBoxes) $gameConfig($w,attach$realm)
        scrollbar $ff.f$realm.attach.sb -command "$tbw yview"
        grid $ff.f$realm.attach.t -sticky nsew
        grid columnconfigure $ff.f$realm.attach 0 -weight 1
        grid rowconfigure $ff.f$realm.attach 0 -weight 1

        bind $tbw <ButtonPress-1> \
            "Game::ClickTextBox $w %X %Y 1 attach$realm opponent"
        bind $tbw <ButtonPress-3> \
            "Game::ClickTextBox $w %X %Y 3 attach$realm opponent"
        bindtags $tbw "$tbw all"

        grid $ff.f$realm.realm -sticky ew
        grid $ff.f$realm.attach -sticky nsew
        grid $ff.f$realm -row $row -column $column -columnspan 2 \
            -sticky nsew -padx 3 -pady 3
        grid columnconfigure $ff.f$realm 0 -weight 1
        grid rowconfigure $ff.f$realm 1 -weight 1
    }

    # Phase buttons.  Vertically to the left of realms A & B
    frame $ff.phase

    label $ff.phase.l -text "Phase:" -anchor w
    grid $ff.phase.l -sticky w -columnspan 6
    foreach phase {0 1 2 3 4 5} {
        set rb $ff.phase.phase$phase
        radiobutton $rb -text $phase -value $phase \
            -indicatoron 0 -state disabled -borderwidth 0 \
            -variable Game::gameConfig($w,phase)
        $rb configure -disabledforeground [$rb cget -foreground]
        grid $ff.phase.phase$phase -row 1 -column $phase -sticky ew
        grid columnconfigure $ff.phase $phase -weight 1
    }
    set gameConfig($w,phase) 0

    # Put the Rule and Dungeon cards next to realm A
    frame $ff.extra

    label $ff.extra.dungeon -foreground black \
        -background $Config::config(Online,color,dungeon) \
        -text "No Dungeon" -width $lbWidth -relief groove
    set gameConfig($w,dungeonLabel) $ff.extra.dungeon
    set gameConfig($w,dungeonCard) "none"

    set lw $ff.extra.dungeon
    bind $lw <ButtonPress-1> "Game::ClickLabel $w %X %Y 1 dungeon opponent"
    bind $lw <ButtonPress-3> "Game::ClickLabel $w %X %Y 3 dungeon opponent"

    label $ff.extra.rule -foreground black \
        -background $Config::config(Online,color,rule) \
        -text "No Rule" -width $lbWidth -relief groove
    set gameConfig($w,ruleLabel) $ff.extra.rule
    set gameConfig($w,ruleCard) "none"

    set lw $ff.extra.rule
    bind $lw <ButtonPress-1> "Game::ClickLabel $w %X %Y 1 rule opponent"
    bind $lw <ButtonPress-3> "Game::ClickLabel $w %X %Y 3 rule opponent"

    if {$invert == "No"} {
        grid $ff.extra.dungeon -sticky ew
        grid $ff.extra.rule -sticky ew -pady 3
    } else {
        grid $ff.extra.rule -sticky ew -pady 3
        grid $ff.extra.dungeon -sticky ew
    }

    grid $ff.phase -row $phaseRow -column $phaseCol -columnspan 2 \
        -sticky new -padx 3 -pady 3
    grid $ff.extra -row $extraRow -column $extraCol -columnspan 2 \
        -sticky new -padx 3 -pady 3

    grid columnconfigure $ff.extra 0 -weight 1

    set rowList ""
    for {set i 0} {$i <= $lastRealmRow} {incr i} {
        lappend rowList $i
    }

    set columnList ""
    for {set i 0} {$i <= [expr $lastRealmColumn + 1]} {incr i} {
        lappend columnList $i
    }

    grid $ff -sticky nsew -padx 3 -pady 3
    grid rowconfigure $ff $rowList -weight 1
    grid columnconfigure $ff $columnList -weight 1

    if {$invert == "No"} {
	grid columnconfigure $fp1 0 -weight 1
	grid rowconfigure $fp1 0 -weight 1
    } else {
	grid columnconfigure $fp2 0 -weight 1
	grid rowconfigure $fp2 0 -weight 1
    }

    #
    # The various discard type places
    #
    if {$invert == "No"} {
	set df $fp2.discard
    } else {
	set df $fp1.discard
    }
    frame $df

    # Discard pile
    frame $df.discard
    label $df.discard.l -text "Discard:" -anchor w
    frame $df.discard.list
    text $df.discard.list.t -height 8 -width 20 -spacing1 2 \
        -exportselection 0 -background white -foreground black \
        -yscrollcommand "CrossFire::SetScrollBar $df.discard.list.sb" \
        -wrap none -cursor {} -takefocus 0
    set tbw $df.discard.list.t
    $tbw tag configure select -foreground white -background blue
    set gameConfig($w,discard) $tbw
    lappend gameConfig($w,textBoxes) $gameConfig($w,discard)
    scrollbar $df.discard.list.sb -command "$tbw yview"
    grid $df.discard.list.t -sticky nsew
    grid columnconfigure $df.discard.list 0 -weight 1
    grid rowconfigure $df.discard.list 0 -weight 1

    set tbw $gameConfig($w,discard)
    bind $tbw <ButtonPress-1> "Game::ClickTextBox $w %X %Y 1 discard opponent"
    bind $tbw <ButtonPress-3> "Game::ClickTextBox $w %X %Y 3 discard opponent"
    bindtags $tbw "$tbw all"

    grid $df.discard.l -sticky w
    grid $df.discard.list -sticky nsew
    grid columnconfigure $df.discard 0 -weight 1
    grid rowconfigure $df.discard 1 -weight 1

    # The Abyss
    frame $df.abyss
    label $df.abyss.l -text "Abyss:" -anchor w
    frame $df.abyss.list
    text $df.abyss.list.t -height 2 -width 20 -spacing1 2 \
        -exportselection 0 -background white -foreground black \
        -yscrollcommand "CrossFire::SetScrollBar $df.abyss.list.sb" \
        -wrap none -cursor {} -takefocus 0
    set tbw $df.abyss.list.t
    $tbw tag configure select -foreground white -background blue
    set gameConfig($w,abyss) $tbw
    lappend gameConfig($w,textBoxes) $gameConfig($w,abyss)
    scrollbar $df.abyss.list.sb -command "$tbw yview"
    grid $df.abyss.list.t -sticky nsew
    grid columnconfigure $df.abyss.list 0 -weight 1
    grid rowconfigure $df.abyss.list 0 -weight 1

    bind $tbw <ButtonPress-1> "Game::ClickTextBox $w %X %Y 1 abyss opponent"
    bind $tbw <ButtonPress-3> "Game::ClickTextBox $w %X %Y 3 abyss opponent"
    bindtags $tbw "$tbw all"

    grid $df.abyss.l -sticky w
    grid $df.abyss.list -sticky nsew
    grid columnconfigure $df.abyss 0 -weight 1
    grid rowconfigure $df.abyss 1 -weight 1

    # Out of Play
    label $df.outOfPlay -background black -foreground yellow \
        -text "Out of Play (The Void)" -width $lbWidth
    bind $df.outOfPlay <Double-Button-1> "Game::ToggleView $w OutOfPlay Yes"

    # Limbo
    frame $df.limbo
    label $df.limbo.l -text "Limbo:" -anchor w
    frame $df.limbo.list
    text $df.limbo.list.t -height 8 -width 20 -spacing1 2 \
        -exportselection 0 -background white -foreground black \
        -yscrollcommand "CrossFire::SetScrollBar $df.limbo.list.sb" \
        -wrap none -cursor {} -takefocus 0
    set tbw $df.limbo.list.t
    $tbw tag configure select -foreground white -background blue
    set gameConfig($w,limbo) $tbw
    lappend gameConfig($w,textBoxes) $gameConfig($w,limbo)
    scrollbar $df.limbo.list.sb -command "$tbw yview"
    grid $df.limbo.list.t -sticky nsew
    grid columnconfigure $df.limbo.list 0 -weight 1
    grid rowconfigure $df.limbo.list 0 -weight 1

    bind $tbw <ButtonPress-1> "Game::ClickTextBox $w %X %Y 1 limbo opponent"
    bind $tbw <ButtonPress-3> "Game::ClickTextBox $w %X %Y 3 limbo opponent"
    bindtags $tbw "$tbw all"

    grid $df.limbo.l -sticky w
    grid $df.limbo.list -sticky nsew
    grid columnconfigure $df.limbo 0 -weight 1
    grid rowconfigure $df.limbo 1 -weight 1

    grid $df.discard   -column 0 -row 0 -sticky nsew -padx 3 -pady 3 \
	-rowspan 2
    grid $df.abyss     -column 1 -row 0 -sticky nsew -padx 3 -pady 3 \
	-rowspan 2
    grid $df.outOfPlay -column 2 -row 0 -sticky nsew -padx 3 -pady 3
    grid $df.limbo     -column 2 -row 1 -sticky nsew -padx 3 -pady 3

    grid $df -sticky nsew -padx 3 -pady 3
    grid columnconfigure $df {0 1 2} -weight 1
    grid rowconfigure $df 1 -weight 1

    if {$invert == "No"} {
	grid columnconfigure $fp2 0 -weight 1
	grid rowconfigure $fp2 0 -weight 1
    } else {
	grid columnconfigure $fp1 0 -weight 1
	grid rowconfigure $fp1 0 -weight 1
    }

    grid $mp2.right -sticky nsew
    grid columnconfigure $mp2 0 -weight 1
    grid rowconfigure $mp2 0 -weight 1

    #
    # Grid the parts together
    #
    grid $w.main -sticky nsew -rowspan 2
    grid rowconfigure $w 0 -weight 1
    grid columnconfigure $w 0 -weight 1

    bind $w <Key-Up>   "Game::MoveSelection $w U"
    bind $w <Key-Down> "Game::MoveSelection $w D"

    return $w
}

# Game::AddOpponentMenuBar --
#
#   Creates the menubar for the game and sets up the
#   accelerator key bindings for the commands.
#
# Parameters:
#   w          : Toplevel of the new game window.
#
# Returns:
#   Nothing.
#
proc Game::AddOpponentMenuBar {w} {

    variable gameConfig

    menu $w.menubar

    $w.menubar add cascade \
        -label "Game" \
        -underline 0 \
        -menu $w.menubar.game

    menu $w.menubar.game -tearoff false
    $w.menubar.game  add command \
        -label "Remove From Game" \
        -command "Game::RemoveOpponent $w yes"

    $w.menubar add cascade \
        -label "Help" \
        -underline 0 \
        -menu $w.menubar.help

    menu $w.menubar.help -tearoff false
    $w.menubar.help add command \
        -label "Help..." \
        -accelerator "F1" \
        -underline 0 \
        -command "CrossFire::Help online.html"
    $w.menubar.help add separator
    $w.menubar.help add command \
        -label "About Online Spellfire..." \
        -underline 0 \
        -command "Game::About $w"

    $w config -menu $w.menubar

    # Help menu
    bind $w <Key-F1> "CrossFire::Help online.html"
    bind $w <Key-Help> "CrossFire::Help online.html"

    return
}
