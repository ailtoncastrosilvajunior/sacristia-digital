# Cartaz MESC v2 (protótipo)

Layout **1080×1920** usando a **moldura MESC** + camadas de texto alinhadas à arte aprovada.

## Arte de fundo

| Arquivo | Uso |
|---------|-----|
| `liturgia-moldura-mesc-template.jpg` | Cópia fiel do template ChatGPT (576×1024) — referência |
| `liturgia-moldura.jpg` | Moldura ativa (v1 e base do upscale) |
| `liturgia-moldura-1080.jpg` | Fundo do cartaz v2 (gerado a partir da moldura ativa) |

Para trocar o template: substitua `liturgia-moldura.jpg` e regenere os derivados:

```bash
bin/rails liturgia:cartaz:prepare_moldura
```

O v2 **prefere** `liturgia-moldura-1080.png` (sem recompressão JPEG no fundo).

### Variáveis de experimento (`.env`)

| Variável | Efeito |
|----------|--------|
| `LITURGIA_CARTAZ_RENDERER=v2` | Gera PNG pelo layout v2 |
| `LITURGIA_CARTAZ_EXPORT_DPR=2` | PNG 2× mais denso (2160×3840) |
| `LITURGIA_CARTAZ_FONT_SCALE=1.1` | Textos dinâmicos ~10% maiores |

Reinicie o servidor após alterar.

Coleta litúrgica, validação e escala permanecem iguais.

## Preview

Admin → Liturgia do dia (validada) → **Cartaz v2 (protótipo)**  
Rota: `GET /admin/liturgia/:id/cartaz_v2`

## Gerar PNG

Por padrão o botão **Gerar PNG WhatsApp** ainda usa **v1** (moldura).

Para exportar v2:

```bash
LITURGIA_CARTAZ_RENDERER=v2
```

Reinicie o servidor Rails após alterar o `.env`.

## Ajustes visuais

- Estilos: `app/views/mesc_cards/_styles.html.erb`
- Partials: `app/views/mesc_cards/_*.html.erb`
- Ponto focal da foto do santo (CSS): `--saint-focal-x` / `--saint-focal-y` em `_day_identity.html.erb` (futuro: campos no cadastro)
- Fundo artístico: hoje gradiente CSS; opcional colocar `app/assets/images/cartaz/mesc-fundo.png` e referenciar no `.mesc-card`

## Caso de referência

Calibrar visualmente com **31/10/2026** e comparar ao card aprovado do WhatsApp.
