const githubToken = process.env.GITHUB_TOKEN;
const owner = process.env.OWNER;
const repo = process.env.REPO;
const pullNumber = process.env.PULL_NUMBER;
const commitId = process.env.COMMIT_ID;
const body = process.env.BODY;
const filePath = process.env.PATH;
const position = process.env.POSITION;
const comment = process.env.COMMENT;

console.log(`GITHUB_TOKEN: ${githubToken}`);
console.log(`OWNER: ${owner}`);
console.log(`REPO: ${repo}`);
console.log(`PULL_NUMBER: ${pullNumber}`);
console.log(`COMMIT_ID: ${commitId}`);
console.log(`BODY: ${body}`);
console.log(`FILE PATH: ${filePath}`);
console.log(`POSITION: ${position}`);
console.log(`COMMENT: ${comment}`);
