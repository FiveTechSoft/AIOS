// image_gen.prg - AI Image Generation Skill via Pollinations.ai API
// Returns a markdown image that the AIOS chat frontend will render.

function Aios_ImageGen( hArgs )

    local hResult := { "success" => .f., "text" => "" }
    local cPrompt, cUrl, cSeed

    cPrompt := hb_HGetDef( hArgs, "prompt", "" )
    if Empty( cPrompt )
    hResult["error"] := "El prompt para generar la imagen está vacío o no fue proveído."
    return hResult
    endif

    // Replace spaces with URL-friendly %20 and build the request URL
    cPrompt := StrTran( cPrompt, " ", "%20" )
   
    // Random seed so identical prompts give different variations 
    cSeed := hb_ValToStr( hb_RandomInt( 100000, 999999 ) )

    // Fast, free, URL-based image generation (Pollinations AI / Stable Diffusion)
    cUrl := "https://image.pollinations.ai/prompt/" + cPrompt + "?width=1024&height=1024&nologo=true&seed=" + cSeed

    hResult["success"] := .t.
    hResult["text"] := "🖼️ ¡Aquí tienes la imagen generada!" + Chr(13) + Chr(10) + Chr(13) + Chr(10) + "![Imagen Generada por IA](" + cUrl + ")"

    LogTrace( "ImageGen execution for prompt: " + cPrompt )

return hResult
