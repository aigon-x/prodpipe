# Source vs Generated — AIGON Production Platform

> **STATUS: FOUNDATION PLACEHOLDER** — polityka w fazie genesis.

## Cel
Rozdzielenie źródła od artefaktów generowanych.

## Zasada

```text
SOURCE
  ↓
GENERATOR
  ↓
GENERATED ARTIFACT
```

Nie:

```text
generated file
  ↓
manual edit
  ↓
drift
```

## Wymagania
- Każdy generated artifact musi mieć wskazane źródło
- Wygenerowane pliki oznaczane jako generated (`.gitattributes`)
- Nie pozwól, aby wygenerowany plik był mylony ze źródłem

## Status
**STATUS: FOUNDATION PLACEHOLDER** — nie zaimplementowano w pełni.
