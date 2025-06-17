import pyperclip
from pathlib import Path

all_code = "\n\n".join(file.read_text() for file in Path(".").rglob("*.gleam"))
pyperclip.copy(all_code)
