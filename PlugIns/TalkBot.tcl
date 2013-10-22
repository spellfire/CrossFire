# TalkBot.tcl 20050902
#
# This file contains the procedures for a talk 'bot.
# plug-in for CrossFire chat.
#
# Copyright (c) 2004-2005 Dan Curtiss. All rights reserved.

namespace eval PlugIn::TalkBot {

    variable storage

    set storage(key) "!tb"
    set storage(message) "is A.F.K. (Away from Keyboard)"
    set storage(delay) 20
    set storage(tl) .talkBot

    # See if message has been saved.
    if {[info exists Config::config(TalkBot,message)]} {
	set storage(message) $Config::config(TalkBot,message)
	set storage(delay) $Config::config(TalkBot,delay)
    }

}

# PlugIn::TalkBot::Start --
#
#   Starts the talk bot.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc PlugIn::TalkBot::Start {} {

    variable storage

    # create window
    set w $storage(tl)
    if {[winfo exists $w]} {
	wm deiconify $w
	raise $w
	return
    }

    toplevel $w
    wm title $w "CrossFire TalkBot 1.0"
    wm protocol $w WM_DELETE_WINDOW "$w.b.c invoke"

    frame $w.m -relief raised -borderwidth 1
    label $w.m.ml -text "Message:" -anchor e
    entry $w.m.me -textvariable PlugIn::TalkBot::storage(message)
    grid $w.m.ml $w.m.me -sticky ew -padx 3 -pady 3

    label $w.m.dl -text "Minutes:" -anchor e
    menubutton $w.m.dmb -indicatoron 1 \
        -menu $w.m.dmb.menu -relief raised \
        -textvariable PlugIn::TalkBot::storage(delay)
    menu $w.m.dmb.menu -tearoff 0
    foreach delayTime "5 10 15 20 25 30 45" {
        $w.m.dmb.menu add radiobutton \
            -label $delayTime -value $delayTime \
            -variable PlugIn::TalkBot::storage(delay)
    }
    grid $w.m.dl $w.m.dmb -sticky ew -padx 3 -pady 3
    grid columnconfigure $w.m 1 -weight 1

    frame $w.b -relief raised -borderwidth 1
    button $w.b.save -text "Save" -command PlugIn::TalkBot::SaveSettings \
	-width 10
    set storage(button) $w.b.s
    button $storage(button) -text "Start" -command PlugIn::TalkBot::Go \
	-width 10
    button $w.b.c -text "Close" -command PlugIn::TalkBot::Close \
	-width 10
    grid $w.b.save $w.b.s $w.b.c -padx 5 -pady 3

    grid $w.m -sticky nsew
    grid $w.b -sticky nsew
    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 1

    return
}

# PlugIn::TalkBot::SaveSettings --
#
#   Saves message and delay settings to configure.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc PlugIn::TalkBot::SaveSettings {} {

    variable storage

    Config::Set TalkBot,message $storage(message)
    Config::Set TalkBot,delay $storage(delay)

    return
}

# PlugIn::TalkBot::Go --
#
#   Called from command button.
#
proc PlugIn::TalkBot::Go {} {

    variable storage

    if {[$storage(button) cget "-text"] == "Start"} {
	Talk
	$storage(button) configure -text "Stop"
    } else {
	Stop
	$storage(button) configure -text "Start"
    }

}

# PlugIn::TalkBot::Talk --
#
#   Sends a message to chat.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc PlugIn::TalkBot::Talk {} {

    variable storage

    Chat::ChatMessage $storage(message)
    set t [expr $storage(delay) * 60000]
    set storage(afterID) [after $t PlugIn::TalkBot::Talk]

    return
}

# PlugIn::TalkBot::Stop --
#
#   Stops the talker.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc PlugIn::TalkBot::Stop {} {

    variable storage

    if {[info exists storage(afterID)]} {
	after cancel $storage(afterID)
    }

    return 0
}

# PlugIn::TalkBot::Close --
#
#   Stops the talker and closes window.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc PlugIn::TalkBot::Close {} {

    variable storage

    Stop
    destroy $storage(tl)

    return
}

# PlugIn::TalkBot::Receive --
#
#   Called when recieving a talkbot command from someone else.  Odd that this
#   would happen!
#
# Parameters:
#   args       : command args
#
# Returns:
#   Nothing.
#
proc PlugIn::TalkBot::Receive {args} {

    variable storage

    return
}
