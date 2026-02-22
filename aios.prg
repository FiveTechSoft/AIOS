#include "hbcurl.ch"

function main()

   local cQuery, cModel, cHistory, cSystemPrompt := "", cJsonRes
   local hAttachment := nil, cAttachment := ""
   local cFile, cFileName, cMimeType
   local hResult := { "success" => .f. }, oErr, cOldMem, cSep, cMemPath, cBaseDir
   local cJsonObj, hPayload
   local cAttachmentJSON
   local cRoutingPrompt, aRoutingMessages, hRouteResult, cRouteDecision

   cBaseDir := hb_DirBase()
   cSep := "\"
   if ! ( "\" $ cBaseDir )
   cSep := "/"
   endif

   cQuery      := UGet( "query" )
   cModel      := UGet( "model" )
   cHistory    := UGet( "history" )
   
   if Empty( cQuery )
   cQuery   := UPost( "query" )
   endif
   
   if Empty( cModel )
   cModel   := UPost( "model" )
   endif
   
   if Empty( cHistory )
   cHistory := UPost( "history" )
   endif

   cAttachmentJSON := UPost( "attachment" )

   // Clean data for URL-encoded
   if ! Empty( cHistory ) .and. "%" $ hb_ValToStr( cHistory )
   cHistory := Hix_UrlDecode( hb_ValToStr( cHistory ) )
   endif
   
   if ! Empty( cQuery ) .and. "%" $ hb_ValToStr( cQuery )
   cQuery   := Hix_UrlDecode( hb_ValToStr( cQuery ) )
   endif
   
   // Process the JSON attachment
   if ! Empty( cAttachmentJSON )
   hb_jsonDecode( cAttachmentJSON, @cJsonObj )
   if ValType( cJsonObj ) == "H"
   cFileName := hb_HGetDef( cJsonObj, "name", "file.bin" )
   cMimeType := hb_HGetDef( cJsonObj, "type", "application/octet-stream" )
   hAttachment := { "name" => cFileName, "type" => cMimeType }
         
   if "text/" $ cMimeType .or. ".csv" $ Lower( cFileName ) .or. ".md" $ Lower( cFileName ) .or. ".prg" $ Lower( cFileName )
   hAttachment["isText"] := .T.
   if hb_HHasKey( cJsonObj, "filepath" ) .and. File( cJsonObj["filepath"] )
   hAttachment["data"] := hb_MemoRead( cJsonObj["filepath"] )
   else
   BEGIN SEQUENCE WITH {|e| break( e )}
   hAttachment["data"] := hb_base64Decode( hb_ValToStr( hb_HGetDef( cJsonObj, "data", "" ) ) )
   RECOVER USING oErr
   UWrite( '{"success":false, "error":"Base64 Decode Crash: ' + hb_ValToStr( oErr:Description ) + '", "v":"1.0-err"}' )
   return ""
   END
   endif
   else
   hAttachment["isText"] := .F.
   if hb_HHasKey( cJsonObj, "filepath" ) .and. File( cJsonObj["filepath"] )
   hAttachment["data"] := hb_base64Encode( hb_MemoRead( cJsonObj["filepath"] ) )
   else
   hAttachment["data"] := hb_ValToStr( hb_HGetDef( cJsonObj, "data", "" ) )
   endif
   endif
   endif
   endif

   if cQuery == "ping"
   UWrite( '{"success":true, "text":"pong"}' )
   return ""
   endif

   if Empty( cQuery ) .and. ( hAttachment == nil )
   UWrite( '{"success":false, "error":"No query provided"}' ) 
   return "" 
   endif

   if Empty( cQuery ) .and. ( ValType( hAttachment ) == "H" )
   cQuery := "Revisa este documento o archivo adjunto e indícame de qué trata o descríbelo detalle."
   endif

   cJsonRes := '{"success":false, "error":"Fatal Crash"}'

   BEGIN SEQUENCE WITH {|e| break( e )}
   if Empty( cModel )
   cModel := "gemini-3.1-pro-preview"
   endif

   // System Prompt - FORCED PERSONALITY
   cSystemPrompt := "ERES HIX AIOS v1.0. ASISTENTE AVANZADO." + ( Chr( 13 ) + Chr( 10 ) )
   cSystemPrompt += "TIENES ACCESO A MEMORIA PERSISTENTE QUE SE TE PROPORCIONA A CONTINUACIÓN." + ( Chr( 13 ) + Chr( 10 ) )
   cSystemPrompt += "PROHIBIDO DECIR QUE NO TIENES MEMORIA." + ( Chr( 13 ) + Chr( 10 ) )
   cSystemPrompt += "REGLAS GENERALES DEL CREADOR DE TAREAS:" + ( Chr( 13 ) + Chr( 10 ) )
   cSystemPrompt += "1. Al usar 'ui_plan_tasks', inventa un 'plan_id' único y usa el MISMO en llamadas sucesivas para actualizar los estados a 'completed'." + ( Chr( 13 ) + Chr( 10 ) )
   cSystemPrompt += "2. En tu respuesta de TEXTO al chat, SIEMPRE repite la lista usando sintaxis Markdown pura: '- [ ] Paso' o '- [x] Paso'." + ( Chr( 13 ) + Chr( 10 ) )

   // Load Identity & Soul & Tasks
   if File( cBaseDir + "persona" + cSep + "IDENTITY.md" )
   cSystemPrompt += "TU IDENTIDAD:" + ( Chr( 13 ) + Chr( 10 ) ) + hb_MemoRead( cBaseDir + "persona" + cSep + "IDENTITY.md" ) + ( Chr( 13 ) + Chr( 10 ) )
   endif
      
   if File( cBaseDir + "persona" + cSep + "SOUL.md" )
   cSystemPrompt += "TU ALMA:" + ( Chr( 13 ) + Chr( 10 ) ) + hb_MemoRead( cBaseDir + "persona" + cSep + "SOUL.md" ) + ( Chr( 13 ) + Chr( 10 ) )
   endif

   if File( cBaseDir + "persona" + cSep + "TASKS.md" )
   cSystemPrompt += "TAREAS ACTIVAS (TASKS.md):" + ( Chr( 13 ) + Chr( 10 ) ) + hb_MemoRead( cBaseDir + "persona" + cSep + "TASKS.md" ) + ( Chr( 13 ) + Chr( 10 ) )
   endif

   cMemPath := cBaseDir + "persona" + cSep + "CONVERSATIONS.md"

   cSystemPrompt += "Si necesitas un chat_id para Telegram, BÚSCALO EN EL HISTORIAL DE CONVERSACIÓN ( history_data )." + ( Chr( 13 ) + Chr( 10 ) )

   LogTrace( "REQ: " + Left( cQuery, 100 ) + "... | PromptLen: " + AllTrim( Str( Len( cSystemPrompt ) ) ) + " | HasAttach: " + iif( hAttachment != nil, "Y", "N" ) )

   // --- ENRUTAMIENTO PREVIO (Fase de Evaluación Estricta) ---
   if Empty( hAttachment )
   cRoutingPrompt := "Analiza la petición del usuario: '" + cQuery + "'. " + ;
      "¿Puedes descomponer esta petición en una lista secuencial de pasos o tareas que seguir para completarla adecuadamente? " + ;
      "Responde ÚNICAMENTE con la palabra 'SI' en caso de que requiera pasos (por ejemplo: informes, desarrollos, guías, análisis), " + ;
      "o con la palabra 'NO' si es un saludo, una pregunta de conocimiento directo o un cálculo simple que se responde en un solo párrafo corto."
      
   aRoutingMessages := { { "role" => "user", "parts" => { { "text" => cRoutingPrompt } } } }
   hRouteResult := GeminiCallFC( aRoutingMessages, {}, cModel, "Eres un clasificador estricto binario. Tu respuesta solo puede ser SI o NO." )
      
   cRouteDecision := "NO"
   if ValType( hRouteResult ) == "H" .and. hb_HGetDef( hRouteResult, "success", .f. ) .and. ! Empty( hb_HGetDef( hRouteResult, "text", "" ) )
   cRouteDecision := Upper( AllTrim( StrTran( StrTran( hRouteResult["text"], Chr( 13 ), "" ), Chr( 10 ), "" ) ) )
   cRouteDecision := StrTran( cRouteDecision, ".", "" )
   endif
      
   LogTrace( "ROUTING DECISION (STEPS?): " + cRouteDecision )
      
   if "SI" $ cRouteDecision .or. "SÍ" $ cRouteDecision
   // Modificamos la petición del usuario para forzar la herramienta
   cQuery := "Desglosa la siguiente tarea en una guía de pasos lógicos y secuenciales para su ejecución inmediata. No analices si es necesaria la división, simplemente presenta el plan de acción detallado. La tarea es: " + cQuery

   cSystemPrompt += "INSTRUCCIÓN DIRECTA DE SISTEMA: Ejecuta la labor solicitada EXCLUSIVAMENTE llamando a la herramienta 'ui_plan_tasks'. " + ;
      "ESTÁ TERMINANTEMENTE PROHIBIDO QUE ME DES LA RESPUESTA EN TEXTO O REPITAS LOS PASOS EN EL CHAT. " + ;
      "Tu ÚNICA acción permitida en este turno es imaginar los pasos necesarios y enviarlos usando la herramienta. No escribas NADA de texto en el chat." + ( Chr( 13 ) + Chr( 10 ) )
   else
   cSystemPrompt += "Responde a la petición del usuario directamente y de forma natural, sin crear tareas." + ( Chr( 13 ) + Chr( 10 ) )
   endif
   endif

   hResult := ExecuteReasoningLoop( cQuery, cModel, hb_ValToStr( cHistory ), cSystemPrompt, hAttachment )

   // Save to Memory
   if ValType( hResult ) == "H" .and. hb_HGetDef( hResult, "success", .f. )
   if ! hb_DirExists( cBaseDir + "persona" )
   hb_DirCreate( cBaseDir + "persona" )
   endif
         
   cOldMem := ""
   if File( cMemPath )
   cOldMem := hb_MemoRead( cMemPath )
   endif
   hb_MemoWrit( cMemPath, cOldMem + "## [" + DtoC(Date()) + " " + Time() + "]" + ( Chr( 13 ) + Chr( 10 ) ) + "**USER:** " + cQuery + ( Chr( 13 ) + Chr( 10 ) ) + "**AIOS:** " + hb_ValToStr( hResult["text"] ) + ( Chr( 13 ) + Chr( 10 ) ) + "---" + ( Chr( 13 ) + Chr( 10 ) ) )
   endif

   // Generate a short title summary for the sidebar
   if ValType( hResult ) == "H" .and. hb_HGetDef( hResult, "success", .f. )
   if UPost( "is_first" ) == "1"
   hResult["summary"] := Aios_GenerateSummary( cQuery, cModel )
   endif
   endif

   hResult["v"] := "1.0"
   cJsonRes := hb_jsonEncode( hResult )

   RECOVER USING oErr
   cJsonRes := '{"success":false, "error":"RTE: ' + hb_ValToStr( oErr:Description ) + '", "v":"1.0-err"}'
   END

   UWrite( cJsonRes )
return ""

function Aios_GenerateSummary( cQuery, cModel )
   local aMessages, hGeminiResult, cSummary := Left( cQuery, 40 ) + "..."
   local cPrompt := "Genera UN ÚNICO TÍTULO MUY BREVE (máximo 5-6 palabras) que resuma de qué trata este texto: '" + cQuery + "'. Responde SOLO con el título de forma afirmativa y coloquial, sin comillas, sin decir 'claro' ni nada extra."
   
   aMessages := { { "role" => "user", "parts" => { { "text" => cPrompt } } } }
   
   hGeminiResult := GeminiCallFC( aMessages, {}, cModel, "" )
   
   if ValType( hGeminiResult ) == "H" .and. hb_HGetDef( hGeminiResult, "success", .f. ) .and. ! Empty( hb_HGetDef( hGeminiResult, "text", "" ) )
   cSummary := AllTrim( StrTran( StrTran( hGeminiResult["text"], Chr( 13 ), "" ), Chr( 10 ), "" ) )
   endif
return cSummary

function LogTrace( cMsg )

   local nH

   nH := fOpen( "aios_debug.log", 1 )
   if nH < 0
   nH := fCreate( "aios_debug.log" )
   endif
   if nH > 0
   fSeek( nH, 0, 2 )
   fWrite( nH, "[" + DToC( Date() ) + " " + Time() + "] v1.0: " + hb_ValToStr( cMsg ) + ( Chr( 13 ) + Chr( 10 ) ) )
   fClose( nH )
   endif
return nil

function ExecuteReasoningLoop( cQuery, cModel, cHistory, cSystemPrompt, hAttachment )

   local aFunctions := BuildAiosFunctions()
   local aMessages := {}, nStep := 0, hResult := { "success" => .f. }, hGeminiResult, hSkillResult, hMsg, aResponseParts, hPart, lHasFC
   local cFullText := "", nPromptTokens := 0, nCandidatesTokens := 0, nTotalTokens := 0
   local aUserParts := {}

   if ! Empty( cHistory )
   hb_jsonDecode( cHistory, @aMessages )
   endif
   if ValType( aMessages ) != "A"
   aMessages := {}
   endif

   // Process Query and Attachment
   if ValType( hAttachment ) == "H"
   if hb_HGetDef( hAttachment, "isText", .f. )
   aAdd( aUserParts, { "text" => "Attached Text File (" + hb_HGetDef( hAttachment, "name", "file.txt" ) + "):" + Chr( 13 ) + Chr( 10 ) + hb_HGetDef( hAttachment, "data", "" ) + Chr( 13 ) + Chr( 10 ) } )
   else
   aAdd( aUserParts, { "inlineData" => { "mimeType" => hb_HGetDef( hAttachment, "type", "application/octet-stream" ), "data" => hb_HGetDef( hAttachment, "data", "" ) } } )
   endif
   endif
   
   aAdd( aUserParts, { "text" => cQuery } )
   aAdd( aMessages, { "role" => "user", "parts" => aUserParts } )

   do while nStep < 10 // Increase steps for safety
   nStep++
   hGeminiResult := GeminiCallFC( aMessages, aFunctions, cModel, cSystemPrompt )

   if ValType( hGeminiResult ) != "H" .or. ! hb_HGetDef( hGeminiResult, "success", .f. )
   if nStep > 1 .and. ! Empty( cFullText )
   // If it fails after Turn 1 but we have text, return it
   hResult["success"] := .t.
   hResult["text"] := cFullText
   hResult["model_used"] := cModel
   hResult["usageMetadata"] := { "promptTokenCount" => nPromptTokens, "candidatesTokenCount" => nCandidatesTokens, "totalTokenCount" => nTotalTokens }
   return hResult
   endif
         
   hResult["success"] := .f.
   hResult["error"] := hb_ValToStr( hb_HGetDef( hGeminiResult, "error", "API Fail" ) )
   LogTrace( "LOOP ERR: " + hResult["error"] )
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
   if ! Empty( hGeminiResult["text"] )
   cFullText += hGeminiResult["text"]
   endif

   if hGeminiResult["type"] == "function_call"
   aResponseParts := {}
   for each hPart in hGeminiResult["raw_parts"]
   if ValType( hPart ) == "H" .and. hb_HHasKey( hPart, "functionCall" )
   hSkillResult := ExecuteAiosSkill( hPart["functionCall"]["name"], hPart["functionCall"]["args"] )
               
   // Intercept image output to inject directly and save prompt tokens for the next tool turn
   if hPart["functionCall"]["name"] == "image_gen" .and. hb_HGetDef( hSkillResult, "success", .f. )
   if hb_HHasKey( hSkillResult, "text" )
   cFullText += Chr( 13 ) + Chr( 10 ) + hSkillResult["text"] + Chr( 13 ) + Chr( 10 )
   hSkillResult["text"] := "Image generated successfully and delivered to UI. Please provide a brief, friendly confirmation to the user."
   endif
   endif

   if hPart["functionCall"]["name"] == "ui_plan_tasks" .and. hb_HGetDef( hSkillResult, "success", .f. )
   if hb_HGetDef( hSkillResult, "is_creation", .f. )
   if hb_HHasKey( hSkillResult, "js_eval" )
   hResult["js_eval"] := hSkillResult["js_eval"]
   endif
   cFullText := "He preparado el plan de tareas en el menú lateral. Por favor, revísalo y confírmame si quieres que proceda a ejecutar estos pasos antes de darte la respuesta final."
   hResult["success"] := .t.
   hResult["text"] := cFullText
   hResult["model_used"] := cModel
   hResult["usageMetadata"] := { "promptTokenCount" => nPromptTokens, "candidatesTokenCount" => nCandidatesTokens, "totalTokenCount" => nTotalTokens }
   return hResult
   endif
   endif
               
   aAdd( aResponseParts, { "functionResponse" => { "name" => hPart["functionCall"]["name"], "response" => hSkillResult } } )
   if hb_HHasKey( hSkillResult, "js_eval" )
   hResult["js_eval"] := hSkillResult["js_eval"]
   endif
   endif
   next
   aAdd( aMessages, { "role" => "function", "parts" => aResponseParts } )
         
   elseif hGeminiResult["type"] == "text"
   hResult["success"] := .t.
   hResult["text"] := cFullText
   hResult["model_used"] := cModel
   hResult["usageMetadata"] := { "promptTokenCount" => nPromptTokens, "candidatesTokenCount" => nCandidatesTokens, "totalTokenCount" => nTotalTokens }
   return hResult
   else
   // Type is 'empty' or unknown, but if we have text, we are done
   hResult["success"] := .t.
   hResult["text"] := iif( Empty( cFullText ), "OK", cFullText )
   hResult["model_used"] := cModel
   hResult["usageMetadata"] := { "promptTokenCount" => nPromptTokens, "candidatesTokenCount" => nCandidatesTokens, "totalTokenCount" => nTotalTokens }
   return hResult
   endif
   enddo

   hResult["error"] := "Max retries reached without final answer"
return hResult

function GeminiCallFC( aMessages, aFunctions, cModel, cSystemPrompt )

   local cApiKey := GetAiosApiKey()
   local cUrl, cJson, hCurl, nError, cResponse := "", hResult := { "success" => .f. }
   local hPayload := { "contents" => aMessages, "tools" => { { "function_declarations" => aFunctions } } }

   if ! Empty( cSystemPrompt )
   hPayload["system_instruction"] := { "parts" => { { "text" => cSystemPrompt } } }
   endif

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
   if ! hResult["success"]
   LogTrace( "PARSE ERR: " + hb_ValToStr( hResult["error"] ) )
   endif
   else
   hResult["error"] := "Curl error: " + hb_ValToStr( nError )
   LogTrace( "CURL ERR: " + AllTrim( Str( nError ) ) )
   endif
   curl_easy_cleanup( hCurl )
   else
   hResult["error"] := "Curl init failed"
   endif
return hResult

function ParseAiosFCResponse( cJSON )

   local hResult := { "success" => .f. }, hResponse := {=>}, aParts, nErr := 0, cW, nS, nE, hPart, lHasFC

   cW := AllTrim( StrTran( hb_ValToStr( cJSON ), Chr( 0 ), "" ) )
   nS := At( "{", cW )
   nE := RAt( "}", cW )
   
   if nS > 0 .and. nE > nS
   cW := SubStr( cW, nS, nE - nS + 1 )
   endif
   
   if Empty( cW )
   hResult["error"] := "Empty response"
   return hResult
   endif
   
   nErr := hb_jsonDecode( cW, @hResponse )
   if ( nErr == 0 .or. nErr == Len( cW ) ) .and. ValType( hResponse ) == "H"
   if hb_HHasKey( hResponse, "candidates" ) .and. Len( hResponse["candidates"] ) > 0
   aParts := hResponse["candidates"][1]["content"]["parts"]
   hResult["success"] := .t.
   hResult["raw_parts"] := aParts
   lHasFC := .f.
   hResult["text"] := ""
   hResult["type"] := "unknown"

   for each hPart in aParts
   if ValType( hPart ) == "H"
   if hb_HHasKey( hPart, "functionCall" )
   lHasFC := .t.
   endif
   if hb_HHasKey( hPart, "text" )
   hResult["text"] += hPart["text"]
   endif
   endif
   next

   if lHasFC
   hResult["type"] := "function_call"
   elseif ! Empty( hResult["text"] )
   hResult["type"] := "text"
   endif
   elseif hb_HHasKey( hResponse, "error" )
   hResult["error"] := "API Error: " + hb_ValToStr( hResponse["error"]["message"] )
   elseif hb_HHasKey( hResponse, "usageMetadata" )
   // Valid response but empty of content ( happens after tool turns sometimes )
   hResult["success"] := .t.
   hResult["type"] := "empty"
   hResult["raw_parts"] := {}
   hResult["text"] := ""
   else
   hResult["error"] := "Invalid API Response Structure"
   endif
   else
   hResult["error"] := "JSON Parse Error ( Code: " + AllTrim( Str( nErr ) ) + " )"
   endif

   if ValType( hResponse ) == "H" .and. hb_HHasKey( hResponse, "usageMetadata" )
   hResult["usageMetadata"] := hResponse["usageMetadata"]
   endif

   if ValType( hResponse ) == "H" .and. hb_HHasKey( hResponse, "js_eval" )
   hResult["js_eval"] := hResponse["js_eval"]
   endif
   
return hResult

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
   aAdd( aFuncs, { "name" => "os_hardware_control", "description" => "Control Windows OS hardware settings.", "parameters" => { "type" => "object", "properties" => { "action" => { "type" => "string" } }, "required" => {"action"} } } )
   aAdd( aFuncs, { "name" => "frontend_set_interval", "description" => "Auto-send message from UI.", "parameters" => { "type" => "object", "properties" => { "message" => { "type" => "string" }, "seconds" => { "type" => "number" } }, "required" => {"message", "seconds"} } } )
   aAdd( aFuncs, { "name" => "frontend_clear_intervals", "description" => "Stop recurrent UI tasks.", "parameters" => { "type" => "object", "properties" => {=>}, "required" => {} } } )
   aAdd( aFuncs, { "name" => "frontend_execute_js", "description" => "Execute JS on browser.", "parameters" => { "type" => "object", "properties" => { "javascript" => { "type" => "string" } }, "required" => {"javascript"} } } )
   aAdd( aFuncs, { "name" => "image_gen", "description" => "Generates an image via AI.", "parameters" => { "type" => "object", "properties" => { "prompt" => { "type" => "string" } }, "required" => {"prompt"} } } )

return aFuncs

function ExecuteAiosSkill( cName, hArgs )

   local hRes := { "success" => .f. }

   do case
   case cName == "filesystem_search"
   hRes := Aios_FileSystem( cName, hArgs )
   case cName == "identity_get_context"
   hRes := Aios_Identity()
   case cName == "telegram_send_message"
   hRes := Aios_Telegram( cName, hArgs )
   case cName == "telegram_get_updates"
   hRes := Aios_Telegram( cName, hArgs )
   case cName == "config_set"
   hRes := Aios_Config( "config_set", hArgs )
   case cName == "config_get"
   hRes := Aios_Config( "config_get", hArgs )
   case cName == "memory_summarize"
   hRes := Aios_MemorySummarize( hArgs )
   case cName == "filesystem_get_datetime"
   hRes := Aios_FileSystem( cName, hArgs )
   case cName == "os_hardware_control"
   hRes := Aios_FileSystem( cName, hArgs )
   case cName == "identity_update"
   hRes := Aios_PersonaUpdate( "identity", hArgs )
   case cName == "soul_update"
   hRes := Aios_PersonaUpdate( "soul", hArgs )
   case cName == "cron_add_reminder"
   hRes := Aios_Cron( cName, hArgs )
   case cName == "web_search"
   hRes := Aios_WebSearch( hArgs )
   case cName == "web_search_wiki"
   hRes := Aios_WebSearchWiki( hArgs )
   case cName == "frontend_set_interval"
   hRes := Aios_Cron( cName, hArgs )
   case cName == "frontend_clear_intervals"
   hRes := Aios_Cron( cName, hArgs )
   case cName == "frontend_execute_js"
   hRes := Aios_Cron( cName, hArgs )
   case cName == "image_gen"
   hRes := Aios_ImageGen( hArgs )
   case cName == "ui_plan_tasks"
   hRes := Aios_UiPlanTasks( hArgs )
   endcase

return hRes

#include "skills\identity\identity.prg"
#include "skills\filesystem\hix_filesystem.prg"
#include "skills\telegram\telegram.prg"
#include "skills\config\config_skill.prg"
#include "skills\cron\cron_skill.prg"
#include "skills\websearch\websearch_wiki.prg"
#include "skills\websearch\websearch.prg"
#include "skills\image_gen\image_gen.prg"
#include ".agent\skills\ui_plan_tasks\ui_plan_tasks.prg"

function GetAiosApiKey()

   local cKey := GetEnv( "GEMINI_API_KEY" ), hCfg := {=>}

   if Empty( cKey ) .and. File( "gemini_config.json" )
   hb_jsonDecode( hb_MemoRead( "gemini_config.json" ), @hCfg )
   if ValType( hCfg ) == "H"
   cKey := hb_HGetDef( hCfg, "api_key", "" )
   endif
   endif
return cKey

function Hix_UrlDecode( cT )

   local cR := "", n := 1, cX

   if Empty( cT )
   return ""
   endif
   
   cT := StrTran( cT, "+", " " )
   
   do while n <= Len( cT )
   if SubStr( cT, n, 1 ) == "%"
   cX := SubStr( cT, n + 1, 2 )
   cR += Chr( Hix_HexToNum( cX ) )
   n += 3
   else
   cR += SubStr( cT, n, 1 )
   n++
   endif
   enddo
return cR

function Hix_HexToNum( cX )

   local n := 0, i, cC, nV

   cX := Upper( cX )
   for i := 1 to Len( cX )
   cC := SubStr( cX, i, 1 )
   nV := At( cC, "0123456789ABCDEF" ) - 1
   if nV >= 0
   n := n * 16 + nV
   endif
   next
return n
