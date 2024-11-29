const axios = require('axios');

const typoOutput = process.env.TYPO_OUTPUT;
const githubToken = process.env.GITHUB_TOKEN;
const repo = process.env.REPO;
const pullNumber = process.env.PULL_NUMBER;
const commitId = process.env.COMMIT_ID;

console.log('typoOutput', typoOutput);
console.log(`GITHUB_TOKEN: ${githubToken}`);
console.log(`REPO: ${repo}`);
console.log(`PULL_NUMBER: ${pullNumber}`);
console.log(`COMMIT_ID: ${commitId}`);

async function sendPostRequest({ githubToken, repo, pullNumber, commitId, body, path, comment, line }) {
  const url = `https://api.github.com/repos/${repo}/pulls/${pullNumber}/reviews`;

  const data = {
    commit_id: commitId,
    body,
    event: 'REQUEST_CHANGES',
    threads: [
      {
        path,
        body: comment,
        side: 'RIGHT',
        line,
      },
    ],
  };

  console.log('Sending request with data:', data);

  const axiosInstance = axios.create({
    baseURL: 'https://api.github.com',
    headers: {
      Authorization: `Bearer ${githubToken}`, // Use 'Bearer' instead of 'token'
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',  // Include the required API version header
    },
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

async function processTypos() {
  if (typoOutput) {
    const typoArray = typoOutput.split('\n').map(line => line.trim()).filter(line => line);

    console.log('typoArray', typoArray);

    // Optionally, you could parse these lines into more structured objects
    const parsedTypos = typoArray.map(typo => {
      const [file, line, column, typoDetail] = typo.split(':');
      const typoMatch = typoDetail.match(/`(.*?)` -> `(.*?)`/);
      const [incorrectWord, correctWord] = typoMatch ? typoMatch.slice(1) : [];

      return {
        file: file.trim(),
        line: parseInt(line.trim(), 10),
        column: parseInt(column.trim(), 10),
        incorrectWord: incorrectWord.trim(),
        correctWord: correctWord.trim(),
      };
    });

    console.log('parsedTypos', parsedTypos);

    if (parsedTypos) {
      for (const typo of parsedTypos) {
        console.log(`File: ${typo.file}`);
        console.log(`Line: ${typo.line}`);
        console.log(`Column: ${typo.column}`);
        console.log(`Incorrect Word: ${typo.incorrectWord}`);
        console.log(`Correct Word: ${typo.correctWord}`);
        console.log('------------------------');

        const response = await sendPostRequest({
          githubToken,
          repo,
          pullNumber,
          commitId,
          body: 'This is a review comment.',
          path: typo.file,
          comment: `Please check this code. Replace '${typo.incorrectWord}' with '${typo.correctWord}'`,
          line: typo.line
        });

        console.log('response', response);
      }
    }
  } else {
    console.log('No typos found.');
  }
}

processTypos();
