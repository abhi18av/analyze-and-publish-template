# F# Package Development Automation
# Tools for creating, testing, and building F# research libraries

# Create a new F# library package
create-fsharp-package name description="Research F# library":
    #!/usr/bin/env bash
    package_dir="fsharp/{{name}}"
    mkdir -p "${package_dir}"
    
    # Create F# project structure
    dotnet new classlib -lang "F#" -n "{{name}}" -o "${package_dir}"
    
    # Add test project
    dotnet new xunit -lang "F#" -n "{{name}}.Tests" -o "${package_dir}.Tests"
    
    # Create solution and add projects
    dotnet new sln -n "{{name}}" -o "${package_dir}/.."
    dotnet sln "${package_dir}/../{{name}}.sln" add "${package_dir}/{{name}}.fsproj"
    dotnet sln "${package_dir}/../{{name}}.sln" add "${package_dir}.Tests/{{name}}.Tests.fsproj"
    
    # Add test reference
    dotnet add "${package_dir}.Tests/{{name}}.Tests.fsproj" reference "${package_dir}/{{name}}.fsproj"
    
    # Copy template files
    if [ -f "templates/fsharp-library/README.md" ]; then
        cp "templates/fsharp-library/README.md" "${package_dir}/README.md"
    fi
    
    echo "📦 Created F# package: ${package_dir}"
    echo "📝 To get started:"
    echo "   cd ${package_dir}"
    echo "   dotnet restore"
    echo "   dotnet build"
    echo "   dotnet test ../{{name}}.Tests/"

# Test an F# package
test-fsharp package:
    #!/usr/bin/env bash
    if [ -d "fsharp/{{package}}" ]; then
        cd "fsharp/{{package}}"
        dotnet test
    else
        echo "❌ Package not found: fsharp/{{package}}"
        exit 1
    fi

# Build an F# package
build-fsharp package:
    #!/usr/bin/env bash
    if [ -d "fsharp/{{package}}" ]; then
        cd "fsharp/{{package}}"
        dotnet build
    else
        echo "❌ Package not found: fsharp/{{package}}"
        exit 1
    fi
