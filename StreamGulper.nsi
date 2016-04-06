SetCompressor /SOLID lzma
Name "Stream Gulper"
OutFile "StreamGulper.exe"
ReserveFile "${NSISDIR}\Plugins\InstallOptions.dll"
ReserveFile "StreamGulper.ini"
!define TEMP1 $R9
Caption "Stream Gulper"
BrandingText "Created by Andrew Y. (andryou)"
Icon "StreamGulper.ico"
InstallButtonText "Download"
MiscButtonText "Back" "Next" "Close"
!include "FileFunc.nsh"
!include "LogicLib.nsh"
!insertmacro GetTime

Page custom SetCustom ValidateCustom
Page instfiles

Section "Components"
	Var /GLOBAL inputurl
	Var /GLOBAL downloadurl
	Var /GLOBAL outputpath
	Var /GLOBAL outputname
	Var /GLOBAL baseoutputname
	Var /GLOBAL fileextension
	Var /GLOBAL error
	SetAutoClose true
	ReadINIStr ${TEMP1} "$PLUGINSDIR\StreamGulper.ini" "Field 3" "State"
	StrCpy $inputurl ${TEMP1}
	ReadINIStr ${TEMP1} "$PLUGINSDIR\StreamGulper.ini" "Field 5" "State"
	StrCpy $outputpath ${TEMP1}
	DetailPrint "Extracting files..."
	SetOutPath $TEMP
		File /r "andryoustreamdl"
	nsExec::ExecToStack '"$TEMP\andryoustreamdl\LiveStreamer\youtube-dl.exe" --restrict-filenames -g --get-filename "$inputurl"'
		Pop $0
		Pop $1
		StrCpy $error $1
		Push "$\n"
		Push $1
		Call SplitFirstStrPart
		Pop $R1
		Pop $R2
		StrCmp $R2 "" error
		Push $R1
		Call Trim
		Pop $R1
		Push $R2
		Call Trim
		Pop $R2
		${GetTime} "" "L" $0 $1 $2 $3 $4 $5 $6
		StrCpy $downloadurl $R1
		StrCpy $outputname $2$1$0_$4$5$6-$R2
		Push $outputname
		Push "."
		Call GetAfterChar
		Pop $fileextension
		StrLen $R1 $fileextension
		IntOp $R1 $R1 + 1
		IntOp $R1 $R1 * -1
		StrCpy $baseoutputname $outputname $R1
		StrLen $R1 "$outputpath\$outputname"
		${If} $R1 > 255
			IntOp $R2 255 - $R1
			StrCpy $baseoutputname $baseoutputname $R2
			;MessageBox MB_OK 'NOTE: the output filename will automatically be truncated.'
		${EndIf}
		StrCpy $error ""
		;MessageBox MB_OK '"$outputpath\$outputname" "x://$downloadurl"'
		DetailPrint "> Video Address: $inputurl"
		DetailPrint "> Download Address: $downloadurl"
		DetailPrint "> Output Folder: $outputpath"
		DetailPrint "> Output Name: $outputname"
		DetailPrint "(1/9) Attempting HTTP method..."
		nsExec::Exec '$TEMP\andryoustreamdl\LiveStreamer\livestreamer.exe -f -o "$outputpath\$outputname" "httpstream://$downloadurl" best'
		IfFileExists "$outputpath\$outputname" 0 othermethods
		FileOpen $4 "$outputpath\$outputname" r
		FileRead $4 $1 7
		FileClose $4
		StrCmp $1 "#EXTM3U" othermethods success
		othermethods:
			DetailPrint "(2/9) Attempting HLS method..."
			nsExec::Exec '$TEMP\andryoustreamdl\LiveStreamer\livestreamer.exe -f -o "$outputpath\$outputname" "hls://$downloadurl" best'
			IfFileExists "$outputpath\$outputname" success
			DetailPrint "(3/9) Attempting HLS Variant method..."
			nsExec::Exec '$TEMP\andryoustreamdl\LiveStreamer\livestreamer.exe -f -o "$outputpath\$outputname" "hlsvariant://$downloadurl" best'
			IfFileExists "$outputpath\$outputname" success
			DetailPrint "(4/9) Attempting HDS method..."
			nsExec::Exec '$TEMP\andryoustreamdl\LiveStreamer\livestreamer.exe -f -o "$outputpath\$outputname" "hds://$downloadurl" best'
			IfFileExists "$outputpath\$outputname" success
			DetailPrint "(5/9) Attempting AkamaiHD method..."
			nsExec::Exec '$TEMP\andryoustreamdl\LiveStreamer\livestreamer.exe -f -o "$outputpath\$outputname" "akamaihd://$downloadurl" best'
			IfFileExists "$outputpath\$outputname" success
			DetailPrint "(6/9) Attempting RTMP method..."
			nsExec::Exec '$TEMP\andryoustreamdl\LiveStreamer\livestreamer.exe -f -o "$outputpath\$outputname" "rtmp://$downloadurl" best'
			IfFileExists "$outputpath\$outputname" success
			DetailPrint "(7/9) Attempting RTMPS method..."
			nsExec::Exec '$TEMP\andryoustreamdl\LiveStreamer\livestreamer.exe -f -o "$outputpath\$outputname" "rtmps://$downloadurl" best'
			IfFileExists "$outputpath\$outputname" success
			DetailPrint "(8/9) Attempting RTMPT method..."
			nsExec::Exec '$TEMP\andryoustreamdl\LiveStreamer\livestreamer.exe -f -o "$outputpath\$outputname" "rtmpt://$downloadurl" best'
			IfFileExists "$outputpath\$outputname" success
			DetailPrint "(9/9) Attempting RTMPTE method..."
			nsExec::Exec '$TEMP\andryoustreamdl\LiveStreamer\livestreamer.exe -f -o "$outputpath\$outputname" "rtmpte://$downloadurl" best'
			IfFileExists "$outputpath\$outputname" success
			goto error
	success:
		ReadINIStr $0 "$PLUGINSDIR\StreamGulper.ini" "Field 7" "State"
		StrCmp $0 1 checkformat checksubs
		checkformat:
			StrCmp $fileextension "mp4" checksubs
			DetailPrint "Converting to MP4..."
			nsExec::Exec '$TEMP\andryoustreamdl\ffmpeg\ffmpeg.exe -y -i "$outputpath\$outputname" -vcodec copy -acodec copy -bsf aac_adtstoasc "$outputpath\$baseoutputname.mp4"'
			ReadINIStr $0 "$PLUGINSDIR\StreamGulper.ini" "Field 8" "State"
			StrCmp $0 1 checksubs
			Delete "$outputpath\$outputname"
		checksubs:
			ReadINIStr $0 "$PLUGINSDIR\StreamGulper.ini" "Field 9" "State"
			StrCmp $0 1 downsubs exit
			downsubs:
				DetailPrint "Checking for and downloading all possible subtitles..."
				nsExec::Exec '"$TEMP\test\LiveStreamer\youtube-dl.exe" --restrict-filenames --skip-download --all-subs "$inputurl" -o "andryoustreamdl\subs\subtitles"'
				RMDir '$TEMP\andryoustreamdl\subs'
				IfFileExists '$TEMP\andryoustreamdl\subs' copysubs exit
				copysubs:
					DetailPrint "Converting downloaded subtitles..."
					nsExec::Exec '$TEMP\andryoustreamdl\SubtitleEdit\SubtitleEdit.exe /convert "$TEMP\andryoustreamdl\subs\*.*" SubRip /outputfolder:andryoustreamdl\subsout'
					nsExec::Exec '$TEMP\andryoustreamdl\subsout\subrename.bat "$baseoutputname" "andryoustreamdl\subsout"'
					CopyFiles '$TEMP\andryoustreamdl\subsout\*.srt' '$outputpath'
					goto exit
	error:
		StrCmp $error "" +2 0
		MessageBox MB_OK '$error'
		goto cleanup
		MessageBox MB_OK 'ERROR: a video stream could not be found.'
		goto cleanup
	exit:
		ReadINIStr $0 "$PLUGINSDIR\StreamGulper.ini" "Field 6" "State"
		StrCmp $0 1 openfolder cleanup
		openfolder:
			DetailPrint "Opening output folder..."
			ExecShell "open" "$outputpath\"
		cleanup:
			RMDir /r "$TEMP\andryoustreamdl"
SectionEnd

Function .onInit
	InitPluginsDir
	File /oname=$PLUGINSDIR\StreamGulper.ini "StreamGulper.ini"
FunctionEnd

Function SetCustom
	Push ${TEMP1}
	InstallOptions::dialog "$PLUGINSDIR\StreamGulper.ini"
	Pop ${TEMP1}
FunctionEnd

Function ValidateCustom
	ReadINIStr ${TEMP1} "$PLUGINSDIR\StreamGulper.ini" "Field 3" "State"
	StrCmp ${TEMP1} "" error
	ReadINIStr ${TEMP1} "$PLUGINSDIR\StreamGulper.ini" "Field 5" "State"
	StrCmp ${TEMP1} "" error
	goto done
	error:
		MessageBox MB_ICONEXCLAMATION|MB_OK "You must input a url and also select an output folder."
		Abort
	done:
FunctionEnd

Function Trim
	Exch $R1 ; Original string
	Push $R2
 
Loop:
	StrCpy $R2 "$R1" 1
	StrCmp "$R2" " " TrimLeft
	StrCmp "$R2" "$\r" TrimLeft
	StrCmp "$R2" "$\n" TrimLeft
	StrCmp "$R2" "$\t" TrimLeft
	GoTo Loop2
TrimLeft:	
	StrCpy $R1 "$R1" "" 1
	Goto Loop
 
Loop2:
	StrCpy $R2 "$R1" 1 -1
	StrCmp "$R2" " " TrimRight
	StrCmp "$R2" "$\r" TrimRight
	StrCmp "$R2" "$\n" TrimRight
	StrCmp "$R2" "$\t" TrimRight
	GoTo Done
TrimRight:	
	StrCpy $R1 "$R1" -1
	Goto Loop2
 
Done:
	Pop $R2
	Exch $R1
FunctionEnd

Function GetAfterChar
  Exch $0 ; chop char
  Exch
  Exch $1 ; input string
  Push $2
  Push $3
  StrCpy $2 0
  loop:
    IntOp $2 $2 - 1
    StrCpy $3 $1 1 $2
    StrCmp $3 "" 0 +3
      StrCpy $0 ""
      Goto exit2
    StrCmp $3 $0 exit1
    Goto loop
  exit1:
    IntOp $2 $2 + 1
    StrCpy $0 $1 "" $2
  exit2:
    Pop $3
    Pop $2
    Pop $1
    Exch $0 ; output
FunctionEnd

Function SplitFirstStrPart
  Exch $R0
  Exch
  Exch $R1
  Push $R2
  Push $R3
  StrCpy $R3 $R1
  StrLen $R1 $R0
  IntOp $R1 $R1 + 1
  loop:
    IntOp $R1 $R1 - 1
    StrCpy $R2 $R0 1 -$R1
    StrCmp $R1 0 exit0
    StrCmp $R2 $R3 exit1 loop
  exit0:
  StrCpy $R1 ""
  Goto exit2
  exit1:
    IntOp $R1 $R1 - 1
    StrCmp $R1 0 0 +3
     StrCpy $R2 ""
     Goto +2
    StrCpy $R2 $R0 "" -$R1
    IntOp $R1 $R1 + 1
    StrCpy $R0 $R0 -$R1
    StrCpy $R1 $R2
  exit2:
  Pop $R3
  Pop $R2
  Exch $R1 ;rest
  Exch
  Exch $R0 ;first
FunctionEnd