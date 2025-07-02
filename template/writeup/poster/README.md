# Poster Management System

This directory provides a structured and automated system for creating, managing, and rendering academic and professional posters. It supports multiple templates and output formats, and includes a `justfile` for automating common tasks.

## Directory Structure

```
poster/
├── README.md                 # This file
├── _quarto.yml               # Global quarto configuration
├── justfile                  # Automation tasks
├── templates/                # Poster templates
│   ├── academic/             # Academic research posters
│   ├── conference/           # Conference posters
│   └── professional/         # Professional/corporate posters
├── posters/                  # Your posters
│   ├── academic/             # Academic posters
│   ├── conference/           # Conference posters
│   └── professional/         # Professional posters
├── styles/                   # Styling resources
│   └── logo.png              # Institution/organization logo
└── _output/                  # Rendered posters
    ├── html/                 # HTML output
    │   ├── draft/            # Draft versions
    │   └── final/            # Final versions
    └── pdf/                  # PDF output
        ├── draft/            # Draft versions
        └── final/            # Final versions
```

## Available Templates

The poster system includes several specialized templates:

1. **Academic Poster**: Research-focused with sections for methods, results, and analysis.
2. **Conference Poster**: Professional presentation for academic conferences with emphasis on visual clarity.
3. **Professional Poster**: Business-oriented with sections for solutions, ROI, and impact.

Each template is pre-configured with appropriate styling, layout, and placeholder content.

## Automation with Just

The `justfile` provides a comprehensive set of commands for managing your posters. Run from the `poster/` directory.

### Creating New Posters

```bash
# Create a new academic poster
just create-academic research-poster

# Create a conference poster
just create-conference conference-poster

# Create a professional poster
just create-professional business-poster
```

### Rendering Posters

```bash
# Render an academic poster to PDF
just render-poster academic research-poster format=pdf

# Render a conference poster to HTML
just render-poster conference conference-poster format=html

# Render to the 'final' output folder
just render-poster professional business-poster version=final
```

### Other Commands

```bash
# List all available commands
just

# List all posters
just list-posters

# List available templates
just list-templates

# Clone a poster to create a new version
just clone-poster original-poster new-poster academic

# Initialize a new poster project
just poster-init

# Clean draft output directories
just clean

# Clean all output directories
just clean-all

# Export a poster as PDF with timestamp
just export-pdf academic research-poster

# Create a differently sized version of an existing poster
just resize-poster academic research-poster size=42x30
```

## Customization

- **Logo**: Replace the default logo in `styles/logo.png` with your institution or organization logo.
- **Colors**: Adjust header, footer, and section title colors in the poster YAML frontmatter.
- **Fonts**: Customize fonts, sizes, and weights in the poster YAML frontmatter.
- **Columns**: Change the number of columns in the poster layout as needed.

## Workflow Integration

The poster system is designed to integrate with your existing workflow:

- **Version Control**: Each poster is stored in its own directory for easier version control.
- **Multiple Sizes**: Create different sized versions of the same poster for different venues.
- **Output Management**: Separate output directories for draft and final versions.
- **Templating**: Consistent structure and branding across all posters.

This system provides a robust and flexible way to manage your posters, ensuring consistency and efficiency in your poster creation workflow.
