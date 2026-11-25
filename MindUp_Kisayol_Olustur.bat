@echo off
setlocal
set "APP_DIR=%~dp0"
if "%APP_DIR:~-1%"=="\" set "APP_DIR=%APP_DIR:~0,-1%"
set "APP_URL=https://serhatakca.github.io/mindup-kids/"
set "VBS=%TEMP%\mindup_shortcut_setup.vbs"

> "%VBS%" (
  echo Set fso = CreateObject("Scripting.FileSystemObject"^)
  echo Set sh  = CreateObject("WScript.Shell"^)
  echo dir = WScript.Arguments(0^)
  echo uri = WScript.Arguments(1^)
  echo icoSrc = dir ^& "\mindup.ico"
  echo pf  = sh.ExpandEnvironmentStrings("%ProgramFiles%"^)
  echo pf8 = sh.ExpandEnvironmentStrings("%ProgramFiles(x86)%"^)
  echo la  = sh.ExpandEnvironmentStrings("%LocalAppData%"^)
  echo cands = Array(pf8 ^& "\Microsoft\Edge\Application\msedge.exe", pf ^& "\Microsoft\Edge\Application\msedge.exe", pf ^& "\Google\Chrome\Application\chrome.exe", pf8 ^& "\Google\Chrome\Application\chrome.exe", la ^& "\Google\Chrome\Application\chrome.exe"^)
  echo browser = ""
  echo For Each c In cands
  echo   If c ^<^> "" And fso.FileExists(c^) Then
  echo     browser = c
  echo     Exit For
  echo   End If
  echo Next
  echo If browser = "" Then
  echo   If WScript.Arguments.Count ^< 3 Then MsgBox "Microsoft Edge veya Google Chrome bulunamadi.", 16, "MindUp Kids"
  echo   WScript.Quit 1
  echo End If
  echo appRoot = la ^& "\MindUpKids"
  echo appProf = appRoot ^& "\AppData"
  echo If Not fso.FolderExists(appRoot^) Then fso.CreateFolder appRoot
  echo If Not fso.FolderExists(appProf^) Then fso.CreateFolder appProf
  echo icoTarget = appRoot ^& "\mindup.ico"
  echo If fso.FileExists(icoSrc^) Then fso.CopyFile icoSrc, icoTarget, True
  echo desk = sh.SpecialFolders("Desktop"^)
  echo lnkPath = desk ^& "\MindUp Kids.lnk"
  echo Set sc = sh.CreateShortcut(lnkPath^)
  echo sc.TargetPath = browser
  echo sc.Arguments = "--user-data-dir=" ^& Chr(34^) ^& appProf ^& Chr(34^) ^& " --no-first-run --no-default-browser-check --app=" ^& Chr(34^) ^& uri ^& Chr(34^)
  echo sc.WorkingDirectory = appRoot
  echo If fso.FileExists(icoTarget^) Then sc.IconLocation = icoTarget ^& ",0"
  echo sc.Description = "MindUp Kids Yonetim Sistemi"
  echo sc.Save
  echo If WScript.Arguments.Count ^< 3 Then MsgBox "MindUp Kids masaustu uygulamasi basariyla kuruldu!" ^& vbCrLf ^& "Masaustundeki MindUp Kids simgesine cift tiklayabilirsiniz.", 64, "MindUp Kids"
)

if "%~1"=="--silent" (
  cscript //nologo "%VBS%" "%APP_DIR%" "%APP_URL%" silent
) else (
  cscript //nologo "%VBS%" "%APP_DIR%" "%APP_URL%"
)
set "ERR=%ERRORLEVEL%"
del "%VBS%" >nul 2>&1
exit /b %ERR%
