#!/usr/bin/env python3
"""Bridge script: anonymize Norwegian text using no-anonymizer.

Called by AnonymizationService.swift via subprocess.
Reads input text from --input file, writes JSON result to --output file.

Exit codes:
    0  success
    1  unexpected error
    3  no-anonymizer not installed
"""

import argparse
import json
import os
import sys
import traceback


def main() -> None:
    parser = argparse.ArgumentParser(description="no-anonymizer bridge")
    parser.add_argument("--input", required=True, help="Path to input text file")
    parser.add_argument("--output", required=True, help="Path to write JSON result")
    args = parser.parse_args()

    try:
        with open(args.input, encoding="utf-8") as f:
            text = f.read()
    except OSError as exc:
        _write_error({"error": "io_error", "message": str(exc)})
        sys.exit(1)

    try:
        from no_anonymizer import anonymize
    except ImportError:
        # Fallback: try to locate the no-anonymizer src/ in common development paths
        _added = False
        for candidate in [
            os.path.expanduser("~/Github/no-anonymizer/src"),
        ]:
            if os.path.isdir(candidate) and candidate not in sys.path:
                sys.path.insert(0, candidate)
                _added = True
                break
        if _added:
            try:
                from no_anonymizer import anonymize
            except ImportError:
                _write_error(
                    {
                        "error": "library_not_installed",
                        "message": (
                            "no-anonymizer er ikke installert. Installer via: "
                            "pip install 'no-anonymizer[ner]'"
                        ),
                    }
                )
                sys.exit(3)
        else:
            _write_error(
                {
                    "error": "library_not_installed",
                    "message": (
                        "no-anonymizer er ikke installert. Installer via: "
                        "pip install 'no-anonymizer[ner]'"
                    ),
                }
            )
            sys.exit(3)

    try:
        result = anonymize(text)
    except RuntimeError as exc:
        msg = str(exc)
        if "not installed" in msg or "pip install" in msg:
            _write_error({"error": "library_not_installed", "message": msg})
            sys.exit(3)
        _write_error({"error": "runtime_error", "message": msg})
        sys.exit(1)
    except Exception as exc:
        _write_error(
            {
                "error": "unexpected",
                "message": traceback.format_exc(),
            }
        )
        sys.exit(1)

    payload = {
        "anonymizedText": result.anonymized_text,
        "redactions": [_serialize_redaction(r) for r in result.redactions],
        "stats": result.stats,
        "processingTimeMs": result.processing_time_ms,
    }

    # v2 forward-compat: include the new top-level fields when the
    # upstream library returns them. v0.5.0 (current) has none of these;
    # v2 (per docs/no_anonymizer_v2_implementasjon.md) returns all of them.
    # Swift side decodes them via optional fields with snake_case
    # CodingKeys — see AnonymizationService.swift.
    _maybe_set(payload, "version", getattr(result, "version", None))
    _maybe_set(
        payload,
        "flagged_for_review",
        _serialize_flagged_list(getattr(result, "flagged_for_review", None)),
    )
    _maybe_set(
        payload,
        "statistics",
        _serialize_statistics(getattr(result, "statistics", None)),
    )
    _maybe_set(payload, "audit_log_path", getattr(result, "audit_log_path", None))

    try:
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False)
    except OSError as exc:
        _write_error({"error": "io_error", "message": str(exc)})
        sys.exit(1)

    sys.exit(0)


# --- Serialisation helpers --------------------------------------------------
#
# All helpers are defensive: if an attribute is missing or None, the
# corresponding key is omitted from the JSON. v0.5.0 (no v2 attributes)
# produces exactly the same output as before this change.


def _serialize_redaction(r) -> dict:
    """Serialise one redaction. v1 fields are required; v2 enrichment
    (`decision`, `score`, `bucket`) is forwarded when present."""
    payload = {
        "position": r.original_position,
        "length": r.length,
        "category": r.category,
        "replacement": r.replacement,
    }
    _maybe_set(payload, "decision", getattr(r, "decision", None))
    _maybe_set(payload, "score", getattr(r, "score", None))
    _maybe_set(payload, "bucket", getattr(r, "bucket", None))
    return payload


def _serialize_flagged_list(flagged):
    """Convert the v2 `flagged_for_review` collection into a list of dicts
    with snake_case keys matching the Swift `FlaggedToken` decoder. Returns
    None if the input is falsy."""
    if not flagged:
        return None
    out = []
    for t in flagged:
        out.append(
            {
                "original": getattr(t, "original", None),
                "start": getattr(t, "start", None),
                "end": getattr(t, "end", None),
                "type": getattr(t, "type", None),
                "score": getattr(t, "score", None),
                "bucket": getattr(t, "bucket", None),
                "context_snippet": getattr(t, "context_snippet", None),
                "signals_summary": getattr(t, "signals_summary", None),
            }
        )
    return out


def _serialize_statistics(stats):
    """Convert the v2 `statistics` object into a dict with snake_case keys
    matching the Swift `AnonymizationStatistics` decoder. Returns None if
    the input is falsy."""
    if not stats:
        return None
    return {
        "total_candidates": getattr(stats, "total_candidates", None),
        "redacted": getattr(stats, "redacted", None),
        "flagged": getattr(stats, "flagged", None),
        "kept": getattr(stats, "kept", None),
        "by_bucket": getattr(stats, "by_bucket", None),
    }


def _maybe_set(d: dict, key: str, value) -> None:
    if value is not None:
        d[key] = value


def _write_error(payload: dict) -> None:
    print(json.dumps(payload, ensure_ascii=False), file=sys.stderr)


if __name__ == "__main__":
    main()
