# Stack and technology preferences

Technologies you use regularly. Helps the team choose with judgment and avoid introducing
new things without a reason.

## Default preferences
- **Web / fullstack**: Next.js (App Router), TypeScript, Prisma + PostgreSQL, Tailwind.
- **Deploy**: Vercel (web) / Docker (services and workers).
- **AI / voice**: Retell for voice; Anthropic / OpenAI via AI Gateway for LLMs.
- **Video / live decks**: HyperFrames (HTML → video, slideshows with presenter mode). External
  skill pack, installed with `bash install.sh --external`, not vendored in this repo.
- **Support / chat**: Chatwoot for conversational support.
- **ML / vision**: Python (workers), RTSP pipelines for video streams.

## Criteria for adding new technology
Only if it solves a concrete problem the current tools don't cover, and the benefit
outweighs the maintenance cost. Document the decision.

## Current projects (context)
- **aiforma** — learning platform with an AI voice tutor (Next.js + Prisma + Retell, Vercel deploy).
- **aipower-retail / retaileye** — computer vision for retail (frontend + RTSP demo + Python worker).
- **chefiando** — support POC with Chatwoot (agent-bot + backoffice) for hospitality.
- **naghon** — content / landing work.

_(Update this list as projects change.)_
