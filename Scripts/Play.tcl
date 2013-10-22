# Play.tcl 20051206
#
# This file contains the common procedures for Online play.
#
# Copyright (c) 1998-2005 Dan Curtiss. All rights reserved.
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

namespace eval Game {}

# Game::OpenDeck --
#
#   Opens a deck and shuffles it.
#
# Parameters:
#   w          : Game toplevel widget name.
#
# Returns:
#   The filename of the deck.
#
proc Game::OpenDeck {w} {

    variable gameConfig

    set warned 0
    if {$gameConfig($w,fileName) != ""} {
        set msg "You already have a deck opened."
        append msg "  Opening a new deck will restart the game."
        append msg "\n\nAre you sure you want to open another?"
        set response \
            [tk_messageBox -title "Game In Progress" -icon warning \
                 -type yesno -message $msg -default "no"]
        if {$response == "no"} {
            return
        }
        set warned 1
    }

    if {([llength $gameConfig($w,opponents)] == 0) && ($warned == 0) &&
        ($gameConfig($w,mode) == "Online")} {
        set msg "You must select your opponents before opening a deck."
        append msg "\n\nAre you sure you want to continue?"
        set response \
            [tk_messageBox -title "No Opponents!" -icon warning \
                 -type yesno -message $msg -default "no"]
        if {$response == "no"} {
            return
        }
    }

    set fileName [tk_getOpenFile -initialdir $Config::config(DeckIt,dir) \
                      -title "Open CrossFire Deck" \
                      -defaultextension $CrossFire::extension(deck) \
                      -filetypes $CrossFire::deckFileTypes]

    if {$fileName == ""} {
        return ""
    }

    set gameConfig($w,fileName) $fileName

    Clear $w
    TellOpponents $w "Clear"
    ReadDeck $w

    return $fileName
}

# Game::ReadDeck --
#
proc Game::ReadDeck {w} {

    variable gameConfig

    set fileName $gameConfig($w,fileName)
    if {$fileName == ""} {
        return
    }

    if {[Editor::ReadDeck $w $fileName] == 0} {
        tk_messageBox -title "Error Opening Deck" -icon error \
            -parent $w -message "$fileName is not a valid deck!"
        return
    }

    $w config -cursor watch
    update

    Initialize $w
    TellOpponents $w "Clear"

    set fanSetIDs ""
    set dungeon 0
    set deckWeight 0
    set dungeonCard ""
    foreach cardID [Editor::GetDeckInfo $w deck] {
        set card [eval CrossFire::GetCard $cardID]
        set setID [lindex $card 0]
        if {[lsearch $CrossFire::setClass(fan,ids) $setID] != -1} {
            if {[lsearch $fanSetIDs $setID] == -1} {
                lappend fanSetIDs $setID
            }
        }
        if {[lindex $card 3] == 21} {
            # This is the dungeon card
            set dungeon 1
            set dungeonCard [list $card]
            set cardID [lindex [CrossFire::GetCardDesc $card] 0]
            lappend gameConfig($w,handList) \
                [list $cardID "normal"]
        } else {
            lappend gameConfig($w,drawPile) $card
        }

        set weight [lindex $card 12]
        if {$weight == ""} {
            incr deckWeight
        } else {
            incr deckWeight $weight
        }
    }

    set gameConfig($w,handSize) [llength $gameConfig($w,handList)]
    TellOpponents $w "HandSize $gameConfig($w,handSize)"

    set gameConfig($w,deckSize) [llength $gameConfig($w,drawPile)]
    UpdateDeckSize $w
    TellOpponents $w "DeckSize $gameConfig($w,deckSize)"
    DisplayHand $w
    ShuffleDrawPile $w

    set sizeID [Editor::GetDeckInfo $w size]
    set deckType $CrossFire::deckFormat($sizeID,name)
    set chatter "Message opened a $deckType deck"
    if {$dungeon == 1} {
        append chatter " with dungeon"
    }
    TellOpponents $w $chatter

    set deckKey \
        [Editor::GetDeckKey $sizeID "$gameConfig($w,drawPile) $dungeonCard"]
    TellOpponents $w "Message deck key is: $deckKey"
    if {[lindex [split $deckKey "-"] end] != "11111"} {
        TellOpponents $w \
            "Message deck does NOT comply with deck requirements!!!"
    }

    if {$fanSetIDs != ""} {
        set s ""
        if {[llength $fanSetIDs] > 1} {
            set s s
        }
        TellOpponents $w \
            "Message is using fan cards from set$s: $fanSetIDs"
    }

    $w config -cursor {}

    return
}

# Game::ShuffleCards --
#
#   Shuffles a list of cards.
#
# Parameters:
#   cardList   : A list of cards.
#
# Returns:
#   The shuffled list of cards.
#
proc Game::ShuffleCards {cardList} {

    # seed the random number generator
    expr srand([clock clicks])

    set n [expr int(rand() * 3 + 1)]
    for {set i 0} {$i <= $n} {incr i} {
        set shuffled {}

        while {[llength $cardList]} {
            set pos [expr int(rand() * [llength $cardList])]
            lappend shuffled [lindex $cardList $pos]
            set cardList [lreplace $cardList $pos $pos]
        }

        set cardList $shuffled
    }

    return $shuffled
}

# Game::ShuffleDrawPile --
#
#   Shuffles the draw pile.
#
# Parameters:
#   w          : Game toplevel.
#   tell       : Optional field to tell opponents the draw pile was shuffled.
#
# Returns:
#   Nothing.
#
proc Game::ShuffleDrawPile {w {tell ""}} {
    
    variable gameConfig

    set gameConfig($w,drawPile) [ShuffleCards $gameConfig($w,drawPile)]

    if {$tell != ""} {
        TellOpponents $w "Message shuffled draw pile"
    }

    return
}

# Game::GetNextCard --
#
#   Returns the next card from the draw pile.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   The card.
#
proc Game::GetNextCard {w} {

    variable gameConfig

    if {$gameConfig($w,fileName) == ""} {
        tk_messageBox -title "Unable to Comply" -icon error \
            -message "You need to open a deck first!!"
        return ""
    }

    if {[llength $gameConfig($w,drawPile)]} {
        set card [lindex $gameConfig($w,drawPile) 0]
        set gameConfig($w,drawPile) [lreplace $gameConfig($w,drawPile) 0 0]
    } else {
        set card ""
        tk_messageBox -title "Unable to Comply" -icon info \
            -message "No more cards to draw!"
    }

    return $card
}

# Game::CloseAll --
#
#   Calls the ExitGame procedure for all the open game windows.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Game::CloseAll {} {

    variable gameConfig

    set result 0
    foreach game $gameConfig(gameList) {
        if {$gameConfig($game,mode) == "Online"} {
            set result [ExitGame $game]
            if {$result == 1} {
                break
            }
        }
    }

    return $result
}

# Game::ExitGame --
#
#   Exits the game game.
#
# Parameters:
#   w          : Game game toplevel name.
#
# Returns:
#   Nothing.
#
proc Game::ExitGame {w} {

    variable gameConfig

    wm deiconify $w
    raise $w
    set response \
        [tk_messageBox -title "Exit Game" -icon question -default yes \
             -message "Are you sure you want to quit?" -type yesno]
    if {$response == "no"} {
        return 1
    }

    # Remove all games notes
    set m $gameConfig($w,removeMenu)
    set last [$m index end]
    if {$last != "none"} {
        for {set i 0} {$i <= $last} {incr i} {
            set title [$m entrycget $i -label]
            TellOpponents $w "DeleteGameNote [list $title]"
        }
    }

    # Save window positions
    foreach window {Player OutOfPlay Panes GameNotes Card} {
        if {[info exists gameConfig($w,viewTop,$window)]} {
            wm deiconify $gameConfig($w,viewTop,$window)
            SaveWindowSize $w $window
        }
    }

    # Save paned window settings
    if {[info exists gameConfig($w,handPane)]} {
	# Will not exist for watcher
	Config::Set Online,handPane \
	    [PanedWindow::Position $gameConfig($w,handPane) 1]
	Config::Set Online,mainPane \
	    [PanedWindow::Position $gameConfig($w,mainPane) 1]
	Config::Set Online,formPane \
	    [PanedWindow::Position $gameConfig($w,formPane) 1]
    }

    # This update prevents Tcl/Tk 8.3.0 Win from crashing
    # in this part of the code. (8.3b1 didn't have this problem)
    #update

    TellOpponents $w "Message has left the game"
    TellOpponents $w "ExitGame"

    # Officially remove each opponent
    foreach ow $gameConfig($w,opponents) {
        RemoveOpponent $ow
    }

    set pos [lsearch $gameConfig(gameList) $w]
    set gameConfig(gameList) [lreplace $gameConfig(gameList) $pos $pos]

    foreach oName $gameConfig($w,names) {
        unset gameConfig(tw,$oName)
    }

    foreach var [array names gameConfig "$w*"] {
        unset gameConfig($var)
    }

    destroy $w

    return 0
}

# Game::CutDeck --
#
#   Cuts to a card near the middle of the draw pile and
#   sends a message to chat telling which one.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   The card cut to.
#
proc Game::CutDeck {w {tell "yes"}} {

    variable gameConfig

    # seed the random number generator
    expr srand([clock clicks])

    if {$gameConfig($w,fileName) == ""} {
        tk_messageBox -title "Unable to Comply" -icon info \
            -message "You must first open a deck..."
        return ""
    }

    if {[llength $gameConfig($w,drawPile)] == 0} {
        tk_messageBox -title "Unable to Comply" -icon info \
            -message "Your draw pile is empty!"
        return ""
    }

    set len [llength $gameConfig($w,drawPile)]
    set num [expr int(rand() * $len)]
    set card [lindex $gameConfig($w,drawPile) $num]
    set cardNum [string range [lindex $card 1] end end]
    set cardID [CrossFire::GetCardDesc $card]

    if {$tell == "yes"} {
        TellOpponents $w "Message cut to $cardID ..."
        set gameConfig($w,powTotalEntry) "Cut: $cardNum"
        UpdateCombatTotal $w
        focus $w
    }

    return $card
}

# Game::PickPoolCard --
#
#   Picks a random card from the pool.  Used for selecting a card
#   as a target when the pool is hidden.
#
# Parameters:
#   w          : Game toplevel.
#   type       : Card, Champion, or list of card type IDs
#
# Returns:
#   Nothing.
#
proc Game::PickPoolCard {w type {typeName ""}} {

    variable gameConfig

    # seed the random number generator
    expr srand([clock clicks])

    set pool $gameConfig($w,poolList)
    set flatList {}
    foreach champList $pool {
        foreach card $champList {
            lappend flatList [lindex $card 0]
        }
    }
    if {$flatList == ""} {
        tk_messageBox -title "Unable to Comply" -icon error \
            -message "Pool is empty!"
        return
    }

    if {$type == "Champion"} {
        set len [llength $pool]
        set num [expr int(rand() * $len)]
        set cardID [lindex [lindex [lindex $pool $num] 0] 0]
    } elseif {$type == "Card"} {
        set flatLen [llength $flatList]
        set cardID [lindex $flatList [expr int(rand() * $flatLen)]]
    } else {
        # List of card type IDs
        set idList ""
        foreach testID $flatList {
            set testType [lindex [CrossFire::GetCard $testID] 3]
            if {[lsearch $type $testType] != -1} {
                lappend idList $testID
            }
        }
        set cardID [lindex $idList [expr int(rand() * [llength $idList])]]
    }

    if {$typeName == ""} {
        set typeName $type
    }

    if {$cardID != ""} {
        set card [CrossFire::GetCard $cardID]
        set cardDesc [CrossFire::GetCardDesc $card]
        TellOpponents $w "Message picked $cardDesc for random $typeName..."
    } else {
        TellOpponents $w "Message has no $typeName in pool"
    }

    return
}

# Game::BagOfBeans --
#
#   Emulates NSc/11 Bag of Beans.  Cuts to a card near the middle of the deck
#   and sends it to the discard if it is a realm or the hand otherwise.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::BagOfBeans {w} {

    variable gameConfig

    set card [CutDeck $w "no"]
    if {$card == ""} {
        return
    }
    set pos [lsearch $gameConfig($w,drawPile) $card]
    set gameConfig($w,drawPile) \
        [lreplace $gameConfig($w,drawPile) $pos $pos]
    set cardDesc [CrossFire::GetCardDesc $card]
    set cardID [lindex $cardDesc 0]
    set gameConfig($w,cardID) $cardID

    if {[lindex $card 3] == 13} {
        # Must discard if it is a realm.
        MoveCard $w discard $cardID card
        set chatter " and discarded $cardDesc !!"
    } else {
        MoveCard $w hand $cardID card
        set chatter "..."
    }

    TellOpponents $w "Message reached into the Bag of Beans$chatter"

    return
}

# Game::MithrilHall --
#
#   Emulates Mithril/Mithral Hall cards.  Search draw pile for first
#   magical item or artifact and play to hand.
#
# Parameters:
#   w          Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::MithrilHall {w} {

    variable gameConfig

    TellOpponents $w "Message takes a trip through Mithril Hall..."

    if {[llength $gameConfig($w,drawPile)] == 0} {
        TellOpponents $w "Message has no cards in draw pile"
        tk_messageBox -title "Unable to Comply" -icon info \
            -message "No cards in draw pile!"
        return
    }

    set card ""
    foreach tempCard $gameConfig($w,drawPile) {
        if {[lsearch "2 9" [lindex $tempCard 3]] != -1} {
            set card $tempCard
            break
        }
    }

    if {$card == ""} {
        TellOpponents $w "Message found nothing in Mithril Hall"
    } else {
        set pos [lsearch $gameConfig($w,drawPile) $card]
        set gameConfig($w,drawPile) \
            [lreplace $gameConfig($w,drawPile) $pos $pos]
        set cardDesc [CrossFire::GetCardDesc $card]
        set cardID [lindex $cardDesc 0]
        set gameConfig($w,cardID) $cardID
        MoveCard $w hand $cardID card
        ShuffleDrawPile $w
        TellOpponents $w "Message returned from Mithril Hall with booty!"
    }

    return
}

# Game::ConGame --
#
#   Emulates having the ol' Con Game brutally played on the pool.  Grrrr!
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::ConGame {w} {

    variable gameConfig

    if {[llength $gameConfig($w,poolList)] == 0} {
        tk_messageBox -title "Happy Day!!" -icon info \
            -message "No Pool = No Con Game!!"
        return
    }

    set poolList {}
    foreach champList $gameConfig($w,poolList) {
        foreach card $champList {
            lappend poolList [lindex $card 0]
        }
    }

    set lostCards {}
    set lose 0
    foreach cardID [ShuffleCards $poolList] {
        if {$lose == 1} {
            lappend lostCards $cardID
        }
        set lose [expr 1 - $lose]
    }

    TellOpponents $w "Message is conned out of cards $lostCards ..."

    return
}

# Game::RecallCards --
#
#   Returns the specified cards from the discard pile to draw.
#
# Parameters:
#   w          : Game toplevel.
#   typeName   : Name of the type of cards to recall.
#   typeList   : List of card type IDs to recall.
#
# Returns:
#   Nothing.
#
proc Game::RecallCards {w typeName typeList {mode type}} {

    variable gameConfig

    set gotOne 0
    foreach cardInfo $gameConfig($w,discardList) {
        set id [lindex [lindex $cardInfo 0] 0]
        set card [CrossFire::GetCard $id]
        set type [lindex $card 3]
        set move 0
        if {$mode == "type"} {
            if {[lsearch $typeList $type] != -1} {
                set gotOne 1
                set move 1
            }
        } else {
            set attrList [lindex $card 10]
            foreach attr $typeList {
                if {[lsearch $attrList $attr] != -1} {
                    set gotOne 1
                    set move 1
                }
            }
        }
        if {$move == 1} {
            set gameConfig($w,cardID) $id
            MoveCard $w draw recall discard
        }
    }

    if {$gotOne == 1} {
        TellOpponents $w "Message returned all $typeName to draw"
        ShuffleDrawPile $w
    }

    return
}

# Game::Undermountain --
#
#   Emulates the card Undermountain.  Draws the bottom 3 cards and places
#   any monsters in the pool; others to top of draw.  Tells player what
#   the others were.
#
# Parameters:
#   w          : Game toplevel.
#
# Returns:
#   Nothing.
#
proc Game::Undermountain {w} {

    variable gameConfig

    set first [expr [llength $gameConfig($w,drawPile)] - 3]
    set drawList [lrange $gameConfig($w,drawPile) $first end]
    if {$drawList == ""} {
        tk_messageBox -title "Undermountain Error" -icon error \
            -message "You have no cards in draw pile!"
        return
    }

    set gameConfig($w,drawPile) \
        [lreplace $gameConfig($w,drawPile) $first end]
    set cardList ""
    foreach card $drawList {
        set cardDesc [CrossFire::GetCardDesc $card end]
        set cardID [lindex $cardDesc end]
        if {[lindex $card 3] == 10} {
            # Monsters go to the pool
            set gameConfig($w,cardID) $cardID
            MoveCard $w pool $cardID card
            TellOpponents $w "Message moved card $cardDesc from draw to pool"
        } else {
            append cardList "$cardDesc\n"
            set gameConfig($w,cardID) $cardID
            MoveCard $w draw $cardID card
        }
    }

    TellOpponents $w "Message has delved under a mountain..."

    tk_messageBox -title "Undermountain Note" -icon info \
        -message "Cards:\n${cardList}were sent to top of draw"

    return
}

# Game::SetTraps --
#
#   Emulates the card Set Traps.  Draws a card and then hides it under
#   the lead realm.
#
# Parameters:
#   w          : Game toplevel
#
# Returns:
#   Nothing.
#
proc Game::SetTraps {w} {

    variable gameConfig

    set gameConfig($w,cardID) "unknown"
    set cardID [lindex [lindex [MoveCard $w hand drawCard draw] 0] 0]
    if {$cardID == ""} {
        return
    }

    set card [CrossFire::GetCard $cardID]
    set cardDesc [CrossFire::GetCardDesc $card end]
    set gameConfig($w,cardID) $cardID
    MoveCard $w attachA setTraps hidehand

    TellOpponents $w "Message has set a trap..."

    tk_messageBox -title "Set Traps" -icon info \
        -message "You set a trap with card:\n$cardDesc"

    return
}

# Game::Solitaire --
#
#   Creates a window for launching a game.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Game::Solitaire {} {

    variable gameConfig

    set w .solStart

    if {[winfo exists $w]} {
        wm deiconify $w
        raise $w
        return
    }

    toplevel $w
    wm title $w "Solitaire"

    frame $w.top -relief raised -borderwidth 1
    foreach maxRealm $gameConfig(formation,keyList) {
        radiobutton $w.top.r$maxRealm \
            -text $gameConfig(formation,$maxRealm,name) \
            -value $maxRealm -variable Game::gameConfig(solMode)
        grid $w.top.r$maxRealm -padx 5 -pady 5 -sticky w
    }

    frame $w.buttons -relief raised -borderwidth 1
    button $w.buttons.launch -text "Start" -width 6 -command [subst {
        Game::Create Solitaire "\$Game::gameConfig(solMode)" Offline
        destroy $w
    }]
    button $w.buttons.cancel -text "Cancel" -width 6 -command "destroy $w"
    grid $w.buttons.launch $w.buttons.cancel -padx 5 -pady 5

    grid $w.top -sticky nsew
    grid $w.buttons -sticky ew

    grid rowconfigure $w 0 -weight 1
    grid columnconfigure $w 0 -weight 1

    if {$CrossFire::platform == "windows"} {
        focus $w
    }

    return
}

# Game::RollDice --
#
#   Rolls dice.
#
# Parameters:
#   w          : Game toplevel
#   number     : Number of times to roll the die.
#   sides      : Number of sides of the die.
#   modifier   : Amount to add to or subtract from the total.
#
# Returns:
#   Nothing.  Prints total to chat window.
#
proc Game::RollDice {w {number 1} {sides 6} {modifier 0}} {

    set total $modifier
    set rollList {}

    for {set i 1} {$i <= $number} {incr i} {
	set roll [expr int(rand() * $sides + 1)]
	incr total $roll
	if {$rollList != ""} {
	    append rollList ", "
	}
	append rollList $roll
    }

    set dieString ""
    if {$number > 1} {
	append dieString "$number"
    }
    append dieString "d$sides"
    if {$modifier < 0} {
	append dieString "$modifier"
    } elseif {$modifier > 0} {
	append dieString "+$modifier"
    }

    if {$number > 1} {
	TellOpponents $w \
	    "Message rolled $dieString and got $rollList for a total of $total"
    } else {
	TellOpponents $w "Message rolled a d$sides and got $total"
    }

    return
}

# Game::RollCustom --
#
#   Creates a GUI for entry of a custom die roll string.
#
# Parameters:
#   w          : Game toplevel
#
# Returns:
#   Nothing.
#
proc Game::RollCustom {w} {

    variable gameConfig

    set tw $w.rollCustom

    if {[winfo exists $tw]} {
	wm deiconify $tw
	raise $tw
	return
    }

    toplevel $tw
    wm title $tw "Roll Custom Dice"
    wm protocol $tw WM_DELETE_WINDOW "$tw.buttons.cancel invoke"

    frame $tw.top -borderwidth 1 -relief raised
    label $tw.top.l -text "Enter die roll string:"
    entry $tw.top.e -width 30 \
	-textvariable Game::gameConfig($w,customRoll)
    grid $tw.top.l -sticky w  -padx 5 -pady 5
    grid $tw.top.e -sticky ew -padx 8 -pady 8
    grid $tw.top -sticky nsew
    grid columnconfigure $tw.top 0 -weight 1

    frame $tw.buttons -borderwidth 1 -relief raised
    button $tw.buttons.ok -text "Roll" -width 8 \
        -command "Game::ProcessCustomRoll $w"
    button $tw.buttons.cancel -text "Cancel" -width 8 \
        -command "destroy $tw"
    grid $tw.buttons.ok $tw.buttons.cancel -padx 5 -pady 5

    grid $tw.buttons -sticky ew

    grid rowconfigure $tw 0 -weight 1
    grid columnconfigure $tw 0 -weight 1

    set gameConfig($w,customRoll) ""
    focus $tw.top.e

    return
}

# Game::ProcessCustomRoll --
#
#   Manipulates the custom die roll string from RollCustom and calls
#   RollDice to get and display the result.
#
# Parameters:
#   w          : Game toplevel
#
# Returns:
#   Nothing.
#
proc Game::ProcessCustomRoll {w} {

    variable gameConfig

    # Format: [n]d{4,6,10}[+-m]
    set dieString $gameConfig($w,customRoll)

    regsub -all "\[d+\]" $dieString " " dieString
    regsub -- "-" $dieString " -" dieString

    foreach {number sides modifier} $dieString break

    # Some error checking
    if {$number < 1} {
	set number 1
    } elseif {$number > 100} {
	set number 100
    }

    if {$sides < 2} {
	set sides 2
    } elseif {$sides > 100} {
	set sides 100
    }

    eval RollDice $w $number $sides $modifier

    return
}
