#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook true
; macOS shortcuts on Windows for an ANSI keyboard laid out like a Mac:
; physical Alt = Cmd, physical Win = Option, Ctrl = Ctrl.
; Shortcuts do not reach elevated (admin) windows such as Task Manager.

A_MenuMaskKey := "vkE8"

GroupAdd "Term", "ahk_exe WindowsTerminal.exe"
GroupAdd "Term", "ahk_class ConsoleWindowClass"
; WSLg windows (Ghostty). Ghostty handles Cmd (Alt) itself; see ~/.config/ghostty/config.
; shortcut: matches every WSLg app, add per-app rules if you run other Linux GUI apps.
GroupAdd "WSLg", "ahk_exe msrdc.exe"

SendKeys(keys, *) => Send(keys)

; Turn every shortcut off while a game has focus (in CS2, Ctrl+A is crouch-strafe, not Home).
; Add new games by process name (Task Manager > Details), between | marks.
Games := "|cs2.exe|PioneerGame.exe|WardogsClient-Win64-Shipping.exe|TslGame.exe|Sand.exe"
    . "|FPSAimTrainer-Win64-Shipping.exe|EscapeFromTarkov.exe|League of Legends.exe|Clone Hero.exe|"
SetTimer SuspendInGames, 250
SuspendInGames() {
    try exe := WinGetProcessName("A")
    catch
        return
    Suspend InStr(Games, "|" exe "|") ? 1 : 0
}

; ---------- Cmd+key -> Ctrl+key in normal apps ----------
HotIf (*) => !WinActive("ahk_group Term") && !WinActive("ahk_group WSLg")
for k in StrSplit("abcdefgijklnoprstuvwxyz") {
    Hotkey "!" k, SendKeys.Bind("^" k)
    Hotkey "!+" k, SendKeys.Bind("^+" k)
}
for k in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "=", "-", ",", ".", "/", ";", "Enter"]
    Hotkey "!" k, SendKeys.Bind("^{" k "}")
HotIf

#HotIf !WinActive("ahk_group Term") && !WinActive("ahk_group WSLg")
; Text navigation: Cmd = line/document, Option = word.
!Left::Send "{Home}"
!Right::Send "{End}"
!Up::Send "^{Home}"
!Down::Send "^{End}"
!+Left::Send "+{Home}"
!+Right::Send "+{End}"
!+Up::Send "^+{Home}"
!+Down::Send "^+{End}"
!Backspace::Send "+{Home}{Backspace}"
!Delete::Send "+{End}{Delete}"
#Left::Send "^{Left}"
#Right::Send "^{Right}"
#+Left::Send "^+{Left}"
#+Right::Send "^+{Right}"
#Backspace::Send "^{Backspace}"
#Delete::Send "^{Delete}"
; Ctrl+A / Ctrl+E jump to line start/end, like Cocoa text fields.
^a::Send "{Home}"
^e::Send "{End}"
^+a::Send "+{Home}"
^+e::Send "+{End}"
; Cmd+Shift+[ / ] switch tabs.
!+[::Send "^{PgUp}"
!+]::Send "^{PgDn}"
#HotIf

#HotIf WinActive("ahk_exe chrome.exe")
![::Send "!{Left}"
!]::Send "!{Right}"
#HotIf

#HotIf WinActive("ahk_exe Code.exe")
; Option+Up/Down moves lines, Option+Shift+Up/Down copies them.
#Up::Send "!{Up}"
#Down::Send "!{Down}"
#+Up::Send "!+{Up}"
#+Down::Send "!+{Down}"
#HotIf

#HotIf WinActive("ahk_group Term")
!c::Send "^+c"
!v::Send "^+v"
!a::Send "^+a"
!f::Send "^+f"
!t::Send "^+t"
!n::Send "^+n"
!w::Send "^+w"
!d::Send "!+{=}"
!+d::Send "!+{-}"
![::Send "!{Left}"
!]::Send "!{Right}"
!+[::Send "^+{Tab}"
!+]::Send "^{Tab}"
!=::Send "^{=}"
!-::Send "^{-}"
!0::Send "^0"
!,::Send "^,"
!1::Send "^!1"
!2::Send "^!2"
!3::Send "^!3"
!4::Send "^!4"
!5::Send "^!5"
!6::Send "^!6"
!7::Send "^!7"
!8::Send "^!8"
!9::Send "^!9"
; Shell line editing (zsh emacs keys). Home/End, not Ctrl+A, because Ctrl+A is the tmux prefix.
!Left::Send "{Home}"
!Right::Send "{End}"
!Backspace::Send "^u"
#Left::Send "!b"
#Right::Send "!f"
#Backspace::Send "!{Backspace}"
#Delete::Send "!d"
#HotIf

#HotIf WinActive("ahk_group WSLg")
; WSLg drops the Win key, so Option goes to Ghostty as Ctrl+Alt.
!Left::Send "{Home}"
!Right::Send "{End}"
#Left::Send "^!{Left}"
#Right::Send "^!{Right}"
#Backspace::Send "^!{Backspace}"
#HotIf

; ---------- Everywhere ----------
; A lone Cmd tap must not open app menu bars.
~LAlt::Send "{Blind}{vkE8}"
~RAlt::Send "{Blind}{vkE8}"
!q::Send "!{F4}"
!h::WinMinimize "A"
!m::WinMinimize "A"
!Space::Send "#s"
!SC029::CycleAppWindows()  ; SC029 is the ` key
!+3::Send "{PrintScreen}"
!+4::Send "#+s"
!+5::Send "#+s"
^!q::DllCall "LockWorkStation"
^Left::Send "^#{Left}"
^Right::Send "^#{Right}"
^Up::Send "#{Tab}"

; Cmd+` cycles the windows of the active app.
CycleAppWindows() {
    exe := WinGetProcessName("A")
    wins := []
    for hwnd in WinGetList("ahk_exe " exe)
        if WinGetTitle(hwnd) != "" && WinGetMinMax(hwnd) != -1
            wins.Push(hwnd)
    if wins.Length > 1
        WinActivate wins[wins.Length]
}
