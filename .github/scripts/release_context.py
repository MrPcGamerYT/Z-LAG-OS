#!/usr/bin/env python3
"""Validate release source without mutating files, tags, or remote state."""
import os
from pathlib import Path
import re
import subprocess
import sys
import xml.etree.ElementTree as ET


def git(*args: str) -> str:
    return subprocess.check_output(['git', *args], text=True, stderr=subprocess.PIPE).strip()


def main() -> None:
    event = os.environ.get('EVENT_NAME', '')
    if event not in ('push', 'workflow_dispatch'):
        raise ValueError('Release must be triggered by a tag push or workflow_dispatch.')
    tag = os.environ.get('REF_NAME' if event == 'push' else 'INPUT_VERSION', '')
    if not re.fullmatch(r'v?\d+(?:\.\d+){1,3}', tag, flags=re.ASCII):
        raise ValueError('Invalid version tag. Use a version such as 5.19 or v5.19.')
    version = ET.parse('src/playbook.conf').findtext('Version')
    release_version = tag.removeprefix('v')
    if event == 'push' and release_version != version:
        raise ValueError(
            f'Requested {tag}, but src/playbook.conf declares {version}. '
            'Update playbook.conf and the README version metadata in the source commit, '
            'then dispatch that ref. Release packaging does not silently rewrite source versions.'
        )
    commit = git('rev-parse', '--verify', 'HEAD^{commit}')
    expected = os.environ.get('GITHUB_SHA')
    if expected and commit != expected:
        raise ValueError('Checked-out source does not match the workflow commit.')
    exists = subprocess.run(
        ['git', 'show-ref', '--verify', '--quiet', f'refs/tags/{tag}'], check=False
    ).returncode
    if exists not in (0, 1):
        raise ValueError('Unable to inspect local release tags. Check checkout/fetch configuration.')
    if exists == 0:
        tag_commit = git('rev-parse', '--verify', f'refs/tags/{tag}^{{commit}}')
        if tag_commit != commit:
            raise ValueError(f'Tag {tag} points at a different commit. Existing tags are never moved.')
    elif event == 'push':
        raise ValueError(f'Pushed tag {tag} is missing from checkout. Fetch tags before releasing.')
    # Missing tags are valid ONLY for manual releases. gh creates them at this
    # exact validated commit after all tests and archive verification succeed.
    output = (
        f'RELEASE_TAG={tag}\nRELEASE_COMMIT={commit}\n'
        f'SOURCE_VERSION={version}\nRELEASE_VERSION={release_version}\n'
        f'RELEASE_TAG_EXISTS={str(exists == 0).lower()}\n'
    )
    with Path(os.environ['GITHUB_ENV']).open('a', encoding='utf-8') as stream:
        stream.write(output)
    print(f'Validated {tag} at {commit}; ' + ('using existing tag.' if exists == 0 else 'new tag will be created during publication.'))


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError, ET.ParseError, subprocess.CalledProcessError) as error:
        print(f'::error::{error}', file=sys.stderr)
        sys.exit(1)
