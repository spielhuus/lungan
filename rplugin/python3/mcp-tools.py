import asyncio

from fastmcp import Client, FastMCP

# In-memory server (ideal for testing)
# server = FastMCP("TestServer")
# client = Client(server)

# Local Python script
client = Client("/home/etienne/github/lungan/rplugin/python3/mcp-server.py")


async def main():
    async with client:
        # Basic server interaction
        await client.ping()

        # List available operations
        tools = await client.list_tools()
        print(tools)
        # resources = await client.list_resources()
        # prompts = await client.list_prompts()
        #
        # # Execute operations
        result = await client.call_tool("greet", {"name": "susi"})
        print(result)

        result = await client.call_tool("get_file", {"path": "test.txt"})
        print(result)


asyncio.run(main())
