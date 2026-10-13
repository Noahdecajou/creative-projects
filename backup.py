"""Copy approved text/code files only, then verify and push the private repository."""
import collections
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
import msvcrt

ROOT = Path(__file__).resolve().parent
LOCAL = ROOT / ".local"
REMOTE = "https://github.com/Noahdecajou/creative-projects.git"
REPO = "Noahdecajou/creative-projects"
GIT = r"C:\Users\notti\AppData\Local\hermes\git\cmd\git.exe"
GH = r"C:\Program Files\GitHub CLI\gh.exe"
CODE = {".txt", ".md", ".json", ".html", ".htm", ".css", ".js", ".mjs", ".cjs",
        ".ts", ".tsx", ".jsx", ".py", ".ps1", ".cmd", ".bat", ".toml", ".yml",
        ".yaml", ".ini", ".xml", ".csv", ".tsv", ".tex", ".sh", ".sql"}
BLOCK_DIRS = {".git", ".codex", ".agents", ".local", "node_modules", "__pycache__",
              "work", "tmp", "temp", "cache", ".cache", "logs", "sessions", "memories"}
BLOCK_NAME = re.compile(r"(?:^|[-_. ])(?:conversation|conversations|chat-export|chat-history|rollout|session|sessions|credentials|secrets|cookies|auth)(?:$|[-_. ])", re.I)
SECRET = re.compile(r"sk-[A-Za-z0-9_-]{24,}|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----")
EMBEDDED = re.compile(r"data:(?:image|audio|video)/[^;\\s]+;base64,", re.I)
CONTROLS = {"sources.json", ".gitignore", ".gitattributes", "README.md", "AGENTS.md",
            "Backup.ps1", "Watch-Launch.ps1", "Install-Automation.ps1", "backup.py", "manifest.json"}
MAX_TEXT = 2 * 1024 * 1024

def command(args, timeout=180):
    result = subprocess.run(args, cwd=ROOT, capture_output=True, text=True,
                            encoding="utf-8", errors="replace", timeout=timeout)
    if result.returncode:
        raise RuntimeError("Command failed: " + " ".join(args[:3]) + "\n" + result.stderr[-1800:])
    return result.stdout.strip()

def git(*args):
    return command([GIT, *args])

def stable_read(path):
    for attempt in range(3):
        before = path.stat()
        raw = path.read_bytes()
        after = path.stat()
        if (before.st_size, before.st_mtime_ns) == (after.st_size, after.st_mtime_ns):
            return raw
        time.sleep(0.3)
    raise RuntimeError("Source currently changing: " + str(path))

def checked_target(relative):
    target = ROOT / relative
    if target.is_symlink() or ROOT not in target.resolve().parents:
        raise RuntimeError("Unsafe destination: " + relative)
    return target

def collect():
    entries = {}
    stats = []
    for project in json.loads((ROOT / "sources.json").read_text(encoding="utf-8-sig")):
        source = Path(project["source"])
        dest = project["destination"]
        if not source.is_dir() or source.is_symlink():
            raise RuntimeError("Source missing or linked: " + str(source))
        if not dest.startswith("projects/") or ".." in Path(dest).parts:
            raise RuntimeError("Invalid project destination")
        approved = None
        if project.get("allowlist"):
            approved = set(json.loads((source / project["allowlist"]).read_text(encoding="utf-8-sig")))
        counts = collections.Counter()
        for directory, dirs, files in os.walk(source, followlinks=False):
            dirs[:] = sorted(d for d in dirs if d.lower() not in BLOCK_DIRS
                             and not (Path(directory) / d).is_symlink())
            for name in sorted(files):
                path = Path(directory) / name
                rel = path.relative_to(source).as_posix()
                if path.is_symlink():
                    counts["linked"] += 1
                    continue
                if approved is not None and rel not in approved:
                    counts["outside_studio_allowlist"] += 1
                    continue
                if name.lower().startswith(".env") or BLOCK_NAME.search(name):
                    counts["private_or_runtime"] += 1
                    continue
                if path.suffix.lower() not in CODE and name not in {".gitignore", ".gitattributes"}:
                    counts["media_or_binary"] += 1
                    continue
                if path.stat().st_size > MAX_TEXT:
                    counts["large_or_embedded_asset"] += 1
                    continue
                raw = stable_read(path)
                try:
                    text = raw.decode("utf-8-sig")
                except UnicodeDecodeError:
                    try:
                        text = raw.decode("utf-16") if raw[:2] in (b"\\xff\\xfe", b"\\xfe\\xff") else raw.decode("cp1252")
                    except UnicodeDecodeError:
                        counts["non_text"] += 1
                        continue
                if "\0" in text:
                    counts["non_text"] += 1
                    continue
                if EMBEDDED.search(text):
                    counts["large_or_embedded_asset"] += 1
                    continue
                if SECRET.search(text):
                    raise RuntimeError("Potential credential in source; not uploaded: " + str(path))
                entries[dest + "/" + rel] = raw
                counts["included"] += 1
        entries[dest + "/PROJECT.md"] = (
            "# " + project["name"] + "\n\n"
            "Sauvegarde du code, des prompts et des workflows uniquement.\n"
            "Les medias et conversations ne sont pas sauvegardes.\n"
        ).encode("utf-8")
        stats.append({"project": project["name"], "destination": dest,
                      "counts": dict(sorted(counts.items()))})
    manifest = {"schema": 1, "scope": "code-prompts-workflows-only", "projects": stats,
                "files": [{"path": p, "bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest()}
                          for p, raw in sorted(entries.items())]}
    return entries, manifest

def save_status(body):
    body["time_utc"] = datetime.now(timezone.utc).isoformat()
    (LOCAL / "last-status.json").write_text(json.dumps(body, indent=2), encoding="utf-8")

def run():
    metadata = json.loads(command([GH, "api", "repos/" + REPO]))
    if metadata.get("private") is not True:
        raise RuntimeError("Remote repository must remain private")
    if git("remote", "get-url", "origin") != REMOTE:
        raise RuntimeError("Unapproved remote")
    if git("branch", "--show-current") != "main":
        raise RuntimeError("Unexpected branch")
    tracked = git("ls-files").splitlines()
    for name in tracked:
        if name not in CONTROLS and not name.startswith("projects/"):
            raise RuntimeError("Tracked file outside approved scope: " + name)
    heads = git("ls-remote", "--heads", "origin", "main")
    if heads:
        git("fetch", "origin", "main")
        if not subprocess.run([GIT, "rev-parse", "--verify", "HEAD"], cwd=ROOT,
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode:
            git("merge", "--ff-only", "origin/main")
        else:
            git("reset", "--mixed", "origin/main")
    entries, manifest = collect()
    for name, raw in entries.items():
        target = checked_target(name)
        target.parent.mkdir(parents=True, exist_ok=True)
        if not target.exists() or target.read_bytes() != raw:
            target.write_bytes(raw)
    for name in tracked:
        if name.startswith("projects/") and name not in entries:
            target = checked_target(name)
            if target.exists():
                target.unlink()
    (ROOT / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    paths = sorted(CONTROLS)
    git("add", "--", *paths, "projects")
    staged = git("diff", "--cached", "--name-only").splitlines()
    for name in staged:
        if name not in CONTROLS and name not in entries and name not in tracked:
            raise RuntimeError("Unapproved staged file: " + name)
    staged_secrets = SECRET.search(git("diff", "--cached", "--", *[p for p in CONTROLS if p != "backup.py"]))
    if staged_secrets:
        raise RuntimeError("Potential credential in backup configuration")
    # Preserve original project text, including legacy whitespace.
    git("diff", "--cached", "--check", "--", *sorted(CONTROLS))
    changed = bool(staged)
    if changed:
        git("commit", "-m", "Backup des projets — " + datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC"))
    git("push", "-u", "origin", "main")
    head = git("rev-parse", "HEAD")
    remote_head = git("ls-remote", "origin", "refs/heads/main").split()[0]
    if head != remote_head:
        raise RuntimeError("Remote verification failed")
    save_status({"success": True, "changed": changed, "commit": head,
                 "source_files": len(entries), "projects": len(manifest["projects"])})
    print(json.dumps({"success": True, "changed": changed, "commit": head,
                      "files": len(entries), "projects": len(manifest["projects"])}))

def main():
    LOCAL.mkdir(exist_ok=True)
    with (LOCAL / "backup.lock").open("a+b") as lock:
        lock.seek(0)
        if not lock.read(1):
            lock.write(b"0")
            lock.flush()
        lock.seek(0)
        try:
            msvcrt.locking(lock.fileno(), msvcrt.LK_NBLCK, 1)
        except OSError:
            print("Another backup is running.")
            return 0
        try:
            run()
            return 0
        except Exception as error:
            message = str(error)
            save_status({"success": False, "error": message})
            with (LOCAL / "backup.log").open("a", encoding="utf-8") as log:
                log.write(datetime.now(timezone.utc).isoformat() + " " + message + "\n")
            print(message, file=sys.stderr)
            return 1
        finally:
            lock.seek(0)
            msvcrt.locking(lock.fileno(), msvcrt.LK_UNLCK, 1)

if __name__ == "__main__":
    sys.exit(main())
