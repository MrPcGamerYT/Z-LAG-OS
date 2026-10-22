#!/usr/bin/env python3
"""Stamp CI workspace metadata for a release; never commit or retag source."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import xml.etree.ElementTree as ET


def main():
    version = os.environ['RELEASE_VERSION']
    source = os.environ['SOURCE_VERSION']
    if not re.fullmatch(r'\d+(?:\.\d+){1,3}', version, flags=re.ASCII):
        raise ValueError('Invalid release metadata version.')
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
    if commit != os.environ['RELEASE_COMMIT']:
        raise ValueError('Source commit changed after validation.')
    config = Path('src/playbook.conf')
    if ET.parse(config).findtext('Version') != source:
        raise ValueError('Source version changed after validation.')
    text = config.read_text(encoding='utf-8')
    text, count = re.subn(r'<Version>[^<]*</Version>', f'<Version>{version}</Version>', text)
    if count != 1:
        raise ValueError('Expected exactly one playbook Version element.')
    readme_path = Path('README.md')
    readme = readme_path.read_text(encoding='utf-8')
    if f'Version: {source}' not in readme or f'Z LAG OS v{source}' not in readme:
        raise ValueError('README source metadata is inconsistent; fix it before releasing.')
    readme = readme.replace(f'Version: {source}', f'Version: {version}')
    readme = readme.replace(f'Version-{source}-', f'Version-{version}-')
    readme = readme.replace(f'Z LAG OS v{source}', f'Z LAG OS v{version}')
    config.write_text(text, encoding='utf-8')
    readme_path.write_text(readme, encoding='utf-8')
    provenance = {
        'source_commit': commit, 'source_version': source,
        'release_version': version, 'release_tag': os.environ['RELEASE_TAG'],
        'metadata_override': source != version,
    }
    Path('release-provenance.json').write_text(json.dumps(provenance, indent=2) + '\n', encoding='utf-8')
    print(f'Staged package version {version} from source {source} at {commit}; no commits or tags changed.')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, KeyError, OSError, ET.ParseError, subprocess.CalledProcessError) as error:
        print(f'::error::{error}', file=sys.stderr)
        sys.exit(1)
