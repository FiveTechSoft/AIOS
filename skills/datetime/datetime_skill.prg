// datetime_skill.prg - Date and Time utilities for HIX AIOS

function Aios_DateTime()
   local hR := { "success" => .t. }
   local dDate := Date()
   local cTime := Time()
   local aDays := { "Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado" }

   hR["date"] := DToC( dDate )
   hR["time"] := cTime
   hR["day_of_week"] := aDays[ DoW( dDate ) ]
   hR["day"] := Day( dDate )
   hR["month"] := Month( dDate )
   hR["year"] := Year( dDate )
   hR["full_iso"] := TToS( hb_DateTime() )

   hR["notes"] := "Current server local time. Use this to relative date calculations."
   retu hR
