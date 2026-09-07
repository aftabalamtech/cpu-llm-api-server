import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class RepositoryContractTests(unittest.TestCase):
    def test_required_files_exist(self):
        required = [
            "README.md", "LICENSE", ".gitignore", ".dockerignore", ".env.example",
            "Dockerfile", "docker-compose.yml", "railway.toml", "render.yaml",
            "scripts/start.sh", "scripts/start.ps1", "scripts/download-model.sh",
            "scripts/healthcheck.sh", "docs/architecture.md", "models/.gitkeep",
        ]
        for relative in required:
            self.assertTrue((ROOT / relative).is_file(), relative)

    def test_required_environment_contract_is_present(self):
        env = (ROOT / ".env.example").read_text()
        for name in [
            "MODEL_REPO", "MODEL_FILE", "MODEL_PATH", "MODEL_ALIAS", "PORT",
            "CPU_THREADS", "CONTEXT_SIZE", "BATCH_SIZE", "API_KEY",
        ]:
            self.assertRegex(env, rf"(?m)^{name}=", name)

    def test_launcher_uses_documented_flags(self):
        script = (ROOT / "scripts/start.sh").read_text()
        for flag in [
            "--model", "--alias", "--host", "--port", "--threads",
            "--threads-batch", "--ctx-size", "--batch-size", "--ubatch-size",
            "--parallel", "--no-webui", "--api-key",
        ]:
            self.assertIn(flag, script)
        self.assertNotIn("--n-ctx", script)
        self.assertNotIn("--threads-http", script)

    def test_provider_configs_do_not_hardcode_provider_ports(self):
        railway = (ROOT / "railway.toml").read_text()
        render = (ROOT / "render.yaml").read_text()
        self.assertNotRegex(railway, r"(?m)^port\s*=")
        self.assertNotIn("8080", render)
        self.assertIn("healthcheckPath = \"/health\"", railway)
        self.assertIn("healthCheckPath: /health", render)

    def test_no_large_model_is_committed(self):
        models = [p for p in (ROOT / "models").iterdir() if p.name != ".gitkeep"]
        self.assertEqual(models, [])


if __name__ == "__main__":
    unittest.main()
