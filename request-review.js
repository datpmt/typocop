const axios = require('axios');

// Validate environment variables
const githubToken = process.env.GITHUB_TOKEN;
if (!githubToken) {
  throw new Error('GitHub token is required');
}

const owner = process.env.OWNER;
if (!owner) {
  throw new Error('GitHub owner is required');
}

const repo = process.env.REPO;
if (!repo) {
  throw new Error('GitHub repository name is required');
}

const pullNumber = process.env.PULL_NUMBER;
if (!pullNumber) {
  throw new Error('GitHub pull request number is required');
}

const commitId = process.env.COMMIT_ID;
if (!commitId) {
  throw new Error('Commit ID is required');
}

const body = process.env.BODY;
if (!body) {
  throw new Error('Body is required');
}

const path = process.env.PATH;
if (!path) {
  throw new Error('Path is required');
}

const position = process.env.POSITION;
if (!position) {
  throw new Error('Position is required');
}


const comment = process.env.COMMENT;
if (!comment) {
  throw new Error('Comment is required');
}

async function sendPostRequest() {
  const url = `https://api.github.com/repos/${owner}/${repo}/pulls/${pullNumber}/reviews`;
  const headers = {
    Authorization: `token ${githubToken}`,
  };

  const data = {
    commit_id: commitId,
    body: body,
    event: 'REQUEST_CHANGES',
    comments: [
      {
        path: path,
        body: comment,
        side: 'RIGHT',
        position: position,
      }
    ]
  };

  console.log('Sending request with data:', data);

  try {
    const response = await axios.post(url, data, { headers });
    console.log('Response:', response.data);
  } catch (error) {
    if (error.response) {
      console.error('GitHub API Error:', error.response.status, error.response.data);
    } else if (error.request) {
      console.error('No response received:', error.request);
    } else {
      console.error('Error during POST request:', error.message);
    }
  }
}

sendPostRequest();
