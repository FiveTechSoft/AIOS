function Aios_Config( cAct, hArgs )
   local hR := { "success" => .f. }, cBaseDir, cSep, cPath, hCfg := {=>}, cKey, cVal
   cBaseDir := hb_DirBase()
   cSep := "\" ; if !( "\" $ cBaseDir ) ; cSep := "/" ; endif
   cPath := cBaseDir + "persona" + cSep + "SETTINGS.json"

   if File( cPath )
      hb_jsonDecode( hb_MemoRead( cPath ), @hCfg )
   endif
   if ValType( hCfg ) != "H" ; hCfg := {=>} ; endif

   do case
   case cAct == 'config_set'
      cKey := hb_HGetDef( hArgs, "key", "" )
      cVal := hb_HGetDef( hArgs, "value", "" )
      if ! Empty( cKey )
         hCfg[cKey] := cVal
         if ! hb_DirExists( cBaseDir + "persona" ) ; hb_DirCreate( cBaseDir + "persona" ) ; endif
         hb_MemoWrit( cPath, hb_jsonEncode( hCfg, .t. ) )
         hR['success'] := .t.
         hR['message'] := "Config saved: " + cKey
      else
         hR['error'] := "Key is required"
      endif

   case cAct == 'config_get'
      cKey := hb_HGetDef( hArgs, "key", "" )
      if Empty( cKey )
         hR['success'] := .t.
         hR['config'] := hCfg
      elseif hb_HHasKey( hCfg, cKey )
         hR['success'] := .t.
         hR['value'] := hCfg[cKey]
      else
         hR['error'] := "Key not found: " + cKey
      endif
   endcase
   retu hR
