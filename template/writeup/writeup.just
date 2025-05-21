import "manuscript/manuscript.just"


# === Common Tasks ===
clean-all: # Clean all generated files
    rm -rf */_book
    rm -rf */_site
    rm -rf */*_files
    rm -rf */_output

# === Poster Tasks ===
[working-directory: 'poster']
poster-new name="new-poster" template="default": # Create a new poster
    @mkdir -p {{name}}
    quarto create presentation --template {{template}} {{name}}/index.qmd

poster-render name: # Render poster to PDF
    quarto render {{name}}/index.qmd --to pdf

poster-preview name: # Preview poster with live reload
    quarto preview {{name}}/index.qmd

poster-clean name: # Clean poster generated files
    rm -rf {{name}}/_book
    rm -rf {{name}}/index_files

# === Presentation Tasks ===
[working-directory: 'presentation']
presentation-new name="new-presentation" template="revealjs": # Create new presentation
    @mkdir -p {{name}}
    quarto create presentation --template {{template}} {{name}}/index.qmd

presentation-render name format="revealjs": # Render presentation
    quarto render {{name}}/index.qmd --to {{format}}

presentation-preview name: # Preview presentation with live reload
    quarto preview {{name}}/index.qmd

presentation-clean name: # Clean presentation generated files
    rm -rf {{name}}/_book
    rm -rf {{name}}/index_files

presentation-pdf name: # Export presentation to PDF
    quarto render {{name}}/index.qmd --to pdf

presentation-pptx name: # Export presentation to PowerPoint
    quarto render {{name}}/index.qmd --to pptx

# === Report Tasks ===
[working-directory: 'report']
report-new name="new-report" template="default": # Create new report
    @mkdir -p {{name}}
    quarto create document --template {{template}} {{name}}/index.qmd

report-render name: # Render report
    quarto render {{name}}/index.qmd

report-preview name: # Preview report with live reload
    quarto preview {{name}}/index.qmd

report-clean name: # Clean report generated files
    rm -rf {{name}}/_book
    rm -rf {{name}}/index_files

report-pdf name: # Export report to PDF
    quarto render {{name}}/index.qmd --to pdf

report-word name: # Export report to Word
    quarto render {{name}}/index.qmd --to docx

report-html name: # Export report to HTML
    quarto render {{name}}/index.qmd --to html

# === Asset Management ===
[working-directory: 'assets-figtables']
figures-sync: # Sync figures with version control
    git add figures/
    git commit -m "Update figures" || true

tables-sync: # Sync tables with version control
    git add tables/
    git commit -m "Update tables" || true

# === Bibliography Management ===
[working-directory: '..']
bib-update: # Update bibliography
    quarto tools citeproc

bib-check: # Check bibliography for issues
    quarto tools citeproc --check

# === Export and Archive ===
export-all: # Export all documents to PDF
    quarto render */index.qmd --to pdf

archive-all: # Create backup of all documents
    tar -czf writeup-backup-$(date +%Y%m%d).tar.gz poster/ presentation/ report/ manuscript/
