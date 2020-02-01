; SCRIPT INFORMATION ============================================================================================================
;
; Script Name:		Twitch Channel Points Integration (tcpi)
; Description:		Redeeming Channel Points on Twitch sends key input to your game, broadcasting software, or plays a sound file
; Filename:			tcpiv05.ahk
; Script Version:	v0.5
; Modified:			2020-02-01
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
; 		Run this script as administrator. It's now in your system tray.
;
;
; 2) Chatty ---------------------------------------------------------------------------------------------------------------------
;
; 		This script is configured to be used with Chatty logfiles. Download Chatty here: https://chatty.github.io/
; 		Chatty must run on your computer and it must have "Log to file" enabled. You find the settings here:
; 		Main > Settings > Chat > Log to file
;
; 		1. Add only your channel to the list of channels to be logged
;		2. Select a folder where the log files should be saved
;		3. In the column for "Message Types", at least "Chat Info" needs to be selected
;		4. Unselect everything else if you don't need chat logs otherwise and want the most lightweight script
;		5. Recommended Split Logs: Daily
;		6. Uncheck "Lock files", otherwise AHK can't read the file
;		7. Timestamp: [2020-01-26 13:56:33]
;
;
; 3) Variables ------------------------------------------------------------------------------------------------------------------
;
; 		Change these variables to match your environment:
;
		logfolder 		:= "O:\Stream\logs"				; The folder where your log files are stored. Last modified file is used
		soundfolder 	:= "O:\Stream\soundbits"		; The folder where your sound files are stored
		game 			:= "PlanetSide2_x64.exe"		; Your game's exe file
		checktime 		:= 200			; Time in milliseconds until the log file is checked for changes again
										; The script only ever reads the last log line, so keep this number fairly low
										; For this reason, there also is no "reward action queue"
;
;
; 4) Twitch rewards ---------------------------------------------------------------------------------------------------------
;
;		name:		"string"
;					Name of your reward as it appears in Twitch

;		type:		game | "sound" | "hotkey"
;
;					game
;					Reward's actions will only trigger while the game is active to prevent unwanted keyboard input
;					It's a variable. Set your game's exe under point 3)
;					Reward's sound will always trigger
;
;					"sound"
;					Reward is only a sound. Will always trigger
;
;					"hotkey"
;					Reward's actions and sound will always trigger, meant for broadcasting software hotkeys
;					The according hotkeys have to be set up in your broadcasting software as well

;		sound:		"string"
;					Name of the sound file you want to be played
;					In some cases, the sound file will not play no matter what. Try saving the file at lower bitrate
;					There is no volume control per sound file. Sounds tend to come out too loud
;					Either save the sound file at the according volume, or lower the ahk output volume in Windows Volume Mixer

;		actions:	"{AHK key}" | "Sleep, duration"
;					Actions to be performed, in the order given
;					List of Keys: https://www.autohotkey.com/docs/KeyList.htm
;					Modifier keys (^ Ctrl, ! Alt, + Shift) seem to not work right, so send the actual keys individually instead
;					If a game does not accept a sequence of keys, a short 50ms Sleep between key presses might do the trick


rewards := []

; Example reward with sound file and key input in a game (Space bar)
rewards[0,"name"]	:= "Reward Name"
rewards[0,"type"]	:= game
rewards[0,"sound"]	:= "yoursoundfile.mp3"
rewards[0,"actions"]:= [ "{Space}" ]

; Example reward with sound file
rewards[1,"name"]	:= "Sound Reward"
rewards[1,"type"]	:= "sound"
rewards[1,"sound"]	:= "boing.mp3"

; Example reward with multiple key input in a game (v, short pause, 4)
rewards[2,"name"]	:= "Another Reward"
rewards[2,"type"]	:= game
rewards[2,"actions"]:= [ "{v}", "Sleep, 50", "{4}" ]

; Example reward triggers a sound and a hotkey meant for your broadcasting software
rewards[3,"name"]	:= "Hotkey Reward"
rewards[3,"type"]	:= "hotkey"
rewards[3,"sound"]	:= "yoursoundfile.mp3"
rewards[3,"actions"]:= [ "{Alt down}", "Sleep, 50", "{Numpad7 down}", "Sleep, 50", "{Alt up}", "Sleep, 50", "{Numpad7 up}" ]

; add more rewards by copying one of the above and increasing the number


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
		; this checks if the 23rd chracter is an opening bracket. look at your chatlog file to understand why
		If (SubStr(lastline,23,1)="[") {

			; cycle through each reward in the array
			For Each, reward in rewards {
			
				; do the thing where the reward name matches the last line
				If (InStr(lastline, reward.name)) {
				
					; in case a sound file is specified, play that.
					If (reward.sound!="") {
						SoundPlay, % soundfolder . "\" . reward.sound
					}
				
					; in case there are actions specified
					If (reward.actions!="") {
					
						; game must be focused, or it's a hotkey for broadcasting software
						If ((reward.type=game)&&(WinActive("ahk_exe" . game)) or (reward.type="hotkey")) {
					
							; cycle through the actions
							For Each, action in reward.actions {
							
								; sleep between keys, sometimes important for applications to pick up input
								If InStr(action,"Sleep,") {
									el_sleep := StrSplit(action, ",")
									Sleep, el_sleep[2]
								}
								
								; keypress
								Else {											
									SendInput, % action
								}
							}
						}
					}
				}
			}				
		}
	}
	Return
