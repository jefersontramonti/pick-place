# CLAUDE.md

Guia para o Claude Code trabalhar neste projeto.

## Sobre o projeto

`aula01` é um projeto **SCL (Structured Control Language)** para **PLC Siemens S7-1500**,
desenvolvido no **TIA Portal**, simulado em **FACTORY I/O + S7-PLCSIM** e editado no
WebStorm (`.idea/`).

> **Estado atual: ✅ lógica SCL COMPLETA (13/13 blocos — validados, revisados e auditados em
> safety). Resta integração no TIA Portal + validação no PLCSIM.** O escopo do processo
> está em **`DOCS/ESCOPO_PickPlace.md`** e a arquitetura em **`DOCS/ARQUITETURA_PickPlace.md`**:
> uma estação **Two-Axis Pick & Place** com duas esteiras (**M1** entrada, **M2** saída),
> comandos **Liga/Desliga/Emergência/Reset**, **torre de sinalização** e o ciclo **pega → gira
> 180° → deposita → retorna**. Os eixos X/Z são **posicionamento analógico** (setpoint/feedback
> em tensão 0–10 V), não Technology Objects. **Feitos e validados:** UDTs `typeAxis`/
> `typeStation`, DB `StationData`, FCs `FC_ScaleVolt`/`FC_IoMapInputs`/`FC_IoMapOutputs`, FBs
> `FB_ClockGen`/`FB_AxisPos`/`FB_Rotate180`/`FB_Conveyor`/`FB_MachineMode`/`FB_PickPlaceSeq` e
> `OB_Main`. **Pendências só no TIA** (não viram `.scl`): tag table (24 tags), 5 DBs de
> instância, atribuir OB1. Progresso ao vivo em `DOCS/PROJECT_STATE.md`.
>
> *(Histórico: o repositório teve antes um subsistema de 20 motores + 2 reguladores ITV,
> removido nesta sessão. O log fica em `DOCS/PROJECT_STATE.md`.)*

## Hardware alvo

- **CPU:** 1518T-4 PN/DP (Technology CPU) — MLFB `6ES7 518-4TP00-0AB0`
- **Firmware:** V3.1
- **Memória:** 9 MB de código + 60 MB de dados
- **Tempo de operação de bit:** 1 ns
- **Display:** integrado na CPU
- **Interfaces:**
  - 1ª — PROFINET RT/IRT, 2 portas
  - 2ª — PROFINET RT
  - 3ª — Gigabit Ethernet
  - 4ª — PROFIBUS
- **Variante "T" (Technology):** suporta **Motion Control** (eixos/Technology Objects:
  `TO_PositioningAxis`, `TO_SynchronousAxis`, came/leva, etc.) e instruções `MC_*`.
  > Nota: a **cena atual usa posicionamento analógico simples** (escrever setpoint em V,
  > ler posição em V, comparar com tolerância) — **não** usa `MC_*`/TO. Aproveitar Motion
  > Control só se o projeto evoluir para eixos reais.

## Ambiente de simulação

- **FACTORY I/O v2.5.10** (cena "New Scene") ↔ **S7-PLCSIM**.
- Export de tags da cena: `DOCS/Tags_New Scene_Siemens S7-PLCSIM_2026-06-16-13-16-09.xml`
  (fonte da verdade do endereçamento físico de I/O).

## Estrutura

```
aula01/
├─ OBs/          OB_Main.scl  (OB1 orquestrador — chama tudo na ordem §4)
├─ FBs/          FB_ClockGen, FB_AxisPos, FB_Rotate180, FB_Conveyor, FB_MachineMode,
│                FB_PickPlaceSeq
├─ FCs/          FC_ScaleVolt, FC_IoMapInputs, FC_IoMapOutputs
├─ DBs/          StationData (Station : typeStation)
├─ UDTs/         typeAxis, typeStation
├─ DOCS/         ESCOPO + ARQUITETURA + tags + Componentes + manuais SCL + export de tags
└─ .claude/      agentes, comandos, skills, hooks (mantidos)
```

Convenção de pastas por tipo de bloco: `OBs/`, `FBs/`, `DBs/`, `UDTs/`, e (quando
surgirem) `FCs/`. **Um bloco por arquivo `.scl`.**

### Arquitetura proposta (a confirmar ao implementar — ver §10 do escopo)
- **`OB_Main` (OB1)** — orquestra: lê comandos, roda a máquina de modo e a sequência.
- **`FB_MachineMode`** — estados PARADO/RODANDO/EMERGÊNCIA/FALHA + sinalização (torre,
  luzes de botão, lógica de pisca lento/rápido).
- **`FB_PickPlaceSeq`** — máquina de estados do ciclo do robô (passos da §5 do escopo).
- **`FB_AxisPos`** (reutilizável, 1 por eixo X/Z) — escreve setpoint, lê feedback, gera
  "em posição" (tolerância + debounce).
- **`FB_Rotate180`** — primitiva de rotação: 2 pulsos de `Rotate CW/CCW` (1 = 90°), contando
  quedas de `Rotating`, sinaliza fim em 180° (rotação é **por borda**, não por nível).
- **`FB_Conveyor`** (reutilizável, M1/M2) — liga/desliga (escreve velocidade) e, no M1,
  integra `Sensor_caixa` + delay.
- **UDT `typeStation`** (Cmd/Cfg/Sts) + **DB global** para HMI/diagnóstico.

## I/O (resumo — detalhe e convenções em `DOCS/ESCOPO_PickPlace.md`)

- **E-Stop deste projeto: `EStop` = `%I0.3` (lógica NF)** — atenção: difere do `%I0.0` do
  subsistema antigo. `Stop` (`%I0.7`) também é NF; `Start`/`Reset`/`Sensor_caixa` são NA.
- **Entradas:** Reset `%I0.4`, Sensor_caixa `%I0.5`, Start `%I0.6`, feedbacks do robô
  `%I1.0–%I1.2`; posições X `%ID30` / Z `%ID34` (Real, V).
- **Saídas:** luzes (botões/torre) `%Q0.3–%Q1.0`; `Grab`/`Rotate CW-CCW`/`Gripper CW-CCW`
  `%Q1.1–%Q1.5`; **M1 `%QD30`**, **M2 `%QD34`** (velocidade, Real), X SP `%QD38`,
  Z SP `%QD42`.

## Documentação de referência (DOCS/)

Sempre seguir a sintaxe dos manuais ao escrever SCL:

- **`ESCOPO_PickPlace.md`** — **especificação do projeto atual**: processo, mapa de I/O,
  sequência passo a passo, intertravamentos, sinalização e pontos a confirmar. Manter
  sincronizado com as interfaces dos blocos ao implementar.
- **`ARQUITETURA_PickPlace.md`** — **plano de arquitetura** (do `scl-architect`): 13 blocos,
  interfaces, máquinas de estado, ordem de chamada no OB, onde cada intertravamento vive e a
  ordem de implementação. Blueprint a seguir no `/new-block`.
- **`Componentes_FactoryIO.md`** — referência dos componentes FACTORY I/O da cena
  (Emergency Stop, botoeiras, Stack Light, sensor retrorreflexivo) mapeados às tags do
  projeto, com polaridades NC/NO e cores IEC 60204‑1.
- **`creating SCL programs.md`** — editor TIA Portal, expressões, precisão REAL/LREAL,
  constantes tipadas vs não-tipadas, exemplos.
- **`scl4.md`** — referência completa da linguagem: tipos, gramática, declarações, acesso a
  memória/DB, controle (IF/CASE/FOR/WHILE/REPEAT/GOTO), chamadas FB/FC, timers/counters IEC,
  conversões, interface de OB, nomenclatura.

Outros documentos de apoio em `DOCS/`:

- **`COMANDOS.md`** — referência dos comandos manuais (`/new-block`, `/review-block`,
  `/safety-check`, `/io-sync`, `/wrap-session`, skills). Atualizar ao mexer em
  `.claude/commands/`.
- **`PROJECT_STATE.md`** — histórico cronológico de decisões e log de sessões (lido pelos
  subagentes). Alimentado por `/wrap-session`.
- **`AGENT_ARCHITECTURE.md`** — design da arquitetura de subagentes/comandos/skills.
- **`tags.md`** — **mapa de I/O atual** (Pick & Place): tags físicas, polaridades, mapa de
  endereços, sinalização e setpoints iniciais. Sincronizar com a I/O via `/io-sync`.

### Documentos vivos (manter sincronizados)

A "cadeia de contexto" lida pelos subagentes precisa estar sempre atual — atualizar **antes
de seguir** para a próxima tarefa (ver memória `keep-context-in-sync`):

| Documento | Atualizar quando… |
|---|---|
| `DOCS/PROJECT_STATE.md` | mudou o estado / fim de sessão (`/wrap-session`) — **lido pelos subagentes** |
| `CLAUDE.md` | decisão ou estrutura **permanente** mudou (I/O, convenção, equipe, estrutura de pastas) |
| `.claude/handoff.md` | a cada `/new-block` (bloco em andamento) |
| memória (`MEMORY.md` + arquivos) | um fato **durável** mudou (cross-sessão) |
| `DOCS/tags.md` | a **I/O** mudou (`/io-sync`) |
| `DOCS/ESCOPO_PickPlace.md` | a **especificação** de processo mudou |
| `DOCS/ARQUITETURA_PickPlace.md` | a **interface/arquitetura** de blocos mudou |
| `DOCS/COMANDOS.md` · `AGENT_ARCHITECTURE.md` | comandos/infra de agentes mudaram |

Estáticos (não precisam manutenção): `scl4.md`, `creating SCL programs.md` (manuais),
`Componentes_FactoryIO.md`, `Tags_New Scene_*.xml` (export fonte), `GUIA_AGENTES.md` (local).

## Convenções de código SCL

- **Idioma dos comentários:** português.
- **Acesso otimizado:** blocos usam `{ S7_Optimized_Access := 'TRUE' }`.
- **Organização:** agrupar lógica em blocos `REGION ... END_REGION`.
- **Detecção de borda:** usar `R_TRIG`/`F_TRIG` em vez de comparar com flag manual.
- **Cada instrução termina com `;`**. SCL não diferencia maiúsculas/minúsculas, mas
  manter palavras-chave em MAIÚSCULAS e tags em camelCase/PascalCase.
- **Prefixos de tags sugeridos:** `i_` entrada, `o_` saída, `s_` estática interna,
  `t_` temporária.
- **Segurança:** E-Stop em lógica NF (normalmente fechado → `FALSE` = emergência).

## Recursos da S7-1500 (aproveitar)

- **LREAL/LTIME/LINT/LTOD/LDT** disponíveis nativamente — preferir em cálculos e
  tempos com precisão crítica (feedbacks/setpoints de posição em LReal).
- **Comparação de structs/UDTs** (`=`, `<>`) suportada a partir do firmware >= 2.0.
- Constantes não-tipadas são interpretadas como **LINT** (data type mais largo da CPU).
- Usar instruções IEC de timers/counters (`TON`, `TOF`, `CTU`, ...) com DB de instância.

## Cuidados importantes

- **OB precisa chamar o FB:** um FB só executa se for instanciado e chamado a partir
  de um OB (com seu DB de instância). FB órfão = código que nunca roda.
- **REAL vs LREAL:** preferir LREAL em cálculos com precisão crítica (REAL ~6 casas;
  LREAL ~15) — a S7-1500 processa LREAL nativamente.
- **Constantes:** evitar misturar tipadas e não-tipadas em expressões matemáticas
  (conversões implícitas podem gerar resultados errados).
- **Escala analógica:** posições e velocidades são tensões 0–10 V; usar `NORM_X`/`SCALE_X`
  para converter V ↔ unidade de engenharia, com `LIMIT` (clamp).

## Intertravamentos e segurança (garantir na implementação)

A lógica é **standard (sem F-CPU)** — a segurança é responsabilidade do código:

- **E-Stop NF (`%I0.3`) tem prioridade máxima:** força estado seguro em todos os blocos
  (M1=0, M2=0, `Grab`=FALSE, sem novo movimento), **latcheado**; só libera com emergência
  rearmada **+ borda nova** de Reset.
- **Anticolisão (mecânico):** rotacionar o braço **só com Z subido e X recolhido (home)**;
  mover X **só com Z subido**; **não** comandar X/Z enquanto `Rotating` estiver ativo.
- **Exclusão mútua de saídas:** `Rotate CW` ⊻ `Rotate CCW` nunca energizados juntos. Gripper
  **não usado** (`Gripper CW/CCW` ficam `FALSE`). Esteiras só em RODANDO.
- **Handshake da sequência:** o ciclo do robô só inicia com RODANDO + OK da esteira (caixa
  parada no `Sensor_caixa`); avanço passo a passo confirmando cada condição. O `Item Detected`
  (`%I1.1`) é **anti-esmagamento** na descida do Z, não gate de início.
- **Vácuo:** liga no instante em que `Item Detected` aciona durante a descida (anti-esmagamento);
  solta (desliga) só com Z na posição de depósito.
- **Rotação por pulso:** `Rotate CW/CCW` é por **borda** (1 pulso = 90°); **180° = 2 pulsos**
  (contar quedas de `Rotating`) — encapsular em `FB_Rotate180`.

## Equipe de agentes (orquestração)

Este projeto tem um **time de subagentes especializados** + comandos + skills + hooks + MCP.
A **conversa principal age como orquestrador**: roteia para o subagente certo pela tarefa,
agrega resultados e só traz ao usuário o que importa. Use o time **proativamente** — não
faça à mão o que um especialista faz melhor. Design completo em `DOCS/AGENT_ARCHITECTURE.md`;
referência de uso em `DOCS/COMANDOS.md`.

### Como os subagentes funcionam (importante para usá-los bem)
- **Começam "do zero"** (contexto isolado). A cada execução eles leem, nesta ordem:
  `CLAUDE.md` → `DOCS/PROJECT_STATE.md` → `.claude/handoff.md` (se existir). **Mantenha esses
  três em dia** — é o que torna os agentes autônomos *e* corretos (feito nesta sessão).
- **Menor privilégio:** cada um tem só as ferramentas do seu papel (read-only vs. write).
- **Modelo por custo/complexidade:** opus (arquitetura/revisão/safety), sonnet (execução),
  haiku (mecânico).

### Subagentes (`.claude/agents/`)
| Agente | Modelo | Quando usar | Capacidade |
|---|---|---|---|
| **scl-architect** | opus | **antes** de escrever código novo | Projeta blocos/FSM/interfaces — entrega **plano**, não implementa (read-only + MCP introspecção) |
| **scl-developer** | sonnet | implementar/editar blocos do plano | Escreve SCL idiomático e **valida no MCP** (Write/Edit/validate/generate) |
| **scl-reviewer** | opus | após implementar, antes de "concluído" | Caça bugs de ciclo de scan, tipos, CASE, IEC/Siemens (read-only) |
| **safety-auditor** | opus | qualquer E-Stop/intertravamento/falha/estado seguro | Audita fail-safe standard; aponta o que exigiria F-CPU (read-only) |
| **tag-io-documenter** | haiku | criar/alterar E/S | Mantém `DOCS/tags.md` coerente com símbolos↔endereços (MCP I/O) |
| **test-sim-engineer** | sonnet | projetar testes/cenários | Casos por estado/transição p/ PLCSIM, critérios de aceitação |
| **motion-specialist** | sonnet | **só** eixos com Technology Objects/`MC_*` | **Standby neste projeto** — os eixos X/Z são **analógicos** (`FB_AxisPos`), não TO/MC_* |

### Comandos (`.claude/commands/` — você digita; orquestram o time)
| Comando | Faz |
|---|---|
| `/new-block <OB\|FB\|FC\|UDT> <Nome> "<desc>"` | Ciclo completo: architect → (orquestrador grava `handoff.md`) → developer+valida → reviewer → safety (se houver segurança) → motion (se houver eixos TO) → tag-io-documenter |
| `/review-block <bloco>` | scl-reviewer + safety-auditor em paralelo; consolida por severidade |
| `/safety-check` | Varre todos os blocos com segurança via safety-auditor |
| `/io-sync` | tag-io-documenter reconcilia `tags.md` com o estado real (MCP) |
| `/wrap-session` | Append datado em `PROJECT_STATE.md`; promove decisões permanentes ao `CLAUDE.md` |

### Skills (`.claude/skills/` — auto-invocadas; conhecimento sob demanda)
`scl-syntax` (sintaxe Siemens, ao escrever/revisar SCL) · `scl-troubleshooting` (não compila/
valida) · `motion-control` (TO/`MC_*` — standby, ver acima).

### Hooks (`.claude/settings.json`) e MCP
- **SessionStart** injeta o target real (1518T V3.1, S7-1500). **PostToolUse (Write|Edit)**
  lembra de validar `.scl` no MCP. **SessionStart (compact|resume)** lembra de reconciliar a
  memória + `PROJECT_STATE.md` após compactação/retomada do contexto.
- **MCP WebStorm SCL** dá percepção real: `scl_project_summary` (sempre primeiro),
  `scl_list_blocks`, `scl_get_interface`, `scl_validate_file`, `scl_generate_fb`,
  `scl_read_io_list`. **Regra de ouro:** todo bloco `.scl` criado/editado é **validado no MCP**
  antes de concluir — nunca entregar bloco que não valida.

### Autonomia
Os agentes devem operar **com autonomia dentro do seu escopo**: pesquisar contexto sozinhos
(MCP + os 3 arquivos), implementar e validar sem hand-holding. O nível de **permissão** (o que
roda sem confirmação) é controlado por `.claude/settings.json` — ajustar lá conforme o quanto
de autonomia de escrita/execução se deseja conceder.

## Ao evoluir o projeto

Antes de escrever código novo, validar no PLCSIM os **pontos da §9.2** do escopo (largura do
pulso de rotação, valores exatos de setpoint/tolerância/velocidade, polaridade real NC/NO,
ponto de pega vs. sensor). As demais decisões já estão **fechadas** (§9.1). Implementar via
`/new-block` (começando pelas primitivas `FB_AxisPos` e `FB_Rotate180`), validar cada bloco no
linter SCL (MCP WebStorm) e manter `ESCOPO_PickPlace.md`/`tags.md` sincronizados com as
interfaces. Rodar `/wrap-session` ao encerrar.
