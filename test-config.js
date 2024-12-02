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

async function sendPostRequest({ body, path, line }) {
  const url = `https://api.github.com/repos/${repo}/pulls/${pullNumber}/comments`;

  console.log('url', url);

  const data = {
    side: 'RIGHT',
    commit_id: commitId,
    body,
    path,
    line
  };

  console.log('Sending request with data:', data);

  const axiosInstance = axios.create({
    baseURL: 'https://api.github.com',
    headers: {
      Authorization: `Bearer ${githubToken}`,
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    },
  });

  try {
    const response = await axiosInstance.post(url, data);
    console.log('Response:', response.data);
    return response.data;
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
        const response = await sendPostRequest({
          body: `Please check this code. Replace '${typo.incorrectWord}' with '${typo.correctWord}'`,
          path: typo.file,
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
