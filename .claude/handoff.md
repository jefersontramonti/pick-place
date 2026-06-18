# Handoff: implementar referenciamento da ROTAÇÃO via sensor HOME (do scl-architect)

**Tag física real (já criada pelo usuário no FACTORY I/O):**
`"Inductive Sensor 0"` = **`%I1.3`**, Bool, indutivo **NA (NO)** → **TRUE = braço na casa (virado p/ M1)**.
> Usar ESSE nome exato (`"Inductive Sensor 0"`) no `OB_Main` — não o nome sugerido pelo arquiteto.
> Polaridade real confirma-se no PLCSIM (resolver no FACTORY I/O como em `Sensor_caixa`/`Item Detected`).

## Objetivo
Recuperar a orientação do braço após parada (E-Stop/Stop) no meio do giro (90° pós-pega ou 180°
lado M2). Hoje o homing do IDLE recupera só X/Z; a rotação é cega (pulsos, sem ângulo absoluto).
Confirmado: Step=0 com braço a 90°/180°.

## Ordem de implementação (validar CADA `.scl` no MCP antes de seguir)

### 1. `UDTs/typeStation.scl` — +1 campo em `Sts`
Adicionar (junto dos outros feedbacks): `RotHome : Bool;   // %I1.3 espelhado — braço na casa (M1)`.

### 2. `FBs/FB_RotateToHome.scl` — NOVO bloco
Primitiva escalar: gira **CCW** até o sensor HOME, reusando o handshake por NÍVEL do `FB_Rotate180`
(pulso → espera Rotating subir → espera cair = 90°), mas o critério de parada é `i_AtHome` após cada
queda, NÃO contagem. `{ S7_Optimized_Access := 'TRUE' }`, comentários PT.
```
VAR_INPUT
    i_Trig      : Bool;   // dispara; manter TRUE ate o_Done (handshake)
    i_AtHome    : Bool;   // Sts.RotHome (referencia absoluta)
    i_Rotating  : Bool;   // %I1.0 espelhado
    i_SafeState : Bool;   // aborta -> IDLE, pulso OFF no mesmo scan (prioridade maxima)
    i_MaxSteps  : Int;    // teto de pulsos de 90 (anti-laco-infinito); ex.: 4
END_VAR
VAR_OUTPUT
    o_PulseCCW  : Bool;   // -> Rotate CCW
    o_Busy      : Bool;
    o_Done      : Bool;   // segura ao detectar AtHome (handshake)
    o_Fault     : Bool;   // estourou i_MaxSteps sem achar home (sensor preso) -> falha
END_VAR
VAR
    s_State : Int := 0;   // 0 IDLE,1 PULSE,2 MOVING,3 DONE,4 FAULT
    s_Count : Int := 0;
    s_trig  : R_TRIG;
END_VAR
```
FSM:
```
s_trig(CLK := i_Trig);
IF i_SafeState THEN s_State := 0; END_IF;   // prioridade: nao gira em estado seguro
CASE s_State OF
 0: o_PulseCCW:=F; o_Busy:=F; o_Done:=F; o_Fault:=F;
    IF i_AtHome THEN o_Done := TRUE;                       // ja em casa -> nao pulsa
    ELSIF s_trig.Q AND NOT i_SafeState AND NOT i_Rotating THEN s_Count:=0; s_State:=1; END_IF;
 1: o_PulseCCW:=TRUE; o_Busy:=TRUE; IF i_Rotating THEN s_Count:=s_Count+1; s_State:=2; END_IF;
 2: o_PulseCCW:=FALSE; o_Busy:=TRUE;
    IF NOT i_Rotating THEN                                 // 90 concluido (queda gated por estado)
        IF i_AtHome THEN s_State:=3;
        ELSIF s_Count >= i_MaxSteps THEN s_State:=4;
        ELSE s_State:=1; END_IF; END_IF;
 3: o_PulseCCW:=FALSE; o_Done:=TRUE; IF NOT i_Trig THEN s_State:=0; END_IF;
 4: o_PulseCCW:=FALSE; o_Fault:=TRUE; IF NOT i_Trig THEN s_State:=0; END_IF;
 ELSE s_State:=0;
END_CASE;
```
Cuidados (mesmos do FB_Rotate180 já validado): detecção por NÍVEL gated por estado (sem F_TRIG
global); inicializações explícitas; o caso "já em casa" sinaliza o_Done sem pulsar (não congela).

### 3. `FCs/FC_IoMapInputs.scl` — +1 entrada
`+ i_RotHome : Bool;   // %I1.3 — HOME de rotacao` na VAR_INPUT; na região Feedbacks:
`#io_Station.Sts.RotHome := #i_RotHome;` (cópia crua).

### 4. `FBs/FB_PickPlaceSeq.scl` — homing rotacional + malha do passo 15
- **+VAR:** `s_RotHome : "FB_RotateToHome";` e `s_trigHome : Bool;`.
- **Defaults do scan:** `+ #s_trigHome := FALSE;`.
- **Estado 0 (IDLE/HOMING):** após confirmar Z em Z_up E X em X_home, ANTES de aceitar ciclo,
  inserir o homing da rotação:
  ```
  IF NOT #io_Station.Sts.RotHome THEN
      #s_trigHome := TRUE;        // dispara FB_RotateToHome (gira CCW ate HOME)
      #s_stepIsMove := TRUE;      // timeout externo (anti-laco)
      IF #s_RotHome.o_Fault THEN  // sensor nao achado -> falha de homing rotacao
          IF NOT #s_Fault THEN #s_Fault := TRUE; #s_FaultCode := 3; END_IF;
          #s_State := 99;
      END_IF;
  ELSE
      // braco em casa: aceita partida (logica atual)
      IF #io_Station.Cfg.Enabled AND #io_Station.Sts.BoxAtPick
      AND NOT #i_SafeState AND NOT #s_Fault THEN #s_State := 1; END_IF;
  END_IF;
  ```
  (a guarda de anticolisão Z up + X home já está garantida pelo aninhamento; o NOT Rotating está
  dentro do FB_RotateToHome.)
- **Chamada sub-FBs (região após o CASE):** chamar incondicionalmente:
  `#s_RotHome(i_Trig:=#s_trigHome, i_AtHome:=#io_Station.Sts.RotHome, i_Rotating:=#io_Station.Sts.Rotating, i_SafeState:=#i_SafeState, i_MaxSteps:=4);`
- **Espelha status (o_RotCCW):** OR com o homing —
  `#o_RotCCW := #s_RotCCW.o_PulseCCW OR #s_RotHome.o_PulseCCW;` (homing é estado 0, passo 15 é outro
  estado → nunca coexistem; mantém exclusão mútua com o_RotCW).
- **Passo 15 (fechar a malha):** a transição passa a exigir também `RotHome`:
  `IF #s_RotCCW.o_Done AND #io_Station.Sts.RotHome THEN #s_State := 16; END_IF;` (se o_Done vier
  sem RotHome = deriva → timeout do passo 15 = FaultCode 3 → FALHA → homing recupera).
- **NÃO** mudar a interface externa do FB_PickPlaceSeq (mesmas VAR_INPUT/OUTPUT/IN_OUT). O passo 7
  (CW p/ M2) continua por contagem (`FB_Rotate180`) — não há sensor no lado M2.

### 5. `OBs/OB_Main.scl` — fiar a tag nova
Na chamada do `FC_IoMapInputs` (região 1), adicionar o parâmetro:
`i_RotHome := "Inductive Sensor 0",`.

## Restrições de safety (safety-auditor valida depois)
- Homing NÃO gira em estado seguro (i_SafeState aborta o FB e o estado 0 está sob `IF i_Run`).
- Anticolisão mantida (Z up + X home + NOT Rotating).
- Anti-laço-infinito: dupla guarda (`i_MaxSteps` interno + `s_stepIsMove`/timeout externo → FALHA).
- Falha de homing latcheia no FB_PickPlaceSeq (fonte única, o_Fault nível, FaultCode 3); sem double-latch.
- Sensor HOME é standard (não F-safe) → mantém C-1 (acesso de pessoas exigiria F-CPU/STO).

## Impacto no TIA (não vira `.scl`)
- Criar a tag `"Inductive Sensor 0"` = `%I1.3` (o usuário já adicionou na cena).
- `typeStation` muda → `StationData` recompila; `FB_PickPlaceSeq_DB` é regenerado (nova
  multi-instância `s_RotHome`); nenhum DB de instância novo no nível do OB.
- `tag-io-documenter`: adicionar `%I1.3` à §2/§6 do `tags.md`.
