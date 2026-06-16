# Handoff: FB_Rotate180 (FB com estado — FSM de rotação por pulso)

**Decisão de arquitetura:** primitiva que gira o braço **180°** dando **2 pulsos** de 90° no
sentido travado, contando as conclusões via `Rotating` (`%I1.0`). Interface ESCALAR (sem
typeStation). Consumida pelo `FB_PickPlaceSeq` (instâncias CW e CCW). Fonte:
`ARQUITETURA_PickPlace.md` §2.8/§3.3.

**Refinamento vs. §2.8 (deliberado — documentar):** em vez de pulso de **largura fixa**
(`s_tPulse` TON, que abria a dúvida §9.2 "1 scan basta?"), uso **handshake com `Rotating`**:
o pulso fica TRUE até o modelo começar a girar (`Rotating` sobe), então é solto, e espera-se a
**queda** de `Rotating` (90° concluído). Isso **auto-sincroniza** com o modelo e **resolve o
item §9.2** (não depende de calibrar a largura do pulso). Removo `s_tPulse`; adiciono
`s_Count`/`s_Dir`. A rotação é **por borda** (1 pulso=90°), confirmado pelo usuário.

## Interface
```
FUNCTION_BLOCK "FB_Rotate180"
{ S7_Optimized_Access := 'TRUE' }
VERSION : 0.1
VAR_INPUT
   i_Trig      : Bool;   // dispara a sequência (Execute) — manter TRUE até o_Done (handshake)
   i_Dir       : Bool;   // TRUE = CW, FALSE = CCW (travado na partida)
   i_Rotating  : Bool;   // %I1.0 — braço em rotação (feedback)
   i_SafeState : Bool;   // TRUE = aborta (estado seguro)
END_VAR
VAR_OUTPUT
   o_PulseCW  : Bool;    // -> Rotate CW  (%Q1.2)
   o_PulseCCW : Bool;    // -> Rotate CCW (%Q1.4)
   o_Busy     : Bool;    // TRUE enquanto gira
   o_Done     : Bool;    // TRUE ao concluir 180° (segura até i_Trig cair — handshake)
END_VAR
VAR
   s_State : Int := 0;   // 0 IDLE, 1 PULSE, 2 MOVING, 3 DONE
   s_Dir   : Bool;       // sentido travado na partida (TRUE=CW)
   s_Count : Int := 0;   // incrementos de 90° concluídos (0..2)
   s_trig  : R_TRIG;     // borda de subida do trigger (i_Trig)
END_VAR
```
> **CORREÇÃO (achado CRÍTICO do revisor):** removido o `s_fRot : F_TRIG`. A conclusão de
> cada 90° é detectada por **nível gated por estado** (queda só conta no state 2), eliminando
> a corrida em que uma queda global de `Rotating` era consumida tarde / perdida / contada
> espúria. O start exige `NOT i_Rotating` (braço assentado).
```
```

## Lógica (CASE com ELSE seguro)
```
// Borda do trigger — chamar todo scan
#s_trig(CLK := #i_Trig);

// Estado seguro: aborta a qualquer momento (prioridade sobre o CASE)
IF #i_SafeState THEN
   #s_State := 0;
END_IF;

CASE #s_State OF
   0:  // IDLE — tudo desligado; aguarda trigger
      #o_PulseCW := FALSE; #o_PulseCCW := FALSE; #o_Busy := FALSE; #o_Done := FALSE;
      // Só inicia com o braço assentado (NOT i_Rotating) — guarda contra residual
      IF #s_trig.Q AND NOT #i_SafeState AND NOT #i_Rotating THEN
         #s_Dir   := #i_Dir;   // trava o sentido na partida
         #s_Count := 0;
         #s_State := 1;
      END_IF;

   1:  // PULSE — emite o pulso (borda de subida) no sentido travado; segura até girar
      #o_PulseCW  := #s_Dir;
      #o_PulseCCW := NOT #s_Dir;
      #o_Busy := TRUE;
      IF #i_Rotating THEN       // modelo registrou o pulso e começou a girar
         #s_State := 2;
      END_IF;

   2:  // MOVING — pulso solto; espera a queda de Rotating (90° concluído)
      // Detecção por NÍVEL gated por estado: só chega aqui APÓS o state 1 ver i_Rotating=TRUE,
      // então NOT i_Rotating = a queda do movimento atual (sem F_TRIG global, sem corrida).
      #o_PulseCW := FALSE; #o_PulseCCW := FALSE;
      #o_Busy := TRUE;
      IF NOT #i_Rotating THEN   // 90° concluído
         #s_Count := #s_Count + 1;
         IF #s_Count >= 2 THEN
            #s_State := 3;       // 180° concluído
         ELSE
            #s_State := 1;       // próximo pulso (novo flanco de subida)
         END_IF;
      END_IF;

   3:  // DONE — sinaliza conclusão; aguarda o consumidor soltar i_Trig (handshake)
      #o_PulseCW := FALSE; #o_PulseCCW := FALSE; #o_Busy := FALSE;
      #o_Done := TRUE;
      IF NOT #i_Trig THEN
         #s_State := 0;
      END_IF;

   ELSE
      #s_State := 0;   // estado inválido -> seguro
END_CASE;
```

**Pontos críticos:**
- **Estado seguro prioritário:** o `IF i_SafeState THEN s_State := 0` ANTES do CASE força o
  retorno a IDLE; o CASE 0 então zera os pulsos no mesmo scan. Rotação **para** em emergência.
- **Sentido travado** (`s_Dir := i_Dir` na partida): mudar `i_Dir` no meio não inverte.
- **Handshake Execute/Done:** o consumidor (`FB_PickPlaceSeq`) **mantém `i_Trig` TRUE até ver
  `o_Done`**, então solta — aí a FSM volta a IDLE. Garante que o `o_Done` não se perca.
- **Sem `s_tPulse`:** o pulso é segurado até `Rotating` subir (state 1) e solto em state 2 —
  novo pulso em state 1 = flanco de subida fresco para o 2º 90°. Não há largura a calibrar.
- **Sem timeout interno:** se `Rotating` nunca responder, a FSM fica em PULSE/MOVING; o
  **timeout de passo do `FB_PickPlaceSeq`** (`s_tStep`, FaultCode 3) é quem aborta. (§2.10)
- `CASE` com `ELSE` → estado inválido cai em IDLE seguro (convenção do projeto).

Regras: comentários PT, nomes EN, REGION (pode envolver o CASE numa REGION). Arquivo:
`FBs/FB_Rotate180.scl`. É FB instanciado dentro do `FB_PickPlaceSeq` (CW e CCW) — **não**
chamar de OB diretamente.

**Restrições de safety (safety-auditor valida):**
1. `i_SafeState` aborta a rotação em qualquer estado → IDLE, `o_PulseCW/CCW := FALSE` no mesmo
   scan (não continuar girando em emergência).
2. Não há caminho que ligue `o_PulseCW`/`o_PulseCCW` fora do state 1; nunca os dois juntos
   (são `s_Dir` ⊻ `NOT s_Dir`). (A exclusão mútua final também é garantida no `FC_IoMapOutputs`.)
3. Trigger não dispara em estado seguro (`s_trig.Q AND NOT i_SafeState`).
4. Estado inválido → IDLE (sem pulso preso).

**Tags I/O reservadas:** nenhuma — `o_PulseCW/CCW` vão ao `%Q` via `FC_IoMapOutputs` (VAR_INPUT
i_RotCW/i_RotCCW dele). `i_Rotating` vem de `Sts.Rotating` (espelho do `%I1.0`). Tag-io: nada novo.

**Casos de teste pendentes (test-sim-engineer):** trigger → 2 pulsos → o_Done após 2 quedas de
Rotating; o_Busy TRUE durante; i_SafeState no meio → aborta (pulsos OFF, IDLE); i_Dir travado;
handshake (o_Done segura até i_Trig cair); estado inválido → IDLE.

**Carry-forward (consumidor `FB_PickPlaceSeq`):** instanciar `s_RotCW`/`s_RotCCW : FB_Rotate180`;
nos passos 7/15, dar `i_Trig := TRUE` e **manter** até `o_Done`, com `i_Dir := TRUE` (CW) / `FALSE`
(CCW), `i_Rotating := Sts.Rotating`, `i_SafeState := <safe>`; `o_PulseCW/CCW` → `o_RotCW/o_RotCCW`
da sequência (que vão ao FC de saída). Timeout do passo cobre rotação travada.
