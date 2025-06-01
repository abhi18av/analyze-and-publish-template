# === Default Task ===
default:
    @just --list

# Manuscript Management Tasks

# === Setup and Initialization ===
manuscript-init: # Initialize manuscript structure
    mkdir -p src assets/{figures,tables,supplementary} _output/{pdf,docx,html}/{draft,final} reviews/{feedback,responses,revisions} submissions/{preprint} versions
    touch src/{index,abstract,introduction,methods,results,discussion}.qmd
    touch src/references.bib
    touch _quarto.yml

# === Source Management ===
manuscript-new-section name: # Create a new section file
    touch src/{{name}}.qmd

manuscript-edit-section name: # Open section in default editor
    $EDITOR src/{{name}}.qmd

manuscript-list-sections: # List all section files
    ls -1 src/*.qmd

# === Rendering and Preview ===
manuscript-render format="pdf" version="draft": # Render manuscript
    quarto render src/index.qmd --to {{format}} --_output-dir _output/{{format}}/{{version}}

manuscript-preview: # Preview with live reload
    quarto preview src/index.qmd

manuscript-clean: # Clean generated files
    rm -rf src/_book src/index_files

# === Asset Management ===
manuscript-add-figure name: # Add new figure
    touch assets/figures/{{name}}.qmd

manuscript-add-table name: # Add new table
    touch assets/tables/{{name}}.qmd

manuscript-add-supplementary name: # Add new supplementary material
    touch assets/supplementary/{{name}}.qmd

# === Review Management ===
manuscript-new-feedback: # Create new feedback directory
    mkdir -p reviews/feedback/$(date +%Y%m%d)

manuscript-new-response: # Create new response directory
    mkdir -p reviews/responses/$(date +%Y%m%d)

manuscript-new-revision: # Create new revision directory
    mkdir -p reviews/revisions/$(date +%Y%m%d)

# === Submission Management ===
manuscript-prepare-journal-submission journal: # Prepare journal submission
    mkdir -p submissions/{{journal}}/$(date +%Y%m%d)
    cp _output/pdf/final/* submissions/{{journal}}/$(date +%Y%m%d)/
    cp _output/docx/final/* submissions/{{journal}}/$(date +%Y%m%d)/
    echo "Submission prepared for {{journal}} on $(date)" > submissions/{{journal}}/$(date +%Y%m%d)/README.md

manuscript-prepare-preprint platform: # Prepare preprint submission
    mkdir -p submissions/preprint/{{platform}}/$(date +%Y%m%d)
    cp _output/pdf/final/* submissions/preprint/{{platform}}/$(date +%Y%m%d)/
    cp _output/html/final/* submissions/preprint/{{platform}}/$(date +%Y%m%d)/
    echo "Preprint prepared for {{platform}} on $(date)" > submissions/preprint/{{platform}}/$(date +%Y%m%d)/README.md

# === Bibliography Management ===
manuscript-update-bib: # Update bibliography
    quarto tools citeproc src/index.qmd

manuscript-check-bib: # Check bibliography for issues
    quarto tools citeproc --check src/index.qmd

# === Version Control ===
manuscript-sync: # Sync with version control
    fossil add src assets _quarto.yml
    fossil commit -m "Update manuscript" || true

manuscript-backup: # Create backup
    tar -czf manuscript-backup-$(date +%Y%m%d).tar.gz .

manuscript-track-changes: # Track changes between versions
    fossil diff --brief | grep -E '\.qmd$|\.bib$' | xargs -I{} echo "Changed: {}"

manuscript-show-history: # Show commit history
    fossil timeline -n 10

manuscript-create-branch name: # Create new branch
    fossil branch new {{name}} trunk

manuscript-switch-branch name: # Switch to branch
    fossil checkout {{name}}

manuscript-merge-branch name: # Merge branch into current
    fossil merge {{name}}

manuscript-status: # Show repository status
    fossil status

manuscript-undo: # Undo last commit
    fossil undo

manuscript-tag-version version: # Tag current version
    fossil tag add {{version}}

manuscript-list-tags: # List all version tags
    fossil tag list

manuscript-export-version version: # Export specific version
    fossil checkout {{version}}
    just manuscript-build-all
    fossil checkout trunk

# === Quality Checks ===
manuscript-check: # Check manuscript for issues
    quarto check src/*.qmd

manuscript-spell: # Run spell check
    quarto tools spell src/*.qmd

# === Export Tasks ===
manuscript-export-pdf version="draft": # Export to PDF
    quarto render src/index.qmd --to pdf --_output-dir _output/pdf/{{version}}

manuscript-export-docx version="draft": # Export to Word
    quarto render src/index.qmd --to docx --_output-dir _output/docx/{{version}}

manuscript-export-html version="draft": # Export to HTML
    quarto render src/index.qmd --to html --_output-dir _output/html/{{version}}

# === Helper Tasks ===
manuscript-list-_outputs: # List all _output files
    find _output -type f

manuscript-list-assets: # List all assets
    find assets -type f

manuscript-list-reviews: # List all review files
    find reviews -type f

# === Collaboration Management ===
manuscript-new-collaborator name: # Create new collaborator workspace
    mkdir -p collaborators/{{name}}/responses
    touch collaborators/{{name}}/README.md
    echo "# {{name}}'s Workspace\n\n## Response History" > collaborators/{{name}}/README.md
    fossil branch new collaborator-{{name}} trunk

manuscript-send-to-collaborator name version_name: # Prepare package for collaborator
    fossil checkout collaborator-{{name}}
    mkdir -p collaborators/{{name}}/packages
    zip -r collaborators/{{name}}/packages/manuscript-$(date +%Y%m%d).zip \
        src/*.qmd \
        assets/figures/* \
        assets/tables/* \
        versions/{{version_name}}/manuscript.pdf
    fossil commit -m "Prepared package for {{name}} for version {{version_name}}"
    fossil checkout trunk

# === Review Process Management ===
manuscript-prepare-review-package: # Prepare review package
    fossil branch new review-branch trunk
    fossil checkout review-branch
    mkdir -p reviews/packages/$(date +%Y%m%d)
    cp _output/pdf/draft/* reviews/packages/$(date +%Y%m%d)/
    cp _output/docx/draft/* reviews/packages/$(date +%Y%m%d)/
    echo "Review package prepared on $(date)" > reviews/packages/$(date +%Y%m%d)/README.md
    fossil commit -m "Prepared review package"
    fossil checkout trunk

manuscript-track-review-status: # Track review status
    find reviews -type f -name "*.md" | xargs grep -l "TODO" || echo "No pending reviews"
    fossil status review-branch

# === Enhanced Quality Control ===
manuscript-check-formatting: # Check formatting consistency
    find src -name "*.qmd" -exec grep -l "\\n\\n\\n" {} \;
    find src -name "*.qmd" -exec grep -l "  " {} \;

manuscript-check-references: # Check reference consistency
    quarto tools citeproc --check src/index.qmd
    grep -r "\\[@.*\\]" src/

manuscript-check-figures: # Check figure references
    find src -name "*.qmd" -exec grep -l "!\\[" {} \;
    find assets/figures -type f -name "*.png" -o -name "*.jpg" -o -name "*.pdf" | sort > /tmp/figures.txt
    grep -r "!\\[" src/ | grep -o "!\\[.*\\]" | sort > /tmp/refs.txt
    diff /tmp/figures.txt /tmp/refs.txt

# === Version Management ===
manuscript-create-version version: # Create new version
    mkdir -p versions/{{version}}
    fossil checkout trunk
    cp -r src assets _quarto.yml versions/{{version}}/
    echo "Version {{version}} created on $(date)" > versions/{{version}}/README.md
    fossil tag add {{version}}

manuscript-compare-versions v1 v2: # Compare two versions
    fossil diff --from {{v1}} --to {{v2}} src/

manuscript-merge-review-changes: # Merge review changes
    fossil merge review-branch
    just manuscript-build-all
    fossil commit -m "Merged review changes"

# === Enhanced Build System ===
manuscript-build-all: # Build all formats
    just manuscript-export-pdf version=final
    just manuscript-export-docx version=final
    just manuscript-export-html version=final

manuscript-watch: # Watch for changes and rebuild
    fswatch -o src/ assets/ | xargs -n1 -I{} just manuscript-build-all

# Create a new versioned folder with ISO timestamp
manuscript-new-version version:
    VERSION_DIR="v{{version}}-$(date +%Y-%m-%dT%H-%M-%S)" && \
    mkdir -p versions/$$VERSION_DIR/feedback && \
    echo "Created: versions/$$VERSION_DIR"

# Render draft to the new versioned folder
manuscript-render-version version:
    VERSION_DIR="v{{version}}-$(date +%Y-%m-%dT%H-%M-%S)" && \
    mkdir -p versions/$$VERSION_DIR/feedback && \
    quarto render src/index.qmd --to pdf --output versions/$$VERSION_DIR/draft.pdf && \
    echo "Draft rendered to: versions/$$VERSION_DIR/draft.pdf"

# Add feedback to a specific versioned folder (coauthor feedback colocated with version)
manuscript-add-feedback version_name file:
    cp {{file}} versions/{{version_name}}/feedback/
    echo "Feedback {{file}} added to versions/{{version_name}}/feedback/"

# Only keep the latest draft in _output/
manuscript-export-draft:
    quarto render src/index.qmd --to pdf --output _output/draft.pdf

manuscript-compile stage="draft":
    quarto render src/index.qmd --to pdf --output _output/{{stage}}/manuscript.pdf

manuscript-version-from-final version:
    VERSION_DIR="v{{version}}-$(date +%Y-%m-%dT%H-%M-%S)" && \
    mkdir -p versions/$$VERSION_DIR/feedback && \
    cp _output/final/manuscript.pdf versions/$$VERSION_DIR/ && \
    echo "Version created: versions/$$VERSION_DIR"

manuscript-submit-journal version journal:
    mkdir -p submissions/{{journal}}/{{version}}
    cp versions/{{version}}/manuscript.pdf submissions/{{journal}}/{{version}}/
    echo "Submission prepared for {{journal}} version {{version}}" > submissions/{{journal}}/{{version}}/README.md

manuscript-submit-preprint version platform:
    mkdir -p submissions/preprint/{{platform}}/{{version}}
    cp versions/{{version}}/manuscript.pdf submissions/preprint/{{platform}}/{{version}}/
    echo "Preprint prepared for {{platform}} version {{version}}" > submissions/preprint/{{platform}}/{{version}}/README.md

# === Version Logging ===
# Log and tag each new version in Fossil and append to VERSIONS.md
manuscript-log-version version:
    VERSION_DIR="v{{version}}-$(date +%Y-%m-%dT%H-%M-%S)" && \
    fossil tag add $$VERSION_DIR && \
    echo "- $$VERSION_DIR | $(date) | $(fossil info current | grep uuid)" >> VERSIONS.md && \
    echo "Logged version: $$VERSION_DIR"

# === Feedback Management ===
# List all feedback files for a version
manuscript-list-feedback version_name:
    ls versions/{{version_name}}/feedback/

# Summarize all feedback for a version into a single file
manuscript-summarize-feedback version_name:
    cat versions/{{version_name}}/feedback/* > versions/{{version_name}}/feedback/summary.txt
    echo "Feedback summarized to versions/{{version_name}}/feedback/summary.txt"

# === Clean-Up ===
# Remove empty feedback folders and old temp files
manuscript-clean-versions:
    find versions -type d -empty -delete
    find versions -type f -name '*.tmp' -delete
    echo "Cleaned empty folders and temp files in versions/"

# === Preflight Check ===
# Run all checks before versioning or submission
manuscript-preflight-check:
    just manuscript-check
    just manuscript-check-formatting
    just manuscript-check-references
    just manuscript-check-figures
    just manuscript-spell
    echo "Preflight checks complete."

# === Changelog Management ===
# Append a major change to CHANGELOG.md
manuscript-changelog message:
    echo "- $(date): {{message}}" >> CHANGELOG.md
    echo "Changelog updated."

# === Archive Submission ===
# Zip and archive all files for a submission
manuscript-archive-submission version_name:
    ZIPFILE="archive-{{version_name}}-$(date +%Y%m%d).zip" && \
    zip -r $$ZIPFILE versions/{{version_name}} submissions/*/{{version_name}} && \
    echo "Submission archived as $$ZIPFILE"

# === Documentation ===
# Print workflow documentation
manuscript-docs:
    echo "Manuscript Workflow:\n"
    echo "1. Compile draft/final: just manuscript-compile stage=draft|final"
    echo "2. Create version from final: just manuscript-version-from-final version=2"
    echo "3. Add feedback: just manuscript-add-feedback version_name=... file=..."
    echo "4. List feedback: just manuscript-list-feedback version_name=..."
    echo "5. Summarize feedback: just manuscript-summarize-feedback version_name=..."
    echo "6. Preflight check: just manuscript-preflight-check"
    echo "7. Archive submission: just manuscript-archive-submission version_name=..."
    echo "8. Log version: just manuscript-log-version version=..."
    echo "9. Update changelog: just manuscript-changelog message=..."
    echo "10. See this help: just manuscript-docs"
