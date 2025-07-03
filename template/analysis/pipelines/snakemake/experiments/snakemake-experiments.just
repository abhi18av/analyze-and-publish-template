# Snakemake Experiments Management with Resume Support
# Enhanced experiment tracking for failed and resumed Snakemake pipeline runs

# Variables
experiments_dir := justfile_directory()
templates_dir := experiments_dir + "/runs/templates"
runs_dir := experiments_dir + "/runs"
logs_dir := experiments_dir + "/logs"
reports_dir := experiments_dir + "/reports"
configs_dir := experiments_dir + "/config"
profiles_dir := experiments_dir + "/profiles"
rules_dir := experiments_dir + "/rules"
workflows_dir := experiments_dir + "/workflows"
timestamp := `date +%Y%m%d_%H%M%S`
date := `date +%Y-%m-%d`
researcher := "researcher-name"

# Default recipe
default:
    @echo "🐍 Snakemake Experiments Management:"
    @just --list

# === Experiment Creation ===

# Create new experiment
smk-new-experiment name purpose="exploratory":
    #!/usr/bin/env bash
    exp_id="{{date}}_{{purpose}}_{{name}}_v1"
    exp_dir="{{runs_dir}}/$exp_id"
    
    echo "🐍 Creating new Snakemake experiment: $exp_id"
    
    # Create experiment directory
    mkdir -p "$exp_dir"
    
    # Create experiment plan from template
    cp "{{templates_dir}}/experiment-plan.md" "$exp_dir/experiment-plan.md"
    sed -i.bak "s/{{experiment_id}}/$exp_id/g" "$exp_dir/experiment-plan.md"
    sed -i.bak "s/{{date}}/{{date}}/g" "$exp_dir/experiment-plan.md"
    sed -i.bak "s/{{researcher}}/{{researcher}}/g" "$exp_dir/experiment-plan.md"
    sed -i.bak "s/{{project}}/{{name}}/g" "$exp_dir/experiment-plan.md"
    rm "$exp_dir/experiment-plan.md.bak"
    
    # Create execution log template
    cp "{{templates_dir}}/execution-log.md" "$exp_dir/execution-log.md"
    sed -i.bak "s/{{experiment_id}}/$exp_id/g" "$exp_dir/execution-log.md"
    sed -i.bak "s/{{date}}/{{date}}/g" "$exp_dir/execution-log.md"
    sed -i.bak "s/{{researcher}}/{{researcher}}/g" "$exp_dir/execution-log.md"
    sed -i.bak "s/{{attempt_number}}/1/g" "$exp_dir/execution-log.md"
    rm "$exp_dir/execution-log.md.bak"
    
    # Create experiment configuration
    cat > "$exp_dir/config.yaml" << EOF
    # Experiment Configuration for $exp_id
    # Generated on {{date}}
    
    # Basic settings
    experiment_id: "$exp_id"
    researcher: "{{researcher}}"
    project: "{{name}}"
    
    # Input/Output paths
    input_dir: "../data/01_raw"
    output_dir: "../data/02_processed/$exp_id"
    temp_dir: "../data/temp/$exp_id"
    log_dir: "{{logs_dir}}/$exp_id"
    
    # Sample information
    samples: "samples.tsv"
    
    # Analysis parameters
    quality_threshold: 30
    min_length: 50
    
    # Resource allocation
    max_threads: 8
    max_memory_gb: 32
    
    # Software environments
    conda_prefix: "../envs"
    use_conda: true
    use_singularity: false
    
    # Cluster settings (if applicable)
    cluster:
      name: "local"
      partition: "compute"
      account: "research"
      max_jobs: 100
    EOF
    
    # Create sample sheet template
    cat > "$exp_dir/samples.tsv" << EOF
    sample_id	condition	fastq_1	fastq_2	genome
    sample_001	control	/path/to/sample_001_R1.fastq.gz	/path/to/sample_001_R2.fastq.gz	hg38
    sample_002	treatment	/path/to/sample_002_R1.fastq.gz	/path/to/sample_002_R2.fastq.gz	hg38
    sample_003	control	/path/to/sample_003_R1.fastq.gz	/path/to/sample_003_R2.fastq.gz	hg38
    EOF
    
    # Create resume log template
    cat > "$exp_dir/resume-log.md" << EOF
    # Resume Log for $exp_id
    
    ## Resume History
    | Attempt | Date | Reason | Strategy | Status |
    |---------|------|--------|----------|--------|
    | 1 | {{date}} | Initial run | - | Pending |
    
    ## Notes
    - Add notes about each resume attempt here
    EOF
    
    echo "✅ Experiment created: $exp_dir"
    echo "📝 Edit experiment-plan.md to define objectives"
    echo "⚙️  Edit config.yaml to configure parameters"
    echo "📊 Edit samples.tsv to define samples"

# Create resumed experiment from failed one
smk-resume-experiment failed_experiment_id resume_strategy="rerun-incomplete":
    #!/usr/bin/env bash
    failed_exp_dir="{{runs_dir}}/{{failed_experiment_id}}"
    
    if [ ! -d "$failed_exp_dir" ]; then
        echo "❌ Failed experiment directory not found: $failed_exp_dir"
        exit 1
    fi
    
    # Extract base name and increment version
    base_name=$(echo "{{failed_experiment_id}}" | sed 's/_v[0-9]*$//')
    version_num=$(echo "{{failed_experiment_id}}" | grep -o '_v[0-9]*$' | sed 's/_v//' || echo "1")
    new_version=$((version_num + 1))
    resume_exp_id="${base_name}_resume_v${new_version}"
    resume_exp_dir="{{runs_dir}}/$resume_exp_id"
    
    echo "🔄 Creating resumed Snakemake experiment: $resume_exp_id"
    echo "📂 From failed experiment: {{failed_experiment_id}}"
    echo "🔧 Resume strategy: {{resume_strategy}}"
    
    # Create resume experiment directory
    mkdir -p "$resume_exp_dir"
    
    # Copy configuration and samples from failed experiment
    cp "$failed_exp_dir/config.yaml" "$resume_exp_dir/config.yaml"
    cp "$failed_exp_dir/samples.tsv" "$resume_exp_dir/samples.tsv"
    
    # Update experiment ID in config
    sed -i.bak "s/experiment_id: \"{{failed_experiment_id}}\"/experiment_id: \"$resume_exp_id\"/g" "$resume_exp_dir/config.yaml"
    rm "$resume_exp_dir/config.yaml.bak"
    
    # Create experiment plan for resumed experiment
    cp "{{templates_dir}}/experiment-plan.md" "$resume_exp_dir/experiment-plan.md"
    sed -i.bak "s/{{experiment_id}}/$resume_exp_id/g" "$resume_exp_dir/experiment-plan.md"
    sed -i.bak "s/{{date}}/{{date}}/g" "$resume_exp_dir/experiment-plan.md"
    sed -i.bak "s/{{researcher}}/{{researcher}}/g" "$resume_exp_dir/experiment-plan.md"
    sed -i.bak "s/{{previous_experiment_id}}/{{failed_experiment_id}}/g" "$resume_exp_dir/experiment-plan.md"
    sed -i.bak "s/{{resume_strategy}}/{{resume_strategy}}/g" "$resume_exp_dir/experiment-plan.md"
    
    # Mark as resumed experiment
    sed -i.bak 's/- \[ \] New experiment/- [ ] New experiment/g' "$resume_exp_dir/experiment-plan.md"
    sed -i.bak 's/- \[ \] Resumed experiment/- [x] Resumed experiment/g' "$resume_exp_dir/experiment-plan.md"
    
    rm "$resume_exp_dir/experiment-plan.md.bak"
    
    # Create execution log template
    cp "{{templates_dir}}/execution-log.md" "$resume_exp_dir/execution-log.md"
    sed -i.bak "s/{{experiment_id}}/$resume_exp_id/g" "$resume_exp_dir/execution-log.md"
    sed -i.bak "s/{{date}}/{{date}}/g" "$resume_exp_dir/execution-log.md"
    sed -i.bak "s/{{researcher}}/{{researcher}}/g" "$resume_exp_dir/execution-log.md"
    sed -i.bak "s/{{resumed_from}}/{{failed_experiment_id}}/g" "$resume_exp_dir/execution-log.md"
    sed -i.bak "s/{{attempt_number}}/$new_version/g" "$resume_exp_dir/execution-log.md"
    rm "$resume_exp_dir/execution-log.md.bak"
    
    # Copy and update resume log
    if [ -f "$failed_exp_dir/resume-log.md" ]; then
        cp "$failed_exp_dir/resume-log.md" "$resume_exp_dir/resume-log.md"
    else
        echo "# Resume Log for $resume_exp_id" > "$resume_exp_dir/resume-log.md"
        echo "" >> "$resume_exp_dir/resume-log.md"
        echo "## Resume History" >> "$resume_exp_dir/resume-log.md"
        echo "| Attempt | Date | Reason | Strategy | Status |" >> "$resume_exp_dir/resume-log.md"
        echo "|---------|------|--------|----------|--------|" >> "$resume_exp_dir/resume-log.md"
    fi
    
    echo "| $new_version | {{date}} | Resume from {{failed_experiment_id}} | {{resume_strategy}} | Pending |" >> "$resume_exp_dir/resume-log.md"
    
    echo "✅ Resumed experiment created: $resume_exp_dir"
    echo "📝 Review and update experiment-plan.md"
    echo "⚙️  Review and update config.yaml"
    echo "🔄 Resume strategy: {{resume_strategy}}"

# === Experiment Execution ===

# Run experiment with specified profile
smk-run-experiment experiment_id profile="local":
    #!/usr/bin/env bash
    exp_dir="{{runs_dir}}/{{experiment_id}}"
    
    if [ ! -d "$exp_dir" ]; then
        echo "❌ Experiment directory not found: $exp_dir"
        exit 1
    fi
    
    echo "🐍 Running Snakemake experiment: {{experiment_id}}"
    echo "🏃 Profile: {{profile}}"
    
    # Create log directory for this experiment
    log_dir="{{logs_dir}}/{{experiment_id}}"
    mkdir -p "$log_dir"
    
    # Set working directory to experiment directory
    cd "$exp_dir"
    
    # Run Snakemake with specified profile and configuration
    snakemake \
        --configfile config.yaml \
        --profile {{profiles_dir}}/{{profile}} \
        --directory . \
        --printshellcmds \
        --reason \
        --stats "$log_dir/stats.json" \
        --log-handler-script "{{experiments_dir}}/scripts/log_handler.py" \
        2>&1 | tee "$log_dir/snakemake_{{timestamp}}.log"
    
    exit_code=${PIPESTATUS[0]}
    
    if [ $exit_code -eq 0 ]; then
        echo "✅ Experiment completed successfully"
        echo "{{timestamp}}: SUCCESS" >> "$exp_dir/run_history.txt"
    else
        echo "❌ Experiment failed with exit code: $exit_code"
        echo "{{timestamp}}: FAILED (exit code: $exit_code)" >> "$exp_dir/run_history.txt"
    fi
    
    echo "📝 Logs saved to: $log_dir"
    echo "📊 Generate report with: just smk-report-experiment {{experiment_id}}"

# Resume experiment with specific strategy
smk-resume-run experiment_id resume_type="rerun-incomplete" profile="local":
    #!/usr/bin/env bash
    exp_dir="{{runs_dir}}/{{experiment_id}}"
    
    if [ ! -d "$exp_dir" ]; then
        echo "❌ Experiment directory not found: $exp_dir"
        exit 1
    fi
    
    echo "🔄 Resuming Snakemake experiment: {{experiment_id}}"
    echo "🔧 Resume strategy: {{resume_type}}"
    echo "🏃 Profile: {{profile}}"
    
    # Create log directory for this experiment
    log_dir="{{logs_dir}}/{{experiment_id}}"
    mkdir -p "$log_dir"
    
    # Set working directory to experiment directory
    cd "$exp_dir"
    
    # Build resume command based on strategy
    case "{{resume_type}}" in
        "rerun-incomplete")
            resume_args="--rerun-incomplete"
            ;;
        "force-all")
            resume_args="--forceall"
            ;;
        "force-rule")
            echo "Enter rule name to force rerun:"
            read rule_name
            resume_args="--forcerun $rule_name"
            ;;
        "until-rule")
            echo "Enter target rule:"
            read target_rule
            resume_args="--until $target_rule"
            ;;
        *)
            resume_args="--rerun-incomplete"
            ;;
    esac
    
    # Run Snakemake with resume strategy
    snakemake \
        --configfile config.yaml \
        --profile {{profiles_dir}}/{{profile}} \
        --directory . \
        --printshellcmds \
        --reason \
        --stats "$log_dir/stats_resume_{{timestamp}}.json" \
        $resume_args \
        2>&1 | tee "$log_dir/snakemake_resume_{{timestamp}}.log"
    
    exit_code=${PIPESTATUS[0]}
    
    if [ $exit_code -eq 0 ]; then
        echo "✅ Experiment resumed successfully"
        echo "{{timestamp}}: RESUME SUCCESS ({{resume_type}})" >> "$exp_dir/run_history.txt"
    else
        echo "❌ Experiment resume failed with exit code: $exit_code"
        echo "{{timestamp}}: RESUME FAILED ({{resume_type}}, exit code: $exit_code)" >> "$exp_dir/run_history.txt"
    fi
    
    echo "📝 Resume logs saved to: $log_dir"

# === Experiment Monitoring ===

# Check experiment status and progress
smk-status experiment_id:
    #!/usr/bin/env bash
    exp_dir="{{runs_dir}}/{{experiment_id}}"
    
    if [ ! -d "$exp_dir" ]; then
        echo "❌ Experiment directory not found: $exp_dir"
        exit 1
    fi
    
    echo "📊 Snakemake Experiment Status: {{experiment_id}}"
    echo "========================================"
    
    cd "$exp_dir"
    
    # Show run history
    if [ -f "run_history.txt" ]; then
        echo "📝 Run History:"
        cat "run_history.txt"
        echo ""
    fi
    
    # Show Snakemake summary
    echo "🐍 Snakemake Summary:"
    snakemake --configfile config.yaml --summary 2>/dev/null || echo "No summary available"
    
    echo ""
    echo "📈 Detailed Summary:"
    snakemake --configfile config.yaml --detailed-summary 2>/dev/null || echo "No detailed summary available"

# Show experiment statistics
smk-stats experiment_id:
    #!/usr/bin/env bash
    exp_dir="{{runs_dir}}/{{experiment_id}}"
    log_dir="{{logs_dir}}/{{experiment_id}}"
    
    if [ ! -d "$exp_dir" ]; then
        echo "❌ Experiment directory not found: $exp_dir"
        exit 1
    fi
    
    echo "📊 Experiment Statistics: {{experiment_id}}"
    echo "======================================="
    
    # Show stats from JSON file if available
    if [ -f "$log_dir/stats.json" ]; then
        echo "📈 Runtime Statistics:"
        python3 -c "
import json
with open('$log_dir/stats.json') as f:
    stats = json.load(f)
    print(f'Total jobs: {stats.get(\"total_jobs\", \"N/A\")}')
    print(f'Rules: {len(stats.get(\"rules\", {}))}')
    print(f'Runtime: {stats.get(\"total_runtime\", \"N/A\")} seconds')
"
    fi
    
    # Show file counts
    cd "$exp_dir"
    echo ""
    echo "📁 Output Files:"
    if [ -d "../data/02_processed/{{experiment_id}}" ]; then
        find "../data/02_processed/{{experiment_id}}" -type f | wc -l | xargs echo "Files generated:"
    fi

# === Experiment Analysis ===

# Generate comprehensive experiment report
smk-report-experiment experiment_id:
    #!/usr/bin/env bash
    exp_dir="{{runs_dir}}/{{experiment_id}}"
    report_file="{{reports_dir}}/{{experiment_id}}_report.html"
    
    if [ ! -d "$exp_dir" ]; then
        echo "❌ Experiment directory not found: $exp_dir"
        exit 1
    fi
    
    echo "📊 Generating Snakemake report for: {{experiment_id}}"
    
    # Create reports directory
    mkdir -p "{{reports_dir}}"
    
    cd "$exp_dir"
    
    # Generate Snakemake HTML report
    snakemake \
        --configfile config.yaml \
        --report "$report_file" \
        --report-stylesheet "{{experiments_dir}}/assets/report.css" 2>/dev/null || \
    snakemake \
        --configfile config.yaml \
        --report "$report_file" 2>/dev/null || \
        echo "⚠️  Could not generate HTML report"
    
    # Generate DAG visualization
    snakemake \
        --configfile config.yaml \
        --dag | dot -Tsvg > "{{reports_dir}}/{{experiment_id}}_dag.svg" 2>/dev/null || \
        echo "⚠️  Could not generate DAG (graphviz required)"
    
    # Generate rule graph
    snakemake \
        --configfile config.yaml \
        --rulegraph | dot -Tsvg > "{{reports_dir}}/{{experiment_id}}_rulegraph.svg" 2>/dev/null || \
        echo "⚠️  Could not generate rule graph"
    
    echo "✅ Reports generated in: {{reports_dir}}"
    if [ -f "$report_file" ]; then
        echo "🌐 Open HTML report: $report_file"
    fi

# Create detailed markdown report
smk-markdown-report experiment_id:
    #!/usr/bin/env bash
    exp_dir="{{runs_dir}}/{{experiment_id}}"
    md_report="{{reports_dir}}/{{experiment_id}}_detailed_report.md"
    
    if [ ! -d "$exp_dir" ]; then
        echo "❌ Experiment directory not found: $exp_dir"
        exit 1
    fi
    
    echo "📝 Generating detailed markdown report for: {{experiment_id}}"
    
    mkdir -p "{{reports_dir}}"
    
    # Generate comprehensive markdown report
    cat > "$md_report" << EOF
# Detailed Experiment Report: {{experiment_id}}

Generated: $(date)

## Experiment Overview
$(cat "$exp_dir/experiment-plan.md" 2>/dev/null || echo "No experiment plan found")

## Configuration
\`\`\`yaml
$(cat "$exp_dir/config.yaml" 2>/dev/null || echo "No config found")
\`\`\`

## Sample Information
\`\`\`
$(cat "$exp_dir/samples.tsv" 2>/dev/null || echo "No samples file found")
\`\`\`

## Execution Log
$(cat "$exp_dir/execution-log.md" 2>/dev/null || echo "No execution log found")

## Resume History
$(cat "$exp_dir/resume-log.md" 2>/dev/null || echo "No resume log found")

## Run History
\`\`\`
$(cat "$exp_dir/run_history.txt" 2>/dev/null || echo "No run history found")
\`\`\`

## Latest Logs
EOF
    
    # Add latest log files
    log_dir="{{logs_dir}}/{{experiment_id}}"
    if [ -d "$log_dir" ]; then
        echo "" >> "$md_report"
        echo "### Latest Snakemake Log" >> "$md_report"
        echo "\`\`\`" >> "$md_report"
        latest_log=$(ls -t "$log_dir"/snakemake_*.log 2>/dev/null | head -1)
        if [ -n "$latest_log" ]; then
            tail -50 "$latest_log" >> "$md_report" 2>/dev/null
        fi
        echo "\`\`\`" >> "$md_report"
    fi
    
    echo "✅ Detailed report generated: $md_report"

# === Experiment Management ===

# List all experiments
smk-list-experiments:
    @echo "🐍 All Snakemake Experiments:"
    @find {{runs_dir}} -name "20*" -type d | sort | while read exp_dir; do \
        exp_id=$(basename "$exp_dir"); \
        status="Unknown"; \
        if [ -f "$exp_dir/run_history.txt" ]; then \
            status=$(tail -1 "$exp_dir/run_history.txt" | cut -d: -f2 | xargs); \
        fi; \
        echo "  📊 $exp_id ($status)"; \
    done

# List failed experiments
smk-list-failed:
    @echo "❌ Failed Snakemake Experiments:"
    @find {{runs_dir}} -name "20*" -type d | sort | while read exp_dir; do \
        exp_id=$(basename "$exp_dir"); \
        if [ -f "$exp_dir/run_history.txt" ] && grep -q "FAILED" "$exp_dir/run_history.txt"; then \
            last_failure=$(grep "FAILED" "$exp_dir/run_history.txt" | tail -1); \
            echo "  ❌ $exp_id: $last_failure"; \
        fi; \
    done

# List experiments that can be resumed
smk-list-resumable:
    @echo "🔄 Resumable Snakemake Experiments:"
    @find {{runs_dir}} -name "20*" -type d | sort | while read exp_dir; do \
        exp_id=$(basename "$exp_dir"); \
        cd "$exp_dir" 2>/dev/null || continue; \
        if snakemake --configfile config.yaml --summary 2>/dev/null | grep -q "incomplete"; then \
            echo "  🔄 $exp_id (has incomplete jobs)"; \
        fi; \
    done

# Archive completed experiment
smk-archive experiment_id:
    #!/usr/bin/env bash
    exp_dir="{{runs_dir}}/{{experiment_id}}"
    archive_dir="{{runs_dir}}/archived"
    
    if [ ! -d "$exp_dir" ]; then
        echo "❌ Experiment directory not found: $exp_dir"
        exit 1
    fi
    
    mkdir -p "$archive_dir"
    
    echo "📦 Archiving Snakemake experiment: {{experiment_id}}"
    
    # Create archive with timestamp
    tar -czf "$archive_dir/{{experiment_id}}_{{timestamp}}.tar.gz" -C "{{runs_dir}}" "{{experiment_id}}"
    
    # Move original to archived directory
    mv "$exp_dir" "$archive_dir/"
    
    echo "✅ Experiment archived to: $archive_dir/{{experiment_id}}"
    echo "📦 Archive file: $archive_dir/{{experiment_id}}_{{timestamp}}.tar.gz"

# Clean temporary files from experiment
smk-clean-experiment experiment_id:
    #!/usr/bin/env bash
    exp_dir="{{runs_dir}}/{{experiment_id}}"
    
    if [ ! -d "$exp_dir" ]; then
        echo "❌ Experiment directory not found: $exp_dir"
        exit 1
    fi
    
    echo "🧹 Cleaning temporary files for: {{experiment_id}}"
    
    cd "$exp_dir"
    
    # Clean Snakemake temporary files
    find . -name ".snakemake" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.tmp" -delete 2>/dev/null || true
    find . -name "*.bak" -delete 2>/dev/null || true
    
    # Clean conda environments (ask first)
    if [ -d ".snakemake/conda" ]; then
        echo "Remove conda environments? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            rm -rf ".snakemake/conda"
            echo "🗑️  Conda environments removed"
        fi
    fi
    
    echo "✅ Cleanup completed for {{experiment_id}}"

# === Setup and Utilities ===

# Setup Snakemake experiment infrastructure
smk-setup:
    @mkdir -p {{runs_dir}} {{logs_dir}} {{reports_dir}} {{configs_dir}} {{profiles_dir}} {{rules_dir}} {{workflows_dir}}
    @mkdir -p {{runs_dir}}/templates {{runs_dir}}/archived
    @mkdir -p {{profiles_dir}}/local {{profiles_dir}}/cluster {{profiles_dir}}/cloud
    @echo "✅ Snakemake experiment directories created"
    @echo "📁 Directory structure:"
    @echo "  {{runs_dir}} - Individual experiment runs"
    @echo "  {{logs_dir}} - Execution logs"
    @echo "  {{reports_dir}} - Generated reports"
    @echo "  {{configs_dir}} - Configuration templates"
    @echo "  {{profiles_dir}} - Execution profiles"
    @echo "  {{rules_dir}} - Reusable Snakemake rules"
    @echo "  {{workflows_dir}} - Complete workflow definitions"

# Validate experiment configuration
smk-validate-experiment experiment_id:
    #!/usr/bin/env bash
    exp_dir="{{runs_dir}}/{{experiment_id}}"
    
    if [ ! -d "$exp_dir" ]; then
        echo "❌ Experiment directory not found: $exp_dir"
        exit 1
    fi
    
    echo "✅ Validating Snakemake experiment: {{experiment_id}}"
    
    cd "$exp_dir"
    
    # Check if required files exist
    files_to_check=("config.yaml" "samples.tsv")
    for file in "${files_to_check[@]}"; do
        if [ -f "$file" ]; then
            echo "✅ $file exists"
        else
            echo "❌ $file missing"
        fi
    done
    
    # Validate Snakemake workflow
    if [ -f "../../Snakefile" ]; then
        echo "🐍 Validating Snakemake syntax..."
        snakemake --configfile config.yaml --dry-run --quiet 2>/dev/null && \
            echo "✅ Snakemake validation passed" || \
            echo "❌ Snakemake validation failed"
    fi
    
    # Check sample file format
    if [ -f "samples.tsv" ]; then
        echo "📊 Checking sample file format..."
        python3 -c "
import pandas as pd
try:
    df = pd.read_csv('samples.tsv', sep='\t')
    print(f'✅ Sample file valid: {len(df)} samples')
    required_cols = ['sample_id']
    missing = [col for col in required_cols if col not in df.columns]
    if missing:
        print(f'⚠️  Missing columns: {missing}')
    else:
        print('✅ Required columns present')
except Exception as e:
    print(f'❌ Sample file error: {e}')
"
    fi

# Show experiment statistics
smk-global-stats:
    #!/usr/bin/env bash
    echo "📊 Snakemake Experiments Statistics:"
    echo "===================================="
    
    total_exp=$(find {{runs_dir}} -name "20*" -type d | wc -l)
    archived_exp=$(find {{runs_dir}}/archived -name "20*" -type d 2>/dev/null | wc -l)
    active_exp=$((total_exp - archived_exp))
    
    echo "Total experiments: $total_exp"
    echo "Active experiments: $active_exp"
    echo "Archived experiments: $archived_exp"
    
    # Count by status
    echo ""
    echo "Status breakdown:"
    success_count=0
    failed_count=0
    pending_count=0
    
    find {{runs_dir}} -name "20*" -type d | while read exp_dir; do
        if [ -f "$exp_dir/run_history.txt" ]; then
            if grep -q "SUCCESS" "$exp_dir/run_history.txt"; then
                success_count=$((success_count + 1))
            elif grep -q "FAILED" "$exp_dir/run_history.txt"; then
                failed_count=$((failed_count + 1))
            else
                pending_count=$((pending_count + 1))
            fi
        else
            pending_count=$((pending_count + 1))
        fi
    done
    
    echo "✅ Successful: $success_count"
    echo "❌ Failed: $failed_count"
    echo "⏳ Pending: $pending_count"
    
    echo ""
    echo "Recent experiments (last 7 days):"
    find {{runs_dir}} -name "20*" -type d -mtime -7 | sort | while read exp_dir; do
        exp_id=$(basename "$exp_dir")
        echo "  📊 $exp_id"
    done

# Clean up all temporary files
smk-cleanup:
    @echo "🧹 Cleaning up Snakemake experiment files..."
    @find {{runs_dir}} -name ".snakemake" -type d -exec rm -rf {} + 2>/dev/null || true
    @find {{runs_dir}} -name "*.bak" -delete 2>/dev/null || true
    @find {{logs_dir}} -name "*.tmp" -delete 2>/dev/null || true
    @echo "✅ Cleanup completed"
