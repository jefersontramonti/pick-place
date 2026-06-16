---
description: Varre todos os blocos com lógica de segurança e audita fail-safe.
argument-hint: (sem argumentos — varre o projeto inteiro)
---

Audite a segurança de todo o projeto.

1. Use `mcp__webstorm__scl_list_blocks` para inventariar os blocos.
2. Identifique os que contêm lógica de segurança (E-Stop, intertravamento, falha,
   estado seguro, parada de atuadores).
3. Para cada um, acione o **safety-auditor**.
4. Consolide um relatório único: por bloco, achados por severidade e recomendações.
   Destaque qualquer função que, por categoria de risco, exigiria F-CPU/PROFIsafe
   (lembrando que este projeto é standard) para decisão do usuário.