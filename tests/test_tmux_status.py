"""Status rendering and timer contracts without starting a tmux server.

Run from the repository root with:
    python3 -m unittest discover -s tests -v
"""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
RENDERER = ROOT / "scripts" / "tmux-mutagen-status.sh"


class MutagenRenderingTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="tmux-status-test-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.tmp = self.root / "tmp"
        self.tmp.mkdir()
        self.scenario = self.root / "scenario.json"
        self.calls = self.root / "calls.jsonl"
        mutagen = self.bin / "mutagen"
        mutagen.write_text(
            f"#!{sys.executable}\n"
            "import json, os, sys\n"
            "from pathlib import Path\n"
            "state = json.loads(Path(os.environ['MUTAGEN_TEST_STATE']).read_text())\n"
            "with open(os.environ['MUTAGEN_TEST_CALLS'], 'a') as f:\n"
            "    f.write(json.dumps(sys.argv[1:]) + '\\n')\n"
            "if sys.argv[1:] == ['daemon', 'running']:\n"
            "    sys.exit(state.get('daemon_exit', 0))\n"
            "if sys.argv[1:4] == ['sync', 'list', '--template']:\n"
            "    sys.stdout.write(state.get('rows', ''))\n"
            "    sys.exit(state.get('list_exit', 0))\n"
            "raise SystemExit('Unexpected Mutagen command: ' + repr(sys.argv))\n"
        )
        mutagen.chmod(0o755)

    def render(
        self,
        rows=(),
        *,
        daemon_exit=0,
        list_exit=0,
        mutagen_installed=True,
        expected_exit=0,
    ):
        self.scenario.write_text(
            json.dumps(
                {
                    "rows": "".join("\t".join(row) + "\n" for row in rows),
                    "daemon_exit": daemon_exit,
                    "list_exit": list_exit,
                }
            )
        )
        env = os.environ.copy()
        # A real tmux or Mutagen executable must never be reached by these tests.
        env.update(
            PATH=str(self.bin) if mutagen_installed else str(self.tmp),
            TMPDIR=str(self.tmp),
            MUTAGEN_TEST_STATE=str(self.scenario),
            MUTAGEN_TEST_CALLS=str(self.calls),
        )
        env.pop("TMUX", None)
        result = subprocess.run(
            ["/bin/bash", str(RENDERER)],
            env=env,
            text=True,
            capture_output=True,
            timeout=5,
            check=False,
        )
        self.assertEqual(result.returncode, expected_exit, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertEqual(list(self.tmp.iterdir()), [], "Rendering wrote a disk cache")
        return result.stdout

    def recorded_calls(self):
        if not self.calls.exists():
            return []
        return [json.loads(line) for line in self.calls.read_text().splitlines()]

    def test_main_status_icons_and_pause_precedence(self):
        cases = [
            ("Watching", "false", "✓"),
            ("Staging files", "false", "⟳"),
            ("Reconciling", "false", "⟳"),
            ("Saving", "false", "⟳"),
            ("Scanning files", "false", "⟳"),
            ("Transitioning", "false", "⟳"),
            ("Waiting for rescan", "false", "⟳"),
            ("Halted on conflict", "false", "✗"),
            ("Connecting to endpoint", "false", "…"),
            ("Disconnected", "false", "…"),
            ("Watching", "true", "⏸"),
        ]
        for status, paused, icon in cases:
            with self.subTest(status=status, paused=paused):
                self.assertEqual(
                    self.render([("olympus", status, paused, "/repo")]),
                    f"mut: {icon} olympus\n",
                )

    def test_unknown_main_status_remains_visible(self):
        self.assertEqual(
            self.render([("olympus", "New status", "false", "/repo")]),
            "mut: ? olympus:New status\n",
        )

    def test_worktrees_are_compact_and_unrelated_sessions_are_ignored(self):
        rows = [
            ("olympus", "Watching", "false", "/repo"),
            ("olympus-wt-good", "Watching", "false", "/worktrees/good"),
            ("olympus-wt-paused", "Disconnected", "true", "/worktrees/paused"),
            ("personal", "Halted", "false", "/personal"),
        ]
        self.assertEqual(self.render(rows), "mut: ✓ olympus | wt: 1✓ 1⏸\n")
        calls = self.recorded_calls()
        self.assertEqual(len(calls), 2, calls)
        self.assertEqual(calls[0], ["daemon", "running"])
        self.assertEqual(calls[1][:3], ["sync", "list", "--template"])
        self.assertIn(".Alpha.Path", calls[1][3])

    def test_unhealthy_worktree_names_preserve_spaces_and_overflow_count(self):
        rows = [
            ("olympus-wt-a", "Staging", "false", "/worktrees/branch one"),
            ("olympus-wt-b", "Halted", "false", "/worktrees/修正"),
            ("olympus-wt-c", "Disconnected", "false", "/worktrees/third"),
            ("olympus-wt-d", "Halted", "false", "/worktrees/fourth"),
            ("olympus-wt-e", "New status", "false", "/worktrees/fifth"),
        ]
        self.assertEqual(
            self.render(rows),
            "mut: | wt: 0✓ ⟳ branch one ✗ 修正 … third +2\n",
        )

    def test_empty_or_unavailable_mutagen_is_quiet(self):
        self.assertEqual(self.render(), "")
        self.assertEqual(self.render(daemon_exit=1), "")
        self.assertEqual(self.render(mutagen_installed=False), "")
        calls = self.recorded_calls()
        self.assertEqual(
            [call[:2] for call in calls],
            [["daemon", "running"], ["sync", "list"], ["daemon", "running"]],
        )

    def test_query_failure_cannot_publish_partial_status(self):
        self.assertEqual(
            self.render(
                [("olympus", "Watching", "false", "/repo")],
                list_exit=1,
                expected_exit=1,
            ),
            "",
        )


if __name__ == "__main__":
    unittest.main()
