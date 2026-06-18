# PROJECT_STATE — histórico e decisões do projeto aula01

> Fonte canônica **in-project** de contexto entre sessões. Versionada com o código.
> Os subagentes leem este arquivo no início (ver bloco "Contexto de projeto" em cada
> `.claude/agents/*.md`). O comando `/wrap-session` adiciona uma nova seção datada ao
> fim a cada encerramento de sessão.
>
> Regra de divisão: `CLAUDE.md` = convenções e estado estrutural estável;
> `PROJECT_STATE.md` = histórico cronológico de decisões e do que mudou em cada sessão.

## Estado atual

- **Projeto atual: estação Two-Axis Pick & Place** (FACTORY I/O v2.5.10 ↔ S7-PLCSIM).
  **✅ LÓGICA COMPLETA — 13/13 blocos** criados e validados no linter MCP, cada um
  revisado (`scl-reviewer`) e auditado em safety (`safety-auditor`): UDTs `typeAxis`/
  `typeStation`, DB `StationData`, FCs `FC_ScaleVolt`/`FC_IoMapInputs`/`FC_IoMapOutputs`, FBs
  `FB_ClockGen`/`FB_AxisPos`/`FB_Rotate180`/`FB_Conveyor`/`FB_MachineMode`/`FB_PickPlaceSeq`,
  e `OBs/OB_Main.scl`. **Pendências só no TIA Portal** (não viram `.scl`): criar a tag table das
  24 tags (endereços no `tags.md` §6; `%ID/%QD`=Real), os 5 DBs de instância
  (`FB_ClockGen_DB`, `FB_MachineMode_DB`, `FB_Conveyor_M1_DB`, `FB_Conveyor_M2_DB`,
  `FB_PickPlaceSeq_DB`), atribuir `OB_Main` ao OB1, e calibrar `Cfg.*`. Escopo em
  `DOCS/ESCOPO_PickPlace.md`; arquitetura em `DOCS/ARQUITETURA_PickPlace.md`; I/O em
  `DOCS/tags.md`; componentes em `DOCS/Componentes_FactoryIO.md`.
- **Transição (2026-06-16):** removido TODO o código SCL do subsistema antigo (20 motores +
  2 reguladores ITV/PID — `FB_Motor`, `FB_MotorGroup`, `FB_PID`, `FB_Regulator`,
  `FB_RegGroup`, `MotorData`, `RegData`, `typeMotor`, `typeRegulator`, `typePidParams`,
  `OB_Main`). Histórico preservado no log de sessões abaixo. Agentes/comandos/skills mantidos.
- **Hardware:** mesma CPU **1518T-4 PN/DP** (FW V3.1). Target MCP/WebStorm S7-1500 confirmado
  (`.idea/sclCpuSettings.xml`, `sclHardwareTarget.xml`).
- **Segurança (lógica standard, sem F-CPU):** E-Stop NF agora em **`%I0.3`** (não `%I0.0`);
  `Stop` NF `%I0.7`; `Start`/`Reset` NO. Estado seguro: `M1:=0, M2:=0, Grab:=FALSE`, sem novo
  setpoint de eixo; latch de falha + reset por **borda**. Intertravamentos (anticolisão,
  exclusão mútua, handshake) na §7 do escopo.
- **Eixos X/Z:** **posicionamento analógico** (setpoint/feedback em tensão 0–10 V), **NÃO**
  Technology Objects/`MC_*`. Rotação do braço **por pulso** (`Rotate CW/CCW` borda, 1 pulso =
  90°; 180° = 2 pulsos). Gripper não usado.
- **Arquitetura:** plano completo em `DOCS/ARQUITETURA_PickPlace.md` (13 blocos: OB_Main,
  FB_MachineMode, FB_PickPlaceSeq, FB_AxisPos, FB_Rotate180, FB_Conveyor, FB_ClockGen, FCs de
  I/O e escala, UDTs typeAxis/typeStation, DB StationData). Ordem de build na §8. **Feitos:**
  `typeAxis`, `typeStation` (+`Sts.SensorBox`), `StationData`, `FC_ScaleVolt`,
  `FC_IoMapInputs`, `FC_IoMapOutputs`, `FB_ClockGen`, `FB_AxisPos`, `FB_Rotate180`,
  `FB_Conveyor`, `FB_MachineMode`, `FB_PickPlaceSeq`, `OB_Main`. **✅ TODOS os 13 blocos
  prontos** — lógica completa; resta só a integração no TIA + validação no PLCSIM.
- **Equipe de agentes:** 7 subagentes + 5 comandos + 3 skills + hooks (SessionStart +
  PostToolUse validate + **PreCompact** memória). Permissões **autônomo mas limitado**
  (Write/Edit só em código/DOCS + handoff). Doc em `DOCS/AGENT_ARCHITECTURE.md` /
  `DOCS/GUIA_AGENTES.md` (local) e seção "Equipe de agentes" do `CLAUDE.md`.
  `motion-specialist`/skill `motion-control` em **standby** (posicionamento analógico).

## Log de sessões

<!-- /wrap-session adiciona seções "## Sessão AAAA-MM-DD" abaixo desta linha -->

## Sessão 2026-06-13

### Blocos criados/modificados
- Nenhum bloco SCL. Sessão dedicada a infraestrutura de agentes/comandos.
- `.claude/agents/scl-architect.md` — adicionada seção "Arquitetura de blocos (quando
  usar OB/FB/FC/DB/UDT)" + heurística rápida; e bloco "Contexto de projeto (leia primeiro)".
- `.claude/agents/scl-developer.md` — adicionada seção "Esqueleto de cada tipo de bloco"
  (modelos SCL de UDT/FB/FC/OB/DB) + bloco "Contexto de projeto" com leitura do handoff.
- Bloco "Contexto de projeto" também em scl-reviewer, safety-auditor, motion-specialist,
  test-sim-engineer e (versão enxuta) tag-io-documenter.
- `.claude/commands/new-block.md` — orquestrador passou a escrever `.claude/handoff.md`
  a partir do plano do arquiteto (passo 2).
- Criados: `.claude/commands/wrap-session.md`, `DOCS/PROJECT_STATE.md`, `DOCS/COMANDOS.md`.
- `CLAUDE.md` — ponteiros para COMANDOS.md, PROJECT_STATE.md e AGENT_ARCHITECTURE.md.

### Decisões de arquitetura (ainda não no CLAUDE.md)
- **Context injection in-project:** subagentes começam cold; a fonte de contexto entre
  sessões é `CLAUDE.md` + `DOCS/PROJECT_STATE.md` (dentro do projeto), nunca o
  `~/.claude/projects/.../memory/` (que é só da sessão principal e não chega aos agentes).
- **Handoff é escrito pelo orquestrador**, não pelo scl-architect — o arquiteto é
  read-only (sem Write) de propósito; manter assim.
- **/wrap-session é comando, não hook:** hook SessionEnd roda depois do Claude parar e
  não preenche template; o comando deixa o Claude escrever via Write (append no PROJECT_STATE).
- Mantidos sem mudança (corretos): MCP-first no architect; separação opus/sonnet/haiku.

### Bugs encontrados e resoluções
- Proposta original apontava memória em `.claude/memory/...` → caminho inexistente →
  corrigido para fontes in-project (`CLAUDE.md` + `DOCS/PROJECT_STATE.md`).
- Proposta de `session-end.ps1` preencher template → hook não faz isso + `New-Item -Force`
  truncaria o log → descartado o hook, mantido só o comando `/wrap-session`.
- Proposta do architect escrever handoff → architect não tem Write → passou para o orquestrador.

### Próximos passos
- Voltar ao trabalho de SCL propriamente dito (próximo bloco/feature) usando `/new-block`.
- Lembrar de rodar `/wrap-session` ao fim das sessões (memória `wrap-session-routine`).
- Manter `DOCS/COMANDOS.md` em dia se criar/remover comandos.

## Sessão 2026-06-13 (cont. — reguladores ITV2051 + PID)

### Blocos criados/modificados
- `UDTs/typePidParams.scl` — NOVO. Sintonia reutilizável do PID: Kp, Ti, Td, N, bProp,
  cDeriv, OutMin, OutMax (LReal, com defaults). Ti=0 desliga I; Td=0 desliga D.
- `UDTs/typeRegulator.scl` — NOVO. Molde do regulador: Cmd(Setpoint%, ManualMode, Reset),
  Cfg(Enabled:=FALSE, **Pid: typePidParams**, AiRawMin/Max, AoRawMin/Max, DeviationLimit:=0,
  DeviationTime), Sts(Mode, SetpointOut, Pressure, Output, Deviation, RawOut, RawIn,
  Integral, Fault, FaultCode).
- `DBs/RegData.scl` — NOVO. `Regulators : ARRAY[1..2] OF typeRegulator`; start values de
  exemplo com `Cfg.Pid.*` (malha 1 = PI, malha 2 = PID).
- `FBs/FB_PID.scl` — NOVO. Controlador PID genérico em SCL (forma posicional), multi-instância.
  P ponderado por bProp; **integral usa erro puro SP−PV** (2-DOF correto); derivada sobre PV
  filtrada (Tf=Td/N) anti-kick; anti-windup por back-calculation; tracking/bumpless por
  i_TrackEnable; reset/init limpo. Proteções de divisão por zero (Ti/Td/N/Ts).
- `FBs/FB_Regulator.scl` — NOVO (virou wrapper). Escala AI→PV% e %→AO (NORM_X/SCALE_X),
  seleção Manual/Auto, E-Stop/estado seguro (0 V absoluto), latch de falha + reset por borda,
  checagem under/overrange e escala invertida. Chama `s_Pid : FB_PID` em todos os caminhos.
- `FBs/FB_RegGroup.scl` — NOVO. FOR 1..2 instanciando FB_Regulator; ARRAYs AI/AO; passa i_Ts
  e `io_Regulators[i].Cfg.Pid → cfg_Pid`.
- `DOCS/tags.md` — seção de reguladores ITV2051 (I/O analógico, typePidParams, FB_PID, Cfg.Pid,
  FaultCodes). Seção de motores intacta.
- `OBs/OB_Main.scl` — NÃO alterado (PID roda no OB30, criado no TIA Portal).

### Decisões de arquitetura (ainda não no CLAUDE.md)
- **ITV2051 é regulador PROPORCIONAL (analógico), não válvula on/off.** Comando por saída
  analógica 0–10 V; feedback por entrada analógica (monitor de pressão). Controle em %.
- **PID feito à mão em SCL** (decisão do usuário), NÃO PID_Compact / nenhum Technology Object.
- **PID extraído para FB próprio `FB_PID` genérico + UDT de sintonia `typePidParams`**, para
  suportar variações paramétricas (PI/PID/sintonias diferentes por malha) reutilizando 1 bloco.
  SCL clássico não tem polimorfismo em runtime — variações paramétricas via config (1 FB, N
  instâncias); algoritmos estruturalmente diferentes exigiriam família de FBs + seletor.
- **PID exige Ts determinístico → roda em OB de interrupção cíclica OB30 (50 ms)**, separado do
  OB1 dos motores. `i_Ts` passado ao FB deve casar com o período do OB30.
- **Bumpless via i_TrackEnable** (PID em tracking durante Manual) — dispensa F_TRIG/pré-carga.
- **Estado seguro = 0 V absoluto** (`o_RawOut := 0` literal), integral zerada, PID em Reset.
- **Tipos LReal** nos cálculos do PID (integral acumula; 1518T processa LReal nativo); só
  RawIn/RawOut são Int (WORD do periférico).

### Bugs encontrados e resoluções
- 1ª arquitetura assumiu válvula solenoide discreta (FB_Valve, fins de curso, máquina
  open/close) → usuário revelou o modelo SMC ITV2051 (proporcional) → replanejado do zero
  para regulador analógico. Handoff de válvula descartado (gravação interrompida a tempo).
- DeviationTime=0 fazia o TON disparar falha imediata → guarda passou a exigir
  `DeviationLimit>0 AND DeviationTime>0` (detecção desabilitada com 0).
- Bumpless não estrito: pré-carga sobrescrita pela soma integral no mesmo scan → integração
  bloqueada no scan de transição (depois resolvido de vez ao migrar bumpless para TrackEnable).
- Pré-carga perdida se a transição Manual→Auto ocorresse durante E-Stop (RETURN antes da
  pré-carga) → `s_Init` re-armado nos RETURN de estado seguro/falha (partida limpa no rearme).
- Estado seguro emitia `cfg_AoRawMin` → trocado por `0` literal (0 V absoluto garantido).
- Escala invertida (Max≤Min) → LIMIT com MN>MX é indefinido na S7 → valida e latcheia FaultCode 5.
- Margem de under/overrange do AI fixa (1382) → passou a ser proporcional ao span configurado.
- **2-DOF incorreto:** integral usava erro ponderado por bProp → corrigido para erro puro
  SP−PV (com bProp=1.0 fica idêntico ao anterior).
- Setpoint de Auto clampado pela faixa de saída → separado: Auto usa 0..100% (processo),
  Manual usa OutMin/OutMax (saída). Desvio força saída 0 V no mesmo scan do latch (FaultCode 4).

### Próximos passos
- **TIA Portal (não viram arquivo no repo):** criar OB30 `OB_CyclicPID` (50 ms) chamando
  `FB_RegGroup_DB(i_EStop:="EStop", i_Ts:=0.050, i_RawIn, o_RawOut, io_Regulators:="RegData".Regulators)`;
  criar `FB_RegGroup_DB`; criar tags `ITV1_PV %IW64`, `ITV2_PV %IW66`, `ITV1_CMD %QW80`,
  `ITV2_CMD %QW82` (tensão 0–10 V); habilitar `Cfg.Enabled` e sintonizar `Cfg.Pid.*` por malha.
- **Limitação de segurança a decidir:** fio rompido no AI 0–10 V é indetectável (live-zero) →
  considerar feedback 4–20 mA, bit de diagnóstico do módulo, ou habilitar DeviationLimit/Time.
- **Normativo:** se o ITV atuar em zona de risco a pessoas, a parada segura exige F-CPU/PROFIsafe
  (esta lógica é standard).
- Medir a dinâmica real do ITV e refinar Ts (20–50 ms) e os ganhos antes do tuning final.

## Sessão 2026-06-16

### Blocos criados/modificados
- **Removido** todo o código antigo (10 arquivos `.scl`: motores + reguladores); pastas de
  bloco esvaziadas (convenção mantida).
- **Criados e validados (MCP limpo):** `UDTs/typeAxis.scl` e `UDTs/typeStation.scl`, via
  `/new-block` (pipeline architect→handoff→developer→reviewer). Início da implementação.
- `DOCS/ARQUITETURA_PickPlace.md` — NOVO. Blueprint do `scl-architect` (13 blocos, interfaces,
  FSMs, ordem de build §8).
- `DOCS/GUIA_AGENTES.md` — NOVO (local/gitignored). Guia didático do sistema de agentes (vídeo).
- `.claude/hooks/memory-update-reminder.ps1` + `settings.json` — NOVO hook **PreCompact**
  (lembra de persistir memória antes da compactação). Permissões "autônomo mas limitado".
- Memória persistente reescrita (projeto = Pick & Place) + nova feedback `keep-context-in-sync`.
- `CLAUDE.md` — reescrito para o escopo Pick & Place; adicionada seção "Equipe de agentes".
- `DOCS/ESCOPO_PickPlace.md` — NOVO. Especificação completa: processo, mapa de I/O,
  estados da máquina, sequência (PICK 1–7 / PLACE 8–16), intertravamentos (§7), comandos,
  decisões fechadas (§9) e arquitetura proposta (§10).
- `DOCS/Componentes_FactoryIO.md` — NOVO. Referência dos componentes FACTORY I/O
  (Emergency Stop, botoeiras, Stack Light, sensor retrorreflexivo) → tags + cores IEC.
- `DOCS/tags.md` — reescrito para o Pick & Place (era dos motores/reguladores).
- `DOCS/Tags_New Scene_..._2026-06-16-13-16-09.xml` — export de tags do FACTORY I/O (fonte).
- `.claude/handoff.md` — resetado (apontava para blocos deletados).

### Decisões de arquitetura (refletidas no escopo/CLAUDE.md)
- E-Stop NF em `%I0.3`; Stop NF `%I0.7`; Start/Reset NO (confirmado pela doc dos componentes).
- Eixos por **posicionamento analógico** (V), não MC_*/TO. `FB_AxisPos` faz "em posição".
- Rotação **por pulso** (1=90°, 180°=2 pulsos) → primitiva `FB_Rotate180`. Gripper não usado.
- `Item Detected` (`%I1.1`) = **anti-esmagamento**: na descida do Z, ao acionar, para e liga
  o vácuo. M2 corre por padrão em RODANDO, pausa no depósito. Luz de Reset **pisca** se há falha.
- Z: maior tensão = mais descido (0 V topo). Setpoints iniciais propostos (calibrar no sim).

### Bugs encontrados e resoluções
- Nada crítico. Docs vivos (`PROJECT_STATE.md`, `CLAUDE.md`) reconciliados após criar os UDTs.

### Próximos passos
- **✅ Lógica SCL completa (13/13 blocos).** Os carry-forwards abaixo já foram cumpridos
  (histórico). Trabalho restante:
- **Integração no TIA Portal** (não vira `.scl`): criar a tag table (24 tags, §6 do `tags.md`;
  `%ID/%QD`=Real), os 5 DBs de instância (`FB_ClockGen_DB`, `FB_MachineMode_DB`,
  `FB_Conveyor_M1_DB`, `FB_Conveyor_M2_DB`, `FB_PickPlaceSeq_DB`), atribuir `OB_Main` ao OB1.
- **Validar no PLCSIM** (test-sim-engineer): ciclo 1–16, E-Stop/Stop/Reset, falhas (timeouts,
  FALHA 4/5), anticolisão, e a **§9.2** (setpoints/tolerância/velocidade exatos, polaridade
  NC/NO real, debounce de `i_Rotating`, espaçamento de caixas no release da M1, R1 parada-por-SP).
- **Decisão de processo pendente:** vácuo no E-Stop/FALHA = **(i) soltar a peça** (atual) vs
  **(ii) segurar** (muda só a máscara de `o_Grab` no `FC_IoMapOutputs`).
- **Carry-forward (FC_IoMapOutputs):** os FBs de processo (`FB_Conveyor`/`FB_AxisPos`/
  `FB_PickPlaceSeq`) devem **escrever** `Sts.M1Speed/M2Speed/VacuumOn/AxisX-Z.SP` no DB (via
  IN_OUT) antes do FC de saída rodar (ele só LÊ esses campos). O `FB_MachineMode` produz
  `o_SafeState` (entrada da máscara) e as 6 luzes (VAR_INPUT do FC de saída).
- **Carry-forward (eixos):** `FB_AxisPos` (feito, interface escalar) recebe `i_Tol`/`i_Debounce`
  por VAR_INPUT. No `FB_PickPlaceSeq`, ligar a `Cfg.PosTol`/`Cfg.PosDebounce` (**fonte única** —
  não os defaults de `typeAxis`), `i_PV := Sts.AxisX/Z.PV`, e escrever `o_SetPointCmd`/`o_InPos`
  em `Sts.AxisX/Z.SP`/`.InPos` (para o `FC_IoMapOutputs` ler o SP).
- **Safety no consumidor:** ao implementar `FB_MachineMode`, o safety-auditor valida o
  tratamento NF de `Cmd.EStop`/`Cmd.Stop` (latch, prioridade, reset por borda).
- Fechar §9.2 do escopo no PLCSIM (valores exatos, polaridade NC/NO, e **debounce de
  `i_Rotating`** — anti-glitch da contagem de 90° no `FB_Rotate180`, achado [MÉDIO] do
  revisor; largura de pulso já resolvida pelo handshake). Encaminhar ao test-sim-engineer.
- **Carry-forward (`FB_Conveyor`):** no `FB_PickPlaceSeq`, `o_ReleaseM1` deve **segurar nível
  durante todo o passo 5** (não pulso de 1 scan) — há latência de 1 ciclo (M1 roda antes da
  sequência no OB). Premissa §9.2/§7-risco7: o re-arm da M1 precisa de **nova borda de descida**
  do sensor → validar no PLCSIM que o espaçamento das caixas deixa o sensor livre no release
  (senão a 2ª caixa não re-latcha). Falha é para o lado seguro (M1 fica parada).
- **Carry-forward CRÍTICO (`FB_PickPlaceSeq` — latch de falha único):** decisão de arquitetura
  após achado [ALTO] no `FB_MachineMode` (que **removeu** seu `s_FaultLatch`). O `FB_PickPlaceSeq`
  é a **fonte única** da falha: `o_Fault` é **NÍVEL latcheado** (não pulso), `o_FaultCode`
  **congela** no 1º código; CLEAR só no **próprio reset** = borda de `i_Reset` **E** `i_EStop`
  rearmado (NOT i_SafeState), **clear-antes-do-set**, voltando a passo 0. O `FB_MachineMode`
  liga `i_SeqFault := o_Fault` (nível) e só reflete (FALHA por nível). Sem double-latch.
- **`FB_PickPlaceSeq` FEITO** (revisão pegou 1 CRÍTICO + 1 ALTO, corrigidos): interface por
  `io_Station` IN_OUT; FSM 0..16+99; multi-instancia AxisX/Z + RotCW/CCW; latch único
  (`o_Fault` nível, CLEAR = `s_rReset.Q AND i_EStop`); `s_stepIsMove` fora da guarda (timeout
  cobre a espera); R1 captura PV no contato; vácuo na FALHA = decisão **(i) soltar** (FSM zera
  `s_grab` no safe; FC mascara Grab) — *usuário pode trocar p/ (ii) segurar (muda máscara do FC)*.
- **Carry-forward `OB_Main` (último bloco):** chamar (ordem §4) FC_IoMapInputs → ClockGen →
  MachineMode → Conveyor M1/M2 → PickPlaceSeq → FC_IoMapOutputs. Fiar
  `PickPlaceSeq.i_EStop := Station.Cmd.EStop` (mesma fonte do MachineMode.i_EStop),
  `i_Reset := Cmd.Reset`, `io_Station := "StationData".Station`, `o_Fault → MachineMode.i_SeqFault`,
  `o_RotCW/CCW → FC_IoMapOutputs`, `o_ReleaseM1 → Conveyor M1.i_Release`, `o_PauseM2 → Conveyor M2.i_ForcePause`.
  DB de instância e tags físicas: criados no TIA Portal.

## Sessão 2026-06-16 (cont. — implementação completa da lógica, 13/13)

### Blocos criados/modificados
- **Lógica SCL 100% implementada** via `/new-block` (pipeline architect→handoff→developer→
  reviewer→safety por bloco), todos validados no linter MCP:
- `UDTs/typeAxis.scl`, `UDTs/typeStation.scl` (+`Sts.SensorBox`); `DBs/StationData.scl`.
- `FCs/FC_ScaleVolt.scl` (V↔eng, protegido), `FC_IoMapInputs.scl` (cópia crua %I/%ID→DB),
  `FC_IoMapOutputs.scl` (DB→%Q/%QD com máscara de safe-state; decisão B: luzes/rot por VAR_INPUT).
- `FBs/FB_ClockGen.scl` (pisca TON_TIME), `FB_AxisPos.scl` (posição+freeze), `FB_Rotate180.scl`
  (2 pulsos handshake por nível), `FB_Conveyor.scl` (M1 box-stop+release / M2 pause),
  `FB_MachineMode.scl` (núcleo fail-safe), `FB_PickPlaceSeq.scl` (FSM 0..16+99).
- `OBs/OB_Main.scl` (OB1 orquestrador, 7 chamadas na ordem §4, tags reais do TIA).
- Infra: hook `memory-update-reminder.ps1` (SessionStart compact|resume — PreCompact não injeta
  contexto); permissões "autônomo mas limitado"; agentes developer/motion → opus; `GUIA_AGENTES.md`
  (local/gitignored, p/ vídeo); `ARQUITETURA_PickPlace.md`, `Componentes_FactoryIO.md` (novos).

### Decisões de arquitetura (já refletidas em CLAUDE.md / ARQUITETURA / Estado atual)
- **I/O isolada em 2 FCs** (`FC_IoMapInputs/Outputs`); tudo flui pelo DB `StationData` (IN_OUT).
- **Eixos = posicionamento analógico** (V), não MC_*/TO. **Rotação por pulso** (handshake por
  nível, sem F_TRIG global). **Latch de falha ÚNICO** no `FB_PickPlaceSeq` (`o_Fault` nível);
  `FB_MachineMode` só reflete (FALHA por nível) — sem double-latch.
- **CLEAR de falha gateado por `i_EStop` físico** (não `o_SafeState`, que causa deadlock).
- **Realimentações no OB** (release/pause/seqFault) via valores persistidos (DB / DB de
  instância) — latência 1 scan inócua (níveis). **R1 anti-esmagamento:** captura PV no contato.
- **Sinalização FALHA = vermelho fixo** (a confirmar). **Vácuo no E-Stop = (i) soltar** (a confirmar).

### Bugs encontrados e resoluções (o pipeline multi-agente pagou-se)
- `FB_Rotate180`: **[CRÍTICO]** corrida na borda de descida de `Rotating` (F_TRIG global consumido
  tarde) → trocado p/ detecção por **nível gated por estado**.
- `FB_MachineMode`: **[ALTO]** double-latch de falha (CLEAR mal condicionado) → latch único movido
  p/ `FB_PickPlaceSeq`; FALHA por nível.
- `FB_PickPlaceSeq`: **[CRÍTICO]** deadlock do reset (`NOT i_SafeState` insatisfável na falha →
  máquina presa em FALHA) → CLEAR por `s_rReset.Q AND i_EStop`. **[ALTO]** trava silenciosa
  (timeout não cobria a espera da guarda; `s_stepIsMove` dentro do IF) → movido p/ fora da guarda.
- `StationData`: "1" acidental coladо (`END_DATA_BLOCK1`) → corrigido. Reformatações do WebStorm
  (indentação/comentários) em vários `.scl` → benignas, revalidadas.
- **1º compile no TIA (MHJ S7-1500): 2 erros + 2 warnings.** `FB_ClockGen` usava `LREAL_TO_TIME`
  (aceito pelo linter MCP, mas **inexistente no compilador TIA**) → corrigido p/
  `DINT_TO_TIME(LREAL_TO_DINT(ms))`; **0 erros após a correção (confirmado no TIA)**. Lição: o
  **linter MCP não é 100% fiel ao compilador TIA** (nomes de função) — compilar no TIA é a
  validação definitiva (registrado no CLAUDE.md "Cuidados importantes"). `FB_AxisPos.o_SetPointCmd`
  ganhou `:= 0.0` (silencia warning de não-init, benigno). Warning "I/O não configurado no
  hardware" = configurar módulos/endereços no TIA (Device Config), não é código.

### Próximos passos
- **TIA Portal** (não vira `.scl`): tag table (24 tags, `tags.md` §6; `%ID/%QD`=Real); 5 DBs de
  instância (`FB_ClockGen_DB`, `FB_MachineMode_DB`, `FB_Conveyor_M1_DB`, `FB_Conveyor_M2_DB`,
  `FB_PickPlaceSeq_DB`); atribuir `OB_Main` ao OB1; calibrar `Cfg.*`.
- **PLCSIM** (test-sim-engineer): ciclo 1–16, E-Stop/Stop/Reset, falhas/timeouts, anticolisão;
  **§9.2**: setpoints/tolerância/velocidade exatos, polaridade NC/NO real, debounce de `i_Rotating`,
  espaçamento de caixas no release da M1, R1 (parada por SP congelado vs. carga).
- **Decisões do usuário pendentes:** sinalização FALHA (vermelho fixo?); vácuo no E-Stop (i) soltar
  vs (ii) segurar.
- **Normativo:** E-Stop sobre eixos/rotação/esteiras com risco a pessoas exigiria F-CPU/PROFIsafe
  (lógica atual é standard fail-safe). Live-zero do AI (fio rompido em 0–10 V) indetectável.

## Sessão 2026-06-17 — comissionamento no PLCSIM (ciclo completo OK) + correções

### Blocos modificados (todos validados no MCP)
- `FB_AxisPos` — **A-1 (ALTO):** estado seguro agora congela na **posição atual** (`o_SetPointCmd
  := i_PV`), não no último destino. Antes o eixo continuava percorrendo ao alvo durante a
  falha/E-Stop (causou o robô descer na caixa).
- `FB_PickPlaceSeq` — 4 mudanças: (1) **estado 2** FALHA 4 só dispara com Z **de fato** no
  `Z_pickLimit` (`+ ABS(PV-Z_pickLimit)<=PosTol`) — antes o `InPos` residual de `Z_up` dava falso
  FALHA 4 no 1º scan; (2) **estado 11 (depósito)** é posicional (removida a espera por
  `NOT ItemDetected`, que travava — a peça fica sob o sensor); (3) **IDLE/homing**: em RODANDO
  o robô **referencia** (sobe Z → X home) antes de novo ciclo — recupera de falha fora de casa
  (M-3/"problema 2"); (4) **estado 1** alinhado ao padrão `InPos + PV-check` (reviewer). FaultCode
  5 **aposentado**.
- `FB_ClockGen` — `LREAL_TO_TIME`→`DINT_TO_TIME(LREAL_TO_DINT())` (TIA não tem LREAL_TO_TIME).
- `typeStation` — legenda do FaultCode (5 aposentado).

### Decisões de arquitetura
- **Estado seguro do eixo = congelar no PV** (segura onde está), não em 0 V (movimento) nem no
  destino (movimento). A máscara do `FC_IoMapOutputs` continua **não** mascarando o SP analógico —
  a segurança do eixo vive no `FB_AxisPos`.
- **IDLE é estado de homing**: em RODANDO o robô vai para casa (Z up → X home) antes de aceitar
  ciclo. Ocorre no **START** (em PARADO/safe os eixos congelam). Comando analógico à posição home
  (sem MC_*/referência).
- **Polaridade dos sensores** (`Sensor_caixa`, `Item Detected`): resolvida **no FACTORY I/O** (o
  `FC_IoMapInputs` segue cópia crua — TRUE = detectado).

### Bugs/achados (comissionamento + re-revisão dos agentes)
- **Falso FALHA 4** (estado 2, `InPos` genérico) e **deadlock no depósito** (estado 11,
  `NOT ItemDetected`) — corrigidos. Reviewer achou o **mesmo padrão "InPos genérico" no estado 1**
  (corrigido). Safety achou **A-1 (ALTO)** — corrigido — e recomendou **homing no reset** (feito
  via IDLE/homing). **C-1 (normativo):** parada segura dos eixos exigiria F-CPU/STO se houver
  acesso de pessoas — **decisão da análise de risco do usuário (pendente)**.

### Calibração validada no PLCSIM (§9.2)
- `Item Detected` aciona em **Z≈5.8**; caixa em **6.7**; `Z_pickLimit = 8.0` (limite só p/ "sem
  caixa"); **`Z_place = 6.5`** (caixa pousa na M2 com o robô em ~6.59; 6.8 era fundo demais →
  timeout); `M1StopDelay` reduzido (1,2 s era grande demais → caixa passava direto); `ConvSpeed`
  baixada (rápida demais → sensor não amostra: janela < scan do OB1). **Ciclo
  Pick→gira→deposita→retorna rodou completo e repetido.**

### Próximos passos
- **Testar no PLCSIM** as 4 correções: recuperação por homing (provocar falha no meio do ciclo →
  reset → start → robô sobe Z, vai pra home e retoma) e confirmar que o ciclo normal segue OK.
- **M-1:** confirmar que `Z_pickLimit` é alcançável dentro de `PosTol`. **C-1:** decisão de risco
  (F-CPU/STO). **M-2:** dwell de despressurização (opcional). Recompilar tudo no TIA.

## Sessão 2026-06-18 — recuperação pós-falha (release M1 + referenciamento da rotação)

### Blocos criados/modificados (todos validados no MCP)
- `FB_PickPlaceSeq` — **F1:** pulsa `o_ReleaseM1` no reset deliberado (`s_rReset.Q AND i_EStop`)
  → limpa o box-latch da M1 (senão a esteira fica travada após a falha e o ciclo reinicia sem
  caixa → FALHA 4). **F2:** estado 0 referencia a rotação (chama `s_RotHome` após Z up + X home);
  passo 15 confirma `RotHome`; `+VAR s_RotHome/s_trigHome`; `o_RotCCW := s_RotCCW.o_PulseCCW OR
  s_RotHome.o_PulseCCW`. Interface externa inalterada.
- **`FB_RotateToHome` (NOVO)** — primitiva: gira CCW até `i_AtHome` (sensor HOME), parada por
  sensor (não contagem), `i_MaxSteps`=4 anti-laço → `o_Fault`; "já em casa" → `o_Done` sem pulsar.
- `typeStation` — `+Sts.RotHome`. `FC_IoMapInputs` — `+i_RotHome` (cópia crua). `OB_Main` —
  `i_RotHome := "Inductive Sensor 0"`. `tags.md` — `%I1.3` (§2/§6).

### Decisões / I/O
- **Novo sensor de HOME de rotação:** `"Inductive Sensor 0"` = **`%I1.3`** (indutivo NA → TRUE =
  braço na casa/M1). Referência absoluta que faltava (rotação é por pulso). Feito via **pipeline
  completo** (architect→developer→reviewer→safety→tag-io).
- Passo 7 (CW p/ M2) segue por **contagem** (`FB_Rotate180`) — não há sensor no lado M2.

### Achados dos agentes (não-bloqueantes)
- Reviewer 0 CRÍTICO; 2 ALTO de robustez/latência a confirmar no PLCSIM (o_Done não consumido — a
  sequência usa `Sts.RotHome`; janela de 1 scan). Safety **APROVADO** (6 requisitos conformes).
- MÉDIO: estado 0 lê `s_RotHome.o_Fault` 1 scan atrasado → sempre FALHA segura; FaultCode pode ser
  1 (timeout) vs 3 (rotação) por modo de falha — ambos coerentes (código 1 cobre "homing").
  Deixado como está (fail-safe; item de verificação §9.2).

### Próximos passos
- **TIA:** criar a tag `%I1.3` "Inductive Sensor 0"; recompilar (`typeStation`/`StationData`
  recompilam; `FB_PickPlaceSeq_DB` regenera c/ a multi-instância `s_RotHome`; `FB_RotateToHome`
  novo). **Testar no PLCSIM:** recuperação 90°/180° (reset→start→gira CCW até HOME→retoma); sensor
  forçado FALSE → FALHA sem laço; §9.2 (polaridade NA, janela do sensor vs detente, FaultCode 1×3).
- Pendências herdadas: C-1 (F-CPU/STO, decisão de risco), M-1, M-2.