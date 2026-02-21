#include "hbcurl.ch"

function main()
   local cQuery, cModel, cHistory, cSystemPrompt := "", cJsonRes
   local hResult := { "success" => .f. }, oErr, cOldMem, cSep, cMemPath, cBaseDir

   cBaseDir := hb_DirBase()
   cSep := "\" ; if !( "\" $ cBaseDir ) ; cSep := "/" ; endif

   cQuery   := UGet( "query" )
   cModel   := UGet( "model" )
   cHistory := UGet( "history" )

   if Empty( cQuery )   ; cQuery   := UPost( "query" )   ; endif
   if Empty( cModel )   ; cModel   := UPost( "model" )   ; endif
   if Empty( cHistory ) ; cHistory := UPost( "history" ) ; endif

   // Clean data
   if ! Empty( cHistory ) .and. "%" $ hb_ValToStr( cHistory ) ; cHistory := Hix_UrlDecode( hb_ValToStr( cHistory ) ) ; endif
   if ! Empty( cQuery )   .and. "%" $ hb_ValToStr( cQuery )   ; cQuery   := Hix_UrlDecode( hb_ValToStr( cQuery ) )   ; endif

   if cQuery == "ping" ; UWrite( '{"success":true, "text":"pong"}' ) ; return "" ; endif
   if Empty( cQuery )   ; UWrite( '{"success":false, "error":"No query provided"}' ) ; return "" ; endif

   cJsonRes := '{"success":false, "error":"Fatal Crash"}'

   BEGIN SEQUENCE WITH {|e| break( e )}
   if Empty( cModel ) ; cModel := "gemini-3.1-pro-preview" ; endif

   // System Prompt - FORCED PERSONALITY
   cSystemPrompt := "ERES HIX AIOS v1.0. ASISTENTE AVANZADO." + ( Chr( 13 )+Chr( 10 ) )
   cSystemPrompt += "TIENES ACCESO A MEMORIA PERSISTENTE QUE SE TE PROPORCIONA A CONTINUACIÓN." + ( Chr( 13 )+Chr( 10 ) )
   cSystemPrompt += "PROHIBIDO DECIR QUE NO TIENES MEMORIA." + ( Chr( 13 )+Chr( 10 ) )

   // Load Identity & Soul
   if File( cBaseDir + "persona" + cSep + "IDENTITY.md" )
   cSystemPrompt += "TU IDENTIDAD:" + ( Chr( 13 )+Chr( 10 ) ) + hb_MemoRead( cBaseDir + "persona" + cSep + "IDENTITY.md" ) + ( Chr( 13 )+Chr( 10 ) )
   endif
   if File( cBaseDir + "persona" + cSep + "SOUL.md" )
   cSystemPrompt += "TU ALMA:" + ( Chr( 13 )+Chr( 10 ) ) + hb_MemoRead( cBaseDir + "persona" + cSep + "SOUL.md" ) + ( Chr( 13 )+Chr( 10 ) )
   endif

   cMemPath := cBaseDir + "persona" + cSep + "MEMORY.md"

   cSystemPrompt += "Si necesitas un chat_id para Telegram, BÚSCALO EN EL HISTORIAL DE CONVERSACIÓN ( history_data )." + ( Chr( 13 )+Chr( 10 ) )

   LogTrace( "REQ: " + cQuery + " | PromptLen: " + AllTrim( Str( Len( cSystemPrompt ) ) ) )

   hResult := ExecuteReasoningLoop( cQuery, cModel, hb_ValToStr( cHistory ), cSystemPrompt )

   // Save to Memory
   if ValType( hResult ) == "H" .and. hb_HGetDef( hResult, 'success', .f. )
   if ! hb_DirExists( cBaseDir + "persona" ) ; hb_DirCreate( cBaseDir + "persona" ) ; endif
   cOldMem := "" ; if File( cMemPath ) ; cOldMem := hb_MemoRead( cMemPath ) ; endif
   hb_MemoWrit( cMemPath, cOldMem + "[" + Time() + "] User: " + cQuery + ( Chr( 13 )+Chr( 10 ) ) + "HIX: " + hb_ValToStr( hResult['text'] ) + ( Chr( 13 )+Chr( 10 ) ) + ( Chr( 13 )+Chr( 10 ) ) )
   endif

   hResult["v"] := "1.0"
   cJsonRes := hb_jsonEncode( hResult )

   RECOVER USING oErr
   cJsonRes := '{"success":false, "error":"RTE: ' + hb_ValToStr( oErr:Description ) + '", "v":"1.0-err"}'
   END

   UWrite( cJsonRes )
return ""

function LogTrace( cMsg )

   local nH

   nH := fOpen( "aios_debug.log", 1 )
   if nH < 0 ; nH := fCreate( "aios_debug.log" ) ; endif
   if nH > 0
   fSeek( nH, 0, 2 )
   fWrite( nH, "[" + DToC( Date() ) + " " + Time() + "] v1.0: " + hb_ValToStr( cMsg ) + ( Chr( 13 )+Chr( 10 ) ) )
   fClose( nH )
   endif
return nil

function ExecuteReasoningLoop( cQuery, cModel, cHistory, cSystemPrompt )
   local aFunctions := BuildAiosFunctions()
   local aMessages := {}, nStep := 0, hResult := { "success" => .f. }, hGeminiResult, hSkillResult, hMsg, aResponseParts, hPart, lHasFC
   local cFullText := "", nPromptTokens := 0, nCandidatesTokens := 0, nTotalTokens := 0

   if ! Empty( cHistory ) ; hb_jsonDecode( cHistory, @aMessages ) ; endif
   if ValType( aMessages ) != "A" ; aMessages := {} ; endif

   aAdd( aMessages, { "role" => "user", "parts" => { { "text" => cQuery } } } )

   do while nStep < 10 // Increase steps for safety
   nStep++
   hGeminiResult := GeminiCallFC( aMessages, aFunctions, cModel, cSystemPrompt )

   if ValType( hGeminiResult ) != "H" .or. ! hb_HGetDef( hGeminiResult,"success",.f. )
   if nStep > 1 .and. ! Empty( cFullText )
   // If it fails after Turn 1 but we have text, return it
   hResult['success'] := .t. ; hResult['text'] := cFullText ; hResult['model_used'] := cModel
   hResult['usageMetadata'] := { "promptTokenCount" => nPromptTokens, "candidatesTokenCount" => nCandidatesTokens, "totalTokenCount" => nTotalTokens }
   return hResult
   endif
   hResult['success'] := .f. ; hResult['error'] := hb_ValToStr( hb_HGetDef( hGeminiResult, "error", "API Fail" ) )
   LogTrace( "LOOP ERR: " + hResult['error'] )
   return hResult
   endif

   if hb_HHasKey( hGeminiResult, "usageMetadata" )
   nPromptTokens += hb_HGetDef( hGeminiResult["usageMetadata"], "promptTokenCount", 0 )
   nCandidatesTokens += hb_HGetDef( hGeminiResult["usageMetadata"], "candidatesTokenCount", 0 )
   nTotalTokens += hb_HGetDef( hGeminiResult["usageMetadata"], "totalTokenCount", 0 )
   endif

   hMsg := { "role" => "model", "parts" => hGeminiResult["raw_parts"] }
   aAdd( aMessages, hMsg )

   // Accumulate text from this turn
   if ! Empty( hGeminiResult['text'] )
   cFullText += hGeminiResult['text']
   endif

   if hGeminiResult['type'] == "function_call"
   aResponseParts := {}
   for each hPart in hGeminiResult["raw_parts"]
   if ValType( hPart ) == "H" .and. hb_HHasKey( hPart, "functionCall" )
   hSkillResult := ExecuteAiosSkill( hPart["functionCall"]["name"], hPart["functionCall"]["args"] )
   aAdd( aResponseParts, { "functionResponse" => { "name" => hPart["functionCall"]["name"], "response" => hSkillResult } } )
   if hb_HHasKey( hSkillResult, "js_eval" )
   hResult["js_eval"] := hSkillResult["js_eval"]
   endif
   endif
   next
   aAdd( aMessages, { "role" => "function", "parts" => aResponseParts } )
   elseif hGeminiResult['type'] == "text"
   hResult['success'] := .t. ; hResult['text'] := cFullText ; hResult['model_used'] := cModel
   hResult['usageMetadata'] := { "promptTokenCount" => nPromptTokens, "candidatesTokenCount" => nCandidatesTokens, "totalTokenCount" => nTotalTokens }
   return hResult
   else
   // Type is 'empty' or unknown, but if we have text, we are done
   hResult['success'] := .t. ; hResult['text'] := iif( Empty( cFullText ), "OK", cFullText ) ; hResult['model_used'] := cModel
   hResult['usageMetadata'] := { "promptTokenCount" => nPromptTokens, "candidatesTokenCount" => nCandidatesTokens, "totalTokenCount" => nTotalTokens }
   return hResult
   endif
   enddo

   hResult['error'] := "Max retries reached without final answer"
return hResult

function GeminiCallFC( aMessages, aFunctions, cModel, cSystemPrompt )
   local cApiKey := GetAiosApiKey()
   local cUrl, cJson, hCurl, nError, cResponse := "", hResult := { "success" => .f. }
   local hPayload := { "contents" => aMessages, "tools" => { { "function_declarations" => aFunctions } } }

   if ! Empty( cSystemPrompt ) ; hPayload["system_instruction"] := { "parts" => { { "text" => cSystemPrompt } } } ; endif

   cUrl := "https://generativelanguage.googleapis.com/v1beta/models/" + cModel + ":generateContent?key=" + cApiKey
   cJson := hb_jsonEncode( hPayload )

   hCurl := curl_easy_init()
   if ! Empty( hCurl )
   curl_easy_setopt( hCurl, HB_CURLOPT_POST, .T. )
   curl_easy_setopt( hCurl, HB_CURLOPT_URL, cUrl )
   curl_easy_setopt( hCurl, HB_CURLOPT_HTTPHEADER, { "Content-Type: application/json" } )
   curl_easy_setopt( hCurl, HB_CURLOPT_SSL_VERIFYPEER, .F. )
   curl_easy_setopt( hCurl, HB_CURLOPT_POSTFIELDS, cJson )
   curl_easy_setopt( hCurl, HB_CURLOPT_DL_BUFF_SETUP )

   nError := curl_easy_perform( hCurl )
   if nError == HB_CURLE_OK
   cResponse := curl_easy_dl_buff_get( hCurl )
   LogTrace( "RECV: " + Left( cResponse, 500 ) + " ( len: " + AllTrim( Str( Len( cResponse ) ) ) + " )" )
   hResult := ParseAiosFCResponse( cResponse )
   if ! hResult['success'] ; LogTrace( "PARSE ERR: " + hb_ValToStr( hResult['error'] ) ) ; endif
   else
   hResult['error'] := "Curl error: " + hb_ValToStr( nError )
   LogTrace( "CURL ERR: " + AllTrim( Str( nError ) ) )
   endif
   curl_easy_cleanup( hCurl )
   else
   hResult['error'] := "Curl init failed"
   endif
return hResult

function ParseAiosFCResponse( cJSON )
   local hResult := { "success" => .f. }, hResponse := {=>}, aParts, nErr := 0, cW, nS, nE, hPart, lHasFC
   cW := AllTrim( StrTran( hb_ValToStr( cJSON ), Chr( 0 ), "" ) )
   nS := At( "{", cW ) ; nE := RAt( "}", cW )
   if nS > 0 .and. nE > nS ; cW := SubStr( cW, nS, nE - nS + 1 ) ; endif
   if Empty( cW ) ; hResult['error'] := "Empty response" ; return hResult ; endif
   nErr := hb_jsonDecode( cW, @hResponse )
   if ( nErr == 0 .or. nErr == Len( cW ) ) .and. ValType( hResponse ) == "H"
   if hb_HHasKey( hResponse, "candidates" ) .and. Len( hResponse["candidates"] ) > 0
   aParts := hResponse["candidates"][1]["content"]["parts"]
   hResult['success'] := .t. ; hResult['raw_parts'] := aParts ; lHasFC := .f.
   hResult['text'] := ""
   hResult['type'] := 'unknown'

   for each hPart in aParts
   if ValType( hPart ) == "H"
   if hb_HHasKey( hPart, "functionCall" ) ; lHasFC := .t. ; endif
   if hb_HHasKey( hPart, "text" ) ; hResult['text'] += hPart["text"] ; endif
   endif
   next

   if lHasFC
   hResult['type'] := 'function_call'
   elseif ! Empty( hResult['text'] )
   hResult['type'] := 'text'
   endif
   elseif hb_HHasKey( hResponse, "error" )
   hResult['error'] := "API Error: " + hb_ValToStr( hResponse["error"]["message"] )
   elseif hb_HHasKey( hResponse, "usageMetadata" )
   // Valid response but empty of content ( happens after tool turns sometimes )
   hResult['success'] := .t. ; hResult['type'] := 'empty' ; hResult['raw_parts'] := {} ; hResult['text'] := ""
   else
   hResult['error'] := "Invalid API Response Structure"
   endif
   else
   hResult['error'] := "JSON Parse Error ( Code: " + AllTrim( Str( nErr ) ) + " )"
   endif

   if ValType( hResponse ) == "H" .and. hb_HHasKey( hResponse, "usageMetadata" )
   hResult["usageMetadata"] := hResponse["usageMetadata"]
   endif

   if ValType( hResponse ) == "H" .and. hb_HHasKey( hResponse, "js_eval" )
   hResult["js_eval"] := hResponse["js_eval"]
   endif
   
retu hResult

function BuildAiosFunctions()
   local aFuncs := {}
   aAdd( aFuncs, { "name" => "filesystem_search", "description" => "Search files.", "parameters" => { "type" => "object", "properties" => { "pattern" => { "type" => "string" }, "path" => { "type" => "string" } }, "required" => {"pattern", "path"} } } )
   aAdd( aFuncs, { "name" => "identity_get_context", "description" => "Identity info.", "parameters" => { "type" => "object", "properties" => {=>}, "required" => {} } } )
   aAdd( aFuncs, { "name" => "telegram_send_message", "description" => "Send Telegram Msg.", "parameters" => { "type" => "object", "properties" => { "chat_id" => { "type" => "string" }, "text" => { "type" => "string" } }, "required" => {"chat_id", "text"} } } )
   aAdd( aFuncs, { "name" => "telegram_get_updates", "description" => "Read incoming Telegram messages.", "parameters" => { "type" => "object", "properties" => {=>}, "required" => {} } } )
   aAdd( aFuncs, { "name" => "config_set", "description" => "Save key-value pair.", "parameters" => { "type" => "object", "properties" => { "key" => { "type" => "string" }, "value" => { "type" => "string" } }, "required" => {"key", "value"} } } )
   aAdd( aFuncs, { "name" => "config_get", "description" => "Get saved info.", "parameters" => { "type" => "object", "properties" => { "key" => { "type" => "string", "description" => "Optional key" } }, "required" => {} } } )
   aAdd( aFuncs, { "name" => "memory_summarize", "description" => "Optimize/Summarize conversation history.", "parameters" => { "type" => "object", "properties" => { "summary" => { "type" => "string" } }, "required" => {"summary"} } } )
   aAdd( aFuncs, { "name" => "filesystem_get_datetime", "description" => "Get current date, time and day of week.", "parameters" => { "type" => "object", "properties" => {=>}, "required" => {} } } )
   aAdd( aFuncs, { "name" => "identity_update", "description" => "Update IDENTITY.md content.", "parameters" => { "type" => "object", "properties" => { "content" => { "type" => "string" } }, "required" => {"content"} } } )
   aAdd( aFuncs, { "name" => "soul_update", "description" => "Update SOUL.md content.", "parameters" => { "type" => "object", "properties" => { "content" => { "type" => "string" } }, "required" => {"content"} } } )
   aAdd( aFuncs, { "name" => "cron_add_reminder", "description" => "Schedule a reminder message.", "parameters" => { "type" => "object", "properties" => { "message" => { "type" => "string" }, "minutes" => { "type" => "number" }, "chat_id" => { "type" => "string" } }, "required" => {"message", "minutes"} } } )
   aAdd( aFuncs, { "name" => "web_search", "description" => "Search the internet for real-time information via Google Search.", "parameters" => { "type" => "object", "properties" => { "query" => { "type" => "string" } }, "required" => {"query"} } } )
   aAdd( aFuncs, { "name" => "web_search_wiki", "description" => "Search Wikipedia for encyclopedic or general concept information.", "parameters" => { "type" => "object", "properties" => { "query" => { "type" => "string" } }, "required" => {"query"} } } )
   aAdd( aFuncs, { "name" => "os_hardware_control", "description" => "Control Windows OS hardware settings: volume (level 0-100), brightness (level 0-100), power (state: lock, suspend, restart, shutdown), or battery (state: status).", "parameters" => { "type" => "object", "properties" => { "action" => { "type" => "string", "enum" => {"volume", "brightness", "power", "battery"}, "description" => "Hardware component to control" }, "level" => { "type" => "number", "description" => "Percentage from 0 to 100 (for volume/brightness)" }, "state" => { "type" => "string", "description" => "Required for power (lock/suspend/reboot/shutdown) or battery (status)" } }, "required" => {"action"} } } )
   aAdd( aFuncs, { "name" => "frontend_set_interval", "description" => "Instruct the user's chat browser to automatically send a message repeatedly every X seconds. Allows recurring jobs in the background.", "parameters" => { "type" => "object", "properties" => { "message" => { "type" => "string", "description" => "The exact message the browser should auto-send to you." }, "seconds" => { "type" => "number", "description" => "Interval delay in seconds." } }, "required" => {"message", "seconds"} } } )
   aAdd( aFuncs, { "name" => "frontend_clear_intervals", "description" => "Stop all background recurrent tasks running on the user's browser.", "parameters" => { "type" => "object", "properties" => {=>}, "required" => {} } } )
   aAdd( aFuncs, { "name" => "frontend_execute_js", "description" => "Execute raw Javascript on the user's chat browser to manipulate the DOM (change background color, trigger alerts, etc).", "parameters" => { "type" => "object", "properties" => { "javascript" => { "type" => "string", "description" => "A valid single or multi-line Javascript code block." } }, "required" => {"javascript"} } } )
   aAdd( aFuncs, { "name" => "image_gen", "description" => "Generates an image via AI based on a description prompt and returns it to be rendered in the chat.", "parameters" => { "type" => "object", "properties" => { "prompt" => { "type" => "string", "description" => "Detailed English description of the image to generate" } }, "required" => {"prompt"} } } )
retu aFuncs

function ExecuteAiosSkill( cName, hArgs )
   local hRes := { "success" => .f. }
   do case
   case cName == 'filesystem_search' ; hRes := Aios_FileSystem( cName, hArgs )
   case cName == 'identity_get_context' ; hRes := Aios_Identity()
   case cName == 'telegram_send_message' ; hRes := Aios_Telegram( cName, hArgs )
   case cName == 'telegram_get_updates' ; hRes := Aios_Telegram( cName, hArgs )
   case cName == 'config_set' ; hRes := Aios_Config( 'config_set', hArgs )
   case cName == 'config_get' ; hRes := Aios_Config( 'config_get', hArgs )
   case cName == 'memory_summarize' ; hRes := Aios_MemorySummarize( hArgs )
   case cName == 'filesystem_get_datetime' ; hRes := Aios_FileSystem( cName, hArgs )
   case cName == 'os_hardware_control' ; hRes := Aios_FileSystem( cName, hArgs )
   case cName == 'identity_update' ; hRes := Aios_PersonaUpdate( 'identity', hArgs )
   case cName == 'soul_update' ; hRes := Aios_PersonaUpdate( 'soul', hArgs )
   case cName == 'cron_add_reminder' ; hRes := Aios_Cron( cName, hArgs )
   case cName == 'web_search' ; hRes := Aios_WebSearch( hArgs )
   case cName == 'web_search_wiki' ; hRes := Aios_WebSearchWiki( hArgs )
   case cName == 'frontend_set_interval' ; hRes := Aios_Cron( cName, hArgs )
   case cName == 'frontend_clear_intervals' ; hRes := Aios_Cron( cName, hArgs )
   case cName == 'frontend_execute_js' ; hRes := Aios_Cron( cName, hArgs )
   case cName == 'image_gen' ; hRes := Aios_ImageGen( hArgs )
   endcase
retu hRes

#include "skills\identity\identity.prg"
#include "skills\filesystem\hix_filesystem.prg"
#include "skills\telegram\telegram.prg"
#include "skills\config\config_skill.prg"
#include "skills\cron\cron_skill.prg"
#include "skills\websearch\websearch_wiki.prg"
#include "skills\websearch\websearch.prg"
#include "skills\image_gen\image_gen.prg"

function GetAiosApiKey()
   local cKey := GetEnv( "GEMINI_API_KEY" ), hCfg := {=>}
   if Empty( cKey ) .and. File( "gemini_config.json" )
   hb_jsonDecode( hb_MemoRead( "gemini_config.json" ), @hCfg )
   if ValType( hCfg ) == "H" ; cKey := hb_HGetDef( hCfg, "api_key", "" ) ; endif
   endif
retu cKey

function Hix_UrlDecode( cT )
   local cR := "", n := 1, cX
   if Empty( cT ) ; return "" ; endif
   cT := StrTran( cT, "+", " " )
   do while n <= Len( cT )
   if SubStr( cT, n, 1 ) == "%"
   cX := SubStr( cT, n + 1, 2 ) ; cR += Chr( Hix_HexToNum( cX ) ) ; n += 3
   else ; cR += SubStr( cT, n, 1 ) ; n++ ; endif
   enddo
retu cR

function Hix_HexToNum( cX )
   local n := 0, i, cC, nV
   cX := Upper( cX )
   for i := 1 to Len( cX )
   cC := SubStr( cX, i, 1 ) ; nV := At( cC, "0123456789ABCDEF" ) - 1
   if nV >= 0 ; n := n * 16 + nV ; endif
   next
retu n
