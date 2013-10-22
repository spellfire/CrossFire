# CommonUI.tcl 20041231
#
# This file defines the common routines used throughout CrossFire.
#
# Copyright (c) 1998-2004 Dan Curtiss. All rights reserved.
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

# CrossFire::PlaceWindow --
#
#   Places a toplevel winodw.  Verifies it is visible.
#
# Parameters:
#   t          : Toplevel
#   geom       : X and Y coordinates for placement.  ie: [200x200]+32+318
#
# Returns:
#   Nothing.
#
proc CrossFire::PlaceWindow {t geom} {

    if {$geom == "center"} {
        set size 0
        set x [expr ([winfo screenwidth .] - [winfo reqwidth $t]) / 2]
        set y [expr ([winfo screenheight .] - [winfo reqheight $t]) / 2]
        foreach {w h} [split [wm geometry $t] "+x"] break
    } elseif {![regexp "\[0-9\]*x\[0-9\]*" $geom]} {
        set size 0
        foreach {null x y} [split $geom "+"] break
        foreach {w h} [split [wm geometry $t] "+x"] break
    } else {
        set size 1
        foreach {w h x y} [split $geom "+x"] break
	if {$w < 25} {
	    set w 100
	}
	if {$h < 25} {
	    set h 100
	}
    }
    #dputs "window=$t, size=$size, geom=$geom, w=$w, h=$h, x=$x, y=$y"

    if {$x < 0} { set x 0 }
    set sw [winfo screenwidth .]
    if {[expr $x + $w] > $sw} {
        set x [expr $sw - $w]
    }

    if {$y < 10} { set y 20 }
    set sh [winfo screenheight .]
    if {[expr $y + $h] > $sh} {
        set y [expr $sh - $h]
    }

    if {$size} {
	set newGeom "${w}x${h}+${x}+${y}"
    } else {
	set newGeom "+${x}+${y}"
    }
    wm geometry $t $newGeom

    #dputs "Final: geom=$newGeom, sw=$sw, sh=$sh, w=$w, h=$h, x=$x, y=$y"
    return
}

# CrossFire::Transient --
#
#   Changes a toplvel to be a transient of its parent and adjusts
#   its positioning.
#
# Parameters:
#   w          : Toplevel to change.
#
# Returns:
#   Nothing.
#
proc CrossFire::Transient {w} {

    if {$Config::config(CrossFire,transient) == "Yes"} {
        set pw [winfo parent $w]
        wm transient $w $pw
        set x [expr [winfo rootx $pw] + 10]
        set y [expr [winfo rooty $pw] + 10]
        wm geometry $w +$x+$y
    }

    return
}

# CrossFire::WindowTitle --
#
#   Sets the title for a new window.  This is usually the name of the
#   part of CrossFire and shouldn't change.  This proc also initializes
#   the variables for filename and changed status storage.
#   Example: CrossFire::WindowTitle $w "DeckIt!"
#
# Parameters:
#   w           : Widget name of the toplevel.
#   windowTitle : Name for the window.
#
# Returns:
#   Nothing.
#
proc CrossFire::WindowTitle {w {windowTitle ""}} {

    variable windowInfo

    set windowInfo($w,title) $windowTitle
    set windowInfo($w,file) ""
    set windowInfo($w,changed) "false"

    UpdateWindowTitle $w

    return
}

# CrossFire::WindowFile --
#
#   Sets the name for the optional filename or file title for a window.
#   This file/title is appended to the window title.
#   Example: CrossFire::WindowFile $w "GenCon '99 Deck"
#
# Parameters:
#   w          : Widget name of the toplevel.
#   fileTitle  : Name for the file or title.
#
# Returns:
#   Nothing.
#
proc CrossFire::WindowFile {w {fileTitle ""}} {

    variable windowInfo

    set windowInfo($w,file) $fileTitle
    UpdateWindowTitle $w

    return
}

# CrossFire::SetChanged --
#
#   Sets the changed status for a window.  This appends a '*' to the
#   window title if "true".
#
# Parameters:
#   w          : Widget name of the toplevel.
#   bool       : Boolean changed state.
#   args       : Optional stuff appended from trace.
#
# Returns:
#   Nothing.
#
proc CrossFire::SetChanged {w bool args} {

    variable windowInfo

    set windowInfo($w,changed) $bool
    UpdateWindowTitle $w

    return
}

# CrossFire::UpdateWindowTitle --
#
#   Updates a window's title as "Window Title [ - File Title] [ *]"
#
# Parameters:
#   w          : Widget name of the toplevel.
#
# Returns:
#   Nothing.
#
proc CrossFire::UpdateWindowTitle {w} {

    variable windowInfo

    if {$windowInfo($w,file) == ""} {
        set tempTitle "$windowInfo($w,title)"
    } else {
        set tempTitle "$windowInfo($w,title) - $windowInfo($w,file)"
    }

    if {$windowInfo($w,changed) == "true"} {
        append tempTitle " *"
    }

    wm title $w $tempTitle

    return
}

# CrossFire::Changed --
#
#   Returns the changed status of a window.
#
# Parameters:
#   w          : Widget name of the toplevel.
#
# Returns:
#   true or false.
#
proc CrossFire::Changed {w} {

    variable windowInfo

    return $windowInfo($w,changed)
}

