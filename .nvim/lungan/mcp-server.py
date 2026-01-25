from typing import Annotated, Any, Dict

from fastmcp import FastMCP
from pydantic import Field

mcp = FastMCP("My MCP Server")


@mcp.tool
def greet(name: str) -> Dict[str, Any]:
    """
    Greets the user by name.

    Args:
        name: The name of the user to greet.
    """
    return {"content": f"Hello, {name}!", "type": "text"}


@mcp.tool
def get_file(
    path: Annotated[
        str,
        Field(
            description="The absolute path to the file to read (e.g., /tmp/notes.txt)"
        ),
    ],
) -> Dict[str, Any]:
    # read the file and return its content
    try:
        with open(path, "r") as f:
            content = f.read()
        return {"content": content, "type": "text"}
    except Exception as e:
        return {"content": f"Error reading file: {str(e)}", "type": "text"}


@mcp.tool
def filelist(
    path: Annotated[
        str,
        Field(
            description="The relative path from where to get the filelist. for the project root set path to '.'"
        ),
    ] = ".",
) -> Dict[str, Any]:
    """
    Get the list of files recursevly from a path.
    the path is relative to the project root.

    Args:
        path: the path to get the files from
    """
    # return the file list recursively
    import os

    try:
        files = []
        for root, dirs, filenames in os.walk(path):
            dirs[:] = [d for d in dirs if not d.startswith(".")]
            for filename in filenames:
                files.append(os.path.join(root, filename))
        return {"content": str(files), "type": "text"}
    except Exception as e:
        return {"content": f"Error: {str(e)}", "type": "text"}


if __name__ == "__main__":
    mcp.run(show_banner=False)
