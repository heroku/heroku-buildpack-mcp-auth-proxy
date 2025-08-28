import express from 'express';
import { randomUUID } from 'node:crypto';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import { isInitializeRequest } from '@modelcontextprotocol/sdk/types.js';

// Minimal Streamable HTTP MCP server for Option B deployments
// Endpoint: /mcp (POST for requests, GET for SSE notifications)

const app = express();
app.use(express.json());

// Keep active transports by session id
/** @type {Record<string, StreamableHTTPServerTransport>} */
const transports = {};

// Builds a fresh MCP server instance with a trivial tool
function buildServer() {
  const server = new McpServer({ name: 'sample-http-mcp', version: '0.1.0' });

  // Simple echo tool (JSON-Schema input)
  server.registerTool(
    'echo',
    {
      title: 'Echo',
      description: 'Echo back the provided message',
      inputSchema: {
        type: 'object',
        properties: { message: { type: 'string', description: 'Text to echo' } },
        required: ['message']
      }
    },
    async ({ message }) => ({ content: [{ type: 'text', text: message }] })
  );

  return server;
}

// POST /mcp: client → server JSON-RPC
app.post('/mcp', async (req, res) => {
  try {
    const sessionId = /** @type {string|undefined} */ (req.headers['mcp-session-id']);

    // Reuse existing transport for this session
    if (sessionId && transports[sessionId]) {
      const transport = transports[sessionId];
      await transport.handleRequest(req, res, req.body);
      return;
    }

    // New session initialization
    if (!sessionId && isInitializeRequest(req.body)) {
      const server = buildServer();
      const transport = new StreamableHTTPServerTransport({
        sessionIdGenerator: () => randomUUID()
      });

      // Connect and handle first request
      await server.connect(transport);
      await transport.handleRequest(req, res, req.body);

      // Persist transport after first request assigns session id
      if (transport.sessionId) {
        transports[transport.sessionId] = transport;
        transport.onclose = () => {
          if (transport.sessionId) delete transports[transport.sessionId];
        };
      }
      return;
    }

    // Invalid request
    res.status(400).json({
      jsonrpc: '2.0',
      error: { code: -32000, message: 'Bad Request: invalid session or body' },
      id: null
    });
  } catch (err) {
    // Avoid leaking internals
    res.status(500).json({
      jsonrpc: '2.0',
      error: { code: -32603, message: 'Internal server error' },
      id: null
    });
  }
});

// GET /mcp: optional SSE stream for server → client notifications
app.get('/mcp', async (req, res) => {
  const sessionId = /** @type {string|undefined} */ (req.headers['mcp-session-id']);
  if (!sessionId || !transports[sessionId]) {
    res.status(400).send('Invalid or missing session ID');
    return;
  }

  const transport = transports[sessionId];
  await transport.handleRequest(req, res);
});

const port = Number(process.env.PORT || 3000);
app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`HTTP MCP server listening on :${port}`);
});
