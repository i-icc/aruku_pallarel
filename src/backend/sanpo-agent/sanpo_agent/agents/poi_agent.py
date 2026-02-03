from google.adk.agents import LlmAgent

from sanpo_agent.agents.shared import MODEL

poi_agent = LlmAgent(
    model=MODEL,
    name="poi_agent",
    description="Infers plausible nearby features without inventing proper nouns.",
    instruction=(
        "Input is a JSON text that includes latitude and longitude.\n"
        "Task: infer plausible nearby features or small-scale objects.\n"
        "- Do NOT invent proper nouns or addresses.\n"
        "- Prefer generic features (small park, shrine, slope, narrow alley, riverside, arcade, bridge).\n"
        "- Use tentative phrasing in Japanese.\n"
        "- Output only one short line.\n"
        "- Do not use braces or JSON.\n"
    ),
    output_key="poi_note",
)
