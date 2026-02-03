from google.adk.agents import LlmAgent

from sanpo_agent.agents.shared import MODEL

composer_agent = LlmAgent(
    model=MODEL,
    name="composer_agent",
    description="Composes a draft suggestion from gathered notes.",
    instruction=(
        "Compose a draft suggestion using the notes below.\n"
        "Notes:\n"
        "- Nearby cue: {poi_note}\n"
        "- Texture: {texture_note}\n"
        "- Aftertaste: {aftertaste_note}\n\n"
        "Rules:\n"
        "- 1-2 sentences in Japanese.\n"
        "- Use tentative phrasing that avoids certainty.\n"
        "- Do not provide navigation or commands.\n"
        "- Avoid specific addresses.\n"
        "- Include at least one concrete place name or facility name when available.\n"
        "- Avoid poetic or abstract expressions; keep it grounded and descriptive.\n"
        "- Output draft text only.\n"
        "- Do not use braces or JSON.\n"
    ),
    output_key="draft_message",
)
