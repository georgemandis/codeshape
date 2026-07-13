import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { TOOL, buildArgs, schemaFor } from "./tools.ts";
import { runCodeshape } from "./runner.ts";

const server = new McpServer({ name: "codeshape", version: "0.1.0" });

server.tool(TOOL.name, TOOL.description, schemaFor(), async (params: any) => {
  try {
    const data = await runCodeshape(buildArgs(params), params.directory as string | undefined);
    return { content: [{ type: "text" as const, text: JSON.stringify(data) }] };
  } catch (e: any) {
    return {
      isError: true,
      content: [{ type: "text" as const, text: e?.message ?? String(e) }],
    };
  }
});

const transport = new StdioServerTransport();
await server.connect(transport);
