#!/usr/bin/env python3
"""Validate slide count, fonts, sources, data, confidentiality, PDF and overflow."""

from __future__ import annotations

import csv
import os
from pathlib import Path
import re
import subprocess
import sys
from zipfile import ZipFile

from lxml import etree
from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[1]
PPTX = ROOT / "presentation" / "soutenance-stage-marc-duboc.pptx"
PDF = ROOT / "presentation" / "soutenance-stage-marc-duboc.pdf"
DATA = ROOT / "assets" / "charts" / "performance-data.csv"
FULL_SCRIPT = ROOT / "content" / "oral-script-full.md"
SHORT_SCRIPT = ROOT / "content" / "oral-script-4min.md"

NS = {
    "a": "http://schemas.openxmlformats.org/drawingml/2006/main",
    "p": "http://schemas.openxmlformats.org/presentationml/2006/main",
}

FORBIDDEN = {
    "marqueur de production": re.compile(r"\b(?:TODO|XXX|PLACEHOLDER)\b", re.I),
    "adresse IPv4 privée": re.compile(
        r"\b(?:10(?:\.\d{1,3}){3}|192\.168(?:\.\d{1,3}){2}|172\.(?:1[6-9]|2\d|3[01])(?:\.\d{1,3}){2})\b"
    ),
    "identifiant ou secret": re.compile(r"\b(?:IMSI|ICCID|OPc|private\s+key|password|token)\b", re.I),
    "nom d'hôte historique": re.compile(r"\bserber-(?:firecell|minipc|pi|jetson)\b", re.I),
    "adresse électronique": re.compile(r"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b", re.I),
}

TITLE_TEXTS = [
    "Security for UAV-Based 5G-Advanced and 6G Networks",
    "Sécuriser commence par rendre le système observable",
    "Un banc 5G conçu comme une chaîne de preuves",
    "Trois F1 validés ; 68 Mbit/s sur Jetson",
    "Une base vérifiable avant l’intégration UAV",
]

SMALL_OK = re.compile(
    r"^(?:[1-5]$|0[1-5]\s*[·/]|MARC DUBOC|Marc Duboc|KAUST\s+·|AVRIL$|MAI$|MAI - JUIN$|JUIN - JUIL\.$|JUILLET$|"
    r"MISSION$|OBJECTIF UAV$|RADIO D'ACCÈS$|CONTRIBUTION PERSONNELLE$|PIVOTS$|"
    r"UNE PREUVE DE BOUT EN BOUT$|CHAÎNE DE SERVICE|DIAGNOSTIC \+ IMPACT$|LIMITES ASSUMÉES$|"
    r"UNE MÉTHODE TRANSFÉRABLE$|fonctions fixes$|Ethernet · Wi-Fi · 5G$|nœud déportable$|PWS \+ données$|"
    r"VALIDÉ$|LIVRÉ$|À FAIRE$|≈100 pic$|run final validé$)",
    re.I,
)


def spoken_words(path: Path, stop_heading: str | None = None) -> tuple[int, list[int]]:
    text = path.read_text(encoding="utf-8")
    counts: list[int] = []
    current: list[str] = []
    active = False
    for line in text.splitlines():
        if stop_heading and line.startswith(stop_heading):
            break
        if line.startswith("## Diapositive"):
            if active:
                counts.append(len(" ".join(current).split()))
            active = True
            current = []
            continue
        if not active or line.startswith("#") or line.startswith("Version") or line.startswith("Cette version"):
            continue
        if line.strip():
            current.append(re.sub(r"[*`]", "", line.strip()))
    if active:
        counts.append(len(" ".join(current).split()))
    return sum(counts), counts


def find_slides_test() -> Path | None:
    explicit = os.environ.get("CODEX_PRESENTATIONS_SKILL_DIR")
    if explicit:
        candidate = Path(explicit) / "container_tools" / "slides_test.py"
        return candidate if candidate.exists() else None
    cache = Path.home() / ".codex" / "plugins" / "cache" / "openai-primary-runtime" / "presentations"
    candidates = sorted(cache.glob("*/skills/presentations/container_tools/slides_test.py"), reverse=True)
    return candidates[0] if candidates else None


def validate() -> list[str]:
    errors: list[str] = []
    for required in (PPTX, PDF, DATA, FULL_SCRIPT, SHORT_SCRIPT):
        if not required.is_file() or required.stat().st_size == 0:
            errors.append(f"Fichier absent ou vide : {required}")
    if errors:
        return errors

    visible_text: list[str] = []
    title_sizes: dict[str, float] = {}
    notes_with_sources = 0
    with ZipFile(PPTX) as archive:
        slide_names = sorted(
            name for name in archive.namelist() if re.fullmatch(r"ppt/slides/slide\d+\.xml", name)
        )
        if len(slide_names) != 5:
            errors.append(f"Le PPTX contient {len(slide_names)} diapositives au lieu de 5.")

        media_names = {name for name in archive.namelist() if name.startswith("ppt/media/")}
        for rel_name in (name for name in archive.namelist() if re.fullmatch(r"ppt/slides/_rels/slide\d+\.xml\.rels", name)):
            rel_root = etree.fromstring(archive.read(rel_name))
            for rel in rel_root:
                target = rel.get("Target", "")
                if "../media/" in target:
                    expected = "ppt/media/" + target.split("../media/", 1)[1]
                    if expected not in media_names:
                        errors.append(f"Image référencée mais absente : {expected}")

        for slide_name in slide_names:
            root = etree.fromstring(archive.read(slide_name))
            for shape in root.xpath(".//p:sp", namespaces=NS):
                text = " ".join(shape.xpath(".//a:t/text()", namespaces=NS)).strip()
                if not text:
                    continue
                visible_text.append(text)
                sizes = [int(v) / 100 for v in shape.xpath(".//*[@sz]/@sz", namespaces=NS)]
                if text in TITLE_TEXTS and sizes:
                    title_sizes[text] = max(sizes)
                if sizes and min(sizes) < 12 and not SMALL_OK.search(text):
                    errors.append(f"Texte public sous 12 pt ({min(sizes):.2f} pt) : {text[:80]}")

        for media_name in sorted(name for name in media_names if name.lower().endswith(".svg")):
            svg_text = archive.read(media_name).decode("utf-8", errors="ignore")
            visible_text.extend(
                re.sub(r"\s+", " ", value).strip()
                for value in re.findall(r"<text\b[^>]*>(.*?)</text>", svg_text, flags=re.I | re.S)
                if re.sub(r"\s+", " ", value).strip()
            )

        notes_names = sorted(
            name for name in archive.namelist() if re.fullmatch(r"ppt/notesSlides/notesSlide\d+\.xml", name)
        )
        for notes_name in notes_names:
            notes_root = etree.fromstring(archive.read(notes_name))
            notes_text = " ".join(notes_root.xpath(".//a:t/text()", namespaces=NS))
            if "[Sources]" in notes_text:
                notes_with_sources += 1
        if notes_with_sources != 5:
            errors.append(f"{notes_with_sources}/5 diapositives seulement possèdent un bloc [Sources].")

    for title in TITLE_TEXTS:
        size = title_sizes.get(title)
        if size is None:
            errors.append(f"Titre attendu absent : {title}")
        elif size < 20:
            errors.append(f"Titre sous 20 pt ({size:.2f} pt) : {title}")

    joined = "\n".join(visible_text)
    for label, pattern in FORBIDDEN.items():
        if pattern.search(joined):
            errors.append(f"Contenu sensible ou interdit détecté dans le support : {label}")

    for content_file in ROOT.glob("content/*.md"):
        data = content_file.read_text(encoding="utf-8")
        if FORBIDDEN["marqueur de production"].search(data):
            errors.append(f"Marqueur de production détecté : {content_file}")

    with DATA.open(newline="", encoding="utf-8") as stream:
        rows = list(csv.DictReader(stream))
    required_values = {"89", "100", "52", "68"}
    csv_values = {row["throughput_mbps"] for row in rows}
    if not required_values.issubset(csv_values):
        errors.append("Le CSV de référence ne contient pas toutes les valeurs attendues.")
    for value in ("89", "52", "68"):
        if not re.search(rf"\b{value}\b", joined):
            errors.append(f"Valeur du graphique absente du PPTX : {value}")
    if not re.search(r"≈\s*100\s*Mbit/s\s*en\s*pic", joined) or not re.search(
        r"MCS dominant de 5 à 24[–-]27", joined
    ):
        errors.append("Les annotations de pic Ethernet ou de diagnostic MCS ne correspondent pas au contenu attendu.")

    pdf_reader = PdfReader(str(PDF))
    if len(pdf_reader.pages) != 5:
        errors.append(f"Le PDF contient {len(pdf_reader.pages)} pages au lieu de 5.")

    full_total, full_by_slide = spoken_words(FULL_SCRIPT)
    short_total, _ = spoken_words(SHORT_SCRIPT, "## Coupures")
    if full_total != 603 or full_by_slide != [118, 119, 129, 132, 105]:
        errors.append(f"Comptage oral principal inattendu : {full_total} mots, détail {full_by_slide}.")
    if short_total != 457:
        errors.append(f"Comptage oral de secours inattendu : {short_total} mots.")

    slides_test = find_slides_test()
    if slides_test:
        result = subprocess.run(
            [sys.executable, str(slides_test), str(PPTX)], capture_output=True, text=True
        )
        if result.returncode != 0:
            errors.append("Débordement détecté par slides_test.py : " + (result.stdout + result.stderr).strip())
    else:
        errors.append("slides_test.py introuvable ; le contrôle de débordement n'a pas été exécuté.")
    return errors


def main() -> int:
    errors = validate()
    if errors:
        print("VALIDATION ÉCHOUÉE")
        for error in errors:
            print(f"- {error}")
        return 1
    print("VALIDATION RÉUSSIE")
    print("- 5 diapositives et 5 pages PDF")
    print("- titres >= 20 pt ; texte public >= 12 pt hors métadonnées approuvées")
    print("- sources présentes dans les notes de chaque diapositive")
    print("- données 89/100/52/68 et diagnostic MCS conformes au CSV")
    print("- aucun marqueur, motif sensible connu ou débordement détecté")
    print("- script principal : 603 mots ; version de secours : 457 mots")
    return 0


if __name__ == "__main__":
    sys.exit(main())
