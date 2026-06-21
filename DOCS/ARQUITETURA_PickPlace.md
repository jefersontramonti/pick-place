# Arquitetura — Estação Two-Axis Pick & Place

> Plano de arquitetura produzido pelo subagente **scl-architect** a partir de
> `DOCS/ESCOPO_PickPlace.md` (§5 sequência, §7 intertravamentos, §10 arquitetura).
> **Blueprint da implementação (em andamento — 11/12 blocos prontos; falta `FB_PickPlaceSeq` e
> `OB_Main`).** CPU S7-1500 1518T-4 PN/DP,
> SCL/TIA Portal, FACTORY I/O ↔ S7-PLCSIM. Convenções: comentários PT, tags EN, standard.
>
> Mantê-lo sincronizado com `ESCOPO_PickPlace.md` (processo) e `tags.md` (I/O) ao implementar.

---

## 1. Blocos propostos

| # | Tipo | Nome | Propósito | Quem chama |
|---|---|---|---|---|
| 1 | **OB** | `OB_Main` (OB1) | Orquestra: roteia I/O → DB, chama modo, sequência, eixos, esteiras, rotação; aplica estado seguro; roteia DB → I/O | SO da CPU |
| 2 | **UDT** | `typeStation` | Molde único de dados da estação (Cmd / Cfg / Sts) — interface HMI e barramento entre FBs | — (tipo) |
| 3 | **UDT** | `typeAxis` | Sub-molde de um eixo (SP, PV, InPos, tol, debounce) reutilizado para X e Z | — (tipo) |
| 4 | **DB** | `StationData` | DB global instanciando `typeStation`. HMI lê/escreve; OB e FBs acessam por `IN_OUT` | — (TIA, do UDT) |
| 5 | **FC** | `FC_IoMapInputs` | Roteia entradas físicas (`%I`, `%ID`) → `StationData`. Stateless | `OB_Main` (início do scan) |
| 6 | **FC** | `FC_IoMapOutputs` | Roteia `StationData` → saídas (`%Q`, `%QD`). Aplica máscara de estado seguro. Stateless | `OB_Main` (fim do scan) |
| 7 | **FC** | `FC_ScaleVolt` | Conversão V ↔ engenharia (NORM_X/SCALE_X + LIMIT). Pura | `FB_AxisPos`, HMI (opcional) |
| 8 | — | byte de clock da CPU | Pisca lento (`%M0.5`=1 Hz) e rápido (`%M0.2`=2,5 Hz) — bits de sistema (MB0), lidos direto no `OB_Main`. **Sem FB** (o padrão TON auto-rearmado não oscila em SCL otimizado) | `OB_Main` |
| 9 | **FB** | `FB_MachineMode` | Estados PARADO/RODANDO/EMERGÊNCIA/FALHA + latch de **emergência** (FALHA = nível via `i_SeqFault`, latcheada no `FB_PickPlaceSeq`) + sinalização (torre + luzes) | `OB_Main` |
| 10 | **FB** | `FB_AxisPos` | Eixo analógico genérico (1 inst./eixo): escreve SP, lê PV, "em posição" (tol + debounce), congela no safe | `FB_PickPlaceSeq` (multi-inst.) |
| 11 | **FB** | `FB_Rotate180` | A partir de um trigger, 2 pulsos de `Rotate CW/CCW` contando quedas de `Rotating`; `o_Done` em 180° | `FB_PickPlaceSeq` (CW e CCW) |
| 12 | **FB** | `FB_Conveyor` | Esteira analógica (M1/M2): liga (velocidade) / desliga (0 V). M1 integra sensor + delay | `FB_PickPlaceSeq`/`OB_Main` (2 inst.) |
| 13 | **FB** | `FB_PickPlaceSeq` | Máquina de estados do ciclo (passos 1–16), anticolisão e handshake. Multi-instancia `FB_AxisPos` (X,Z) e `FB_Rotate180` (CW,CCW) | `OB_Main` |

**Acréscimos além da §10 do escopo:** `FC_IoMapInputs`/`FC_IoMapOutputs` (isolam o
endereçamento físico num ponto único, com a máscara de estado seguro), `FC_ScaleVolt`
(V↔eng.) e o UDT `typeAxis` (evita duplicar campos de eixo). O pisca da torre usa o **byte de
clock da CPU** (MB0), não um FB. Os FBs principais + UDT/DB já vinham da §10.

**Multi-instância:** `FB_PickPlaceSeq` é dono dos sub-FBs de movimento (`FB_AxisPos` X/Z,
`FB_Rotate180` CW/CCW), pois o avanço de passo depende do `o_InPos`/`o_Done` deles. M1/M2
(`FB_Conveyor`) ficam preferencialmente dentro da sequência (pausa/religa nos passos 9/13 e
religa M1 no passo 5), com RODANDO liberando-os.

---

## 2. Interfaces dos blocos

Todos: `{ S7_Optimized_Access := 'TRUE' }`, comentários PT.

### 2.1 UDT `typeAxis`
```
SP        : LReal;   // setpoint comandado (V)
PV        : LReal;   // feedback de posição (V)
Tol       : LReal;   // tolerância "em posição" (V), default 0.1
Debounce  : Time;    // estabilização, default T#200ms
InPos     : Bool;    // (Sts) em posição
```

### 2.2 UDT `typeStation` (interface HMI + barramento)
```
// --- Cmd: comandos (físicos ou HMI) ---
Cmd :
   Start      : Bool;   // pulso de partida (%I0.6 ou HMI)
   Stop       : Bool;   // FALSE = parar (NF)
   EStop      : Bool;   // FALSE = emergência (NF)
   Reset      : Bool;   // pulso de reset (R_TRIG)
   AutoMode   : Bool;   // (reservado p/ HMI: auto/manual)

// --- Cfg: parametrização (HMI / start values) ---
Cfg :
   Enabled        : Bool   := TRUE;   // habilita o ciclo
   X_pick         : LReal  := 7.7;
   X_place        : LReal  := 6.8;
   X_home         : LReal  := 0.0;
   Z_up           : LReal  := 0.0;
   Z_place        : LReal  := 7.0;
   Z_pickLimit    : LReal  := 8.0;    // limite de descida na pega
   PosTol         : LReal  := 0.1;
   PosDebounce    : Time   := T#200ms;
   ConvSpeed      : LReal  := 5.0;    // V de regime das esteiras
   M1StopDelay    : Time   := T#500ms;
   SeqStepTimeout : Time   := T#30s;  // timeout de passo → FALHA
   ClkSlowHz      : LReal  := 1.0;
   ClkFastHz      : LReal  := 3.0;

// --- Sts: status (lido pela HMI) ---
Sts :
   Mode        : Int;     // 0=PARADO 1=RODANDO 2=EMERGÊNCIA 3=FALHA
   Step        : Int;     // passo atual da sequência (0..16)
   AxisX       : typeAxis;
   AxisZ       : typeAxis;
   BoxAtPick   : Bool;    // OK da esteira (caixa posicionada)
   ItemDetected: Bool;    // %I1.1 espelhado
   Rotating    : Bool;    // %I1.0 espelhado
   VacuumOn    : Bool;    // estado do Grab
   M1Speed     : LReal;
   M2Speed     : LReal;
   Fault       : Bool;
   FaultCode   : Int;     // 0=ok 1=timeout X 2=timeout Z 3=timeout rotação 4=Z limite s/ItemDet 5=caixa não liberada
   CycleCount  : DInt;
```
> HMI escreve em `StationData.Cmd.*` / `Cfg.*`; lê `Sts.*`. OB e FBs recebem
> `io_Station : typeStation` por `IN_OUT` (referência ao `StationData`).

### 2.3 FC `FC_ScaleVolt`
```
VAR_INPUT  i_Volt:LReal; i_VMin:LReal; i_VMax:LReal; i_EngMin:LReal; i_EngMax:LReal;
(retorno)  : LReal;   // valor em engenharia (clamp por LIMIT)
```

### 2.4 FC `FC_IoMapInputs` / `FC_IoMapOutputs`
```
// FC_IoMapInputs : Void  (IMPLEMENTADO)
VAR_INPUT  i_EStop,i_Stop,i_Start,i_Reset,i_SensorBox,i_Rotating,i_ItemDetected : Bool;
           i_Xpos,i_Zpos : Real;        // %ID30,%ID34 (FACTORY I/O entrega Real → convertido p/ LReal no .PV)
VAR_IN_OUT io_Station : typeStation;    // grava em Cmd.* / Sts.* (cópia crua, sem inverter NF)

// FC_IoMapOutputs : Void  (IMPLEMENTADO — decisão B: luzes + RotCW/CCW vêm por VAR_INPUT
//   dos FBs; M1/M2/Grab/SP vêm do DB. typeStation NÃO ganhou campos.)
VAR_INPUT  i_SafeState : Bool;          // máscara (FB_MachineMode.o_SafeState)
           i_Red,i_Green,i_Yellow,i_ResetLite,i_StartLite,i_StopLite : Bool;  // de FB_MachineMode
           i_RotCW,i_RotCCW : Bool;     // de FB_PickPlaceSeq
VAR_IN_OUT io_Station : typeStation;    // lê Sts.M1Speed/M2Speed/VacuumOn/AxisX.SP/AxisZ.SP
VAR_OUTPUT o_ResetLite,o_Red,o_Green,o_Yellow,o_StartLite,o_StopLite,o_Grab,
           o_RotCW,o_RotCCW,o_GripCW,o_GripCCW : Bool;
           o_M1,o_M2,o_Xsp,o_Zsp : Real;   // %QD são Real (LREAL_TO_REAL na escrita)
```
> `FC_IoMapOutputs` zera fisicamente `o_M1/o_M2/o_Grab/o_RotCW/o_RotCCW` quando `i_SafeState`
> — última barreira antes do periférico. `o_GripCW/CCW` sempre FALSE. **Não** mascara luzes
> nem SP de eixo (sinalização precisa indicar emergência; SP é congelado pelo `FB_AxisPos`).
> Exclusão mútua `RotCW⊻RotCCW` garantida (conflito → ambos FALSE).
> **Carry-forward:** os FBs de processo escrevem `Sts.M1Speed/M2Speed/VacuumOn/AxisX-Z.SP` no
> DB (via IN_OUT) antes do FC rodar — a definir nas interfaces de `FB_Conveyor`/`FB_AxisPos`/
> `FB_PickPlaceSeq`.

### 2.5 Pisca da torre — byte de clock da CPU (sem FB)
O pisca vem dos bits de sistema do **clock memory byte** (CPU → System and clock memory,
endereço **MB0**), lidos direto no `OB_Main`:
```
#t_clkSlow := %M0.5;   // Clock_1Hz   -> pisca lento  (amarelo PARADO / vermelho FALHA)
#t_clkFast := %M0.2;   // Clock_2.5Hz -> pisca rápido (vermelho EMERGÊNCIA)
```
Determinístico e imune ao tempo de scan. **Não usar** o padrão TON auto-rearmado
(`IN := NOT Q`) em SCL otimizado — ele não oscila (recálculo de `.Q` a cada acesso). Ver
`DOCS/compass_artifact_*.md`.

### 2.6 FB `FB_MachineMode`
```
VAR_INPUT  i_Start,i_Stop,i_EStop,i_Reset : Bool;
           i_SeqFault : Bool;        // falha vinda da sequência (timeout etc.)
           i_ClkSlow,i_ClkFast : Bool;
VAR_OUTPUT o_Mode : Int;            // 0..3
           o_Run  : Bool;           // habilita esteiras + sequência
           o_SafeState : Bool;      // E-Stop OU Stop OU Falha ativos
           o_Red,o_Green,o_Yellow,o_StartLite,o_StopLite,o_ResetLite : Bool;
VAR        s_State : Int;
           s_Reset : R_TRIG;
           s_Latched : Bool;        // latch de emergência (só emergência)
```
> **Falha por nível:** `FB_MachineMode` NÃO latcheia falha — `i_SeqFault` é **nível** e
> entra em FALHA diretamente. O latch de falha é **único** e vive no `FB_PickPlaceSeq`
> (`o_Fault`). Decisão pós-revisão (achado [ALTO]): elimina double-latch, glitch de 1 scan
> e disputa da borda de Reset entre os dois blocos.

### 2.7 FB `FB_AxisPos`
```
VAR_INPUT  i_Enable : Bool;         // FALSE = congela (não escreve novo SP)
           i_SetPoint : LReal;      // SP desejado (V)
           i_PV : LReal;            // feedback (V)
           i_Tol : LReal;  i_Debounce : Time;
           i_SafeState : Bool;
VAR_OUTPUT o_SetPointCmd : LReal;   // SP a escrever no %QD
           o_InPos : Bool;
VAR        s_tDebounce : TON_TIME;   // (TON_TIME — variante com PT:Time)
```
> Em `i_SafeState` / `NOT i_Enable`: segura o último `o_SetPointCmd` (não comanda novo
> destino) → "congela o eixo" da §3 do escopo.

### 2.8 FB `FB_Rotate180`
```
VAR_INPUT  i_Trig : Bool;           // dispara a sequência de 180°
           i_Dir : Bool;            // TRUE=CW, FALSE=CCW (informativo)
           i_Rotating : Bool;       // %I1.0
           i_SafeState : Bool;
VAR_OUTPUT o_PulseCW,o_PulseCCW : Bool;
           o_Busy,o_Done : Bool;
VAR        s_State : Int := 0;     // 0 IDLE, 1 PULSE, 2 MOVING, 3 DONE (IMPLEMENTADO)
           s_Dir   : Bool;          // sentido travado na partida
           s_Count : Int := 0;      // incrementos de 90° concluídos (0..2)
           s_trig  : R_TRIG;        // borda de subida do trigger
```
> **IMPLEMENTADO (refinado vs. esboço):** sem `s_tPulse`/`s_fRot`. Pulso segurado até
> `Rotating` subir (handshake) e a conclusão de cada 90° detectada por **nível gated por
> estado** (`NOT i_Rotating` só no state 2). Resolve o item §9.2 da largura de pulso e a
> corrida de borda. *(A validar no PLCSIM: debounce de `i_Rotating` p/ glitch — ver §9.2.)*

### 2.9 FB `FB_Conveyor`  (IMPLEMENTADO — decisão A do release)
```
VAR_INPUT  i_Run : Bool;            // permissão geral (modo RODANDO)
           i_SafeState : Bool;      // estado seguro -> 0 V
           i_Speed : LReal;         // V de regime (Cfg.ConvSpeed)
           i_HasSensor : Bool;      // TRUE só para M1 (habilita box-stop)
           i_Sensor : Bool;         // sensor M1 (TRUE=caixa) <- Sts.SensorBox
           i_StopDelay : Time;      // atraso da borda até parar (Cfg.M1StopDelay)
           i_ForcePause : Bool;     // pausa M2 no depósito <- o_PauseM2
           i_Release : Bool;        // pulso: libera o box-latch da M1 <- o_ReleaseM1
VAR_OUTPUT o_Speed : LReal;         // 0.0 ou i_Speed (consumidor -> Sts.M1/M2Speed)
           o_BoxArrived : Bool;     // (M1) caixa posicionada (= s_boxLatch, nível)
VAR        s_fSensor : F_TRIG;  s_rRel : R_TRIG;  s_tDelay : TON_TIME;
           s_boxLatch : Bool;  s_counting : Bool;
```
> **Mudança vs. esboço:** `+ i_Release` / `- i_StopOnBox` (redundante com `i_HasSensor`);
> `+ s_rRel`/`s_counting`; `TON` → `TON_TIME`. Box-stop: borda de descida do sensor + delay
> (sustentado por `s_counting`) seta `s_boxLatch`; release (borda de subida) limpa (ordem:
> clear ANTES do set, p/ re-arm no mesmo scan). M2 (`i_HasSensor=FALSE`) nunca latcha.
> **Premissa (§9.2 / §7-risco 7):** o re-arm depende de uma nova borda de descida do sensor;
> se a 2ª caixa já estiver parada SOBRE o sensor no release, não re-latcha — validar no PLCSIM
> que o espaçamento das caixas garante o sensor livre no release, e que `o_ReleaseM1` segura
> nível durante todo o passo 5.

### 2.10 FB `FB_PickPlaceSeq`  (IMPLEMENTADO — interface por io_Station IN_OUT)
```
VAR_INPUT  i_Run : Bool;            // RODANDO (FB_MachineMode.o_Run)
           i_SafeState : Bool;      // estado seguro (FB_MachineMode.o_SafeState)
           i_Reset : Bool;          // NO — pulso de reset (Cmd.Reset)
           i_EStop : Bool;          // NF — E-Stop rearmado (Cmd.EStop) — gate do CLEAR do latch
VAR_OUTPUT o_RotCW,o_RotCCW : Bool; // -> FC_IoMapOutputs
           o_ReleaseM1 : Bool;      // -> Conveyor M1 (passo 5, nível)
           o_PauseM2 : Bool;        // -> Conveyor M2 (passos 9..13, nível)
           o_Fault : Bool;          // -> FB_MachineMode.i_SeqFault (NÍVEL latcheado)
           o_FaultCode : Int;       // congela no 1º código (1..5)
           o_CycleDone : Bool;      // pulso 1 scan (passo 16)
VAR_IN_OUT io_Station : "typeStation";   // lê Cfg/Sts, escreve Sts (SP/InPos/VacuumOn/Step/Fault/CycleCount)
VAR        s_State : Int;           // 0=IDLE, 1..16 passos, 99=FALHA
           s_AxisX,s_AxisZ : "FB_AxisPos";    // multi-instância (chamados todo scan, após o CASE)
           s_RotCW,s_RotCCW : "FB_Rotate180";
           s_tStep : TON_TIME;      // timeout de passo (Cfg.SeqStepTimeout)
           s_Fault : Bool;  s_FaultCode : Int;  s_rReset : R_TRIG;
           s_xEnable,s_zEnable : Bool;  s_xTarget,s_zTarget : LReal;
           s_trigCW,s_trigCCW,s_grab : Bool;  s_PrevState : Int;  s_stepIsMove : Bool;
```
> **Mudanças vs. esboço:** interface por **`io_Station` IN_OUT** (não ~30 escalares); `s_tStep :
> TON_TIME`; `s_State=99` p/ FALHA; intermediários (`s_xEnable/.../s_grab`) separam "decisão por
> passo" da "chamada incondicional". **Latch de falha ÚNICO aqui** (`o_Fault` nível; CLEAR =
> `s_rReset.Q AND i_EStop` — rearme físico do E-Stop, NÃO `NOT i_SafeState`, que causaria
> deadlock). **`s_stepIsMove` no topo de cada passo de movimento** (fora da guarda) p/ o timeout
> cobrir a espera. **R1 anti-esmagamento:** passo 2 captura `Sts.AxisZ.PV` no `ItemDetected`.
> **Vácuo na FALHA/safe:** decisão (i) — soltar a peça (FC mascara `Grab`; FSM zera `s_grab` no
> estado seguro p/ coerência). *(Alternativa (ii) "segurar a peça" = não mascarar Grab no FC.)*

---

## 3. Máquinas de estado

### 3.1 `FB_MachineMode` (modo de operação)

Estados: **EMERGÊNCIA (2)**, **FALHA (3)**, **PARADO (0)**, **RODANDO (1)** — avaliados por
prioridade (segurança vence no scan).

| De → Para | Condição |
|---|---|
| qualquer → EMERGÊNCIA | `i_EStop = FALSE` (NF) → latch `s_Latched := TRUE` |
| EMERGÊNCIA → PARADO | `i_EStop = TRUE` (rearmada) **E** borda de `i_Reset` |
| qualquer (exceto EMERG) → FALHA | `i_SeqFault = TRUE` (nível — latch único em `FB_PickPlaceSeq.o_Fault`) |
| FALHA → PARADO | `i_SeqFault = FALSE` (sequência limpou `o_Fault` após reset); MachineMode não latcheia falha |
| qualquer → PARADO | `i_Stop = FALSE` (NF) — sem latch, exige novo Start |
| PARADO → RODANDO | borda de `i_Start` **E** `i_EStop = TRUE` **E** sem latch falha/emergência |
| RODANDO → PARADO | `i_Stop = FALSE` |

Energização: inicia em **PARADO** sem latch; se `i_EStop = FALSE` na partida, cai em
EMERGÊNCIA na hora (fail-safe).

Saídas / sinalização:
- RODANDO: `o_Run:=TRUE`, `o_Green` fixo, `o_StartLite` aceso. `o_SafeState:=FALSE`.
- PARADO: `o_Run:=FALSE`, `o_Yellow := i_ClkSlow`, `o_StopLite` aceso. `o_SafeState:=TRUE`.
- EMERGÊNCIA: `o_Run:=FALSE`, `o_Red := i_ClkFast`. `o_SafeState:=TRUE`.
- FALHA: como PARADO + `o_Yellow := i_ClkSlow` (vermelho fixo a definir). `o_SafeState:=TRUE`.
- `o_ResetLite := (s_Latched OR i_SeqFault) AND i_ClkSlow` — pisca enquanto há emergência
  latcheada OU falha de nível ativa; apaga após reset.

### 3.2 `FB_PickPlaceSeq` (ciclo do robô — passos 1–16)

Gate de início: `i_Run AND i_Enabled AND i_BoxAtPick AND NOT i_SafeState`. Anticolisão
checada a cada transição de movimento. Timeout `s_tStep` em cada passo de movimento → FALHA.

| Passo | Ação (saídas) | Pré-condição (anticolisão) | Avança quando |
|---|---|---|---|
| 0 IDLE | aguarda gate | — | `i_BoxAtPick` |
| 1 | `AxisX.SP := X_pick` | Z em `Z_up` | `AxisX.InPos` |
| 2 | `AxisZ.SP := Z_pickLimit` (desce); `s_zDescending:=TRUE` | X em `X_pick` & InPos | `i_ItemDetected` **ou** Z no limite (→ FALHA 4) |
| 3 | congela Z (SP := Zpv atual); `o_Grab:=TRUE` | — | vácuo ligado (1 scan) |
| 4 | `AxisZ.SP := Z_up` (sobe) | — | `AxisZ.InPos` |
| 5 | `o_ReleaseM1:=TRUE` (religa M1) | — | imediato |
| 6 | `AxisX.SP := X_home` | Z em `Z_up` | `AxisX.InPos` |
| 7 | `RotCW.Trig` (180° CW) | Z `Z_up` & X `X_home` & NOT `i_Rotating` | `RotCW.Done` |
| 8 | `AxisX.SP := X_place` | Z em `Z_up` & NOT Rotating | `AxisX.InPos` |
| 9 | `o_PauseM2:=TRUE` (pausa M2) | — | imediato |
| 10 | `AxisZ.SP := Z_place` (desce) | X em `X_place` & InPos | `AxisZ.InPos` |
| 11 | `o_Grab:=FALSE` (solta) | Z em `Z_place` | `NOT i_ItemDetected` (caixa liberada) |
| 12 | `AxisZ.SP := Z_up` (sobe) | — | `AxisZ.InPos` |
| 13 | `o_PauseM2:=FALSE` (religa M2) | — | imediato |
| 14 | `AxisX.SP := X_home` | Z em `Z_up` | `AxisX.InPos` |
| 15 | `RotCCW.Trig` (180° CCW) | Z `Z_up` & X `X_home` & NOT Rotating | `RotCCW.Done` |
| 16 | `o_CycleDone` pulso; `CycleCount++` | — | volta a IDLE |

Em `i_SafeState` (E-Stop/Stop/Falha): **reset para passo 0** (não retoma no meio — §7.4);
saídas de processo já zeradas pela máscara. Reinício só com novo gate.

### 3.3 `FB_Rotate180` (sub-máquina — IMPLEMENTADO)
FSM de 4 estados com handshake por nível e contagem de 2×90°:
`0 IDLE → (trig, NOT i_Rotating) 1 PULSE (segura pulso até Rotating subir) → 2 MOVING (pulso
solto; espera NOT i_Rotating = 90° feito; s_Count++) → (s_Count<2: volta a 1; =2: vai a 3) →
3 DONE (o_Done segura até i_Trig cair, handshake)`. `i_SafeState` (antes do CASE) → state 0,
pulsos OFF no mesmo scan. `o_Busy` em 1–2. `ELSE` → 0 (estado inválido seguro).
Detecção por **nível gated por estado** (sem F_TRIG global) — evita corrida/contagem espúria.

---

## 4. Ordem de execução no `OB_Main`

```
1. FC_IoMapInputs    — %I/%ID → StationData.Cmd/.Sts (espelha feedbacks)
2. byte de clock     — lê %M0.5 (lento) e %M0.2 (rápido) em t_clkSlow/t_clkFast (sem FB)
3. FB_MachineMode    — modo + latch + sinalização; produz o_Run e o_SafeState
4. FB_Conveyor (M1)  — sensor+delay → BoxAtPick; respeita o_Run e SafeState
5. FB_Conveyor (M2)  — RODANDO + ForcePause (passos 9..13); SafeState
6. FB_PickPlaceSeq   — passos 1–16; multi-instancia AxisX/Z e Rotate CW/CCW
7. FC_IoMapOutputs   — StationData → %Q/%QD; máscara SafeState (zera M1/M2/Grab/Rotate)
```

**Propagação do E-Stop (dupla barreira):**
- `FB_MachineMode` calcula `o_SafeState` (E-Stop OU Stop OU Falha) e passa a **todos** os FBs
  no mesmo scan (cada um se auto-protege).
- `FC_IoMapOutputs` é a **última linha**: a máscara força `M1:=0, M2:=0, Grab:=FALSE,
  RotCW/CCW:=FALSE` antes do periférico. Setpoints de eixo não recebem novo destino.

---

## 5. Intertravamentos e modos de falha (§7 do escopo) — onde cada um vive

| Regra (§7) | Bloco responsável | Mecanismo |
|---|---|---|
| 7.1 E-Stop sobrepõe tudo, latch | `FB_MachineMode` + `FC_IoMapOutputs` | latch `s_Latched`; máscara dupla |
| 7.1 Stop → PARADO (sem latch) | `FB_MachineMode` | transição, exige novo Start |
| 7.1 Fio rompido NF = fail-safe | mapeamento + lógica NF | `EStop/Stop FALSE` = acionado |
| 7.1 Start inibido em EMERG/FALHA | `FB_MachineMode` | guarda na transição PARADO→RODANDO |
| 7.2 Rotate CW ⊻ CCW | `FB_Rotate180` + `FC_IoMapOutputs` | só um pulso ativo; máscara garante |
| 7.2 Gripper sempre FALSE | `FC_IoMapOutputs` | `o_GripCW/CCW := FALSE` |
| 7.2 M1/M2 só >0 em RODANDO | `FB_Conveyor` (`i_Run`) + máscara | velocidade 0 se NOT Run |
| 7.3 Rotacionar só com Z up & X home | `FB_PickPlaceSeq` | pré-condição passos 7 e 15 |
| 7.3 Mover X só com Z up | `FB_PickPlaceSeq` | pré-condição passos 1,6,8,14 |
| 7.3 Não comandar eixo durante Rotating | `FB_PickPlaceSeq` | guarda `NOT i_Rotating` |
| 7.3 Descer Z só com X em posição | `FB_PickPlaceSeq` | passos 2 e 10 exigem `AxisX.InPos` |
| 7.4 Handshake início | `FB_PickPlaceSeq` (gate) | `i_Run AND i_Enabled AND i_BoxAtPick` |
| 7.4 Avanço passo a passo | `FB_PickPlaceSeq` (CASE) | sem GOTO; cada passo confirma |
| 7.4 Reinício no passo inicial | `FB_PickPlaceSeq` | `i_SafeState` → `s_State:=0` |
| 7.5 Vácuo: liga em ItemDetected, solta só em Z_place | `FB_PickPlaceSeq` | passo 3 liga; passo 11 só após `AxisZ.InPos@Z_place` |
| 7.5 M1 para no sensor, religa passo 5 | `FB_Conveyor` (M1) + `o_ReleaseM1` | F_TRIG+TON; latch até release |
| 7.5 M2 pausa no depósito | `o_PauseM2` → `FB_Conveyor` (M2) | `i_ForcePause` passos 9–13 |

**Modos de falha (→ FALHA, FaultCode):** timeout de posição X (1) / Z (2) / rotação (3) / Z
atingiu limite na pega sem `ItemDetected` (4) / caixa não liberada após soltar (5). Todos por
`s_tStep` (TON com `Cfg.SeqStepTimeout`). Recuperação só por Reset (borda) → PARADO + passo 0.

---

## 6. Mapeamento de I/O

A HMI escreve no DB (`StationData.Cmd/Cfg`) e lê `Sts`. O endereçamento físico fica isolado
nos dois FCs, chamados só pelo `OB_Main`:

**Entrada (`FC_IoMapInputs`, início do scan):**
- `%I0.3 EStop → Cmd.EStop` · `%I0.7 Stop → Cmd.Stop` · `%I0.6 Start → Cmd.Start` ·
  `%I0.4 Reset → Cmd.Reset` · `%I0.5 Sensor_caixa → Sts.SensorBox` (campo novo; M1 lê do DB) ·
  `%I1.0 Rotating → Sts.Rotating` · `%I1.1 ItemDetected → Sts.ItemDetected`.
- `%ID30 X Position → Sts.AxisX.PV` · `%ID34 Z Position → Sts.AxisZ.PV`.

**Saída (`FC_IoMapOutputs`, fim do scan, com máscara SafeState):**
- `%Q0.3 ResetLite` · `%Q0.4 Red` · `%Q0.5 Green` · `%Q0.6 Yellow` · `%Q0.7 StartLite` ·
  `%Q1.0 StopLite` (de `FB_MachineMode`).
- `%Q1.1 Grab` · `%Q1.2 RotCW` · `%Q1.4 RotCCW` (de `FB_PickPlaceSeq`) ·
  `%Q1.3/%Q1.5 Gripper := FALSE`.
- `%QD30 M1` · `%QD34 M2` (de `FB_Conveyor`) · `%QD38 X SetPoint` · `%QD42 Z SetPoint`
  (de `FB_AxisPos`).

> Tags de PLC e DBs de instância (`FB_PickPlaceSeq_DB`, etc.) são criados **no TIA Portal** a
> partir do XML do FACTORY I/O e dos FBs — não viram arquivo `.scl` no repo.

---

## 7. Riscos / decisões em aberto

1. **Calibração no PLCSIM (§9.2):** X_home, Z_place, Z_pickLimit, tolerância, velocidade das
   esteiras, delays e pisca são **start values no `Cfg`** — ajustáveis sem recompilar. Risco
   baixo por design.
2. **Largura mínima do pulso de rotação:** se 1 scan não registrar, `FB_Rotate180` usa
   `s_tPulse` (TON) calibrável. Já previsto.
3. **Polaridade NC/NO real:** confirmada na doc; validar empiricamente. Se invertida, só muda
   a leitura em `FC_IoMapInputs` (ponto único).
4. **`Item Detected` no passo 11 (soltar):** usa `NOT ItemDetected` como confirmação; se o
   sensor não cair para FALSE ao soltar, usar timeout como fallback (FaultCode 5).
5. **Anti-esmagamento vs. timeout no passo 2:** parar em **ambos** (limite `Z_pickLimit` OU
   timeout) — nunca passar do limite.
6. **Congelar Z na pega (passo 3):** `FB_AxisPos` segura o último SP; validar no sim se não há
   drift.
7. **Pipeline M1:** religar M1 no passo 5 pode trazer a próxima caixa antes do fim do ciclo;
   `BoxAtPick` só rearma quando a sequência volta a IDLE. Confirmar ausência de corrida.
8. **Clock:** adotado o **byte de clock da CPU** (MB0: `%M0.5`/`%M0.2`), lido no `OB_Main`.
   Pré-requisito: habilitar o clock memory byte na config da CPU. O padrão TON auto-rearmado
   em SCL otimizado **não** oscila (recálculo de `.Q` por acesso) — por isso sem FB.

---

## 8. Ordem de implementação (dependências → `/new-block`)

1. UDT `typeAxis` e UDT `typeStation` (base — nada compila sem o tipo).
2. DB `StationData` (instancia o UDT).
3. FC `FC_ScaleVolt` (puro) e FC_IoMap* (dependem do UDT).
4. (pisca da torre: habilitar o clock byte MB0 na config da CPU — sem bloco a implementar).
5. FB `FB_AxisPos` (primitiva; usa FC_ScaleVolt opcional).
6. FB `FB_Rotate180` (primitiva, independente).
7. FB `FB_Conveyor` (primitiva).
8. FB `FB_MachineMode` (usa o byte de clock p/ sinalização, via OB_Main).
9. FB `FB_PickPlaceSeq` (multi-instancia AxisPos × Rotate180; topo da lógica).
10. OB `OB_Main` (amarra tudo na ordem da §4).

Validar cada bloco no linter SCL (MCP) e sincronizar `DOCS/tags.md` ao fechar cada interface.
