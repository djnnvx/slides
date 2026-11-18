#!/usr/bin/env bash
cd "$(dirname "$0")"
uv run python rogue_csms.py & CSMS=$!
trap 'kill $CSMS' EXIT
sleep 1
uv run python charge_point.py
