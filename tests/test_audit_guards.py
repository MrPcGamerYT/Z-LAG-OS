#!/usr/bin/env python3
"""Mutation tests: prove the static guards reject the bugs they document.

No Windows payloads are executed. Run: python -m unittest discover -s tests
"""
import unittest
from pathlib import Path
from unittest.mock import patch

import validate_repo as validation


class AuditGuardTests(unittest.TestCase):
    def assert_rejected(self, filename, old, new, guard=validation.validate_audit_regressions):
        original_read = Path.read_text
        matched = []

        def mutated_read(path, *args, **kwargs):
            text = original_read(path, *args, **kwargs)
            if path.name == filename:
                self.assertIn(old, text)
                matched.append(path)
                return text.replace(old, new)
            return text

        with patch.object(Path, 'read_text', mutated_read):
            with self.assertRaises(AssertionError):
                guard()
        self.assertTrue(matched)

    def test_current_contracts(self):
        validation.validate_audit_regressions()
        validation.validate_store_removal_contract()
        validation.validate_network_hosts_regressions()
        validation.validate_windows_compatibility()
        validation.validate_kernel_profile()

    def test_reversed_hags_value(self):
        self.assert_rejected('set_gpu_scheduling.ps1', "-Name 'HwSchMode' -Value 2", "-Name 'HwSchMode' -Value 1")

    def test_invalid_cim_parameter(self):
        self.assert_rejected('set_pagefile.ps1', 'Set-CimInstance -InputObject $cs', 'Set-CimInstance -ClassName Win32_ComputerSystem')

    def test_hash_mismatch_cannot_be_warning_only(self):
        self.assert_rejected('install_toolbox.ps1', 'throw "SHA256 mismatch', 'Write-Warning "SHA256 mismatch')

    def test_logs_do_not_turn_failure_into_truthy_array(self):
        self.assert_rejected('install_toolbox.ps1', 'Write-Host $line', 'Write-Output $line')

    def test_destructive_cleanup(self):
        self.assert_rejected('38_deepClean.yml', '.\\remove_onedrive.ps1', '.\\remove_onedrive.ps1 -RemoveSyncedData')

    def test_account_block_option(self):
        self.assert_rejected('main.yml', "17_removeMSAccount.yml', option: 'store-disable'", "17_removeMSAccount.yml'")

    def test_release_mutates_tag(self):
        self.assert_rejected('build-release.yml', 'set -euo pipefail', 'set -euo pipefail\n          git push origin :refs/tags/example')

    def test_broken_store_member_syntax(self):
        self.assert_rejected('RemoveStoreServices.ps1', '$_.DisplayName -eq $Pkg', '$_ .DisplayName -eq $Pkg', validation.validate_store_removal_contract)

    def test_readonly_host_assignment(self):
        self.assert_rejected('add_update_hosts.ps1', '$defenderEndpoints =', "$Host = 'bad'\n$defenderEndpoints =", validation.validate_network_hosts_regressions)

    def test_tcp_guid_format(self):
        self.assert_rejected('set_tcp_nodelay_per_interface.ps1', ".ToString('B')", ".ToString('D')", validation.validate_network_hosts_regressions)

    def test_nic_must_not_restart(self):
        self.assert_rejected('disable_network_offload.ps1', '-RegistryValue 0 -NoRestart', '-RegistryValue 0', validation.validate_network_hosts_regressions)

    def test_hosts_replacement_guard(self):
        self.assert_rejected('hosts_file_utils.ps1', '[IO.File]::Replace', '[IO.File]::Copy', validation.validate_network_hosts_regressions)

    def test_hags_build_floor(self):
        self.assert_rejected('windows_compatibility.ps1', '$Build -ge 19041', '$Build -ge 10240', validation.validate_windows_compatibility)

    def test_taskbar_preserves_other_bits(self):
        self.assert_rejected('windows_compatibility.ps1', '-bor 1', '-bor 3', validation.validate_windows_compatibility)

    def test_kernel_does_not_pin_executive_memory(self):
        self.assert_rejected('set_kernel_profile.ps1', "Name = 'DisablePagingExecutive'; Value = 0", "Name = 'DisablePagingExecutive'; Value = 1", validation.validate_kernel_profile)

    def test_kernel_original_snapshot_is_preserved(self):
        self.assert_rejected('set_kernel_profile.ps1', '-NoClobber', '-Force', validation.validate_kernel_profile)


if __name__ == '__main__':
    unittest.main()
