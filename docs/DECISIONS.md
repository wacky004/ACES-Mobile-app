# Decisions

## D001 - Multiple subjects in one app

Use one app with subject switching instead of separate APKs. Each subject is a
pack with its own terms, handouts, questions, and reader.

## D002 - 40 items per term

Use 30 MCQs and 10 modified True/False items per term. This matches the existing
30-item quiz while increasing the pool for retakes.

## D003 - Modified True/False

Show a statement with an underlined term, offer True/False, and reveal the
correction after answering. No typed correction is required.

## D004 - Fresh retakes

Prioritize questions not seen in recent attempts, then least-recently-seen
questions. Shuffle questions and MCQ options. A 30-item single-term quiz cannot
be fully new every time from a 40-item pool; older items rotate back.

## D005 - PDF chat context

A PDF chat automatically uses relevant excerpts from the opened PDF for both
local and cloud AI. Cloud AI sends excerpts only, not the full file, and the UI
shows a provider-aware privacy notice.

## D006 - Persistent chat sessions

Persist sessions per Tutor subject and per PDF. Store messages, citations,
reasoning, usage, and attachment labels. Do not store raw attachment bytes.

## D007 - Provider-specific interface

Local AI uses a private/offline presentation. Cloud providers use a cloud accent
and explicit context notices. The same screens share the chat engine.

## D008 - OpenAI-compatible provider

OpenCode credentials and internal model access cannot be used by this app.
Provide a BYO OpenAI-compatible provider so users can use their own free-tier or
self-hosted endpoint.

## D009 - Web target removed from main

The product is Android-first with Windows desktop next. The web target was
removed from `main` because it was not the primary distribution platform and
would require separate AI, update, and packaging work.


## D010 - Multiple custom cloud profiles

Save multiple OpenAI-compatible cloud profiles, each with its own secure key,
base URL, model, and capability flags. DeepSeek remains a separate built-in
provider.

## D011 - Local engine can be paused

The local AI engine can be switched off or automatically unloaded when cloud AI
is selected. Downloaded model files are preserved; no deletion or re-download is
required to turn it back on.

## D012 - Reader full text in parts

Show one PDF page at a time and split long pages at sentence boundaries. Provide
Previous/Next, a jump menu, progress, and resume position. This avoids dumping
the entire handout into one long scroll.

## D013 - Windows desktop uses Inno Setup

The Windows target uses a per-user Inno Setup installer and an in-app update
check. MSIX and Squirrel-style silent updates were rejected because the product
requires an explicit setup wizard on update. The app downloads and verifies the
installer, then launches it with `/UPDATECHECK=1`.

## D014 - Web Learning resources are linked via WebView

Protocol Explorer, Electronics 101, and Learn Arduino have no visible
redistribution license, so the app does not copy their assets. It loads the live
sites in Android/Windows WebViews, keeps attribution, restricts navigation, and
opens external links in the browser. Offline bundling would require written
permission from the author.
