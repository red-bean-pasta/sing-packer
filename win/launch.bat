@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0fetch_config.ps1"
powershell -ExecutionPolicy Bypass -File "%~dp0run.ps1"
