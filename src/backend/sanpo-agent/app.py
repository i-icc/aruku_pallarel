import os

from google.adk.cli.fast_api import get_fast_api_app

AGENTS_DIR = os.getenv("ADK_AGENTS_DIR", os.path.dirname(__file__))

app = get_fast_api_app(agents_dir=AGENTS_DIR, web=False)


@app.get("/health")
async def health():
    return {"status": "ok"}
