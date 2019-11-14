﻿#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

CoordMode, Pixel, Window

#Include MapLib.ahk
#Include JSON.ahk
#Include FlowExec.ahk

; To-do list
; 1. deals with invalid auth after long idle time
; 2. add the ability to choose stage automatically:
;       * use horizontal click and drag to move the stage map
;       * use image search to determine current position?
;       * use image search to click on target stage
; 3. BattleCmd error? try to reproduce?


; standard wait time
stdWaitTime = 1.0
stdLoadTime = 8.0

; Emulator title height -> yBorder
yBorder = 36  ; NemuPlayer

; Click error
stdErrorRange = 12.0  ; max distance from the click point to the base point in px

; Create GUI control panel
clickPos := "Click Position"
workStatus := "Starting"
winSize := "Target Window Size"
statsRun := "Stats"

winResolutionWidth := 1280
winResolutionHeight := 720

; Script states
canRun := false
canRestart := false
isRepeatTask := false
useCoordDataOnly := false


Gui, Add, Text, x5 y5 h14 w100 vWorkStatusIndicator, %workStatus%
Gui, Add, Text, x5 y25 h14 w350 vWinSize, %winSize%
Gui, Add, Text, x5 y45 h48 w450 vClickPosIndicator, %clickPos%
Gui, Add, Text, x400 y5 h14 w100 vRunNum, %statsRun%

Gui, Show, w500 h200, % "アッシュアームズ自動管理システム"

Gui, Add, Button, x250 y125 h50 w50 vMasterButton gMasterRoutine, % "Start"
Gui, Add, Button, x300 y125 h50 w50 vStopButton gBigSwitchOff, % "Stop"
Gui, Add, Button, x445 y145 h50 w50 gTapTap, % "Test Function"

; map selection dropdown list
Gui, Add, DropDownList, x250 y100 vStageChoice gOnStageSelect w100 h50 Choose2 R5, 遺跡 01-06 (Manual)|雪原 03A-02 N|雪原 03A-02 N (Manual)|溶岩 04A-10 N|溶岩 04A-10 N (Manual)|森丘 05A-02 N (Manual)


; add as per file
path := A_ScriptDir "\data\flow\*.txt"
files =
Loop %path% {
	files = %files% | %A_LoopFileName%
}

Gui, Add, DropDownList, x350 y100 vStageChoiceNew w100 h50 Choose1 R5, %files%

Gui, Add, CheckBox, x5 y145 h20 w150 gForceClick, % "Silent Mode (Coord and Time only)"

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

; user defined number of runs before stop
limitRuns = 0


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


; TapTap
tapAnywhere := {x: 642, y: 73, act: "Quick Taps"}  ; need xy data for different games, supposedly?

; Errors
refreshPlayerData := {x: 0, y: 0, path: "Error_RefreshPlayerData.PNG", size: {w: 195, h: 40}, offset: {x: 167, y: 164}, act: "Deal RefreshPlayerData error"}
networkError := {x: 0, y: 0, path: "Error_NetWork.PNG", size: {w: 208, h: 36}, offset: {x: 167, y: 164}, act: "Deal Network error"}
connectionError := {x: 0, y: 0, path: "Error_Connection.png", size: {w: 247, h: 38}, offset: {x: 258, y: 165}, act: "Deal Connection error"}
return



OnStageSelect:
Gui, Submit, nohide
selStage := StageChoice

TrayTip,, Grinding Stage: %selStage%, 5
;~ MsgBox, %selStage%
return



; Subroutines
TapTap:
canRun = true
simulateRandomBehavior()
;~ checkLoginOnBadAuth()

;~ MsgBox % hasEarlyResult()
;~ checkLoginOnBadAuth()

;~ res := notExistImage("battleView_ClearAssignment.png",,,,,3)

;~ res := ExistImage("battleView_ClearAssignment.png",,,,,3)
;~ MsgBox % "notExistImage" res

;~ notExistImage("battleView_ClearAssignment.png")
;~ battleView_StartTurn()

return


MasterRoutine:
runCount = 0
GuiControl,, RunNum, % "Round: " runCount

; run the process
BigSwitchOn()
while(true) {
	gosub CheckWorkStatus
	
	;~ MsgBox % canRun
	if(!canRun) {
		TrayTip,, Script has been stopped
		break  ; the whole script should halt here
		; check if canStart?
	}
	runCount++
	GuiControl,, RunNum, % "Round: " runCount
	
	; if user defines a number of stages to be run before the script stop
	if (limitRun > 0 && runCount >= limitRun) {
		canRun = false
	}
	
	
}
changeStatusText("Script stopped.")
GuiControl, Enable, MasterButton


if(canRestart) {
	; restart the script
	; reset status
	canRun := false
	canRestart := false
	isRepeatTask := false

	changeStatusText("Script restarting")
	gosub MasterRoutine
}
return


CheckWorkStatus:
; need improvement ------------------------------------------------------------> need LOTS of refractoring
; 1. if isRepeatTask is false and canRun is true, then it's a new work
; 2. if isRepeatTask is true and canRun is true, then it's a repeated work
; 3. whenever canRun is false, stop
if(canRun) {
	; work is done and big switch is on; we can dispatch new work
	; find the selected work at the moment
	if(selStage = "遺跡 01-06 (Manual)") {
		if(!isRepeatTask) {
			;~ MsgBox, New Task
			changeStatusText("Dispatch new task: " + selStage)
			gosub Grind01-06-Manual  ; start from home page
			isRepeatTask := true
		} else {
			gosub Continue01-06-Manual  ; start from stage selection page
			isRepeatTask := true
		}
	} else if(selStage = "雪原 03A-02 N") {
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
	} else if(selStage = "雪原 03A-02 N (Manual)") {
		if(!isRepeatTask) {
			changeStatusText("Dispatch new task: " + selStage)
			gosub Grind03A-02N-Manual  ; start from home page
			isRepeatTask := true
		} else {
			gosub Continue03A-02N-Manual  ; start from stage selection page
			isRepeatTask := true
		}
	} else if(selStage = "溶岩 04A-10 N (Manual)") {
		if(!isRepeatTask) {
			changeStatusText("Dispatch new task: " + selStage)
			gosub Grind04A-10N-Manual  ; start from home page
			isRepeatTask := true
		} else {
			gosub Continue04A-10N-Manual  ; start from stage selection page
			isRepeatTask := true
		}
	} else if(selStage = "森丘 05A-02 N (Manual)") {
		if(!isRepeatTask) {
			changeStatusText("Dispatch new task: " + selStage)
			gosub Grind05A-02N-Manual  ; start from home page
			isRepeatTask := true
		} else {
			gosub Continue05A-02N-Manual  ; start from stage selection page
			isRepeatTask := true
		}
	}

} else {
	; work is not done or is not ready to dispatch new work
	;~ MsgBox, switch is off, cannot dispatch
}
return

BigSwitchOn:
BigSwitchOn()
return

BigSwitchOff:
BigSwitchOff()
return


BigSwitchOn() {
	global canRun
	global isRepeatTask
	global MasterButton
	global StopButton
	global StageChoice
	
	canRun := true
	isRepeatTask := false
	GuiControl, Disable, MasterButton
	GuiControl, Enable, StopButton
	GuiControl, Disable, StageChoice
	return
}

BigSwitchOff() {
	global canRun
	global isRepeatTask
	global StopButton
	global StageChoice
	
	canRun := false
	isRepeatTask := false
	GuiControl, Disable, StopButton
	GuiControl, Enable, StageChoice
	changeStatusText("Stopping...")
	;~ Reload
	return
}

ForceClick:
if (useCoordDataOnly = true) {
	useCoordDataOnly := false
} else {
	useCoordDataOnly := true
}


Grind01-06-Manual:
findClick("returnHomeButton", 5)
Sleep 2000  ; wait for main page

rWait := NormalRand(0, stdWaitTime, 0)
Sleep rWait

; generate a random click wait time
rWait := NormalRand(0, stdWaitTime, 0)
findClick("mapCampaign")
Sleep rWait

rWait := NormalRand(0, stdWaitTime, 0)
findClick("mapView_01")
Sleep rWait

gosub Continue01-06-Manual
workDone := true
return

Continue01-06-Manual:
findClick("mapSel_0106")
Sleep 500
findClick("orderReady")
Sleep 500
findClick("affirmReady")

path := A_ScriptDir "\data\flow\01-06.txt"
executeFlow(path)

findClick("resultBattleStats",,,true)
return



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



Grind03A-02N-Manual:
findClick("returnHomeButton", 5)
findClick("mapCampaign")
findClick("mapView_03A")
gosub Continue03A-02N-Manual
workDone := true
return


Continue03A-02N-Manual:
Sleep 1000
findClick("mapSel_03A02N")
Sleep 1000
findClick("orderReady")
findClick("affirmReady")

path := A_ScriptDir "\data\flow\03A-02 N.txt"
executeFlow(path)

findClick("resultBattleStats",,,true)
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


Grind04A-10N-Manual:
rWait := NormalRand(0, stdWaitTime, 0)
findClick("returnHomeButton", 5)
Sleep rWait

rWait := NormalRand(0, stdWaitTime, 0)
findClick("mapCampaign")
Sleep rWait

rWait := NormalRand(0, stdWaitTime, 0)
findClick("mapView_04A")
Sleep rWait

gosub Continue04A-10N-Manual
workDone := true
return


Continue04A-10N-Manual:
Sleep 1000
findClick("mapSel_04A10N")
Sleep 1000
findClick("orderReady")
findClick("affirmReady")

path := A_ScriptDir "\data\flow\04A-10 N.txt"
executeFlow(path)

findClick("resultBattleStats",,,true)
return



Grind05A-02N-Manual:
rWait := NormalRand(0, stdWaitTime, 0)
findClick("returnHomeButton", 5)
Sleep rWait

rWait := NormalRand(0, stdWaitTime, 0)
findClick("mapCampaign")
Sleep rWait

rWait := NormalRand(0, stdWaitTime, 0)
findClick("mapView_05A")
Sleep rWait

gosub Continue05A-02N-Manual
workDone := true
return


Continue05A-02N-Manual:
Sleep 1000
findClick("mapSel_05A02N")
Sleep 1000
findClick("orderReady")
findClick("affirmReady")

path := A_ScriptDir "\data\flow\05A-02 N.txt"
executeFlow(path)

findClick("resultBattleStats",,,true)
return



AutoBattleProcess:
findClick("orderReady")
findClick("affirmReady")
findClick("autoBattle")
findClick("resultBattleStats",,,true)
return




GuiClose:
ExitApp
