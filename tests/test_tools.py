"""Test isolati: nessun download, account GitHub o modifica alla home reale."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ('install.sh', 'installa-gh.sh', 'github-inizio.sh', 'github-fine.sh')
GH = r'''#!/usr/bin/env python3
import os, sys, pathlib
p=pathlib.Path(os.environ['LAB_TEST_STATE']); a=sys.argv[1:]
with (p/'calls').open('a') as f: f.write('gh '+' '.join(a)+'\n')
auth=p/'auth'
if a==['--version']: print('gh version 2.23.0'); sys.exit(0)
if a[:3]==['config','get','user'] or a[:2]==['auth','token']:
 if auth.exists(): print('fake-value'); sys.exit(0)
 sys.exit(1)
if a[:2]==['auth','logout']:
 if os.environ.get('LAB_TEST_LOGOUT_FAIL'): sys.exit(1)
 auth.unlink(missing_ok=True); sys.exit(0)
if a[:2]==['auth','login']:
 auth.touch(); sys.exit(1 if os.environ.get('LAB_TEST_LOGIN_FAIL') else 0)
if a[0]=='api': print(os.environ.get('LAB_TEST_ACCOUNT','alice')); sys.exit(0)
if a[:2]==['auth','setup-git']: sys.exit(0)
sys.exit(2)
'''


class ToolsTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='.test-tools-', dir=ROOT)
        self.addCleanup(self.tmp.cleanup)
        self.dir = Path(self.tmp.name)
        self.home = self.dir/'userhome'
        self.bin = self.dir/'bin'
        self.sources = self.dir/'sources'
        for path in (self.home, self.bin, self.sources):
            path.mkdir()
        # Soltanto le copie di test aggirano il rifiuto root e usano una home
        # fittizia; la variabile di sistema HOME non viene modificata.
        for name in SCRIPTS:
            code = (ROOT/name).read_text()
            code = code.replace('if (( EUID == 0 )); then', 'if false; then', 1)
            code = code.replace('gh_user_home="$HOME"', 'gh_user_home="$LAB_TEST_HOME"')
            code = code.replace('install_user_home="$HOME"', 'install_user_home="$LAB_TEST_HOME"')
            if name.startswith('github-'):
                code = code.replace('$HOME/.local/bin', '$LAB_TEST_HOME/.local/bin')
            (self.sources/name).write_text(code)
        self.env = {k: v for k, v in os.environ.items()
                    if k not in ('GH_TOKEN', 'GITHUB_TOKEN', 'LAB_TOOLS_REF')}
        self.env.update(PATH=f'{self.bin}:/usr/bin:/bin', LAB_TEST_HOME=str(self.home),
                        LAB_TEST_STATE=str(self.dir), TMPDIR=str(self.dir))
        self.exe(self.dir/'gh-payload', GH)
        self.exe(self.bin/'git', '#!/bin/bash\ncat >/dev/null\n')
        self.exe(self.bin/'apt-get', r'''#!/usr/bin/env python3
import os, pathlib, sys
p=pathlib.Path(os.environ['LAB_TEST_STATE'])
with (p/'calls').open('a') as f: f.write('download-gh\n')
if os.environ.get('LAB_TEST_DOWNLOAD_FAIL'): sys.exit(100)
pathlib.Path('gh_test.deb').touch()
''')
        self.exe(self.bin/'dpkg-deb', r'''#!/usr/bin/env python3
import os, pathlib, shutil
p=pathlib.Path('estratto/usr/bin'); p.mkdir(parents=True)
shutil.copy2(pathlib.Path(os.environ['LAB_TEST_STATE'])/'gh-payload',p/'gh')
''')
        self.exe(self.bin/'curl', r'''#!/usr/bin/env python3
import os, pathlib, shutil, sys
p=pathlib.Path(os.environ['LAB_TEST_STATE']); a=sys.argv[1:]
name=a[-1].rsplit('/',1)[1]
if name==os.environ.get('LAB_TEST_CURL_FAIL'): sys.exit(22)
dest=pathlib.Path(a[a.index('--output')+1])
shutil.copy2(p/'sources'/name,dest)
''')

    def exe(self, path, content):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        path.chmod(0o755)

    @property
    def local(self):
        return self.home/'.local/bin'

    @property
    def bashrc(self):
        return self.home/'.bashrc'

    def run_script(self, name, success=True, inline=False):
        args = ['bash', '-c', (self.sources/name).read_text()] if inline else ['bash', str(self.sources/name)]
        r = subprocess.run(args, input='alice\n', text=True, capture_output=True,
                           cwd=self.dir, env=self.env)
        self.assertEqual(r.returncode == 0, success, r.stdout + r.stderr)
        return r

    def calls(self):
        p = self.dir/'calls'
        return p.read_text() if p.exists() else ''

    def test_syntax_and_root_guard(self):
        for name in SCRIPTS:
            subprocess.run(['bash', '-n', str(ROOT/name)], check=True)
            if os.geteuid() == 0:
                r = subprocess.run(['bash', str(ROOT/name)], capture_output=True, text=True)
                self.assertNotEqual(r.returncode, 0)
                self.assertIn('senza sudo', r.stderr)

    def test_install_fresh_and_repeat(self):
        self.run_script('install.sh', inline=True)
        for name in SCRIPTS[1:]:
            self.assertEqual((self.local/name).stat().st_mode & 0o777, 0o755)
        self.assertEqual((self.local/'gh').stat().st_mode & 0o777, 0o755)
        first = self.bashrc.read_text()
        self.run_script('install.sh')
        self.assertEqual(self.bashrc.read_text(), first)
        self.assertEqual(self.calls().count('download-gh'), 1)
        self.assertNotIn('auth login', self.calls())

    def test_reuse_local_gh_outside_path(self):
        self.exe(self.local/'gh', GH)
        self.run_script('installa-gh.sh')
        self.assertNotIn('download-gh', self.calls())
        self.assertTrue(self.bashrc.exists())

    def test_system_gh_still_configures_script_directory(self):
        self.exe(self.bin/'gh', GH)
        self.run_script('installa-gh.sh')
        self.assertNotIn('download-gh', self.calls())
        self.assertTrue(self.local.is_dir())
        self.assertTrue(self.bashrc.exists())

    def test_existing_bashrc_path_forms(self):
        self.exe(self.local/'gh', GH)
        for form in ('$HOME/.local/bin', '${HOME}/.local/bin', '~/.local/bin', str(self.local)):
            with self.subTest(form=form):
                line = f'export PATH="{form}:$PATH"\n'
                self.bashrc.write_text(line)
                self.run_script('installa-gh.sh')
                self.assertEqual(self.bashrc.read_text(), line)

    def test_comments_and_similar_directory_are_not_path_entries(self):
        self.exe(self.local/'gh', GH)
        for line in ('# export PATH="$HOME/.local/bin:$PATH"\n',
                     'export PATH="/opt/tools:$PATH" # ~/.local/bin\n',
                     'export PATH="$HOME/.local/bin-old:$PATH"\n'):
            with self.subTest(line=line):
                self.bashrc.write_text(line)
                self.run_script('installa-gh.sh')
                result = self.bashrc.read_text()
                self.assertTrue(result.startswith(line))
                self.assertIn('if [ -d "$HOME/.local/bin" ]; then', result)

    def test_failed_script_download_preserves_installed_files(self):
        self.exe(self.local/'github-inizio.sh', 'previous version\n')
        self.env['LAB_TEST_CURL_FAIL'] = 'github-fine.sh'
        self.run_script('install.sh', success=False)
        self.assertEqual((self.local/'github-inizio.sh').read_text(), 'previous version\n')
        self.assertFalse(self.bashrc.exists())

    def test_failed_gh_download_does_not_report_success(self):
        self.env['LAB_TEST_DOWNLOAD_FAIL'] = '1'
        r = self.run_script('install.sh', success=False)
        self.assertNotIn('Installazione completata', r.stdout)
        self.assertFalse((self.local/'gh').exists())

    def test_sessions_find_local_gh_and_cleanup_previous_account(self):
        self.exe(self.local/'gh', GH)
        (self.dir/'auth').touch()
        self.run_script('github-inizio.sh')
        calls = self.calls()
        self.assertLess(calls.index('auth logout'), calls.index('auth login'))
        self.run_script('github-fine.sh')
        self.run_script('github-fine.sh')
        self.assertFalse((self.dir/'auth').exists())

    def test_wrong_account_and_partial_login_cleanup(self):
        self.exe(self.local/'gh', GH)
        for key, value in (('LAB_TEST_ACCOUNT', 'bob'), ('LAB_TEST_LOGIN_FAIL', '1')):
            with self.subTest(key=key):
                self.env[key] = value
                self.run_script('github-inizio.sh', success=False)
                self.assertFalse((self.dir/'auth').exists())
                del self.env[key]

    def test_failed_cleanup_blocks_login(self):
        self.exe(self.local/'gh', GH)
        (self.dir/'auth').touch()
        self.env['LAB_TEST_LOGOUT_FAIL'] = '1'
        self.run_script('github-inizio.sh', success=False)
        self.assertNotIn('auth login', self.calls())

    def test_environment_token_blocks_login_but_cleans_disk(self):
        self.exe(self.local/'gh', GH)
        (self.dir/'auth').touch()
        self.env['GH_TOKEN'] = 'mock-token-not-a-secret'
        self.run_script('github-inizio.sh', success=False)
        self.assertNotIn('auth login', self.calls())
        self.assertFalse((self.dir/'auth').exists())


if __name__ == '__main__':
    unittest.main()
