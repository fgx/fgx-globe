@setlocal

@set TMPCNT=0
@set ERRCNT=0
@set ERRLIST=

@for %%i in (*.json) do @(call :CHKJ %%i)

@echo Done %TMPCNT% files...
@if %ERRCNT% == 0 goto END
@echo Got %ERRCNT% Errors
@echo %ERRLIST%
@echo Got %ERRCNT% Errors


@goto END

:CHKJ
@if "%~1x" == "x" goto :EOF
@set /A TMPCNT+=1
@call chkjson %1
@if ERRORLEVEL 1 goto :ERR1
@goto :EOF

:ERR1
@set /A ERRCNT+=1
@set ERRLIST=%ERRLIST% %1
@goto :EOF


:END
@endlocal
