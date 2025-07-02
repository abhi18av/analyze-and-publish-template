# Presentation Management System

This directory provides a structured and automated system for creating, managing, and rendering presentations. It supports multiple templates (academic, corporate, workshop) and output formats, and includes a `justfile` for automating common tasks.

## Directory Structure

```
presentation/
├── README.md                 # This file
├── _quarto.yml               # Global quarto configuration
├── _brand.yml                # Branding configuration
├── justfile                  # Automation tasks
├── templates/                # Presentation templates
│   ├── academic/             # For research talks, conferences
│   ├── corporate/            # For business meetings, pitches
│   ├── workshop/             # For interactive training
│   └── poster/               # For academic posters
├── presentations/            # Your presentations
│   ├── new-academic-presentation/ # Example presentation
│   └── posters/                # Your posters
├── assets/                   # Shared assets
│   ├── figures/
│   ├── tables/
│   └── graphics/
└── _output/                  # Rendered presentations
    ├── html/
    │   ├── draft/
    │   └── final/
    ├── pdf/
    │   ├── draft/
    │   └── final/
    └── pptx/
        ├── draft/
        └── final/
```

## Automation with Just

The `justfile` provides a comprehensive set of commands for managing your presentations. Run from the `presentation/` directory.

### Creating New Presentations

```bash
# Create a new academic presentation
just create-academic name="my-research-talk"

# Create a new corporate presentation
just create-corporate name="q3-business-review"

# Create a new workshop
just create-workshop name="intro-to-quarto"

# Create a new academic poster
just create-poster name="my-conference-poster"
```

### Rendering Presentations

```bash
# Render a presentation to HTML (default)
just render-presentation name="my-research-talk" format="revealjs"

# Render a presentation to PDF
just render-presentation name="my-research-talk" format="pdf"

# Render to the 'final' output folder
just render-presentation name="my-research-talk" version="final"

# Render a poster to PDF
just render-poster name="my-conference-poster"
```

### Other Commands

```bash
# List all available commands
just

# List all presentations
just list-presentations

# List all posters
just list-posters

# Clone a presentation to create a new version
just clone-presentation source="my-research-talk" target="my-updated-talk"

# Initialize a new presentation project
just presentation-init

# Clean all generated files
just presentation-clean
```

## Branding and Customization

- **Global styles** are defined in `_quarto.yml`.
- **Branding** (colors, logos, fonts) is managed in `_brand.yml`.
- **Templates** can be customized in the `templates/` directory.

This system provides a robust and flexible way to manage your presentations, ensuring consistency and efficiency in your workflow. It is designed to be easily extensible to support additional templates and formats as needed.
