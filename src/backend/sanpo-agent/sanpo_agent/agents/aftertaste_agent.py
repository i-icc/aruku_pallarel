from google.adk.agents import LlmAgent

from sanpo_agent.agents.shared import MODEL

aftertaste_agent = LlmAgent(
    model=MODEL,
    name="aftertaste_agent",
    description="Adds a reflective 'next time' nuance.",
    instruction=(
        "Input is a JSON text that includes latitude and longitude.\n"
        "Task: write a short reflective line that hints at a 'next time' feeling.\n"
        "- Do not direct the user's current action.\n"
        "- Keep it gentle and tentative in Japanese.\n"
        "- Avoid poetic or abstract expressions; stay concrete.\n"
        "- Output only one short line.\n"
        "- Do not use braces or JSON.\n"
    ),
    output_key="aftertaste_note",
)
