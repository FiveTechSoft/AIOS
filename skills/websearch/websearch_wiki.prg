// websearch_wiki.prg - Web Search Skill via Wikipedia API
// Uses hbcurl and hb_jsonDecode to retrieve factual summaries

function Aios_WebSearchWiki( hArgs )

   local hResult := { "success" => .f., "text" => "" }
   local cQuery, cUrl, hCurl, nError, cResponse, cExtractedText := ""
   local hJson, aSearch, hItem, i

   cQuery := hb_HGetDef( hArgs, "query", "" )
   if Empty( cQuery )
      hResult["error"] := "Query is empty"
      return hResult
   endif

   // Format the query for Wikipedia API URL
   cQuery := StrTran( cQuery, " ", "+" )
   cUrl := "https://es.wikipedia.org/w/api.php?action=query&list=search&srsearch=" + cQuery + "&utf8=&format=json"

   hCurl := curl_easy_init()
   if ! Empty( hCurl )
      curl_easy_setopt( hCurl, HB_CURLOPT_URL, cUrl )
      curl_easy_setopt( hCurl, HB_CURLOPT_USERAGENT, "OpenClaw HIX/1.0" )
      curl_easy_setopt( hCurl, HB_CURLOPT_FOLLOWLOCATION, .T. )
      curl_easy_setopt( hCurl, HB_CURLOPT_SSL_VERIFYPEER, .F. )
      curl_easy_setopt( hCurl, HB_CURLOPT_DL_BUFF_SETUP )

      nError := curl_easy_perform( hCurl )
      if nError == HB_CURLE_OK
         cResponse := curl_easy_dl_buff_get( hCurl )

         // Decode the JSON response from Wikipedia
         hb_jsonDecode( cResponse, @hJson )

         if hb_IsHash( hJson ) .and. hb_HHasKey( hJson, "query" ) .and. hb_HHasKey( hJson["query"], "search" )
            aSearch := hJson["query"]["search"]
            if hb_IsArray( aSearch ) .and. Len( aSearch ) > 0
               // Extract the title and snippet from the top 3 results
               for i := 1 to Min( 3, Len( aSearch ) )
                  hItem := aSearch[i]
                  cExtractedText += "- " + hItem["title"] + ": " + ;
                  StrTran( StrTran( hItem["snippet"], '<span class="searchmatch">', '' ), '</span>', '' ) + Chr( 13 ) + Chr( 10 )
               next
            endif
         endif

         if ! Empty( cExtractedText )
            hResult["success"] := .t.
            hResult["text"] := "Web search results for '" + hb_HGetDef( hArgs, "query", "" ) + "':" + Chr( 13 ) + Chr( 10 ) + cExtractedText
         else
            hResult["success"] := .t.
            hResult["text"] := "No useful results found on Wikipedia for this query."
         endif

         // Log for debugging
         LogTrace( "WebSearchWiki query execution: " + hb_HGetDef( hArgs, "query", "" ) + " ( Results length: " + AllTrim( Str( Len( cExtractedText ) ) ) + " )" )

      else
         hResult["error"] := "Curl error fetching search results: " + hb_ValToStr( nError )
         LogTrace( "WebSearchWiki CURL ERR: " + AllTrim( Str( nError ) ) )
      endif
      curl_easy_cleanup( hCurl )
   else
      hResult["error"] := "Curl init failed in WebSearchWiki"
   endif

   return hResult
