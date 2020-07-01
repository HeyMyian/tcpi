; SCRIPT INFORMATION ============================================================================================================
;
; Script Name:		Twitch Channel Points Integration (tcpi)
; Description:		Redeeming Channel Points on Twitch sends key input to your game, broadcasting software, or plays a sound file
; Filename:			tcpi.ahk
; Script Version:	v0.71
; Modified:			2020-07-01
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
;		Script needs to be restarted after midnight (right click on the icon in system tray > Reload This Script)
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
		ttsfile			:= "O:\Stream\tts.mp3"			; Path where you want your text-to-speech file to sit
		ttslang			:= "en"							; Text-to-speech language code (en, es, de, nl, ...)
		game 			:= "PlanetSide2_x64.exe"		; Your game's exe file
		
		checktime 		:= 200			; Time in milliseconds until the log file is checked for changes again
										; The script only ever reads the last log line, so keep this number fairly low
										; For this reason, there also is no "reward action queue"
;
;
; 4) Twitch Rewards -------------------------------------------------------------------------------------------------------------
;
;		name:		"string"
;					Name of your reward exactly as it appears on Twitch
;
;		type:		game | "globaltrigger" | "tts"
;
;					game
;					Reward's actions will only trigger while the game is active to prevent unwanted keyboard input
;					It's a variable. Set your game's exe under point 3)
;					Reward's sound will always trigger
;
;					"globaltrigger"
;					Reward's actions and sound will always trigger
;					Meant for sound rewards and broadcasting software hotkeys
;					The according hotkeys have to be set up in your broadcasting software as well
;
;					"tts"
;					Text-to-speech
;					This requires "Viewer to Enter Text" in Twitch
;
;		sound:		"string.mp3"
;					Name of the sound file you want to be played
;					In some cases, the sound file will not play no matter what. Try saving the file at lower bitrate
;					There is no volume control per sound file. Sounds tend to come out too loud
;					Either save the sound file at the according volume, or lower the ahk output volume in Windows Volume Mixer
;
;		actions:	"{AHK key}" | "Sleep, duration"
;					Actions to be performed, in the order given
;					List of Keys: https://www.autohotkey.com/docs/KeyList.htm
;					Modifier keys (^ Ctrl, ! Alt, + Shift) tend to not work right, so send the actual keys individually instead
;					If a sequence of keys is seemingly not accepted, "Sleep, 50" (50ms pause) between key presses might help


rewards := []

rewards[0,"name"]	:= "PS2 :: Granada"
rewards[0,"type"]	:= game
rewards[0,"sound"]	:= "granada.mp3"
rewards[0,"actions"]:= [ "{MButton}" ]

rewards[1,"name"]	:= "PS2 :: Tool Slot"
rewards[1,"type"]	:= game
rewards[1,"sound"]	:= "boing.mp3"
rewards[1,"actions"]:= [ "{3}", "Sleep, 1500", "{LButton}" ]

rewards[2,"name"]	:= "PS2 :: v5"
rewards[2,"type"]	:= game
rewards[2,"actions"]:= [ "{v}", "Sleep, 50", "{5}" ]

rewards[3,"name"]   := "PS2 :: Instant Action"
rewards[3,"type"]	:= game
rewards[3,"actions"]:= [ "!{i}" ]

rewards[4,"name"]	:= "Stream :: Rainbow"
rewards[4,"type"]	:= "globaltrigger"
rewards[4,"sound"]	:= "chime.mp3"
rewards[4,"actions"]:= [ "{Ctrl down}", "Sleep, 50", "{Numpad8 down}", "Sleep, 50", "{Ctrl up}", "Sleep, 50", "{Numpad8 up}"
						, "Sleep, 10000", "{Ctrl down}", "Sleep, 50", "{Numpad8 down}", "Sleep, 50", "{Ctrl up}", "Sleep, 50", "{Numpad8 up}" ]
						
rewards[5,"name"]    := "Stream :: Sad"
rewards[5,"type"]	:= "globaltrigger"
rewards[5,"sound"]   := "sad2.mp3"
rewards[5,"actions"] := [ "{Ctrl down}", "Sleep, 50", "{Numpad7 down}", "Sleep, 50", "{Ctrl up}", "Sleep, 50", "{Numpad7 up}"
						, "Sleep, 10000", "{Ctrl down}", "Sleep, 50", "{Numpad9 down}", "Sleep, 50", "{Ctrl up}", "Sleep, 50", "{Numpad9 up}" ]
						
rewards[6,"name"]    := "PS2 :: F"
rewards[6,"type"]	:= game
rewards[6,"sound"]   := "boing.mp3"
rewards[6,"actions"] := [ "{F}" ]

rewards[7,"name"]	:= "TTS"
rewards[7,"type"]	:= "tts"


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
		; this checks if the 23rd character is an opening bracket. look at your chatlog file to understand why
		If (SubStr(lastline,23,2)="[P") {

			; cycle through each reward in the array
			For Each, reward in rewards {
			
				; do the thing where the reward name matches the last line
				If (InStr(lastline, reward.name)) {
				
					; in case a sound file is specified, play that.
					If (reward.sound!="") {
						;SoundPlay, % soundfolder . "\" . reward.sound, Wait
						SoundPlay, % soundfolder . "\" . reward.sound
					}
				
					; in case there are actions specified
					If (reward.actions!="") {
					
						; game must be focused, or it's a hotkey for broadcasting software
						If (((reward.type=game)&&(WinActive("ahk_exe" . game))) or (reward.type="globaltrigger")) {
						
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
					
					; in case the thing is tts
					If (reward.type=="tts") {
					
						tts := lastline

						RegExMatch(tts, "(?<=\)\s\[)([\s\!-\x{00FF}]*)(?=\])", tts)
						;MsgBox, %tts%
						;tts := UriEncode(tts)
						;MsgBox, %tts%
						 
						; Modified from http://goo.gl/0a0iJq
						UriEncode(Uri)
						{
							Res := ""
							VarSetCapacity(Var, StrPut(Uri, "UTF-8"), 0) 
							StrPut(Uri, &Var, "UTF-8")
							f := A_FormatInteger
							SetFormat, IntegerFast, H
							While Code := NumGet(Var, A_Index - 1, "UChar")
								If (Code >= 0x30 && Code <= 0x39 ; 0-9
									|| Code >= 0x41 && Code <= 0x5A ; A-Z
									|| Code >= 0x61 && Code <= 0x7A ; a-z
									|| Code == 0x2B) ; +
									Res .= Chr(Code)
								Else
									Res .= "%" . SubStr(Code + 0x100, -1)
							SetFormat, IntegerFast, %f%
							Return, Res
						}

						UrlDownloadToFile, https://translate.google.com/translate_tts?ie=UTF-8&tl=%ttslang%&client=tw-ob&q=%tts%, %ttsfile%
						Soundplay, %ttsfile%, Wait ; plays the downloaded speech file and waits for it to finish
					
					}
				}
			}				
		}
	}
	Return
