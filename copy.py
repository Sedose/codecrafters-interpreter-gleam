import pyperclip
from pathlib import Path

all_code = "\n\n".join(
    [file.read_text() for file in Path("src").rglob("*") if file.is_file()] + 
    [Path("gleam.toml").read_text()]
)
pyperclip.copy(all_code)
