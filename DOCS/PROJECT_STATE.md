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
  **✅ VALIDADO E RODANDO NO PLCSIM** (2026-06-20): ciclo Pick & Place completo, torre piscando
  (byte de clock MB0), rotação sem volta extra, conexão via handshake do template S7-PLCSIM.
  **Lógica completa** criada e validada no linter MCP, cada um
  revisado (`scl-reviewer`) e auditado em safety (`safety-auditor`): UDTs `typeAxis`/
  `typeStation`, DB `StationData`, FCs `FC_ScaleVolt`/`FC_IoMapInputs`/`FC_IoMapOutputs`, FBs
  `FB_AxisPos`/`FB_Rotate180`/`FB_RotateToHome`/`FB_Conveyor`/`FB_MachineMode`/`FB_PickPlaceSeq`,
  e `OBs/OB_Main.scl`. Pisca da torre via **byte de clock da CPU** (MB0), não por FB.
- **Fase Modo MANUAL + IHM (2026-06-21): ✅ LÓGICA IMPLEMENTADA e validada** (aprovada sem
  CRÍTICO/ALTO). Novos: `FCs/FC_Interlocks.scl`, `FBs/FB_ManualControl.scl`; estendidos
  `typeStation` (`Cmd.Man.*`+`Sts.ManActive/ManRejected`), `FB_MachineMode` (mux `o_AutoMode`/
  `o_RunAuto`/`o_RunManual`), `OB_Main` (mux por modo latcheado). Mapa IHM em `tags.md` §10.
  **Falta TIA/WinCC** (DBs de instância incl. `FB_ManualControl_DB`, reinit `StationData`, device
  TP1500) e **validação no PLCSIM** — ver "Sessão 2026-06-21" ao fim deste arquivo.
  **Pendências só no TIA Portal** (não viram `.scl`): criar a tag table das
  24 tags (endereços no `tags.md` §6; `%ID/%QD`=Real), os 4 DBs de instância
  (`FB_MachineMode_DB`, `FB_Conveyor_M1_DB`, `FB_Conveyor_M2_DB`,
  `FB_PickPlaceSeq_DB`), atribuir `OB_Main` ao OB1, e calibrar `Cfg.*`. Escopo em
  `DOCS/ESCOPO_PickPlace.md`; arquitetura em `DOCS/ARQUITETURA_PickPlace.md`; I/O em
  `DOCS/tags.md`; componentes em `DOCS/Componentes_FactoryIO.md`.
- **Transição (2026-06-16):** removido TODO o código SCL do subsistema antigo (20 motores +
  2 reguladores ITV/PID — `FB_Motor`, `FB_MotorGroup`, `FB_PID`, `FB_Regulator`,
  `FB_RegGroup`, `MotorData`, `RegData`, `typeMotor`, `typeRegulator`, `typePidParams`,
  `OB_Main`). Histórico preservado no log de sessões abaixo. Agentes/comandos/skills mantidos.
- **Hardware:** mesma CPU **1518T-4 PN/DP** (FW V3.1). Target MCP/WebStorm S7-1500 confirmado
  (`.idea/sclCpuSettings.xml`, `sclHardwareTarget.xml`).
- **Simulação (PLCSIM ↔ FACTORY I/O) — pré-requisitos OBRIGATÓRIOS:** (1) **handshake do template
  S7-PLCSIM** no OB cíclico — heartbeat `QB511` (+1/scan) + espelho de entradas (periferia `16#1`
  → imagem `16#81`, 64 bytes) + DWords `QD1016/QD1020` + eco do byte 512. **Sem ele o driver não
  conecta** ("correct project template / run mode"). Código de protocolo do fornecedor: **não
  modificar**; rodar todo scan, espelho ANTES da leitura de I/O. (2) **Clock memory byte em MB0**:
  `%M0.5 = Clock_1Hz` (pisca lento), `%M0.2 = Clock_2.5Hz` (pisca rápido) — usado pela torre no
  `OB_Main`. Mudança de config de hardware (ex.: habilitar o clock byte) **derruba a conexão** →
  recompilar HW + download + RUN + reconnect no FACTORY I/O.
- **Segurança (lógica standard, sem F-CPU):** E-Stop NF agora em **`%I0.3`** (não `%I0.0`);
  `Stop` NF `%I0.7`; `Start`/`Reset` NO. Estado seguro: `M1:=0, M2:=0, Grab:=FALSE`, sem novo
  setpoint de eixo; latch de falha + reset por **borda**. Intertravamentos (anticolisão,
  exclusão mútua, handshake) na §7 do escopo.
- **Eixos X/Z:** **posicionamento analógico** (setpoint/feedback em tensão 0–10 V), **NÃO**
  Technology Objects/`MC_*`. Rotação do braço **por pulso** (`Rotate CW/CCW` borda, 1 pulso =
  90°; 180° = 2 pulsos). Gripper não usado.
- **Arquitetura:** plano completo em `DOCS/ARQUITETURA_PickPlace.md` (OB_Main,
  FB_MachineMode, FB_PickPlaceSeq, FB_AxisPos, FB_Rotate180, FB_RotateToHome, FB_Conveyor, FCs de
  I/O e escala, UDTs typeAxis/typeStation, DB StationData). Pisca da torre via byte de clock da
  CPU (MB0), não por FB. Ordem de build na §8. **Feitos:**
  `typeAxis`, `typeStation` (+`Sts.SensorBox`), `StationData`, `FC_ScaleVolt`,
  `FC_IoMapInputs`, `FC_IoMapOutputs`, `FB_AxisPos`, `FB_Rotate180`, `FB_RotateToHome`,
  `FB_Conveyor`, `FB_MachineMode`, `FB_PickPlaceSeq`, `OB_Main`. **✅ Lógica completa** —
  resta só a integração no TIA + validação no PLCSIM.
- **Equipe de agentes:** 7 subagentes + 5 comandos + 3 skills + hooks (SessionStart +
  PostToolUse validate + **SessionStart(compact|resume)** lembrete de memória). Permissões **autônomo mas limitado**
  (Write/Edit só em código/DOCS + handoff). Doc em `DOCS/AGENT_ARCHITECTURE.md` /
  `DOCS/GUIA_AGENTES.md` (local) e seção "Equipe de agentes" do `CLAUDE.md`.
  `motion-specialist`/skill `motion-control` em **standby** (posicionamento analógico).
- **Fase Modo MANUAL + IHM (2026-06-21): ✅ LÓGICA `.scl` IMPLEMENTADA** (ver bullet acima e
  "Sessão 2026-06-21" no log). Jog por posições predefinidas; esteiras jog puro; AUTO/MANUAL
  ortogonal (troca só em `Step=0`); mux do OB por `o_AutoMode`; `FC_Interlocks` fonte única das
  guardas. **IHM comanda Liga/Para/Reset** (mescla físico+IHM no `FC_IoMapInputs`: `+Cmd.HmiStart/
  HmiStopReq/HmiReset`); **E-Stop só físico** (`%I0.3`). **Decisão C-1:** rearme de EMERGÊNCIA é só
  físico (`+Cmd.ResetPhys` → `FB_MachineMode`; HMI reseta só FALHA); **partida remota aceita** sob
  C-1 (sem linha de visão; parada/partida seguras com pessoas exigiriam F-CPU/STO). Projeto das
  telas WinCC (6 telas + template + pop-ups) em **`DOCS/IHM_TP1500_Telas.md`**. **Falta TIA/WinCC +
  PLCSIM.**

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
- `.claude/hooks/memory-update-reminder.ps1` + `settings.json` — NOVO hook **SessionStart(compact|resume)**
  (lembra de persistir memória ao retomar/compactar — PreCompact não injeta contexto). Permissões "autônomo mas limitado".
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

## Sessão 2026-06-18 (cont. — bug da torre vermelha + auditoria de sinalização)

### Blocos criados/modificados (todos validados no MCP)
- `FB_MachineMode` — sinalização da FALHA (estado 3): `o_Red := TRUE` (fixo) → `o_Red :=
  #i_ClkSlow` (vermelho **pisca lento**, distinto da emergência que pisca rápido); `o_StopLite :=
  FALSE` → `TRUE` (FALHA = "PARADO + indicação", acende a luz Desliga). Sem variável nova.
- `FB_ClockGen` — **fallback fail-safe**: se `i_SlowHz`/`i_FastHz` ≤ 0, usa 1 Hz / 3 Hz padrão em
  vez de devolver FALSE (antes apagava o pisca). Removido o ramo `ELSE` que zerava a saída.
  `s_SlowState`/`s_FastState` ganharam inicializador `:= TRUE` (acendem no 1º scan — blinda
  "torre apagada na partida"). Sem variável nova.
- `StationData` (DB) — start values **explícitos** `Station.Cfg.ClkSlowHz := 1.0` e
  `ClkFastHz := 3.0` na seção `BEGIN` (antes dependiam só da herança do UDT). Sem campo novo no
  UDT — atribuição a membros já existentes.
- `DOCS/ESCOPO_PickPlace.md` (§3.1) e `DOCS/tags.md` (§7) — +linha de **FALHA** (vermelho pisca
  lento + Desliga aceso); documentado o fallback do clock.
- `CLAUDE.md` (tabela de agentes: developer/motion → **opus**; linha "Modelo por custo") e
  `PROJECT_STATE.md` (fraseado do hook "PreCompact" → "SessionStart(compact|resume)") —
  correções de divergências documentais achadas na verificação inicial do projeto.

### Decisões de arquitetura
- **EMERGÊNCIA × FALHA distinguem-se pela cadência do vermelho** (emergência = ~3 Hz; falha =
  ~1 Hz), no mesmo LED da torre. Decisão do usuário (havia 3 opções). FALHA não constava nas
  tabelas de sinalização → **formalizada** no escopo §3.1 e no `tags.md §7`.
- **Sinalização nunca pode apagar por config 0:** `FB_ClockGen` usa fallback de frequência e
  parte com a onda em nível alto. Princípio: perder a indicação de emergência por `Cfg.*Hz=0` é
  anti-fail-safe (registrado também nos comentários do FB e do DB).
- **Nenhuma mudança de interface nesta sessão** (sem nova VAR, UDT intacto) → **nenhum DB de
  instância precisa ser regenerado**; só recompilar os `.scl` e reinicializar `StationData`.

### Bugs encontrados e resoluções
- **Torre vermelha não acendia na emergência, mas acendia (fixa) na falha** → causa raiz:
  `i_ClkFast` travado em FALSE porque `Cfg.ClkFastHz` estava 0 no DB real (start values
  dependiam da herança do UDT, que **não repropaga** após reinit do DB; o `typeStation` mudou
  várias vezes). Emergência usa `o_Red := i_ClkFast` (ficava apagada); falha usava `o_Red :=
  TRUE` constante (acendia fixa) → assinatura exata do clock parado. **Correção:** fallback no
  `FB_ClockGen` + start values explícitos no `StationData` + init `TRUE` das ondas.
- Falha "ficava ligada direta", não piscava → era `o_Red := TRUE` por design (FALHA = fixo).
  Trocado para pisca lento conforme decisão do usuário.

### Achados da equipe de agentes (auditoria de TODAS as lâmpadas vs escopo)
- **scl-reviewer + safety-auditor: 0 CRÍTICO / 0 ALTO.** Lógica das 6 luzes correta nos 4
  estados (sem lâmpada indefinida, cores exclusivas, luz de Reset conforme §3.2, fiação do OB OK).
- Aplicados: init `TRUE` das ondas (recomendação única do safety-auditor — blinda partida);
  Desliga aceso na FALHA (BAIXO-1 do reviewer); formalização da FALHA na doc (MÉDIO-1).
- Riscos residuais aceitos (não-bloqueantes): pisca tem ~50% OFF (escopo exige pisca); lâmpada
  queimada/canal travado indetectável em lógica standard; distinção emergência×falha só por
  cadência é sutil; C-1 (E-Stop F-CPU) segue como a pendência normativa real (não é a torre).

### Próximos passos
- **TIA/PLCSIM:** **reinicializar o DB `StationData`** (ou escrever online `ClkFastHz=3.0`/
  `ClkSlowHz=1.0`) — sem isso o valor de carga antigo (0.0) persiste mesmo recompilando.
  Recompilar os 3 `.scl` alterados. **Confirmar:** emergência → vermelho rápido; falha →
  vermelho lento + Desliga aceso; parado → amarelo lento; Reset pisca quando há algo a rearmar.
- Pendências herdadas: C-1 (F-CPU/STO, decisão de risco), M-1, M-2; recuperação 90°/180° da
  rotação no PLCSIM (sessão anterior).
## Sessão 2026-06-20

### Blocos criados/modificados
- `FBs/FB_PickPlaceSeq.scl` — **fix de robustez** nos passos 7 (Rot CW) e 15 (Rot CCW): a guarda
  de anticolisão agora **gateia só a PARTIDA**; o trigger se sustenta via `OR o_Busy OR o_Done`
  do sub-FB até o handshake. Sem novas VAR (layout do DB de instância preservado). Validado limpo
  no MCP e revisado (scl-reviewer): sem regressão, sem deadlock; anticolisão na partida e
  fechamento de malha por `RotHome` no passo 15 preservados.
- `OBs/OB_Main.scl` — **endereço do byte de clock corrigido** de `%M10.5/%M10.2` para
  `%M0.5/%M0.2` (a config real da CPU tem o clock memory byte em **MB0**, não MB10). Comentários
  atualizados. (Linter MCP retornou cache stale citando os endereços antigos; disco confirmado correto.)
- `DOCS/LEVANTAMENTO_ERROS.md` — nova **seção H** (verificação completa: fix H1 rotação,
  esclarecimento H2 do falso-positivo `Cfg.Enabled`, itens residuais H3).
- ⚠️ **As edições acima estão SÓ nos `.scl` (repo), NÃO no projeto TIA** — o TIA reportou
  "all blocks up-to-date" (os `.scl` são fontes externas; precisam ser importados/regenerados).

### Decisões de arquitetura (ainda não no CLAUDE.md)
- **FACTORY I/O ↔ S7-PLCSIM (S7-1500) exige o handshake do template** dentro do OB cíclico:
  contador de **heartbeat em `QB511` (+1/scan)** + **espelho de entradas** (periferia `16#1` →
  imagem de processo `16#81`, 64 bytes via PEEK/POKE) + DWords de handshake (`QD1016/QD1020`) +
  eco do byte 512. **Sem isso o driver recusa com "correct project template / S7-PLCSIM run mode"**
  — mesmo com a CPU em RUN. NÃO é a lógica nem o clock byte. Código de protocolo do fornecedor:
  **não modificar/“otimizar”**; rodar todo scan, com o espelho de entradas ANTES da leitura de I/O.
  (Usuário já possui esse handshake no TIA → conexão restabelecida nesta sessão.)
- **Clock memory byte habilitado em MB0** (não MB10): `%M0.5 = Clock_1Hz` (pisca lento) e
  `%M0.2 = Clock_2.5Hz` (pisca rápido). É pré-requisito de comissionamento para a torre piscar.
- **`Cfg.Enabled := TRUE` é intencional** (ARQUITETURA §68; gate `i_Run AND i_Enabled AND
  i_BoxAtPick`). O "default FALSE" era do `typeRegulator` deletado — **falso-positivo do
  safety-auditor; NÃO mudar** (mudar quebraria a simulação, não há HMI para habilitar).

### Bugs encontrados e resoluções
- **Sobre-rotação latente (passos 7/15)** → o trigger caía quando `Rotating` subia (guarda tinha
  `AND NOT Rotating`), violando o contrato do `FB_Rotate180` ("manter `i_Trig` até `o_Done`");
  sob jitter de PV podia resetar o FB de DONE→IDLE e disparar **180° extra** → **correção:** guarda
  só na partida + sustento via `o_Busy/o_Done`. (Reclassificado de "CRÍTICO/FSM travada" → ALTO/
  robustez após análise de scan: no caso nominal não trava, pois o FB avança por `Rotating`.)
- **Torre não piscava / endereço do clock** → `OB_Main` lia `%M10.x` mas o clock byte real está em
  **MB0** → corrigido para `%M0.5/%M0.2`.
- **FACTORY I/O não conectava ("correct project template / run mode")** → causa: faltava o
  **handshake do template S7-PLCSIM** no projeto (não era lógica nem clock byte). Confirmado via
  fórum oficial da FACTORY I/O. **Resolvido:** handshake já presente no TIA do usuário → conectou.

### Validado no PLCSIM (fim da sessão) ✅
- **Conexão FACTORY I/O ↔ S7-PLCSIM** restabelecida (handshake do template no OB1).
- **Torre piscando** corretamente (byte de clock MB0): amarelo lento (PARADO), vermelho lento
  (FALHA), vermelho rápido (EMERGÊNCIA), verde fixo (RODANDO).
- **Rotação** completa 180° **sem volta extra** (fix dos passos 7/15 importado e recompilado no TIA).
- **Ciclo Pick & Place completo** rodando.
- **`FB_ClockGen` REMOVIDO**: era órfão; pisca vem do byte de clock. `Cfg.ClkSlowHz/ClkFastHz`
  ficaram sem consumidor (mantidos no UDT por ora).

### Próximos passos
- Itens residuais (opcionais/decisão): `FB_AxisPos.o_InPos` fica TRUE no estado seguro;
  nota cosmética do mapa de timeout em `FB_PickPlaceSeq.scl:374`; remover `Cfg.ClkSlowHz/ClkFastHz`
  do UDT numa limpeza futura (mexe no layout do DB → regen no TIA).
- Pendências herdadas: C-1 (F-CPU/STO, decisão normativa), M-1, M-2.

---

## Sessão 2026-06-21 — Modo MANUAL + IHM (lógica implementada)

Fase "Modo MANUAL + IHM SIMATIC" saiu do plano para `.scl`. Orquestração pelo time de
subagentes (architect → developer → reviewer → safety → tag-io). **Aprovada sem CRÍTICO/ALTO.**

### Blocos criados/alterados (todos validam no MCP)
- **`FCs/FC_Interlocks.scl`** (NOVO) — FC pura/stateless: fonte única das guardas de anticolisão
  (`o_CanMoveX/CanDescendZ/CanRotate`), reusada pelo Seq e pelo Manual. Sem E-Stop/estado seguro
  (responsabilidade do chamador). Validado + safety-auditor emitiu "contrato de uso" (na ARQUITETURA).
- **`UDTs/typeStation.scl`** — `+Cmd.Man{12 bool}` (M1Run/M2Run/XToPick/XToHome/XToPlace/ZToUp/
  ZToPlace/RotCW/RotCCW/RotHome/VacOn/VacOff) + `Sts.ManActive:Bool` + `Sts.ManRejected:Int`.
- **`FBs/FB_MachineMode.scl`** — `+i_AutoMode`, `+i_Step` → `+o_RunAuto/o_RunManual/o_AutoMode`
  (`o_Run = RunAuto OR RunManual`). Modo latcheado `s_AutoMode` com gate de troca só em `Step=0`.
  MANUAL = verde piscando lento. FSM/latches/SafeState inalterados.
- **`FBs/FB_ManualControl.scl`** (NOVO) — jog X/Z por posições predefinidas (FB_AxisPos próprios),
  esteiras jog puro, rotação por pulso (FB_Rotate180/FB_RotateToHome próprios), vácuo on/off
  (VacOff domina). Gate-mestre `t_active = i_RunManual AND NOT i_SafeState AND NOT i_Fault`.
  `Sts.ManRejected` (0..5, primeiro evento do scan). Interface `io_Station` IN_OUT.
- **`OBs/OB_Main.scl`** — mux **por modo latcheado** `IF o_AutoMode` (Conveyors+Seq) `ELSE`
  (FB_ManualControl); `Sts.ManActive := o_RunManual`; rotação roteada da fonte ativa.
- **`DOCS/tags.md`** — nova §10: mapa de tags IHM (52 símbolos do StationData), legenda
  `ManRejected`, TP1500 Comfort/WinCC. **Sem I/O física nova** (fase DB-cêntrica).

### Decisões-chave da sessão
- **Mux ramifica por `o_AutoMode` (modo latcheado), NÃO por `o_RunAuto`.** Senão o `FB_PickPlaceSeq`
  não rodaria em AUTO+PARADO/E-Stop e não executaria seu "Reset a IDLE" (`i_SafeState OR NOT i_Run`),
  congelando o Step no meio do ciclo. Por isso o `FB_MachineMode` ganhou a saída `o_AutoMode`.
- **`FC_Interlocks` é fonte única** das guardas (Seq + Manual) — evita divergência auto/manual.
- **Homing manual exige Z up** (anticolisão §7) e solta o trigger também na falha (`o_Fault`) —
  achados do safety/reviewer corrigidos antes de fechar.

### Achados de revisão (corrigidos) e pendências de verificação
- Corrigido: deadlock latente do homing (o_Fault não consumido); homing sem Z up; `ManRejected`
  "último vence" → "primeiro vence".
- **Verificar no PLCSIM:** (1) bumpless AUTO↔MANUAL (sem salto de SP; FB_AxisPos i_Enable=FALSE
  mantém o_SetPointCmd); (2) `InPos` herdado na transição AUTO→MANUAL (mitigado por troca só em
  Step=0); (3) TON congelado dos conveyors não emite pulso residual ao voltar MANUAL→AUTO;
  (4) `Sts.ManActive` = "MANUAL e RODANDO" — confirmar semântica esperada na tela WinCC.

### Pendências só no TIA/WinCC (não viram .scl)
- Regenerar DBs de instância: **`FB_ManualControl_DB`** (NOVO), `FB_MachineMode_DB` (interface
  mudou). `FB_PickPlaceSeq_DB` só recompilar (layout igual).
- **Reinit `StationData`** (typeStation cresceu → layout do DB mudou; senão start values não
  propagam — como já ocorreu com `ClkFastHz`).
- Recompilar `OB_Main`/`FB_MachineMode`/`FB_ManualControl`; importar `FC_Interlocks`.
- WinCC: criar device **TP1500 Comfort** + telas + binding simbólico (mapa em `tags.md` §10).

### Pendências herdadas (inalteradas)
- C-1 (parada segura real exigiria F-CPU/PROFIsafe/STO — **agravada** pelo jog manual aumentar a
  exposição do operador; decisão de risco do usuário), M-1, M-2.

---

## Sessão 2026-06-21 (cont.) — IHM TP1500: projeto de telas + comando IHM + decisões C-1

### Projeto de telas (novo doc)
- **`DOCS/IHM_TP1500_Telas.md`** (NOVO) — projeto das telas WinCC do TP1500 Comfort: **6 telas**
  (Início/Sinótico, Automático, Manual, Parâmetros, Alarmes, Sistema) + template (cabeçalho + barra
  de navegação) + 2 pop-ups (login, confirmação). Mapa de navegação, protótipos ASCII por tela,
  bindings de tag, lista de alarmes (FaultCode 1..4 / ManRejected 1..5), 3 níveis de acesso,
  convenções IEC, checklist de implementação. **Só projeto** — telas serão feitas no WinCC.

### IHM comanda Liga/Para/Reset (mescla físico+IHM)
- `+Cmd.HmiStart/HmiStopReq/HmiReset` no `typeStation`; `FC_IoMapInputs` agora MESCLA:
  `Start := físico OR HMI`, `Reset := físico OR HMI`, `Stop := físico AND NOT HmiStopReq` (NF — IHM
  só ADICIONA parada), `EStop` **inalterado** (só físico). Safety-auditor: **fail-safe preservado,
  sem defeito de código** (Stop NF imune a mascaramento, provado por tabela-verdade).

### Decisões de risco (C-1) tomadas pelo usuário
1. **Rearme de EMERGÊNCIA = só físico** (IMPLEMENTADO). `+Cmd.ResetPhys` (reset físico cru) alimenta
   só o `FB_MachineMode.i_Reset` (clear do latch de emergência); o `Cmd.Reset` mesclado (físico OU
   IHM) segue para a FALHA no `FB_PickPlaceSeq`. Resultado: **HMI reseta falha funcional, mas NÃO
   destrava emergência** — o reset físico co-localizado destrava ambos. `FB_MachineMode` não mudou
   (só a fiação no OB: `i_Reset := Cmd.ResetPhys`).
2. **Partida remota (`HmiStart`) ACEITA** como está — registrada como risco sob **C-1**: dá RODANDO
   sem linha de visão da zona. Em lógica standard não há garantia de zona livre; partida/parada
   seguras com pessoas na zona exigiriam **F-CPU/PROFIsafe/STO**. (Mitigações opcionais futuras:
   pré-aviso sirene/delay, intertravamento de zona livre.)

### Pré-requisitos WinCC (do `IHM_TP1500_Telas.md` §5, parte já no PLC)
- Botões `Cmd.Hmi*` = momentâneos ("set bit while key pressed"). A IHM **não** binda
  `Cmd.Start/Stop/Reset` (são derivados no FC) nem `Cmd.EStop`/`Cmd.ResetPhys` (físicos).
- TIA: o reinit do `StationData` agora cobre também `Cmd.HmiStart/HmiStopReq/HmiReset/ResetPhys`
  (nascem FALSE = seguro).
