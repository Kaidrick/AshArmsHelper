﻿#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

CoordMode, Pixel, Window

#Include MapLib.ahk
#Include HumanBehaviors.ahk

; To-do list
; 1. make a basic click wait function
; 2. add a timer
; 3. add an GUI for user control
; 4. add more map options such as 1-2(need new function) and 4-10 or so
; 5. deals with errors


; General Image Search Ranges
mapNodeSelection := {x1: 53, x2: 1203, y1: 300, y2: 420}
homeNode := {x1: 1186, x2: 1261, y1: 20, y2: 89}

; frequency
stdWaitTime = 2.0
stdLoadTime = 8.0

; Click error
stdErrorRange = 12.0  ; px


; Create GUI control panel
clickPos := "Current Click -> x = 0, y = 0"
workStatus := "Starting"
winSize := "Target Window Size"

winResolutionWidth := 1280
winResolutionHeight := 720

canRun := false
useCoordDataOnly := false


Gui, Add, Text, x5 y5 h14 w150 vWorkStatusIndicator, %workStatus%
Gui, Add, Text, x5 y25 h14 w150 vWinSize, %winSize%
Gui, Add, Text, x5 y45 h14 w450 vClickPosIndicator, %clickPos%

Gui, Show, w500 h200, % "アッシュアームズ自動管理システム"

Gui, Add, Button, x5 y85 h20 w50 gTestFind, % "Start"
Gui, Add, Button, x5 y105 h20 w50 gBigSwitchOff, % "Stop"
Gui, Add, Button, x5 y125 h20 w50 gTapTap, % "Tap Fes!"

Gui, Add, CheckBox, x5 y145 h20 w150 gForceClick, % "Coord mode for scale"

GuiControl,, ClickPosIndicator, % "Ready"

; try get window handle
WinGet, asaGameHwnd, ID, アッシュアームズ - MuMu模拟器

if (asaGameHwnd) {
	GuiControl,, WorkStatusIndicator, % "Emulator HWND: " + asaGameHwnd
	
	; get window resolution at start
	WinGetPos,,, winResolutionWidth, winResolutionHeight, ahk_id %asaGameHwnd%
	GuiControl,, WinSize, Initial Window Size: %winResolutionWidth% x %winResolutionHeight%
} else {
	MsgBox, Unable to locate Ash Arms emulator window.`rPlease make sure the emulator is running properly.`rAHK will now quit.
	ExitApp
}


; Data

; Auto Play Wait Data
mapData03A02N = {wait: 120} ; in seconds

; IMPORTANT: notice that the image in the path is the anchor image
;            an offset need to be provided to correct the click point
;            if no offset is given, it will click on the center of the image itself

; Campaign Map
mapCampaign := {x: 817, y: 252, path: "mainPage_CapaignMap.png", offset: {x: 0, y: -22}, size: {w: 145, h: 121}, act: "出撃"}
;~ mapCampaign := {x: 535, y: 221, act: "出撃"} ; fake!
; 03A Map
mapView03A := {x: 475, y: 470, path: "mapTheater_03A.png", offset: {x: -13, y: 3}, size: {w: 50, h: 39}, act: "雪原 「03A」"}
; 03A-02 N
; x y coordinates for backup mode, since it is impossible to deal with resized image? maybe prepare two versions of the images in different reoslution.
mapSel02N := {x: 640, y: 416, path: "mapSel_03A-02N.png", type: "mapNodeSel", offset: {x: -98, y: 82}, size: {w: 125, h: 27}, act: "▶ 03A-02 N"}
; Go
orderReady := {x: 1048, y: 654, path: "mapSel_OrderReady.png", offset: {x: 75, y: 48}, size: {w: 58, h: 64}, act: "ステージ情報 出撃"}
; Confirm Go
affirmReady := {x: 1041, y: 664, path: "preStage_Consumption.png", offset: {x: 382, y: -5}, size: {w: 26, h: 31}, act: "出撃準備 確認"}
; Auto
autoBattle := {x: 234, y: 42, path: "battleViewWithdraw.png", offset: {x: 158, y: 0}, size: {w: 51, h: 33}, act: "Auto ▷"}

; BattleResult
resultBattleStats := {x: 0, y: 0, path: "resultBattleStats.png", offset: {x: 0, y: 0}, size: {w: 0, h: 0}, act: "Battle Result Check", override: "quick taps"}

; TapTap
tapAnywhere := {x: 642, y: 73, act: "Quick Taps"}

; Back Button
returnArrowButton := {x: 60, y: 40, act: "Return to Previous Page"}

; Home Button
returnHomeButton := {x: 1226, y: 50, path: "homePage.png", type: "returnHome", size: {w: 26, h: 30}, act: "Return Home Page"}


; Errors
refreshPlayerData := {x: 0, y: 0, path: "Error_RefreshPlayerData.PNG", size: {w: 195, h: 40}, offset: {x: 167, y: 164}, act: "Deal RefreshPlayerData error"}
networkError := {x: 0, y: 0, path: "Error_NetWork.PNG", size: {w: 208, h: 36}, offset: {x: 167, y: 164}, act: "Deal RefreshPlayerData error"}
connectionError := {x: 0, y: 0, path: "Error_Connection.png", size: {w: 247, h: 38}, offset: {x: 258, y: 165}, act: "Deal RefreshPlayerData error"}
return



; Subroutines
TapTap:
;~ quickTapAnywhere()
;~ startFromHome()
;~ simulateRandomBehavior()
;~ autoBattle()
;~ checkBattleResult()
;~ findClick(refreshPlayerData)
checkForError()
return


TestFind:
gosub BigSwitchOn
gosub Grind03A-02N

;~ WinActivate, ahk_id %asaGameHwnd%
;~ ImageSearch, imgX, imgY, mapNodeSelection["x1"], mapNodeSelection["y1"], mapNodeSelection["x2"], mapNodeSelection["y2"], *50 mapSel_03A-02N.png

;~ if(ErrorLevel = 1) 
;~ {
	;~ TrayTip,,Image Not Found, 5
;~ }
;~ else if(ErrorLevel = 0) 
;~ {
	;~ TrayTip,,Image Found + %imgX% + %imgY%, 5
;~ }
return

BigSwitchOn:
canRun := true
return

BigSwitchOff:
canRun := false
Reload
return

ForceClick:
if (useCoordDataOnly = true) {
	useCoordDataOnly := false
} else {
	useCoordDataOnly := true
}

Grind03A-02N:
if (canRun != true) {
	return
} else {
	TrayTip,, Grinding 03A-02 N non-stop, 5
}

startFromHome()
Sleep 2000  ; wait for main page
; TODO: use image search to determine

rWait := NormalRand(0, stdWaitTime, 0)
Sleep rWait

; generate a random click wait time
rWait := NormalRand(0, stdWaitTime, 0)
findClick(mapCampaign)
;~ switchView(mapCampaign)
Sleep rWait

rWait := NormalRand(0, stdWaitTime, 0)
findClick(mapView03A)
;~ switchView(mapView03A)
Sleep rWait

gosub Continue03A-02N
return


Continue03A-02N:
while(true) {
	;~ Random, rWait, 1500.0, 4500.0
	rWait := NormalRand(0, stdWaitTime, 0)

	findClick(mapSel02N)
	Sleep rWait * 1000

	findClick(orderReady)
	Sleep rWait * 1000

	findClick(affirmReady)
	
	findClick(autoBattle)
	
	findClick(resultBattleStats,,,true)
	
	;~ simulateRandomBehavior()  ; more reasonable because usually i put it game on auto and switch to other task but forgot about it for a while
	; put it in find click?
	
	
	;~ ; if useCoordDataOnly is true
	;~ if (useCoordDataOnly) {  ; use coord data and time to operate
		;~ Sleep stdLoadTime * 1000  ; to milliseconds
		;~ switchView(autoBattle)
		;~ countdown := 90
		;~ while (countdown > 0) {
			;~ countdown--
			;~ Sleep 1000
			;~ changeStatusText("counting down ... " + countdown)
		;~ }
	;~ } else {  ; use image search to determine phase
		;~ autoBattle()
		;~ Sleep 1000
		
		;~ checkBattleResult()
		;~ changeStatusText("Waiting for battle result")
		;~ ; check battle result
	;~ }


	;~ quickTapAnywhere()

	if(canRun = true) {
		Sleep 1000
		
	} else {
		;~ MsgBox, do not run again
		Reload
	}
}

; Test line ends here
return


GuiClose:
ExitApp
