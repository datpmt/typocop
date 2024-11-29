import { sendPostRequest } from 'request-review.js';

const typoOutput = process.env.TYPO_OUTPUT;
const githubToken = process.env.GITHUB_TOKEN;
const owner = process.env.OWNER;
const repo = process.env.REPO;
const pullNumber = process.env.PULL_NUMBER;
const commitId = process.env.COMMIT_ID;

console.log('typoOutput', typoOutput);
console.log(`GITHUB_TOKEN: ${githubToken}`);
console.log(`OWNER: ${owner}`);
console.log(`REPO: ${repo}`);
console.log(`PULL_NUMBER: ${pullNumber}`);
console.log(`COMMIT_ID: ${commitId}`);

if (typoOutput) {
  const typoArray = typoOutput.split('\n').map(line => line.trim()).filter(line => line);

  console.log('typoArray', typoArray);

  // Optionally, you could parse these lines into more structured objects
  const parsedTypos = typoArray.map(typo => {
    // Example of parsing each typo into a structured object
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
        owner,
        repo,
        pullNumber,
        commitId,
        body: 'This is a review comment.',
        path: typo.file,
        comment: 'Please check this code.',
        position: typo.line
      });

      console.log('response', response);
    }
  }
} else {
  console.log('No typos found.');
}