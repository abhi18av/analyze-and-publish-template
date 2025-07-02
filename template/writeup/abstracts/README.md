# Study Abstracts Directory

This directory contains templates and organizational structure for managing study abstracts for conferences, journals, and symposiums.

**Location:** `/writeup/abstracts/` - Standalone abstracts management system within the writeup project structure.

## Directory Structure

```
abstracts/
├── templates/          # Abstract templates for different venues
│   ├── conference/     # Conference abstract templates
│   ├── journal/        # Journal abstract templates
│   └── symposium/      # Symposium and workshop templates
├── conference/         # Conference abstracts by status
│   ├── submitted/      # Submitted conference abstracts
│   ├── accepted/       # Accepted conference abstracts
│   └── presented/      # Abstracts that have been presented
├── journal/           # Journal abstracts by status
│   ├── submitted/      # Submitted journal abstracts
│   ├── accepted/       # Accepted journal abstracts
│   └── presented/      # Published abstracts (conferences within journals)
├── symposium/         # Symposium and workshop abstracts
│   ├── submitted/      # Submitted symposium abstracts
│   ├── accepted/       # Accepted symposium abstracts
│   └── presented/      # Abstracts that have been presented
└── tracking/          # Abstract tracking and management
    ├── deadlines.md   # Deadline tracking
    ├── reviews.md     # Review feedback and responses
    └── metrics.md     # Presentation metrics and outcomes
```

## Abstract Types Supported

- **Conference Abstracts**: Academic conferences, professional meetings
- **Journal Abstracts**: Journal submission abstracts, special issues
- **Symposium Abstracts**: Workshops, symposiums, invited talks

## Usage

1. Start with the appropriate template from `templates/`
2. Copy to the relevant category folder (`conference/`, `journal/`, `symposium/`)
3. Place in `submitted/` during initial submission
4. Move to `accepted/` upon acceptance
5. Move to `presented/` after presentation/publication
6. Track progress in `tracking/`

## Templates Include

- Standard conference abstract formats
- Journal abstract templates
- Symposium presentation abstracts
- Poster session formats
- Lightning talk templates
- Workshop abstracts

## Automation with Just

The `justfile` provides automation for common tasks. Run from the `abstracts/` directory:

```bash
# Create new abstracts
just new-conference "study-name" "Conference-Name-2024"
just new-journal "manuscript-abstract" "Journal-Name"
just new-symposium "workshop-talk" "Symposium-Name"

# Manage workflow
just list-submitted              # See all pending abstracts
just accept conference study-name # Move to accepted
just present conference study-name # Move to presented

# Generate outputs
just compile conference study-name   # Render to PDF
just wordcount conference study-name # Check word limits
just stats                          # View statistics
just deadlines                     # Check upcoming deadlines
```

## Integration with Grant Applications

Abstracts in this directory can be:
- Referenced in grant applications as preliminary results
- Used to demonstrate research dissemination
- Linked to ongoing projects in the main grants system
- Tracked for impact metrics and citations
