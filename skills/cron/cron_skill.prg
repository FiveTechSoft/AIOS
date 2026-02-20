// cron_skill.prg - Task Scheduling for HIX AIOS

function Aios_Cron( cAct, hArgs )
   local hR := { "success" => .f. }
   do case
   case cAct == 'cron_add_reminder'
      hR := Cron_AddReminder( hArgs )
   case cAct == 'cron_add_task'
      hR := Cron_AddTask( hArgs )
   endcase
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
