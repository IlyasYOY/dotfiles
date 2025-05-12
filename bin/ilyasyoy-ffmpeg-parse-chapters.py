#!/usr/bin/python3

import re
import subprocess
from optparse import OptionParser, Values
from typing import List, NamedTuple

SECONDS_IN_MINUTE = 60


class ChapterInfo(NamedTuple):
    internal_name: str
    start: float
    end: float
    name: str

    @property
    def duration_representation(self) -> str:
        start = int(self.start)

        hours = str(start // SECONDS_IN_MINUTE).rjust(2, '0')
        minutes = str(start % SECONDS_IN_MINUTE).rjust(2, '0')

        return f'{hours}:{minutes}'


def main():
    '''
    Basic implementation was borrowed from 
    https://gist.github.com/dcondrey/469e2850e7f88ac198e8c3ff111bda7c
    '''
    options = _parse_command_line_options()
    if options.infile:
        chapters = find_chapters_in_file(options.infile)
        chapters_result = format_chapters(chapters)
        print(chapters_result)
    else:
        print("no file specified")


def format_chapters(chapters: List[ChapterInfo]) -> str:
    return '  \n'.join(
        chapter.duration_representation + ' ' + chapter.name for chapter in chapters)


def find_chapters_in_file(filename: str) -> List[ChapterInfo]:
    output = _execute_ffmpeg(filename)
    matches = re.findall(
        r'.*Chapter '
        r'#(\d+:\d+)'
        r': start '
        r'(\d+\.\d+)'
        r', end '
        r'(\d+\.\d+)\s*\n\s*'
        r'Metadata:'
        r'\n\s*title\s*:\s*(.*)\n', output)
    return _convert_ffmpeg_response(matches)


def _parse_command_line_options() -> Values:
    parser = OptionParser(
        usage="usage: ffmpeg-chapters-parser [options] filename",
        version="ffmpeg-chapters-parser 1.0")

    parser.add_option('-f', '--file', dest='infile',
                      help='Input File', metavar='FILE')

    options, _ = parser.parse_args()

    return options


def _convert_ffmpeg_response(matches: List) -> List[ChapterInfo]:
    chapters: List[ChapterInfo] = []

    for internal_name, start, end, name in matches:
        chapter = ChapterInfo(internal_name=internal_name,
                              start=float(start), end=float(end), name=name)
        chapters.append(chapter)

    return chapters


def _execute_ffmpeg(filename: str) -> str:
    try:
        command = ['ffmpeg', '-i', filename]
        return subprocess.check_output(
            command, stderr=subprocess.STDOUT, universal_newlines=True)
    except subprocess.CalledProcessError as error:
        return error.output


if __name__ == '__main__':
    main()
