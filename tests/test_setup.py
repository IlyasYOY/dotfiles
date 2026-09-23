from __future__ import annotations

from pathlib import Path
import shutil
import subprocess
import tempfile
import textwrap
import unittest


ROOT = Path(__file__).resolve().parents[1]


class SetupTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.home = self.root / "home"
        self.home.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.tmp = self.root / "tmp"
        self.tmp.mkdir()
        self.env = {
            "HOME": str(self.home),
            "PATH": f"{self.bin}:/usr/bin:/bin:/usr/sbin:/sbin",
            "TMPDIR": str(self.tmp),
            "TEST_ROOT": str(self.root),
            "GIT_PARALLEL_JOBS": "2",
        }
        # Never let an unexpected dependency reach the host or the network.
        for command in ("git", "curl", "brew", "sudo", "defaults", "gpgconf",
                        "go", "fnm", "wt", "tmux", "killall"):
            self.stub(command, 'printf "unexpected command: %s\\n" "$0 $*" >&2; exit 97')

    def stub(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/bash\nset -eu\n" + textwrap.dedent(body) + "\n")
        path.chmod(0o755)
        return path

    def shell(self, body, script="helpers.sh"):
        source = ROOT / "sh/setup" / script
        return subprocess.run(
            ["/bin/bash", "--noprofile", "--norc", "-c",
             'source "$1"; is_mac() { return 0; }; ' + body, "bash", str(source)],
            env=self.env, cwd=self.home, capture_output=True, text=True, timeout=30,
        )

    def test_package_failures_are_nonzero(self):
        self.stub("brew", 'case "$1" in shellenv|--version) exit 0;; *) exit 9;; esac')
        for function in ("update_brew", "update_brew_packages", "update_brew_cask_packages"):
            with self.subTest(function=function):
                result = self.shell(f'source "{ROOT}/sh/setup/mac.sh"; {function}')
                self.assertNotEqual(result.returncode, 0, result.stdout)

    def test_parallel_clone_reports_failure_after_all_workers_finish(self):
        self.stub("git", '''
            if [ "$2" = bad ]; then exit 8; fi
            mkdir -p "$3/.git"
        ''')
        result = self.shell('clone_repos_parallel bad "$HOME/bad" good "$HOME/good"')
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertTrue((self.home / "good/.git").is_dir())
        self.assertIn("failed", result.stdout)
        self.assertTrue(list(self.tmp.glob("dotfiles-git-clone.*/*.log")))

    def test_parallel_updates_finish_and_keep_failure_logs(self):
        for name in ("good", "bad"):
            (self.home / name / ".git").mkdir(parents=True)
        self.stub("git", '''
            case "$2" in */bad) exit 8;; esac
            touch "$2/updated"
        ''')
        result = self.shell('update_repos_parallel "$HOME/bad" "$HOME/good"', "update.sh")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertTrue((self.home / "good/updated").exists())
        self.assertTrue(list(self.tmp.glob("dotfiles-git-update.*/*.log")))

    def test_parallel_success_and_invalid_concurrency_fallback(self):
        self.env["GIT_PARALLEL_JOBS"] = "0"
        self.stub("git", 'mkdir -p "$3/.git"')
        result = self.shell('clone_repos_parallel one "$HOME/one" two "$HOME/two"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.home / "one/.git").exists())
        self.assertTrue((self.home / "two/.git").exists())
        self.assertEqual(list(self.tmp.iterdir()), [])

    def test_parallel_worker_without_status_is_a_failure(self):
        self.stub("git", 'kill -TERM "$PPID"; exit 8')
        result = self.shell('clone_repos_parallel bad "$HOME/bad"')
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("failed", result.stdout)
        self.assertTrue(list(self.tmp.glob("dotfiles-git-clone.*")))

    def download(self, body, status=0):
        payload = self.root / "installer"
        payload.write_text(textwrap.dedent(body))
        self.stub("curl", f'cp "$TEST_ROOT/installer" "$4"; exit {status}')

    def test_download_errors_never_execute_partial_or_empty_content(self):
        for body, status in (('touch "$HOME/executed"', 22), ("", 0)):
            with self.subTest(status=status):
                self.download(body, status)
                result = self.shell('run_downloaded_installer https://example.invalid/install bash')
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertFalse((self.home / "executed").exists())
                self.assertEqual(list(self.tmp.iterdir()), [])

    def test_installer_status_arguments_and_cleanup(self):
        self.download('printf "%s\\n" "$@" > "$HOME/arguments"; exit 7')
        result = self.shell('run_downloaded_installer https://example.invalid/install bash "two words" --flag')
        self.assertEqual(result.returncode, 7, result.stderr)
        self.assertEqual((self.home / "arguments").read_text(), "two words\n--flag\n")
        self.assertEqual(list(self.tmp.iterdir()), [])

    def test_installers_require_artifacts_and_preserve_incomplete_directories(self):
        for function, directory, artifact in (
            ("setup_sdkman", ".sdkman", "bin/sdkman-init.sh"),
            ("setup_go_version_manager", ".gvm", "scripts/gvm"),
            ("setup_oh_my_zsh", ".oh-my-zsh", "oh-my-zsh.sh"),
        ):
            with self.subTest(function=function):
                self.download("exit 0")
                result = self.shell(function, "install.sh")
                self.assertNotEqual(result.returncode, 0, result.stdout)
                partial = self.home / directory
                partial.mkdir()
                (partial / "user-data").write_text("keep")
                self.download('touch "$HOME/should-not-download"')
                result = self.shell(function, "install.sh")
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertEqual((partial / "user-data").read_text(), "keep")
                self.assertFalse((self.home / "should-not-download").exists())
                installed = partial / artifact
                installed.parent.mkdir(parents=True, exist_ok=True)
                installed.write_text(":\n")
                result = self.shell(function, "install.sh")
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_oh_my_zsh_preserves_rc_symlink_and_managed_integrations(self):
        rc = self.home / "user.zshrc"
        rc.write_text("export USER_CONFIG=preserved\n")
        (self.home / ".zshrc").symlink_to(rc)
        self.download('''
            test "$1" = --unattended && test "$2" = --keep-zshrc || exit 7
            mkdir -p "$HOME/.oh-my-zsh"
            printf ':\\n' > "$HOME/.oh-my-zsh/oh-my-zsh.sh"
        ''')
        for _ in range(2):
            result = self.shell("setup_oh_my_zsh; setup_shell_rc", "install.sh")
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.home / ".zshrc").is_symlink())
        self.assertIn("export USER_CONFIG=preserved\n", rc.read_text())
        self.assertEqual(rc.read_text().count("/sh/helpers.sh"), 1)

    def test_legacy_shell_sources_are_not_duplicated(self):
        rc = self.home / ".zshrc"
        legacy = "".join(f"source $ILYASYOY_DOTFILES_DIR/sh/{name}.sh\n"
                         for name in ("helpers", "exports", "aliases"))
        rc.write_text(legacy)
        result = self.shell("setup_shell_rc", "install.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(rc.read_text().startswith(legacy))
        for name in ("helpers", "exports", "aliases"):
            self.assertEqual(rc.read_text().count(f"/sh/{name}.sh"), 1)

    def test_load_brew_from_explicit_location_and_check_shellenv(self):
        brew = self.bin / "brew"
        brew.unlink()
        prefix = self.root / "custom prefix"
        prefix.mkdir()
        executable = prefix / "brew"
        executable.write_text('#!/bin/bash\ncase "$1" in shellenv) printf \'export PATH="%s:$PATH"\\n\' "${0%/*}";; --version) exit 0;; esac\n')
        executable.chmod(0o755)
        self.env["BREW_EXECUTABLE"] = str(executable)
        result = self.shell('load_brew "$BREW_EXECUTABLE"; command -v brew')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), str(executable))
        executable.write_text("#!/bin/bash\nexit 8\n")
        result = self.shell('load_brew "$BREW_EXECUTABLE"')
        self.assertNotEqual(result.returncode, 0)

    def test_homebrew_bootstrap_checks_download_and_load(self):
        # Inject the executable discovery boundary, never probe host installations.
        discover = 'load_mac_brew() { load_brew "$TEST_ROOT/new-brew/brew"; }; '
        (self.bin / "brew").unlink()
        self.download('''
            test "$NONINTERACTIVE" = 1 || exit 9
            mkdir -p "$TEST_ROOT/new-brew"
            cat > "$TEST_ROOT/new-brew/brew" <<'BREW'
#!/bin/bash
case "$1" in
shellenv) printf 'export PATH="%s:$PATH"\\n' "${0%/*}";;
--version) exit 0;;
esac
BREW
            chmod +x "$TEST_ROOT/new-brew/brew"
        ''')
        result = self.shell(discover + "setup_mac_homebrew", "install.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("shellenv", (self.home / ".zshrc").read_text())
        self.stub("curl", "exit 99")
        result = self.shell(discover + "setup_mac_homebrew", "install.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.home / ".zshrc").read_text().count("## start"), 1)
        shutil.rmtree(self.root / "new-brew")
        self.download("exit 0")
        result = self.shell(discover + "setup_mac_homebrew", "install.sh")
        self.assertNotEqual(result.returncode, 0, result.stdout)

    def prepare_pinentry(self):
        prefix = self.root / "pinentry prefix"
        (prefix / "bin").mkdir(parents=True, exist_ok=True)
        executable = prefix / "bin/pinentry-touchid"
        executable.write_text("#!/bin/bash\nexit 0\n")
        executable.chmod(0o755)
        self.stub("brew", 'printf "%s\\n" "$TEST_ROOT/pinentry prefix"')
        self.stub("defaults", "exit 0")
        self.stub("gpgconf", "exit 0")
        return executable

    def test_gnupg_renders_resolved_pinentry_and_migrates_known_link(self):
        executable = self.prepare_pinentry()
        (self.home / ".gnupg").mkdir()
        link = self.home / ".gnupg/gpg-agent.conf"
        link.symlink_to(ROOT / "config/gnupg/gpg-agent.conf")
        for _ in range(2):
            result = self.shell("setup_gnupg", "install.sh")
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(link.readlink(), self.home / ".config/dotfiles/gpg-agent.conf")
        self.assertIn(f"pinentry-program {executable}\n", link.read_text())
        self.assertIn("default-cache-ttl 0\n", link.read_text())
        self.assertIn("max-cache-ttl 0\n", link.read_text())
        self.assertEqual(len(list((self.home / ".gnupg").glob("dotfiles-backup.*/*"))), 1)

    def test_gnupg_preserves_unknown_files_and_links(self):
        self.prepare_pinentry()
        (self.home / ".gnupg").mkdir()
        link = self.home / ".gnupg/gpg-agent.conf"
        for kind in ("file", "symlink"):
            with self.subTest(kind=kind):
                if kind == "file":
                    link.write_text("user config\n")
                else:
                    link.symlink_to(self.home / "missing")
                result = self.shell("setup_gnupg", "install.sh")
                self.assertEqual(result.returncode, 0, result.stderr)
                if kind == "file":
                    self.assertEqual(link.read_text(), "user config\n")
                else:
                    self.assertEqual(link.readlink(), self.home / "missing")
                self.assertFalse((self.home / ".config/dotfiles/gpg-agent.conf").exists())
                link.unlink()

    def test_gnupg_rejects_missing_executable(self):
        executable = self.prepare_pinentry()
        executable.unlink()
        result = self.shell("setup_gnupg", "install.sh")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.home / ".gnupg/gpg-agent.conf").exists())

    def test_gnupg_preserves_unknown_generated_destination(self):
        self.prepare_pinentry()
        generated = self.home / ".config/dotfiles/gpg-agent.conf"
        generated.parent.mkdir(parents=True)
        generated.write_text("not a managed file\n")
        result = self.shell("setup_gnupg", "install.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(generated.read_text(), "not a managed file\n")
        self.assertFalse((self.home / ".gnupg/gpg-agent.conf").exists())

    def test_gnupg_rerenders_when_formula_prefix_changes(self):
        self.prepare_pinentry()
        result = self.shell("setup_gnupg", "install.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        prefix = self.root / "other-prefix"
        (prefix / "bin").mkdir(parents=True)
        executable = prefix / "bin/pinentry-touchid"
        executable.write_text("#!/bin/bash\nexit 0\n")
        executable.chmod(0o755)
        self.stub("brew", 'printf "%s\\n" "$TEST_ROOT/other-prefix"')
        result = self.shell("setup_gnupg", "install.sh")
        self.assertEqual(result.returncode, 0, result.stderr)
        content = (self.home / ".gnupg/gpg-agent.conf").read_text()
        self.assertIn(str(executable), content)
        self.assertNotIn("pinentry prefix", content)

    def prepare_tpm(self):
        directory = self.home / ".tmux/plugins/tpm"
        (directory / ".git").mkdir(parents=True)
        (directory / "bin").mkdir()
        for name, body in (
            ("install_plugins", 'mkdir -p "$HOME/.tmux/plugins/declared-plugin"'),
            ("update_plugins", 'touch "$HOME/.tmux/plugins/declared-plugin/updated"'),
        ):
            path = directory / "bin" / name
            path.write_text("#!/bin/bash\n" + body + "\n")
            path.chmod(0o755)
        return directory

    def test_existing_tpm_repairs_plugins_on_install_and_update(self):
        self.prepare_tpm()
        plugin = self.home / ".tmux/plugins/declared-plugin"
        for function in ("setup_tmux_plugins", "update_tmux_plugins"):
            with self.subTest(function=function):
                result = self.shell(function, "update.sh")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertTrue(plugin.exists())
                if function == "update_tmux_plugins":
                    self.assertTrue((plugin / "updated").exists())
                shutil.rmtree(plugin)

    def test_missing_tpm_is_cloned_and_plugins_installed(self):
        template = self.prepare_tpm()
        shutil.move(str(template), self.root / "tpm-template")
        self.stub("git", 'cp -R "$TEST_ROOT/tpm-template" "$3"')
        result = self.shell("setup_tmux_plugins")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.home / ".tmux/plugins/declared-plugin").is_dir())

    def test_tpm_clone_and_missing_executable_fail(self):
        self.stub("git", "exit 8")
        result = self.shell("setup_tmux_plugins")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        (self.home / ".tmux/plugins/tpm/.git").mkdir(parents=True)
        result = self.shell("setup_tmux_plugins")
        self.assertNotEqual(result.returncode, 0, result.stdout)

    def test_tmux_failures_are_nonzero(self):
        directory = self.prepare_tpm()
        for name in ("update_plugins", "install_plugins"):
            with self.subTest(name=name):
                (directory / "bin" / name).write_text("#!/bin/bash\nexit 8\n")
                result = self.shell("update_tmux_plugins", "update.sh")
                self.assertNotEqual(result.returncode, 0, result.stdout)

    def prepare_flow(self):
        """A complete workstation fixture: no real installers or package managers."""
        checkout = self.root / "dotfiles"
        checkout.mkdir()
        for directory in ("sh", "config"):
            shutil.copytree(ROOT / directory, checkout / directory)
        for name in ("Makefile", "Brewfile.mac", "Brewfile.mac.cask"):
            shutil.copy2(ROOT / name, checkout / name)
        (checkout / ".git").mkdir()
        self.env["TEST_CHECKOUT"] = str(checkout)
        self.prepare_pinentry()
        self.stub("uname", "printf 'Darwin\\n'")
        self.stub("brew", '''
            case "$1" in
            shellenv) printf 'export PATH="%s:$PATH"\\n' "${0%/*}";;
            --version) printf 'Homebrew fixture\\n';;
            --prefix) printf '%s\\n' "$TEST_ROOT/pinentry prefix";;
            update|upgrade) test "${FAIL_OPERATION:-}" != "$1";;
            bundle)
                test "${FAIL_OPERATION:-}" != bundle || exit 8
                while [ "$1" != --file ]; do shift; done
                cat "$2" >> "$TEST_ROOT/installed-packages"
                ;;
            *) exit 97;;
            esac
        ''')
        self.stub("git", '''
            case "$1" in
            ls-files|config) exit 0;;
            clone)
                case "$2" in
                *password-store*) exit 8;;
                *t-invest*) test "${FAIL_OPERATION:-}" != clone || exit 8;;
                esac
                mkdir -p "$3/.git"
                case "$2" in
                *t-invest*) printf 'install:\\n\\t@touch "$(HOME)/built-t-invest"\\n' > "$3/Makefile";;
                esac
                ;;
            -C)
                if [ "$3" = init ]; then mkdir -p "$2/.git"; exit 0; fi
                test "$3" = pull || exit 97
                if [ "$2" = "$TEST_CHECKOUT" ]; then
                    test "${FAIL_OPERATION:-}" != pull || exit 8
                    printf 'brew "new-dependency"\\n' >> "$2/Brewfile.mac"
                fi
                case "$2" in
                *t-invest*) test "${FAIL_OPERATION:-}" != personal-pull || exit 8;;
                *password-store*) exit 8;;
                esac
                ;;
            *) exit 97;;
            esac
        ''')
        self.stub("curl", '''
            test "${FAIL_OPERATION:-}" != download || exit 22
            case "$2" in
            *ohmyzsh*)
                cat > "$4" <<'INSTALL'
test "$1" = --unattended && test "$2" = --keep-zshrc || exit 8
mkdir -p "$HOME/.oh-my-zsh"
printf ':\\n' > "$HOME/.oh-my-zsh/oh-my-zsh.sh"
if [ ! -e "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    printf '# Oh My Zsh fixture\\n' > "$HOME/.zshrc"
fi
INSTALL
                ;;
            *sdkman*)
                cat > "$4" <<'INSTALL'
mkdir -p "$HOME/.sdkman/bin"
printf 'export SDKMAN_STARTED=yes\\n' > "$HOME/.sdkman/bin/sdkman-init.sh"
INSTALL
                ;;
            *gvm*)
                cat > "$4" <<'INSTALL'
mkdir -p "$HOME/.gvm/scripts"
printf 'gvm() { printf "gvm-ready\\\\n"; }\\n' > "$HOME/.gvm/scripts/gvm"
INSTALL
                ;;
            *) exit 97;;
            esac
        ''')
        self.stub("go", 'touch "$HOME/built-go"')
        self.stub("wt", '''
            rc="$HOME/.${4}rc"
            if ! grep -q WORKTRUNK_STARTED "$rc"; then
                printf 'export WORKTRUNK_STARTED=yes\\n' >> "$rc"
            fi
        ''')
        self.stub("fnm", 'if [ "$1" = env ]; then printf "export FNM_STARTED=yes\\n"; fi')
        self.stub("fzf", "exit 0")
        self.stub("node", "exit 0")
        self.stub("npm", "exit 0")
        self.prepare_tpm()
        for name, variable in (("nvim", "ILYASYOY_NVIM_WORKBENCH_DIR"),
                               ("agent", "ILYASYOY_AGENT_WORKBENCH_DIR")):
            workbench = self.root / name
            workbench.mkdir()
            (workbench / "Makefile").write_text("install update:\n\t@touch completed-$@\n")
            self.env[variable] = str(workbench)
        return checkout

    def make(self, checkout, target):
        return subprocess.run(
            ["make", target], cwd=checkout, env=self.env, input="n\n",
            capture_output=True, text=True, timeout=30,
        )

    def test_make_install_and_update_reject_non_macos_without_changes(self):
        self.stub("uname", "printf 'Linux\\n'")
        # Make reads tracked Lua paths even for setup targets; allow only that read.
        self.stub("git", '''
            if [ "$1" = ls-files ]; then exit 0; fi
            printf 'unexpected command: git %s\\n' "$*" >&2
            exit 97
        ''')
        for target in ("install", "update"):
            with self.subTest(target=target):
                result = self.make(ROOT, target)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("Workstation setup supports macOS only", result.stdout)
                self.assertNotIn("unexpected command", result.stdout + result.stderr)
                self.assertEqual(list(self.home.iterdir()), [])
                self.assertEqual(list(self.tmp.iterdir()), [])

    def test_make_install_is_repeatable_and_preserves_shell_startup(self):
        checkout = self.prepare_flow()
        (self.home / ".zshrc").write_text("export USER_CONFIG=preserved\n")
        for _ in range(2):
            result = self.make(checkout, "install")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        rc = (self.home / ".zshrc").read_text()
        self.assertEqual(rc.count("/sh/helpers.sh"), 1)
        self.assertEqual(rc.count("## start ilyasyoy sdkman config"), 1)
        self.assertTrue((self.home / "built-t-invest").exists())
        self.assertTrue((self.root / "agent/completed-install").exists())
        self.assertTrue((self.home / ".tmux/plugins/declared-plugin").exists())
        self.assertNotIn("unexpected command", result.stderr)
        startup = subprocess.run(
            ["zsh", "-d", "-i", "-c",
             'test "$USER_CONFIG:$SDKMAN_STARTED:$WORKTRUNK_STARTED:$FNM_STARTED" = preserved:yes:yes:yes && '
             'whence kb-link >/dev/null && gvm'],
            cwd=self.home, env=self.env, capture_output=True, text=True, timeout=30,
        )
        self.assertEqual(startup.returncode, 0, startup.stdout + startup.stderr)
        self.assertIn("gvm-ready", startup.stdout)

    def test_make_update_installs_new_manifest_dependency_and_repairs_plugins(self):
        checkout = self.prepare_flow()
        required = self.home / "Projects/IlyasYOY/t-invest-mcp"
        (required / ".git").mkdir(parents=True)
        (required / "Makefile").write_text("install:\n\t@touch built\n")
        (self.home / ".password-store/.git").mkdir(parents=True)
        result = self.make(checkout, "update")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('brew "new-dependency"', (self.root / "installed-packages").read_text())
        self.assertTrue((required / "built").exists())
        self.assertTrue((self.home / ".tmux/plugins/declared-plugin/updated").exists())
        self.assertTrue((self.root / "agent/completed-update").exists())

    def test_make_install_stops_after_required_failures(self):
        checkout = self.prepare_flow()
        for operation in ("download", "bundle", "clone"):
            with self.subTest(operation=operation):
                self.env["FAIL_OPERATION"] = operation
                result = self.make(checkout, "install")
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertNotIn("Setup completed successfully", result.stdout)
                self.assertFalse((self.home / "built-t-invest").exists())
                self.assertFalse((self.root / "agent/completed-install").exists())

    def test_make_update_stops_after_required_failures(self):
        checkout = self.prepare_flow()
        (self.home / "Projects/IlyasYOY/t-invest-mcp/.git").mkdir(parents=True)
        for operation in ("pull", "update", "bundle", "upgrade", "personal-pull"):
            with self.subTest(operation=operation):
                self.env["FAIL_OPERATION"] = operation
                result = self.make(checkout, "update")
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertFalse((self.home / "built-go").exists())
                self.assertFalse((self.root / "agent/completed-update").exists())

    def test_missing_required_build_checkout_stops_update(self):
        checkout = self.prepare_flow()
        result = self.make(checkout, "update")
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Required build checkout is missing", result.stdout)
        self.assertFalse((self.home / "built-go").exists())

    def test_kb_link_preserves_unknown_entries(self):
        kb = self.home / "kb"
        kb.mkdir()
        self.env["ILYASYOY_KB_STORE_DIR"] = str(kb)
        self.stub("git", "exit 1")
        link = self.home / ".kb-store"
        other = self.home / "other"
        other.mkdir()
        for kind in ("file", "directory", "symlink", "dangling"):
            with self.subTest(kind=kind):
                if link.is_symlink() or link.is_file():
                    link.unlink()
                elif link.exists():
                    shutil.rmtree(link)
                if kind == "file":
                    link.write_text("user data\n")
                elif kind == "directory":
                    link.mkdir()
                else:
                    link.symlink_to(other if kind == "symlink" else self.home / "missing")
                before = link.readlink() if link.is_symlink() else None
                result = subprocess.run(
                    ["/bin/bash", "-c", 'source "$1"; kb-link', "bash", str(ROOT / "sh/helpers.sh")],
                    cwd=self.home, env=self.env, capture_output=True, text=True, timeout=30,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                if kind == "file":
                    self.assertEqual(link.read_text(), "user data\n")
                elif kind == "directory":
                    self.assertTrue(link.is_dir() and not link.is_symlink())
                else:
                    self.assertEqual(link.readlink(), before)
                if link.is_dir() and not link.is_symlink():
                    shutil.rmtree(link)
                else:
                    link.unlink()

    def test_kb_link_creates_link_and_preserves_existing_notes_on_repeat(self):
        kb = self.home / "kb"
        project = self.home / "project"
        kb.mkdir()
        project.mkdir()
        self.env["ILYASYOY_KB_STORE_DIR"] = str(kb)
        self.stub("git", "exit 1")
        for iteration in range(2):
            result = subprocess.run(
                ["/bin/bash", "-c", 'source "$1"; kb-link', "bash", str(ROOT / "sh/helpers.sh")],
                cwd=project, env=self.env, capture_output=True, text=True, timeout=30,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((project / ".kb-store").readlink(), kb)
            note = kb / "project/branch-master/README.md"
            if iteration == 0:
                self.assertTrue(note.exists())
                note.write_text("user notes\n")
            else:
                self.assertEqual(note.read_text(), "user notes\n")


if __name__ == "__main__":
    unittest.main()
