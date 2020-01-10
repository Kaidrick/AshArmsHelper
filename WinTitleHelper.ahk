;~ ########################################################################################
;~ This little script helps you to find the title of your emulator
;~ ****************************************************************************************
;~ How To Use:
;~ 1. run this script and focus a window, then press F12 
;~ 2. you will be shown a message box containing the info of the current focused window.
;~ 3. press F11 to exit this script
;~ ########################################################################################

F12::
MouseGetPos, tX, tY, tWin
WinGetTitle, winTitle, ahk_id %tWin%
MsgBox % "Window Title: " winTitle "`nHWND: " tWin
return

F11::
ExitApp
