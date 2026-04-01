# MCP vs CLI Token Benchmark
> Google Analytics MCP vs `gmp` CLI — Real data, no mocks

## Session Initialization

| Approach | Tokens at session start | Notes |
|----------|------------------------|-------|
| MCP (`listTools`) | **8,004** | Full JSON schema for all 7 tools |
| CLI (`gmp --help`) | **0** | LLM already knows CLI conventions |
| CLI (all helps combined) | 1,381 | Only loaded on demand |

### MCP Tool Breakdown

| Tool | Tokens | Description | Schema |
|------|--------|-------------|--------|
| `get_account_summaries` | 50 | 12 | 14 |
| `list_google_ads_links` | 129 | 47 | 54 |
| `get_property_details` | 120 | 40 | 54 |
| `list_property_annotations` | 169 | 85 | 54 |
| `get_custom_dimensions_and_metrics` | 125 | 42 | 54 |
| `run_report` | 3,738 | 3,110 | 259 |
| `run_realtime_report` | 3,626 | 3,044 | 215 |

## Task Comparison (GA4 only)

| Task | MCP Tokens | CLI Tokens | Ratio | Tokens Saved |
|------|-----------|-----------|-------|-------------|
| List GA4 accounts | 11,240 | 3,076 | **3.7x** | 8,164 |
| Get property details | 8,410 | 542 | **15.5x** | 7,868 |
| Run GA4 report (top pages last 7 days) | 8,134 | 442 | **18.4x** | 7,692 |
| Run GA4 realtime report | 8,093 | 363 | **22.3x** | 7,730 |
| Get custom dimensions and metrics | 46,430 | 34,585 | **1.3x** | 11,845 |
| **Total** | **82,307** | **39,008** | **2.1x** | **43,299** |

### Token breakdown per task

**List GA4 accounts**
- MCP: schema 8,004 + call 18 + response 3,218 = **11,240**
- CLI: discovery 279 + cmd 7 + response 2,790 = **3,076**

**Get property details**
- MCP: schema 8,004 + call 28 + response 378 = **8,410**
- CLI: discovery 227 + cmd 12 + response 303 = **542**

**Run GA4 report (top pages last 7 days)**
- MCP: schema 8,004 + call 93 + response 37 = **8,134**
- CLI: discovery 408 + cmd 33 + response 1 = **442**

**Run GA4 realtime report**
- MCP: schema 8,004 + call 52 + response 37 = **8,093**
- CLI: discovery 342 + cmd 20 + response 1 = **363**

**Get custom dimensions and metrics**
- MCP: schema 8,004 + call 30 + response 38,396 = **46,430**
- CLI: discovery 316 + cmd 13 + response 34,256 = **34,585**

## Methodology

- **Tokenizer**: tiktoken `o200k_base` (GPT-5 tokenizer)
- **MCP payload**: Real `listTools` JSON-RPC response extracted from `google-analytics-mcp` v0.2.0
- **CLI payload**: Real `gmp` CLI outputs captured against live Google Analytics API
- **MCP schema cost**: Counted once per task (injected into LLM context on every interaction)
- **CLI discovery**: Progressive `--help` calls — only the levels needed for each task
- **Response data**: Same underlying GA4 API data; MCP wraps in JSON-RPC envelope
- **All payloads saved** in `payloads/` directory for reproducibility

