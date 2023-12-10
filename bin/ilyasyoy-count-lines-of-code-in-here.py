#!/usr/bin/env python3

import argparse
import pathlib
from dataclasses import dataclass


@dataclass
class Config:
    extension: str
    skip_empty_lines: bool


def parse_args() -> Config:
    parser = argparse.ArgumentParser(
        prog="CodeLinesCounter",
        description="Counts number of lines for a aspecified extension"
    )

    parser.add_argument("extension", type=str)
    parser.add_argument("-s", "--skip-empty",
                        action="store_true")
    args = parser.parse_args()
    config = Config(
        extension=args.extension,
        skip_empty_lines=args.skip_empty
    )

    print(f"Looking for files with extension: {config.extension}")
    if config.skip_empty_lines:
        print("I'll be skipping empty lines")

    return config


def main():
    config = parse_args()

    lines_counter = 0
    cwd = pathlib.Path.cwd()
    for file in cwd.glob("**/*"):
        file = file.relative_to(cwd)
        if file.is_dir():
            continue
        if not file.name.endswith(config.extension):
            continue
        lines = file.read_bytes().splitlines()
        if config.extension:
            lines = [line for line in lines if line.strip()]
        lines_count = len(lines)
        lines_counter += lines_count

    print(f"Lines found: {lines_counter}")


if __name__ == "__main__":
    main()
