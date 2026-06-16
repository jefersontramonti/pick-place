---
description: Cria um bloco SCL completo orquestrando arquiteto, desenvolvedor, revisor, segurança e documentador.
argument-hint: <tipo: OB|FB|FC|UDT> <Nome> "<descrição do que deve fazer>"
---

Crie o bloco solicitado: **$ARGUMENTS**

Orquestre o time de subagentes nesta ordem, encadeando os resultados:

1. **scl-architect** — produza o plano (interface, máquina de estados, ordem de
   chamada, intertravamentos). Comece por `scl_project_summary`.
2. **Você (orquestrador) escreve `.claude/handoff.md`** a partir do plano retornado
   pelo arquiteto — o arquiteto é read-only e não pode gravar. Sobrescreva o arquivo a
   cada bloco, no formato:
   ```markdown
   ## Handoff: <nome-do-bloco>
   **Decisão de arquitetura:** <por que essa estrutura>
   **Restrições de safety:** <o que precisa ser garantido / o que o safety-auditor valida>
   **Tags I/O reservadas:** <o que o tag-io-documenter deve catalogar>
   **Casos de teste pendentes:** <o que o test-sim-engineer ainda vai cobrir>
   ```
   Os subagentes seguintes leem este arquivo (ver "Contexto de projeto" em cada `.md`).
3. **scl-developer** — implemente o bloco a partir do plano + handoff e valide com
   `scl_validate_file`. Garanta a chamada no OB quando for um FB.
4. **scl-reviewer** — revise o bloco implementado (ciclo de scan, tipos, CASE).
5. Se houver E-Stop / intertravamento / modo de falha → **safety-auditor**.
6. Se envolver eixos/movimento → **motion-specialist** (em vez de, ou junto com, o developer).
7. **tag-io-documenter** — atualize a tabela de tags e a lista de I/O.

Ao final, consolide: arquivos criados, resultado da validação, achados de revisão/
segurança e pendências. Não conclua se houver erro de validação ou achado CRÍTICO em aberto.