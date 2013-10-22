# Balloon.tcl 20040820
#
# This file contains procedures for the balloon help.
#
# Copyright (c) 2004 Dan Curtiss. All rights reserved.
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

# Procedure List:
#   Balloon::Mode {args}
#   Balloon::AutoHide {args}
#   Balloon::Delay {args}
#   Balloon::HideDelay {args}
#   Balloon::Set {w {msg ""}}
#   Balloon::Start {w}
#   Balloon::SustainTime {args}
#   Balloon::Hide {}
#   Balloon::Show {w {x -1} {y -1}}


namespace eval Balloon {

    variable config

    array set config {
        mode          On
        delay         0.5
        autoHide      On
        autoHideDelay 4
        toplevel      .balloonhelp
        text          .balloonhelp.text
        sustained     0
        sustainTime   200
    }

    #
    # This part is CrossFire specific.
    #
    foreach varName {
        mode delay autoHide autoHideDelay
    } {
	set config($varName) $Config::config(Tooltips,$varName)
    }
    #
    # End of CrossFire specific.
    #

    # Create the toplevel for the "balloon"
    toplevel $config(toplevel) -borderwidth 1 -relief flat \
        -background black

    wm overrideredirect $config(toplevel) 1
    wm withdraw $config(toplevel)

    label $config(text) -foreground black -background "\#FFFFDD" \
        -justify left
    pack $config(text) -side left -fill y

}

# Balloon::Mode --
#
#   Either turns on or off balloon help or returns the current mode.
#
# Parameters:
#   args       : Display mode.  On or Off.
#                If nothing, returns current mode.
#
# Returns:
#   The current show state.
#
proc Balloon::Mode {args} {

    variable config

    if {$args != ""} {
 	set config(mode) [lindex $args 0]
    }

    return $config(mode)
}

# Balloon::AutoHide --
#
#   Either urns on or off automatic hiding of balloon help
#   or returns the current state of auto hide.
#
# Parameters:
#   args       : Automatic hide state. On or Off.
#                If nothing, returns current state.
#
# Returns:
#   The current auto hide state.
#
proc Balloon::AutoHide {args} {

    variable config

    if {$args != ""} {
        set config(autoHide) [lindex $args 0]
    }

    return $config(autoHide)
}

# Balloon::Delay --
#
#   Sets the wait delay before balloon help pops up or
#   returns the current delay.
#
# Parameters:
#   args       : Delay in seconds.  Minimum of 0.1.
#
# Returns:
#   The delay.
#
proc Balloon::Delay {args} {

    variable config

    if {$args != ""} {
        set delay [lindex $args 0]
        if {$delay < 0.1} {
            set config(delay) 0.1
        } else {
            set config(delay) $delay
        }
    }

    return [expr int($config(delay) * 1000)]
}

# Balloon::HideDelay --
#
#   Sets the wait delay before balloon help is automatically
#   hiden or returns the current delay.
#
# Parameters:
#   args       : Delay in seconds.  Minimum of 0.5.
#
# Returns:
#   The delay.
#
proc Balloon::HideDelay {args} {

    variable config

    if {$args != ""} {
        set delay [lindex $args 0]
        if {$delay < 0.5} {
            set config(autoHideDelay) 0.5
        } else {
            set config(autoHideDelay) $delay
        }
    }

    return [expr int($config(autoHideDelay) * 1000)]
}

# Balloon::Set --
#
#   Sets the help text for a widget. Also used to remove
#   help for a particular widget.
#
# Parameters:
#   w          : Widget name to apply balloon help to.
#   msg        : Message to display for the widget. If no
#                text is given, help is disabled for the widget.
#
# Returns:
#   The help text.
#
proc Balloon::Set {w {msg ""}} {

    variable config

    if {$msg != ""} {
        set config($w) $msg
        bind $w <Enter> "Balloon::Start %W"
        bind $w <Leave> "Balloon::Hide"
    } else {
        set config($w) ""
    }

    return $config($w)
}

# Balloon::Start --
#
#   Starts the background processes to handle popping up the
#   balloon help for a widget.
#
# Parameters:
#   w          : Widget name.
#
# Returns:
#   Nothing.
#
proc Balloon::Start {w} {

    variable config

    if {$config(sustained)} {
        Balloon::Show $w
    } else {
        Balloon::Hide
        set config(afterID) [after [Delay] "Balloon::Show $w"]
    }

    return
}

# Balloon::SustainTime --
#
#   Sets the amount of time to sustain popped up help or
#   returns the current time.
#
# Parameters:
#   args       : Time in milliseconds.  Minimum of 100.
#
# Returns:
#   The time
#
proc Balloon::SustainTime {args} {

    variable config

    if {$args != ""} {
        set sustainTime [lindex $args 0]
        if {$sustainTime < 100} {
            set config(sustainTime) 100
        } else {
            set config(sustainTime) $sustainTime
        }
    }

    return $config(sustainTime)
}

# Balloon::Hide --
#
#   Hides the current balloon help.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Balloon::Hide {} {

    variable config

    if {[info exists config(afterID)]} {
        after cancel $config(afterID)
        unset config(afterID)
    }

    if {[info exists config(autoHideAfterID)]} {

        set config(sustained) 1
        if {[info exists config(sustainAfterID)]} {
            after cancel $config(sustainAfterID)
        }
        set config(sustainAfterID) \
            [after [SustainTime] "set Balloon::config(sustained) 0"]

        after cancel $config(autoHideAfterID)
        unset config(autoHideAfterID)
    }

    wm withdraw $config(toplevel)

    return
}

# Balloon::Show --
#
#   Shows the balloon help message.
#
# Parameters:
#   w          : Widget name.
#
# Returns:
#   Nothing.
#
proc Balloon::Show {w {x -1} {y -1}} {

    variable config

    if {[Mode] != "Off"} {
        if {[info exists config($w)]} {
            $config(text) configure -text $config($w)
            update
            if {$x == -1} {
                set x [expr [winfo pointerx $w] + 10]
                set y [expr [winfo pointery $w] + 10]
            }

	    set w [winfo reqwidth $config(text)]
	    set h [winfo reqheight $config(text)]

	    set sw [winfo screenwidth .]
	    if {[expr $x + $w] > $sw} {
		set x [expr $sw - $w]
	    }

	    set sh [winfo screenheight .]
	    if {[expr $y + $h] > $sh} {
		set y [expr $y - $h - 15]
	    }

	    wm geometry $config(toplevel) "${w}x${h}+${x}+${y}"
            wm deiconify $config(toplevel)
            raise $config(toplevel)
        }
    }

    if {[info exists config(afterID)]} {
        unset config(afterID)
    }

    if {[AutoHide] == "On"} {
        set config(autoHideAfterID) [after [HideDelay] "Balloon::Hide"]
    }

    return
}

