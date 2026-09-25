"""Exercise timer lifecycle through fake commands; never start a tmux server."""

import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile
import time
import unittest


TIMER = Path(__file__).resolve().parents[1] / "scripts" / "tmux-status-timer.py"

FAKE_TMUX = r'''
import fcntl, json, os, sys

args = sys.argv[1:]
if args[:3] != ['-N', '-S', os.environ['TMUX_TEST_SOCKET']]:
    raise SystemExit('Tests require explicit no-start socket routing: ' + repr(args))
args = args[3:]
output, code = '', 0
with open(os.environ['TMUX_TEST_STATE'], 'r+') as handle:
    fcntl.flock(handle, fcntl.LOCK_EX)
    state = json.load(handle)
    state['calls'].append(args)
    if not state['alive']:
        code = 1
    elif args == ['display-message', '-p', '-F', '#{pid}']:
        output = str(state['pid'])
    elif args[:2] == ['show-options', '-gv'] and len(args) == 3:
        output = state['options'].get(args[2], '')
        code = 0 if args[2] in state['options'] else 1
    elif args[:2] == ['set-option', '-gq'] and len(args) == 4:
        state['options'][args[2]] = args[3]
    elif args[:4] == ['run-shell', '-b', '-d', '60'] and len(args) == 5:
        state['scheduled'].append(args[4])
    else:
        raise SystemExit('Unexpected tmux command: ' + repr(args))
    handle.seek(0)
    json.dump(state, handle)
    handle.truncate()
if output:
    print(output)
sys.exit(code)
'''

FAKE_RENDERER = r'''
import json, os, sys, time
from pathlib import Path
with open(os.environ['TMUX_TEST_RENDER_CALLS'], 'a') as f:
    f.write('render\n')
state = json.loads(Path(os.environ['TMUX_TEST_RENDER_STATE']).read_text())
time.sleep(state.get('sleep', 0))
sys.stdout.write(state['stdout'])
sys.exit(state.get('exit', 0))
'''


class TimerLifecycleTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="tmux-timer-test-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.tmp = self.root / "tmp"
        self.tmp.mkdir()
        self.socket = str(self.root / "socket with spaces")
        self.pid = 43210
        self.state_file = self.root / "tmux.json"
        self.render_state = self.root / "render.json"
        self.render_calls = self.root / "render.calls"
        self.continuum_calls = self.root / "continuum.calls"
        self.tpm_calls = self.root / "tpm.calls"
        self.write_state(
            {
                "alive": True,
                "pid": self.pid,
                "options": {"@continuum-save-interval": "5"},
                "calls": [],
                "scheduled": [],
            }
        )
        self.set_render("mut: ✓ olympus\n")
        self.tmux = self.write_program(self.bin / "tmux", FAKE_TMUX)
        self.renderer = self.write_program(self.root / "render", FAKE_RENDERER)
        self.continuum = self.root / "continuum_save.sh"
        self.continuum.write_text(
            '#!/bin/bash\n'
            'printf "save-check\\n" >> "$TMUX_TEST_CONTINUUM_CALLS"\n'
            'tmux show-options -gv @continuum-save-interval >/dev/null\n'
        )
        self.continuum.chmod(0o755)
        self.tpm = self.root / "tpm"
        self.tpm.write_text(
            '#!/bin/bash\n'
            'printf "load\\n" >> "$TMUX_TEST_TPM_CALLS"\n'
            '/bin/sleep "${TMUX_TEST_TPM_SLEEP:-0}"\n'
            'format="host │ #{@mutagen-status}"\n'
            'if [[ "$TMUX_TEST_INCLUDE_CONTINUUM" == 1 ]]; then\n'
            '  format+=" #(${TMUX_STATUS_CONTINUUM})"\n'
            'fi\n'
            'tmux set-option -gq status-right "$format"\n'
        )
        self.tpm.chmod(0o755)
        self.env = os.environ.copy()
        self.env.pop("TMUX", None)
        self.env.update(
            PATH=str(self.bin) + os.pathsep + "/usr/bin:/bin",
            TMPDIR=str(self.tmp),
            TMUX_STATUS_TMUX=str(self.tmux),
            TMUX_STATUS_RENDERER=str(self.renderer),
            TMUX_STATUS_TPM=str(self.tpm),
            TMUX_STATUS_CONTINUUM=str(self.continuum),
            TMUX_TEST_SOCKET=self.socket,
            TMUX_TEST_STATE=str(self.state_file),
            TMUX_TEST_RENDER_STATE=str(self.render_state),
            TMUX_TEST_RENDER_CALLS=str(self.render_calls),
            TMUX_TEST_CONTINUUM_CALLS=str(self.continuum_calls),
            TMUX_TEST_TPM_CALLS=str(self.tpm_calls),
            TMUX_TEST_INCLUDE_CONTINUUM="1",
        )

    @staticmethod
    def write_program(path, source):
        path.write_text(f"#!{sys.executable}\n" + source)
        path.chmod(0o755)
        return path

    def state(self):
        return json.loads(self.state_file.read_text())

    def write_state(self, state):
        self.state_file.write_text(json.dumps(state))

    def set_option(self, key, value):
        state = self.state()
        state["options"][key] = value
        self.write_state(state)

    def set_render(self, value, *, exit_code=0, sleep=0):
        self.render_state.write_text(
            json.dumps({"stdout": value, "exit": exit_code, "sleep": sleep})
        )

    @staticmethod
    def count_lines(path):
        return len(path.read_text().splitlines()) if path.exists() else 0

    def command(self, action, generation=None):
        args = [sys.executable, str(TIMER), action, self.socket, str(self.pid)]
        if generation is not None:
            args.append(generation)
        return args

    def invoke(self, action, generation=None):
        result = subprocess.run(
            self.command(action, generation),
            env=self.env,
            text=True,
            capture_output=True,
            timeout=8,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def bootstrap(self):
        self.invoke("bootstrap")
        return self.state()["options"]["@status-timer-generation"]

    def make_due(self):
        self.set_option("@status-timer-next-run", "0")

    def test_timer_lease_uses_clock_shared_between_processes(self):
        before = int(time.clock_gettime(time.CLOCK_MONOTONIC))
        self.bootstrap()
        after = int(time.clock_gettime(time.CLOCK_MONOTONIC))
        lease = int(self.state()["options"]["@status-timer-next-run"])
        self.assertGreaterEqual(lease, before + 60)
        self.assertLessEqual(lease, after + 60)

    def test_reloading_plugins_keeps_one_timer_and_removes_redraw_shell_job(self):
        generation = self.bootstrap()
        first = self.state()
        self.assertEqual(self.count_lines(self.render_calls), 1)
        self.assertEqual(self.count_lines(self.continuum_calls), 1)
        for _ in range(3):
            self.invoke("bootstrap")
        state = self.state()
        self.assertEqual(state["options"]["@status-timer-generation"], generation)
        self.assertEqual(len(state["scheduled"]), len(first["scheduled"]))
        self.assertEqual(len(state["scheduled"]), 1)
        self.assertEqual(self.count_lines(self.tpm_calls), 4)
        self.assertEqual(self.count_lines(self.render_calls), 1)
        self.assertEqual(self.count_lines(self.continuum_calls), 1)
        self.assertNotIn("#(", state["options"]["status-right"])
        self.assertIn("#{@mutagen-status}", state["options"]["status-right"])
        self.assertIn(self.socket, shlex.split(state["scheduled"][0]))
        self.assertEqual(state["options"]["@continuum-save-interval"], "5")

    def test_tick_publishes_only_changes_and_delegates_continuum_once(self):
        generation = self.bootstrap()
        self.set_option("@mutagen-status", "mut: ✓ olympus")
        self.make_due()
        before = self.state()
        renders = self.count_lines(self.render_calls)
        continuum = self.count_lines(self.continuum_calls)
        self.invoke("tick", generation)
        after = self.state()
        self.assertEqual(self.count_lines(self.render_calls), renders + 1)
        self.assertEqual(self.count_lines(self.continuum_calls), continuum + 1)
        self.assertEqual(len(after["scheduled"]), len(before["scheduled"]) + 1)
        calls = after["calls"][len(before["calls"]):]
        self.assertFalse(
            any(call[:3] == ["set-option", "-gq", "@mutagen-status"] for call in calls)
        )
        self.set_render("mut: ⟳ olympus\n")
        self.make_due()
        self.invoke("tick", generation)
        self.assertEqual(self.state()["options"]["@mutagen-status"], "mut: ⟳ olympus")

    def test_poll_failure_preserves_last_good_status_and_can_recover(self):
        generation = self.bootstrap()
        self.set_option("@mutagen-status", "last good")
        self.set_render("partial result\n", exit_code=1)
        self.make_due()
        scheduled = len(self.state()["scheduled"])
        self.invoke("tick", generation)
        self.assertEqual(self.state()["options"]["@mutagen-status"], "last good")
        self.assertEqual(len(self.state()["scheduled"]), scheduled + 1)
        self.set_render("")
        self.make_due()
        self.invoke("tick", generation)
        self.assertEqual(self.state()["options"]["@mutagen-status"], "")

    def test_timed_out_poll_keeps_status_and_future_timer(self):
        generation = self.bootstrap()
        self.set_option("@mutagen-status", "last good")
        self.set_render("never publish", sleep=0.5)
        self.env["TMUX_STATUS_POLL_TIMEOUT"] = "0.05"
        self.make_due()
        scheduled = len(self.state()["scheduled"])
        self.invoke("tick", generation)
        self.assertEqual(self.state()["options"]["@mutagen-status"], "last good")
        self.assertEqual(len(self.state()["scheduled"]), scheduled + 1)

    def test_continuum_is_not_enabled_when_plugin_did_not_request_it(self):
        self.env["TMUX_TEST_INCLUDE_CONTINUUM"] = "0"
        generation = self.bootstrap()
        self.make_due()
        self.invoke("tick", generation)
        self.assertEqual(self.count_lines(self.continuum_calls), 0)

    def test_duplicate_or_overlapping_callbacks_poll_only_once(self):
        generation = self.bootstrap()
        self.set_render("mut: ✓ olympus\n", sleep=0.2)
        self.make_due()
        renders = self.count_lines(self.render_calls)
        scheduled = len(self.state()["scheduled"])
        processes = [
            subprocess.Popen(
                self.command("tick", generation),
                env=self.env,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            for _ in range(3)
        ]
        for process in processes:
            stdout, stderr = process.communicate(timeout=8)
            self.assertEqual(process.returncode, 0, stdout + stderr)
        self.invoke("tick", generation)
        self.assertEqual(self.count_lines(self.render_calls), renders + 1)
        self.assertEqual(len(self.state()["scheduled"]), scheduled + 1)

    def test_old_callback_cannot_revive_expired_timer_generation(self):
        old = self.bootstrap()
        self.make_due()
        new = self.bootstrap()
        self.assertNotEqual(old, new)
        before = self.state()
        renders = self.count_lines(self.render_calls)
        self.invoke("tick", old)
        self.assertEqual(self.count_lines(self.render_calls), renders)
        self.assertEqual(self.state()["scheduled"], before["scheduled"])
        self.assertEqual(self.state()["options"], before["options"])

    def test_due_callback_racing_slow_reload_leaves_one_working_timer(self):
        old = self.bootstrap()
        # A recently due lease caught the original bug: reload assumed that its
        # callback was pending, while that callback exited on the reload lock.
        now = int(time.clock_gettime(time.CLOCK_MONOTONIC))
        self.set_option("@status-timer-next-run", str(now - 1))
        renders = self.count_lines(self.render_calls)
        scheduled = len(self.state()["scheduled"])
        self.env["TMUX_TEST_TPM_SLEEP"] = "0.5"
        reload_process = subprocess.Popen(
            self.command("bootstrap"),
            env=self.env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        processes = [reload_process]
        try:
            deadline = time.monotonic() + 3
            while self.count_lines(self.tpm_calls) < 2:
                self.assertLess(time.monotonic(), deadline, "reload did not enter TPM")
                time.sleep(0.01)
            processes.append(
                subprocess.Popen(
                    self.command("tick", old),
                    env=self.env,
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                )
            )
            for process in processes:
                stdout, stderr = process.communicate(timeout=8)
                self.assertEqual(process.returncode, 0, stdout + stderr)
        finally:
            for process in processes:
                if process.poll() is None:
                    process.kill()
                    process.communicate()

        self.assertEqual(self.count_lines(self.render_calls), renders + 1)
        self.assertEqual(len(self.state()["scheduled"]), scheduled + 1)
        self.assertNotIn("#(", self.state()["options"]["status-right"])
        # Execute the resulting chain once more to prove it can keep going.
        current = self.state()["options"]["@status-timer-generation"]
        self.make_due()
        self.invoke("tick", current)
        self.assertEqual(self.count_lines(self.render_calls), renders + 2)
        self.assertEqual(len(self.state()["scheduled"]), scheduled + 2)

    def test_missing_or_replaced_server_cannot_be_created_or_modified(self):
        generation = self.bootstrap()
        for changes in ({"alive": False}, {"alive": True, "pid": self.pid + 1}):
            with self.subTest(changes=changes):
                state = self.state()
                state.update(changes)
                self.write_state(state)
                before = self.state()
                renders = self.count_lines(self.render_calls)
                self.invoke("tick", generation)
                self.assertEqual(self.count_lines(self.render_calls), renders)
                self.assertEqual(self.state()["scheduled"], before["scheduled"])
                self.assertEqual(self.state()["options"], before["options"])


if __name__ == "__main__":
    unittest.main()
