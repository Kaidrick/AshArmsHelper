#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Test Gdip Search Image
CoordMode, Pixel, Window

#Include Gdip_All.ahk
#Include Gdip_ImageSearch.ahk

; try get window handle
WinGet, asaGameHwnd, ID, アッシュアームズ - MuMu模拟器

p := Gdip_Startup()

hwnd := WinExist("アッシュアームズ - MuMu模拟器")

pBitmapHayStack := Gdip_BitmapFromHWND(hwnd)

pBitmapNeedle := Gdip_CreateBitmapFromFile("C:\Users\Administrator\Documents\Autohotkey\mainPage_CapaignMap.png")

msgbox, % pBitmapHayStack "," pBitmapNeedle

result := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle,OutputList,,,,,60,0,1,1)

array := StrSplit(OutputList, ",")

msgbox, % array[1] array[2] ;There is no value of Outpulist when running this script

msgbox, % result    ; value of result is "0" when running this script


return