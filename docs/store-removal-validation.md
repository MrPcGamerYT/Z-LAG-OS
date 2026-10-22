# Microsoft Store removal verification

The `store-disable` selection removes the listed Store/consumer packages for all
users and removes their provisioning for future accounts. Targeted services are
disabled, not deleted; per-user service templates and existing instances are
included. Core Windows, AppX, GPU and pairing infrastructure are preserved.
Microsoft account dependencies remain manual and can trigger-start if an app
requires them. This option does not remove every Microsoft service from Windows.

The removal script requires Administrator/SYSTEM. It reports remaining packages,
provisioning, disabled-start failures and services that have not stopped, then
returns exit code 1 on incomplete removal. `StoreRemoved=1` records intent;
`StoreRemovalComplete=1` is written only after verification succeeds.

## Windows VM smoke test (snapshot first)

1. Select **Keep Microsoft Store** and confirm the removal task is skipped.
2. On a separate snapshot, select removal and complete the playbook. Check its
   output for warnings rather than relying on the task status text.
3. Confirm `Get-AppxPackage -AllUsers Microsoft.WindowsStore` returns nothing and
   `Get-AppxProvisionedPackage -Online` has no Microsoft.WindowsStore entry.
4. Check `InstallService` and `PushToInstall` startup are Disabled, and targeted
   per-user templates (for example OneSyncSvc) have registry `Start=4`.
5. Reboot and sign in to a second local account; repeat package/service checks.
6. Confirm Start, Search, GPU utilities and sideloaded apps still launch. Run
   `repair_appx_runtime.ps1` and confirm it does not explicitly start wlidsvc or
   TokenBroker when StoreRemoved is 1.
7. Simulate a denied package/service operation: expect a warning, exit code 1
   and StoreRemovalComplete=0 rather than a false success report.

Linux repository checks do not execute Windows AppX or service commands. The
Windows CI parser checks syntax without executing the destructive payloads;
actual removal still needs the VM checks above.
