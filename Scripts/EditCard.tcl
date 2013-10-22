# EditCard.tcl 20051019
#
# This file contains the procedures for editing cards.
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

# To Do:
#   Add changing of Set Name (may be difficult)
#   Add changing of world definition

namespace eval EditCard {

    # paramList is a cross ref from global index to card lindex.
    variable paramList {
        number    1
        bonus     2
        type      3
        world     4
        isAvatar  5
        title     6
        cardText  7
        rarity    8
        blueLine  9
        attrList 10
        usesList 11
        weight   12
    }

}

# EditCard::SetChanged --
#
#   Changes the boolean flag for if a card has changed.
#   Adjusts the title of the editor; adds a '*' indicating
#   that a change has been made.
#
# Parameters:
#   bool       : Boolean (true or false). Need to save?
#   args       : Extra things that are appended by a variable trace.
#
# Returns:
#   Nothing.
#
proc EditCard::SetChanged {bool args} {

    variable fseConfig
    variable windowTitle

    set fseConfig(change) $bool
    set title "$windowTitle - $fseConfig(title) "

    if {$bool == "true"} {
        wm title $fseConfig(topw) "${title}*"
    } else {
        wm title $fseConfig(topw) $title
    }

    return
}

# EditCard::Create --
#
#   Creates the fan card editor.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc EditCard::Create {} {

    variable fseConfig
    variable windowTitle "Card Editor"

    if {([llength [CrossFire::CardSetIDList fan]] == 0) &&
        ($::developer == 0)} {
        tk_messageBox -icon error -title "CrossFire Error" \
            -message "You do not have any fan sets installed."
        return
    }

    set w .editcard
    set fseConfig(topw) $w
    CrossFire::Register CardEditor $w

    if {[winfo exists $w]} {
        wm deiconify $w
        raise $w
        return
    }

    toplevel $w
    wm title $w $windowTitle
    wm protocol $w WM_DELETE_WINDOW "EditCard::ExitEditCard"

    set fseConfig(embedCardView) $Config::config(FanSetEditor,embedCardView)

    AddMenuBar $w

    frame $w.info -relief raised -borderwidth 1
    label $w.info.lan -text "Author:" -width 7 -anchor e
    entry $w.info.authorName -textvariable EditCard::fseConfig(authorName)
    bind $w.info.authorName <Return> "EditCard::UpdateInformation"
    label $w.info.lae -text "Email:" -width 7 -anchor e
    entry $w.info.authorEmail -textvariable EditCard::fseConfig(authorEmail)
    bind $w.info.authorEmail <Return> "EditCard::UpdateInformation"
    grid $w.info.lan $w.info.authorName -sticky ew -padx 5 -pady 5
    grid $w.info.lae $w.info.authorEmail -sticky ew -padx 5 -pady 5
    grid columnconfigure $w.info 1 -weight 1

    frame $w.select -relief raised -borderwidth 1
    frame $w.select.set
    label $w.select.set.l -text "Card Set:"
    menubutton $w.select.set.mb -menu $w.select.set.mb.menu \
        -indicatoron 1 -textvariable EditCard::fseConfig(cardSetName) \
        -relief raised
    menu $w.select.set.mb.menu -tearoff 0 -title "Card Set"
    set fseConfig(setNameMenu) $w.select.set.mb.menu
    if {$::developer == 1} {
        set setList [CrossFire::CardSetIDList allPlain]
    } else {
        set setList [CrossFire::CardSetIDList fan]
    }
    foreach setID $setList {
        $w.select.set.mb.menu add radiobutton \
            -label $CrossFire::setXRef($setID,name) \
            -variable EditCard::fseConfig(tempSetID) -value $setID \
            -command "EditCard::ChangeCardSet $setID"
    }

    grid $w.select.set.l $w.select.set.mb -sticky ew -pady 3
    grid columnconfigure $w.select.set 1 -weight 1

    frame $w.select.card
    listbox $w.select.card.lb -selectmode single \
        -exportselection 0 -background white -foreground black \
        -selectbackground blue -selectforeground white \
        -selectborderwidth 0 -height 15 \
        -yscrollcommand "CrossFire::SetScrollBar $w.select.card.sb"
    set fseConfig(lbw) $w.select.card.lb
    scrollbar $w.select.card.sb -command "$w.select.card.lb yview"
    grid $w.select.card.lb $w.select.card.sb -sticky nsew
    grid columnconfigure $w.select.card 0 -weight 1
    grid rowconfigure $w.select.card 0 -weight 1

    foreach buttonNum "1 2 3" {
        bind $fseConfig(lbw) <ButtonPress-$buttonNum> \
            "EditCard::ClickListBox %X %Y $buttonNum"
    }
    bindtags $fseConfig(lbw) "$fseConfig(lbw) all"

    grid $w.select.set -sticky ew -padx 5 -pady 3
    grid $w.select.card -sticky nsew -padx 5 -pady 5
    grid columnconfigure $w.select 0 -weight 1
    grid rowconfigure $w.select 1 -weight 1

    frame $w.edit -relief raised -borderwidth 1

    label $w.edit.lnumber -text "Card:" -anchor e
    frame $w.edit.ftitle
    label $w.edit.ftitle.number -width 4 \
        -textvariable EditCard::fseConfig(number)
    entry $w.edit.ftitle.title -textvariable EditCard::fseConfig(title)
    grid $w.edit.ftitle.number -row 0 -column 0
    grid $w.edit.ftitle.title  -row 0 -column 1 -sticky ew
    grid columnconfigure $w.edit.ftitle 1 -weight 1
    grid $w.edit.lnumber -row 0 -column 0 -sticky e  -pady 3
    grid $w.edit.ftitle  -row 0 -column 1 -sticky ew -pady 3 -padx 5

    label $w.edit.lbonus -text "Level:" -anchor e
    entry $w.edit.ebonus -textvariable EditCard::fseConfig(bonus)
    grid $w.edit.lbonus -row 1 -column 0 -sticky e  -pady 3
    grid $w.edit.ebonus -row 1 -column 1 -sticky ew -pady 3 -padx 5

    label $w.edit.ltype -text "Type:" -anchor e
    frame $w.edit.type
    menubutton $w.edit.type.mbtype -menu $w.edit.type.mbtype.menu \
        -indicator 1 -textvariable EditCard::fseConfig(typeName) \
        -relief raised
    menu $w.edit.type.mbtype.menu -tearoff 0
    foreach typeID $CrossFire::cardTypeIDList {
        if {($typeID > 0) && ($typeID < 99)} {
            $w.edit.type.mbtype.menu add radiobutton \
                -label $CrossFire::cardTypeXRef($typeID,name) \
                -variable EditCard::fseConfig(typeName)
        }
    }
    checkbutton $w.edit.type.isAvatar -text "Avatar" \
        -onvalue 1 -offvalue 0 \
        -variable EditCard::fseConfig(isAvatar)
    grid $w.edit.type.mbtype -sticky ew
    grid $w.edit.type.isAvatar -row 0 -column 1 -sticky e
    grid columnconfigure $w.edit.type 0 -weight 1

    grid $w.edit.ltype -row 2 -column 0 -sticky e  -pady 3
    grid $w.edit.type  -row 2 -column 1 -sticky ew -pady 3 -padx 5

    set worldList {}
    label $w.edit.lworld -text "World:" -anchor e
    foreach worldID $CrossFire::worldIDList {
        lappend worldList $CrossFire::worldXRef($worldID,name)
    }
    menubutton $w.edit.oworld -indicatoron 1 \
        -menu $w.edit.oworld.menu -relief raised \
        -textvariable EditCard::fseConfig(worldName)
    menu $w.edit.oworld.menu -tearoff 0
    set fseConfig(worldNameMenu) $w.edit.oworld.menu
    foreach worldID $worldList {
        $w.edit.oworld.menu add radiobutton \
            -label $worldID -value $worldID \
            -variable EditCard::fseConfig(worldName)
    }
    grid $w.edit.lworld -row 3 -column 0 -sticky e  -pady 3
    grid $w.edit.oworld -row 3 -column 1 -sticky ew -pady 3 -padx 5

    label $w.edit.lfreq -text "Rarity:" -anchor e
    frame $w.edit.rarity
    menubutton $w.edit.rarity.ofreq -indicatoron 1 \
        -menu $w.edit.rarity.ofreq.menu -relief raised \
        -textvariable EditCard::fseConfig(rarity)
    menu $w.edit.rarity.ofreq.menu -tearoff 0
    foreach freq $CrossFire::cardFreqIDList {
        $w.edit.rarity.ofreq.menu add radiobutton \
            -label $freq -value $freq \
            -variable EditCard::fseConfig(rarity)
    }
    set fseConfig(rom) $w.edit.rarity.ofreq
    grid $w.edit.rarity.ofreq   -sticky ew -row 0 -column 0
    grid columnconfigure $w.edit.rarity 0 -weight 1

    grid $w.edit.lfreq  -row 4 -column 0 -sticky e  -pady 3
    grid $w.edit.rarity -row 4 -column 1 -sticky ew -pady 3 -padx 5

    label $w.edit.lcardText -text "Card Text:" -anchor e
    frame $w.edit.ecardText

    set fseConfig(tw) $w.edit.ecardText.t
    text $fseConfig(tw) -height 5 -width 40 -wrap word \
        -wrap word -background white -foreground black \
        -yscrollcommand "CrossFire::SetScrollBar $w.edit.ecardText.sb"
    scrollbar $w.edit.ecardText.sb -command "$fseConfig(tw) yview"
    bind $fseConfig(tw) <KeyPress> "EditCard::CheckTextChange %A"
    bindtags $fseConfig(tw) "$fseConfig(tw) Text all"

    grid $fseConfig(tw) -sticky nsew
    grid columnconfigure $w.edit.ecardText 0 -weight 1
    grid rowconfigure $w.edit.ecardText 0 -weight 1
    grid $w.edit.lcardText -row 5 -column 0 -sticky ne   -pady 3
    grid $w.edit.ecardText -row 5 -column 1 -sticky nsew -pady 3 -padx 5

    label $w.edit.lblueLine -text "Blueline:" -anchor e
    entry $w.edit.eblueLine -textvariable EditCard::fseConfig(blueLine)
    grid $w.edit.lblueLine -row 6 -column 0 -sticky ne  -pady 3
    grid $w.edit.eblueLine -row 6 -column 1 -sticky new -pady 3 -padx 5

    # Card attributes list
    label $w.edit.lattr -text "Attributes:" -anchor e
    frame $w.edit.attrf
    frame $w.edit.attrf.sel
    listbox $w.edit.attrf.sel.lb -selectmode multiple -width 0 -height 4 \
        -exportselection 0 -yscrollcommand "$w.edit.attrf.sel.sb set"
    scrollbar $w.edit.attrf.sel.sb -command "$w.edit.attrf.sel.lb yview"
    set fseConfig(attrlb) $w.edit.attrf.sel.lb
    bind $w.edit.attrf.sel.lb <ButtonRelease-1> \
        "+EditCard::ChangeAttributeList"
    grid $w.edit.attrf.sel.lb $w.edit.attrf.sel.sb -sticky nsew
    grid columnconfigure $w.edit.attrf.sel 0 -weight 1
    grid rowconfigure $w.edit.attrf.sel 0 -weight 1
    grid $w.edit.attrf.sel -sticky nsew
    grid $w.edit.lattr -row 7 -column 0 -sticky ne   -pady 3
    grid $w.edit.attrf -row 7 -column 1 -sticky nsew -pady 3 -padx 5
    grid columnconfigure $w.edit.attrf 0 -weight 1
    grid rowconfigure $w.edit.attrf 0 -weight 1

    # Usable card type list
    label $w.edit.lusable -text " Usable Cards:" -anchor w
    frame $w.edit.usable
    frame $w.edit.usable.sel
    listbox $w.edit.usable.sel.lb -selectmode multiple -width 20 -height 4 \
        -exportselection 0 -yscrollcommand "$w.edit.usable.sel.sb set"
    scrollbar $w.edit.usable.sel.sb -command "$w.edit.usable.sel.lb yview"
    set fseConfig(useslb) $w.edit.usable.sel.lb
    bind $w.edit.usable.sel.lb <ButtonRelease-1> \
        "+EditCard::ChangeUsesList"
    grid $w.edit.usable.sel.lb $w.edit.usable.sel.sb -sticky nsew
    grid columnconfigure $w.edit.usable.sel 0 -weight 1
    grid rowconfigure $w.edit.usable.sel 0 -weight 1
    grid $w.edit.usable.sel -sticky nsew
    grid $w.edit.lusable -row 8 -column 0 -sticky ne   -pady 3
    grid $w.edit.usable  -row 8 -column 1 -sticky nsew -pady 3 -padx 5
    grid columnconfigure $w.edit.usable 0 -weight 1
    grid rowconfigure $w.edit.usable 0 -weight 1

    grid columnconfigure $w.edit 1  -weight 1
    grid rowconfigure $w.edit 5     -weight 1
    grid rowconfigure $w.edit {7 8} -weight 2

    grid $w.info   -row 0 -column 0 -sticky nsew
    grid $w.select -row 1 -column 0 -sticky nsew
    grid $w.edit   -row 0 -column 1 -rowspan 2 -sticky nsew

    # Optional embedded card viewer
    if {$fseConfig(embedCardView) == "Yes"} {
	frame $w.cardView -relief raised -borderwidth 1
	set fseConfig(cardFrame) [ViewCard::CreateCardView $w.cardView.cv]
	grid $w.cardView.cv -sticky nsew -padx 5 -pady 5
	grid rowconfigure $w.cardView 0 -weight 1
	grid columnconfigure $w.cardView 0 -weight 1
	grid $w.cardView -column 2 -row 0 -sticky nsew -rowspan 2
	grid columnconfigure $w 2 -weight 1
    }

    grid columnconfigure $w {0 1} -weight 1
    grid rowconfigure $w 1 -weight 1

    bind $w <Key-Down>  "EditCard::ClickListBox m +1  0"
    bind $w <Key-Up>    "EditCard::ClickListBox m -1  0"
    bind $w <Key-Next>  "EditCard::ClickListBox m +25 0"
    bind $w <Key-Prior> "EditCard::ClickListBox m -25 0"

    SetChanged "false"
    if {[lsearch [CrossFire::CardSetIDList fan] \
             $Config::config(FanSetEditor,setID)] != -1} {
        set fseConfig(setID) $Config::config(FanSetEditor,setID)
    } else {
        set fseConfig(setID) [lindex [CrossFire::CardSetIDList fan] 0]
    }
    set fseConfig(tempSetID) $fseConfig(setID)
    ChangeCardSet $fseConfig(setID)

    if {$CrossFire::platform == "windows"} {
        focus $w
    }

    return
}

proc EditCard::UpdateInformation {} {

    variable fseConfig

    WriteConfiguationFile
    focus $fseConfig(topw)

    return
}

# EditCard::AddMenuBar --
#
#   Creates the menubar for the card editor and sets up the
#   accelerator key bindings for the commands.
#
# Parameters:
#   w          : Toplevel of the new inventory window.
#
# Returns:
#   Nothing.
#
proc EditCard::AddMenuBar {w} {

    variable fseConfig

    menu $w.menubar

    $w.menubar add cascade \
        -label "File" \
        -underline 0 \
        -menu $w.menubar.file

    menu $w.menubar.file -tearoff 0
    $w.menubar.file add command \
	-label "New..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+N" \
	-command "EditCard::NewFanSet"
    $w.menubar.file add separator
    $w.menubar.file add command \
        -label "Custom Attributes..." \
        -underline 7 \
        -accelerator "$CrossFire::accelKey+A" \
        -command "EditCard::CustomAttributes"
    $w.menubar.file add command \
        -label "Number of Cards..." \
	-underline 10 \
        -command "EditCard::EditCardQty"
    $w.menubar.file add separator
    $w.menubar.file add command \
        -label "Configure..." \
        -underline 1 \
        -accelerator "$CrossFire::accelKey+O" \
        -command "Config::Create Fan Set Editor"

    $w.menubar.file add separator
    set exitLabel "Close"
    set exitAccelerator "Alt+F4"
    if {$CrossFire::platform == "macintosh"} {
        # This is a Macintosh, so make the exit
        # accelerator more "Mac-ish"
        set exitLabel "Quit"
        set exitAccelerator "Command+Q"
    }
    $w.menubar.file add command \
        -label $exitLabel \
        -underline 1 \
        -accelerator $exitAccelerator \
        -command "EditCard::ExitEditCard"

    $w.menubar add cascade \
        -label "Card" \
        -underline 0 \
        -menu $w.menubar.card

    menu $w.menubar.card -tearoff 0
    $w.menubar.card add command \
        -label "Save" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+S" \
        -command "EditCard::SaveCard"

    $w.menubar.card add checkbutton \
        -label "Auto Save" \
        -underline 0 \
        -variable Config::config(FanSetEditor,autoSave)

    $w.menubar.card add separator
    $w.menubar.card add command \
        -label "Move To..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+M" \
        -command "EditCard::Move"   

    $w.menubar.card add separator
    $w.menubar.card add command \
        -label "Clear" \
        -underline 1 \
        -accelerator "$CrossFire::accelKey+L" \
        -command "EditCard::Clear"  

    $w.menubar add cascade \
        -label "Help" \
        -underline 0 \
        -menu $w.menubar.help

    menu $w.menubar.help -tearoff 0
    $w.menubar.help add command \
        -label "Help..." \
        -underline 0 \
        -accelerator "F1" \
        -command "CrossFire::Help ce_main.html"
    $w.menubar.help add separator
    $w.menubar.help add command \
        -label "About Fan Set Editor..." \
        -underline 0 \
        -command "EditCard::About $w"

    if {$::developer} {
        $w.menubar add cascade \
            -label "Developer" \
            -underline 0 \
            -menu [menu $w.menubar.dev -tearoff 0]
        $w.menubar.dev add command \
            -label "Add Card Phase" \
            -command "EditCard::AddCardPhase"
        $w.menubar.dev add command \
            -label "Validate Card Set" \
            -command "EditCard::Validate"
    }

    $w config -menu $w.menubar

    # Card menu bindings
    bind $w <$CrossFire::accelBind-m> "EditCard::Move"
    bind $w <$CrossFire::accelBind-l> "EditCard::Clear"
    bind $w <$CrossFire::accelBind-s> "EditCard::SaveCard"

    if {$CrossFire::platform == "macintosh"} {
        bind $w <Command-q> "EditCard::ExitEditCard"
    } else {
        bind $w <Meta-x> "EditCard::ExitEditCard"
        bind $w <Alt-F4> "EditCard::ExitEditCard; break"
    }

    # File menu bindings
    bind $w <$CrossFire::accelBind-n> "EditCard::NewFanSet"
    bind $w <$CrossFire::accelBind-a> "EditCard::CustomAttributes"
    bind $w <$CrossFire::accelBind-o> "Config::Create Fan Set Editor"

    # Help menu bindings
    bind $w <Key-F1> "CrossFire::Help ce_main.html"
    bind $w <Key-Help> "CrossFire::Help ce_main.html"

    # menu for right click on card in listbox
    menu $w.popupMenu -tearoff 0
    $w.popupMenu add command -label " View" \
        -command "EditCard::View"
    set fseConfig(popUp) $w.popupMenu

    return
}

# EditCard::Trace --
#
#   Turns on or off the trace of the card variables.
#
# Parameters:
#   mode       : On or Off.
#
# Returns:
#   Nothing.
#
proc EditCard::Trace {mode} {

    set cmd "EditCard::SetChanged true"
    foreach var {
        title bonus typeName worldName isAvatar blueLine rarity weight
    } {
        if {$mode == "Off"} {
            trace vdelete EditCard::fseConfig($var) w $cmd
        } else {
            trace variable EditCard::fseConfig($var) w $cmd
        }
    }

    return
}

# EditCard::EditCard --
#
#   Allows the specified card to be edited.
#
# Parameters:
#   args       : Short card ID (FR/46)...used by next and prev. Or gets
#                current selection from listbox.
#
# Returns:
#   Nothing.
#
proc EditCard::EditCard {args} {

    variable fseConfig
    variable paramList

    if {$args == ""} {
        # Get the current selection from the list box
        set lbw $fseConfig(lbw)
        set tempID [lindex [$lbw get [$lbw curselection]] 0]
        set card [CrossFire::GetCard $tempID -nocache]
    } else {
        set card [CrossFire::GetCard $args -nocache]
    }

    # Untrace entries so status is not changed when updating window.
    Trace Off

    # Update the data fields using the text variables.
    foreach {param index} $paramList {
        set fseConfig($param) [lindex $card $index]
    }

    if {$fseConfig(weight) == ""} {
        set fseConfig(weight) 1
    }

    # Update the card text.
    $fseConfig(tw) delete 1.0 end
    $fseConfig(tw) insert end [lindex $card 7]

    # Card type number to name.
    set fseConfig(typeName) $CrossFire::cardTypeXRef($fseConfig(type),name)

    # World number to name.
    set fseConfig(worldName) $CrossFire::worldXRef($fseConfig(world),name)

    # Convert the attribute IDs to names
    set attrNew {}
    foreach id $fseConfig(attrList) {
        if {[info exists CrossFire::cardAttributes(attr,$id)]} {
            lappend attrNew $CrossFire::cardAttributes(attr,$id)
        } else {
            lappend attrNew $id
        }
    }
    set fseConfig(attrList) $attrNew
    UpdateAttributeList $fseConfig(attrList)

    # Convert the uses IDs to names
    set usesNew {}
    foreach id $fseConfig(usesList) {
        if {[info exists CrossFire::usableCards(uses,$id)]} {
            lappend usesNew $CrossFire::usableCards(uses,$id)
        } else {
            lappend usesNew $id
        }
    }
    set fseConfig(usesList) $usesNew
    UpdateUsableList $fseConfig(usesList)

    # Trace entries, to save change status.
    Trace On

    SetChanged "false"
    set fseConfig(newCardNumber) $fseConfig(number)

    return
}

# EditCard::ChangeAttributeList --
#
#   Updates the list of attributes for the card.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc EditCard::ChangeAttributeList {} {

    variable fseConfig

    set fseConfig(attrList) {}
    set lbw $fseConfig(attrlb)
    foreach lbIndex [$lbw curselection] {
        lappend fseConfig(attrList) [$lbw get $lbIndex]
    }

    SetChanged "true"

    return
}

# EditCard::ChangeUsesList --
#
#   Updates the list of usable card types for the card.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc EditCard::ChangeUsesList {} {

    variable fseConfig

    set fseConfig(usesList) {}
    set lbw $fseConfig(useslb)
    foreach lbIndex [$lbw curselection] {
        lappend fseConfig(usesList) [$lbw get $lbIndex]
    }

    SetChanged "true"

    return
}

# EditCard::SaveCard --
#
#   Builds the new card and replaces the card in the data base.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc EditCard::SaveCard {} {

    variable fseConfig

    set topIndex [$fseConfig(lbw) index @0,0]
    set curSelection [$fseConfig(lbw) curselection]

    $fseConfig(topw) configure -cursor watch
    update

    set out [format "%-3s %3d %s %s %s %s" $fseConfig(setID) \
                 $fseConfig(number) [list $fseConfig(bonus)] \
                 $CrossFire::cardTypeXRef($fseConfig(typeName)) \
                 $CrossFire::worldXRef($fseConfig(worldName)) \
                 $fseConfig(isAvatar)]

    append out " [list [string trim $fseConfig(title)]]"
    append out " [list [string trim [$fseConfig(tw) get 1.0 end]]]"
    append out " [list $fseConfig(rarity)]"
    append out " [list [string trim $fseConfig(blueLine)]]"

    # Convert the attrbute list to IDs
    set attrOut {}
    foreach attr $fseConfig(attrList) {
        if {[info exists CrossFire::cardAttributes(ID,$attr)]} {
            lappend attrOut $CrossFire::cardAttributes(ID,$attr)
        } else {
            lappend attrOut $attr
        }
    }
    append out " [list $attrOut]"

    # Convert the uses list to IDs
    set usesOut {}
    foreach uses $fseConfig(usesList) {
        if {[info exists CrossFire::usableCards(ID,$uses)]} {
            lappend usesOut $CrossFire::usableCards(ID,$uses)
        } else {
            lappend usesOut $uses
        }
    }
    append out " [list $usesOut]"

    append out " [list $fseConfig(weight)]"

    set setID $fseConfig(setID)
    set cardNum $fseConfig(number)

    CrossFire::ReadCardDataBase $setID
    set cardDataBase \
        [lreplace $CrossFire::cardDataBase $cardNum $cardNum $out]

    set fid [open $CrossFire::setXRef($setID,tclFile) "w"]
    puts $fid "set CrossFire::cardDataBase \{"
    foreach card $cardDataBase {
        puts $fid "    [list $card]"
    }
    puts $fid "\}"
    close $fid

    SetChanged "false"

    ChangeCardSet $fseConfig(setID)
    $fseConfig(lbw) yview scroll $topIndex units
    ClickListBox m $curSelection 0

    $fseConfig(topw) configure -cursor {}

    return
}

# EditCard::CheckTextChange --
#
#   Checks each key press on the text widget to see if it is
#   one that changes the text.  Just need to add a check for
#   paste somehow...
#
# Parameters:
#   char       : From %A binding = ASCII char, {} if special char.
#
# Returns:
#   Nothing.
#
proc EditCard::CheckTextChange {char} {

    if {$char != ""} {
        SetChanged "true"
    }

    return
}

# EditCard::CheckForChange --
#
#   Checks if the current card needs to be updated.
#
# Parameters:
#   None.
#
# Returns:
#   0 - Saved, or no save needed.
#   1 - Not saved
#
proc EditCard::CheckForChange {} {

    variable fseConfig

    if {$fseConfig(change) == "true"} {

        if {$Config::config(FanSetEditor,autoSave) == 1} {
            SaveCard
            set result 0
        } else {
            set result 1
            set msg "Current card not updated.  Update now?"
            set answer \
                [tk_messageBox -default yes -icon warning -type yesnocancel \
                     -title "Edit Card Warning" -message $msg]
            if {$answer == "yes"} {
                SaveCard
                set result 0
            } elseif {$answer == "no"} {
                set result 0
            }
        }
    } else {
        set result 0
    }

    return $result
}

# EditCard::ChangeCardSet --
#
#   Changes the card set.
#
# Parameters:
#   setID      : Set ID to change to.
#
# Returns:
#   Nothing.
#
proc EditCard::ChangeCardSet {setID} {

    variable fseConfig

    if {[CheckForChange] == 0} {
        set fseConfig(setID) $fseConfig(tempSetID)
        set lastNumber $CrossFire::setXRef($setID,lastNumber)
        if {$fseConfig(number) > $lastNumber} {
            set fseConfig(number) $lastNumber
        }
        CrossFire::ReadCardDataBase $setID
        CrossFire::CardSetToListBox $CrossFire::cardDataBase \
            $fseConfig(lbw) 0 "clear"
        set fseConfig(cardSetName) $CrossFire::setXRef($setID,name)

        if {[lsearch [CrossFire::CardSetIDList fan] $setID] != -1} {
            $fseConfig(rom) configure -state disabled
            set fileName \
                [file join $CrossFire::homeDir "FanSets" \
                     "${setID}$CrossFire::extension(config)"]
            set fid [open $fileName "r"]
            set cfgData [read $fid]
            close $fid

            CrossFire::SetSafeVar attributes ""
            catch {
                safeInterp eval $cfgData
            }

            set fseConfig(authorName)  [CrossFire::GetSafeVar authorName]
            set fseConfig(authorEmail) [CrossFire::GetSafeVar authorEmail]
            set fseConfig(worldDef)    [CrossFire::GetSafeVar worldDef]
            set fseConfig(attributes)  [CrossFire::GetSafeVar attributes]
        } else {
            $fseConfig(rom) configure -state normal

            if {$CrossFire::setXRef($setID,author) == ""} {
                set fseConfig(authorName) "TSR, Inc."
            } else {
                set fseConfig(authorName) $CrossFire::setXRef($setID,author)
            }
            set fseConfig(authorEmail) ""
            set fseConfig(worldDef) ""
            set fseConfig(attributes) ""
        }

        UpdateAttributeList ""
        UpdateUsableList ""
        UpdateCustomAttribute
        set fseConfig(numRegular) [CrossFire::GetSafeVar numRegular]
        set fseConfig(numChase)   [CrossFire::GetSafeVar numChase]

        SetChanged "false"
        ClickListBox m 0 0
    }

    return
}

# EditCard::UpdateAttributeList --
#
#   Displays all the card attributes and highlights any that are in the 
#   specified list.
#
# Parameters:
#   attrs      : List of attributes to highlight.
#
# Returns:
#   Nothing.
#
proc EditCard::UpdateAttributeList {attrs} {

    variable fseConfig

    $fseConfig(attrlb) delete 0 end
    set attrList "$CrossFire::cardAttributes(list) $fseConfig(attributes)"
    foreach attribute [lsort $attrList] {
        $fseConfig(attrlb) insert end $attribute
        if {[lsearch $attrs $attribute] != -1} {
            $fseConfig(attrlb) selection set end
        }
    }
    
    return
}

# EditCard::UpdateUsableList --
#
#   Displays all the useable cards and highlights any that are in the 
#   specified list.
#
# Parameters:
#   uses       : List of card types to highlight.
#
# Returns:
#   Nothing.
#
proc EditCard::UpdateUsableList {uses} {

    variable fseConfig

    $fseConfig(useslb) delete 0 end
    foreach cardType [lsort $CrossFire::usableCards(list)] {
        $fseConfig(useslb) insert end $cardType
        if {[lsearch $uses $cardType] != -1} {
            $fseConfig(useslb) selection set end
        }
    }
    
    return
}

# EditCard::ExitEditCard --
#
#   Closes the card editor.  Checks if save needed.
#
# Parameters:
#   args       : Optional toplevel widget name (sent from CrossFire::Exit)
#
# Returns:
#   Nothing.
#
proc EditCard::ExitEditCard {args} {

    variable fseConfig

    if {[CheckForChange] == 0} {
        ViewCard::CleanUpCardViews $fseConfig(topw)
        destroy $fseConfig(topw)
        CrossFire::UnRegister CardEditor $fseConfig(topw)
        return 0
    } else {
        return -1
    }
}

# EditCard::ClickListBox --
#
#   Moves the selection to the line clicked on or moved to.
#
# Parameters:
#   X,Y        : %X,%Y of click
#   btnNum     : Buttton number.
#
# Returns:
#   The current line number of the selection.
#
proc EditCard::ClickListBox {X Y btnNum} {

    variable fseConfig

    set lbw $fseConfig(lbw)

    set curSel [$lbw curselection]
    if {$curSel == ""} {
        set curSel -1
    }
    set curSel [lindex $curSel 0]

    if {$X == "m"} {
        set first [string index $Y 0]
        if {$first == "-"} {
            set line [expr $curSel + $Y]
            if {$line < 0} {
                set line 0
            }
        } elseif {$first == "+"} {
            set line [expr $curSel + [string range $Y 1 end]]
            if {$line >= [$lbw index end]} {
                set line end
            }
        } else {
            set line $Y
        }
    } else {
        set line \
            [$lbw nearest [expr [winfo pointery $lbw] - [winfo rooty $lbw]]]
    }

    if {[CheckForChange] != 0} {
        return
    }

    focus $fseConfig(topw)

    # Highlight the line clicked.
    $lbw selection clear 0 end
    $lbw selection set $line
    $lbw see $line

    set tempID [lindex [$lbw get [$lbw curselection]] 0]
    if {$fseConfig(embedCardView) == "Yes"} {
	ViewCard::UpdateCardView $fseConfig(cardFrame) \
	    [CrossFire::GetCard $tempID]
    }
    EditCard $tempID

    switch -- $btnNum {
        2 {
            View
        }
        3 {
            tk_popup $fseConfig(popUp) $X $Y
        }
    }

    return
}

# EditCard::View --
#
#   Views the current card
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc EditCard::View {} {

    variable fseConfig

    ViewCard::View $fseConfig(topw) $fseConfig(setID) $fseConfig(number)

    return
}

# EditCard::About --
#
#   Displays an about dialog for the card editor.
#
# Paramters:
#   w         : Parent toplevel for the pop-up dialog.
#
# Returns:
#   Nothing.
#
proc EditCard::About {w} {
    set message "CrossFire Fan Set Editor\n"
    append message "\nby Dan Curtiss"
    tk_messageBox -icon info -parent $w -message $message \
        -title "About Fan Set Editor"

    return
}

# EditCard::Clear --
#
#   Clears the entries for the current card.
#
# Paramters:
#   None.
#
# Returns:
#   Nothing.
#
proc EditCard::Clear {} {

    variable fseConfig

    set fseConfig(title) ""
    set fseConfig(bonus) ""
    set fseConfig(typeName) "Ally"
    set fseConfig(worldName) "None"
    set fseConfig(isAvatar) 0
    $fseConfig(tw) delete 1.0 end
    set fseConfig(blueLine) ""
    set fseConfig(rarity) "V"
    set fseConfig(attrList) ""
    UpdateAttributeList ""
    $fseConfig(attrlb) selection clear 0 end
    set fseConfig(usesList) ""
    UpdateUsableList ""
    $fseConfig(useslb) selection clear 0 end
    set fseConfig(weight) 1

    SetChanged "true"

    return
}

# EditCard::GetMoveTo --
#
#   Gets the number to move the current card to.
#
# Parameters:
#   None.
#
# Returns:
#   The number (absolute) to move to, or 0 if canceled.
#
proc EditCard::GetMoveTo {} {

    variable fseConfig
    variable getMoveTo 0

    set maxNumber $CrossFire::setXRef($fseConfig(setID),lastNumber)

    set tw $fseConfig(topw).moveTo
    toplevel $tw
    wm title $tw "Move Card To"
    wm protocol $tw WM_DELETE_WINDOW "$tw.buttons.cancel invoke"

    CrossFire::Transient $tw

    frame $tw.range -borderwidth 1 -relief raised
    label $tw.range.l -text "Card Number (1-$maxNumber):"
    entry $tw.range.e -width 3
    set ew $tw.range.e
    bind $ew <Return> "set EditCard::getMoveTo \[$ew get\]"
    grid $tw.range.l $tw.range.e -padx 5 -pady 5

    frame $tw.buttons -borderwidth 1 -relief raised
    button $tw.buttons.select -text "Move" \
        -command "set EditCard::getMoveTo \[$ew get\]"
    button $tw.buttons.cancel -text "Cancel" \
        -command "set EditCard::getMoveTo 0"
    grid $tw.buttons.select $tw.buttons.cancel -padx 10 -pady 5

    grid $tw.range -sticky nsew
    grid $tw.buttons -sticky ew
    grid columnconfigure $tw 0 -weight 1
    grid rowconfigure $tw 0 -weight 1

    bind $tw <Key-Escape> "$tw.buttons.cancel invoke"
    bind $tw <Key-Return> "$tw.buttons.select invoke"

    update
    focus $ew
    grab set $tw
    vwait EditCard::getMoveTo
    grab release $tw
    destroy $tw

    if {($getMoveTo < 0) || ($getMoveTo > $maxNumber)} {
        set getMoveTo 0
    }

    return $getMoveTo
}

# EditCard::Move --
#
#   Moves the current card to another number.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc EditCard::Move {} {

    variable fseConfig

    SetChanged "false"

    set varList {
        title bonus typeName worldName isAvatar
        blueLine rarity attrList usesList
    }

    # Save all the information
    foreach var $varList {
        set temp($var) $fseConfig($var)
    }
    set tempText [string trimright [$fseConfig(tw) get 1.0 end] "\n"]

    # Get the card number to move to
    set moveTo [GetMoveTo]

    if {$moveTo != 0} {
        # Clear the old one and save
        Clear
        SaveCard

        # Move to the new one and fill in the info
        ClickListBox m [expr $moveTo - 1] 0
        foreach var $varList {
            set fseConfig($var) $temp($var)
        }
        $fseConfig(tw) insert end $tempText
        SaveCard
        UpdateAttributeList $fseConfig(attrList)
        UpdateUsableList $fseConfig(usesList)
    }

    return
}

# EditCard::EditCardQty --
#
#   Creates the GUI for changing the number of cards in a fan set.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc EditCard::EditCardQty {} {

    variable fseConfig
    variable changeQty 0

    set tw $fseConfig(topw).changeQty

    toplevel $tw
    wm title $tw "Edit Card Quantity"
    wm protocol $tw WM_DELETE_WINDOW "$tw.buttons.cancel invoke"

    CrossFire::Transient $tw

    set fseConfig(newNumReg) $fseConfig(numRegular)
    set fseConfig(newNumChase) $fseConfig(numChase)

    frame $tw.qty -borderwidth 1 -relief raised
    label $tw.qty.regl -text "Regular (25-500):" -width 18 -anchor e
    entry $tw.qty.rege -width 3 -textvariable EditCard::fseConfig(newNumReg)
    bind $tw.qty.rege <Return> "$tw.buttons.change invoke"
    label $tw.qty.chasel -text "Chase (0-100):" -width 18 -anchor e
    entry $tw.qty.chasee -width 3 \
        -textvariable EditCard::fseConfig(newNumChase)
    bind $tw.qty.chasee <Return> "$tw.buttons.change invoke"
    grid $tw.qty.regl $tw.qty.rege -padx 5 -pady 5
    grid $tw.qty.chasel $tw.qty.chasee -padx 5 -pady 5

    frame $tw.buttons -borderwidth 1 -relief raised
    button $tw.buttons.change -text "Change" \
        -command "set EditCard::changeQty 1"
    button $tw.buttons.cancel -text "Cancel" \
        -command "set EditCard::changeQty 0"
    grid $tw.buttons.change $tw.buttons.cancel -padx 10 -pady 5

    grid $tw.qty -sticky nsew
    grid $tw.buttons -sticky ew
    grid columnconfigure $tw 0 -weight 1
    grid rowconfigure $tw 0 -weight 1

    bind $tw <Key-Escape> "$tw.buttons.cancel invoke"
    bind $tw <Key-Return> "$tw.buttons.change invoke"

    update
    focus $tw.qty.rege
    grab set $tw
    vwait EditCard::changeQty
    grab release $tw
    destroy $tw

    if {$changeQty == 1} {
        DoChangeCardQty
    }

    return
}

# EditCard::DoChangeCardQty --
#
#   Does the actual change of the number of cards in a fan set.
#   Writes the .tcl file with the changes.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc EditCard::DoChangeCardQty {} {

    variable fseConfig

    # Just in case the current card is changed
    SaveCard

    set newNumRegular $fseConfig(newNumReg)
    set newNumChase $fseConfig(newNumChase)

    # Check new qtys to makes sure they are still within the accepted ranges
    if {($newNumRegular < 25) || ($newNumRegular > 500)} {
        tk_messageBox -icon error -title "Bad Card Quantity" \
            -message "The range for regular cards is 25-500."
        return
    }

    if {($newNumChase < 0) || ($newNumChase > 100)} {
        tk_messageBox -icon error -title "Bad Card Quantity" \
            -message "The range for chase cards is 0-100."
        return
    }

    set setID $fseConfig(setID)
    CrossFire::ReadCardDataBase $setID
    set cardDataBase $CrossFire::cardDataBase
    set numRegular $fseConfig(numRegular)
    set regularCards [lrange $cardDataBase 0 $numRegular]
    set numChase $fseConfig(numChase)
    set chaseCards [lrange $cardDataBase [expr $numRegular + 1] end]

    if {($newNumRegular == $numRegular) && ($newNumChase == $numChase)} {
        # No changes were made.
        return
    }

    # adjustChase is a flag to change the card numbers of chase cards if
    # the number of regulars changed.
    set adjustChase 0

    # Make changes to the regular cards
    if {$newNumRegular < $numRegular} {
        # User decreased the number of regulars
        set regularCards [lrange $regularCards 0 $newNumRegular]
    } elseif {$newNumRegular > $numRegular} {
        # Increased the number of regulars
        set start [expr $numRegular + 1]
        for {set num $start} {$num <= $newNumRegular} {incr num} {
            lappend regularCards \
                [format "%-3s %3d \{\} 1 0 0 \{\} \{\} V \{\} \{\} \{\} \{\}" \
                     $setID $num]
        }
    }

    # Make changes to the chase cards
    if {$newNumChase < $numChase} {
        # Decreased the number of chase.
        set chaseCards [lrange $chaseCards 0 [expr $newNumChase - 1]]
    } elseif {$newNumChase > $numChase} {
        # Increased the number of chase.
        for {set num [expr $numChase + 1]} {$num <= $newNumChase} {incr num} {
            lappend chaseCards \
                [format "%-3s %3d \{\} 1 0 0 \{\} \{\} V \{\} \{\} \{\} \{\}" \
                     $setID [expr $num + $newNumRegular]]
        }
    }

    # Resequence the number of the chase cards.
    if {$newNumRegular != $numRegular} {
        set offset 0
        set newChaseCards {}
        foreach card $chaseCards {
            set newNumber [expr [incr offset] + $newNumRegular]
            set newCard [lreplace $card 1 1 $newNumber]
            lappend newChaseCards $newCard
        }
        set chaseCards $newChaseCards
    }

    set fseConfig(numChase) $newNumChase
    set fseConfig(numRegular) $newNumRegular

    # Write the new fan set configuration file
    if {[lsearch [CrossFire::CardSetIDList fan] $setID] != -1} {
        WriteConfiguationFile
    }

    # Write the new fan set data file
    set fid [open $CrossFire::setXRef($setID,tclFile) "w"]
    puts $fid "set CrossFire::cardDataBase \{"
    foreach card "$regularCards $chaseCards" {
        puts $fid "    [list $card]"
    }
    puts $fid "\}"
    close $fid

    # Reregister the set with CrossFire
    CrossFire::AddCardSet fan $setID $fseConfig(cardSetName) \
 	$newNumRegular $newNumChase "$setID.tcl" na \
 	$fseConfig(attributes)

    # Redisplay the list of cards
    ChangeCardSet $setID

    return
}

# EditCard::WriteConfiguationFile --
#
#   Writes the .cfg file for the current set.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc EditCard::WriteConfiguationFile {} {

    variable fseConfig

    set cfgFile \
        [file join $CrossFire::homeDir "FanSets" "$fseConfig(setID).cfg"]
    set fid [open $cfgFile "w"]
    puts $fid "set authorEmail [list $fseConfig(authorEmail)]"
    puts $fid "set authorName [list $fseConfig(authorName)]"
    puts $fid "set numChase [list $fseConfig(numChase)]"
    puts $fid "set numRegular [list $fseConfig(numRegular)]"
    puts $fid "set setID [list $fseConfig(setID)]"
    puts $fid "set setName [list $fseConfig(cardSetName)]"
    puts $fid "set worldDef [list $fseConfig(worldDef)]"
    puts $fid "set attributes [list $fseConfig(attributes)]"
    close $fid

    return
}

# EditCard::CustomAttributes --
#
#   Creates a window displaying the custom attributes for a fan set and
#   allows for addition of new ones or removal.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc EditCard::CustomAttributes {} {

    variable fseConfig

    set w $fseConfig(topw).customAttr

    if {[winfo exists $w]} {
        wm deiconify $w
        raise $w
        return
    }

    toplevel $w
    wm title $w "Custom Attributes"
    wm protocol $w WM_DELETE_WINDOW "$w.buttons.quit invoke"

    frame $w.top -relief raised -borderwidth 1

    frame $w.top.list
    listbox $w.top.list.lb -selectmode single \
        -exportselection 0 -background white -foreground black \
        -selectbackground blue -selectforeground white \
        -selectborderwidth 0 -height 15 \
        -yscrollcommand "CrossFire::SetScrollBar $w.top.list.sb"
    scrollbar $w.top.list.sb -command "$w.top.list.lb yview"
    set fseConfig(customAttrLB) $w.top.list.lb

    grid $w.top.list.lb $w.top.list.sb -sticky nsew
    grid columnconfigure $w.top.list 0 -weight 1
    grid rowconfigure $w.top.list 0 -weight 1

    grid $w.top.list -sticky nsew -padx 5 -pady 5
    grid columnconfigure $w.top 0 -weight 1
    grid rowconfigure $w.top 0 -weight 1

    frame $w.buttons -relief raised -borderwidth 1

    button $w.buttons.add -text "Add..." \
        -command "EditCard::AddCustomAttribute"
    button $w.buttons.remove -text "Remove" \
        -command "EditCard::RemoveCustomAttribute"
    button $w.buttons.quit -text $CrossFire::close -command "destroy $w"
    grid $w.buttons.add $w.buttons.remove $w.buttons.quit \
        -padx 5 -pady 5

    grid $w.top -sticky nsew
    grid $w.buttons -sticky nsew
    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 1

    UpdateCustomAttribute

    return
}

# EditCard::UpdateCustomAttribute --
#
#   Updates the list of custom attributes if the window is displayed.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc EditCard::UpdateCustomAttribute {} {

    variable fseConfig

    if {[info exists fseConfig(customAttrLB)] &&
        [winfo exists $fseConfig(customAttrLB)]} {
        $fseConfig(customAttrLB) delete 0 end
        foreach attr [lsort $fseConfig(attributes)] {
            $fseConfig(customAttrLB) insert end $attr
        }
    }

    return
}

# EditCard::AddCustomAttribute --
#
#   Creates a window for entry of a new attribute.  Will not add duplicate
#   attributes (custom or standard).
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc EditCard::AddCustomAttribute {} {

    variable fseConfig

    # Get opponent to show to
    set tw [toplevel $fseConfig(topw).addCustom]
    wm title $tw "Add Custom Attribute"
    wm protocol $tw WM_DELETE_WINDOW "$tw.buttons.cancel invoke"

    frame $tw.top -relief raised -borderwidth 1

    frame $tw.top.sel
    label $tw.top.sel.l -text "Attribute:" -anchor e
    entry $tw.top.sel.e -width 30
    set entryW $tw.top.sel.e
    bind $entryW <Key-Return> "$tw.buttons.add invoke"
    grid $tw.top.sel.l $tw.top.sel.e -sticky ew -padx 3
    grid columnconfigure $tw.top.sel 1 -weight 1

    grid $tw.top.sel -sticky nsew -padx 5 -pady 5
    grid columnconfigure $tw.top 0 -weight 1
    grid rowconfigure $tw.top 0 -weight 1

    frame $tw.buttons -relief raised -borderwidth 1
    button $tw.buttons.add -text "Add" \
        -command "set EditCard::fseConfig(addCustom) ok"
    button $tw.buttons.cancel -text "Cancel" \
        -command "set EditCard::fseConfig(addCustom) cancel"
    grid $tw.buttons.add $tw.buttons.cancel -padx 5 -pady 5

    grid $tw.top -sticky nsew
    grid $tw.buttons -sticky ew
    grid columnconfigure $tw 0 -weight 1
    grid rowconfigure $tw 1 -weight 1

    focus $entryW
    update
    grab set $tw
    vwait EditCard::fseConfig(addCustom)
    grab release $tw

    if {$fseConfig(addCustom) == "ok"} {
        set attr [$entryW get]
    } else {
        set attr ""
    }

    destroy $tw

    # Add the new attribute only if it does not already exist in the
    # custom attribute list nor the regular attribute list.
    if {($attr != "") && ([lsearch $fseConfig(attributes) $attr] == -1) &&
        ([lsearch $CrossFire::cardAttributes(list) $attr] == -1)} {
        lappend fseConfig(attributes) $attr

        # Reregister the set with CrossFire
        CrossFire::AddCardSet fan $fseConfig(setID) $fseConfig(cardSetName) \
            $fseConfig(numRegular) $fseConfig(numChase) \
            "$fseConfig(setID).tcl" na $fseConfig(attributes)

        WriteConfiguationFile
        UpdateCustomAttribute
        UpdateAttributeList $fseConfig(attrList)
    }

    return
}

# EditCard::RemoveCustomAttribute --
#
#   Removes an attribute from the configuration file and from any card that
#   has it selected.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc EditCard::RemoveCustomAttribute {} {

    variable fseConfig
    variable paramList

    set sel [$fseConfig(customAttrLB) curselection]
    if {$sel == ""} {
        tk_messageBox -title "Unable to Comply" -icon error \
            -message "Select an attribute first!!"
        return
    }

    set attr [$fseConfig(customAttrLB) get $sel]
    set pos [lsearch $fseConfig(attributes) $attr]
    set fseConfig(attributes) [lreplace $fseConfig(attributes) $pos $pos]

    WriteConfiguationFile
    UpdateCustomAttribute

    set lbIndex [expr $fseConfig(number) - 1]
    SaveCard

    # cycle through all cards, removing the attribute.
    CrossFire::ReadCardDataBase $fseConfig(setID)
    foreach card $CrossFire::cardDataBase {

        set attrList [lindex $card 10]
        set pos [lsearch $attrList $attr]
        if {$pos != -1} {
            foreach {param index} $paramList {
                set fseConfig($param) [lindex $card $index]
            }
            set fseConfig(attrList) [lreplace $attrList $pos $pos]
            SaveCard
        }
    }

    # Refresh the display with the selected card
    ClickListBox m $lbIndex 0

    return
}

# EditCard::NewFanSet --
#
#   Creates a dialog for creating a new fan set.
#
# Parameters:
#   mode
#
# Returns:
#   Nothing.
#
proc EditCard::NewFanSet {} {

    variable fseConfig

    if {[CheckForChange]} return

    set w $fseConfig(topw).newSet

    if {[winfo exists $w]} {
        wm deiconify $w
        raise $w
        return
    }

    toplevel $w
    wm title $w "New Fan Set"
    wm protocol $w WM_DELETE_WINDOW "$w.buttons.quit invoke"
    set fseConfig(newSetGUI) $w

    set fseConfig(newAuthorName)  $Config::config(CrossFire,authorName)
    set fseConfig(newAuthorEmail) $Config::config(CrossFire,authorEmail)
    set fseConfig(newSetID)       {}
    set fseConfig(newSetName)     {}
    set fseConfig(newNumReg)      100
    set fseConfig(newNumChase)    10
    set fseConfig(newWorldDef)    0
    set fseConfig(newAttributes)  {}

    frame $w.top -borderwidth 1 -relief raised

    set fw [frame $w.top.data]

    label $fw.lauthor -text "Author:" -anchor e
    entry $fw.eauthor -textvariable EditCard::fseConfig(newAuthorName)
    label $fw.lemail  -text "Email:" -anchor e
    entry $fw.eemail  -textvariable EditCard::fseConfig(newAuthorEmail)
    label $fw.lsetid  -text "Set ID:" -anchor e
    entry $fw.esetid  -textvariable EditCard::fseConfig(newSetID)
    label $fw.lname   -text "Set Name:" -anchor e
    entry $fw.ename   -textvariable EditCard::fseConfig(newSetName)
    label $fw.lreg    -text "Regular (25-500):" -anchor e
    entry $fw.ereg    -textvariable EditCard::fseConfig(newNumReg)
    label $fw.lchase  -text "Chase (0-100):" -anchor e
    entry $fw.echase  -textvariable EditCard::fseConfig(newNumChase)
    checkbutton $fw.cbworld -text "Create New World" \
	-variable EditCard::fseConfig(newWorldDef)

    grid $fw.lauthor $fw.eauthor -sticky ew -padx 5 -pady 5
    grid $fw.lemail  $fw.eemail  -sticky ew -padx 5 -pady 5
    grid $fw.lsetid  $fw.esetid  -sticky ew -padx 5 -pady 5
    grid $fw.lname   $fw.ename   -sticky ew -padx 5 -pady 5
    grid $fw.lreg    $fw.ereg    -sticky ew -padx 5 -pady 5
    grid $fw.lchase  $fw.echase  -sticky ew -padx 5 -pady 5
    grid $fw.cbworld -sticky w -padx 5 -pady 5 -columnspan 2
    grid columnconfigure $fw 1 -weight 1
    grid rowconfigure $fw {0 1 2 3 4 5} -weight 1
    grid $fw -sticky nsew

    grid columnconfigure $w.top 0 -weight 1
    grid rowconfigure $w.top 0 -weight 1

    frame $w.buttons -borderwidth 1 -relief raised
    button $w.buttons.go -text "Create" -width 8 \
	-command "EditCard::CreateNewFanSet"
    button $w.buttons.quit -text "Cancel" -width 8 \
	-command "destroy $w"
    grid $w.buttons.go $w.buttons.quit -padx 3 -pady 5

    grid $w.top -sticky nsew
    grid $w.buttons -sticky nsew
    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 1

    return
}

# EditCard::CreateNewFanSet --
#
#   Performs data validation, creates 2 data files, and registers set.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc EditCard::CreateNewFanSet {} {

    variable fseConfig

    # Fix set id
    set setID [string toupper $fseConfig(newSetID)]
    regsub -all "\[^A-Z0-9]" $setID {} setID

    # Fix set name
    set setName $fseConfig(newSetName)
    regsub -all "\[^A-Z0-9]" $setName {} setNameClean

    # Make sure we have an ID and name.
    if {$setID == ""} {
	tk_messageBox -icon error -title "Invalid Set ID" \
	    -message "You must specify a Set ID."
	return
    }
    if {$fseConfig(newSetName) == ""} {
	tk_messageBox -icon error -title "Invalid Set ID" \
	    -message "You must specify a set name."
	return
    }

    # Makes sure ID is 2 or 3 characters
    set l [string length $setID]
    if {($l < 2) || ($l > 3)} {
	tk_messageBox -icon error -title "Invalid Set ID" \
	    -message "Set ID must be 2 or 3 characters."
	return
    }

    # Make sure the set ID and name are unique.
    set idList [string toupper [CrossFire::CardSetIDList "all"]]
    if {[lsearch $idList $setID] != -1} {
	tk_messageBox -icon error -title "Invalid Set ID" \
	    -message "Set ID '$setID' already exists!"
	return
    }
    if {[info exists CrossFire::setXRef($setName)]} {
	tk_messageBox -icon error -title "Invalid Set Name" \
	    -message "Set name '$setName' already exists!"
	return
    }

    # Check new qtys to makes sure they are within the accepted ranges
    if {($fseConfig(newNumReg) < 25) || ($fseConfig(newNumReg) > 500)} {
        tk_messageBox -icon error -title "Bad Card Quantity" \
            -message "The range for regular cards is 25-500."
        return
    }

    if {($fseConfig(newNumChase) < 0) || ($fseConfig(newNumChase) > 100)} {
        tk_messageBox -icon error -title "Bad Card Quantity" \
            -message "The range for chase cards is 0-100."
        return
    }

    set fseConfig(authorName)  $fseConfig(newAuthorName)
    set fseConfig(authorEmail) $fseConfig(newAuthorEmail)
    set fseConfig(numRegular)  $fseConfig(newNumReg)
    set fseConfig(numChase)    $fseConfig(newNumChase)
    set fseConfig(setID)       $setID
    set fseConfig(cardSetName) $setName
    set fseConfig(attributes)  $fseConfig(newAttributes)

    # Create world definition
    if $fseConfig(newWorldDef) {
	set fseConfig(worldDef) \
	    [list $setID $setName $setNameClean $setID.gif $setID]
	$fseConfig(worldNameMenu) add radiobutton \
            -label $setName -value $setName \
            -variable EditCard::fseConfig(worldName)
    } else {
	set fseConfig(worldDef) {}
    }

    # Save the configuration file
    WriteConfiguationFile

    # Save the empty tcl file
    set tclFile \
	[file join $CrossFire::homeDir "FanSets" "$setID.tcl"]
    set fid [open $tclFile "w"]
    puts $fid "set CrossFire::cardDataBase \{"
    puts $fid "  \{$fseConfig(cardSetName)\}"
    set totalCards [expr $fseConfig(numRegular) + $fseConfig(numChase)]
    for {set num 1} {$num <= $totalCards} {incr num} {
	puts $fid \
	    "  \{$setID $num \{\} 1 0 0 \{\} \{\} V \{\} \{\} \{\} \{\}\}"
    }
    puts $fid "\}"
    close $fid

    # Update set selection menu
    $fseConfig(setNameMenu) add radiobutton \
	-label $fseConfig(cardSetName) \
	-variable EditCard::fseConfig(tempSetID) -value $setID \
	-command "EditCard::ChangeCardSet $setID"
    set fseConfig(tempSetID) $setID

    # Reregister the set with CrossFire
    CrossFire::AddCardSet fan $setID $fseConfig(cardSetName) \
 	$fseConfig(newNumReg) $fseConfig(newNumChase) "$setID.tcl" na \
 	$fseConfig(attributes)

    # Register the world
    if $fseConfig(newWorldDef) {
	eval CrossFire::AddWorld "fan" $fseConfig(worldDef)
    }

    # Redisplay the list of cards
    ChangeCardSet $setID

    destroy $fseConfig(newSetGUI)

    return
}

# EditCard::AddCardPhase --
#
#   Adds card phase(s) to the list of attributes based on card type.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc EditCard::AddCardPhase {} {

    variable fseConfig

    set r [tk_messageBox -icon warning -type yesno \
	       -message "Are you sure?" -title "Add Card Phase"]
    if {$r == "no"} return

    set setID $fseConfig(setID)
    CrossFire::ReadCardDataBase $setID
    set cardDataBase $CrossFire::cardDataBase

    foreach card [lrange $cardDataBase 1 end] {

	set cardNum  [lindex $card 1]
	set cardType [lindex $card 3]
	set attrList [lindex $card 10]
	set cardText [lindex $card 7]

	switch $cardType {
	    1 {
		# Ally
		set phaseList 4
	    }
	    2 - 5 - 7 - 9 - 10 - 12 - 14 - 16 - 20 {
		# Champions, Magic Items, Artifacts
		set phaseList {3 4}
	    }
	    3 - 4 - 11 - 17 - 18 - 19 {
		# Spells, Powers, Abilities, etc
		set phaseList {}
		foreach phase {3 4 5} {
		    if {[regexp "/$phase" $cardText] ||
			[regexp "$phase\\)" $cardText]} {
			lappend phaseList $phase
		    }
		}
		if {$phaseList == ""} {
		    set phaseList 4
		}
	    }
	    21 {
		# Dungeon
		set phaseList {}
	    }
	    6 {
		# Event
		set phaseList {0 1 2 3 4 5}
	    }
	    8 - 13 {
		# Holding, Realm
		set phaseList 2
	    }
	    15 {
		# Rule
		set phaseList 0
	    }
	}

	# Add the selected phases to the attribute list
	foreach phase $phaseList {
	    set attr "Phase $phase"
	    if {[lsearch $attrList $attr] == -1} {
		lappend attrList $attr
	    }
	}

	# Store the card
	set card [lreplace $card 10 10 $attrList]
	set cardDataBase \
	    [lreplace $cardDataBase $cardNum $cardNum $card]
    }

    # Write the new database file
    set fid [open $CrossFire::setXRef($setID,tclFile) "w"]
    puts $fid "set CrossFire::cardDataBase \{"
    foreach card $cardDataBase {
	puts $fid "    [list $card]"
    }
    puts $fid "\}"
    close $fid

    SetChanged "false"

    # Refresh the display
    ClickListBox m 0 0

    return
}

proc EditCard::Validate {} {

    variable fseConfig

    ClickListBox m 0 0
    SaveCard
    set max [$fseConfig(lbw) size]
    for {set i 1} {$i < $max} {incr i} {
        ClickListBox m +1 0
        SaveCard
    }

    return
}
