# ChatLog.tcl 20041231
#
# This file contains the procedures for chatroom logging.
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

# Chat::WriteToLog --
#
#   Writes a string to the currently opened log file.
#
# Parameters:
#   logString  : String to write
#   force      : Boolean to require write.
#
# Returns:
#   Nothing.
#
proc Chat::WriteToLog {logString {force 0}} {

    variable chatConfig

    if {($chatConfig(writeToLog) == 1) || ($force == 1)} {
        catch {
            puts $chatConfig(logFID) $logString
            flush $chatConfig(logFID)
        }
    }

    return
}

# Chat::SelectLogFile --
#
#   Selects a log file to append to.
#
# Parameters:
#   w         
#   mode      : Save or Open.
#
# Returns:
#   Nothing.
#
proc Chat::SelectLogFile {w mode} {

    variable chatConfig

    if {[info exists chatConfig(logDir)] == 0} {
        set chatConfig(logDir) $Config::config(Chat,logDir)
    }

    set fileName \
        [tk_get${mode}File -parent $w -filetypes $CrossFire::logFileTypes \
             -initialfile [file tail $chatConfig(logFileName)] \
             -defaultextension $CrossFire::extension(log) \
             -initialdir $chatConfig(logDir) -title "Select Log File"]

    if {($fileName == "") || ($fileName == $chatConfig(logFileName))} {
        return
    }

    set chatConfig(logDir) [file dirname $fileName]
    set chatConfig(logFileName) $fileName
    OpenLogFile
    set chatConfig(writeToLog) 1

    return
}

# Chat::CloseLogFile --
#
#   Closes the log file if it is open.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::CloseLogFile {} {

    variable chatConfig

    if {[info exists chatConfig(logFID)]} {
        set logString "\n*** Log End: [clock format [clock seconds]]\n"
        WriteToLog $logString 1
        close $chatConfig(logFID)
        unset chatConfig(logFID)
    }

    return
}

# Chat::OpenLogFile --
#
#   Opens a log file if possible.  If a failure occurs, writing to the file
#   will be turned off as an additional clue to the user that the log is not
#   being captured.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::OpenLogFile {} {

    variable chatConfig

    CloseLogFile

    set fileName $chatConfig(logFileName)
    if {[catch {set chatConfig(logFID) [open $fileName "a"]} err]} {
        # Could not open file for appending.
        tk_messageBox -icon error -title "Error Opening Log" \
            -message "Unable to open file:\n$fileName"
        set chatConfig(writeToLog) 0
    } else {
        set chatConfig(writeToLog) 1
        set logString \
            "\n*** Log Started: [clock format [clock seconds]]\n"
        WriteToLog $logString
    }

    return
}

# Chat::ToggleWrite --
#
#   Called when write to log is turned on or off.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::ToggleWrite {} {

    variable chatConfig

    if {$chatConfig(writeToLog) == 1} {
        if {$chatConfig(logFileName) != ""} {
            OpenLogFile
        } else {
            tk_messageBox -icon error -title "Logging Error" \
                -message "You must select a log file first!"
            set chatConfig(writeToLog) 0
        }
    } else {
        CloseLogFile
    }

    return
}

# Chat::CreateLogViewer --
#
#   Creates the chat log viewer GUI.
#
# Parameters:
#   fileName   : Optional log to open.
#
# Returns:
#   Nothing.
#
proc Chat::CreateLogViewer {{fileName ""}} {

    variable chatConfig

    set w .logViewer

    if {[winfo exists $w]} {
        wm deiconify $w
        raise $w
    } else {

        toplevel $w
        wm title $w "Chat Log Viewer"

        set chatConfig(logViewer) $w
        menu $w.menubar
        $w configure -menu $w.menubar

        $w.menubar add cascade \
            -label "Log" \
            -underline 0 \
            -menu $w.menubar.log

        menu $w.menubar.log -tearoff 0
        $w.menubar.log add command \
            -label "Open..." \
            -command "Chat::SelectViewLog" \
            -underline 0 \
            -accelerator "$CrossFire::accelKey+O"
        $w.menubar.log add separator
        set exitLabel "Exit"
        set exitAccelerator "Alt+F4"
        if {$CrossFire::platform == "macintosh"} {
            set exitLabel "Quit"
            set exitAccelerator "Command+Q"
        }
        $w.menubar.log add command \
            -label $exitLabel \
            -command "destroy $w" \
            -underline 0 \
            -accelerator $exitAccelerator

        frame $w.log
        text $w.log.t -background white -foreground black -wrap word \
            -yscrollcommand "CrossFire::SetScrollBar $w.log.sb"
        set chatConfig(log,textw) $w.log.t
        scrollbar $w.log.sb -command "$w.log.t yview"
        grid $w.log.t -sticky nsew
        grid columnconfigure $w.log 0 -weight 1
        grid rowconfigure $w.log 0 -weight 1

        grid $w.log -sticky nsew -padx 5 -pady 5
        grid columnconfigure $w 0 -weight 1
        grid rowconfigure $w 0 -weight 1
    }

    if {$fileName != ""} {
        ViewChatLog $fileName
    }

    return
}

# Chat::SelectViewLog --
#
#   Selects a chat log to view.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::SelectViewLog {} {

    variable chatConfig

    if {[info exists chatConfig(logDir)] == 0} {
        set chatConfig(logDir) $Config::config(Chat,logDir)
    }

    set fileName \
        [tk_getOpenFile -parent $chatConfig(logViewer) \
             -initialdir $chatConfig(logDir) -title "Select Chat Log" \
             -filetypes $CrossFire::logFileTypes]

    if {$fileName != ""} {
        ViewChatLog $fileName
    }

    return
}

# Chat::ViewChatLog --
#
#   Opens a chat log and displays it.
#
# Parameters:
#   fileName  : The name of the file.
#
# Returns:
#   Nothing.
#
proc Chat::ViewChatLog {fileName} {

    variable chatConfig

    if {[catch {set fid [open $fileName "r"]}]} {
        tk_messageBox -icon warning -title "Log Error" \
            -message "Unable to open log file."
        return
    }

    set chatConfig(logDir) [file dirname $fileName]
    $chatConfig(log,textw) delete 1.0 end
    $chatConfig(log,textw) insert end [read $fid]
    close $fid

    return
}

