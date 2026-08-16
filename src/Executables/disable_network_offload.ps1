# Z-LAG OS - NIC latency tuning that actually helps gaming.
# NOTE: TCP checksum offload is NO LONGER disabled. Disabling checksum offload
# moves per-packet checksum work onto the CPU, which raises DPC load and causes
# frame drops during firefights (exactly when packet rates spike). Modern NICs
# handle checksums in hardware at zero latency cost - leave it on.
#
# What IS worth doing for competitive latency:
#   * Disable interrupt moderation (packets are delivered immediately instead
#     of being batched, shaving off up to ~1ms of jitter).
#   * Disable Energy-Efficient Ethernet / green throttling (prevents the link
#     from micro-sleeping between packets).
#   * Disable adapter power saving (prevents mid-game NIC power-downs, a known
#     cause of sudden lag spikes and disconnects on Wi-Fi and Ethernet).
$ErrorActionPreference = 'SilentlyContinue'

Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
    $name = $_.Name

    # Interrupt moderation off = lowest latency packet delivery.
    Set-NetAdapterAdvancedProperty -Name $name -DisplayName 'Interrupt Moderation' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $name -RegistryKeyword '*InterruptModeration' -RegistryValue 0 -ErrorAction SilentlyContinue

    # Green/energy features off = no link micro-sleeps between packets.
    foreach ($greenSetting in @('Energy-Efficient Ethernet', 'Green Ethernet', 'Power Saving Mode', 'Ultra Low Power Mode', 'System Idle Power Saver')) {
        Set-NetAdapterAdvancedProperty -Name $name -DisplayName $greenSetting -DisplayValue 'Disabled' -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $name -DisplayName $greenSetting -DisplayValue 'Off' -ErrorAction SilentlyContinue
    }

    # Never let Windows power the NIC down to save energy (mid-game lag spikes).
    if (Get-Command Disable-NetAdapterPowerManagement -ErrorAction SilentlyContinue) {
        Disable-NetAdapterPowerManagement -Name $name -NoRestart -ErrorAction SilentlyContinue
    }
}

exit 0