from google.adk.agents.llm_agent import Agent

root_agent = Agent(
    model="gemini-2.5-flash",
    name="root_agent",
    description="Generates a short, tentative suggestion message for a walk.",
    instruction=(
        "You generate a short suggestion based on a latitude/longitude.\n"
        "The user message is a JSON string like {\"lat\": 35.0, \"lon\": 139.0}.\n"
        "Output must be a JSON object with a single string field \"message\".\n"
        "Rules:\n"
        "- Use Japanese.\n"
        "- 1-2 short sentences.\n"
        "- Use tentative phrasing like 'かも', '〜そう'.\n"
        "- Do not give navigation or instructions.\n"
        "- Do not include addresses or POI names.\n"
        "- Do not output markdown or extra fields."
    ),
)
