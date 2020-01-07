#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include Lib\JSON.ahk
#Include Lib\MapLib.ahk


;
earlyTermination = false

selectFocus := false

; This file contains a few function to execute pre-defined battle flow provided in json files
executeFlow(flowName) {
	global resx
	
	; find file by name, and then read the file. convert json to ahk object
	;~ MsgBox % flowName
	global WinSize
	global clickNoDelay
	global earlyResult
	
	GuiControl,, WinSize, % resx["status_FlowExecStart"]
	
	numLines = 0
	idx = 0
	
	earlyResult := false
	
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
					GuiControl,, WinSize, % resx["status_FlowExecutingAt"] idx "/" numLines
					
					perform(action, args, desc)
				}
			}
		}
	}
	
	GuiControl,, WinSize, % resx["status_FlowExecEnd"]
	
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
	global resx
	
	;~ MsgBox, % action args desc
	global canRun
	global ClickPosIndicator
	global clickNoDelay
	global stdWaitTime
	
	if(hasEarlyResult()) {
		return
	}
	
	GuiControl,, ClickPosIndicator, % resx["pos_FlowCmd"] action ", " args "`n" resx["pos_FlowOps"] desc
	
	checkForError()
	checkLoginOnBadAuth()
	
	if(!canRun) {
		return
	}
	
	if(!clickNoDelay) {
		; random sleep
		tPause := NormalRand(0, stdWaitTime, 0)
		Sleep tPause * 1000
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
			battleView_Wait(args)
		case "CHECK":
			; search for image
		case "AUTO":
			; find and click auto?
			battleView_Auto()
		case "CONFIRM":
			; confirm skill not set but start turn
			battleView_Confirm()
		case "SKIP":
			; skill this turn
			battleView_SkipTurn()
	}
}


battleView_Wait(args) {
	if(hasEarlyResult()) {
		return
	}
	Sleep args
}


battleView_Select(index=1) {
	global canRun
	global selectFocus
	
	;~ while battle start button is not seen, check for errors
	hasTurn := existImage("battleView_BattleStart.png",1114,542,1191,622,,true)
	while(!hasTurn) {
		if(!canRun) {
			;~ MsgBox, cancelling
			return
		}
	
		if(hasEarlyResult()) {
			return
		}
	
		handleGeneralError()  ; dealing with errors
		checkLoginOnBadAuth()  ; dealing with login problems
		
		hasTurn := existImage("battleView_BattleStart.png",1114,542,1191,622,,true)
	}
	
	
	;~ TODO: if enemy turn is shown, postpone early result search until next turn
	
	;~ GuiControl,, WinSize, % "Coord Click Mode"
	existImage("battleView_BattleStart.png",1114,542,1191,622,0,0,true)  ; must see
		
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
	global selectFocus
	
	;~ Sleep 200
	
	;~ notExistImage("battleView_BattleStart.png",1114,542,1191,622,20,1)
	;~ ; existImage("battleView_ClearAssignment.png",171,477,1027,565,10,0)  ; must see clear button
		
	;~ switch index {
		;~ case 1: coordClick(113, 638)
		;~ case 2: coordClick(286, 638)
		;~ case 3: coordClick(460, 638)
		;~ case 4: coordClick(634, 638)
		;~ case 5: coordClick(807, 638)
		;~ case 6: coordClick(981, 638)
		;~ Default: coordClick(113, 638)
	;~ }
	
	;~ if battle start button is not visible, deselect again until it is visible
	battleStartButton := existImage("battleView_BattleStart.png",1114,542,1191,622,0,1)
	while(!battleStartButton) {
		;~ switch index {
			;~ case 1: coordClick(113, 638)
			;~ case 2: coordClick(286, 638)
			;~ case 3: coordClick(460, 638)
			;~ case 4: coordClick(634, 638)
			;~ case 5: coordClick(807, 638)
			;~ case 6: coordClick(981, 638)
			;~ Default: coordClick(113, 638)
		;~ }
		coordClick(1206, 203)
		;~ quickTapAnywhere(1)
		Sleep 100
		battleStartButton := existImage("battleView_BattleStart.png",1114,542,1191,622,0,1)
	}
	
	selectFocus := false
	; Sleep 500
}

battleView_Move(index) {
	global selectFocus
	
	waitSelection()
	
	;~ if(!selectFocus) {  ;~ if no select focus
		;~ pixelColorMatch(76, 481.2, 4281135593) ; the color of the switch stance button upper left cornor rotate thingy
		;~ ; existImage("battleView_StanceSwitchIcon.png",61,472,91,502,0,0)  ; wait for and confirm focus
		;~ selectFocus := true  ; confirm select focus
	;~ }
	
	; existImage("battleView_ClearAssignment.png",171,477,1027,565,10,0)  ; must see clear button

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
	; Sleep 500  ; should be random
}

battleView_Switch() {
	global selectFocus
	
	waitSelection()
	Sleep 100
	
	;~ image search to confirm switch? TODO
	
	; find and click the image?
	; notExistImage("battleView_BattleStart.png",1114,542,1191,622,20,1)
	;~ if(!selectFocus) {  ;~ if no select focus
		;~ pixelColorMatch(76, 481.2, 4281135593) ; the color of the switch stance button upper left cornor rotate thingy
		;~ ; existImage("battleView_StanceSwitchIcon.png",61,472,91,502,0,0)  ; wait for and confirm focus
		;~ selectFocus := true  ; confirm select focus
	;~ }
	
	coordClick(124, 508)
}

battleView_Skill(index) {
	global selectFocus
	
	waitSelection()
	Sleep 50
	
	;~ if(!selectFocus) {  ;~ if no select focus
		;~ pixelColorMatch(76, 481.2, 4281135593) ; the color of the switch stance button upper left cornor rotate thingy
		;~ ; existImage("battleView_StanceSwitchIcon.png",61,472,91,502,0,0)  ; wait for and confirm focus
		;~ selectFocus := true  ; confirm select focus
	;~ }
	
	switch index {
		case 1: coordClick(336, 518)
		case 2: coordClick(575, 518)
		case 3: coordClick(810, 518)
	}
}

battleView_StartTurn() {
	
	; check clear button is gone and then click start turn
	; notExistImage("battleView_ClearAssignment.png")
	existImage("battleView_BattleStart.png",1114,542,1191,622,10,0)  ; must see

	coordClick(1162, 609)
}

battleView_Confirm() {
	
	existImage("battleView_ConfirmTurn.png",,,,,,0)  ; must see

	coordClick(1052, 343)
}

battleView_SkipTurn() {
	
	;~ skill this turn without doing anything
	;~ if start turn image exists, click on it
	existImage("battleView_BattleStart.png",,,,,,0)

	coordClick(1162, 609)
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
	if(hasEarlyResult()) {
		return
	}
	
	existImage("battleViewWithdraw.png",1114,542,1191,622,,0)  ; must see
	if(hasEarlyResult()) {
		return
	}
	coordClick(1052, 343)
}



waitSelection() {
	global selectFocus
	
	if(selectFocus) {  ;~ if can confirm selectFocus, return immediately
		return
	}
	
	while(true) {
		if(checkUnitSelection()) {  ;~ 0 skill set
			break
		}
	;~ 255.8 523.2
	;~ 497.6 523.2
	;~ 735.4 523.2
	;~ 974.2 523.2
	
		;~ MsgBox, not selected!
	}
	selectFocus := true
	;~ MsgBox, Selected!
	return
}



coordClick(x, y) {
	global asaGameHwnd
	global WinSize
	global stdErrorRange
	global yBorder
	global clickNoDelay
	
	if(hasEarlyResult()) {
		return
	}
	
	; generate random click position offset
	xRand := NormalRand(-stdErrorRange, stdErrorRange, 0)
	yRand := NormalRand(-stdErrorRange, stdErrorRange, 0)
	
	xClick := x + xRand
	yClick := y + yRand + yBorder
	
	; random sleep
	if(!clickNoDelay) {
		tPause := NormalRand(0, stdWaitTime, 0)
		Sleep tPause * 1000
	}
	
	;~ GuiControl,, clickPosIndicator, x = %x%`, y = %y%`, Action -> %act%, Click Time Offset -> %tPause%s
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