const request = require('supertest');
const { createApp } = require('./app');

const taskStore = {
  listTasks: jest.fn(),
  createTask: jest.fn(),
};

const app = createApp(taskStore);

beforeEach(() => {
  jest.clearAllMocks();
});

describe('GET /health', () => {
  it('should return health check status', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.text).toBe('ok');
  });
});

describe('GET /', () => {
  it('serves the static task tracker UI', async () => {
    const res = await request(app).get('/');

    expect(res.status).toBe(200);
    expect(res.text).toContain('Task tracker');
  });
});

describe('GET /goat', () => {
  it('should return football GOAT', async () => {
    const res = await request(app).get('/goat');
    expect(res.status).toBe(200);
    expect(res.text).toBe('L. Messi');
  });
});

describe('GET /tasks', () => {
  it('returns tasks stored in PostgreSQL', async () => {
    const tasks = [{ id: '1', title: 'Deploy the demo app', completed: false }];
    taskStore.listTasks.mockResolvedValue(tasks);

    const res = await request(app).get('/tasks');

    expect(res.status).toBe(200);
    expect(res.body).toEqual(tasks);
  });
});

describe('POST /tasks', () => {
  it('creates a task', async () => {
    const task = { id: '1', title: 'Deploy the demo app', completed: false };
    taskStore.createTask.mockResolvedValue(task);

    const res = await request(app)
      .post('/tasks')
      .send({ title: '  Deploy the demo app  ' });

    expect(res.status).toBe(201);
    expect(res.body).toEqual(task);
    expect(taskStore.createTask).toHaveBeenCalledWith('Deploy the demo app');
  });

  it('rejects an empty title', async () => {
    const res = await request(app).post('/tasks').send({ title: '  ' });

    expect(res.status).toBe(400);
    expect(taskStore.createTask).not.toHaveBeenCalled();
  });
});
