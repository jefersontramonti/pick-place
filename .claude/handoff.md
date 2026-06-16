# Handoff: FC_IoMapOutputs (FC pura, última barreira fail-safe)

**Decisão de arquitetura:** FC **stateless** chamada no FIM do scan pelo `OB_Main`. Produz as
saídas físicas (`%Q`/`%QD`) a partir de duas fontes e aplica a **máscara de estado seguro**.
Retorno `: Void`. **`typeStation` NÃO é editado** (decisão B — campos consumidos já existem).
Fonte: `ARQUITETURA_PickPlace.md` §2.4/§5/§6 + plano detalhado do `scl-architect` nesta sessão.

**Decisão (B) — duas fontes (assimetria intencional vs. FC_IoMapInputs):**
- **VAR_INPUT** (vêm direto dos VAR_OUTPUT dos FBs, repassados pelo OB): as 6 luzes
  (`FB_MachineMode`) + `RotCW`/`RotCCW` (`FB_PickPlaceSeq`). São transitórios/derivados de
  `Mode` — não valem campo no DB.
- **DB** (`io_Station.Sts.*`): `M1Speed`, `M2Speed`, `VacuumOn`, `AxisX.SP`, `AxisZ.SP` — já
  existem; são estado de processo que a HMI vê.

## Interface
```
FUNCTION "FC_IoMapOutputs" : Void
{ S7_Optimized_Access := 'TRUE' }
VERSION : 0.1
VAR_INPUT
   i_SafeState : Bool;   // FB_MachineMode.o_SafeState (E-Stop OU Stop OU Falha)
   i_Red       : Bool;   // -> %Q0.4
   i_Green     : Bool;   // -> %Q0.5
   i_Yellow    : Bool;   // -> %Q0.6
   i_ResetLite : Bool;   // -> %Q0.3
   i_StartLite : Bool;   // -> %Q0.7
   i_StopLite  : Bool;   // -> %Q1.0
   i_RotCW     : Bool;   // FB_PickPlaceSeq.o_RotCW  -> %Q1.2
   i_RotCCW    : Bool;   // FB_PickPlaceSeq.o_RotCCW -> %Q1.4
END_VAR
VAR_IN_OUT
   io_Station : "typeStation";   // lê Sts.M1Speed/M2Speed/VacuumOn/AxisX.SP/AxisZ.SP
END_VAR
VAR_OUTPUT
   o_ResetLite : Bool;   // %Q0.3
   o_Red       : Bool;   // %Q0.4
   o_Green     : Bool;   // %Q0.5
   o_Yellow    : Bool;   // %Q0.6
   o_StartLite : Bool;   // %Q0.7
   o_StopLite  : Bool;   // %Q1.0
   o_Grab      : Bool;   // %Q1.1
   o_RotCW     : Bool;   // %Q1.2
   o_GripCW    : Bool;   // %Q1.3 (sempre FALSE)
   o_RotCCW    : Bool;   // %Q1.4
   o_GripCCW   : Bool;   // %Q1.5 (sempre FALSE)
   o_M1        : Real;   // %QD30
   o_M2        : Real;   // %QD34
   o_Xsp       : Real;   // %QD38
   o_Zsp       : Real;   // %QD42
END_VAR
VAR_TEMP
   t_bothRot : Bool;     // conflito RotCW & RotCCW
END_VAR
```
> Saídas analógicas são **`Real`** (os `%QD` do FACTORY I/O são Real). A §2.4 da arquitetura
> diz `LReal` por engano — **corrigir** a doc depois.

## Corpo (REGIONs)
```
REGION Sinalizacao   // luzes: VAR_INPUT, SEM máscara (precisam indicar emergência/parado)
   o_ResetLite := i_ResetLite; o_Red := i_Red; o_Green := i_Green;
   o_Yellow := i_Yellow; o_StartLite := i_StartLite; o_StopLite := i_StopLite;
END_REGION

REGION Processo   // M1/M2/Grab: máscara de estado seguro
   IF i_SafeState THEN
      o_M1 := 0.0; o_M2 := 0.0; o_Grab := FALSE;
   ELSE
      o_M1 := LREAL_TO_REAL(io_Station.Sts.M1Speed);
      o_M2 := LREAL_TO_REAL(io_Station.Sts.M2Speed);
      o_Grab := io_Station.Sts.VacuumOn;
   END_IF;
END_REGION

REGION Rotacao   // máscara + exclusão mútua (estado seguro = ambos FALSE no conflito)
   t_bothRot := i_RotCW AND i_RotCCW;
   IF i_SafeState OR t_bothRot THEN
      o_RotCW := FALSE; o_RotCCW := FALSE;
   ELSE
      o_RotCW := i_RotCW; o_RotCCW := i_RotCCW;
   END_IF;
END_REGION

REGION Setpoints   // SP de eixo: SEM máscara (FB_AxisPos já congela; FC só repassa)
   o_Xsp := LREAL_TO_REAL(io_Station.Sts.AxisX.SP);
   o_Zsp := LREAL_TO_REAL(io_Station.Sts.AxisZ.SP);
END_REGION

REGION GripperOff   // gripper não usado no projeto
   o_GripCW := FALSE; o_GripCCW := FALSE;
END_REGION
```
Regras: comentários PT, nomes EN. Só `VAR_INPUT`/`VAR_IN_OUT`/`VAR_OUTPUT`/`VAR_TEMP` (sem VAR
estático/instâncias). Usar `LREAL_TO_REAL` explícito (estreitamento; valores 0–10 V cabem em
Real). Arquivo: `FCs/FC_IoMapOutputs.scl`.

**Restrições de safety (safety-auditor valida) — este FC é a ÚLTIMA barreira física:**
1. Em `i_SafeState`: `o_M1/o_M2 := 0.0`, `o_Grab/o_RotCW/o_RotCCW := FALSE` — garantido mesmo
   que um FB a montante falhe em se auto-proteger.
2. `o_GripCW/o_GripCCW := FALSE` SEMPRE (intertravamento do gripper não usado).
3. **Luzes NÃO mascaradas** — zerar a torre em emergência apagaria a sinalização (anti-fail-safe).
4. **SP de eixo NÃO mascarado/forçado a 0** — forçar SP=0 mandaria o eixo correr para 0 V em
   plena emergência (movimento perigoso). O FC só repassa o SP que `FB_AxisPos` já congelou.
5. Exclusão mútua `RotCW ⊻ RotCCW`: conflito → ambos FALSE (estado seguro, não eleger sentido).

**Tags I/O reservadas (tag-io-documenter):** saídas `%Q0.3 ResetLite`, `%Q0.4 Red`,
`%Q0.5 Green`, `%Q0.6 Yellow`, `%Q0.7 StartLite`, `%Q1.0 StopLite`, `%Q1.1 Grab`,
`%Q1.2 RotCW`, `%Q1.3 GripCW(=FALSE)`, `%Q1.4 RotCCW`, `%Q1.5 GripCCW(=FALSE)`,
`%QD30 M1`, `%QD34 M2`, `%QD38 X SP`, `%QD42 Z SP`. Registrar em `tags.md` que as saídas são
escritas num ponto único (`FC_IoMapOutputs`, fim do scan) com máscara de estado seguro nas de
processo, e a fonte de cada uma (VAR_INPUT vs DB).

**Casos de teste pendentes (test-sim-engineer):** SafeState zera M1/M2/Grab/Rot mas mantém
luzes e SP; conflito RotCW&RotCCW → ambos FALSE; LReal→Real correto nos extremos 0/10 V;
Gripper sempre FALSE.

**Carry-forward (NÃO deste bloco):** os FBs de processo (`FB_Conveyor`, `FB_AxisPos`,
`FB_PickPlaceSeq`) devem **escrever** `Sts.M1Speed/M2Speed/VacuumOn/AxisX.SP/AxisZ.SP` no DB
(via `IN_OUT`) ANTES de o FC rodar — definir isso nas interfaces deles. O FC só LÊ esses campos.
