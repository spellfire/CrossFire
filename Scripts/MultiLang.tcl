# MultiLang.tcl 20031006
#
# This file contains all the procedures for multiple language support.
#
# Copyright (c) 2003 Dan Curtiss. All rights reserved.
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

namespace eval ML {

    variable storage
    variable languageList

}

# ML::Initialize --
#
#    Reads all the available language files.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc ML::Initialize {} {

    variable storage
    variable languageList

    set languageList {}

    set filePattern [file join $CrossFire::homeDir "Languages" "*.lng"]
    foreach langFile [glob -nocomplain $filePattern] {
	set lang "undef"
	set fid [open $langFile "r"]
	while {![eof $fid]} {
	    set line [gets $fid]
	    set first [lindex $line 0]
	    switch -- $first {
		"Language" {
		    set lang [lindex $line 1]
		    lappend languageList $lang
		}
		"\#" - "" {
		    # skip it - blank line or comment
		}
		default {
		    set storage($lang,$first) [lindex $line 1]
		}
	    }
	}
	close $fid
    }

    return
}

# ML::str --
#
#    Returns a string in the current language.
#
# Parameters:
#   key       : Key code for the requested string.
#
# Returns:
#   The translated string in the current language if it exists or
#   the English version of the string if undefined.
#
proc ML::str {key} {

    variable storage

    set lang $Config::config(CrossFire,language)

    if {[info exists storage($lang,$key)]} {
	set result $storage($lang,$key)
    } else {
	set lang "English"
	if {[info exists storage($lang,$key)]} {
	    set result $storage($lang,$key)
	    dputs "Subsituted English for key: $key" force
	} else {
	    set result "!$key"
	    dputs "Undefined key: $key lang: $lang" force
	}
    }

    return $result
}
