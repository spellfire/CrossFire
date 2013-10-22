# ComboVue.tcl 20040715
#
# This file contains all the procedures for the Combo viewer.
#
# Copyright (c) 1999-2004 Dan Curtiss. All rights reserved.
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

namespace eval Combo {

    variable viewerWindowTitle "Combo Viewer"

}

# Combo::Viewer --
#
#   Incrementally creates a new Combo Viewer toplevel.  Data is stored such
#   that the Combo namespace thinks this is a ComboMan window.  Therefore,
#   printing, card viewing can be done from the currently displayed Combo.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Combo::Viewer {} {

    variable storage
    variable viewerWindowTitle

    set w .comboView

    if {[winfo exists $w]} {
        wm deiconify $w
        raise $w
        return
    }

    toplevel $w
    wm title $w $viewerWindowTitle
    wm protocol $w WM_DELETE_WINDOW "Combo::ExitComboViewer $w"
    wm withdraw $w

    AddViewerMenuBar $w

    set storage($w,comboTextBox) $w.comboText.comboText.t
    set storage($w,comboListBox) $w.comboSelect.comboList.lb
    set storage($w,selectListBox) $w.comboCards.cardList.lb
    set storage($w,comboDir) $Config::config(ComboMan,dir)
    set storage($w,combo) ""
    set storage($w,embedCardView) $Config::config(ComboMan,embedCardViewV)
    set storage($w,cardFrame) ""

    # Combo Selection
    set fw $w.comboSelect
    frame $fw

    label $fw.selLabel -text "Combo Selection:" -anchor w

    frame $fw.comboList
    listbox $fw.comboList.lb -selectmode single -width 30 -height 20 \
        -exportselection 0 -background white -foreground black \
        -selectbackground blue -selectforeground white -selectborderwidth 0 \
        -yscrollcommand "CrossFire::SetScrollBar $fw.comboList.sb"
    scrollbar $fw.comboList.sb -command "$fw.comboList.lb yview"
    foreach btn "1 2 3" {
        bind $fw.comboList.lb <Button-$btn> \
            "Combo::ClickComboListBox $w %X %Y $btn combo"
    }
    grid $fw.comboList.lb -sticky nsew
    grid columnconfigure $fw.comboList 0 -weight 1
    grid rowconfigure $fw.comboList 0 -weight 1

    grid $fw.selLabel  -sticky w
    grid $fw.comboList -sticky nsew
    grid columnconfigure $fw 0 -weight 1
    grid rowconfigure $fw 1 -weight 1

    # Name and Email address
    set fw $w.info
    frame $fw

    label $fw.lname -width 7 -anchor w -text "Name:"
    label $fw.name -background white -foreground black -anchor w \
        -textvariable Combo::storage($w,authorName)
    label $fw.lemail -width 7 -anchor w -text "Email:"
    label $fw.email -background white -foreground black -anchor w \
        -textvariable Combo::storage($w,authorEmail)
    grid $fw.lname $fw.name -sticky ew -pady 3
    grid $fw.lemail $fw.email -sticky ew -pady 3
    grid columnconfigure $fw 1 -weight 1

    # List of cards
    set fw $w.comboCards
    frame $fw

    label $fw.cardLabel -text "Cards:" -anchor w

    frame $fw.cardList
    listbox $fw.cardList.lb -selectmode single -width 30 -height 4 \
        -exportselection 0 -background white -foreground black \
        -selectbackground blue -selectforeground white -selectborderwidth 0 \
        -yscrollcommand "CrossFire::SetScrollBar $fw.cardList.sb"
    scrollbar $fw.cardList.sb -command "$fw.cardList.lb yview"
    foreach btn "1 2 3" {
        bind $fw.cardList.lb <Button-$btn> \
            "Combo::ClickComboListBox $w %X %Y $btn select"
    }
    grid $fw.cardList.lb -sticky nsew
    grid columnconfigure $fw.cardList 0 -weight 1
    grid rowconfigure $fw.cardList 0 -weight 1

    grid $fw.cardLabel -sticky w
    grid $fw.cardList -sticky nsew
    grid columnconfigure $fw 0 -weight 1
    grid rowconfigure $fw 1 -weight 1

    # Combo Text
    set fw $w.comboText
    frame $fw

    label $fw.textLabel -text "Instructions:" -anchor w

    frame $fw.comboText
    text $fw.comboText.t -exportselection 0 -width 10 -height 1 -spacing1 2 \
        -wrap word -background white -foreground black -state disabled \
        -yscrollcommand "CrossFire::SetScrollBar $fw.comboText.sb" -cursor {}
    scrollbar $fw.comboText.sb -command "$fw.comboText.t yview"
    grid $fw.comboText.t -sticky nsew
    grid columnconfigure $fw.comboText 0 -weight 1
    grid rowconfigure $fw.comboText 0 -weight 1

    grid $fw.textLabel  -sticky w
    grid $fw.comboText -sticky nsew
    grid columnconfigure $fw 0 -weight 1
    grid rowconfigure $fw 1 -weight 1

    # Optional embedded card viewer
    if {$storage($w,embedCardView) == "Yes"} {
	frame $w.cardView
	set storage($w,cardFrame) [ViewCard::CreateCardView $w.cardView.cv]
	grid $w.cardView.cv -sticky nsew -padx 5 -pady 5
	grid rowconfigure $w.cardView 0 -weight 1
	grid columnconfigure $w.cardView 0 -weight 1
	grid $w.cardView -column 3 -row 0 -sticky nsew -rowspan 3
	grid columnconfigure $w 3 -weight 2
    }

    grid $w.comboSelect -row 0 -column 0 -sticky nsew -padx 5 -pady 5 \
        -rowspan 3
    grid $w.info        -row 0 -column 1 -sticky ew   -padx 5 -pady 5
    grid $w.comboCards  -row 1 -column 1 -sticky nsew -padx 5
    grid $w.comboText   -row 2 -column 1 -sticky nsew -padx 5 -pady 5
    grid rowconfigure $w {2} -weight 1
    grid columnconfigure $w {0 1} -weight 1

    wm deiconify $w
    raise $w
    update

    if {$CrossFire::platform == "windows"} {
        focus $w
    }

    GetComboList $w

    return
}

# Combo::AddViewerMenuBar --
#
#   Adds a menubar to the viewer.
#
# Parameters:
#   w          : Viewer toplevel.
#
# Returns:
#   Nothing.
#
proc Combo::AddViewerMenuBar {w} {

    menu $w.menubar

    $w.menubar add cascade \
        -label "Combo" \
        -underline 0 \
        -menu $w.menubar.combo
    menu $w.menubar.combo -tearoff 0

    $w.menubar.combo add command \
        -label "Change Directory..." \
        -underline 7 \
        -accelerator "$CrossFire::accelKey+D" \
        -command "Combo::ChangeComboDir $w"
    $w.menubar.combo add separator
    $w.menubar.combo add command \
        -label "Print..." \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+P" \
        -command "Combo::PrintCombo $w"
    $w.menubar.combo add separator

    set exitLabel "Close"
    set exitAccelerator "Alt+F4"
    if {$CrossFire::platform == "macintosh"} {
        # This is a Macintosh, so make the exit
        # accelerator more "Mac-ish"
        set exitLabel "Quit"
        set exitAccelerator "Command+Q"
    }
    $w.menubar.combo add command \
        -label $exitLabel \
        -underline 1 \
        -accelerator $exitAccelerator \
        -command "Combo::ExitComboViewer $w"

    $w.menubar add cascade \
        -label "Card" \
        -underline 0 \
        -menu $w.menubar.card
    menu $w.menubar.card -tearoff 0

    $w.menubar.card add command \
        -label "View" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+V" \
        -command "Combo::ViewCard $w"

    $w.menubar add cascade \
        -label "Help" \
        -underline 0 \
        -menu $w.menubar.help
    menu $w.menubar.help -tearoff 0

    $w.menubar.help add command \
        -label "Help..." \
        -underline 0 \
        -accelerator "F1" \
        -command "CrossFire::Help cm_viewer.html"
    $w.menubar.help add separator
    $w.menubar.help add command \
        -label "About Combo Viewer..." \
        -underline 0 \
        -command "Combo::AboutViewer $w"

    $w config -menu $w.menubar

    # Combo menu bindings.
    bind $w <$CrossFire::accelBind-p> "Combo::PrintCombo $w"

    if {$CrossFire::platform == "macintosh"} {
        bind $w <Command-q> "Combo::ExitComboViewer $w"
    } else {
        bind $w <Meta-x> "Combo::ExitComboViewer $w"
        bind $w <Alt-F4> "Combo::ExitComboViewer $w; break"
    }

    # Card menu bindings.
    bind $w <$CrossFire::accelBind-v> "Combo::ViewCard $w"
    bind $w <$CrossFire::accelBind-d> "Combo::ChangeComboDir $w"

    # Help menu bindings.
    bind $w <Key-F1> "CrossFire::Help cm_viewer.html"
    bind $w <Key-Help> "CrossFire::Help cm_viewer.html"

    # menu for right click on card list
    menu $w.viewMenu -tearoff 0
    $w.viewMenu add command -label " View" \
        -command "Combo::ViewCard $w"

    return
}

# Combo::ExitComboViewer --
#
#
# Parameters:
#   w          : Combo viewer toplevel.
#
# Returns:
#   Nothing.
#
proc Combo::ExitComboViewer {w} {

    ViewCard::CleanUpCardViews $w
    destroy $w

    return
}

# Combo::ChangeComboDir --
#
proc Combo::ChangeComboDir {w} {

    variable storage

    set curDir $storage($w,comboDir)
    set topLabel "Select Combo Directory"
    set newDir [tk_chooseDirectory -title $topLabel -mustexist 1 \
                    -initialdir $curDir]

    if {$newDir != ""} {
        set storage($w,comboDir) $newDir
        GetComboList $w
    }

    return
}

# Combo::GetComboList --
#
#   Rebuilds the list of Combos in the combo directory.
#
# Parameters:
#   w          : Viewer toplevel.
#
# Returns:
#   Nothing.
#
proc Combo::GetComboList {w} {

    variable storage
    variable comboFile

    # Clear the combo viewer's display.
    set lbw $storage($w,comboListBox)
    $lbw delete 0 end
    set tbw $storage($w,comboTextBox)
    $tbw configure -state normal
    $tbw delete 1.0 end
    $tbw configure -state disabled
    $storage($w,selectListBox) delete 0 end
    set storage($w,comboTitle) ""
    set storage($w,authorName) ""
    set storage($w,authorEmail) ""

    # Clear the crossreference table.
    foreach index [array names comboFile] {
        unset comboFile($index)
    }

    set filePattern [file join $storage($w,comboDir) "*.cfc"]
    foreach fileName [glob -nocomplain $filePattern] {
        if {[Combo::ReadCombo $w $fileName] == 1} {
            set tempComboTitle [CrossFire::GetSafeVar tempComboTitle]
            set comboFile($tempComboTitle) $fileName
            $lbw insert end $tempComboTitle
        }
    }

    ClickComboListBox $w m 0 0 combo

    return
}

# Combo::ClickComboListBox --
#
#   Updates the displyed combo.
#
# Parameters:
#   w          : Viewer toplevel.
#
# Returns:
#   Nothing.
#
proc Combo::ClickComboListBox {w X Y btn which} {

    variable comboFile
    variable storage
    variable viewerWindowTitle

    # Get and return the current selection's card ID.
    set storage($w,selectionAt) $which

    # Card selection list box.
    set lbw $storage($w,${which}ListBox)
    $storage($w,comboListBox) selection clear 0 end
    $storage($w,selectListBox) selection clear 0 end

    set lbw $storage($w,${which}ListBox)
    CrossFire::ClickListBox $w $lbw $X $Y

    if {[$lbw size] == 0} {
        return
    }

    if {$which == "select"} {

	set tempID [GetSelectedCardID $w]
	if {$storage($w,embedCardView) == "Yes"} {
	    ViewCard::UpdateCardView $storage($w,cardFrame) \
		[CrossFire::GetCard $tempID]
	} elseif {($Config::config(ViewCard,mode) == "Continuous") &&
		  ([$lbw size] != 0)} {
	    ViewCard::View $w $tempID
	}

        # Do various activities depending which button was pressed.
        switch -- $btn {
        1 { }
        2 {
            ViewCard $w
        }
        3 {
            tk_popup $w.viewMenu $X $Y
        }
    }

    } else {

        set comboTitle [$lbw get [$lbw curselection]]
        Combo::ReadCombo $w $comboFile($comboTitle)

        set storage($w,fileName) $comboFile($comboTitle)
        set storage($w,comboTitle) [GetComboInfo $w comboTitle]
        set storage($w,authorName) [GetComboInfo $w authorName]
        set storage($w,authorEmail) [GetComboInfo $w authorEmail]

        $storage($w,selectListBox) delete 0 end
        set storage($w,combo) [GetComboInfo $w combo]
        foreach card $storage($w,combo) {
            set cardDesc [CrossFire::GetCardDesc $card]
            $storage($w,selectListBox) insert end $cardDesc
        }

        set tbw $storage($w,comboTextBox)
        $tbw configure -state normal
        $tbw delete 1.0 end
        $tbw insert end [GetComboInfo $w comboText]
        $tbw configure -state disabled

        wm title $w "$viewerWindowTitle - $storage($w,comboTitle)"
    }

    return
}


# Combo::AboutViewer --
#
#   Displays an about dialog for the combo viewer.
#
# Paramters:
#   w         : Parent toplevel for the pop-up dialog.
#
# Returns:
#   Nothing.
#
proc Combo::AboutViewer {w} {
    set message "CrossFire Combo Viewer\n"
    append message "\nby Dan Curtiss"
    tk_messageBox -icon info -title "About Combo Viewer" \
        -parent $w -message $message
    return
}

