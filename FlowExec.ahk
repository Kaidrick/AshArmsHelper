#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include JSON.ahk
#Include MapLib.ahk


;
earlyTermination = false

; This file contains a few function to execute pre-defined battle flow provided in json files
executeFlow(flowName) {
	; find file by name, and then read the file. convert json to ahk object
	;~ MsgBox % flowName
	global WinSize
	
	GuiControl,, WinSize, % "Executing predefined battle flow..."
	
	numLines = 0
	idx = 0
	
	Loop, read, %flowName%
	{
		Loop, parse, A_LoopReadLine, %A_Tab%
		{
			if (trim(A_LoopReadLine) != "") {
				dt := StrSplit(A_LoopField, ",")
				action := dt[1]
				if(action != "INFO" && action != "DESC") {
					numLines++
				}
			}
		}
	}
	
	Loop, read, %flowName%
	{
		Loop, parse, A_LoopReadLine, %A_Tab%
		{
			if (trim(A_LoopReadLine) != "") {
				;~ if this line is a line that contains map info, then ignore
				dt := StrSplit(A_LoopField, ",")
				action := dt[1]
				args := dt[2]
				desc := dt[3]
				
				if(action != "INFO" && action != "DESC") {
					idx++
					;~ MsgBox, Field number %A_Index% is %A_LoopField%.
					GuiControl,, WinSize, % "Executing predefined battle flow..." idx "/" numLines
					
					perform(action, args, desc)
				}
			}
		}
	}
	
	GuiControl,, WinSize, % "Finished predefined battle flow"
	
	return
}


;~ Loop, read, test flow.txt
;~ {
    ;~ Loop, parse, A_LoopReadLine, %A_Tab%
    ;~ {
        ;~ ;~ MsgBox, Field number %A_Index% is %A_LoopField%.
		;~ dt := StrSplit(A_LoopField, ",")
		;~ action := dt[1]
		;~ args := dt[2]
		;~ desc := dt[3]
		
		;~ perform(action, args)
    ;~ }
;~ }


perform(action, args="", desc="") {
	;~ MsgBox, % action args desc
	global canRun
	global ClickPosIndicator
	GuiControl,, ClickPosIndicator, % "Command: " action ", " args "`nOperation: " desc
	
	checkForError()
	checkLoginOnBadAuth()
	
	if(!canRun) {
		return
	}
	
	switch action {
		case "SELECT":
			; select which one?
			battleView_Select(args)
		case "DESELECT":
			battleView_Deselect(args)
		case "MOVE":
			; move to which grid?
			battleView_Move(args)
		case "SWITCH":
			; click switch button
			battleView_Switch()
		case "SKILL":
			; assign which skill?
			battleView_Skill(args)
		case "BATTLE":
			; click start battle, battleView_ClearAssignment.png, Wait until clear button is gone
			battleView_StartTurn()
		case "WAIT":
			Sleep args
		case "CHECK":
			; search for image
		case "AUTO":
			; find and click auto?
			battleView_Auto()
		case "CONFIRM":
			; confirm skill not set but start turn
			battleView_Confirm()
	}
}


battleView_Select(index=1) {
	;~ GuiControl,, WinSize, % "Coord Click Mode"
	existImage("battleView_BattleStart.png",,,,,,0)  ; must see
	if(hasEarlyResult()) {
			return
		}
		
	switch index {
		case 1: coordClick(113, 638)
		case 2: coordClick(286, 638)
		case 3: coordClick(460, 638)
		case 4: coordClick(634, 638)
		case 5: coordClick(807, 638)
		case 6: coordClick(981, 638)
	}
}

battleView_Deselect(index) {
	notExistImage("battleView_BattleStart.png")
	if(hasEarlyResult()) {
			return
		}
		
	switch index {
		case 1: coordClick(113, 638)
		case 2: coordClick(286, 638)
		case 3: coordClick(460, 638)
		case 4: coordClick(634, 638)
		case 5: coordClick(807, 638)
		case 6: coordClick(981, 638)
		Default: coordClick(113, 638)
	}
	Sleep 500
}

battleView_Move(index) {
	notExistImage("battleView_BattleStart.png")
	if(hasEarlyResult()) {
			return
		}
	switch index {
		case 1: coordClick(183, 411)
		case 2: coordClick(313, 411)
		case 3: coordClick(446, 411)
		case 4: coordClick(578, 411)
		case 5: coordClick(702, 411)
		case 6: coordClick(833, 411)
		case 7: coordClick(971, 411)
		case 8: coordClick(1096, 411)
	}
	Sleep 500  ; should be random
}

battleView_Switch() {
	; find and click the image?
	notExistImage("battleView_BattleStart.png")
	if(hasEarlyResult()) {
			return
		}
	coordClick(124, 508)
}

battleView_Skill(index) {
	notExistImage("battleView_BattleStart.png")
	if(hasEarlyResult()) {
			return
		}
	switch index {
		case 1: coordClick(336, 518)
		case 2: coordClick(575, 518)
		case 3: coordClick(810, 518)
	}
}

battleView_StartTurn() {
	; check clear button is gone and then click start turn
	notExistImage("battleView_ClearAssignment.png")
	if(hasEarlyResult()) {
			return
		}
	coordClick(1162, 609)
}

battleView_Confirm() {
	existImage("battleView_ConfirmTurn.png",,,,,,0)  ; must see
	if(hasEarlyResult()) {
			return
		}
	coordClick(1052, 343)
}



; need a function to check if boss has died or if this stage has been finished
; if stage has been finished, stop the flow and go to the end directly


battleView_CheckWin() {
	; check win in every loop
	; if result image is found then switch early termination
	
	global earlyTermination
	
	; click battle start -> check auto -> withdraow disappear once -> show up once -> disappear once(enemy turn) -> show up again -> battle start button show up
	notExistImage("battleViewWithdraw.png",,,,,10)
	existImage("battleViewWithdraw.png",,,,,0)
	
	res := notExistImage("resultBattleStats.png",,,,,20)
	
	if (res) { ; if battle stat does not show up in limited time, maybe enemy still has turns
		existImage("battleViewWithdraw.png")  ; end of animation?
		existImage("battleView_BattleStart.png")
		MsgBox, animation done
	} else { ; if battle stat does show up here
		earlyTermination = true  ; and skip to deal with result
		MsgBox, animation done
	}
}


battleView_Auto() {
	existImage("battleViewWithdraw.png",,,,,,0)  ; must see
	if(hasEarlyResult()) {
		return
	}
	coordClick(1052, 343)
}




coordClick(x, y) {
	global asaGameHwnd
	global WinSize
	global stdErrorRange
	global yBorder
	
	; generate random click position offset
	xRand := NormalRand(-stdErrorRange, stdErrorRange, 0)
	yRand := NormalRand(-stdErrorRange, stdErrorRange, 0)
	
	xClick := x + xRand
	yClick := y + yRand + yBorder
	
	; random sleep
	;~ tPause := NormalRand(0, stdWaitTime, 0)

	;~ GuiControl,, clickPosIndicator, x = %x%`, y = %y%`, Action -> %act%, Click Time Offset -> %tPause%s
	
	if(hasEarlyResult()) {
		return
	}
	
	ControlClick, x%xClick% y%yClick%, ahk_id %asaGameHwnd%,, left  ; do click
	
	return
}


; test read json file
; Load image data from json file and then merge into a singe object
;~ FileRead, battleFlowJson, test flow.json

;~ battleFlowData := JSON.Load(battleFlowJson)

;~ MsgBox % battleFlowJson

;~ orderStr := ""

;~ for _,v in battleFlowData
	;~ MsgBox % v["action"]

;~ MsgBox % orderStr
;~ allData := {}
;~ for k, v in generalData
	;~ ObjRawSet(allData, k, v)

;~ for k, v in theaterData
	;~ ObjRawSet(allData, k, v)

;~ for k, v in nodeData
	;~ ObjRawSet(allData, k, v)