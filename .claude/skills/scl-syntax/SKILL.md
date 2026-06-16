---
name: scl-syntax
description: Regras de sintaxe e idioma SCL (Structured Control Language) da Siemens para S7-1500/TIA Portal. Use ao escrever, editar ou revisar qualquer código .scl — tipos de dados, declarações (VAR/TEMP/STATIC), IF/CASE/FOR/WHILE/REPEAT, operadores e precedência, detecção de borda, chamada de FB/FC. Consulte sempre antes de gerar SCL para garantir sintaxe Siemens correta.
---

# Sintaxe SCL — Siemens S7-1500 (TIA Portal)

Referência rápida. Para detalhes, ver `DOCS/scl4.md` (referência de linguagem) e
`DOCS/creating SCL programs.md` (uso do editor). Convenções do projeto: comentários em
**PT**, nomes em **EN**, lógica **standard** (sem F-CPU).

## Regras gerais
- Cada instrução termina com `;`. Não diferencia maiúsculas/minúsculas (manter
  palavras-chave em MAIÚSCULAS, tags em PascalCase/camelCase por convenção).
- Comentários: `// linha` ou `(* bloco *)`. Não afetam execução.
- Cabeçalho de bloco: `{ S7_Optimized_Access := 'TRUE' }`.
- Organizar lógica em `REGION <nome> ... END_REGION`.

## Tipos de dados (S7-1500)
- **Inteiros:** SINT, INT, DINT, LINT (com sinal); USINT, UINT, UDINT, ULINT (sem sinal).
- **Reais:** REAL (~6 casas), **LREAL** (~15 casas — preferir em cálculo crítico).
- **Bits/strings:** BOOL, BYTE, WORD, DWORD, LWORD; CHAR, STRING, WCHAR, WSTRING.
- **Tempo/data:** TIME, **LTIME**, DATE, TOD/LTOD, DT, **LDT**, DTL.
- **Compostos:** ARRAY, STRUCT, UDT (PLC data type), REF_TO, VARIANT.
- S7-1500 suporta nativamente LREAL/LTIME/LINT e **comparação de STRUCT/UDT** (FW>=2.0).
- Constantes não-tipadas são interpretadas como o tipo mais largo (LINT/LREAL). **Não
  misturar** constantes tipadas e não-tipadas em expressões matemáticas.

## Seções de declaração
```
VAR_INPUT ... END_VAR      // entradas (i_)
VAR_OUTPUT ... END_VAR     // saídas (o_)
VAR_IN_OUT ... END_VAR     // passagem por referência
VAR ... END_VAR            // estáticas, mantêm valor entre scans (s_)
VAR_TEMP ... END_VAR       // temporárias, sem retenção (t_)
VAR CONSTANT ... END_VAR   // constantes
```
Inicialização: `s_Count : INT := 0;`  ·  Instância: `s_TonDelay : TON_TIME;`

## Instruções de controle
```scl
IF cond THEN ... ELSIF cond2 THEN ... ELSE ... END_IF;

CASE s_State OF
    0: ... ;
    1, 2: ... ;          // múltiplos rótulos
    10..20: ... ;        // faixa
    ELSE ... ;           // SEMPRE tratar estado inválido
END_CASE;

FOR i := 1 TO 10 BY 1 DO ... END_FOR;
WHILE cond DO ... END_WHILE;
REPEAT ... UNTIL cond END_REPEAT;
CONTINUE; EXIT; RETURN;   // GOTO existe mas evitar
```

## Operadores (precedência: aritmético > relacional > lógico)
`**` (potência) · `* / MOD` · `+ -` · `< > <= >=` · `= <>` · `NOT` · `AND`/`&` · `XOR` · `OR`
Atribuição `:=` (direita→esquerda). Combinadas: `+= -= *= /=`. Parênteses primeiro.

## Detecção de borda (NUNCA por flag manual)
```scl
s_StartEdge(CLK := i_Start);   // s_StartEdge : R_TRIG (ou F_TRIG)
IF s_StartEdge.Q THEN ... END_IF;
```

## Chamada de blocos
```scl
// FB precisa de DB de instância:
"FB_Conveyor_DB"(i_Start := "Start", i_Stop := "Stop", o_Run => "Motor");
// FC retorna valor:
#result := "FC_Scale"(in := #raw);
```

## Idiomas/cuidados frequentes
- Um FB só executa se chamado por um OB com seu DB de instância.
- E-Stop em lógica NF (`FALSE` = emergência).
- Cuidado com precisão REAL: ordene operações ou use LREAL (ver `DOCS/creating SCL programs.md`, seção 1.1.8).
- Evite divisão por zero e conversões implícitas entre tipos de tamanhos diferentes.
