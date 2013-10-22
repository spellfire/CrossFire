# ViewCard.tcl 20060110
#
# This file contains the procedures for viewing cards.
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

namespace eval ViewCard {

    variable viewCount 0      ;# Counter for creating new toplevels.
    variable superView
    set superView(count) 0
    set superView(topw) .viewer

    foreach {htmlMode modeName pageHead html pageTail} {
        full {ML::str cv,allInfo} {} {
	    <TABLE WIDTH="100%" BORDER=1 CELLPADDING=3>
	    <TR><TD WIDTH="15%">$cardID</TD>
	    <TD ALIGN=center WIDTH="70%"><B>$name</B></TD>
	    <TD WIDTH="15%" ALIGN=right>$type $bonus</TD></TR>
	    <TR><TD COLSPAN=2>$world</TD>
	    <TD ALIGN=right>$rarity</TD></TR>
	    <TR><TD COLSPAN=3>$cardText
	    <FONT COLOR=$Config::config(ViewCard,color,blueLine)>
	    $blueLine</FONT>
	    <FONT COLOR=$Config::config(ViewCard,color,attribute)>
	    $attributes</FONT>
	    <FONT COLOR=$Config::config(ViewCard,color,usable)>
	    $usable</FONT>
	    </TD></TR></TABLE><BR><BR>
	} {}
        viewer {ML::str cv,windowName} {} {
	    <TABLE BORDER=2 WIDTH="100%" HEADING="Standard"><TR><TD>
	    <TABLE CELLPADDING=5 CELLSPACING=0 BGCOLOR=white WIDTH="100%">
	    <TR><TD VALIGN=top COLSPAN=2>$type $bonus</TD></TR>
	    <TR><TD>$world</TD><TD ALIGN=right><B>$name</B></TD></TR>
	    <TR><TD BGCOLOR=beige COLSPAN=2>$cardText
	    <FONT COLOR=$Config::config(ViewCard,color,blueLine)>
	    $blueLine</FONT>
	    <FONT COLOR=$Config::config(ViewCard,color,attribute)>
	    $attributes</FONT>
	    <FONT COLOR=$Config::config(ViewCard,color,usable)>
	    $usable</FONT>
	    </TD></TR>
	    <TR><TD>$rarity</TD>
	    <TD ALIGN=right>$cardSet $cardNumber of $setMax</TD>
	    </TR></TABLE></TD></TR></TABLE><BR><BR>
	} {}
        standard {ML::str cv,standard} {} {
	    <TABLE WIDTH="100%" BORDER=1 CELLPADDING=3>
	    <TR><TD WIDTH="15%">$type</TD>
	    <TD ALIGN=center WIDTH="70%"><B>$name</B></TD>
	    <TD WIDTH="15%" ALIGN=right>$bonus</TD></TR>
	    <TR><TD COLSPAN=3>$cardText
	    <FONT COLOR=$Config::config(ViewCard,color,blueLine)>
	    $blueLine</FONT>
	    <FONT COLOR=$Config::config(ViewCard,color,attribute)>
	    $attributes</FONT>
	    <FONT COLOR=$Config::config(ViewCard,color,usable)>
	    $usable</FONT>
	    </TD></TR>
	    <TR><TD>$cardSet</TD><TD ALIGN=center>$world</TD>
	    <TD ALIGN=right>$cardNumber/$setMax</TD></TR></TABLE><BR><BR>
	} {}
        graphics {ML::str cv,standardAlt} {} {
	    <TABLE WIDTH="100%" BORDER=1 CELLPADDING=3>
	    <TR><TD WIDTH="15%">$type $bonus</TD>
	    <TD ALIGN=center WIDTH="70%"><B>$name</B></TD>
	    <TD WIDTH="15%" ALIGN=right>$world</TD></TR>
	    <TR><TD COLSPAN=3>$cardText
	    <FONT COLOR=$Config::config(ViewCard,color,blueLine)>
	    $blueLine</FONT>
	    <FONT COLOR=$Config::config(ViewCard,color,attribute)>
	    $attributes</FONT>
	    <FONT COLOR=$Config::config(ViewCard,color,usable)>
	    $usable</FONT>
	    </TD></TR>
	    <TR><TD ALIGN=right COLSPAN=3>$cardSet $cardNumber of $setMax
	    </TD></TR></TABLE><BR><BR>
	} {}
        plain {ML::str cv,plain} {} {
	    <TABLE WIDTH="100%" BORDER=1 CELLPADDING=3>
	    <TR><TD><B>Card ID</B></TD><TD>$cardID</TD></TR>
	    <TR><TD><B>Title</B></TD><TD>$name</TD></TR>
	    <TR><TD><B>World</B></TD><TD>$world</TD></TR>
	    <TR><TD><B>Type</B></TD><TD>$type</TD></TR>
	    <TR><TD><B>Bonus</B></TD><TD>Bonus</TD></TR>
	    <TR><TD><B>Text</B></TD><TD>$cardText
	    <FONT COLOR=$Config::config(ViewCard,color,blueLine)>
	    $blueLine</FONT>
	    <FONT COLOR=$Config::config(ViewCard,color,attribute)>
	    $attributes</FONT>
	    <FONT COLOR=$Config::config(ViewCard,color,usable)>
	    $usable</FONT>
	    </TD></TR>
	    <TR><TD><B>Rarity</B><TD>$rarity</TD></TR></TABLE><BR><BR>
	} {}
        listBasic {ML::str cv,basicList} \
	    {<TABLE><TR><TH>Card ID<TH ALIGN=LEFT>Name
		<TH ALIGN=LEFT>Type<TH>Rarity} \
	    {<TR><TD>$cardID<TD>$name<TD>$type<TD>$rarity} \
	    {</TABLE>}
        listFramed {ML::str cv,framedList} \
	    {<TABLE BORDER=1 CELLPADDING=3>
		<TR><TH>Card ID<TH>Name<TH>Type<TH>Rarity} \
	    {<TR><TD>$cardID<TD>$name<TD>$type<TD>$rarity} \
	    {</TABLE>}
    } {
        lappend superView(htmlModeList) $htmlMode
        set superView(htmlModeName,$htmlMode) [eval $modeName]
        set superView(htmlMode,$htmlMode,pageHead) $pageHead
        set superView(htmlMode,$htmlMode,html) $html
        set superView(htmlMode,$htmlMode,pageTail) $pageTail
    }
}

# ViewCard::FixCardText --
#
#   Removes the annoying and redundantly repeative rule card instructional
#   text if the option is set in Configure.
#
# Parameters:
#   cardText   : Card text.
#
# Returns:
#   Fixed card.
#
proc ViewCard::FixCardText {cardText {group ViewCard}} {

    if {$Config::config($group,showRuleText) == "No"} {
        regsub "Played at the beginning of th\[eis]+ player's turn,? this card is not discarded. *" $cardText {} cardText
        regsub "It affects all players and remains in effect until an\[y ]*other rule card is played\. *" $cardText {} cardText
    }

    return $cardText
}

# ViewCard::View --
#
#   Views a card.  This is the main procedure that calls ViewCard.
#
# Parameters:
#   w          : Toplevel widget that viewed card will be a child of.
#
# Args:
#   Short ID   : A short card ID. (ie: FRc/18)
#     -or-
#   Set ID     : Card set ID. (ie: FR)
#   Number     : Raw card number (ie: 118)
#
# Returns:
#   Nothing.
#
proc ViewCard::View {w args} {

    set card [eval CrossFire::GetCard $args]

    if {($card == "") || ([lindex $card 0] == "+") ||
        ([lindex $card 0] == "-")} {
        tk_messageBox -message [ML::str cv,cardErrorMsg] \
            -icon error -title [ML::str cv,cardError]
    } else {
        ViewCard $w $card
    }
}

# ViewCard::ViewCard --
#
#   Procedure that actually creates/updates a card toplevel.
#
# Parameters:
#   tw         : Toplevel widget that viewed card will be a child of.
#   card       : The card to view in standard card data base format.
#   args       : Optional parameters passed to CreateCardView
#
# Returns:
#   Nothing.
#
proc ViewCard::ViewCard {tw card args} {

    variable viewCount
    variable superView
    variable cardViewID

    set cardID [lindex [eval CrossFire::GetCardID [lrange $card 0 1]] 0]

    if {[info exists cardViewID($tw,$cardID)] &&
        [winfo exists $cardViewID($tw,$cardID)]} {
        set w $cardViewID($tw,$cardID)
    } elseif {($Config::config(ViewCard,mode) == "Multiple") ||
        ([regexp $superView(topw) $tw])} {
        set w $tw.card[incr viewCount]
    } else {
        set w $tw.card
    }

    # Display the card
    if {[winfo exists $w]} {
        wm deiconify $w
        raise $w
    } else {
        toplevel $w
        bind $w <Key-Escape> "$w.bottom.dismiss invoke"

	if {$CrossFire::platform == "macintosh"} {
	    # Add a menubar on Macs
	    menu $w.m
	    $w.m add cascade -label "Card" -menu $w.m.card
	    menu $w.m.card -tearoff 0
	    $w.m.card add command -label "Quit" \
		-command "$w.bottom.dismiss invoke"
	    $w configure -menu $w.m
	}

        CrossFire::Transient $w

        CreateCardView $w.cv $args
        pack $w.cv -expand 1 -fill both -padx 5 -pady 5

        frame $w.bottom
        button $w.bottom.dismiss -text $CrossFire::close \
            -command "destroy $w"
        pack $w.bottom.dismiss -pady 5

        if {$Config::config(ViewCard,closeButton) == "Yes"} {
            pack $w.bottom
        }
    }

    set cardViewID($tw,$cardID) $w
    set name [UpdateCardView $w.cv $card]
    wm title $w "$cardID $name"

    return
}

# ViewCard::CleanUpCardViews --
#
#   This should be called by the various process that create card view child
#   upon exiting.  It cleans up some data.
#
# Parameters:
#   w          : Toplevel parent
#
# Returns:
#   Nothing.
#
proc ViewCard::CleanUpCardViews {w} {

    variable cardViewID

    foreach key [array names cardViewID "$w,*"] {
        unset cardViewID($key)
    }

    return
}

# ViewCard::CreateCardView --
#
#   Creates a card viewing "widget" in the supplied frame.
#
# Parameters:
#   fw         : Frame to create the card widget in.
#   args       : Optional parameters for the card view.
#                -height : text area height (default = 6)
#                -width  : text area width (default = 40)
#
# Returns:
#   The frame widget name.
#
proc ViewCard::CreateCardView {fw args} {

    variable view

    set tbHeight 6
    set tbWidth 40

    foreach {opt value} $args {
        switch -- $opt {
            "-height" {
                set tbHeight $value
            }
            "-width" {
                set tbWidth $value
            }
        }
    }

    frame $fw -background white
    bind $fw <Destroy> "ViewCard::RemoveCardView $fw"

    frame $fw.icon -background white
    label $fw.icon.image -background white -foreground black \
        -font {Times 18 bold}
    bind $fw.icon.image <ButtonRelease-1> "ViewCard::ToggleImage $fw"
    label $fw.icon.level -background white -foreground black \
        -font {Times 18 bold}
    pack $fw.icon.image $fw.icon.level -anchor nw -side left
    pack $fw.icon -anchor nw
    frame $fw.desc -relief groove -bd 2 -background white
    frame $fw.desc.title -background white
    label $fw.desc.title.world -anchor w -background white -foreground black
    message $fw.desc.title.name -background white -foreground black \
        -width 100 -justify right
    Balloon::Set $fw.desc.title.name "Right-click to copy to clipboard "
    grid $fw.desc.title.world -row 0 -column 0 -stick w
    grid $fw.desc.title.name -row 0 -column 1 -padx 3 -sticky e
    grid columnconfigure $fw.desc.title 1 -weight 1
    pack $fw.desc.title -fill x
    frame $fw.desc.cardText
    text $fw.desc.cardText.text -height $tbHeight -width $tbWidth \
        -relief flat -wrap word -pady 5 -padx 5 -background bisque \
        -foreground black -cursor {} -exportselection 1 \
        -yscrollcommand "CrossFire::SetScrollBar $fw.desc.cardText.sb"
    set view($fw,text) $fw.desc.cardText.text

    set copyCommand [bind Text <<Copy>>]
    bind $view($fw,text) <Any-Key> "break"
    bind $view($fw,text) <<Copy>> $copyCommand

    $fw.desc.cardText.text tag configure center -justify center
    $fw.desc.cardText.text tag configure blueline \
        -foreground $Config::config(ViewCard,color,blueLine) -justify center
    $fw.desc.cardText.text tag configure attribute \
        -foreground $Config::config(ViewCard,color,attribute) -justify center
    $fw.desc.cardText.text tag configure usable \
        -foreground $Config::config(ViewCard,color,usable) -justify center
    scrollbar $fw.desc.cardText.sb -background bisque \
        -command "$fw.desc.cardText.text yview"
    grid $fw.desc.cardText.text -sticky nsew
    grid columnconfigure $fw.desc.cardText 0 -weight 1
    grid rowconfigure $fw.desc.cardText 0 -weight 1
    pack $fw.desc.cardText -expand 1 -fill both -padx 5
    label $fw.desc.rarity -background white -foreground black
    label $fw.desc.number -background white -foreground black
    pack $fw.desc.rarity -side left -pady 3 -padx 2
    pack $fw.desc.number -side right -pady 3 -padx 3
    pack $fw.desc -expand 1 -fill both -padx 5 -pady 5

    return $fw
}

proc ViewCard::FormatAttributeList {attrList {mode normal}} {

    set aList ""
    set phaseList ""

    # Add each attribute except phases to list (unless mode == flat)
    foreach attr $attrList {
        if {([lindex $attr 0] == "Phase") && ($mode != "flat")} {
            lappend phaseList [lindex $attr 1]
        } else {
            if {$aList != ""} {
                append aList "; "
            }
            append aList $attr
        }
    }

    # Make phase list look nice.
    set pLen [llength $phaseList]
    if {$pLen > 0} {
        set s [expr {$pLen > 1 ? "s" : ""}]
        set pAdd "Phase$s "
        set count 0
        foreach phaseNum $phaseList {
            incr count
            if {$count != 1} {
                if {$count == $pLen} {
                    append pAdd " and "
                } else {
                    append pAdd ", "
                }
            }
            append pAdd $phaseNum
        }
        if {$aList != ""} {
            append aList "; "
        }
        append aList $pAdd
    }

    return $aList
}

# ViewCard::UpdateCardView --
#
#   Updates the card view in the specified frame.
#
# Parameters:
#   fw         : Frame widget name the card is in.
#   card       : Card to view in standard card format.
#
# Returns:
#   The card name.
#
proc ViewCard::UpdateCardView {fw card} {

    variable storage

    set storage($fw,card) $card
    foreach {
        cardSetID rawCardNumber bonus cardTypeNumber worldID isAvatar
        name cardText rarity blueLine attrList usesList weight
    } $card break

    # Convert the attribute IDs to names
    set attrNew {}
    foreach id $attrList {
        if {[info exists CrossFire::cardAttributes(attr,$id)]} {
            lappend attrNew $CrossFire::cardAttributes(attr,$id)
        } else {
            lappend attrNew $id
        }
    }
    set attrList $attrNew

    # Convert the uses IDs to names
    set usesNew {}
    foreach id $usesList {
        if {[info exists CrossFire::usableCards(uses,$id)]} {
            lappend usesNew $CrossFire::usableCards(uses,$id)
        } else {
            lappend usesNew $id
        }
    }
    set usesList $usesNew

    set cardSetName $CrossFire::setXRef($cardSetID,name)
    set world $CrossFire::worldXRef($worldID,name)
    set icon $CrossFire::cardTypeXRef($cardTypeNumber,icon)
    set cardTypeName $CrossFire::cardTypeXRef($cardTypeNumber,name)
    foreach {cardID cardNumber setMax} \
        [CrossFire::GetCardID $cardSetID $rawCardNumber] break

    if {$world == "None"} {
        set world "AD&D"
    }
    if {$name == "(no card)"} {
        set world ""
        set icon All
    }

    # Change the word 'of' depending on the language.
    switch -- $cardSetID {
        FRN     {
            set of "sur"
        }
        DE      {
            set of "von"
        }
        IT      {
            set of "di"
        }
        POR - SP {
            set of "de"
        }
        default {
            set of "of"
        }
    }

    # Woohoo! Found another typo in a Spellfire card!
    if {($cardSetID == "POR") && ($rawCardNumber == 85)} {
        set of "of"
    }

    if {$::imgPackage == "No"} {
        set ext ".gif"
    } else {
        set ext ".*"
    }
    set cardGraphicList \
        [glob -nocomplain \
	     [file join $CrossFire::homeDir "Graphics" "Cards" \
		  $cardSetID [format "%03d" $rawCardNumber]$ext]]

    $fw.icon.level configure -text " $bonus"
    $fw.icon.image configure -text $cardTypeName -image ""
    set storage($fw,icon) "Name"
    if {$Config::config(ViewCard,typeMode) == "Icon"} {
        if {[lsearch [image names] $icon] != -1} {
            $fw.icon.image configure -image $icon
            set storage($fw,icon) "Icon"
        }
        foreach cardGraphic $cardGraphicList {
	    set imageName cardPic$fw
	    if {$Config::config(ViewCard,showLevel) == "No"} {
		$fw.icon.level configure -text ""
	    }
	    if {[catch {image create photo $imageName -file $cardGraphic} err]} {
		dputs $err
	    } else {
                $fw.icon.image configure -image $imageName
                set storage($fw,icon) "Image"
                break
	    }
	}
    }

    $fw.desc.title.world configure -text $world -image ""
    if {$Config::config(ViewCard,worldMode) == "Icon"} {
        set iconName $CrossFire::worldXRef($worldID,icon)
        if {[lsearch [image names] $iconName] != -1} {
            $fw.desc.title.world configure -image $iconName
        }
    }

    $fw.desc.title.name configure -text $name
    ### bind $fw.desc.title.name <Double-Button-1> \
	"CrossFire::SetClipboard \{$cardID $name\}"
    bind $fw.desc.title.name <Button-3> \
        "ViewCard::CreateRightClick $fw $cardID %X %Y"
    ### CrossFire::CreateYogilandLink $fw.desc.title.name $cardID

    $fw.desc.rarity configure -text "$rarity"
    if {$cardSetName == "Promo"} {
        set numberText "$cardSetName $cardNumber"
    } else {
        set numberText "$cardSetName  $cardNumber $of $setMax"
    }
    $fw.desc.number configure -text $numberText
    $fw.desc.cardText.text delete 1.0 end
    $fw.desc.cardText.text insert end [FixCardText $cardText] center

    if {($blueLine != "") &&
        ($Config::config(ViewCard,showBluelines) == "Yes")} {
        $fw.desc.cardText.text insert end " $blueLine" blueline
    }

    if {($attrList != "") &&
        ($Config::config(ViewCard,showAttributes) == "Yes")} {
        $fw.desc.cardText.text insert end \
            " [FormatAttributeList $attrList]." attribute
    }

    if {($usesList != "") &&
        ($Config::config(ViewCard,showUsable) == "Yes")} {
        set uList ""
        foreach usable $usesList {
            if {$uList != ""} {
                append uList "; "
            }
            append uList $usable
        }
        $fw.desc.cardText.text insert end " $uList." usable
    }

    return $name
}

# ViewCard::SetImage --
#
#   Attempts to change the image to display for a card.
#
# Parameters:
#   fw         : Card frame
#   mode       : What to change to.
#                  Name  : Textual card name and bonus
#                  Icon  : Card type icon and textual bonus
#                  Image : Scanned card image, no bonus
#
# Returns:
#   1 on success, 0 on failure
#
proc ViewCard::SetImage {fw mode} {

    variable storage

    set result 1

    foreach {
        cardSetID rawCardNumber bonus cardTypeNumber worldID isAvatar
        name cardText rarity blueLine attrList usesList weight
    } $storage($fw,card) break

    set icon $CrossFire::cardTypeXRef($cardTypeNumber,icon)
    set cardTypeName $CrossFire::cardTypeXRef($cardTypeNumber,name)
    set cardGraphic \
        [file join $CrossFire::homeDir "Graphics" "Cards" \
             $cardSetID [format "%03d" ${rawCardNumber}].gif]

    $fw.icon.level configure -text " $bonus"
    $fw.icon.image configure -text $cardTypeName -image ""

    switch -- $mode {
        "Name" {
            set storage($fw,icon) "Name"
        }
        "Icon" {
            if {[lsearch [image names] $icon] != -1} {
                $fw.icon.image configure -image $icon
                set storage($fw,icon) "Icon"
            } else {
                set result 0
            }
        }
        "Image" {
            if {[file exists $cardGraphic]} {
                set imageName cardPic$fw
                $fw.icon.level configure -text ""
                image create photo $imageName -file $cardGraphic
                $fw.icon.image configure -image $imageName
                set storage($fw,icon) "Image"
            } else {
                set result 0
            }
        }
    }

    return $result
}

# ViewCard::ToggleImage --
#
#   Cycles through the 3 card image display modes.
#
# Parameters:
#   fw         : Card frame
#
# Returns:
#   Nothing.
#
proc ViewCard::ToggleImage {fw} {

    variable storage

    switch -- $storage($fw,icon) {
        "Name" {
            if {[SetImage $fw "Icon"] == 0} {
                SetImage $fw "Image"
            }
        }
        "Icon" {
            if {[SetImage $fw "Image"] == 0} {
                SetImage $fw "Name"
            }
        }
        "Image" {
            SetImage $fw "Name"
        }
    }
    
    return
}

# ViewCard::Viewer --
#
#   Allows for viewing of cards.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc ViewCard::Viewer {} {

    variable superView

    set tw $superView(topw)[incr superView(count)]

    toplevel $tw
    wm title $tw [ML::str cv,windowName]
    wm protocol $tw WM_DELETE_WINDOW "ViewCard::ExitViewer $tw"
    AddMenuBar $tw

    # Card Set Selection text box
    set superView($tw,cardSetSel) $tw.setList
    CrossFire::CreateCardSetSelection $superView($tw,cardSetSel) all \
        "ViewCard::UpdateSelection $tw setList"
    grid $tw.setList -sticky nsew -padx 5 -pady 7

    set css $tw.sel
    frame $css

    # Card Type Selection
    menubutton $css.cardType -indicatoron 1 -relief raised \
        -menu $css.cardType.menu \
        -textvariable ViewCard::superView($tw,cardTypeName)

    menu $css.cardType.menu -tearoff 0
    foreach typeID $CrossFire::cardTypeIDList {
        set name $CrossFire::cardTypeXRef($typeID,name)
        if {$typeID <= 100} {
            $css.cardType.menu add radiobutton \
                -label $name -value $typeID \
                -variable ViewCard::superView($tw,typeID) \
                -command "ViewCard::UpdateSelection $tw type"
        }
    }

    # Card Selection Listbox
    frame $css.list
    listbox $css.list.lb -selectmode single \
        -exportselection 0 -background white -foreground black \
        -selectbackground blue -selectforeground white \
        -selectborderwidth 0 -height 20 \
        -yscrollcommand "CrossFire::SetScrollBar $css.list.sb"
    set superView($tw,lbw) $css.list.lb
    scrollbar $css.list.sb -command "$css.list.lb yview"
    grid $css.list.lb -sticky nsew

    frame $css.search
    label $css.search.label -text "[ML::str search]: " -borderwidth 0
    entry $css.search.entry -background white -foreground black
    pack $css.search.entry -side right -expand 1 -fill x
    pack $css.search.label -side left

    # Set up the listbox navigation and search bindings.
    CrossFire::InitListBox $tw $css.list.lb ViewCard
    CrossFire::InitSearch $tw $css.search.entry $css.list.lb ViewCard

    grid columnconfigure $css.list 0 -weight 1
    grid rowconfigure $css.list 0 -weight 1

    grid $css.cardType -sticky ew -pady 3
    grid $css.list -sticky nsew -pady 3
    grid $css.search -sticky ew -pady 3
    grid columnconfigure $css 0 -weight 1
    grid rowconfigure $css 1 -weight 1

    grid $css -row 0 -column 1 -sticky nsew -padx 5 -pady 5

    # Card View
    set superView($tw,cardView) $tw.card
    CreateCardView $superView($tw,cardView) -width 40
    grid $superView($tw,cardView) -row 0 -column 2 \
        -sticky nsew -padx 5 -pady 8 -rowspan 2

    grid columnconfigure $tw 0 -weight 1
    grid columnconfigure $tw 1 -weight 3
    grid rowconfigure $tw 0 -weight 1

    bind $tw <Key-Right> "ViewCard::NewCardView $tw"
    bind $tw <$CrossFire::accelBind-v> "ViewCard::NewCardView $tw"
    bind $css.search.entry <$CrossFire::accelBind-v> \
        "ViewCard::NewCardView $tw; break"

    set setID "1st"
    set superView($tw,setID) $setID
    set superView($tw,cardSetName) $CrossFire::setXRef($setID,name)

    set typeID "All Cards"
    set superView($tw,typeID) $CrossFire::cardTypeXRef($typeID)
    set superView($tw,cardTypeName) $typeID

    if {$CrossFire::platform == "windows"} {
        focus $tw
    }

    CrossFire::Register CardViewer $tw

    UpdateSelection $tw init

    return
}

# ViewCard::AddMenuBar --
#
#   Creates the menubar for the viewer and sets up the
#   accelerator key bindings for the commands.
#
# Parameters:
#   w          : Toplevel.
#
# Returns:
#   Nothing.
#
proc ViewCard::AddMenuBar {w} {

    variable superView

    menu $w.menubar

    $w.menubar add cascade \
        -label [ML::str card] \
        -underline 0 \
        -menu $w.menubar.card
    menu $w.menubar.card -tearoff 0

    $w.menubar.card add cascade \
        -label [ML::str cv,exportSet] \
        -underline 0 \
        -menu $w.menubar.card.export

    menu $w.menubar.card.export -tearoff 0
    $w.menubar.card.export add command \
        -label [ML::str csv] \
        -underline 0 \
        -command "ViewCard::Export $w csv"
    $w.menubar.card.export add cascade \
        -label [ML::str html] \
        -underline 0 \
        -menu $w.menubar.card.export.html
    menu $w.menubar.card.export.html -tearoff 0
    foreach htmlMode $superView(htmlModeList) {
        $w.menubar.card.export.html add command \
            -label $superView(htmlModeName,$htmlMode) \
           -command "ViewCard::ExportHTML $w $htmlMode"
    }
    $w.menubar.card.export add command \
        -label [ML::str txt] \
        -underline 0 \
        -command "ViewCard::Export $w txt"
    $w.menubar.card.export add command \
        -label [ML::str rtf] \
        -underline 0 \
        -command "ViewCard::Export $w rtf"
    $w.menubar.card.export add command \
        -label [ML::str cv,flatFile] \
        -underline 0 \
        -command "ViewCard::Export $w tdb"

    $w.menubar.card add separator
    if {$CrossFire::platform == "windows"} {
        $w.menubar.card add command \
            -label [ML::str cv,copyCardText] \
            -underline 0 \
            -accelerator "$CrossFire::accelKey+C" \
            -command "ViewCard::CopyText $w"       
        bind $w <$CrossFire::accelBind-C> "ViewCard::CopyText $w"
    }
    $w.menubar.card add command \
        -label [ML::str cv,viewInNew] \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+V" \
        -command "ViewCard::NewCardView $w"

    $w.menubar.card add separator
    $w.menubar.card add command \
        -label "[ML::str configure]..." \
        -underline 1 \
        -accelerator "$CrossFire::accelKey+O" \
        -command "Config::Create Viewing Cards"

    set exitLabel [ML::str close]
    set exitAccelerator "Alt+F4"
    if {$CrossFire::platform == "macintosh"} {
        # This is a Macintosh, so make the exit
        # accelerator more "Mac-ish"
        set exitLabel [ML::str quit]
        set exitAccelerator "Command+Q"
    }
    $w.menubar.card add separator
    $w.menubar.card add command \
        -label $exitLabel \
        -underline 0 \
        -accelerator $exitAccelerator \
        -command "ViewCard::ExitViewer $w"

    $w.menubar add cascade \
        -label [ML::str help] \
        -underline 0 \
        -menu $w.menubar.help

    menu $w.menubar.help -tearoff 0
    $w.menubar.help add command \
        -label "[ML::str help]..." \
        -underline 0 \
        -accelerator "F1" \
        -state disabled \
        -command "CrossFire::OpenURL cv_main.html"
    $w.menubar.help add separator
    $w.menubar.help add command \
        -label "[ML::str cv,about]..." \
        -underline 0 \
        -command "ViewCard::About $w"

    $w config -menu $w.menubar

    bind $w <$CrossFire::accelBind-o> "Config::Create Viewing Cards"

    if {$CrossFire::platform == "macintosh"} {
        bind $w <Command-q> "ViewCard::ExitViewer $w"
    } else {
        bind $w <Meta-x> "ViewCard::ExitViewer $w"
        bind $w <Alt-F4> "ViewCard::ExitViewer $w; break"
    }

    return
}

# ViewCard::ExitViewer --
#
#   Unregisters the toplevel and removes it.
#
# Parameters:
#   w         : Widget name of the card view.
#
# Returns:
#   Nothing.
#
proc ViewCard::ExitViewer {w} {

    variable superView

    CrossFire::UnRegister CardViewer $w
    CleanUpCardViews $w

    foreach key [array names superView "$w,*"] {
        unset superView($key)
    }

    destroy $w

    return
}

# ViewCard::RemoveCardView --
#
#   Removes a custom card pic for a card if it exists.
#
# Parameters:
#   w         : Widget name of the card view.
#
# Returns:
#   Nothing.
#
proc ViewCard::RemoveCardView {w} {

    set imageName cardPic$w
    if {[lsearch [image names] $imageName] != -1} {
        image delete $imageName
    }

    return
}

# ViewCard::NewCardView --
#
#   Creates a new card view of the selected card.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc ViewCard::NewCardView {w} {

    variable superView

    set cardID [GetSelectedCardID $w]

    if {$cardID != ""} {
        View $w $cardID
    }

    return
}

# ViewCard::About --
#
#   Displays an about dialog for the CrossFire Card Viewer.
#
# Paramters:
#   w         : Parent toplevel for the pop-up dialog.
#
# Returns:
#   Nothing.
#
proc ViewCard::About {w} {
    set message "CrossFire [ML::str cv,windowName]\n"
    append message "\n[ML::str by] Dan Curtiss"
    tk_messageBox -icon info -parent $w -message $message \
        -title [ML::str cv,about]

    return
}

# ViewCard::CopyText --
#
#   Copies the card text to the clipboard. This is not needed for Unix
#   because the regular way of selecting text works.  It does not work,
#   however, on Windows when the text widget is diabled...this appears
#   to be a bug in Tcl/Tk.  Lots of problems with the text widget and
#   selection.
#
#   Update 10/10/2003.  Ctrl+C appears to work with ActiveState Tcl.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc ViewCard::CopyText {w} {

    variable view
    variable superView

    set cfw $superView($w,cardView)
    set cardText [string trimright [$view($cfw,text) get 1.0 end] "\n"]
    clipboard clear
    clipboard append -- $cardText

    return
}

# ViewCard::ClickListBox --
#
#   Moves the highlight bar to the line clicked or requested
#   with a move command.
#
# Parameters:
#   w          : Toplevel of the viewer.
#   X Y        : X and Y coordinates of the click (%X %Y)
#              : -or- m line for move to line.
#   btnNum     : Button number that was pushed.
#
# Returns:
#   Nothing.
#
proc ViewCard::ClickListBox {w X Y btnNum} {

    variable superView

    set lbw $superView($w,lbw)
    CrossFire::ClickListBox $w $lbw $X $Y

    set tempID [GetSelectedCardID $w]
    if {$tempID != ""} {
        UpdateCardView $superView($w,cardView) \
            [CrossFire::GetCard $tempID]
        if {$btnNum == 3} {
            View $w $tempID
        }
    }

    return
}

# ViewCard::GetSelectedCardID --
#
#   Returns the ID of the selected card.
#
# Parameters:
#   None.
#
# Returns:
#   The short ID.
#
proc ViewCard::GetSelectedCardID {w} {

    variable superView

    set lbw $superView($w,lbw)
    set index [$lbw curselection]

    if {$index != ""} {
        set cardID [lindex [$lbw get [$lbw curselection]] 0]
    } else {
        set cardID ""
    }

    return $cardID
}

# ViewCard::UpdateSelection --
#
#   Updates the card selection box.
#
# Parameters:
#   w
#   from
#   setID(s)
#
# Returns:
#   Nothing.
#
proc ViewCard::UpdateSelection {w from args} {

    variable superView

    $w configure -cursor watch
    update

    if {($from == "menu") || ($from == "init")} {
        # Changed the menubutton on regular mode or initializing.
        set setID $superView($w,setID)
        set superView($w,cardSetName) $CrossFire::setXRef($setID,name)
        set superView($w,listOfIDs) $setID
        if {$from == "init"} {
            CrossFire::ClickCardSetSelection $superView($w,cardSetSel) \
                "m" $setID
        }
    } elseif {$from == "type"} {
        # Just use the preset list of IDs and the new type ID.
    } elseif {$from == "setList"} {
        # Clicked on the set list
        set superView($w,listOfIDs) $args
    }

    if {$superView($w,listOfIDs) == "All"} {
        set superView($w,listOfIDs) $Config::config(ViewCard,setIDList)
    }

    set typeID $superView($w,typeID)
    set superView($w,cardTypeName) $CrossFire::cardTypeXRef($typeID,name)

    $superView($w,lbw) delete 0 end
    foreach setID [CrossFire::CardSetIDList "allPlain"] { 
        if {[lsearch $superView($w,listOfIDs) $setID] != -1} {
            CrossFire::ReadCardDataBase $setID
            CrossFire::CardSetToListBox $CrossFire::cardDataBase \
                $superView($w,lbw) $typeID "append"
        }
    }

    ClickListBox $w m 0 0
    $w configure -cursor {}

    return
}

# ViewCard::Export --
#
#   Exports the selected card set to formats easily read by other
#   programs.  Note that csv *IS* generated properly, but M$ Excel
#   seems to think it knows more than me and promptly screws up the
#   bonus/level field. ex: +4 becomes 4, 5/7 becomes 5/7/<year> !
#
# Parameters:
#   format     : The format to generate. (csv,txt,rtf)
#
# Returns:
#   Nothing.
#
proc ViewCard::Export {w format args} {

    variable superView

    if {[lsearch $superView($w,listOfIDs) "All"] != -1} {
	set fname "All_Card_Sets"
    } else {
	set fname [CrossFire::GetIDListName $superView($w,listOfIDs)]
    }

    set fileName \
        [tk_getSaveFile -title [ML::str saveAs] \
             -initialfile "${fname}.$format" \
             -initialdir $Config::config(Warehouse,reportDir)]

    if {$fileName == ""} {
        return
    }

    $w configure -cursor watch
    update

    set fid [open $fileName "w"]

    # Print a file header
    set header [FormatHeader $format]
    if {$header != ""} {
        puts $fid $header
    }

    foreach setID $superView($w,listOfIDs) {

        CrossFire::ReadCardDataBase $setID

        # Print a set header
        set setHeader [FormatSetHeader $format $setID]
        if {$setHeader != ""} {
            puts $fid $setHeader
        }

        foreach card [lrange $CrossFire::cardDataBase 1 end] {
            puts $fid [FormatCard $format $card]
        }

	if {$format == "rtf"} {
	    puts $fid "\\par\\pard\\plain\\f3\\fs20 \n"
	}
    }

    # Print, of course, a file footer!
    set footer [ML::str cv,genMessage]
    if {$footer != ""} {
	if {$format == "rtf"} {
	    puts $fid "\\par\\pard\\plain\\f3\\fs20 $footer\n"
	} else {
	    puts $fid $footer
	}
    }

    if {$format == "rtf"} {
	puts $fid "\\par \}\n"
    }

    close $fid

    $w configure -cursor {}

    return
}

# ViewCard::FormatHeader --
#
#   Returns a file header for the specified format.
#
# Parameters:
#   format     : The format to generate. (csv,txt,rtf)
#
# Returns:
#   The formated string (if any).
#
proc ViewCard::FormatHeader {format} {

    switch $format {
        "csv" {
            set header "[ML::str set],[ML::str number],"
	    append header "[ML::str name],[ML::str type],"
	    append header "[ML::str level],[ML::str world],[ML::str rarity],"
            append header "[ML::str text],[ML::str blueline],"
	    append header "[ML::str attributes],[ML::str usableCards]"
        }
        "rtf" {
	    set header ""
	    append header "\{\\rtf1\\ansi\\deff0\\deftab720" \
		"\{\\fonttbl\{\\f0\\fnil MS Sans Serif;\}" \
		"\{\\f1\\fnil\\fcharset2 Symbol;\}" \
		"\{\\f2\\fswiss\\fprq2 System;\}" \
		"\{\\f3\\fnil Times New Roman;\}\}\n" \
		"\{\\colortbl \\red0\\green0\\blue0;"
	    foreach colorName {blueLine attribute usable} {
		set color $Config::config(ViewCard,color,$colorName)
		set red   [expr 0x[string range $color 1 2]]
		set green [expr 0x[string range $color 3 4]]
		set blue  [expr 0x[string range $color 5 6]]
		append header "\\red$red\\green$green\\blue$blue;"
	    }
	    append header "\}\\deflang1033\n"
	}
        default {
            set header ""
        }
    }

    return $header
}

# ViewCard::FormatSetHeader --
#
#   Formats the set name in the requested format.
#
# Parameters:
#   format     : The format to generate. (csv,txt,rtf)
#   setID      : The set ID.
#
# Returns:
#   The formated string (if any).
#
proc ViewCard::FormatSetHeader {format setID} {

    set setName $CrossFire::setXRef($setID,name)

    switch $format {
        "txt" {
            set out "$setName\n"
        }
        "rtf" {
	    set out "\\pard\\plain\\f3\\fs28 $setName\n"
	    append out "\\par \\pard\\plain\\f3\\fs20 \n"
        }
        "tdb" {
            set out "Set: $setName\n"
        }
        default {
            set out ""
        }
    }

    return $out
}

# ViewCard::FormatCard --
#
#   Formats a card in the requested format.
#
# Parameters:
#   format     : The format to generate. (csv,txt,rtf)
#   card       : A card in standard format
#
# Returns:
#   The formated string.
#
proc ViewCard::FormatCard {format card} {

    variable superView

    foreach {
        cardSetID rawCardNumber bonus cardTypeNumber worldID isAvatar
        name cardText rarity blueLine attrList usesList weight
    } $card break

    # Convert the attribute IDs to names
    set attrNew {}
    foreach id $attrList {
        if {[info exists CrossFire::cardAttributes(attr,$id)]} {
            lappend attrNew $CrossFire::cardAttributes(attr,$id)
        } else {
            lappend attrNew $id
        }
    }
    set attrList $attrNew

    # Convert the uses IDs to names
    set usesNew {}
    foreach id $usesList {
        if {[info exists CrossFire::usableCards(uses,$id)]} {
            lappend usesNew $CrossFire::usableCards(uses,$id)
        } else {
            lappend usesNew $id
        }
    }
    set usesList $usesNew

    set cardSet $CrossFire::setXRef($cardSetID,name)
    foreach {cardID cardNumber setMax} \
        [CrossFire::GetCardID $cardSetID $rawCardNumber] break
    foreach {setID formatedNumber} [split $cardID "/"] break

    set world $CrossFire::worldXRef($worldID,name)
    if {$world == "None"} {
        set world "AD&D"
    }
    set type $CrossFire::cardTypeXRef($cardTypeNumber,name)

    if {$attrList != ""} {
        set attributes "[FormatAttributeList $attrList]."
    } else {
        set attributes ""
    }

    set usable ""
    foreach uses $usesList {
        if {$usable != ""} {
            append usable "; "
        }
        append usable $uses
    }
    if {$usable != ""} {
        append usable "."
    }

    switch $format {
        "csv" {
            regsub -all "\"" $cardText "'" cardText
            regsub -all "\"" $name "'" name
            set out "$setID,$cardNumber,\"$name\",$type,$bonus,$world,"
            append out "$rarity,\"$cardText\",\"$blueLine\","
            append out "\"$attributes\",\"$usable\""
        }
        "txt" {
            set allText $cardText
            if {$name == "(no card)"} {
                set out "$cardID $name\n"
            } else {
                set out "$cardID $name, $type $bonus\n"
                append out "    $world - $CrossFire::cardFreqName($rarity)\n"
                if {($blueLine != "") &&
                    ($Config::config(ViewCard,showBluelines) == "Yes")} {
                    append allText " $blueLine "
                }
                if {($attributes != "") &&
                    ($Config::config(ViewCard,showAttributes) == "Yes")} {
                    append allText " $attributes "
                }
                if {($usable != "") &&
                    ($Config::config(ViewCard,showUsable) == "Yes")} {
                    append allText " Uses: $usable"
                }
            }
            if {$allText != ""} {
                append out [CrossFire::SplitLine 80 $allText 4]
            }
            append out "\n"
        }
        "rtf" {
            set allText $cardText
	    set out {}
            if {$name == "(no card)"} {
                set out "\\par\\pard\\plain\\f3\\fs24 $cardID $name\n"
            } else {
                append out "\\par\\pard\\plain\\f3\\fs24 $cardID " \
		    "$name, $type $bonus\n" \
		    "\\par\\pard\\plain\\f3\\fs20\\tab $world" \
		    " - $CrossFire::cardFreqName($rarity)\n"
                if {($blueLine != "") &&
                    ($Config::config(ViewCard,showBluelines) == "Yes")} {
                    append allText " \\cf1 $blueLine\\cf0 "
                }
                if {($attributes != "") &&
                    ($Config::config(ViewCard,showAttributes) == "Yes")} {
                    append allText " \\cf2 $attributes\\cf0 "
                }
                if {($usable != "") &&
                    ($Config::config(ViewCard,showUsable) == "Yes")} {
                    append allText " \\cf3 Uses: $usable\\cf0 "
                }
            }
            if {$allText != ""} {
		append out "\\par\\pard\\plain\\f3\\fs20\\ri720\\li720 $allText\n"
            }
	    append out "\\par\\pard\\plain\\f3\\fs20 \n"
        }
        "tdb" {
            if {$name == "(no card)"} {
                set type ""
                set world ""
                set rarity ""
            }
            set out "ID: $cardID $cardSetID $rawCardNumber\n"
            append out "Name: $name\nType: $type\nBonus: $bonus\n"
            append out "World: $world\nRarity: $rarity\n"
            append out "Text: $cardText\nBlueline: $blueLine\n"
            append out "Attribute: $attributes\nUsable: $usable\n"
        }
        default {
            # All of the HTML modes
	    if {$Config::config(ViewCard,showBluelines) == "No"} {
		set blueLine {}
	    }
	    if {$Config::config(ViewCard,showAttributes) == "No"} {
		set attributes {}
	    }
	    if {($Config::config(ViewCard,showUsable) == "Yes") &&
		($usable != "")} {
		set usable "Uses: $usable"
	    } else {
		set usable {}
	    }
            set out [subst $superView(htmlMode,$format,html)]
        }
    }

    return $out
}

# ViewCard::ExportHTML --
#
#   Generates HTML tables of the card database.
#
# Parameters:
#   w          : Card viewer toplevel.
#   mode       : HTML mode to create
#
# Returns:
#   Nothing.
#
proc ViewCard::ExportHTML {w mode} {

    variable superView

    if {[lsearch $superView($w,listOfIDs) "All"] != -1} {
	set fname "All_Card_Sets"
    } else {
	set fname [CrossFire::GetIDListName $superView($w,listOfIDs)]
    }

    set fileName \
        [tk_getSaveFile -title [ML::str saveAs] \
             -initialfile "${fname}.html" \
             -initialdir $Config::config(Warehouse,reportDir)]

    if {$fileName == ""} {
        return
    }

    $w configure -cursor watch
    update

    set makeIndex $Config::config(Print,makeIndex)
    set numPerPage $Config::config(Print,numPerPage)

    if {$makeIndex == "Yes"} {

        set indexFID [open $fileName "w"]
        set indexDir [file dirname $fileName]

        puts $indexFID "<HTML>\n<HEAD>\n<TITLE>$fname</TITLE>\n</HEAD>\n<BODY>"

        foreach setID $superView($w,listOfIDs) {

	    if {$setID == "All"} continue

            set count 0
            set limit 0
            set cardSet $CrossFire::setXRef($setID,name)
            set setMax $CrossFire::setXRef($setID,setMax)

            puts $indexFID "<H3>$cardSet</H3>\n<UL>"

            CrossFire::ReadCardDataBase $setID
            foreach card [lrange $CrossFire::cardDataBase 1 end] {
                incr count
                if {$count > $limit} {
                    if {$limit != 0} {
                        puts $fid [subst $superView(htmlMode,$mode,pageTail)]
                        puts $fid "</BODY>\n</HTML>"
                        close $fid
                    }
                    incr limit $numPerPage
                    if {$limit > $CrossFire::setXRef($setID,lastNumber)} {
                        set limit $CrossFire::setXRef($setID,lastNumber)
                    }
                    set fname $setID$count-$limit.html
                    if {$count > $setMax} {
                        set lo [expr $count - $setMax]
                        set high [expr $limit - $setMax]
                        set link "[ML::str chaseCards] $lo - $high"
                    } else {
                        set link "[ML::str cards] $count - $limit"
                    }
                    puts $indexFID "<LI><A HREF=\"$fname\">$link</A>"
                    set fid [open [file join $indexDir $fname] "w"]
                    puts $fid "<HTML>\n<HEAD>"
                    puts $fid "<TITLE>$cardSet $link</TITLE>\n</HEAD>\n<BODY>"
                    puts $fid "<H3 ALIGN=CENTER>$cardSet $link</H3>\n<HR><BR>"
                    puts $fid [subst $superView(htmlMode,$mode,pageHead)]
                }

                puts $fid [FormatCard $mode $card]
            }
            close $fid

            puts $indexFID "</UL>"
        }

        puts $indexFID "</BODY>\n</HTML>"
        close $indexFID

    } else {
        # Just write out one big HTML page
        set fid [open $fileName "w"]
        puts $fid "<HTML>\n<HEAD>\n<TITLE>$fname</TITLE>\n</HEAD>"
        foreach setID $superView($w,listOfIDs) {
            CrossFire::ReadCardDataBase $setID
            puts $fid [subst $superView(htmlMode,$mode,pageHead)]
            foreach card [lrange $CrossFire::cardDataBase 1 end] {
                puts $fid [FormatCard $mode $card]
            }
            puts $fid [subst $superView(htmlMode,$mode,pageTail)]
        }
        puts $fid "</BODY>\n</HTML>"
        close $fid
    }

    $w configure -cursor {}

    return
}

# ViewCard::CreateRightClick --
#
#   Creates a right click menu with options for copying various information
#   to the clipboard or linking the Yogiland (if appropraite)
#
# Parameters:
#   fw        : Frame widget path
#   cardID    : The card ID
#   X, Y      : Screen location for the click
#
# Returns:
#   Nothing.
#
proc ViewCard::CreateRightClick {fw cardID X Y} {

    set card [CrossFire::GetCard $cardID]
    foreach {
        setID cardNum bonus cardTypeNumber worldID isAvatar
        name cardText rarity blueLine attrList usesList weight
    } $card break

    # Create popup menu
    if {[winfo exists $fw.menu]} {
        destroy $fw.menu
    }

    set m [menu $fw.menu -tearoff 0]
    $m add command -label "Copy Card Title to Clipboard" \
        -command "CrossFire::SetClipboard \{$cardID $name\}"

    set bbc [Print::Card $fw $card -mode bbc]
    $m add command -label "Copy Card as BBCode" \
        -command "CrossFire::SetClipboard \{$bbc\}"
    $m add command -label "View Official Spellfire Guide" \
        -command ""

    if {[lsearch $CrossFire::yogiSets $setID] != -1} {
        $m entryconfigure end -state normal \
            -command [CrossFire::CreateYogilandCommand $setID $cardNum]
    } else {
        $m entryconfigure end -state disabled
    }

    tk_popup $m $X $Y

    return
}
