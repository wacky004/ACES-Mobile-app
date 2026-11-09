# Content pipeline

## Source materials

Original PDFs live outside the repository, normally at:

`C:\Users\DESKTOP-123\Desktop\CPE APP REVIWER\ALL HANDOUT`

Override with:

```powershell
$env:SOURCE_HANDOUT_DIR = "D:\path\to\ALL HANDOUT"
```

The repository contains derived JSON only.

## Handouts

- CPE LAW: 8 PDFs
- EMBEDDED SYSTEM: 5 PDFs (handout 02 is absent from the source folder)
- ROBOT Dynamics: 6 PDFs

## Generated assets

- `assets/packs/it2205.json`
- `assets/packs/it2102.json`
- `assets/packs/it1919.json`
- `assets/handouts/it2205_reader.json`
- `assets/handouts/it2102_reader.json`
- `assets/handouts/it1919_reader.json`
- `assets/handouts/it2205.json`
- `assets/handouts/it2102.json`
- `assets/handouts/it1919.json`

## Scripts

- `tools/build_subjects.py` - extracts new subject content, builds readers,
  builds packs, and adds IT2205 T/F items.
- `tools/build_pack.py` - rebuilds the IT2205 MCQ bank and then adds T/F.
- `tools/build_handout_chunks.py` - extracts full-text chunks for IT2205.
- `tools/build_reader_pack.py` - curates the IT2205 reader.
- `tools/questions_*.py` - IT2205 MCQ authoring data.

Run from the repository root:

```powershell
python tools\build_subjects.py
```

## Validation

- 40 items per term: 30 MCQs and 10 T/F.
- Unique question IDs.
- Four unique MCQ options.
- Two T/F options in True/False order.
- Underlined term appears in the T/F stem.
- False T/F items have corrections.
- Source pages and handout references exist in the manifest.

## Copyright

Handout content is property of STI. Derived content is for ACES classroom use.
Review licensing before making the repository or app public.
