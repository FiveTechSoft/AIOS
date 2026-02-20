function Aios_Identity()
   local hR := { "success" => .t. }, cId := "", cSoul := "", cMem := "", cBaseDir := hb_DirBase()
   local cSep := "\" ; if !( "\" $ cBaseDir ) ; cSep := "/" ; endif

   if File( cBaseDir + "persona" + cSep + "IDENTITY.md" ) ; cId := hb_MemoRead( cBaseDir + "persona" + cSep + "IDENTITY.md" ) ; endif
   if File( cBaseDir + "persona" + cSep + "SOUL.md" )     ; cSoul := hb_MemoRead( cBaseDir + "persona" + cSep + "SOUL.md" )     ; endif
   if File( cBaseDir + "persona" + cSep + "MEMORY.md" )   ; cMem := Right( hb_MemoRead( cBaseDir + "persona" + cSep + "MEMORY.md" ), 2000 ) ; endif

   hR['identity'] := cId
   hR['soul'] := cSoul
   hR['recent_memory'] := cMem

   if Empty( cId ) .and. Empty( cSoul ) ; hR['success'] := .f. ; hR['error'] := "Identity files not found" ; endif
   retu hR

function Aios_MemorySummarize( hArgs )
   local hR := { "success" => .f. }, cSummary, cBaseDir, cSep, cPath
   cSummary := hb_HGetDef( hArgs, "summary", "" )
   if Empty( cSummary ) ; hR['error'] := "Summary content is empty" ; retu hR ; endif

   cBaseDir := hb_DirBase()
   cSep := "\" ; if !( "\" $ cBaseDir ) ; cSep := "/" ; endif
   cPath := cBaseDir + "persona" + cSep + "MEMORY.md"

   if ! hb_DirExists( cBaseDir + "persona" ) ; hb_DirCreate( cBaseDir + "persona" ) ; endif

   if hb_MemoWrit( cPath, "[OPTIMIZED MEMORY " + DToC( Date() ) + "]" + ( Chr( 13 )+Chr( 10 ) ) + cSummary + ( Chr( 13 )+Chr( 10 ) ) + ( Chr( 13 )+Chr( 10 ) ) )
      hR['success'] := .t.
      hR['message'] := "Memory reorganized successfully"
   else
      hR['error'] := "Could not write memory file"
   endif
   retu hR

function Aios_PersonaUpdate( cType, hArgs )
   local hR := { "success" => .f. }, cContent, cFile, cBaseDir, cSep, cPath
   cContent := hb_HGetDef( hArgs, "content", "" )
   if Empty( cContent ) ; hR['error'] := "Content is empty" ; retu hR ; endif

   cBaseDir := hb_DirBase()
   cSep := "\" ; if !( "\" $ cBaseDir ) ; cSep := "/" ; endif
   cFile := iif( cType == "identity", "IDENTITY.md", "SOUL.md" )
   cPath := cBaseDir + "persona" + cSep + cFile

   if ! hb_DirExists( cBaseDir + "persona" ) ; hb_DirCreate( cBaseDir + "persona" ) ; endif

   if hb_MemoWrit( cPath, cContent )
      hR['success'] := .t.
      hR['message'] := "Persona ( " + cType + " ) updated successfully"
   else
      hR['error'] := "Could not write " + cFile
   endif
   retu hR
