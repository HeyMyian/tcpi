; SCRIPT INFORMATION ============================================================================================================
;
; Script Name:		Twitch Channel Points Integration (tcpi)
; Description:		Redeeming Channel Points on Twitch sends key input to your game, broadcasting software, or plays a sound file
; Filename:			tcpi.ahk
; Script Version:	v0.3
; Modified:			2020-01-26
; AHK Version:		v1.1.24.01 - August 2, 2016
; Author:			Myian <heymyian@gmail.com> <https://twitch.tv/myian>
;
;
;
; INSTRUCTIONS ==================================================================================================================
;
; 1) AutoHotkey -----------------------------------------------------------------------------------------------------------------
;
; 		Download AutoHotkey here: https://www.autohotkey.com/ and install.
; 		Run this script as administrator by double-clicking on the file. It's now in your system tray.
;
;
; 2) Chatty ---------------------------------------------------------------------------------------------------------------------
;
; 		This script is configured to be used with Chatty logfiles. Download Chatty here: https://chatty.github.io/
; 		Chatty must run on your computer and it must have "Log to file" enabled. You find the settings here:
; 		Main > Settings > Chat > Log to file
;
; 		1. Add only your channel to the list of channels to be logged
;			2. Select a folder where the log files should be saved
;			3. In the column for "Message Types", at least "Chat Info" needs to be selected
;			4. Unselect everything else if you don't need chat logs otherwise and want the most lightweight script
;			5. Recommended Split Logs: Daily
;			6. Uncheck "Lock files", otherwise AHK can't read the file
;			7. Timestamp: [2020-01-26 13:56:33]
;
;
; 3) Variables ------------------------------------------------------------------------------------------------------------------
;
; 		Change these variables to match your environment:
;
		logfolder 		:= "O:\Stream\logs"				; The folder where your log files are stored. Last modified file is used
		soundfolder 	:= "O:\Stream\soundbits"		; The folder where your sound files are stored
		game 			:= "PlanetSide2_x64.exe"		; Your game's exe file
		obs				:= "obs64.exe"					; Your broadcasting software exe file (only tested with OBS)
		checktime 		:= 100			; Time in milliseconds until the log file is checked for changes again
										; The script only ever reads the last log line, so keep this number fairly low
		activategame	:= 1			; 1 allows the script to focus your game when the redemption happens. 0 disables this
;
;
; 4) Twitch Redemptions ---------------------------------------------------------------------------------------------------------
;
;		name:		Name of your Redemption as it appears in Twitch

;		sound:		Name of the sound file you want to be played

;		app:		game | obs
;					If a redemption should happen in the game or in your broadcasting software
;					The according hotkeys have to be set up in the broadcsting software as well

;		actions:	Actions to be performed, in the order given
;					List of Keys: https://www.autohotkey.com/docs/KeyList.htm
;					If a game does not accept a sequence of keys, a short 50ms Sleep between key presses might do the trick
;
; 		The weird line breaks are on purpose. Don't change unless you know what you are doing
;
		redemptions 
			:= [{ 	 name: "PS2 Integration :: Granada"
					,sound: "granada.mp3"
					,app: game
					,actions :[ "{MButton down}", "{MButton up}" ] }
						
			, { 	 name: "PS2 Integration :: Use Tool"
					,sound: "boing.mp3"
					,app: game
					,actions :[ "{3 down}", "{3 up}", "Sleep, 1500", "{LButton down}", "{LButton up}" ] }
						
			, { 	 name: "Stream Integration :: Sad"
					,sound: "sad2.mp3"
					,app: obs
					,actions :[ "^!{k}"	] }

			, { 	 name: "PS2 Integration :: v6"
					,sound: "ding.mp3"
					,app: game
					,actions :[ "{v down}", "{v up}", "Sleep, 100", "{6 down}", "{6 up}" ] } ]


; ===============================================================================================================================
; ===============================================================================================================================
;
; 		Only change the code from here if you know what you are doing
; 		Some comments are provided to explain what is going on
;
; ===============================================================================================================================
; ===============================================================================================================================

#Persistent
#SingleInstance Force
#NoEnv
#Warn
SendMode Input
filesize1 := ""
filesize2 := ""
Time := ""

; get last modified, presumably current, log file in the folder
Loop %logfolder%\*.*
	If ( A_LoopFileTimeModified >= Time )
		Time := A_LoopFileTimeModified, logfile := A_LoopFileLongPath

; get this file's size in bits
FileGetSize, filesize1, %logfile%

; do the thing
SetTimer, checkfile, %checktime%
Return

; the thing
checkfile:

	; get file size again, stored in different variable
	FileGetSize, filesize2, %logfile%
	
	; compare the file sizes. if they differ, the file has been updated since the last check
	If(filesize1 != filesize2) {
	
		filesize1 := filesize2
	
		; get last line
		Loop, read, %logfile% 
		{
			lastline := A_LoopReadLine
		}
		
		; change this line if you use a different timestamp format or a different chat logger altogether
		; this checks if the 23rd chracter on the last line is an opening bracket. look at your log file to understand why
		If (SubStr(lastline,23,1)="[") {

			; cycle through each redemption in the array
			For Each, redemption in redemptions {

				; do the thing where the redemption name matches the last line
				If (InStr(lastline, redemption.name)) {
				
					; in case there are actions specified
					If (redemption.actions!="") {
					
						; in case you allow the script to bring the game to front
						If (activategame=1) {

							; if tabbed out of the game
							If (redemption.app=game)&&(!WinActive("ahk_exe" . game)) {
							
								; bring game to front
								WinActivate, ahk_exe %game%
								
								; and center the mouse cursor
								WinGetPos,,, width, height, A
								center_x := width/2
								center_y := height/2
								MouseMove, center_x, center_y
								
								; Workaround for activating mouse clicks in PS2
								If (game="PlanetSide2_x64.exe") { 
									Send {Alt}
								}
							}
						}
						
						; cycle through the actions
						For Each, action in redemption.actions {
							
							; keypress
							If InStr(action,"{") {
							
								; keypress in game, assuming game is focused
								; if game is not focused, and you don't want this script to focus the game,
								; try analogous the below ControlSend
								; ControlSend doesn't work in every application
								If (redemption.app=game) {
									SendInput, %action%
								}
								
								; keypress in broadcasting software
								; using ControlSend to send keys to background program
								If (redemption.app=obs) {
									ControlSend,, %action%, ahk_exe %obs%
								}
							}
							
							; sleep between keys, sometimes important for applications to pick up input
							Else If InStr(action,"Sleep,") {
								el_sleep := StrSplit(action, ", ")
								Sleep, el_sleep[2]
							}
						}
					}
					
					; in case a sound file is specified, play that.
					; there is no volume control per file. sounds tend to come out too loud
					; either lower the ahk volume in Windows, or save the sound files at the correct volume
					If (redemption.sound!="") {
						SoundPlay, % soundfolder . "\" . redemption.sound
					}
				}
			}				
		}
	}
	Return
