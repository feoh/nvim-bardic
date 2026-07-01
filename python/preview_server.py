#!/usr/bin/env python3
"""Preview server placeholder for nvim-bardic.

The implementation will mirror the Bardic VSCode extension's subprocess
protocol: load compiled story JSON on stdin, render passages with BardEngine,
and exchange JSON commands/responses with Neovim.
"""

import json


def main() -> int:
    print(json.dumps({"error": "not-implemented", "message": "Preview server is not implemented yet"}), flush=True)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
