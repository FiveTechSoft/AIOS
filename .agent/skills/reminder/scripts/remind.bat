@echo off
rem remind.bat - Browser-based reliable reminder
rem Usage: remind.bat <seconds> "Message"

set seconds=%1
set message=%~2
set /a pings=%seconds% + 1

rem Wait using ping
ping 127.0.0.1 -n %pings% > nul

rem Open the beautiful browser reminder
start "" "c:\openclaw\.agent\skills\reminder\resources\reminder.html?msg=%message%"
