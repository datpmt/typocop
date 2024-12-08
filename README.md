# Check Typos in Pull Request

![image](typocop.png)

This GitHub Action automatically checks for typos in the files changed in a pull request. It comments on the pull request with any detected typos and provides suggestions for corrections.

## Features

- Detects typos in files that are part of the pull request.
- Provides a brief output of typos found in each file.
- Comments on the pull request with the results.
- Approve the PR if no typos.
- Dismiss approvals on pull requests if new commit contains typo.
- Delete outdated typos comments.
- Supports all programing languages.

## Usage

- Copy file `.github/workflows/typocop.yml` into your project.
- Create new PR.

## Contributors

- Tran Dang Duc Dat [datpmt](https://github.com/datpmt)
- Hoang Duc Quan [BlazingRockStorm](https://github.com/BlazingRockStorm)

I welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b your-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin your-feature`).
5.  Create a new pull request.

## References
1. https://github.com/crate-ci/typos
2. https://github.com/prontolabs/pronto

## License
The gem is available as open source under the terms of the [MIT License](LICENSE).
