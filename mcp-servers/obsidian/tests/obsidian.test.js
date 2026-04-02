'use strict';

const { ObsidianClient } = require('../src/obsidian');

const mockConfig = {
  host: '127.0.0.1',
  port: 27124,
  apiKey: 'test-api-key'
};

global.fetch = jest.fn();

beforeEach(() => {
  jest.clearAllMocks();
});

describe('ObsidianClient.listFiles', () => {
  it('lists files in vault root', async () => {
    global.fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ files: ['note1.md', 'folder/note2.md'] })
    });

    const client = new ObsidianClient(mockConfig);
    const result = await client.listFiles();

    expect(result).toEqual(['note1.md', 'folder/note2.md']);
    expect(global.fetch).toHaveBeenCalledWith(
      'https://127.0.0.1:27124/vault/',
      expect.objectContaining({
        headers: expect.objectContaining({ Authorization: 'Bearer test-api-key' })
      })
    );
  });

  it('lists files in a specific directory', async () => {
    global.fetch.mockResolvedValueOnce({
      ok: true,
      json: async () => ({ files: ['projects/todo.md'] })
    });

    const client = new ObsidianClient(mockConfig);
    const result = await client.listFiles('projects');

    expect(result).toEqual(['projects/todo.md']);
    expect(global.fetch).toHaveBeenCalledWith(
      'https://127.0.0.1:27124/vault/projects/',
      expect.any(Object)
    );
  });

  it('throws a clear error when Obsidian is not running', async () => {
    global.fetch.mockRejectedValueOnce(new TypeError('fetch failed'));

    const client = new ObsidianClient(mockConfig);
    await expect(client.listFiles()).rejects.toThrow('Obsidian is not running');
  });
});

describe('ObsidianClient.readFile', () => {
  it('returns file content as text', async () => {
    global.fetch.mockResolvedValueOnce({
      ok: true,
      text: async () => '# My Note\n\nHello world'
    });

    const client = new ObsidianClient(mockConfig);
    const content = await client.readFile('folder/note.md');

    expect(content).toBe('# My Note\n\nHello world');
    expect(global.fetch).toHaveBeenCalledWith(
      'https://127.0.0.1:27124/vault/folder/note.md',
      expect.any(Object)
    );
  });

  it('throws when file is not found', async () => {
    global.fetch.mockResolvedValueOnce({ ok: false, status: 404 });

    const client = new ObsidianClient(mockConfig);
    await expect(client.readFile('missing.md')).rejects.toThrow('404');
  });
});

describe('ObsidianClient.appendContent', () => {
  it('appends content to a file', async () => {
    global.fetch.mockResolvedValueOnce({ ok: true });

    const client = new ObsidianClient(mockConfig);
    await client.appendContent('note.md', '\n## New Section\nContent here');

    expect(global.fetch).toHaveBeenCalledWith(
      'https://127.0.0.1:27124/vault/note.md',
      expect.objectContaining({
        method: 'POST',
        body: '\n## New Section\nContent here'
      })
    );
  });
});

describe('ObsidianClient.patchContent', () => {
  it('inserts content under a heading', async () => {
    global.fetch.mockResolvedValueOnce({ ok: true });

    const client = new ObsidianClient(mockConfig);
    await client.patchContent('note.md', 'Tasks', '- New task');

    expect(global.fetch).toHaveBeenCalledWith(
      'https://127.0.0.1:27124/vault/note.md',
      expect.objectContaining({
        method: 'PATCH',
        headers: expect.objectContaining({ Heading: 'Tasks' })
      })
    );
  });
});
