# Python Copier Template for Data Science

TODO @abhi18av:
- git-submodules for various sun templates
- mlflow

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Copier](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/copier-org/copier/master/img/badge/badge-grayscale-inverted-border-orange.json)](https://github.com/copier-org/copier)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)

This is a template built with [Copier](https://github.com/copier-org/copier) to generate a data science focused python project.

Get started with the following command:

```shell
copier copy gh:abhi18av/template-analyze-and-publish path/to/destination
```

## Features

### Project structure

It is assumed that most of the work will be done in Jupyter Notebooks.
However, the template also includes a python project, in which you can put functions and classes shared across notebooks.
The repository is set up to use [Pytest](https://docs.pytest.org/en/stable/) for unit testing this module code.

The template also includes a `data` directory whose contents will be ignored by git.
You can use this folder to store data that you do not commit.
You may also put a readme file in which you can document the source datasets you use and how to acquire them.

### [just](https://github.com/casey/just)

`just` is a command runner that allows you to easily to run project-specific commands.
In fact, you can use `just` to run all the setup commands listed below:

```shell
just setup
```

### [pre-commit](https://github.com/pre-commit/pre-commit)

pre-commit is a tool that runs checks on your files before you commit them with git, thereby helping ensure code quality.
Enable it with the following command:

```shell
pre-commit install --install-hooks
```

The configuration is stored in `.pre-commit-config.yaml`.

### Github Actions

You may optionally add a github workflow file which checks the following:

- uses ruff to check files are formatted and linted
- Runs unit tests and checks coverage
- Checks any markdown files are formatted with [markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2)
- Checks that all jupyter notebooks are clean

### [Typos](https://github.com/crate-ci/typos)

Typos checks for common typos in code, aiming for a low false positive rate.
The repository is configured not to use it for Jupyter notebook files, as it tends to find errors in cell outputs.

Test with [Copier](https://github.com/copier-org/copier) and [copier-template-tester](https://github.com/KyleKing/copier-template-tester).
