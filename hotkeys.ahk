#Requires AutoHotkey v2.0.2
#SingleInstance Force

; Run Terminal on Win+T
#t::
{
    if WinExist("ahk_exe WindowsTerminal.exe")
        WinActivate()
    else
        Run("wt.exe")
}

; ^#t::
; {
;     if WinExist("ahk_exe warp.exe")
;         WinActivate()
;     else
;         Run("C:\Program Files\Warp\warp.exe")
; }

#x::
{
    ; msrdc.exe is the Remote Desktop client for Windows; in this case it'll be the Warp Terminal remote window
    if WinExist("ahk_exe msrdc.exe")
        WinActivate()
    else
        Run("wsl warp-terminal", , "Hide")
}

#b::
{
    if WinExist("ahk_exe vivaldi.exe")
        WinActivate()
    else
        Run("C:\Users\" A_UserName "\AppData\Local\Vivaldi\Application\vivaldi.exe")
}

#o::
{
    if WinExist("ahk_exe Obsidian.exe")
        WinActivate()
    else
        Run("C:\Users\" A_UserName "\AppData\Local\Obsidian\Obsidian.exe")
}

#c::
{
    if WinExist("ahk_exe cursor.exe")
        WinActivate()
    else if WinExist("ahk_exe code.exe")
        WinActivate()
    else if WinExist("ahk_exe windsurf.exe")
        WinActivate()
}

