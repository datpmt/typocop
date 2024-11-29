const axios = require('axios');

export async function sendPostRequest({githubToken, owner, repo, pullNumber, commitId, body, path, comment, position }) {
  const url = `/repos/${owner}/${repo}/pulls/${pullNumber}/reviews`;

  const data = {
    commit_id: commitId,
    body,
    event: 'REQUEST_CHANGES',
    comments: [
      {
        path,
        body: comment,
        side: 'RIGHT',
        position,
      },
    ],
  };

  console.log('Sending request with data:', data);

  const axiosInstance = axios.create({
    baseURL: 'https://api.github.com',
    headers: { Authorization: `token ${githubToken}` },
  });

  try {
    const response = await axiosInstance.post(url, data);
    console.log('Response:', response.data);
    return response.data;  // Return response for further processing if needed
  } catch (error) {
    handleError(error);
  }
}

function handleError(error) {
  if (error.response) {
    // HTTP response error (e.g., 404, 500)
    console.error(`GitHub API Error: ${error.response.status}`, error.response.data);
  } else if (error.request) {
    // No response received
    console.error('No response received:', error.request);
  } else {
    // Other errors (e.g., setup issues)
    console.error('Error during POST request:', error.message);
  }
}
