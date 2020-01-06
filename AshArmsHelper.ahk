#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

CoordMode, Pixel, Window
FileEncoding, UTF-8

#Include Lib\MapLib.ahk
#Include Lib\JSON.ahk
#Include Lib\FlowExec.ahk
#Include Lib\UnitOptionCheck.ahk
#Include Lib\DropStats.ahk

; To-do list
; 1. deals with invalid auth after long idle time (partially implemented)
; 2. add the ability to choose stage automatically (partially implemented)
;       * use horizontal click and drag to move the stage map
; 3. validate clicks; that is, check if click is successfual / UI is responsive for this click; if not, retry      
; 

LC_path := A_ScriptDir "\lang.ini"
FileReadLine, LC, %LC_path%, 1
textResFile := A_ScriptDir "\res\" LC ".json"
FileRead, resxJson, %textResFile%
resx := JSON.Load(resxJson)


eop_path := A_ScriptDir "\emulator window title.ini"
FileReadLine, emulatorWindowTitle, %eop_path%, 1

; standard wait time
stdWaitTime = 1.0
stdLoadTime = 8.0

; Emulator window title height -> yBorder
yBorder = 36  ; NemuPlayer

; Click error
stdErrorRange = 12.0  ; max distance from the click point to the base point in px

; Create GUI control panel
clickPos := resx["s_ClickPos"]
workStatus := resx["s_WorkStatus"]
winSize := resx["s_WinSize"]
statsRun := resx["s_StatsRun"]

winResolutionWidth := 1280
winResolutionHeight := 720

; Script states
startTime := A_Now

canRun := false
canRestart := false
isRepeatTask := false
useCoordDataOnly := false

skipSleep := false
alwaysSkipSleep := false ;~ to-do

earlyResult := false

; User options
longSessionBreak := false
runNonStop := false
logDrops := false
clickNoDelay := false

logFilePath := A_ScriptDir "\logs\"


Gui, Add, Text, x5 y5 h14 w135 vWorkStatusIndicator, %workStatus%
Gui, Add, Text, x5 y25 h14 w350 vWinSize, %winSize%
Gui, Add, Text, x5 y45 h48 w450 vClickPosIndicator, %clickPos%
Gui, Add, Text, x220 y5 h14 w100 vRunNum, %statsRun%

Gui, Show, w292 h378, % resx["title"] ; "ｱｯｼｭｱｰﾑｽﾞ周回ﾍﾙﾊﾟｰ"

Gui, Add, Button, x5 y130 h50 w50 vMasterButton gMasterRoutine, % resx["btn_Start"]
Gui, Add, Button, x55 y130 h50 w50 vStopButton gBigSwitchOff, % resx["btn_Stop"]
;~ Gui, Add, Button, x5 y180 h16 w100 gTapTap, % "Test"

Gui, Add, Text, x5 y200 h170 w450 vStageInstruction, % resx["info_SelectStage"]
; add as per file
path := A_ScriptDir "\data\flow\*.txt"
files =
Loop %path% {
	stdName := StrSplit(A_LoopFileName, ".")[1]
	files = %files% | %stdName%
}

Gui, Add, Text, x5 y90 h10 w450 vBr1, % "———————————————————————————————————————————————"

Gui, Add, DropDownList, x5 y105 vStageChoiceNew gOnStageSelectNew w280 h50 Choose1 R10, %files%

Gui, Add, CheckBox, x110 y130 h16 w95 vCB_Nonstop gNonStop, % resx["cb_NonStop"]

Gui, Add, CheckBox, x210 y130 h16 w95 vCB_LogDrops gLogDrops, % resx["cb_LogDrops"]

Gui, Add, CheckBox, x110 y147 h16 w95 vCB_NoDelay gNoDelay, % resx["cb_ClickNoDelay"]

;~ Gui, Add, CheckBox, x115 y130 h26 w150 vCB_ForceClick gForceClick, % "[WIP] Silent Mode (Coord and Time only)"
;~ GuiControl, Disable, CB_ForceClick

Gui, Add, Checkbox, x110 y164 h16 w200 gLongSession, % resx["cb_SleepSession"]

Gui, Add, Button, x150 y5 h15 w30 vWakeButton gWakeUpNow, % "▶▶"
GuiControl, Hide, WakeButton


GuiControl,, ClickPosIndicator, % resx["info_ClickPosReady"]
GuiControl, Disable, StopButton


; Initialize
runCount = 0
previousRunCount = 0  ;~ copy runCount on script restart

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
WinGet, asaGameHwnd, ID, %emulatorWindowTitle%

if (asaGameHwnd) {
	GuiControl,, WorkStatusIndicator, % resx["emulator_hwnd"] asaGameHwnd
	
	; get window resolution at start
	WinGetPos,,, winResolutionWidth, winResolutionHeight, ahk_id %asaGameHwnd%
	GuiControl,, WinSize, % resx["InitWindowSize"] winResolutionWidth "x" winResolutionHeight
} else {
	MsgBox, Unable to locate Ash Arms emulator window.`rPlease make sure the emulator is running properly.`rScript will now terminate.
	ExitApp
}


; Data


; TapTap
tapAnywhere := {x: 642, y: 73, act: "Quick Taps"}  ; need xy data for different games, supposedly?

; Errors
;~ refreshPlayerData := {x: 0, y: 0, path: "Error_RefreshPlayerData.PNG", size: {w: 195, h: 40}, offset: {x: 167, y: 164}, act: "Deal RefreshPlayerData error"}
;~ updatePlayerData := {x: 0, y: 0, path: "Error_UpdatePlayerData.PNG", size: {w: 196, h: 37}, offset: {x: 167, y: 164}, act: "Deal UpdatePlayerData error"}
;~ networkError := {x: 0, y: 0, path: "Error_NetWork.PNG", size: {w: 208, h: 36}, offset: {x: 167, y: 164}, act: "Deal Network error"}
;~ connectionError := {x: 0, y: 0, path: "Error_Connection.png", size: {w: 247, h: 38}, offset: {x: 258, y: 165}, act: "Deal Connection error"}
;~ battleCmdError := {x: 0, y: 0, path: "Error_BattleCmd.png", size: {w: 113, h: 30}, offset: {x: 208, y: 165}, act: "Deal Battle Cmd Error"}

errorConfirmButton := {x: 0, y: 0, path: "Error_ConfirmButton.png", size: {w: 203, h: 75}, offset: {x: 0, y: 0}, act: "General Error Handling"}

return


WakeUpNow:
skipSleep := true
GuiControl, Hide, WakeButton
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

strTeamComp := resx["desc_TeamComp"]
strDrops := resx["desc_Drops"]
strRareDrops := resx["desc_RareDrops"]

GuiControl,, StageInstruction, %strTeamComp%`nA: [1]%pos1%`t [2]%pos2%`t [3]%pos3%`t [4]%pos4%`nG: [1]%pos5%`t [2]%pos6%`t [3]%pos7%`t [4]%pos8%`n----------------`n%strDrops%`n%drop1% [25`%]`n%drop2% [10`%]`n%drop3% [6`%]`n%drop4% [2.5`%]`n----------------`n%strRareDrops%`n%drop5% [10`%]`n%drop6% [1`%]

return



; Subroutines
TapTap:
canRun := true

;~ pixelColorMatch(971.2, 523.2, 429213272)
;~ areaColorMatch(497.6, 523.2, 4293302272)
waitSelection()
	;~ 255.8 523.2
	;~ 497.6 523.2
	;~ 735.4 523.2
	;~ 974.2 523.2

; Normal 4280382317
; Green 4280250988

; 173.8, 586.2
; 345.7 586.2

;~ waitSelection()
;4281135593
; 4293302272




;~ simulateRandomBehavior()

;~ checkLoginOnBadAuth()
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
runCount = 0  ;~ reset runCount on start

if(previousRunCount != 0) {
	runCount := previousRunCount
	previousRunCount = 0
}

GuiControl,, RunNum, % resx["round"] runCount

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
	;~ runCount++
	;~ GuiControl,, RunNum, % "Round: " runCount
	
	; if user defines a number of stages to be run before the script stop
	if (limitRun > 0 && runCount >= limitRun) {
		canRun = false
	}
	
	
}
changeStatusText(resx["status_ScriptStop"])
GuiControl, Enable, MasterButton


if(canRestart) {
	; restart the script
	; reset status
	canRun := false
	canRestart := false
	isRepeatTask := false

	changeStatusText(resx["status_ScriptRestart"])
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
	FileReadLine, descInfo, %path%, 2
	stageInfo := StrSplit(stageInfo, ",")
	theaterSel := stageInfo[2]
	mapNodeSel := stageInfo[3]
	mapDifficulty := stageInfo[4]
	
	mapTheaterKeyName := "mapView_" theaterSel
	mapNodeKeyName := "mapSel_" theaterSel mapNodeSel mapDifficulty
	
	if(!isRepeatTask) {
		;~ MsgBox, New Task
		changeStatusText(resx["status_DispatchNew"] selStageName)
		gosub GrindStart  ; start from home page

		rWait := NormalRand(0, stdWaitTime, 0)

		findClick(mapTheaterKeyName)
		Sleep rWait * 1000
		
		findClick(mapNodeKeyName)
		Sleep 1000
		findClick("orderReady")
		
		;~ wait until ui loaded
		existImage("preStage_Consumption.png",,,,,,0)
		
		earlyResult := false
		disableAutoBattle()
		matchOptions(descInfo)  ;~ check for unit role option mismatch
		
		findClick("affirmReady")
		
		earlyResult := false
		
		;~ check if affirm ready still exists, if so keep clicking
		stuck := existImage("preStage_Consumption.png")
		while(stuck) {
			if(!canRun) {
				;~ MsgBox, cancelling
				break
			}
		
			changeStatusText(resx["status_EnsuringLoad"])
		
			handleGeneralError()  ; dealing with errors
			checkLoginOnBadAuth()  ; dealing with login problems
			
			stuck := existImage("preStage_Consumption.png")
			
			findClick("affirmReady", 1)  ;~ abort if not found for once
		}
		
		;~ button is pressed for sure, but network errors may occur
		;~ wait until battle button shows up
		changeStatusText(resx["status_Loading"])
		;~ if start button is not seen then keep handling errors here
		
		loaded := existImage("battleView_BattleStart.png")
		while(!loaded) {
			if(!canRun) {
				;~ MsgBox, cancelling
				break
			}
		
			handleGeneralError()  ; dealing with errors
			checkLoginOnBadAuth()  ; dealing with login problems
			
			loaded := existImage("battleView_BattleStart.png")
		}
		
		executeFlow(path)
		
		if(!logDrops) {
			;~ findClick("resultBattleStats",,,true)
			
			; if repeat button is not visible then keep clicking
			repeatButton := existImage("postStage_Repeat.png", 420, 610, 631, 700, 50, 1)
			while(!repeatButton) {
				if(!canRun) {
					;~ MsgBox, cancelling
					break
				}
				repeatButton := existImage("postStage_Repeat.png", 420, 610, 631, 700, 50, 1)
				quickTapAnywhere(1)
			}
			
		} else {
			;~ wait until resultBattleStats is found
			existImage("resultBattleStats.png",,,,,,0)  ; must see
		
			;~ click three times to go to item drops
			quickTapAnywhere(3)
			
			existImage("Result_Loot.png",,,,,,0)  ;~ check for got item title
			changeStatusText(resx["status_AnalyzeDrops"])
			Sleep 2000
			;~ check drops
			dollDrop := collectDollDropData()
			matsDrop := collectMatsDropData()
			
			logNum := runCount + 1
			strDrop := logNum "," dollDrop "," matsDrop "`n"

			logFileName := theaterSel mapNodeSel " " mapDifficulty " " startTime ".csv"
			file := FileOpen(logFilePath logFileName,"a")
			file.write(strDrop)
			file.close()
			
			;~ click until repeat button shows up
			quickTapAnywhere(10)
		}
		
		
		workDone := true
		isRepeatTask := true
		
		runCount++
		GuiControl,, RunNum, % resx["round"] runCount
	} else {
		;~ start from result page
		findClick("repeatStageFromBattleResult")  
		
		;~ check errors here? --> no need; no connection here only loading

		;~ Sleep 3000
		findClick("affirmReady")
		
		earlyResult := false
		
		;~ check if affirm ready still exists, if so keep clicking
		stuck := existImage("preStage_Consumption.png")
		
		while(stuck) {
			if(!canRun) {
				;~ MsgBox, cancelling
				break
			}
		
			changeStatusText(resx["status_EnsuringLoad"])
		
			handleGeneralError()  ; dealing with errors
			checkLoginOnBadAuth()  ; dealing with login problems
			
			stuck := existImage("preStage_Consumption.png")
			
			findClick("affirmReady", 1)  ;~ abort if not found for once
		}
		
		;~ button is pressed for sure, but network errors may occur
		;~ wait until battle button shows up
		changeStatusText(resx["status_Loading"])
		;~ if start button is not seen then keep handling errors here
		
		loaded := existImage("battleView_BattleStart.png")
		while(!loaded) {
			if(!canRun) {
				;~ MsgBox, cancelling
				break
			}
		
			handleGeneralError()  ; dealing with errors
			checkLoginOnBadAuth()  ; dealing with login problems
			
			loaded := existImage("battleView_BattleStart.png")
		}
		
		;~ execute battle flow if no error
		executeFlow(path)
		
		if(!logDrops) {
			;~ findClick("resultBattleStats",,,true)
			
			repeatButton := existImage("postStage_Repeat.png", 420, 610, 631, 700, 50, 1)
			while(!repeatButton) {
				if(!canRun) {
					;~ MsgBox, cancelling
					break
				}
				repeatButton := existImage("postStage_Repeat.png", 420, 610, 631, 700, 50, 1)
				quickTapAnywhere(1)
			}
		} else {
			;~ wait until resultBattleStats is found
			existImage("resultBattleStats.png",,,,,,0)  ; must see
		
			;~ click three times to go to item drops
			quickTapAnywhere(3)
			
			existImage("Result_Loot.png",,,,,,0)  ;~ check for got item title
			changeStatusText(resx["status_AnalyzeDrops"])
			Sleep 2000
			;~ check drops
			dollDrop := collectDollDropData()
			matsDrop := collectMatsDropData()

			logNum := runCount + 1
			strDrop := logNum "," dollDrop "," matsDrop "`n"

			logFileName := theaterSel mapNodeSel " " mapDifficulty " " startTime ".csv"
			file := FileOpen(logFilePath logFileName,"a")
			file.write(strDrop)
			file.close()
			
			;~ click until repeat button shows up
			quickTapAnywhere(10)
		}
		
		workDone := true
		isRepeatTask := true
		
		runCount++
		GuiControl,, RunNum, % resx["round"] runCount
	}

} else {
	; work is not done or script is not ready to dispatch new work
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
	global resx
	
	global canRun
	global isRepeatTask
	global MasterButton
	global StopButton
	global StageChoiceNew
	
	if (StageChoiceNew = "") {
		MsgBox % resx["msgbox_SelectStageNotice"]
		return
	}
	
	canRun := true
	isRepeatTask := false
	GuiControl, Disable, MasterButton
	GuiControl, Enable, StopButton
	GuiControl, Disable, StageChoiceNew
	
	startTime := A_Now

	return
}

BigSwitchOff() {
	global resx
	
	global canRun
	global isRepeatTask
	global StopButton
	global StageChoice
	global earlyResult
	
	canRun := false
	isRepeatTask := false
	earlyResult := false
	GuiControl, Disable, StopButton
	GuiControl, Enable, StageChoiceNew
	GuiControl, Hide, WakeButton
	changeStatusText(resx["status_Stopping"])
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

NonStop:
if (runNonStop = true) {
	runNonStop := false
} else {
	runNonStop := true
}
return

LogDrops:
if (logDrops = true) {
	logDrops := false
} else {
	logDrops := true
}
return

NoDelay:
if (clickNoDelay = true) {
	clickNoDelay := false
} else {
	clickNoDelay := true
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

;~ network errors may occur here

Sleep 2000  ; wait for main page

; todo
; check exist
; click
; check next exist

; generate a random click wait time
rWait := NormalRand(0, stdWaitTime, 0)
findClick("mapCampaign")
Sleep rWait * 1000

return





AutoBattleProcess:
findClick("orderReady")
findClick("affirmReady")
findClick("autoBattle")
findClick("resultBattleStats",,,true)
return




GuiClose:
ExitApp
