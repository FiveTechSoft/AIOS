// websearch.prg - Web Search Skill via Google Serper API
// Uses hbcurl and hb_jsonDecode to retrieve Google search results

function Aios_WebSearch( hArgs )

   local hResult := { "success" => .f., "text" => "" }
   local cQuery, cUrl, hCurl, nError, cResponse, cExtractedText := ""
   local hJson, aOrganic, hItem, i
   local cApiKey := Aios_GetSerperKey() // We will read this from MEMORY.md or config

   if Empty( cApiKey )
      hResult["error"] := "Serper API Key no configurada. Por favor, añádela a tus ajustes."
      return hResult
   endif

   cQuery := hb_HGetDef( hArgs, "query", "" )
   if Empty( cQuery )
      hResult["error"] := "Query is empty"
      return hResult
   endif

   cUrl := "https://google.serper.dev/search"

   hCurl := curl_easy_init()
   if ! Empty( hCurl )
      curl_easy_setopt( hCurl, HB_CURLOPT_URL, cUrl )
      curl_easy_setopt( hCurl, HB_CURLOPT_POST, 1 )
      curl_easy_setopt( hCurl, HB_CURLOPT_POSTFIELDS, '{"q": "' + StrTran( cQuery, '"', '\"' ) + '"}' )
      curl_easy_setopt( hCurl, HB_CURLOPT_HTTPHEADER, {"X-API-KEY: " + cApiKey, "Content-Type: application/json"} )
      curl_easy_setopt( hCurl, HB_CURLOPT_FOLLOWLOCATION, .T. )
      curl_easy_setopt( hCurl, HB_CURLOPT_SSL_VERIFYPEER, .F. )
      curl_easy_setopt( hCurl, HB_CURLOPT_DL_BUFF_SETUP )

      nError := curl_easy_perform( hCurl )
      if nError == HB_CURLE_OK
         cResponse := curl_easy_dl_buff_get( hCurl )

         hb_jsonDecode( cResponse, @hJson )

         if hb_IsHash( hJson )
            // Extraer Knowledge Graph si existe
            if hb_HHasKey( hJson, "knowledgeGraph" )
               cExtractedText += "=== Información Destacada ===" + Chr( 13 ) + Chr( 10 )
               if hb_HHasKey( hJson["knowledgeGraph"], "title" )
                  cExtractedText += hJson["knowledgeGraph"]["title"] + Chr( 13 ) + Chr( 10 )
               endif
               if hb_HHasKey( hJson["knowledgeGraph"], "description" )
                  cExtractedText += hJson["knowledgeGraph"]["description"] + Chr( 13 ) + Chr( 10 )
               endif
               cExtractedText += Chr( 13 ) + Chr( 10 )
            endif

            // Extraer Answer Box si existe
            if hb_HHasKey( hJson, "answerBox" ) .and. hb_HHasKey( hJson["answerBox"], "snippet" )
               cExtractedText += "=== Respuesta Rápida ===" + Chr( 13 ) + Chr( 10 )
               cExtractedText += hJson["answerBox"]["snippet"] + Chr( 13 ) + Chr( 10 ) + Chr( 13 ) + Chr( 10 )
            elseif hb_HHasKey( hJson, "answerBox" ) .and. hb_HHasKey( hJson["answerBox"], "answer" )
               cExtractedText += "=== Respuesta Rápida ===" + Chr( 13 ) + Chr( 10 )
               cExtractedText += hJson["answerBox"]["answer"] + Chr( 13 ) + Chr( 10 ) + Chr( 13 ) + Chr( 10 )
            endif

            // Extraer resultados orgánicos
            if hb_HHasKey( hJson, "organic" )
               aOrganic := hJson["organic"]
               if hb_IsArray( aOrganic ) .and. Len( aOrganic ) > 0
                  cExtractedText += "=== Resultados Orgánicos ===" + Chr( 13 ) + Chr( 10 )
                  for i := 1 to Min( 4, Len( aOrganic ) )
                     hItem := aOrganic[i]
                     cExtractedText += "- " + hItem["title"] + ": " + hItem["snippet"] + Chr( 13 ) + Chr( 10 )
                  next
               endif
            endif
         endif

         if ! Empty( cExtractedText )
            hResult["success"] := .t.
            hResult["text"] := "Resultados de búsqueda en Google para '" + hb_HGetDef( hArgs, "query", "" ) + "':" + Chr( 13 ) + Chr( 10 ) + cExtractedText
         else
            hResult["success"] := .t.
            hResult["text"] := "No se encontraron resultados útiles en Google Serper."
         endif

         LogTrace( "WebSearch ( Google ) query execution: " + hb_HGetDef( hArgs, "query", "" ) + " ( Results length: " + AllTrim( Str( Len( cExtractedText ) ) ) + " )" )

      else
         hResult["error"] := "Curl error fetching search results: " + hb_ValToStr( nError )
         LogTrace( "WebSearch ( Google ) CURL ERR: " + AllTrim( Str( nError ) ) )
      endif
      curl_easy_cleanup( hCurl )
   else
      hResult["error"] := "Curl init failed in WebSearch"
   endif

   return hResult

function Aios_GetSerperKey()

   local cKey := GetEnv( "SERPER_API_KEY" )
   local hCfg := {=>}

   if Empty( cKey ) .and. File( "serper_config.json" )
      hb_jsonDecode( hb_MemoRead( "serper_config.json" ), @hCfg )
      if ValType( hCfg ) == "H"
         cKey := hb_HGetDef( hCfg, "api_key", "" )
      endif
   endif

   return cKey
