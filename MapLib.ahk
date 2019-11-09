#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; import Gdip libs for image search
#Include Gdip_All.ahk
#Include Gdip_ImageSearch.ahk

; Functions
p := Gdip_Startup()

findClick(viewObj, abortCount=500, waitInterval=500, canSimulateHumanBehavior=false) {
	global asaGameHwnd
	global ClickPosIndicator
	global stdWaitTime
	global stdErrorRange
	global WinSize 
	global refreshPlayerData
	
	yBorder = 36
	
	retryCount = 0
	while(true) {
		
		checkForError()
		
		pBitmapHayStack := Gdip_BitmapFromHWND(asaGameHwnd)

		pBitmapNeedle := Gdip_CreateBitmapFromFile(viewObj["path"])

		;~ msgbox, % pBitmapHayStack "," pBitmapNeedle
	
		result := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle,OutputList,,,,,60,0,1,1)
		
		
		if (result = 1) {  ; image found
			
			if(viewObj["override"] != "") {
				switch viewObj["override"] {
					case "quick taps": quickTapAnywhere()
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
			
			; random sleep
			;~ Random, tPause, 0.0, 4.0
			tPause := NormalRand(0, stdWaitTime, 0)

			GuiControl,, ClickPosIndicator, x = %xClick%`, y = %yClick%`, Action -> %act%, Click Time Offset -> %tPause%s
			Sleep tPause * 1000
			
			if canSimulateHumanBehavior {
				simulateRandomBehavior()  ; more reasonable because usually i put it game on auto and switch to other task but forgot about it for a while
			}
			
			ControlClick, x%xClick% y%yClick%, ahk_id %asaGameHwnd%,, left  ; do click
			
			break
		}
		
		retryCount++
		GuiControl,, WinSize, % "Fail to find, retry:" retryCount
		Sleep waitInterval
		
		if (retryCount >= abortCount) {
			; abort
			MsgBox, Huston, we have a problem!
		}
		
		
		; IMPORTANT: if unable to find target images after multiple iteration, maybe the draw need to be updated
		; drag the screen a little bit, or go back to previous page to let the screen to be redraw
		
	}
}


checkForError() {
	global asaGameHwnd
	global ClickPosIndicator
	global stdWaitTime
	global stdErrorRange
	global WinSize 
	
	global refreshPlayerData
	global networkError
	global connectionError
	
	eX1 = 400
	eY1 = 300
	eX2 = 870
	eY2 = 400
	
	yBorder = 36
	
	retryCount = 0
	
	pBitmapHayStack := Gdip_BitmapFromHWND(asaGameHwnd)
	
	; Check for RefreshPlayerData Error
	pBitmapNeedle_refreshPlayerData := Gdip_CreateBitmapFromFile(refreshPlayerData["path"])
	result_refreshPlayerData := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle_refreshPlayerData,OutputList,eX1,eY1,eX2,eY2,60,0,1,1)
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
		yClick := y + hH + yOffset + yRand ;+ yBorder  ; maybe yBorder is not needed when using gdip? idk
		act := viewObj["act"]
		
		; random sleep
		;~ Random, tPause, 0.0, 4.0
		tPause := NormalRand(0, stdWaitTime, 0)

		GuiControl,, ClickPosIndicator, x = %xClick%`, y = %yClick%`, Action -> %act%, Click Time Offset -> %tPause%s
		Sleep tPause * 1000
		
		ControlClick, x%xClick% y%yClick%, ahk_id %asaGameHwnd%,, left  ; do click
	}
	
	; Check for Network Error
	pBitmapNeedle_networkError := Gdip_CreateBitmapFromFile(networkError["path"])
	result_networkError := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle_networkError,OutputList,eX1,eY1,eX2,eY2,60,0,1,1)
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
		
		; random sleep
		;~ Random, tPause, 0.0, 4.0
		tPause := NormalRand(0, stdWaitTime, 0)

		GuiControl,, ClickPosIndicator, x = %xClick%`, y = %yClick%`, Action -> %act%, Click Time Offset -> %tPause%s
		Sleep tPause * 1000
		
		ControlClick, x%xClick% y%yClick%, ahk_id %asaGameHwnd%,, left  ; do click
	}
	
	; Check for Connection Error
	pBitmapNeedle_connectionError := Gdip_CreateBitmapFromFile(connectionError["path"])
	result_connectionError := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle_connectionError,OutputList,eX1,eY1,eX2,eY2,60,0,1,1)
	if (result_connectionError = 1) {  ; image found
		resCoord := StrSplit(OutputList, ",")
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
		yClick := y + hH + yOffset + yRand ;+ yBorder  ; maybe yBorder is not needed when using gdip? idk
		act := viewObj["act"]
		
		; random sleep
		;~ Random, tPause, 0.0, 4.0
		tPause := NormalRand(0, stdWaitTime, 0)

		GuiControl,, ClickPosIndicator, x = %xClick%`, y = %yClick%`, Action -> %act%, Click Time Offset -> %tPause%s
		Sleep tPause * 1000
		
		ControlClick, x%xClick% y%yClick%, ahk_id %asaGameHwnd%,, left  ; do click
	}
}


switchView(viewName) {
	; This function takes view data and find the corresponding position of the view on the screen and click it
	; it currently only uses coordinate mode; it does not do any image search
	; TODO:
	
	global asaGameHwnd
	global ClickPosIndicator
	
	; check if switch is valid, to-do
	
	clickData := getRandomClick(viewName, ClickPosIndicator)
	xClick := clickData["x"]
	yClick := clickData["y"]
	
	; apply random sleep
	Sleep clickData["delay"] * 1000
	
	ControlClick, x%xClick% y%yClick%, ahk_id %asaGameHwnd%,,left
}

quickTapAnywhere(numClick=10) {
	; generate some quick taps at random positions
	; usually used in after battle stats page
	
	global asaGameHwnd        ; Handle to emulator window
	global ClickPosIndicator  ; next click position
	global WinSize            ; status bar
	
	yBorder := 36 ; constant border px
	
	; base point
	;~ Random, xBase, 562.0, 1000.0
	;~ Random, yBase, 570.0, 670.0
	
	xBase := NormalRand(562, 1000, 0)
	yBase := NormalRand(570, 670, 0)
	
	; TODO: chances to get large offset, 2% percent?
	
	k := 0
	while(k < numClick) {
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
		
		Random, rT, 0.0, 0.5 ; random time interval
		
		xClick := xBase + xRand
		yClick := yBase + yRand + yBorder
		
		GuiControl,, ClickPosIndicator, Click Time Offset -> %rT%s, %xClick% %yClick%
		ControlClick, x%xClick% y%yClick%, ahk_id %asaGameHwnd%,,left  ; do click
		GuiControl,, WinSize, "Click Combo!"
		k++
		
		Sleep rT * 1000
	}
}

getRandomClick(mapDataObj, clickPosIndicator) 
{
	global useCoordDataOnly  ; disable image search, use prepared coord only
	global WinSize
	global mapNodeSelection
	global asaGameHwnd       ; handle to window
	global stdWaitTime       ; standard wait time
	global stdErrorRange     ; limit of click offset
	
	xRand := NormalRand(-stdErrorRange, stdErrorRange, 0)
	yRand := NormalRand(-stdErrorRange, stdErrorRange, 0)
	yBorder := 36
	
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


autoBattle() {
	global asaGameHwnd
	global ClickPosIndicator
	
	yBorder := 36
	
	imgFile := "battleViewWithdraw.png"
	imgWidth = 51
	imgHeight = 33
	
	; region limit
	x1 = 33
	y1 = 21
	x2 = 166
	y2 = 67
	
	
	retryCount := 0
	while(true) {
		; find withdraw image
		;~ WinActivate, ahk_id %asaGameHwnd%
		ImageSearch, imgX, imgY, x1, y1 + yBorder, x2, y2 + yBorder, *50 %imgFile%
	
		if(ErrorLevel = 0) {
			; do clicks here then break while loop
			hW := imgWidth / 2
			hH := imgHeight / 2
			
			x := imgX + hW + 150  ; offset px to AUTO button
			y := imgY + hH
			act := "Auto ▷"
			
			; random sleep
			Random, tPause, 0.0, 4.0
			
			; need to refractor this line
			GuiControl,, ClickPosIndicator, x = %x%`, y = %y%`, Action -> %act%, Click Time Offset -> %tPause%s
			
			Sleep tPause * 1000
			
			ControlClick, x%x% y%y%, ahk_id %asaGameHwnd%,,left  ; do click
			
			break
		}
		
		retryCount++
		GuiControl,, WinSize, % "Image Not Found... re-try: " retryCount
		
		Sleep 500
	}
	
	; offset click on auto
}


checkBattleResult() {
	global asaGameHwnd
	global ClickPosIndicator
	
	yBorder := 36
	
	imgFile := "resultBattleStats.png"
	imgWidth = 98
	imgHeight = 21
	
	; region limit
	x1 = 1137
	y1 = 413
	x2 = 1252
	y2 = 454
	
	retryCount := 0
	while(true) {
		; find battle result image
		;~ WinActivate, ahk_id %asaGameHwnd%
		ImageSearch, imgX, imgY, x1, y1 + yBorder, x2, y2 + yBorder, *5 %imgFile%
	
		if(ErrorLevel = 0) {
			GuiControl,, WinSize, % "Battle Result Confirmed"
			Sleep 1000
			quickTapAnywhere()
			
			break
		}
		
		retryCount++
		GuiControl,, WinSize, % "Waiting For Battle Result... re-try: " retryCount
		
		Sleep 1000
	}
	
	; offset click on auto
}



changeStatusText(currentStatus) {
	global WinSize
	GuiControl,, WinSize, %currentStatus%
	
	return
}

startFromHome() {
	;~ global useCoordDataOnly  ; disable image search, use prepared coord only
	global WinSize
	global homeNode
	global asaGameHwnd
	global returnHomeButton
	global ClickPosIndicator
	
	yBorder := 36
	
	imgFile := returnHomeButton["path"]
	
	retryCount := 0
	while(true) {
		WinActivate, ahk_id %asaGameHwnd%
		ImageSearch, imgX, imgY, homeNode["x1"], homeNode["y1"] + yBorder, homeNode["x2"], homeNode["y2"] + yBorder, *50 %imgFile%
		Sleep 200
		
		if(ErrorLevel = 0) {
			; do clicks here then break while loop
			hW := returnHomeButton["size"]["w"] / 2
			hH := returnHomeButton["size"]["h"] / 2
			
			x := imgX + hW
			y := imgY + hH
			act := returnHomeButton["act"]
			
			; random sleep
			Random, tPause, 0.0, 4.0
			
			; need to refractor this line
			GuiControl,, ClickPosIndicator, x = %x%`, y = %y%`, Action -> %act%, Click Time Offset -> %tPause%s
			
			Sleep tPause * 1000
			
			ControlClick, x%x% y%y%, ahk_id %asaGameHwnd%,,left  ; do click
			
			return true
		}
		
		retryCount++
		GuiControl,, WinSize, % "Image Not Found... re-trying count: " + retryCount
		
		if(retryCount > 5) {
			return false ; assert that game is already at home page
		}
	}
	
	
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


;~ QuickTaps:
;~ quickTapAnywhere()
;~ return