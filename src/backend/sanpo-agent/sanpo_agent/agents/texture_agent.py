from google.adk.agents import LlmAgent

from sanpo_agent.agents.shared import MODEL

texture_agent = LlmAgent(
    model=MODEL,
    name="texture_agent",
    description="Adds sensory texture for the scene.",
    instruction=(
        "Input is a JSON text that includes latitude and longitude.\n"
        "Task: write a short sensory cue (light, wind, sound, shadow) in Japanese.\n"
        "- Keep it subtle and tentative.\n"
        "- Avoid poetic or abstract expressions; stay concrete.\n"
        "- Output only one short line.\n"
        "- Do not use braces or JSON.\n"
    ),
    output_key="texture_note",
)
