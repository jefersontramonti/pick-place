---
name: scl-troubleshooting
description: Diagnóstico de erros de compilação e de tempo de execução em SCL Siemens S7-1500 — erros de sintaxe/semântica, problemas de ciclo de scan, conversões de tipo, precisão REAL/LREAL, FB que não roda, falhas de validação no MCP. Use ao depurar um bloco que não compila, não valida ou se comporta de forma inesperada.
---

# Troubleshooting SCL — S7-1500

Guia de diagnóstico. Sempre rode `mcp__webstorm__scl_validate_file` primeiro para ver o
que o compilador acusa, depois cruze com os sintomas abaixo.

## Erros de compilação comuns
- **Tipo incompatível na atribuição** → o tipo da esquerda define o resultado; converta
  explicitamente (`INT_TO_REAL`, `DINT_TO_LREAL`, ...). Não confie em conversão implícita.
- **Constante fora de faixa (sublinhado amarelo)** → constante não-tipada convertida para
  um tipo menor gera valor errado/negativo. Tipar a constante (`DINT#50000`) ou não tipar
  nenhuma (ver `DOCS/creating SCL programs.md`, seção 1.1.9).
- **Falta `;`** ou `END_IF`/`END_CASE`/`END_REGION` não fechado.
- **Símbolo não declarado** → tag ausente na interface ou erro de nome (EN).
- **Chamada de FB sem DB de instância** → todo FB e toda instrução `MC_*`/`TON`/`R_TRIG`
  precisa de DB de instância.

## Bugs de tempo de execução (ciclo de scan)
- **Saída "atrasada" um scan** → valor lido antes de ser atribuído no mesmo scan; revise
  a ordem das regiões/instruções.
- **Estado pulado na FSM** → `CASE` sem `ELSE`, ou transição que avança 2 estados num scan.
- **E-Stop ignorado** → checagem de emergência sobrescrita por uma região posterior; a
  emergência deve ter prioridade e ser reavaliada a cada scan.
- **Auto-rearme indevido** → saiu de falha/emergência sem reset deliberado; exigir rearme
  do E-Stop **E** comando de reset.
- **Estática com lixo na energização** → inicialize (`:= 0`) e garanta estado seguro no
  primeiro scan.

## Cálculo / precisão
- **Resultado REAL errado ou divisão por zero inesperada** → soma/subtração com expoentes
  muito diferentes trunca casas. Reordene (`a - c + b`) ou use **LREAL** (~15 casas).
  Ver `DOCS/creating SCL programs.md`, seção 1.1.8.
- **Comparação de floats com NaN** → `==` e `<>` retornam FALSE com NaN.

## Validação no MCP
- `mcp__webstorm__scl_validate_file` → erros/avisos do bloco.
- `mcp__webstorm__scl_get_interface` → confira tipos da interface antes de chamar.
- ⚠️ Se o MCP reportar **target S7-1200** mas a CPU é **1518T (S7-1500)**, a validação
  pode liberar/bloquear recursos errados (LREAL/LTIME/comparação de structs). Corrigir o
  target do projeto antes de confiar no resultado.
