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

; User options
longSessionBreak := false


Gui, Add, Text, x5 y5 h14 w150 vWorkStatusIndicator, %workStatus%
Gui, Add, Text, x5 y25 h14 w350 vWinSize, %winSize%
Gui, Add, Text, x5 y45 h48 w450 vClickPosIndicator, %clickPos%
Gui, Add, Text, x400 y5 h14 w100 vRunNum, %statsRun%

Gui, Show, w500 h500, % "アッシュアームズ自動管理システム"

Gui, Add, Button, x250 y125 h50 w50 vMasterButton gMasterRoutine, % "Start"
Gui, Add, Button, x300 y125 h50 w50 vStopButton gBigSwitchOff, % "Stop"
Gui, Add, Button, x445 y145 h50 w50 gTapTap, % "Test Function"

Gui, Add, Text, x5 y200 h170 w450 vStageInstruction, % "Select a stage from the droplist"

; map selection dropdown list
;~ Gui, Add, DropDownList, x250 y100 vStageChoice gOnStageSelect w200 h50 Choose2 R5, 遺跡 01-06 (Manual)|雪原 03A-02 N|雪原 03A-02 N (Manual)|雪原 03A-06 N (ランカ/Pe-2/Ju87/SBD)|雪原 03A-08 N (Manual)|雪原 03A-10 N (Manual)|溶岩 04A-10 N|溶岩 04A-10 N (Manual)|森丘 05A-02 N (Manual)|——————————————————|雪原奥地 03B-04 N (SDB碎片)|雪原奥地 03B-06 N (兰开碎片/矿)|溶岩奥地 04B-08 N (KV-1碎片)


; add as per file
path := A_ScriptDir "\data\flow\*.txt"
files =
Loop %path% {
	stdName := StrSplit(A_LoopFileName, ".")[1]
	files = %files% | %stdName%
}

Gui, Add, DropDownList, x250 y100 vStageChoiceNew gOnStageSelectNew w200 h50 Choose1 R5, %files%

Gui, Add, CheckBox, x5 y145 h20 w150 gForceClick, % "Silent Mode (Coord and Time only)"
Gui, Add, Checkbox, x5 y165 h20 w200 gLongSession, % "Sleep Session (Allow long break)"

GuiControl,, ClickPosIndicator, % "Ready"
GuiControl, Disable, StopButton


; Initialize
runCount = 0

selStage := "雪原 03A-02 N"
selStageNew := ""
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
updatePlayerData := {x: 0, y: 0, path: "Error_UpdatePlayerData.PNG", size: {w: 196, h: 37}, offset: {x: 167, y: 164}, act: "Deal UpdatePlayerData error"}
networkError := {x: 0, y: 0, path: "Error_NetWork.PNG", size: {w: 208, h: 36}, offset: {x: 167, y: 164}, act: "Deal Network error"}
connectionError := {x: 0, y: 0, path: "Error_Connection.png", size: {w: 247, h: 38}, offset: {x: 258, y: 165}, act: "Deal Connection error"}
battleCmdError := {x: 0, y: 0, path: "Error_BattleCmd.png", size: {w: 113, h: 30}, offset: {x: 208, y: 165}, act: "Deal Battle Cmd Error"}

errorConfirmButton := {x: 0, y: 0, path: "Error_ConfirmButton.png", size: {w: 203, h: 75}, offset: {x: 0, y: 0}, act: "General Error Handling"}

return



OnStageSelect:
Gui, Submit, nohide
selStage := StageChoice

TrayTip,, Grinding Stage: %selStage%, 5
;~ MsgBox, %selStage%
return

OnStageSelectNew:
Gui, Submit, nohide
selStageNew := StageChoiceNew

TrayTip,, Grinding Stage: %selStageNew%, 5


selStageName := trim(selStageNew)
path := A_ScriptDir "\data\flow\" selStageName ".txt"

FileReadLine, descInfo, %path%, 2
descInfo := StrSplit(descInfo, ",")
pos1 := descInfo[2]
pos2 := descInfo[3]
pos3 := descInfo[4]
pos4 := descInfo[5]
pos5 := descInfo[6]
pos6 := descInfo[7]
pos7 := descInfo[8]
pos8 := descInfo[9]

drop1 := descInfo[10]
drop2 := descInfo[11]
drop3 := descInfo[12]
drop4 := descInfo[13]
drop5 := descInfo[14]
drop6 := descInfo[15]

GuiControl,, StageInstruction, Team Composition:`nA: [1]%pos1%`t [2]%pos2%`t [3]%pos3%`t [4]%pos4%`nG: [1]%pos5%`t [2]%pos6%`t [3]%pos7%`t [4]%pos8%`n----------------`nDrops: `n%drop1% [25`%]`n%drop2% [10`%]`n%drop3% [6`%]`n%drop4% [2.5`%]`n----------------`nRare Drops:`n%drop5% [10`%]`n%drop6% [1`%]

return



; Subroutines
TapTap:
canRun := true
handleGeneralError()
;~ quickTapAnywhere()
;~ canRun = true
;~ checkLoginOnBadAuth()
;~ notExistImage("battleView_BattleStart.png")
;~ MsgBox % what
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
	
	;~ read from selected flow file
	selStageName := trim(selStageNew)
	path := A_ScriptDir "\data\flow\" selStageName ".txt"
	
	FileReadLine, stageInfo, %path%, 1
	stageInfo := StrSplit(stageInfo, ",")
	theaterSel := stageInfo[2]
	mapNodeSel := stageInfo[3]
	mapDifficulty := stageInfo[4]
	
	mapTheaterKeyName := "mapView_" theaterSel
	mapNodeKeyName := "mapSel_" theaterSel mapNodeSel mapDifficulty
	
	if(!isRepeatTask) {
		;~ MsgBox, New Task
		changeStatusText("Dispatch new task: " + selStageName)
		gosub GrindStart  ; start from home page

		rWait := NormalRand(0, stdWaitTime, 0)

		findClick(mapTheaterKeyName)
		Sleep rWait
		
		findClick(mapNodeKeyName)
		Sleep 2000
		findClick("orderReady")
		Sleep 2000
		findClick("affirmReady")

		executeFlow(path)

		findClick("resultBattleStats",,,true)
		
		workDone := true
		
		isRepeatTask := true
	} else {
		;~ start from result page
		findClick("repeatStageFromBattleResult")
		Sleep 3000
		findClick("affirmReady")

		executeFlow(path)

		findClick("resultBattleStats",,,true)
		
		workDone := true
		isRepeatTask := true
	}
	
	;~ gosub GrindStart

	;~ rWait := NormalRand(0, stdWaitTime, 0)
	;~ MsgBox, find click map theater now
	;~ findClick(mapTheaterKeyName)
	;~ Sleep rWait
	
	;~ findClick(mapNodeKeyName)
	;~ Sleep 500
	;~ findClick("orderReady")
	;~ Sleep 500
	;~ findClick("affirmReady")

	;~ executeFlow(path)

	;~ findClick("resultBattleStats",,,true)
	
	;~ workDone := true
	



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
return

LongSession:
if (longSessionBreak) {
	longSessionBreak := false
} else {
	longSessionBreak := true
}
return



GrindStart:
findClick("returnHomeButton", 5)
Sleep 2000  ; wait for main page

; generate a random click wait time
rWait := NormalRand(0, stdWaitTime, 0)
findClick("mapCampaign")
Sleep rWait


; determine which theatre and which stage to go?
; search files with name


return



Grind03A-10N-Manual:
gosub GrindStart

rWait := NormalRand(0, stdWaitTime, 0)
findClick("mapView_03A")
Sleep rWait

gosub Continue03A-10N-Manual
workDone := true
return

Continue03A-10N-Manual:
findClick("mapSel_03A10N")
Sleep 500
findClick("orderReady")
Sleep 500
findClick("affirmReady")

path := A_ScriptDir "\data\flow\03A-10 N.txt"
executeFlow(path)

findClick("resultBattleStats",,,true)
return






Grind03A-08N-Manual:
gosub GrindStart

rWait := NormalRand(0, stdWaitTime, 0)
findClick("mapView_03A")
Sleep rWait

gosub Continue03A-08N-Manual
workDone := true
return

Continue03A-08N-Manual:
findClick("mapSel_03A08N")
Sleep 500
findClick("orderReady")
Sleep 500
findClick("affirmReady")

path := A_ScriptDir "\data\flow\03A-08 N.txt"
executeFlow(path)

findClick("resultBattleStats",,,true)
return




Grind01-06-Manual:
gosub GrindStart

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
gosub GrindStart

rWait := NormalRand(0, stdWaitTime, 0)
findClick("mapView_03A")
;~ switchView(mapView03A)
Sleep rWait

gosub Continue03A-02N
workDone := true
return



Grind03A-02N-Manual:
gosub GrindStart

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
gosub GrindStart

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
gosub GrindStart

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
gosub GrindStart

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


Grind04B-08N-Manual:
gosub GrindStart
rWait := NormalRand(0, stdWaitTime, 0)
findClick("mapView_04B")
Sleep rWait

gosub Continue04B-08N-Manual
workDone := true

return


Continue04B-08N-Manual:
Sleep 1000
findClick("mapSel_04B08N")
Sleep 1000
findClick("orderReady")
findClick("affirmReady")

path := A_ScriptDir "\data\flow\04B-08 N.txt"
executeFlow(path)

findClick("resultBattleStats",,,true)
return



Grind03B-04N-Manual:
gosub GrindStart
rWait := NormalRand(0, stdWaitTime, 0)
findClick("mapView_03B")
Sleep rWait

gosub Continue03B-04N-Manual
workDone := true

return

continue03B-04N-Manual:
Sleep 1000
findClick("mapSel_03B04N")
Sleep 1000
findClick("orderReady")
findClick("affirmReady")

path := A_ScriptDir "\data\flow\03B-04 N.txt"
executeFlow(path)

findClick("resultBattleStats",,,true)
return


Grind03B-06N-Manual:
gosub GrindStart
rWait := NormalRand(0, stdWaitTime, 0)
findClick("mapView_03B")
Sleep rWait

gosub Continue03B-06N-Manual
workDone := true

return

continue03B-06N-Manual:
Sleep 1000
findClick("mapSel_03B06N")
Sleep 1000
findClick("orderReady")
findClick("affirmReady")

path := A_ScriptDir "\data\flow\03B-06 N.txt"
executeFlow(path)

findClick("resultBattleStats",,,true)
return


Grind03A-06N-Manual:
gosub GrindStart
rWait := NormalRand(0, stdWaitTime, 0)
findClick("mapView_03A")
Sleep rWait

gosub Continue03A-06N-Manual
workDone := true

return

continue03A-06N-Manual:
Sleep 1000
findClick("mapSel_03A06N")
Sleep 1000
findClick("orderReady")
findClick("affirmReady")

path := A_ScriptDir "\data\flow\03A-06 N.txt"
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
