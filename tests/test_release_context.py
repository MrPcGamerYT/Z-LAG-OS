"""Exercise the real release validator against disposable local Git repositories."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / '.github/scripts/release_context.py'


class ReleaseContextTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)
        self.git('init', '-q')
        self.git('config', 'user.email', 'test@example.invalid')
        self.git('config', 'user.name', 'Release tests')
        (self.repo / 'src').mkdir()
        (self.repo / 'src/playbook.conf').write_text('<Playbook><Version>5.19</Version></Playbook>')
        self.git('add', '.')
        self.git('commit', '-qm', 'Fixture')
        self.commit = self.git('rev-parse', 'HEAD')
        self.output = self.repo / 'github-env'

    def git(self, *args):
        return subprocess.check_output(['git', *args], cwd=self.repo, text=True, stderr=subprocess.PIPE).strip()

    def run_validator(self, event='workflow_dispatch', version='5.19'):
        env = {**os.environ, 'EVENT_NAME': event, 'INPUT_VERSION': version,
               'REF_NAME': version, 'GITHUB_SHA': self.git('rev-parse', 'HEAD'),
               'GITHUB_ENV': str(self.output)}
        return subprocess.run([sys.executable, str(SCRIPT)], cwd=self.repo, env=env,
                              text=True, capture_output=True)

    def test_manual_missing_tag_is_valid_without_mutating_git(self):
        result = self.run_validator()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('RELEASE_TAG_EXISTS=false', self.output.read_text())
        self.assertIn('RELEASE_COMMIT=' + self.commit, self.output.read_text())
        self.assertEqual(self.git('tag', '--list'), '')

    def test_missing_push_tag_is_actionable_error(self):
        result = self.run_validator('push')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('missing from checkout', result.stderr)
        self.assertFalse(self.output.exists())

    def test_existing_tag_is_verified(self):
        self.git('tag', '5.19')
        result = self.run_validator()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('RELEASE_TAG_EXISTS=true', self.output.read_text())

    def test_annotated_tag_with_v_prefix(self):
        self.git('tag', '-a', 'v5.19', '-m', 'Fixture release')
        result = self.run_validator('push', 'v5.19')
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_existing_tag_at_other_commit_is_not_moved(self):
        self.git('tag', '5.19')
        self.git('commit', '--allow-empty', '-qm', 'Later source')
        result = self.run_validator()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('different commit', result.stderr)
        self.assertEqual(self.git('rev-parse', 'refs/tags/5.19'), self.commit)

    def test_version_mismatch_explains_fix(self):
        result = self.run_validator(event='push', version='5.20')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('playbook.conf declares 5.19', result.stderr)
        self.assertIn('README', result.stderr)

    def test_manual_version_override_is_accepted_without_changing_source(self):
        result = self.run_validator(version='5.20')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('SOURCE_VERSION=5.19', self.output.read_text())
        self.assertIn('RELEASE_VERSION=5.20', self.output.read_text())
        self.assertIn('<Version>5.19</Version>', (self.repo / 'src/playbook.conf').read_text())

    def test_exact_518_to_519_manual_build_stamps_metadata_and_provenance(self):
        import json
        (self.repo / 'src/playbook.conf').write_text(
            '<Playbook><Description><![CDATA[Keep & preserve]]></Description><Version>5.18</Version></Playbook>')
        (self.repo / 'README.md').write_text('Version: 5.18 Version-5.18-success Z LAG OS v5.18')
        self.git('add', '.')
        self.git('commit', '-qm', 'Source 5.18')
        source_commit = self.git('rev-parse', 'HEAD')
        result = self.run_validator(version='5.19')
        self.assertEqual(result.returncode, 0, result.stderr)
        env = {**os.environ, **dict(line.split('=', 1) for line in self.output.read_text().splitlines())}
        stage = SCRIPT.with_name('stage_release.py')
        result = subprocess.run([sys.executable, str(stage)], cwd=self.repo, env=env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        config = (self.repo / 'src/playbook.conf').read_text()
        self.assertIn('<Version>5.19</Version>', config)
        self.assertIn('<![CDATA[Keep & preserve]]>', config)
        self.assertIn('Version-5.19-success', (self.repo / 'README.md').read_text())
        self.assertIn('Z LAG OS v5.19', (self.repo / 'README.md').read_text())
        provenance = json.loads((self.repo / 'release-provenance.json').read_text())
        self.assertEqual(provenance['source_commit'], source_commit)
        self.assertEqual(provenance['source_version'], '5.18')
        self.assertEqual(provenance['release_version'], '5.19')
        self.assertTrue(provenance['metadata_override'])
        self.assertIn('<Version>5.18</Version>', self.git('show', 'HEAD:src/playbook.conf'))
        self.assertEqual(self.git('tag', '--list'), '')

    def test_invalid_input_is_not_executed(self):
        result = self.run_validator(version='5.19; touch injected')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.repo / 'injected').exists())

    def test_checkout_must_match_workflow_commit(self):
        env = {**os.environ, 'EVENT_NAME': 'workflow_dispatch', 'INPUT_VERSION': '5.19',
               'GITHUB_SHA': 'not-the-checkout', 'GITHUB_ENV': str(self.output)}
        result = subprocess.run([sys.executable, str(SCRIPT)], cwd=self.repo, env=env,
                                text=True, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('workflow commit', result.stderr)
