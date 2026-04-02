'use strict';

class ObsidianClient {
  constructor({ host = '127.0.0.1', port = 27124, apiKey }) {
    this.baseUrl = `https://${host}:${port}`;
    this.apiKey = apiKey;
  }

  _headers(extra = {}) {
    return {
      Authorization: `Bearer ${this.apiKey}`,
      'Content-Type': 'text/markdown',
      ...extra
    };
  }

  async _fetch(path, options = {}) {
    const url = `${this.baseUrl}${path}`;
    try {
      const res = await fetch(url, {
        ...options,
        headers: { ...this._headers(), ...options.headers }
      });
      if (!res.ok) {
        throw new Error(`Obsidian API error: ${res.status} ${res.statusText} — ${url}`);
      }
      return res;
    } catch (err) {
      if (err.message.startsWith('Obsidian API error')) throw err;
      throw new Error(`Obsidian is not running or unreachable (${err.message})`);
    }
  }

  async listFiles(dir = '') {
    const path = `/vault/${dir ? dir.replace(/\/?$/, '/') : ''}`;
    const res = await this._fetch(path);
    const data = await res.json();
    return data.files;
  }

  async readFile(filePath) {
    const res = await this._fetch(`/vault/${filePath}`);
    return res.text();
  }

  async appendContent(filePath, content) {
    await this._fetch(`/vault/${filePath}`, {
      method: 'POST',
      body: content
    });
  }

  async patchContent(filePath, heading, content) {
    await this._fetch(`/vault/${filePath}`, {
      method: 'PATCH',
      headers: { Heading: heading },
      body: content
    });
  }
}

module.exports = { ObsidianClient };
