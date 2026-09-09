"""Adapt pi's JSON event stream for the command-not-found agent.

Progress (braille spinner plus one line per tool call) goes to stderr, then the
agent's last assistant message is read as JSON

    {"markdown": "...", "command": "..."}

whose markdown mdcat renders to stderr and whose command is announced and run
with `bash -c`, inheriting stdout/stderr and the exit status. Either field may
be empty: no markdown prints nothing, no command runs nothing.
"""

import json
import os
import select
import signal
import subprocess
import sys
import time
import unicodedata

FRAMES = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
INTERVAL = 0.1
SUMMARY_KEYS = ("command", "path", "pattern", "query", "url")


def terminate(signum: int, _frame: object) -> None:
    sys.exit(128 + signum)


signal.signal(signal.SIGPIPE, signal.SIG_DFL)
signal.signal(signal.SIGINT, terminate)
signal.signal(signal.SIGTERM, terminate)
signal.signal(signal.SIGHUP, terminate)

is_tty = sys.stderr.isatty()
BOLD, RESET = ("\x1b[1m", "\x1b[0m") if is_tty else ("", "")
clouds = 0
line_open = False
frame = 0
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


def render() -> None:
    """Redraw the live status line: accumulated clouds plus the spinner."""
    global line_open
    if not is_tty:
        return
    room = max((width() - 2) // 2, 0)
    sys.stderr.write("\r\x1b[K" + "💭" * min(clouds, room) + FRAMES[frame])
    sys.stderr.flush()
    line_open = True


def clear() -> None:
    global line_open
    if line_open:
        sys.stderr.write("\r\x1b[K")
        sys.stderr.flush()
        line_open = False


def log(line: str) -> None:
    clear()
    sys.stderr.write(clip(line) + "\n")
    sys.stderr.flush()
    render()


def rule() -> None:
    sys.stderr.write("─" * width() + "\n")
    sys.stderr.flush()


def show_markdown(text: str) -> bool:
    if not text.strip():
        return False
    clear()
    rule()
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
    return True


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
    global clouds
    kind = event.get("type")
    if kind == "message_end":
        message = event.get("message")
        if not isinstance(message, dict) or message.get("role") != "assistant":
            return
        content = message.get("content")
        text = "".join(
            part.get("text", "")
            for part in content or []
            if isinstance(part, dict) and part.get("type") == "text"
        )
        if text.strip():
            texts.append(text)
        error = message.get("errorMessage")
        if isinstance(error, str) and error.strip():
            errors.append(printable(error).replace("\n", " "))
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
            render()


try:
    buffered = bytearray()
    last = 0.0
    while True:
        ready, _, _ = select.select([0], [], [], INTERVAL)
        now = time.monotonic()
        if now - last >= INTERVAL:
            last = now
            frame = (frame + 1) % len(FRAMES)
            render()
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
    if texts:
        show_markdown(texts[-1])
        sys.stderr.write(
            f"command-not-found: pi did not return the expected {hint} JSON"
            f"{reason} — run the command again to retry.\n"
        )
    else:
        sys.stderr.write(f"command-not-found: pi gave no answer{reason}\n")
    sys.exit(1)

shown_markdown = show_markdown(answer.get("markdown", ""))
command = answer.get("command", "")
if not command.strip():
    sys.exit(0)

clear()
if shown_markdown:
    sys.stderr.write("\n")
shown = printable(command).replace("\n", "⏎")
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
try:
    os.execvp("bash", ["bash", "-c", command])
except (OSError, ValueError) as error:
    sys.stderr.write(f"command-not-found: {error}\n")
    sys.exit(127)
