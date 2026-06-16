# Handoff — (nenhum bloco em andamento)

> Este arquivo é **sobrescrito pelo orquestrador** a cada `/new-block`, a partir do plano do
> `scl-architect`, e lido pelos subagentes (developer/reviewer/safety/motion/test) como
> contexto do bloco atual. Quando não há bloco em andamento, fica neste estado neutro.

**Projeto atual:** estação Two-Axis Pick & Place (ver `DOCS/ESCOPO_PickPlace.md`).
**Nenhum handoff ativo.** Use `/new-block <tipo> <Nome> "<descrição>"` para iniciar um bloco;
o orquestrador preenche este arquivo no formato:

```markdown
## Handoff: <nome-do-bloco>
**Decisão de arquitetura:** <por que essa estrutura>
**Restrições de safety:** <o que o safety-auditor valida>
**Tags I/O reservadas:** <o que o tag-io-documenter cataloga>
**Casos de teste pendentes:** <o que o test-sim-engineer cobre>
```