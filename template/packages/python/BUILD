py_library(
    name = "my_package",
    srcs = glob(["my_package/**/*.py"]),
    visibility = ["//visibility:public"],
)

py_test(
    name = "core_test",
    srcs = ["tests/core_test.py"],
    deps = [":my_package"],
    imports = ["."],
)
