#include "hbclass.ch"
#include "fileio.ch"

function Aios_UiPlanTasks( hArgs )

    local cJson, hResponse
    local cPlanId, aTasks, hTask, aSteps, hStep, cMdContent := ""
    local cFileName := hb_DirBase() + "persona\TASKS.md"
    local lIsCreation := .T.

    // Extraemos el objeto tareas crudo que nos paso gemini
    if ! hb_HHasKey( hArgs, "tasks" ) .or. ! hb_HHasKey( hArgs, "plan_id" )
        return { "success" => .F., "error" => "Falta el array de tareas o el plan_id en la invocacion" }
    endif
   
    // DEBUG: Ver qué envió Gemini realmente
    LogTrace( "ui_plan_tasks Args: " + hb_jsonEncode( hArgs ) )
   
    cPlanId := hb_ValToStr( hArgs["plan_id"] )
    aTasks := hArgs["tasks"]

    // Determinamos si es un plan nuevo o una actualización
    for each hTask in aTasks
        if ValType( hTask ) == "H" .and. hb_HGetDef( hTask, "status", "" ) == "completed"
            lIsCreation := .F.
        endif
        if ValType( hTask ) == "H" .and. hb_HHasKey( hTask, "steps" ) .and. ValType( hTask["steps"] ) == "A"
            aSteps := hTask["steps"]
            for each hStep in aSteps
                if ValType( hStep ) == "H" .and. hb_HGetDef( hStep, "status", "" ) == "completed"
                    lIsCreation := .F.
                endif
            next
        endif
    next

    // Generamos el Markdown
    cMdContent += "# Plan de Acción: " + cPlanId + hb_OsNewLine() + hb_OsNewLine()
    for each hTask in aTasks
        if ValType( hTask ) == "H"
            cMdContent += "- " + iif( hTask["status"] == "completed", "[x]", "[ ]" ) + " " + ;
                hb_HGetDef( hTask, "name", "" ) + ": " + hb_HGetDef( hTask, "description", "" ) + hb_OsNewLine()
         
            if hb_HHasKey( hTask, "steps" ) .and. ValType( hTask["steps"] ) == "A"
                aSteps := hTask["steps"]
                for each hStep in aSteps
                    if ValType( hStep ) == "H"
                        cMdContent += "  - " + iif( hStep["status"] == "completed", "[x]", "[ ]" ) + " " + hb_HGetDef( hStep, "name", "" ) + hb_OsNewLine()
                    endif
                next
            endif
            cMdContent += hb_OsNewLine()
        endif
    next
   
    // Guardamos fisicamente
    if ! hb_DirExists( hb_DirBase() + "persona" )
        hb_DirCreate( hb_DirBase() + "persona" )
    endif
    hb_MemoWrit( cFileName, cMdContent )

    // Convertimos el Hash/Array Harbour de vuelta a String JSON puro y a Base64
    cJson := hb_jsonEncode( hArgs["tasks"] )
    cJson := hb_base64Encode( cJson )
   
    // Le respondemos a Gemini que se publico con exito y
    // enviamos el comando JS para que chat.prg renderice el menu
    hResponse := {=>}
    hResponse["success"] := .T.
    hResponse["is_creation"] := lIsCreation
    hResponse["message"] := "Tareas guardadas en TASKS.md y publicadas en la Sidebar con exito."
    hResponse["js_eval"] := "renderAgentTasks('" + cJson + "', '" + cPlanId + "', true)"
   
return hResponse
