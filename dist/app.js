const form = document.querySelector('#task-form');
const input = document.querySelector('#task-title');
const list = document.querySelector('#tasks');
const status = document.querySelector('#status');

const setStatus = (message, isError = false) => {
  status.textContent = message;
  status.classList.toggle('error', isError);
};

const formatDate = (value) => {
  if (!value) {
    return 'No timestamp';
  }

  return new Intl.DateTimeFormat(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value));
};

const renderTasks = (tasks) => {
  list.replaceChildren();

  if (tasks.length === 0) {
    setStatus('No tasks yet.');
    return;
  }

  setStatus(`${tasks.length} task${tasks.length === 1 ? '' : 's'} loaded.`);

  tasks.forEach((task) => {
    const item = document.createElement('li');
    item.className = 'task';

    const title = document.createElement('div');
    title.className = 'task-title';
    title.textContent = task.title;

    const meta = document.createElement('div');
    meta.className = 'task-meta';
    meta.textContent = `Created ${formatDate(task.createdAt)}`;

    item.append(title, meta);
    list.append(item);
  });
};

const loadTasks = async () => {
  setStatus('Loading tasks...');

  try {
    const response = await fetch('/tasks');

    if (!response.ok) {
      throw new Error(`Request failed with ${response.status}`);
    }

    renderTasks(await response.json());
  } catch (error) {
    setStatus(`Unable to load tasks: ${error.message}`, true);
  }
};

form.addEventListener('submit', async (event) => {
  event.preventDefault();

  const title = input.value.trim();

  if (!title) {
    setStatus('Enter a task title first.', true);
    input.focus();
    return;
  }

  try {
    const response = await fetch('/tasks', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ title }),
    });

    if (!response.ok) {
      throw new Error(`Request failed with ${response.status}`);
    }

    input.value = '';
    await loadTasks();
  } catch (error) {
    setStatus(`Unable to create task: ${error.message}`, true);
  }
});

loadTasks();

