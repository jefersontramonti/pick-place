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

### Pendências herdadas
C-1 (parada segura real exigiria F-CPU/PROFIsafe/STO — **agravada** pelo jog manual; decisão de
risco do usuário), M-1, M-2.
