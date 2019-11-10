#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; import Gdip libs for image search
#Include Gdip_All.ahk
#Include Gdip_ImageSearch.ahk
#Include HumanBehaviors.ahk

; Functions
p := Gdip_Startup()

findClick(viewObjName, abortCount=1000, waitInterval=500, canSimulateHumanBehavior=false) {
	global asaGameHwnd
	global ClickPosIndicator
	global stdWaitTime
	global stdErrorRange
	global WinSize 
	global refreshPlayerData
	global canRun
	global allData
	
	yBorder = 36
	
	viewObj := allData[viewObjName]
	
	retryCount = 0
	while(true) {
		if(!canRun) {
			;~ MsgBox, cancelling
			return
		}
		
		checkForError()  ; dealing with errors
		
		pBitmapHayStack := Gdip_BitmapFromHWND(asaGameHwnd)

		pBitmapNeedle := Gdip_CreateBitmapFromFile(viewObj["path"])

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
						quickTapAnywhere()
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
			
			changeStatusText("Searching for [" viewObj["path"] "]...success!")
			
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
		GuiControl,, WinSize, % "Searching for [" viewObj["path"] "], iters:" retryCount
		Sleep waitInterval
		
		if (retryCount >= abortCount) {
			; abort
			changeStatusText("Search limit reached for " viewObj["path"] "...skip")
			return
		}
		
		; IMPORTANT: if unable to find target images after multiple iteration, maybe the draw need to be updated
		; drag the screen a little bit, or go back to previous page to let the screen to be redraw
		
	}
}


checkForError() {
	; TODO: three different images are searched. need this refractoring badly
	
	global asaGameHwnd
	global ClickPosIndicator
	global stdWaitTime
	global stdErrorRange
	global WinSize 
	
	global refreshPlayerData
	global networkError
	global connectionError
	
	global allData
	
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
		Sleep tPause * 1000
		
		ControlClick, x%xClick% y%yClick%, ahk_id %asaGameHwnd%,, left  ; do click
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
		yClick := y + hH + yOffset + yRand ;+ yBorder  ; maybe yBorder is not needed when using gdip? idk
		act := viewObj["act"]
		
		; random sleep
		tPause := NormalRand(0, stdWaitTime, 0)

		GuiControl,, ClickPosIndicator, Action: %act%`nX: %xClick% / Y: %yClick%`nClick Delay: %tPause%s
		Sleep tPause * 1000
		
		ControlClick, x%xClick% y%yClick%, ahk_id %asaGameHwnd%,, left  ; do click
	}
	
	; Check for Connection Error
	pBitmapNeedle_connectionError := Gdip_CreateBitmapFromFile(connectionError["path"])
	result_connectionError := Gdip_ImageSearch(pBitmapHayStack,pBitmapNeedle_connectionError,OutputList,eX1,eY1,eX2,eY2,60,0,1,1)
	
	; try freeing vars
	Gdip_DisposeImage(pBitmapNeedle_connectionError)
	
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
		tPause := NormalRand(0, stdWaitTime, 0)

		GuiControl,, ClickPosIndicator, Action: %act%`nX: %xClick% / Y: %yClick%`nClick Delay: %tPause%s
		Sleep tPause * 1000
		
		ControlClick, x%xClick% y%yClick%, ahk_id %asaGameHwnd%,, left  ; do click
	}
	
	; free bmp from handle to window
	Gdip_DisposeImage(pBitmapHayStack)
}



quickTapAnywhere(numClick=20) {
	; generate some quick taps at random positions
	; usually used in after battle stats page
	
	global asaGameHwnd        ; Handle to emulator window
	global ClickPosIndicator  ; next click position
	global WinSize            ; status bar
	global allData            ; click data
	
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



changeStatusText(currentStatus) {
	global WinSize
	GuiControl,, WinSize, %currentStatus%
	
	return
}

ExecClick(actName, pX, pY, delay, canSimulateHumanBehavior) {
	global ClickPosIndicator
	global canRun
	global asaGameHwnd
	
	GuiControl,, ClickPosIndicator, Action: %actName%`nX: %pX% / Y: %pY%`nDelay: %delay%s
	
	if (canSimulateHumanBehavior) {
		simulateRandomBehavior()  ; more reasonable because usually i put it game on auto and switch to other task but forgot about it for a while
	}
	
	Sleep delay * 1000
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
