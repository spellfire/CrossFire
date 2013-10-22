# USearch.tcl 20050804
#
#    This file contains all the procedures for perfoming an UltraSearch.
#    An UltraSearch is a GUI-less search with all of the capability of the
#    UltraSearcher window.  The purpose is so that any CrossFire part can
#    perform complex card searches.  Obviously, Random Deck Generator will
#    be a prime candidate for this!
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

#
# UltraSearch -- We find the cards YOU need!
#
# Procedures:
#   UltraSearch::New {}                       => searchID
#   UltraSearch::Clear {searchID}
#   UltraSearch::Set {searchID criteria data} => data
#   UltraSearch::Search {searchID}            => list of card IDs
#   UltraSearch::Delete {searchID}
#
# Criteria:
#   setIDList    {}    List of set IDs
#   titleToggle  0     Boolean for card title
#   searchTitle  ""    Text for card title
#   textToggle   0     Boolean for card text
#   searchText   ""    Text for card text
#   textMode     "RE"  Mode for card text { +/- || RE }
#   levelToggle  0     Boolean for levels
#   searchLevels ""    List of levels
#   numberToggle 0     Boolean for last digit
#   searchNumber ""    List of last digits
#   avatarToggle 0     Boolean for avatar
#   avatarMode   'yes' Card is an avatar {I18n 'yes' || 'no'}
#   chaseToggle  0     Boolean for chase
#   chaseMode    'yes' Card is a chase {I18n 'yes' || 'no'}
#   rarityToggle 0     Boolean for rarity
#   searchRarity "C"   A card rarity. See CommonV.tcl - cardFreqIDList
#   attrToggle   0     Boolean for attributes
#   attrList     {}    List of attribute IDs. See CommonV.tcl - cardAttributes
#   attrMode     "OR"  Mode for attributes {AND:all || OR:any}
#   typeToggle   0     Boolean for card type
#   typeList     {}    List of card type IDs. See CommonV.tcl - cardTypeIDList
#   worldToggle  0     Boolean for world
#   worldList    {}    List of world IDs. See CommonV.tcl - worldIDList
#   usesToggle   0     Boolean for usable cards
#   usesMode     "OR"  Mode for usable cards {AND:all || OR:any}
#   usesList     {}    List of usable card types. See CommonV.tcl - usableList
#

namespace eval UltraSearch {

    variable storage

    set storage(count) 0
}

# UltraSearch::New --
#
#   Creates storage space for a search and calls Clear.
#
# Parameters:
#   None.
#
# Returns:
#   Search ID.
#
proc UltraSearch::New {} {

    variable storage

    set searchID [incr storage(count)]
    lappend storage(searchIDList) $searchID

    Clear $searchID

    return $searchID
}

# UltraSearch::Clear --
#
#   Sets all search criteria to null/default.
#
# Parameters:
#   searchID   : ID for the search.  Returned from New
#
# Returns:
#   Nothing.
#
proc UltraSearch::Clear {searchID} {

    Set $searchID setIDList {}
    Set $searchID titleToggle 0
    Set $searchID searchTitle ""
    Set $searchID textToggle 0
    Set $searchID searchText ""
    Set $searchID textMode "RE"
    Set $searchID levelToggle 0
    Set $searchID searchLevels ""
    Set $searchID numberToggle 0
    Set $searchID searchNumber ""
    Set $searchID avatarToggle 0
    Set $searchID avatarMode [ML::str yes]
    Set $searchID chaseToggle 0
    Set $searchID chaseMode [ML::str yes]
    Set $searchID rarityToggle 0
    Set $searchID searchRarity "C"
    Set $searchID attrToggle 0
    Set $searchID attrList {}
    Set $searchID attrMode "OR"
    Set $searchID typeToggle 0
    Set $searchID typeList {}
    Set $searchID worldToggle 0
    Set $searchID worldList {}
    Set $searchID usesToggle 0
    Set $searchID usesMode "OR"
    Set $searchID usesList {}

    return
}

# UltraSearch::Set --
#
#   Sets a criteria's value.
#
# Parameters:
#   searchID   : ID for the search.  Returned from New
#   criteria   : One of the various search criteria.  See Clear
#   data       : Value to set the criteria to.
#
# Returns:
#   The value.
#
proc UltraSearch::Set {searchID criteria data} {

    variable storage

    set storage($searchID,$criteria) $data

    return $data
}

# UltraSearch::Search --
#
#   Searches all the cards for matches to the Ultra Search criteria.
#
# Parameters:
#   searchID   : ID for the search.  Returned from New
#
# Returns:
#   Nothing.
#
proc UltraSearch::Search {searchID} {

    variable storage

    # Verify this is a valid search ID
    if {[lsearch $storage(searchIDList) $searchID] == -1} {
        return {}
    }

    set searchTitle $storage($searchID,searchTitle)

    if {$storage($searchID,textToggle) == 1} {
        if {$storage($searchID,textMode) == "+/-"} {
            foreach {searchInclude searchExclude} \
                $storage($searchID,searchText) break
        } else {
            set searchText $storage($searchID,searchText)
        }
    }

    if {$storage($searchID,levelToggle) == 1} {
        set searchLevels $storage($searchID,searchLevels)
    }

    if {$storage($searchID,numberToggle) == 1} {
        set searchNumber $storage($searchID,searchNumber)
    }

    if {$storage($searchID,attrToggle) == 1} {
        set searchAttrList $storage($searchID,attrList)
    } else {
        set searchAttrList {}
    }

    if {$storage($searchID,typeToggle) == 1} {
        set searchTypes $storage($searchID,typeList)
    } else {
        set searchTypes {}
    }

    if {$storage($searchID,worldToggle) == 1} {
        set searchWorlds $storage($searchID,worldList)
    } else {
        set searchWorlds {}
    }

    if {$storage($searchID,usesToggle) == 1} {
        set searchUsesList $storage($searchID,usesList)
    } else {
        set searchUsesList {}
    }

    set chaseMode $storage($searchID,chaseMode)
    set avatarMode $storage($searchID,avatarMode)

    set results {}

    set yes [ML::str yes]
    set no  [ML::str no]

    foreach setID [CrossFire::CardSetIDList "allPlain"] {

        if {[lsearch $storage($searchID,setIDList) $setID] == -1} {
            continue
        }
        set setMax $CrossFire::setXRef($setID,setMax)
        CrossFire::ReadCardDataBase $setID

        foreach card [lrange $CrossFire::cardDataBase 1 end] {

            foreach {
                tempSetID cardNumber bonus type world isAvatar
                title text frequency blueLine attrList usesList
            } $card break

            if {($storage($searchID,typeToggle) == 1) &&
                ([lsearch $searchTypes $type] == -1)} {
                continue
            }

            if {($storage($searchID,worldToggle) == 1) &&
                ([lsearch $searchWorlds $world] == -1)} {
                continue
            }

            if {($storage($searchID,titleToggle) == 1) &&
                ([regexp -nocase -- $searchTitle $title] == 0)} {
                continue
            }

            set cardText "$text $blueLine"
            if {$storage($searchID,textToggle) == 1} {
                if {$storage($searchID,textMode) == "RE"} {
                    # Good old regular expression :)
                    if {[regexp -nocase -- $searchText $cardText] == 0} {
                        continue
                    }
                } else {
                    # Search Engine +this -that style search
                    set fail 0

                    # Check for all items that must be in the text
                    foreach elem $searchInclude {
                        if {![regexp -nocase $elem $cardText]} {
                            set fail 1
                        }
                    }
                    if {$fail == 1} {
                        continue
                    }

                    # Check for all items that must not be in the text
                    foreach elem $searchExclude {
                        if {[regexp -nocase $elem $cardText]} {
                            set fail 1
                        }
                    }

                    if {$fail == 1} {
                        continue
                    }
                }
            }

            if {$storage($searchID,levelToggle) == 1} {
                regsub "^\\+" [lindex [split $bonus "/"] 0] "" level
                if {$level == "-½"} {
                    set level -1
                } elseif {$level == "?"} {
                    set level 0
                }
                if {[lsearch -exact $searchLevels $level] == -1} {
                    continue
                }
            }

            if {$storage($searchID,attrToggle) == 1} {
                set all 1
                set any 0
                foreach attrPattern $searchAttrList {
                    if {[lsearch $attrList $attrPattern] == -1} {
                        set all 0
                    } else {
                        set any 1
                    }
                }

                if {$storage($searchID,attrMode) == "AND"} {
                    # AND mode (all must match to be OK)
                    if {$all == 0} {
                        continue
                    }
                } else {
                    # OR mode (allows for any to match to be OK)
                    if {$any == 0} {
                        continue
                    }
                }
            }

            if {$storage($searchID,usesToggle) == 1} {
                set all 1
                set any 0
                foreach usesPattern $searchUsesList {
                    if {[lsearch $usesList $usesPattern] == -1} {
                        set all 0
                    } else {
                        set any 1
                    }
                }

                if {$storage($searchID,usesMode) == "AND"} {
                    # AND mode (all must match to be OK)
                    if {$all == 0} {
                        continue
                    }
                } else {
                    # OR mode (allows for any to match to be OK)
                    if {$any == 0} {
                        continue
                    }
                }
            }

            if {$storage($searchID,avatarToggle) == 1} {
                if {(($isAvatar != 0) && ($avatarMode == $no)) ||
                    (($isAvatar == 0) && ($avatarMode == $yes))} {
                    continue
                }
            }

            if {$storage($searchID,chaseToggle) == 1} {
                set isChase [expr $cardNumber > $setMax]
                if {(($isChase != 0) && ($chaseMode == $no)) ||
                    (($isChase == 0) && ($chaseMode == $yes))} {
                    continue
                }
            }

            if {($storage($searchID,numberToggle) == 1) &&
                ([lsearch $searchNumber \
                      [string range $cardNumber end end]] == -1)} {
                continue
            }

            if {($storage($searchID,rarityToggle) == 1) &&
                ($storage($searchID,searchRarity) != $frequency)} {
                continue
            }

            lappend results \
                [lindex [CrossFire::GetCardID $tempSetID $cardNumber] 0]
        }
    }

    return $results
}

# UltraSearch::Delete --
#
#   Removes all the data for a particular search.
#
# Parameters:
#   searchID   : ID for the search.  Returned from New
#
# Returns:
#   Nothing.
#
proc UltraSearch::Delete {searchID} {

    variable storage

    # Remove all the variables
    foreach varName [array names storage "$searchID,*"] {
        unset storage($varName)
    }

    # Remove from searchIDList
    set pos [lsearch $storage(searchIDList) $searchID]
    set storage(searchIDList) [lreplace $storage(searchIDList) $pos $pos]

    return
}
