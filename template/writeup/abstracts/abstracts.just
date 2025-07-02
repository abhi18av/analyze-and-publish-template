# Abstract Management Automation
# Use with just (https://github.com/casey/just)
# Run from the writeup/abstracts directory

# Set default shell
set shell := ["bash", "-c"]

# Variables
abstracts_dir := justfile_directory()
templates_dir := abstracts_dir + "/templates"
conference_dir := abstracts_dir + "/conference"
journal_dir := abstracts_dir + "/journal"
symposium_dir := abstracts_dir + "/symposium"
tracking_dir := abstracts_dir + "/tracking"

# Default recipe
default:
    @echo "Available abstract management commands:"
    @just --list

# Create new conference abstract
new-conference abstract_name conference_name:
    #!/usr/bin/env bash
    mkdir -p "{{conference_dir}}/submitted/{{abstract_name}}"
    cp "{{templates_dir}}/conference_abstract.qmd" "{{conference_dir}}/submitted/{{abstract_name}}/{{abstract_name}}.qmd"
    echo "Created new conference abstract: {{abstract_name}}"
    echo "Location: {{conference_dir}}/submitted/{{abstract_name}}"
    echo "Conference: {{conference_name}}"

# Create new journal abstract
new-journal abstract_name journal_name:
    #!/usr/bin/env bash
    mkdir -p "{{journal_dir}}/submitted/{{abstract_name}}"
    cp "{{templates_dir}}/journal_abstract.qmd" "{{journal_dir}}/submitted/{{abstract_name}}/{{abstract_name}}.qmd"
    echo "Created new journal abstract: {{abstract_name}}"
    echo "Location: {{journal_dir}}/submitted/{{abstract_name}}"
    echo "Journal: {{journal_name}}"

# Create new symposium abstract
new-symposium abstract_name event_name:
    #!/usr/bin/env bash
    mkdir -p "{{symposium_dir}}/submitted/{{abstract_name}}"
    cp "{{templates_dir}}/symposium_abstract.qmd" "{{symposium_dir}}/submitted/{{abstract_name}}/{{abstract_name}}.qmd"
    echo "Created new symposium abstract: {{abstract_name}}"
    echo "Location: {{symposium_dir}}/submitted/{{abstract_name}}"
    echo "Event: {{event_name}}"

# List all submitted abstracts
list-submitted:
    @echo "Submitted abstracts:"
    @echo "==================="
    @echo "Conferences:"
    @find "{{conference_dir}}/submitted" -maxdepth 1 -type d -not -path "*/submitted" -exec basename {} \; 2>/dev/null || echo "  No conference abstracts"
    @echo ""
    @echo "Journals:"
    @find "{{journal_dir}}/submitted" -maxdepth 1 -type d -not -path "*/submitted" -exec basename {} \; 2>/dev/null || echo "  No journal abstracts"
    @echo ""
    @echo "Symposiums:"
    @find "{{symposium_dir}}/submitted" -maxdepth 1 -type d -not -path "*/submitted" -exec basename {} \; 2>/dev/null || echo "  No symposium abstracts"

# List all accepted abstracts
list-accepted:
    @echo "Accepted abstracts:"
    @echo "=================="
    @echo "Conferences:"
    @find "{{conference_dir}}/accepted" -maxdepth 1 -type d -not -path "*/accepted" -exec basename {} \; 2>/dev/null || echo "  No accepted conference abstracts"
    @echo ""
    @echo "Journals:"
    @find "{{journal_dir}}/accepted" -maxdepth 1 -type d -not -path "*/accepted" -exec basename {} \; 2>/dev/null || echo "  No accepted journal abstracts"
    @echo ""
    @echo "Symposiums:"
    @find "{{symposium_dir}}/accepted" -maxdepth 1 -type d -not -path "*/accepted" -exec basename {} \; 2>/dev/null || echo "  No accepted symposium abstracts"

# List all presented abstracts
list-presented:
    @echo "Presented abstracts:"
    @echo "==================="
    @echo "Conferences:"
    @find "{{conference_dir}}/presented" -maxdepth 1 -type d -not -path "*/presented" -exec basename {} \; 2>/dev/null || echo "  No presented conference abstracts"
    @echo ""
    @echo "Journals:"
    @find "{{journal_dir}}/presented" -maxdepth 1 -type d -not -path "*/presented" -exec basename {} \; 2>/dev/null || echo "  No presented journal abstracts"
    @echo ""
    @echo "Symposiums:"
    @find "{{symposium_dir}}/presented" -maxdepth 1 -type d -not -path "*/presented" -exec basename {} \; 2>/dev/null || echo "  No presented symposium abstracts"

# Move abstract to accepted status
accept abstract_type abstract_name:
    #!/usr/bin/env bash
    case "{{abstract_type}}" in
        "conference")
            source_dir="{{conference_dir}}/submitted/{{abstract_name}}"
            dest_dir="{{conference_dir}}/accepted/"
            ;;
        "journal")
            source_dir="{{journal_dir}}/submitted/{{abstract_name}}"
            dest_dir="{{journal_dir}}/accepted/"
            ;;
        "symposium")
            source_dir="{{symposium_dir}}/submitted/{{abstract_name}}"
            dest_dir="{{symposium_dir}}/accepted/"
            ;;
        *)
            echo "Error: Invalid abstract type. Use 'conference', 'journal', or 'symposium'"
            exit 1
            ;;
    esac
    
    if [ -d "$source_dir" ]; then
        mv "$source_dir" "$dest_dir"
        echo "Moved {{abstract_name}} to accepted {{abstract_type}} abstracts"
    else
        echo "Error: {{abstract_name}} not found in submitted {{abstract_type}} abstracts"
    fi

# Move abstract to presented status
present abstract_type abstract_name:
    #!/usr/bin/env bash
    case "{{abstract_type}}" in
        "conference")
            source_dir="{{conference_dir}}/accepted/{{abstract_name}}"
            dest_dir="{{conference_dir}}/presented/"
            ;;
        "journal")
            source_dir="{{journal_dir}}/accepted/{{abstract_name}}"
            dest_dir="{{journal_dir}}/presented/"
            ;;
        "symposium")
            source_dir="{{symposium_dir}}/accepted/{{abstract_name}}"
            dest_dir="{{symposium_dir}}/presented/"
            ;;
        *)
            echo "Error: Invalid abstract type. Use 'conference', 'journal', or 'symposium'"
            exit 1
            ;;
    esac
    
    if [ -d "$source_dir" ]; then
        mv "$source_dir" "$dest_dir"
        echo "Moved {{abstract_name}} to presented {{abstract_type}} abstracts"
    else
        echo "Error: {{abstract_name}} not found in accepted {{abstract_type}} abstracts"
    fi

# Compile abstract to PDF
compile abstract_type abstract_name:
    #!/usr/bin/env bash
    # Try to find the abstract in any status folder
    abstract_found=false
    for status in submitted accepted presented; do
        case "{{abstract_type}}" in
            "conference")
                abstract_dir="{{conference_dir}}/$status/{{abstract_name}}"
                ;;
            "journal")
                abstract_dir="{{journal_dir}}/$status/{{abstract_name}}"
                ;;
            "symposium")
                abstract_dir="{{symposium_dir}}/$status/{{abstract_name}}"
                ;;
        esac
        
        if [ -d "$abstract_dir" ]; then
            cd "$abstract_dir"
            for qmd_file in *.qmd; do
                if [ -f "$qmd_file" ]; then
                    echo "Compiling $qmd_file..."
                    quarto render "$qmd_file"
                    abstract_found=true
                fi
            done
            break
        fi
    done
    
    if [ "$abstract_found" = false ]; then
        echo "Error: {{abstract_name}} not found in {{abstract_type}} abstracts"
    fi

# Check upcoming deadlines
deadlines:
    @echo "Checking upcoming abstract deadlines..."
    @grep -E "Due:|Deadline:" "{{tracking_dir}}/deadlines.md" | head -10

# Show abstract statistics
stats:
    #!/usr/bin/env bash
    echo "Abstract Submission Statistics:"
    echo "==============================="
    
    # Count abstracts by type and status
    for type in conference journal symposium; do
        echo ""
        echo "$type abstracts:"
        case "$type" in
            "conference") base_dir="{{conference_dir}}" ;;
            "journal") base_dir="{{journal_dir}}" ;;
            "symposium") base_dir="{{symposium_dir}}" ;;
        esac
        
        submitted=$(find "$base_dir/submitted" -maxdepth 1 -type d ! -path "*/submitted" | wc -l)
        accepted=$(find "$base_dir/accepted" -maxdepth 1 -type d ! -path "*/accepted" | wc -l)
        presented=$(find "$base_dir/presented" -maxdepth 1 -type d ! -path "*/presented" | wc -l)
        
        echo "  Submitted: $submitted"
        echo "  Accepted: $accepted"
        echo "  Presented: $presented"
        
        if [ $submitted -gt 0 ] && [ $accepted -gt 0 ]; then
            acceptance_rate=$(echo "scale=1; $accepted * 100 / $submitted" | bc -l)
            echo "  Acceptance rate: $acceptance_rate%"
        fi
    done

# Word count for abstract
wordcount abstract_type abstract_name:
    #!/usr/bin/env bash
    # Try to find the abstract in any status folder
    for status in submitted accepted presented; do
        case "{{abstract_type}}" in
            "conference")
                abstract_dir="{{conference_dir}}/$status/{{abstract_name}}"
                ;;
            "journal")
                abstract_dir="{{journal_dir}}/$status/{{abstract_name}}"
                ;;
            "symposium")
                abstract_dir="{{symposium_dir}}/$status/{{abstract_name}}"
                ;;
        esac
        
        if [ -d "$abstract_dir" ]; then
            cd "$abstract_dir"
            for qmd_file in *.qmd; do
                if [ -f "$qmd_file" ]; then
                    echo "Word count for $qmd_file:"
                    # Count words in abstract section only
                    sed -n '/^# Abstract/,/^---/p' "$qmd_file" | wc -w
                fi
            done
            exit 0
        fi
    done
    echo "Error: {{abstract_name}} not found in {{abstract_type}} abstracts"

# Update tracking files
update-tracking abstract_type abstract_name status:
    #!/usr/bin/env bash
    echo "Updating tracking for {{abstract_name}}..."
    # This is a placeholder for more sophisticated tracking updates
    # Could integrate with calendar systems, notification systems, etc.
    echo "Abstract: {{abstract_name}}"
    echo "Type: {{abstract_type}}"  
    echo "Status: {{status}}"
    echo "Date: $(date)"
    echo ""

# Clean up empty directories
clean:
    @echo "Cleaning up empty directories..."
    @find "{{abstracts_dir}}" -type d -empty -not -path "*/.*" -delete
    @echo "Done"

# Initialize abstracts workspace
init:
    #!/usr/bin/env bash
    echo "Initializing abstracts workspace..."
    
    # Ensure all directories exist
    mkdir -p "{{conference_dir}}"/{submitted,accepted,presented}
    mkdir -p "{{journal_dir}}"/{submitted,accepted,presented}
    mkdir -p "{{symposium_dir}}"/{submitted,accepted,presented}
    mkdir -p "{{tracking_dir}}"
    
    echo "Abstracts workspace initialized!"
    echo "Use 'just new-conference <name> <conference>' to create your first conference abstract"
    echo "Use 'just new-journal <name> <journal>' to create your first journal abstract"
    echo "Use 'just new-symposium <name> <event>' to create your first symposium abstract"
