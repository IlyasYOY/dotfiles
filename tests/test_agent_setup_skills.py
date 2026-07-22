import json
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SKILLS_ROOT = REPO_ROOT / ".agents" / "skills"


class AgentSetupSkillsTest(unittest.TestCase):
    def test_repo_local_skills_and_references_exist(self) -> None:
        expected = {
            "setup-codex": "config.toml",
            "setup-opencode": "opencode.json",
        }

        for skill_name, reference_name in expected.items():
            with self.subTest(skill=skill_name):
                skill_root = SKILLS_ROOT / skill_name
                self.assertTrue((skill_root / "SKILL.md").is_file())
                self.assertTrue(
                    (skill_root / "references" / reference_name).is_file()
                )

    def test_project_opencode_config_registers_only_setup_skill(self) -> None:
        config = json.loads((REPO_ROOT / "opencode.json").read_text())

        self.assertEqual(
            config["skills"]["paths"],
            [".agents/skills/setup-opencode"],
        )

    def test_opencode_reference_is_strict_json_object(self) -> None:
        reference = json.loads(
            (
                SKILLS_ROOT
                / "setup-opencode"
                / "references"
                / "opencode.json"
            ).read_text()
        )

        self.assertIsInstance(reference, dict)
        self.assertEqual(reference["$schema"], "https://opencode.ai/config.json")

    def test_bootstrap_does_not_manage_user_config_files(self) -> None:
        install = (REPO_ROOT / "sh" / "setup" / "install.sh").read_text()
        helpers = (REPO_ROOT / "sh" / "setup" / "helpers.sh").read_text()

        self.assertNotIn("config/opencode/opencode.json", install)
        self.assertNotIn("config.toml", install)
        self.assertNotIn("configure_opencode_json()", helpers)
        self.assertNotIn("add_toml_root_block()", helpers)
        self.assertNotIn("add_toml_table_block()", helpers)

    def test_legacy_opencode_default_was_moved_into_skill(self) -> None:
        legacy_config = REPO_ROOT / "config" / "opencode" / "opencode.json"

        self.assertFalse(legacy_config.exists())


if __name__ == "__main__":
    unittest.main()
