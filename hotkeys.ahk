; Run Terminal on Win+T
#t::
    If WinExist("ahk_exe WindowsTerminal.exe")
        WinActivate
    else
        Run,"%LocalAppData%\Microsoft\WindowsApps\wt.exe"
return

#x::
    ; msrdc.exe is the Remote Desktop client for Windows; in this case it'll be the Warp Terminal remote window
    If WinExist("ahk_exe msrdc.exe")
        WinActivate
    else
        Run, wsl warp-terminal, , Hide
return

#b::
    If WinExist("ahk_exe vivaldi.exe")
        WinActivate
    else
        Run, "C:\Program Files\Vivaldi\Application\vivaldi.exe"
return

#o::
    If WinExist("ahk_exe Obsidian.exe")
        WinActivate
    else
        Run, "C:\Users\%username%\AppData\Local\Obsidian\Obsidian.exe"
return

#c::
    If WinExist("ahk_exe cursor.exe")
        WinActivate
    else if WinExist("ahk_exe code.exe")
        WinActivate
return
