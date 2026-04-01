#!/usr/bin/env python3
"""
Capture the real listTools JSON-RPC response from google-analytics-mcp.

Prerequisites:
  pip install analytics-mcp

This script imports the MCP server's tool definitions and serializes
the exact JSON-RPC response that would be sent to a client on session init.
No Google credentials needed — this only reads tool schemas, not data.

Usage:
  python3 scripts/capture-mcp-payload.py
"""

import json
import sys
from pathlib import Path

try:
    from google.adk.tools.function_tool import FunctionTool
    from google.adk.tools.mcp_tool.conversion_utils import adk_to_mcp_tool_type
except ImportError:
    print("ERROR: Install google-analytics-mcp first:")
    print("  pip install git+https://github.com/googleanalytics/google-analytics-mcp.git")
    sys.exit(1)

from analytics_mcp.tools.admin.info import (
    get_account_summaries,
    list_google_ads_links,
    get_property_details,
    list_property_annotations,
)
from analytics_mcp.tools.reporting.core import run_report, _run_report_description
from analytics_mcp.tools.reporting.realtime import (
    run_realtime_report,
    _run_realtime_report_description,
)
from analytics_mcp.tools.reporting.metadata import get_custom_dimensions_and_metrics

# Build tools exactly as the server does in coordinator.py
run_report_tool = FunctionTool(run_report)
run_report_tool.description = _run_report_description()
run_realtime_tool = FunctionTool(run_realtime_report)
run_realtime_tool.description = _run_realtime_report_description()

tools = [
    FunctionTool(get_account_summaries),
    FunctionTool(list_google_ads_links),
    FunctionTool(get_property_details),
    FunctionTool(list_property_annotations),
    FunctionTool(get_custom_dimensions_and_metrics),
    run_report_tool,
    run_realtime_tool,
]

mcp_tools = [adk_to_mcp_tool_type(t) for t in tools]

# Apply the same fixes as coordinator.py
for tool in mcp_tools:
    if tool.inputSchema == {}:
        tool.inputSchema = {"type": "object", "properties": {}}
    for prop in tool.inputSchema.get("properties", {}).values():
        if "anyOf" in prop and prop.get("type") == "null":
            del prop["type"]

# Build the exact JSON-RPC response
jsonrpc_response = {
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "tools": [
            {
                "name": t.name,
                "description": t.description,
                "inputSchema": t.inputSchema,
            }
            for t in mcp_tools
        ]
    },
}

output_dir = Path(__file__).parent.parent / "payloads" / "mcp"
output_dir.mkdir(parents=True, exist_ok=True)
output_file = output_dir / "listTools_response.json"

with open(output_file, "w") as f:
    json.dump(jsonrpc_response, f, indent=2)

tool_count = len(mcp_tools)
json_size = len(json.dumps(jsonrpc_response))
print(f"Captured {tool_count} tools ({json_size:,} bytes) -> {output_file}")
