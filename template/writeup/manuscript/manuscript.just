# Manuscript Management Tasks

# === Setup and Initialization ===
manuscript-init: # Initialize manuscript structure
    mkdir -p src assets/{figures,tables,supplementary} _output/{pdf,docx,html}/{draft,final} reviews/{feedback,responses,revisions} submissions/{preprint}
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
manuscript-prepare-submission journal="preprint": # Prepare submission package
    mkdir -p submissions/{{journal}}
    zip -r submissions/{{journal}}/submission-$(date +%Y%m%d).zip \
        src/*.qmd \
        src/*.bib \
        assets/figures/* \
        assets/tables/* \
        assets/supplementary/* \
        _output/pdf/final/*

# === Bibliography Management ===
manuscript-update-bib: # Update bibliography
    quarto tools citeproc src/index.qmd

manuscript-check-bib: # Check bibliography for issues
    quarto tools citeproc --check src/index.qmd

# === Version Control ===
manuscript-sync: # Sync with version control
    git add src assets _quarto.yml
    git commit -m "Update manuscript" || true

manuscript-backup: # Create backup
    tar -czf manuscript-backup-$(date +%Y%m%d).tar.gz .

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

# === Default Task ===
default:
    @just --list
