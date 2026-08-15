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

$welcomeExe = Join-Path $coreDir 'ZLAGOptiServices.exe'
$tempExe = Join-Path $env:TEMP 'ZLAGOptiServices.exe'
Remove-Item -LiteralPath $tempExe -Force -ErrorAction SilentlyContinue

# Compile a native WinForms WindowsApplication. Source exists only while the
# playbook runs; the permanent artifact is the verified executable.
$welcomeSource = @'
using System;
using System.Diagnostics;
using System.Drawing;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;

[assembly: AssemblyTitle("Z LAG Opti Services")]
[assembly: AssemblyProduct("Z LAG Optimization Services")]
[assembly: AssemblyDescription("Native Z LAG post-boot Welcome host")]
[assembly: AssemblyCompany("Z LAG Community")]
[assembly: AssemblyVersion("5.13.0.0")]
[assembly: AssemblyFileVersion("5.13.0.0")]

namespace ZLagOS
{
    internal sealed class WelcomeForm : Form
    {
        [DllImport("gdi32.dll")]
        private static extern IntPtr CreateRoundRectRgn(int left, int top, int right, int bottom, int width, int height);

        [DllImport("gdi32.dll")]
        private static extern bool DeleteObject(IntPtr handle);

        private readonly System.Windows.Forms.Timer animationTimer;
        private int phase;
        private int holdTicks;
        private bool closing;

        internal WelcomeForm()
        {
            Text = "Z LAG Opti Services";
            ClientSize = new Size(640, 290);
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.None;
            ShowInTaskbar = false;
            TopMost = true;
            BackColor = Color.FromArgb(17, 17, 21);
            Opacity = 0.0;
            KeyPreview = true;
            AutoScaleMode = AutoScaleMode.Dpi;
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.UserPaint, true);

            AddLabel("WELCOME TO", 14f, FontStyle.Bold, Color.FromArgb(169, 163, 199), 28, 34);
            AddLabel("Z LAG OS", 46f, FontStyle.Bold, Color.White, 72, 68);

            var separator = new Panel
            {
                BackColor = Color.FromArgb(108, 92, 231),
                Size = new Size(250, 2),
                Location = new Point(195, 145)
            };
            Controls.Add(separator);

            AddLabel("Welcome, " + Environment.UserName, 18f, FontStyle.Regular, Color.FromArgb(232, 230, 242), 170, 40);
            AddLabel("ZERO LAG - MAX PERFORMANCE", 11f, FontStyle.Bold, Color.FromArgb(142, 136, 168), 228, 28);

            KeyDown += delegate(object sender, KeyEventArgs args) { if (args.KeyCode == Keys.Escape) BeginClose(); };
            MouseDown += delegate { BeginClose(); };
            foreach (Control control in Controls) control.MouseDown += delegate { BeginClose(); };

            animationTimer = new System.Windows.Forms.Timer { Interval = 25 };
            animationTimer.Tick += Animate;
            Shown += delegate
            {
                IntPtr regionHandle = CreateRoundRectRgn(0, 0, Width + 1, Height + 1, 26, 26);
                Region = Region.FromHrgn(regionHandle);
                DeleteObject(regionHandle);
                animationTimer.Start();
            };
            Paint += delegate(object sender, PaintEventArgs args)
            {
                using (var pen = new Pen(Color.FromArgb(128, 91, 75, 222), 2f))
                    args.Graphics.DrawRectangle(pen, 1, 1, ClientSize.Width - 3, ClientSize.Height - 3);
            };
        }

        private void AddLabel(string value, float size, FontStyle style, Color color, int top, int height)
        {
            var label = new Label
            {
                Text = value,
                ForeColor = color,
                BackColor = Color.Transparent,
                Font = new Font("Segoe UI", size, style, GraphicsUnit.Point),
                TextAlign = ContentAlignment.MiddleCenter,
                AutoSize = false,
                Location = new Point(20, top),
                Size = new Size(600, height)
            };
            Controls.Add(label);
        }

        private void BeginClose()
        {
            if (closing) return;
            closing = true;
            phase = 2;
        }

        private void Animate(object sender, EventArgs args)
        {
            if (phase == 0)
            {
                Opacity = Math.Min(1.0, Opacity + 0.08);
                if (Opacity >= 1.0) phase = 1;
                return;
            }
            if (phase == 1)
            {
                holdTicks++;
                if (holdTicks >= 200) phase = 2;
                return;
            }
            Opacity = Math.Max(0.0, Opacity - 0.08);
            if (Opacity <= 0.0)
            {
                animationTimer.Stop();
                Close();
            }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing && animationTimer != null) animationTimer.Dispose();
            base.Dispose(disposing);
        }
    }

    public static class OptiServicesHost
    {
        private static bool ExplorerReady(int session)
        {
            foreach (Process process in Process.GetProcessesByName("explorer"))
            {
                try { if (process.SessionId == session) return true; }
                catch { }
                finally { process.Dispose(); }
            }
            return false;
        }

        [STAThread]
        public static void Main()
        {
            int session = Process.GetCurrentProcess().SessionId;
            bool created;
            using (var mutex = new Mutex(true, "Local\\ZLAGOptiServices_" + session, out created))
            {
                if (!created) return;
                try
                {
                    DateTime deadline = DateTime.Now.AddSeconds(30);
                    while (!ExplorerReady(session) && DateTime.Now < deadline) Thread.Sleep(250);
                    if (!ExplorerReady(session)) return;
                    Thread.Sleep(1400);
                    Application.EnableVisualStyles();
                    Application.SetCompatibleTextRenderingDefault(false);
                    Application.Run(new WelcomeForm());
                }
                finally { mutex.ReleaseMutex(); }
            }
        }
    }
}
'@

try {
    # WinForms is part of every supported Windows 10/11 .NET Framework image and
    # avoids WPF/System.Xaml reference-resolution failures entirely.
    Add-Type -AssemblyName @('System.Windows.Forms', 'System.Drawing') -ErrorAction Stop
    $references = @(
        [System.Diagnostics.Process].Assembly.Location,
        [System.Windows.Forms.Form].Assembly.Location,
        [System.Drawing.Color].Assembly.Location
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique
    if ($references.Count -lt 3) { throw 'Required .NET Framework WinForms assemblies were not resolved.' }

    Add-Type -TypeDefinition $welcomeSource -Language CSharp -ReferencedAssemblies $references -CompilerOptions '/optimize+ /platform:anycpu' -OutputAssembly $tempExe -OutputType WindowsApplication -IgnoreWarnings -ErrorAction Stop
    if (-not (Test-Path -LiteralPath $tempExe -PathType Leaf)) { throw 'Compiler did not create the Welcome executable.' }
    $bytes = [IO.File]::ReadAllBytes($tempExe)
    if ($bytes.Length -lt 8192 -or $bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) { throw 'Compiled Welcome executable failed PE validation.' }
    $assembly = [Reflection.AssemblyName]::GetAssemblyName($tempExe)
    $versionInfo = [Diagnostics.FileVersionInfo]::GetVersionInfo($tempExe)
    if ($assembly.Name -ne 'ZLAGOptiServices' -or $versionInfo.ProductName -ne 'Z LAG Optimization Services') { throw 'Compiled Welcome executable failed identity validation.' }

    # Unlock the existing core only after a fully verified replacement exists.
    & attrib.exe -h -s $coreRoot 2>$null
    & takeown.exe /f $coreRoot /a /r /d y 2>$null | Out-Null
    $currentSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $currentGrant = '*' + $currentSid + ':(OI)(CI)F'
    & icacls.exe $coreRoot /inheritance:e /grant '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464:(OI)(CI)F' $currentGrant /t /c /q 2>$null | Out-Null
    Stop-Process -Name 'ZLAGOptiServices' -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath $tempExe -Destination $welcomeExe -Force -ErrorAction Stop
    Write-ZLagLog ('Compiled and verified native host: ' + $versionInfo.ProductName + ' v' + $versionInfo.FileVersion)
} catch {
    Write-ZLagLog ('ERROR: Native Welcome host compilation failed: ' + $_.Exception.Message)
    exit 2
} finally {
    Remove-Item -LiteralPath $tempExe -Force -ErrorAction SilentlyContinue
}

# Remove every former scripted launcher/copy from both old locations.
$oldRoots = @((Join-Path $env:ProgramData 'Z-LAG-OS'), (Join-Path $env:ProgramFiles 'Z-LAG-OS\Core'), $coreDir)
foreach ($oldRoot in ($oldRoots | Select-Object -Unique)) {
    foreach ($oldFile in @('show_startup_status.ps1', 'show_welcome_panel.ps1', 'launch_welcome_panel.vbs', 'ZLagWelcome.exe')) {
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
Remove-ItemProperty -Path $runKey -Name 'ZLAGWelcomePanel' -Force -ErrorAction SilentlyContinue
New-ItemProperty -Path $runKey -Name 'Z LAG Opti Services' -Value ('"' + $welcomeExe + '"') -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
foreach ($approvalKey in @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32'
)) {
    foreach ($valueName in @('ZLAGStartupStatus', 'ZLAGWelcomePanel', 'Z LAG Opti Services')) {
        Remove-ItemProperty -Path $approvalKey -Name $valueName -Force -ErrorAction SilentlyContinue
    }
}

$marker = 'HKLM:\SOFTWARE\Z-LAG-OS'
New-Item -Path $marker -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'VerboseBootStatus' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'PostBootWelcomePanel' -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path $marker -Name 'OptiServicesHost' -Value $welcomeExe -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
Remove-ItemProperty -Path $marker -Name 'WelcomePanelHost' -ErrorAction SilentlyContinue
New-ItemProperty -Path $marker -Name 'BootWelcomeInstalledDate' -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
Remove-ItemProperty -Path $marker -Name 'VerboseStartupStatus' -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $marker -Name 'StartupStatusInstalledDate' -ErrorAction SilentlyContinue

Write-ZLagLog 'Z LAG Opti Services native Welcome host configured.'
