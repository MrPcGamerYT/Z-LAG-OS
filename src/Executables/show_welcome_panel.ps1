# ==============================================================================
# Z-LAG OS - Welcome-only panel
# ------------------------------------------------------------------------------
# Runs after sign-in, waits until the user's Explorer desktop is available, then
# shows one short branded Welcome panel. It does not enumerate or display boot,
# process, service, or startup-app status.
# ==============================================================================

$ErrorActionPreference = 'SilentlyContinue'
$sessionId = (Get-Process -Id $PID).SessionId
$mutexName = 'Local\ZLAGWelcomePanel_' + $sessionId
$createdNew = $false
$mutex = [System.Threading.Mutex]::new($true, $mutexName, [ref]$createdNew)
if (-not $createdNew) { exit 0 }

try {
    # HKLM Run can fire while Explorer is still being created. Do not show the
    # custom panel until the actual user desktop exists; if it never appears,
    # silently exit instead of presenting a misleading post-boot panel.
    $deadline = (Get-Date).AddSeconds(30)
    $desktopReady = $false
    do {
        $desktopReady = [bool](Get-Process -Name explorer -ErrorAction SilentlyContinue |
            Where-Object { $_.SessionId -eq $sessionId } |
            Select-Object -First 1)
        if (-not $desktopReady) { Start-Sleep -Milliseconds 250 }
    } while (-not $desktopReady -and (Get-Date) -lt $deadline)

    if (-not $desktopReady) { exit 0 }
    Start-Sleep -Milliseconds 1400

    Add-Type -AssemblyName @('PresentationFramework', 'PresentationCore', 'WindowsBase')

    $xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Welcome to Z LAG OS" Width="640" Height="290" Opacity="0"
        WindowStyle="None" ResizeMode="NoResize" ShowInTaskbar="False"
        WindowStartupLocation="CenterScreen" Topmost="True"
        AllowsTransparency="True" Background="Transparent">
    <Border CornerRadius="18" Background="#F0111115" BorderBrush="#805B4BDE" BorderThickness="1.4" Padding="34">
        <Border.Effect>
            <DropShadowEffect Color="#AA6C5CE7" BlurRadius="28" ShadowDepth="0" Opacity="0.45"/>
        </Border.Effect>
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <TextBlock Grid.Row="0" Text="WELCOME TO" Foreground="#FFA9A3C7"
                       FontFamily="Segoe UI Variable Text, Segoe UI" FontSize="14"
                       FontWeight="SemiBold" HorizontalAlignment="Center"/>
            <TextBlock Grid.Row="1" Text="Z LAG OS" Foreground="White"
                       FontFamily="Segoe UI Variable Display, Segoe UI" FontSize="46"
                       FontWeight="Bold" Margin="0,5,0,0" HorizontalAlignment="Center"/>
            <Border Grid.Row="2" Width="250" Height="2" CornerRadius="1" Margin="0,15,0,15"
                    Background="#FF6C5CE7" HorizontalAlignment="Center"/>
            <TextBlock Grid.Row="3" Name="UserGreeting" Foreground="#FFE8E6F2"
                       FontFamily="Segoe UI Variable Text, Segoe UI" FontSize="18"
                       TextAlignment="Center" HorizontalAlignment="Center"/>
            <TextBlock Grid.Row="4" Text="ZERO LAG - MAX PERFORMANCE" Foreground="#FF8E88A8"
                       FontFamily="Segoe UI Variable Text, Segoe UI" FontSize="11"
                       FontWeight="SemiBold" Margin="0,18,0,0"
                       VerticalAlignment="Bottom" HorizontalAlignment="Center"/>
        </Grid>
    </Border>
</Window>
'@

    $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $greeting = $window.FindName('UserGreeting')
    $displayName = $env:USERNAME
    if ([string]::IsNullOrWhiteSpace($displayName)) { $displayName = 'Player' }
    $greeting.Text = 'Welcome, ' + $displayName

    $window.Add_Loaded({
        $fadeIn = New-Object Windows.Media.Animation.DoubleAnimation
        $fadeIn.From = 0
        $fadeIn.To = 1
        $fadeIn.Duration = [Windows.Duration]::new([TimeSpan]::FromMilliseconds(450))
        $window.BeginAnimation([Windows.Window]::OpacityProperty, $fadeIn)
    })

    $closePanel = {
        $fadeOut = New-Object Windows.Media.Animation.DoubleAnimation
        $fadeOut.From = $window.Opacity
        $fadeOut.To = 0
        $fadeOut.Duration = [Windows.Duration]::new([TimeSpan]::FromMilliseconds(550))
        $fadeOut.Add_Completed({ $window.Close() })
        $window.BeginAnimation([Windows.Window]::OpacityProperty, $fadeOut)
    }

    $timer = New-Object Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(5)
    $timer.Add_Tick({
        $timer.Stop()
        & $closePanel
    })

    $window.Add_KeyDown({
        if ($_.Key -eq [System.Windows.Input.Key]::Escape) {
            $timer.Stop()
            & $closePanel
        }
    })
    $window.Add_MouseLeftButtonDown({
        $timer.Stop()
        & $closePanel
    })
    $window.Add_Closed({ $timer.Stop() })

    $timer.Start()
    [void]$window.ShowDialog()
} finally {
    if ($mutex) {
        try { $mutex.ReleaseMutex() } catch { }
        $mutex.Dispose()
    }
}
