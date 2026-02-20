// telegram.prg - Telegram Bot API Integration for HIX AIOS
// REVERTED TO HBCURL AS REQUESTED

#include "hbcurl.ch"

function Aios_Telegram( cAct, hP )
   local hR := { "success" => .t. }
   do case
   case cAct == 'telegram_send_message'
      hR := Telegram_SendMessage( hb_HGetDef( hP, "chat_id", "" ), hb_HGetDef( hP, "text", "" ) )
   case cAct == 'telegram_get_updates'
      hR := Telegram_GetUpdates()
   otherwise
      hR := { "success" => .f., "error" => "Telegram action not supported: " + cAct }
   endcase
   retu hR

function Telegram_SendMessage( cChatId, cText )
   local hR := { "success" => .f. }, cToken := GetTelegramToken()
   local cUrl, cPayload, hCurl, nError, cResponse := ""

   if Empty( cToken ) ; hR['error'] := "Token not found" ; retu hR ; endif
   if Empty( cChatId ) ; hR['error'] := "Chat ID required" ; retu hR ; endif

   cUrl := "https://api.telegram.org/bot" + cToken + "/sendMessage"
   cPayload := hb_jsonEncode( { "chat_id" => cChatId, "text" => cText } )

   hCurl := curl_easy_init()
   if ! Empty( hCurl )
      curl_easy_setopt( hCurl, HB_CURLOPT_POST, .T. )
      curl_easy_setopt( hCurl, HB_CURLOPT_URL, cUrl )
      curl_easy_setopt( hCurl, HB_CURLOPT_HTTPHEADER, { "Content-Type: application/json" } )
      curl_easy_setopt( hCurl, HB_CURLOPT_SSL_VERIFYPEER, .F. )
      curl_easy_setopt( hCurl, HB_CURLOPT_POSTFIELDS, cPayload )
      curl_easy_setopt( hCurl, HB_CURLOPT_DL_BUFF_SETUP )

      nError := curl_easy_perform( hCurl )
      if nError == HB_CURLE_OK
         cResponse := curl_easy_dl_buff_get( hCurl )
         hR['success'] := .t. ; hR['raw_response'] := cResponse
      else
         hR['error'] := "Curl error: " + hb_ValToStr( nError )
      endif
      curl_easy_cleanup( hCurl )
   else
      hR['error'] := "Curl init failed"
   endif
   retu hR

function Telegram_GetUpdates()
   local hR := { "success" => .f. }, cToken := GetTelegramToken()
   local cUrl, hCurl, nError, cResponse := "", hResp := {=>}

   if Empty( cToken ) ; hR['error'] := "Token not found" ; retu hR ; endif

   cUrl := "https://api.telegram.org/bot" + cToken + "/getUpdates"

   hCurl := curl_easy_init()
   if ! Empty( hCurl )
      curl_easy_setopt( hCurl, HB_CURLOPT_URL, cUrl )
      curl_easy_setopt( hCurl, HB_CURLOPT_SSL_VERIFYPEER, .F. )
      curl_easy_setopt( hCurl, HB_CURLOPT_DL_BUFF_SETUP )

      nError := curl_easy_perform( hCurl )
      if nError == HB_CURLE_OK
         cResponse := curl_easy_dl_buff_get( hCurl )
         hb_jsonDecode( cResponse, @hResp )
         hR['success'] := .t.
         if ValType( hResp ) == "H" .and. hb_HHasKey( hResp, "result" )
            hR['updates'] := hResp["result"]
         else
            hR['updates'] := cResponse
         endif
      else
         hR['error'] := "Curl error: " + hb_ValToStr( nError )
      endif
      curl_easy_cleanup( hCurl )
   else
      hR['error'] := "Curl init failed"
   endif
   retu hR

function GetTelegramToken()
   local cKey := GetEnv( "TELEGRAM_BOT_TOKEN" ), hCfg := {=>}
   if Empty( cKey ) .and. File( "telegram_config.json" )
      hb_jsonDecode( hb_MemoRead( "telegram_config.json" ), @hCfg )
      if ValType( hCfg ) == "H" ; cKey := hb_HGetDef( hCfg, "bot_token", "" ) ; endif
   endif
   retu cKey
