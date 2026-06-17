# Handoff: FB_PickPlaceSeq (FB com estado — topo da lógica, FSM do ciclo 1–16)

**Decisão de arquitetura:** máquina de estados do ciclo Pick & Place. Multi-instancia
`FB_AxisPos`×2 (X,Z) e `FB_Rotate180`×2 (CW,CCW), aplica anticolisão (§7.3), vácuo, religa M1
(passo 5) e pausa M2 (9–13), e é a **fonte única do latch de falha** (`o_Fault` NÍVEL +
`o_FaultCode` congelado, clear no próprio reset). Interface por **`io_Station` IN_OUT**. Fonte:
`ARQUITETURA_PickPlace.md` §2.10/§3.2 + plano do `scl-architect`.

## Decisões-chave
- **`io_Station : typeStation` (IN_OUT):** o FB lê `Cfg.*`/`Sts.*` e ESCREVE `Sts.*` direto no
  DB (sem fiação no OB). Escalares só p/ `i_Run`, `i_SafeState`, `i_Reset` (de outros FBs) e as
  saídas que vão p/ outros FBs.
- **Sub-FBs chamados TODO scan, INCONDICIONALMENTE, DEPOIS do CASE.** O CASE NÃO chama os
  sub-FBs — só decide variáveis intermediárias (`s_xEnable/s_zEnable/s_xTarget/s_zTarget/
  s_trigCW/s_trigCCW/s_grab`). Ordem: CASE decide → chama sub-FBs → espelha status.
- **R1 anti-esmagamento:** no passo 2, ao acionar `Sts.ItemDetected`, **capturar o PV atual**
  (`s_zTarget := io_Station.Sts.AxisZ.PV`) e ir ao passo 3 — congela o Z no ponto de contato
  (NÃO usar `i_Enable:=FALSE`, que seguraria o SP do limite e amassaria a caixa).
- **Latch de falha único:** `s_Fault`/`s_FaultCode` (nível), congela o 1º código, CLEAR só no
  próprio reset (`i_Reset`↑ E `NOT i_SafeState`), **clear-antes-do-set**, `s_State:=99` em FALHA.

## Interface
```
FUNCTION_BLOCK "FB_PickPlaceSeq"
{ S7_Optimized_Access := 'TRUE' }
VERSION : 0.1
VAR_INPUT
   i_Run       : Bool;   // RODANDO (FB_MachineMode.o_Run)
   i_SafeState : Bool;   // estado seguro (FB_MachineMode.o_SafeState)
   i_Reset     : Bool;   // NO — pulso de reset (Cmd.Reset); borda limpa o latch
   i_EStop     : Bool;   // NF — E-Stop físico rearmado (Cmd.EStop); gate do CLEAR do latch
END_VAR
VAR_OUTPUT
   o_RotCW     : Bool;   // -> FC_IoMapOutputs.i_RotCW
   o_RotCCW    : Bool;   // -> FC_IoMapOutputs.i_RotCCW
   o_ReleaseM1 : Bool;   // -> FB_Conveyor M1 (i_Release) — NÍVEL no passo 5
   o_PauseM2   : Bool;   // -> FB_Conveyor M2 (i_ForcePause) — NÍVEL passos 9..13
   o_Fault     : Bool;   // -> FB_MachineMode.i_SeqFault — NÍVEL latcheado
   o_FaultCode : Int;    // congela no 1º código (1..5)
   o_CycleDone : Bool;   // pulso de 1 scan no passo 16
END_VAR
VAR_IN_OUT
   io_Station  : "typeStation";   // referência ao StationData.Station
END_VAR
VAR
   s_State      : Int := 0;    // 0=IDLE, 1..16 passos, 99=FALHA
   s_AxisX      : "FB_AxisPos";
   s_AxisZ      : "FB_AxisPos";
   s_RotCW      : "FB_Rotate180";
   s_RotCCW     : "FB_Rotate180";
   s_tStep      : TON_TIME;    // timeout de passo (PT := Cfg.SeqStepTimeout)
   s_Fault      : Bool;
   s_FaultCode  : Int;
   s_rReset     : R_TRIG;
   s_xEnable    : Bool;
   s_zEnable    : Bool;
   s_xTarget    : LReal;
   s_zTarget    : LReal;
   s_trigCW     : Bool;
   s_trigCCW    : Bool;
   s_grab       : Bool;        // nível do vácuo (liga passo 3, desliga passo 11)
   s_PrevState  : Int;         // passo do scan anterior (re-arma o timeout)
   s_stepIsMove : Bool;        // passo atual é de movimento (habilita timeout)
END_VAR
VAR_TEMP
   t_stepChanged : Bool;
END_VAR
```

## Ordem das REGIONs (CRÍTICA)
```
1. REGION Bordas            -> s_rReset(CLK := i_Reset)
2. REGION Reset do latch    -> CLEAR (antes do set): IF s_rReset.Q AND NOT i_SafeState THEN
                               s_Fault:=FALSE; s_FaultCode:=0; s_State:=0; END_IF
3. REGION Reset a IDLE      -> IF i_SafeState OR NOT i_Run THEN s_State:=0; s_grab:=FALSE; END_IF
                               (não toca o latch; s_grab:=FALSE p/ coerência com a máscara do FC — peça solta no safe)
4. REGION Defaults do scan  -> zera (todo scan) s_xEnable/s_zEnable/s_trigCW/s_trigCCW/
                               o_ReleaseM1/o_PauseM2/o_CycleDone/s_stepIsMove.
                               NÃO zerar s_grab, s_xTarget, s_zTarget (persistem).
5. REGION FSM (CASE s_State)-> decide intermediários + transições + SET de falha (4/5)
6. REGION Timeout de passo  -> re-arma s_tStep na troca de passo; estouro -> SET falha (1/2/3)
7. REGION Chamada sub-FBs   -> s_AxisX/Z e s_RotCW/CCW INCONDICIONALMENTE
8. REGION Espelha status    -> escreve Sts.* e saídas de processo
```

## FSM (CASE) — cada passo seta intermediários; guarda de anticolisão ANTES de habilitar
Helpers de posição: **"Z em Z_up"** = `Sts.AxisZ.InPos AND ABS(Sts.AxisZ.PV - Cfg.Z_up) <= Cfg.PosTol`;
**"X em X_home/place"** análogo. (Não basta `InPos` genérico — confirmar destino.)

| Passo | Ação (intermediários/saídas) | Anticolisão (guarda) | Avança quando |
|---|---|---|---|
| 0 IDLE | tudo OFF; `s_grab:=F` | — | `i_Run AND Cfg.Enabled AND Sts.BoxAtPick AND NOT i_SafeState AND NOT s_Fault` → 1 |
| 1 | `s_xEnable:=T; s_xTarget:=Cfg.X_pick`; move(T) | Z em Z_up | `Sts.AxisX.InPos` → 2 |
| 2 | `s_zEnable:=T; s_zTarget:=Cfg.Z_pickLimit`; `s_xEnable:=T; s_xTarget:=Cfg.X_pick`; move(T) | X em X_pick | **`Sts.ItemDetected`** → `s_zTarget:=Sts.AxisZ.PV` (captura) → 3 · OU Z em Z_pickLimit (`AxisZ.InPos`) → **FALHA 4** |
| 3 | `s_zEnable:=T` (segura o SP capturado); `s_grab:=T`; `s_xEnable:=T; s_xTarget:=Cfg.X_pick` | — | (1 scan) → 4 |
| 4 | `s_zEnable:=T; s_zTarget:=Cfg.Z_up`; `s_grab:=T`; move(T) | — | `Sts.AxisZ.InPos`(Z_up) → 5 |
| 5 | `o_ReleaseM1:=T`; `s_grab:=T`; eixos congelados (enable=F) | — | (1 scan) → 6 |
| 6 | `s_xEnable:=T; s_xTarget:=Cfg.X_home`; `s_grab:=T`; move(T) | Z em Z_up | `Sts.AxisX.InPos`(X_home) → 7 |
| 7 | `s_trigCW:=T`; `s_grab:=T`; eixos congelados; move(T) | Z em Z_up & X em X_home & `NOT Sts.Rotating` | `s_RotCW.o_Done` → 8 |
| 8 | `s_xEnable:=T; s_xTarget:=Cfg.X_place`; `s_grab:=T`; move(T) | Z em Z_up & `NOT Sts.Rotating` | `Sts.AxisX.InPos`(X_place) → 9 |
| 9 | `o_PauseM2:=T`; `s_grab:=T`; `s_xEnable:=T; s_xTarget:=Cfg.X_place` | — | (1 scan) → 10 |
| 10 | `s_zEnable:=T; s_zTarget:=Cfg.Z_place`; `o_PauseM2:=T`; `s_grab:=T`; move(T) | X em X_place | `Sts.AxisZ.InPos`(Z_place) → 11 |
| 11 | `s_grab:=F`; `o_PauseM2:=T`; Z congelado (enable=T, target=Z_place); move(T) | Z em Z_place | `NOT Sts.ItemDetected` → 12 · OU timeout → **FALHA 5** |
| 12 | `s_zEnable:=T; s_zTarget:=Cfg.Z_up`; `o_PauseM2:=T`; move(T) | — | `Sts.AxisZ.InPos`(Z_up) → 13 |
| 13 | `o_PauseM2:=F`; eixos congelados | — | (1 scan) → 14 |
| 14 | `s_xEnable:=T; s_xTarget:=Cfg.X_home`; move(T) | Z em Z_up | `Sts.AxisX.InPos`(X_home) → 15 |
| 15 | `s_trigCCW:=T`; eixos congelados; move(T) | Z em Z_up & X em X_home & `NOT Sts.Rotating` | `s_RotCCW.o_Done` → 16 |
| 16 | `s_trigCCW:=F`; `o_CycleDone:=T`; `Sts.CycleCount := Sts.CycleCount + 1` | — | sempre → 0 |
| 99 FALHA | tudo OFF; `s_Fault` mantido | — | só por reset (REGION 2) → 0 |

> **`move(T)`** = passo de movimento → setar `s_stepIsMove := TRUE` **no TOPO do passo (FORA da
> guarda de anticolisão)**, para o timeout cobrir também a espera da guarda (senão trava
> silenciosa sem FALHA). O comando do eixo (`s_xEnable`/`s_zEnable`/trigs) permanece DENTRO da
> guarda. Passos
> 0,3,5,9,13,16 NÃO são de movimento (sem timeout). Mapa do código de timeout: passos 1,6,8,14→1;
> 2,4,10,12→2; 7,15→3; 11→5.
>
> **Guarda de anticolisão:** se a guarda do passo NÃO for satisfeita, **não habilitar o
> movimento** (manter o eixo congelado, enable=F) e **não avançar** — fica esperando (o timeout
> protege contra travamento). Mais seguro que avançar e colidir.

## Chamada dos sub-FBs (REGION 7 — incondicional, todo scan)
```
#s_AxisX(i_Enable := #s_xEnable, i_SafeState := #i_SafeState, i_SetPoint := #s_xTarget,
         i_PV := #io_Station.Sts.AxisX.PV, i_Tol := #io_Station.Cfg.PosTol,
         i_Debounce := #io_Station.Cfg.PosDebounce);
#s_AxisZ(i_Enable := #s_zEnable, i_SafeState := #i_SafeState, i_SetPoint := #s_zTarget,
         i_PV := #io_Station.Sts.AxisZ.PV, i_Tol := #io_Station.Cfg.PosTol,
         i_Debounce := #io_Station.Cfg.PosDebounce);
#s_RotCW (i_Trig := #s_trigCW,  i_Dir := TRUE,  i_Rotating := #io_Station.Sts.Rotating, i_SafeState := #i_SafeState);
#s_RotCCW(i_Trig := #s_trigCCW, i_Dir := FALSE, i_Rotating := #io_Station.Sts.Rotating, i_SafeState := #i_SafeState);
```

## Espelho de status (REGION 8 — após as chamadas)
```
#io_Station.Sts.AxisX.SP := #s_AxisX.o_SetPointCmd;  #io_Station.Sts.AxisX.InPos := #s_AxisX.o_InPos;
#io_Station.Sts.AxisZ.SP := #s_AxisZ.o_SetPointCmd;  #io_Station.Sts.AxisZ.InPos := #s_AxisZ.o_InPos;
#io_Station.Sts.VacuumOn := #s_grab;
#io_Station.Sts.Step := #s_State;  #io_Station.Sts.Fault := #s_Fault;  #io_Station.Sts.FaultCode := #s_FaultCode;
#o_RotCW := #s_RotCW.o_PulseCW;  #o_RotCCW := #s_RotCCW.o_PulseCCW;
#o_Fault := #s_Fault;  #o_FaultCode := #s_FaultCode;
```

## Latch de falha (padrões)
- **CLEAR (REGION 2, antes do CASE):** `IF #s_rReset.Q AND #i_EStop THEN s_Fault:=FALSE;
  s_FaultCode:=0; s_State:=0; END_IF`. ⚠️ **Gate por `i_EStop` (rearme físico), NÃO por
  `NOT i_SafeState`** — `i_SafeState` é TRUE durante a falha → deadlock (espelha o `FB_MachineMode`).
- **SET (no CASE e no Timeout):** `IF NOT #s_Fault THEN s_Fault:=TRUE; s_FaultCode:=<código>;
  END_IF; #s_State := 99;` — congela o 1º código.
- **Timeout (REGION 6):** `t_stepChanged := s_State <> s_PrevState; s_PrevState := s_State;
  s_tStep(IN := s_stepIsMove AND NOT t_stepChanged, PT := Cfg.SeqStepTimeout); IF s_tStep.Q THEN
  <SET falha com código do passo>; END_IF`.

Regras: comentários PT, nomes EN, REGION, `CASE` com `ELSE` (→ `s_State:=0` seguro). Arquivo:
`FBs/FB_PickPlaceSeq.scl`. FB de instância única no `OB_Main` — **não** criar chamada agora.

**Restrições de safety (safety-auditor valida — pesado):** anticolisão (rotacionar só Z up+X
home+NOT Rotating; mover X só Z up; descer Z só X em posição); estado seguro (`i_SafeState`/
`NOT i_Run` → IDLE + sub-FBs congelam); vácuo (liga em ItemDetected, solta só em Z_place);
latch de falha único (clear-antes-do-set, congela código, sem auto-rearme); FALHA só sai por
reset deliberado; `CASE` com `ELSE` seguro. Anti-esmagamento (R1: captura PV no contato).

**Tags I/O reservadas:** nenhuma nova (tudo via DB / sub-FBs). Tag-io: **N/A**.

**Casos de teste pendentes (test-sim-engineer):** ciclo completo 1→16; anticolisão (cada guarda);
ItemDetected na descida → captura+vácuo; falta de ItemDetected → FALHA 4; timeout de cada passo
de movimento → FALHA 1/2/3; passo 11 sem liberar → FALHA 5; reset limpa falha (com EStop rearmado);
i_SafeState no meio → IDLE; pipeline (release M1 passo 5).

**Carry-forward (`OB_Main`):** chamar APÓS Conveyor M1/M2 e MachineMode, ANTES do FC_IoMapOutputs.
`i_Run:=MachineMode.o_Run`, `i_SafeState:=MachineMode.o_SafeState`, `i_Reset:=Station.Cmd.Reset`,
`io_Station:="StationData".Station`. `o_Fault→MachineMode.i_SeqFault` (latência 1 scan, ok),
`o_RotCW/CCW→FC_IoMapOutputs`, `o_ReleaseM1→Conveyor M1.i_Release`, `o_PauseM2→Conveyor M2.i_ForcePause`.
**Validar no PLCSIM (R1):** se o modelo persegue o SP congelado vs. para por carga (§9.2).
