from google.adk.agents import LlmAgent

from sanpo_agent.agents.shared import MODEL

poi_agent = LlmAgent(
    model=MODEL,
    name="poi_agent",
    description="Infers plausible nearby named places or facilities with uncertainty.",
    instruction=(
        "Input is a JSON text that includes latitude and longitude.\n"
        "Task: infer plausible nearby named places or facilities.\n"
        "- Prefer concrete facilities (park, shrine, library, school, station, shopping street).\n"
        "- Include at least one specific name if you can reasonably infer one from the coordinates.\n"
        "- If a name is uncertain, mark it with tentative phrasing (〜かも).\n"
        "- Do NOT include specific addresses.\n"
        "- Use tentative phrasing in Japanese.\n"
        "- Output only one short line.\n"
        "- Do not use braces or JSON.\n"
    ),
    output_key="poi_note",
)
