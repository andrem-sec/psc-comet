'use strict';

const { OmnisearchClient } = require('../src/omnisearch');

const mockConfig = { port: 51361 };

global.fetch = jest.fn();

beforeEach(() => {
  jest.clearAllMocks();
});

describe('OmnisearchClient.search', () => {
  it('returns search results with path and excerpt', async () => {
    global.fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => [
        { path: 'projects/idea.md', excerpt: 'A great idea about...', score: 0.9 },
        { path: 'daily/2024-01-01.md', excerpt: 'Today I worked on...', score: 0.7 }
      ]
    });

    const client = new OmnisearchClient(mockConfig);
    const results = await client.search('great idea');

    expect(results).toHaveLength(2);
    expect(results[0]).toMatchObject({ path: 'projects/idea.md', excerpt: expect.any(String) });
    expect(global.fetch).toHaveBeenCalledWith(
      'http://localhost:51361/search?q=great+idea',
      expect.any(Object)
    );
  });

  it('returns empty array when no results', async () => {
    global.fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => []
    });

    const client = new OmnisearchClient(mockConfig);
    const results = await client.search('xyzzy nonexistent');

    expect(results).toEqual([]);
  });

  it('throws a clear error when Omnisearch is not running', async () => {
    global.fetch.mockRejectedValueOnce(new TypeError('fetch failed'));

    const client = new OmnisearchClient(mockConfig);
    await expect(client.search('anything')).rejects.toThrow('Omnisearch is not running');
  });

  it('encodes the query in the URL', async () => {
    global.fetch.mockResolvedValueOnce({ ok: true, json: async () => [] });

    const client = new OmnisearchClient(mockConfig);
    await client.search('hello world & more');

    expect(global.fetch).toHaveBeenCalledWith(
      expect.stringContaining('hello+world'),
      expect.any(Object)
    );
  });
});
