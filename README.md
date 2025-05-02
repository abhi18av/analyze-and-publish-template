# Python Copier Template for Data Science

 [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ruff](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/ruff/main/assets/badge/v2.json)](https://github.com/astral-sh/ruff)
[![Copier](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/copier-org/copier/master/img/badge/badge-grayscale-inverted-border-orange.json)](https://github.com/copier-org/copier)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)

This is a template built with [Copier](https://github.com/copier-org/copier) to generate a data science focused python project.

Get started with the following command:

```shell
copier copy gh:abhi18av/analyzer-and-publish-template path/to/destination
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

### [uv](https://github.com/astral-sh/uv)

The repository is set up to use [uv](https://github.com/astral-sh/uv) for package or project management.
You may set up your python environment with

```shell
uv sync --all-groups --all-extras
```

### [Ruff](https://github.com/astral-sh/ruff)

The repository is configured to use [Ruff](https://github.com/astral-sh/ruff) for linting and formatting.
By default, all lints are enabled except

- [`COM`](https://docs.astral.sh/ruff/rules/#flake8-commas-com) Enforces trailing commas
- [`ERA`](https://docs.astral.sh/ruff/rules/#eradicate-era) Disallows commented-out code
- [`ISC001`](https://docs.astral.sh/ruff/rules/single-line-implicit-string-concatenation/#flake8-executable-exe) (conflicts with the formatter).

In addition, the following rules are only enforced for module code as they are inappropriate or too strict for unit tests and notebooks:

- [`D`](https://docs.astral.sh/ruff/rules/#pydocstyle-d) Requires docstrings on functions, classes and modules
- [`ANN`](https://docs.astral.sh/ruff/rules/#flake8-annotations-ann) Requires type annotations on functions and methods
- [`S101`](https://docs.astral.sh/ruff/rules/assert/) Disallows use of `assert`
- [`PLR2004`](https://docs.astral.sh/ruff/rules/magic-value-comparison/) Disallows "magic" values in comparisons
- [`T20`](https://docs.astral.sh/ruff/rules/#flake8-print-t20) Disallows print statements

The target line length is 120 and the docstring convention is google.

### [pre-commit](https://github.com/pre-commit/pre-commit)

pre-commit is a tool that runs checks on your files before you commit them with git, thereby helping ensure code quality.
Enable it with the following command:

```shell
pre-commit install --install-hooks
```

The configuration is stored in `.pre-commit-config.yaml`.

### [nbwipers](https://github.com/felixgwilliams/nbwipers)

`nbwipers` is a tool written in rust to ensure Jupyter notebooks are clean.
Committing notebooks that are not clean makes diffs more confusing, can degrade performance and increases the risk of leaking sensitive information.
You can set it up as a git filter with the following command.

```shell
nbwipers install local
```

### [pytest](https://docs.pytest.org/en/stable/)

The repository comes configured to use `pytest` for unit testing the module code.
Feel free to ignore it if you do not write module code.

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
