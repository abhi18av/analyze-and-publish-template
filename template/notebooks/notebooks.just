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
