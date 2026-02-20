' remind.vbs - Simple and reliable reminder
Dim delay, message
delay = WScript.Arguments(0)
message = WScript.Arguments(1)

WScript.Sleep delay * 1000
MsgBox message, 64, "Recordatorio de Soul"
