from __future__ import annotations

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]
HELPERS = REPO_ROOT / "sh/setup/helpers.sh"
MANAGER = REPO_ROOT / "sh/setup/codex-external-skills.sh"


class ExternalCodexSkillsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        self.home = self.root / "home"
        self.data_root = self.root / "data"
        self.dest_root = self.root / "codex-skills"
        self.manifest = self.root / "external-skills.conf"
        self.home.mkdir()

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def git(self, repo: Path, *args: str) -> str:
        result = subprocess.run(
            ["git", "-C", str(repo), *args],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        return result.stdout.strip()

    def create_repo(self, skills: dict[str, str]) -> tuple[Path, str]:
        repo = self.root / "source"
        repo.mkdir()
        subprocess.run(["git", "init", "-q", str(repo)], check=True)
        for name, content in skills.items():
            skill_dir = repo / "skills" / name
            skill_dir.mkdir(parents=True)
            (skill_dir / "SKILL.md").write_text(
                f"---\nname: {name}\ndescription: Test {name}\n---\n\n{content}\n"
            )
        (repo / "unrelated.txt").write_text("not a skill\n")
        self.git(repo, "add", ".")
        self.git(
            repo,
            "-c",
            "user.name=Codex Tests",
            "-c",
            "user.email=codex-tests@example.invalid",
            "commit",
            "-qm",
            "initial",
        )
        return repo, self.git(repo, "rev-parse", "HEAD")

    def commit(self, repo: Path, message: str) -> str:
        self.git(repo, "add", ".")
        self.git(
            repo,
            "-c",
            "user.name=Codex Tests",
            "-c",
            "user.email=codex-tests@example.invalid",
            "commit",
            "-qm",
            message,
        )
        return self.git(repo, "rev-parse", "HEAD")

    def run_manager(
        self,
        command: str,
        *args: str,
        input_text: str | None = None,
    ) -> subprocess.CompletedProcess[str]:
        env = os.environ.copy()
        env.update(
            {
                "HOME": str(self.home),
                "EXTERNAL_CODEX_SKILLS_DATA_ROOT": str(self.data_root),
                "EXTERNAL_CODEX_SKILLS_DEST_ROOT": str(self.dest_root),
                "EXTERNAL_CODEX_SKILLS_MANIFEST": str(self.manifest),
            }
        )
        script = f'source "{HELPERS}"; source "{MANAGER}"; {command} "$@"'
        return subprocess.run(
            ["bash", "-c", script, "manager", *args],
            check=False,
            input=input_text,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            env=env,
        )

    def test_installs_all_discovered_skills_by_default(self) -> None:
        repo, commit = self.create_repo({"one": "One", "two": "Two"})

        result = self.run_manager(
            "install_skills_from_repo", str(repo), commit
        )

        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertTrue((self.dest_root / "one").is_symlink())
        self.assertTrue((self.dest_root / "two").is_symlink())
        self.assertFalse((self.dest_root / "unrelated.txt").exists())
        self.assertIn(commit, os.readlink(self.dest_root / "one"))

        repeated = self.run_manager(
            "install_skills_from_repo", str(repo), commit
        )
        self.assertEqual(repeated.returncode, 0, repeated.stdout)

    def test_manifest_can_install_all_skills_without_include_paths(self) -> None:
        repo, commit = self.create_repo({"one": "One", "two": "Two"})
        self.manifest.write_text(f"{repo}|main|{commit}|\n")

        result = self.run_manager("install_external_codex_skills")

        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertTrue((self.dest_root / "one").is_symlink())
        self.assertTrue((self.dest_root / "two").is_symlink())

    def test_include_paths_limit_installed_skills(self) -> None:
        repo, commit = self.create_repo({"one": "One", "two": "Two"})

        result = self.run_manager(
            "install_skills_from_repo", str(repo), commit, "skills/two"
        )

        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertFalse((self.dest_root / "one").exists())
        self.assertTrue((self.dest_root / "two").is_symlink())

    def test_rejects_non_commit_refs_and_escaping_paths(self) -> None:
        repo, commit = self.create_repo({"one": "One"})

        bad_commit = self.run_manager(
            "install_skills_from_repo", str(repo), "main"
        )
        bad_path = self.run_manager(
            "install_skills_from_repo", str(repo), commit, "../skills"
        )

        self.assertNotEqual(bad_commit.returncode, 0)
        self.assertIn("full lowercase 40-character SHA", bad_commit.stdout)
        self.assertNotEqual(bad_path.returncode, 0)
        self.assertIn("Invalid external skill include path", bad_path.stdout)

    def test_rejects_symlinks_inside_a_skill(self) -> None:
        repo, _ = self.create_repo({"one": "One"})
        (repo / "skills/one/link.md").symlink_to("SKILL.md")
        commit = self.commit(repo, "add symlink")

        result = self.run_manager(
            "install_skills_from_repo", str(repo), commit
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("contains a symlink", result.stdout)
        self.assertFalse((self.dest_root / "one").exists())

    def test_rejects_gitlinks_inside_a_skill(self) -> None:
        repo, object_id = self.create_repo({"one": "One"})
        self.git(
            repo,
            "update-index",
            "--add",
            "--cacheinfo",
            f"160000,{object_id},skills/one/dependency",
        )
        self.git(
            repo,
            "-c",
            "user.name=Codex Tests",
            "-c",
            "user.email=codex-tests@example.invalid",
            "commit",
            "-qm",
            "add gitlink",
        )
        commit = self.git(repo, "rev-parse", "HEAD")

        result = self.run_manager(
            "install_skills_from_repo", str(repo), commit
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("non-file Git object", result.stdout)

    def test_rejects_existing_skill_name_collision(self) -> None:
        repo, commit = self.create_repo({"one": "One"})
        self.dest_root.mkdir()
        (self.dest_root / "one").mkdir()

        result = self.run_manager(
            "install_skills_from_repo", str(repo), commit
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("collides with an existing path", result.stdout)

    def test_review_decline_preserves_and_accept_updates(self) -> None:
        repo, old_commit = self.create_repo({"one": "Old"})
        first_install = self.run_manager(
            "install_skills_from_repo", str(repo), old_commit, "skills"
        )
        self.assertEqual(first_install.returncode, 0, first_install.stdout)

        (repo / "skills/one/SKILL.md").write_text(
            "---\nname: one\ndescription: Test one\n---\n\nNew\n"
        )
        second_dir = repo / "skills/two"
        second_dir.mkdir()
        (second_dir / "SKILL.md").write_text(
            "---\nname: two\ndescription: Test two\n---\n\nTwo\n"
        )
        new_commit = self.commit(repo, "update skills")
        self.manifest.write_text(f"{repo}|main|{old_commit}|skills\n")

        declined = self.run_manager(
            "review_and_update_skills_from_repo",
            str(repo),
            old_commit,
            new_commit,
            "skills",
            input_text="n\n",
        )

        self.assertEqual(declined.returncode, 2, declined.stdout)
        self.assertIn(old_commit, os.readlink(self.dest_root / "one"))
        self.assertIn(old_commit, self.manifest.read_text())

        accepted = self.run_manager(
            "review_and_update_skills_from_repo",
            str(repo),
            old_commit,
            new_commit,
            "skills",
            input_text="y\n",
        )

        self.assertEqual(accepted.returncode, 0, accepted.stdout)
        self.assertIn(new_commit, os.readlink(self.dest_root / "one"))
        self.assertTrue((self.dest_root / "two").is_symlink())
        self.assertIn(new_commit, self.manifest.read_text(), accepted.stdout)

    def test_manifest_update_driver_resolves_tracked_ref(self) -> None:
        repo, old_commit = self.create_repo({"one": "Old"})
        branch = self.git(repo, "branch", "--show-current")
        first_install = self.run_manager("install_external_codex_skills")
        self.assertNotEqual(first_install.returncode, 0)

        self.manifest.write_text(f"{repo}|{branch}|{old_commit}|skills\n")
        first_install = self.run_manager("install_external_codex_skills")
        self.assertEqual(first_install.returncode, 0, first_install.stdout)

        (repo / "skills/one/SKILL.md").write_text(
            "---\nname: one\ndescription: Test one\n---\n\nUpdated\n"
        )
        new_commit = self.commit(repo, "update tracked skill")

        updated = self.run_manager(
            "update_external_codex_skills", input_text="y\n"
        )

        self.assertEqual(updated.returncode, 0, updated.stdout)
        self.assertIn(new_commit, self.manifest.read_text(), updated.stdout)
        self.assertIn(new_commit, os.readlink(self.dest_root / "one"))

    def test_accepted_update_removes_a_deleted_managed_skill(self) -> None:
        repo, old_commit = self.create_repo({"one": "One", "two": "Two"})
        branch = self.git(repo, "branch", "--show-current")
        self.manifest.write_text(f"{repo}|{branch}|{old_commit}|skills\n")
        installed = self.run_manager("install_external_codex_skills")
        self.assertEqual(installed.returncode, 0, installed.stdout)

        self.git(repo, "rm", "-qr", "skills/two")
        new_commit = self.commit(repo, "remove second skill")
        updated = self.run_manager(
            "update_external_codex_skills", input_text="y\n"
        )

        self.assertEqual(updated.returncode, 0, updated.stdout)
        self.assertTrue((self.dest_root / "one").is_symlink())
        self.assertFalse((self.dest_root / "two").exists())
        self.assertIn(new_commit, self.manifest.read_text())


if __name__ == "__main__":
    unittest.main()
