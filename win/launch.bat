@echo off
setlocal


set "PS=powershell -NoProfile -ExecutionPolicy Bypass -File"


for %%S in (
    download_exe.ps1
    fetch_config.ps1
    run.ps1
) do (
    echo Running %%S...
    %PS% "%~dp0%%S"

    if errorlevel 1 (
        echo.
        echo Execution FAILED: %%S
	echo.
        pause
	exit /b %ERRORLEVEL%
    )
)