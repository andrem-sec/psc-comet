@echo off
setlocal enabledelayedexpansion

:: Accept paths as positional args or prompt interactively.
:: Usage: run-library-pipeline.bat [library-root] [vault-root] [output-root]
::
:: output-root is optional; defaults to <library-root>\..\Markdown

set "LIBRARY_ROOT=%~1"
set "VAULT_ROOT=%~2"
set "OUTPUT_ROOT=%~3"

if "%LIBRARY_ROOT%"=="" (
    set /p LIBRARY_ROOT="Library root path (folder containing your books/papers): "
)
if "%VAULT_ROOT%"=="" (
    set /p VAULT_ROOT="Obsidian vault root path: "
)

:: Strip any trailing backslash to avoid broken quoted args
if "%LIBRARY_ROOT:~-1%"=="\" set "LIBRARY_ROOT=%LIBRARY_ROOT:~0,-1%"
if "%VAULT_ROOT:~-1%"=="\" set "VAULT_ROOT=%VAULT_ROOT:~0,-1%"

if "%OUTPUT_ROOT%"=="" (
    for %%I in ("%LIBRARY_ROOT%\..") do set "OUTPUT_ROOT=%%~fI\Markdown"
)
if "%OUTPUT_ROOT:~-1%"=="\" set "OUTPUT_ROOT=%OUTPUT_ROOT:~0,-1%"

if not exist "%LIBRARY_ROOT%" (
    echo ERROR: library root does not exist: %LIBRARY_ROOT% 1>&2
    exit /b 1
)
if not exist "%VAULT_ROOT%" (
    echo ERROR: vault root does not exist: %VAULT_ROOT% 1>&2
    exit /b 1
)

echo === Library Pipeline ===
echo Library root : %LIBRARY_ROOT%
echo Vault root   : %VAULT_ROOT%
echo Output root  : %OUTPUT_ROOT%
echo.

echo Step 1: Converting PDF/EPUB to Markdown...
python "%~dp0convert-to-md.py" ^
    --library-root "%LIBRARY_ROOT%" ^
    --output-root "%OUTPUT_ROOT%"
if errorlevel 1 goto :error

echo.
echo Step 2: Generating Obsidian MOC notes...
python "%~dp0generate-book-moc.py" ^
    --library-root "%LIBRARY_ROOT%" ^
    --vault-root "%VAULT_ROOT%" ^
    --output-root "%OUTPUT_ROOT%"
if errorlevel 1 goto :error

echo.
echo Done.
pause
exit /b 0

:error
echo.
echo Pipeline failed. Check output above.
pause
exit /b 1
