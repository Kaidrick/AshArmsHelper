#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include Lib\MapLib.ahk
#Include Lib\JSON.ahk

matchOptions(descInfo) {
	FileRead, optionJson, UnitOptionData.json
	optionData := JSON.Load(optionJson)
	
	;~ takes in a description entry provided in flow file
	descInfo := StrSplit(descInfo, ",")
	
	;~ for instance: MC.200/INTC,F4F/AIRS,Hurricane/RECC
	wStr := ""
	
	a1 := StrSplit(descInfo[2], "/")[2]  ;~ Option of Air Unit #1
	if (a1 != "") {
		optionImgPath := optionData[a1]
		if(!existImage(optionImgPath,255,276,296,317,100,2)) {
			wStr := wStr "Wrong Unit Option -> Air Unit #1 -> " a1 "`n"
		}
	}
	
	a2 := StrSplit(descInfo[3], "/")[2]  ;~ Option of Air Unit #2
	if (a2 != "") {
		optionImgPath := optionData[a2]
		if(!existImage(optionImgPath,399,276,440,317,100,2)) {
			wStr := wStr "Wrong Unit Option -> Air Unit #2 -> " a2 "`n"
		}
	}
	
	a3 := StrSplit(descInfo[4], "/")[2]  ;~ Option of Air Unit #3
	if (a3 != "") {
		optionImgPath := optionData[a3]
		if(!existImage(optionImgPath,544,276,584,317,100,2)) {
			wStr := wStr "Wrong Unit Option -> Air Unit #3 -> " a3 "`n"
		}
	}
	
	a4 := StrSplit(descInfo[5], "/")[2]  ;~ Option of Air Unit #4
	if (a4 != "") {
		optionImgPath := optionData[a4]
		if(!existImage(optionImgPath,688,276,728,317,100,2)) {
			wStr := wStr "Wrong Unit Option -> Air Unit #4 -> " a4 "`n"
		}
	}
	
	;~ TODO: add checks for ground units
	g1 := StrSplit(descInfo[6], "/")[2]
	if (g1 != "") {
		optionImgPath := optionData[g1]
		if(!existImage(optionImgPath,255,493,297,534,100,2)) {
			wStr := wStr "Wrong Unit Option -> Ground Unit #1 -> " g1 "`n"
		}
	}
	
	g2 := StrSplit(descInfo[7], "/")[2]
	if (g2 != "") {
		optionImgPath := optionData[g2]
		if(!existImage(optionImgPath,399,494,441,533,100,2)) {
			wStr := wStr "Wrong Unit Option -> Ground Unit #2 -> " g2 "`n"
		}
	}
	
	g3 := StrSplit(descInfo[8], "/")[2]
	if (g3 != "") {
		optionImgPath := optionData[g3]
		if(!existImage(optionImgPath,543,493,585,535,100,2)) {
			wStr := wStr "Wrong Unit Option -> Ground Unit #3 -> " g3 "`n"
		}
	}
	
	g4 := StrSplit(descInfo[9], "/")[2]
	if (g4 != "") {
		optionImgPath := optionData[g4]
		if(!existImage(optionImgPath,688,494,727,534,100,2)) {
			wStr := wStr "Wrong Unit Option -> Ground Unit #4 -> " g4 "`n"
		}
	}
	
	if (wStr = "") {
		changeStatusText("Units Option Check...Pass")
	} else {
		changeStatusText("Units Option Check...Fail")
		MsgBox % wStr
		changeStatusText("Script will stop now.")
		;~ stop the script
		BigSwitchOff()
	}
	
	
}

