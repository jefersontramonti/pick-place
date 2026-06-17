# Handoff: FB_MachineMode (FB com estado — núcleo fail-safe)

**Decisão de arquitetura:** máquina de **modo de operação** PARADO/RODANDO/EMERGÊNCIA/FALHA.
É o **único** ponto que interpreta a polaridade **NF** de `i_EStop`/`i_Stop`, faz o **latch** de
emergência/falha e produz `o_SafeState` (consumido por TODAS as máscaras — FCs e FBs) + a
sinalização (torre + luzes de botão). Prioridade: **emergência > falha > stop > operação**, a
cada scan. Fonte: `ARQUITETURA_PickPlace.md` §2.6/§3.1, `ESCOPO_PickPlace.md` §3.

## Polaridade (CRÍTICO — este FB trata o NF; os FCs só copiam cru)
- `i_EStop` **NF**: `FALSE` = emergência (ou fio rompido) → estado seguro.
- `i_Stop` **NF**: `FALSE` = parar (ou fio rompido).
- `i_Start` **NO**: borda de subida = liga.
- `i_Reset` **NO**: borda de subida = rearma (pulso).

## Interface
```
FUNCTION_BLOCK "FB_MachineMode"
{ S7_Optimized_Access := 'TRUE' }
VERSION : 0.1
VAR_INPUT
   i_Start    : Bool;    // NO  — borda liga
   i_Stop     : Bool;    // NF  — FALSE = parar
   i_EStop    : Bool;    // NF  — FALSE = emergência
   i_Reset    : Bool;    // NO  — borda rearma
   i_SeqFault : Bool;    // falha vinda da sequência (timeout etc.)
   i_ClkSlow  : Bool;    // pisca lento (FB_ClockGen.o_Slow)
   i_ClkFast  : Bool;    // pisca rápido (FB_ClockGen.o_Fast)
END_VAR
VAR_OUTPUT
   o_Mode      : Int;    // 0=PARADO 1=RODANDO 2=EMERGÊNCIA 3=FALHA
   o_Run       : Bool;   // habilita esteiras + sequência (TRUE só em RODANDO)
   o_SafeState : Bool;   // TRUE em PARADO/EMERGÊNCIA/FALHA (máscara das saídas)
   o_Red       : Bool;   // torre vermelho
   o_Green     : Bool;   // torre verde
   o_Yellow    : Bool;   // torre amarelo
   o_StartLite : Bool;   // luz botão Liga
   o_StopLite  : Bool;   // luz botão Desliga
   o_ResetLite : Bool;   // luz botão Reset
END_VAR
VAR
   s_State   : Int := 0;   // estado atual (default PARADO)
   s_Reset   : R_TRIG;     // borda de subida do Reset
   s_Start   : R_TRIG;     // borda de subida do Start
   s_Latched : Bool;       // latch de EMERGÊNCIA (só emergência; falha é NÍVEL via i_SeqFault)
END_VAR
```
> **CORREÇÃO (achado [ALTO] do revisor + decisão do arquiteto):** o latch de FALHA é ÚNICO e
> vive no `FB_PickPlaceSeq` (`o_Fault`, nível). Aqui `i_SeqFault` é **NÍVEL** — o MachineMode
> **não** tem `s_FaultLatch`: entra em FALHA por nível e o CLEAR trata só a emergência. Elimina
> o glitch de 1 scan e a disputa de borda do reset entre os dois blocos.
```
```

## Lógica
```
REGION Bordas
   #s_Reset(CLK := #i_Reset);
   #s_Start(CLK := #i_Start);
END_REGION

REGION Latches de emergencia e falha
   // SET emergência: NF — FALSE = acionado (ou fio rompido). Reavaliado todo scan.
   IF NOT #i_EStop THEN
      #s_Latched := TRUE;
   END_IF;
   // (FALHA não latcheia aqui — é NÍVEL via i_SeqFault, latcheada no FB_PickPlaceSeq.)
   // CLEAR (rearme deliberado) da EMERGÊNCIA: só com E-Stop REARMADO E borda de Reset.
   // Enquanto i_EStop=FALSE, o SET acima re-trava — sem auto-rearme.
   IF #s_Reset.Q AND #i_EStop THEN
      #s_Latched := FALSE;
   END_IF;
END_REGION

REGION Maquina de modo (prioridade: emergencia > falha > stop > operacao)
   IF #s_Latched THEN
      #s_State := 2;                  // EMERGÊNCIA
   ELSIF #i_SeqFault THEN
      #s_State := 3;                  // FALHA (nível — reflete o_Fault da sequência)
   ELSIF NOT #i_Stop THEN
      #s_State := 0;                  // PARADO (Stop NF acionado/fio rompido)
   ELSE
      // saudável: nem emergência, nem falha, nem Stop. (Aqui i_EStop=TRUE garantido,
      // pois NOT i_EStop teria setado s_Latched -> ramo EMERGÊNCIA.)
      IF #s_State = 1 THEN
         ;                            // permanece RODANDO (Stop já tratado acima)
      ELSIF #s_Start.Q THEN
         #s_State := 1;               // PARADO -> RODANDO na borda de Start
      ELSE
         #s_State := 0;               // PARADO
      END_IF;
   END_IF;
END_REGION

REGION Saidas e sinalizacao
   o_Mode := #s_State;
   // Luz de Reset: pisca enquanto houver latch a rearmar; apaga após reset bem-sucedido.
   o_ResetLite := (#s_Latched OR #i_SeqFault) AND #i_ClkSlow;

   CASE #s_State OF
      1:  // RODANDO
         #o_Run := TRUE;  #o_SafeState := FALSE;
         #o_Green := TRUE; #o_Yellow := FALSE; #o_Red := FALSE;
         #o_StartLite := TRUE; #o_StopLite := FALSE;
      2:  // EMERGÊNCIA — vermelho piscando rápido
         #o_Run := FALSE; #o_SafeState := TRUE;
         #o_Green := FALSE; #o_Yellow := FALSE; #o_Red := #i_ClkFast;
         #o_StartLite := FALSE; #o_StopLite := FALSE;
      3:  // FALHA — vermelho FIXO (distingue de emergência/parado); ver decisão abaixo
         #o_Run := FALSE; #o_SafeState := TRUE;
         #o_Green := FALSE; #o_Yellow := FALSE; #o_Red := TRUE;
         #o_StartLite := FALSE; #o_StopLite := FALSE;
      ELSE  // 0 PARADO — amarelo piscando lento, luz Desliga acesa
         #o_Run := FALSE; #o_SafeState := TRUE;
         #o_Green := FALSE; #o_Yellow := #i_ClkSlow; #o_Red := FALSE;
         #o_StartLite := FALSE; #o_StopLite := TRUE;
   END_CASE;
END_REGION
```

**Pontos críticos (safety):**
- **E-Stop NF latcheado, sem auto-rearme:** `NOT i_EStop` seta `s_Latched` TODO scan; só limpa
  com `i_EStop=TRUE` (rearmado fisicamente) **E** borda de Reset. SET e CLEAR são mutuamente
  exclusivos em `i_EStop` (não há conflito no mesmo scan).
- **Prioridade emergência > falha > stop > operação** garantida pela ordem IF/ELSIF.
- **`o_SafeState=TRUE` em PARADO/EMERGÊNCIA/FALHA** (só FALSE em RODANDO) — alimenta as
  máscaras do `FC_IoMapOutputs`, `FB_AxisPos`, `FB_Conveyor`, `FB_Rotate180`.
- **Energização:** `s_State:=0` (PARADO), latches FALSE; se `i_EStop=FALSE` na 1ª varredura →
  `s_Latched` seta → EMERGÊNCIA (fail-safe). Nunca nasce em RODANDO.
- **Start inibido** em emergência/falha/stop: só o ramo ELSE (saudável) aceita `s_Start.Q`;
  após reset, cai em PARADO e exige novo Start (não retoma RODANDO sozinho).
- **Fio rompido** em EStop/Stop (NF) → `FALSE` → estado seguro.

**DECISÃO a confirmar (sinalização da FALHA — era "a definir" na §3.1):** adotei **vermelho
FIXO** para FALHA (distingue de EMERGÊNCIA=vermelho piscando e PARADO=amarelo piscando), com
`o_ResetLite` piscando (há latch a rearmar). Alternativa: "como PARADO" (amarelo piscando). Não
afeta safety (`o_Run`/`o_SafeState` idênticos); é só visual.

Regras: comentários PT, nomes EN, REGION, `CASE` com `ELSE`. Arquivo: `FBs/FB_MachineMode.scl`.
É FB de instância única, chamado pelo `OB_Main` (passo 3 da §4) — **não** criar a chamada agora.

**Restrições de safety (safety-auditor valida — bloco mais crítico do projeto):** E-Stop NF
prioritário + latch + reset por borda com rearme físico; prioridade emergência>falha>operação a
cada scan; `o_SafeState` correto nos 4 estados; energização em estado seguro; sem auto-rearme;
fail-safe a fio rompido. Sinalizar o que exigiria F-CPU/PROFIsafe (premissa standard do projeto).

**Tags I/O reservadas:** nenhuma nova — entradas vêm de `Station.Cmd.*` (Start/Stop/EStop/Reset,
via FC_IoMapInputs) e dos clocks (FB_ClockGen); saídas de luz vão ao `FC_IoMapOutputs` (VAR_INPUT
i_Red/Green/Yellow/ResetLite/StartLite/StopLite). Tag-io: **N/A**.

**Casos de teste pendentes (test-sim-engineer):** EStop FALSE → EMERGÊNCIA latcheada; reset sem
rearme não sai; rearme+reset → PARADO; Start em PARADO → RODANDO; Stop/fio rompido em RODANDO →
PARADO; SeqFault → FALHA; energização com EStop pressionado → EMERGÊNCIA; pisca da torre e da
luz de Reset coerentes.

**Carry-forward (`OB_Main`):** instância única; ligar `i_Start/Stop/EStop/Reset := Station.Cmd.*`,
`i_SeqFault := PickPlaceSeq.o_Fault`, `i_ClkSlow/Fast := ClockGen.o_Slow/o_Fast`. Propagar
`o_SafeState` e `o_Run` a todos os FBs; luzes → `FC_IoMapOutputs`.
