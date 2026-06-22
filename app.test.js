const request = require('supertest');
const app = require('./app');

describe('GET /health', () => {
  it('should return health check status', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.text).toBe('ok');
  });
});

describe('GET /goat', () => {
  it('should return football GOAT', async () => {
    const res = await request(app).get('/goat');
    expect(res.status).toBe(200);
    expect(res.text).toBe('L. Messi');
  });
});
