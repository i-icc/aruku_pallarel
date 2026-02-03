from google.adk.agents import ParallelAgent

from sanpo_agent.agents.aftertaste_agent import aftertaste_agent
from sanpo_agent.agents.poi_agent import poi_agent
from sanpo_agent.agents.texture_agent import texture_agent

gather_agent = ParallelAgent(
    name="gather_agent",
    description="Collects nearby cues in parallel.",
    sub_agents=[poi_agent, texture_agent, aftertaste_agent],
)
