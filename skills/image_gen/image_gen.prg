// image_gen.prg - AI Image Generation Skill via Gemini Imagen 3
// Returns a base64 markdown image that the AIOS chat frontend will render.

function Aios_ImageGen( hArgs )

    local hResult := { "success" => .f., "text" => "" }
    local cPrompt, cUrl, hCurl, cApiKey, cJson, nError, cResponse, hJson
    local cBase64Image := ""

    cPrompt := hb_HGetDef( hArgs, "prompt", "" )
    if Empty( cPrompt )
        hResult["error"] := "El prompt para generar la imagen está vacío o no fue proveído."
        return hResult
    endif

    cApiKey := GetAiosApiKey()
    if Empty( cApiKey )
        hResult["error"] := "No se encontró la API Key de Gemini. Asegúrate de configurarla."
        return hResult
    endif
    cUrl := "https://generativelanguage.googleapis.com/v1beta/models/nano-banana-pro-preview:generateContent?key=" + cApiKey
    
    // Payload for Nano Banana Pro Preview
    cJson := '{"contents":[{"parts":[{"text":"' + StrTran( cPrompt, '"', '\"' ) + '"}]}]}'

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
            hb_jsonDecode( cResponse, @hJson )
    
            LogTrace("ImageGen RAW Response: " + Left(cResponse, 500))

            if hb_IsHash( hJson ) .and. hb_HHasKey( hJson, "candidates" ) .and. Len( hJson["candidates"] ) > 0
                // Extract the base64 string
                if hb_HHasKey( hJson["candidates"][ 1 ], "content" ) .and. hb_HHasKey( hJson["candidates"][ 1 ]["content"], "parts" ) .and. Len( hJson["candidates"][ 1 ]["content"]["parts"] ) > 0
                    if hb_HHasKey( hJson["candidates"][ 1 ]["content"]["parts"][ 1 ], "inlineData" ) .and. hb_HHasKey( hJson["candidates"][ 1 ]["content"]["parts"][ 1 ]["inlineData"], "data" )
                        cBase64Image := hJson["candidates"][ 1 ]["content"]["parts"][ 1 ]["inlineData"]["data"]
                        
                        hResult["success"] := .t.
                        hResult["text"] := "🖼️ ¡Aquí tienes la imagen generada con Nano Banana!" + Chr(13) + Chr(10) + Chr(13) + Chr(10) + "![Imagen Generada por IA](data:image/jpeg;base64," + cBase64Image + ")"
                    else
                        hResult["error"] := "No se pudo extraer inlineData.data de la respuesta."
                    endif
                else
                    hResult["error"] := "No se pudo extraer content.parts de la respuesta."
                endif
            elseif hb_IsHash( hJson ) .and. hb_HHasKey( hJson, "error" )
                hResult["error"] := "Error de Gemini API: " + hb_ValToStr( hJson["error"]["message"] )
            else
                hResult["error"] := "No se pudo extraer la imagen generada de la respuesta (no hay candidates)."
            endif

            LogTrace( "ImageGen execution for prompt: " + cPrompt + " (Success: " + hb_ValToStr( hResult["success"] ) + ")" )
        else
            hResult["error"] := "Curl error fetching image: " + hb_ValToStr( nError )
            LogTrace( "ImageGen CURL ERR: " + AllTrim( Str( nError ) ) )
        endif
        curl_easy_cleanup( hCurl )
    else
        hResult["error"] := "Curl init failed in ImageGen"
    endif

return hResult
