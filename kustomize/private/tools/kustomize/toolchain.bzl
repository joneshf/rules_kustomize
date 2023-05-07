# We must accommodate loading this file from repositories generated by
# our repository rules.
visibility("public")

_TOOLS_BY_RELEASE = {
    "v5.0.2": {
        struct(os = "darwin", arch = "amd64"): "26bedd5680d8af0e91b5b0ef470d384b158f160413f9e68a0ad23e2b8d17a462",
        struct(os = "darwin", arch = "arm64"): "63b09921ed392c0697ec56118bb46f25fb7c3454d5f9ddaf49b8d1ad96cac12b",
        struct(os = "linux", arch = "amd64"): "112782e22bc5d4f09868a633eda515f48f16fa2338df51844096c7107ca174a1",
        struct(os = "linux", arch = "arm64"): "291e19b486790177bc62695328467c2ff973a91d0e7fdf96b902bb073d9b9724",
        struct(os = "windows", arch = "amd64"): "6adad0254103bca5673a4dd3b35fe4aa7e52ff6620413ba4a921271c8aa58d6c",
        struct(os = "windows", arch = "arm64"): "e60ec24a1df34bd2ddb4770fb88db3348b51bbbd3bc3e32bf140ff0ae6f904e6",
    },
    "v5.0.1": {
        struct(os = "darwin", arch = "amd64"): "4a2b9f7fad0355c8bea08da6dd9c48e790df5f357983280998d80b8dc7ad3def",
        struct(os = "darwin", arch = "arm64"): "b264fe931e85d8ca7c7ac47872695b1fa39fe2b73cfc0d58cbdca0bde69d0bc0",
        struct(os = "linux", arch = "amd64"): "dca623b36aef84fbdf28f79d02e9b3705ff641424ac1f872d5420dadb12fb78d",
        struct(os = "linux", arch = "arm64"): "c6e036c5c7eee4c15f7544e441ced5cb6cf9eba24a011c25008df5617cd2fb85",
        struct(os = "windows", arch = "amd64"): "d9053411276df9fff3abc082fdb6dae4b2901d5b6c6c65d0e27f241dddbb9cb4",
        struct(os = "windows", arch = "arm64"): "3447de7560295843f698358823336d08738509dcafd47ad52385e0549894d51b",
    },
    "v5.0.0": {
        struct(os = "darwin", arch = "amd64"): "75bd0e776a1e1c44639aa017bba9b6a305ce7332b89b9e8089e99fee2b83d04a",
        struct(os = "darwin", arch = "arm64"): "74c576a9d6de9d6abb3e886141635b81e8cf3c2331b011535d4e8b5119f291db",
        struct(os = "linux", arch = "amd64"): "2e8c28a80ce213528251f489db8d2dcbea7c63b986c8f7595a39fc76ff871cd7",
        struct(os = "linux", arch = "arm64"): "e97b12a83e7b9b0407cac97cac4c25bc135c42383bd3764d5544e32c96542eca",
        struct(os = "windows", arch = "amd64"): "19d5e98dbe9a66fc0a75897b6557243c6f9d69c113c1fa4b34c1d3fa892cf74c",
        struct(os = "windows", arch = "arm64"): "55fe8b00b07b5701a6b537287b54bf0b70db05ffa9b0d7aa8f298256c8da57af",
    },
    "v4.5.7": {
        struct(os = "darwin", arch = "amd64"): "6fd57e78ed0c06b5bdd82750c5dc6d0f992a7b926d114fe94be46d7a7e32b63a",
        struct(os = "linux", arch = "amd64"): "701e3c4bfa14e4c520d481fdf7131f902531bfc002cb5062dcf31263a09c70c9",
        struct(os = "linux", arch = "arm64"): "65665b39297cc73c13918f05bbe8450d17556f0acd16242a339271e14861df67",
        struct(os = "windows", arch = "amd64"): "79af25f97bb10df999e540def94e876555696c5fe42d4c93647e28f83b1efc55",
    },
}

_DEFAULT_TOOL_VERSION = "v5.0.2"

def known_release_versions():
    return _TOOLS_BY_RELEASE.keys()

KustomizeInfo = provider(
    doc = "Details pertaining to the Kustomize toolchain.",
    fields = {
        "tool": "Kustomize tool to invoke",
        "version": "This tool's released version name",
    },
)

KustomizeToolInfo = provider(
    doc = "Details pertaining to the Kustomize tool.",
    fields = {
        "binary": "Kustomize tool to invoke",
        "version": "This tool's released version name",
    },
)

def _kustomize_tool_impl(ctx):
    return [KustomizeToolInfo(
        binary = ctx.executable.binary,
        version = ctx.attr.version,
    )]

kustomize_tool = rule(
    implementation = _kustomize_tool_impl,
    attrs = {
        "binary": attr.label(
            mandatory = True,
            allow_single_file = True,
            executable = True,
            cfg = "exec",
            doc = "Kustomize tool to invoke",
        ),
        "version": attr.string(
            mandatory = True,
            doc = "This tool's released version name",
        ),
    },
)

def _toolchain_impl(ctx):
    tool = ctx.attr.tool[KustomizeToolInfo]
    toolchain_info = platform_common.ToolchainInfo(
        kustomizeinfo = KustomizeInfo(
            tool = tool.binary,
            version = tool.version,
        ),
    )
    return [toolchain_info]

kustomize_toolchain = rule(
    implementation = _toolchain_impl,
    attrs = {
        "tool": attr.label(
            mandatory = True,
            providers = [KustomizeToolInfo],
            cfg = "exec",
            doc = "Kustomize tool to use for building kustomizations.",
        ),
    },
)

# buildifier: disable=unnamed-macro
def declare_kustomize_toolchains(kustomize_tool):
    for version, platforms in _TOOLS_BY_RELEASE.items():
        for platform in platforms.keys():
            kustomize_toolchain(
                name = "{}_{}_{}".format(platform.os, platform.arch, version),
                tool = kustomize_tool,
            )

def _translate_host_platform(ctx):
    # NB: This is adapted from rules_go's "_detect_host_platform" function.
    os = ctx.os.name
    if os == "mac os x":
        os = "darwin"
    elif os.startswith("windows"):
        os = "windows"

    arch = ctx.os.arch
    if arch == "aarch64":
        arch = "arm64"
    elif arch == "x86_64":
        arch = "amd64"

    return os, arch

_MODULE_REPOSITORY_NAME = "rules_kustomize"
_CONTAINING_PACKAGE_PREFIX = "//kustomize/private/tools/kustomize"

def _download_tool_impl(ctx):
    if not ctx.attr.arch and not ctx.attr.os:
        os, arch = _translate_host_platform(ctx)
    else:
        if not ctx.attr.arch:
            fail('"os" is set but "arch" is not')
        if not ctx.attr.os:
            fail('"arch" is set but "os" is not')
        os, arch = ctx.attr.os, ctx.attr.arch
    version = ctx.attr.version

    sha256sum = _TOOLS_BY_RELEASE[version][struct(os = os, arch = arch)]
    if not sha256sum:
        fail('No Kustomize tool is available for OS "{}" and CPU architecture "{}" at version {}'.format(os, arch, version))
    ctx.report_progress('Downloading Kustomize tool for OS "{}" and CPU architecture "{}" at version {}.'.format(os, arch, version))
    ctx.download_and_extract(
        url = "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F{version}/kustomize_{version}_{os}_{arch}.tar.gz".format(
            version = version,
            os = os,
            arch = arch,
        ),
        sha256 = sha256sum,
    )

    ctx.template(
        "BUILD.bazel",
        Label("{}:BUILD.tool.bazel".format(_CONTAINING_PACKAGE_PREFIX)),
        executable = False,
        substitutions = {
            "{containing_package_prefix}": "@{}{}".format(_MODULE_REPOSITORY_NAME, _CONTAINING_PACKAGE_PREFIX),
            "{extension}": ".exe" if os == "windows" else "",
            "{version}": version,
        },
    )
    return None

_download_tool = repository_rule(
    implementation = _download_tool_impl,
    attrs = {
        "arch": attr.string(),
        "os": attr.string(),
        "version": attr.string(
            values = _TOOLS_BY_RELEASE.keys(),
            default = _DEFAULT_TOOL_VERSION,
        ),
    },
)

# buildifier: disable=unnamed-macro
def declare_bazel_toolchains(version, toolchain_prefix):
    native.constraint_value(
        name = version,
        constraint_setting = "{}:tool_version".format(_CONTAINING_PACKAGE_PREFIX),
    )
    constraint_value_prefix = "@{}//kustomize/private/tools".format(_MODULE_REPOSITORY_NAME)
    for platform in _TOOLS_BY_RELEASE[version].keys():
        native.toolchain(
            name = "{}_{}_{}_toolchain".format(platform.os, platform.arch, version),
            exec_compatible_with = [
                "{}:cpu_{}".format(constraint_value_prefix, platform.arch),
                "{}:os_{}".format(constraint_value_prefix, platform.os),
            ],
            toolchain = toolchain_prefix + (":{}_{}_{}".format(platform.os, platform.arch, version)),
            toolchain_type = "@{}//tools/kustomize:toolchain_type".format(_MODULE_REPOSITORY_NAME),
        )

def _toolchains_impl(ctx):
    ctx.template(
        "BUILD.bazel",
        Label("{}:BUILD.toolchains.bazel".format(_CONTAINING_PACKAGE_PREFIX)),
        executable = False,
        substitutions = {
            "{containing_package_prefix}": "@{}{}".format(_MODULE_REPOSITORY_NAME, _CONTAINING_PACKAGE_PREFIX),
            "{tool_repo}": ctx.attr.tool_repo,
            "{version}": ctx.attr.version,
        },
    )

_toolchains_repo = repository_rule(
    implementation = _toolchains_impl,
    attrs = {
        "tool_repo": attr.string(mandatory = True),
        "version": attr.string(
            values = _TOOLS_BY_RELEASE.keys(),
            default = _DEFAULT_TOOL_VERSION,
        ),
    },
)

def download_tool(name, version = None):
    _download_tool(
        name = name,
        version = version,
    )
    _toolchains_repo(
        name = name + "_toolchains",
        tool_repo = name,
        version = version,
    )
