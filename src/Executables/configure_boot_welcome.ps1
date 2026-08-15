# ==============================================================================
# Z-LAG OS - Native boot status + native post-boot Welcome installer
# ------------------------------------------------------------------------------
# Secure-screen loading text is supplied by Windows VerboseStatus. The post-boot
# panel is compiled into a normal Windows GUI executable: no VBS launcher and no
# PowerShell script/process is needed at logon. The executable remains visible in
# Task Manager for its five-second lifetime, as every legitimate process must.
# ==============================================================================

$ErrorActionPreference = 'Continue'
$dataDir = Join-Path $env:ProgramData 'Z-LAG-OS'
$coreRoot = Join-Path $env:SystemRoot 'Z-LAG-OS'
$coreDir = Join-Path $coreRoot 'Core'
New-Item -Path $dataDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path $coreDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$logFile = Join-Path $dataDir 'boot_welcome_install.log'

function Write-ZLagLog {
    param([Parameter(Mandatory = $true)][string]$Message)
    $line = '[Z-LAG-WELCOME] ' + $Message
    Write-Output $line
    Add-Content -Path $logFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    Write-ZLagLog 'ERROR: Administrator privileges are required.'
    exit 1
}

# Keep loading text inside the real secure Windows boot/sign-in screen.
$systemPolicy = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
New-Item -Path $systemPolicy -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $systemPolicy -Name 'VerboseStatus' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $systemPolicy -Name 'DisableStatusMessages' -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $systemPolicy -Name 'EnableFirstLogonAnimation' -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null

$welcomeExe = Join-Path $coreDir 'ZLagWelcome.exe'
$tempExe = Join-Path $env:TEMP 'ZLagWelcome.exe'
Remove-Item -LiteralPath $tempExe -Force -ErrorAction SilentlyContinue

# Compile a native WPF WindowsApplication. Source exists only while the playbook
# runs; the permanent artifact is the executable in the protected Windows folder.
$welcomeSource = @'
using System;
using System.Diagnostics;
using System.Linq;
using System.Reflection;
using System.Threading;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Media.Effects;
using System.Windows.Threading;

[assembly: AssemblyTitle("Z LAG Welcome")]
[assembly: AssemblyProduct("Z LAG OS")]
[assembly: AssemblyCompany("Z LAG Community")]
[assembly: AssemblyVersion("5.12.0.0")]

namespace ZLagOS
{
    public static class WelcomeProgram
    {
        private static SolidColorBrush Brush(string value)
        {
            return new SolidColorBrush((Color)ColorConverter.ConvertFromString(value));
        }

        private static TextBlock Text(string value, double size, string color, FontWeight weight)
        {
            return new TextBlock
            {
                Text = value,
                FontSize = size,
                Foreground = Brush(color),
                FontWeight = weight,
                FontFamily = new FontFamily("Segoe UI"),
                TextAlignment = TextAlignment.Center,
                HorizontalAlignment = HorizontalAlignment.Center
            };
        }

        [STAThread]
        public static void Main()
        {
            int session = Process.GetCurrentProcess().SessionId;
            bool created;
            using (var mutex = new Mutex(true, "Local\\ZLAGWelcomePanel_" + session, out created))
            {
                if (!created) return;

                DateTime deadline = DateTime.Now.AddSeconds(30);
                bool desktopReady = false;
                while (DateTime.Now < deadline)
                {
                    desktopReady = Process.GetProcessesByName("explorer").Any(p => p.SessionId == session);
                    if (desktopReady) break;
                    Thread.Sleep(250);
                }
                if (!desktopReady) return;
                Thread.Sleep(1400);

                var app = new Application { ShutdownMode = ShutdownMode.OnMainWindowClose };
                var window = new Window
                {
                    Title = "Welcome to Z LAG OS",
                    Width = 640,
                    Height = 290,
                    Opacity = 0,
                    WindowStyle = WindowStyle.None,
                    ResizeMode = ResizeMode.NoResize,
                    ShowInTaskbar = false,
                    WindowStartupLocation = WindowStartupLocation.CenterScreen,
                    Topmost = true,
                    AllowsTransparency = true,
                    Background = Brushes.Transparent
                };

                var border = new Border
                {
                    CornerRadius = new CornerRadius(18),
                    Background = Brush("#F0111115"),
                    BorderBrush = Brush("#805B4BDE"),
                    BorderThickness = new Thickness(1.4),
                    Padding = new Thickness(34),
                    Effect = new DropShadowEffect { Color = (Color)ColorConverter.ConvertFromString("#AA6C5CE7"), BlurRadius = 28, ShadowDepth = 0, Opacity = 0.45 }
                };
                var grid = new Grid();
                grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
                grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
                grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
                grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
                grid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });

                var welcome = Text("WELCOME TO", 14, "#FFA9A3C7", FontWeights.SemiBold);
                Grid.SetRow(welcome, 0); grid.Children.Add(welcome);
                var title = Text("Z LAG OS", 46, "#FFFFFFFF", FontWeights.Bold);
                title.Margin = new Thickness(0, 5, 0, 0); Grid.SetRow(title, 1); grid.Children.Add(title);
                var line = new Border { Width = 250, Height = 2, CornerRadius = new CornerRadius(1), Margin = new Thickness(0, 15, 0, 15), Background = Brush("#FF6C5CE7"), HorizontalAlignment = HorizontalAlignment.Center };
                Grid.SetRow(line, 2); grid.Children.Add(line);
                var greeting = Text("Welcome, " + Environment.UserName, 18, "#FFE8E6F2", FontWeights.Normal);
                Grid.SetRow(greeting, 3); grid.Children.Add(greeting);
                var footer = Text("ZERO LAG - MAX PERFORMANCE", 11, "#FF8E88A8", FontWeights.SemiBold);
                footer.Margin = new Thickness(0, 18, 0, 0); footer.VerticalAlignment = VerticalAlignment.Bottom;
                Grid.SetRow(footer, 4); grid.Children.Add(footer);

                border.Child = grid;
                window.Content = border;
                bool closing = false;
                Action close = () =>
                {
                    if (closing) return;
                    closing = true;
                    var fade = new DoubleAnimation(window.Opacity, 0, TimeSpan.FromMilliseconds(550));
                    fade.Completed += (s, e) => window.Close();
                    window.BeginAnimation(Window.OpacityProperty, fade);
                };
                window.Loaded += (s, e) => window.BeginAnimation(Window.OpacityProperty, new DoubleAnimation(0, 1, TimeSpan.FromMilliseconds(450)));
                window.KeyDown += (s, e) => { if (e.Key == Key.Escape) close(); };
                window.MouseLeftButtonDown += (s, e) => close();
                var timer = new DispatcherTimer { Interval = TimeSpan.FromSeconds(5) };
                timer.Tick += (s, e) => { timer.Stop(); close(); };
                window.Closed += (s, e) => timer.Stop();
                timer.Start();
                app.Run(window);
                mutex.ReleaseMutex();
            }
        }
    }
}
'@

try {
    $references = @('System.dll', 'System.Core.dll', 'WindowsBase.dll', 'PresentationCore.dll', 'PresentationFramework.dll')
    Add-Type -TypeDefinition $welcomeSource -Language CSharp -ReferencedAssemblies $references -OutputAssembly $tempExe -OutputType WindowsApplication -ErrorAction Stop
    Copy-Item -LiteralPath $tempExe -Destination $welcomeExe -Force -ErrorAction Stop
    Remove-Item -LiteralPath $tempExe -Force -ErrorAction SilentlyContinue
} catch {
    Write-ZLagLog ('ERROR: Could not compile native Welcome panel: ' + $_.Exception.Message)
    exit 2
}

# Remove every former scripted launcher/copy from both old locations.
$oldRoots = @((Join-Path $env:ProgramData 'Z-LAG-OS'), (Join-Path $env:ProgramFiles 'Z-LAG-OS\Core'), $coreDir)
foreach ($oldRoot in ($oldRoots | Select-Object -Unique)) {
    foreach ($oldFile in @('show_startup_status.ps1', 'show_welcome_panel.ps1', 'launch_welcome_panel.vbs')) {
        Remove-Item -LiteralPath (Join-Path $oldRoot $oldFile) -Force -ErrorAction SilentlyContinue
    }
}
# This task runs after all other core installers, so the former Program Files
# code tree can now be removed completely.
Remove-Item -LiteralPath (Join-Path $env:ProgramFiles 'Z-LAG-OS') -Recurse -Force -ErrorAction SilentlyContinue

# Windows-folder code is hidden/system and cannot be modified by standard users.
& icacls.exe $coreRoot /inheritance:r /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464:(OI)(CI)F' '*S-1-5-32-545:(OI)(CI)RX' /t /c /q 2>$null | Out-Null
& attrib.exe +h +s $coreRoot 2>$null
& attrib.exe +h $dataDir 2>$null

# Register the explicit native executable. It is intentionally auditable rather
# than concealed from Task Manager or startup inspection.
$runKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
New-Item -Path $runKey -Force -ErrorAction SilentlyContinue | Out-Null
Remove-ItemProperty -Path $runKey -Name 'ZLAGStartupStatus' -Force -ErrorAction SilentlyContinue
New-ItemProperty -Path $runKey -Name 'ZLAGWelcomePanel' -Value ('"' + $welcomeExe + '"') -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
foreach ($approvalKey in @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32'
)) {
    foreach ($valueName in @('ZLAGStartupStatus', 'ZLAGWelcomePanel')) {
        Remove-ItemProperty -Path $approvalKey -Name $valueName -Force -ErrorAction SilentlyContinue
    }
}

$marker = 'HKLM:\SOFTWARE\Z-LAG-OS'
New-Item -Path $marker -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'VerboseBootStatus' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'PostBootWelcomePanel' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'WelcomePanelHost' -Value $welcomeExe -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'BootWelcomeInstalledDate' -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
Remove-ItemProperty -Path $marker -Name 'VerboseStartupStatus' -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $marker -Name 'StartupStatusInstalledDate' -ErrorAction SilentlyContinue

Write-ZLagLog 'Native Windows-folder Welcome executable configured.'
