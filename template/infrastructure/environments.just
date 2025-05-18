# === Environment Management ===

# Install dependencies
install:
    {% if programming_language == "Python" or programming_language == "Both" %}
    pixi install
    {% endif %}
    {% if programming_language == "R" or programming_language == "Both" %}
    Rscript -e "renv::restore()"
    {% endif %}
