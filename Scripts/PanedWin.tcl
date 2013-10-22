# MultiPane.tcl 20051123
#
# This file provides procedures to implement paned windows.
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

namespace eval PanedWindow {

    variable  pwInfo

    set pwInfo(min) 0.05
}

# PanedWindow::Create --
#
#   Creates the frames for the "panes".
#
# Parameters:
#   win         : Widget path for container frame.
#   args        : Various options
#
# Returns:
#   The container frame widget.
#
proc PanedWindow::Create {win args} {

    variable pwInfo

    # For orientation, "v" (vertical) means the panes are stacked
    # vertically, and "h" (horizontal) for side-by-side panes.
    set orient   v
    set width    2i
    set height   2i
    set grip     y
    set live     1
    set numPanes 2

    # CrossFire specific code here
    set live $Config::config(CrossFire,autoResize)
    set grip $Config::config(CrossFire,showGrip)

    foreach {arg value} $args {
        switch -regexp -- $arg {
            "^-w" { set width $value }
            "^-h" { set height $value }
            "^-l" { set live $value }
            "^-o" { set orient [string tolower [string range $value 0 0]] }
            "^-g" { set grip [string tolower [string range $value 0 0]] }
            "^-s" { set sashLoc $value }
            "^-n" { set numPanes $value }
        }
    }

    set pwInfo($win,orient) $orient
    set pwInfo($win,grip) $grip
    set pwInfo($win,update) $live
    set pwInfo($win,num) $numPanes

    set fraction [expr 1.0 / $numPanes]
    if {![info exists sashLoc]} {
        set sashLoc {}
        for {set i 1} {$i < $numPanes} {incr i} {
            lappend sashLoc [expr $fraction * $i]
        }
    }
    set sashLoc "0.0 $sashLoc 1.0"
    set pwInfo($win,pos,0) [lindex $sashLoc 0]
    if {$orient == "v"} {
        set prev [lindex $sashLoc 0]
        for {set i 1} {$i <= $numPanes} {incr i} {
            set loc [lindex $sashLoc $i]
            set pwInfo($win,pos,$i) $loc
            set px($i) 0.0
            set py($i) $prev
            set prw($i) 1.0
            set prh($i) [expr $loc - $prev]
            set prev $loc
            set gx($i) 0.95
            set gy($i) $loc
        }
        set cursor sb_v_double_arrow
    } else {
        set prev [lindex $sashLoc 0]
        for {set i 1} {$i <= $numPanes} {incr i} {
            set loc [lindex $sashLoc $i]
            set pwInfo($win,pos,$i) $loc
            set px($i) $prev
            set py($i) 0.0
            set prw($i) [expr $loc - $prev]
            set prev $loc
            set prh($i) 1.0
            set gx($i) $loc
            set gy($i) 0.95
        }
        set cursor sb_h_double_arrow
    }

    # Main container frame
    frame $win -width $width -height $height

    # Create the sub frames.  These are the frames the calling code
    # will place its widgets within.  To get these frame names, the code
    # *should* call PanedWindow::Pane $win $paneNum
    for {set i 1} {$i <= $numPanes} {incr i} {
        set pwInfo($win,pane$i) [frame $win.pane$i]
        place $win.pane${i} -relx $px($i) -rely $py($i) \
            -relwidth $prw($i) -relheight $prh($i)
    }

    # Create the "sash" frame.
    for {set i 1} {$i < $numPanes} {incr i} {
        frame $win.sash$i -width 2 -height 2 -borderwidth 2 -relief sunken
        if {$orient == "v"} {
            place $win.sash$i -relx 0.5 -rely $gy($i) -anchor c -relwidth 1.0
        } else {
            place $win.sash$i -relx $gx($i) -rely 0.5 -anchor c -relheight 1.0
        }

        frame $win.grip$i -width 8 -height 8 \
            -borderwidth 1 -relief raised -cursor $cursor
        if {$grip == "y"} {
            place $win.grip$i -relx $gx($i) -rely $gy($i) -anchor c

            bind $win.grip$i <ButtonPress-1> \
                "PanedWindow::Grab $win $i"
            bind $win.grip$i <B1-Motion> \
                "PanedWindow::Drag $win $i %X %Y"
            bind $win.grip$i <ButtonRelease-1> \
                "PanedWindow::Release $win $i %X %Y"
        } else {
            bind $win.sash$i <B1-Motion> \
                "PanedWindow::Drag $win $i %X %Y"
            bind $win.sash$i <ButtonRelease-1> \
                "PanedWindow::Release $win $i %X %Y"
            $win.sash$i configure -cursor $cursor
        }
    }

    return $win
}

# PanedWindow::Pane --
#
#   Convienence proc to return the name of a pane's frame.
#
# Parameters:
#   win         : Container frame path name.
#   which       : Pane number
#
# Returns:
#   The widget path of the requested frame.
#
proc PanedWindow::Pane {win which} {

    variable pwInfo

    return $pwInfo($win,pane$which)
}

# PanedWindow::Grab --
#
#   Called upon button-press on the grip to change its appearance.
#
# Parameters:
#   win         : Container frame path name.
#
# Returns:
#   Nothing.
#
proc PanedWindow::Grab {win which} {

    $win.grip$which configure -relief sunken

    return
}

# PanedWindow::Check --
#
#   Checks if resizing too big or too small.
#
# Parameters:
#   val         : Proposed new ratio.
#
# Returns:
#   An acceptable value for window size.
#
proc PanedWindow::Check {win which val} {

    variable pwInfo

    set prev [expr $which - 1]
    set next [expr $which + 1]

    set min [expr $pwInfo($win,pos,$prev) + $pwInfo(min)]
    set max [expr $pwInfo($win,pos,$next) - $pwInfo(min)]
    if {$val < $min} {
        set val $min
    } elseif {$val > $max} {
        set val $max
    }

    return $val
}

# PanedWindow::Drag --
#
#   Calculates new frame sizes for the 2 panes depending on where
#   the sash or grip has been dragged to.  Will update display if
#   auto/continuous update is selected.
#
# Parameters:
#   win         : Container frame path name.
#   x, y        : X and Y cooridinates of the mouse pointer.
#
# Returns:
#   
#
proc PanedWindow::Drag {win which x y} {

    variable pwInfo

    if {$pwInfo($win,orient) == "v"} {
        set realY [expr $y - [winfo rooty $win]]
        set Ymax [winfo height $win]
        set pos [Check $win $which [expr double($realY) / $Ymax]]
        place $win.sash$which -rely $pos
        if {$pwInfo($win,grip) == "y"} {
            place $win.grip$which -rely $pos
        }
    } else {
        set realX [expr $x - [winfo rootx $win]]
        set Xmax [winfo width $win]
        set pos [Check $win $which [expr double($realX) / $Xmax]]
        place $win.sash$which -relx $pos
        if {$pwInfo($win,grip) == "y"} {
            place $win.grip$which -relx $pos
        }
    }

    if {$pwInfo($win,update) == 1} {
        Divide $win $which $pos
    }

    return $pos
}

# PanedWindow::Release --
#
#   Called upon button-release from the sash or grip.  Resizes the frames.
#
# Parameters:
#   win         : Container frame path name.
#   x, y        : X and Y cooridinates of the mouse pointer.
#
# Returns:
#   Nothing.
#
proc PanedWindow::Release {win which x y} {

    # Makes sure position is updated
    set pos [Drag $win $which $x $y]
    Divide $win $which $pos
    $win.grip$which configure -relief raised

    return
}

# PanedWindow::Divide --
#
#   Resizes the 2 panes based upon relative sizing.
#
# Parameters:
#   win         : Container frame path name.
#   which       : Which sash has moved.
#   pos         : Relative position of sash between panes.
#
# Returns:
#   Nothing.
#
proc PanedWindow::Divide {win which pos} {

    variable pwInfo

    set pwInfo($win,pos,$which) $pos
    set prev [expr $which - 1]
    set next [expr $which + 1]

    set mySize [expr $pos - $pwInfo($win,pos,$prev)]
    set nextSize [expr $pwInfo($win,pos,$next) - $pos]

    if {$pwInfo($win,orient) == "v"} {
        place $win.sash$which -rely $pos
        if {$pwInfo($win,grip) == "y"} {
            place $win.grip$which -rely $pos
        }
        place $win.pane$which -relheight $mySize
        place $win.pane$next  -relheight $nextSize -rely $pos
    } else {
        place $win.sash$which -relx $pos
        if {$pwInfo($win,grip) == "y"} {
            place $win.grip$which -relx $pos
        }
        place $win.pane$which -relwidth $mySize
        place $win.pane$next  -relwidth $nextSize -relx $pos
    }

    return
}

# PanedWindow::Position --
#
#   Returns the relative position of the sash.
#
# Parameters:
#   win         : Container frame path name.
#
# Returns:
#   Sash position.
#
proc PanedWindow::Position {win which} {

    variable pwInfo

    return $pwInfo($win,pos,$which)
}

proc PanedWindow::Demo {{numPanes 3}} {

    set tw .paneDemo
    if {[winfo exists $tw]} {destroy $tw}

    toplevel $tw
    wm title $tw "Paned Window Demo"
    Create $tw.f -num $numPanes -o h -w 4i -h 2i

    for {set i 1} {$i <= $numPanes} {incr i} {
        set f [Pane $tw.f $i]
        frame $f.f
        grid [label $f.f.b -text "Pane $i"]
        grid $f.f -sticky nsew
        grid columnconfigure $f 0 -weight 1
        grid rowconfigure $f 0 -weight 1
    }

    grid $tw.f -sticky nsew
    grid columnconfigure $tw 0 -weight 1
    grid rowconfigure $tw 0 -weight 1

    return
}