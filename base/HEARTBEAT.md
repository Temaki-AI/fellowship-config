# HEARTBEAT.md

## Downtime Detection (ALWAYS run first)
- Read `memory/heartbeat-state.json` → `lastHeartbeat` field (epoch seconds)
- Update `lastHeartbeat` to current time immediately
- If `lastHeartbeat` exists and gap > 30 minutes:
  - Calculate downtime window (last heartbeat → now)
  - Log: "⚠️ Detected downtime: {duration} ({from} → {to})"
  - Check MY cron jobs only (`agentId: main`) — find any with `nextRunAtMs` that falls WITHIN the downtime window
  - For each missed job: report it and offer to run it now (`cron run`)
  - Other agents handle their own missed jobs — don't run theirs
  - If no jobs missed, just note the downtime in today's memory file
- If gap > 8 hours: likely overnight downtime, be extra thorough checking missed jobs

## Night Shift Results (check first heartbeat after 07:00)
- Check if `memory/night-shift-plan.md` exists and has last night's date
- If yes: check for result files from sub-agents in workspace
- Compile a "🌙 Night Shift Report" — what was planned, what got done, key findings
- Append to today's daily briefing or send standalone on Telegram if briefing isn't ready
- Update TASKS.md with completed items
- Clear/archive the night shift plan

## Daily Briefing (once per day, first heartbeat after 07:30 WET)
- Check `memory/heartbeat-state.json` → `lastBriefing` field
- If NOT today's date: run `python3 scripts/generate-briefing.py`
  - **Sat/Sun**: script auto-skips unless urgent items found. No action needed.
  - **Mon**: The Week Ahead — add strategic priorities to the 🗓️ section
  - **Tue**: AI & Tech deep dive — web search for AI/agent/model news
  - **Wed**: Business deep dive — web search for Rydoo, SaaS, CRO, Temaki competitors
  - **Thu**: Infra & Security deep dive — web search for Node.js/npm/Linux vulns
  - **Fri**: Week recap — add wins, lessons, curate weekend reading picks
- Web search topics vary by day (see briefing's 🔍 Web Intelligence checklist)
- Append web search findings to `memory/briefings/YYYY-MM-DD.md`
- Update `memory/heartbeat-state.json` → set `lastBriefing` to today's date
- If anything urgent found, notify Miguel on Telegram
- **Only generate ONCE per day** — skip if lastBriefing matches today

## Morning App Ideas (daily, after briefing)
- **Every morning**: Send Miguel 3 new app ideas on Telegram (after daily briefing)
- **Criteria for good pitches:**
  - AI-forward (aligns with Temaki vision, he believes in AI-human collaboration)
  - Solves real friction (not novelty for novelty's sake)
  - Leverages Miguel's hybrid skills (technical + revenue expertise)
  - Buildable with the Fellowship (within our capabilities)
  - Clear path to revenue (SaaS, marketplace, automation)
- **Format**: Brief pitch (2-3 sentences each), why it matters, rough revenue model
- **Variety**: Mix categories — SaaS tools, AI apps, marketplaces, automation, dev tools
- **Tone**: Some wild, some practical. All worth 60 seconds of attention.
- **Frequency**: Daily, starting 2026-02-05

## Playground Social — PAUSED
- Miguel deprioritized this on 2026-02-01. Don't run sessions unless he asks.
- Bridge scripts and creds still in place if needed later.

## Temaki Product Feedback (2-3x per week)
- Explore a Temaki feature I haven't used deeply yet (or revisit one that's changed)
- Log bugs and friction points in `memory/temaki-feedback.md`
- Propose features from the AI-user perspective — what would make agent collaboration better?
- Post findings in Temaki Beta Squad channel when significant
- Think about: What would make Temaki the obvious choice for teams running AI agents?

## Screen Power Management
- Check if the display is on: `DISPLAY=:0 xrandr --query 2>/dev/null | grep "None-1 connected"`
- If the screen is ON and Miguel is NOT actively chatting on the iMac (no recent non-heartbeat message in this session within ~30 min), turn it off: `DISPLAY=:0 xrandr --output None-1 --off`
- Screen off saves ~154% CPU (software rendering). Always prefer off unless Miguel needs it.
- If Miguel asks to wake the screen: `DISPLAY=:0 xrandr --output None-1 --mode 2560x1440`

## Periodic Checks
- Review `TASKS.md` inbox — anything to triage or act on?
- Check `memory/heartbeat-state.json` — rotate through checks that are stale
- Run crash monitor: `bash scripts/crash-monitor.sh` — alert Miguel if exit code 2 (crash loop)
- If 3+ days since last memory maintenance: review recent daily files, update MEMORY.md

## Strategic Review (once daily, first heartbeat of the day)
- Reread USER.md and MEMORY.md — has anything changed? Am I missing something?
- Look at TASKS.md Backlog — what's the highest-leverage item I can move forward right now, without Miguel?
- Is there something I should research, prototype, or prepare that serves the three goals?
- Have I learned anything recently that changes priorities?

## Autonomous Work (do without asking)
- Research and write up findings on Backlog items
- Improve workspace: documentation, memory, tooling, automation
- Security monitoring: check for obvious issues, update knowledge
- Prepare briefings on things Miguel should know
- Move tasks forward — if I can complete something independently, do it

## Rule
Never let a heartbeat pass as HEARTBEAT_OK if there is meaningful work to do.
Only HEARTBEAT_OK when genuinely nothing needs attention.
