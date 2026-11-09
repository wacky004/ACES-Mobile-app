"""Extract searchable chunks from the IT2205 handout PDFs.

Run from the project root:
    python tools/build_handout_chunks.py
"""

from __future__ import annotations

import json
import os
import re
from pathlib import Path

import pymupdf

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_PDF_ROOT = Path(r"C:\Users\DESKTOP-123\Desktop\CPE APP REVIWER\ALL HANDOUT")
PDF_ROOT = Path(os.environ.get("SOURCE_HANDOUT_DIR", DEFAULT_PDF_ROOT))
OUTPUT = ROOT / "assets" / "handouts" / "it2205.json"

FILES = [
    ("Prelim", "01_Handout_1(5).pdf", "prelim", "prelim-01", "01",
     "Introduction to CPE Laws and Professional Practice"),
    ("Prelim", "02_Handout_1(3).pdf", "prelim", "prelim-02", "02",
     "Computer Engineering & IT Laws"),
    ("Midterm", "03_Handout_1(3).pdf", "midterm", "midterm-03", "03",
     "Understanding Contemporary Issues"),
    ("Midterm", "04_Handout_1(3).pdf", "midterm", "midterm-04", "04",
     "Analysis of the Current Computer Engineering & IT Field Using Case Study"),
    ("Pre Finals", "05_Handout_1(3).pdf", "prefinals", "prefinals-05", "05",
     "Responsibilities of Computer Engineers"),
    ("Pre Finals", "06_Handout_1(3).pdf", "prefinals", "prefinals-06", "06",
     "Professionalism at Work"),
    ("Finals", "07_Handout_1(3).pdf", "finals", "finals-07", "07",
     "Computer Engineers at Work"),
    ("Finals", "08_Handout_1(2).pdf", "finals", "finals-08", "08",
     "Application of IT Laws in the Computer Engineering Field"),
]

BOILERPLATE = [
    re.compile(r"^IT2205\s*$"),
    re.compile(r"^\d{2}\s+Handout\s+1\s*$"),
    re.compile(r"^03 Handout 1\s*$"),
    re.compile(r"^\*Property of STI\s*$"),
    re.compile(r"^student\.feedback@sti\.edu\s*$"),
    re.compile(r"^Page \d+ of \d+\s*$"),
]

SENTENCE_SPLIT = re.compile(r"(?<=[.!?])\s+")
WHITESPACE = re.compile(r"\s+")
MAX_CHARS = 700


def clean_page_text(text: str) -> str:
    lines = []
    for raw_line in text.replace("\r", "\n").split("\n"):
        line = WHITESPACE.sub(" ", raw_line).strip()
        if not line:
            continue
        if any(pattern.match(line) for pattern in BOILERPLATE):
            continue
        lines.append(line)
    return " ".join(lines)


def split_chunks(text: str) -> list[str]:
    if not text:
        return []
    sentences = SENTENCE_SPLIT.split(text)
    chunks: list[str] = []
    current: list[str] = []
    size = 0
    for sentence in sentences:
        sentence = sentence.strip()
        if not sentence:
            continue
        if size + len(sentence) > MAX_CHARS and current:
            chunks.append(" ".join(current))
            current = [sentence]
            size = len(sentence)
        else:
            current.append(sentence)
            size += len(sentence) + 1
    if current:
        chunks.append(" ".join(current))
    # Split any oversized chunk on commas/whitespace as a last resort.
    result: list[str] = []
    for chunk in chunks:
        if len(chunk) <= MAX_CHARS * 2:
            result.append(chunk)
        else:
            words = chunk.split(" ")
            buffer: list[str] = []
            length = 0
            for word in words:
                if length + len(word) > MAX_CHARS and buffer:
                    result.append(" ".join(buffer))
                    buffer = [word]
                    length = len(word)
                else:
                    buffer.append(word)
                    length += len(word) + 1
            if buffer:
                result.append(" ".join(buffer))
    return [chunk for chunk in result if len(chunk) > 60]


def main() -> None:
    chunks = []
    for folder, filename, term_id, handout_id, number, title in FILES:
        pdf_path = PDF_ROOT / folder / filename
        document = pymupdf.open(pdf_path)
        for page_index, page in enumerate(document):
            text = clean_page_text(page.get_text())
            for chunk_index, chunk in enumerate(split_chunks(text), start=1):
                chunks.append({
                    "id": f"{handout_id}-p{page_index + 1}-c{chunk_index}",
                    "termId": term_id,
                    "handoutId": handout_id,
                    "handoutNumber": number,
                    "handoutTitle": title,
                    "page": page_index + 1,
                    "text": chunk,
                })
        document.close()

    payload = {
        "subjectId": "it2205",
        "subject": "Computer Engineering Laws and Discipline",
        "chunks": chunks,
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {len(chunks)} chunks to {OUTPUT}")
    by_term: dict[str, int] = {}
    for chunk in chunks:
        by_term[chunk["termId"]] = by_term.get(chunk["termId"], 0) + 1
    print("Chunks per term:", by_term)


if __name__ == "__main__":
    main()
