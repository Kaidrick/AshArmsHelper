#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include Lib\MapLib.ahk

dollImgPath := A_ScriptDir "\data\img\doll_intel\*.bmp"
matsImgPath := A_ScriptDir "\data\img\items\*.bmp"

dollRelativePath := "\doll_intel\"
matsRelativePath := "\items\"


collectDollDropData() {
	global resx
	global canRun
	global dollImgPath
	global dollRelativePath
	
	path := dollImgPath
	
	idx := 0
	total := 0
	drops := ""
	
	Loop %path% {
		total := total + 1
	}

	Loop %path% {
		idx := idx + 1
		dollName := StrSplit(A_LoopFileName, ".")[1]
		changeStatusText(resx["status_MatchingDrops"] "#" idx " " dollName )
		;~ if (existFuzzImage(dollRelativePath A_LoopFileName,228,197,1093,564,10,2,50)) {
		if (existFuzzImage(dollRelativePath A_LoopFileName,228,197,1093,564,5,1,100)) {
			if(drops = "") {
				drops := drops dollName
			} else {  ;~ has content
				drops := drops "," dollName
			}
		}
	}
	
	return drops
}

collectMatsDropData() {
	global resx
	global canRun
	global matsImgPath
	global matsRelativePath
	
	path := matsImgPath
	
	idx := 0
	total := 0
	drops := ""
	
	Loop %path% {
		total := total + 1
	}
	
	Loop %path% {
		idx := idx + 1
		matsName := StrSplit(A_LoopFileName, ".")[1]
		changeStatusText(resx["status_MatchingDrops"] "#" idx " " matsName )
		if (existFuzzImage(matsRelativePath A_LoopFileName,228,197,1093,564,5,1,110)) {
			if(drops = "") {
				drops := drops matsName
			} else {  ;~ has content
				drops := drops "," matsName
			}
		}
	}
	
	return drops
}