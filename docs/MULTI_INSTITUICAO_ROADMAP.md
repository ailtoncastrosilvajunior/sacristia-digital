# Multi-instituição — plano de atividades

Referência de execução (detalhes em `.cursor/plans/multi-tenant_sacristia_digital_*.plan.md`).

## Fase A — Fundação (em andamento)

- [x] Documento de roadmap
- [x] Tabelas `planos`, `instituicoes`, `instituicao_planos` + models (migrations `20261103170000`–`70003`)
- [x] `Current.instituicao` + `Instituicoes::Resolver` + `SetCurrentInstituicao`
- [x] `instituicao_id` nas tabelas operacionais + backfill Face de Cristo (migration)
- [x] Concern `InstituicaoScoped` + login Devise por instituição
- [x] Seeds ajustados para `facedecristo` (plano Completo vem do backfill)
- [x] `Instituicao#recurso?` via vínculo vigente
- [x] Branding cartaz / recibos → `Current.instituicao`
- [x] `InstituicaoScope` nos controllers + services financeiros/espórtulas (consultas `da_instituicao_atual`)
- [x] Spec de isolamento (`spec/requests/instituicao_isolation_spec.rb`)
- [ ] Rodar `bin/rails db:migrate` no ambiente local (incl. `20261104140000_create_liturgia_cartazes`)
- [x] Allowed hosts: subdomínios `*.INSTITUICAO_BASE_DOMAIN` + `*.localhost` (initializer)
- [x] Gates de menu/rota por `Instituicao#recurso?` (admin, coordenador, ministro, escala extra)

## Fase B — Piloto e módulos

- [x] Segunda instituição piloto (`saovicente`, plano `escala_liturgia`) no `db/seeds.rb`
- [x] Gates de menu/rota (`esportulas`, `financeiro_caixa`, `escala_extra`, `liturgia_cartaz`, `escala_mesc`)
- [x] Testes de isolamento entre slugs (base request spec; ampliar por recurso)
- [x] E-mail único por `(instituicao_id, email)` (`User` + login por tenant)

## Fase C — Liturgia

- [x] `liturgia_cartazes` por instituição (PNG WhatsApp; liturgia/IGMR/santo permanecem globais)
- [ ] Overrides locais (opcional — título/rodapé custom por tenant no cartaz)

## Fase D — Negócio

- [x] Provisionamento manual de tenant (`Instituicoes::Provisioner` + `rake instituicoes:provision`)
- [ ] Super-admin web, troca de plano com histórico
- [ ] Billing (Mercado Pago / Stripe)
