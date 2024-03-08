#Requires AutoHotkey v2
#SingleInstance Force

; Make sure you run the command "komorebic ahk-library" 
; to generate the required library.

; Make sure the app specific configurations are also
; generated with "komorebic ahk-app-specific-configuration"

; Load library
#Include komorebic.lib.ahk

; ENVIRONMENTAL VARIABLES
global USERPROFILE := EnvGet("USERPROFILE")
global KOMOREBICONFIG := USERPROFILE . "\komorebi.awk"
global KOMOREBIJSON := USERPROFILE . "\komorebi.json"
global EDITOR := USERPROFILE . "\scoop\apps\neovim\current\bin\nvim.exe"

; SCRIPT ICON
TraySetIcon USERPROFILE . "\script_icons\omega256.ico"

; STARTUP DEFAULTS
; disable alt-tab
!Tab::Return
; swap escape and caps lock:
Capslock::Esc
Esc::Capslock
; Activate start menu with ctrl+alt+space:
^!Space Up::Send "{Control Up}{Alt Up}{LWin}" 
; Disables start menu from activating on a single press:
~LWin::Send "{Blind}{vkE8}" 
; Rebind Appskey (menu key) to LWin and stop it from activating:
AppsKey::
{
	Send "{LWin down}"
	KeyWait "AppsKey"
	Send "{Ctrl down}{LWin up}{Ctrl up}"
}
; use win+tab as alt tab, currently unused
;#Tab::
;{   
;  Send "{LAlt Down}{Tab}"          
;  KeyWait "LWin"  ; Wait to release left Win key
;  Send "{LAlt Up}" ; Close switcher on hotkey release
;}

; FOCUS WINDOWS
; #h::Focus("left")
; #j::Focus("down")
; #k::Focus("up")
; #l::Focus("right")
#k::CycleFocus("previous")
#j::CycleFocus("next")

; MOVE WINDOWS
;#+h::Move("left")
;#+j::Move("down")
;#+k::Move("up")
;#+l::Move("right")

#+j::CycleMove("next")
#+k::CycleMove("previous")
#Space::Promote()

; STACK WINDOWS
#Left::Stack("left")
#Right::Stack("right")
#Up::Stack("up")
#Down::Stack("down")
#;::Unstack()
#[::CycleStack("previous")
#]::CycleStack("next")

; RESIZE
;#+=::ResizeAxis("vertical", "increase")
;#+-::ResizeAxis("vertical", "decrease")
;#=::ResizeAxis("horizontal", "increase")
;#-::ResizeAxis("horizontal", "decrease")
#h::
{
Resize("left", "increase")
Resize("right", "decrease")
}
#l::
{
Resize("left", "decrease")
Resize("right", "increase")
}


; MANIPULATE WINDOWS
#+Space::ToggleFloat()
#q::WinClose(WinGetTitle("A"))
;#q::Close()


; WINDOW MANAGER OPTIONS
#+r::Retile()
#+Insert::TogglePause()
;#m::ToggleMaximize()
^!+m::Manage()
#m:: {                                    
    Static toggle := 1                          
    toggle := !toggle                           
    if toggle {
     WinRestore(WinGetTitle("A"))            
    }
    else {
      WinMaximize(WinGetTitle("A"))                
    }
}
#f::FullScreen("A")  
; Toggle fullscreen
; uses same parameters as WinExist
FullScreen(winTitle*) {
static MONITOR_DEFAULTTONEAREST := 0x00000002
static WS_CAPTION               := 0x00C00000
static WS_SIZEBOX               := 0x00040000
static Border                   := WS_CAPTION|WS_SIZEBOX
static IsBorderless             := "AHK:BorderlessFullscreen"
static IsMaxed                  := "AHK:FullscreenPrevMax"
static propX                    := "AHK:FullscreenPrevX"
static propY                    := "AHK:FullscreenPrevY"
static propW                    := "AHK:FullscreenPrevW"
static propH                    := "AHK:FullscreenPrevH"
if !hwnd := WinExist(winTitle*)
    return 0
if WinGetClass(hwnd) = "ApplicationFrameWindow" {
    Send "#+{Enter}"
    return
}
if WinGetClass(hwnd) = "CabinetWClass" && WinGetProcessName(hwnd) = "explorer.exe" {
    ControlSend "{F11}", hwnd
    return
}    
if !GetProp(hwnd, IsBorderless) { ; If not borderless
    GetWindowPlacement(hwnd, &X, &Y, &W, &H)
    SetProp(hwnd, propX, X, propY, Y, propW, W, propH, H)
    if maxState := WinGetMinMax(hwnd) = 1 ? true : false { ; Save max state
        WinGetPos(&X, &Y, &W, &H, hwnd)
        SetWindowPlacement(hwnd, X, Y, W, H) ; Make transition smoother between restoring and fullscreen
        WinRestore hwnd ; Restore window if maximized, some windows can't be moved if maximized
    }
    SetProp(hwnd, IsMaxed, maxState) ; Save minmax state
    WinSetStyle("-" Border, hwnd) ; Remove caption and sizebox from window
    NumPut("uint", 40, monInfo := Buffer(40))
    DllCall("GetMonitorInfo"
        , "ptr", DllCall("MonitorFromWindow", "ptr", hwnd, "uint", MONITOR_DEFAULTTONEAREST) ; hMonitor from nearest monitor to window
        , "ptr", monInfo)
    WinMove(
        monLeft   := NumGet(monInfo, 4, "int"),
        monTop    := NumGet(monInfo, 8, "int"),
        monWidth  := (monRight    := NumGet(monInfo, 12, "Int") - monLeft),
        monHeight := (monBottom   := NumGet(monInfo, 16, "int") - monTop),
        hwnd)
    SetProp(hwnd, IsBorderless, 1)
} else { ; Restore borders and original position
    WinSetStyle "+" Border, hwnd
    X := GetProp(hwnd, propX), Y := GetProp(hwnd, propY), W := GetProp(hwnd, propW), H := GetProp(hwnd, propH)
    if GetProp(hwnd, IsMaxed)
        WinMaximize hwnd
    SetWindowPlacement(hwnd, X, Y, W, H)
    SetProp(hwnd, IsBorderless, 0)
}

SetProp(win, propValue*) {
    if propValue.Length & 1
        throw Error("Invalid number of parameters.", -1)
    loop propValue.Length // 2 {
        prop := propValue[A_Index*2 - 1], value := propValue[A_Index*2]
        DllCall("SetProp", "ptr", win, "str", prop, "ptr", value)
    }
}
GetProp(win, name) => DllCall("GetProp", "ptr", WinExist(win), "str", name)
GetWindowPlacement(hwnd, &X, &Y, &W, &H) {
    NumPut("uint", 44, WP := Buffer(44, 0))
    DllCall("GetWindowPlacement", "Ptr", hwnd, "Ptr", WP)
    X := NumGet(WP, 28, "Int")
    Y := NumGet(WP, 32, "Int")
    W := NumGet(WP, 36, "Int") - X
    H := NumGet(WP, 40, "Int") - Y
}
SetWindowPlacement(hwnd, X, Y, W, H) {
    NumPut("uint", 44, WP := Buffer(44, 0))
    DllCall("GetWindowPlacement", "Ptr", hwnd, "Ptr", WP)
    NumPut("uint", 4, WP, 4) ; WPF_ASYNCWINDOWPLACEMENT
    NumPut("int", X, WP, 28)
    NumPut("int", Y, WP, 32)
    NumPut("int", W + X, WP, 36)
    NumPut("int", H + Y, WP, 40)
    DllCall("SetWindowPlacement", "ptr", hwnd, "ptr", WP)
    }
}

; LAYOUTS
;!x::FlipLayout("horizontal")
;!y::FlipLayout("vertical")
#PgDn::CycleLayout("next")
#PgUp::CycleLayout("previous")

#+u::ToggleMonocle()
#y::ChangeLayout("bsp")
#+t::ChangeLayout("horizontal-stack")
#t::ChangeLayout("vertical-stack")


; WORKSPACES
#1::FocusWorkspace(0)
#2::FocusWorkspace(1)
#3::FocusWorkspace(2)
#4::FocusWorkspace(3)
#5::FocusWorkspace(4)
#6::FocusWorkspace(5)
#7::FocusWorkspace(6)
#8::FocusWorkspace(7)
#9::FocusWorkspace(8)
#0::FocusWorkspace(9)
#Tab::FocusLastWorkspace()
; !WheelUp::CycleWorkspace("next")
; !WheelDown::CycleWorkspace("previous")

; MOVE WINDOWS ACROSS WORKSPACES
#+1::MoveToWorkspace(0)
#+2::MoveToWorkspace(1)
#+3::MoveToWorkspace(2)
#+4::MoveToWorkspace(3)
#+5::MoveToWorkspace(4)
#+6::MoveToWorkspace(5)
#+7::MoveToWorkspace(6)
#+8::MoveToWorkspace(7)
#+9::MoveToWorkspace(8)
#+0::MoveToWorkspace(9)
	
; LAUNCH APPLICATIONS
; terminal
#Enter::Run USERPROFILE . "\AppData\Local\Microsoft\WindowsApps\wt.exe powershell.exe -nologo"
; browser lol
#w:: 
{
	Run "C:\Program Files\Mozilla Firefox\firefox.exe"
	WinWait("Mozilla Firefox")
	WinActivate
 ;  Send "#+r"
  ; Send "#+r"
  ;Promote()
  ;Run "komorebic.exe toggle-title-bars"
}
; file explorer with user home directory
#r:: Run Format("explorer.exe {1}", USERPROFILE)
; screenshot app
+PrintScreen:: Run "SnippingTool.exe"
; system run
#+d:: Run USERPROFILE . "\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\System Tools\Run.lnk"

; SCRIPT HOTKEYS
^!+r::Reload
; for edit to work open the registry editor, go to 
; HKEY_CLASSES_ROOT\AutoHotkeyScript\Shell\Edit\Command 
; and change the default value to your editor command 
; like: "C:\Users\Null\scoop\apps\neovim\current\bin\nvim.exe" "%l"
#+i::Edit
#^i::Run EDITOR . " " . KOMOREBIJSON

; WINDOWS ACTIONS

; session control gui
SysAct := Gui()
SysAct.Title := "System Management Options"
SysAct.Opt("+ToolWindow")  ; +ToolWindow avoids a taskbar button and an alt-tab menu item.
SysAct.SetFont("s12")
SysAct.Add("Text", , "Choose an Action:")

ShutdownSys := SysAct.AddButton("Default w450", "[&S] Shutdown")
RebootSys:= SysAct.AddButton("w450", "[&R] Reboot")
Logoff:= SysAct.AddButton("w450", "[&O] Logoff")
LockSys:= SysAct.AddButton("w450", "[&L] Lock")

ShutdownSys.OnEvent("Click", p1)
RebootSys.OnEvent("Click", p2)
Logoff.OnEvent("Click", p0)
LockSys.OnEvent("Click", Lock)
SysAct.OnEvent("Escape", CloseWithEscape)

p1(*) {
  Shutdown 1
}
p2(*) {
  Shutdown 2
}
p0(*) {
  Shutdown 0
}
; need to re-enable lockworkstation in registry for this to work
Lock(*) {
RegWrite 0, "REG_DWORD", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System", "DisableLockWorkstation"
WinClose(WinGetTitle("A")) ;close session control gui before locking
DllCall("LockWorkStation")
Sleep(1000) ; without delay regWrite will swap back to value 1 before locking can take place
RegWrite 1, "REG_DWORD", "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System", "DisableLockWorkstation"
}
CloseWithEscape(*) {
  WinClose(WinGetTitle("A"))
}

#Backspace::
{
SysAct.Show
; WinSetStyle "-0xC00000", "A" ; Disable titlebar, causes windows to offset a little
}

; ACTIVATE WORKSPACE INDICATOR
Run USERPROFILE . "\Komodo\komotray.ahk"

; NOTIFY WHEN SCRIPT IS LOADED
TrayTip "Hotkeys initialized", "Komorebi", 16
SetTimer HideTrayTip, -3000
HideTrayTip() {
    TrayTip
}
