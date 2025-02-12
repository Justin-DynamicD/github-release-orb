# github-release-orb

[![CircleCI Build Status](https://circleci.com/gh/duffn/github-release-orb.svg?style=shield "CircleCI Build Status")](https://circleci.com/gh/duffn/github-release-orb) ![Orb Version Badge](https://badges.circleci.com/orbs/duffn/github-release.svg) [![GitHub License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/duffn/github-release-orb/master/LICENSE)

A CircleCI orb to automatically create releases for a GitHub repository.

## Usage

- Add the orb to your CircleCI `config.yml`.
  - Find the latest version in [the CircleCI orb registry](https://circleci.com/developer/orbs/orb/duffn/github-release).

```yaml
version: 2.1

orbs:
  github-release: duffn/github-release@0.1

jobs:
  release:
    docker:
      - image: cimg/base:stable
    steps:
      - checkout
      - github-release/release

workflows:
  release:
    jobs:
      - release:
          filters:
            branches:
              only:
                - main
```

- Specify `[semver:<major|minor|patch>]` in your commit message to trigger a new release.
  - The orb will extract the SemVer from your commit message and bump the GitHub version accordingly.
  - Add `[semver:skip]` to your commit message to skip publishing a release or just leave `[semver:<increment>]` out entirely.
    - Note that when merging a PR in GitHub, if you [squash](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-request-merges#squash-and-merge-your-pull-request-commits) your PR when merging, the title of your PR will the the title of your commit message! So, open your PR with a title like `[semver:minor] New minor release`, squash your PR when merging, and the orb will pick up that commit message and create a GitHub release.
- See the examples and documentation in [the CircleCI orb registry](https://circleci.com/developer/orbs/orb/duffn/github-release) for more.

## Setup

Use of this orb requires some additional setup.

- The orb requires [`curl`](https://curl.se/). Ensure that your Docker image or executor has `curl` installed.
- You must set the `GITHUB_TOKEN` environment variable.
  - This environment variable must have [permissions to create releases in your repository](https://github.com/settings/tokens/new?description=CircleCI%20GitHub%20token&scopes=repo).
