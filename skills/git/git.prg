function Aios_Git( hP )
   local hR := { "success" => .t. }, cCmd := hb_HGetDef( hP, 'command', '' )
   if Empty( cCmd ) ; hR['success'] := .f. ; return hR ; endif
   if !( Left( AllTrim( Lower( cCmd ) ), 4 ) == "git " )
      cCmd := "git " + cCmd
   endif
   hb_Run( cCmd + " > git_out.tmp 2>&1" )
   hR['output'] := MemoRead( "git_out.tmp" ) ; FErase( "git_out.tmp" )
   retu hR
