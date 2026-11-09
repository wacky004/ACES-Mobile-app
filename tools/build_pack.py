"""Build and validate the bundled IT2205 subject pack.

Run from the project root:
    python tools/build_pack.py
"""

from __future__ import annotations

import json
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))

import questions_finals  # noqa: E402
import questions_midterm  # noqa: E402
import questions_prefinals  # noqa: E402
import questions_prelim  # noqa: E402

TERMS = [
    {"id": "prelim", "name": "Prelim", "order": 1, "defaultWeight": 20},
    {"id": "midterm", "name": "Midterm", "order": 2, "defaultWeight": 20},
    {"id": "prefinals", "name": "Pre-Finals", "order": 3, "defaultWeight": 20},
    {"id": "finals", "name": "Finals", "order": 4, "defaultWeight": 40},
]

HANDOUTS = [
    {
        "id": "prelim-01",
        "termId": "prelim",
        "number": "01",
        "title": "Introduction to CPE Laws and Professional Practice",
    },
    {
        "id": "prelim-02",
        "termId": "prelim",
        "number": "02",
        "title": "Computer Engineering & IT Laws",
    },
    {
        "id": "midterm-03",
        "termId": "midterm",
        "number": "03",
        "title": "Understanding Contemporary Issues",
    },
    {
        "id": "midterm-04",
        "termId": "midterm",
        "number": "04",
        "title": "Analysis of the Current Computer Engineering & IT Field Using Case Study",
    },
    {
        "id": "prefinals-05",
        "termId": "prefinals",
        "number": "05",
        "title": "Responsibilities of Computer Engineers",
    },
    {
        "id": "prefinals-06",
        "termId": "prefinals",
        "number": "06",
        "title": "Professionalism at Work",
    },
    {
        "id": "finals-07",
        "termId": "finals",
        "number": "07",
        "title": "Computer Engineers at Work",
    },
    {
        "id": "finals-08",
        "termId": "finals",
        "number": "08",
        "title": "Application of IT Laws in the Computer Engineering Field",
    },
]

PACK = {
    "id": "it2205",
    "subject": "Computer Engineering Laws and Discipline",
    "code": "IT2205",
    "org": "ACES - Association of Computer Engineering Students of STI Ortigas-Cainta",
    "version": "1.0.0",
    "description": (
        "Prelim to finals reviewer covering computer engineering law, ethics, "
        "professionalism, contemporary issues, and the CPE profession."
    ),
    "authors": ["ACES", "IT2205 Faculty"],
    "license": "For ACES classroom use only. Handout content is property of STI.",
    "terms": TERMS,
    "handouts": HANDOUTS,
    "questions": [],
}


def build_questions() -> list[dict]:
    raw = (
        questions_prelim.QUESTIONS
        + questions_midterm.QUESTIONS
        + questions_prefinals.QUESTIONS
        + questions_finals.QUESTIONS
    )
    term_ids = {term["id"] for term in TERMS}
    handout_ids = {handout["id"] for handout in HANDOUTS}
    seen_ids = set()
    built = []

    for index, entry in enumerate(raw):
        (
            question_id,
            term_id,
            handout_id,
            topic,
            difficulty,
            stem,
            correct,
            distractors,
            explanation,
            page,
        ) = entry

        if question_id in seen_ids:
            raise ValueError(f"Duplicate question id: {question_id}")
        seen_ids.add(question_id)
        if term_id not in term_ids:
            raise ValueError(f"{question_id}: unknown term {term_id}")
        if handout_id not in handout_ids:
            raise ValueError(f"{question_id}: unknown handout {handout_id}")
        if difficulty not in {"easy", "medium", "hard"}:
            raise ValueError(f"{question_id}: bad difficulty {difficulty}")
        if not stem.strip():
            raise ValueError(f"{question_id}: empty stem")
        if not explanation.strip():
            raise ValueError(f"{question_id}: empty explanation")
        if len(distractors) != 3:
            raise ValueError(f"{question_id}: needs exactly 3 distractors")
        option_set = {correct, *distractors}
        if len(option_set) != 4:
            raise ValueError(f"{question_id}: duplicate option text")
        if not 1 <= page <= 5:
            raise ValueError(f"{question_id}: source page out of range")

        options = [correct, *distractors]
        rng = random.Random(9000 + index)
        rng.shuffle(options)
        built.append(
            {
                "id": question_id,
                "termId": term_id,
                "handoutId": handout_id,
                "topic": topic,
                "difficulty": difficulty,
                "stem": stem,
                "options": options,
                "answerIndex": options.index(correct),
                "explanation": explanation,
                "sourcePage": page,
            }
        )
    return built


def validate_pack(pack: dict) -> None:
    if len(pack["questions"]) != 120:
        raise ValueError(f"Expected 120 questions, got {len(pack['questions'])}")
    for term in TERMS:
        term_questions = [
            question
            for question in pack["questions"]
            if question["termId"] == term["id"]
        ]
        if len(term_questions) != 30:
            raise ValueError(
                f"{term['name']} has {len(term_questions)} questions, expected 30"
            )
        difficulty_counts = {"easy": 0, "medium": 0, "hard": 0}
        page_counts: dict[int, int] = {}
        for question in term_questions:
            if len(question["options"]) != 4:
                raise ValueError(f"{question['id']}: expected 4 options")
            if not 0 <= question["answerIndex"] < 4:
                raise ValueError(f"{question['id']}: bad answer index")
            difficulty_counts[question["difficulty"]] += 1
            page_counts[question["sourcePage"]] = (
                page_counts.get(question["sourcePage"], 0) + 1
            )
        print(
            f"  {term['name']:<10} {len(term_questions):>2} items "
            f"(easy {difficulty_counts['easy']}, "
            f"medium {difficulty_counts['medium']}, "
            f"hard {difficulty_counts['hard']}) pages {page_counts}"
        )


def main() -> None:
    print("Building IT2205 pack...")
    questions = build_questions()
    pack = {**PACK, "questions": questions}
    print(f"Total questions: {len(questions)}")
    validate_pack(pack)
    output = ROOT / "assets" / "packs" / "it2205.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(pack, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {output}")

    # Keep the bundled pack in sync with the modified True/False items.
    from build_subjects import add_it2205_tf

    add_it2205_tf()


if __name__ == "__main__":
    main()
