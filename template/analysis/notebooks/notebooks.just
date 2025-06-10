# Run exploratory data analysis
eda:
    @echo "Running EDA notebooks..."
    {% if programming_language == "Python" or programming_language == "Both" %}
    jupyter nbconvert --execute notebooks/eda/*.ipynb --to html
    {% endif %}
    {% if programming_language == "R" or programming_language == "Both" %}
    Rscript -e "rmarkdown::render('notebooks/eda/eda.Rmd')"
    {% endif %}

# Create a new notebook
new-notebook name:
    @mkdir -p notebooks
    {% if programming_language == "Python" or programming_language == "Both" %}
    @echo "Creating Python notebook: {{name}}.ipynb"
    @cp templates/notebook_templates/python_template.ipynb notebooks/{{name}}.ipynb
    {% endif %}
    {% if programming_language == "R" or programming_language == "Both" %}
    @echo "Creating R notebook: {{name}}.Rmd"
    @cp templates/notebook_templates/r_template.Rmd notebooks/{{name}}.Rmd
    {% endif %}



# Variables
EXPERIMENTS_LOG := experiments_log.md

# Helper to get UTC timestamp in ISO format (YYYY-MM-DDThhmmZ)
timestamp := `date -u +"%Y-%m-%dT%H%MZ"`

# Usage: just new-experiment SUBSTAGE "short-description"
new-experiment substage desc:
    # Create experiment folder with timestamp and description
    ts={{timestamp}}
    folder="notebooks/python/{{substage}}/experiments/${ts}_{{desc// /_}}"
    mkdir -p "$folder"
    # Create Quarto notebook
    cp experiment_template.qmd "$folder/experiment.qmd"
    # Create experiment metadata file
    cp experiment_template.md "$folder/experiment.md"
    # Fill in some info in experiment.md
    sed -i "" "s/{{EXPERIMENT_ID}}/${ts}_{{desc// /_}}/g" "$folder/experiment.md"
    sed -i "" "s/{{SUBSTAGE}}/{{substage}}/g" "$folder/experiment.md"
    sed -i "" "s/{{AUTHOR}}/abhi18av/g" "$folder/experiment.md"
    sed -i "" "s/{{DATE}}/$ts/g" "$folder/experiment.md"
    echo "Experiment initialized at $folder"

# Usage: just update-history SUBSTAGE "short-description" "key-result-metric"
update-history substage desc result:
    ts={{timestamp}}
    id="${ts}_{{desc// /_}}"
    echo "| $id | {{substage}} | abhi18av | $ts | {{desc}} | {{result}} |" >> {{EXPERIMENTS_LOG}}
    echo "Updated experiment history with $id"

# Initialize log file header
init-history:
    if [ ! -f {{EXPERIMENTS_LOG}} ]; then \
      echo '| Experiment ID | Stage | Author | Date/Time (UTC) | Description | Key Result/Metric |' >> {{EXPERIMENTS_LOG}}; \
      echo '|---------------|-------|--------|-----------------|-------------|-------------------|' >> {{EXPERIMENTS_LOG}}; \
      echo "Initialized experiment log at {{EXPERIMENTS_LOG}}"; \
    else \
      echo "Experiment log already exists."; \
    fi

# Variables for directories
NOTEBOOKS_PYTHON := notebooks/python
SCRIPTS_PYTHON := scripts/python

NOTEBOOKS_R := notebooks/r
SCRIPTS_R := scripts/r

# Extract Python scripts from Jupyter and Quarto notebooks
extract-python:
    mkdir -p {{SCRIPTS_PYTHON}}
    # Extract from Jupyter Notebooks
    for nb in $(find {{NOTEBOOKS_PYTHON}} -name '*.ipynb'); do \
      jupyter nbconvert --to script "$$nb" --output-dir="{{SCRIPTS_PYTHON}}"; \
    done
    # Extract from Quarto Notebooks
    for qmd in $(find {{NOTEBOOKS_PYTHON}} -name '*.qmd'); do \
      quarto extract "$$qmd" --to "{{SCRIPTS_PYTHON}}"; \
    done

# Extract R scripts from Jupyter and Quarto notebooks
extract-r:
    mkdir -p {{SCRIPTS_R}}
    # Extract from Jupyter Notebooks
    for nb in $(find {{NOTEBOOKS_R}} -name '*.ipynb'); do \
      jupyter nbconvert --to script "$$nb" --output-dir="{{SCRIPTS_R}}"; \
    done
    # Extract from Quarto Notebooks
    for qmd in $(find {{NOTEBOOKS_R}} -name '*.qmd'); do \
      quarto extract "$$qmd" --to "{{SCRIPTS_R}}"; \
    done

# Extract all scripts
extract-all: extract-python extract-r
