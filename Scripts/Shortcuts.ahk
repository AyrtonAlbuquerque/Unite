controls := ["Button2", "TrayShowDesktopButtonWClass1"] ; "TrayButton4", "ToolbarWindow323"
hide := true

SetTimer, OnPeriod, 200
return

; Hotkeys
^q::
    WinGetTitle, title, A

    if (title != "" && title != "Program Manager" && title != "Start Menu" && title != "Start") {
        WinClose, A
    }
return

^h::
    RegRead, HiddenFiles_Status, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden

    if HiddenFiles_Status = 2
        RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 1
    else
        RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 2
    
    Send, {F5}
return

#f::
    WinGetTitle, title, A

    if (title != "" && title != "Program Manager" && title != "Start Menu" && title != "Start") {
        WinMinimize, A
    }
return

#c::
    window := WinExist("A")

    VarSetCapacity(monitor, 40), NumPut(40, monitor)
    DllCall("GetMonitorInfo", "Ptr", DllCall("MonitorFromWindow", "Ptr", window, "UInt", 0x2), "Ptr", &monitor)

    workLeft := NumGet(monitor, 20, "Int")
    workTop := NumGet(monitor, 24, "Int")
    workRight := NumGet(monitor, 28, "Int")
    workBottom := NumGet(monitor, 32, "Int")

    WinGetPos, , , W, H, A
    WinGet, Style, Style, A

    if (Style & 0x20000) {
        WinMove, A, , workLeft + (workRight - workLeft) // 2 - W // 2, workTop + (workBottom - workTop) // 2 - H // 2
    }
return

!t::
    global hide
    hide := !hide
return

; Functions
IsControlVisible(control) {
    ControlGet, visible, Visible, , % control, ahk_class Shell_TrayWnd
    
    return visible
}

IsTrayVisible() {
    global controls

    for all, control in controls {
        if (IsControlVisible(control)) {
            return true
        }
    }

    return false
}

OnPeriod:
    global hide
    global controls

    if (IsTrayVisible() && hide) {
        for all, control in controls {
            Control, Hide, , % control, ahk_class Shell_TrayWnd
        }
    } 
    else if (!IsTrayVisible() && !hide) {
        for all, control in controls {
            Control, Show, , % control, ahk_class Shell_TrayWnd
        }
    }
return