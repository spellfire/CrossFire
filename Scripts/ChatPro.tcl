# ChatPro.tcl 20051117
#
# This file contains the procedures for handling chat profiles.
#
# Copyright (c) 2000-2005 Dan Curtiss. All rights reserved.
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

    set chatConfig(profileData) {
        User      Chat,profile,user
        Name      Chat,profile,name
        Email     Chat,profile,email
        WebSite   Chat,profile,web
        Location  Chat,profile,location
        Champion  Chat,profile,champion
        Level     Chat,profile,level
        Info      Chat,profile,info
        EnterMsg  Chat,profile,enter
        LeaveMsg  Chat,profile,leave
        Home      Chat,profile,home
        LogonMsg  Chat,profile,logon
        LogoffMsg Chat,profile,logoff
        ImageURL  Chat,progile,imageURL
    }
}

# Chat::SetProfileData --
#
#   Sets the profile data from the saved infomation in configure.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::SetProfileData {} {

    variable chatConfig

    foreach {nsVar configVar} $chatConfig(profileData) {
        set chatConfig(profile,$nsVar) $Config::config($configVar)
    }

    if {$chatConfig(profile,Name) == ""} {
        set chatConfig(profile,Name) $Config::config(CrossFire,authorName)
    }
    if {$chatConfig(profile,Email) == ""} {
        set chatConfig(profile,Email) $Config::config(CrossFire,authorEmail)
    }

    # Always update this in case the user name has changed
    set chatConfig(profile,User) $chatConfig(name)

    return
}

# Chat::ProfileChange --
#
#   Called when a change has been made to a profile or when the profile
#   has been saved.
#
# Parameters:
#   status     : Boolean true or false.
#   args       : Junk from trace.
#
# Returns:
#   Nothing.
#
proc Chat::ProfileChange {status args} {

    variable chatConfig

    set chatConfig(profile,changed) $status
    set title $chatConfig(profileEditorTitle)
    if {$status == "true"} {
        append title " *"
    }
    wm title $chatConfig(editProfile) $title

    return
}

# Chat::EditProfile --
#
#   Creates the GUI for editting one's profile.
#
# Parameters:
#   mode       : Optional editor mode (online or offline)
#
# Returns:
#   Nothing.
#
proc Chat::EditProfile {{mode online}} {

    variable chatConfig

    set w .editProfile
    set chatConfig(editProfile) $w

    if {[winfo exists $w]} {
        wm deiconify $w
        raise $w
        return
    }

    SetProfileData

    set chatConfig(profileEditorTop) $w
    set chatConfig(profileEditorTitle) "Chat Profile Editor"
    set width 15

    toplevel $w
    wm title $w $chatConfig(profileEditorTitle)
    wm protocol $w WM_DELETE_WINDOW "$w.buttons.close invoke"

    frame $w.profile -borderwidth 1 -relief raised

    frame $w.profile.f

    foreach {var varName title} {
        name     Name     Name
        email    Email    Email
        webSite  WebSite  {Web Site}
        image    ImageURL {Image URL}
        location Location Location
        level    Level    Level
    } {
        frame $w.profile.f.$var
        label $w.profile.f.$var.l -text "$title:" -anchor e -width $width
        entry $w.profile.f.$var.e -width 30 \
            -textvariable Chat::chatConfig(profile,$varName)
        if {$var == "name"} {
            focus $w.profile.f.$var.e
        }
        grid $w.profile.f.$var.l $w.profile.f.$var.e -sticky ew
        grid $w.profile.f.$var -sticky nsew
        grid columnconfigure $w.profile.f.$var 1 -weight 1
    }

    frame $w.profile.f.champion
    label $w.profile.f.champion.l -text "Champion:" -anchor e -width $width
    menubutton $w.profile.f.champion.om -width 20 -relief raised \
        -menu $w.profile.f.champion.om.m -indicatoron 1 \
        -textvariable Chat::chatConfig(profile,Champion)
    menu $w.profile.f.champion.om.m -tearoff 0
    set cList "Random"
    if {$::developer} {
        foreach typeNum $CrossFire::cardTypeIDList {
            if {$typeNum > 0 && $typeNum < 99} {
                lappend cList $CrossFire::cardTypeXRef($typeNum,name)
            }
        }
    } else {
        foreach typeNum $CrossFire::championList {
            lappend cList $CrossFire::cardTypeXRef($typeNum,name)
        }
    }
    foreach type $cList {
        $w.profile.f.champion.om.m add radiobutton \
            -label $type -value $type \
            -variable Chat::chatConfig(profile,Champion)
    }
    grid $w.profile.f.champion.l $w.profile.f.champion.om -sticky ew
    grid $w.profile.f.champion -sticky nsew -pady 5
    grid columnconfigure $w.profile.f.champion 1 -weight 1

    frame $w.profile.f.info
    label $w.profile.f.info.l -text "Info:" -anchor e -width $width
    frame $w.profile.f.info.t
    text $w.profile.f.info.t.t -width 30 -height 4 -wrap word \
        -yscrollcommand "CrossFire::SetScrollBar $w.profile.f.info.t.sb"
    scrollbar $w.profile.f.info.t.sb \
        -command "$w.profile.f.info.t.t yview"
    grid $w.profile.f.info.t.t -sticky nsew
    grid rowconfigure $w.profile.f.info.t 0 -weight 1
    grid columnconfigure $w.profile.f.info.t 0 -weight 1
    grid $w.profile.f.info.l -row 0 -column 0 -sticky new
    grid $w.profile.f.info.t -row 0 -column 1 -sticky nsew
    grid $w.profile.f.info -sticky nsew -pady 5
    grid columnconfigure $w.profile.f.info 1 -weight 1

    set chatConfig(profileText) $w.profile.f.info.t.t
    bind $chatConfig(profileText) <KeyPress> "Chat::CheckTextChange %A"
    bindtags $chatConfig(profileText) "$chatConfig(profileText) Text all"

    set flag 0
    foreach {entryName entryVar} {
        {Logon Message:}  LogonMsg
        {Logoff Message:} LogoffMsg
        {Enter Realm:}    EnterMsg
        {Leave Realm:}    LeaveMsg
        {Home Realm:}     Home
    } {
        set f $w.profile.f.f$entryVar
        frame $f
        label $f.l -text $entryName -anchor e -width $width
        entry $f.e -width 30 \
            -textvariable Chat::chatConfig(profile,$entryVar)
        grid $f.l $f.e -sticky ew
        if {$flag == 0} {
            grid $f -sticky nsew
        } else {
            grid $f -sticky nsew -pady 5
        }
        set flag [expr 1 - $flag]
        grid columnconfigure $f 1 -weight 1
    }

    grid $w.profile.f -sticky nsew -padx 5 -pady 5
    grid rowconfigure $w.profile.f 5 -weight 1
    grid columnconfigure $w.profile.f 0 -weight 1

    grid $w.profile -sticky nsew
    grid rowconfigure $w.profile 0 -weight 1
    grid columnconfigure $w.profile 0 -weight 1

    frame $w.buttons -borderwidth 1 -relief raised
    button $w.buttons.update -width 6 -command "Chat::UpdateProfile $mode"
    if {$mode == "online"} {
        $w.buttons.update configure -text "Update"
    } else {
        $w.buttons.update configure -text "Save"
    }
    button $w.buttons.close -width 6 -text $CrossFire::close \
        -command "Chat::CloseEditProfile $mode"
    grid $w.buttons.update $w.buttons.close -padx 5 -pady 5
    grid $w.buttons -sticky nsew

    grid rowconfigure $w 0 -weight 1
    grid columnconfigure $w 0 -weight 1

    foreach {nsVar trash} $chatConfig(profileData) {
        trace variable Chat::chatConfig(profile,$nsVar) w \
            {Chat::ProfileChange "true"}
    }

    $chatConfig(profileText) insert end $chatConfig(profile,Info)
    ProfileChange "false"

    return
}

# Chat::CheckTextChange --
#
#   Makes a simple check to see if the text has changed in the text box.
#
# Parameters:
#   char       : Character pressed from bind command (%A).
#
# Returns:
#   Nothing.
#
proc Chat::CheckTextChange {char} {

    if {$char != ""} {
        ProfileChange "true"
    }

    return
}

# Chat::UpdateProfile --
#
#   Saves the profile in the configuration and sends it to the server.
#
# Parameters:
#   mode       : Optional editor mode (online or offline)
#
# Returns:
#   Nothing.
#
proc Chat::UpdateProfile {{mode online}} {

    variable chatConfig

    Config::Set Chat,lastProfileChange $mode

    set chatConfig(profile,Info) \
        [string trim [$chatConfig(profileText) get 1.0 end]]

    foreach {nsVar configVar} $chatConfig(profileData) {
        Config::Set $configVar $chatConfig(profile,$nsVar)
    }

    if {$mode == "online"} {
        SendProfileToServer
    }

    ProfileChange "false"

    return
}

# Chat::SendProfileToServer --
#
#   Send the profile to the server via the profile command.
#
# Parameters:
#   None.
#
# Returns:
#   Nothing.
#
proc Chat::SendProfileToServer {} {

    variable chatConfig

    set profile {}
    foreach {nsVar configVar} $chatConfig(profileData) {
        lappend profile $nsVar $chatConfig(profile,$nsVar)
    }
    SendToServer "profile [list $profile]"

    return
}

# Chat::CloseEditProfile --
#
#   Closes the profile editor.  First checks if changes need to be saved.
#
# Parameters:
#   mode       : Optional editor mode (online or offline)
#
# Returns:
#   Nothing.
#
proc Chat::CloseEditProfile {{mode online}} {

    variable chatConfig

    if {$chatConfig(profile,changed) == "true"} {
        set msg "Profile not updated.  Update now?"
        set response [tk_messageBox -icon question -type yesnocancel \
                          -message "Profile not updated.  Update now?" \
                          -title "Profile Unsaved"]
        if {$response == "yes"} {
            UpdateProfile $mode
        } elseif {$response == "cancel"} {
            return
        }
    }

    foreach {nsVar trash} $chatConfig(profileData) {
        trace vdelete Chat::chatConfig(profile,$nsVar) w \
            {Chat::ProfileChange "true"}
    }

    destroy $chatConfig(editProfile)

    return
}

# Chat::ShowProfile --
#
#   Displays a player's profile.
#
# Parameters:
#   profile   : The profile.
#
# Returns:
#   Nothing.
#
proc Chat::ShowProfile {profileInfo} {

    variable chatConfig

    # Set up empty values in case anything is missing
    array set profile {
        User ""
        Name "Moonbeam Clubfoot"
        Email "Email?"
        WebSite {http://crossfire.spellfire.net}
        Location "Delta Quadrant"
        Level "0.1"
        Champion "Random"
        Info "Please tell me how to set up my profile!!"
    }

    # Assign the profile data
    foreach {datum data} $profileInfo {
        set profile($datum) $data
    }

    regsub -all -- "~NL~" $profile(Info) "\n" profile(Info)
    set w $chatConfig(topw).profile$profile(User)
    set fw $w.top.f

    # Create a new toplevel for this profile.
    if {![winfo exists $w]} {
        toplevel $w
        bind $w <Key-Escape> "$w.buttons.close invoke"

        frame $w.top -borderwidth 1 -relief raised
        frame $fw -background white

        frame $fw.icon -background white
        label $fw.icon.image -background white -foreground black \
            -font {Times 18 bold}
        label $fw.icon.level -background white -foreground black \
            -font {Times 18 bold}
        pack $fw.icon.image $fw.icon.level -anchor nw -side left
        pack $fw.icon -anchor nw
        frame $fw.desc -relief groove -bd 2 -background white
        frame $fw.desc.title -background white
        label $fw.desc.title.world -anchor w -background white \
            -foreground black
        label $fw.desc.title.name -anchor e -background white \
            -foreground black
        grid $fw.desc.title.world $fw.desc.title.name -padx 3 -sticky ew
        grid columnconfigure $fw.desc.title 1 -weight 1
        pack $fw.desc.title -fill x
        frame $fw.desc.cardText
        text $fw.desc.cardText.text -height 4 -width 30 \
            -relief flat -wrap word -pady 5 -padx 5 -background bisque \
            -foreground black -cursor {} -exportselection 1 \
            -yscrollcommand "CrossFire::SetScrollBar $fw.desc.cardText.sb"
        $fw.desc.cardText.text tag configure center -justify center
        $fw.desc.cardText.text tag configure url -justify center \
            -foreground $Config::config(Chat,urlColor) -underline 1
        $fw.desc.cardText.text tag configure email -justify center \
            -foreground $Config::config(Chat,urlColor) -underline 1
	set view($fw,text) $fw.desc.cardText.text

	set copyCommand [bind Text <<Copy>>]
	bind $view($fw,text) <Any-Key> "break"
	bind $view($fw,text) <<Copy>> $copyCommand

        scrollbar $fw.desc.cardText.sb -background bisque \
            -command "$fw.desc.cardText.text yview"
        grid $fw.desc.cardText.text -sticky nsew
        grid columnconfigure $fw.desc.cardText 0 -weight 1
        grid rowconfigure $fw.desc.cardText 0 -weight 1
        pack $fw.desc.cardText -expand 1 -fill both -padx 5 -pady 5
        pack $fw.desc -expand 1 -fill both -padx 5 -pady 5
        pack $fw -expand 1 -fill both -padx 5 -pady 5
        pack $w.top -expand 1 -fill both

        frame $w.buttons -borderwidth 1 -relief raised
        button $w.buttons.close -text $CrossFire::close \
            -command "destroy $w"
        grid $w.buttons.close -padx 5 -pady 5
        pack $w.buttons -fill x
    }

    # Update the profile with the new information
    wm title $w "Profile for $profile(User)"
    $fw.icon.level configure -text $profile(Level)
    $fw.desc.title.world configure -text $profile(Location)
    $fw.desc.title.name configure -text $profile(Name)

    # The champion can be random
    if {($profile(Champion) == "Random") || ($profile(Champion) == "")} {
        set cList $CrossFire::championList
        set cardTypeNumber \
            [lindex $cList [expr int(rand() * [llength $cList])]]
    } else {
        set cardTypeNumber $CrossFire::cardTypeXRef($profile(Champion))
    }
    set cardTypeName $CrossFire::cardTypeXRef($cardTypeNumber,name)
    set icon $CrossFire::cardTypeXRef($cardTypeNumber,icon)
    $fw.icon.image configure -text $cardTypeName -image ""
    if {[lsearch [image names] $icon] != -1} {
        $fw.icon.image configure -image $icon
    }

    # Change the champion icon to an image if a URL is supplied
    # Limit size to 50k to avoid gremlins having a little fun.
    if {$profile(ImageURL) != ""} {
        if {[catch {set id [::http::geturl $profile(ImageURL)]} err]} {
            dputs "ERROR: $err"
        } else {
            if {[::http::size $id] < 75000} {
                set imageData [http::data $id]
                http::cleanup $id
                if {[catch {
                    image create photo img$profile(User) -data $imageData
                } err]} {
                    dputs "Unable to create photo:$profile(ImageURL)"
                } else {
                    $fw.icon.image configure -image img$profile(User)
                }
            } else {
                SendToServer \
                    "emote says $profile(User)'s profile image is too big!"
            }
        }
    }

    # Info text
    set tw $fw.desc.cardText.text
    $tw delete 1.0 end
    $tw insert end "$profile(Info)\n" center
    if {$profile(Email) != ""} {
	if {($CrossFire::platform == "windows") &&
	    ([regexp "\@" $profile(Email)] != 0)} {
	    $tw tag bind email <Enter> "$tw configure -cursor hand2"
	    $tw tag bind email <Leave> "$tw configure -cursor {}"
	    $tw tag bind email <ButtonRelease-1> \
		"CrossFire::OpenURL mailto:$profile(Email)"
	    $fw.desc.cardText.text insert end $profile(Email) email
	} else {
	    $tw insert end $profile(Email) center
	}
    }
    if {$profile(WebSite) != ""} {
        $tw tag bind url <Enter> "$tw configure -cursor hand2"
        $tw tag bind url <Leave> "$tw configure -cursor {}"
        $tw tag bind url <ButtonRelease-1> \
            "CrossFire::OpenURL $profile(WebSite)"
        $fw.desc.cardText.text insert end "\n$profile(WebSite)" url
    }

    return
}

