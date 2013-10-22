# CommonV.tcl 20051229
#
# This file defines the main data structures for card sets and types.
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

namespace eval CrossFire {

    variable wikiURL \
        {http://crossfire.spellfire.net/wiki/wiki.asp?db=CrossFire&o=}

    # Yogiland has official documentation on several sets.
    variable yogiSets {DR IQ MI CH CQ}

    variable cardDigitList {0 1 2 3 4 5 6 7 8 9}

    variable ie {}

    variable XFprocess
    set processInfo {
        viewer   {Card Viewer}     {cv,windowName} ViewCard::Viewer
        searcher {Ultra Searcher}  {ss,windowName} Searcher::Create
        deckIt   {DeckIt!}         {} Editor::Create
        format   {Format Maker}    {} FormatIt::Create
        cardInv  {Card Warehouse}  {} Inventory::Create
        swapShop {Swap Shop}       {} SwapShop::Create
        solGame  {Solitaire Game}  {} Game::Solitaire
        cardEdit {Fan Set Editor}  {} EditCard::Create
        comboMan {ComboMan}        {} Combo::Create
        comboVue {Combo Viewer}    {} Combo::Viewer
        chatRoom {Online Chat}     {} Chat::Login
        logView  {Chat Log Viewer} {} Chat::CreateLogViewer
        backUp   {Back Up Files}   {} BackUp::BackUp
        restore  {Restore Files}   {} BackUp::Restore
        config   {Configure}       {} {Config::Create CrossFire}
        help     {Help}            {} {CrossFire::Help cf_main.html}
        quit     {Exit CrossFire}  {} CrossFire::Exit
    }
    foreach {graphic name mlKey command} $processInfo {
        lappend XFprocess(list) $name
        set XFprocess(graphic,$name) $graphic
        set XFprocess(command,$name) $command
	set XFprocess(mlkey,$name) $mlKey
    }

    variable extension
    array set extension {
        combo   .cfc
        deck    .cfd
        format  .cff
        config  .cfg
        game    .cfo
        inv     .cfi
        log     .cfl
        trade   .cft
        values  .cfv
    }

    # Set the accelerator key name, binding name, and file types
    # depending on the platform CrossFire is running on.
    if {$platform == "macintosh"} {
        variable accelKey "Command"
        variable accelBind "Command"
        variable deckFileTypes {
            {{CrossFire Deck} {} DECK}
            {{CrossFire Deck [as Text]} {.cfd} TEXT}
            {{All Files} {*}}
        }
        variable invFileTypes {
            {{CrossFire Inventory} {} INVT}
            {{CrossFire Inventory [as Text]} {.cfi} TEXT}
            {{All Files} {*}}
        }
        variable tradeFileTypes {
            {{CrossFire Trade} {} TRAD}
            {{CrossFire Trade [as Text]} {.cft} TEXT}
            {{All Files} {*}}
        }
        variable comboFileTypes {
            {{CrossFire Combo} {} COMB}
            {{CrossFire Combo [as Text]} {.cfc} TEXT}
            {{All Files} {*}}
        }
        variable logFileTypes {
            {{CrossFire Chat Log} {} CLOG}
            {{CrossFire Chat Log [as Text]} {.cfl} TEXT}
            {{All Files} {*}}
        }
        variable actionFileTypes {
            {{Chat Actions} {.cfa} TEXT}
            {{All Files} {*}}
        }
        variable formatFileTypes {
            {{CrossFire Deck Format} {} DFOR}
            {{CrossFire Deck Format [as Text]} {.cff} TEXT}
            {{All Files} {*}}
        }
        variable gameFileTypes {
            {{CrossFire Game Format} {} CFOG}
            {{CrossFire Game Format [as Text]} {.cfo} TEXT}
            {{All Files} {*}}
        }

        variable macCode
        array set macCode {
            creator XFIR
            deck    DECK
            inv     INVT
            trade   TRAD
            combo   COMB
            log     CLOG
            format  DFOR
            format  CFOG
        }

    } else {
        variable accelKey "Ctrl"
        variable accelBind "Control"
        variable deckFileTypes {
            {{CrossFire Deck} {.cfd}}
            {{All Files} {*}}
        }
        variable invFileTypes {
            {{CrossFire Inventory} {.cfi}}
            {{All Files} {*}}
        }
        variable tradeFileTypes {
            {{CrossFire Trade} {.cft}}
            {{All Files} {*}}
        }
        variable comboFileTypes {
            {{CrossFire Combo} {.cfc}}
            {{All Files} {*}}
        }
        variable logFileTypes {
            {{CrossFire Chat Log} {.cfl}}
            {{All Files} {*}}
        }
        variable actionFileTypes {
            {{Chat Actions} {.cfa}}
            {{All Files} {*}}
        }
        variable formatFileTypes {
            {{CrossFire Deck Format} {.cff}}
            {{All Files} {*}}
        }
        variable gameFileTypes {
            {{CrossFire Game Format} {.cfo}}
            {{All Files} {*}}
        }
    }

    # What shall we call the close button?.
    if {$platform == "unix"} {
        variable close "Dismiss"
    } else {
        variable close "Close"
    }

    # A string of 65 spaces...used for padding and centering.
    variable spaces \
        "                                                                 "

    # Array to store active toplevel paths by process
    variable toplevelReg
    foreach process {
        CardEditor CardViewer Chat ComboMan DeckIt SwapShop Warehouse Format
    } {
        set toplevelReg($process) {}
    }

    variable fanAttributes {} ;# Stores all fan set attributes

    # AddCardSet --
    #
    #   Adds a card set to the card set look up arrays.
    #
    # Parameters:
    #   class      : One of all, ed, intl, bost, or fan. This is the 
    #                classification of the set. (Which submenu it belongs on.)
    #
    # Returns:
    #   Nothing.
    #
    proc AddCardSet {class setID name numLimits chaseQty tclFile \
                         sfdbID {attrList ""}} {

        variable setXRef
        variable homeDir
        variable setClass
        variable fanAttributes

        if {$class == "fan"} {
            set fileName [file join $homeDir "FanSets" $tclFile]
            foreach attr $attrList {
                if {[lsearch $fanAttributes $attr] == -1} {
                    lappend fanAttributes $attr
                }
            }
        } else {
            set fileName [file join $homeDir "DataBase" $tclFile]
            set setXRef($setID,author) $attrList
        }

        if {[lsearch $setClass($class,ids) $setID] == -1} {
            lappend setClass($class,ids) $setID
        }

        if {([file exists $fileName] == 0) && ($setID != "All")} {
            return
        }

        # Make the cross reference table indexed by set ID.
        set setXRef($setID,name)       $name
        set setXRef($setID,numLimits)  $numLimits
        set setXRef($setID,setMax)     [lindex $numLimits end]
        set setXRef($setID,chaseQty)   $chaseQty
        set setXRef($setID,lastNumber) \
            [expr $setXRef($setID,setMax) + $chaseQty]
        set setXRef($setID,tclFile)    $fileName
        set setXRef($setID,sfdbID)     $sfdbID

        # Cross reference from set name to ID.
        set setXRef($name) $setID

        # Cross reference from SFDB2.0 to CrossFire.
        set setXRef($sfdbID) $setID

        return
    }

    variable setClass
    foreach {class className} {
        all  {All Card Sets}
        ed   {Edition}
        bost {Booster}
        stik {Sticker Booster}
        intl {International}
        fan  {Fan}
    } {
        lappend setClass(list) $class
        set setClass($class,ids) {}
        set setClass($class,name) $className
        set setClass($className) $class
    }

    # cardSetInfo stores information on all the card sets.
    #
    # The format for each card set is:
    #   class
    #   {Set ID}
    #   name      {Set_Name}
    #   numLimits {Num_Limit [Num_Limit ...]}
    #   chaseQty  {Chase_Qty}
    #   tclFile   {Tcl file for the card set.}
    #   sfdbID    {SF DB 2.x identifier}
    #
    set cardSetInfo {
        {all  All {All Card Sets}        0            0 na      na}
        {ed   NO  {No Edition}         400            0 NO.tcl  NoEdition}
        {ed   1st {1st Edition}        {400 420 440} 25 1st.tcl 1stEdition}
        {ed   2nd {2nd Edition}        {400 420}      0 2nd.tcl 2ndEdition}
        {ed   3rd {3rd Edition}        400            0 3rd.tcl 3rdEdition}
        {ed   4th {4th Edition}        {500 520}      0 4th.tcl 4thEdition}
        {bost PR  Promo                  3            0 PR.tcl  Promotional}
        {bost RL  Ravenloft            100            0 RL.tcl  Ravenloft}
        {bost DL  DragonLance          100           25 DL.tcl  DragonLance}
        {bost FR  {Forgotten Realms}   100           25 FR.tcl  ForgottenRealms}
        {bost AR  Artifacts            100           20 AR.tcl  Artifacts}
        {bost PO  Powers               100           20 PO.tcl  Powers}
        {bost UD  {The Underdark}      100           25 UD.tcl  UnderDark}
        {bost RR  {Runes & Ruins}      100           25 RR.tcl  Runes&Ruins}
        {bost BR  Birthright           100           25 BR.tcl  Birthright}
        {bost DR  Draconomicon         100           25 DR.tcl  Draconomicon}
        {bost NS  {Night Stalkers}     100           25 NS.tcl  NightStalkers}
        {bost DU  Dungeons             100           25 DU.tcl  Dungeons}
        {stik IQ  Inquisition           99            0 IQ.tcl  na {Spellfire Community}}
        {stik MI  Millennium            99            0 MI.tcl  na {Spellfire Community}}
        {stik CH  Chaos                 72            0 CH.tcl  na {Spellfire Community}}
        {stik CQ  Conquest              81            0 CQ.tcl  na {Spellfire Community}}
        {intl FRN {French Edition}     400           25 FRN.tcl na}
        {intl DE  {German Edition}     400           25 DE.tcl  na}
        {intl IT  {Italian Edition}    400           25 IT.tcl  na}
        {intl POR {Portuguese Edition} 400           25 POR.tcl na}
        {intl SP  {Spanish Edition}    400           25 SP.tcl  na}
    }

    variable setXRef

    foreach setInfo $cardSetInfo {
        eval AddCardSet $setInfo
    }

    # AddWorld --
    #
    #   Adds a world to the world look up arrays.
    #
    # Parameters:
    #
    # Returns:
    #   Nothing.
    #
    proc AddWorld {class worldID name worldIcon iconFile shortName} {

        variable worldXRef
        variable worldIDList
        variable fanWorldIDList

        lappend worldIDList $worldID

        if {$class == "fan"} {
            lappend fanWorldIDList $worldID
            lappend worldXRef(IDList,Fan) $worldID
        } else {
            lappend worldXRef(IDList,Base) $worldID
        }

        set worldXRef($worldID,name) $name
        set worldXRef($worldID,shortName) $shortName
        set worldXRef($worldID,icon) $worldIcon

        if {$iconFile != "null"} {
            if {$class == "base"} {
                set grDir [file join "Graphics" "Icons"]
            } else {
                set grDir "FanSets"
            }
            set gifName \
                [file join $CrossFire::homeDir $grDir $iconFile]
            if {[file exists $gifName]} {
                image create photo $worldIcon -file $gifName
            }
        }

        # Cross reference from world name to ID.
        set worldXRef($name) $worldID

        return
    }

    # worldInfo holds all the information on the various worlds.
    #
    # The format for each world is:
    #   {Card set type} := [base | fan]
    #   {ID}
    #   {Name}
    #   {Image Name}
    #   {Image Filename}
    #   {Abbreviation}
    #
    set worldInfo {
        {base 0 None               NoWorld         worldad2.gif {}}
        {base 7 {AD&D}             ADD             worldadd.gif AD&D}
        {base 6 Birthright         Birthright      worldbr.gif  BR}
        {base 4 {Dark Sun}         DarkSun         worldds.gif  DS}
        {base 5 DragonLance        DragonLance     worlddl.gif  DL}
        {base 1 {Forgotten Realms} ForgottenRealms worldfr.gif  FR}
        {base 2 Greyhawk           Greyhawk        worldgh.gif  GH}
        {base 3 Ravenloft          Ravenloft       worldrl.gif  RL}
        {base 8 TSR                TSR             null         TSR}
	{base 9 {No World}         Blank           worldnon.gif {}}
    }

    variable worldXRef
    variable worldIDList {}
    variable fanWorldIDList {}

    foreach world $worldInfo {
        eval AddWorld $world
    }

    # cardTypeInfo
    #
    # The format for each card type is:
    #   {Numeric ID}
    #   {Type Name}
    #   {Champion Boolean}
    #   {Usable Flag}
    #   {Icon name, Limit name}
    #   {Icon file name}
    #
    set cardTypeInfo {
        {0   {All Cards}      0 0 All            nocard.gif}
        {1   Ally             0 1 Ally           ally.gif}
        {2   Artifact         0 1 Artifact       artifact.gif} 
        {3   {Blood Ability}  0 2 Blood_Ability  bability.gif}
        {5   Cleric           1 0 Cleric         cleric.gif}
        {4   {Cleric Spell}   0 2 Cleric_Spell   cspell.gif}
        {21  Dungeon          0 0 Dungeon        dungeon.gif}
        {6   Event            0 0 Event          event.gif}
        {7   Hero             1 0 Hero           hero.gif}
        {8   Holding          0 0 Holding        holding.gif}
        {9   {Magical Item}   0 2 Magical_Item   magicitm.gif}
        {10  Monster          1 0 Monster        monster.gif}
        {12  Psionicist       1 0 Psionicist     psionic.gif}
        {11  {Psionic Power}  0 2 Psionic_Power  ppower.gif}
        {13  Realm            0 0 Realm          realm.gif}
        {14  Regent           1 0 Regent         regent.gif}
        {15  Rule             0 0 Rule           rule.gif}
        {16  Thief            1 0 Thief          thief.gif}
        {17  {Thief Ability}  0 2 Thief_Ability  tability.gif}
        {18  {Unarmed Combat} 0 2 Unarmed_Combat ucombat.gif}
        {20  Wizard           1 0 Wizard         wizard.gif}
        {19  {Wizard Spell}   0 2 Wizard_Spell   wspell.gif}
        {99  Champions        0 0 Champions      null}
        {100 Chase            0 0 Chase          null}
        {200 {Total Levels}   0 0 Levels         null}
    }

    variable cardTypeXRef
    variable cardTypeIDList
    variable championList "" ;# List of IDs for all champion types.

    # List of IDs that are usable by other cards
    variable usableCards
    foreach {id name} {
        101 {Dragon Unarmed Combat}
        102 {Undead Unarmed Combat}
    } {
        set nameD "$name, Def"
        set nameO "$name, Off"
        set usableCards(ID,$nameD) d$id
        set usableCards(ID,$nameO) o$id
        set usableCards(uses,d$id) $nameD
        set usableCards(uses,o$id) $nameO
        lappend usableCards(list) $nameD
        lappend usableCards(list) $nameO
    }

    foreach cardType $cardTypeInfo {

        foreach {cardTypeID name champion usable cardIcon graphicFileName} \
            $cardType break

        lappend cardTypeIDList $cardTypeID

        set cardTypeXRef($cardTypeID,name) $name

        if {$champion} {
            lappend championList $cardTypeID
        }

        set id $cardTypeID
        if {$usable == 1} {
            lappend usableCards(list) $name
            set usableCards(ID,$name) $id
            set usableCards(uses,$id) $name
        } elseif {$usable == 2} {
            set nameD "$name, Def"
            set nameO "$name, Off"
            set usableCards(ID,$nameD) d$id
            set usableCards(ID,$nameO) o$id
            set usableCards(uses,d$id) $nameD
            set usableCards(uses,o$id) $nameO
            lappend usableCards(list) $nameD
            lappend usableCards(list) $nameO
        }

        set cardTypeXRef($cardTypeID,icon) $cardIcon

        if {$graphicFileName != "null"} {
            set gifName \
                [file join $CrossFire::homeDir \
                     "Graphics" "Icons" $graphicFileName]
            if {[file exists $gifName]} {
                image create photo $cardTypeXRef($cardTypeID,icon) \
                    -file $gifName
            }
            set smallGifName \
                [file join $CrossFire::homeDir "Graphics" "Icons" \
                     "Small" $graphicFileName]
            if {[file exists $smallGifName]} {
                image create photo small$cardTypeID -file $smallGifName
            }
        }

        # Cross reference from card type name to ID.
        set cardTypeXRef($name) $cardTypeID
    }

    # cardFrequency
    #
    # List of card frequencies. Format:
    #  {ID  PV Name}
    #
    variable cardFrequency {
        M    1 Realm
        C    1 Common
        UC   2 Uncommon
        R    4 Rare
        VR  24 {Very Rare}
        S   25 Special
        V    0 Virtual
    }

    variable cardFreqIDList
    variable cardFreqName
    variable cardFreqPV

    foreach {freqID freqPV freqName} $cardFrequency {
        lappend cardFreqIDList $freqID
        set cardFreqPV($freqID) $freqPV
        set cardFreqName($freqID) $freqName
        set cardFreqXRef($freqName) $freqID
    }

    # Various card attributes. Mainly used by Ultra Searcher.
    variable cardAttributes
    foreach {id attr} {
        1 Adventurer
        2 Awnshegh
        3 Beholder
        4 {Black Wizard}
        5 Coastal
        6 Defensive
        7 Draconian
        8 Dragon
        9 {Dragon Unarmed Combat}
        10 Drow
        11 Duergar
        12 Dwarf
        13 Earthwalker
        14 Elf
        15 Familiar
        16 Flyer
        17 Giant
        18 Gnome
	19 Golem
        20 Half-Elf
        21 Halfling
        22 Harmful
        23 Helpful
        24 Kender
        25 Kobold
        26 Mul
        27 Offensive
        28 Orc
	29 {Phase 0}
	30 {Phase 1}
	31 {Phase 2}
	32 {Phase 3}
	33 {Phase 4}
	34 {Phase 5}
        35 {Red Wizard}
        36 Spear
        37 Swimmer
        38 Sword
        39 Svirfneblin
        40 Undead
        41 {Undead Unarmed Combat}
        42 Underdark
        43 Vampire
        44 Weapon
        45 Werebeast
        46 {White Wizard}
    } {
        lappend cardAttributes(list) $attr
        set cardAttributes(ID,$attr) $id
        set cardAttributes(attr,$id) $attr
    }

}
