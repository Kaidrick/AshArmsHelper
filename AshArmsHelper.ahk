﻿#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

CoordMode, Pixel, Window

#Include MapLib.ahk
#Include JSON.ahk

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
statsRun := "Stats"

winResolutionWidth := 1280
winResolutionHeight := 720

; Script states
canRun := false
isRepeatTask := false
useCoordDataOnly := false


Gui, Add, Text, x5 y5 h14 w150 vWorkStatusIndicator, %workStatus%
Gui, Add, Text, x5 y25 h14 w350 vWinSize, %winSize%
Gui, Add, Text, x5 y45 h14 w450 vClickPosIndicator, %clickPos%
Gui, Add, Text, x400 y25 h14 w100 vRunNum, %statsRun%

Gui, Show, w500 h200, % "アッシュアームズ自動管理システム"

Gui, Add, Button, x5 y85 h20 w50 vMasterButton gMasterRoutine, % "Start"
Gui, Add, Button, x5 y105 h20 w50 vStopButton gBigSwitchOff, % "Stop"
Gui, Add, Button, x5 y125 h20 w50 gTapTap, % "Tap Fes!"

; map selection dropdown list
Gui, Add, DropDownList, x250 y150 vStageChoice gOnStageSelect w100 h50 Choose2 R5, 遺跡 01-02|雪原 03A-02 N|溶岩 04A-10 N

Gui, Add, CheckBox, x5 y145 h20 w150 gForceClick, % "Coord mode for scale"

GuiControl,, ClickPosIndicator, % "Ready"
GuiControl, Disable, StopButton


; Initialize
selStage := "雪原 03A-02 N"
; Load image data from json file and then merge into a singe object
FileRead, generalJson, ImageSearchData.json
FileRead, theaterJson, Map_TheaterData.json
FileRead, nodeJson, Map_StageNodeData.json

generalData := JSON.Load(generalJson)
theaterData := JSON.Load(theaterJson)
nodeData := JSON.Load(nodeJson)

allData := {}
for k, v in generalData
	ObjRawSet(allData, k, v)

for k, v in theaterData
	ObjRawSet(allData, k, v)

for k, v in nodeData
	ObjRawSet(allData, k, v)



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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Campaign Map
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mapCampaign := {x: 817, y: 252, path: "mainPage_CapaignMap.png", offset: {x: 0, y: -22}, size: {w: 145, h: 121}, act: "出撃"}
;~ mapCampaign := {x: 535, y: 221, act: "出撃"} ; fake!

; 03A Map
mapView_01 := {x: 433, y: 272, path: "mapTheater_01.png", offset: {x: -13, y: 3}, size: {w: 45, h: 33}, act: "遺跡 「01」"}
mapView_03A := {x: 475, y: 470, path: "mapTheater_03A.png", offset: {x: -13, y: 3}, size: {w: 51, h: 49}, act: "雪原 「03A」"}
mapView_04A := {x: 855, y: 381, path: "mapTheater_04A.png", offset: {x: -13, y: 3}, size: {w: 49, h: 32}, act: "溶岩 「04A」"}

; 03A-02 N
; x y coordinates for backup mode, since it is impossible to deal with resized image? maybe prepare two versions of the images in different reoslution.
mapSel_0102 := {x: 640, y: 416, path: "mapSel_01-02.png", type: "mapNodeSel", offset: {x: -98, y: 82}, size: {w: 96, h: 23}, act: "▶ 01-02"}
mapSel_03A02N := {x: 640, y: 416, path: "mapSel_03A-02N.png", type: "mapNodeSel", offset: {x: -98, y: 82}, size: {w: 125, h: 27}, act: "▶ 03A-02 N"}
mapSel_04A10N := {x: 640, y: 416, path: "mapSel_04A-10N.png", type: "mapNodeSel", offset: {x: -98, y: 82}, size: {w: 128, h: 24}, act: "▶ 04A-10 N"}



; Go
orderReady := {x: 1048, y: 654, path: "mapSel_OrderReady.png", offset: {x: 75, y: 48}, size: {w: 58, h: 64}, act: "ステージ情報 出撃"}
; Confirm Go
affirmReady := {x: 1041, y: 664, path: "preStage_Consumption.png", offset: {x: 382, y: -5}, size: {w: 26, h: 31}, act: "出撃準備 確認"}
; Auto
autoBattle := {x: 234, y: 42, path: "battleViewWithdraw.png", offset: {x: 158, y: 0}, size: {w: 51, h: 33}, act: "Auto ▷"}

; BattleResult
resultBattleStats := {x: 0, y: 0, path: "resultBattleStats.png", offset: {x: 0, y: 0}, size: {w: 0, h: 0}, act: "Battle Result Check", override: "quick taps"}

; TapTap
tapAnywhere := {x: 642, y: 73, act: "Quick Taps"}  ; need xy data for different games, supposedly?

; Back Button
returnArrowButton := {x: 60, y: 40, act: "Return to Previous Page"}

; Home Button
returnHomeButton := {x: 1226, y: 50, path: "homePage.png", type: "returnHome", size: {w: 26, h: 30}, act: "Return Home Page"}


; Errors
refreshPlayerData := {x: 0, y: 0, path: "Error_RefreshPlayerData.PNG", size: {w: 195, h: 40}, offset: {x: 167, y: 164}, act: "Deal RefreshPlayerData error"}
networkError := {x: 0, y: 0, path: "Error_NetWork.PNG", size: {w: 208, h: 36}, offset: {x: 167, y: 164}, act: "Deal Network error"}
connectionError := {x: 0, y: 0, path: "Error_Connection.png", size: {w: 247, h: 38}, offset: {x: 258, y: 165}, act: "Deal Connection error"}
return



OnStageSelect:
Gui, Submit, nohide
selStage := StageChoice

TrayTip,, Grinding Stage: %selStage%, 5
MsgBox, %selStage%
return



; Subroutines
TapTap:
;~ quickTapAnywhere()
;~ startFromHome()
;~ simulateRandomBehavior()
;~ autoBattle()
;~ checkBattleResult()
;~ findClick(mapCampaign,,,true)
;~ checkForError()
;~ MsgBox, %MapChoice%
;~ gosub BigSwitchOn

; test json




return


MasterRoutine:
runCount = 0
GuiControl,, RunNum, % "Round: " runCount

; run the process
gosub BigSwitchOn
while(true) {
	gosub CheckWorkStatus
	
	;~ MsgBox % canRun
	if(!canRun) {
		TrayTip,, Stop Stop Stop, 5
		break  ; the whole script should halt here
	}
	runCount++
	GuiControl,, RunNum, % "Round: " runCount
}
changeStatusText("Script stopped.")
GuiControl, Enable, MasterButton

;~ runCount = 0
;~ gosub BigSwitchOn
;~ while(true) {
	;~ gosub CheckWorkStatus
	
	;~ ;MsgBox % canRun
	;~ if(!canRun) {
		;~ TrayTip,, Stop Stop Stop, 5
		;~ break  ; the whole script should halt here
	;~ }
	;~ runCount++
	;~ GuiControl,, RunNum, % "Round: " runCount
;~ }
;~ changeStatusText("Script stopped.")

;~ TrayTip,, Stop Stop Stop, 5


; use a timer to check if current work is done and if dispatcher is allowed to issue new work


;~ if(selStage = "雪原 03A-02 N") {
	;~ gosub Grind03A-02N
;~ } else if(selStage = "溶岩 04A-10 N") {
	;~ gosub Grind04A-10N
;~ }

;~ gosub Grind03A-02N

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

CheckWorkStatus:
; need improvement
; 1. if isRepeatTask is false and canRun is true, then it's a new work
; 2. if isRepeatTask is true and canRun is true, then it's a repeated work
; 3. whenever canRun is false, stop
if(canRun) {
	; work is done and big switch is on; we can dispatch new work
	; find the selected work at the moment
	if(selStage = "雪原 03A-02 N") {
		if(!isRepeatTask) {
			;~ MsgBox, New Task
			changeStatusText("Dispatch new task: " + selStage)
			gosub Grind03A-02N  ; start from home page
			isRepeatTask := true
		} else {
			gosub Continue03A-02N  ; start from stage selection page
			isRepeatTask := true
		}
	} else if(selStage = "溶岩 04A-10 N") {
		if(!isRepeatTask) {
			changeStatusText("Dispatch new task: " + selStage)
			gosub Grind04A-10N  ; start from home page
			isRepeatTask := true
		} else {
			gosub Continue04A-10N  ; start from stage selection page
			isRepeatTask := true
		}
	}
	
} else {
	; work is not done or is not ready to dispatch new work
	MsgBox, switch is off, cannot dispatch
}
return


BigSwitchOn:
canRun := true
isRepeatTask := false
GuiControl, Disable, MasterButton
GuiControl, Enable, StopButton
return

BigSwitchOff:
canRun := false
isRepeatTask := false
GuiControl, Disable, StopButton
changeStatusText("Stopping...")
;~ Reload
return

ForceClick:
if (useCoordDataOnly = true) {
	useCoordDataOnly := false
} else {
	useCoordDataOnly := true
}

Grind03A-02N:

;~ startFromHome()
findClick("returnHomeButton", 5)
Sleep 2000  ; wait for main page
; TODO: use image search to determine

rWait := NormalRand(0, stdWaitTime, 0)
Sleep rWait

; generate a random click wait time
rWait := NormalRand(0, stdWaitTime, 0)
findClick("mapCampaign")
;~ switchView(mapCampaign)
Sleep rWait

rWait := NormalRand(0, stdWaitTime, 0)
findClick("mapView_03A")
;~ switchView(mapView03A)
Sleep rWait

gosub Continue03A-02N
workDone := true
return

Grind04A-10N:

;~ startFromHome()
findClick("returnHomeButton", 5)
Sleep 2000  ; wait for main page
; TODO: use image search to determine
 
rWait := NormalRand(0, stdWaitTime, 0)
Sleep rWait

; generate a random click wait time
rWait := NormalRand(0, stdWaitTime, 0)
findClick("mapCampaign")
Sleep rWait

rWait := NormalRand(0, stdWaitTime, 0)
findClick("mapView_04A")
Sleep rWait

gosub Continue04A-10N

TrayTip,, Falldown End, 5
return


Continue03A-02N:
;~ Random, rWait, 1500.0, 4500.0
rWait := NormalRand(0, stdWaitTime, 0)

findClick("mapSel_03A02N")
Sleep rWait * 1000

gosub AutoBattleProcess

return


Continue04A-10N:
;~ Random, rWait, 1500.0, 4500.0
rWait := NormalRand(0, stdWaitTime, 0)

findClick("mapSel_04A10N")
Sleep rWait * 1000

gosub AutoBattleProcess

return



AutoBattleProcess:
findClick("orderReady")
findClick("affirmReady")
findClick("autoBattle")
findClick("resultBattleStats",,,true)
return




GuiClose:
ExitApp
