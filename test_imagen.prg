#include "hbcurl.ch"

function main()
    local cPrompt := "A futuristic city in the clouds"
    local cUrl, hCurl, cApiKey, cJson, nError, cResponse, hJson
    local hCfg := {=>}

    hb_jsonDecode( hb_MemoRead( "gemini_config.json" ), @hCfg )
    cApiKey := hb_HGetDef( hCfg, "api_key", "" )

    cUrl := "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict?key=" + cApiKey
    cJson := '{"instances":[{"prompt":"' + StrTran( cPrompt, '"', '\"' ) + '"}],"parameters":{"sampleCount":1}}'

    hCurl := curl_easy_init()
    curl_easy_setopt( hCurl, HB_CURLOPT_POST, .T. )
    curl_easy_setopt( hCurl, HB_CURLOPT_URL, cUrl )
    curl_easy_setopt( hCurl, HB_CURLOPT_HTTPHEADER, { "Content-Type: application/json" } )
    curl_easy_setopt( hCurl, HB_CURLOPT_SSL_VERIFYPEER, .F. )
    curl_easy_setopt( hCurl, HB_CURLOPT_POSTFIELDS, cJson )
    curl_easy_setopt( hCurl, HB_CURLOPT_DL_BUFF_SETUP )

    ? "Calling API..."
    nError := curl_easy_perform( hCurl )
    if nError == HB_CURLE_OK
    cResponse := curl_easy_dl_buff_get( hCurl )
    ? "Raw response length: ", Len(cResponse)
    ? "Response start: ", Left(cResponse, 500)
    else
    ? "Curl error: " + Str(nError)
    endif
    curl_easy_cleanup( hCurl )

return nil
