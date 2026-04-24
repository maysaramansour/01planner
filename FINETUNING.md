# Speeding up Qwen for 01-Planner

Goal: **< 1 minute plan generation.**
Current: qwen/qwen2.5-vl-7b Q4 on CPU = 60–180 s per plan.

Fast wins take hours, not weeks. Try in this order.

---

## 1. Inference-level wins (no training)

### 1.a Switch to a smaller model — biggest single win
`qwen2.5-vl-7b` is a vision-language model; you don't use its image modality for plan
extraction, so the vision branch is dead weight.

| Swap to | Approx. speed vs. 7B VL | Quality impact for plans |
|---|---|---|
| `qwen2.5-3b-instruct` Q4_K_M | ~3× faster | Small; structured output still solid |
| `qwen2.5-1.5b-instruct` Q4_K_M | ~7× faster | Acceptable for short plans |
| `qwen2.5-coder-7b-instruct` Q4 | same speed | JSON compliance noticeably better |

In LM Studio: Download → search `qwen2.5-3b-instruct-gguf` (Bartowski).
App-side: update **AI Settings → Model** to the new identifier LM Studio shows.

### 1.b Turn on GPU / Apple Silicon
LM Studio → Settings → GPU Offload: raise layers until RAM is comfortable.
On M-series Macs, aim for `GPU Layers: 32+`, Metal backend.
**This alone typically gives 3–5× throughput.**

### 1.c Enable `speculative decoding`
LM Studio → per-model → Speculative → add a 1B "draft" model.
Works for plain chat/tool formats; ~1.5× speedup.

### 1.d Tighter app-side prompts (already applied)
`maxTokens` dropped from 8192 → 3500; prompts trimmed; duplicate-task cap at 15.
Further wins: drop old chat turns before extraction (send only the last 6).

### 1.e Streaming
Use `stream: true` on the OpenAI-compatible endpoint. Perceived latency drops
from "stuck for 60 s" to "words arriving now". Requires migrating `_chat()` to
SSE parsing — straightforward with `http` but ~100 lines. Not critical if
models and HW are already fast; do it after 1.a + 1.b.

---

## 2. Fine-tune a LoRA for plan extraction

Do this only after the inference-level wins — tuning a slow model still
yields a slow model.

### 2.a Dataset (~100 examples is enough)
Format: `{system, user (conversation), assistant (JSON plan)}`.
Build by capturing real extractions the user liked + hand-writing 20 Arabic +
20 English canonical plans (learn topic X, prepare for interview, daily
fitness, etc.). Save as `plans.jsonl`.

Schema reminder (keep identical to runtime):
```json
{"goals": [...], "habits": [...], "tasks": [...]}
```

### 2.b Training
- Base: `qwen2.5-3b-instruct` (not the 7B VL variant).
- Framework: [Axolotl](https://github.com/OpenAccess-AI-Collective/axolotl) or
  [unsloth](https://github.com/unslothai/unsloth) (~2× faster, handles Qwen).
- LoRA rank 16, alpha 32, targets `q_proj`, `k_proj`, `v_proj`, `o_proj`.
- 3 epochs, batch size 4, learning rate 2e-4, cosine schedule.
- On a single RTX 4090 / M3 Max this is 30–60 minutes.

### 2.c Export + run
Merge LoRA → export to GGUF via llama.cpp:
```bash
python llama.cpp/convert.py --outtype q4_k_m path/to/merged
```
Drop the `.gguf` into LM Studio's models folder; point the app at it.

Result: same model, but follows the exact `{goals, habits, tasks}` shape
first-try, so `response_format` isn't needed and generation stops earlier. Cuts
another 20–40 % off generation time.

---

## 3. Alternative routes if in a hurry

- **Groq / Together.ai hosted Qwen2.5-72B** — cloud, free tier of each is
  enough for personal use; plan in < 3 s. Just point Base URL at their
  OpenAI-compatible endpoint. Privacy trade-off.
- **Llama-3.1-8B-Instruct Q4** on LM Studio — non-Qwen alternative,
  comparable JSON quality, sometimes faster.

---

## What's already in the app

| Optimisation | Status |
|---|---|
| Tight system prompt with few-shot | ✅ |
| `maxTokens` trimmed to 3500 | ✅ |
| Dedup/cap at 15 tasks post-response | ✅ |
| Truncation-repair JSON parser | ✅ |
| Background-safe extraction (persists + resumes) | ✅ |
| Availability + weekend pruning | ✅ |
| SSE streaming | ❌ (planned) |
| Tool-use mode | ❌ (Qwen VL support is flaky) |
