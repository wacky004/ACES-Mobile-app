"""Build the Embedded Systems (IT2102) and Robot Dynamics (IT1919) content.

The script extracts full-text handout chunks, builds the reader packs, and
authors a stable question bank from curated key terms. It also adds modified
True/False items to the existing IT2205 pack.

Run from the project root:
    python tools/build_subjects.py
"""

from __future__ import annotations

import json
import os
import random
import re
from pathlib import Path

import pymupdf

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_PDF_ROOT = Path(r"C:\Users\DESKTOP-123\Desktop\CPE APP REVIWER\ALL HANDOUT")
PDF_ROOT = Path(os.environ.get("SOURCE_HANDOUT_DIR", DEFAULT_PDF_ROOT))

TERMS = [
    {"id": "prelim", "name": "Prelim", "order": 1, "defaultWeight": 20},
    {"id": "midterm", "name": "Midterm", "order": 2, "defaultWeight": 20},
    {"id": "prefinals", "name": "Pre-Finals", "order": 3, "defaultWeight": 20},
    {"id": "finals", "name": "Finals", "order": 4, "defaultWeight": 40},
]

SUBJECTS = {
    "it2102": {
        "name": "Embedded Systems",
        "code": "IT2102",
        "folder": "EMBEDDED SYSTEM",
        "description": (
            "Prelim to finals reviewer covering embedded system concepts, "
            "structures, communications, interfaces, and optimization."
        ),
        "authors": ["ACES", "IT2102 Faculty"],
        "handouts": [
            ("Prelim", "01_Handout_1(21).pdf", "it2102-prelim-01", "prelim", "01",
             "Introduction to Embedded Systems", 3),
            ("Prelim", "03_Handout_1(26).pdf", "it2102-prelim-03", "prelim", "03",
             "Embedded System Structure", 3),
            ("Midterm", "04_Handout_1(21).pdf", "it2102-midterm-04", "midterm", "04",
             "Communications and Protocols", 3),
            ("Prefinals", "05_Handout_1(21).pdf", "it2102-prefinals-05", "prefinals", "05",
             "Interfaces and Mechanisms", 4),
            ("finals", "06_Handout_1(22).pdf", "it2102-finals-06", "finals", "06",
             "Embedded System Optimization", 5),
        ],
    },
    "it1919": {
        "name": "Robot Dynamics",
        "code": "IT1919",
        "folder": "ROBOT Dynamics",
        "description": (
            "Prelim to finals reviewer covering embedded systems basics, "
            "robotics, simple machines, electronics, and microcontrollers."
        ),
        "authors": ["ACES", "IT1919 Faculty"],
        "handouts": [
            ("Prelim", "01_Handout_1(39).pdf", "it1919-prelim-01", "prelim", "01",
             "Embedded Systems Basics", 1),
            ("Prelim", "02_Handout_1(9).pdf", "it1919-prelim-02", "prelim", "02",
             "Overview of Robotics", 1),
            ("Midterm", "03_Handout_1(15).pdf", "it1919-midterm-03", "midterm", "03",
             "Simple Machines Fundamentals", 2),
            ("Midterm", "04_Handout_1(63).pdf", "it1919-midterm-04", "midterm", "04",
             "Fundamentals of Electricity and Electronics", 5),
            ("Prefinals", "05_Handout_1(17).pdf", "it1919-prefinals-05", "prefinals", "05",
             "Microcontrollers Fundamentals", 3),
            ("Finals", "06_Handout_1(14).pdf", "it1919-finals-06", "finals", "06",
             "Microcontroller Programming Fundamentals", 1),
        ],
    },
}

# Hand-curated terms keep the reader and question bank factual and readable.
# Entry format: (term, definition, page).
EXTRA_TERMS: dict[str, list[tuple[str, str, int]]] = {
    "it2102-prelim-01": [
        ("Embedded system", "A combination of hardware and software designed to perform dedicated functions inside a larger product or system.", 1),
        ("Ubiquitous computing", "A computing approach that focuses on providing information anytime and anywhere.", 1),
        ("Cyber-physical system", "An integration of computation and physical processes that is observed through sensors and controlled through actuators.", 1),
        ("Internet of Things", "A network of devices with unique addressing that interact and cooperate to reach common goals.", 1),
        ("Sensor", "A device that measures a physical quantity and converts it into an electrical signal.", 1),
        ("Actuator", "A component that converts a control signal into a physical action or output.", 1),
        ("Safety", "The condition of being protected from harm or other non-desirable outcomes.", 2),
        ("Security", "Protection against harm caused by attacks originating from outside the system.", 2),
        ("Confidentiality", "The property that information can only be accessed by its intended recipients.", 2),
        ("Reliability", "The ability of a system to avoid malfunctions caused by components that stop working.", 2),
        ("Repairability", "The probability that a failing system can be repaired within a certain time.", 2),
        ("Availability", "The probability that a system is available when it is needed.", 2),
        ("Hard real-time", "A system designed to meet all deadlines, where a missed deadline is a design flaw.", 2),
        ("Firm real-time", "A system that meets all deadlines but allows an occasional missed deadline.", 2),
        ("Soft real-time", "A system that meets as many deadlines as possible but may occasionally be late.", 2),
        ("Model", "A simplified representation containing only the traits of the modeled entity that are relevant to the task.", 2),
        ("Ambient intelligence", "Intelligence embedded in everyday environments so that the environment becomes sensitive and responsive.", 1),
    ],
    "it2102-prelim-03": [
        ("Input block", "The part of an embedded system that accepts data signals from the external world.", 1),
        ("Photodiode", "A reverse-biased semiconducting optical sensor that produces a very low current.", 1),
        ("Temperature sensor", "A sensor that provides temperature feedback to a system controller.", 1),
        ("Line-tracking sensor", "A sensor that detects white lines in black and black lines in white using a TTL signal.", 1),
        ("Ultrasonic sensor", "A non-contact distance sensor that uses sonar timing to measure the distance to an object.", 1),
        ("Motion sensor", "An electronic device that detects movement within its field of view.", 1),
        ("Hall sensor", "An omni-polar magnetic sensor used for proximity, positioning, speed, and current sensing.", 1),
        ("Datapath block", "The block that coordinates system activities and performs computations and data manipulation.", 2),
        ("Control block", "The processing unit that directs the operations of an embedded system.", 2),
        ("Channel", "An abstract communication entity described by properties such as transfer capacity and noise.", 2),
        ("Communication media", "The physical entities that enable communication, such as wires, optical fibers, and wireless links.", 2),
        ("VLIW", "Very Long Instruction Word processing, where several operations are encoded in a single long instruction.", 2),
        ("EPIC", "Explicitly Parallel Instruction Set Computer, a design that explicitly identifies operations to run in parallel.", 3),
        ("Homogeneous multicore", "A multicore architecture that uses multiple identical processor cores.", 3),
        ("ROM", "Read-only memory that stores embedded instructions and data that do not normally change.", 3),
        ("RAM", "Random access memory that is volatile and stores temporary programs and data.", 3),
    ],
    "it2102-midterm-04": [
        ("Local device", "A device located close to the core system, usually within one to three meters, with a specialized interface.", 1),
        ("Remote device", "A device located farther from the core system, usually three to five meters or more, with distributed tasks.", 1),
        ("Channel", "An abstract communication entity characterized by transfer capacity and noise parameters.", 1),
        ("Communication media", "The wired or wireless physical entities that enable communication.", 1),
        ("Single-ended signaling", "A signaling method that propagates a signal on one wire with respect to a common ground and is susceptible to noise.", 1),
        ("Differential signaling", "A signaling method that uses two wires per signal and twisted pairing to reduce noise.", 1),
        ("I/O driver", "A software routine associated with an I/O device that manages communication with that device.", 2),
        ("Transport mechanism", "The implementation that moves information through a physical medium or configuration.", 2),
        ("Protocol", "A standard set of rules and interfaces used to synchronize tasks and exchange data.", 2),
        ("Distributed task", "A task that executes on a remote device and interacts with the rest of the system.", 2),
        ("Timing requirement", "A constraint on when an I/O exchange or computation must occur.", 2),
    ],
    "it2102-prefinals-05": [
        ("Interface", "A connection between humans, the environment, phenomena, and machines that provides input, process, or output.", 1),
        ("Pulse Width Modulation", "A technique for delivering variable power by rapidly switching a signal between high and low at a fixed frequency.", 1),
        ("General-purpose digital I/O", "A digital interface that lets software read or write logical zero and one voltage levels.", 1),
        ("Serial interface", "An interface that sends or receives a sequence of bits one after another over a single line.", 2),
        ("Parallel interface", "An interface that uses multiple lines to send or receive bits simultaneously.", 2),
        ("Bus", "An interface shared among multiple devices rather than a point-to-point link between two devices.", 2),
        ("RS-232", "A serial interface standard introduced by the EIA to connect teletypes to modems.", 2),
        ("IEEE-1284", "A parallel printer bus specification that uses a point-to-point asynchronous bidirectional interface.", 2),
        ("Tristate logic", "A digital output state that can be high, low, or electrically off.", 1),
        ("Handshake", "A control exchange, such as strobe and acknowledge, that coordinates a data transfer.", 2),
        ("Hardware interrupt", "A signal generated when external hardware changes the voltage on an interrupt request line.", 3),
        ("Memory-mapped register", "A register that software accesses through a memory address.", 1),
    ],
    "it2102-finals-06": [
        ("Optimization", "The process of improving a system's efficiency in time, space, or resources.", 1),
        ("Software optimization", "The process of modifying a software system so that it works more efficiently or uses fewer resources.", 1),
        ("Loop permutation", "A transformation that swaps the order of two loops to improve parallelism or locality.", 1),
        ("Loop unrolling", "A transformation that creates several instances of a loop body to reduce loop overhead.", 1),
        ("Unrolling factor", "The number of copies of a loop body created by loop unrolling.", 1),
        ("Loop fusion", "A transformation that combines two separate loops into one loop.", 1),
        ("Loop fission", "A transformation that splits a single loop into two loops.", 1),
        ("Loop tiling", "A transformation that chunks nested loops so that memory hierarchies can be used efficiently.", 1),
        ("Spatial locality", "The tendency to access memory locations that are close to recently accessed locations.", 1),
        ("Cache", "A small, fast memory near the processor that stores recently or frequently used data.", 1),
        ("Dynamic voltage and frequency scaling", "A power optimization that reduces dynamic power by adjusting voltage and clock frequency.", 3),
        ("Priority inheritance", "A scheduling technique where a task holding a lock temporarily inherits the priority of a higher-priority blocked task.", 3),
        ("Assignment", "The scheduling decision of which processor should execute a task.", 4),
        ("Ordering", "The scheduling decision of the order in which each processor executes its tasks.", 4),
    ],
    "it1919-prelim-01": [
        ("Embedded system", "A computer system designed to perform a specific task such as accessing, processing, storing, and controlling data in an electronics-based system.", 1),
        ("Power supply", "The component that provides battery or external electrical power to an embedded system.", 1),
        ("Processor", "The component that controls the electrical and mechanical functions of an embedded system.", 1),
        ("Memory", "The component that stores hardware instructions and data.", 1),
        ("Timer", "A component that measures time intervals or elapsed time.", 1),
        ("Communication port", "A port such as UART, USB, or Ethernet used to communicate with other embedded systems.", 1),
        ("ASIC", "An application-specific integrated circuit customized for a particular use.", 1),
        ("Single-functioned", "An embedded system characteristic where the system executes a particular operation in a consistent manner.", 1),
        ("Tightly constrained", "An embedded system characteristic where design metrics such as size, power, cost, and performance are limited.", 1),
        ("Real time", "An embedded system characteristic requiring fast operation and low power consumption.", 1),
        ("Reactive", "An embedded system characteristic where the system constantly reacts to changes without delay.", 1),
        ("Sensor", "A device that measures a physical quantity and converts it into an electrical signal.", 1),
        ("A-D converter", "A component that converts the analog signal from a sensor into a digital signal.", 1),
        ("Actuator", "A component that receives a control signal and produces a physical action.", 1),
    ],
    "it1919-prelim-02": [
        ("Artificial intelligence", "The science of training machines to perform human tasks.", 1),
        ("Reasoning", "An AI subset that makes inferences based on data.", 1),
        ("Natural Language Processing", "An AI subset that understands written text and human speech.", 1),
        ("Planning", "An AI subset that acts autonomously and flexibly to construct a sequence of actions toward a goal.", 1),
        ("Machine learning", "An AI subset that enables a system to learn from data, identify patterns, and make decisions with minimal human intervention.", 1),
        ("Robotics", "The study of machines that independently perform work following rules programmed by a computer.", 1),
        ("Sensing", "A robot characteristic describing the ability to gather information from its environment.", 1),
        ("Movement", "A robot characteristic describing the ability to change position or actuate parts.", 1),
        ("Unimate", "The first industrially used robot, developed by Joseph Engelberger and George Devol in 1961.", 1),
        ("Shakey", "The first mobile robot able to perceive and reason about its surroundings, developed by Charles Rosen in 1966.", 1),
        ("Stanford Arm", "The first successfully computer-controlled electrically powered robot arm, created by Victor Scheinman in 1969.", 1),
        ("Industrial robot", "A robotic arm or manipulator that performs production tasks such as welding, handling, and painting.", 1),
        ("Medical robot", "A robot used in healthcare and medicine for tasks such as equipment lifting and surgery.", 1),
        ("Military robot", "A robot used by armed forces for searching, rescue, and surveillance.", 1),
        ("Space robot", "A robot used to substitute for astronauts in dangerous environments.", 1),
        ("Domestic robot", "A robot primarily used for household chores.", 1),
    ],
    "it1919-midterm-03": [
        ("Simple machine", "A basic mechanical device for applying a force and doing work.", 1),
        ("Lever", "A straight rigid object that pivots on a turning point to move or lift an object.", 1),
        ("Fulcrum", "The pivot point on a lever bar.", 1),
        ("Effort", "The force applied at one point to move or lift a load.", 1),
        ("Load", "The object to be moved or lifted by a machine.", 1),
        ("Class 1 lever", "A lever where the fulcrum is between the effort and the load.", 1),
        ("Class 2 lever", "A lever where the load is between the effort and the fulcrum.", 1),
        ("Class 3 lever", "A lever where the effort is between the load and the fulcrum.", 1),
        ("Wheel and axle", "A simple machine using a wheel with a rod axle to move or lift loads.", 1),
        ("Pulley", "A simple machine with a wheel and groove that uses a rope to move a load or change force direction.", 1),
        ("Fixed pulley", "A pulley whose axle is fixed in place and cannot move.", 1),
        ("Movable pulley", "A pulley where the load is attached and both the pulley and load can move.", 1),
        ("Compound pulley", "A combination of pulleys designed to make the effort less than half the load.", 1),
        ("Inclined plane", "A flat surface with one end higher than the other that helps move objects to a different height.", 2),
        ("Wedge", "A simple machine made of two inclined planes used to cut, split, or tighten an object.", 2),
        ("Screw", "An inclined plane wrapped around a cylinder, used to lift or hold things together.", 2),
        ("Mechanical advantage", "A measure of how much a machine increases or decreases the force applied to a load.", 2),
    ],
    "it1919-midterm-04": [
        ("Electrical circuit", "An interconnection of electrical components such as resistors, capacitors, and sources.", 1),
        ("Scientific notation", "A way of expressing very large or very small numbers for accuracy and precision.", 1),
        ("SI", "The International System of Units, an international measurement language and standard.", 1),
        ("Atom", "The basic unit of matter that can be built up into elements.", 2),
        ("Proton", "A positively charged particle in an atom.", 2),
        ("Neutron", "A neutral particle in an atom.", 2),
        ("Electron", "A negatively charged particle in an atom.", 2),
        ("Electric charge", "A fundamental property of matter measured in coulombs.", 2),
        ("Coulomb", "The SI unit used to measure electric charge.", 2),
        ("Electric current", "The flow of electric charge, measured in amperes.", 2),
        ("Voltage", "The electrical potential difference that drives current, measured in volts.", 2),
        ("Resistance", "The opposition to electric current, measured in ohms.", 2),
        ("Ohm's law", "The relationship between voltage, current, and resistance, commonly written as V = IR.", 3),
        ("Conductor", "A material that allows electric charge to flow easily.", 3),
        ("Insulator", "A material that resists the flow of electric charge.", 3),
    ],
    "it1919-prefinals-05": [
        ("Microcomputer", "A computer made of a microprocessor, input/output chips, and memory chips.", 1),
        ("Microprocessor", "The CPU of a microcomputer contained in a single chip, requiring memory and I/O chips to function.", 1),
        ("Microcontroller", "A single chip containing a CPU, memory, and input/output peripherals.", 1),
        ("Central Processing Unit", "The component that executes instructions and performs arithmetic and logic operations on data.", 1),
        ("ROM", "Read-only memory that retains its contents when power is off and stores fixed instructions and data.", 1),
        ("RAM", "Random access memory that loses its contents when power is off and stores temporary programs and data.", 1),
        ("System bus", "The internal set of address, data, and control buses that carries information during program execution.", 1),
        ("Address bus", "The bus that transfers addresses in one direction from the processor to memory or I/O.", 1),
        ("Data bus", "The bidirectional bus that carries data to or from the CPU.", 1),
        ("Control bus", "The bus that carries signals used to synchronize the operation of microcomputer components.", 1),
        ("Clock", "A timing circuit that synchronizes the components and instruction execution of a microcontroller.", 1),
        ("Register", "A small volatile storage location for bits inside the CPU.", 2),
        ("Program counter", "The register that contains the address of the next instruction.", 2),
        ("Instruction register", "The register that stores the instruction currently being processed.", 2),
        ("Memory address register", "The register that contains the address of data being accessed.", 2),
        ("Harvard architecture", "A processor architecture with separate program and data memories and separate buses.", 2),
    ],
    "it1919-finals-06": [
        ("Sketch", "An Arduino program written in the Arduino IDE and saved with the .ino extension.", 1),
        ("setup()", "The Arduino function called once when a sketch starts, used to set pin modes or initialize libraries.", 1),
        ("loop()", "The Arduino function that executes statements repeatedly and is considered the heart of a sketch.", 1),
        ("pinMode()", "The Arduino function that configures a pin as an input or an output.", 1),
        ("digitalWrite()", "The Arduino function that outputs a HIGH or LOW value on a pin.", 1),
        ("delay()", "The Arduino function that pauses the program for a specified number of milliseconds.", 1),
        ("Variable", "A named storage location holding values that may change as the program runs.", 1),
        ("Constant", "A named identifier whose value cannot change while the program runs.", 1),
        ("Function", "A programming construct used to control the Arduino board and perform computations.", 1),
        ("Structure", "The elements of an Arduino sketch such as setup(), loop(), operators, and comments.", 1),
        ("LED_BUILTIN", "The constant giving the pin number connected to the board's on-board LED.", 1),
        ("Data type", "A category such as int, float, boolean, or char that defines the kind of value a variable holds.", 1),
        ("Array", "A collection of values of the same data type stored under one name.", 1),
    ],
}

BULLET_MARK = re.compile(r"^[•▪➢]$|^o$|^[-–—]$")
NUMBERED = re.compile(r"^\d+\.\s+\S")
HEADER_LINE = re.compile(
    r"^(IT\d{4}|\d{2} Handout 1|\*Property of STI|student\.feedback@sti\.edu|Page \d+ of \d+)$",
    re.IGNORECASE,
)
BOILERPLATE = re.compile(
    r"(IT\d{4}|\d{2} Handout 1|\*Property of STI|student\.feedback@sti\.edu|Page \d+ of \d+)",
    re.IGNORECASE,
)
SPLIT_SENTENCE = re.compile(r"(?<=[.!?])\s+")
SENTENCE_LIMITS = (40, 320)


def clean_text(text: str) -> str:
    text = text.replace("\u00ad", "")
    text = re.sub(r"[\ue000-\uf8ff]", "", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def clean_bullet(text: str) -> str:
    text = re.sub(r"^[•▪➢o]+\s*", "", text).strip()
    text = re.sub(r"^(?:[-–—]|\d+\.)\s*", "", text).strip()
    return clean_text(text)


def parse_units(pdf_path: Path) -> list[dict]:
    document = pymupdf.open(pdf_path)
    units: list[dict] = []
    heading: str | None = None
    references = False
    for page_index, page in enumerate(document):
        blocks = sorted(
            page.get_text("dict")["blocks"],
            key=lambda block: (round(block["bbox"][0] / 100), block["bbox"][1]),
        )
        for block in blocks:
            lines = []
            for line in block.get("lines", []):
                spans = line.get("spans", [])
                text = "".join(span.get("text", "") for span in spans).strip()
                if not text:
                    continue
                lines.append(
                    (
                        line["bbox"][0],
                        line["bbox"][1],
                        text,
                        any("Bold" in span.get("font", "") for span in spans),
                    )
                )
            lines.sort(key=lambda item: item[1])
            current = None
            content_x = None
            for x, y, text, bold in lines:
                if y < 55 or y > 540 or HEADER_LINE.match(text):
                    continue
                if references:
                    continue
                if text.startswith("References:"):
                    if current:
                        units.append(current)
                    current = None
                    references = True
                    continue
                if BULLET_MARK.fullmatch(text):
                    if current:
                        units.append(current)
                    current = None
                    content_x = None
                    continue
                if NUMBERED.match(text):
                    if current:
                        units.append(current)
                    current = {
                        "heading": heading,
                        "page": page_index + 1,
                        "lines": [clean_bullet(text)],
                    }
                    content_x = x
                    continue
                heading_candidate = (
                    bold
                    and len(text) <= 62
                    and len(text.split()) <= 8
                    and not text.endswith((".", ":", ";"))
                )
                can_heading = current is None or (
                    content_x is not None and x < content_x - 10
                )
                if heading_candidate and can_heading:
                    if current:
                        units.append(current)
                    current = None
                    heading = clean_text(text)
                    content_x = None
                    continue
                if current is None:
                    current = {
                        "heading": heading,
                        "page": page_index + 1,
                        "lines": [clean_bullet(text)],
                    }
                    content_x = x
                else:
                    current["lines"].append(clean_bullet(text))
                    if content_x is None:
                        content_x = x
            if current:
                units.append(current)
    document.close()

    facts = []
    for unit in units:
        text = clean_text(" ".join(unit["lines"]))
        if len(text) < 25 or BOILERPLATE.fullmatch(text):
            continue
        facts.append(
            {
                "heading": unit["heading"] or "Overview",
                "page": unit["page"],
                "text": text,
            }
        )
    return facts


def page_sentences(pdf_path: Path) -> list[dict]:
    document = pymupdf.open(pdf_path)
    sentences = []
    for page_index, page in enumerate(document):
        text = clean_text(page.get_text("text"))
        text = re.sub(r"IT\d{4}", " ", text)
        text = re.sub(r"\d{2} Handout 1", " ", text)
        text = re.sub(r"\*Property of STI", " ", text)
        text = re.sub(r"student\.feedback@sti\.edu", " ", text)
        text = re.sub(r"Page \d+ of \d+", " ", text)
        for sentence in SPLIT_SENTENCE.split(text):
            sentence = clean_bullet(sentence)
            if not SENTENCE_LIMITS[0] <= len(sentence) <= SENTENCE_LIMITS[1]:
                continue
            if not re.search(r"[A-Za-z]", sentence):
                continue
            if re.search(r"=\s*[{\[]|\bString\s+\w+\s*=", sentence):
                continue
            if sentence.lower().startswith(("references", "retrieved", "http")):
                continue
            sentences.append({"page": page_index + 1, "text": sentence})
    document.close()
    return sentences


def make_chunks(pdf_path: Path, handout: dict) -> list[dict]:
    document = pymupdf.open(pdf_path)
    chunks = []
    for page_index, page in enumerate(document):
        lines = []
        for raw in page.get_text("text").replace("\r", "\n").split("\n"):
            line = clean_text(raw)
            if not line or HEADER_LINE.match(line):
                continue
            lines.append(line)
        text = clean_text(" ".join(lines))
        sentences = SPLIT_SENTENCE.split(text)
        current = []
        size = 0
        for sentence in sentences:
            sentence = sentence.strip()
            if not sentence:
                continue
            if size + len(sentence) > 700 and current:
                chunks.append(
                    {
                        "id": f"{handout['id']}-p{page_index + 1}-c{len(chunks) + 1}",
                        "termId": handout["termId"],
                        "handoutId": handout["id"],
                        "handoutNumber": handout["number"],
                        "handoutTitle": handout["title"],
                        "page": page_index + 1,
                        "text": " ".join(current),
                    }
                )
                current = [sentence]
                size = len(sentence)
            else:
                current.append(sentence)
                size += len(sentence) + 1
        if current:
            chunks.append(
                {
                    "id": f"{handout['id']}-p{page_index + 1}-c{len(chunks) + 1}",
                    "termId": handout["termId"],
                    "handoutId": handout["id"],
                    "handoutNumber": handout["number"],
                    "handoutTitle": handout["title"],
                    "page": page_index + 1,
                    "text": " ".join(current),
                }
            )
    document.close()
    return chunks


def slug(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-") or "section"


def source_path(subject: dict, handout: tuple) -> Path:
    return PDF_ROOT / subject["folder"] / handout[0] / handout[1]


def handout_dicts(subject: dict) -> list[dict]:
    return [
        {
            "id": entry[2],
            "termId": entry[3],
            "number": entry[4],
            "title": entry[5],
            "pages": entry[6],
            "path": source_path(subject, entry),
        }
        for entry in subject["handouts"]
    ]


def reader_terms_for(handout_id: str) -> list[dict]:
    return [
        {
            "term": term,
            "definition": definition,
            "page": page,
        }
        for term, definition, page in EXTRA_TERMS.get(handout_id, [])
    ]


def clean_definition(value: str) -> str:
    value = clean_text(value)
    value = value.lstrip("-–—: ")
    return value.strip()


def make_reader_pack(subject_id: str, subject: dict) -> tuple[dict, dict[str, list[dict]]]:
    handouts = handout_dicts(subject)
    reader_handouts = []
    terms_by_handout: dict[str, list[dict]] = {}
    for handout in handouts:
        units = parse_units(handout["path"])
        terms = [
            {
                "id": f"{handout['id']}-t{index + 1:02d}",
                "termId": handout["termId"],
                "handoutId": handout["id"],
                "term": clean_text(item["term"]),
                "definition": clean_definition(item["definition"]),
                "page": item["page"],
                "sectionId": "",
            }
            for index, item in enumerate(reader_terms_for(handout["id"]))
            if len(clean_definition(item["definition"])) >= 15
        ]
        # Deduplicate terms while preserving the first, longer definition.
        unique: dict[str, dict] = {}
        for term in terms:
            key = re.sub(r"[^a-z0-9]+", "", term["term"].lower())
            if key in unique and len(unique[key]["definition"]) >= len(term["definition"]):
                continue
            unique[key] = term
        terms = list(unique.values())
        for index, term in enumerate(terms, start=1):
            term["id"] = f"{handout['id']}-t{index:02d}"
            term["sectionId"] = "key-terms"
        terms_by_handout[handout["id"]] = terms

        sentences = page_sentences(handout["path"])
        overview = [item for item in sentences[:4]]
        concepts = [
            item
            for item in sentences[4:]
            if 60 <= len(item["text"]) <= 240
        ][:6]
        sections = []
        if overview:
            sections.append(
                {
                    "id": "overview",
                    "title": "Overview",
                    "page": 1,
                    "bullets": [item["text"] for item in overview],
                    "tableIds": [],
                }
            )
        if concepts:
            sections.append(
                {
                    "id": "key-concepts",
                    "title": "Key concepts",
                    "page": concepts[0]["page"],
                    "bullets": [item["text"] for item in concepts],
                    "tableIds": [],
                }
            )
        key_terms = terms[:10]
        if key_terms:
            sections.append(
                {
                    "id": "key-terms",
                    "title": "Key terms",
                    "page": min(term["page"] for term in key_terms),
                    "bullets": [
                        f"{term['term']} ? {term['definition']}" for term in key_terms[:5]
                    ],
                    "tableIds": [f"{handout['id']}-terms"],
                }
            )
        tables = []
        if key_terms:
            tables.append(
                {
                    "id": f"{handout['id']}-terms",
                    "title": "Key terms",
                    "headers": ["Term", "Definition"],
                    "rows": [
                        [term["term"], term["definition"]] for term in key_terms
                    ],
                    "page": min(term["page"] for term in key_terms),
                    "note": "",
                }
            )
        sentences = page_sentences(handout["path"])
        summary = " ".join(
            clean_bullet(item["text"]) for item in sentences[:2]
        ) or "Review the key concepts from this handout."
        reader_handouts.append(
            {
                "id": handout["id"],
                "termId": handout["termId"],
                "number": handout["number"],
                "title": handout["title"],
                "summary": summary,
                "sections": sections,
                "tables": tables,
                "terms": terms,
            }
        )
    return (
        {
            "subjectId": subject_id,
            "subject": subject["name"],
            "version": "1.0.0",
            "handouts": reader_handouts,
        },
        terms_by_handout,
    )


def options_with_correct(correct: str, distractors: list[str], seed: int) -> tuple[list[str], int]:
    pool = []
    for item in distractors:
        item = clean_text(item)
        if item and item != correct and item not in pool:
            pool.append(item)
    while len(pool) < 3:
        pool.append(f"None of the above ({len(pool) + 1})")
    options = [correct, *pool[:3]]
    random.Random(seed).shuffle(options)
    return options, options.index(correct)


def make_mcq(
    subject_id: str,
    handout: dict,
    term: dict,
    form: int,
    term_pool: list[dict],
    number: int,
) -> dict:
    definition = term["definition"]
    correct_definition = definition[:220]
    others = [item for item in term_pool if item["term"] != term["term"]]
    other_defs = [item["definition"][:220] for item in others]
    other_terms = [item["term"] for item in others]
    if form == 3:
        correct = term["term"]
        options, answer = options_with_correct(
            correct,
            other_terms,
            seed=hash((subject_id, handout["id"], term["term"], form)) & 0xFFFFFFFF,
        )
        stem = f"Which term is described by this statement?\n\n{definition[:300]}"
        explanation = f"{term['term']} is defined as: {definition}"
        difficulty = "medium" if number % 3 else "hard"
    else:
        correct = correct_definition
        options, answer = options_with_correct(
            correct,
            other_defs,
            seed=hash((subject_id, handout["id"], term["term"], form)) & 0xFFFFFFFF,
        )
        stem = (
            f"Which of the following best defines “{term['term']}”?"
            if form == 1
            else f"Which statement correctly describes “{term['term']}”?"
        )
        explanation = f"The handout defines {term['term']} as: {definition}"
        difficulty = "easy" if form == 1 else "medium"
    return {
        "id": f"{handout['id']}-mcq-{number:02d}",
        "termId": handout["termId"],
        "handoutId": handout["id"],
        "topic": "Key concepts",
        "difficulty": difficulty,
        "type": "multipleChoice",
        "stem": stem,
        "options": options,
        "answerIndex": answer,
        "explanation": explanation,
        "sourcePage": term["page"],
    }


def make_tf(
    subject_id: str,
    handout: dict,
    term: dict,
    wrong: dict,
    number: int,
) -> dict:
    is_false = number % 2 == 1
    display = wrong["term"] if is_false else term["term"]
    definition = term["definition"][:280]
    stem = f'In the handout, the term “{display}” is defined as: {definition}'
    correction = term["term"] if is_false else ""
    return {
        "id": f"{handout['id']}-tf-{number:02d}",
        "termId": handout["termId"],
        "handoutId": handout["id"],
        "topic": "Modified True/False",
        "difficulty": "medium",
        "type": "modifiedTrueFalse",
        "stem": stem,
        "options": ["True", "False"],
        "answerIndex": 1 if is_false else 0,
        "underlined": display,
        "correction": correction,
        "explanation": (
            f"The correct term is {term['term']}. "
            f"The handout defines it as: {term['definition']}"
        ),
        "sourcePage": term["page"],
    }


def build_subject_pack(subject_id: str, subject: dict, reader_pack: dict, terms_by_handout: dict) -> dict:
    handouts = handout_dicts(subject)
    all_terms = [term for handout_id in terms_by_handout for term in terms_by_handout[handout_id]]
    all_terms.sort(key=lambda item: (-len(item["definition"]), item["term"]))
    questions: list[dict] = []
    for term_id in [term["id"] for term in TERMS]:
        term_handouts = [handout for handout in handouts if handout["termId"] == term_id]
        target_mcq = 30
        per_handout = target_mcq // len(term_handouts)
        mcq_serial = 0
        for handout in term_handouts:
            terms = list(terms_by_handout.get(handout["id"], []))
            terms.sort(key=lambda item: (-len(item["definition"]), item["term"]))
            candidates = [
                (term, form)
                for form in (1, 3, 2)
                for term in terms
            ]
            handout_count = 0
            for term, form in candidates:
                if handout_count >= per_handout:
                    break
                handout_count += 1
                mcq_serial += 1
                questions.append(
                    make_mcq(
                        subject_id,
                        handout,
                        term,
                        form,
                        all_terms,
                        mcq_serial,
                    )
                )
        selected_tf: list[tuple[dict, dict]] = []
        tf_number = 0
        tf_per_handout = 10 // len(term_handouts)
        for handout in term_handouts:
            terms = list(terms_by_handout.get(handout["id"], []))
            terms.sort(key=lambda item: item["page"])
            taken = 0
            for term in terms:
                if taken >= tf_per_handout:
                    break
                same_term = [
                    item
                    for item in all_terms
                    if item["termId"] == term_id and item["term"] != term["term"]
                ]
                wrong = next(
                    (item for item in same_term if item["handoutId"] == term["handoutId"]),
                    same_term[0] if same_term else term,
                )
                selected_tf.append((term, wrong))
                taken += 1
        for term, wrong in selected_tf:
            tf_number += 1
            handout = next(
                item for item in handouts if item["id"] == term["id"].rsplit("-t", 1)[0]
            )
            questions.append(
                make_tf(subject_id, handout, term, wrong, tf_number)
            )
    return {
        "id": subject_id,
        "subject": subject["name"],
        "code": subject["code"],
        "org": "ACES - Association of Computer Engineering Students of STI Ortigas-Cainta",
        "version": "1.0.0",
        "description": subject["description"],
        "authors": subject["authors"],
        "license": "For ACES classroom use only. Handout content is property of STI.",
        "terms": TERMS,
        "handouts": [
            {
                "id": handout["id"],
                "termId": handout["termId"],
                "number": handout["number"],
                "title": handout["title"],
            }
            for handout in handouts
        ],
        "questions": questions,
    }


def add_it2205_tf() -> None:
    pack_path = ROOT / "assets" / "packs" / "it2205.json"
    reader_path = ROOT / "assets" / "handouts" / "it2205_reader.json"
    pack = json.loads(pack_path.read_text(encoding="utf-8"))
    reader = json.loads(reader_path.read_text(encoding="utf-8"))
    terms = [
        {
            **term,
            "termId": handout["termId"],
            "handoutId": handout["id"],
        }
        for handout in reader["handouts"]
        for term in handout["terms"]
    ]
    terms.sort(key=lambda item: (-len(item.get("definition", "")), item.get("term", "")))
    by_term: dict[str, list[dict]] = {}
    for term in terms:
        if len(clean_text(term.get("definition", ""))) >= 20:
            by_term.setdefault(term["termId"], []).append(term)
    pack["questions"] = [
        question
        for question in pack["questions"]
        if question.get("type") != "modifiedTrueFalse"
    ]
    existing_ids = {question["id"] for question in pack["questions"]}
    new_questions = []
    for term_id in [term["id"] for term in TERMS]:
        candidates = by_term.get(term_id, [])[:10]
        for index, term in enumerate(candidates, start=1):
            correct = clean_text(term["term"])
            definition = clean_text(term["definition"])[:280]
            handout_id = term["handoutId"]
            page = int(term.get("page", 1))
            same_handout = [
                item
                for item in terms
                if item["termId"] == term_id
                and item["handoutId"] == handout_id
                and item["term"] != correct
            ]
            same_term = [
                item
                for item in terms
                if item["termId"] == term_id and item["term"] != correct
            ]
            pool = same_handout or same_term
            wrong = pool[(index - 1) % len(pool)] if pool else term
            is_false = index % 2 == 0
            display = wrong["term"] if is_false else correct
            question_id = f"it2205-tf-{term_id}-{index:02d}"
            if question_id in existing_ids:
                continue
            new_questions.append(
                {
                    "id": question_id,
                    "termId": term_id,
                    "handoutId": handout_id,
                    "topic": "Modified True/False",
                    "difficulty": "medium",
                    "type": "modifiedTrueFalse",
                    "stem": f'In the handout, the term “{display}” is defined as: {definition}',
                    "options": ["True", "False"],
                    "answerIndex": 1 if is_false else 0,
                    "underlined": display,
                    "correction": correct if is_false else "",
                    "explanation": (
                        f"The correct term is {correct}. "
                        f"The handout defines it as: {term['definition']}"
                    ),
                    "sourcePage": page,
                }
            )
    if new_questions:
        pack["questions"].extend(new_questions)
        pack["version"] = "1.1.0"
        pack_path.write_text(
            json.dumps(pack, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
    print(f"IT2205: added {len(new_questions)} T/F items, total {len(pack['questions'])}")


def validate_pack(pack: dict) -> None:
    assert pack["id"]
    assert len(pack["questions"]) == 160, (pack["id"], len(pack["questions"]))
    for term in TERMS:
        items = [q for q in pack["questions"] if q["termId"] == term["id"]]
        assert len(items) == 40, (pack["id"], term["id"], len(items))
        assert len([q for q in items if q["type"] == "multipleChoice"]) == 30
        assert len([q for q in items if q["type"] == "modifiedTrueFalse"]) == 10
    for question in pack["questions"]:
        assert question["options"], question["id"]
        assert 0 <= question["answerIndex"] < len(question["options"])
        if question["type"] == "modifiedTrueFalse":
            assert question["options"] == ["True", "False"]
            assert question["underlined"] in question["stem"]
            if question["answerIndex"] == 1:
                assert question["correction"]
        else:
            assert len(question["options"]) == 4
            assert len(set(question["options"])) == 4
    ids = [q["id"] for q in pack["questions"]]
    assert len(ids) == len(set(ids))


def main() -> None:
    chunks_dir = ROOT / "assets" / "handouts"
    packs_dir = ROOT / "assets" / "packs"
    chunks_dir.mkdir(parents=True, exist_ok=True)
    packs_dir.mkdir(parents=True, exist_ok=True)

    for subject_id, subject in SUBJECTS.items():
        handouts = handout_dicts(subject)
        reader_pack, terms_by_handout = make_reader_pack(subject_id, subject)
        (chunks_dir / f"{subject_id}_reader.json").write_text(
            json.dumps(reader_pack, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        chunks = []
        for handout in handouts:
            chunks.extend(make_chunks(handout["path"], handout))
        (chunks_dir / f"{subject_id}.json").write_text(
            json.dumps(
                {
                    "subjectId": subject_id,
                    "subject": subject["name"],
                    "chunks": chunks,
                },
                indent=2,
                ensure_ascii=False,
            )
            + "\n",
            encoding="utf-8",
        )
        pack = build_subject_pack(subject_id, subject, reader_pack, terms_by_handout)
        validate_pack(pack)
        (packs_dir / f"{subject_id}.json").write_text(
            json.dumps(pack, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        print(
            f"{subject_id}: {len(pack['questions'])} questions, "
            f"{len(reader_pack['handouts'])} handouts, {len(chunks)} chunks"
        )
    add_it2205_tf()


if __name__ == "__main__":
    main()
