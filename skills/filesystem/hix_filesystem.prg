function Aios_FileSystem( cAct, hP )
   local hR := { "success" => .t. }, cPat, cPath, cFile, aRes := {}, nLevel, nUp
   if cAct == 'filesystem_search'
   cPat := hb_HGetDef( hP, 'pattern', '*.*' ) ; cPath := hb_HGetDef( hP, 'path', 'c:\hix' )
   for each cFile in Directory( cPath + '\' + cPat )
   if !( cFile[1] $ '.,' ) ; aAdd( aRes, { "name" => cFile[1], "size" => cFile[2], "date" => DToC( cFile[3] ), "time" => cFile[4] } ) ; endif
   next
   hR['files'] := aRes ; hR['count'] := Len( aRes )
   elseif cAct == 'filesystem_read'
   cFile := hb_HGetDef( hP, 'file', '' )
   if File( cFile ) ; hR['content'] := Left( MemoRead( cFile ), 5000 ) ; else ; hR['success'] := .f. ; hR['error'] := "File not found" ; endif
   elseif cAct == 'filesystem_write'
   if MemoWrit( hb_HGetDef( hP, 'file', '' ), hb_HGetDef( hP, 'content', '' ) ) ; hR['msg'] := "Stored"
   else ; hR['success'] := .f. ; hR['error'] := "Writ error" ; endif
   elseif cAct == 'filesystem_delete'
   cFile := hb_HGetDef( hP, 'file', '' )
   if Empty( cFile ) ; hR['success'] := .f. ; hR['error'] := "No target provided" ; return hR ; endif
   if hb_DirExists( cFile )
   // Recursive delete for directories
   hb_Run( "rd /s /q " + '"' + cFile + '"' )
   if ! hb_DirExists( cFile ) ; hR['msg'] := "Directory deleted" ; else ; hR['success'] := .f. ; hR['error'] := "Failed to delete directory" ; endif
   elseif File( cFile )
   if FErase( cFile ) == 0 ; hR['msg'] := "File deleted" ; else ; hR['success'] := .f. ; hR['error'] := "Failed to delete file" ; endif
   else ; hR['success'] := .f. ; hR['error'] := "Not found: " + cFile ; endif
   elseif cAct == 'filesystem_get_datetime'
   hR["date"] := DToC( Date() )
   hR["time"] := Time()
   hR["day_of_week"] := { "Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado" }[ DoW( Date() ) ]
   hR["full_iso"] := TToS( hb_DateTime() )
   elseif cAct == 'os_hardware_control'
   cAct := hb_HGetDef( hP, 'action', '' )
   nLevel := hb_HGetDef( hP, 'level', -1 )
   cState := hb_HGetDef( hP, 'state', '' )

   if cAct == "volume"
   if nLevel >= 0 .and. nLevel <= 100
   nUp := Int( Round( nLevel / 2, 0 ) )
   hb_Run( 'powershell -Command "$obj = new-object -com wscript.shell; for($i=0; $i -lt 50; $i++) { $obj.SendKeys([char]174) }; for($i=0; $i -lt ' + AllTrim( Str( nUp ) ) + '; $i++) { $obj.SendKeys([char]175) }"' )
   hR['msg'] := "Volumen del sistema ajustado al " + AllTrim( Str( nLevel ) ) + "%."
   else
   hR['success'] := .f. ; hR['error'] := "Nivel de volumen inválido. Debe ser de 0 a 100."
   endif

   elseif cAct == "brightness"
   if nLevel >= 0 .and. nLevel <= 100
   hb_Run( 'powershell -Command "(Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1, ' + AllTrim( Str( nLevel ) ) + ')"' )
   hR['msg'] := "Brillo de pantalla ajustado al " + AllTrim( Str( nLevel ) ) + "%."
   else
   hR['success'] := .f. ; hR['error'] := "Nivel de brillo inválido. Debe ser de 0 a 100."
   endif

   elseif cAct == "power"
   if cState == "lock"
   hb_Run( 'rundll32.exe user32.dll,LockWorkStation' )
   hR['msg'] := "Windows Workstation locked."
   elseif cState == "suspend" .or. cState == "sleep"
   hb_Run( 'rundll32.exe powrprof.dll,SetSuspendState 0,1,0' )
   hR['msg'] := "System suspended."
   elseif cState == "reboot" .or. cState == "restart"
   hb_Run( 'shutdown /r /t 0' )
   hR['msg'] := "System reboot initiated."
   elseif cState == "shutdown"
   hb_Run( 'shutdown /s /t 0' )
   hR['msg'] := "System shutdown initiated."
   else
   hR['success'] := .f. ; hR['error'] := "Estado de energía inválido (lock/suspend/reboot/shutdown)."
   endif

   elseif cAct == "battery"
   hb_Run( 'WMIC Path Win32_Battery Get EstimatedChargeRemaining > c:\AIOS\bat_tmp.txt' )
   if File( 'c:\AIOS\bat_tmp.txt' )
   hR['msg'] := "Battery Report generated."
   hR['content'] := MemoRead( 'c:\AIOS\bat_tmp.txt' )
   FErase( 'c:\AIOS\bat_tmp.txt' )
   else
   hR['success'] := .f. ; hR['error'] := "Fallo leyendo métricas de batería WMI."
   endif

   else
   hR['success'] := .f. ; hR['error'] := "OS Hardware Acción inválida."
   endif
   endif
retu hR
