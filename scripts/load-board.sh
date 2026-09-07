#!/usr/bin/env bash
# Program the PYNQ-Z2's FPGA with a .bit over the network.
# Usage: scripts/load-board.sh <file.bit>
#
# The .bit is converted to the byte-swapped .bin that the Zynq fpga_manager
# kernel driver expects and loaded through /sys/class/fpga_manager.
#
# Settings come from scripts/local.env (git-ignored) or the environment:
#   BOARD_HOST  ssh target, default xilinx@pynq.local
#   BOARD_PW    sudo password on the board, default xilinx
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
[[ -f "$here/local.env" ]] && source "$here/local.env"
BOARD_HOST="${BOARD_HOST:-xilinx@pynq.local}"
BOARD_PW="${BOARD_PW:-xilinx}"

bit="${1:?usage: $0 <file.bit>}"
name="$(basename "${bit%.bit}")"
bin="$(mktemp -t "$name.XXXX")"
trap 'rm -f "$bin"' EXIT

python3 "$here/bit2bin.py" "$bit" "$bin"

# piped through ssh rather than scp so IPv6 link-local addresses (fe80::x%en8) work too
ssh "$BOARD_HOST" "cat > /home/xilinx/$name.bin" < "$bin"

ssh "$BOARD_HOST" "echo '$BOARD_PW' | sudo -S sh -c '
  cp /home/xilinx/$name.bin /lib/firmware/$name.bin &&
  echo 0 > /sys/class/fpga_manager/fpga0/flags &&
  echo $name.bin > /sys/class/fpga_manager/fpga0/firmware &&
  dmesg | grep fpga_manager | tail -1 &&
  echo state: \$(cat /sys/class/fpga_manager/fpga0/state)' 2>&1 | grep -v '^\[sudo\]'"
