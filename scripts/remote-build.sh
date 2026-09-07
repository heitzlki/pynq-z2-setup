#!/usr/bin/env bash
# Build an apio project on a remote Linux machine and copy the bitstream back.
# Usage: scripts/remote-build.sh <project-dir> [apio subcommand, default: build]
#
# Settings come from scripts/local.env (git-ignored, see local.env.example)
# or from the environment: BUILD_HOST, BUILD_KEY (optional), BUILD_ROOT.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
[[ -f "$here/local.env" ]] && source "$here/local.env"

: "${BUILD_HOST:?set BUILD_HOST (user@host) in scripts/local.env or the environment}"
BUILD_ROOT="${BUILD_ROOT:-fpga}"
ssh_opts=()
[[ -n "${BUILD_KEY:-}" ]] && ssh_opts=(-i "$BUILD_KEY")

proj="${1:?usage: $0 <project-dir> [apio-subcommand]}"
cmd="${2:-build}"
proj="$(cd "$proj" && pwd)"
name="$(basename "$proj")"

rsync -az --delete --exclude '_build' --exclude '.vscode' -e "ssh ${ssh_opts[*]}" \
  "$proj/" "$BUILD_HOST:$BUILD_ROOT/$name/"

ssh "${ssh_opts[@]}" "$BUILD_HOST" \
  "export PATH=\$HOME/.local/bin:\$PATH && cd $BUILD_ROOT/$name && apio $cmd"

if [[ "$cmd" == "build" ]]; then
  mkdir -p "$proj/_build"
  scp -q "${ssh_opts[@]}" "$BUILD_HOST:$BUILD_ROOT/$name/_build/default/hardware.bit" "$proj/_build/$name.bit"
  echo "bitstream: $proj/_build/$name.bit"
fi
