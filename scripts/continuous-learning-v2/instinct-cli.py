#!/usr/bin/env python3
"""
Instinct CLI - Continuous Learning v2

Commands:
  list [--domain DOMAIN] [--confidence MIN]  List instincts
  add TRIGGER ACTION --domain DOMAIN         Add new instinct
  apply ID                                   Mark instinct as applied (increase confidence)
  promote ID                                 Promote to global scope
  export [--output FILE]                     Export all instincts to JSON
  import FILE                                Import instincts from JSON
  projects                                   List all projects with instincts
  evolve                                     Cluster instincts into skill suggestions
  --version                                  Show version
"""

import argparse
import json
import sys
from pathlib import Path
from datetime import datetime
import hashlib

VERSION = "0.1.0"

class InstinctStorage:
    def __init__(self, project_hash):
        self.base_dir = Path.home() / ".claude" / "homunculus" / "projects" / project_hash
        self.base_dir.mkdir(parents=True, exist_ok=True)
        self.instincts_file = self.base_dir / "instincts.json"

    def load(self):
        if not self.instincts_file.exists():
            return {"project": {}, "instincts": [], "global_instincts": []}
        with open(self.instincts_file, 'r') as f:
            return json.load(f)

    def save(self, data):
        with open(self.instincts_file, 'w') as f:
            json.dump(data, f, indent=2)

def get_project_hash():
    """Get git remote URL hash for current project"""
    import subprocess
    try:
        remote = subprocess.check_output(
            ["git", "config", "--get", "remote.origin.url"],
            stderr=subprocess.DEVNULL,
            text=True
        ).strip()
        return hashlib.md5(remote.encode()).hexdigest()[:8]
    except:
        # Fallback: use current directory name
        return hashlib.md5(str(Path.cwd()).encode()).hexdigest()[:8]

def cmd_list(args, storage):
    data = storage.load()
    instincts = data.get("instincts", []) + data.get("global_instincts", [])

    # Filter
    if args.domain:
        instincts = [i for i in instincts if i.get("domain") == args.domain]
    if args.confidence:
        instincts = [i for i in instincts if i.get("confidence", 0) >= args.confidence]

    # Display
    for inst in instincts:
        scope_marker = "[GLOBAL]" if inst.get("scope") == "global" else "[PROJECT]"
        print("{} [{}] {}".format(scope_marker, inst['id'], inst['trigger']))
        print("   -> {}".format(inst['action']))
        print("   Confidence: {:.2f} | Domain: {} | Applied: {}x".format(
            inst['confidence'], inst['domain'], inst.get('apply_count', 0)))
        print()

def cmd_add(args, storage):
    data = storage.load()
    new_id = "inst_{:03d}".format(len(data['instincts']) + 1)

    instinct = {
        "id": new_id,
        "trigger": args.trigger,
        "action": args.action,
        "confidence": 0.3,
        "domain": args.domain,
        "evidence": ["{}: Created manually".format(datetime.now().isoformat())],
        "scope": "project",
        "created": datetime.now().isoformat(),
        "apply_count": 0
    }

    data["instincts"].append(instinct)
    storage.save(data)
    print("[OK] Added instinct: {}".format(new_id))

def cmd_apply(args, storage):
    data = storage.load()
    for inst in data["instincts"]:
        if inst["id"] == args.id:
            inst["apply_count"] = inst.get("apply_count", 0) + 1
            inst["confidence"] = min(0.95, inst["confidence"] + 0.05)
            inst["last_applied"] = datetime.now().isoformat()
            inst["evidence"].append("{}: Applied successfully".format(datetime.now().isoformat()))
            storage.save(data)
            print("[OK] Applied {}. Confidence now: {:.2f}".format(args.id, inst['confidence']))
            return
    print("ERROR: Instinct {} not found".format(args.id), file=sys.stderr)
    sys.exit(1)

def cmd_promote(args, storage):
    data = storage.load()
    for i, inst in enumerate(data["instincts"]):
        if inst["id"] == args.id:
            if inst["confidence"] < 0.8:
                print("ERROR: Confidence {:.2f} < 0.8 (promotion threshold)".format(inst['confidence']), file=sys.stderr)
                sys.exit(1)

            inst["scope"] = "global"
            inst["promoted_at"] = datetime.now().isoformat()

            # Move to global list
            data["global_instincts"].append(inst)
            data["instincts"].pop(i)
            storage.save(data)

            print("[OK] Promoted {} to global scope".format(args.id))
            return
    print("ERROR: Instinct {} not found".format(args.id), file=sys.stderr)
    sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Instinct CLI - Continuous Learning v2")
    parser.add_argument('--version', action='version', version='instinct-cli {}'.format(VERSION))

    subparsers = parser.add_subparsers(dest='command', help='Available commands')

    # list
    list_parser = subparsers.add_parser('list', help='List instincts')
    list_parser.add_argument('--domain', help='Filter by domain')
    list_parser.add_argument('--confidence', type=float, help='Minimum confidence')

    # add
    add_parser = subparsers.add_parser('add', help='Add new instinct')
    add_parser.add_argument('trigger', help='When to apply')
    add_parser.add_argument('action', help='What to do')
    add_parser.add_argument('--domain', required=True, help='Domain category')

    # apply
    apply_parser = subparsers.add_parser('apply', help='Mark instinct as applied')
    apply_parser.add_argument('id', help='Instinct ID')

    # promote
    promote_parser = subparsers.add_parser('promote', help='Promote to global')
    promote_parser.add_argument('id', help='Instinct ID')

    # export/import/projects/evolve (stubs for now)
    subparsers.add_parser('export', help='Export instincts')
    subparsers.add_parser('import', help='Import instincts')
    subparsers.add_parser('projects', help='List projects')
    subparsers.add_parser('evolve', help='Cluster into skills')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    # Initialize storage
    project_hash = get_project_hash()
    storage = InstinctStorage(project_hash)

    # Dispatch
    if args.command == 'list':
        cmd_list(args, storage)
    elif args.command == 'add':
        cmd_add(args, storage)
    elif args.command == 'apply':
        cmd_apply(args, storage)
    elif args.command == 'promote':
        cmd_promote(args, storage)
    else:
        print("Command '{}' not yet implemented".format(args.command), file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
