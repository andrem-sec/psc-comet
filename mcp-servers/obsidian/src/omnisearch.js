'use strict';

class OmnisearchClient {
  constructor({ port = 51361 } = {}) {
    this.baseUrl = `http://localhost:${port}`;
  }

  async search(query) {
    const url = `${this.baseUrl}/search?q=${encodeURIComponent(query).replace(/%20/g, '+')}`;
    let res;
    try {
      res = await fetch(url, { headers: { Accept: 'application/json' } });
    } catch (err) {
      throw new Error(`Omnisearch is not running or unreachable (${err.message})`);
    }
    if (!res.ok) {
      throw new Error(`Omnisearch error: ${res.status} ${res.statusText}`);
    }
    return res.json();
  }
}

module.exports = { OmnisearchClient };
