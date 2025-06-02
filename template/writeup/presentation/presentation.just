# === Default Task ===
default:
    @just --list

# Manuscript Management Tasks

# === Setup and Initialization ===

#NOTE:  quarto use template grantmcdermott/quarto-revealjs-clean

manuscript-init: # Initialize manuscript structure
    mkdir -p src assets/{figures,tables,supplementary} _output/{pdf,docx,html}/{draft,final} reviews/{feedback,responses,revisions} submissions/{preprint}
    touch _quarto.yml

# === Rendering and Preview ===

manuscript-render format="pdf" version="draft": # Render manuscript
    quarto render src/index.qmd --to {{format}} --_output-dir _output/{{format}}/{{version}}

manuscript-preview: # Preview with live reload
    quarto preview src/index.qmd

manuscript-clean: # Clean generated files
    rm -rf src/_book src/index_files
