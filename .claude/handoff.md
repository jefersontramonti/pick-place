# Handoff: OB_Main (OB1) — orquestrador final (bloco 13/13)

**Decisão de arquitetura:** OB1 cíclico. Orquestra o scan da estação na ordem da §4:
`FC_IoMapInputs → FB_ClockGen → FB_MachineMode → FB_Conveyor(M1) → FB_Conveyor(M2) →
FB_PickPlaceSeq → FC_IoMapOutputs`. **NÃO contém lógica de processo** — só roteia I/O (tags
físicas reais do TIA) e encadeia os FCs/FBs, propagando `o_SafeState` a todos no mesmo scan.
Fonte: `ARQUITETURA_PickPlace.md` §4 + plano do `scl-architect`.

## Resolução das 3 realimentações (produtor roda DEPOIS do consumidor)
Usar valores **persistidos** (latência de 1 scan — inócua: os 3 são níveis sustentados, nunca
pulsos): `i_SeqFault := "StationData".Station.Sts.Fault`; conveyors leem
`"FB_PickPlaceSeq_DB".o_ReleaseM1` / `.o_PauseM2` (VAR_OUTPUT retido no DB de instância). **Não**
adicionar campos ao `typeStation`. **Não** usar VAR_TEMP para essas 3 entradas (TEMP nasce
indefinido a cada scan e quebraria o feedback).

## Estrutura + VAR_TEMP (só sinais consumidos no MESMO scan)
```
ORGANIZATION_BLOCK "OB_Main"
{ S7_Optimized_Access := 'TRUE' }
VERSION : 0.1
VAR_TEMP
   t_clkSlow, t_clkFast : Bool;                 // FB_ClockGen -> MachineMode
   t_run, t_safeState : Bool;                   // FB_MachineMode -> conveyors/seq/FC
   t_mode : Int;
   t_red, t_green, t_yellow, t_startLite, t_stopLite, t_resetLite : Bool;  // MachineMode -> FC
   t_rotCW, t_rotCCW : Bool;                     // FB_PickPlaceSeq -> FC
   t_m1Speed, t_m2Speed : LReal;                // FB_Conveyor -> DB
   t_boxM1, t_boxM2 : Bool;                      // o_BoxArrived (M2 descartado)
END_VAR
```

## Sequência de chamadas (corpo do OB) — usar as tags reais COM ASPAS
```
// 1) Entradas físicas -> DB (cópia crua NF)
"FC_IoMapInputs"(i_EStop:="Emergency Stop 0", i_Stop:="Stop Button 0",
   i_Start:="Start Button 0", i_Reset:="Reset Button 0", i_SensorBox:="Sensor_caixa",
   i_Rotating:="Two-Axis Pick & Place 0 (Rotating)",
   i_ItemDetected:="Two-Axis Pick & Place 0 (Item Detected)",
   i_Xpos:="Two-Axis Pick & Place 0 X Position (V)",
   i_Zpos:="Two-Axis Pick & Place 0 Z Position (V)",
   io_Station:="StationData".Station);

// 2) Clocks de pisca
"FB_ClockGen_DB"(i_SlowHz:="StationData".Station.Cfg.ClkSlowHz,
   i_FastHz:="StationData".Station.Cfg.ClkFastHz, o_Slow=>#t_clkSlow, o_Fast=>#t_clkFast);

// 3) Modo + sinalização + SafeState (i_SeqFault = Sts.Fault do scan anterior)
"FB_MachineMode_DB"(i_Start:="StationData".Station.Cmd.Start,
   i_Stop:="StationData".Station.Cmd.Stop, i_EStop:="StationData".Station.Cmd.EStop,
   i_Reset:="StationData".Station.Cmd.Reset, i_SeqFault:="StationData".Station.Sts.Fault,
   i_ClkSlow:=#t_clkSlow, i_ClkFast:=#t_clkFast,
   o_Mode=>#t_mode, o_Run=>#t_run, o_SafeState=>#t_safeState,
   o_Red=>#t_red, o_Green=>#t_green, o_Yellow=>#t_yellow,
   o_StartLite=>#t_startLite, o_StopLite=>#t_stopLite, o_ResetLite=>#t_resetLite);
"StationData".Station.Sts.Mode := #t_mode;   // espelho p/ HMI

// 4) Esteira M1 (com sensor); i_Release do DB de instância da sequência (scan anterior)
"FB_Conveyor_M1_DB"(i_Run:=#t_run, i_SafeState:=#t_safeState,
   i_Speed:="StationData".Station.Cfg.ConvSpeed, i_HasSensor:=TRUE,
   i_Sensor:="StationData".Station.Sts.SensorBox,
   i_StopDelay:="StationData".Station.Cfg.M1StopDelay, i_ForcePause:=FALSE,
   i_Release:="FB_PickPlaceSeq_DB".o_ReleaseM1,
   o_Speed=>#t_m1Speed, o_BoxArrived=>#t_boxM1);
"StationData".Station.Sts.M1Speed   := #t_m1Speed;
"StationData".Station.Sts.BoxAtPick := #t_boxM1;

// 5) Esteira M2 (sem sensor); i_ForcePause do DB de instância da sequência
"FB_Conveyor_M2_DB"(i_Run:=#t_run, i_SafeState:=#t_safeState,
   i_Speed:="StationData".Station.Cfg.ConvSpeed, i_HasSensor:=FALSE, i_Sensor:=FALSE,
   i_StopDelay:=T#0ms, i_ForcePause:="FB_PickPlaceSeq_DB".o_PauseM2, i_Release:=FALSE,
   o_Speed=>#t_m2Speed, o_BoxArrived=>#t_boxM2);
"StationData".Station.Sts.M2Speed := #t_m2Speed;

// 6) Sequência (escreve Sts.* via io_Station; só capturamos RotCW/CCW p/ o FC)
"FB_PickPlaceSeq_DB"(i_Run:=#t_run, i_SafeState:=#t_safeState,
   i_Reset:="StationData".Station.Cmd.Reset, i_EStop:="StationData".Station.Cmd.EStop,
   o_RotCW=>#t_rotCW, o_RotCCW=>#t_rotCCW, io_Station:="StationData".Station);

// 7) DB -> saídas físicas, com máscara de estado seguro
"FC_IoMapOutputs"(i_SafeState:=#t_safeState, i_Red:=#t_red, i_Green:=#t_green,
   i_Yellow:=#t_yellow, i_ResetLite:=#t_resetLite, i_StartLite:=#t_startLite,
   i_StopLite:=#t_stopLite, i_RotCW:=#t_rotCW, i_RotCCW:=#t_rotCCW,
   io_Station:="StationData".Station,
   o_ResetLite=>"Reset Button 0 (Light)", o_Red=>"Stack Light 0 (Red)",
   o_Green=>"Stack Light 0 (Green)", o_Yellow=>"Stack Light 0 (Yellow)",
   o_StartLite=>"Start Button 0 (Light)", o_StopLite=>"Stop Button 0 (Light)",
   o_Grab=>"Two-Axis Pick & Place 0 (Grab)",
   o_RotCW=>"Two-Axis Pick & Place 0 Rotate CW",
   o_GripCW=>"Two-Axis Pick & Place 0 Gripper CW",
   o_RotCCW=>"Two-Axis Pick & Place 0 Rotate CCW",
   o_GripCCW=>"Two-Axis Pick & Place 0 Gripper CCW",
   o_M1=>"M1", o_M2=>"M2",
   o_Xsp=>"Two-Axis Pick & Place 0 X Set Point (V)",
   o_Zsp=>"Two-Axis Pick & Place 0 Z Set Point (V)");
```
Regras: comentários PT, REGION (uma por etapa, opcional), `{ S7_Optimized_Access := 'TRUE' }`.
Arquivo: `OBs/OB_Main.scl`. Conferir os **parâmetros formais** contra as interfaces reais dos
FBs/FCs (nomes/tipos exatos). Pode atribuir a tag física diretamente ao `o_*` na chamada do FC
de saída (válido em SCL).

**⚠️ CAVEAT DE VALIDAÇÃO (esperado):** o linter MCP vai acusar como **não-declarados** as 24
tags físicas (`"Emergency Stop 0"`, `"M1"`, …) e os 5 DBs de instância (`"FB_ClockGen_DB"`,
`"FB_MachineMode_DB"`, `"FB_Conveyor_M1_DB"`, `"FB_Conveyor_M2_DB"`, `"FB_PickPlaceSeq_DB"`) —
eles só existem no projeto TIA, não como `.scl`. **Isso é OK.** O que importa validar: sintaxe
do OB, nomes/tipos dos **parâmetros formais** dos FBs/FCs e os acessos a `"StationData".Station.*`.
Qualquer erro FORA dessas 24 tags + 5 DBs é real e deve ser corrigido. Reporte exatamente quais
símbolos o linter acusou.

**Restrições de safety (safety-auditor valida):** ordem de chamada correta (SafeState propagado
a todos no mesmo scan); E-Stop/Stop crus do `Cmd.*` (NF tratado no MachineMode); `i_SafeState`
chega a Conveyors/PickPlaceSeq/FC_IoMapOutputs; máscara de saída por último. Latência de 1 scan
nos 3 feedbacks (níveis) não compromete o estado seguro (a máscara do FC e o `i_SafeState` agem
no mesmo scan).

**Tags I/O reservadas (tag-io-documenter):** confirmar que TODAS as 24 tags da §2/§4/§5 do
`tags.md` estão ligadas (entradas no FC_IoMapInputs; saídas no FC_IoMapOutputs) — nenhuma órfã,
nenhuma faltando.

**Pendências TIA (não viram `.scl`):** criar a tag table (24 tags, endereços da §6 do tags.md;
`%ID/%QD` = Real); criar os 5 DBs de instância com os nomes exatos acima; atribuir `OB_Main` ao
OB1; conferir `Cfg.Enabled` e start values de calibração.