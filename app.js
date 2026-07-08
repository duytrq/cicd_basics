const express = require('express');
const database = require('./db');

// get the port from env variable
const PORT = process.env.PORT || 5001;

const GOAT = 'L. Messi';

const createApp = (taskStore = database) => {
  const app = express();

  app.use(express.json());
  app.use(express.static('dist'));

  app.get('/health', (req, res) => {
    res.send('ok');
  });

  app.get('/goat', (req, res) => {
    res.send(GOAT);
  });

  app.get('/tasks', async (req, res, next) => {
    try {
      res.json(await taskStore.listTasks());
    } catch (error) {
      next(error);
    }
  });

  app.post('/tasks', async (req, res, next) => {
    const title = typeof req.body.title === 'string' ? req.body.title.trim() : '';

    if (!title || title.length > 200) {
      return res.status(400).json({ error: 'title must contain 1 to 200 characters' });
    }

    try {
      return res.status(201).json(await taskStore.createTask(title));
    } catch (error) {
      return next(error);
    }
  });

  app.use((error, req, res, next) => {
    void next;
    console.error(error);
    res.status(500).json({ error: 'internal server error' });
  });

  return app;
};

const app = createApp();

const start = async () => {
  await database.initialize();
  app.listen(PORT, () => {
    console.log(`server started on port ${PORT}`);
  });
};

if (require.main === module) {
  start().catch((error) => {
    console.error('failed to start server', error);
    process.exitCode = 1;
  });
}

module.exports = app;
module.exports.createApp = createApp;
