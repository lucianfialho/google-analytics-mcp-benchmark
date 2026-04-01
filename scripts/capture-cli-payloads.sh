#!/bin/bash
# Capture real CLI payloads from gmp.
#
# Prerequisites:
#   npm install -g @anthropic/gmp-cli  (or however gmp is installed)
#   gmp auth login
#
# Usage:
#   bash scripts/capture-cli-payloads.sh [GA4_PROPERTY_ID] [GA4_ACCOUNT_ID]
#
# Example:
#   bash scripts/capture-cli-payloads.sh 250837915 187144

set -euo pipefail

PROPERTY_ID="${1:?Usage: $0 <property_id> <account_id>}"
ACCOUNT_ID="${2:?Usage: $0 <property_id> <account_id>}"

DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLI_DIR="$DIR/payloads/cli"
mkdir -p "$CLI_DIR"

echo "=== Capturing CLI help payloads ==="

gmp --help > "$CLI_DIR/gmp_help.txt"
gmp ga --help > "$CLI_DIR/gmp_ga_help.txt"
gmp ga report --help > "$CLI_DIR/gmp_ga_report_help.txt"
gmp ga realtime --help > "$CLI_DIR/gmp_ga_realtime_help.txt"
gmp ga metadata --help > "$CLI_DIR/gmp_ga_metadata_help.txt"
gmp ga accounts --help > "$CLI_DIR/gmp_ga_accounts_help.txt"
gmp gsc --help > "$CLI_DIR/gmp_gsc_help.txt"
gmp gsc report --help > "$CLI_DIR/gmp_gsc_report_help.txt"
gmp ads --help > "$CLI_DIR/gmp_ads_help.txt"
gmp ads campaigns --help > "$CLI_DIR/gmp_ads_campaigns_help.txt"
gmp gtm --help > "$CLI_DIR/gmp_gtm_help.txt"

echo "Help payloads captured."

echo ""
echo "=== Capturing real API responses ==="

echo "Task 1: List GA4 accounts..."
gmp ga accounts -f json > "$CLI_DIR/task1_ga_accounts.json" 2>/dev/null
echo "  -> $(wc -c < "$CLI_DIR/task1_ga_accounts.json") bytes"

echo "Task 2: Get property details..."
gmp ga properties --account "$ACCOUNT_ID" -f json > "$CLI_DIR/task2_ga_properties.json" 2>/dev/null
echo "  -> $(wc -c < "$CLI_DIR/task2_ga_properties.json") bytes"

echo "Task 3: Run GA4 report (top pages, 7d)..."
gmp ga report -p "$PROPERTY_ID" -m sessions,screenPageViews -d pagePath -r 7d -l 10 -f json > "$CLI_DIR/task3_ga_report.json" 2>/dev/null
echo "  -> $(wc -c < "$CLI_DIR/task3_ga_report.json") bytes"

echo "Task 4: Run GA4 realtime report..."
gmp ga realtime -p "$PROPERTY_ID" -m activeUsers -d country -f json > "$CLI_DIR/task6_ga_realtime.json" 2>/dev/null
echo "  -> $(wc -c < "$CLI_DIR/task6_ga_realtime.json") bytes"

echo "Task 5: Get custom dimensions and metrics..."
gmp ga metadata -p "$PROPERTY_ID" -f json > "$CLI_DIR/task7_ga_metadata.json" 2>/dev/null
echo "  -> $(wc -c < "$CLI_DIR/task7_ga_metadata.json") bytes"

echo ""
echo "All payloads captured in $CLI_DIR"
echo "Run 'python3 scripts/benchmark.py' to generate results."
