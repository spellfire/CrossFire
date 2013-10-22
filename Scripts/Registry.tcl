# Registry.tcl 20050701
#
# This file contains all the routines for reading and writing to the
# Windows Registry.
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

# Notes:
#   Any subKey can have sub key(s). Ex: CrossFire\\DeckIt

namespace eval Registry {

    # Determine if we are running on a platform that uses the Registry.
    if {[regexp "^Windows" $tcl_platform(os)]} {
        package require registry 1.0
        variable useRegistry 1
        variable registryKey {HKEY_CURRENT_USER\Software\Wolom}
    } else {
        variable useRegistry 0
    }

}

# Registry::Exists --
#
#   Tests if a sub key or an item under the sub key exists.
#   Ex: [Registry::Exists CrossFire] => does CrossFire path exist?
#   Ex: [Registry::Exists CrossFire deckDir] => does deckDir exist under
#       CrossFire?
#
# Parameters:
#   subKey     : Path of the data.
#   item       : Optional data item to check for.
#
# Returns:
#   1 if exists, 0 if not.
#
proc Registry::Exists {{subKey ""} {item ""}} {

    variable registryKey
    variable useRegistry

    if {$useRegistry == 0} return

    set exists 1
    set key "$registryKey\\$subKey"

    if {$item == ""} {
        # Checking if subKey exists
        if {[catch {registry keys $key}]} {
            set exists 0
        }
    } else {
        # Checking if item exists
        if {[catch {registry get $key $item}]} {
            set exists 0
        }
    }

    return $exists
}

# Registry::Set --
#
#   Sets data into the Windows Registry.
#   Ex: Registry::Set CrossFire deckDir {C:\My Documents}
#
# Parameters:
#   subKey     : Path of the data.
#   item       : Data element to set.
#   data       : Data to write.
#
# Returns:
#   Nothing.
#
proc Registry::Set {subKey item data} {

    variable registryKey
    variable useRegistry

    if {$useRegistry == 0} return

    registry set "$registryKey\\$subKey" $item $data

    return
}

# Registry::Get --
#
#   Get data from the Windows Registry.
#   Ex: set deckDir [Registry::Get CrossFire deckDir]
#
# Parameters:
#   subKey     : Path of the data.
#   item       : Data element to set.
#
# Returns:
#   The data or UNDEF if item has not been set
#
proc Registry::Get {subKey item} {

    variable registryKey
    variable useRegistry

    if {$useRegistry == 0} return

    if {[Exists $subKey $item]} {
        set result [registry get "$registryKey\\$subKey" $item]
    } else {
        set result "UNDEF"
    }

    return $result
}

# Registry::ItemList --
#
#   Returns a list of items under a key.
#   Ex: [Registry::ItemList CrossFire] == {deckDir invDir ...}
#
# Parameters:
#   subKey     : Path of the data.
#
# Returns:
#   A list of item names.
#
proc Registry::ItemList {{subKey ""}} {

    variable registryKey
    variable useRegistry

    if {$useRegistry == 0} return

    if {[Exists $subKey]} {
        set itemList [registry values "$registryKey\\$subKey"]
    } else {
        set itemList ""
    }

    return $itemList
}

# Registry::KeyList --
#
#   Returns a list of items under a key.
#   Ex: [Registry::KeyList] == {CrossFire ...}
#   Ex: [Registry::KeyList CrossFire] == {DeckIt SwapShop ...}
#
# Parameters:
#   subKey     : Optional sub key path.
#
# Returns:
#   A list of subKey names.
#
proc Registry::KeyList {{subKey ""}} {

    variable registryKey
    variable useRegistry

    if {$useRegistry == 0} return

    set keyList ""

    if {[Exists $subKey]} {
        set keyList [registry keys "$registryKey\\$subKey"]
    }

    return $keyList
}

# Registry::Delete --
#
#   Deletes a sub key or an item under the sub key.
#   Ex: [Registry::Delete CrossFire] => removes all of CrossFire.
#   Ex: [Registry::Delete CrossFire deckDir] => removes deckDir from CrossFire.
#
# Parameters:
#   subKey     : Path of the data.
#   item       : Optional data item to delete.
#
# Returns:
#   Nothing.
#
proc Registry::Delete {subKey {item ""}} {

    variable registryKey
    variable useRegistry

    if {$useRegistry == 0} return

    if {[Exists $subKey $item]} {
        if {$item == ""} {
            # Delete the entire sub key
            registry delete "$registryKey\\$subKey"
        } else {
            # Delete an item only.
            registry delete "$registryKey\\$subKey" $item
        }
    }

    return
}

# Registry::AssociateFiles --
#
#   Updates all the file association for Windows Explorer.
#   Calls Registry::AssociateFileType to do the actual update.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Registry::AssociateFiles {} {

    variable useRegistry

    if {$useRegistry == 0} return

    foreach ext {.cfc .cfd .cfi .cft .cfl .cff} {
        AssociateFileType $ext
    }

    return
}

# Registry::AssociateFileType --
#
#
#
# Parameters:
#   extension  : File extension to associate.
#   force      : Optional parameter to override predefined associations
#
# Returns:
#   Nothing.
#
proc Registry::AssociateFileType {extension {force ""}} {

    variable useRegistry

    if {$useRegistry == 0} return

    set wish [info nameofexecutable]
    set crossFire [file join $CrossFire::homeDir "CrossFire.tcl"]

    switch $extension {
        ".cfc" {
            set fileType "Combo"
            set icon 1
        }
        ".cfd" {
            set fileType "Deck"
            set icon 2
        }
        ".cfi" {
            set fileType "Inventory"
            set icon 3
        }
        ".cfl" {
            set fileType "ChatLog"
            set icon 5
        }
        ".cft" {
            set fileType "Trade"
            set icon 4
        }
        ".cff" {
            set fileType "Format"
            ### Need icon added for this!
            set icon 0
        }
    }

    set type "CrossFire${fileType}File"
    set key "HKEY_CLASSES_ROOT\\$type"
    set iconFile [file join $CrossFire::homeDir "Graphics" \
                      "XFire" "xFire.icl"]

    if {([file exists $iconFile] == 0) || ($icon == -1)} {
        set iconFile $wish
        set icon 0
    }

    # Check for extension already existing.
    set testKey "HKEY_CLASSES_ROOT\\$extension"
    if {[catch {registry keys $testKey}]} {
        set current ""
    } else {
        set current [registry get $testKey ""]
    }

    # Associate the file type to CrossFire if one of these:
    #  1) file type is not associated
    #  2) is associated to CrossFire already (update)
    #  3) requesting a forced overwrite
    if {($current == "") || ($current == $type) || ($force != "")} {
        Config::Set Windows,bind,$extension $type
        registry set "HKEY_CLASSES_ROOT\\$extension" "" $type
        registry set $key "" "CrossFire $fileType"
        registry set $key "EditFlags" "\000\000\000\000" binary
        registry set "$key\\DefaultIcon" "" "$iconFile,$icon"
        registry set "$key\\Shell\\Open" "EditFlags" \
            "\001\000\000\000" binary
        registry set "$key\\Shell\\Open\\Command" "" \
            "\"$wish\" \"$crossFire\" \"%1\""
    } else {
        Config::Set Windows,bind,$extension $current
    }
}
