# TipOfDay.tcl 20030908
#
# This file contains the procedures for the Tip of the Day.
#
# Copyright (c) 1998-2003 Dan Curtiss. All rights reserved.
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

namespace eval Tip {

    variable tipConfig

    set tipConfig(showTips) "Yes"
    set tipConfig(toplevel) .topOfDay

    image create photo imgIdea -data {
R0lGODlhGQAjAPMAAAAAAGZmAGZmZpmZAP//AJmZZmZmmQD//5mZmcDAwMzMzP///wAAAAAA
AAAAAAAAACH5BAEAAAwAIf4jICBJbXBvcnRlZCBmcm9tIEdJRiBpbWFnZTogcHVrZS5naWYA
LAAAAAAZACMAAATmkMlJq7046zpCH9vlESTphdNALGvLBmiwLosAICwJbCpNA0AXYZcJ+H5A
Vo546R2BAOGAWZEdFwWAQWmiUgbKJ5c1xchI3CiXEPCm0MIxoYyJlmq3HNtNAZxZUC50GAgA
KiSFAiVtfBICBwt+cEpTCwd8CJCXhyVdml6PlpZ+nB4AmqMTp6KQhaSMAKypEquaAkgACgq1
sxKFqAg2C7pQrAACEwLBvDhQu8bBCMnLtjgKrp/KyBTRtVBAn9EX3Z/go9oZ2rzhyhvkxugh
6uzSKAzkx8H2E93x+47Rtv2bJnAgP4MIIwAAOw==
    }

    # Set up TOTDs for TOTD.
    set tipConfig(programName) "TOTD"
    set tipConfig(chapter) "!!!"
    set tipConfig(tipNumber,!!!) 1
    set tipConfig(lastTip,!!!) 3
    set tipConfig(tip,!!!,1) "TOTD was written by Dan Curtiss!"
    set tipConfig(tip,!!!,2) "You can have several 'chapters' of tips."
    set tipConfig(tip,!!!,3) "You should make a table of contents to use this!"
}

# Tip::InitTips --
#
#   Reads a table of contents file and calls ReadTips to read each TOTD file.
#
# Parameters:
#   tocFile    : TOTD table of contents file.
#
# Returns:
#   Nothing.
#
proc Tip::InitTips {tocFile} {

    variable tipConfig

    if {![file readable $tocFile]} {
        tk_messageBox -title "TOC Error!" -icon error \
            -message "Unable to read TOC $tocFile"
        return
    }

    set tipConfig(chapterList) {}
    set dir [file dirname $tocFile]
    set toc [open $tocFile "r"]
    foreach {cmd data} [read $toc] {
        switch $cmd {
            "Program" {
                set tipConfig(programName) $data
            }
            "ChapterFile" {
                ReadTips [file join $dir $data]
            }
            "Chapter" {
                set chapter $data
                if {![info exists tipConfig(lastTip,$chapter)]} {
                    set tipConfig(lastTip,$chapter) 0
                }
                lappend tipConfig(chapterList) $chapter
            }
            "Tip" {
                set count [incr tipConfig(lastTip,$chapter)]
                set tipConfig(tip,$chapter,$count) [string trim $data]
            }
        }
    }
    close $toc

    UpdateTip 1 [lindex $tipConfig(chapterList) 0]

    return
}

# Tip::ReadTips --
#
#   Reads a tip of the day file.
#
# Parameters:
#   totdFile   : Name of the TOTD file.
#
# Returns:
#   Nothing.
#
proc Tip::ReadTips {totdFile} {

    variable tipConfig

    if {![file readable $totdFile]} {
        puts stderr "Unable to read $totdFile"
        return
    }

    set totd [open $totdFile "r"]
    foreach {cmd data} [read $totd] {
        switch $cmd {
            "Chapter" {
                set chapter $data
                if {![info exists tipConfig(lastTip,$chapter)]} {
                    set tipConfig(lastTip,$chapter) 0
                }
                lappend tipConfig(chapterList) $chapter
            }
            "Tip" {
                set count [incr tipConfig(lastTip,$chapter)]
                set tipConfig(tip,$chapter,$count) [string trim $data]
            }
        }
    }
    close $totd

    return
}

# Tip::Create --
#
#   Creates the Tip of the Day toplevel.
#
# Parameters:
#   progName   : Name of the program.
#
# Returns:
#   Nothing.
#
proc Tip::Create {{progName ""} {chapter ""}} {

    variable tipConfig

    if {$chapter != ""} {
        set tipConfig(chapter) $chapter
    }

    if {$progName != ""} {
        set tipConfig(programName) $progName
    }

    set w $tipConfig(toplevel)
    if {[winfo exists $w]} {
        wm deiconify $w
        raise $w
        return
    }

    toplevel $w
    wm withdraw $w
    wm title $w "Welcome"
    wm resizable $w 0 0
    wm protocol $w WM_DELETE_WINDOW "$w.control.close invoke"

    frame $w.welcome
    label $w.welcome.l1 -text "Welcome to" -font {Times 14}
    label $w.welcome.l2 -textvariable Tip::tipConfig(programName) \
        -font {Times 14 bold italic}
    label $w.welcome.l3 -textvariable Tip::tipConfig(chapter) \
        -font {Times 14 bold italic}
    grid $w.welcome.l1 $w.welcome.l2 $w.welcome.l3
    grid $w.welcome -sticky w -padx 5 -pady 5 -columnspan 2

    frame $w.tip -relief sunken -borderwidth 2 -background white
    frame $w.tip.f -background white

    frame $w.tip.f.icon -background white
    label $w.tip.f.icon.l -image imgIdea -background white
    grid $w.tip.f.icon.l -sticky n -pady 5 -padx 5
    grid rowconfigure $w.tip.f.icon 0 -weight 1
    grid $w.tip.f.icon -row 0 -column 0 -rowspan 2 -sticky nsew

    frame $w.tip.f.q -background white
    label $w.tip.f.q.l -text "Did you know..." -background white \
        -foreground black -font {Times 12 bold}
    grid $w.tip.f.q.l -padx 5 -pady 5
    grid columnconfigure $w.tip.f.q 0 -weight 1
    grid $w.tip.f.q -row 0 -column 1 -sticky w

    frame $w.tip.f.text -background white
    text $w.tip.f.text.t -relief flat -borderwidth 0 -background white \
        -foreground black -height 8 -width 40 -wrap word -cursor {} \
        -highlightthickness 0 -font {Times 12} -state disabled
    set tipConfig(textBox) $w.tip.f.text.t
    grid $w.tip.f.text.t -sticky nsew -padx 5 -pady 5
    grid columnconfigure $w.tip.f.text 0 -weight 1
    grid rowconfigure $w.tip.f.text 0 -weight 1
    grid $w.tip.f.text -row 1 -column 1 -sticky nsew

    grid $w.tip.f -padx 10 -pady 10 -sticky nsew
    grid columnconfigure $w.tip.f 1 -weight 1
    grid rowconfigure $w.tip.f 1 -weight 1

    grid $w.tip -row 1 -column 0 -sticky nsew -padx 5
    grid columnconfigure $w.tip 0 -weight 1
    grid rowconfigure $w.tip 0 -weight 1

    frame $w.buttons
    button $w.buttons.prev -text "Previous Tip" -command "Tip::PreviousTip" \
        -state disabled
    set tipConfig(previousButton) $w.buttons.prev 
    button $w.buttons.next -text "Next Tip" -command "Tip::NextTip" \
        -state disabled
    set tipConfig(nextButton) $w.buttons.next
    frame $w.buttons.huh -borderwidth 1 -relief flat -background black
    grid $w.buttons.prev -sticky new
    grid $w.buttons.next -sticky new -pady 5
    grid $w.buttons.huh -sticky sew 
    grid columnconfigure $w.buttons 0 -weight 1
    grid rowconfigure $w.buttons {1 2} -weight 1
    grid $w.buttons -row 1 -column 1 -sticky nsew -padx 5

    checkbutton $w.show -variable Tip::tipConfig(showTips) \
        -text "Show the Tip of the Day" -anchor w \
        -onvalue "Yes" -offvalue "No" -highlightthickness 0
    button $w.close -text "Close" -command "Tip::CloseTOTD"
    grid $w.show $w.close -sticky ew -padx 5 -pady 5

    grid columnconfigure $w {0 1} -weight 1
    grid rowconfigure $w 1 -weight 1

    # Center tip window.
    update
    set x [expr ([winfo screenwidth .] - [winfo reqwidth $w]) / 2]
    set y [expr ([winfo screenheight .] - [winfo reqheight $w]) / 2]
    wm geometry $w +$x+$y
    wm deiconify $w

    UpdateTip

    return
}

# Tip::PreviousTip --
#
#   Displays the previous tip if applicable.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Tip::PreviousTip {} {

    variable tipConfig

    set chapter $tipConfig(chapter)
    if {$tipConfig(tipNumber,$chapter) > 1} {
        incr tipConfig(tipNumber,$chapter) -1
        UpdateTip
    }

    return
}

# Tip::NextTip --
#
#   Displays the next tip if applicable.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Tip::NextTip {} {

    variable tipConfig

    set chapter $tipConfig(chapter)
    if {$tipConfig(tipNumber,$chapter) < $tipConfig(lastTip,$chapter)} {
        incr tipConfig(tipNumber,$chapter)
        UpdateTip
    }

    return
}

# Tip::UpdateTip --
#
#   Updates the displayed tip and the previous/next buttons.
#
# Parameters:
#   num        : Option tip to jump to.
#
# Returns:
#   Nothing.
#
proc Tip::UpdateTip {{num 0} {chapter ""}} {

    variable tipConfig

    if {$chapter != ""} {
        set tipConfig(chapter) $chapter
    } else {
        set chapter $tipConfig(chapter)
    }

    if {$num != 0} {
        set tipConfig(tipNumber,$chapter) $num
    }

    if {![winfo exists $tipConfig(toplevel)]} {
        return
    }

    $tipConfig(textBox) configure -state normal
    $tipConfig(textBox) delete 1.0 end
    $tipConfig(textBox) insert end \
        $tipConfig(tip,$chapter,$tipConfig(tipNumber,$chapter))
    $tipConfig(textBox) configure -state disabled

    # Dis/Enable the next button.
    if {$tipConfig(tipNumber,$chapter) == $tipConfig(lastTip,$chapter)} {
        $tipConfig(nextButton) configure -state disabled
    } else {
        $tipConfig(nextButton) configure -state normal
    }

    # Dis/Enable the previous button.
    if {$tipConfig(tipNumber,$chapter) == 1} {
        $tipConfig(previousButton) configure -state disabled
    } else {
        $tipConfig(previousButton) configure -state normal
    }

}

# Tip::CloseTOTD --
#
#   Closes the tip of the day window.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Tip::CloseTOTD {} {
    variable tipConfig
    destroy $tipConfig(toplevel)
    return
}

