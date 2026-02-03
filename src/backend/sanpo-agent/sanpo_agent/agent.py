from google.adk.agents import SequentialAgent

from sanpo_agent.agents.composer_agent import composer_agent
from sanpo_agent.agents.final_agent import final_agent
from sanpo_agent.agents.gather_agent import gather_agent

root_agent = SequentialAgent(
    name="root_agent",
    description="Generates a rich walking suggestion from layered sub-agent notes.",
    sub_agents=[gather_agent, composer_agent, final_agent],
)
