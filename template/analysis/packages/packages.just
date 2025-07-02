# Academic Package Development Automation
# Comprehensive tools for research package lifecycle management

# Set shell for cross-platform compatibility
set shell := ["bash", "-c"]

# Variables
project_name := "{{project_name}}"
author_name := "{{author_name}}"
author_email := "{{author_email}}"
python_version := "{{python_version|default('3.11')}}"

# Default recipe - show available commands
default:
    @echo "📦 Academic Package Development Commands:"
    @just --list

# === PACKAGE CREATION ===

# Create a new Python research package
create-python-package name description="Research package":
    #!/usr/bin/env bash
    package_dir="python/{{name}}"
    mkdir -p "${package_dir}"
    
    # Create package structure
    mkdir -p "${package_dir}/src/{{name}}"
    mkdir -p "${package_dir}/tests"
    mkdir -p "${package_dir}/docs"
    mkdir -p "${package_dir}/examples"
    
    # Generate pyproject.toml
    cat > "${package_dir}/pyproject.toml" << EOF
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "{{name}}"
version = "0.1.0"
description = "{{description}}"
authors = [{name = "{{author_name}}", email = "{{author_email}}"}]
readme = "README.md"
requires-python = ">={{python_version}}"
classifiers = [
    "Development Status :: 3 - Alpha",
    "Intended Audience :: Science/Research",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.{{python_version.split('.')[1]}}",
    "Topic :: Scientific/Engineering",
]
dependencies = [
    "numpy",
    "pandas",
    "scipy",
]

[project.optional-dependencies]
dev = [
    "pytest",
    "pytest-cov",
    "black",
    "isort",
    "flake8",
    "mypy",
]
docs = [
    "sphinx",
    "sphinx-rtd-theme",
    "myst-parser",
]
vis = [
    "matplotlib",
    "seaborn",
    "plotly",
]

[project.urls]
"Homepage" = "https://github.com/{{author_name}}/{{name}}"
"Bug Reports" = "https://github.com/{{author_name}}/{{name}}/issues"
"Source" = "https://github.com/{{author_name}}/{{name}}"

[tool.setuptools.packages.find]
where = ["src"]

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]

[tool.black]
line-length = 88
target-version = ['py{{python_version.replace('.', '')}}]

[tool.isort]
profile = "black"
line_length = 88
EOF
    
    # Create main module
    cat > "${package_dir}/src/{{name}}/__init__.py" << EOF
"""{{description}}

A research package developed as part of {{project_name}}.
"""

__version__ = "0.1.0"
__author__ = "{{author_name}}"
__email__ = "{{author_email}}"

from .core import *
from .utils import *

__all__ = [
    "__version__",
    "__author__", 
    "__email__",
]
EOF
    
    # Create core module
    cat > "${package_dir}/src/{{name}}/core.py" << EOF
"""Core functionality for {{name}} package."""

import numpy as np
import pandas as pd
from typing import Union, Optional, Tuple, List


class ResearchComponent:
    """Base class for research components.
    
    This class provides a foundation for implementing
    research algorithms and methods with consistent
    interfaces and documentation.
    """
    
    def __init__(self, name: str, **kwargs):
        """Initialize research component.
        
        Args:
            name: Name of the component
            **kwargs: Additional configuration parameters
        """
        self.name = name
        self.config = kwargs
        self._fitted = False
    
    def fit(self, data: Union[np.ndarray, pd.DataFrame]):
        """Fit the component to data.
        
        Args:
            data: Input data for fitting
            
        Returns:
            self: Fitted component
        """
        # Implement fitting logic here
        self._fitted = True
        return self
    
    def transform(self, data: Union[np.ndarray, pd.DataFrame]):
        """Transform data using fitted component.
        
        Args:
            data: Input data for transformation
            
        Returns:
            Transformed data
        """
        if not self._fitted:
            raise ValueError("Component must be fitted before transform")
        
        # Implement transformation logic here
        return data
    
    def fit_transform(self, data: Union[np.ndarray, pd.DataFrame]):
        """Fit component and transform data.
        
        Args:
            data: Input data
            
        Returns:
            Transformed data
        """
        return self.fit(data).transform(data)


def research_function(data: Union[np.ndarray, pd.DataFrame], 
                     parameter: float = 1.0) -> Union[np.ndarray, pd.DataFrame]:
    """Example research function.
    
    This function demonstrates the structure for implementing
    research algorithms with proper documentation and type hints.
    
    Args:
        data: Input data for analysis
        parameter: Research parameter (default: 1.0)
        
    Returns:
        Processed research results
        
    Examples:
        >>> import numpy as np
        >>> data = np.random.rand(100, 5)
        >>> result = research_function(data, parameter=2.0)
        >>> result.shape
        (100, 5)
    """
    # Implement research algorithm here
    if isinstance(data, pd.DataFrame):
        return data * parameter
    elif isinstance(data, np.ndarray):
        return data * parameter
    else:
        raise TypeError("Data must be numpy array or pandas DataFrame")
EOF
    
    # Create utils module
    cat > "${package_dir}/src/{{name}}/utils.py" << EOF
"""Utility functions for {{name}} package."""

import numpy as np
import pandas as pd
from pathlib import Path
from typing import Union, Dict, Any
import json


def load_research_data(filepath: Union[str, Path]) -> pd.DataFrame:
    """Load research data from various formats.
    
    Args:
        filepath: Path to data file
        
    Returns:
        Loaded data as DataFrame
    """
    filepath = Path(filepath)
    
    if filepath.suffix == '.csv':
        return pd.read_csv(filepath)
    elif filepath.suffix == '.json':
        return pd.read_json(filepath)
    elif filepath.suffix == '.parquet':
        return pd.read_parquet(filepath)
    else:
        raise ValueError(f"Unsupported file format: {filepath.suffix}")


def save_research_results(data: pd.DataFrame, 
                         filepath: Union[str, Path],
                         metadata: Dict[str, Any] = None):
    """Save research results with metadata.
    
    Args:
        data: Results data to save
        filepath: Output file path
        metadata: Optional metadata dictionary
    """
    filepath = Path(filepath)
    
    # Save data
    if filepath.suffix == '.csv':
        data.to_csv(filepath, index=False)
    elif filepath.suffix == '.parquet':
        data.to_parquet(filepath, index=False)
    else:
        raise ValueError(f"Unsupported output format: {filepath.suffix}")
    
    # Save metadata if provided
    if metadata:
        metadata_file = filepath.with_suffix('.json')
        with open(metadata_file, 'w') as f:
            json.dump(metadata, f, indent=2)


def validate_research_data(data: pd.DataFrame) -> Dict[str, Any]:
    """Validate research data quality.
    
    Args:
        data: Data to validate
        
    Returns:
        Validation report dictionary
    """
    report = {
        'shape': data.shape,
        'missing_values': data.isnull().sum().to_dict(),
        'data_types': data.dtypes.to_dict(),
        'duplicates': data.duplicated().sum(),
        'memory_usage': data.memory_usage(deep=True).sum(),
    }
    
    return report
EOF
    
    # Create test file
    cat > "${package_dir}/tests/test_core.py" << EOF
"""Tests for {{name}} core functionality."""

import pytest
import numpy as np
import pandas as pd
from {{name}}.core import ResearchComponent, research_function


class TestResearchComponent:
    """Test cases for ResearchComponent class."""
    
    def test_initialization(self):
        """Test component initialization."""
        component = ResearchComponent("test")
        assert component.name == "test"
        assert not component._fitted
    
    def test_fit_transform(self):
        """Test fit and transform methods."""
        component = ResearchComponent("test")
        data = np.random.rand(10, 3)
        
        # Test fit
        result = component.fit(data)
        assert result is component
        assert component._fitted
        
        # Test transform
        transformed = component.transform(data)
        assert transformed is not None
    
    def test_fit_transform_combined(self):
        """Test combined fit_transform method."""
        component = ResearchComponent("test")
        data = np.random.rand(10, 3)
        
        result = component.fit_transform(data)
        assert result is not None
        assert component._fitted


class TestResearchFunction:
    """Test cases for research functions."""
    
    def test_numpy_input(self):
        """Test function with numpy input."""
        data = np.random.rand(5, 3)
        result = research_function(data, parameter=2.0)
        
        assert isinstance(result, np.ndarray)
        assert result.shape == data.shape
        np.testing.assert_array_equal(result, data * 2.0)
    
    def test_pandas_input(self):
        """Test function with pandas input."""
        data = pd.DataFrame(np.random.rand(5, 3))
        result = research_function(data, parameter=3.0)
        
        assert isinstance(result, pd.DataFrame)
        assert result.shape == data.shape
        pd.testing.assert_frame_equal(result, data * 3.0)
    
    def test_invalid_input(self):
        """Test function with invalid input."""
        with pytest.raises(TypeError):
            research_function([1, 2, 3])
EOF
    
    # Create README
    cat > "${package_dir}/README.md" << EOF
# {{name}}

{{description}}

## Installation

```bash
pip install -e .
```

## Development Installation

```bash
pip install -e ".[dev]"
```

## Usage

```python
import {{name}}

# Example usage
component = {{name}}.ResearchComponent("example")
result = {{name}}.research_function(data)
```

## Testing

```bash
pytest
```

## Documentation

Documentation is available in the `docs/` directory.

## Citation

If you use this package in your research, please cite:

```bibtex
@software{{{name}_{{year}},
    title = {{{{{name}}}: {{description}}},
    author = {{{{{author_name}}}}},
    year = {{{{year}}}},
    url = {{https://github.com/{{author_name}}/{{name}}}}
}
```

## License

MIT License - see LICENSE file for details.
EOF
    
    echo "📦 Created Python package: ${package_dir}"
    echo "📝 To get started:"
    echo "   cd ${package_dir}"
    echo "   pip install -e '.[dev]'"
    echo "   pytest"

# Create a new R package
create-r-package name description="Research R package":
    #!/usr/bin/env bash
    package_dir="r/{{name}}"
    mkdir -p "${package_dir}"
    
    # Create R package structure
    mkdir -p "${package_dir}/R"
    mkdir -p "${package_dir}/man"
    mkdir -p "${package_dir}/tests/testthat"
    mkdir -p "${package_dir}/vignettes"
    mkdir -p "${package_dir}/data"
    
    # Generate DESCRIPTION file
    cat > "${package_dir}/DESCRIPTION" << EOF
Package: {{name}}
Type: Package
Title: {{description}}
Version: 0.1.0
Author: {{author_name}} <{{author_email}}>
Maintainer: {{author_name}} <{{author_email}}>
Description: {{description}} developed as part of {{project_name}} research.
License: MIT + file LICENSE
Encoding: UTF-8
LazyData: true
RoxygenNote: 7.2.3
Depends: 
    R (>= 4.1.0)
Imports:
    dplyr,
    ggplot2,
    tibble
Suggests:
    testthat (>= 3.0.0),
    knitr,
    rmarkdown
VignetteBuilder: knitr
EOF
    
    # Create main R functions
    cat > "${package_dir}/R/{{name}}.R" << EOF
#' {{description}}
#'
#' @docType package
#' @name {{name}}
#' @import dplyr
#' @import ggplot2
NULL

#' Research Function
#'
#' This function performs research analysis on the provided data.
#'
#' @param data A data frame containing the research data
#' @param parameter A numeric parameter for the analysis (default: 1.0)
#' @return A processed data frame with research results
#' @export
#' @examples
#' data <- data.frame(x = 1:10, y = rnorm(10))
#' result <- research_function(data, parameter = 2.0)
research_function <- function(data, parameter = 1.0) {
  if (!is.data.frame(data)) {
    stop("Input must be a data frame")
  }
  
  # Implement research logic here
  result <- data %>%
    mutate(across(where(is.numeric), ~ .x * parameter))
  
  return(result)
}

#' Validate Research Data
#'
#' This function validates the quality of research data.
#'
#' @param data A data frame to validate
#' @return A list containing validation results
#' @export
validate_data <- function(data) {
  list(
    nrows = nrow(data),
    ncols = ncol(data),
    missing_values = sapply(data, function(x) sum(is.na(x))),
    data_types = sapply(data, class)
  )
}
EOF
    
    # Create test file
    cat > "${package_dir}/tests/testthat/test-{{name}}.R" << EOF
library(testthat)
library({{name}})

test_that("research_function works correctly", {
  data <- data.frame(x = 1:5, y = 6:10)
  result <- research_function(data, parameter = 2)
  
  expect_equal(result$x, c(2, 4, 6, 8, 10))
  expect_equal(result$y, c(12, 14, 16, 18, 20))
})

test_that("validate_data returns correct structure", {
  data <- data.frame(x = 1:5, y = letters[1:5])
  validation <- validate_data(data)
  
  expect_equal(validation$nrows, 5)
  expect_equal(validation$ncols, 2)
  expect_named(validation, c("nrows", "ncols", "missing_values", "data_types"))
})
EOF
    
    # Create README
    cat > "${package_dir}/README.md" << EOF
# {{name}}

{{description}}

## Installation

```r
# Install from source
devtools::install(".")

# Or install with dependencies
devtools::install(".", dependencies = TRUE)
```

## Usage

```r
library({{name}})

# Example usage
data <- data.frame(x = 1:10, y = rnorm(10))
result <- research_function(data, parameter = 2.0)
```

## Development

```r
# Load package for development
devtools::load_all()

# Run tests
devtools::test()

# Generate documentation
devtools::document()
```

## Citation

If you use this package in your research, please cite:

```
{{author_name}} ({{year}}). {{name}}: {{description}}. 
R package version 0.1.0. https://github.com/{{author_name}}/{{name}}
```
EOF
    
    echo "📦 Created R package: ${package_dir}"
    echo "📝 To get started:"
    echo "   cd ${package_dir}"
    echo "   R -e 'devtools::load_all()'"
    echo "   R -e 'devtools::test()'"

# Create a CLI tool package
create-cli-tool name description="Research CLI tool":
    #!/usr/bin/env bash
    tool_dir="tools/cli/{{name}}"
    mkdir -p "${tool_dir}"
    
    # Create CLI tool structure
    cat > "${tool_dir}/{{name}}.py" << EOF
#!/usr/bin/env python3
"""{{description}}

A command-line tool for research workflows.
"""

import argparse
import sys
from pathlib import Path
import pandas as pd
import json


def main():
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(
        description="{{description}}",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        "input",
        type=str,
        help="Input file or data"
    )
    
    parser.add_argument(
        "-o", "--output",
        type=str,
        help="Output file (default: stdout)"
    )
    
    parser.add_argument(
        "-p", "--parameter",
        type=float,
        default=1.0,
        help="Analysis parameter (default: 1.0)"
    )
    
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Enable verbose output"
    )
    
    parser.add_argument(
        "--version",
        action="version",
        version="{{name}} 0.1.0"
    )
    
    args = parser.parse_args()
    
    try:
        # Load input data
        if args.verbose:
            print(f"Loading data from: {args.input}", file=sys.stderr)
        
        input_path = Path(args.input)
        if not input_path.exists():
            print(f"Error: Input file not found: {args.input}", file=sys.stderr)
            sys.exit(1)
        
        # Process based on file type
        if input_path.suffix == '.csv':
            data = pd.read_csv(input_path)
        elif input_path.suffix == '.json':
            data = pd.read_json(input_path)
        else:
            print(f"Error: Unsupported file type: {input_path.suffix}", file=sys.stderr)
            sys.exit(1)
        
        # Perform analysis
        if args.verbose:
            print(f"Processing {len(data)} rows with parameter {args.parameter}", file=sys.stderr)
        
        # Example processing - replace with actual research logic
        result = data.copy()
        numeric_cols = result.select_dtypes(include=['number']).columns
        result[numeric_cols] *= args.parameter
        
        # Output results
        if args.output:
            output_path = Path(args.output)
            if output_path.suffix == '.csv':
                result.to_csv(output_path, index=False)
            elif output_path.suffix == '.json':
                result.to_json(output_path, orient='records', indent=2)
            else:
                print(f"Error: Unsupported output type: {output_path.suffix}", file=sys.stderr)
                sys.exit(1)
            
            if args.verbose:
                print(f"Results saved to: {args.output}", file=sys.stderr)
        else:
            # Output to stdout
            print(result.to_csv(index=False))
    
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
EOF
    
    # Make executable
    chmod +x "${tool_dir}/{{name}}.py"
    
    # Create test script
    cat > "${tool_dir}/test_{{name}}.py" << EOF
#!/usr/bin/env python3
"""Tests for {{name}} CLI tool."""

import subprocess
import tempfile
import pandas as pd
from pathlib import Path


def test_cli_basic():
    """Test basic CLI functionality."""
    # Create test data
    test_data = pd.DataFrame({
        'x': [1, 2, 3],
        'y': [4, 5, 6]
    })
    
    with tempfile.NamedTemporaryFile(mode='w', suffix='.csv', delete=False) as f:
        test_data.to_csv(f.name, index=False)
        
        # Run CLI tool
        result = subprocess.run([
            'python3', '{{name}}.py', f.name, '--parameter', '2.0'
        ], capture_output=True, text=True)
        
        assert result.returncode == 0
        
        # Parse output
        output_data = pd.read_csv(pd.StringIO(result.stdout))
        expected = test_data * 2.0
        
        pd.testing.assert_frame_equal(output_data, expected)
    
    # Clean up
    Path(f.name).unlink()


if __name__ == "__main__":
    test_cli_basic()
    print("All tests passed!")
EOF
    
    chmod +x "${tool_dir}/test_{{name}}.py"
    
    # Create README
    cat > "${tool_dir}/README.md" << EOF
# {{name}}

{{description}}

## Usage

```bash
# Basic usage
./{{name}}.py input.csv

# With output file
./{{name}}.py input.csv -o output.csv

# With custom parameter
./{{name}}.py input.csv --parameter 2.5

# Verbose mode
./{{name}}.py input.csv -v
```

## Options

- `-o, --output`: Output file (default: stdout)
- `-p, --parameter`: Analysis parameter (default: 1.0)
- `-v, --verbose`: Enable verbose output
- `--version`: Show version information

## Testing

```bash
python3 test_{{name}}.py
```
EOF
    
    echo "🔧 Created CLI tool: ${tool_dir}"
    echo "📝 To test:"
    echo "   cd ${tool_dir}"
    echo "   python3 test_{{name}}.py"

# === PACKAGE MANAGEMENT ===

# List all packages
list-packages:
    @echo "📦 Available Packages:"
    @echo "Python Packages:"
    @find python -maxdepth 1 -type d ! -name python ! -name __pycache__ ! -name experimental | sed 's/python\///g' | grep -v '^$' | sort
    @echo ""
    @echo "R Packages:"
    @find r -maxdepth 1 -type d ! -name r ! -name experimental 2>/dev/null | sed 's/r\///g' | grep -v '^$' | sort || echo "No R packages found"
    @echo ""
    @echo "CLI Tools:"
    @find tools/cli -maxdepth 1 -type d ! -name cli 2>/dev/null | sed 's/tools\/cli\///g' | grep -v '^$' | sort || echo "No CLI tools found"

# Install a Python package in development mode
install-python package:
    #!/usr/bin/env bash
    if [ -d "python/{{package}}" ]; then
        cd "python/{{package}}"
        pip install -e ".[dev]"
        echo "✅ Installed {{package}} in development mode"
    else
        echo "❌ Package not found: python/{{package}}"
        exit 1
    fi

# Test a Python package
test-python package:
    #!/usr/bin/env bash
    if [ -d "python/{{package}}" ]; then
        cd "python/{{package}}"
        python -m pytest tests/ -v
    else
        echo "❌ Package not found: python/{{package}}"
        exit 1
    fi

# Test an R package
test-r package:
    #!/usr/bin/env bash
    if [ -d "r/{{package}}" ]; then
        cd "r/{{package}}"
        R -e "devtools::test()"
    else
        echo "❌ Package not found: r/{{package}}"
        exit 1
    fi

# Build Python package distribution
build-python package:
    #!/usr/bin/env bash
    if [ -d "python/{{package}}" ]; then
        cd "python/{{package}}"
        python -m build
        echo "✅ Built distribution for {{package}}"
        echo "📦 Files in dist/:"
        ls -la dist/
    else
        echo "❌ Package not found: python/{{package}}"
        exit 1
    fi

# === VALIDATION AND QUALITY ===

# Validate package structure
validate-package type package:
    #!/usr/bin/env bash
    package_dir="{{type}}/{{package}}"
    
    if [ ! -d "${package_dir}" ]; then
        echo "❌ Package not found: ${package_dir}"
        exit 1
    fi
    
    echo "🔍 Validating {{package}} ({{type}})..."
    
    if [ "{{type}}" = "python" ]; then
        # Python package validation
        required_files=("pyproject.toml" "README.md" "src" "tests")
        for file in "${required_files[@]}"; do
            if [ -e "${package_dir}/${file}" ]; then
                echo "✅ ${file}"
            else
                echo "❌ Missing: ${file}"
            fi
        done
        
        # Check for common Python issues
        cd "${package_dir}"
        if command -v black &> /dev/null; then
            echo "🔧 Checking code formatting..."
            black --check src/ || echo "⚠️ Code formatting issues found"
        fi
        
        if command -v flake8 &> /dev/null; then
            echo "🔧 Checking code style..."
            flake8 src/ || echo "⚠️ Code style issues found"
        fi
        
    elif [ "{{type}}" = "r" ]; then
        # R package validation
        required_files=("DESCRIPTION" "README.md" "R" "tests")
        for file in "${required_files[@]}"; do
            if [ -e "${package_dir}/${file}" ]; then
                echo "✅ ${file}"
            else
                echo "❌ Missing: ${file}"
            fi
        done
    fi
    
    echo "✅ Validation complete for {{package}}"

# Run comprehensive tests for all packages
test-all:
    @echo "🧪 Running tests for all packages..."
    @for pkg in $(find python -maxdepth 1 -type d ! -name python ! -name experimental | sed 's/python\///'); do \
        if [ -n "$pkg" ]; then \
            echo "Testing Python package: $pkg"; \
            just test-python "$pkg" || echo "❌ Tests failed for $pkg"; \
        fi \
    done
    @for pkg in $(find r -maxdepth 1 -type d ! -name r ! -name experimental 2>/dev/null | sed 's/r\///'); do \
        if [ -n "$pkg" ]; then \
            echo "Testing R package: $pkg"; \
            just test-r "$pkg" || echo "❌ Tests failed for $pkg"; \
        fi \
    done

# === DOCUMENTATION ===

# Generate documentation for Python package
docs-python package:
    #!/usr/bin/env bash
    if [ -d "python/{{package}}" ]; then
        cd "python/{{package}}"
        
        if [ -d "docs" ]; then
            cd docs
            make html
            echo "📚 Documentation built for {{package}}"
            echo "Open: docs/_build/html/index.html"
        else
            echo "⚠️ No docs directory found. Creating basic documentation..."
            mkdir -p docs
            cd docs
            sphinx-quickstart -q -p "{{package}}" -a "{{author_name}}" --ext-autodoc --ext-viewcode .
            echo "📚 Basic documentation structure created"
        fi
    else
        echo "❌ Package not found: python/{{package}}"
        exit 1
    fi

# === DISTRIBUTION ===

# Create distribution package for PyPI
dist-pypi package:
    #!/usr/bin/env bash
    if [ -d "python/{{package}}" ]; then
        cd "python/{{package}}"
        
        # Clean previous builds
        rm -rf dist/ build/ *.egg-info/
        
        # Build distribution
        python -m build
        
        # Check distribution
        python -m twine check dist/*
        
        echo "📦 Distribution ready for {{package}}"
        echo "📝 To upload to PyPI:"
        echo "   twine upload dist/*"
        echo "📝 To upload to Test PyPI:"
        echo "   twine upload --repository testpypi dist/*"
    else
        echo "❌ Package not found: python/{{package}}"
        exit 1
    fi

# Create conda package
dist-conda package:
    #!/usr/bin/env bash
    if [ -d "python/{{package}}" ]; then
        echo "🏗️ Creating conda package for {{package}}..."
        
        # Create conda-build directory structure
        mkdir -p "distribution/conda/{{package}}"
        
        # Generate meta.yaml
        cat > "distribution/conda/{{package}}/meta.yaml" << EOF
{% set name = "{{package}}" %}
{% set version = "0.1.0" %}

package:
  name: {{ name|lower }}
  version: {{ version }}

source:
  path: ../../python/{{package}}

build:
  number: 0
  script: python -m pip install . -vv
  noarch: python

requirements:
  host:
    - python >=3.8
    - pip
    - setuptools
  run:
    - python >=3.8
    - numpy
    - pandas
    - scipy

test:
  imports:
    - {{package}}
  commands:
    - python -c "import {{package}}; print({{package}}.__version__)"

about:
  home: https://github.com/{{author_name}}/{{package}}
  license: MIT
  license_family: MIT
  license_file: LICENSE
  summary: {{description}}
  description: |
    {{description}} developed as part of {{project_name}} research.
  dev_url: https://github.com/{{author_name}}/{{package}}

extra:
  recipe-maintainers:
    - {{author_name}}
EOF
        
        echo "📦 Conda recipe created at distribution/conda/{{package}}/"
        echo "📝 To build:"
        echo "   conda-build distribution/conda/{{package}}/"
    else
        echo "❌ Package not found: python/{{package}}"
        exit 1
    fi

# === LEGACY COMMANDS (for backward compatibility) ===

# Compile a Zig file (legacy)
zig-build file:
    #!/usr/bin/env bash
    if command -v zig &> /dev/null; then
        zig build-exe zig/{{file}}.zig -O ReleaseSafe -femit-bin=../pbin/{{file}}
        echo "🔧 Compiled {{file}} to ../pbin/{{file}}"
    else
        echo "❌ Zig compiler not found"
        exit 1
    fi

# Run a compiled Zig binary (legacy)
zig-run file:
    #!/usr/bin/env bash
    if [ -f "../pbin/{{file}}" ]; then
        ../pbin/{{file}}
    else
        echo "❌ Binary not found: ../pbin/{{file}}"
        echo "💡 Try: just zig-build {{file}}"
        exit 1
    fi
