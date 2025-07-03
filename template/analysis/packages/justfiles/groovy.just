# Groovy Package Development Automation
# Tools for creating, testing, and building Groovy research libraries

# Create a new Groovy library package
create-groovy-package name description="Research Groovy library":
    #!/usr/bin/env bash
    package_dir="groovy/{{name}}"
    mkdir -p "${package_dir}/src/main/groovy"
    
    # Initialize a basic Gradle project
    cd "${package_dir}"
    gradle init --type groovy-library --dsl groovy --package "{{name}}"
    
    # Copy template files
    if [ -f "../../templates/groovy-library/README.md" ]; then
        cp "../../templates/groovy-library/README.md" README.md
    fi
    
    echo "📦 Created Groovy package: ${package_dir}"
    echo "📝 To get started:"
    echo "   cd ${package_dir}"
    echo "   gradle build"

# Test a Groovy package
test-groovy package:
    #!/usr/bin/env bash
    if [ -d "groovy/{{package}}" ]; then
        cd "groovy/{{package}}"
        gradle test
    else
        echo "❌ Package not found: groovy/{{package}}"
        exit 1
    fi

# Build a Groovy package
build-groovy package:
    #!/usr/bin/env bash
    if [ -d "groovy/{{package}}" ]; then
        cd "groovy/{{package}}"
        gradle build
    else
        echo "❌ Package not found: groovy/{{package}}"
        exit 1
    fi

# Clean a Groovy package
clean-groovy package:
    #!/usr/bin/env bash
    if [ -d "groovy/{{package}}" ]; then
        cd "groovy/{{package}}"
        gradle clean
    else
        echo "⚠️  No build artifacts to clean for groovy/{{package}}"
    fi

