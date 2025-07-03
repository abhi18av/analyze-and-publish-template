# Academic Conference Poster System

Streamlined system for creating academic conference posters with automated workflows and conference-specific templates. Optimized for rapid poster development and conference submission deadlines.

## Simplified Directory Structure

```
poster/
├── README.md                 # This documentation
├── justfile                  # Poster automation commands
├── templates/                # Conference poster templates
│   ├── standard/             # Standard academic poster layout
│   ├── landscape/            # Landscape format posters
│   └── specialized/          # Field-specific templates (bio, cs, physics, etc.)
├── conferences/              # Conference-specific posters
│   ├── 2025/                 # Year-based organization
│   │   ├── neurips/          # Conference folders
│   │   ├── icml/
│   │   └── aaai/
│   └── 2026/
├── assets/                   # Shared poster assets
│   ├── figures/              # Research figures and plots
│   ├── logos/                # Institution and conference logos
│   ├── data/                 # Small datasets for plots
│   └── references/           # BibTeX files
└── output/                   # Generated posters
    ├── drafts/               # Work-in-progress versions
    ├── reviews/              # Versions for internal review
    └── final/                # Submission-ready posters
```

## Conference-Focused Templates

1. **Standard**: Traditional academic poster layout (48"×36" or A0)
2. **Landscape**: Horizontal layout for better readability 
3. **Specialized**: Field-specific layouts optimized for different research areas

## Automation with Just

The `justfile` provides a comprehensive set of commands for managing your posters. Run from the `poster/` directory.

## Quick Start

1. **Initialize the system** (first time only):
   ```bash
   just init
   ```

2. **Create a conference poster**:
   ```bash
   just create neurips 2025 standard
   ```

3. **Edit your poster**: 
   ```bash
   # Edit: conferences/2025/neurips/neurips_poster.qmd
   ```

4. **Render and review**:
   ```bash
   just render neurips 2025        # Creates draft
   just render-review neurips 2025  # Creates review version
   just finalize neurips 2025      # Creates final submission
   ```

## Example Workflow

Creating a poster for NeurIPS 2025:

```bash
# Create poster
just create neurips 2025 standard

# Add your research content to:
# conferences/2025/neurips/neurips_poster.qmd

# Add figures to assets/figures/
just add-figure "my_results.png" "/path/to/my_results.png"

# Render for review
just render-review neurips 2025

# Make final submission
just finalize neurips 2025
```

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
