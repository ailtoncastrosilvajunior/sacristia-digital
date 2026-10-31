# IGMR — referência e cadastro no Sacristia Digital

## Edição adotada

**Tradução oficial em português (CNBB / Brasil).** Constante no código: `IgmrParagrafo::EDICAO_REFERENCIA`.

## Onde conferir (humano)

1. **Arquidiocese de Goiânia** — IGMR em PDF (documento disponibilizado pela arquidiocese).
2. **Veritatis Splendor** — IGMR em HTML (localizar parágrafos).
3. **Vaticano** — IGMR institucional; a redação portuguesa pode **diferir** da tradução brasileira.

Priorize o **livro físico CNBB** e o cadastro no app para o cartaz WhatsApp.

## Modelo de dados

| Campo | Uso |
|-------|-----|
| `texto` | Parágrafo integral |
| `trecho_cartaz` | Recorte para card/briefing (opcional; senão usa `texto`) |
| `edicao` | Edição de referência |
| `fonte` | Onde conferiu (ex.: livro, páginas) |
| `texto_conferido` | Conferido com o livro físico |

## Briefing ChatGPT

Envia `texto_para_cartaz` + rótulo de fonte. Instrução explícita: **não reescrever** a IGMR.

A UI admin expõe a página **Admin → IGMR → Referências oficiais** (`/admin/igmr/referencia`).

## Importação em massa (PDF CNBB)

Arquivos no repositório:

- `db/fixtures/igmr_cnbb_2002.pdf` — separata usada na extração
- `db/fixtures/igmr_paragrafos_cnbb_2002.json` — **399 parágrafos** (1–399)

A migration `ImportIgmrParagrafosCnbbFixture` faz **upsert** por `numero` (cria ou atualiza `texto`, `edicao`, `fonte`). Parágrafos já marcados como **conferidos** no app não são sobrescritos.

Reimportar manualmente:

```bash
docker compose run --rm web bin/rails igmr:import_fixture
# só novos (não atualiza existentes): UPDATE=0
# sobrescrever inclusive conferidos: FORCE=1
```

Regenerar o JSON a partir do PDF (dev, com venv):

```bash
python3 -m venv .venv-pdf && .venv-pdf/bin/pip install pypdf
.venv-pdf/bin/python script/extract_igmr_cnbb_json.py
```
