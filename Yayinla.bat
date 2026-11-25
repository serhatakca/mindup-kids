@echo off
setlocal
cd /d "%~dp0"

if not exist "mindup.html" (
  echo HATA: mindup.html bulunamadi!
  pause
  exit /b 1
)

copy /y "mindup.html" "index.html" >nul
git add -A
git diff --cached --quiet
if %errorlevel%==0 (
  echo Degisiklik bulunamadi, her sey zaten guncel.
  pause
  exit /b 0
)

for /f "tokens=1-3 delims=." %%a in ("%date%") do set "D=%%c-%%b-%%a"
git commit -m "MindUp Kids guncellemesi (%date% %time:~0,5%)"
if errorlevel 1 (
  echo Commit sirasinda hata olustu.
  pause
  exit /b 1
)

git push -u origin main
if errorlevel 1 (
  echo.
  echo GitHub'a gonderilemedi! Internet baglantinizi veya GitHub girisinizi kontrol edin.
  pause
  exit /b 1
)

echo.
echo Basariyla yayinlandi! Yaklasik 30-60 saniye icinde tum PC'lerde aktif olur.
pause
