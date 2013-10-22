# Server.tcl 20030908
#
# This file contains all the procedures for the file server.
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

namespace eval Server {

    array set storage {
        host localhost
        port 12177
    }
}

# Server::Start --
#
#    Set up the server to listen for files to open.  This is used
#    so decks, combos, etc can be double-clicked on windows machines,
#    or specified on the command line for Linux.
#
# Parameters:
#   None.
#
proc Server::Start {} {

    variable storage
    global argv

    if {$CrossFire::platform == "macintosh"} {
        # No need for this on a Mac...at least thats what we think. :|
        return
    }

    if {$Config::config(CrossFire,serverMode) != "Single"} {
        # User wants to run multiples, so return.
        return
    }

    if {[catch {socket $storage(host) $storage(port)} chID]} {
        # Server not running, starting...
        socket -server Server::FileServerConnect $storage(port)
    } else {
        # We connected to the server.
        if {$argv == ""} {
            # Did not give any files!
            puts $chID "wakeup"
        } else {
            # Send the file names.
            foreach fileName $argv {
                puts $chID $fileName
            }
        }
        close $chID
        exit
    }
}

# Server::FileServerConnect --
#
#   Configures the listening server.
#
# Parameteres:
#   chID, addr, port : Channel ID, addr, port
#
# Returns:
#   Nothing.
#
proc Server::FileServerConnect {chID addr port} {

    fileevent $chID readable "Server::FileServerReceive $chID"
    fconfigure $chID -buffering line

    return
}

# Server::FileServerReceive --
#
#   Got a file or wakeup command from an newly run CrossFire.
#
# Parameteres:
#   chID        : Channel ID.
#
# Returns:
#   Nothing.
#
proc Server::FileServerReceive {chID} {

    if {([gets $chID data] < 0) || ([eof $chID] == 1)} {
        close $chID
        return
    }

    if {$data == "wakeup"} {
        set msg "CrossFire is running in single mode. To run multiple "
        append msg "instances change the configuration."
        tk_messageBox -icon info -title "CrossFire Notice" \
            -message $msg
    } else {
        CrossFire::AutoLoad $data
    }

    return
}
