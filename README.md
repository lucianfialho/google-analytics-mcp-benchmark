# MCP vs CLI Token Benchmark: Google Analytics

A reproducible benchmark comparing the token cost of [Google Analytics MCP](https://github.com/googleanalytics/google-analytics-mcp) vs the [`gmp` CLI](https://github.com/lucianfialho/gmp) when used by AI agents (Claude, GPT-5, Gemini, etc).

**TL;DR**: MCP consumes **2-22x more tokens** than CLI for the same GA4 tasks, primarily because MCP injects the full tool schema (~8,000 tokens) into the LLM context on every interaction.

## Results

| Task | MCP Tokens | CLI Tokens | Ratio |
|------|-----------|-----------|-------|
| List GA4 accounts | 11,240 | 3,076 | **3.7x** |
| Get property details | 8,410 | 542 | **15.5x** |
| Run GA4 report | 8,134 | 442 | **18.4x** |
| Run realtime report | 8,093 | 363 | **22.3x** |
| Get custom dimensions/metrics | 46,430 | 34,585 | **1.3x** |
| **Total (5 tasks)** | **82,307** | **39,008** | **2.1x** |

For the full breakdown, see [`results.md`](results.md).

## Why this matters

When an AI agent connects to an MCP server, the server's **entire tool schema** is loaded into the LLM's context window. For the Google Analytics MCP server, that's **8,004 tokens** before the agent does anything useful.

This cost is paid on **every interaction**, not just once. Across 5 tasks, that's 40,020 tokens spent purely on schema — more than the CLI spends on everything combined (discovery + commands + responses).

The CLI approach uses **progressive disclosure**: the agent only discovers what it needs, when it needs it. `gmp --help` (107 tokens) leads to `gmp ga --help` (120 tokens) leads to `gmp ga report --help` (181 tokens). Total discovery for a report task: 408 tokens vs 8,004 for MCP.

## Where MCP schema tokens go

92% of the MCP schema tokens come from just 2 tools:

| Tool | Tokens | % of total |
|------|--------|-----------|
| `run_report` | 3,738 | 46.7% |
| `run_realtime_report` | 3,626 | 45.3% |
| Other 5 tools | 593 | 7.4% |

These descriptions are large because they embed JSON examples for filters, date ranges, and order_bys — many of which are **duplicated** between the two tools.

## Reproduce it yourself

### Prerequisites

- Python 3.10+
- Node.js 18+ (for `gmp` CLI)
- A Google account with GA4 access

### Step 1: Install dependencies

```bash
# gmp CLI
npm install -g gmp-cli
gmp auth login

# Python deps (for MCP payload extraction + benchmark)
pip install tiktoken
pip install git+https://github.com/googleanalytics/google-analytics-mcp.git
```

### Step 2: Capture payloads

```bash
# Capture MCP listTools payload (no auth needed)
python3 scripts/capture-mcp-payload.py

# Capture CLI payloads (needs auth + your property/account IDs)
# Find your IDs: gmp ga accounts && gmp ga properties --account <ACCOUNT_ID>
bash scripts/capture-cli-payloads.sh <PROPERTY_ID> <ACCOUNT_ID>
```

### Step 3: Run benchmark

```bash
python3 scripts/benchmark.py                    # terminal output
python3 scripts/benchmark.py --format markdown   # for articles
python3 scripts/benchmark.py --format json       # structured data
python3 scripts/benchmark.py --format csv        # spreadsheets
```

## Repository structure

```
benchmark/
├── README.md                          # This file
├── results.md                         # Full results (markdown)
├── results.json                       # Structured results
├── results.csv                        # Spreadsheet-friendly
├── scripts/
│   ├── benchmark.py                   # Main benchmark script
│   ├── capture-mcp-payload.py         # Extract MCP listTools JSON
│   └── capture-cli-payloads.sh        # Capture gmp CLI outputs
└── payloads/
    ├── mcp/
    │   └── listTools_response.json    # Real MCP JSON-RPC response (29KB)
    └── cli/
        ├── gmp_help.txt               # --help at each level
        ├── gmp_ga_help.txt
        ├── gmp_ga_report_help.txt
        ├── ...
        ├── task1_ga_accounts.json     # Real API responses
        ├── task2_ga_properties.json
        ├── task3_ga_report.json
        ├── task6_ga_realtime.json
        └── task7_ga_metadata.json
```

## Methodology

- **Tokenizer**: tiktoken `o200k_base` (GPT-5 tokenizer)
- **MCP payload**: Real `listTools` JSON-RPC response extracted from [`google-analytics-mcp`](https://github.com/googleanalytics/google-analytics-mcp) v0.2.0 source code
- **CLI payload**: Real `gmp` CLI outputs captured against live Google Analytics Data API
- **MCP schema cost**: Full listTools injected per task (this is how MCP works — the schema is in context for every LLM call)
- **CLI discovery**: Only the `--help` levels needed for each specific task
- **Response data**: Same underlying GA4 API; MCP adds JSON-RPC envelope overhead
- **No mocked data**: All payloads in `payloads/` are from real API calls

### What we measure

For each task, we count:

| Component | MCP | CLI |
|-----------|-----|-----|
| **Discovery** | Full `listTools` schema (all 7 tools) | Only the `--help` levels needed |
| **Call** | JSON tool_call object | Shell command string |
| **Response** | JSON-RPC wrapped response | Raw JSON output |

### Limitations

- Token counts use tiktoken with `o200k_base` (GPT-5 tokenizer). Other models use different tokenizers, so counts may differ by ~5-10%, but ratios remain consistent.
- MCP schema is counted per task. In a multi-turn conversation, the schema is in context the whole time (amortized), but still consumes the same context window space.
- CLI discovery assumes the LLM calls `--help` progressively. A well-trained LLM may skip some levels for familiar CLIs, making the CLI even more efficient.
- We compare only GA4 tasks since that's the overlap between both tools.

## Related work

- [Scalekit: MCP vs CLI Benchmark](https://www.scalekit.com/blog/mcp-vs-cli-use) — 75 head-to-head tests, 4-32x token overhead for MCP
- [Apideck: Your MCP Server Is Eating Your Context Window](https://www.apideck.com/blog/mcp-server-eating-context-window-cli-alternative) — 72% context window consumed by 3 MCP servers
- [Cloudflare: Code Mode](https://blog.cloudflare.com/code-mode-mcp/) — 99.9% token reduction via code generation
- [Anthropic: Code execution with MCP](https://www.anthropic.com/engineering/code-execution-with-mcp) — 98.7% reduction
- [arXiv: MCP Tool Descriptions Are Smelly](https://arxiv.org/html/2602.14878v1) — Academic analysis of description overhead
- [CircleCI: MCP vs CLI](https://circleci.com/blog/mcp-vs-cli/) — Practical comparison with browser automation

## License

MIT
