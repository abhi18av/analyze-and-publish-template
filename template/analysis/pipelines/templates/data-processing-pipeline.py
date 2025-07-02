#!/usr/bin/env python3
"""
Data Processing Pipeline Template
Pipeline ID: {{PIPELINE_ID}}
Pipeline Name: {{PIPELINE_NAME}}
Created: {{DATE}}

This template provides a structured approach to data processing with:
- Logging and monitoring
- Data validation
- Error handling
- Reproducible processing steps
- Integration with experiment tracking
"""

import pandas as pd
import numpy as np
from pathlib import Path
import logging
import sys
from typing import Optional, Dict, Any
import yaml
from dataclasses import dataclass
from datetime import datetime
import joblib

# Configuration dataclass
@dataclass
class PipelineConfig:
    """Configuration for the data processing pipeline"""
    input_path: str
    output_path: str
    validation_rules: Dict[str, Any]
    processing_steps: Dict[str, Any]
    log_level: str = "INFO"
    save_intermediate: bool = True

def setup_logging(log_level: str = "INFO") -> logging.Logger:
    """Setup logging configuration"""
    logging.basicConfig(
        level=getattr(logging, log_level),
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(f'pipeline_{{PIPELINE_ID}}.log'),
            logging.StreamHandler(sys.stdout)
        ]
    )
    return logging.getLogger(__name__)

def load_config(config_path: str) -> PipelineConfig:
    """Load pipeline configuration from YAML file"""
    try:
        with open(config_path, 'r') as f:
            config_dict = yaml.safe_load(f)
        return PipelineConfig(**config_dict)
    except FileNotFoundError:
        # Return default configuration
        return PipelineConfig(
            input_path="../data/01_raw/{{PIPELINE_NAME}}.csv",
            output_path="../data/02_processed/{{PIPELINE_NAME}}_processed.csv",
            validation_rules={
                "required_columns": [],
                "min_rows": 1,
                "max_missing_ratio": 0.5
            },
            processing_steps={
                "remove_duplicates": True,
                "handle_missing": "drop",
                "normalize_columns": False
            }
        )

def validate_data(df: pd.DataFrame, rules: Dict[str, Any], logger: logging.Logger) -> bool:
    """Validate input data against specified rules"""
    logger.info("Starting data validation...")
    
    # Check minimum rows
    if len(df) < rules.get("min_rows", 1):
        logger.error(f"Dataset has {len(df)} rows, minimum required: {rules['min_rows']}")
        return False
    
    # Check required columns
    required_cols = rules.get("required_columns", [])
    missing_cols = set(required_cols) - set(df.columns)
    if missing_cols:
        logger.error(f"Missing required columns: {missing_cols}")
        return False
    
    # Check missing data ratio
    max_missing = rules.get("max_missing_ratio", 1.0)
    missing_ratio = df.isnull().sum().sum() / (len(df) * len(df.columns))
    if missing_ratio > max_missing:
        logger.warning(f"Missing data ratio {missing_ratio:.3f} exceeds threshold {max_missing}")
    
    logger.info("Data validation completed successfully")
    return True

def load_data(input_path: str, logger: logging.Logger) -> pd.DataFrame:
    """Load raw data from input path"""
    logger.info(f"Loading data from: {input_path}")
    
    try:
        # Handle different file formats
        if input_path.endswith('.csv'):
            df = pd.read_csv(input_path)
        elif input_path.endswith('.parquet'):
            df = pd.read_parquet(input_path)
        elif input_path.endswith('.json'):
            df = pd.read_json(input_path)
        else:
            raise ValueError(f"Unsupported file format: {input_path}")
        
        logger.info(f"Loaded dataset with shape: {df.shape}")
        return df
    
    except Exception as e:
        logger.error(f"Failed to load data: {str(e)}")
        raise

def handle_missing_values(df: pd.DataFrame, method: str, logger: logging.Logger) -> pd.DataFrame:
    """Handle missing values in the dataset"""
    logger.info(f"Handling missing values using method: {method}")
    
    initial_missing = df.isnull().sum().sum()
    logger.info(f"Initial missing values: {initial_missing}")
    
    if method == "drop":
        df_clean = df.dropna()
    elif method == "mean":
        df_clean = df.fillna(df.select_dtypes(include=[np.number]).mean())
    elif method == "median":
        df_clean = df.fillna(df.select_dtypes(include=[np.number]).median())
    elif method == "mode":
        df_clean = df.fillna(df.mode().iloc[0])
    elif method == "forward_fill":
        df_clean = df.fillna(method='ffill')
    else:
        logger.warning(f"Unknown method {method}, using drop")
        df_clean = df.dropna()
    
    final_missing = df_clean.isnull().sum().sum()
    logger.info(f"Final missing values: {final_missing}")
    
    return df_clean

def remove_duplicates(df: pd.DataFrame, logger: logging.Logger) -> pd.DataFrame:
    """Remove duplicate rows from the dataset"""
    initial_rows = len(df)
    df_clean = df.drop_duplicates()
    final_rows = len(df_clean)
    
    removed_rows = initial_rows - final_rows
    logger.info(f"Removed {removed_rows} duplicate rows ({removed_rows/initial_rows:.2%})")
    
    return df_clean

def normalize_columns(df: pd.DataFrame, logger: logging.Logger) -> pd.DataFrame:
    """Normalize column names to lowercase with underscores"""
    logger.info("Normalizing column names...")
    
    original_cols = df.columns.tolist()
    df.columns = df.columns.str.lower().str.replace(' ', '_').str.replace('[^a-zA-Z0-9_]', '', regex=True)
    
    logger.info(f"Renamed columns: {dict(zip(original_cols, df.columns))}")
    return df

def process_data(df: pd.DataFrame, config: PipelineConfig, logger: logging.Logger) -> pd.DataFrame:
    """Apply all processing steps to the data"""
    logger.info("Starting data processing...")
    
    # Store original shape
    original_shape = df.shape
    
    # Apply processing steps based on configuration
    if config.processing_steps.get("normalize_columns", False):
        df = normalize_columns(df, logger)
    
    if config.processing_steps.get("remove_duplicates", True):
        df = remove_duplicates(df, logger)
    
    if config.processing_steps.get("handle_missing", "drop") != "none":
        df = handle_missing_values(df, config.processing_steps["handle_missing"], logger)
    
    # Log processing summary
    final_shape = df.shape
    logger.info(f"Processing completed: {original_shape} -> {final_shape}")
    
    return df

def save_data(df: pd.DataFrame, output_path: str, logger: logging.Logger):
    """Save processed data to output path"""
    logger.info(f"Saving processed data to: {output_path}")
    
    # Create output directory if it doesn't exist
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    
    try:
        # Save based on file extension
        if output_path.endswith('.csv'):
            df.to_csv(output_path, index=False)
        elif output_path.endswith('.parquet'):
            df.to_parquet(output_path, index=False)
        elif output_path.endswith('.json'):
            df.to_json(output_path, orient='records')
        else:
            # Default to CSV
            df.to_csv(output_path, index=False)
        
        logger.info(f"Successfully saved {len(df)} rows to {output_path}")
    
    except Exception as e:
        logger.error(f"Failed to save data: {str(e)}")
        raise

def generate_processing_report(df: pd.DataFrame, config: PipelineConfig, logger: logging.Logger) -> Dict[str, Any]:
    """Generate a summary report of the processing pipeline"""
    report = {
        "pipeline_id": "{{PIPELINE_ID}}",
        "pipeline_name": "{{PIPELINE_NAME}}",
        "timestamp": datetime.now().isoformat(),
        "input_path": config.input_path,
        "output_path": config.output_path,
        "final_shape": df.shape,
        "columns": df.columns.tolist(),
        "data_types": df.dtypes.to_dict(),
        "missing_values": df.isnull().sum().to_dict(),
        "summary_stats": df.describe().to_dict() if len(df.select_dtypes(include=[np.number]).columns) > 0 else {}
    }
    
    # Save report
    report_path = config.output_path.replace('.csv', '_report.json').replace('.parquet', '_report.json')
    with open(report_path, 'w') as f:
        import json
        json.dump(report, f, indent=2, default=str)
    
    logger.info(f"Processing report saved to: {report_path}")
    return report

def main():
    """Main pipeline execution function"""
    
    # Setup logging
    logger = setup_logging()
    logger.info(f"Starting data processing pipeline: {{PIPELINE_ID}}")
    
    try:
        # Load configuration
        config = load_config("../pipelines/configs/{{PIPELINE_NAME}}_config.yaml")
        logger.info(f"Loaded configuration for pipeline: {{PIPELINE_NAME}}")
        
        # Load data
        df = load_data(config.input_path, logger)
        
        # Validate data
        if not validate_data(df, config.validation_rules, logger):
            logger.error("Data validation failed, stopping pipeline")
            sys.exit(1)
        
        # Process data
        processed_df = process_data(df, config, logger)
        
        # Save processed data
        save_data(processed_df, config.output_path, logger)
        
        # Generate processing report
        report = generate_processing_report(processed_df, config, logger)
        
        logger.info("Data processing pipeline completed successfully")
        logger.info(f"Final dataset shape: {processed_df.shape}")
        
        return processed_df, report
    
    except Exception as e:
        logger.error(f"Pipeline failed with error: {str(e)}")
        raise

if __name__ == "__main__":
    main()
