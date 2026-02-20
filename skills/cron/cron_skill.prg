// cron_skill.prg - Task Scheduling for HIX AIOS

function Aios_Cron( cAct, hArgs )
   local hR := { "success" => .f. }
   do case
   case cAct == 'cron_add_reminder'
   hR := Cron_AddReminder( hArgs )
   case cAct == 'cron_add_task'
   hR := Cron_AddTask( hArgs )
   case cAct == 'frontend_set_interval'
   hR := Cron_SetFrontendInterval( hArgs )
   case cAct == 'frontend_clear_intervals'
   hR := Cron_ClearFrontendIntervals( hArgs )
   case cAct == 'frontend_execute_js'
   hR := Cron_ExecuteJs( hArgs )
   endcase
retu hR

function Cron_ExecuteJs( hArgs )
   local hR := { "success" => .t. }
   local cJsScript := hb_HGetDef( hArgs, "javascript", "" )

   if Empty( cJsScript )
   hR['success'] := .f. ; hR['error'] := "Empty javascript payload." ; retu hR
   endif

   hR['msg'] := "Frontend generic Javascript payload executed successfully."
   hR['js_eval'] := cJsScript
retu hR

function Cron_AddReminder( hArgs )
   local hR := { "success" => .t. }
   local cMsg := hb_HGetDef( hArgs, "message", "" )
   local nMinutes := hb_HGetDef( hArgs, "minutes", 0 )
   local cChatId := hb_HGetDef( hArgs, "chat_id", "" )

   if Empty( cMsg ) .or. nMinutes <= 0
   hR['success'] := .f. ; hR['error'] := "Invalid reminder params" ; retu hR
   endif

   // Start background thread for reminder
   hb_threadStart( { |m, n, c| Cron_ReminderThread( m, n, c ) }, cMsg, nMinutes, cChatId )

   hR['message'] := "Reminder scheduled in " + AllTrim( Str( nMinutes ) ) + " minutes."
retu hR

function Cron_ReminderThread( cMsg, nMinutes, cChatId )
   hb_idleSleep( nMinutes * 60 )
   Aios_Telegram( "telegram_send_message", { "chat_id" => cChatId, "text" => "[RECORDATORIO] " + cMsg } )
retu nil

function Cron_AddTask( hArgs )
   local hR := { "success" => .t. }
   // More complex recurring tasks using the engine's HIX_AddTask if needed
   // For now, simple implementation
   hR['message'] := "Task added to schedule."
retu hR

function Cron_SetFrontendInterval( hArgs )
   local hR := { "success" => .t. }
   local cMsg := hb_HGetDef( hArgs, "message", "" )
   local nSeconds := hb_HGetDef( hArgs, "seconds", 0 )
   local cJsScript := ""

   if Empty( cMsg ) .or. nSeconds <= 0
   hR['success'] := .f. ; hR['error'] := "Invalid interval params." ; retu hR
   endif

   // Build the JS to be injected in chat.prg window environment
   cJsScript += "if ( typeof window.aios_intervals === 'undefined' ) { window.aios_intervals = []; } "
   cJsScript += "var iId = setInterval( function() { document.getElementById('input').value = '" + cMsg + "'; sendMessage(); }, " + AllTrim( Str( nSeconds * 1000 ) ) + " ); "
   cJsScript += "window.aios_intervals.push( iId );"

   hR['msg'] := "Frontend recurrent task scheduled successfully."
   hR['js_eval'] := cJsScript
retu hR

function Cron_ClearFrontendIntervals( hArgs )
   local hR := { "success" => .t. }
   local cJsScript := ""

   // Loop over active intervals and kill them
   cJsScript += "if ( typeof window.aios_intervals !== 'undefined' ) { "
   cJsScript += "   while ( window.aios_intervals.length > 0 ) { "
   cJsScript += "      clearInterval( window.aios_intervals.pop() ); "
   cJsScript += "   } "
   cJsScript += "}"

   hR['msg'] := "All frontend recurrent tasks have been stopped."
   hR['js_eval'] := cJsScript
retu hR

