; Include here the windows, processes and games that you want to exclude from the script
windows := ["Program Manager", "Start", "Search", "System tray overflow window.", "Quick Settings", "Windows Default Lock Screen", "Tela de Bloqueio padrão do Windows"]
processes := ["explorer.exe", "firefox.exe", "zen.exe", "devenv.exe", "jetbrains-toolbox.exe", "thunderbird.exe", "mstsc.exe", "League of Legends.exe"]
games := ["Warcraft III", "League of Legends", "Warhammer: Vermintide 2"]
controls := ["Button2", "TrayShowDesktopButtonWClass1"] ; "TrayButton4", "ToolbarWindow323"
hide := true
modified := []

;SetWorkingDir, %A_ScriptDir%
;Menu, Tray, Icon, unite.ico

#Persistent
SetTimer, OnPeriod, 100
return

; ---------------------------------------- Hotkeys ----------------------------------------
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

; --------------------------------------- Functions ---------------------------------------
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

IsWindowMaximized(id) {
    WinGet, maximized, MinMax, ahk_id %id%

    return maximized = 1
}

IsTitleBarVisible(id) {
    WinGet, Style, Style, ahk_id %id% 

    return (Style & 0xC00000)
}

IsMouseOnPrimaryMonitor() {
    CoordMode, Mouse, Screen
    MouseGetPos, mouseX, mouseY
    SysGet, count, MonitorCount
    SysGet, primary, MonitorPrimary

    Loop, %count% {
        SysGet, monitor%A_Index%, Monitor, %A_Index%

        if (mouseX >= monitor%A_Index%left) && (mouseX < monitor%A_Index%right) && (mouseY >= monitor%A_Index%top) && (mouseY < monitor%A_Index%bottom) {
            current := A_Index
            break
        }
    }

    return current = primary
}

IsMouseAtBottom() {
    CoordMode, Mouse, Screen
    MouseGetPos, x, y, id

    ; ToolTip, % "x: " x "`n" "y: " y "`n" "width: " GetMonitorWidth(GetWindowMonitor(id)) "`n" "height: " GetMonitorHeight(GetWindowMonitor(id)) "`n" "A_ScreenHeight: " A_ScreenHeight

    return y >= A_ScreenHeight - 3
}

IsExcluded(value, array) {
    for index, element in array {
        if (InStr(value, element)) {
            return true
        }
    }

    return false
}

GetWindowMonitor(id) {
    SysGet, count, MonitorCount
    WinGetPos, x, y, width, height, ahk_id %id%

    x := x + width / 2
    y := y + height / 2

    Loop, %count% {
        SysGet, monitor%A_Index%, Monitor, %A_Index%

        if (x >= monitor%A_Index%left && x < monitor%A_Index%right && y >= monitor%A_Index%top && y < monitor%A_Index%bottom) {
            return A_Index
        }
    }

    return 1
}

GetMonitorWidth(id) {
    SysGet, monitor%id%, Monitor, %id%

    return monitor%id%right - monitor%id%left
}

GetMonitorHeight(id) {
    SysGet, monitor%id%, Monitor, %id%

    return monitor%id%bottom - monitor%id%top
}

GetWindowTitle(id) {
    WinGetTitle, title, ahk_id %id%

    return title
}

GetProcessName(id) {
    WinGet, ProcessName, ProcessName, ahk_id %id%

    return ProcessName
}

GetWindowIdUnderMouse() {
    MouseGetPos, , , id

    return id
}

GetCurrentWindowId() {
    WinGet, id, ID, A

    return id
}

GetWindowsVersion() {
    version := DllCall("GetVersion") & 0xFF
    build := DllCall("GetVersion") >> 16 & 0xFFFF

    if (version = 10) {
        if (build >= 22000) {
            return 11
        } else {
            return 10
        }
    } else {
        return 11
    }
}

SetTaskbarOnTop() {
    WinSet, AlwaysOnTop, off, ahk_class Shell_TrayWnd
    WinSet, AlwaysOnTop, on, ahk_class Shell_TrayWnd
}

ShowTitleBar(id) {
    WinSet, Style, +0xC00000, ahk_id %id%
}

HideTitleBar(id) {
    global modified

    SysGet, count, MonitorCount
    WinSet, Style, -0xC00000, ahk_id %id%

    modified.Push(id)

    ; This is a workaround for Windows 10 weird behavior when the title bar is hidden.
    ; Could also be caused when the monitors have different resolutions.
    if (GetWindowsVersion() <= 10 && count > 1) {
        monitor := GetWindowMonitor(id)

        ; I'm assuming that the monitor 1 is in the left side of the monitor 2 (Check Display Settings)
        if (monitor = 2) {
            Send, {LWin Down}{LShift Down}{Right}{LWin Up}{LShift Up}
            Send, {LWin Down}{LShift Down}{Left}{LWin Up}{LShift Up}
        } else {
            Send, {LWin Down}{LShift Down}{Left}{LWin Up}{LShift Up}
            Send, {LWin Down}{LShift Down}{Right}{LWin Up}{LShift Up}
        }
    }
}

HandleModified() {
    global modified
    output := ""

    For index, id in modified {
        if (!IsWindowMaximized(id)) {
            ShowTitleBar(id)
            modified.RemoveAt(index)
            break
        }
    }

    ; For _, value in modified {
    ;     output .= value " "
    ; }

    ; ToolTip, %output%
}

; --------------------------------------- ; Callback --------------------------------------
OnPeriod:
    global hide
    global controls
    id := GetWindowIdUnderMouse()
    active := GetCurrentWindowId()
    title := GetWindowTitle(active)
    process := GetProcessName(active)

    ; ToolTip, % GetWindowTitle(id) "`n" GetProcessName(id)

    HandleModified()

    ; Window management
    if (IsMouseOnPrimaryMonitor() && IsMouseAtBottom() && IsWindowMaximized(id) && !IsTitleBarVisible(id)) {
        SetTaskbarOnTop()
    }

    if (!IsExcluded(title, windows) && !IsExcluded(process, processes) && !IsExcluded(title, games)) {
        if (IsWindowMaximized(active) && IsTitleBarVisible(active)) {
            HideTitleBar(active)
        }
    }

    ; Tray management
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