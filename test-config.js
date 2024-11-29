const typoOutput = process.env.TYPO_OUTPUT;
const githubToken = process.env.GITHUB_TOKEN;
const owner = process.env.OWNER;
const repo = process.env.REPO;
const pullNumber = process.env.PULL_NUMBER;
const commitId = process.env.COMMIT_ID;
const body = process.env.BODY;
const filePath = process.env.PATH;
const position = process.env.POSITION;
const comment = process.env.COMMENT;

console.log(`typos: ${typos}`);
console.log(`GITHUB_TOKEN: ${githubToken}`);
console.log(`OWNER: ${owner}`);
console.log(`REPO: ${repo}`);
console.log(`PULL_NUMBER: ${pullNumber}`);
console.log(`COMMIT_ID: ${commitId}`);
console.log(`BODY: ${body}`);
console.log(`FILE PATH: ${filePath}`);
console.log(`POSITION: ${position}`);
console.log(`COMMENT: ${comment}`);


if (typoOutput) {
  console.log('typoOutput', typoOutput);
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
} else {
  console.log('No typos found.');
}