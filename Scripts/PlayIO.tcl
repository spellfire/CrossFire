# PlayerIO.tcl 20051006
#
# This file contains all the procedures for saving and loading games.
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

# Game::Save --
#
#   Saves the current game state.
#
# Parameters:
#   w         : Toplevel
#
# Returns:
#   Nothing.
#
proc Game::Save {w} {

    variable gameConfig

    # create a default name
    set today [clock format [clock scan today] -format "%Y%m%d"]
    set iFile "Game-$today-$gameConfig($w,gameNum).cfo"

    set gameFile \
        [tk_getSaveFile -initialdir $Config::config(Online,dir) \
             -initialfile $iFile -title "Save CrossFire Game" \
             -defaultextension $CrossFire::extension(game) \
             -filetypes $CrossFire::gameFileTypes]
    if {$gameFile == ""} return

    set fid [open $gameFile "w"]

    foreach var {
        handList fileName
        handSize deckSize hidePool phase powTotal
        dungeonCard ruleCard
        poolList battlefieldList abyssList
	outOfPlayList discardList limboList
        attachAList attachBList attachCList attachDList attachEList
        attachFList attachGList attachHList attachIList attachJList
    } {
        puts $fid "$var [list $gameConfig($w,$var)]"
    }

    foreach rl $gameConfig($w,realmLabel) {
        set realm $gameConfig($rl)
        foreach which {Card Status} {
            puts $fid "$realm$which $gameConfig($w,${realm}$which)"
        }
    }

    # Draw Pile $gameConfig($w,drawPile) - list of card format cards
    set drawList {}
    foreach card $gameConfig($w,drawPile) {
        lappend drawList [lindex [CrossFire::GetCardDesc $card] 0]
    }
    puts $fid "drawList [list $drawList]"

    # Game notes

    close $fid

    return
}

# Game::Load --
#
#   Loads a previously started game.
#
# Parameters:
#   w         : Toplevel
#
# Returns:
#   Nothing.
#
proc Game::Load {w} {

    variable gameConfig

    if {$gameConfig($w,fileName) != ""} {
        set msg "You already have a deck opened."
        append msg "\n\nAre you sure you want to load a game?"
        set response \
            [tk_messageBox -title "Game In Progress" -icon warning \
                 -type yesno -message $msg -default "no"]
        if {$response == "no"} {
            return
        }
    }

    set gameFile \
        [tk_getOpenFile -initialdir $Config::config(Online,dir) \
             -title "Open CrossFire Game" \
             -defaultextension $CrossFire::extension(game) \
             -filetypes $CrossFire::gameFileTypes]
    if {$gameFile == ""} return

    Clear $w
    TellOpponents $w "Clear"

    set fid [open $gameFile "r"]
    while {[gets $fid line] >= 0} {
        foreach {var value} $line break
        #dputs "Read var=$var, value=$value" force
        if {$value != ""} {
            set gameConfig($w,$var) $value
        }
    }
    close $fid

    set gameConfig($w,drawPile) {}
    foreach cardID $gameConfig($w,drawList) {
        lappend gameConfig($w,drawPile) [CrossFire::GetCard $cardID]
    }

    DisplayHand $w
    UpdateHandSize $w
    UpdateDeckSize $w
    RefreshOpponents $w

    return
}
