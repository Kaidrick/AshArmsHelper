; Simulated Human Behaviors
simulateRandomBehavior() {
	; This function is used to simulate human behavior such as bio break or afk
	
	; other possible behavior:
	; 1. check other pages
	; 2. go to wrong pages and mis-touch
	; 3. 
	
	global WinSize
	global asaGameHwnd
	global ClickPosIndicator
	
	behavior := getRandomBehavior()
	baseLength := behavior["pauseLength"]
	Random, fraction, 0.00, 1.00
	fBehaviorLength := baseLength + (baseLength / 4) * fraction
	
	;~ MsgBox % "Triggered behavior: " behavior["name"] ", base pause time is " baseLength " seconds, processed pause time is " fBehaviorLength
	
	GuiControl,, ClickPosIndicator, % "Triggered behavior: " behavior["name"] ", base time " baseLength "s, processed pause time " fBehaviorLength "s"
	
	Sleep fBehaviorLength * 1000  ; to milliseconds1 / 60
	
	return
}

getRandomBehavior() {
	; This function is used to generate a behavior
	; it returns enum object, and this object contains behavior name and break time
	Random, hP, 0.00, 1.00  ; uniformly generate a number between 0 and 1
	if (hP >= 0 && hP < 0.02) {  ; 2% rate to drink
		return {name: "drink", pauseLength: 180}
	} else if (hP >= 0.02 && hP < 0.025) {  ; 0.5% rate to eat
		return {name: "eat", pauseLength: 600}
	} else if (hP >= 0.025 && hP < 0.100) {  ; 7.5% rate to pause short
		return {name: "pause short", pauseLength: 30}
	} else if (hP >= 0.100 && hP < 0.150) {  ; 5% rate to pause long
		return {name: "pause long", pauseLength: 60}
	} else if (hP >= 0.150 && hP < 0.165) {  ; 1.5% rate to pause extremely long
		return {name: "pause extreme", pauseLength: 90}
	} else {  ; 83.5% rate to continue grinding
			  ; maybe also add time specific behaviors, such as night mode
			  
		; do nothing at all, let the flow continue
		return {name: "continue", pauseLength: 0}
	}
}


;~ simulateRandomBehavior()


awayFromKeyBoard = {rate: 0}  ; at least half an hour or so
outDoor = {rate: 0}  ; at least an hour or so

; Miscellaneous activities
checkStorage = {}
checkMissionBoard = {}
changeTeamAssignment = {}


;~ MsgBox, % rand_gaussian(3, 10)


; Guassian distribution generator
rand_gaussian(standard_deviation, mean=0, overflow_error=true) ; by berban - https://www.autohotkey.com/boards/viewtopic.php?f=6&t=67066
{
	Static table_file := "ztable.txt" ; put whatever path you stored the table at
	Static ztable
	if (ztable = "") {
		; build the table. source: https://en.wikipedia.org/wiki/Standard_normal_table#Cumulative_from_mean_(0_to_Z)
		If FileExist(table_file) {
			ztable := []
			Loop, Read, %table_file%
				ztable[SubStr(A_LoopReadLine, 1, InStr(A_LoopReadLine, A_Tab) - 1)] := SubStr(A_LoopReadLine, InStr(A_LoopReadLine, A_Tab) + 1)
		} else
			MsgBox, 262160, , Table file not found!`n`nSearch path:%table_file%
	}
	Random, r, 0, 099999 ; this is the precision of the list on wikipedia
	r := r / 100000 + 1 / 200000
	If (r > 0.5)
		r -= 0.5, positive := true
	lastKey := 0.00
	For a,b in ztable
		If (b > r)
			Return mean + standard_deviation * (positive ? 1 : -1) * (lastKey * (b - r) + a * (r - ztable[lastKey])) / (b - ztable[lastKey]) ; perform linear interpolation between the two closest values
		Else
			lastKey := a
	If overflow_error
		MsgBox, 262160, , Overflow! Those are some crazy odds!
	else
		Return mean + standard_deviation * (positive ? 1 : -1) * 4.10 ; 4.10 is the next value beyond what the table provides
}