#Requires AutoHotkey v2.0
#SingleInstance Force
A_IconHidden := true

global IniFile := EnvGet("APPDATA") "\WinEasyLaunch\WinEasyLaunch.ini"
global ProfileNames := []

; --- Ensure config exists ---
if !FileExist(IniFile) {
    DirCreate(EnvGet("APPDATA") "\WinEasyLaunch")
    FileAppend("", IniFile)
}

; --- Read [Config] section ---
Title     := IniRead(IniFile, "Config", "Title", "WinEasyLaunch")
IconFile  := IniRead(IniFile, "Config", "IconFile", "shell32.dll")
IconIndex := IniRead(IniFile, "Config", "IconIndex", "44")
AlwaysOnTop := IniRead(IniFile, "Config", "AlwaysOnTop", "0")
ShowEdit  := IniRead(IniFile, "Config", "ShowEdit", "1")

TraySetIcon(IconFile, IconIndex + 0)

; --- Build GUI ---
opts := "+Resize -MaximizeBox" (AlwaysOnTop = "1" ? " +AlwaysOnTop" : "")
myGui := Gui(opts, Title)
myGui.SetFont("s10")
lb := myGui.Add("ListBox", "w300 h300 vSel")
lb.OnEvent("DoubleClick", Launch)
myGui.Add("Button", "w300", "Launch").OnEvent("Click", Launch)
if (ShowEdit = "1")
    myGui.Add("Button", "w300", "Edit Config").OnEvent("Click", (*) => Run("notepad.exe " IniFile))
myGui.Show()

; --- Load profiles (after GUI exists) ---
LoadProfiles()

; --- Enter key launches selected profile ---
#HotIf WinActive(Title)
Enter::Launch()
#HotIf

; --- Functions ---

LoadProfiles() {
    global lb, IniFile, ProfileNames
    Loop Read IniFile {
        if RegExMatch(A_LoopReadLine, "^\s*\[(.+?)\]\s*$", &m) {
            name := m[1]
            if (name != "Config")
                ProfileNames.Push(name)
        }
    }
    if ProfileNames.Length
        lb.Add(ProfileNames)
}

GetSelected() {
    global lb, ProfileNames
    idx := lb.Value
    if (idx < 1 || idx > ProfileNames.Length)
        return ""
    return ProfileNames[idx]
}

Launch(*) {
    global IniFile
    name := GetSelected()
    if (name = "")
        return
    try {
        exe  := IniRead(IniFile, name, "Exe", "")
        args := IniRead(IniFile, name, "Args", "")
        if (exe = "") {
            MsgBox("Profile '" name "' has no Exe set.", "Error", "Icon!")
            return
        }
        section := IniRead(IniFile, name, , "")
        for line in StrSplit(section, "`n", "`r") {
            if (line = "")
                continue
            eq := InStr(line, "=")
            if !eq
                continue
            key := Trim(SubStr(line, 1, eq - 1))
            val := Trim(SubStr(line, eq + 1))
            if (key = "Exe" || key = "Args")
                continue
            args := StrReplace(args, "%" key "%", val)
        }
        Run('"' exe '" ' args)
    } catch as e {
        MsgBox(e.Message, "Error", "Icon!")
    }
}