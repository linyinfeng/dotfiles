"""Adapt pi's JSON event stream for the command-not-found agent.

Progress (braille spinner plus one line per tool call) goes to stderr, then the
agent's last assistant message is read as JSON

    {"markdown": "...", "command": "..."}

whose markdown mdcat renders to stderr and whose command is announced and run
with `bash -c`, inheriting stdin/stdout/stderr and the exit status. Either
field may be empty: no markdown prints nothing, no command runs nothing.

Every invocation is logged to
`~/.pi/command-not-found/sessions/<session_id>/history/<time>/` as input,
markdown, command, status, stdout and stderr; the command's output is
tee'd to the terminal while it runs.
"""

import json
import os
import select
import signal
import subprocess
import sys
import time
import unicodedata
from collections import deque
from datetime import datetime, timezone
from typing import IO

FRAMES = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
INTERVAL = 0.1
SUMMARY_KEYS = ("command", "path", "pattern", "query", "url")
FILE_MODE = 0o600
WRITE_FLAGS = os.O_WRONLY | os.O_CREAT | os.O_TRUNC
HOME = os.environ.get("HOME", "")
LOG_ROOT = os.path.join(HOME, ".pi", "command-not-found", "sessions")


def terminate(signum: int, _frame: object) -> None:
    sys.exit(128 + signum)


signal.signal(signal.SIGPIPE, signal.SIG_DFL)
signal.signal(signal.SIGINT, terminate)
signal.signal(signal.SIGTERM, terminate)
signal.signal(signal.SIGHUP, terminate)

is_tty = sys.stderr.isatty()
BOLD, RESET = ("\x1b[1m", "\x1b[0m") if is_tty else ("", "")
raw = os.environ.get("COMMAND_NOT_FOUND_SESSION_ID", "")
session_id = "".join(c if c.isalnum() or c == "-" else "_" for c in raw)
if not session_id:
    session_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%f")
user_input = ""
clouds = 0
drawn = 0
frame = 0
lines: deque[str] = deque(maxlen=5)
texts: list[str] = []
errors: list[str] = []


def width() -> int:
    try:
        columns = os.get_terminal_size(sys.stderr.fileno()).columns
    except OSError:
        return 80
    return columns or 80


def char_width(char: str) -> int:
    if unicodedata.combining(char):
        return 0
    return 2 if unicodedata.east_asian_width(char) in "WF" else 1


def printable(text: str) -> str:
    keep = "\n\t"
    return "".join(char for char in text if char in keep or char.isprintable())


def clip(line: str) -> str:
    limit = max(width() - 1, 1)
    kept = ""
    used = 0
    for char in line:
        size = char_width(char)
        if used + size > limit:
            return kept + "…"
        kept += char
        used += size
    return line


def draw() -> None:
    """Redraw the rolling block: recent tool calls plus the live status."""
    global drawn
    if not is_tty:
        return
    room = max((width() - 2) // 2, 0)
    block = [clip(line) for line in lines]
    block.append("💭" * min(clouds, room) + FRAMES[frame])
    total = max(drawn, len(block))
    out = f"\x1b[{drawn}A" if drawn else ""
    for index in range(total):
        out += "\r\x1b[K" + (block[index] if index < len(block) else "") + "\n"
    sys.stderr.write(out)
    sys.stderr.flush()
    drawn = total


def clear() -> None:
    """Erase the rolling block, leaving the cursor on its first line."""
    global drawn
    if not (is_tty and drawn):
        return
    out = f"\x1b[{drawn}A"
    for _ in range(drawn):
        out += "\r\x1b[K\n"
    out += f"\x1b[{drawn}A"
    sys.stderr.write(out)
    sys.stderr.flush()
    drawn = 0


def log(line: str) -> None:
    lines.append(line)
    if is_tty:
        draw()
    else:
        sys.stderr.write(clip(line) + "\n")
        sys.stderr.flush()


def rule() -> None:
    sys.stderr.write("─" * width() + "\n")
    sys.stderr.flush()


def write(path: str, content: str) -> None:
    try:
        fd = os.open(path, WRITE_FLAGS, FILE_MODE)
    except OSError:
        return
    with os.fdopen(fd, "w", encoding="utf-8") as sink:
        sink.write(content)


def start_log(markdown: str, command: str) -> str | None:
    """Create the per-invocation log directory and write the static files."""
    if not HOME:
        return None
    now = datetime.now(timezone.utc)
    stamp = now.strftime("%Y-%m-%dT%H-%M-%S-%f")[:-3] + "Z"
    session_dir = os.path.join(LOG_ROOT, session_id)
    directory = os.path.join(session_dir, "history", stamp)
    try:
        os.makedirs(directory, mode=0o700, exist_ok=True)
    except OSError:
        return None
    for path in (session_dir, directory):
        try:
            os.chmod(path, 0o700)
        except OSError:
            pass
    for name, content in (
        ("input", user_input),
        ("markdown", markdown),
        ("command", command),
        ("stdout", ""),
        ("stderr", ""),
        ("status", ""),
    ):
        write(os.path.join(directory, name), content)
    return directory


def finish_log(directory: str | None, status: int) -> None:
    if directory:
        write(os.path.join(directory, "status"), f"{status}\n")


def open_log(path: str) -> IO[bytes] | None:
    """Open a log file for writing, owner-only."""
    try:
        return os.fdopen(os.open(path, WRITE_FLAGS, FILE_MODE), "wb")
    except OSError:
        return None


def run_logged(directory: str | None, command: str) -> int:
    """Run the command, teeing its output to the terminal and the log."""
    out_log = err_log = None
    if directory:
        out_log = open_log(os.path.join(directory, "stdout"))
        err_log = open_log(os.path.join(directory, "stderr"))
    process = None
    interrupts = 0

    def on_interrupt(*_: object) -> None:
        nonlocal interrupts
        interrupts += 1
        if interrupts > 1 and process is not None:
            process.kill()

    previous = signal.signal(signal.SIGINT, on_interrupt)
    try:
        process = subprocess.Popen(
            ["bash", "-c", command],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        streams = {
            process.stdout: (sys.stdout.buffer, out_log),
            process.stderr: (sys.stderr.buffer, err_log),
        }
        deadline = None
        while streams:
            ready, _, _ = select.select(list(streams), [], [], 1.0)
            if not ready:
                if process.poll() is not None:
                    deadline = deadline or time.monotonic() + 0.5
                    if time.monotonic() > deadline:
                        break
                continue
            for stream in ready:
                chunk = stream.read1(65536)
                terminal, sink = streams[stream]
                if not chunk:
                    del streams[stream]
                    continue
                terminal.write(chunk)
                terminal.flush()
                if sink is None:
                    continue
                try:
                    sink.write(chunk)
                    sink.flush()
                except OSError:
                    streams[stream] = (terminal, None)
        status = process.wait()
    except BaseException:
        if process is not None:
            process.kill()
            process.wait()
        raise
    finally:
        signal.signal(signal.SIGINT, previous)
        for handle in (out_log, err_log):
            if handle is not None:
                try:
                    handle.close()
                except OSError:
                    pass
    if status < 0:
        status = 128 + abs(status)
    finish_log(directory, status)
    return status


def show_markdown(text: str) -> None:
    if not text.strip():
        return
    clear()
    command = ["mdcat", "--columns", str(max(width(), 20))]
    if not is_tty:
        command.append("--no-colour")
    previous = signal.signal(signal.SIGPIPE, signal.SIG_IGN)
    try:
        done = subprocess.run(
            command,
            input=text,
            encoding="utf-8",
            stdout=sys.stderr,
            check=False,
        )
    except (OSError, UnicodeError):
        done = None
    finally:
        signal.signal(signal.SIGPIPE, previous)
    if done is None or done.returncode != 0:
        sys.stderr.write(f"{printable(text).rstrip()}\n")


def summarize(args: object) -> str:
    if not isinstance(args, dict):
        return ""
    for key in SUMMARY_KEYS:
        value = args.get(key)
        if isinstance(value, str) and value.strip():
            return printable(" ".join(value.split()))
    return ""


def parse_answer(text: str) -> dict | None:
    """Return the last JSON object in the message that has our two fields."""
    decoder = json.JSONDecoder()
    found = None
    index = text.find("{")
    while index != -1:
        try:
            data, _ = decoder.raw_decode(text, index)
        except (json.JSONDecodeError, RecursionError):
            data = None
        keys = ("markdown", "command")
        if isinstance(data, dict) and any(key in data for key in keys):
            markdown = data.get("markdown", "")
            command = data.get("command", "")
            if all(isinstance(value, str) for value in (markdown, command)):
                found = data
        index = text.find("{", index + 1)
    return found


def feed(line: bytes) -> None:
    try:
        event = json.loads(line)
    except (json.JSONDecodeError, UnicodeDecodeError, RecursionError):
        return
    if isinstance(event, dict):
        handle(event)


def handle(event: dict) -> None:
    global clouds, user_input
    kind = event.get("type")
    if kind == "message_end":
        message = event.get("message")
        if not isinstance(message, dict):
            return
        content = message.get("content")
        text = "".join(
            part.get("text", "")
            for part in content or []
            if isinstance(part, dict) and part.get("type") == "text"
        )
        if message.get("role") == "assistant":
            if text.strip():
                texts.append(text)
            error = message.get("errorMessage")
            if isinstance(error, str) and error.strip():
                errors.append(printable(error).replace("\n", " "))
        elif message.get("role") == "user" and not user_input and text:
            try:
                payload = json.loads(text)
            except (json.JSONDecodeError, UnicodeDecodeError):
                payload = None
            value = payload.get("input") if isinstance(payload, dict) else None
            user_input = value if isinstance(value, str) else text.strip()
        return

    if kind == "tool_execution_start":
        clouds = 0
        label = f"🔧{event.get('toolName', '?')}"
        summary = summarize(event.get("args"))
        if summary:
            label += f": {summary}"
        log(label)
        return

    if kind == "message_update":
        delta = event.get("assistantMessageEvent") or {}
        if delta.get("type") == "thinking_start":
            clouds += 1
            draw()


try:
    buffered = bytearray()
    last = 0.0
    while True:
        ready, _, _ = select.select([0], [], [], INTERVAL)
        now = time.monotonic()
        if now - last >= INTERVAL:
            last = now
            frame = (frame + 1) % len(FRAMES)
            draw()
        if not ready:
            continue
        chunk = os.read(0, 65536)
        if not chunk:
            feed(buffered)
            break
        buffered += chunk
        while True:
            index = buffered.find(b"\n")
            if index == -1:
                break
            cut = index + 1
            feed(buffered[:index])
            del buffered[:cut]
finally:
    clear()

answer = None
for text in reversed(texts):
    answer = parse_answer(text)
    if answer is not None:
        break

if answer is None:
    hint = '{"markdown", "command"}'
    reason = f": {errors[-1]}" if errors else ""
    directory = start_log(texts[-1] if texts else "", "")
    if directory and errors:
        write(os.path.join(directory, "stderr"), "\n".join(errors) + "\n")
    finish_log(directory, 1)
    if texts:
        show_markdown(texts[-1])
        sys.stderr.write(
            f"command-not-found: pi did not return the expected {hint} JSON"
            f"{reason} — run the command again to retry.\n"
        )
    else:
        sys.stderr.write(f"command-not-found: pi gave no answer{reason}\n")
    sys.exit(1)

markdown = answer.get("markdown", "")
command = answer.get("command", "")
show_markdown(markdown)
directory = start_log(markdown, command)
if not command.strip():
    finish_log(directory, 0)
    sys.exit(0)

clear()
if markdown.strip():
    sys.stderr.write("\n")
shown = printable(command).replace("\n", "⏎").replace("\t", " ")
if is_tty:
    sys.stderr.write(f"⚡ {BOLD}{shown}{RESET}\n")
else:
    sys.stderr.write(f"⚡ {shown}\n")
rule()
sys.stdout.flush()
try:
    tty_fd = os.open("/dev/tty", os.O_RDONLY)
except OSError:
    pass
else:
    os.dup2(tty_fd, 0)
    os.close(tty_fd)
sys.exit(run_logged(directory, command))
