# RPS.tcl 20050902
#
# This file contains the procedures for a Rock, Paper, Scissors
# plug-in game for CrossFire chat.
#
# Copyright (c) 2001-2005 Dan Curtiss. All rights reserved.
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

namespace eval PlugIn::RPS {

    variable gameConfig

    array set gameConfig {
        count 0
        title {Rock, Paper, Scissors}
    }

    set gameConfig(key) "!rps"
}

# PlugIn::RPS::Start --
#
#   Creates the dialog to select opponent
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc PlugIn::RPS::Start {} {

    variable gameConfig

    # Get the list of names in the realm and remove those already added.
    # And do not allow the player to be listed.
    set allyList ""
    set pName [string tolower [Chat::PlayerName]]
    foreach champName [Chat::AllyList] {
        set lName [string tolower $champName]
        if {([info exists gameConfig(inGame,$lName)] == 0) &&
            ($lName != $pName)} {
            lappend allyList $champName
        }
    }

    # Some error checking.
    if {$allyList == ""} {
        tk_messageBox -title "Unable to Comply" -icon error \
            -message "No more players in this realm to play against."
        return
    }

    # Get opponent name
    set w [toplevel .rpsOppSel]
    wm title $w "Select Opponent"
    wm protocol $w WM_DELETE_WINDOW "$w.buttons.cancel invoke"

    frame $w.top -relief raised -borderwidth 1

    frame $w.top.sel
    label $w.top.sel.l -text "Opponent:" -anchor e
    menubutton $w.top.sel.mb -indicatoron 1 -width 20 \
        -menu $w.top.sel.mb.menu -relief raised \
        -textvariable PlugIn::RPS::gameConfig(opponent)
    menu $w.top.sel.mb.menu -tearoff 0
    foreach opponent $allyList {
        $w.top.sel.mb.menu add radiobutton \
            -label $opponent -value $opponent \
            -variable PlugIn::RPS::gameConfig(opponent)
    }
    set gameConfig(opponent) [lindex $allyList 0]
    grid $w.top.sel.l $w.top.sel.mb -sticky ew -padx 3
    grid columnconfigure $w.top.sel 1 -weight 1

    grid $w.top.sel -sticky nsew -padx 5 -pady 5
    grid columnconfigure $w.top 0 -weight 1
    grid rowconfigure $w.top 0 -weight 1

    frame $w.buttons -relief raised -borderwidth 1
    button $w.buttons.show -text "Select" \
        -command "set PlugIn::RPS::gameConfig(selMode) ok"
    button $w.buttons.cancel -text "Cancel" \
        -command "set PlugIn::RPS::gameConfig(selMode) cancel"
    grid $w.buttons.show $w.buttons.cancel -padx 5 -pady 5

    grid $w.top -sticky nsew
    grid $w.buttons -sticky ew
    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 1 -weight 1

    update
    
    if {$CrossFire::platform == "windows"} {
        focus $w
    }

    grab set $w
    tkwait variable PlugIn::RPS::gameConfig(selMode)
    grab release $w
    destroy $w

    if {$gameConfig(selMode) == "ok"} {
        PlugIn::RPS::Create player $gameConfig(opponent)
    }

    return
}

# PlugIn::RPS::Create --
#
#   Create the game play window for either the starting player (controller)
#   or the opponent.
#
# Parameters:
#   side      : Which "side" this is: player or opponent
#   oppName   : Name of the opponent for the window title
#
# Returns:
#   Nothing.
#
proc PlugIn::RPS::Create {side oppName} {

    variable gameConfig

    set oppID [string tolower $oppName]

    # create game window
    set w [toplevel .rpsGame[incr gameConfig(count)]]
    wm title $w "RPS 1.0: $oppName"
    wm protocol $w WM_DELETE_WINDOW "$w.cmd.cancel invoke"

    set gameConfig(inGame,$oppID) $w
    set gameConfig($w,side) $side
    set gameConfig($w,opponent) $oppName

    # Interface
    frame $w.top -borderwidth 1 -relief groove
    foreach item {Rock Paper Scissors} {
        radiobutton $w.top.i$item -text $item -value $item \
            -variable PlugIn::RPS::gameConfig($w,choice)
        grid $w.top.i$item -sticky w
    }
    grid $w.top -sticky nsew

    # Command Buttons
    frame $w.cmd -borderwidth 1 -relief groove
    if {$side == "player"} {
        button $w.cmd.new -text "New" -command "PlugIn::RPS::NewGame $w"
    }
    button $w.cmd.pick -text "Pick" -command "PlugIn::RPS::Pick $w"
    button $w.cmd.cancel -text "Quit" -command "PlugIn::RPS::EndGame $w"

    if {$side == "player"} {
        grid $w.cmd.new $w.cmd.pick $w.cmd.cancel -padx 5 -pady 5
    } else {
        grid $w.cmd.pick $w.cmd.cancel -padx 5 -pady 5
    }

    grid $w.cmd -sticky ew

    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 1

    if {$side == "player"} {
        NewGame $w
        SendCommand $w "Create"
    }

    return
}

# PlugIn::RPS::NewGame --
#
#   Sends a taunt to the chat window and clears the game play variables.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   Nothing.
#
proc PlugIn::RPS::NewGame {w} {

    variable gameConfig

    Chat::ChatMessage \
        "challenges $gameConfig($w,opponent) to a game of $gameConfig(title)!"

    set gameConfig($w,opponentPick) ""
    set gameConfig($w,playerPick) ""
    set gameConfig($w,announced) 0

    return
}

# PlugIn::RPS::SendCommand --
#
#   Sends a game play command to the opponent.
#
# Parameters:
#   w          : Game toplevel.
#   command    : Command to send along.
#
# Returns:
#   Nothing.
#
proc PlugIn::RPS::SendCommand {w command} {

    variable gameConfig

    Chat::PlugInCommand $gameConfig(key) $gameConfig($w,opponent) \
        [Chat::PlayerName] $command

    return
}

# PlugIn::RPS::CloseAll --
#
#   Closes all game windows.  Called when closing chat window.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc PlugIn::RPS::CloseAll {} {

    variable gameConfig

    foreach match [array names gameConfig "*,opponent"] {
        foreach {w trash} [split $match ","] {break}
        EndGame $w
    }

    return 0
}

# PlugIn::RPS::EndGame --
#
#   Closes the game window and tells opponent to close.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   Nothing.
#
proc PlugIn::RPS::EndGame {w} {

    variable gameConfig

    if {[info exists gameConfig($w,side)]} {
        SendCommand $w "EndGame"
    }

    # Clean up
    unset gameConfig(inGame,[string tolower $gameConfig($w,opponent)])
    foreach match [array names gameConfig "$w,*"] {
        unset gameConfig($match)
    }

    destroy $w

    return
}

# PlugIn::RPS::ReceiveOpponentCommand --
#
#   Called when recieving a command from the opponent.  Calls the appropriate
#   procedure depending on the command.
#
# Parameters:
#   args       : Game key, opponent name, command, command args
#
# Returns:
#   Nothing.
#
proc PlugIn::RPS::ReceiveOpponentCommand {args} {

    variable gameConfig

    set oppName [lindex $args 1]
    set oppID [string tolower $oppName]
    set command [lindex $args 2]
    set cmdArgs [lrange $args 3 end]

    switch -- $command {
        "Create" {
            Create opponent $oppName
        }
        "EndGame" {
            if {[info exists gameConfig(inGame,$oppID)]} {
                EndGame $gameConfig(inGame,$oppID)
            }
        }
        "Pick" {
            if {[info exists gameConfig(inGame,$oppID)]} {
                ReceivePick $gameConfig(inGame,$oppID) [lindex $cmdArgs 0]
            }
        }
    }

    return
}

# PlugIn::RPS::Pick --
#
#   Picks one of Rock, Paper, Scissors.  Tells the chat room that the
#   selection has been made.  Sends command to controller if this is
#   the "client"/oppoenent side of the game.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   Nothing.
#
proc PlugIn::RPS::Pick {w} {

    variable gameConfig

    if {$gameConfig($w,choice) == ""} {
        tk_messageBox -title "Huh?" -icon error -message \
            "You must pick one first!!"
        return
    }

    Chat::ChatMessage "has chosen ..."

    if {$gameConfig($w,side) == "player"} {

        if {$gameConfig($w,playerPick) != ""} {
            # Picked again before receiving from opponent.
            Chat::ChatMessage "wants to try to cheat!"
        } else {
            set gameConfig($w,playerPick) $gameConfig($w,choice)
            if {$gameConfig($w,opponentPick) != ""} {
                # Got both picks, see who won!
                AnnounceWinner $w
            }
        }
    } else {
        # Tell controller our pick.
        SendCommand $w "Pick $gameConfig($w,choice)"
    }

    return
}

# PlugIn::RPS::ReceivePick --
#
#   Handles receiving the choice from an opponent.
#
# Parameters:
#   w          : Game toplevel.
#   choice     : Choice of Rock, Paper, Scissors
#
# Returns:
#   Nothing.
#
proc PlugIn::RPS::ReceivePick {w choice} {
    
    variable gameConfig

    if {$gameConfig($w,opponentPick) != ""} {
        # Received another before both choices were made!
        Chat::ChatMessage "notices that $gameConfig($w,opponent) is cheating!"
        return
    }

    set gameConfig($w,opponentPick) $choice

    if {$gameConfig($w,playerPick) != ""} {
        # Let's see who won!
        AnnounceWinner $w
    }

    return
}

# PlugIn::RPS::AnnounceWinner --
#
#   Checks to see who won the game or if it was a draw.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   Nothing.
#
proc PlugIn::RPS::AnnounceWinner {w} {

    variable gameConfig

    if {$gameConfig($w,announced) == 1} return

    set out "picked $gameConfig($w,playerPick), $gameConfig($w,opponent) "
    append out "picked $gameConfig($w,opponentPick)... "

    # If both picks are the same, the game is a draw
    switch -- $gameConfig($w,playerPick) {
        "Rock" {
            if {$gameConfig($w,opponentPick) == "Paper"} {
                # Paper covers rock and wins
                set winner $gameConfig($w,opponent)
            } elseif {$gameConfig($w,opponentPick) == "Rock"} {
                set winner "a draw"
            } else {
                set winner [Chat::PlayerName]
            }
        }
        "Paper" {
            if {$gameConfig($w,opponentPick) == "Scissors"} {
                # Scissors cut paper and wins
                set winner $gameConfig($w,opponent)
            } elseif {$gameConfig($w,opponentPick) == "Paper"} {
                set winner "a draw"
            } else {
                set winner [Chat::PlayerName]
            }
        }
        "Scissors" {
            if {$gameConfig($w,opponentPick) == "Rock"} {
                # Rock smashes scissors and wins
                set winner $gameConfig($w,opponent)
            } elseif {$gameConfig($w,opponentPick) == "Scissors"} {
                set winner "a draw"
            } else {
                set winner [Chat::PlayerName]
            }
        }
    }

    if {$winner == "a draw"} {
        append out "game is a draw"
    } else {
        append out "winner is $winner"
    }

    Chat::ChatMessage $out
    set $gameConfig($w,announced) 1

    return
}
