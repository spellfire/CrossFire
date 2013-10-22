# SSearch.tcl 20060103
#
# This file contains all the procedures for the Ultra Searcher.
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

namespace eval Searcher {

    variable storage

    set storage(count) 0   ;# Counter for creating new toplevels.
}

# Searcher::Create --
#
#   Creates a ultra searcher window.  The Ultra Searcher allows for some
#   very complex card searches.
#
# Parameters:
#   args      : Optional parent of the Ultra Searcher
#
# Returns:
#   Nothing.
#
proc Searcher::Create {args} {

    variable storage

    if {$args != ""} {
        set w [lindex $args 0].searcher
    } else {
        set w .searcher[incr storage(count)]
    }

    if {[winfo exists $w]} {
        wm deiconify $w
        raise $w
        return
    }

    set storage($w,searchMode) $Config::config(Searcher,searchMode)
    set storage($w,embedCardView) $Config::config(Searcher,embedCardView)
    set storage($w,cardFrame) ""
    set yesNo [list [ML::str yes] [ML::str no]]

    toplevel $w
    wm title $w [ML::str ss,windowName]
    wm protocol $w WM_DELETE_WINDOW "Searcher::ExitSearcher $w"

    AddMenuBar $w

    if {$storage($w,embedCardView) == "Yes"} {
        set numPanes 4
    } else {
        set numPanes 3
    }
    set storage($w,numPanes) $numPanes
    set sashLoc $Config::config(Searcher,sashLoc,$numPanes)

    foreach {width height} $Config::config(Searcher,geometry,$numPanes) break

    set pw [PanedWindow::Create $w.f -orient horizontal -numPanes $numPanes \
                -width $width -height $height -sashLoc $sashLoc]
    set storage($w,paneFrame) $pw

    # List of card sets to search.
    set setListPane [PanedWindow::Pane $pw 1]
    set setList [frame $setListPane.setList]

    set storage($w,sllb) \
        [CrossFire::ScrolledListBox $setList.f \
	     -title "[ML::str cardSets]:" \
             -selectmode multiple]
    bind $storage($w,sllb) <ButtonRelease-1> \
        "Searcher::UpdateSetList $w update"
    UpdateSetList $w init

    grid $setList.f -sticky nsew -padx 5 -pady 5
    grid columnconfigure $setList 0 -weight 1
    grid rowconfigure $setList 0 -weight 1

    grid $setList -sticky nsew -padx 1 -pady 1
    grid columnconfigure $setListPane 0 -weight 1
    grid rowconfigure $setListPane 0 -weight 1

    # Search criteria
    set criteriaPane [PanedWindow::Pane $pw 2]
    set criteria [frame $criteriaPane.criteria]

    frame $criteria.entries

    frame $criteria.entries.title
    checkbutton $criteria.entries.title.cb \
	-text "[ML::str title]:" \
        -padx 0 -variable Searcher::storage($w,titleToggle)
    entry $criteria.entries.title.e \
        -textvariable Searcher::storage($w,searchTitle)
    grid $criteria.entries.title.cb \
        $criteria.entries.title.e -sticky ew
    grid rowconfigure $criteria.entries.title 0 -weight 1
    grid columnconfigure $criteria.entries.title 1 -weight 1
    bindtags $criteria.entries.title.e "$w Entry"

    frame $criteria.entries.text
    checkbutton $criteria.entries.text.cb \
	-text "[ML::str text]:" \
        -padx 0 -variable Searcher::storage($w,textToggle)
    entry $criteria.entries.text.e \
        -textvariable Searcher::storage($w,searchText)
    menubutton $criteria.entries.text.mb -width 3 -indicatoron 1 \
        -menu $criteria.entries.text.mb.menu -relief raised \
        -textvariable Searcher::storage($w,searchMode)
    menu $criteria.entries.text.mb.menu -tearoff 0
    foreach searchMode [array names Config::searchModes] {
        $criteria.entries.text.mb.menu add radiobutton \
            -value $searchMode -label $searchMode \
            -variable Searcher::storage($w,searchMode)
    }
    grid $criteria.entries.text.cb -row 0 -column 0
    grid $criteria.entries.text.e  -row 0 -column 1 -sticky ew -padx 3
    grid $criteria.entries.text.mb -row 0 -column 2
    grid rowconfigure $criteria.entries.text 0 -weight 1
    grid columnconfigure $criteria.entries.text 1 -weight 1
    bindtags $criteria.entries.text.e "$w Entry"

    frame $criteria.entries.level
    checkbutton $criteria.entries.level.cb \
	-text "[ML::str levels]:" \
        -padx 0 -variable Searcher::storage($w,levelToggle)
    entry $criteria.entries.level.e \
        -textvariable Searcher::storage($w,searchLevels)
    grid $criteria.entries.level.cb \
        $criteria.entries.level.e -sticky ew
    grid rowconfigure $criteria.entries.level 0 -weight 1
    grid columnconfigure $criteria.entries.level 1 -weight 1
    bindtags $criteria.entries.level.e "$w Entry"

    frame $criteria.entries.number
    checkbutton $criteria.entries.number.cb \
	-text "[ML::str ss,lastDigit]:" \
        -padx 0 -variable Searcher::storage($w,numberToggle)
    entry $criteria.entries.number.e \
        -textvariable Searcher::storage($w,searchNumber)
    grid $criteria.entries.number.cb \
        $criteria.entries.number.e -sticky ew
    grid rowconfigure $criteria.entries.number 0 -weight 1
    grid columnconfigure $criteria.entries.number 1 -weight 1
    bindtags $criteria.entries.number.e "$w Entry"

    frame $criteria.entries.group1
    frame $criteria.entries.group1.avatar
    checkbutton $criteria.entries.group1.avatar.cb \
	-text "[ML::str avatar]:" \
        -padx 0 -variable Searcher::storage($w,avatarToggle)
    menubutton $criteria.entries.group1.avatar.om -indicatoron 0 \
        -menu $criteria.entries.group1.avatar.om.menu -relief raised \
        -textvariable Searcher::storage($w,avatarMode) -width 3
    menu $criteria.entries.group1.avatar.om.menu -tearoff 0
    foreach avatarMode $yesNo {
        $criteria.entries.group1.avatar.om.menu add radiobutton \
            -value $avatarMode -label $avatarMode \
            -variable Searcher::storage($w,avatarMode)
    }
    grid $criteria.entries.group1.avatar.cb \
        $criteria.entries.group1.avatar.om -sticky ew
    grid columnconfigure $criteria.entries.group1.avatar 1 -weight 1

    frame $criteria.entries.group1.chase
    checkbutton $criteria.entries.group1.chase.cb \
	-text "[ML::str chase]:" \
        -padx 0 -variable Searcher::storage($w,chaseToggle)
    menubutton $criteria.entries.group1.chase.om -indicatoron 0 \
        -menu $criteria.entries.group1.chase.om.menu -relief raised \
        -textvariable Searcher::storage($w,chaseMode) -width 3
    menu $criteria.entries.group1.chase.om.menu -tearoff 0
    foreach chaseMode $yesNo {
        $criteria.entries.group1.chase.om.menu add radiobutton \
            -value $chaseMode -label $chaseMode \
            -variable Searcher::storage($w,chaseMode)
    }
    grid $criteria.entries.group1.chase.cb \
        $criteria.entries.group1.chase.om -sticky ew
    grid columnconfigure $criteria.entries.group1.chase 1 -weight 1

    frame $criteria.entries.group1.rarity
    checkbutton $criteria.entries.group1.rarity.l \
	-text "[ML::str rarity]:" \
        -padx 0 -variable Searcher::storage($w,rarityToggle)
    menubutton $criteria.entries.group1.rarity.mb -indicatoron 0 \
        -menu $criteria.entries.group1.rarity.mb.menu -relief raised \
        -textvariable Searcher::storage($w,searchRarity) -width 2
    menu $criteria.entries.group1.rarity.mb.menu -tearoff 0
    foreach freq $CrossFire::cardFreqIDList {
        $criteria.entries.group1.rarity.mb.menu add radiobutton \
            -value $freq -label $freq \
            -variable Searcher::storage($w,searchRarity)
    }
    grid $criteria.entries.group1.rarity.l \
        $criteria.entries.group1.rarity.mb -sticky ew
    grid columnconfigure $criteria.entries.group1.rarity 1 -weight 1

    grid $criteria.entries.group1.avatar -row 0 -column 0 -sticky ew
    grid $criteria.entries.group1.chase  -row 0 -column 1 -sticky ew -padx 3
    grid $criteria.entries.group1.rarity -row 0 -column 2 -sticky ew
    grid columnconfigure $criteria.entries.group1 {0 1 2} -weight 1

    grid $criteria.entries.title  -sticky ew -pady 2
    grid $criteria.entries.text   -sticky ew -pady 2
    grid $criteria.entries.level  -sticky ew -pady 2
    grid $criteria.entries.number -sticky ew -pady 2
    grid $criteria.entries.group1 -sticky ew -pady 2
    grid columnconfigure $criteria.entries 0 -weight 1
    grid rowconfigure $criteria.entries 0 -weight 1

    set wcs [CrossFire::ScrolledCheckBox $criteria.attr \
                 Searcher::storage($w,attrToggle) -height 6 \
                 -title "[ML::str attributes]:"]
    set storage($w,attrListBox) $wcs
    set attrList "$CrossFire::cardAttributes(list) $CrossFire::fanAttributes"
    foreach attribute [lsort $attrList] {
        $wcs insert end $attribute
    }
    checkbutton $criteria.attr.mode -text [ML::str ss,matchAll] \
	-onvalue "AND" -offvalue "OR" \
	-variable Searcher::storage($w,attrMode)
    grid $criteria.attr.mode -sticky w

    set wcs [CrossFire::ScrolledCheckBox $criteria.type \
                 Searcher::storage($w,typeToggle) -height 6 \
                 -title "[ML::str cardTypes]:"]
    set storage($w,typeListBox) $wcs
    foreach cardTypeID $CrossFire::cardTypeIDList {
        if {$cardTypeID > 0 && $cardTypeID <= 99} {
            $wcs insert end $CrossFire::cardTypeXRef($cardTypeID,name)
            lappend storage($w,searchTypeXRef) " $cardTypeID "
        }
    }

    set wcs [CrossFire::ScrolledCheckBox $criteria.world \
                 Searcher::storage($w,worldToggle) \
                 -title "[ML::str ss,cardWorlds]:" -height 6]
    set storage($w,worldListBox) $wcs
    set worldList {}
    foreach worldID $CrossFire::worldIDList {
	lappend worldList $CrossFire::worldXRef($worldID,name)
    }
    foreach worldName [lsort $worldList] {
        $wcs insert end $worldName
        lappend storage($w,searchWorldXRef) \
            $CrossFire::worldXRef($worldName)
    }

    frame $criteria.uses
    checkbutton $criteria.uses.cb -text "[ML::str usableCards]:" \
        -variable Searcher::storage($w,usesToggle) -padx 0
    checkbutton $criteria.uses.mode -onvalue "AND" -offvalue "OR" \
        -variable Searcher::storage($w,usesMode) \
	-text [ML::str ss,matchAll]
    frame $criteria.uses.list
    listbox $criteria.uses.list.lb -exportselection 0 \
        -yscrollcommand "CrossFire::SetScrollBar $criteria.uses.list.sb" \
        -selectmode multiple -height 4
    scrollbar $criteria.uses.list.sb \
        -command "$criteria.uses.list.lb yview"
    set storage($w,usesListBox) $criteria.uses.list.lb
    grid $criteria.uses.list.lb -sticky nsew
    grid rowconfigure $criteria.uses.list 0 -weight 1
    grid columnconfigure $criteria.uses.list 0 -weight 1

    grid $criteria.uses.cb   -row 0 -column 0 -sticky w
    grid $criteria.uses.mode -row 0 -column 1 -sticky e
    grid $criteria.uses.list -sticky nsew -columnspan 2
    grid rowconfigure $criteria.uses 1 -weight 1
    grid columnconfigure $criteria.uses {0 1} -weight 1

    foreach usable [lsort $CrossFire::usableCards(list)] {
        $storage($w,usesListBox) insert end $usable
    }

    # Command buttons
    frame $criteria.buttons
    button $criteria.buttons.clear -text [ML::str clear] -width 8 \
        -command "Searcher::ClearUltraSearch $w"
    button $criteria.buttons.search -text [ML::str search] -width 8 \
        -command "Searcher::DoUltraSearch $w"
    bind $w <Key-Return> "$criteria.buttons.search invoke"

    grid $criteria.buttons.clear $criteria.buttons.search \
        -pady 5 -padx 10

    grid $criteria.entries -columnspan 3 -padx 5 -sticky ew
    grid $criteria.attr    -row 1 -column 0 -pady 3 -padx 5 -sticky nsew
    grid $criteria.type    -row 1 -column 1 -pady 3 -sticky nsew
    grid $criteria.world   -row 1 -column 2 -pady 3 -padx 5 -sticky nsew
    grid $criteria.uses    -columnspan 3 -pady 3 -padx 5 -sticky nsew
    grid $criteria.buttons -columnspan 3 -sticky ew
    grid rowconfigure $criteria {1 2} -weight 1
    grid columnconfigure $criteria {0 1 2} -weight 1

    grid $criteria -sticky nsew -padx 1 -pady 1
    grid columnconfigure $criteriaPane 0 -weight 1
    grid rowconfigure $criteriaPane 0 -weight 1

    # Results list box and bindings.
    set resultsPane [PanedWindow::Pane $pw 3]
    set results [frame $resultsPane.results]

    set lbw [CrossFire::ScrolledListBox $results.r \
                 -titlevar Searcher::storage($w,srLabel)]
    grid $results.r -sticky nsew -padx 5 -pady 5
    grid columnconfigure $results 0 -weight 1
    grid rowconfigure $results 0 -weight 1

    set storage($w,resultsListBox) $lbw
    CrossFire::InitListBox $w $lbw Searcher
    bind $lbw <ButtonRelease-1> "CrossFire::CancelDrag $lbw"
    bind $lbw <Double-Button-1> "Searcher::ClickListBox $w %X %Y 2"
    bindtags $lbw "$lbw all"

    grid $results -sticky nsew -padx 1 -pady 1
    grid columnconfigure $resultsPane 0 -weight 1
    grid rowconfigure $resultsPane 0 -weight 1

    # Optional embedded card viewer
    if {$numPanes == 4} {
        set cardViewPane [PanedWindow::Pane $pw 4]
        set cardView [frame $cardViewPane.cardView]

	set storage($w,cardFrame) [ViewCard::CreateCardView $cardView.cv]
	grid $cardView.cv -sticky nsew -padx 5 -pady 5
	grid rowconfigure $cardView 0 -weight 1
	grid columnconfigure $cardView 0 -weight 1

        grid $cardView -sticky nsew -padx 1 -pady 1
        grid columnconfigure $cardViewPane 0 -weight 1
        grid rowconfigure $cardViewPane 0 -weight 1
    }

#     # Command buttons
#     frame $w.buttons
#     button $w.buttons.clear -text [ML::str clear] -width 8 \
#         -command "Searcher::ClearUltraSearch $w"
#     button $w.buttons.search -text [ML::str search] -width 8 \
#         -command "Searcher::DoUltraSearch $w"
#     bind $w <Key-Return> "$w.buttons.search invoke"
#     button $w.buttons.dismiss -text [ML::str close] -width 8 \
#         -command "Searcher::ExitSearcher $w"

#     grid $w.buttons.clear $w.buttons.search $w.buttons.dismiss \
#         -pady 5 -padx 10

    grid $w.f -sticky nsew
    #grid $w.buttons -columnspan $numPanes -sticky ew
    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 1

    update
    ClearUltraSearch $w

    if {$CrossFire::platform == "windows"} {
        focus $w
    }

    return
}

# Searcher::AddMenuBar --
#
#   Creates the menubar for the searcher and sets up the
#   accelerator key bindings for the commands.
#
# Parameters:
#   w          : Toplevel of the new searcher window.
#
# Returns:
#   Nothing.
#
proc Searcher::AddMenuBar {w} {

    menu $w.menubar

    $w.menubar add cascade \
        -label [ML::str search] \
        -underline 0 \
        -menu $w.menubar.search

    menu $w.menubar.search -tearoff 0
    $w.menubar.search add command \
		    -label [ML::str clear] \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+C" \
        -command "Searcher::ClearUltraSearch $w"
    $w.menubar.search add command \
	-label [ML::str search] \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+S" \
        -command "Searcher::DoUltraSearch $w"

    $w.menubar.search add separator
    $w.menubar.search add command \
        -label "[ML::str configure]..." \
        -underline 1 \
        -accelerator "$CrossFire::accelKey+O" \
        -command "Config::Create Ultra Searcher"

    $w.menubar.search add separator
    set exitLabel [ML::str close]
    set exitAccelerator "Alt+F4"
    if {$CrossFire::platform == "macintosh"} {
        # This is a Macintosh, so make the exit
        # accelerator more "Mac-ish"
        set exitLabel [ML::str quit]
        set exitAccelerator "Command+Q"
    }
    $w.menubar.search add command \
        -label $exitLabel \
        -underline 1 \
        -accelerator $exitAccelerator \
        -command "Searcher::ExitSearcher $w"

    $w.menubar add cascade \
	-label [ML::str cardSets] \
	-underline 0 \
	-menu $w.menubar.sets

    menu $w.menubar.sets -tearoff 0
    $w.menubar.sets add command \
	-label [ML::str ss,clearAll] \
	-command "Searcher::UpdateSetList $w clear"
    $w.menubar.sets add command \
	-label [ML::str ss,selectAll] \
	-command "Searcher::UpdateSetList $w select"
    $w.menubar.sets add separator
    $w.menubar.sets add command \
	-label [ML::str default] \
	-command "Searcher::UpdateSetList $w init"

    $w.menubar add cascade \
        -label [ML::str help] \
        -underline 0 \
        -menu $w.menubar.help

    menu $w.menubar.help -tearoff 0
    $w.menubar.help add command \
        -label "[ML::str help]..." \
        -underline 0 \
        -accelerator "F1" \
        -command "CrossFire::Help se_main.html"
    $w.menubar.help add separator
    $w.menubar.help add command \
        -label "[ML::str ss,about]..." \
        -underline 0 \
        -command "Searcher::About $w"

    $w config -menu $w.menubar

    # Search menu bindings.
    bind $w <$CrossFire::accelBind-c> "Searcher::ClearUltraSearch $w"
    bind $w <$CrossFire::accelBind-s> "Searcher::DoUltraSearch $w"
    bind $w <$CrossFire::accelBind-o> "Config::Create Ultra Searcher"

    if {$CrossFire::platform == "macintosh"} {
        bind $w <Command-q> "Searcher::ExitSearcher $w"
    } else {
        bind $w <Meta-x> "Searcher::ExitSearcher $w"
        bind $w <Alt-F4> "Searcher::ExitSearcher $w; break"
    }

    # Help menu bindings.
    bind $w <Key-F1> "CrossFire::Help se_main.html"
    bind $w <Key-Help> "CrossFire::Help se_main.html"

    # menu for right click on card list
    menu $w.viewMenu -tearoff 0
    $w.viewMenu add command -label " [ML::str view]" \
        -command "ViewCard::View $w \[Searcher::GetSelectedCardID $w\]"
    $w.viewMenu add separator
    $w.viewMenu add command -label " [ML::str remove]" \
        -command "Searcher::RemoveCard $w"

    return
}

# Searcher::RemoveCard --
#
#   Removes a card from the list of results.
#
# Parameters:
#   w          : Searcher top level.
#
# Returns:
#   Nothing.
#
proc Searcher::RemoveCard {w} {

    variable storage

    set lbw $storage($w,resultsListBox)
    set index [$lbw curselection]
    if {$index != ""} {
        $lbw delete $index
    }
    set storage($w,srLabel) "[ML::str ss,searchResults] ([$lbw size]):"

    return
}

# Searcher::UpdateSetList --
#
#   Updates the list of sets to search.
#
# Parameters:
#   w          : Searcher top level.
#   mode       : Update mode (update, clear, select, init)
#
# Returns:
#   Nothing.
#
proc Searcher::UpdateSetList {w mode} {

    variable storage

    set lbw $storage($w,sllb)

    switch $mode {
        "update" {}
        "clear" {
            $lbw selection clear 0 end
        }
        "select" {
            $lbw selection set 0 end
        }
        "init" {
            $lbw delete 0 end
            set def $Config::config(Searcher,setIDList)
            foreach setID [CrossFire::CardSetIDList "allPlain"] {
                $storage($w,sllb) insert end \
                    $CrossFire::setXRef($setID,name)
                if {[lsearch $def $setID] != -1} {
                    $storage($w,sllb) selection set end
                }
            }
        }
    }

    set storage($w,setIDList) {}
    foreach lbIndex [$lbw curselection] {
        set setName [$lbw get $lbIndex]
        lappend storage($w,setIDList) $CrossFire::setXRef($setName)
    }

    return
}

# Searcher::About --
#
#   Displays an about dialog for the ultra searcher
#
# Parameters:
#   w         : Parent toplevel for the pop-up dialog.
#
# Returns:
#   Nothing.
#
proc Searcher::About {w} {
    set message "CrossFire [ML::str ss,windowName]\n"
    append message "\n[ML::str by] Dan Curtiss"
    tk_messageBox -icon info -title [ML::str ss,about] \
        -parent $w -message $message
    return
}

# Searcher::ExitSearcher --
#
# Parameters:
#   w         : Toplevel of the searcher.
#
# Returns:
#   Nothing.
#
proc Searcher::ExitSearcher {w} {

    variable storage

    set np $storage($w,numPanes)

    # Save window size and pane positions
    set pw $storage($w,paneFrame)
    foreach {gw gh gx gy} [split [winfo geometry $pw] "x+-"] break
    Config::Set "Searcher,geometry,$np" "$gw $gh"

    # Build list of sash locations (pane widths)
    for {set i 1} {$i <= $np} {incr i} {
        append sashLoc "[PanedWindow::Position $pw $i] "
    }
    Config::Set "Searcher,sashLoc,$np" $sashLoc

    ViewCard::CleanUpCardViews $w
    destroy $w

    return
}

# Searcher::ClearUltraSearch --
#
#   Clears all the checkboxes, listboxes, and entries on a UltraSearch window.
#
# Parameters:
#   w          : Searcher toplevel.
#
# Returns:
#   Nothing.
#
proc Searcher::ClearUltraSearch {w} {

    variable storage

    set storage($w,attrToggle) 0
    set storage($w,attrMode) "OR"
    $storage($w,attrListBox) selection clear 0 end

    set storage($w,typeToggle) 0
    $storage($w,typeListBox) selection clear 0 end

    set storage($w,worldToggle) 0
    $storage($w,worldListBox) selection clear 0 end

    set storage($w,usesToggle) 0
    set storage($w,usesMode) "OR"
    $storage($w,usesListBox) selection clear 0 end

    set storage($w,titleToggle) 0
    set storage($w,searchTitle) ""

    set storage($w,textToggle) 0
    set storage($w,searchText) ""
    set storage($w,searchMode) $Config::config(Searcher,searchMode)

    set storage($w,levelToggle) 0
    set storage($w,searchLevels) ""

    set storage($w,numberToggle) 0
    set storage($w,searchNumber) ""

    set storage($w,rarityToggle) 0
    set storage($w,searchRarity) "C"

    set storage($w,chaseToggle) 0
    set storage($w,chaseMode) [ML::str yes]

    set storage($w,avatarToggle) 0
    set storage($w,avatarMode) [ML::str yes]

    set storage($w,srLabel) "[ML::str ss,searchResults]:"
    $storage($w,resultsListBox) delete 0 end

    return
}

# Searcher::ParseSEText --
#
#   Converts a search engine string (+this -that) to a list of items
#   that must match and must not match.
#
#   Input  => +this "and ME!!" -that +"the other" +andthis -"not this"
#   Output => {this {and ME!!} {the other} andthis} {that {not this}}
#
# Parameters:
#   a          : String to convert
#
# Returns:
#   {include list} {exclude list}
#
proc Searcher::ParseSEText {a} {

    set include ""
    set exclude ""

    # put the +/- inside the quotes.  ie: +"include me" => "+include me"
    regsub -all "(\[+-\])\"" $a "\"\\1" elemList

    foreach elem $elemList {
        set first [string index $elem 0]
        if {$first == "-"} {
            set elem [string range $elem 1 end]
            lappend exclude $elem
        } elseif {$first == "+"} {
            set elem [string range $elem 1 end]
            lappend include $elem
        } else {
            lappend include $elem
        }
    }

    return [list $include $exclude]
}

proc Searcher::FixRangeData {data {low -5} {high 30}} {

    # Attempt to correct for incorrect input format
    regsub -all {[^-0-9\, <>\?]} $data " " data
    regsub -all " *- *" $data "-" data
    regsub -all "," $data " " data
    regsub -all "(<|>) " $data "\\1" data
    regsub -all {([0-9])(<|>)}  $data "\\1 \\2" data

    set outNumbers ""
    foreach number $data {
        if {[regexp "<" $number] == 1} {
            regsub "<" $number "" max
            while {$max > $low} {
                incr max -1
                append outNumbers " $max"
            }
        } elseif {[regexp ">" $number] == 1} {
            regsub ">" $number "" min
            for {set i [expr $min + 1]} {$i <= $high} {incr i} {
                append outNumbers " $i"
            }
        } elseif {[regexp -- {[0-9]-[0-9]} $number] == 1} {
            foreach {min max} [split $number "-"] {break}
            # This method performs math on both the min and max numbers
            # to assure that they are numbers.  An error will occur if
            # extraneous bad input exists.
            while {$max > [expr $min - 1]} {
                append outNumbers " $max"
                incr max -1
            }
        } else {
            append outNumbers " $number"
        }
    }

    return $outNumbers
}

# Searcher::DoUltraSearch --
#
#   Searches all the cards for matches to the Ultra Search requirements.
#
# Parameters:
#   w          : Searcher toplevel.
#
# Returns:
#   Nothing.
#
proc Searcher::DoUltraSearch {w} {

    variable storage

    set sID [UltraSearch::New]

    # Card Title
    UltraSearch::Set $sID titleToggle $storage($w,titleToggle)
    UltraSearch::Set $sID searchTitle $storage($w,searchTitle)

    # Card text
    if {$storage($w,textToggle) == 1} {
        if {$storage($w,searchMode) == "+/-"} {
            set searchText [ParseSEText $storage($w,searchText)]
        } else {
            set searchText $storage($w,searchText)
            if {[catch {regexp -- $searchText ""}]} {
                tk_messageBox -message [ML::str ss,seMessage] \
		    -title [ML::str searchError] -icon question
                return
            }
        }
        UltraSearch::Set $sID textToggle $storage($w,textToggle)
        UltraSearch::Set $sID searchText $searchText
        UltraSearch::Set $sID textMode $storage($w,searchMode)
    }

    # Levels
    if {$storage($w,levelToggle) == 1} {
        UltraSearch::Set $sID levelToggle $storage($w,levelToggle)
        UltraSearch::Set $sID searchLevels \
            [FixRangeData $storage($w,searchLevels)]
    }

    # Last digit
    if {$storage($w,numberToggle) == 1} {
        UltraSearch::Set $sID numberToggle $storage($w,numberToggle)
        UltraSearch::Set $sID searchNumber \
            [FixRangeData $storage($w,searchNumber) 0 9]
    }

    # Attribute list
    if {$storage($w,attrToggle) == 1} {
        set attrList {}
        foreach i [$storage($w,attrListBox) curselection] {
            set attr [$storage($w,attrListBox) get $i]
            lappend attrList $CrossFire::cardAttributes(ID,$attr)
        }
        UltraSearch::Set $sID attrToggle $storage($w,attrToggle)
        UltraSearch::Set $sID attrList $attrList
        UltraSearch::Set $sID attrMode $storage($w,attrMode)
    }

    # Card types
    if {$storage($w,typeToggle) == 1} {
        set searchTypes ""
        foreach i [$storage($w,typeListBox) curselection] {
            set typeNum [lindex $storage($w,searchTypeXRef) $i]
            if {$typeNum == 99} {
                append searchTypes $CrossFire::championList
            } else {
                append searchTypes " $typeNum"
            }
        }
        UltraSearch::Set $sID typeToggle $storage($w,typeToggle)
        UltraSearch::Set $sID typeList $searchTypes
    }

    # Worlds
    if {$storage($w,worldToggle) == 1} {
        set searchWorlds ""
        foreach i [$storage($w,worldListBox) curselection] {
            append searchWorlds \
                " [lindex $storage($w,searchWorldXRef) $i] "
        }
        UltraSearch::Set $sID worldToggle $storage($w,worldToggle)
        UltraSearch::Set $sID worldList $searchWorlds
    }

    # Usable cards
    if {$storage($w,usesToggle) == 1} {
        set usesList {}
        foreach i [$storage($w,usesListBox) curselection] {
            set uses [$storage($w,usesListBox) get $i]
            lappend usesList $CrossFire::usableCards(ID,$uses)
        }
        UltraSearch::Set $sID usesToggle $storage($w,usesToggle)
        UltraSearch::Set $sID usesList $usesList
        UltraSearch::Set $sID usesMode $storage($w,usesMode)
    }

    # Chase
    UltraSearch::Set $sID chaseToggle $storage($w,chaseToggle)
    UltraSearch::Set $sID chaseMode $storage($w,chaseMode)

    # Avatars
    UltraSearch::Set $sID avatarToggle $storage($w,avatarToggle)
    UltraSearch::Set $sID avatarMode $storage($w,avatarMode)

    # Rarity
    UltraSearch::Set $sID rarityToggle $storage($w,rarityToggle)
    UltraSearch::Set $sID searchRarity $storage($w,searchRarity)

    # Card sets
    UltraSearch::Set $sID setIDList $storage($w,setIDList)

    $w config -cursor watch
    update

    $storage($w,resultsListBox) delete 0 end

    foreach cardID [UltraSearch::Search $sID] {
        $storage($w,resultsListBox) insert end \
            [CrossFire::GetCardDesc [CrossFire::GetCard $cardID]]
    }

    set storage($w,srLabel) \
        "[ML::str ss,searchResults] ([$storage($w,resultsListBox) size]):"

    $w config -cursor {}
    UltraSearch::Delete $sID

    return
}

# Searcher::ClickListBox --
#
#   Handles all clicking of the card selection list box.
#
# Parameters:
#   w          : Search toplevel widget name.
#   X Y        : X and Y coordinates of the click (%X %Y)
#              : -or- m line for move to line.
#   btnNumber  : Button number pressed
#
# Returns:
#   Nothing.
#
proc Searcher::ClickListBox {w X Y btnNumber} {

    variable storage

    set lbw $storage($w,resultsListBox)

    CrossFire::ClickListBox $w $lbw $X $Y

    if {[$lbw size] == 0} {
        return
    }

    set tempID [GetSelectedCardID $w]
    if {$storage($w,embedCardView) == "Yes"} {
	ViewCard::UpdateCardView $storage($w,cardFrame) \
	    [CrossFire::GetCard $tempID]
    } elseif {($Config::config(ViewCard,mode) == "Continuous") &&
        ([$lbw size] != 0)} {
        ViewCard::View $w $tempID
    }

    # Do various activities depending which button was pressed.
    switch -- $btnNumber {
        1 {
            # Start the drag-n-drop routines.
            CrossFire::StartDrag $lbw plus AddCard $tempID
        }

        2 {
            ViewCard::View $w $tempID
        }

        3 {
            tk_popup $w.viewMenu $X $Y
        }
    }

    return
}

# Searcher::GetSelectedCardID --
#
#   Returns the short ID of the selected card.
#
# Parameters:
#   w          : Searcher toplevel widget name.
#
# Returns:
#   The short ID if a card is selected, nothing otherwise.
#
proc Searcher::GetSelectedCardID {w} {

    variable storage

    set lbw $storage($w,resultsListBox)
    if {[$lbw size] != 0} {
        set id [lindex [$lbw get [$lbw curselection]] 0]
    } else {
        set id ""
    }

    return $id
}

