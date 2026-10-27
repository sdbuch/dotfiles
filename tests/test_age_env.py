import os
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AGE_ENV = ROOT / "scripts" / "age-env"


class AgeEnvironmentTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        root = Path(self.temp_dir.name)
        self.config_dir = root / "config"
        self.data_dir = root / "data"
        self.profile_dir = self.config_dir / "profiles"
        self.profile_dir.mkdir(parents=True, mode=0o700)
        self.data_dir.mkdir(mode=0o700)
        self.identity = self.data_dir / "identity.txt"
        self.identity.write_text("test identity\n")
        self.identity.chmod(0o600)

        bin_dir = root / "bin"
        bin_dir.mkdir()
        age = bin_dir / "age"
        age.write_text(
            "#!/bin/sh\n"
            "decrypt=false\n"
            "last=\n"
            'for arg in "$@"; do\n'
            '  [ "$arg" = --decrypt ] && decrypt=true\n'
            "  last=$arg\n"
            "done\n"
            'if [ "$decrypt" = true ]; then cat "$last"; else cat; fi\n'
        )
        age.chmod(age.stat().st_mode | stat.S_IXUSR)
        age_keygen = bin_dir / "age-keygen"
        age_keygen.write_text(
            "#!/bin/sh\n"
            'if [ "$1" = -y ]; then echo age1testrecipient; exit 0; fi\n'
            'if [ "$1" = -o ]; then printf \'test identity\\n\' > "$2"; exit 0; fi\n'
            "exit 2\n"
        )
        age_keygen.chmod(age_keygen.stat().st_mode | stat.S_IXUSR)

        self.environment = os.environ.copy()
        self.environment.update(
            {
                "AGE_ENV_CONFIG_DIR": str(self.config_dir),
                "AGE_ENV_DATA_DIR": str(self.data_dir),
                "PATH": f"{bin_dir}:{self.environment['PATH']}",
            }
        )

    def write_profile(self, profile: str, payload: str, keys: list[str]) -> None:
        (self.profile_dir / f"{profile}.env.age").write_text(payload)
        (self.profile_dir / f"{profile}.keys").write_text(
            "".join(f"{key}\n" for key in keys)
        )

    def invoke(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(AGE_ENV), *arguments],
            capture_output=True,
            check=False,
            env=self.environment,
            text=True,
        )

    def test_run_injects_values_without_printing_them(self) -> None:
        self.write_profile(
            "example",
            "EXAMPLE_API_KEY=super-secret-test-value\n",
            ["EXAMPLE_API_KEY"],
        )
        check = (
            "import os,sys; "
            "sys.exit(0 if os.environ.get('EXAMPLE_API_KEY') == "
            "'super-secret-test-value' else 1)"
        )

        result = self.invoke("run", "example", "--", sys.executable, "-c", check)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertNotIn("super-secret-test-value", result.stderr)

    def test_rejects_unexpected_variable_before_running_command(self) -> None:
        marker = Path(self.temp_dir.name) / "command-ran"
        self.write_profile(
            "example",
            "EXPECTED=value\nUNEXPECTED=value\n",
            ["EXPECTED"],
        )

        result = self.invoke(
            "run",
            "example",
            "--",
            sys.executable,
            "-c",
            f"from pathlib import Path; Path({str(marker)!r}).touch()",
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unexpected variable", result.stderr)
        self.assertFalse(marker.exists())

    def test_list_and_has_expose_only_metadata(self) -> None:
        self.write_profile("example", "EXAMPLE_KEY=value\n", ["EXAMPLE_KEY"])

        listing = self.invoke("list")
        present = self.invoke("has", "example", "EXAMPLE_KEY")
        absent = self.invoke("has", "example", "OTHER_KEY")

        self.assertEqual(listing.returncode, 0, listing.stderr)
        self.assertEqual(listing.stdout, "example\tready\tEXAMPLE_KEY\n")
        self.assertEqual(present.returncode, 0)
        self.assertEqual(present.stdout, "yes\n")
        self.assertEqual(absent.returncode, 1)
        self.assertEqual(absent.stdout, "no\n")
        self.assertNotIn("value", listing.stdout + present.stdout + absent.stdout)

    def test_doctor_rejects_group_readable_identity(self) -> None:
        self.write_profile("example", "EXAMPLE_KEY=value\n", ["EXAMPLE_KEY"])
        self.identity.chmod(0o640)

        result = self.invoke("doctor", "example")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("permits group or other access", result.stderr)

    def test_init_creates_private_identity(self) -> None:
        self.identity.unlink()

        result = self.invoke("init")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.identity.is_file())
        self.assertEqual(stat.S_IMODE(self.identity.stat().st_mode), 0o600)
        self.assertIn("recipient: age1testrecipient", result.stdout)


if __name__ == "__main__":
    unittest.main()
