#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; import Gdip libs for image search
#Include Lib\Gdip_All.ahk
#Include Lib\Gdip_ImageSearch.ahk
#Include Lib\HumanBehaviors.ahk
#Include Lib\FlowExec.ahk

#Include AshArmsHelper.ahk

; Functions
p := Gdip_Startup()

findClick(viewObjName, abortCount=1000, waitInterval=200, canSimulateHumanBehavior=false) {
	global resx
	
	global asaGameHwnd
	global ClickPosIndicator
	global stdWaitTime
	global stdErrorRange
	global WinSize 
	global refreshPlayerData
	global canRun
	global allData
	global clickNoDelay
	
	global yBorder
	
	viewObj := allData[viewObjName]
	
	imgPath := A_ScriptDir "\data\img\" viewObj["path"]
	
	retryCount = 0
	while(true) {
		if(!canRun) {
			;~ MsgBox, cancelling
			return
		}
		
		handleGeneralError()  ; dealing with errors
		checkLoginOnBadAuth()  ; dealing with login problems
		
		pBitmapHayStack := Gdip_BitmapFromHWND(asaGameHwnd)

		pBitmapNeedle := Gdip_CreateBitmapFromFile(imgPath)

		; TODO: consider search region if provided by the view object?
		
		; && viewObj["searchRegion"]["X1"] >= 0 && viewObj["searchRegion"]["Y1"] >= 0 && viewObj["searchRegion"]["X2"] >= 0 && viewObj["searchRegion"]["Y2"] >= 0
		
		if (viewObj["searchRegion"] != "" && viewObj["searchRegion"]["X1"] >= 0 && viewObj["searchRegion"]["Y1"] >= 0 && viewObj["searchRegion"]["X2"] >= 0 && viewObj["searchRegion"]["Y2"] >= 0) {
			;~ MsgBox, search region data!
			sX1 := viewObj["searchRegion"]["X1"]
			sY1 := viewObj["searchRegion"]["Y1"] + yBorder
			sX2 := viewObj["searchRegion"]["X2"]
			sY2 := viewObj["searchRegion"]["Y2"] + yBorder
			;~ MsgBox % sX1 sY1 sX2 sY2
			result := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle,OutputList,sX1,sY1,sX2,sY2,60,0,1,1)
		} else {  ; search region data is invalid or is not provided -> search full window
			result := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle,OutputList,,,,,60,0,1,1)
		}
	
		;~ result := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle,OutputList,,,,,60,0,1,1)
		
		; try freeing vars
		Gdip_DisposeImage(pBitmapHayStack)
		Gdip_DisposeImage(pBitmapNeedle)
		
		pBitmapHayStack := ""
		pBitmapNeedle := ""
		
		
		if (result = 1) {  ; image found
			; Maybe refractor this to a clickOnFound?
			if(viewObj["override"] != "") {
				switch viewObj["override"] {
					case "quick taps": 
						if (canSimulateHumanBehavior) {
							;~ MsgBox behavior!
							simulateRandomBehavior()  ; more reasonable because usually i put it game on auto and switch to other task but forgot about it for a while
						}
						; after possible sleep
						if(canRun) {
							quickTapAnywhere()
						} else {
							return
						}
				}
				return
			}
			
			resCoord := StrSplit(OutputList, ",")
			x := resCoord[1]
			y := resCoord[2]
			
			;~ MsgBox, % x y
			
			; get image center, need to know width and height
			hW := viewObj["size"]["w"] / 2
			hH := viewObj["size"]["h"] / 2
			
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			;;
			;;  OK: consider click offset provided by the view
			;;  TODO: add randomness to the click point
			;;  OK: override action -> go to another action without click
			;;
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
			; if an offset is provided, add offset to the final coord value
			if (viewObj["offset"]["x"] != "" && viewObj["offset"]["y"] != "") {
				xOffset := viewObj["offset"]["x"]
				yOffset := viewObj["offset"]["y"]
				;~ MsgBox, % xOffset ", " yOffset
			} else {
				xOffset = 0
				yOffset = 0
			}
			
			; generate random click position offset
			xRand := NormalRand(-stdErrorRange, stdErrorRange, 0)
			yRand := NormalRand(-stdErrorRange, stdErrorRange, 0)
			
			xClick := x + hW + xOffset + xRand
			yClick := y + hH + yOffset + yRand ;+ yBorder  ; maybe yBorder is not needed when using gdip? idk
			act := viewObj["act"]
			
			changeStatusText(resx["status_ImageSearch_Searching"] "[" viewObj["path"] "]" resx["status_ImageSearch_Success"])
			
			; first click then wait?
			; random sleep
			tPause := NormalRand(0, stdWaitTime, 0)
			
			ExecClick(act, xClick, yClick, tPause, canSimulateHumanBehavior)

			;~ GuiControl,, ClickPosIndicator, Action: %act%`nX: %xClick% / Y: %yClick%`nClick Delay: %tPause%s
			
			;~ if (canSimulateHumanBehavior) {
				;~ simulateRandomBehavior()  ; more reasonable because usually i put it game on auto and switch to other task but forgot about it for a while
			;~ }
			
			;~ Sleep tPause * 1000
			;~ ; check if stop condition met
			;~ if(!canRun) {
				;~ ; MsgBox, cancelling
				;~ return
			;~ }
			
			;~ ControlClick, x%xClick% y%yClick%, ahk_id %asaGameHwnd%,, left  ; do click
			
			break
		}
		
		retryCount++
		GuiControl,, WinSize, % resx["status_ImageSearch_Searching"] "[" viewObj["path"] "]" resx["status_ImageSearch_Iters"] retryCount
		Sleep waitInterval
		
		if (retryCount >= abortCount) {
			; abort
			changeStatusText(resx["status_ImageSearch_Limit"] viewObj["path"] resx["status_ImageSearch_Skip"])
			return
		}
		
		; IMPORTANT: if unable to find target images after multiple iteration, maybe the draw need to be updated
		; drag the screen a little bit, or go back to previous page to let the screen to be redraw
		
	}
}


existImage(imgPath, L_x1="", L_y1="", L_x2="", L_y2="", waitInterval=200, numTryAllowed=5, isTerminal=false) {
	global asaGameHwnd
	global canRun

	global yBorder
	
	iters = 0
	
	imgPath := A_ScriptDir "\data\img\" imgPath
	
	while(true) {
		if(!canRun) {
			;~ MsgBox, cancelling
			return false
		}
		
		; handleGeneralError()  ; dealing with errors
		if(isTerminal) {
			if(hasEarlyResult()) {
				return
			}
		}
		
		pBitmapHayStack := Gdip_BitmapFromHWND(asaGameHwnd)
		pBitmapNeedle := Gdip_CreateBitmapFromFile(imgPath)
		
		if (L_x1 >= 0 && L_y1 >= 0 && L_x2 >= 0 && L_y2 >= 0) {
			;~ MsgBox, search region data!
			sX1 := L_x1
			sY1 := L_y1 + yBorder
			sX2 := L_x2
			sY2 := L_y2 + yBorder
			
			result := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle,OutputList,sX1,sY1,sX2,sY2,60,0,1,1)
		} else {  ; search region data is invalid or is not provided -> search full window
			result := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle,OutputList,,,,,60,0,1,1)
		}

		; try freeing vars
		Gdip_DisposeImage(pBitmapHayStack)
		Gdip_DisposeImage(pBitmapNeedle)
		
		pBitmapHayStack := ""
		pBitmapNeedle := ""
		
		if (result = 1) {  ; image found
			;~ MsgBox, img found!
			return true
		}
		
		iters++
		
		if(numTryAllowed > 0 && iters > numTryAllowed) {
			;~ MsgBox, out of allowance
			return false ; try allowance reached
		} ; else if numTryAllowed < 0 or = 0, then do nothing and let the loop run unlimitedly until image is found
		
		
		
		Sleep waitInterval
		; IMPORTANT: if unable to find target images after multiple iteration, maybe the draw need to be updated
		; drag the screen a little bit, or go back to previous page to let the screen to be redraw
		
	}
}

; if numTryAllowed is 0, then allow unlimited try
notExistImage(imgPath, L_x1="", L_y1="", L_x2="", L_y2="", waitInterval=100, numTryAllowed=2, isTerminal=false) {
	global asaGameHwnd
	global canRun

	global yBorder
	
	iters = 0
	assertCount = 0
	notFound = true
	
	imgPath := A_ScriptDir "\data\img\" imgPath
	
	while(true) {
		if(!canRun) {
			;~ MsgBox, cancelling
			return
		}
		
		; handleGeneralError()  ; dealing with errors
		
		if(isTerminal) {
			if(hasEarlyResult()) {
				return
			}
		}
		
		pBitmapHayStack := Gdip_BitmapFromHWND(asaGameHwnd)
		pBitmapNeedle := Gdip_CreateBitmapFromFile(imgPath)
		
		if (L_x1 >= 0 && L_y1 >= 0 && L_x2 >= 0 && L_y2 >= 0) {
			;~ MsgBox, search region data!
			sX1 := L_x1
			sY1 := L_y1 + yBorder
			sX2 := L_x2
			sY2 := L_y2 + yBorder
			
			result := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle,OutputList,sX1,sY1,sX2,sY2,60,0,1,1)
		} else {  ; search region data is invalid or is not provided -> search full window
			result := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle,OutputList,,,,,60,0,1,1)
		}

		; try freeing vars
		Gdip_DisposeImage(pBitmapHayStack)
		Gdip_DisposeImage(pBitmapNeedle)
		
		pBitmapHayStack := ""
		pBitmapNeedle := ""
		
		if (result = 0) {  ; image not found
			assertCount++
			
			; if numTryAllowed is not given, then loop 5 times and assert
			; otherwise loop numTryAllowed times then assert no such image and return true
			
			if (assertCount >= numTryAllowed) {
				; assert not found
				;~ MsgBox, assert not exist!
				return true
			}
		}  ; else image is still present in the window, try again
		
		Sleep waitInterval
		; IMPORTANT: if unable to find target images after multiple iteration, maybe the draw need to be updated
		; drag the screen a little bit, or go back to previous page to let the screen to be redraw
		
	}
}


existFuzzImage(imgPath, L_x1="", L_y1="", L_x2="", L_y2="", waitInterval=200, numTryAllowed=5, variation=50) {
	global asaGameHwnd
	global canRun

	global yBorder
	
	iters = 0
	
	imgPath := A_ScriptDir "\data\img\" imgPath
	
	while(true) {
		if(!canRun) {
			;~ MsgBox, cancelling
			return false
		}
		
		pBitmapHayStack := Gdip_BitmapFromHWND(asaGameHwnd)
		pBitmapNeedle := Gdip_CreateBitmapFromFile(imgPath)
		
		if (L_x1 >= 0 && L_y1 >= 0 && L_x2 >= 0 && L_y2 >= 0) {
			;~ MsgBox, search region data!
			sX1 := L_x1
			sY1 := L_y1 + yBorder
			sX2 := L_x2
			sY2 := L_y2 + yBorder
			
			result := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle,OutputList,sX1,sY1,sX2,sY2,variation,0,1,1)
		} else {  ; search region data is invalid or is not provided -> search full window
			result := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle,OutputList,,,,,variation,0,1,1)
		}

		; try freeing vars
		Gdip_DisposeImage(pBitmapHayStack)
		Gdip_DisposeImage(pBitmapNeedle)
		
		pBitmapHayStack := ""
		pBitmapNeedle := ""
		
		if (result = 1) {  ; image found
			;~ MsgBox, img found!
			return true
		}
		
		iters++
		
		if(numTryAllowed > 0 && iters > numTryAllowed) {
			;~ MsgBox, out of allowance
			return false ; try allowance reached
		} ; else if numTryAllowed < 0 or = 0, then do nothing and let the loop run unlimitedly until image is found
		
		
		
		Sleep waitInterval
		; IMPORTANT: if unable to find target images after multiple iteration, maybe the draw need to be updated
		; drag the screen a little bit, or go back to previous page to let the screen to be redraw
		
	}
}


pixelColorMatch(cX, cY, matchColor, waitInterval=0, numTryAllowed=0) {
	global asaGameHwnd
	global canRun

	global yBorder
	
	iters = 0
	
	while(true) {
		if(!canRun) {
			;~ MsgBox, cancelling
			return false
		}
		
		pBitmapHayStack := Gdip_BitmapFromHWND(asaGameHwnd)
		pixelColor := Gdip_GetPixel(pBitmapHayStack, cX, cY + yBorder)

		; try freeing vars
		Gdip_DisposeImage(pBitmapHayStack)
		pBitmapHayStack := ""
		
		if (pixelColor = matchColor) {  ; pixel color match 29E2DA
			;~ MsgBox, img found!
			return true
		} 
		else {
			MsgBox % pixelColor
		}
		
		if(numTryAllowed > 0 && iters > numTryAllowed) {
			;~ MsgBox, out of allowance
			return false ; try allowance reached
		} ; else if numTryAllowed < 0 or = 0, then do nothing and let the loop run unlimitedly until image is found
		
		iters++
		
		Sleep waitInterval
		; IMPORTANT: if unable to find target images after multiple iteration, maybe the draw need to be updated
		; drag the screen a little bit, or go back to previous page to let the screen to be redraw
		
	}
}

areaColorMatch(cX, cY, matchColor, waitInterval=0, numTryAllowed=0) {
	global asaGameHwnd
	global canRun

	global yBorder
	
	iters = 0
	
	; 4293302272
	

	if(!canRun) {
		return false
	}
	
	pBitmapHayStack := Gdip_BitmapFromHWND(asaGameHwnd)
	
	offsetDist := -3
	lineMatch := true
	while(offsetDist < 4) {
		pixelColor := Gdip_GetPixel(pBitmapHayStack, cX + offsetDist, cY + yBorder)
		if(pixelColor = matchColor) {
			; continue
			;~ MsgBox % "offset: " offsetDist ", color: " pixelColor
			
			offsetDist := offsetDist + 1
		} else {
			lineMatch := false
			break
		}
	}
	
	;~ MsgBox % "line search done: " lineMatch
	
	; try freeing vars
	Gdip_DisposeImage(pBitmapHayStack)
	pBitmapHayStack := ""
	
	return lineMatch
}



hasEarlyResult() {  ; if battle is ended earlier than expected
	; check win in every loop
	; if result image is found then switch early termination
	global asaGameHwnd
	global canRun
	global yBorder
	global earlyResult
	
	if(!canRun) {
		;~ MsgBox, cancelling
		return
	}
	
	if(earlyResult) { ;~ if confirmed, return immediately
		return true
	}
	
	retryCount = 0
	
	imgPath := A_ScriptDir "\data\img\resultBattleStats.png"
	
	pBitmapHayStack := Gdip_BitmapFromHWND(asaGameHwnd)
	
	; Check for resultBattleStats.png
	pBitmapNeedle := Gdip_CreateBitmapFromFile(imgPath)
	
	sX1 := 1136
	sY1 := 417 + yBorder
	sX2 := 1248
	sY2 := 450 + yBorder
	
	result := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle,OutputList,sX1,sY1,sX2,sY2,60,0,1,1)
	;~ result := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle,OutputList,,,,,60,0,1,1)
	
	; try freeing vars
	Gdip_DisposeImage(pBitmapNeedle)
	Gdip_DisposeImage(pBitmapHayStack)
	
	if (result = 1) {  ; image found
		earlyResult := true
		return true
	} else {
		return false
	}
}


handleGeneralError() {
	global asaGameHwnd
	global ClickPosIndicator
	global stdWaitTime
	global stdErrorRange
	global WinSize 
	
	global errorConfirmButton
	global canRun
	
	global allData
	
	; as long as an error is prompted, click on confirm button, and then check whether the script needs to be restarted (need to re-login)
	
	if(!canRun) {
		;~ MsgBox, cancelling
		return
	}
	
	global yBorder
	
	eX1 := 373
	eY1 := 430 + yBorder
	eX2 := 902
	eY2 := 531 + yBorder
	
	retryCount = 0
	
	imgPath := A_ScriptDir "\data\img\" errorConfirmButton["path"]
	
	pBitmapHayStack := Gdip_BitmapFromHWND(asaGameHwnd)
	
	; Check for RefreshPlayerData Error
	pBitmapNeedle_errorConfirmButton := Gdip_CreateBitmapFromFile(imgPath)
	result_errorConfirmButton := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle_errorConfirmButton,OutputList,eX1,eY1,eX2,eY2,60,0,1,1)
	
	; try freeing vars
	Gdip_DisposeImage(pBitmapNeedle_errorConfirmButton)
	
	if(result_errorConfirmButton = 1) {
		resCoord := StrSplit(OutputList, ",")
		x := resCoord[1]
		y := resCoord[2]
		
		; get image center, need to know width and height
		hW := errorConfirmButton["size"]["w"] / 2
		hH := errorConfirmButton["size"]["h"] / 2
		
		; if an offset is provided, add offset to the final coord value
		if (errorConfirmButton["offset"]["x"] != "" && errorConfirmButton["offset"]["y"] != "") {
			xOffset := errorConfirmButton["offset"]["x"]
			yOffset := errorConfirmButton["offset"]["y"]
			;~ MsgBox, % xOffset ", " yOffset
		} else {
			xOffset = 0
			yOffset = 0
		}
		
		; generate random click position offset
		xRand := NormalRand(-stdErrorRange, stdErrorRange, 0)
		yRand := NormalRand(-stdErrorRange, stdErrorRange, 0)
		
		xClick := x + hW + xOffset + xRand
		yClick := y + hH + yOffset + yRand ; + yBorder  ; maybe yBorder is not needed when using gdip? idk
		act := viewObj["act"]
		
		; random sleep
		tPause := NormalRand(0, stdWaitTime, 0)

		GuiControl,, ClickPosIndicator, Action: %act%`nX: %xClick% / Y: %yClick%`nClick Delay: %tPause%s
		;~ Sleep tPause * 1000
		
		ControlClick, x%xClick% y%yClick%, ahk_id %asaGameHwnd%,, left  ; do click
		
		; sleep a while and let the game continue to run
		Sleep 2000
	}
	
	; free bmp from handle to window
	Gdip_DisposeImage(pBitmapHayStack)
}


checkForError() {
	; TODO: three different images are searched. need refractoring badly
	
	global asaGameHwnd
	global ClickPosIndicator
	global stdWaitTime
	global stdErrorRange
	global WinSize 
	
	global refreshPlayerData
	global networkError
	global connectionError
	global canRun
	
	global allData
	
	if(!canRun) {
		;~ MsgBox, cancelling
		return
	}
	
	eX1 = 400
	eY1 = 300
	eX2 = 870
	eY2 = 400
	
	global yBorder
	
	retryCount = 0
	
	pBitmapHayStack := Gdip_BitmapFromHWND(asaGameHwnd)
	
	; Check for RefreshPlayerData Error
	pBitmapNeedle_refreshPlayerData := Gdip_CreateBitmapFromFile(refreshPlayerData["path"])
	result_refreshPlayerData := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle_refreshPlayerData,OutputList,eX1,eY1,eX2,eY2,60,0,1,1)
	
	; try freeing vars
	Gdip_DisposeImage(pBitmapNeedle_refreshPlayerData)
	
	if (result_refreshPlayerData = 1) {  ; image found
		resCoord := StrSplit(OutputList, ",")
		x := resCoord[1]
		y := resCoord[2]
		
		; get image center, need to know width and height
		hW := refreshPlayerData["size"]["w"] / 2
		hH := refreshPlayerData["size"]["h"] / 2
		
		; if an offset is provided, add offset to the final coord value
		if (refreshPlayerData["offset"]["x"] != "" && refreshPlayerData["offset"]["y"] != "") {
			xOffset := refreshPlayerData["offset"]["x"]
			yOffset := refreshPlayerData["offset"]["y"]
			;~ MsgBox, % xOffset ", " yOffset
		} else {
			xOffset = 0
			yOffset = 0
		}
		
		; generate random click position offset
		xRand := NormalRand(-stdErrorRange, stdErrorRange, 0)
		yRand := NormalRand(-stdErrorRange, stdErrorRange, 0)
		
		xClick := x + hW + xOffset + xRand
		yClick := y + hH + yOffset + yRand ; + yBorder  ; maybe yBorder is not needed when using gdip? idk
		act := viewObj["act"]
		
		; random sleep
		tPause := NormalRand(0, stdWaitTime, 0)

		GuiControl,, ClickPosIndicator, Action: %act%`nX: %xClick% / Y: %yClick%`nClick Delay: %tPause%s
		;~ Sleep tPause * 1000
		
		ControlClick, x%xClick% y%yClick%, ahk_id %asaGameHwnd%,, left  ; do click
		
		; sleep a while and let the game continue to run
		Sleep 2000
	}
	
	; Check for UpdatePlayerData Error
	pBitmapNeedle_updatePlayerData := Gdip_CreateBitmapFromFile(updatePlayerData["path"])
	result_updatePlayerData := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle_updatePlayerData,OutputList,eX1,eY1,eX2,eY2,60,0,1,1)
	
	; try freeing vars
	Gdip_DisposeImage(pBitmapNeedle_updatePlayerData)
	
	if (result_updatePlayerData = 1) {  ; image found
		resCoord := StrSplit(OutputList, ",")
		x := resCoord[1]
		y := resCoord[2]
		
		; get image center, need to know width and height
		hW := updatePlayerData["size"]["w"] / 2
		hH := updatePlayerData["size"]["h"] / 2
		
		; if an offset is provided, add offset to the final coord value
		if (updatePlayerData["offset"]["x"] != "" && updatePlayerData["offset"]["y"] != "") {
			xOffset := updatePlayerData["offset"]["x"]
			yOffset := updatePlayerData["offset"]["y"]
			;~ MsgBox, % xOffset ", " yOffset
		} else {
			xOffset = 0
			yOffset = 0
		}
		
		; generate random click position offset
		xRand := NormalRand(-stdErrorRange, stdErrorRange, 0)
		yRand := NormalRand(-stdErrorRange, stdErrorRange, 0)
		
		xClick := x + hW + xOffset + xRand
		yClick := y + hH + yOffset + yRand ; + yBorder  ; maybe yBorder is not needed when using gdip? idk
		act := viewObj["act"]
		
		; random sleep
		tPause := NormalRand(0, stdWaitTime, 0)

		GuiControl,, ClickPosIndicator, Action: %act%`nX: %xClick% / Y: %yClick%`nClick Delay: %tPause%s
		;~ Sleep tPause * 1000
		
		ControlClick, x%xClick% y%yClick%, ahk_id %asaGameHwnd%,, left  ; do click
		
		; sleep a while and let the game continue to run
		Sleep 2000
	}
	
	; Check for Network Error
	pBitmapNeedle_networkError := Gdip_CreateBitmapFromFile(networkError["path"])
	result_networkError := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle_networkError,OutputList,eX1,eY1,eX2,eY2,60,0,1,1)
	
	; try freeing vars
	Gdip_DisposeImage(pBitmapNeedle_networkError)
	
	if (result_networkError = 1) {  ; image found
		resCoord := StrSplit(OutputList, ",")
		x := resCoord[1]
		y := resCoord[2]
		
		; get image center, need to know width and height
		hW := networkError["size"]["w"] / 2
		hH := networkError["size"]["h"] / 2
		
		; if an offset is provided, add offset to the final coord value
		if (networkError["offset"]["x"] != "" && networkError["offset"]["y"] != "") {
			xOffset := networkError["offset"]["x"]
			yOffset := networkError["offset"]["y"]
		} else {
			xOffset = 0
			yOffset = 0
		}
		
		; generate random click position offset
		xRand := NormalRand(-stdErrorRange, stdErrorRange, 0)
		yRand := NormalRand(-stdErrorRange, stdErrorRange, 0)
		
		xClick := x + hW + xOffset + xRand
		yClick := y + hH + yOffset + yRand ; + yBorder  ; maybe yBorder is not needed when using gdip? idk
		act := viewObj["act"]
		
		; random sleep
		tPause := NormalRand(0, stdWaitTime, 0)

		GuiControl,, ClickPosIndicator, Action: %act%`nX: %xClick% / Y: %yClick%`nClick Delay: %tPause%s
		;~ Sleep tPause * 1000
		
		ControlClick, x%xClick% y%yClick%, ahk_id %asaGameHwnd%,, left  ; do click
		
		; sleep a while and let the game continue to run
		Sleep 2000
	}
	
	; Check for Connection Error
	pBitmapNeedle_connectionError := Gdip_CreateBitmapFromFile(connectionError["path"])
	result_connectionError := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle_connectionError,OutputList,eX1,eY1,eX2,eY2,60,0,1,1)
	
	; try freeing vars
	Gdip_DisposeImage(pBitmapNeedle_connectionError)
	
		resCoord := StrSplit(OutputList, ",")
	if (result_connectionError = 1) {  ; image found
		x := resCoord[1]
		y := resCoord[2]
		
		; get image center, need to know width and height
		hW := connectionError["size"]["w"] / 2
		hH := connectionError["size"]["h"] / 2
		
		; if an offset is provided, add offset to the final coord value
		if (connectionError["offset"]["x"] != "" && connectionError["offset"]["y"] != "") {
			xOffset := connectionError["offset"]["x"]
			yOffset := connectionError["offset"]["y"]
			;~ MsgBox, % xOffset ", " yOffset
		} else {
			xOffset = 0
			yOffset = 0
		}
		
		; generate random click position offset
		xRand := NormalRand(-stdErrorRange, stdErrorRange, 0)
		yRand := NormalRand(-stdErrorRange, stdErrorRange, 0)
		
		xClick := x + hW + xOffset + xRand
		yClick := y + hH + yOffset + yRand ; + yBorder  ; maybe yBorder is not needed when using gdip? idk
		act := viewObj["act"]
		
		; random sleep
		tPause := NormalRand(0, stdWaitTime, 0)

		GuiControl,, ClickPosIndicator, Action: %act%`nX: %xClick% / Y: %yClick%`nClick Delay: %tPause%s
		;~ Sleep tPause * 1000
		
		ControlClick, x%xClick% y%yClick%, ahk_id %asaGameHwnd%,, left  ; do click
		
		; sleep a while and let the game continue to run
		Sleep 2000
	}
	
	; free bmp from handle to window
	Gdip_DisposeImage(pBitmapHayStack)
}



; check for kicked error -> bad auth
checkLoginOnBadAuth() {
	global resx
	
	global canRun
	global canRestart
	global runCount
	global previousRunCount
	; check for associate data with account option image in the lower right corner
	; if found, click a few times to login
	
	if(!canRun) {
		;~ MsgBox, cancelling
		return
	}
	
	titleScreen := existImage("Error_TitleScreen.png", 549, 671, 577, 704, 50, 1)
	;~ as long as Error_TitleScreen.png exists, click a random place to try to login unless number of retries reaches 200
	while(titleScreen) {
		titleScreen := existImage("Error_TitleScreen.png", 549, 671, 577, 704, 50, 1)
		
		if (titleScreen) {
			;~ tap to start
			changeStatusText(resx["err_AuthExp"])
			quickTapAnywhere(1)
			Sleep 1000
		} else {
			changeStatusText(resx["status_LoginSuccess"])
			Sleep 5000
			
			handleGeneralError()
			
			; check if notice board -> check if 出撃 button is visible
			while(true) {
				found := existImage("mainPage_CapaignMap.png",,,,,,1)
				
				if(!found) {  ; if image cannot be found, click on blank area and try finding the image again
					coordClick(61, 338)
					Sleep 5000
					; check for return to last page button
					back := existImage("previousPage.png",,,,,,1)
					if(back) {
						findClick("returnHomeButton")
					}
				} else {  ; if image can be found, break loop and continue
					break
				}
			}
			
			; TODO !!!
			; set canRestart and canRun
			changeStatusText(resx["status_ScriptRestarting"])
			
			;~ copy current runCount
			previousRunCount = runCount
			
			Sleep 2000
			
			BigSwitchOff()
			
			;~ canRun = false  ; stop the script
			canRestart = true  ; set the script to be restarted when reaching the end
			
			break
		}
	}
	
	
	;~ badAuth := existImage("loginView_associateAccount.png", 1045, 584, 1216, 653, 50, 1)
	
	;~ if (badAuth) {
		;~ changeStatusText("Auth expired. Try to re-login...")
		;~ Sleep 2000
		;~ quickTapAnywhere(1)
		
		;~ while(true) {
			;~ Sleep 2000
			;~ recheckBadAuth := existImage("loginView_associateAccount.png", 1045, 584, 1216, 653, 50, 1)
			;~ if (recheckBadAuth) {
				;~ quickTapAnywhere(1)
			;~ } else {
				;~ break
			;~ }
		;~ }
		
		;~ ; check for login success
		;~ existImage("loginView_mailSupport.png", 1042, 577, 1212, 646, 50, 0)  ; must see
		;~ changeStatusText("Login Success")
		;~ ; after mail support icon is found, click on screen to go to the home page
		;~ quickTapAnywhere(1)
		
		;~ Sleep 5000
		
		;~ handleGeneralError()
		
		;~ ; check if notice board -> check if 出撃 button is visible
		;~ while(true) {
			;~ found := existImage("mainPage_CapaignMap.png",,,,,,1)
			
			;~ if(!found) {  ; if image cannot be found, click on blank area and try finding the image again
				;~ coordClick(61, 338)
				;~ Sleep 5000
				;~ ; check for return to last page button
				;~ back := existImage("previousPage.png",,,,,,1)
				;~ if(back) {
					;~ findClick("returnHomeButton")
				;~ }
			;~ } else {  ; if image can be found, break loop and continue
				;~ break
			;~ }
		;~ }
		
		;~ ; TODO !!!
		;~ ; set canRestart and canRun
		;~ changeStatusText("Restarting the script run...")
		;~ Sleep 2000
		
		;~ BigSwitchOff()
		
		;~ canRestart = true  ; set the script to be restarted when reaching the end
	;~ }
	
	return
	; what if this is the first login of the day? then need to click on blank area to skip event data
	; check if 出撃 button is visible, if so, restart the whole script
	; set canRun to false and let the script fall down to the end until it totally stops
	; modify the main routine so that if a canRestart variable is set to true, then it will automatically reset canRun to true and continue to run from
}


disableAutoBattle() {  ;~ this function only needs to be called on the first run
	global resx
	
	global yBorder
	
	;~ search image to check if auto battle option is checked
	;~ if so, uncheck it
	changeStatusText(resx["status_DisableAuto"])
	autoBattle := existImage("Option_AutoBattle.png", 1129, 615, 1250, 699, 200, 5)
	if (autoBattle) {
		;~ click to uncheck the option
		ExecClick(resx["status_UncheckAuto"], 1193, 641 + yBorder, 0, false)
		
		Sleep 500
	}
}



quickTapAnywhere(numClick=20) {
	; generate some quick taps at random positions
	; usually used in after battle stats page
	
	global asaGameHwnd        ; Handle to emulator window
	global ClickPosIndicator  ; next click position
	global WinSize            ; status bar
	global allData            ; click data
	
	global canRun
	
	global yBorder ; constant border px
	
	; base point
	;~ Random, xBase, 562.0, 1000.0
	;~ Random, yBase, 570.0, 670.0
	
	xBase := NormalRand(1086, 1239, 0)
	yBase := NormalRand(96, 565, 0)
	
	; TODO: chances to get large offset, 2% percent?
	
	k := 0
	while(k < numClick) {
		
		if(!canRun) {
			break
		}
	
		; random offsets from base point for each click
		
		; gerating a random point within a circle uniformly
		; random angle and random radius times the sqrt of random()
		
		maxRangeFromCenter := 15
		
		;~ Random, R_angle, 0.0, 1.0  ; random angle percentage of 2*pi
		;~ Random, R_radius, 0.0, 1.0  ; random radius
		
		R_angle := NormalRand(0, 1, 0)
		R_radius := NormalRand(0, 1, 0)
		
		fAngle := R_angle * 2 * 4 * ATan(1)  ; pi value
		fRadius := maxRangeFromCenter * Sqrt(R_radius)
		
		xRand := fRadius * cos(fAngle)
		yRand := fRadius * sin(fAngle)
		
		Random, rT, 0.0, 0.25 ; random time interval
		
		xClick := xBase + xRand
		yClick := yBase + yRand + yBorder
		
		GuiControl,, ClickPosIndicator, Click Time Offset -> %rT%s, %xClick% %yClick%
		ControlClick, x%xClick% y%yClick%, ahk_id %asaGameHwnd%,,left  ; do click
		GuiControl,, WinSize, "Click Combo!"
		k++
		
		Sleep rT * 1000
	}
}

getRandomClick(mapDataObj, clickPosIndicator)  ; OBSOLETE, but maybe useful for coord and time mode...
{
	global useCoordDataOnly  ; disable image search, use prepared coord only
	global WinSize
	global asaGameHwnd       ; handle to window
	global stdWaitTime       ; standard wait time
	global stdErrorRange     ; limit of click offset
	
	xRand := NormalRand(-stdErrorRange, stdErrorRange, 0)
	yRand := NormalRand(-stdErrorRange, stdErrorRange, 0)
	global yBorder
	
	; if mapDataObj's x and y are both -1, it is an image find test
	; else apply coord click
	if (mapDataObj["path"] != "" && useCoordDataOnly = false) {  ; (mapDataObj["x"] = -1) && (mapDataObj["y"] = -1)
		GuiControl,, WinSize, "Image Search Mode"
		imgFile := mapDataObj["path"]
		
		retryCount = 0
		while(true) {
			WinActivate, ahk_id %asaGameHwnd%
			ImageSearch, imgX, imgY, mapNodeSelection["x1"], mapNodeSelection["y1"] + yBorder, mapNodeSelection["x2"], mapNodeSelection["y2"] + yBorder, *50 %imgFile%
		
			Sleep 1000
		
			if (ErrorLevel = 1) {
				retryCount++
				GuiControl,, WinSize, % "Image Not Found... re-trying count: " + retryCount
			} else if (ErrorLevel = 0) {
				GuiControl,, WinSize, "Image Found!" + %imgX% + %imgY%
				break
			}
		}
		
		hW := mapDataObj["size"]["w"] / 2
		hH := mapDataObj["size"]["h"] / 2
		
		x := imgX + hW + xRand
		y := imgY + hH + yRand + yBorder
		act := mapDataObj["act"]
		
		; random sleep
		;~ Random, tPause, 0.0, 4.0
		tPause := NormalRand(0, stdWaitTime, 0)

		GuiControl,, clickPosIndicator, x = %x%`, y = %y%`, Action -> %act%, Click Time Offset -> %tPause%s
		
		_fp := {"x": x, "y": y, "delay": tPause}
		return _fp
	} 
	else 
	{
		GuiControl,, WinSize, % "Coord Click Mode"
		
		x := mapDataObj["x"] + xRand
		y := mapDataObj["y"] + yRand + yBorder
		act := mapDataObj["act"]
		
		; random sleep
		tPause := NormalRand(0, stdWaitTime, 0)

		GuiControl,, clickPosIndicator, x = %x%`, y = %y%`, Action -> %act%, Click Time Offset -> %tPause%s
		
		_fp := {"x": x, "y": y, "delay": tPause}
		return _fp
	}
}



changeStatusText(currentStatus) {
	global WinSize
	GuiControl,, WinSize, %currentStatus%
	
	return
}

ExecClick(actName, pX, pY, delay, canSimulateHumanBehavior) {
	global ClickPosIndicator
	global canRun
	global asaGameHwnd
	global clickNoDelay
	
	if (clickNoDelay) {
		GuiControl,, ClickPosIndicator, Action: %actName%`nX: %pX% / Y: %pY%
	} else {
		GuiControl,, ClickPosIndicator, Action: %actName%`nX: %pX% / Y: %pY%`nDelay: %delay%s
	}
	
	if (canSimulateHumanBehavior) {
		simulateRandomBehavior()  ; more reasonable because usually i put it game on auto and switch to other task but forgot about it for a while
	}
	
	if (!clickNoDelay) {
		Sleep delay * 1000
	}
	
	; check if stop condition met
	if(!canRun) {
		;~ MsgBox, cancelling
		return
	}
	
	ControlClick, x%pX% y%pY%, ahk_id %asaGameHwnd%,, left  ; do click
}



NormalRand(x,y,int=1) { ;x lower y upper int for integer return
	Loop 12
	{
		Random, var,0.0,1
		Num+=var
	}
	norm := (int) ? Round((y+x)/2+((Num-6)*(y-x))/6) : (y+x)/2+((Num-6)*(y-x))/6
	Return norm < x ? x : norm > y ? y : norm
}
