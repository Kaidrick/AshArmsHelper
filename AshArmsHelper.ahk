#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

CoordMode, Pixel, Window

#Include MapLib.ahk
#Include JSON.ahk

; To-do list
; 1. deals with invalid auth after long idle time
; 2. optional search region provided by json
; 3. add the ability to use battle flow provided by json


; standard wait time
stdWaitTime = 2.0
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
Gui, Add, DropDownList, x250 y100 vStageChoice gOnStageSelect w100 h50 Choose2 R5, 遺跡 01-02|雪原 03A-02 N|溶岩 04A-10 N

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
GuiControl, Disable, StageChoice
return

BigSwitchOff:
canRun := false
isRepeatTask := false
GuiControl, Disable, StopButton
GuiControl, Enable, StageChoice
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
