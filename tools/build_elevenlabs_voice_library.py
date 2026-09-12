#!/usr/bin/env python3
"""Build the stable 144-cue game library from the ElevenLabs Flow export."""

from __future__ import annotations

import argparse
import json
import math
import shutil
import struct
import subprocess
import tempfile
import wave
import zipfile
from pathlib import Path


STYLES = {
    "neutral": ("Neutral", "Matter_of_Fact"),
    "bureaucratic": ("Bureaucratic", "Formal"),
    "dismissive": ("Dismissive", "Curt"),
    "cautious": ("Cautious", "Guarded"),
    "questioning": ("Questioning", "Skeptical"),
    "weary": ("Weary", "Resigned"),
    "alarmed": ("Alarmed", "Urgent"),
    "angry": ("Angry", "Irritated"),
    "pleading": ("Pleading", "Choked"),
    "happy": ("Cheerful", "Warm"),
    "conspiratorial": ("Confidential", "Evasive"),
    "haunting": ("Uncertain", "Reflective"),
}

# ElevenLabs supplied two takes of these violin moods, but not the later
# short/medium/long grid. The build changes cadence with atempo (pitch stays
# intact) and makes bounded variants suitable for card-length playback.
VIOLIN_MOODS = {
    "neutral": "Neutral",
    "bureaucratic": "Bureaucratic",
    "dismissive": "Dismissive",
    "cautious": "Cautious",
    "questioning": "Questioning",
    "weary": "Weary",
    "alarmed": "Urgent",
    "angry": "Irritated",
    "pleading": "Sorrowful",
    "happy": "Warm",
    "conspiratorial": "Defensive",
    "haunting": "Nervous",
}

LENGTHS = ("short", "medium", "long")
VIOLIN_FILTERS = {
    "short": ("atempo=2.0,atempo=2.0,atrim=duration=1.55,afade=t=out:st=1.47:d=0.08", 1.55),
    "medium": ("atempo=2.0,atrim=duration=2.85,afade=t=out:st=2.77:d=0.08", 2.85),
    "long": ("atempo=1.35,atrim=duration=4.8,afade=t=out:st=4.72:d=0.08", 4.8),
}


def find_ffmpeg(explicit: str | None) -> Path:
    candidates = [
        Path(explicit) if explicit else None,
        Path(r"C:\Program Files\File Converter\ffmpeg.exe"),
        Path(r"C:\Program Files\Pointframe\ffmpeg.exe"),
    ]
    found = shutil.which("ffmpeg")
    if found:
        candidates.append(Path(found))
    for candidate in candidates:
        if candidate and candidate.is_file():
            return candidate
    raise SystemExit("ffmpeg not found; pass --ffmpeg PATH")


def index_sources(root: Path) -> dict[str, Path]:
    files = {path.name: path for path in root.rglob("*.mp3")}
    if len(files) != 228:
        raise SystemExit(f"Expected 228 unique MP3 files, found {len(files)}")
    return files


def find_one(files: dict[str, Path], fragment: str) -> Path:
    matches = [path for name, path in files.items() if fragment in name]
    if len(matches) != 1:
        raise SystemExit(f"Expected one source matching {fragment!r}, found {len(matches)}")
    return matches[0]


def wav_info(path: Path) -> dict[str, float | int]:
    with wave.open(str(path), "rb") as handle:
        channels = handle.getnchannels()
        rate = handle.getframerate()
        frames = handle.getnframes()
        width = handle.getsampwidth()
        raw = handle.readframes(frames)
    if width != 2:
        raise SystemExit(f"Unexpected sample width in {path}: {width}")
    samples = struct.iter_unpack("<h", raw)
    peak = max((abs(sample[0]) for sample in samples), default=0)
    peak_db = -120.0 if peak == 0 else 20.0 * math.log10(peak / 32767.0)
    return {
        "duration": round(frames / rate, 4),
        "sample_rate": rate,
        "channels": channels,
        "peak_level": round(peak_db, 2),
    }


def render(ffmpeg: Path, source: Path, target: Path, extra_filter: str = "") -> None:
    # Remove only initial dead air. Instrumental speech deliberately contains
    # pauses between phrases; stop-period removal would truncate at the first
    # such pause and can reduce a complete performance to a few milliseconds.
    filters = [
        "silenceremove=start_periods=1:start_duration=0.02s:start_threshold=-50dB"
    ]
    if extra_filter:
        filters.append(extra_filter)
    filters.append("loudnorm=I=-19:TP=-3:LRA=7")
    command = [
        str(ffmpeg), "-hide_banner", "-loglevel", "error", "-y", "-i", str(source),
        "-af", ",".join(filters), "-ac", "1", "-ar", "44100", "-c:a", "pcm_s16le", str(target),
    ]
    subprocess.run(command, check=True)


def build(zip_path: Path, output: Path, ffmpeg: Path) -> None:
    output.mkdir(parents=True, exist_ok=True)
    for old in output.glob("*.wav"):
        old.unlink()
    with tempfile.TemporaryDirectory(prefix="elevenlabs_voice_") as temp_name:
        temp = Path(temp_name)
        with zipfile.ZipFile(zip_path) as archive:
            archive.extractall(temp)
        files = index_sources(temp)
        clips = []
        for instrument in ("trombone", "violin"):
            for style, paired_styles in STYLES.items():
                for length in LENGTHS:
                    for take in (1, 2):
                        target_name = f"{instrument}_{style}_{length}_v{take}.wav"
                        target = output / target_name
                        if instrument == "trombone":
                            source_style = paired_styles[take - 1]
                            fragment = f"_Trombone__{source_style}__{length.capitalize()}_take1.mp3"
                            source = find_one(files, fragment)
                            render(ffmpeg, source, target)
                            transform = "trim outer silence; mono; -19 LUFS; 44.1 kHz 16-bit PCM"
                        else:
                            source_style = VIOLIN_MOODS[style]
                            fragment = f"_Violin__{source_style}_take{take}.mp3"
                            source = find_one(files, fragment)
                            cadence_filter, _ = VIOLIN_FILTERS[length]
                            render(ffmpeg, source, target, cadence_filter)
                            transform = f"pitch-preserving cadence fit ({length}); trim outer silence; mono; -19 LUFS; 44.1 kHz 16-bit PCM"
                        metadata = wav_info(target)
                        clips.append({
                            "filename": target_name,
                            "instrument": instrument,
                            "style": style,
                            "length": length,
                            "take": take,
                            **metadata,
                            "source": source.name,
                            "render_method": f"ElevenLabs Sound Effects MP3; {transform}",
                        })
    if len(clips) != 144:
        raise SystemExit(f"Expected 144 rendered cues, got {len(clips)}")
    manifest = {
        "version": 2,
        "library": "ElevenLabs instrumental speech replacements",
        "source_archive": zip_path.name,
        "clips": clips,
    }
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Built {len(clips)} cues in {output}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--ffmpeg")
    args = parser.parse_args()
    build(args.archive.resolve(), args.output.resolve(), find_ffmpeg(args.ffmpeg))


if __name__ == "__main__":
    main()
