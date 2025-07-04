# Pipeline Results Management System

This system provides organized directory structure and metadata tracking for bioinformatics pipeline runs.

## Quick Start

### 1. Create a new results directory

```bash
# Using Python script directly
./scripts/results/results_manager.py create --workflow-type hyperopt --project-name my_analysis

# Using shell script
./scripts/results/create_results_dir.sh create hyperopt my_project
```

### 2. Run pipeline with organized results

```bash
# Run with specific workflow type
nextflow run data-pipeline.nf -profile hyperopt --workflow_type hyperopt

# Run with custom project name
nextflow run data-pipeline.nf --project_name "genome_assembly_v2"
```

## Directory Structure

Results are organized chronologically with the following structure:

```
results/
├── 2025-07-04/                     # Date-based organization
│   ├── hyperopt/                   # Workflow type
│   │   └── 143025/                 # Time (14:30:25)
│   │       ├── 01_data_preparation/
│   │       ├── 02_optimization/
│   │       │   └── trials/
│   │       ├── 03_validation/
│   │       ├── 04_reports/
│   │       ├── pipeline_info/
│   │       └── run_info.json       # Run metadata
│   ├── training/
│   └── inference/
└── latest/                         # Symlinks to latest runs
    ├── hyperopt -> ../2025-07-04/hyperopt/143025/
    ├── training -> ../2025-07-04/training/090000/
    └── inference -> ../2025-07-04/inference/160000/
```

## Workflow Types

### 1. Hyperparameter Optimization (`hyperopt`)
- **Purpose**: Parameter tuning and optimization
- **Subdirectories**:
  - `01_data_preparation/` - QC and preprocessing
  - `02_optimization/trials/` - Individual optimization trials
  - `03_validation/` - Cross-validation results
  - `04_reports/` - Optimization reports and plots

### 2. Model Training (`training`)
- **Purpose**: Model training and validation
- **Subdirectories**:
  - `01_preprocessing/` - Data preprocessing
  - `02_model_training/` - Trained models and checkpoints
  - `03_evaluation/` - Performance evaluation
  - `04_reports/` - Training reports

### 3. Inference (`inference`)
- **Purpose**: Production analysis with trained models
- **Subdirectories**:
  - `01_input_processing/` - Input validation and processing
  - `02_predictions/` - Prediction results
  - `03_quality_control/` - QC metrics
  - `04_reports/` - Analysis reports

### 4. General Analysis (`analysis`)
- **Purpose**: Standard bioinformatics analysis
- **Subdirectories**:
  - `01_preprocessing/` - Data preprocessing
  - `02_analysis/` - Main analysis results
  - `03_reports/` - Analysis reports

## Commands

### Python Script (`results_manager.py`)

```bash
# Create new results directory
python3 scripts/results/results_manager.py create --workflow-type hyperopt --project-name my_project

# Update run status
python3 scripts/results/results_manager.py update-status results/2025-07-04/hyperopt/143025 completed

# Find runs
python3 scripts/results/results_manager.py find --workflow-type hyperopt --status completed

# Cleanup old runs (dry run)
python3 scripts/results/results_manager.py cleanup --days 30 --dry-run

# Cleanup old runs (actual deletion)
python3 scripts/results/results_manager.py cleanup --days 30
```

### Shell Script (`create_results_dir.sh`)

```bash
# Create new results directory
./scripts/results/create_results_dir.sh create hyperopt my_project

# Update run status
./scripts/results/create_results_dir.sh update-status results/2025-07-04/hyperopt/143025 completed

# Find runs
./scripts/results/create_results_dir.sh find hyperopt completed

# Cleanup old runs
./scripts/results/create_results_dir.sh cleanup 30 true  # dry run
./scripts/results/create_results_dir.sh cleanup 30 false # actual cleanup
```

## Nextflow Integration

The system integrates with Nextflow through configuration:

```groovy
// nextflow.config
params {
    project_name = 'my_analysis'
    workflow_type = 'hyperopt'  // hyperopt, training, inference, analysis
}

// Results directory is automatically created
// Files are published to organized subdirectories
```

### Running with Different Profiles

```bash
# Hyperparameter optimization
nextflow run data-pipeline.nf -profile hyperopt

# Model training
nextflow run data-pipeline.nf -profile training

# Inference analysis
nextflow run data-pipeline.nf -profile inference

# Custom workflow type
nextflow run data-pipeline.nf --workflow_type custom_analysis
```

## Run Metadata

Each run generates a `run_info.json` file containing:

```json
{
  "run_id": "hyperopt_20250704_143025",
  "project_name": "my_analysis",
  "workflow_type": "hyperopt",
  "start_time": "2025-07-04T14:30:25",
  "status": "completed",
  "git_commit": "abc123...",
  "parameters": {...},
  "results_path": "results/2025-07-04/hyperopt/143025"
}
```

## Tower Integration

When using Nextflow Tower:

```bash
# Run with Tower monitoring
nextflow run data-pipeline.nf -profile hyperopt -with-tower

# Tower run ID is automatically recorded in metadata
```

## Best Practices

### 1. Naming Conventions
- Use descriptive project names: `genome_assembly_hg38`, `rna_seq_cancer_study`
- Choose appropriate workflow types for your analysis
- Use consistent parameter naming

### 2. Resource Management
- Different workflow types have optimized resource profiles
- Hyperopt: Moderate resources for parameter exploration
- Training: High resources for model training
- Inference: Balanced resources for production analysis

### 3. Results Organization
- Each workflow type organizes outputs appropriately
- Use `latest/` symlinks for quick access to recent results
- Archive old results using cleanup commands

### 4. Reproducibility
- All runs include git commit information
- Parameter sets are recorded in metadata
- Environment information is captured

## Troubleshooting

### Common Issues

1. **Permission errors**: Ensure scripts are executable
   ```bash
   chmod +x scripts/results/*.sh scripts/results/*.py
   ```

2. **Python not found**: Use correct Python executable
   ```bash
   which python3  # Check Python installation
   ```

3. **Results directory not created**: Check script permissions and disk space

4. **Symlinks not working**: May occur on some filesystems; results are still organized by date

### Debug Mode

Enable verbose output:
```bash
export RESULTS_DEBUG=1
./scripts/results/results_manager.py create --workflow-type hyperopt
```

## Examples

See the `examples/` directory for complete workflow examples:
- Basic analysis pipeline
- Hyperparameter optimization workflow
- Model training and validation
- Production inference pipeline
