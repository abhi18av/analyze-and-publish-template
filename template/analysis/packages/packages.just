# Compile a Zig file
zig-build file:
    zig build-exe zig/{{file}}.zig -O ReleaseSafe -femit-bin=../pbin/{{file}}

# Run a compiled Zig binary
zig-run file:
    ../pbin/{{file}}
