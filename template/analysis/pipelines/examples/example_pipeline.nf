#!/usr/bin/env nextflow

/*
 * Example Pipeline with Results Management Integration
 * Demonstrates organized results directory structure
 */

nextflow.enable.dsl = 2

// Define workflow
workflow {
    // Example processes
    PREPROCESS(Channel.of(true))
    ANALYZE(PREPROCESS.out)
    GENERATE_REPORT(ANALYZE.out)
    
    // Emit results summary
    GENERATE_REPORT.out.view { "Results available at: ${params.outdir}" }
}

// Example preprocessing process
process PREPROCESS {
    publishDir "${params.outdir}/01_preprocessing", mode: params.publish_dir_mode
    
    input:
    val ready
    
    output:
    path "preprocessed_data.txt"
    
    script:
    """
    echo "Preprocessing data for ${params.project_name}" > preprocessed_data.txt
    echo "Workflow type: ${params.workflow_type}" >> preprocessed_data.txt
    echo "Timestamp: \$(date)" >> preprocessed_data.txt
    echo "Sample data processing completed" >> preprocessed_data.txt
    """
}

// Example analysis process
process ANALYZE {
    publishDir "${params.outdir}/02_analysis", mode: params.publish_dir_mode
    
    input:
    path preprocessed_data
    
    output:
    path "analysis_results.txt"
    
    script:
    """
    echo "Analysis Results for ${params.project_name}" > analysis_results.txt
    echo "=================================" >> analysis_results.txt
    cat ${preprocessed_data} >> analysis_results.txt
    echo "" >> analysis_results.txt
    echo "Analysis completed at: \$(date)" >> analysis_results.txt
    
    # Simulate different outputs based on workflow type
    if [ "${params.workflow_type}" = "hyperopt" ]; then
        mkdir -p optimization_trials
        echo "Trial 1: Parameter set A" > optimization_trials/trial_001.txt
        echo "Trial 2: Parameter set B" > optimization_trials/trial_002.txt
        echo "Best parameters found" > best_parameters.json
    elif [ "${params.workflow_type}" = "training" ]; then
        echo "Model training completed" > trained_model.pkl
        echo "Training metrics saved" > training_metrics.csv
    elif [ "${params.workflow_type}" = "inference" ]; then
        echo "Predictions generated" > predictions.csv
        echo "Confidence scores calculated" > confidence_scores.csv
    fi
    """
}

// Example report generation process
process GENERATE_REPORT {
    publishDir "${params.outdir}/03_reports", mode: params.publish_dir_mode
    
    input:
    path analysis_results
    
    output:
    path "*.html"
    
    script:
    """
    cat > pipeline_report.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Pipeline Report - ${params.project_name}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 10px; border-radius: 5px; }
        .section { margin: 20px 0; }
        .metadata { background-color: #f9f9f9; padding: 10px; border-left: 3px solid #007cba; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Pipeline Execution Report</h1>
        <h2>${params.project_name}</h2>
    </div>
    
    <div class="section">
        <h3>Run Information</h3>
        <div class="metadata">
            <p><strong>Workflow Type:</strong> ${params.workflow_type}</p>
            <p><strong>Results Directory:</strong> ${params.outdir}</p>
            <p><strong>Execution Date:</strong> \$(date)</p>
            <p><strong>Nextflow Version:</strong> \$(nextflow -version 2>/dev/null | head -1 || echo 'Unknown')</p>
        </div>
    </div>
    
    <div class="section">
        <h3>Analysis Results</h3>
        <pre>
\$(cat ${analysis_results})
        </pre>
    </div>
    
    <div class="section">
        <h3>Directory Structure</h3>
        <p>Results are organized in the following structure:</p>
        <ul>
            <li>01_preprocessing/ - Data preprocessing outputs</li>
            <li>02_analysis/ - Main analysis results</li>
            <li>03_reports/ - Reports and visualizations</li>
            <li>pipeline_info/ - Pipeline execution metadata</li>
        </ul>
    </div>
</body>
</html>
EOF
    """
}
