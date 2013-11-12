![Online Chat icon](https://raw.github.com/spellfire/CrossFire/master/Graphics/Cards/DL/030.gif) ![Online Chat icon](https://raw.github.com/spellfire/CrossFire/master/Graphics/Cards/3rd/045.gif) ![Online Chat icon](https://raw.github.com/spellfire/CrossFire/master/Graphics/Cards/FR/004.gif) ![Online Chat icon](https://raw.github.com/spellfire/CrossFire/master/Graphics/Cards/1st/456.gif) ![Online Chat icon](https://raw.github.com/spellfire/CrossFire/master/Graphics/Cards/1st/442.gif)

# CrossFire
CrossFire is free desktop software (for Windows, Mac and Linux) for playing the game of Spellfire online in real-time (and for other Spellfire related activities like building decks, organizing card collections and more).

## About Spellfire
[Spellfire](http://en.wikipedia.org/wiki/Spellfire) is a collectible card game from the 90's. It was discontinued, but fans have continued to develop the game by releasing new cards online. The game is easy to learn and fun to play. There is a rich set of cards to choose from, so building decks is also fun and interesting.

## Install CrossFire
Installing CrossFire is a two-step process:

1. Install ActiveTCL
2. Install CrossFire

### Install ActiveTCL
Download version 8.4.x (e.g 8.4.20) of ActiveState Tcl for your operating system (Windows, Mac or Linux) from here: [http://www.activestate.com/activetcl/downloads](http://www.activestate.com/activetcl/downloads). Do not use newer versions of ActiveState Tcl (e.g. 8.5.x or 8.6.x).

### Install CrossFire
Download the latest version from GitHub here: [https://github.com/spellfire/CrossFire/archive/master.zip](https://github.com/spellfire/CrossFire/archive/master.zip). Unzip the CrossFire-master.zip file to some place on your hard drive (e.g. your desktop).

## Open CrossFire

### Windows
Double-click the "CrossFire.tcl" file inside the CrossFire folder that you saved to your hard drive.

### Mac
Double-click the "CrossFire Launcher for Mac" file inside the CrossFire folder that you saved to your hard drive.

## Open Online Chat Interface for Online Real-time Games

Click the Online Chat icon ![Online Chat icon](https://raw.github.com/spellfire/CrossFire/master/Graphics/XFire/chatRoom.gif) from the CrossFire window that opens at launch. Enter any username and password. Make the password easy to remember because it's not possible to reset it.

## Spellfire Communities
Ask someone to show you how to play Spellfire online via one of these communities:

1. [Spellfire Players Facebook Group](https://www.facebook.com/groups/2375681829/)
2. [Spellfire Mailing List](http://spellfire.net/mlist.shtml)
3. [Spellfire Brazil Forum](http://forum.spellfire.org/)

## Troubleshooting Windows Access Denied Error
If you get an error like this:

    unable to open key: Access is denied.
    while executing
    "registry set "HKEY_CLASSES_ROOT\\$extension" ""$type"
    (procedure "AssociateFileType" line 61)
    invoked from within
    "AssociateFileType $ext"
    (rocedure "Registry::AssociateFiles" line 
    invoked from within
    "Registry::AssociateFiles"
    (file "C:\Users\Joe Smith\Desktop\CrossFire\CrossFire.tcl" line 377)

...try one of these options:

1. go to "C:\TC\BIN" Directory -> Right-click on each executable (.exe) file -> click on Property -> click on Compatibility Tab -> Under Privilege Level, check on "Run this program as an administrator".
2. Disable UAC (User Account Control) as described here: [http://windows.microsoft.com/en-us/windows-vista/turn-user-account-control-on-or-off](http://windows.microsoft.com/en-us/windows-vista/turn-user-account-control-on-or-off)

## Troubleshooting Windows Vista ActiveTcl Install
Instead of the latest version of ActiveTcl 8.4.x (e.g. 8.4.20), you might need version 8.4.18. [Searching the web for "ActiveTcl8.4.18.0.284097-win32-ix86-threaded.exe"](https://duckduckgo.com/?q=%22ActiveTcl8.4.18.0.284097-win32-ix86-threaded.exe%22) reveales this download source: [https://www.4shared.com/zip/0rlxvGbY/ActiveTcl84180284097-win32-ix8.html](https://www.4shared.com/zip/0rlxvGbY/ActiveTcl84180284097-win32-ix8.html). Try that.