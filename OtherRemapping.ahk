#Requires AutoHotkey v2.0
#SingleInstance Force

;@Ahk2Exe-UpdateManifest 2

; Use Windows like Mac OS
; Lucky521
; Virtual-Key Codes 
; https://msdn.microsoft.com/en-us/library/windows/desktop/dd375731(v=vs.85).aspx


;  #	Win (Windows logo key)
;  !	Alt
;  ^	Control
;  +	Shift


; Edit operation (Cmd to Ctrl)
;#s::^s
;#a::^a
;#c::^c
;#v::^v
;#x::^x
;#f::^f
;#z::^z
;#y::^y
;#b::^b
#c::Send("^{vk43}")
#d::Send("^{vk44}")
#x::Send("^{vk58}")
#v::Send("^{vk56}")
!v::Send("#{vk56}")
#s::Send("^{vk53}")
#a::Send("^{vk41}")
#z::Send("^{vk5a}")
#b::Send("^{vk42}")
#f::Send("^{vk46}")
#y::Send("^{vk59}")

!Left::Send("^{vk25}")
!Right::Send("^{vk27}")

; Tab switch 
#t::Send("^{vk54}")
#w::Send("^{vk57}")
#n::Send("^{vk4e}")

#1::Send("^{vk31}")
#2::Send("^{vk32}")
#3::Send("^{vk33}")
#4::Send("^{vk34}")
#5::Send("^{vk35}")
#6::Send("^{vk36}")


; Close windows (Cmd + q to Alt + F4)
;#q::Send("!{F4}")
#q::Send("!{vk73}")


; App switch (Win + (Shift) + Tab to Alt + (Shift) + Tab)
<#Tab::{
    Send("{LAlt Down}{Tab}")
    KeyWait("LWin")
    Send("{LAlt Up}")
}

>#Tab::{
    Send("{RAlt Down}{Tab}")
    KeyWait("RWin")
    Send("{RAlt Up}")
}

<+<#Tab::{
    Send("{LAlt Down}{LShift Down}{Tab}")
    KeyWait("LWin")
    KeyWait("LShift")
    Send("{LAlt Up}")
}

<+>#Tab::{
    Send("{RAlt Down}{LShift Down}{Tab}")
    KeyWait("RWin")
    KeyWait("LShift")
    Send("{LAlt Up}")
}

>+<#Tab::{
    Send("{LAlt Down}{RShift Down}{Tab}")
    KeyWait("LWin")
    KeyWait("RShift")
    Send("{LAlt Up}")
}

>+>#Tab::{
    Send("{RAlt Down}{RShift Down}{Tab}")
    KeyWait("RWin")
    KeyWait("RShift")
    Send("{RAlt Up}")
}

#HotIf WinExist("ahk_group AltTabWindow")
~*Esc::Send "{Alt Up}"  ; 取消菜单时, 自动释放 Alt 键.
#HotIf

#HotIf !WinExist("ahk_group AltTabWindow")
!Tab::Send "{Tab}"
+!Tab::Send "+{Tab}"
#HotIf


; Virtual Desktop overview
^Up::Send("#{vk9}")


; Virtual Desktop switch
^Left::Send("^#{vk25}")
^Right::Send("^#{vk27}")

