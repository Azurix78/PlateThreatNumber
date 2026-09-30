"""Run the addon against deterministic WoW stubs using Lua 5.1 (pip install lupa)."""
from pathlib import Path
import os
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".tools" / "lua"))
from lupa.lua51 import LuaRuntime

os.chdir(ROOT)
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute((ROOT / "tests" / "test_addon.lua").read_text(encoding="utf-8"))
