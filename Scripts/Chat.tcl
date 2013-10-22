# Chat.tcl 20051206
#
# This file contains the procedures for the chatroom GUI client.
#
# Copyright (c) 1998-2005 Dan Curtiss. All rights reserved.
# Implemented communications protocols are Copyright (C) 1999 Stephen Thompson.
# All rights reserved.
#
# See the files "copyright.html", "license-protocols.html",
# "spins-copyright.html", and "license-server.html" for information
# on usage and redistribution of this file, and for a
# DISCLAIMER OF ALL WARRANTIES.
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

namespace eval Chat {

    variable chatConfig
    array set chatConfig {
        protocol    CrossFire-tcltk
        topw        .chatRoom
        online      0
        playerColor blue
        autoLogIn   Yes
        name        ""
        password    ""
        displayUp   0
        userNoteCC  ""
        userNoteWidth ""
	typing      0
	typingOff   5000
        linkCount   0
    }

    # chatConfig(plugInID) is no longer used... just use '!'
    set chatConfig(plugInID) "!"

    # Make sure we have the variable, just in case all smileys were removed
    set chatConfig(smileyList) {}

    # Load in the smiley icons and build the look-up array.
    # OK to use any character except for the braces.
    foreach {icon image} {
        :E   elric
        :R   reaper
        :\[  vampire
        :\)  smile
        :-\) smile-with-nose
        :D   smile-big
        ^:D  smile-big-looking-right
        >:D  smile-mischevious
        8)   smile-with-glasses
        v:\) smile-looking-left
        ^:\) smile-looking-right
        :%\) smile-blushing
        |:\) smile-with-brows
        :\\  smile-halfway
        :-\\ smile-slanted
        0:\) smile-halo
        %:\) small-frazzled
        :P   tongue
        :\)\) sillySmile
        :\(  frown
        |:\( frown-with-brows
        :'\( frown-with-tears
        X\(  frown-sick
        >:o  frown-yelling
        >:\( frown-angry
        *:\( frown-beat-up
        :L   loser
        :M   moron
        :S   slacker
        P\)  pirate
        \]:\) devil
        x|   skeleton
        X\)  drunk
        *\)  cyclops
        :V   pacman
        :\]  robot
    } {
        set iFile \
            [file join $CrossFire::homeDir "Graphics" "Icons" ${image}.gif]
        if {[file exists $iFile]} {
            lappend chatConfig(smileyList) $icon
            set chatConfig(smiley,$icon) imageChatSmile$image
	    set chatConfig(smiley,name,$icon) $image
            image create photo imageChatSmile$image -file $iFile
        } else {
            dputs "Missing file: $iFile"
        }
    }

# This code adds the mini icons as smileys
#     foreach cardTypeID $CrossFire::cardTypeIDList {
#         set icon ":$cardTypeID"
#         set imgName "small$cardTypeID"
#         if {[lsearch [image names] $imgName] != -1} {
#             lappend chatConfig(smileyList) $icon
#             set chatConfig(smiley,$icon) $imgName
#             set chatConfig(smiley,name,$icon) $imgName
#         }
#     }

    safeInterp alias Chat::AddToBox Chat::AddToBox
    safeInterp alias Chat::ClearBox Chat::ClearBox
    safeInterp alias Chat::HighlightChannel Chat::HighlightRealm
    safeInterp alias Chat::MessageBox Chat::MessageBox
    safeInterp alias Chat::ShowProfile Chat::ShowProfile

    image create photo imgDisconnected -data {
        R0lGODlhDgAOAPUAAP6ksv6LmP4wPv4gL/4PH/4PG/4HE/4AEf4ADe8ADOcADN4AC7+
        /v9YIEtYADs1iac1iZ81BSM0PHM0ACsa9vcZ7gMZ7f8YACr0ADb0ACbUACa0ACZxKT5
        wACJQAB4wxNoQQFoQACXMPFnMABmsAB2MABVoABloABEoABUoABAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAACH5BAEAAAwALAAAAAAOAA4AAAZrQIZwSCwaj0RLRCKJWI4Qx+GASFwgxcrkQBA
        YFJdOhRg5GAKAggPjARElCINg0MB0Qqf3QrGYaO4leRRCERgYGRt3Jigig0IVHh0eIS
        MlKSgcRQ8kJCconx9FgxUiJyciHI6iQ46qRKqtDEEAOw==
    }

    image create photo imgConnected -data {
        R0lGODlhDgAOAPUAALL+pJj+iz7+MC/+IB/+Dxv+DxP+BxH+AA3+AAzvAAznAAveAL+
        /vxLWCA7WAGnNYmfNYkjNQRzNDwrNAL3GvYDGe3/GewrGAA29AAm9AAm1AAmtAE+cSg
        icAAeUADaMMRaEEAmEABZzDwZzAAdrAAVjAAZaAAVaAAVKAARKAAAAAAAAAAAAAAAAA
        AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
        AAAAACH5BAEAAAwALAAAAAAOAA4AAAZrQIZwSCwaj0RLRCKJWI4Qx+GASFwgxcrkQBA
        YFJdOhRg5GAKAggPjARElCINg0MB0Qqf3QrGYaO4leRRCERgYGRt3Jigig0IVHh0eIS
        MlKSgcRQ8kJCconx9FgxUiJyciHI6iQ46qRKqtDEEAOw==
    }

    variable replacement
    array set replacement {
    }

    set chatConfig(noBody) {
        {no one}
        {their own :L self}
        {thin air}
        {Micro$oft}
        {the Void}
        {their head}
        {Bill Gates}
        {Steve Ballmer}
        {Steve Jobs}
        {Steve Case}
        {their significant other}
        {ummm....hmmm....???}
        {Magic: the Gathering}
        {Pokémon}
        {Micros~1}
        {some brain-dead AOL-er}
    }

    # Set up "plug-ins" for online play
    foreach {mode tempKey cmd} {Play sf Create Watch sfw Watch} {
        foreach rfk $Game::gameConfig(formation,keyList) {
            # For backwards compatibility, 6 realm games use !sf for the
            # communication key.  All others use !sf8, etc.
            if {$rfk == "6"} {
                set key $tempKey
            } else {
                set key "$tempKey$rfk"
            }
            set key "!$key"
            lappend plugIn(keyList) $key
            set name $Game::gameConfig(formation,$rfk,name)
            set plugIn($key,name) "$mode $name Game"
            set plugIn($key) "Game::$cmd \$Chat::chatConfig(name) $rfk"
            set plugIn($key,receive) Game::ReceiveOpponentCommand
        }
        if {$mode == "Play"} {
            lappend plugIn(keyList) "-"
        }
    }
    set plugIn(killCommand) "Game::CloseAll"

}

# Scan for plug-in Games.  Not in the Chat namespace to make coding
# the plug-in easier (no need to fully qualify every namespace).
set plugIns [glob -nocomplain [file join $CrossFire::homeDir PlugIns "*.cfp"]]

if {$plugIns != ""} {
    # Add a separator in the menu
    lappend Chat::plugIn(keyList) "-"
}

foreach plugInDef $plugIns {

    if {[file readable $plugInDef] == 0} {
        continue
    }

    set fid [open $plugInDef "r"]
    set plugInCommand [read $fid]
    close $fid

    # Eval in the safe interpreter
    catch {
        safeInterp eval $plugInCommand
    } err

    set plugInInfo [CrossFire::GetSafeVar plugInInfo]

    foreach {fileName key name command receiveCmd killCmd} $plugInInfo break
    source [file join $CrossFire::homeDir PlugIns $fileName]
    set key "!$key"
    lappend Chat::plugIn(keyList) $key
    set Chat::plugIn($key,name) $name
    set Chat::plugIn($key) $command
    set Chat::plugIn($key,receive) $receiveCmd
    lappend Chat::plugIn(killCommand) $killCmd
}

# Chat::Login --
#
#   Creates the window for user to enter name and password.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::Login {} {

    variable chatConfig

    set w .login
    set chatConfig(login) $w

    # Test for attempting to log in when already logged in!
    if {$chatConfig(online) == 1} {
        wm deiconify $chatConfig(topw)
        raise $chatConfig(topw)
        return
    }

    if {[winfo exists $w]} {
        wm deiconify $w
        raise $w
        return
    }

    SetProfileData

    set chatConfig(host) $Config::config(Chat,server,host)
    set chatConfig(port) $Config::config(Chat,server,port)
    set chatConfig(serverName) $Config::config(Chat,server,name)

    # Copy the user name and password from config.
    foreach {localVar configVar} {
        host          Chat,server,host
        port          Chat,server,port
        serverName    Chat,server,name
        name          Chat,userName
        password      Chat,password
        userNoteCC    Chat,userNoteCC
        userNoteWidth Chat,userNoteWidth
    } {
        set chatConfig($localVar) $Config::config($configVar)
    }

    if {($Config::config(Chat,autoLogIn) == "Yes") &&
        ($chatConfig(autoLogIn) == "Yes") &&
        ($::developer == 0)} {
        ServerLogin
        return
    }

    toplevel $w
    wm title $w "Login to CrossFire Chat"
    wm protocol $w WM_DELETE_WINDOW "$w.buttons.cancel invoke"
    bind $w <Key-Escape> "$w.buttons.cancel invoke"

    frame $w.top -relief raised -borderwidth 1

    label $w.top.lname -text "Username:" -width 9 -anchor e
    entry $w.top.ename -width 24 \
        -textvariable Chat::chatConfig(name)

    label $w.top.lpass -text "Password:"  -width 9 -anchor e
    entry $w.top.epass -width 24 -show "*" \
        -textvariable Chat::chatConfig(password)

    label $w.top.lserver -text "Server:" -width 9 -anchor e
    menubutton $w.top.mbserver -indicatoron 1 -width 15 \
        -menu $w.top.mbserver.menu -relief raised \
        -textvariable Chat::chatConfig(serverName)
    menu $w.top.mbserver.menu -tearoff 0
    foreach {sName host port} $Config::config(Chat,server,list) {
        $w.top.mbserver.menu add radiobutton \
            -label $sName -value $sName \
            -variable Chat::chatConfig(serverName) \
            -command "Chat::UpdateServerConfig $host $port"
    }

    grid $w.top.lname $w.top.ename      -padx 5 -pady 5 -sticky ew
    grid $w.top.lpass $w.top.epass      -padx 5 -pady 5 -sticky ew
    grid $w.top.lserver $w.top.mbserver -padx 5 -pady 5 -sticky ew

    if {$::developer == 1} {
        label $w.top.lhost -text "Host:" -width 9 -anchor e
        entry $w.top.ehost -width 24 \
            -textvariable Chat::chatConfig(host)
        label $w.top.lport -text "Port:" -width 9 -anchor e
        entry $w.top.eport -width 24 \
            -textvariable Chat::chatConfig(port)
        grid $w.top.lhost $w.top.ehost -padx 5 -pady 5 -sticky ew
        grid $w.top.lport $w.top.eport -padx 5 -pady 5 -sticky ew
        grid columnconfigure $w.top 1 -weight 1
        grid rowconfigure $w.top {0 1 2 3 4} -weight 1
    } else {
        grid columnconfigure $w.top 1 -weight 1
        grid rowconfigure $w.top {0 1 2} -weight 1
    }

    frame $w.buttons -relief raised -borderwidth 1
    button $w.buttons.login -text "Login" \
        -command "Chat::ServerLogin" -width 10
    button $w.buttons.cancel -text $CrossFire::close \
        -command "destroy $w" -width 10
    grid $w.buttons.login $w.buttons.cancel -padx 5 -pady 5

    grid $w.top -sticky nsew
    grid $w.buttons -sticky ew
    grid rowconfigure $w 0 -weight 1
    grid columnconfigure $w 0 -weight 1

    focus $w.top.ename
    bind $w <Key-Return> "$w.buttons.login invoke"

    return
}

proc Chat::UpdateServerConfig {host port} {

    variable chatConfig

    set chatConfig(host) $host
    set chatConfig(port) $port

    return
}

# Chat::ServerLogin --
#
#   Logs user into the server.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::ServerLogin {} {

    variable chatConfig

    if {$chatConfig(name) == ""} {
        LoginError "You must enter your user name."
        set chatConfig(autoLogIn) "No"
        Login
        return
    }

    if {$chatConfig(password) == ""} {
        LoginError "You must enter your password."
        set chatConfig(autoLogIn) "No"
        Login
        return
    }

    # Remove the login window
    if {[winfo exists $chatConfig(login)]} {
        destroy $chatConfig(login)
    }

    # Replace non-alphanumeric in the user name with underscores
    regsub -all -- "\[^0-9a-zA-Z\]" $chatConfig(name) "_" chatConfig(name)

    LoginStatus "Attempting to connect to SPINS Server..."

    # Some test to check for login ok
    if {[catch {socket -async $chatConfig(host) $chatConfig(port)} chID]} {
        # ACK!  An error occured logging in.
        LoginStatus ""
        LoginError "Unable to login to server.\n$chID"
        OnlineStatus 0

        # Since we had a problem logging in, turn off auto log in to
        # avoid a repeating login attempt with failure.
        set chatConfig(autoLogIn) "No"

        # Redisplay the login window.
        Login
    } else {
        set chatConfig(cid) $chID
        CreateChatRoom
        OnlineStatus 1

        LoginStatus "Connecting to SPINS Server..."

        LoginStatus "Verifying Username and Password..."

        SendToServer $chatConfig(name)
        SendToServer $chatConfig(password)
        SendToServer "protocol $chatConfig(protocol)"

        # Set up the event handler for receiving from server
        if {[catch {fileevent $chID readable Chat::ReceiveFromServer} err]} {
            LogOff 1
        }
    }

    return
}

# Chat::LoginStatus --
#
#   Displays a message while connecting to the SPINS server.
#
# Parameters:
#   msg        : Message to display or "" to close window.
#
# Returns:
#   Nothing.
#
proc Chat::LoginStatus {msg} {

    set tw .loginStatus

    if {$msg == ""} {
        if {[winfo exists $tw]} {
            destroy $tw
        }
    } else {
        if {[winfo exists $tw]} {
            wm deiconify $tw
            raise $tw
        } else {
            toplevel $tw
            wm title $tw "Login Status"
            wm resizable $tw 0 0
            label $tw.msg -font {Times -14 bold} -width 50
            pack $tw.msg -padx 10 -pady 20
            update
            CrossFire::PlaceWindow $tw center
        }
        $tw.msg configure -text $msg
        update
        after 350
    }

    return
}

# Chat::LoginError --
#
#   Called if there was any problem logging into the server.
#
# Parameters:
#   msg        : Message to display.
#
# Returns:
#   Nothing.
#
proc Chat::LoginError {msg} {

    tk_messageBox  -title "Login Error" -icon error \
        -message $msg

    return
}

# Chat::CreateChatRoom --
#
#   Create the chat room GUI.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::CreateChatRoom {} {

    variable chatConfig

    set w $chatConfig(topw)

    # Set up a trace to deiconify the client window once it is known that the
    # user is logged in ok. The test for ok login is receiving a realm name.
    trace variable Chat::chatConfig(map) w Chat::LoginOK

    if {[winfo exists $w]} {
        return
    }

    toplevel $w
    CrossFire::Register Chat $w
    wm withdraw $w
    wm title $w "CrossFire Chat"
    wm protocol $w WM_DELETE_WINDOW "Chat::ExitChat"
    CrossFire::PlaceWindow $w $Config::config(Chat,geometry)

    set chatConfig(messageEntry) $w.message.e
    set chatConfig(championSel)  ""
    set chatConfig(realmSel)     ""
    set chatConfig(selectionAt)  ""
    set chatConfig(msgStack)     ""
    set chatConfig(writeToLog)   0
    set chatConfig(allyList)     ""

    AddMenuBar $w
    AddActionMenu

    foreach {localVar configVar} {
        inAlert     Chat,arriveAlert
        outAlert    Chat,leaveAlert
        timeStamp   Chat,timeStamp
        chatFG      Chat,foreground
        chatBG      Chat,background
        newChamp    Chat,newChampion
        logFileName Chat,logFile
        chatFont    Chat,font
    } {
        set chatConfig($localVar) $Config::config($configVar)
    }

    PanedWindow::Create $w.top -size $Config::config(Chat,chatPane) \
        -orient horizontal -height 10 -width 10
    set chatConfig(chatPaneW) $w.top
    set cp1 [PanedWindow::Pane $w.top 1]
    set cp2 [PanedWindow::Pane $w.top 2]

    # Chat is the discussion area
    frame $cp1.chat -relief raised -borderwidth 1
    frame $cp1.chat.box
    set chatConfig(messageTextBox) $cp1.chat.box.t
    set chatConfig($chatConfig(messageTextBox),entry) \
        $chatConfig(messageEntry)
    text $cp1.chat.box.t -width 50 -height 20 -cursor {} -wrap word \
        -spacing1 2 -background $chatConfig(chatBG) -takefocus 0 \
        -foreground $chatConfig(chatFG) -font $chatConfig(chatFont) \
        -yscrollcommand "CrossFire::SetScrollBar $cp1.chat.box.sb"
    $chatConfig(messageTextBox) tag configure system \
        -foreground $chatConfig(chatFG)
    $chatConfig(messageTextBox) tag configure tell -underline 1
    scrollbar $cp1.chat.box.sb -takefocus 0 \
        -command "$cp1.chat.box.t yview"

    grid $cp1.chat.box.t -sticky nsew
    grid columnconfigure $cp1.chat.box 0 -weight 1
    grid rowconfigure $cp1.chat.box 0 -weight 1

    grid $cp1.chat.box -sticky nsew -padx 5 -pady 5
    grid columnconfigure $cp1.chat 0 -weight 1
    grid rowconfigure $cp1.chat 0 -weight 1

    # For some reason, Macintosh will not allow copy from a disabled
    # text widget, so...the following disables all keys except copy. :)
    set copyCommand [bind Text <<Copy>>]
    bind $chatConfig(messageTextBox) <Any-Key> "break"
    bind $chatConfig(messageTextBox) <Button-2> "break"
    bind $chatConfig(messageTextBox) <ButtonRelease-2> \
        "focus $chatConfig(messageEntry); break"
    bind $chatConfig(messageTextBox) <<Copy>> $copyCommand

    grid $cp1.chat -sticky nsew
    grid rowconfigure $cp1 0 -weight 1
    grid columnconfigure $cp1 0 -weight 1

    PanedWindow::Create $cp2.info -height 10 -width 10 \
        -size $Config::config(Chat,realmPane)
    set chatConfig(realmPaneW) $cp2.info
    $cp2.info configure -relief raised -borderwidth 1

    set ip1 [PanedWindow::Pane $cp2.info 1]
    set ip2 [PanedWindow::Pane $cp2.info 2]

    # Realms is the list of channels
    frame $ip1.realms
    label $ip1.realms.l -text "Realms:" -anchor w
    frame $ip1.realms.list
    set chatConfig(realmTextBox) $ip1.realms.list.t
    text $chatConfig(realmTextBox) -width 15 -height 4 -wrap none \
        -background $chatConfig(chatBG) -foreground $chatConfig(chatFG) \
        -exportselection 0 -cursor {} -state disabled -yscrollcommand \
        "CrossFire::SetScrollBar $ip1.realms.list.sb"
    # cget returns the translated font name on Solaris, so get the
    # coded default and use it.
    set chatConfig(fontNormal) \
        [lindex [$chatConfig(realmTextBox) configure -font] 3]
    set chatConfig(fontBold) "$chatConfig(fontNormal) bold"
    $chatConfig(realmTextBox) tag configure select \
        -foreground white -background blue
    scrollbar $ip1.realms.list.sb \
        -command "$chatConfig(realmTextBox) yview"
    grid $ip1.realms.list.t -sticky nsew
    grid columnconfigure $ip1.realms.list 0 -weight 1
    grid rowconfigure $ip1.realms.list 0 -weight 1
    grid $ip1.realms.l -sticky w
    grid $ip1.realms.list -sticky nsew
    grid rowconfigure $ip1.realms 1 -weight 1
    grid columnconfigure $ip1.realms 0 -weight 1

    foreach btn {1 2 3} {
        bind $chatConfig(realmTextBox) <Button-$btn> \
            "Chat::ClickTextBox realm %X %Y $btn"
    }
    bind $chatConfig(realmTextBox) <Double-Button-1> "Chat::ChangeRealm"
    bindtags $chatConfig(realmTextBox) "$chatConfig(realmTextBox) all"

    grid $ip1.realms -sticky nsew -padx 5 -pady 5
    grid rowconfigure $ip1 0 -weight 1
    grid columnconfigure $ip1 0 -weight 1

    # Allies are those in the same realm as the user.
    frame $ip2.allies
    label $ip2.allies.l -anchor w \
        -textvariable Chat::chatConfig(allyLabel)
    frame $ip2.allies.list
    set chatConfig(inRealmTextBox) $ip2.allies.list.t
    text $chatConfig(inRealmTextBox) -width 15 -height 0 \
	-wrap none -selectbackground blue -selectforeground white \
	-selectborderwidth 0 \
        -background $chatConfig(chatBG) -foreground $chatConfig(chatFG) \
        -exportselection 0 -cursor {} -state disabled -yscrollcommand \
        "CrossFire::SetScrollBar $ip2.allies.list.sb"
    $chatConfig(inRealmTextBox) tag configure select \
        -foreground white -background blue
    scrollbar $ip2.allies.list.sb \
        -command "$chatConfig(inRealmTextBox) yview"
    grid $ip2.allies.list.t -sticky nsew
    grid columnconfigure $ip2.allies.list 0 -weight 1
    grid rowconfigure $ip2.allies.list 0 -weight 1
    grid $ip2.allies.l -sticky w
    grid $ip2.allies.list -sticky nsew
    grid rowconfigure $ip2.allies 1 -weight 1
    grid columnconfigure $ip2.allies 0 -weight 1

    foreach btn {1 2 3} {
        bind $chatConfig(inRealmTextBox) <Button-$btn> \
            "Chat::ClickTextBox inRealm %X %Y $btn"
    }
    bind $chatConfig(inRealmTextBox) <Double-Button-1> \
	Chat::CreateIMWindow
    bindtags $chatConfig(inRealmTextBox) "$chatConfig(inRealmTextBox) all"

    grid $ip2.allies -sticky nsew -padx 5 -pady 5
    grid rowconfigure $ip2 0 -weight 1
    grid columnconfigure $ip2 0 -weight 1

    grid $cp2.info -sticky nsew
    grid rowconfigure $cp2 0 -weight 1
    grid columnconfigure $cp2 0 -weight 1

    # The Champions list contains all the users logged in.
    # By default it is hidden.
    frame $w.champions -relief raised -borderwidth 1
    set chatConfig(championFrame) $w.champions
    frame $w.champions.list
    label $w.champions.list.l -anchor w \
        -textvariable Chat::chatConfig(championLabel)
    frame $w.champions.list.list
    set chatConfig(championTextBox) $w.champions.list.list.t
    text $w.champions.list.list.t -width 15 -height 0 -wrap none \
        -exportselection 0 -cursor {} -state disabled \
        -background $chatConfig(chatBG) -foreground $chatConfig(chatFG) \
        -selectbackground blue -selectforeground white -selectborderwidth 0 \
        -yscrollcommand "CrossFire::SetScrollBar $w.champions.list.list.sb"
    $w.champions.list.list.t tag configure select \
        -foreground white -background blue
    scrollbar $w.champions.list.list.sb \
        -command "$w.champions.list.list.t yview"
    grid $w.champions.list.list.t -sticky nsew
    grid columnconfigure $w.champions.list.list 0 -weight 1
    grid rowconfigure $w.champions.list.list 0 -weight 1
    grid $w.champions.list.l -sticky w
    grid $w.champions.list.list -sticky nsew
    grid rowconfigure $w.champions.list 1 -weight 1
    grid columnconfigure $w.champions.list 0 -weight 1

    foreach btn {1 2 3} {
        bind $w.champions.list.list.t <Button-$btn> \
            "Chat::ClickTextBox champion %X %Y $btn"
    }
    bind $w.champions.list.list.t <Double-Button-1> Chat::CreateIMWindow
    bindtags $w.champions.list.list.t "$w.champions.list.list.t all"

    grid $w.champions.list -padx 5 -pady 5 -sticky nsew
    grid rowconfigure $w.champions 0 -weight 1
    grid columnconfigure $w.champions 0 -weight 1

    frame $w.message -relief raised -borderwidth 1
    label $w.message.status -borderwidth 0 -padx 0 -pady 0
    set chatConfig(statusGraphic) $w.message.status
    label $w.message.typing -borderwidth 0 -padx 0 -pady 0 \
	-image imgDisconnected
    set chatConfig(typingStatus) $w.message.typing
    entry $chatConfig(messageEntry) -width 1
    bind $chatConfig(messageEntry) <Key-Return> "Chat::SendMessage"
    bind $chatConfig(messageEntry) <Control-Return> "Chat::Whisper"
    bind $chatConfig(messageEntry) <Alt-Return> "Chat::Whisper"
    bind $chatConfig(messageEntry) <Key-Up> "Chat::RepeatMessage up; break"
    bind $chatConfig(messageEntry) <Key-Down> "Chat::RepeatMessage down; break"
    bind $chatConfig(messageEntry) <Button-3> "tk_popup $w.smiles %X %Y"
    bind $chatConfig(messageEntry) <KeyPress> "Chat::StartTyping"
    # Smile popup menu
    menu $w.smiles -tearoff 1 -title "Smiles"
    set smileCount 0
    foreach icon $chatConfig(smileyList) {
        incr smileCount
        set break 0
        if {$smileCount == 13} {
            set smileCount 0
            set break 1
        }
        $w.smiles add command \
	    -label $chatConfig(smiley,name,$icon) \
	    -accelerator $icon \
            -columnbreak $break \
            -command "$chatConfig(messageEntry) insert insert \{ $icon \}"
	# Mac OSX seems to not work with icons on the menu
	if {$CrossFire::platform != "macintosh"} {
	    $w.smiles entryconfigure end \
		-image $chatConfig(smiley,$icon)
	}
    }

    button $w.message.send -text "Send" -command "Chat::SendMessage" \
        -takefocus 0 -width 8
    button $w.message.whisper -text "Whisper" -command "Chat::Whisper" \
        -takefocus 0 -width 8
    set bHelp "1. Select name above\n"
    append bHelp "2. Type message to left\n"
    append bHelp "3. Click Whisper to send message only to selected name"
    Balloon::Set $w.message.whisper $bHelp
    button $w.message.champ -command "Chat::ShowChampions" -takefocus 0 \
        -textvariable Chat::chatConfig(showHideLabel)
    set chatConfig(showHideLabel) ">>"
    set chatConfig(showHideWidget) $w.message.champ
    grid $w.message.status $w.message.typing $w.message.e $w.message.send \
	$w.message.whisper $w.message.champ -sticky ew -padx 3 -pady 5
    grid columnconfigure $w.message 2 -weight 1
    grid rowconfigure $w.message 0 -weight 1

    grid $w.top     -row 0 -column 0 -sticky nsew
    grid $w.message -row 1 -column 0 -sticky ew   -columnspan 2
    grid rowconfigure $w 0 -weight 1
    grid columnconfigure $w 0 -weight 1

    set chatConfig(championGridArgs) "-row 0 -column 1 -sticky nsew"

    # Load the pre-saved chat colors. Create a default for this user
    # if no color has been previously saved.
    GetTagColors
    set tagName [string tolower $chatConfig(name)]
    if {![info exists chatConfig(color,$tagName)]} {
        SetTagColor $tagName $chatConfig(playerColor) $chatConfig(chatBG) \
            $chatConfig(chatFG) $chatConfig(chatBG) $chatConfig(chatFont)
    }

    if {$Config::config(Chat,expandedView) == "Yes"} {
	ShowChampions
    }

    update idletasks
    grid propagate $w 0

    if {($chatConfig(logFileName) != "") &&
        ($Config::config(Chat,autoLog) == "Yes")} {
        OpenLogFile
    }

    set chatConfig(msgStack) {}
    set chatConfig(msgIndex) -1

    return
}

# Chat::AddMenuBar --
#
#   Adds the menu bar to the chat window.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::AddMenuBar {w} {

    variable chatConfig
    variable plugIn

    menu $w.menubar

    $w.menubar add cascade \
        -label "Chat" \
        -underline 0 \
        -menu $w.menubar.chat

    menu $w.menubar.chat -tearoff 0
    set chatConfig(chatMenu) $w.menubar.chat
    $w.menubar.chat add command \
        -label "Clear Message Window" \
        -underline 1 \
        -accelerator "$CrossFire::accelKey+L" \
        -command "Chat::ClearBox Message"
    $w.menubar.chat add separator
    $w.menubar.chat add checkbutton \
        -label "Arriving Alert" \
        -variable Chat::chatConfig(inAlert) \
        -onvalue 1 -offvalue 0
    $w.menubar.chat add checkbutton \
        -label "Departing Alert" \
        -variable Chat::chatConfig(outAlert) \
        -onvalue 1 -offvalue 0
    $w.menubar.chat add checkbutton \
        -label "Time Stamps" \
        -variable Chat::chatConfig(timeStamp) \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+T" \
        -onvalue 1 -offvalue 0
    $w.menubar.chat add separator
    $w.menubar.chat add command \
        -label "Configure..." \
        -underline 1 \
        -accelerator "$CrossFire::accelKey+O" \
        -command "Config::Create Chat"
    $w.menubar.chat add separator
    $w.menubar.chat add command \
        -label "Log Off" \
        -underline 0 \
        -command "Chat::LogOff"
    set exitLabel "Exit"
    set exitAccelerator "Alt+F4"
    if {$CrossFire::platform == "macintosh"} {
        # This is a Macintosh, so make the exit
        # accelerator more "Mac-ish"
        set exitLabel "Quit"
        set exitAccelerator "Command+Q"
    }
    $w.menubar.chat add command \
        -label $exitLabel \
        -command "Chat::ExitChat" \
        -underline 0 \
        -accelerator $exitAccelerator

    $w.menubar add cascade \
        -label "Game" \
        -underline 0 \
        -menu $w.menubar.game
    menu $w.menubar.game -tearoff 0
    foreach key $plugIn(keyList) {
        if {$key == "-"} {
            $w.menubar.game add separator
        } else {
            $w.menubar.game add command \
                -label $plugIn($key,name) \
                -command $plugIn($key)
        }
    }

    $w.menubar add cascade \
        -label "Log" \
        -underline 0 \
        -menu $w.menubar.log

    menu $w.menubar.log -tearoff 0
    $w.menubar.log add command \
        -label "New..." \
        -command "Chat::SelectLogFile $w Save" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+N"
    $w.menubar.log add command \
        -label "Select..." \
        -command "Chat::SelectLogFile $w Open" \
        -underline 0 \
        -accelerator "$CrossFire::accelKey+S"
    $w.menubar.log add separator
    $w.menubar.log add checkbutton \
        -label "Capture" \
        -variable Chat::chatConfig(writeToLog) \
        -command "Chat::ToggleWrite" \
        -underline 0
    $w.menubar.log add separator
    $w.menubar.log add command \
        -label "View..." \
        -command "Chat::CreateLogViewer \$Chat::chatConfig(logFileName)" \
        -underline 1 \
        -accelerator "$CrossFire::accelKey+I"

    $w.menubar add cascade \
        -label "Action" \
        -underline 0 \
        -menu $w.menubar.action

    menu $w.menubar.action -tearoff 0
    set chatConfig(actionMenu) $w.menubar.action

    $w.menubar add cascade \
        -label "Realm" \
        -underline 0 \
        -menu $w.menubar.realm

    menu $w.menubar.realm -tearoff 0
    $w.menubar.realm add command \
        -label "Create/Join..." \
        -underline 1 \
        -accelerator "$CrossFire::accelKey+R" \
        -command "Chat::CreateRealmGUI"

    $w.menubar add cascade \
        -label "Commands" \
        -underline 1 \
        -menu $w.menubar.commands

    menu $w.menubar.commands -tearoff 1 -title "Chat Commands"
    set chatConfig(commandMenu) $w.menubar.commands

    $w.menubar add cascade \
        -label "Help" \
        -underline 0 \
        -menu $w.menubar.help

    menu $w.menubar.help -tearoff 0
    $w.menubar.help add command \
        -label "Help..." \
        -accelerator "F1" \
        -command "CrossFire::Help chatmain.html" \
        -underline 0
    $w.menubar.help add separator
    $w.menubar.help add command \
        -label "About Chat..." \
        -underline 0 \
        -command "Chat::About $w"

    $w config -menu $w.menubar

    # Chat menu bindings.
    bind $w <$CrossFire::accelBind-o> "Config::Create Chat"
    bind $w <$CrossFire::accelBind-t> {
        set Chat::chatConfig(timeStamp) \
            [expr 1 - $Chat::chatConfig(timeStamp)]
    }

    if {$CrossFire::platform == "macintosh"} {
        bind $w <Command-q> "Chat::LogOff"
    } else {
        bind $w <Alt-F4> "Chat::LogOff; break"
        bind $w <Meta-x> "Chat::LogOff"
    }

    bind $w <$CrossFire::accelBind-n> "Chat::SelectLogFile $w Save"
    bind $w <$CrossFire::accelBind-s> "Chat::SelectLogFile $w Open"
    bind $w <$CrossFire::accelBind-l> "Chat::ClearBox Message"
    bind $w <$CrossFire::accelBind-i> "Chat::CreateLogViewer; break"
    bind $w <$CrossFire::accelBind-r> "Chat::CreateRealmGUI"

    bind $w <Key-F1> "CrossFire::Help chatmain.html"
    bind $w <Key-Help> "CrossFire::Help chatmain.html"

    CreateAllyMenu "Unregistered"

    # menu for right click on realm list
    menu $w.realmMenu -tearoff 0
    $w.realmMenu add command -label "Who??" -command {
        Chat::SendToServer "whochannel $Chat::chatConfig(realmSel)"
    }
    $w.realmMenu add command -label "Join..." \
        -command "Chat::CreateRealmGUI join"

    return
}

# Chat::CreateAllyMenu --
#
#   Creates the ally right click menu.
#
# Parameters:
#   mode       : Users status. (Registered or Unregistered)
#
# Returns:
#   Nothing.
#
proc Chat::CreateAllyMenu {status} {

    variable chatConfig

    set m $chatConfig(topw).allyMenu
    if {[winfo exists $m]} {
        destroy $m
    }

    # menu for right click on ally/champion list
    menu $m -tearoff 0
    $m add command -label "Set Colors..." \
        -command "Chat::ConfigureColors"
    $m add command -label "Where??" -command {
        Chat::SendToServer "where $Chat::chatConfig(championSel)"
    }
    if {$Config::config(Chat,useIMs) == "Yes"} {
        $m add command -label "Private Chat..." \
            -command Chat::CreateIMWindow
    }
    if {$status == "Registered"} {
        $m add command -label "Profile..." -command {
            Chat::SendToServer "whois $Chat::chatConfig(championSel)"
        }
    }
    $m add separator
    $m add command -label "Deselect" \
        -command "Chat::DeselectChampion"

    return
}

# Chat::AddActionMenu --
#
#   Adds the menu of actions to the menu bar.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::AddActionMenu {} {

    variable chatConfig

    set w $chatConfig(topw)

    if {![winfo exists $w]} return

    # Clear out the previous run's action info.
    set chatConfig(actionList) {}
    foreach key [array names chatConfig "action,*"] {
        unset chatConfig($key)
    }

    # Make sure the file exists.
    if {[file exists $Config::config(Chat,actionFile)] == 0} {
        set actionFile \
            [file join $CrossFire::homeDir "Scripts" "Actions.cfa"]
    } else {
        set actionFile $Config::config(Chat,actionFile)
    }

    # Read the list of actions
    set fid [open $actionFile "r"]
    while {[eof $fid] == 0} {
        set line [gets $fid]

        # Skip comments and blank lines.
        if {([llength $line] == 0) || ([regexp "^\#" $line])} {
            continue
        }

        foreach {aKey aName aText} $line {break}
        set aKey [string tolower $aKey]
        lappend chatConfig(actionList) $aName
        set chatConfig(action,key,$aName) $aKey
        set chatConfig(action,$aKey) $aText
    }
    close $fid

    # Destroy previous action menu
    set m $chatConfig(actionMenu)
    $m delete 0 end
    foreach child [winfo children $m] {
        $child delete 0 end
        destroy $child
    }

    # Build new multi-cascadeing action menu
    set actionList [lsort $chatConfig(actionList)]
    set count 1
    set cascadeCount 0
    set cascadeLines 20 ;# Number of lines per cascade
    foreach action $actionList {
        if {$count == 1} {
            # Create a new cascade
            set lastIndex [expr ($cascadeCount + 1) * $cascadeLines - 1]
            if {$lastIndex > [llength $actionList]} {
                set lastIndex end
            }
            set cw $m.list[incr cascadeCount]
            set last [lindex $actionList $lastIndex]
            $m add cascade \
                -label "$action - $last" -menu $cw
            menu $cw -tearoff 1 -title "Actions $cascadeCount"
        } elseif {$count == $cascadeLines} {
            # Reset counter to 0 so it will be 1 on the next iteration.
            set count 0
        }
        $cw add command \
            -label $action \
            -command "Chat::SendAction $chatConfig(action,key,$action)"
        incr count
    }

    return
}

# Chat::ClickTextBox --
#
#   Handles clicking the text box to make it appear more like a listbox.
#
# Parameters:
#   which      : Which text box (realm, inRealm, champion)
#   X, Y       : %X, %Y from them bind
#   btn        : Button number
#
# Returns:
#   Nothing.
#
proc Chat::ClickTextBox {which X Y btn} {

    variable chatConfig

    set tbw $chatConfig(${which}TextBox)

    if {($which == "inRealm") || ($which == "champion")} {
        set chatConfig(selectionAt) $which
        set userList 1
    } else {
        set userList 0
    }

    if {$X == "m"} {
        if {$Y == "end" } {
            set pos [expr int([$tbw index end]) - 1]
        } else {
            set pos $Y
        }
    } else {

        # Translate X,Y coordinates to textbox x,y and determine line number.
        set x [expr $X - [winfo rootx $tbw]]
        set y [expr $Y - [winfo rooty $tbw]]
        set pos [expr int([$tbw index @$x,$y])]
    }

    # Remove current selection, if any. Remove selection from both
    # lists of users, of clicking on one of them.
    if {$userList == 1} {
        $chatConfig(inRealmTextBox)  tag remove select 1.0 end
        $chatConfig(championTextBox) tag remove select 1.0 end
    } else {
        $tbw tag remove select 1.0 end
    }

    if {[$tbw get 1.0 end] == "\n"} {
        # Nothing in the text box
        return
    } elseif {[$tbw get $pos.0 [expr $pos + 1].0] == "\n"} {
        # Clicked below the last line.
        incr pos -1
    }

    $tbw tag add select $pos.0 [expr $pos + 1].0
    $tbw see $pos.0

    if {$userList == 1} {
        set chatConfig(championSel) [lindex [$tbw get $pos.0 $pos.end] 0]
        if {$btn == 3} {
            tk_popup $chatConfig(topw).allyMenu $X $Y
        }
    } else {
        set chatConfig(realmSel) [lindex [$tbw get $pos.0 $pos.end] 0]
        if {$btn == 3} {
            tk_popup $chatConfig(topw).realmMenu $X $Y
        }
    }

    return
}

# Chat::SetTagColor --
#
#   Configures the tags for a Champions colors. Saves colors in configuration.
#
# Parameters:
#   tag        : The tag to color. IE: user's name
#   nameFG     : Foreground color for Champion's name.
#   nameBG     : Background color for Champion's name.
#   textFG     : Foreground color for Champion's text.
#   textBG     : Background color for Champion's text.
#   font       : Font for the champion's name and text.
#
# Returns:
#   Nothing.
#
proc Chat::SetTagColor {tag nameFG nameBG textFG textBG {font ""}} {

    variable chatConfig

    # Force tag to be lower case.
    set tagName [string tolower $tag]

    set chatConfig(color,$tagName) 1

    Config::AddChatColor $tagName $nameFG $nameBG $textFG $textBG $font

    # An old tag. Update with default font.
    if {$font == ""} {
        set font $chatConfig(chatFont)
    }

    $chatConfig(messageTextBox) tag configure "${tagName}-name" \
        -foreground $nameFG -background $nameBG -font $font
    $chatConfig(messageTextBox) tag configure "${tagName}-text" \
        -foreground $textFG -background $textBG -font $font

    foreach imText [array names chatConfig "im,text,*"] {
        $chatConfig($imText) tag configure "${tagName}-name" \
            -foreground $nameFG -background $nameBG -font $font
        $chatConfig($imText) tag configure "${tagName}-text" \
            -foreground $textFG -background $textBG -font $font
    }

    # This magic little line (discovered by Bryan) makes the selection work
    # on all the text...even those lines with configured background color!
    $chatConfig(messageTextBox) tag raise sel

    return
}

# Chat::GetTagColors --
#
#   Gets all the saved Champion's chat colors and sets the color tags.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::GetTagColors {} {

    variable chatConfig

    foreach colorSet [Config::GetChatColors] {
        eval SetTagColor $colorSet
    }

    return
}

# Chat::ConfigureColors --
#
#   Creates or updates the interface for configuring the colors for a user.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::ConfigureColors {} {

    variable chatConfig

    set w $chatConfig(topw).configColor
    set chatConfig(colorConfig) $w
    set who [string tolower $chatConfig(championSel)]

    if {[winfo exists $w]} {
        wm deiconify $w
        raise $w
    } else {
        toplevel $w
        bind $w <Key-Escape> "$w.btns.close invoke"

        CrossFire::Transient $w

        frame $w.top -borderwidth 1 -relief raised
        foreach {wid type lbl} {
            nameFG   Color {Name Foreground:}
            nameBG   Color {Name Background:}
            textFG   Color {Text Foreground:}
            textBG   Color {Text Background:}
            textFont Font  {Text Font:}
        } {
            label $w.top.l$wid -text $lbl -anchor e
            label $w.top.cw$wid -width 6
            set chatConfig(colorW$wid) $w.top.cw$wid
            button $w.top.s$wid -text "Select..." \
                -command "Chat::SetCustom$type $wid"
            grid $w.top.l$wid $w.top.cw$wid $w.top.s$wid -padx 5 -pady 3 \
                -sticky ew
        }
        grid $w.top -sticky nsew
        grid columnconfigure $w.top 1 -weight 1

        frame $w.btns -borderwidth 1 -relief raised
        button $w.btns.default -text "Default" \
            -command "Chat::SetDefaultColors"
        button $w.btns.close -text $CrossFire::close -command "destroy $w"
        grid $w.btns.default $w.btns.close -pady 3 -padx 5
        grid $w.btns -sticky ew

        grid columnconfigure $w 0 -weight 1
        grid rowconfigure $w 0 -weight 1
    }

    wm title $w "Set $chatConfig(championSel)'s Colors"

    foreach {wid tagPart which} {
        nameFG   name -foreground
        nameBG   name -background
        textFG   text -foreground
        textBG   text -background
    } {
        set chatConfig($wid) \
            [$chatConfig(messageTextBox) tag cget "${who}-$tagPart" $which]
        $chatConfig(colorW$wid) configure -background $chatConfig($wid)
    }
    set chatConfig(textFont) \
        [$chatConfig(messageTextBox) tag cget "${who}-name" -font]
    $w.top.cwtextFont configure -text "ABCabc" -font $chatConfig(textFont)

    return
}

# Chat::SetCustomColor --
#
#   Updates the color changes for a user in the message box.
#
# Parameters:
#   var        : Variable to change (nameFG, TextFG, etc)
#
# Returns:
#   Nothing.
#
proc Chat::SetCustomColor {var} {

    variable chatConfig

    set color [tk_chooseColor -initialcolor $chatConfig($var) \
                   -parent $chatConfig(colorConfig)]

    if {$color == ""} {
        return
    }

    set chatConfig($var) $color
    $chatConfig(colorW$var) configure -background $chatConfig($var)

    SetCustomTextSettings

    return
}

# Chat::SetCustomFont --
#
#   Updates the font changes for a user in the message box.
#
# Parameters:
#   var        : Variable to change (textFont)
#
# Returns:
#   Nothing.
#
proc Chat::SetCustomFont {var} {

    variable chatConfig

    set font [tk_chooseFont -initialfont $chatConfig($var) \
                   -parent $chatConfig(colorConfig)]

    if {$font == ""} {
        return
    }

    set chatConfig($var) $font
    $chatConfig(colorW$var) configure -font $font

    SetCustomTextSettings

    return
}

# Chat::SetCustomTextSettings --
#
#   Updates the colors and font settings for a champion.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::SetCustomTextSettings {} {

    variable chatConfig

    SetTagColor $chatConfig(championSel) $chatConfig(nameFG) \
        $chatConfig(nameBG) $chatConfig(textFG) $chatConfig(textBG) \
        $chatConfig(textFont)

    return
}

# Chat::SetDefaultColors --
#
#   Sets the colors and font back to the defaults.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::SetDefaultColors {} {

    variable chatConfig

    if {[string tolower $chatConfig(championSel)] == \
            [string tolower $chatConfig(name)]} {
        set nameColor $chatConfig(playerColor)
    } else {
        set nameColor $chatConfig(newChamp)
    }

    $chatConfig(colorWnameFG) configure -background $nameColor
    $chatConfig(colorWnameBG) configure -background $chatConfig(chatBG)
    $chatConfig(colorWtextFG) configure -background $chatConfig(chatFG)
    $chatConfig(colorWtextBG) configure -background $chatConfig(chatBG)
    $chatConfig(colorWtextFont) configure -font $chatConfig(chatFont)

    set chatConfig(nameFG) $nameColor
    set chatConfig(nameBG) $chatConfig(chatBG)
    set chatConfig(textFG) $chatConfig(chatFG)
    set chatConfig(textBG) $chatConfig(chatBG)
    set chatConfig(textFont) $chatConfig(chatFont)

    SetTagColor $chatConfig(championSel) $nameColor \
        $chatConfig(chatBG) $chatConfig(chatFG) $chatConfig(chatBG) \
        $chatConfig(textFont)

    return
}

# Chat::ShowChampions --
#
#   Shows the champion list and changes the button to hide it.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::ShowChampions {} {

    variable chatConfig

    set chatConfig(showHideLabel) "<<"
    $chatConfig(showHideWidget) configure -command "Chat::HideChampions"
    eval grid $chatConfig(championFrame) $chatConfig(championGridArgs)
    grid columnconfigure $chatConfig(topw) 0 -weight 1
    update
    $chatConfig(messageTextBox) see end

    return
}

# Chat::HideChampions --
#
#   Hides the champion list and changes the button to show it.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::HideChampions {} {

    variable chatConfig

    set chatConfig(showHideLabel) ">>"
    $chatConfig(showHideWidget) configure -command "Chat::ShowChampions"
    grid forget $chatConfig(championFrame)
    set w $chatConfig(topw)
    grid columnconfigure $w 0 -weight 1
    grid columnconfigure $w 1 -weight 0

    return
}

# Chat::LoginOK --
#
#   Called via a trace.  Raises the client window.  This is done to prevent
#   the client window from appearing if a login error occurs.
#
# Parameters:
#   args       : Junk from trace command.
#
# Returns:
#   Nothing.
#
proc Chat::LoginOK {args} {

    variable chatConfig

    trace vdelete Chat::chatConfig(map) w Chat::LoginOK

    LoginStatus ""

    wm deiconify $chatConfig(topw)
    focus $chatConfig(messageEntry)

    # We got in, so make sure auto logins are allowed
    # (until a failure occurs, of course)
    set chatConfig(autoLogIn) "Yes"

    # Check if profile was updated in Configure while offline.
    if {$Config::config(Chat,lastProfileChange) == "offline"} {
        SendProfileToServer
        Config::Set Chat,lastProfileChange "online"
    }

    # Switch to our Home realm and send our Hello message.
    if {$chatConfig(profile,Home) != ""} {
        SendToServer "join $chatConfig(profile,Home)"
    }
    if {$chatConfig(profile,LogonMsg) != ""} {
        SendToServer "emote $chatConfig(profile,LogonMsg)"
    }

    # So we don't get spammed with beeps....
    set chatConfig(displayUp) 1

    return
}

# Chat::LogOff --
#
#   Called when logging out of chat.
#
# Parameters:
#   abort      : Optional param used when connection is lost.
#
# Returns:
#   Nothing.
#
proc Chat::LogOff {{abort 0}} {

    variable chatConfig

    LoginStatus ""

    if {$chatConfig(online) == 0} {
        return
    }

    if {$abort == 0} {
        # Send a goodbye to the server
        if {$chatConfig(profile,LogoffMsg) != ""} {
            SendToServer "emote $chatConfig(profile,LogoffMsg)"
        }
        SendToServer "quit"
    }

    # Close the connection
    close $chatConfig(cid)

    OnlineStatus 0

    if {$abort == 1} {
        if {![info exists chatConfig(serverMsg)]} {
            set msg "You have been wished away from the CrossFire Server!!"
            tk_messageBox -icon warning -title "Connection Lost" \
                -message $msg
        }
        set chatConfig(autoLogIn) "No"
    }

    # Close the log file, if one is open.
    CloseLogFile

    AddToMessageBox [list "<You have logged off.>" system]
    ClearBox InChannel
    ClearBox User
    ClearBox Channel

    return
}

# Chat::ExitChat --
#
#   Closes the chat window.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::ExitChat {args} {

    variable chatConfig
    variable plugIn

    foreach killCommand $plugIn(killCommand) {
        if {[eval $killCommand] == 1} {
            return 1
        }
    }

    if {$chatConfig(online) == 1} {
        LogOff
    }

    set chatConfig(displayUp) 0

    ViewCard::CleanUpCardViews $chatConfig(topw)
    Config::Set Chat,geometry [wm geometry $chatConfig(topw)]
    Config::Set Chat,chatPane \
        [PanedWindow::Position $chatConfig(chatPaneW) 1]
    Config::Set Chat,realmPane \
        [PanedWindow::Position $chatConfig(realmPaneW) 1]

    DoneTyping
    destroy $chatConfig(topw)

    # Remove color configurations
    foreach key [array names chatConfig "color,*"] {
        unset chatConfig($key)
    }

    # Remove IM window info
    foreach key [array names chatConfig "im,*"] {
        unset chatConfig($key)
    }

    CrossFire::UnRegister Chat $chatConfig(topw)

    return 0
}

# Chat::SendMessage --
#
#   Sends a typed message to the server.  Calls SendToServer which
#   actually sends the message.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::SendMessage {} {

    variable chatConfig
    variable plugIn

    set msgText [GetMessageText]

    if {$msgText == ""} {
        return
    }

    if {[string length $msgText] > 1000} {
        tk_messageBox -title "Error Sending Message" -icon error \
            -message "Your message exceeds the 1,000 character limit." \
            -parent $chatConfig(topw)
        return
    }

    AddToMessageStack $msgText

    if {[regexp "^/" $msgText]} {
        # SPINS command
        regsub "^/" $msgText "" msgText
        set first [lindex [split $msgText " "] 0]

        # Joining a new realm, so send the realm goodbye to the current realm.
        if {[regexp -nocase "^joi?n?\$" $first]} {
            regsub -all " " [lrange [split $msgText " "]  1 end] "_" newRealm
            set current [string tolower $chatConfig(inRealm)]
            if {([string tolower $newRealm] != 
                 [string tolower $chatConfig(inRealm)]) &&
                !(($newRealm == "") && ($current == "main")) &&
                ($chatConfig(profile,LeaveMsg) != "")} {
                SendToServer "emote $chatConfig(profile,LeaveMsg)"
            }
        }

        SendToServer $msgText
    } elseif {[regexp "^\#" $msgText]} {
        # An action
        regsub "^\#" $msgText "" msgText
        set actionName [string tolower [lindex $msgText 0]]
        SendAction $actionName [lindex $msgText 1]
    } elseif {[info exists plugIn($msgText)]} {
        eval $plugIn($msgText)
    } else {
        # Regular message.
        SendToServer "say $msgText"
    }

    ClearMessageText

    return
}

# Chat::AddToMessageStack --
#
#   Adds a message to the message stack if not the same as the last one.
#
# Parameters:
#   msgText    : Text message to add.
#
# Returns:
#   Nothing.
#
proc Chat::AddToMessageStack {msgText} {

    variable chatConfig

    if {$msgText != [lindex $chatConfig(msgStack) 0]} {
        set chatConfig(msgStack) \
            [linsert $chatConfig(msgStack) 0 $msgText]
    }
    set chatConfig(msgIndex) -1

    return
}

# Chat::RepeatMessage --
#
#    This routine handles key up and down in the command interface.
#
# Parameters:
#    direction : Direction to get next line in the stack (up or down).
#
# Returns:
#    Nothing.
#
proc Chat::RepeatMessage {direction} {

    variable chatConfig

    switch $direction {
        "up" {
            if {$chatConfig(msgIndex) < \
                    [expr [llength $chatConfig(msgStack)] - 1]} {
                incr chatConfig(msgIndex)
            } else {
                bell
            }
            set msg [lindex $chatConfig(msgStack) $chatConfig(msgIndex)]
        }
        "down" {
            if {$chatConfig(msgIndex) > 0} {
                incr chatConfig(msgIndex) -1
                set msg [lindex $chatConfig(msgStack) $chatConfig(msgIndex)]
            } elseif {$chatConfig(msgIndex) == 0} {
                incr chatConfig(msgIndex) -1
                set msg ""
            } else {
                bell
                return
            }
        }
    }

    # Put the message into the text entry widget
    ClearMessageText
    $chatConfig(messageEntry) insert end $msg

    return
}

# Chat::RandomNoOne --
#
#   Returns one of the names to use for no one.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::RandomNoOne {} {

    variable chatConfig

    set num [expr int(rand() * [llength $chatConfig(noBody)])]

    return [lindex $chatConfig(noBody) $num]
}

# Chat::SendAction --
#
#   Sends an action command to the server.  If who is not specified,
#   the selected champion will be used...if none selected, who be
#   be defaulted to a random nobody such as "no one".
#
# Paramters:
#   action    : Action id
#   who       : Optional parameter for who to target
#
# Returns:
#   Nothing.
#
proc Chat::SendAction {actionName {who ""}} {

    variable chatConfig

    if {$who == ""} {
        if {$chatConfig(championSel) == ""} {
            set who [RandomNoOne]
        } else {
            set who $chatConfig(championSel)
            if {[info exists chatConfig(champ,[string tolower $who])] == 0} {
                set who [RandomNoOne]
            }
        }
    }

    set cfVersion $CrossFire::crossFireVersion

    if {[info exists chatConfig(action,$actionName)]} {
        if {[catch {
            set action [subst -nocommands $chatConfig(action,$actionName)]
        } err]} {
            set msgText "emote has tried to play an unknown event..."
        } else {
            set msgText "emote $action"
        }
    } else {
        # should warn or something
        set msgText "emote has tried to cast an unknown spell at $who..."
    }

    SendToServer $msgText

    return
}

# Chat::DeselectChampion --
#
#   Removes the highlighting and variable storage of the selected champion.
#   This is used mainly to play with the random nobodies.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::DeselectChampion {} {

    variable chatConfig

    set chatConfig(championSel) ""
    foreach textBox {inRealmTextBox championTextBox} {
        $chatConfig($textBox) tag remove select 1.0 end
    }

    return
}

# Chat::SendToServer --
#
#   This procedure sends any string (command) to SPINS.
#
# Parameters:
#   msg        : Message to send.
#
# Returns:
#   Nothing.
#
proc Chat::SendToServer {msg} {

    variable chatConfig

    if {$chatConfig(online) == 0} {
        Login
        return
    }

    # Newlines cause some problems...change to a key.
    regsub -all -- "\[\r\n\]" $msg "~NL~" msg

    # Send the string to SPINS
    if {[catch {puts $chatConfig(cid) $msg} err]} {
        tk_messageBox -title "Error Sending to Server" -icon error \
            -message "An error occured:\n$err" -parent $chatConfig(topw)
    } else {
        if {[catch {flush $chatConfig(cid)} err]} {
            LogOff 1
        }
    }

    return
}

# Chat::Whisper --
#
#   Sends a whisper to the selected user.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::Whisper {} {

    variable chatConfig

    if {$chatConfig(championSel) == ""} {
        tk_messageBox -icon error -title "Whisper Error" \
            -message "You must select someone on the champion list."
    } else {
        set msgText [GetMessageText]
        if {$msgText != ""} {
            SendToServer "tell $chatConfig(championSel) $msgText"
            AddToMessageStack $msgText
            ClearMessageText
        }
    }

    return
}

# Chat::GetMessageText --
#
#   Gets the string the user typed in the entry widget.
#
# Parameters:
#   None.
#
# Returns:
#   The message in the entry widget.
#
proc Chat::GetMessageText {} {

    variable chatConfig

    return [$chatConfig(messageEntry) get]
}

# Chat::ClearMessageText --
#
#   Clears the message entry widget.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::ClearMessageText {} {

    variable chatConfig

    DoneTyping
    $chatConfig(messageEntry) delete 0 end

    return
}

# Chat::MessageBox --
#
#   Displays a message from the server.
#
# Parameters:
#   msg
#
# Returns:
#   Nothing.
#
proc Chat::MessageBox {type msg} {

    variable chatConfig

    # chatConfig(serverMsg) lets client code know a message from the server
    # is waiting for user response.
    set chatConfig(serverMsg) 1
    tk_messageBox -icon $type -title "SPINS Server Message" -message $msg
    unset chatConfig(serverMsg)

    return
}

# Chat::ReceiveFromServer --
#
#   Called when receiving data from the server.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::ReceiveFromServer {} {

    variable chatConfig

    set chID $chatConfig(cid)
    if {[eof $chID] || [gets $chID cmd] < 0} {
        LogOff 1
    } else {

        # Execute the command from the server in the safe interpreter
        catch {
            safeInterp eval $cmd
        } err

        if {$err != ""} {
            dputs "ERROR from Chat: $err"
        }
    }

    return
}

# Chat::CreateRealmGUI --
#
#   Creates an interface for the user to enter a new realm name to create.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::CreateRealmGUI {args} {

    variable chatConfig

    set tw $chatConfig(topw).newch

    if {[winfo exists $tw]} {
        wm deiconify $tw
        raise $tw
    } else {
        toplevel $tw
        wm protocol $tw WM_DELETE_WINDOW "$tw.buttons.cancel invoke"
        bind $tw <Key-Escape> "$tw.buttons.cancel invoke"

        CrossFire::Transient $tw

        frame $tw.top -borderwidth 1 -relief raised
        label $tw.top.nameLabel -text "Realm Name:" -anchor e
        entry $tw.top.nameEntry -width 35 \
            -textvariable Chat::chatConfig(newRealm)
        label $tw.top.passwordLabel -text "Password (Optional):" -anchor e
        entry $tw.top.passwordEntry -width 35 \
            -textvariable Chat::chatConfig(realmPassword)
        set chatConfig(realmPassword) ""
        grid $tw.top.nameLabel $tw.top.nameEntry \
            -sticky ew -padx 5 -pady 5
        grid $tw.top.passwordLabel $tw.top.passwordEntry \
            -sticky ew -padx 5 -pady 5
        grid columnconfigure $tw.top 1 -weight 1
        grid $tw.top -sticky nsew

        bind $tw <Key-Return> "$tw.buttons.ok invoke"

        frame $tw.buttons -borderwidth 1 -relief raised
        button $tw.buttons.ok -command "Chat::CreateRealm; destroy $tw"
        button $tw.buttons.cancel -text "Cancel" -command "destroy $tw"
        grid $tw.buttons.ok $tw.buttons.cancel -padx 5 -pady 5

        grid $tw.buttons -sticky nsew
        grid columnconfigure $tw 0 -weight 1
        grid rowconfigure $tw 0 -weight 1
    }

    if {$args == "join"} {
        wm title $tw "Join Realm"
        $tw.buttons.ok configure -text "Join"
        set chatConfig(newRealm) $chatConfig(realmSel)
        focus $tw.top.passwordEntry
    } else {
        wm title $tw "Create New Realm"
        $tw.buttons.ok configure -text "Create"
        set chatConfig(newRealm) ""
        focus $tw.top.nameEntry
    }

    return
}

# Chat::CreateRealm --
#
#   Formats the server command for creating or joining a realm.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::CreateRealm {} {

    variable chatConfig

    if {$chatConfig(newRealm) == ""} {
        return
    }

    # Change evil spaces to underscore
    regsub -all " " $chatConfig(newRealm) "_" newRealm

    if {$newRealm == $chatConfig(inRealm)} {
        return
    }

    # Joining a new realm, so send the realm goodbye to the current realm.
    if {$chatConfig(profile,LeaveMsg) != ""} {
        SendToServer "emote $chatConfig(profile,LeaveMsg)"
    }

    if {[info exists chatConfig(realm,[string tolower $newRealm])]} {
        # Realm exists
        if {$chatConfig(realmPassword) == ""} {
            SendToServer "join $newRealm"
        } else {
            SendToServer "join $newRealm \#$chatConfig(realmPassword)\#"
        }
    } else {
        # No such realm
        SendToServer "join $newRealm"
        if {$chatConfig(realmPassword) != ""} {
            SendToServer "lock $chatConfig(realmPassword)"
        }
    }

    return
}

# Chat::ChangeRealm --
#
#   Handles changing realms from double clicking on the realm name.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::ChangeRealm {} {

    variable chatConfig

    set tbw $chatConfig(realmTextBox)

    set start [lindex [$tbw tag ranges select] 0]
    if {$start != ""} {
        set end [lindex [split $start "."] 0].end
        set newRealm [lindex [$tbw get $start $end] 0]
        if {$newRealm != $chatConfig(inRealm)} {
            # Joining a new realm, so send the realm goodbye to the current realm.
            if {$chatConfig(profile,LeaveMsg) != ""} {
                SendToServer "emote $chatConfig(profile,LeaveMsg)"
            }
            SendToServer "join $newRealm"
        }
    }

    return
}

# Chat::ClearBox --
#
#   Called by SPINS, this clears one of the chatroom boxes.
#
# Parameters:
#   which      : Which box to clear. (InChannel, User, Channel, Message, IM)
#   who        : Only used with IM windows.
#
# Returns:
#   Nothing.
#
proc Chat::ClearBox {which {who ""}} {

    variable chatConfig

    switch -- $which {
        "Message" {
            $chatConfig(messageTextBox) delete 1.0 end
        }
        "IM" {
            $chatConfig(im,text,$who) delete 1.0 end
        }
        "Channel" {
            set tbw $chatConfig(realmTextBox)
            $tbw configure -state normal
            $tbw delete 1.0 end
            $tbw configure -state disabled
            foreach key [array names chatConfig "realm,*"] {
                unset chatConfig($key)
            }
        }
        "InChannel" {
            set chatConfig(allyList) ""
            set tbw $chatConfig(inRealmTextBox)
            $tbw configure -state normal
            $tbw delete 1.0 end
            $tbw configure -state disabled
            set chatConfig(allyLabel) "Allies:"
        }
        "User" {
            set tbw $chatConfig(championTextBox)
            $tbw configure -state normal
            $tbw delete 1.0 end
            $tbw configure -state disabled
            foreach key [array names chatConfig "champ,*"] {
                unset chatConfig($key)
            }
            set chatConfig(championLabel) "Champions:"
        }
    }

    return
}

# Chat::AddToBox --
#
#   Called by SPINS, this adds to one of the chatroom boxes.
#
# Parameters:
#   which      : Which box. (InChannel, User, Channel, Message)
#   data       : Appropriate data for the box.
#
# Returns:
#   Nothing.
#
proc Chat::AddToBox {which data} {

    variable chatConfig

    switch -- $which {
        "Message" {
            AddToMessageBox $data
        }
        "Channel" {
	    # Realms
            set tbw $chatConfig(realmTextBox)
            $tbw configure -state normal
            set tagName [lindex $data 0]
            $tbw tag configure $tagName -font $chatConfig(fontNormal)
            $tbw insert end "$data\n" $tagName
            $tbw configure -state disabled
            set chatConfig(realm,[string tolower $tagName]) 1
        }
        "InChannel" {
	    # Allies
            set tbw $chatConfig(inRealmTextBox)
            $tbw configure -state normal
            $tbw insert end "$data\n"
            $tbw configure -state disabled
            lappend chatConfig(allyList) [lindex $data 0]
            if {([lindex $data 0] == $chatConfig(championSel)) &&
                ($chatConfig(selectionAt) == "inRealm")} {
                ClickTextBox inRealm m end 1
            }
            set qty [expr int([$tbw index end] - 2)]
            set chatConfig(allyLabel) "Allies ($qty):"
        }
        "User" {
	    # Champions
            set tbw $chatConfig(championTextBox)
            $tbw configure -state normal
            $tbw insert end "$data\n"
            $tbw configure -state disabled
            if {([lindex $data 0] == $chatConfig(championSel)) &&
                ($chatConfig(selectionAt) == "champion")} {
                ClickTextBox champion m end 1
            }
            set qty [expr int([$tbw index end] - 2)]
            set chatConfig(championLabel) "Champions ($qty):"
            set nameLower [lindex [string tolower $data] 0]
            if {![info exists chatConfig(color,$nameLower)]} {
                SetTagColor $nameLower $chatConfig(newChamp) \
                    $chatConfig(chatBG) $chatConfig(chatFG) \
                    $chatConfig(chatBG) $chatConfig(chatFont)
            }
            set chatConfig(champ,$nameLower) 1
        }
    }

    return
}

# Chat::AddToMessageBox --
#
#   Adds text to the message window.
#
# Parameters:
#   data       : Text to add.
#
# Returns:
#   Nothing.
#
proc Chat::AddToMessageBox {data} {

    variable chatConfig
    variable replacement
    variable plugIn

    # Change the newline key back into a newline.
    regsub -all -- "~NL~" $data "\n" data

    set tbw $chatConfig(messageTextBox)
    set logString ""
    set first [lindex $data 0]
    set newRealm 0
    set isWhisper 0
    if {$Config::config(Chat,useIMs) == "Yes"} {
        set useIM 1
    } else {
        set useIM 0
    }

    # Look at the incoming line for things we dont want to show.
    if {[regexp "^<Current status:" $first]} {
        # Status line: update the menu bar commands.
        UpdateUserCommands $first
        return
    } elseif {[regexp "^<Setting your protocol to" $first]} {
	return
    } elseif {([regexp "^<Changing from Realm" $first]) &&
              ($chatConfig(displayUp) == 1)} { 
        # Entering a new realm, so send the realm entrance message.
        set newRealm 1
    } elseif {[regexp "^<(.+) tells you>\$" $first match who]} {
        # Receiving a whisper command. Check for plug-in
        set whisper [lindex $data 2]
        set firstWord [lindex [split $whisper " "] 1]
        if {[info exists plugIn($firstWord)]} {
            eval $plugIn($firstWord,receive) $whisper
            return
        } elseif {[regexp "^\!" $firstWord]} {
            # message from a plug-in that is not installed.
            return
        }
        if {$useIM} {
            set isWhisper 1
            set data [lreplace $data 0 0 "$who:"]
        }
    } elseif {[regexp "^<You tell (.+)>\$" $first match who]} {
        # Sending a whisper command. Check for plug-in
        set whisper [lindex $data 2]
        set firstWord [lindex [split $whisper " "] 1]
        if {[info exists plugIn($firstWord)]} {
            return
        }
        if {$useIM} {
            set isWhisper 2
            set data [lreplace $data 0 0 "$chatConfig(name):"]
        }
    }

    # Determine which text window to display message in.
    if {($isWhisper) && ($useIM)} {
        if {$isWhisper == 2} {
            set me [string tolower $chatConfig(name)]
            set you [string tolower $who]
            regsub -all "$you\-" $data "$me-" data
        }
        set tbw [CreateIMWindow $who]
    }

    # Audible notice when receiving a message and the chat window is iconified
    if {([wm state $chatConfig(topw)] != "normal") &&
        ($chatConfig(displayUp) == 1)} {
        if {($Config::config(Sound,ChatRcv,file) == "None") ||
            ($Config::config(Sound,play) == "No")} {
            bell
            after 150
        } else {
            CrossFire::PlaySound ChatRcv
        }
    }

    if {[$tbw bbox end-1c] != ""} {
        set goToEnd 1
    } else {
        set goToEnd 0
    }

    # Insert the timestamp.
    if {$chatConfig(timeStamp) == 1 && $data != "\n"} {
        if {$Config::config(Chat,timeMode) == "24"} {
            set form "%T "
        } else {
            set form "%I:%M:%S %p " ;# add %p for AM/PM
        }
        set timeStamp [clock format [clock seconds] -format $form]
        $tbw insert end $timeStamp system
    } else {
        set timeStamp ""
    }

    foreach {text tag} $data {
        set first 1
        set tellPos [lsearch $tag "tell"]
        if {($useIM) && ($tellPos != -1)} {
            set tag [lreplace $tag $tellPos $tellPos]
        }

        foreach word [split $text " "] {
            if {$first == 0} {
                $tbw insert end " " $tag
            } else {
                set first 0
            }
            if {[info exists replacement([string tolower $word])]} {
                set word $replacement([string tolower $word])
            }
            if {[regexp "^http://" $word] || [regexp "^www\." $word]} {
                # URLs
                AddLink $tbw $word "CrossFire::OpenURL $word"
	    } elseif {[regexp "^mailto:" $word] ||
		      [regexp "^.*\\@.*\\..*" $word]} {
		# EMail URL
		if {![regexp "^mailto:" $word]} {
		    set myEmail "mailto:$word"
		} else {
		    set myEmail $word
		    regsub "^mailto:" $word "" word
		}
		AddLink $tbw $word "CrossFire::OpenURL $myEmail"
            } elseif {[regexp "^\[a-zA-Z0-9\]+/\[0-9\]+$" $word]} {
                # Card "URLs"
                regsub -nocase "^TU/" $word "UD/" word
		foreach {tSetID tCardNum} [CrossFire::DecodeShortID $word] {}
		if {([CrossFire::GetValidSetID $tSetID] != "") &&
		    ($tCardNum > 0) &&
		    ($tCardNum <= $CrossFire::setXRef($tSetID,lastNumber))} {
		    AddLink $tbw $word \
                        "ViewCard::View $chatConfig(topw) $word" card
		} else {
		    # Regular text: do the same as a few lines down
		    $tbw insert end $word $tag
		}
            } elseif {[info exists chatConfig(smiley,$word)]} {
                $tbw image create end -image $chatConfig(smiley,$word)
            } else {
		# Regular text, just insert it. see above a few lines
                $tbw insert end $word $tag
            }
        }
        append logString $text
    }

    WriteToLog "$timeStamp$logString"

    $tbw insert end "\n"
    if {$goToEnd == 1} {
        $tbw see end
        update
    }

    # Alert for arriving champion
    if {$chatConfig(inAlert) == 1} {
        if {[regexp "^<(\[^>\]*) has logged on" $logString match who]} {
            after 250
	    if {($Config::config(Sound,ChatLogin,file) == "None") ||
		($Config::config(Sound,play) == "No")} {
		bell
	    } else {
		CrossFire::PlaySound ChatLogin
	    }
        }
    }

    # Alert for leaving champion
    if {$chatConfig(outAlert) == 1} {
        if {[regexp "^<(\[^>\]*) has logged off>" $logString match who]} {
            after 250
	    if {($Config::config(Sound,ChatLogout,file) == "None") ||
		($Config::config(Sound,play) == "No")} {
		bell
	    } else {
		CrossFire::PlaySound ChatLogout
	    }
        }
    }

    if {($newRealm == 1) && ($chatConfig(profile,EnterMsg) != "")} {
        SendToServer "emote $chatConfig(profile,EnterMsg)"
    }

    return
}

# Chat::AddLink --
#
#  Adds a clickable link to the chat message window.
#
# Parameters:
#   tbw        : Textbox widget path
#   word       : The word to make clickable.
#   cmd        : Command to execute when clicked on.
#
# Returns:
#   Nothing.
#
proc Chat::AddLink {tbw word cmd {type HTML}} {

    variable chatConfig

    set tag link[incr chatConfig(linkCount)]

    $tbw tag configure $tag -underline 1 -foreground \
        $Config::config(Chat,urlColor)
    $tbw tag bind $tag <Enter> "$tbw configure -cursor hand2"
    $tbw tag bind $tag <Leave> "$tbw configure -cursor {}"
    $tbw tag bind $tag <ButtonRelease-1> $cmd
    $tbw tag bind $tag <ButtonRelease-1> \
        "+focus $Chat::chatConfig($tbw,entry)"

    if {$type == "card"} {
	CrossFire::CreateYogilandLink $tbw $word $tag
    }

    $tbw insert end $word $tag

    return
}

# Chat::FortifyRealm --
#
#   Creates a GUI for fortifing (lock) a realm.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::FortifyRealm {} {

    variable chatConfig

    set tw $chatConfig(topw).lockRealm

    if {[winfo exists $tw]} {
        wm deiconify $tw
        raise $tw
    } else {
        toplevel $tw
        wm title $tw "Fortify Realm"
        wm protocol $tw WM_DELETE_WINDOW "$tw.buttons.cancel invoke"
        bind $tw <Key-Escape> "$tw.buttons.cancel invoke"

        CrossFire::Transient $tw

        frame $tw.top -borderwidth 1 -relief raised
        label $tw.top.passwordLabel -text "Optional Password:"
        entry $tw.top.passwordEntry -width 35
        set chatConfig(fortifyPassword) $tw.top.passwordEntry
        grid $tw.top.passwordLabel $tw.top.passwordEntry \
            -sticky ew -padx 5 -pady 5
        grid columnconfigure $tw.top 1 -weight 1
        grid $tw.top -sticky nsew

        bind $tw <Key-Return> "$tw.buttons.ok invoke"

        frame $tw.buttons -borderwidth 1 -relief raised
        button $tw.buttons.ok -text "Fortify" \
            -command "Chat::SendFortifyRealm; destroy $tw"
        button $tw.buttons.cancel -text "Cancel" -command "destroy $tw"
        grid $tw.buttons.ok $tw.buttons.cancel -padx 5 -pady 5

        grid $tw.buttons -sticky nsew
        grid columnconfigure $tw 0 -weight 1
        grid rowconfigure $tw 0 -weight 1
    }

    focus $chatConfig(fortifyPassword)

    return
}

# Chat::SendFortifyRealm --
#
#   Sends the command to the server to fortify a realm.
#
# Parameteres:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::SendFortifyRealm {} {

    variable chatConfig

    set password [$chatConfig(fortifyPassword) get]
    if {$password != ""} {
        SendToServer "lock $password"
    } else {
        SendToServer "lock"
    }

    return
}

# Chat::UpdateUserCommands --
#
#   Adds the appropriate command buttons to the interface depending
#   on the current status of the user.  Example line of data:
#   <Current status: user registered su admin hcadmin channelowner judge>
#
# Parameters:
#   data       : User status line.
#
# Returns:
#   Nothing.
#
proc Chat::UpdateUserCommands {data} {

    variable chatConfig

    regsub ">" $data "" data

    # Remove the old menu and any cascades it may have.
    $chatConfig(commandMenu) delete 0 end
    foreach child [winfo children $chatConfig(commandMenu)] {
        $child delete 0 end
        destroy $child
    }

    # ! = Fully supported
    # * = Partially supported
    # ? = Need to add support

    # User: Commands Emote* Getfile Help Insult(!) Join! Motd! Protocol!
    #   Quit! Remote Say! Status Tell! Time! Where! Who WhoChannel!

    # Registered: Cemote Chat Chpwd! Finger Game Info! Joinchat
    #   Joingame Mail/Note* Profile! WhoChat WhoGame Whois!
    #   ListPlayers/PlayerList!

    # Channelowner: Bestow! Boot! Lock! Seminar! Pop! UnLock!

    # Judge: No commands yet.

    # SU: BanList! BanName! BanSite! Barge! Discon! Free! Hijack! Jail!
    #   Makejudge! Register! Revokejudge! Shelp
    #   Silentdiscon! System! Think!

    # Admin: Athink! Force Grab! Grant! Loadhelp Nuke!
    #   PermBanName! PermBanSite! Revoke! UnBanName! UnBanSite

    # HCAdmin: Cleannotes

    CreateAllyMenu "Unregistered"

    set chatConfig(cmdMenu) $chatConfig(commandMenu)

    # Everyone is a user, so add the appropriate user commands
    #AddChatCommand "Insult Me!" insult
    AddChatCommand "Message of the Day" motd
    AddChatCommand "Display CrossFire Time" time

    if {[lsearch $data "registered"] != -1} {
        $chatConfig(commandMenu) add separator
        AddChatCommand "Change Password..." Chat::ChangePassword
        AddChatCommand "Edit Profile..." Chat::EditProfile
        AddChatCommand "Send Note..." Chat::CreateNote
        AddChatCommand "List Players" playerlist
        AddChatCommand "Display Server Info" info
        CreateAllyMenu "Registered"
    }

    if {[lsearch $data "channelowner"] != -1} {
        set chatConfig(seminarMode) "off"
        $chatConfig(commandMenu) add separator
        $chatConfig(commandMenu) add checkbutton \
            -label "Seminar Mode" \
            -onvalue "on" -offvalue "off" \
            -variable Chat::chatConfig(seminarMode) \
            -command {
                Chat::SendToServer "seminar $Chat::chatConfig(seminarMode)"
            }
        AddChatCommand "Show Next Message" pop
        AddChatCommand "Fortify Realm..." Chat::FortifyRealm
        AddChatCommand "UnFortify Realm" unlock
        AddChatCommand "Exile Ally" boot name
        AddChatCommand "Give Realm to Ally" bestow name
    }

    if {[lsearch $data "judge"] != -1} {
        $chatConfig(commandMenu) add separator
        AddChatCommand "Judge Commands Here..." {
            tk_messageBox -icon info -title "La La La!" \
                -message "Alas, no commands yet!"
        }
    }

    if {[lsearch $data "su"] != -1} {
        $chatConfig(commandMenu) add separator
        set chatConfig(cmdMenu) $chatConfig(commandMenu).su
        $chatConfig(commandMenu) add cascade \
            -label "Super User" \
            -menu $chatConfig(cmdMenu)
        menu $chatConfig(cmdMenu) -title "Super User"
        AddChatCommand "Broadcast" system message
        AddChatCommand "SU Message" think message
        $chatConfig(cmdMenu) add separator
        AddChatCommand "Register Player" register name
        AddChatCommand "Make Player a Judge" makejudge name
        AddChatCommand "Remove Player's Gavel" revokejudge name
        $chatConfig(cmdMenu) add separator
        AddChatCommand "Barge Realm" barge realm
        AddChatCommand "Hijack Realm" hijack
        $chatConfig(cmdMenu) add separator
        AddChatCommand "Jail Player (Timed)" jail name message
        AddChatCommand "UnJail Player" free name
        AddChatCommand "Disconnect Player" discon name
        AddChatCommand "Disconnect Player (Silent)" silentdiscon name
        $chatConfig(cmdMenu) add separator
        AddChatCommand "List Banned" banlist
        AddChatCommand "Ban Name (Timed)" banname message
        AddChatCommand "Ban Site (Timed)" bansite message
    }

    if {[lsearch $data "admin"] != -1} {
        set chatConfig(cmdMenu) $chatConfig(commandMenu).admin
        $chatConfig(commandMenu) add cascade \
            -label "Administrator" \
            -menu $chatConfig(cmdMenu)
        menu $chatConfig(cmdMenu) -title "Administrator"
        AddChatCommand "Admin Message" athink message
        $chatConfig(cmdMenu) add separator
        AddChatCommand "Version Info" version
        $chatConfig(cmdMenu) add separator
        AddChatCommand "Grab Player" grab name
        AddChatCommand "Grant User Level" grant name message
        AddChatCommand "Revoke User Level" revoke name message
        AddChatCommand "Delete User" nuke message
        $chatConfig(cmdMenu) add separator
        AddChatCommand "Ban Name (Perm)" permbanname message
        AddChatCommand "UnBan Name" unbanname message
        AddChatCommand "Ban Site (Perm)" permbansite message
        AddChatCommand "UnBan Site" unbansite message
    }

    return
}

# Chat::AddChatCommand --
#
#   Adds a chat command to the menu bar.
#
# Parameters:
#   title      : Label for the command.
#   cmd        : What to invoke when selected.
#   args       : Which vars need to be sent (name, realm, message)
#
# Returns:
#   Nothing.
#
proc Chat::AddChatCommand {title cmd args} {

    variable chatConfig

    if {[regexp "\\.\\.\\.\$" $title]} {
        # cmd is a local command
        set command $cmd
    } else {
        # cmd is a server command
        set command "Chat::SendToServer \"$cmd"
        if {$args != ""} {
            foreach arg $args {
                append command " \[Chat::GetValue $arg\]"
            }
        }
        append command "\""
    }

    $chatConfig(cmdMenu) add command \
        -label $title \
        -command $command

    return
}

# Chat::GetValue --
#
#   Returns the current value for a data item in chat.
#
# Parameters:
#   var        : Name of data to get.
#
# Returns:
#   The data.
#
proc Chat::GetValue {var} {

    variable chatConfig

    switch $var {
        "name" {
            set out $chatConfig(championSel)
        }
        "realm" {
            set out $chatConfig(realmSel)
        }
        "message" {
            set out [GetMessageText]
            ClearMessageText
        }
        default {
            set out ""
            puts "I don't know $var yet"
        }
    }

    return $out
}

# Chat::ChangePassword --
#
#   Creates a GUI for changing the user's password.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::ChangePassword {} {

    variable chatConfig

    set tw $chatConfig(topw).chpwd

    if {[winfo exists $tw]} {
        wm deiconify $tw
        raise $tw
    } else {
        toplevel $tw
        wm title $tw "Change Password"
        wm protocol $tw WM_DELETE_WINDOW "$tw.buttons.cancel invoke"
        bind $tw <Key-Escape> "$tw.buttons.cancel invoke"

        CrossFire::Transient $tw

        frame $tw.top -borderwidth 1 -relief raised
        label $tw.top.passwordLabel -text "New Password:"
        entry $tw.top.passwordEntry -width 35
        set chatConfig(newPasswordEntry) $tw.top.passwordEntry
        grid $tw.top.passwordLabel $tw.top.passwordEntry \
            -sticky ew -padx 5 -pady 5
        grid columnconfigure $tw.top 1 -weight 1
        grid $tw.top -sticky nsew

        bind $tw <Key-Return> "$tw.buttons.ok invoke"

        frame $tw.buttons -borderwidth 1 -relief raised
        button $tw.buttons.ok -text "Change" \
            -command "Chat::SendChangePassword; destroy $tw"
        button $tw.buttons.cancel -text "Cancel" -command "destroy $tw"
        grid $tw.buttons.ok $tw.buttons.cancel -padx 5 -pady 5

        grid $tw.buttons -sticky nsew
        grid columnconfigure $tw 0 -weight 1
        grid rowconfigure $tw 0 -weight 1
    }

    focus $chatConfig(newPasswordEntry)

    return
}

# Chat::SendChangePassword --
#
#   Sends the command to the server to change the user's password.
#
# Parameteres:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::SendChangePassword {} {

    variable chatConfig

    set password [$chatConfig(newPasswordEntry) get]
    if {$password != ""} {
        SendToServer "chpwd $password"
    }

    return
}

# Chat::HighlightRealm --
#
#   Called by SPINS to highlight the realm the champion is in.
#
# Parameters:
#   realm    : Name of the realm
#
# Returns:
#   Nothing.
#
proc Chat::HighlightRealm {realm} {

    variable chatConfig

    # To invoke trace to map client window
    set chatConfig(map) 1
    set chatConfig(inRealm) $realm
    set tbw $chatConfig(realmTextBox)

    $tbw configure -state normal

    foreach tag "[$tbw tag names]" {
        $tbw tag configure $tag -font $chatConfig(fontNormal)
    }

    $tbw tag configure $realm -font $chatConfig(fontBold)
    $tbw configure -state disabled

    return
}

# Chat::About --
#
#   Displays an about dialog for the Chat
#
# Paramters:
#   w         : Parent toplevel for the pop-up dialog.
#
# Returns:
#   Nothing.
#
proc Chat::About {w} {
    set message "CrossFire Online Chat\n"
    append message "\nby Stephen Thompson & Dan Curtiss"
    tk_messageBox -icon info -title "About CrossFire Chat" \
        -parent $w -message $message
    return
}

# Chat::UpdateBoxColors --
#
#   Called by Config...updates the back|fore-ground colors of the boxes
#   and the font for the message window.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::UpdateBoxColors {} {

    variable chatConfig

    if {![winfo exists $chatConfig(topw)]} {
        return
    }

    set chatConfig(chatFG) $Config::config(Chat,foreground)
    set chatConfig(chatBG) $Config::config(Chat,background)
    set chatConfig(newChamp) $Config::config(Chat,newChampion)
    set chatConfig(chatFont) $Config::config(Chat,font)

    foreach widget {
        realmTextBox championTextBox inRealmTextBox messageTextBox
    } {
        $chatConfig($widget) configure -foreground $chatConfig(chatFG) \
            -background $chatConfig(chatBG)
    }
    $chatConfig(messageTextBox) tag configure system \
        -foreground $chatConfig(chatFG) -background $chatConfig(chatBG) \
        -font $chatConfig(chatFont)

    # Update the links
    foreach tagName [$chatConfig(messageTextBox) tag names] {
        if {[regexp "^link\[0-9\]+\$" $tagName]} {
            $chatConfig(messageTextBox) tag configure $tagName \
                -foreground $Config::config(Chat,urlColor) \
                -background $chatConfig(chatBG) -font $chatConfig(chatFont)
        }
    }

    return
}

# Chat::OnlineStatus --
#
#   Sets or returns the online status.  Updates red/green dot.
#
# Parameters:
#   args      : Boolean 1 or 0.
#
# Returns:
#   The boolean status.
#
proc Chat::OnlineStatus {args} {

    variable chatConfig

    if {![winfo exists $chatConfig(topw)]} return

    if {$args != ""} {
        set status [lindex $args 0]
        set chatConfig(online) $status
        set menuNum [expr [$chatConfig(chatMenu) index end] - 1]
        if {$status == 1} {
            $chatConfig(statusGraphic) configure -image imgConnected
            $chatConfig(chatMenu) entryconfigure $menuNum \
                -label "Log Off" \
                -command "Chat::LogOff"
        } else {
            $chatConfig(statusGraphic) configure -image imgDisconnected
            $chatConfig(chatMenu) entryconfigure $menuNum \
                -label "Reconnect" \
                -command "Chat::ServerLogin"
        }
    } else {
        set status $chatConfig(online)
    }

    return $status
}

# Chat::StartTyping --
#
#   Called when the user types something in the message area.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::StartTyping {} {

    variable chatConfig

    if {$chatConfig(typing) == 0} {
	set chatConfig(typing) 1
	$chatConfig(typingStatus) configure -image imgConnected
	set chatConfig(afterID) [after $chatConfig(typingOff) Chat::DoneTyping]
	# Tell the server we are typing.
	#SendToServer "typing"
    } else {
	if {[info exists chatConfig(afterID)]} {
	    after cancel $chatConfig(afterID)
	}
	set chatConfig(afterID) [after $chatConfig(typingOff) Chat::DoneTyping]
    }

    return
}

# Chat::DoneTyping --
#
#   Called when the user is apparently not typing anymore.  This occurs when
#   a message is sent or when there has been no typing for 5 seconds.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::DoneTyping {} {

    variable chatConfig

    set chatConfig(typing) 0
    $chatConfig(typingStatus) configure -image imgDisconnected
    if {[info exists chatConfig(afterID)]} {
        after cancel $chatConfig(afterID)
        unset chatConfig(afterID)
    }
    # Tell the server we are not typing anymore
    #SendToServer "notyping"

    return
}

# Chat::CreateIMWindow --
#
#   Creates or raises an IM window.
#
# Parameters:
#   who       : Name of player.
#
# Returns:
#   The widget path for the text box.
#
proc Chat::CreateIMWindow {{who ""}} {

    variable chatConfig

    if {$Config::config(Chat,useIMs) == "No"} {
        return
    }

    if {$who == ""} {
        set who $chatConfig(championSel)
    }

    set name $who
    set who [string tolower $who]

    # Sorry, no IM'ing oneself!
    if {$who == [string tolower $chatConfig(name)]} {
        bell
        return
    }

    # Extra safe test for IM window existing already.
    if {[info exists chatConfig(im,window,$who)] &&
        [winfo exists $chatConfig(im,window,$who)]} {
        set wState [wm state $chatConfig(im,window,$who)]
        if {($wState == "iconic") || ($wState == "withdrawn")} {
            wm deiconify $chatConfig(im,window,$who)
            raise $chatConfig(im,window,$who)
        }
        return $chatConfig(im,text,$who)
    }

    set tw [toplevel $chatConfig(topw).im$who]
    set chatConfig(im,window,$who) $tw

    wm title $tw "Private Chat: $name"
    wm protocol $tw WM_DELETE_WINDOW "Chat::HideIMWindow $who"

    set m [menu $tw.m]
    $m add cascade -label "Window" -menu $m.win
    menu $m.win -tearoff 0
    $m.win add command -label "Send Message" \
        -command "Chat::SendIM $who"
    $m.win add separator
    $m.win add command -label "Clear Text" \
        -command "Chat::ClearBox IM $who"
    $m.win add separator
    $m.win add command -label $CrossFire::close \
        -command "Chat::HideIMWindow $who"

    $tw configure -menu $m

    set chatConfig(im,entry,$who) $tw.bottom.f.e

    # Text window frame
    frame $tw.top -borderwidth 1 -relief raised

    set f [frame $tw.top.f]
    set textw [text $f.t -width 60 -height 10 -cursor {} -wrap word \
                   -spacing1 2 -background $chatConfig(chatBG) -takefocus 0 \
                   -foreground $chatConfig(chatFG) \
                   -font $chatConfig(chatFont) \
                   -yscrollcommand "CrossFire::SetScrollBar $f.sb"]
    scrollbar $f.sb -takefocus 0 -command "$f.t yview"
    set chatConfig($textw,entry) $chatConfig(im,entry,$who)
    set chatConfig(im,text,$who) $textw
    set copyCommand [bind Text <<Copy>>]
    bind $chatConfig(im,text,$who) <Any-Key> "break"
    bind $chatConfig(im,text,$who) <Button-2> "break"
    bind $chatConfig(im,text,$who) <<Copy>> $copyCommand
    bind $chatConfig(im,text,$who) <ButtonRelease-2> \
        "focus $chatConfig(im,entry,$who); break"

    grid $textw -sticky nsew

    grid columnconfigure $f 0 -weight 1
    grid rowconfigure $f 0 -weight 1

    grid $f -sticky nsew -padx 3 -pady 3
    grid columnconfigure $tw.top 0 -weight 1
    grid rowconfigure $tw.top 0 -weight 1

    # Entry area
    frame $tw.bottom -borderwidth 1 -relief raised
    set f [frame $tw.bottom.f]
    entry $chatConfig(im,entry,$who)
    bind $chatConfig(im,entry,$who) <Key-Return> "Chat::SendIM $who"
    button $f.s -text "Send" -command "Chat::SendIM $who" -width 8

    grid $f.e $f.s -sticky ew -padx 3
    grid columnconfigure $f 0 -weight 1

    grid $f -sticky ew -pady 3
    grid columnconfigure $tw.bottom 0 -weight 1

    grid $tw.top -sticky nsew
    grid $tw.bottom -sticky ew
    grid columnconfigure $tw 0 -weight 1
    grid rowconfigure $tw 0 -weight 1

    GetTagColors

    focus $chatConfig(im,entry,$who)

    bind $tw <$CrossFire::accelBind-l> "Chat::ClearBox IM $who"

    return $chatConfig(im,text,$who)
}

# Chat::SendIM --
#
#   Sends an IM message.
#
# Parameters:
#   who       : Player message is to
#
# Returns:
#   Nothing.
#
proc Chat::SendIM {who} {

    variable chatConfig

    set msg [$chatConfig(im,entry,$who) get]
    if {$msg != ""} {
        $chatConfig(im,entry,$who) delete 0 end
        SendToServer "tell $who $msg"
        focus $chatConfig(im,entry,$who)
    }

    return
}

# Chat::HideIMWindow --
#
#   Hides an IM window. Windows are destroyed when chat window is closed.
#
# Parameters:
#   who       : Which IM window
#
# Returns:
#   Nothing.
#
proc Chat::HideIMWindow {who} {

    variable chatConfig

    wm withdraw $chatConfig(im,window,$who)

    return
}
