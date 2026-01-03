---
name: notion-llm-config
description: Manages the Notion LLM Config Table database tracking model configurations and parameters across multiple model providers. Use when working with the LLM config table, adding models, updating model parameters, or querying model architecture details.
allowed-tools: mcp__notion__notion-search, mcp__notion__notion-fetch, mcp__notion__notion-create-pages, mcp__notion__notion-update-page, mcp__notion__notion-update-database, Read, Bash
---

# Notion LLM Config Table Management

## Database Information
- **Database ID:** `ddfd95bd-109a-4ac6-955c-90541cc53d5e`
- **Data Source ID:** `0a9fafd6-2cc2-4d6b-b6f0-3797ea777421`
- **Location:** Family Notes workspace → "LLM config table"
- **Purpose:** Track LLM model configurations across multiple providers (Llama, others to be added)

## Data Sources

### Llama Models
Primary source: `~/projects/github/llama-models/models/sku_list.py`
- Contains all registered Llama models with architecture parameters
- Constants: `LLAMA2_VOCAB_SIZE = 32000`, `LLAMA3_VOCAB_SIZE = 128256`

## User Preferences
1. **No emojis** in any updates or content
2. **Batch operations** preferred over sequential updates
3. Focus on **practical utility** - add "Main" column for filtering to representative models
4. **Verify calculations** - user will catch errors, so double-check formulas

## Database Schema Key Columns

### Identity
- Model Name (title), Model Family, Model Type, Core Model ID
- HuggingFace Repo, Variant

### Architecture Parameters
- **d_hidden** = model hidden dimension (`dim` from Llama arch_args)
- **d_ff** = feed-forward hidden dimension (see calculation formulas below)
- **d_ff / d_hidden Ratio** = d_ff / d_hidden, rounded to 3 decimals
  - Llama: 2.667 (3B), 3.125 (Guard INT4), 3.25 (405B), 3.469 (2-70b chat), 3.5 (most common), 4.0 (1B)
  - Null for models without d_ff (Llama 4 has empty arch_args)
- **Gated MLP** (checkbox) = gated MLP/activation (SwiGLU for Llama)
- n_layers, n_heads, n_kv_heads, head_dim
- Multiple Of, Norm Eps

### Tokenization
- **Tokenizer**: Llama 2 Tokenizer (32k vocab) or Llama 3 Tokenizer (128k vocab)
- **Vocab Size**: 32000 (Llama 2), 128256 (Llama 3+)

### MoE Architecture
- **Is MoE** (checkbox)
- **Num Experts**: Llama 4: 16 (Scout), 128 (Maverick)
- **Top K Experts**: Number of routed experts per token
- **MoE Routing**: "Token Choice" (Llama 4) vs "Expert Choice"
- **Has Shared Expert**: Llama 4 has 1 shared + 1 routed per token
- **Activated Params (B)**: Llama 4: 17B
- **Total Params (B)**: Llama 4: 109B (Scout), 400B (Maverick)

### RoPE Configuration
- RoPE Theta, RoPE Freq Base
- Use Scaled RoPE (checkbox)

### Other
- Quantization Format, PTH File Count, Max Context Size
- Main (checkbox) - marks representative models for filtering

## Update Patterns

### Property Updates (Preferred)
```python
mcp__notion__notion-update-page({
    "page_id": "page-id-here",
    "command": "update_properties",
    "properties": {
        "Tokenizer": "Llama 3 Tokenizer",
        "Vocab Size": 128256,
        "Is MoE": "__YES__",  # Checkboxes use __YES__/__NO__
        "Num Experts": 16
    }
})
```

### Batch Updates
- Use parallel tool calls when updating multiple independent pages
- Group by model family for logical batching (e.g., all Scout models together)

### Search & Fetch
```python
# Search within database
mcp__notion__notion-search({
    "query": "Llama 4",
    "query_type": "internal",
    "data_source_url": "collection://0a9fafd6-2cc2-4d6b-b6f0-3797ea777421"
})

# Fetch page details
mcp__notion__notion-fetch({"id": "page-id-or-url"})
```

## Common Tasks

### Adding New Models
1. Parse `~/projects/github/llama-models/models/sku_list.py` to get model data
2. Extract arch_args and calculate derived fields (head_dim, d_ff using Llama formula, d_ff/d_hidden ratio)
3. Determine tokenizer based on model family (see Llama Model Family Mappings)
4. Set MoE fields for Llama 4 models
5. Set "Gated MLP" to Yes (all Llama models use SwiGLU)
6. Create pages in batches using `mcp__notion__notion-create-pages`

### Marking Representative Models
Representative "Main" models (user preference):
- Llama 2: 7b chat, 70b chat
- Llama 3.1: 8b instruct, 70b instruct, 405b instruct (FP8)
- Llama 3.2: **1b instruct**, 3b instruct, 11b vision instruct (user trains small models)
- Llama 3.3: 70b instruct
- Llama 4: Scout instruct, Maverick instruct

### Schema Updates
```python
mcp__notion__notion-update-database({
    "database_id": "ddfd95bd-109a-4ac6-955c-90541cc53d5e",
    "properties": {
        "New Column": {"type": "number", "number": {}}
    }
})
```

## Important Notes

### Pitfalls to Avoid
1. **Don't clear existing fields** - Only specify properties you're updating
2. **Column ordering** - Cannot be changed via API (view-level setting in UI)
3. **Checkbox format** - Must use `"__YES__"` or `"__NO__"`, not boolean
4. **Llama 4 models** - Have empty `arch_args={}` in sku_list.py, no d_hidden/d_ff available

### Llama Model Family Mappings
- **llama2**: Llama 2 Tokenizer, 32k vocab
- **llama3, llama3_1, llama3_2, llama3_3, llama4, safety**: Llama 3 Tokenizer, 128k vocab

#### Llama MoE Architecture (Llama 4 only)
- Only Llama 4 models are MoE
- Architecture: 1 shared expert (always active) + 1 routed expert (top_k=1)
- Effective: 2 experts per token (shared + routed)
- Routing: Token Choice (each token selects expert via router scores)

#### Llama Gated MLP / Activation Function
- All Llama models use gated MLP with SwiGLU activation
- Implementation: `w2(F.silu(w1(x)) * w3(x))` (from `models/llama3/model.py`)
- Uses 3 weight matrices (w1, w2, w3) instead of standard 2-matrix FFN
- SwiGLU = Swish-Gated Linear Unit (Swish is same as SiLU)

## Calculation Formulas

### General Derived Fields
```python
head_dim = d_hidden / n_heads
d_ff_d_hidden_ratio = round(d_ff / d_hidden, 3)
```

### Llama d_ff Calculation
From actual Llama code (`models/llama3/model.py`):
```python
# Initial: hidden_dim = 4 * dim
hidden_dim = int(2 * hidden_dim / 3)  # = int(8 * dim / 3)
if ffn_dim_multiplier is not None:
    hidden_dim = int(ffn_dim_multiplier * hidden_dim)
# Round up to multiple_of
hidden_dim = multiple_of * ((hidden_dim + multiple_of - 1) // multiple_of)
# Result is d_ff
```

## Helpful Scripts & References

### Llama
Working directory: `~/projects/github/llama-models/`

**Scripts:**
- Parse models: `parse_llama_models.py`
- Prepare Notion data: `prepare_notion_data.py`
- Update tokenizers: `update_tokenizers.py`
- Bulk updates: `bulk_update_llama3.py`
- Calculate d_ff: `fix_d_ff.py` (correct d_ff calculation using actual Llama formula)
- Calculate ratios: `calculate_ratios.py` (d_ff/d_hidden ratios and gated MLP status)
- Data files: `d_ff_corrections.json`, `complete_notion_updates.json`, `ratio_updates.json`
- Documentation: `COMPLETION_SUMMARY.md` (d_ff update history), `STATUS.md` (current status)

**References:**
- Llama models repo: `~/projects/github/llama-models/`
- Model definitions: `models/sku_list.py`
- Architecture files: `models/llama{2,3,4}/args.py`
- MoE implementation: `models/llama4/moe.py`
