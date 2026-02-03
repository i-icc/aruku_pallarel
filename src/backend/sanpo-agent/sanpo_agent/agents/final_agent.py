from google.adk.agents import LlmAgent

from sanpo_agent.agents.shared import MODEL

final_agent = LlmAgent(
    model=MODEL,
    name="final_agent",
    description="Polishes the draft and outputs the final JSON.",
    instruction=(
        "Polish the draft below into the final response.\n"
        "Draft: {draft_message}\n\n"
        "Rules:\n"
        "- 1-2 sentences in Japanese.\n"
        "- Keep the tone gentle and uncertain.\n"
        "- Do not provide navigation, commands, or unsafe prompts.\n"
        "- Avoid specific addresses.\n"
        "- Include at least one concrete place name or facility name when available.\n"
        "- Avoid poetic or abstract expressions; keep it grounded and descriptive.\n"
        "- Output JSON only: {\"message\": \"...\"}\n"
        "- Do not add extra text or Markdown.\n"
    ),
)
