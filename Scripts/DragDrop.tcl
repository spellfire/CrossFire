# DragDrop.tcl 20050928
#
# This file defines the routines used for drag and drop.
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

# CrossFire::DragTarget --
#
#   Allows for a widget to receive drags and what should
#   be executed when it occurs.
#
# Parameters:
#   w          : Widget that the drop will occur on.
#   type       : Type of data to receive.
#   command    : Command to execute when drop occurs.
#
# Returns:
#   Nothing.
#
proc CrossFire::DragTarget {w type command} {

    variable dropCommand

    set dropCommand($w,$type) $command

    return
}

# CrossFire::StartDrag --
#
#   Starts the drag and drop routine.  Sets an after id when
#   the cursor is changed.  Sets up the receiving bindings
#   for all widgets, except the current.
#
# Parameters:
#   w          : Widget that the drag was started on.
#   cursor     : Cursor to change to after the delay.
#   type       : Type of data to send.
#   data       : Drag data to send.
#
# Returns:
#   Nothing.
#
proc CrossFire::StartDrag {w cursor type data} {
    
    $w configure -cursor $cursor
    bind all <Enter> "CrossFire::EndDrag %W $w $type $data"

    # This bind is used so that the EndDrag is not called if the user
    # drags out of a widget and then back into it.  The problem is that
    # if one does this, the <Enter> event is triggered right away because
    # that widget is active.  Results in immediate canceling of the drag.
    bind $w <Enter> break

    return
}

# CrossFire::CancelDrag --
#
#   Cancels the drag and drop routine.  This is called when either
#   the user releases the button on the drag widget or when the
#   drag and drop is finished.
#
# Parameters:
#   w          : Widget the drag was started on.
#
# Returns:
#   Nothing.
#
proc CrossFire::CancelDrag {w} {

    after 50 "bind $w <Enter> {}; bind all <Enter> {}; bind $w <Leave> {}; $w configure -cursor {}"

    return
}

# CrossFire::EndDrag --
#
#   Ends the drag and drop routine.  Cancels the drag's after id and
#   executes the receiver's drop command.
#
# Parameters:
#   w          : Widget who receives the drag.
#   from       : Widget who started the drag.
#   type       : Type of data receiving.
#   args       : Data received.
#
# Returns:
#   Nothing.
#
proc CrossFire::EndDrag {w from type args} {

    variable dropCommand

    CancelDrag $from
    if {[info exists dropCommand($w,$type)]} {
        eval $dropCommand($w,$type) $from "$args"
    }

    return
}
