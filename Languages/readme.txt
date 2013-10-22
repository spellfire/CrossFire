How to make your own custom language file...

1) Copy the en.lng file to another file such as my.lng
2) Change the 'Language' in the braces {English} to something else.
   Example:  Language {My Custom Language}
3) Change the phrases in the braces {} only.  Do not change the first
   word because that is the 'key' it searches for.

Example:
  quit     {Quit}
could be changed to:
  quit     {Go Away!}


You can add comments by starting a line with the pound (#) sign.

Example:
# This is a comment that someone may want to read someday.