import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class ConfigurationTests(unittest.TestCase):
    def test_no_default_model_is_configured(self):
        env = (ROOT / ".env.example").read_text(encoding="utf-8")
        self.assertIn("MODEL_REPO=", env)
        self.assertIn("MODEL_FILE=", env)
        self.assertNotIn("MODEL_REPO=ggml-org/", env)
        self.assertNotIn("MODEL_FILE=gemma", env)

    def test_runtime_requires_environment_selected_model(self):
        script = (ROOT / "scripts" / "start.sh").read_text(encoding="utf-8")
        self.assertIn('MODEL_REPO', script)
        self.assertIn('MODEL_FILE', script)
        self.assertIn('No model configured.', script)

    def test_documentation_matches_model_policy(self):
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        self.assertIn("no default model", readme.lower())
        self.assertIn("MODEL_REPO", readme)
        self.assertIn("MODEL_FILE", readme)

    def test_required_docs_exist(self):
        for name in ("api.md", "configuration.md", "deployment.md", "troubleshooting.md"):
            self.assertTrue((ROOT / "docs" / name).is_file(), name)


if __name__ == "__main__":
    unittest.main()
