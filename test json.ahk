#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include JSON.ahk

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

;~ testJsonStr = {"mapCampaign":{"x":817,"y":252,"path":"mainPage_CapaignMap.png","offset":{"x":0,"y":-22},"size":{"w":145,"h":121},"act":"出撃"},"orderReady":{"x":1048,"y":654,"path":"mapSel_OrderReady.png","offset":{"x":75,"y":-48},"size":{"w":58,"h":64},"act":"ステージ情報 出撃"},"affirmReady":{"x":1041,"y":664,"path":"preStage_Consumption.png","offset":{"x":382,"y":-5},"size":{"w":26,"h":31},"act":"出撃準備 確認"},"autoBattle":{"x":234,"y":42,"path":"battleViewWithdraw.png","offset":{"x":158,"y":0},"size":{"w":51,"h":33},"act":"Auto ▷"},"resultBattleStats":{"x":-1,"y":-1,"path":"resultBattleStats.png","offset":{"x":0,"y":0},"size":{"w":0,"h":0},"act":"Battle Result Check","override":"quick taps"},"tapAnywhere":{"x":642,"y":73,"act":"Quick Taps"},"returnArrowButton":{"x":60,"y":40,"act":"Return to Previous Page"},"returnHomeButton":{"x":1226,"y":50,"path":"homePage.png","offset":{"x":0,"y":0},"size":{"w":26,"h":30},"type":"returnHome","act":"Return to Home Page"},"refreshPlayerData":{"x":0,"y":0,"path":"Error_RefreshPlayerData.png","offset":{"x":167,"y":164},"size":{"w":195,"h":40},"act":"RefreshPlayerData Error"},"networkError":{"x":0,"y":0,"path":"Error_NetWork.png","offset":{"x":167,"y":164},"size":{"w":208,"h":36},"act":"Network Error"},"connectionError":{"x":0,"y":0,"path":"Error_Connection.png","offset":{"x":258,"y":165},"size":{"w":247,"h":38},"act":"Connection Error"}}

;~ MsgBox % testFile




MsgBox % allData["mapSel_03A02N"]["path"]