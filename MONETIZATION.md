# Revenue plan for 01-Planner

## What you actually have to sell

| Asset | Why it's differentiated |
|---|---|
| Timeline + inbox planner matching Structured | Most Arabic users don't have a polished native equivalent |
| Bilingual AR/EN with full RTL | Structured does not ship Arabic well |
| **AI plan extraction + conflict avoidance** | Sunsama/Motion charge $10–34/mo for this |
| **BYOK local LLM support** (LM Studio) | Privacy-first — no cloud data leaves the device |
| Android home-screen widget | Structured-grade UX on Android (where Structured is weak) |
| Goal → linked sub-tasks with AI generation | Habit-tracker + planner + coach in one |

Price the AI + Arabic + privacy combo; the plain timeline is table-stakes.

---

## Recommended strategy: **Freemium + paid Pro**, with a BYOK escape hatch

Three tiers. 80/20 engineering effort goes into the Pro flow since that's where the money is.

### Free tier (always)
- Timeline + Inbox + Goals + Events + Tasks
- Home widget
- Manual task creation / edit / drag-reschedule
- Local notifications + reminders
- Arabic + English
- Up to 2 active goals and 1 chat session with AI assistant
- **Limit: no AI plan generation, no convert-to-plan**

### Pro tier — **$3.99/mo or $24.99/yr** (match Structured's floor)
- Unlimited AI chats + convert-to-plan
- Unlimited goals + auto sub-task generation
- Conflict-free scheduling
- Daily planner (AI schedule refresh)
- Smart reminders + 3-hour goal pulses
- Custom app colors + layouts
- Cloud sync (see "Tech" below)
- Priority support

### **BYOK Lite** — free forever, for the privacy crowd
User points the app at their own LM Studio / Ollama / OpenAI key. You waive the subscription gate entirely but collect nothing — they fund their own inference.

Marketing angle: "Pay us for the polished AI experience, or run it free on your own machine." That's the privacy story *and* the pragmatic pitch. Converts power-users into advocates.

---

## Secondary streams

### 1. **Team / Deloitte-style SaaS** — $9/user/mo, annual
Sell a hosted team version to the company you're QA-leading for. Add:
- Shared goals (squad-level OKRs)
- Assign tasks across users
- QA-specific templates (test plan, retro, defect-triage)
- Audit log for compliance

One Deloitte-sized team = $300/mo. Land one, reference-sell the next.

### 2. **Template / curriculum marketplace**
AI-generated plan templates users can browse:
- "First 90 days as QA Lead" — $4.99 one-time
- "Ramp up on Python in 60 days" — $4.99
- "Wedding planning — 6 months" — $4.99
- "Ramadan daily routine" — $1.99

70/30 split with any community contributors. Low-volume high-margin. Brings Pro trials.

### 3. **Fine-tuned model packs** (advanced)
Your local LoRA for Qwen plan extraction (see FINETUNING.md) — sell as `.gguf` packs or ship as part of a higher "Studio" tier at $7.99/mo for power users who care about speed + JSON precision.

### 4. **B2B white-label**
Re-skin for a corporate client (bank, consulting firm, university). One-time $20k–50k engagement + maintenance. High touch; only pursue after you have one clear reference customer.

### 5. **Affiliate** (low priority)
Link to LM Studio / Ollama setup guides in-app. Both open-source — but affiliate programs exist for task-related SaaS (Notion, Todoist). Fills $50–200/mo of passive income once scale hits.

---

## Tech dependencies (what to build for Pro)

| Feature | Effort | Unlocks |
|---|---|---|
| Cloud sync (Supabase or self-host Pocketbase) | 2 wks | Cross-device, biggest Pro perk |
| Paywall (RevenueCat + Stripe) | 3 days | Actual billing |
| Hosted AI proxy (small VPS forwarding to Groq free tier or Together.ai) | 1 wk | Users w/o LM Studio get AI |
| Entitlement checks gating AI/goals/colors | 2 days | Free vs Pro split |
| Family plan | 2 days | $39.99/yr/family — converts better |

Total: ~4 weeks of focused work to reach a chargeable Pro v1.

---

## Go-to-market, in order

1. **Month 1 — Arab MENA Pro launch.** Arabic-first landing page, ProductHunt in Arabic + English simultaneously. Content: "Structured for Arabic speakers, with AI that understands you." Target niche is saturated in English but empty in Arabic.
2. **Month 2 — QA professional template pack.** Ride your actual QA Lead transition: post the 90-day plan template on LinkedIn and r/softwaretesting. Each share drives free-tier installs; convert 3–8 % to Pro.
3. **Month 3 — Team SKU for a specific vertical.** Pitch QA teams at three consulting firms (Deloitte included) on the shared-goals version. Sell annually, $9/seat/mo, minimum 5 seats.
4. **Ongoing — BYOK advocates.** Post technical threads ("how I run qwen locally for planning") on HackerNews / X. These users don't pay but drive credibility and bring their employers later.

---

## Revenue math (conservative)

| Source | Year 1 users | Paid % | ARR |
|---|---|---|---|
| Pro consumer (MENA + EN) | 5,000 free / 300 Pro | 6 % | $7,500 |
| Team / enterprise (2 contracts) | 30 seats × $108 | 100 % | $3,240 |
| Template packs | 1,500 buyers × $4.99 | — | $7,485 |
| **Total Year 1** | | | **~$18k** |

Not life-changing Year 1. The shape matters: once cloud sync + team SKU ship, retention and ARR compound. Year 2 target = $120k, Year 3 = realistic path to $500k or a strategic acquihire by a bigger planning/productivity app.

---

## What NOT to do

- **Ads.** Productivity apps with ads feel cheap and churn harder. Your whole story is privacy + craft; ads contradict both.
- **"AI credits" metering.** Confusing, frustrating. Just cap free usage counts (e.g., 3 AI conversations/month) and go unlimited on Pro.
- **Over-polish before charging.** You already have 80 % of Structured's feature set. Ship the paywall this month on Android; iOS can wait.
- **Big-bang launch.** Soft-launch to MENA first, fix feedback, then post globally.

---

## Immediate next steps (this week)

1. Set up **RevenueCat** free tier + Stripe for Pro pricing.
2. Wire a simple **entitlement flag** (`AppPrefs().isPro`) that gates AI + unlimited goals + custom colors.
3. Make an Arabic-first landing page at `01planner.app` — hero screenshot, three tier comparison, waitlist.
4. Write three "Convert to plan" case studies (QA lead, student, new parent) — posts for ProductHunt + LinkedIn.
5. Ship v1 Pro paywall within 3 weeks.

Charge from day one — even at $0.99/mo for the first 100 users you learn faster than another feature cycle.
