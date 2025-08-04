#Requires AutoHotkey v2.0
#SingleInstance Force

;@Ahk2Exe-UpdateManifest 2, CapsLockMapping, , 0

DEBUG := false

; 让脚本在后台持续运行
Persistent()
CN_Code := 0x804, EN_Code := 0x409 ; KBL代码

; ------------------------------------------------------------
;  Wnd helpers
; ------------------------------------------------------------
Imm32 := DllCall("LoadLibrary", "Str", "imm32", "Ptr")
ImmGetDefaultIMEWnd := DllCall("GetProcAddress", "Ptr", Imm32, "AStr",
    "ImmGetDefaultIMEWnd", "Ptr")

getFocusWnd() {
    fg := WinExist("A")
    if !fg
        return 0

    if WinGetClass(fg) = "ConsoleWindowClass" {
        DetectHiddenWindows True
        conhostHWnd := WinExist("ahk_exe conhost.exe")
        DetectHiddenWindows False
        if conhostHWnd
            return conhostHWnd
    }

    tid := DllCall("GetWindowThreadProcessId", "Ptr", fg, "UInt*", 0)
    size := 8 + 6 * A_PtrSize + 16          ; sizeof(GUITHREADINFO)
    buf := Buffer(size, 0), NumPut("UInt", size, buf)
    if DllCall("GetGUIThreadInfo", "UInt", tid, "Ptr", buf) {
        hWnd := Numget(buf, 8 + A_PtrSize, "Ptr") ; hWndFocus
        return hWnd ? hWnd : fg
    }
    return fg
}

getIMEWnd(hWnd) {
    global ImmGetDefaultIMEWnd
    return DllCall(ImmGetDefaultIMEWnd, "Ptr", hWnd, "Ptr")
}

; ------------------------------------------------------------

; ------------------------------------------------------------
;  IME mode helpers – Win32 / IMM32, AutoHotkey v2
; ------------------------------------------------------------
;  ImeNativeMode
;     nativeOn = true   → Chinese  (中)
;     nativeOn = false  → English  (EN)
; ------------------------------------------------------------

WM_IME_CONTROL := 0x0283
IMC_GETCONVERSIONMODE := 0x0001
IMC_SETCONVERSIONMODE := 0x0002

IME_CMODE_ALPHANUMERIC := 0x0000      ; EN
IME_CMODE_NATIVE := 0x0001      ; 中

GetImeConversionMode(imeWnd) {
    return SendMessage(WM_IME_CONTROL, IMC_GETCONVERSIONMODE, 0, , imeWnd)
}

SetImeConversionMode(imeWnd, conv) {
    return SendMessage(WM_IME_CONTROL, IMC_SETCONVERSIONMODE, conv, , imeWnd)
}

GetImeNativeMode(imeWnd) {
    conv := SendMessage(WM_IME_CONTROL, IMC_GETCONVERSIONMODE, 0, , imeWnd)
    return (conv & IME_CMODE_NATIVE) ? true : false
}

SetImeNativeMode(imeWnd, nativeOn := true) {
    conv := 0, sent := 0

    if nativeOn {
        conv &= ~IME_CMODE_ALPHANUMERIC     ; clear EN
        conv |= IME_CMODE_NATIVE           ; set  中
    } else {
        conv &= ~IME_CMODE_NATIVE           ; clear 中
        conv |= IME_CMODE_ALPHANUMERIC     ; set  EN
    }

    SetImeConversionMode(imeWnd, conv)
    return true
}

; ------------------------------------------------------------

; ------------------------------------------------------------
;  Keyboard-layout helpers  (HKL = handle to keyboard layout)
;  Doc: https://learn.microsoft.com/en-us/windows/win32/Intl/language-identifiers
; ------------------------------------------------------------
;  Functions
;    GetInputLocaleID(hWnd)        → returns HKL of the thread of given hWnd
;    SetInputLocaleID(hKL, hWnd)   → activates the layout on behalf of given hWnd
; ------------------------------------------------------------
;  Layout IDs you may find useful
;    "00000409"   English (United States)
;    "00000804"   Chinese (Simplified, PRC) – Microsoft Pinyin
;    "00000404"   Chinese (Traditional, Taiwan)
;    "00000c04"   Chinese (Traditional, Hong-Kong S.A.R.)
;    "00001404"   Chinese (Traditional, Macao)
;    "00000411"   Japanese (IME)
; ------------------------------------------------------------

WM_INPUTLANGCHANGEREQUEST := 0x0050

FormatHKL(hKL) => Format("0x{:08X}", hKL & 0xffffffff)

;
GetInputLocaleID(hWnd) {
    tid := DllCall("GetWindowThreadProcessId", "Ptr", hWnd, "UInt*", 0, "UInt")
    ; GetKeyboardLayout: https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getkeyboardlayout
    hKL := DllCall("GetKeyboardLayout", "UInt", tid, "Int")

    if (hKL = 0) {
        TrayTip "HKL获取失败，可能是因为没有焦点窗口或当前窗口不支持获取键盘布局。", "CapsLockRemapping出现错误", "Iconx"
        return 0
    }

    return hKL
}

GetLcid(hWnd) {
    hKL := GetInputLocaleID(hWnd)
    return GetLcidFromInputLocaleID(hKL)
}

GetLcidFromInputLocaleID(hKL) {
    return hKL & 0xFFFF ; 低16位
}

SetInputLocaleID(hKL, hWnd) {
    return SendMessage(WM_INPUTLANGCHANGEREQUEST, 0, hKL, , hWnd)
}

;-----------------------------------------------------------------------

CapsLock:: {
    FocusHWnd := getFocusWnd()
    if !FocusHWnd {
        if DEBUG
            TrayTip "无法获取焦点窗口。", "CapsLockRemapping 出现错误", "Iconx"
        return
    }
    ActiveIMEHWnd := getIMEWnd(FocusHWnd)
    if !ActiveIMEHWnd {
        if DEBUG
            TrayTip "无法获取活动输入法窗口。", "CapsLockRemapping 出现错误", "Iconx"
        return
    }
    LastHKL := GetInputLocaleID(FocusHWnd)
    LastLCID := GetLcidFromInputLocaleID(LastHKL)
    switch LastLCID {
        case CN_Code:
        {
            if (KeyWait("CapsLock", "T0.3")) {
                ;===== 短按 =====
                try {
                    LastIMENativeMode := GetImeNativeMode(ActiveIMEHWnd)
                    SetImeNativeMode(ActiveIMEHWnd, !LastIMENativeMode)
                } catch as e {
                    TrayTip "获取和设置输入法模式失败: " e.message "`n当前 HKL: " FormatHKL(LastHKL), "CapsLockRemapping 出现错误", "Iconx"
                    return
                }
            } else {
                ;===== 长按 =====
                SetCapsLockState !getKeyState("CapsLock", "T")
            }
            KeyWait "CapsLock" ; 等待按键弹起，防止重复触发
        }
        Default: SetCapsLockState !getKeyState("CapsLock", "T")
    }
}
