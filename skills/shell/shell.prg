function Aios_Shell( hP )
   local hR := { "success" => .t. }, cCmd := hb_HGetDef( hP, 'command', '' )
   if Empty( cCmd ) ; hR['success'] := .f. ; return hR ; endif
   hb_Run( cCmd + " > shell_out.tmp 2>&1" )
   hR['output'] := MemoRead( "shell_out.tmp" ) ; FErase( "shell_out.tmp" )
   retu hR
