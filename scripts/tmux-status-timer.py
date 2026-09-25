#!/usr/bin/python3
"""Refresh tmux integrations on one server timer, never during status drawing."""

import argparse
import fcntl
import hashlib
import os
from pathlib import Path
import shlex
import shutil
import signal
import subprocess
import sys
import time
import uuid


INTERVAL = 60
TMUX_TIMEOUT = 5
GENERATION = "@status-timer-generation"
NEXT_RUN = "@status-timer-next-run"
CONTINUUM = "@status-timer-continuum"
STATUS = "@mutagen-status"
ERROR = "@status-timer-error"


def host_monotonic():
    # Python < 3.10 on macOS offsets time.monotonic() separately per process.
    # Timer leases cross process boundaries, so read the host clock directly.
    return time.clock_gettime(time.CLOCK_MONOTONIC)

# Keep unmodified plugin scripts on this existing server, including their child
# scripts. This function exists only in the plugin subprocess environment.
PLUGIN_RUNNER = r'''
tmux() {
    command "$TMUX_STATUS_TMUX" -N -S "$TMUX_STATUS_SOCKET" "$@"
}
export -f tmux
exec /bin/bash "$1"
'''


class Maintenance:
    def __init__(self, socket, server_pid):
        self.socket = socket
        self.server_pid = str(server_pid)
        self.script = str(Path(__file__).resolve())
        self.tmux = os.environ.get("TMUX_STATUS_TMUX") or shutil.which("tmux")
        if not self.tmux:
            raise RuntimeError("tmux client unavailable")
        self.renderer = os.environ.get(
            "TMUX_STATUS_RENDERER",
            str(Path(self.script).with_name("tmux-mutagen-status.sh")),
        )
        self.tpm = os.environ.get(
            "TMUX_STATUS_TPM", str(Path.home() / ".tmux/plugins/tpm/tpm")
        )
        self.continuum = os.environ.get(
            "TMUX_STATUS_CONTINUUM",
            str(Path.home() / ".tmux/plugins/tmux-continuum/scripts/continuum_save.sh"),
        )
        self.poll_timeout = float(os.environ.get("TMUX_STATUS_POLL_TIMEOUT", "10"))
        if not 0 < self.poll_timeout <= 30:
            raise ValueError("poll timeout must be greater than zero and at most 30 seconds")
        self.env = os.environ.copy()
        self.env.update(
            TMUX=f"{socket},{server_pid},0",
            TMUX_STATUS_TMUX=self.tmux,
            TMUX_STATUS_SOCKET=socket,
        )

    def command(self, *args, check=True):
        return subprocess.run(
            [self.tmux, "-N", "-S", self.socket, *args],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=TMUX_TIMEOUT,
            check=check,
            env=self.env,
        )

    def existing_server(self):
        result = self.command("display-message", "-p", "-F", "#{pid}", check=False)
        return result.returncode == 0 and result.stdout.strip() == self.server_pid

    def option(self, name):
        result = self.command("show-options", "-gv", name, check=False)
        return result.stdout.rstrip("\n") if result.returncode == 0 else ""

    def publish(self, name, value):
        if self.option(name) != value:
            self.command("set-option", "-gq", name, value)

    def plugin(self, script, timeout=None):
        # TPM retains its own asynchronous restore behavior. In particular, do
        # not kill its process group: it can contain a legitimate restore/save.
        subprocess.run(
            ["/bin/bash", "-c", PLUGIN_RUNNER, "tmux-status-plugin", script],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=True,
            timeout=timeout,
            env=self.env,
        )

    def schedule(self, generation):
        callback = shlex.join(
            [sys.executable, self.script, "tick", self.socket, self.server_pid, generation]
        )
        self.command("run-shell", "-b", "-d", str(INTERVAL), callback)
        # This lease is local to the server's host. Wall-clock corrections must
        # not make an already scheduled callback appear to be too early.
        self.command("set-option", "-gq", NEXT_RUN, str(int(host_monotonic()) + INTERVAL))

    def render(self):
        # A stuck renderer must not leave Mutagen grandchildren alive or block
        # future ticks. This process group contains only our own read-only poll.
        child = subprocess.Popen(
            [self.renderer],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            start_new_session=True,
            env=self.env,
        )
        try:
            output, _ = child.communicate(timeout=self.poll_timeout)
        except subprocess.TimeoutExpired:
            os.killpg(child.pid, signal.SIGKILL)
            child.communicate()
            raise
        if child.returncode:
            raise subprocess.CalledProcessError(child.returncode, self.renderer)
        return output.rstrip("\n")

    def refresh(self):
        errors = []
        try:
            self.publish(STATUS, self.render())
        except (OSError, subprocess.SubprocessError) as error:
            errors.append("Mutagen status: " + type(error).__name__)
        if self.option(CONTINUUM) == "1":
            try:
                self.plugin(self.continuum, timeout=20)
            except (OSError, subprocess.SubprocessError) as error:
                errors.append("Continuum: " + type(error).__name__)
        self.publish(ERROR, "; ".join(errors))

    def next_run(self):
        try:
            return int(self.option(NEXT_RUN))
        except ValueError:
            return 0

    def bootstrap(self):
        # TPM executes its plugins synchronously, apart from Continuum's
        # intentional background restore. Initialize only after plugin setup.
        self.plugin(self.tpm, timeout=20)
        if not self.existing_server():
            return
        right = self.option("status-right")
        save_hook = f"#({self.continuum})"
        # The injected hook is Continuum's decision that this server may save.
        # Calling its save script unconditionally would bypass its multi-server
        # protection, which lives in plugin initialization rather than save.sh.
        self.publish(CONTINUUM, "1" if save_hook in right else "0")
        right = right.replace(save_hook, "")
        for path in (
            "~/dotfiles/scripts/tmux-mutagen-status.sh",
            str(Path.home() / "dotfiles/scripts/tmux-mutagen-status.sh"),
            self.renderer,
        ):
            right = right.replace(f"#({path})", "#{@mutagen-status}")
        self.publish("status-right", right)
        generation = self.option(GENERATION)
        now = int(host_monotonic())
        if generation and now + 1 < self.next_run() <= now + INTERVAL + 5:
            return
        generation = uuid.uuid4().hex
        self.command("set-option", "-gq", GENERATION, generation)
        self.schedule(generation)
        self.refresh()

    def tick(self, generation):
        if self.option(GENERATION) != generation:
            return
        # A delayed duplicate callback must not create a second timer chain.
        if self.next_run() > int(host_monotonic()) + 1:
            return
        # Install the successor first so a failed poll does not stop updates.
        self.schedule(generation)
        self.refresh()

    def run(self, action, generation):
        if not self.existing_server():
            return
        root = Path(os.environ.get("TMPDIR", "/tmp")) / f"tmux-status-timer-{os.getuid()}"
        root.mkdir(mode=0o700, parents=True, exist_ok=True)
        identity = hashlib.sha256(self.socket.encode()).hexdigest()[:20]
        lock_path = root / f"{identity}-{self.server_pid}.lock"
        with lock_path.open("a") as lock:
            deadline = time.monotonic() + 45
            while True:
                try:
                    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    break
                except BlockingIOError:
                    # A due callback may race a config reload. Wait for it to
                    # finish, then recheck the lease rather than lose the only
                    # callback or create another timer chain.
                    if time.monotonic() >= deadline:
                        return
                    time.sleep(0.05)
            # Socket reuse while waiting must never target a replacement server.
            if not self.existing_server():
                return
            if action == "bootstrap":
                self.bootstrap()
            else:
                self.tick(generation)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("bootstrap", "tick"))
    parser.add_argument("socket")
    parser.add_argument("server_pid", type=int)
    parser.add_argument("generation", nargs="?")
    args = parser.parse_args()
    if args.action == "tick" and not args.generation:
        parser.error("tick requires a generation")
    os.umask(0o077)
    try:
        Maintenance(args.socket, args.server_pid).run(args.action, args.generation)
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError):
        # A background run-shell error opens tmux copy mode in a user's pane.
        # Keep failures quiet; a reload repairs an expired timer lease.
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
