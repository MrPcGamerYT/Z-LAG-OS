# Z-LAG OS - interactive startup status overlay (installed in ProgramData)
$ErrorActionPreference = 'SilentlyContinue'

# Never create a second overlay in the same user session.
$sessionId = (Get-Process -Id $PID).SessionId
$mutexName = 'Local\ZLAGStartupStatus_' + $sessionId
$createdNew = $false
$mutex = [System.Threading.Mutex]::new($true, $mutexName, [ref]$createdNew)
if (-not $createdNew) { exit 0 }

try {
    Add-Type -AssemblyName @('PresentationFramework', 'PresentationCore', 'WindowsBase')

    $xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Z-LAG Startup Status" Width="700" Height="245"
        WindowStyle="None" ResizeMode="NoResize" ShowInTaskbar="False"
        WindowStartupLocation="CenterScreen" Topmost="True"
        AllowsTransparency="True" Background="Transparent">
    <Border CornerRadius="12" Background="#E6121212" BorderBrush="#704F46E5" BorderThickness="1" Padding="28">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <TextBlock Grid.Row="0" Text="Welcome" Foreground="White" FontFamily="Segoe UI Variable Display, Segoe UI" FontSize="34" FontWeight="SemiBold" HorizontalAlignment="Center"/>
            <TextBlock Grid.Row="1" Name="CurrentStatus" Text="Starting your Windows session..." Foreground="#FFE7E7E7" FontFamily="Segoe UI Variable Text, Segoe UI" FontSize="15" Margin="0,8,0,7" TextAlignment="Center" TextTrimming="CharacterEllipsis"/>
            <ProgressBar Grid.Row="2" IsIndeterminate="True" Height="3" Foreground="#FF7567F1" Background="#402D2D2D" BorderThickness="0" Margin="25,0,25,11"/>
            <TextBlock Grid.Row="3" Name="History" Foreground="#FFBDBDBD" FontFamily="Consolas" FontSize="11.5" TextAlignment="Center" LineHeight="18"/>
            <TextBlock Grid.Row="4" Text="Live startup activity • Press Esc to dismiss" Foreground="#FF777777" FontFamily="Segoe UI" FontSize="10" HorizontalAlignment="Center" Margin="0,8,0,0"/>
        </Grid>
    </Border>
</Window>
'@

    $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $currentStatus = $window.FindName('CurrentStatus')
    $historyBlock = $window.FindName('History')

    $queue = New-Object 'System.Collections.Generic.Queue[string]'
    $history = New-Object 'System.Collections.Generic.List[string]'
    $seenProcesses = @{}
    $script:startupStatusStarted = Get-Date
    $script:startupStatusLastActivity = Get-Date
    $script:startupStatusReadyAt = $null

    function Add-ZLagStatus {
        param([string]$Text)
        if ([string]::IsNullOrWhiteSpace($Text)) { return }
        $queue.Enqueue($Text)
        $script:startupStatusLastActivity = Get-Date
    }

    function Get-FriendlyProcessName {
        param([System.Diagnostics.Process]$Process)
        $description = $null
        try { $description = $Process.MainModule.FileVersionInfo.FileDescription } catch { }
        if ([string]::IsNullOrWhiteSpace($description) -or $description -eq 'Microsoft Windows') {
            $description = $Process.ProcessName
        }
        return $description
    }

    # Report configured startup entries truthfully as queued items. Processes are
    # only labelled "Started" after they are observed in this user session.
    $startupEntries = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($path in @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'
    )) {
        $item = Get-Item -LiteralPath $path
        if ($item) {
            foreach ($name in $item.GetValueNames()) {
                if ($name -and $name -ne 'ZLAGStartupStatus') { [void]$startupEntries.Add($name) }
            }
        }
    }
    foreach ($folder in @(
        [Environment]::GetFolderPath('Startup'),
        [Environment]::GetFolderPath('CommonStartup')
    )) {
        Get-ChildItem -LiteralPath $folder -File | ForEach-Object { [void]$startupEntries.Add($_.BaseName) }
    }
    foreach ($entry in $startupEntries) { Add-ZLagStatus ('Queued startup app: ' + $entry) }

    # Include processes that started while Winlogon was transitioning from the
    # secure Welcome screen to the desktop, before this overlay could be shown.
    $skipNames = @('idle', 'system', 'registry', 'memory compression', 'powershell', 'pwsh', 'conhost', 'fontdrvhost', 'dwm')
    Get-Process | ForEach-Object {
        $seenProcesses[$_.Id] = $true
        try {
            if ($_.SessionId -eq $sessionId -and $_.StartTime -ge ($script:startupStatusStarted).AddSeconds(-30) -and $skipNames -notcontains $_.ProcessName.ToLowerInvariant()) {
                Add-ZLagStatus ('Started: ' + (Get-FriendlyProcessName -Process $_))
            }
        } catch { }
    }

    foreach ($serviceCheck in @(
        [pscustomobject]@{ Name = 'AudioEndpointBuilder'; Label = 'Audio endpoint service ready' },
        [pscustomobject]@{ Name = 'Audiosrv'; Label = 'Windows Audio service ready' },
        [pscustomobject]@{ Name = 'Dhcp'; Label = 'Network configuration service ready' },
        [pscustomobject]@{ Name = 'EventLog'; Label = 'Windows event service ready' }
    )) {
        if ((Get-Service -Name $serviceCheck.Name).Status -eq 'Running') { Add-ZLagStatus $serviceCheck.Label }
    }

    if ($queue.Count -eq 0) { Add-ZLagStatus 'Windows shell is preparing the desktop' }

    $timer = New-Object Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(400)
    $timer.Add_Tick({
        # Polling by session gives real app starts without requiring admin-only
        # process-trace privileges or a permanent background service.
        Get-Process | ForEach-Object {
            if (-not $seenProcesses.ContainsKey($_.Id)) {
                $seenProcesses[$_.Id] = $true
                try {
                    if ($_.SessionId -eq $sessionId -and $skipNames -notcontains $_.ProcessName.ToLowerInvariant()) {
                        Add-ZLagStatus ('Started: ' + (Get-FriendlyProcessName -Process $_))
                    }
                } catch { }
            }
        }

        if ($queue.Count -gt 0) {
            $line = $queue.Dequeue()
            $currentStatus.Text = $line
            $history.Add(((Get-Date).ToString('HH:mm:ss') + '  ' + $line))
            while ($history.Count -gt 4) { $history.RemoveAt(0) }
            $historyBlock.Text = $history -join [Environment]::NewLine
        } elseif (((Get-Date) - $script:startupStatusStarted).TotalSeconds -ge 7) {
            if (-not $script:startupStatusReadyAt) {
                $currentStatus.Text = 'Desktop ready'
                $script:startupStatusReadyAt = Get-Date
            } elseif (((Get-Date) - $script:startupStatusReadyAt).TotalSeconds -ge 1.4) {
                $timer.Stop()
                $window.Close()
            }
        } else {
            $currentStatus.Text = 'Finalizing your desktop...'
        }

        # Hard upper bound: a noisy process launcher can never keep this overlay
        # on screen indefinitely.
        if (((Get-Date) - $script:startupStatusStarted).TotalSeconds -ge 24) {
            $timer.Stop()
            $window.Close()
        }
    })

    $window.Add_KeyDown({
        if ($_.Key -eq [System.Windows.Input.Key]::Escape) {
            $timer.Stop()
            $window.Close()
        }
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
