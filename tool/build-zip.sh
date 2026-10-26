#!/usr/bin/env bash
# Builds dist/dartastic-skills.zip: the skills folders, ready to unzip into
# ~/.claude/skills (all projects) or <project>/.claude/skills (one project).
# The same files are the Claude Code plugin in plugins/dartastic.
set -euo pipefail
cd "$(dirname "$0")/.."
version=$(python3 -c 'import json;print(json.load(open("plugins/dartastic/.claude-plugin/plugin.json"))["version"])')
rm -rf dist && mkdir -p dist
( cd plugins/dartastic/skills && zip -qrX "../../../dist/dartastic-skills-$version.zip" . -x '*.DS_Store' )
cp "dist/dartastic-skills-$version.zip" dist/dartastic-skills.zip
unzip -l dist/dartastic-skills.zip | tail -1
echo "built dist/dartastic-skills.zip ($version)"
