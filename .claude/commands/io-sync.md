---
description: Reconcilia a lista de tags/I-O com os blocos existentes.
argument-hint: (sem argumentos)
---

Sincronize a documentação de tags e I/O com o estado real do projeto.

Acione o **tag-io-documenter** para:
1. Ler o estado real via `scl_project_summary` e `scl_read_io_list`.
2. Atualizar `DOCS/tags.md` (símbolo | tipo | endereço | direção | descrição PT).
3. Reportar inconsistências: tags órfãs, usos sem declaração, divergência símbolo↔endereço,
   nomes fora da convenção (`i_`/`o_`/`s_`/`t_`, tags em inglês).