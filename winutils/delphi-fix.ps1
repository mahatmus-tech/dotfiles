# Hide the PowerShell window
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0) # 0 = SW_HIDE

# Load required assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Define mouse helper class
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public class MouseHelper {
    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);
    [DllImport("user32.dll")]
    public static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, int dwExtraInfo);
    public const uint MOUSEEVENTF_MOVE = 0x0001;
    
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT {
        public int X;
        public int Y;
    }
}
'@

# Create and configure tray icon
$trayIcon = New-Object System.Windows.Forms.NotifyIcon
$trayIcon.Text = "Delphi Fix"
$trayIcon.Icon = [System.Drawing.SystemIcons]::Information
$trayIcon.Visible = $true

# Create context menu
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$exitMenuItem.Text = "Exit"
$exitMenuItem.Add_Click({
    $trayIcon.Visible = $false
    $timer.Stop()
    [System.Windows.Forms.Application]::Exit()
})
$contextMenu.Items.Add($exitMenuItem)
$trayIcon.ContextMenuStrip = $contextMenu

# Set up timer for mouse movement
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 60000 # 60 seconds
$timer.Add_Tick({
    try {
        $point = New-Object MouseHelper+POINT
        [MouseHelper]::GetCursorPos([ref]$point)
        [MouseHelper]::mouse_event([MouseHelper]::MOUSEEVENTF_MOVE, 1, 1, 0, 0)
        [MouseHelper]::mouse_event([MouseHelper]::MOUSEEVENTF_MOVE, -1, -1, 0, 0)
    } catch {}
})

# Start the timer
$timer.Start()

# Keep application running
[System.Windows.Forms.Application]::Run()

# Clean up (though Application::Exit should handle this)
$timer.Dispose()
$trayIcon.Dispose()