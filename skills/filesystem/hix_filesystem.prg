function Aios_FileSystem( cAct, hP )
   local hR := { "success" => .t. }, cPat, cPath, cFile, aRes := {}
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
   elseif cAct == 'filesystem_volume_control'
   cAct := hb_HGetDef( hP, 'action', '' )
   if cAct == "off"
   // Bajar 50 veces el volumen para forzar MUTE a 0% usando COM Shell.Application (Virtual-Key 174)
   hb_Run( 'powershell -Command "$obj = new-object -com wscript.shell; for($i=0; $i -lt 50; $i++) { $obj.SendKeys([char]174) }"' )
   hR['msg'] := "Volumen del sistema apagado exitosamente al 0%."
   elseif cAct == "on"
   // Subir 50 veces el volumen para forzar MAX a 100% usando COM Shell.Application (Virtual-Key 175)
   hb_Run( 'powershell -Command "$obj = new-object -com wscript.shell; for($i=0; $i -lt 50; $i++) { $obj.SendKeys([char]175) }"' )
   hR['msg'] := "Volumen del sistema encendido exitosamente al 100%."
   else
   hR['success'] := .f.
   hR['error'] := "Acción inválida. Usa 'on' para encender o 'off' para apagar."
   endif
   endif
retu hR
