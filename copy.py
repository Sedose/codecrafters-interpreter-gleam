import pyperclip
from pathlib import Path

all_code = "\n\n".join(file.read_text() for file in Path("src").rglob("*.gleam"))
pyperclip.copy(all_code)
