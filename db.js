const { Pool } = require('pg');

let pool;

const getPool = () => {
  if (!process.env.DATABASE_URL) {
    throw new Error('DATABASE_URL is required');
  }

  if (!pool) {
    pool = new Pool({ connectionString: process.env.DATABASE_URL });
  }

  return pool;
};

const initialize = async () => {
  await getPool().query(`
    CREATE TABLE IF NOT EXISTS tasks (
      id BIGSERIAL PRIMARY KEY,
      title TEXT NOT NULL CHECK (char_length(title) BETWEEN 1 AND 200),
      completed BOOLEAN NOT NULL DEFAULT FALSE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);
};

const listTasks = async () => {
  const result = await getPool().query(`
    SELECT id, title, completed, created_at AS "createdAt"
    FROM tasks
    ORDER BY created_at DESC, id DESC
  `);

  return result.rows;
};

const createTask = async (title) => {
  const result = await getPool().query(
    `
      INSERT INTO tasks (title)
      VALUES ($1)
      RETURNING id, title, completed, created_at AS "createdAt"
    `,
    [title],
  );

  return result.rows[0];
};

const close = () => pool?.end();

module.exports = {
  initialize,
  listTasks,
  createTask,
  close,
};
