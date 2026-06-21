## Handoff: Fase Modo MANUAL + IHM — LÓGICA CONCLUÍDA (2026-06-21)

A lógica `.scl` da fase "Modo MANUAL + IHM SIMATIC" está **implementada, validada (MCP) e revisada**
(scl-reviewer + safety-auditor — **aprovado, sem CRÍTICO/ALTO**). Não há bloco em andamento.

### Entregue nesta fase
- **`FCs/FC_Interlocks.scl`** (NOVO) — fonte única das guardas de anticolisão (Seq + Manual).
- **`UDTs/typeStation.scl`** — `+Cmd.Man{12 bool}` + `Sts.ManActive` + `Sts.ManRejected`.
- **`FBs/FB_MachineMode.scl`** — `+i_AutoMode/i_Step` → `+o_RunAuto/o_RunManual/o_AutoMode`; gate de
  troca de modo só em `Step=0`; MANUAL = verde piscando lento.
- **`FBs/FB_ManualControl.scl`** (NOVO) — jog por posições predefinidas, esteiras jog puro, rotação
  por pulso, vácuo; gate-mestre `t_active`; `Sts.ManRejected` 0..5; homing exige Z up.
- **`OBs/OB_Main.scl`** — mux por modo latcheado (`IF o_AutoMode`), `Sts.ManActive := o_RunManual`.
- **`DOCS/tags.md` §10** — mapa de tags IHM (sem I/O física nova).

### Próximos passos (NÃO são `.scl`)
**No TIA Portal:**
1. Regenerar DBs de instância: **`FB_ManualControl_DB`** (NOVO) e `FB_MachineMode_DB` (interface
   mudou). `FB_PickPlaceSeq_DB` só recompilar.
2. **Reinit `StationData`** (typeStation cresceu — senão start values de `Cfg.*` não propagam).
3. Importar `FC_Interlocks`; recompilar `OB_Main`/`FB_MachineMode`/`FB_ManualControl`.

**No WinCC:** criar device **TP1500 Comfort** + telas + binding simbólico (mapa em `tags.md` §10).

**No PLCSIM (validar antes de liberar):**
1. Bumpless AUTO↔MANUAL — sem salto de SP (confirmar que `FB_AxisPos` com `i_Enable=FALSE` mantém
   `o_SetPointCmd`).
2. Transição AUTO→MANUAL com robô em posição intermediária — `InPos` herdado do DB (mitigado por
   troca só em `Step=0`, mas confirmar).
3. Voltar MANUAL→AUTO — TON congelado dos conveyors não emite pulso residual de `M1Speed`.
4. Cada código de `Sts.ManRejected` (conflitos e intertravamentos); homing manual com/sem Z up.
5. Semântica de `Sts.ManActive` (= "MANUAL e RODANDO") na tela.

### Camada IHM (2026-06-21) — projeto + comando IHM (implementados no PLC)
- **`DOCS/IHM_TP1500_Telas.md`** (NOVO) — projeto das telas WinCC: 6 telas + template + 2 pop-ups,
  navegação, protótipos, alarmes, níveis de acesso, checklist. Telas ainda a fazer no WinCC.
- **IHM comanda Liga/Para/Reset:** `+Cmd.HmiStart/HmiStopReq/HmiReset` no `typeStation`; mescla no
  `FC_IoMapInputs` (`Start/Reset = físico OR HMI`; `Stop = físico AND NOT HmiStopReq`). E-Stop só
  físico. Safety: fail-safe preservado.
- **Decisão C-1 — rearme separado (implementado):** `+Cmd.ResetPhys` (físico cru) → só rearme de
  EMERGÊNCIA no `FB_MachineMode`; `HmiReset` reseta só FALHA. **Partida remota aceita sob C-1.**
- **WinCC a fazer:** device TP1500, telas T01–T06, Alarm Control, grupos de usuário, binding
  (botões `Cmd.Hmi*` = "set bit while key pressed"; **não** bindar `Cmd.Start/Stop/Reset/EStop/
  ResetPhys`). Reinit do `StationData` no TIA já cobre os novos `Cmd.*` (nascem FALSE = seguro).

### Pendências herdadas
C-1 (parada segura real exigiria F-CPU/PROFIsafe/STO — **agravada** pelo jog manual **e pela partida
remota da IHM**; decisão de risco do usuário, registrada), M-1, M-2.
