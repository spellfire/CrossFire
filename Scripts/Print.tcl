# Print.tcl 20060227
#
# This file defines the routines for printing (actually exporting).
#
# Copyright (c) 1998-2006 Dan Curtiss. All rights reserved.
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

#
# Print -- Printing, Formating, Exporting... we do it all!
#
# Procedures:
#   Print::GetExportFile  {w fileName args}
#   Print::SelectPrintFile {w which}
#   Print::Mode {w}         => file format (text, rtf, etc)
#   Print::Command {w}      => UNIX command to print
#   Print::FileName {w}     => filename to print to
#   Print::WordAddText {w text args}
#   Print::WordColor {color}
#   Print::Head {w title}   !! should start with this
#   Print::Title {w title}
#   Print::Author {w author}
#   Print::Email {w email}
#   Print::Center {w text}
#   Print::Notes {w notes}
#   Print::Heading {w heading}
#   Print::Card {w card {printText Yes}}
#   Print::Blank {w}
#   Print::Separator {w}
#   Print::Tail {w}           !! should end with this
#   Print::Print {w}

namespace eval Print {

    variable print

    # The fileInfo variable is formated as:
    #   typeID  suffix  extension  Name

    array set print {
        mode     text
        fileInfo {
            text {}      .txt  Text
            rtf  {}      .rtf  RTF
            html {}      .html HTML
            doc  {}      .doc  {Microsoft Word}
            bbc  _bbcode .txt  BBCode
        }
    }
#            flat _flat   .txt  {Flat Text}

}

# Print::GetExportFile --
#
#   Asks user what form of export they want (plain text, RTF document, etc.)
#
# Parameters:
#   fileName   : Optional filename to base printed file's name from.
#
# Returns:
#   Nothing.
#
proc Print::GetExportFile {w fileName args} {

    variable print

    set title "Print to File..."

    if {$fileName == ""} {
        set fileBase [file join $CrossFire::homeDir temp]
    } else {
        set fileBase [file rootname $fileName]
    }
    foreach {ftype suffix ext name} $print(fileInfo) {
        set print($w,${ftype}File) "$fileBase$suffix$ext"
        set print($w,${ftype}Show) 1
    }

    # Initialize settings if this is the first time calling the print
    # routines for this toplevel w.
    if {![info exists print($w,command)]} {
        set print($w,command) $Config::config(Linux,lpr)
        set print($w,mode) $print(mode)
    }

    # Process any args that may have been passed to us.  Possibles are:
    #   -title <text>     : Sets new window title.
    #   -mode <mode>      : Set a default mode. Defaults to 'text'.
    #   -$ftype <boolean> : Dis/en-able a file type. All types default to on.
    foreach {arg value} $args {
        if {$arg == "-title"} {
            set title $value
        } elseif {$arg == "-default"} {
            set print($w,mode) $value
        } else {
            foreach {ftype suffix ext name} $print(fileInfo) {
                if {$arg == "-$ftype"} {
                    set print($w,${ftype}Show) $value
                }
            }
        }
    }

    # Make sure Word doc is disabled if Word is not available.
    if {$::useWord == 0} {
        set print($w,docShow) 0
    }

    toplevel [set tw .lpr]
    wm title $tw $title
    wm protocol $tw WM_DELETE_WINDOW "$tw.buttons.cancel invoke"
    bind $tw <Key-Escape> "$tw.buttons.cancel invoke"
    bind $tw <Key-Return> "$tw.buttons.print invoke"

    frame $tw.opt -borderwidth 1 -relief raised

    set cRow -1
    if {$CrossFire::platform == "unix"} {
        # Option to print to STDOUT. UNIX.
        frame $tw.opt.stdout
        radiobutton $tw.opt.stdout.sel -text "Print To STDOUT" \
            -variable Print::print($w,mode) -value "stdout"
        grid $tw.opt.stdout.sel -sticky w -padx 5
        grid $tw.opt.stdout -sticky w -pady 5
        incr cRow
        lappend rowList $cRow

        # Command to print to printer. UNIX.
        frame $tw.opt.print
        radiobutton $tw.opt.print.sel -text "Print Command:" \
            -variable Print::print($w,mode) -value "print"
        entry $tw.opt.print.command -textvariable Print::print($w,command)
        grid $tw.opt.print.sel -sticky w -padx 5
        grid $tw.opt.print.command -sticky ew -padx 5
        grid columnconfigure $tw.opt.print 0 -weight 1
        grid $tw.opt.print -sticky nsew -pady 5
        incr cRow
        lappend rowList $cRow
    }

    # Add the various formats defined in print(fileInfo).  Some may
    # be excluded via the $args to this proc. ie: "-rtf 0" turns off RTF.
    set entryWidth [string length $print($w,textFile)]
    foreach {ftype suffix ext name} $print(fileInfo) {
        if {$print($w,${ftype}Show) == 0} continue
        frame $tw.opt.${ftype}File
        radiobutton $tw.opt.${ftype}File.sel -text "$name File:" \
            -variable Print::print($w,mode) -value $ftype \
            -font {Courier 12}
        entry $tw.opt.${ftype}File.name -width $entryWidth \
            -textvariable Print::print($w,${ftype}File)
        button $tw.opt.${ftype}File.select -text " Select... " \
            -command "Print::SelectPrintFile $w $ftype"
        grid $tw.opt.${ftype}File.sel -columnspan 2 -sticky w -padx 5
        grid $tw.opt.${ftype}File.name $tw.opt.${ftype}File.select \
            -sticky ew -padx 5
        grid columnconfigure $tw.opt.${ftype}File 0 -weight 1
        set print(${ftype}FileEntry) $tw.opt.${ftype}File.name
        $tw.opt.${ftype}File.name xview end
        grid $tw.opt.${ftype}File -sticky nsew -pady 5
        incr cRow
        lappend rowList $cRow
    }

    grid columnconfigure $tw.opt 0 -weight 1
    grid rowconfigure $tw.opt $rowList -weight 1

    frame $tw.buttons -borderwidth 1 -relief raised
    button $tw.buttons.print -text "Print" -width 8 \
        -command "set Print::print(result) ok"
    button $tw.buttons.cancel -text "Cancel" -width 8 \
        -command "set Print::print(result) cancel"
    grid $tw.buttons.print $tw.buttons.cancel -padx 5 -pady 5

    grid $tw.opt -sticky nsew
    grid $tw.buttons -sticky ew
    grid columnconfigure $tw 0 -weight 1
    grid rowconfigure $tw 0 -weight 1

    update
    focus $tw
    grab set $tw
    vwait Print::print(result)
    grab release $tw

    destroy $tw

    return $print(result)
}

# Print::SelectPrintFile --
#
#   File selection for "printing" to a file.
#
# Parameters:
#   which      : Which type of file. See print(fileInfo)
#
# Returns:
#   Nothing.
#
proc Print::SelectPrintFile {w which} {

    variable print

    foreach {ftype suffix ext name} $print(fileInfo) {
        if {$which == $ftype} {
            set fileTypes \
                [list \
                     [list "$name Files" $ext] \
                     [list "All Files" "*"] \
                    ]
            break
        }
    }

    set iDir [file dirname $print($w,${which}File)]
    set tempFile [tk_getSaveFile -title "Save Printed File As" \
                      -filetypes $fileTypes -defaultextension $ext \
                      -initialdir $iDir]

    if {$tempFile != ""} {
        set print($w,${which}File) $tempFile
        $print(${which}FileEntry) xview end
    }

    return
}

# Print::Mode --
#
#   Returns the selected printing mode.  This will be the first field
#   from print(fileInfo).  Note that mode may also be 'stdout' or 'print'
#   on a UNIX machine.  These should be treated as 'text' when generating
#   formatted output!
#
# Parameters:
#   w         : Toplevel widget path
#
# Returns:
#   The mode
#
proc Print::Mode {w} {

    variable print

    return $print($w,mode)
}

# Print::Command --
#
#   Only used by Linux/Unix.  Contains the command to print.
#
# Parameters:
#   w         : Toplevel widget path
#
# Returns:
#   The print command to execute.
#
proc Print::Command {w} {

    variable print

    return $print($w,command)
}

# Print::FileName --
#
#   Returns the filename to print to.
#
# Parameters:
#   w         : Toplevel widget path
#
# Returns:
#   The filename.
#
proc Print::FileName {w} {

    variable print

    set mode [Mode $w]

    if {($mode == "stdout") || ($mode == "print")} {
        set fileName $mode
    } else {
        set fileName $print($w,${mode}File)
    }

    return $fileName
}

# Print::AddWordText --
#
#   Adds some text to MS Word.
#   Formatting options include:
#     -bold {0 | 1 }
#     -underline {0 | 1 }
#     -italic {0 | 1 }
#     -color #RRGGBB
#     -face <font face name>
#     -size <font size>
#
#
# Parameters:
#   w         : Toplevel widget path
#   text      : Text to add. Newline = \r
#
# Returns:
#   Nothing.
#
proc Print::WordAddText {w text args} {

    variable print

    set align ""
    set indent 0
    set bold 0
    set underline 0
    set italic 0
    set color "#000000"
    set size 10.0
    set face {Times New Roman}

    foreach {arg value} $args {
        switch -regexp -- $arg {
            "^-a" { set align $value }
            "^-b" { set bold $value }
            "^-u" { set underline $value }
            "^-it" { set italic $value }
            "^-in" { set indent $value }
            "^-c" { set color $value }
            "^-s" { set size $value }
            "^-f" { set face $value }
        }
    }

    # Move insertion point to end of document
    $print($w,doc,range) End [expr 256*256*256]
    set end [$print($w,doc,range) End]
    $print($w,doc,range) Start $end

    $print($w,doc,para) LeftIndent [expr $indent]

    # Add new text and then format it.
    $print($w,doc,range) Text $text
    $print($w,doc,font) Color [expr [WordColor $color]]
    $print($w,doc,font) Name $face
    $print($w,doc,font) Size [expr $size]
    $print($w,doc,font) Bold [expr $bold]
    $print($w,doc,font) Underline [expr $underline]
    $print($w,doc,font) Italic [expr $italic]

    # Alignment, if specified
    if {$align != ""} {
        $print($w,doc,para) Alignment [expr $align]
    }

    return
}

# Print::WordColor --
#
#   Generates the Word decimal equivalent for #RRGGBB format colors.
#
# Parameters:
#   color     : Color in #RRGGBB format
#
# Returns:
#   Decimal equivalent.
#
proc Print::WordColor {color} {

    set red   [expr 0x[string range $color 1 2]]
    set green [expr 0x[string range $color 3 4]]
    set blue  [expr 0x[string range $color 5 6]]

    return [expr $red + $green * 256 + $blue * 256 * 256]
}

# Print::Head --
#
#   Returns anything required to initialize a file format.
#
# Parameters:
#   w         : Toplevel widget path
#   title     : Title for the document
#
# Returns:
#   Formated text.
#
proc Print::Head {w title} {

    variable print

    set print($w,text) ""
    set out ""

    switch -- [Mode $w] {
        "rtf" {
            append out "\{\\rtf1\\ansi\\deff0\\deftab720"
            append out "\{\\fonttbl\{\\f0\\fnil MS Sans Serif;\}"
            append out "\{\\f1\\fnil\\fcharset2 Symbol;\}"
            append out "\{\\f2\\fswiss\\fprq2 System;\}"
            append out "\{\\f3\\fnil Times New Roman;\}\}\n"
            append out "\{\\colortbl \\red0\\green0\\blue0;"
	    foreach colorName {blueline attributes usable} {
		set color $Config::config(Print,color,$colorName)
		set red   [expr 0x[string range $color 1 2]]
		set green [expr 0x[string range $color 3 4]]
		set blue  [expr 0x[string range $color 5 6]]
		append out "\\red$red\\green$green\\blue$blue;"
	    }
	    append out "\}\\deflang1033\n"

        }
        "html" {
            append out "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 3.2//EN\">\n"
            append out "<HTML>\n<HEAD>\n"
            append out "<META NAME=\"GENERATOR\" CONTENT=\"CrossFire\">\n"
            append out "<TITLE>$title</TITLE>\n"
            append out "</HEAD>\n\n<BODY>\n"
        }
        "bbc" {
            append out "Create a new thread to discuss your deck here:\n"
            append out "http://spellfire.net/forums/forum.asp?FORUM_ID=6\n"
            append out "Then copy and paste the below text into the new "
            append out "thread.\n\n"
        }
        "doc" {
            set print($w,doc,word)  [::tcom::ref createobj "Word.Application"]
            set print($w,doc,docs)  [$print($w,doc,word) Documents]
            set print($w,doc,myDoc) [$print($w,doc,docs) Add]
            set print($w,doc,range) [$print($w,doc,myDoc) Range]
            set print($w,doc,font)  [$print($w,doc,range) Font]
            set print($w,doc,para)  [$print($w,doc,range) ParagraphFormat]
        }
        default {
            # This covers text, stdout, print, and anything forgotten.
        }
    }

    append print($w,text) $out
    return $out
}

# Print::Title --
#
#   Returns a formatted title for the document.
#
# Parameters:
#   w         : Toplevel widget path
#   title     : Title of the document
#
# Returns:
#   Formated text.
#
proc Print::Title {w title} {

    variable print

    if {$title == ""} {
        return ""
    }

    set out ""

    switch -- [Mode $w] {
        "rtf" {
            append out "\\pard\\qc\\plain\\f3\\fs28 $title\n"
            append out [Blank $w]
        }
        "html" {
            append out "<H1 ALIGN=CENTER>$title</H1>\n"
        }
        "bbc" {
            append out "Title: \[b\]$title\[/b\]\n"
        }
        "doc" {
            WordAddText $w "$title\r" -size 14.0 -align 1
            Blank $w
        }
        "flat" {
            append out "Title: $title\n"
        }
        default {
            append out "[CrossFire::CenterString $title]\n\n"
        }
    }

    append print($w,text) $out
    return $out
}

# Print::Author --
#
#   Returns the formatted author's name.
#
# Parameters:
#   w         : Toplevel widget path
#   author    : Name of author
#
# Returns:
#   Formated text.
#
proc Print::Author {w author} {

    variable print

    if {$author == ""} {
        return ""
    }

    set out ""

    switch -- [Mode $w] {
        "rtf" {
            append out "\\par \\pard\\qc\\plain\\f3\\fs20 Created by $author\n"
        }
        "html" {
            append out "<H2 ALIGN=CENTER>Created by $author</H2>\n"
        }
        "bbc" {
            append out "Created by $author\n"
        }
        "doc" {
            WordAddText $w "Created by $author\r" -align 1
        }
        "flat" {
            append out "Author: $author\n"
        }
        default {
            append out [CrossFire::CenterString "Created by $author"]
            append out "\n"
        }
    }

    append print($w,text) $out
    return $out
}

# Print::Email --
#
#   Returns the author's formatted email address.
#
# Parameters:
#   w         : Toplevel widget path
#   email     : Author's email address
#
# Returns:
#   Formated text.
#
proc Print::Email {w email} {

    variable print

    if {$email == ""} {
        return ""
    }

    set out ""

    switch -- [Mode $w] {
        "rtf" {
            append out "\\par \\pard\\qc\\plain\\f3\\fs20 Email: $email\n"
        }
        "html" {
            append out "<CENTER>\n"
            append out "<I><A HREF=\"mailto:$email\">$email</A></I>\n"
            append out "</CENTER>\n"
        }
        "bbc" {
            append out "Email: $email\n"
        }
        "doc" {
            WordAddText $w "Email: $email\r" -align 1
        }
        "flat" {
            append out "Email: $email\n"
        }
        default {
            append out [CrossFire::CenterString "Email: $email"]
            append out "\n"
        }
    }

    append print($w,text) $out
    return $out
}

# Print::Center --
#
#   Formats some text such that it is centers.
#
# Parameters:
#   w         : Toplevel widget path
#   text      : Text to center
#
# Returns:
#   Formated text.
#
proc Print::Center {w text} {

    variable print

    set out ""

    switch -- [Mode $w] {
        "rtf" {
            append out "\\par \\pard\\qc\\plain\\f3\\fs20 $text\n"
        }
        "html" {
            append out "<CENTER>$text</CENTER>\n"
        }
        "bbc" {
            append out "\[b\]$text\[/b\]\n"
        }
        "doc" {
            WordAddText $w "$text\r" -align 1
        }
        "flat" {
            append out "Info: $text\n"
        }
        default {
            append out "[CrossFire::CenterString $text]\n"
        }
    }

    append print($w,text) $out
    return $out
}

# Print::Notes --
#
#   Returns formatted block of notes. More noticeable than plain text.
#
# Parameters:
#   w         : Toplevel widget path
#   notes     : Text notes
#
# Returns:
#   Formated text.
#
proc Print::Notes {w notes} {

    variable print

    set out ""

    switch -- [Mode $w] {
        "rtf" {
            append out "\\pard\\plain\\f3\\fs20 $notes"
        }
        "html" {
            append out "<BLOCKQUOTE>\n$notes</BLOCKQUOTE>\n"
        }
        "bbc" {
            append out "\[h3\]Notes:\[/h3\]$notes\n"
        }
        "doc" {
            WordAddText $w "$notes\r"
        }
        "flat" {
            regsub -all "\n" $notes " " notes
            append out "Notes: $notes\n"
        }
        default {
            append out [CrossFire::SplitLine 72 $notes 4]
        }
    }

    append print($w,text) $out
    return $out
}

# Print::Heading --
#
#   Formats a heading line depending on the mode.
#
# Parameters:
#   w         : Toplevel widget path
#   heading   : Heading text
#
# Returns:
#   Formatted heading.
#
proc Print::Heading {w heading} {

    variable print

    set out ""

    switch -- [Mode $w] {
        "rtf" {
            append out "\\par \\pard\\plain\\f3\\b\\fs24 $heading\n"
        }
        "html" {
            append out "<H3>$heading</H3>\n"
        }
        "bbc" {
            append out "\[h3\]$heading\[/h3\]\n"
        }
        "doc" {
            WordAddText $w "$heading\r" -bold 1 -size 12.0
            Blank $w
        }
        "flat" {
            append out "Heading: $heading\n"
            Blank $w
        }
        default {
            append out "$heading\n"
        }
    }

    append print($w,text) $out
    return $out
}

# Print::Card --
#
#   Returns a properly formatted card.
#
# Parameters:
#   w         : Toplevel widget path
#   card      : Card information in standard card format
#
# Returns:
#   Formated text.
#
proc Print::Card {w card args} {

    variable print

    set mode ""
    set printText 1
    set out ""

    foreach {arg value} $args {
        switch -- $arg {
            "-text" {
                set printText $value
            }
            "-mode" {
                set mode $value
            }
        }
    }

    if {$mode == ""} {
        set mode [Mode $w]
    }

    foreach {
        setID cardNumber bonus cardType worldID isAvatar
        name cardText rarity blueLine attrList usesList weight
    } $card break

    # Convert the attribute IDs to names
    set attrNew {}
    foreach id $attrList {
        if {[info exists CrossFire::cardAttributes(attr,$id)]} {
            lappend attrNew $CrossFire::cardAttributes(attr,$id)
        } else {
            lappend attrNew $id
        }
    }
    set attrList $attrNew

    # Convert the uses IDs to names
    set usesNew {}
    foreach id $usesList {
        if {[info exists CrossFire::usableCards(uses,$id)]} {
            lappend usesNew $CrossFire::usableCards(uses,$id)
        } else {
            lappend usesNew $id
        }
    }
    set usesList $usesNew

    set cardName [CrossFire::GetCardDesc $card]

    switch -- $mode {
        "rtf" {
            append out "\\par \\pard\\plain\\f3\\b\\fs20 \\tab $cardName\n"
        }
        "html" {
            append out "<B>&nbsp;&nbsp;&nbsp;&nbsp;$cardName</B><BR>\n"
        }
        "bbc" {
            set cardNum [format %03d $cardNumber]
            append out "\[b\]$name\[/b\]\n"
            append out "\[size=1]\[i\]"
            if {$bonus != ""} {
                if {[lsearch "$CrossFire::championList 13 8" $cardType] != -1} {
                    # Champions, realms, and holdings
                    append out "Level "
                }
                append out "$bonus "
            }
            append out $CrossFire::cardTypeXRef($cardType,name)
            if {[lsearch "0 9" $worldID] == -1} {
                # world is NOT 0 (none) or 9 (no world)
                append out ", $CrossFire::worldXRef($worldID,name)"
            }
            append out "\[/i\]\n"
        }
        "doc" {
            WordAddText $w "\t$cardName\r" -bold 1
        }
        "flat" {
            foreach {cardID cNum setMax} \
            [CrossFire::GetCardID $setID $cardNumber] break
            append out "ID: $cardID $setID $cNum\n"
            append out "Name: $name\n"
            append out "Type: $CrossFire::cardTypeXRef($cardType,name)\n"
            append out "Bonus: $bonus\n"
            append out "World: $CrossFire::worldXRef($worldID,name)\n"
            append out "Rarity: $rarity\n"
        }
        default {
            # This covers text, stdout, print, and anything forgotten.
            append out "    $cardName\n"
        }
    }

    if {($cardText != "") && ($printText == 1)} {
        if {$cardType == 15} {
            # Rule card. remove intructional text if desired.
            set cardText [ViewCard::FixCardText $cardText Print]
        }
        set printBlueLine $Config::config(Print,show,blueline)
        set printAttributes $Config::config(Print,show,attributes)
        set aText [ViewCard::FormatAttributeList $attrList $mode]
        set printUsable $Config::config(Print,show,usable)
        set uList ""
        foreach usable $usesList {
            if {$uList != ""} {
                append uList "; "
            }
            append uList $usable
        }
        set uText "Uses: $uList."
        switch -- $mode {
            "rtf" {
                if {($blueLine != "") && ($printBlueLine == "Yes")} {
                    append cardText " \\cf1 $blueLine\\cf0 "
                }
                if {($attrList != "") && ($printAttributes == "Yes")} {
                    append cardText " \\cf2 $aText.\\cf0 "
                }
                if {($usesList != "") && ($printUsable == "Yes")} {
                    append cardText " \\cf3 $uText\\cf0 "
                }
                append out "\\par \\pard\\li1440\\plain\\f3\\fs20 $cardText\n"
                append out [Blank $w]
            }
            "html" {
                append out "<BLOCKQUOTE>\n$cardText\n"
                if {($blueLine != "") && ($printBlueLine == "Yes")} {
                    append out "<FONT COLOR=\""
                    append out $Config::config(Print,color,blueline)
                    append out "\">$blueLine</FONT>\n"
                }
                if {($attrList != "") && ($printAttributes == "Yes")} {
                    append out "<FONT COLOR=\""
                    append out $Config::config(Print,color,attributes)
                    append out "\">$aText.</FONT>\n"
                }
                if {($usesList != "") && ($printUsable == "Yes")} {
                    append out "<FONT COLOR=\""
                    append out $Config::config(Print,color,usable)
                    append out "\">$uText</FONT>\n"
                }
                append out "</BLOCKQUOTE>\n"
            }
            "bbc" {
                append out $cardText
                if {($blueLine != "") && ($printBlueLine == "Yes")} {
                    append out " \[blue\]$blueLine\[/blue\]"
                }
            }
            "doc" {
                WordAddText $w "$cardText " -indent 72
                if {($blueLine != "") && ($printBlueLine == "Yes")} {
                    WordAddText $w "$blueLine " -indent 72 \
                        -color $Config::config(Print,color,blueline)
                }
                if {($attrList != "") && ($printAttributes == "Yes")} {
                    WordAddText $w "$aText. " -indent 72 \
                        -color $Config::config(Print,color,attributes)
                }
                if {($usesList != "") && ($printUsable == "Yes")} {
                    WordAddText $w "$uText " -indent 72 \
                        -color $Config::config(Print,color,usable)
                }
                WordAddText $w "\r" -indent 72
                Blank $w
            }
            "flat" {
                regsub -all "\n" $cardText " " cardText
                append out "Text: $cardText\n"
                append out "Blueline: $blueLine\n"
                append out "Attribute: $aText\n"
                append out "Usable: $uList\n"
                Blank $w
            }
            default {
                if {($blueLine != "") && ($printBlueLine == "Yes")} {
                    append cardText " $blueLine"
                }
                if {($attrList != "") && ($printAttributes == "Yes")} {
                    append cardText " $aText."
                }
                if {($usesList != "") && ($printUsable == "Yes")} {
                    append cardText " $uText"
                }
                append out "[CrossFire::SplitLine 78 $cardText 8]\n"
            }
        }
    }

    if {$mode == "bbc"} {
        append out "\n\[url=\"https://raw.github.com/spellfire/CrossFire/master/Graphics/Cards/"
        append out "$setID/$cardNum.jpg\"\]$CrossFire::setXRef($setID,name)"
        foreach {cardID cardNum setMax} \
            [CrossFire::GetCardID $setID $cardNumber] break
        append out " \#$cardNum of $setMax"
        append out "\[/url\]\n\[/size=1\]\n\n"
    }

    append print($w,text) $out
    return $out
}

# Print::Blank --
#
#   Returns a blank line.
#
# Parameters:
#   w         : Toplevel widget path
#
# Returns:
#   Formated text.
#
proc Print::Blank {w} {

    variable print

    set out ""

    switch -- [Mode $w] {
        "rtf" {
            append out "\\par \\pard\\plain\\f3\\fs20 \n"
        }
        "html" {
            append out "<BR>\n"
        }
        "bbc" {
            append out "\n"
        }
        "doc" {
            WordAddText $w "\r"
        }
        "flat" {
            append out "\n"
        }
        default {
            append out "\n"
        }
    }

    append print($w,text) $out
    return $out
}

# Print::Separator --
#
#   Returns a separator (horizontal line mostly).
#
# Parameters:
#   w         : Toplevel widget path
#
# Returns:
#   Formated text.
#
proc Print::Separator {w} {

    variable print

    set out ""

    switch -- [Mode $w] {
        "rtf" {
            append out "\\par \\pard\\plain\\f3\\fs20 \n"
        }
        "html" {
            append out "<P><HR><P>\n"
        }
        "bbc" {
            append out "\n"
        }
        "doc" {
            WordAddText $w "\r"
        }
        "flat" {
            append out "\n"
        }
        default {
            append out "\n" [string repeat "-" 79] "\n\n"
        }
    }

    append print($w,text) $out
    return $out
}

# Print::Tail --
#
#   Returns any text needed to close a file's format.
#
# Parameters:
#   w         : Toplevel widget path
#
# Returns:
#   Formated text.
#
proc Print::Tail {w} {

    variable print

    set out ""

    switch -- [Mode $w] {
        "rtf" {
            append out "\\par \}\n"
        }
        "html" {
            append out "</BODY>\n</HTML>\n"
        }
        "bbc" {
        }
        "doc" {
            $print($w,doc,myDoc) SaveAs [FileName $w] [expr 0]
            $print($w,doc,word) Quit [expr 0]
        }
        "flat" {
            append out "\n"
        }
        default {
        }
    }

    append print($w,text) $out
    return $out
}

# Print::Print --
#
#   Prints the generated text.
#
# Parameters:
#   w         : Toplevel widget path
#
# Returns:
#   Nothing.
#
proc Print::Print {w} {

    variable print

    switch -- [Mode $w] {
        "stdout" {
            puts $print($w,text)
        }
        "print" {
            # Call Unix lpr (q.v.) command to print the deck
            exec echo "$print($w,text)" | [Print::Command $w]
        }
        "doc" {
            # Do nothing. Save is done with Tail command
        }
        default {
            set fileID [open [Print::FileName $w] "w"]
            puts $fileID $print($w,text)
            close $fileID
        }
    }

    unset print($w,text)

    return
}