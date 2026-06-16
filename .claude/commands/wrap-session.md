---
description: Consolida a sessão atual em DOCS/PROJECT_STATE.md antes de encerrar — blocos mexidos, decisões, bugs e próximos passos.
---

Antes de encerrar a sessão, **adicione** (append, sem apagar o conteúdo existente) uma
nova seção ao fim de `DOCS/PROJECT_STATE.md`, no formato abaixo, preenchida com o que
**de fato aconteceu nesta sessão** (não use placeholders vazios; se um item não se
aplica, escreva "nada"):

```markdown
## Sessão <AAAA-MM-DD>

### Blocos criados/modificados
- <nome do bloco> — <propósito / o que mudou>

### Decisões de arquitetura (ainda não no CLAUDE.md)
- <decisão e o porquê>

### Bugs encontrados e resoluções
- <sintoma> → <causa> → <correção>

### Próximos passos
- <o que fica pendente para a próxima sessão>
```

Regras:
- Use a data real de hoje no título da seção.
- **Append** ao fim do arquivo (após o "Log de sessões"); nunca sobrescreva seções
  anteriores nem o bloco "Estado atual".
- Se alguma decisão desta sessão for estrutural e permanente (convenção, mudança de
  interface, contagem de motores), reflita-a também no `CLAUDE.md` e no "Estado atual"
  do `PROJECT_STATE.md` — não deixe só no log datado.
- Mantenha conciso e factual: este arquivo é lido pelos subagentes no início das
  próximas sessões (Melhoria 1 — context injection).