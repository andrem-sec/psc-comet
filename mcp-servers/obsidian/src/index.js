'use strict';

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const { CallToolRequestSchema, ListToolsRequestSchema } = require('@modelcontextprotocol/sdk/types.js');
const { ObsidianClient } = require('./obsidian');
const { OmnisearchClient } = require('./omnisearch');

const config = {
  host: process.env.OBSIDIAN_HOST || '127.0.0.1',
  port: parseInt(process.env.OBSIDIAN_PORT || '27124', 10),
  apiKey: process.env.OBSIDIAN_API_KEY || '',
  omnisearchPort: parseInt(process.env.OMNISEARCH_PORT || '51361', 10)
};

// Disable TLS verification for Obsidian's self-signed certificate
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const obsidian = new ObsidianClient(config);
const omnisearch = new OmnisearchClient({ port: config.omnisearchPort });

const TOOLS = [
  {
    name: 'obsidian_search',
    description: 'Search the Obsidian vault using Omnisearch full-text search. Returns ranked results with file paths and excerpts.',
    inputSchema: {
      type: 'object',
      properties: {
        query: { type: 'string', description: 'Search query' }
      },
      required: ['query']
    }
  },
  {
    name: 'obsidian_read',
    description: 'Read the full content of a note from the Obsidian vault by its file path.',
    inputSchema: {
      type: 'object',
      properties: {
        path: { type: 'string', description: 'File path relative to vault root (e.g. "projects/idea.md")' }
      },
      required: ['path']
    }
  },
  {
    name: 'obsidian_list',
    description: 'List files and directories in the Obsidian vault. Optionally provide a directory path to list its contents.',
    inputSchema: {
      type: 'object',
      properties: {
        dir: { type: 'string', description: 'Directory path (optional, defaults to vault root)' }
      }
    }
  },
  {
    name: 'obsidian_append',
    description: 'Append content to a note in the Obsidian vault. Creates the file if it does not exist.',
    inputSchema: {
      type: 'object',
      properties: {
        path: { type: 'string', description: 'File path relative to vault root' },
        content: { type: 'string', description: 'Markdown content to append' }
      },
      required: ['path', 'content']
    }
  },
  {
    name: 'obsidian_patch',
    description: 'Insert content into a note under a specific heading.',
    inputSchema: {
      type: 'object',
      properties: {
        path: { type: 'string', description: 'File path relative to vault root' },
        heading: { type: 'string', description: 'Heading to insert content under' },
        content: { type: 'string', description: 'Markdown content to insert' }
      },
      required: ['path', 'heading', 'content']
    }
  }
];

async function handleTool(name, args) {
  switch (name) {
    case 'obsidian_search': {
      const results = await omnisearch.search(args.query);
      return results.length === 0
        ? 'No results found.'
        : results.map(r => `**${r.path}**\n${r.excerpt}`).join('\n\n---\n\n');
    }
    case 'obsidian_read': {
      return await obsidian.readFile(args.path);
    }
    case 'obsidian_list': {
      const files = await obsidian.listFiles(args.dir || '');
      return files.join('\n');
    }
    case 'obsidian_append': {
      await obsidian.appendContent(args.path, args.content);
      return `Appended to ${args.path}`;
    }
    case 'obsidian_patch': {
      await obsidian.patchContent(args.path, args.heading, args.content);
      return `Patched ${args.path} under heading "${args.heading}"`;
    }
    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}

async function main() {
  if (!config.apiKey) {
    process.stderr.write(
      '[mcp-obsidian] OBSIDIAN_API_KEY is not set. Run /obsidian-setup to configure.\n'
    );
    process.exit(1);
  }

  const server = new Server(
    { name: 'mcp-obsidian-psc', version: '1.0.0' },
    { capabilities: { tools: {} } }
  );

  server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: TOOLS }));

  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;
    try {
      const text = await handleTool(name, args);
      return { content: [{ type: 'text', text }] };
    } catch (err) {
      return {
        content: [{ type: 'text', text: `Error: ${err.message}` }],
        isError: true
      };
    }
  });

  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch(err => {
  process.stderr.write(`[mcp-obsidian] Fatal: ${err.message}\n`);
  process.exit(1);
});
