## Context

The user wants a new public, MIT-licensed GitHub repository named `nvim-bardic` for a Neovim plugin supporting the Bardic Python interactive fiction development system. The plugin should be feature-equivalent to the existing Bardic VSCode extension where practical. The user corrected that the project/language name is Bardic, not Bard, and chose `nvim-bardic` as the repository name. For the graph feature, the user wants the closest Neovim equivalent to VSCode's interactive story graph: an image-backed graph display plus a companion selectable navigation/index buffer for jumping to passages.

A Witan workflow project and task breakdown were created for this work:

- Project: `wp-create-nvim-bardic-neovim-plugin-4669ad`
- Epic: `tk-deliver-nvim-bardic-bardic-neovim-plugin-e382ae`
- First ready task: `tk-create-and-scaffold-public-github-repository-0fe29b`

## Goals / Non-goals

Goals:

- Create public GitHub repository `feoh/nvim-bardic` under the user's GitHub account.
- License the repository under MIT.
- Use Bardic terminology consistently, including a Neovim filetype of `bardic` for `.bard` files.
- Provide Bardic filetype support, syntax highlighting, snippets or snippet documentation, and folding.
- Integrate with the Bardic CLI/runtime for compile, lint, graph, and passage preview workflows.
- Implement a graph view that closely mirrors the VSCode extension: visual graph display, selectable passage navigation, missing/orphan indicators, stats, refresh, and export.
- Document installation for common Neovim plugin managers, notably the built-in `vim.pack.add()` plugin manager, plus lazy.nvim, packer.nvim, vim-plug, and manual installation.
- Add tests/validation and CI appropriate for a Neovim Lua plugin.

Non-goals:

- Do not name the plugin `bardic.nvim`; the chosen repository is `nvim-bardic`.
- Do not use `bard` as the Neovim filetype; use `bardic` even though the VSCode extension internally uses `languageId: "bard"`.
- Do not require image support to use every plugin feature; provide fallback behavior where practical.

## Files to change

Likely files/components in the new `nvim-bardic` repository:

- `LICENSE` — MIT license text.
- `README.md` — feature overview, requirements, commands, configuration, troubleshooting, and plugin-manager installation instructions.
- `CHANGELOG.md` — initial changelog placeholder.
- `.gitignore` — ignore generated graph files, temporary output, logs, and local tooling artifacts.
- `lua/bardic/init.lua` — public setup entrypoint and default configuration.
- `lua/bardic/config.lua` — configuration normalization and defaults.
- `lua/bardic/commands.lua` — user commands such as `:BardicCompile`, `:BardicLint`, `:BardicGraph`, `:BardicGraphRefresh`, `:BardicGraphExport`, and `:BardicPreview`.
- `lua/bardic/cli.lua` — Bardic CLI/Python invocation, timeouts, temporary files, and error parsing.
- `lua/bardic/parser.lua` — simple parser fallback for passages, choices, jumps, missing targets, orphan passages, and start passage.
- `lua/bardic/graph.lua` — graph data model and conversion from compiled Bardic JSON or fallback parser output.
- `lua/bardic/graph_view.lua` — image-backed graph rendering integration, refresh/export, and fallback display.
- `lua/bardic/graph_index.lua` — companion selectable passage/index buffer for graph navigation.
- `lua/bardic/preview.lua` — live passage preview UI and state/choice handling.
- `python/preview_server.py` or equivalent helper — Bardic runtime subprocess for live preview, adapted from the VSCode extension approach if needed.
- `ftdetect/bardic.lua` — map `.bard` files to filetype `bardic`.
- `ftplugin/bardic.lua` — Bardic buffer options, mappings, and folding setup.
- `syntax/bardic.vim` and/or Tree-sitter-related docs/config — syntax highlighting for Bardic constructs.
- `snippets/` or `doc/snippets.md` — snippet definitions or documented snippet examples for common snippet engines.
- `doc/nvim-bardic.txt` — optional Neovim help documentation.
- `tests/` — parser, graph model, CLI error parsing, and Neovim command tests.
- `.github/workflows/ci.yml` — headless Neovim test/lint workflow.

## Ordered steps

1. Create the public GitHub repository `feoh/nvim-bardic` with MIT license.
2. Scaffold a standard Neovim Lua plugin layout and initial documentation files.
3. Implement `require('bardic').setup()` with configuration for Bardic executable/Python interpreter, timeouts, image backend, graph behavior, and auto-refresh.
4. Add `.bard` file detection using filetype `bardic`.
5. Port/adapt Bardic language support from the VSCode extension: syntax highlighting for passage headers, comments, Python blocks, control flow, imports, directives, assignments, choices, jumps, and expressions.
6. Add folding for Bardic passages and snippet support or snippet documentation matching the VSCode snippets.
7. Implement Bardic CLI integration for compile and lint, including temporary output handling, timeout behavior, quickfix/location-list population, and friendly errors when Bardic is not installed.
8. Build the graph data model from compiled Bardic JSON, including choices, conditional choices, jumps, parameterized/reusable passages, start passage, missing passages, and orphan passages.
9. Implement a simple parser fallback for graph generation when the CLI is unavailable or when missing passage targets prevent successful compilation.
10. Implement the image-backed story graph view using Neovim image capabilities where available, with text fallback for unsupported terminals.
11. Implement the companion graph index/navigation buffer with selectable passages, missing/orphan indicators, stats, and jump-to-source behavior.
12. Add graph refresh/export commands and optional auto-refresh on save.
13. Implement live passage preview using Bardic runtime integration, including optional initial JSON state, rendered output, choices, state editing, and reset.
14. Write README and help documentation with installation instructions for `vim.pack.add()`, lazy.nvim, packer.nvim, vim-plug, and manual package installation.
15. Add tests, formatting/linting configuration, and GitHub Actions CI.
16. Run validation and update documentation based on observed behavior.

## Validation

- Verify `gh auth status` and repository access before creating or changing the GitHub repository.
- Confirm `feoh/nvim-bardic` exists, is public, and contains an MIT license.
- Install the plugin locally in Neovim and confirm `.bard` files receive filetype `bardic`.
- Open sample Bardic files and manually verify highlighting, snippets/documented snippets, and folding.
- Run `:BardicCompile` and `:BardicLint` against valid and invalid `.bard` files and confirm quickfix/error behavior.
- Run `:BardicGraph` with Bardic installed and confirm the graph appears in Neovim, with companion navigation/index buffer.
- Verify graph missing/orphan indicators, stats, refresh, and export behavior.
- Verify graph fallback behavior when Bardic is unavailable or compilation cannot complete due to missing passage targets.
- Run `:BardicPreview` from inside a passage and confirm preview, choice navigation, state injection/editing, and reset work.
- Run automated tests for parser/graph model/CLI handling and headless Neovim plugin behavior.
- Run configured formatting/linting and CI before declaring the work complete.

## Risks & unknowns

- Neovim image display depends on terminal support and optional image backends such as `image.nvim`; behavior may vary by terminal.
- A Neovim graph image cannot exactly replicate VSCode webview click handling, so the closest agreed equivalent is an image display plus selectable navigation/index buffer.
- The exact best rendering path for graph images is unresolved: options include using Bardic's own graph command, Graphviz output, or generated graph data rendered by plugin code.
- Live preview depends on Bardic runtime APIs and the selected Python environment; this may require adaptation from the VSCode `preview_server.py` approach.
- Tree-sitter support for Bardic was not discussed as a requirement; initial highlighting may use Vim syntax unless later work decides otherwise.
- A repository-local `PLAN.md` mirror cannot be written during this FINALIZE phase; only the canonical plan file is written now.
