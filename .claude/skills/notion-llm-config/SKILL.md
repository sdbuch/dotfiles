---
name: notion-llm-config
description: Manages the Notion LLM Config Table database tracking model configurations and parameters. Use when working with the LLM config table, adding models, updating model parameters, or querying model architecture details from sku_list.py.
allowed-tools: mcp__notion__notion-search, mcp__notion__notion-fetch, mcp__notion__notion-create-pages, mcp__notion__notion-update-page, mcp__notion__notion-update-database, Read, Bash
---

# Notion LLM Config Table Management

## Database Information
- **Database ID:** `ddfd95bd-109a-4ac6-955c-90541cc53d5e`
- **Data Source ID:** `0a9fafd6-2cc2-4d6b-b6f0-3797ea777421`
- **Location:** Family Notes workspace → "LLM config table"
- **Purpose:** Track LLM model configurations, especially for Llama model family

## Data Source
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
- **d_hidden** = `dim` from arch_args (model hidden dimension)
- **d_ff** = feed-forward hidden dim (complex calculation - see STATUS.md)
- n_layers, n_heads, n_kv_heads, head_dim
- FFN Dim Multiplier, Multiple Of, Norm Eps

### Tokenization
- **Tokenizer** (select): "Llama 2 Tokenizer" (32k vocab) or "Llama 3 Tokenizer" (128k vocab)
- **Vocab Size**: 32000 for Llama 2, 128256 for Llama 3+

### MoE Architecture
- **Is MoE** (checkbox)
- **Num Experts**: 16 (Scout) or 128 (Maverick)
- **Top K Experts**: 1 (number of routed experts per token)
- **MoE Routing**: "Token Choice" (not Expert Choice)
- **Has Shared Expert**: Yes (Llama 4 has 1 shared + 1 routed expert per token)
- **Activated Params (B)**: 17B for all Llama 4 models
- **Total Params (B)**: 109B (Scout) or 400B (Maverick)

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
#### Llama Models
1. Parse sku_list.py to get model data
2. Extract arch_args and calculate derived fields (head_dim, d_ff)
3. Determine tokenizer based on model family
4. Set MoE fields for Llama 4 models
5. Create pages in batches using `mcp__notion__notion-create-pages`

### Marking Representative Models
#### Llama Models
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
3. **Llama 4 models** - Have empty `arch_args={}` in sku_list.py, no d_hidden/d_ff available
4. **Checkbox format** - Must use `"__YES__"` or `"__NO__"`, not boolean

### Model Family Mappings
- **llama2**: Llama 2 Tokenizer, 32k vocab
- **llama3, llama3_1, llama3_2, llama3_3, llama4, safety**: Llama 3 Tokenizer, 128k vocab

### MoE Architecture Notes
- Only Llama 4 models are MoE
- Architecture: 1 shared expert (always active) + 1 routed expert (top_k=1)
- Effective: 2 experts per token (shared + routed)
- Routing: Token Choice (each token selects expert via router scores)

## Calculation Formulas

### Derived Fields
```python
head_dim = dim / n_heads
d_ff = complex_calculation  # See STATUS.md for details
```

### d_ff Calculation (Complex - from actual Llama code)
```python
# Initial: hidden_dim = 4 * dim
hidden_dim = int(2 * hidden_dim / 3)  # = int(8 * dim / 3)
if ffn_dim_multiplier is not None:
    hidden_dim = int(ffn_dim_multiplier * hidden_dim)
# Round up to multiple_of
hidden_dim = multiple_of * ((hidden_dim + multiple_of - 1) // multiple_of)
# Result is d_ff
```

## Helpful Scripts Location
Working directory: `~/projects/github/`
- Parse models: `parse_llama_models.py`
- Prepare Notion data: `prepare_notion_data.py`
- Update tokenizers: `update_tokenizers.py`
- Bulk updates: `bulk_update_llama3.py`

## References
- Llama models repo: `~/projects/github/llama-models/`
- Model definitions: `models/sku_list.py`
- Architecture files: `models/llama{2,3,4}/args.py`
- MoE implementation: `models/llama4/moe.py`
