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

# Create a PowerShell module
create-powershell-module name description="Research PowerShell module":
    #!/usr/bin/env bash
    module_dir="powershell/{{name}}"
    mkdir -p "${module_dir}"
    
    # Create PowerShell module structure
    mkdir -p "${module_dir}/Public"
    mkdir -p "${module_dir}/Private"
    mkdir -p "${module_dir}/Tests"
    mkdir -p "${module_dir}/en-US"
    mkdir -p "${module_dir}/Docs"
    
    # Generate module manifest
    cat > "${module_dir}/{{name}}.psd1" << 'EOF'
@{
    RootModule = '{{name}}.psm1'
    ModuleVersion = '0.1.0'
    GUID = '{{guid}}'
    Author = '{{author_name}}'
    CompanyName = '{{project_name}}'
    Copyright = '(c) {{year}} {{author_name}}. All rights reserved.'
    Description = '{{description}}'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('*')
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Research', 'DataScience', 'Academic')
            LicenseUri = 'https://github.com/{{author_name}}/{{name}}/blob/main/LICENSE'
            ProjectUri = 'https://github.com/{{author_name}}/{{name}}'
            ReleaseNotes = 'Initial release'
        }
    }
}
EOF
    
    # Generate module file
    cat > "${module_dir}/{{name}}.psm1" << 'EOF'
<#
.SYNOPSIS
    {{description}}
    
.DESCRIPTION
    A PowerShell module for research workflows developed as part of {{project_name}}.
    
.AUTHOR
    {{author_name}}
    
.VERSION
    0.1.0
#>

# Get public and private function definition files
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files
foreach ($import in @($Public + $Private)) {
    try {
        Write-Verbose "Importing $($import.FullName)"
        . $import.FullName
    }
    catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

# Export only the public functions
Export-ModuleMember -Function $Public.BaseName
EOF
    
    # Create main research function
    cat > "${module_dir}/Public/Invoke-ResearchAnalysis.ps1" << 'EOF'
function Invoke-ResearchAnalysis {
    <#
    .SYNOPSIS
        Performs research analysis on provided data.
    
    .DESCRIPTION
        This function demonstrates the structure for implementing research
        algorithms in PowerShell with proper documentation and parameter validation.
    
    .PARAMETER InputData
        The input data for analysis (CSV file path or PSObject array)
    
    .PARAMETER Parameter
        Research parameter for analysis (default: 1.0)
    
    .PARAMETER OutputPath
        Optional output file path for results
    
    .EXAMPLE
        PS> Invoke-ResearchAnalysis -InputData "data.csv" -Parameter 2.0
        
    .EXAMPLE
        PS> $data | Invoke-ResearchAnalysis -Parameter 1.5 -OutputPath "results.csv"
    
    .OUTPUTS
        PSObject array containing processed research results
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        $InputData,
        
        [Parameter()]
        [ValidateRange(0.1, 100.0)]
        [double]$Parameter = 1.0,
        
        [Parameter()]
        [string]$OutputPath
    )
    
    begin {
        Write-Verbose "Starting research analysis with parameter: $Parameter"
        $Results = @()
    }
    
    process {
        try {
            # Handle different input types
            if ($InputData -is [string] -and (Test-Path $InputData)) {
                Write-Verbose "Loading data from file: $InputData"
                $Data = Import-Csv -Path $InputData
            }
            elseif ($InputData -is [array] -or $InputData -is [System.Collections.IEnumerable]) {
                $Data = $InputData
            }
            else {
                throw "Invalid input data type. Expected CSV file path or PSObject array."
            }
            
            # Process each data item
            foreach ($Item in $Data) {
                $ProcessedItem = $Item.PSObject.Copy()
                
                # Apply research algorithm (example: multiply numeric properties)
                foreach ($Property in $Item.PSObject.Properties) {
                    if ($Property.Value -is [double] -or $Property.Value -is [int]) {
                        $ProcessedItem.$($Property.Name) = $Property.Value * $Parameter
                    }
                }
                
                $Results += $ProcessedItem
            }
        }
        catch {
            Write-Error "Error processing data: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "Analysis completed. Processed $($Results.Count) items."
        
        # Output to file if specified
        if ($OutputPath) {
            try {
                $Results | Export-Csv -Path $OutputPath -NoTypeInformation
                Write-Verbose "Results saved to: $OutputPath"
            }
            catch {
                Write-Error "Failed to save results: $_"
            }
        }
        
        # Return results
        return $Results
    }
}
EOF
    
    # Create utility function
    cat > "${module_dir}/Public/Test-ResearchData.ps1" << 'EOF'
function Test-ResearchData {
    <#
    .SYNOPSIS
        Validates research data quality.
    
    .DESCRIPTION
        Performs quality checks on research data including missing values,
        data types, and basic statistics.
    
    .PARAMETER Data
        The data to validate (PSObject array or CSV file path)
    
    .EXAMPLE
        PS> Test-ResearchData -Data "data.csv"
        
    .EXAMPLE
        PS> $myData | Test-ResearchData
    
    .OUTPUTS
        PSObject containing validation results
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        $Data
    )
    
    begin {
        $ValidationResults = @{
            TotalRows = 0
            TotalColumns = 0
            MissingValues = @{}
            DataTypes = @{}
            NumericColumns = @()
            TextColumns = @()
        }
    }
    
    process {
        try {
            # Handle file input
            if ($Data -is [string] -and (Test-Path $Data)) {
                $DataSet = Import-Csv -Path $Data
            }
            else {
                $DataSet = $Data
            }
            
            $ValidationResults.TotalRows = $DataSet.Count
            
            if ($DataSet.Count -gt 0) {
                $FirstRow = $DataSet[0]
                $ValidationResults.TotalColumns = $FirstRow.PSObject.Properties.Count
                
                # Analyze each column
                foreach ($Property in $FirstRow.PSObject.Properties) {
                    $ColumnName = $Property.Name
                    $Values = $DataSet | ForEach-Object { $_.$ColumnName }
                    
                    # Count missing values
                    $MissingCount = ($Values | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count
                    $ValidationResults.MissingValues[$ColumnName] = $MissingCount
                    
                    # Determine data type
                    $NonEmptyValues = $Values | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
                    if ($NonEmptyValues.Count -gt 0) {
                        $SampleValue = $NonEmptyValues[0]
                        if ([double]::TryParse($SampleValue, [ref]$null)) {
                            $ValidationResults.DataTypes[$ColumnName] = "Numeric"
                            $ValidationResults.NumericColumns += $ColumnName
                        }
                        else {
                            $ValidationResults.DataTypes[$ColumnName] = "Text"
                            $ValidationResults.TextColumns += $ColumnName
                        }
                    }
                }
            }
        }
        catch {
            Write-Error "Error validating data: $_"
            throw
        }
    }
    
    end {
        return [PSCustomObject]$ValidationResults
    }
}
EOF
    
    # Create private helper function
    cat > "${module_dir}/Private/Write-ResearchLog.ps1" << 'EOF'
function Write-ResearchLog {
    <#
    .SYNOPSIS
        Internal logging function for research operations.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    switch ($Level) {
        'Info' { Write-Verbose $LogMessage }
        'Warning' { Write-Warning $LogMessage }
        'Error' { Write-Error $LogMessage }
    }
}
EOF
    
    # Generate Pester tests
    cat > "${module_dir}/Tests/{{name}}.Tests.ps1" << 'EOF'
BeforeAll {
    # Import the module
    Import-Module "$PSScriptRoot\..\{{name}}.psd1" -Force
}

Describe "{{name}} Module Tests" {
    Context "Module Import" {
        It "Should import without errors" {
            { Import-Module "$PSScriptRoot\..\{{name}}.psd1" -Force } | Should -Not -Throw
        }
        
        It "Should export expected functions" {
            $ExportedFunctions = (Get-Module {{name}}).ExportedFunctions.Keys
            $ExportedFunctions | Should -Contain "Invoke-ResearchAnalysis"
            $ExportedFunctions | Should -Contain "Test-ResearchData"
        }
    }
    
    Context "Invoke-ResearchAnalysis" {
        It "Should process simple data correctly" {
            $TestData = @(
                [PSCustomObject]@{ X = 1; Y = 2 }
                [PSCustomObject]@{ X = 3; Y = 4 }
            )
            
            $Result = Invoke-ResearchAnalysis -InputData $TestData -Parameter 2.0
            
            $Result.Count | Should -Be 2
            $Result[0].X | Should -Be 2
            $Result[0].Y | Should -Be 4
            $Result[1].X | Should -Be 6
            $Result[1].Y | Should -Be 8
        }
        
        It "Should handle invalid parameter values" {
            $TestData = @([PSCustomObject]@{ X = 1 })
            { Invoke-ResearchAnalysis -InputData $TestData -Parameter -1 } | Should -Throw
        }
    }
    
    Context "Test-ResearchData" {
        It "Should validate data structure correctly" {
            $TestData = @(
                [PSCustomObject]@{ Name = "Test"; Value = 10; Empty = $null }
                [PSCustomObject]@{ Name = "Test2"; Value = 20; Empty = "" }
            )
            
            $Validation = Test-ResearchData -Data $TestData
            
            $Validation.TotalRows | Should -Be 2
            $Validation.TotalColumns | Should -Be 3
            $Validation.MissingValues["Empty"] | Should -Be 2
            $Validation.DataTypes["Value"] | Should -Be "Numeric"
            $Validation.DataTypes["Name"] | Should -Be "Text"
        }
    }
}
EOF
    
    # Create README
    cat > "${module_dir}/README.md" << 'EOF'
# {{name}}

{{description}}

## Installation

### From PowerShell Gallery (when published)
```powershell
Install-Module -Name {{name}}
```

### Local Development
```powershell
# Clone and import
git clone https://github.com/{{author_name}}/{{name}}.git
Import-Module .\{{name}}\{{name}}.psd1
```

## Usage

```powershell
# Import the module
Import-Module {{name}}

# Perform research analysis
$results = Invoke-ResearchAnalysis -InputData "data.csv" -Parameter 2.0

# Validate data quality
$validation = Test-ResearchData -Data "data.csv"
```

## Functions

### Invoke-ResearchAnalysis
Performs research analysis on provided data with configurable parameters.

### Test-ResearchData
Validates research data quality including missing values and data types.

## Testing

```powershell
# Run Pester tests
Invoke-Pester -Path .\Tests\
```

## Development

```powershell
# Load module for development
Import-Module .\{{name}}.psd1 -Force

# Run specific tests
Invoke-Pester -Path .\Tests\{{name}}.Tests.ps1
```

## Publishing

```powershell
# Publish to PowerShell Gallery
Publish-Module -Path . -NuGetApiKey $apiKey
```

## Citation

If you use this module in your research, please cite:

```
{{author_name}} ({{year}}). {{name}}: {{description}}. 
PowerShell module version 0.1.0. https://github.com/{{author_name}}/{{name}}
```

## License

MIT License - see LICENSE file for details.
EOF
    
    # Replace placeholders with actual values
    guid=$(uuidgen)
    year=$(date +%Y)
    
    # Use portable sed for cross-platform compatibility
    find "${module_dir}" -type f \( -name "*.psd1" -o -name "*.psm1" -o -name "*.ps1" -o -name "*.md" \) -exec sed -i.bak "s/{{guid}}/${guid}/g; s/{{year}}/${year}/g" {} \;
    find "${module_dir}" -name "*.bak" -delete
    
    echo "📦 Created PowerShell module: ${module_dir}"
    echo "📝 To get started:"
    echo "   cd ${module_dir}"
    echo "   Import-Module .\{{name}}.psd1"
    echo "   Invoke-Pester -Path .\Tests\"

# Create a Clojure library
create-clojure-library name description="Research Clojure library":
    #!/usr/bin/env bash
    lib_dir="clojure/{{name}}"
    mkdir -p "${lib_dir}"
    
    # Create Clojure project structure
    mkdir -p "${lib_dir}/src/{{name}}"
    mkdir -p "${lib_dir}/test/{{name}}"
    mkdir -p "${lib_dir}/resources"
    mkdir -p "${lib_dir}/doc"
    mkdir -p "${lib_dir}/dev"
    
    # Generate deps.edn
    cat > "${lib_dir}/deps.edn" << 'EOF'
{:paths ["src" "resources"]
 :deps {org.clojure/clojure {:mvn/version "1.11.1"}
        org.clojure/data.csv {:mvn/version "1.0.1"}
        org.clojure/data.json {:mvn/version "2.4.0"}
        semantic-csv/semantic-csv {:mvn/version "0.2.1-alpha1"}}
 
 :aliases
 {:test {:extra-paths ["test"]
         :extra-deps {org.clojure/test.check {:mvn/version "1.1.1"}}}
  :dev {:extra-paths ["dev"]
        :extra-deps {org.clojure/tools.namespace {:mvn/version "1.4.4"}
                     org.clojure/tools.deps.alpha {:mvn/version "0.15.1244"}}}
  :build {:deps {io.github.clojure/tools.build {:git/tag "v0.9.4" :git/sha "76b78fe"}
                 slipset/deps-deploy {:mvn/version "0.2.0"}}
          :ns-default build}
  :uberjar {:replace-deps {com.github.seancorfield/depstar {:mvn/version "2.1.303"}}
            :exec-fn hf.depstar/uberjar
            :exec-args {:aot true
                        :jar "{{name}}.jar"
                        :main-class "{{name}}.core"
                        :sync-pom true}}}}
EOF
    
    # Generate pom.xml template
    cat > "${lib_dir}/pom.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>{{author_name}}</groupId>
  <artifactId>{{name}}</artifactId>
  <version>0.1.0</version>
  <name>{{name}}</name>
  <description>{{description}}</description>
  <url>https://github.com/{{author_name}}/{{name}}</url>
  <licenses>
    <license>
      <name>MIT License</name>
      <url>https://opensource.org/licenses/MIT</url>
    </license>
  </licenses>
  <developers>
    <developer>
      <name>{{author_name}}</name>
      <email>{{author_email}}</email>
    </developer>
  </developers>
  <scm>
    <url>https://github.com/{{author_name}}/{{name}}</url>
    <connection>scm:git:git://github.com/{{author_name}}/{{name}}.git</connection>
    <developerConnection>scm:git:ssh://git@github.com/{{author_name}}/{{name}}.git</developerConnection>
    <tag>HEAD</tag>
  </scm>
  <dependencies>
    <dependency>
      <groupId>org.clojure</groupId>
      <artifactId>clojure</artifactId>
      <version>1.11.1</version>
    </dependency>
  </dependencies>
  <build>
    <sourceDirectory>src</sourceDirectory>
  </build>
  <repositories>
    <repository>
      <id>clojars</id>
      <url>https://repo.clojars.org/</url>
    </repository>
  </repositories>
</project>
EOF
    
    # Create main namespace
    cat > "${lib_dir}/src/{{name}}/core.clj" << 'EOF'
(ns {{name}}.core
  "{{description}}
  
  A Clojure library for research workflows developed as part of {{project_name}}."
  (:require [clojure.data.csv :as csv]
            [clojure.data.json :as json]
            [clojure.java.io :as io]
            [clojure.string :as str]))

;; Research Component Protocol
(defprotocol ResearchComponent
  "Protocol for research analysis components."
  (fit [this data] "Fit the component to data.")
  (transform [this data] "Transform data using fitted component.")
  (fit-transform [this data] "Fit component and transform data."))

;; Base Research Analyzer
(defrecord ResearchAnalyzer [name config fitted?]
  ResearchComponent
  (fit [this data]
    (println (str "Fitting " name " with " (count data) " samples"))
    (assoc this :fitted? true))
  
  (transform [this data]
    (when-not (:fitted? this)
      (throw (ex-info "Component must be fitted before transform" {:component this})))
    ;; Example transformation - apply parameter to numeric values
    (let [parameter (get-in this [:config :parameter] 1.0)]
      (map #(into {} (for [[k v] %]
                       [k (if (number? v) (* v parameter) v)])) data)))
  
  (fit-transform [this data]
    (-> this
        (fit data)
        (transform data))))

(defn research-analyzer
  "Creates a new research analyzer component."
  ([name] (research-analyzer name {}))
  ([name config]
   (->ResearchAnalyzer name config false)))

;; Data Loading Functions
(defn load-csv
  "Load research data from CSV file."
  [filepath & {:keys [header?] :or {header? true}}]
  (with-open [reader (io/reader filepath)]
    (let [data (csv/read-csv reader)]
      (if header?
        (let [headers (first data)
              rows (rest data)]
          (map #(zipmap (map keyword headers) %) rows))
        (map-indexed #(zipmap (map keyword (range (count %2))) %2) data)))))

(defn load-json
  "Load research data from JSON file."
  [filepath]
  (with-open [reader (io/reader filepath)]
    (json/read reader :key-fn keyword)))

(defn save-csv
  "Save research results to CSV file."
  [data filepath]
  (let [headers (-> data first keys)
        rows (map #(map % headers) data)]
    (with-open [writer (io/writer filepath)]
      (csv/write-csv writer (cons (map name headers) rows)))))

(defn save-json
  "Save research results to JSON file."
  [data filepath]
  (with-open [writer (io/writer filepath)]
    (json/write data writer :escape-unicode false)))

;; Data Validation Functions
(defn validate-data
  "Validate research data quality."
  [data]
  (let [sample (first data)
        columns (keys sample)
        total-rows (count data)]
    {:total-rows total-rows
     :total-columns (count columns)
     :columns columns
     :missing-values (into {} (for [col columns]
                               [col (count (filter #(or (nil? (col %))
                                                        (and (string? (col %))
                                                             (str/blank? (col %)))) data))]))
     :data-types (into {} (for [col columns]
                           [col (let [sample-val (col sample)]
                                 (cond
                                   (number? sample-val) :numeric
                                   (string? sample-val) :text
                                   (boolean? sample-val) :boolean
                                   :else :unknown))]))
     :memory-estimate (* total-rows (count columns) 8)}))

;; Statistical Functions
(defn summary-stats
  "Calculate summary statistics for numeric columns."
  [data]
  (let [numeric-cols (->> (first data)
                          (filter #(number? (val %)))
                          (map key))]
    (into {} (for [col numeric-cols]
               [col (let [values (map col data)
                         sorted-vals (sort values)
                         n (count values)
                         sum (reduce + values)
                         mean (/ sum n)
                         median (if (odd? n)
                                 (nth sorted-vals (/ (dec n) 2))
                                 (/ (+ (nth sorted-vals (/ n 2))
                                      (nth sorted-vals (dec (/ n 2)))) 2))]
                     {:count n
                      :sum sum
                      :mean mean
                      :median median
                      :min (first sorted-vals)
                      :max (last sorted-vals)
                      :std-dev (Math/sqrt (/ (reduce + (map #(Math/pow (- % mean) 2) values))
                                             (dec n)))})]))

;; Research Pipeline Functions
(defn research-pipeline
  "Execute a research analysis pipeline."
  [data & steps]
  (reduce (fn [acc step]
           (if (fn? step)
             (step acc)
             (throw (ex-info "Pipeline step must be a function" {:step step}))))
         data steps))

(defn apply-filter
  "Create a filter step for research pipeline."
  [pred]
  (fn [data]
    (filter pred data)))

(defn apply-transform
  "Create a transform step for research pipeline."
  [transform-fn]
  (fn [data]
    (map transform-fn data)))

(defn apply-analysis
  "Create an analysis step for research pipeline."
  [analysis-fn]
  (fn [data]
    {:data data
     :analysis (analysis-fn data)}))

;; Example research function
(defn research-function
  "Example research function demonstrating the library structure."
  [data & {:keys [parameter] :or {parameter 1.0}}]
  (when-not (sequential? data)
    (throw (ex-info "Data must be a sequence" {:data data})))
  (map #(into {} (for [[k v] %]
                  [k (if (number? v) (* v parameter) v)])) data))

;; Utility Functions
(defn current-timestamp
  "Get current timestamp for research logging."
  []
  (java.time.Instant/now))

(defn log-research
  "Log research operation with timestamp."
  [operation & args]
  (println (str "[" (current-timestamp) "] " operation ": " (str/join ", " args))))
EOF
    
    # Create test file
    cat > "${lib_dir}/test/{{name}}/core_test.clj" << 'EOF'
(ns {{name}}.core-test
  (:require [clojure.test :refer :all]
            [{{name}}.core :refer :all]))

(deftest test-research-analyzer
  (testing "ResearchAnalyzer creation and basic operations"
    (let [analyzer (research-analyzer "test-analyzer" {:parameter 2.0})
          test-data [{:x 1 :y 2} {:x 3 :y 4}]]
      
      (is (= "test-analyzer" (:name analyzer)))
      (is (false? (:fitted? analyzer)))
      
      ;; Test fitting
      (let [fitted-analyzer (fit analyzer test-data)]
        (is (true? (:fitted? fitted-analyzer))))
      
      ;; Test fit-transform
      (let [result (fit-transform analyzer test-data)]
        (is (= 4 (count result)))
        (is (= 2 (:x (first result))))
        (is (= 4 (:y (first result))))))))

(deftest test-data-validation
  (testing "Data validation functionality"
    (let [test-data [{:name "test" :value 10 :empty nil}
                     {:name "test2" :value 20 :empty ""}]
          validation (validate-data test-data)]
      
      (is (= 2 (:total-rows validation)))
      (is (= 3 (:total-columns validation)))
      (is (= 2 (get-in validation [:missing-values :empty])))
      (is (= :text (get-in validation [:data-types :name])))
      (is (= :numeric (get-in validation [:data-types :value]))))))

(deftest test-summary-stats
  (testing "Summary statistics calculation"
    (let [test-data [{:value 1} {:value 2} {:value 3} {:value 4} {:value 5}]
          stats (summary-stats test-data)
          value-stats (:value stats)]
      
      (is (= 5 (:count value-stats)))
      (is (= 15 (:sum value-stats)))
      (is (= 3.0 (:mean value-stats)))
      (is (= 3 (:median value-stats)))
      (is (= 1 (:min value-stats)))
      (is (= 5 (:max value-stats))))))

(deftest test-research-function
  (testing "Basic research function"
    (let [test-data [{:x 1 :y 2} {:x 3 :y 4}]
          result (research-function test-data :parameter 2.0)]
      
      (is (= 2 (count result)))
      (is (= 2 (:x (first result))))
      (is (= 4 (:y (first result))))
      (is (= 6 (:x (second result))))
      (is (= 8 (:y (second result)))))))

(deftest test-research-pipeline
  (testing "Research pipeline execution"
    (let [test-data [{:value 1} {:value 2} {:value 3} {:value 4} {:value 5}]
          result (research-pipeline test-data
                                   (apply-filter #(even? (:value %)))
                                   (apply-transform #(update % :value * 2))
                                   (apply-analysis #(count %)))]
      
      (is (= 2 (count (:data result))))
      (is (= 2 (:analysis result)))
      (is (= 4 (:value (first (:data result))))))))

(deftest test-invalid-inputs
  (testing "Error handling for invalid inputs"
    (is (thrown? Exception (research-function "not-a-sequence")))
    (is (thrown? Exception (transform (research-analyzer "test") [{:x 1}])))))
EOF
    
    # Create build script
    cat > "${lib_dir}/build.clj" << 'EOF'
(ns build
  (:require [clojure.tools.build.api :as b]
            [deps-deploy.deps-deploy :as dd]))

(def lib '{{author_name}}/{{name}})
(def version "0.1.0")
(def class-dir "target/classes")
(def basis (b/create-basis {:project "deps.edn"}))
(def jar-file (format "target/%s-%s.jar" (name lib) version))

(defn clean [_]
  (b/delete {:path "target"}))

(defn jar [_]
  (b/write-pom {:class-dir class-dir
                :lib lib
                :version version
                :basis basis
                :src-dirs ["src"]})
  (b/copy-dir {:src-dirs ["src" "resources"]
               :target-dir class-dir})
  (b/jar {:class-dir class-dir
          :jar-file jar-file}))

(defn deploy [_]
  (dd/deploy {:installer :remote
              :artifact jar-file
              :pom-file (b/pom-path {:lib lib :class-dir class-dir})}))
EOF
    
    # Create README
    cat > "${lib_dir}/README.md" << 'EOF'
# {{name}}

{{description}}

## Installation

### From Clojars (when published)
```clojure
;; Add to deps.edn
{{author_name}}/{{name}} {:mvn/version "0.1.0"}
```

### Local Development
```bash
git clone https://github.com/{{author_name}}/{{name}}.git
cd {{name}}
clj -M:dev
```

## Usage

```clojure
(require '[{{name}}.core :as research])

;; Load and analyze data
(def data (research/load-csv "data.csv"))
(def analyzer (research/research-analyzer "my-analysis" {:parameter 2.0}))
(def results (research/fit-transform analyzer data))

;; Validate data quality
(def validation (research/validate-data data))

;; Calculate summary statistics
(def stats (research/summary-stats data))

;; Use research pipeline
(def pipeline-result
  (research/research-pipeline data
                             (research/apply-filter #(> (:value %) 10))
                             (research/apply-transform #(update % :value * 2))
                             (research/apply-analysis count)))
```

## Core Functions

### Data Loading
- `load-csv` - Load CSV files with optional headers
- `load-json` - Load JSON data files
- `save-csv` / `save-json` - Save results to files

### Analysis Components
- `research-analyzer` - Create configurable analysis components
- `fit` / `transform` / `fit-transform` - Component interface

### Data Quality
- `validate-data` - Comprehensive data validation
- `summary-stats` - Statistical summaries for numeric columns

### Research Pipeline
- `research-pipeline` - Compose analysis steps
- `apply-filter` / `apply-transform` / `apply-analysis` - Pipeline steps

## Testing

```bash
# Run all tests
clj -M:test -m clojure.test.runner

# Run specific test namespace
clj -M:test -m {{name}}.core-test
```

## Building

```bash
# Build JAR
clj -T:build jar

# Clean build artifacts
clj -T:build clean

# Deploy to Clojars
clj -T:build deploy
```

## Development

```bash
# Start REPL
clj -M:dev

# Run tests with file watching
clj -M:test --watch
```

## Citation

If you use this library in your research, please cite:

```
{{author_name}} ({{year}}). {{name}}: {{description}}. 
Clojure library version 0.1.0. https://github.com/{{author_name}}/{{name}}
```

## License

MIT License - see LICENSE file for details.
EOF
    
    echo "📦 Created Clojure library: ${lib_dir}"
    echo "📝 To get started:"
    echo "   cd ${lib_dir}"
    echo "   clj -M:dev"
    echo "   clj -M:test -m clojure.test.runner"

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
    @echo ""
    @echo "PowerShell Modules:"
    @find powershell -maxdepth 1 -type d ! -name powershell ! -name experimental 2>/dev/null | sed 's/powershell\///g' | grep -v '^$' | sort || echo "No PowerShell modules found"
    @echo ""
    @echo "Clojure Libraries:"
    @find clojure -maxdepth 1 -type d ! -name clojure ! -name experimental 2>/dev/null | sed 's/clojure\///g' | grep -v '^$' | sort || echo "No Clojure libraries found"

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

# Test a PowerShell module
test-powershell module:
    #!/usr/bin/env bash
    if [ -d "powershell/{{module}}" ]; then
        cd "powershell/{{module}}"
        if command -v pwsh &> /dev/null; then
            pwsh -Command "Invoke-Pester -Path ./Tests/ -Passthru"
        elif command -v powershell &> /dev/null; then
            powershell -Command "Invoke-Pester -Path ./Tests/ -Passthru"
        else
            echo "❌ PowerShell not found. Install PowerShell Core (pwsh) or Windows PowerShell"
            exit 1
        fi
    else
        echo "❌ Module not found: powershell/{{module}}"
        exit 1
    fi

# Test a Clojure library
test-clojure library:
    #!/usr/bin/env bash
    if [ -d "clojure/{{library}}" ]; then
        cd "clojure/{{library}}"
        if command -v clj &> /dev/null; then
            clj -M:test -m clojure.test.runner
        else
            echo "❌ Clojure CLI not found. Install from https://clojure.org/guides/getting_started"
            exit 1
        fi
    else
        echo "❌ Library not found: clojure/{{library}}"
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

# Distribute PowerShell module to PowerShell Gallery
dist-powershell-gallery module:
    #!/usr/bin/env bash
    if [ -d "powershell/{{module}}" ]; then
        cd "powershell/{{module}}"
        echo "📦 Preparing PowerShell module {{module}} for PowerShell Gallery..."
        
        # Validate module manifest
        if command -v pwsh &> /dev/null; then
            pwsh -Command "Test-ModuleManifest -Path ./{{module}}.psd1"
        elif command -v powershell &> /dev/null; then
            powershell -Command "Test-ModuleManifest -Path ./{{module}}.psd1"
        else
            echo "❌ PowerShell not found"
            exit 1
        fi
        
        echo "📦 Module validated successfully"
        echo "📝 To publish to PowerShell Gallery:"
        echo "   # Set your API key:"
        echo "   \$apiKey = 'your-powershell-gallery-api-key'"
        echo "   # Publish module:"
        echo "   Publish-Module -Path . -NuGetApiKey \$apiKey"
        echo "   # Or publish to test repository:"
        echo "   Publish-Module -Path . -Repository PSGalleryInt -NuGetApiKey \$apiKey"
    else
        echo "❌ Module not found: powershell/{{module}}"
        exit 1
    fi

# Build Clojure library JAR
build-clojure library:
    #!/usr/bin/env bash
    if [ -d "clojure/{{library}}" ]; then
        cd "clojure/{{library}}"
        echo "🏗️ Building Clojure library {{library}}..."
        
        if command -v clj &> /dev/null; then
            # Clean previous builds
            clj -T:build clean
            
            # Build JAR
            clj -T:build jar
            
            echo "✅ JAR built successfully"
            echo "📦 Files in target/:"
            ls -la target/
        else
            echo "❌ Clojure CLI not found"
            exit 1
        fi
    else
        echo "❌ Library not found: clojure/{{library}}"
        exit 1
    fi

# Distribute Clojure library to Clojars
dist-clojars library:
    #!/usr/bin/env bash
    if [ -d "clojure/{{library}}" ]; then
        cd "clojure/{{library}}"
        echo "📦 Preparing Clojure library {{library}} for Clojars..."
        
        if command -v clj &> /dev/null; then
            # Build JAR first
            clj -T:build jar
            
            echo "📦 Library built successfully"
            echo "📝 To deploy to Clojars:"
            echo "   # Set your Clojars credentials in ~/.m2/settings.xml or use environment variables:"
            echo "   # CLOJARS_USERNAME=your-username"
            echo "   # CLOJARS_PASSWORD=your-deploy-token"
            echo "   # Then deploy:"
            echo "   clj -T:build deploy"
            echo "   # Or deploy manually with:"
            echo "   # mvn deploy:deploy-file -DgroupId={{author_name}} -DartifactId={{library}} -Dversion=0.1.0 -Dpackaging=jar -Dfile=target/{{library}}-0.1.0.jar -DrepositoryId=clojars -Durl=https://clojars.org/repo"
        else
            echo "❌ Clojure CLI not found"
            exit 1
        fi
    else
        echo "❌ Library not found: clojure/{{library}}"
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
