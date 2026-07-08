# Changelog

All notable changes to `nvim-bardic` will be documented in this file.

## Unreleased

## 0.1.0 - 2026-07-08

- Fixed Bardic syntax highlighting so Python keywords are only highlighted inside
  `@py` / `@endpy` embedded Python blocks. Ordinary passage prose and Bardic
  source outside those blocks no longer gets Python keyword highlighting.
- Added a smoke-test regression check for embedded Python syntax highlighting.
- Initial repository scaffold.
- Added Bardic filetype detection, syntax highlighting, folding, snippets,
  CLI integration, graph view, graph index navigation, and live preview.
