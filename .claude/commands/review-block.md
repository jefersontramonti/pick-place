---
description: Revisa um bloco SCL existente com revisor de código e auditor de segurança em paralelo.
argument-hint: <caminho ou nome do bloco>
---

Revise o bloco: **$ARGUMENTS**

Dispare em paralelo:
- **scl-reviewer** — bugs de ciclo de scan, tipos, máquina de estados, conformidade IEC/Siemens.
- **safety-auditor** — E-Stop NF, prioridade emergência>falha>operação, reset deliberado,
  estado seguro na energização (apenas se o bloco tiver lógica de segurança).

Consolide os achados por severidade (CRÍTICO/ALTO/MÉDIO/BAIXO) e proponha as correções.
Não aplique edições automaticamente — apresente o relatório para decisão.
