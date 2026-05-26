# Testing Guide — Clio

## Oversikt

Clio har for øyeblikket **ingen Swift-enhetstester**. `Package.swift` definerer kun ett `executableTarget` (`Clio`) uten test-targets. Testing skjer via:

1. **Python-tester** — `pytest` i `tests/`
2. **Manuell bygging** — Xcode (`⌘B`) eller `build.sh`
3. **Pre-commit hooks** — automatiske sjekker ved `git commit`

---

## Python-tester (pytest)

```bash
# Kjør raske tester (standard — brukes av pre-commit)
pytest -m "not slow"

# Kjør alle tester
pytest

# Med verbose output
pytest -v
```

Testfiler ligger i `tests/`:

```
tests/
├── fixtures/              # Testdata
├── test_linear_sync.py    # Linear-sync skript
└── test_template.py       # Template for nye tester
```

---

## Bygge prosjektet

### Xcode (foretrukket)

```bash
# Åpne i Xcode
open Clio.xcodeproj

# Bygg: ⌘B
# Kjør: ⌘R
```

### Kommandolinje

```bash
# Swift Package Manager — kompilerer sources
swift build

# Full .app-bundle (for distribusjon)
./build.sh
```

---

## Pre-commit hooks

Kjøres automatisk ved `git commit`:

| Hook | Formål | Skip |
|------|--------|------|
| `trailing-whitespace` | Fjern trailing spaces | — |
| `end-of-file-fixer` | Newline på slutten av fil | — |
| `check-yaml` | Valider YAML-syntaks | — |
| `black` | Formater Python-kode | `SKIP=black` |
| `isort` | Sorter Python-imports | `SKIP=isort` |
| `flake8` | Lint Python (kun kritiske feil) | `SKIP=flake8` |
| `swiftlint` | Lint Swift-kode | `SKIP=swiftlint` |
| `swift-build` | Verifiser at Swift kompilerer | `SKIP_SWIFT_BUILD=1` |
| `pytest-fast` | Kjør raske Python-tester | `SKIP_TESTS=1` |

```bash
# Installer hooks (én gang)
pip3 install pre-commit
pre-commit install

# Kjør alle hooks manuelt
pre-commit run --all-files

# WIP-commit uten tester
SKIP_TESTS=1 git commit -m "WIP: pågående arbeid"
```

---

## CI/CD (GitHub Actions)

Workflows i `.github/workflows/`:

| Jobb | Kjøres på | Hva den gjør |
|------|-----------|--------------|
| `swift-test` | macOS 15 / Xcode 26 | `swift build`, `swift test`, `./build.sh` |
| `swiftlint` | macOS 15 | `swiftlint lint` |
| `python-lint` | ubuntu | flake8, black, isort |

```bash
# Sjekk CI-status
gh run list

# Se logg for en kjøring
gh run view <run-id> --log-failed
```

---

## SwiftLint

```bash
# Lint alle Swift-filer
swiftlint lint --quiet

# Installer hvis ikke tilgjengelig
brew install swiftlint
```

Konfigurasjon: `.swiftlint.yml` i rotmappen.

---

## Legge til nye Python-tester

1. Opprett testfil i `tests/` med prefiks `test_`
2. Følg AAA-mønsteret (Arrange-Act-Assert)
3. Marker trege tester med `@pytest.mark.slow`
4. Verifiser: `pytest -m "not slow"`
