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
  **Implementação iniciada** — `UDTs/typeAxis.scl`, `UDTs/typeStation.scl`,
  `DBs/StationData.scl`, `FCs/FC_ScaleVolt.scl`, `FCs/FC_IoMapInputs.scl`,
  `FCs/FC_IoMapOutputs.scl`, `FBs/FB_ClockGen.scl`, `FBs/FB_AxisPos.scl` e
  `FBs/FB_Rotate180.scl` criados e validados no linter (MCP limpo); `OBs/` vazia, demais FBs a
  criar. Escopo em
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
  `FC_IoMapInputs`, `FC_IoMapOutputs`, `FB_ClockGen`, `FB_AxisPos`, `FB_Rotate180`.
  **Próximo:** `FB_Conveyor`.
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
- Continuar a implementação na ordem da `ARQUITETURA_PickPlace.md` §8: **próximo =
  `FB_ClockGen`** (1º FB com estado); depois `FB_AxisPos`, `FB_Rotate180`, `FB_Conveyor`,
  `FB_MachineMode`, `FB_PickPlaceSeq`, `OB_Main`.
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