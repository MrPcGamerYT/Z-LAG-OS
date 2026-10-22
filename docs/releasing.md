# Publishing and testing a release

## Manual release

In Actions, choose **Package and Release Z LAG OS.apbx**, select the source
branch, enter `5.19` (or `v5.19`), and leave **publish** enabled.

A manual release does not require editing repository version strings first:

1. The workflow pins the selected commit and validates the version/tag input.
2. In its temporary CI checkout, it stamps playbook.conf and README metadata
   with the requested release version. Git history is not rewritten or committed.
3. It validates the staged metadata, tests the repo, builds/tests the archive,
   and records a checksum and `release-provenance.json` containing the source
   commit, source version, requested version and whether metadata was overridden.
4. It retains all three files as a workflow artifact.
5. When publishing, a missing tag is created at the pinned source commit; existing
   tags must point to that commit and are never moved. An existing release is
   not deleted/replaced. The archive's stamped version can differ from the source
   version; the attached provenance makes this explicit.

For example, source 5.18 can build release 5.19 without the previous validation
failure. Only version metadata changes automatically, not program behavior.

## Dry-run validation (no release/tag creation)

Uncheck **publish** to run the same validation, tests and packaging without
publishing. Inspect the resulting workflow artifact. This is preferable to
re-running production releases just to test workflow changes.

## Tag pushes

A pushed tag must exist in checkout, point at the selected commit and already
match source metadata. Tag-triggered builds keep the stricter source/version
check because they have no manually supplied metadata override.

## Expected safety stops

Invalid versions, a tag pointing elsewhere, broken tests, corrupt archives,
permission failures and existing published releases still fail intentionally.
No workflow can guarantee never to fail. Re-running an old failed job uses its
old workflow/source commit; start a **new** dispatch after the fix is merged,
or select the branch containing the fix. A rerun does not pick up new commits.

## Tests

`tests/test_release_context.py` exercises disposable Git repositories, including
the exact 5.18-source/5.19-release case. It checks staged metadata, preserved CDATA,
provenance and unchanged source history/tags. No tests publish project releases.
