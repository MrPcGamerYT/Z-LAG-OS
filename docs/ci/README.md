# CI files (manual install required)

The automation account that pushes this branch does not have GitHub
`workflows` permission, so these two files must be applied by a maintainer
(one commit from the GitHub web UI or a normal user account):

1. `validate.yml` - copy to `.github/workflows/validate.yml`.
   Runs on every push/PR: `tests/validate_repo.py`, a real PowerShell AST
   syntax parse of all 37 scripts, and a PSScriptAnalyzer error gate.

2. `build-release-validation-gate.patch` - adds a validation gate to
   `.github/workflows/build-release.yml` so a broken playbook can never be
   packaged into an `.apbx` release. Apply from the repository root:

       git apply docs/ci/build-release-validation-gate.patch

Until these are installed, run the same checks locally before tagging:

    python3 tests/validate_repo.py
