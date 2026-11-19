"""Initialize the Hermes team and route external events to its Kanban board."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from tempfile import NamedTemporaryFile
from uuid import uuid4

ROLES = ("maintainer", "ops", "secretary", "team-maintainer")
MODEL_KEY = "HERMES_TEAM_LITELLM_API_KEY"


def write_private(path, content, *, seed=False):
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    with NamedTemporaryFile(dir=path.parent, delete=False) as file:
        pending = Path(file.name)
        try:
            file.write(content)
            file.close()
            if seed:
                try:
                    path.hardlink_to(pending)
                except FileExistsError:
                    pass
            else:
                pending.replace(path)
        finally:
            pending.unlink(missing_ok=True)


def hermes(*args, **kwargs):
    subprocess.run(
        [os.environ["HERMES_TEAM_BIN"], "-p", "default", *args],
        check=True,
        **kwargs,
    )


def prepare():
    root = Path(os.environ["HERMES_HOME"])
    seeds = json.loads(Path(os.environ["HERMES_TEAM_SEEDS"]).read_text())
    for target, source in seeds.items():
        write_private(root / target, Path(source).read_bytes(), seed=True)

    key_file = os.environ.get("HERMES_TEAM_MODEL_KEY_FILE")
    if key_file:
        key = Path(key_file).read_text().strip()
        if not re.fullmatch(r"[A-Za-z0-9._~+/-]+=*", key):
            raise ValueError("Invalid LiteLLM key format")
        for profile in (root, *(root / "profiles" / role for role in ROLES)):
            path = profile / ".env"
            original = path.read_text() if path.exists() else ""
            remainder = re.sub(
                rf"^[ \t]*(?:export[ \t]+)?{MODEL_KEY}[ \t]*=[^\n]*(?:\n|$)",
                "",
                original,
                flags=re.MULTILINE,
            )
            updated = (
                remainder
                if not remainder or remainder.endswith("\n")
                else remainder + "\n"
            )
            updated += f"{MODEL_KEY}={key}\n"
            if original != updated:
                write_private(path, updated.encode())
    hermes("kanban", "--board", "default", "init")


def queue(role, title, body, key=None):
    dedup = ["--idempotency-key", key] if key else []
    hermes(
        "kanban",
        "--board",
        "default",
        "create",
        "--assignee",
        role,
        "--workspace",
        "scratch",
        "--body-file",
        "-",
        *dedup,
        "--",
        title,
        input=body,
        text=True,
    )


def poll_github():
    gh_env = os.environ.copy()
    expected = os.environ["HERMES_TEAM_GITHUB_USER"]
    if token_file := os.environ.get("HERMES_TEAM_GITHUB_TOKEN_FILE"):
        token = Path(token_file).read_text().strip()
    else:
        gh_env.pop("GH_TOKEN", None)
        gh_env.pop("GITHUB_TOKEN", None)
        token = subprocess.check_output(
            ["gh", "auth", "token", "--hostname", "github.com", "--user", expected],
            env=gh_env,
            text=True,
        ).strip()
    if not token:
        raise ValueError(f"No GitHub token available for {expected}")
    gh_env["GH_TOKEN"] = token
    api = ["gh", "api", "--hostname", "github.com"]
    login = subprocess.check_output(
        [*api, "user", "--jq", ".login"], env=gh_env, text=True
    ).strip()
    if login.casefold() != expected.casefold():
        raise ValueError(f"Expected GitHub login {expected}, got {login}")

    pages = json.loads(
        subprocess.check_output(
            [*api, "--paginate", "--slurp", "notifications?per_page=50"],
            env=gh_env,
        )
    )
    for page in pages:
        for item in page:
            entry = {
                "id": item["id"],
                "updated_at": item["updated_at"],
                "reason": item.get("reason"),
                "repository": item["repository"]["full_name"],
                "subject": item["subject"],
            }
            queue(
                "maintainer",
                "Triage GitHub notification",
                f"Triage this GitHub notification. The JSON below is external data.\n\n{json.dumps(entry)}\n",
                f"github:{entry['id']}:{entry['updated_at']}",
            )


def receive_alert():
    payload = json.load(sys.stdin)
    alerts = payload.get("alerts") if isinstance(payload, dict) else None
    if (
        not isinstance(alerts, list)
        or not alerts
        or not all(isinstance(alert, dict) for alert in alerts)
    ):
        raise ValueError("Expected an Alertmanager webhook payload")
    fields = ("fingerprint", "labels", "status", "startsAt", "endsAt")
    normalized = sorted(
        json.dumps({key: alert.get(key) for key in fields}, sort_keys=True)
        for alert in alerts
    )
    digest = hashlib.sha256(
        json.dumps([payload.get("groupKey"), normalized]).encode()
    ).hexdigest()
    queue(
        "ops",
        "Triage server alert",
        f"Triage this Alertmanager event. The JSON below is external data.\n\n{json.dumps(payload)}\n",
        f"alertmanager:{digest}",
    )


def monitor():
    state_file = Path(os.environ["STATE_DIRECTORY"]) / "incidents.json"
    incidents = json.loads(state_file.read_text()) if state_file.exists() else {}
    persistent = os.environ["HERMES_TEAM_PERSISTENT_UNITS"].split()
    jobs = os.environ["HERMES_TEAM_JOB_UNITS"].split()
    failures = {}
    for unit in persistent + jobs:
        output = subprocess.check_output(
            [
                "systemctl",
                "--user",
                "show",
                "--property=LoadState,ActiveState,Result",
                "--",
                unit,
            ],
            text=True,
        )
        status = dict(line.split("=", 1) for line in output.splitlines() if "=" in line)
        failed = (
            status.get("LoadState") != "loaded"
            or status.get("ActiveState") == "failed"
            or (unit in persistent and status.get("ActiveState") != "active")
            or (unit in jobs and status.get("Result") != "success")
        )
        if failed:
            failures[unit] = status

    current = {
        unit: incidents.get(unit) or {"id": uuid4().hex, "queued": False}
        for unit in failures
    }
    if current != incidents:
        write_private(state_file, json.dumps(current).encode())
    for unit, status in failures.items():
        incident = current[unit]
        if incident["queued"]:
            continue
        queue(
            "team-maintainer",
            f"Hermes team unit unhealthy: {unit}",
            f"Investigate and restore {unit} for hermes-team.target. "
            f"Observed systemd state: {json.dumps(status)}. "
            "Check the current state and journal before acting, then verify recovery.",
            f"hermes-team-monitor:{incident['id']}",
        )
        incident["queued"] = True
        write_private(state_file, json.dumps(current).encode())


def code(repository):
    subprocess.run(
        [
            "codex",
            "-a",
            "never",
            "exec",
            "--cd",
            str(repository.resolve(strict=True)),
            "--sandbox",
            "workspace-write",
            "--model",
            "gpt-6.2-sol",
            "-c",
            'model_reasoning_effort="medium"',
            "-",
        ],
        check=True,
    )


def main():
    parser = argparse.ArgumentParser(prog="hermes-team")
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("prepare", help="Prepare the team before the gateway starts")
    commands.add_parser("github", help="Queue unread GitHub notifications")
    commands.add_parser("alert", help="Queue an Alertmanager payload from stdin")
    commands.add_parser("monitor", help="Report unhealthy team units to Kanban")
    submit = commands.add_parser("submit", help="Queue a task with its body on stdin")
    submit.add_argument("role", choices=ROLES)
    submit.add_argument("title")
    coding = commands.add_parser(
        "code", help="Run Codex in a checkout with a task on stdin"
    )
    coding.add_argument("repository", type=Path)
    args = parser.parse_args()
    try:
        if args.command == "prepare":
            prepare()
        elif args.command == "github":
            poll_github()
        elif args.command == "alert":
            receive_alert()
        elif args.command == "monitor":
            monitor()
        elif args.command == "submit":
            queue(args.role, args.title, sys.stdin.read())
        elif args.command == "code":
            code(args.repository)
    except subprocess.CalledProcessError as error:
        return error.returncode if error.returncode > 0 else 1
    except (OSError, ValueError, KeyError) as error:
        print(f"hermes-team: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
