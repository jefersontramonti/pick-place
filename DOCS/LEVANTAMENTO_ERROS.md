# Levantamento de erros — comissionamento (pós-entrega 13/13)

> Documento dedicado aos **erros encontrados e corrigidos APÓS a última entrega total dos
> agentes** (lógica 13/13 "completa", validada no MCP, revisada e auditada). Cobre a fase de
> **integração no TIA Portal** e **comissionamento no PLCSIM/FACTORY I/O** (jun/2026).
> Histórico cronológico fica em `PROJECT_STATE.md`; aqui é a **referência consolidada** dos erros.

## Resumo

| Categoria | Qtde | Observação |
|---|---|---|
| A. Compilação no TIA | 2 | `LREAL_TO_TIME` inexistente + warning de init |
| B. Bugs de lógica (achados no PLCSIM) | 2 | falso FALHA 4 + deadlock no depósito |
| C. Achados da re-revisão dos agentes | 6 | 1 ALTO (estado seguro dos eixos), 1 normativo |
| D. Calibração (§9.2) | 4 | velocidades/atrasos/setpoints/polaridade |
| F. Recuperação pós-falha | 2 | release M1 no reset + referenciamento da rotação (HOME `%I1.3`) |
| G. Sinalização (torre) | 3 | clock zerado → fallback; FALHA fixa → pisca lento; init das ondas |
| **Total de itens** | **19** | + pendências (C-1, M-1, M-2) |

**Lição central:** o **linter MCP e a revisão estática não pegam** bugs de timing, geometria e
estado seguro — **o PLCSIM (e o compilador do TIA) são a validação definitiva**.

---

## A. Compilação no TIA Portal

| # | Bloco | Erro/Warning | Causa | Correção | Status |
|---|---|---|---|---|---|
| A1 | `FB_ClockGen` | `Tag LREAL_TO_TIME not defined` (2×) | `LREAL_TO_TIME` **não existe** no compilador TIA/MHJ (o linter MCP aceitou — falso-positivo) | `DINT_TO_TIME(LREAL_TO_DINT(ms))` | ✅ corrigido + commitado |
| A2 | `FB_AxisPos` | `o_SetPointCmd might not be initialized` | VAR_OUTPUT lido no padrão freeze | `o_SetPointCmd : LReal := 0.0` | ✅ corrigido + commitado |
| A3 | hardware | `Inputs or outputs ... do not exist in the configured hardware` | endereços (%I/%ID/%Q/%QD) sem módulos configurados | Device Config no TIA (não é código) | ⏳ usuário |

---

## B. Bugs de lógica encontrados no PLCSIM

### B1 — Falso FALHA 4 + robô descendo durante a falha (`FB_PickPlaceSeq`, estado 2)
- **Sintoma:** ao iniciar a pega disparava FALHA 4 ("Z no limite sem ItemDetected") com o robô
  ainda em cima; o setpoint de Z congelava em `Z_pickLimit` e o robô **descia durante a falha**,
  prensando a caixa (Step=0, FaultCode=4, Z parado ~6.59, ItemDetected TRUE tarde demais).
- **Causa:** o `ELSIF` usava `AxisZ.InPos` **genérico**. Ao **entrar** no estado 2 o robô está
  parado em `Z_up` (SP=0, PV=0 → `InPos`=TRUE), e como `ItemDetected` ainda é FALSE, o `ELSIF`
  disparava FALHA 4 **no 1º scan, antes de descer**.
- **Correção:** exigir que o Z esteja **de fato** no limite —
  `ELSIF AxisZ.InPos AND ABS(AxisZ.PV - Z_pickLimit) <= PosTol`.
- **Status:** ✅ validado no MCP. (A descida durante a falha foi tratada de raiz no item C1/A-1.)

### B2 — Deadlock no depósito (`FB_PickPlaceSeq`, estado 11)
- **Sintoma:** depositava e desligava o vácuo, mas **não prosseguia** o ciclo — travava no passo 11
  (Grab OFF, ItemDetected TRUE).
- **Causa:** o passo 11 só avançava com `NOT ItemDetected`. Na altura de depósito a peça fica
  **logo sob o sensor da ventosa** → `ItemDetected` permanece TRUE → deadlock (FALHA 5 no timeout).
  A confirmação de "soltou" por esse sensor **não é válida nessa geometria**. Para a entrega o
  sensor **não é necessário** (o depósito é posicional).
- **Correção:** transição **posicional** (chegou em `Z_place` + vácuo OFF → sobe); removida a
  guarda `IF NOT ItemDetected`.
- **Status:** ✅ validado no MCP.

---

## C. Achados da re-revisão dos agentes (scl-reviewer + safety-auditor)

| # | Sev. | Achado | Correção | Status |
|---|---|---|---|---|
| C1 | **ALTO (A-1)** | **Estado seguro NÃO parava os eixos:** em falha/E-Stop o SP analógico congelava no **destino** (não na posição atual) → o eixo continuava percorrendo ao alvo (causa-raiz do robô descer na caixa). A máscara do `FC_IoMapOutputs` zera M1/M2/Grab/Rotate, mas **não** o SP de posição. | `FB_AxisPos`: em `i_SafeState`, congelar `o_SetPointCmd := i_PV` (segura onde está) | ✅ validado |
| C2 | MÉDIO (M-3) | CLEAR voltava a IDLE **sem referenciar os eixos** → geometria desconhecida pós-falha | **IDLE/homing**: em RODANDO sobe Z → leva X a home antes de novo ciclo (homing no START) | ✅ validado |
| C3 | BAIXO | **mesmo padrão "InPos genérico"** sobrevivente no **passo 1** (linha 117) | alinhar: `+ ABS(AxisX.PV - X_pick) <= PosTol` | ✅ validado |
| C4 | MÉDIO (M-2) | passo 11 sem confirmação de solta (pode subir carregando a peça); **FaultCode 5 órfão** | FaultCode 5 **aposentado**; dwell de despressurização = opcional | ✅ (dwell ⏳) |
| C5 | **NORM (C-1)** | parada segura dos eixos/rotação por E-Stop em lógica **standard** tem classe de risco que exigiria **F-CPU/PROFIsafe + STO** se houver **acesso de pessoas** à zona de movimento | avaliação de risco | ⏳ **decisão do usuário** |
| C6 | MÉDIO (M-1) | FALHA 4 depende de o Z atingir `Z_pickLimit` dentro de `PosTol`; senão degrada p/ timeout (FALHA 2) com diagnóstico trocado | validar no PLCSIM que `Z_pickLimit` é alcançável | ⏳ validar |

---

## D. Calibração validada (§9.2)

| # | Parâmetro | Achado | Valor validado |
|---|---|---|---|
| D1 | `Cfg.M1StopDelay` | 1,2 s → caixa passava direto (corria pra fora antes da M1 parar) | **`T#50ms`** (recalibrável) |
| D2 | `Cfg.ConvSpeed` | rápida demais → sensor não amostra a caixa (janela < scan do OB1) | **6.5** (recalibrável) |
| D3 | `Cfg.Z_place` | 6.8 fundo demais (caixa pousa com o robô em ~6.59) → timeout FALHA 2 | **6.5** |
| D4 | sensores `Sensor_caixa` / `Item Detected` | polaridade | resolvida **no FACTORY I/O** (`FC_IoMapInputs` segue cópia crua: TRUE = detectado) |

Referências de geometria medidas no PLCSIM: `Item Detected` aciona em **Z≈5.8**; topo da caixa
em **6.7**; `Z_pickLimit = 8.0` (limite só para o caso "sem caixa").

**Velocidade do robô:** os eixos X/Z movem na velocidade do **componente FACTORY I/O** (o SCL só
comanda posição). Para acelerar o ciclo pelo lado do PLC, reduzir `Cfg.PosDebounce` (200 ms →
~80–100 ms) corta o dwell em cada um dos ~10 posicionamentos; **manter a descida da pega (Z)
moderada** para não perder o `Item Detected` por amostragem.

---

## E. Pendências em aberto

- **C-1 (normativo):** decisão da análise de risco — F-CPU/PROFIsafe + STO se houver acesso de
  pessoas. A correção C1 (congelar no PV) é boa prática em lógica standard, mas **não substitui**
  canal de segurança certificado.
- **M-1:** confirmar no PLCSIM que `Z_pickLimit` é alcançável dentro de `PosTol`.
- **M-2:** dwell de despressurização do vácuo no passo 11 (opcional; o ciclo fecha sem ele).
- **Recompilar tudo no TIA** após as correções (validação definitiva).
- **Decisões de processo (do escopo):** sinalização FALHA (vermelho fixo?); vácuo no E-Stop
  (i) soltar vs (ii) segurar.

---

## F. Recuperação pós-falha (2ª rodada de comissionamento)

### F1 — M1 não avançava após a falha (latch preso) → release no reset
- **Sintoma:** após uma falha, a esteira M1 ficava parada e não trazia caixa nova; com o
  `BoxAtPick` "fantasma" (latch antigo), o ciclo reiniciava sem caixa física → FALHA 4 de novo
  (operador tinha que pôr caixa na mão).
- **Causa:** o box-latch da M1 (`FB_Conveyor.s_boxLatch`) só era limpo pelo release do passo 5
  (ciclo normal). Numa falha, nunca chegava ao passo 5 → latch preso.
- **Correção:** `FB_PickPlaceSeq` pulsa `o_ReleaseM1` no **reset deliberado** (`s_rReset.Q AND
  i_EStop`) → limpa o latch → M1 volta a trazer caixas e `BoxAtPick` reflete a realidade.
- **Status:** ✅ validado no MCP.

### F2 — Rotação não era recuperada (parada a 90°/180°) → referenciamento via sensor HOME
- **Sintoma:** parando (E-Stop/Stop) **no meio do giro** (90° pós-pega ou 180° lado M2), no
  reset+start a FSM voltava a Step=0 mas o braço ficava **fisicamente rotacionado** → o ciclo
  seguinte operava no lado errado ("tentava largar caixa onde estava"). Confirmado: Step=0 a 90° e 180°.
- **Causa:** o homing recuperava só X/Z; a rotação é por **pulso, sem ângulo absoluto** → sem
  referência para casa.
- **Correção (pipeline completo architect→developer→reviewer→safety→tag-io):** novo sensor de
  **HOME de rotação** `"Inductive Sensor 0"` = **`%I1.3`** (indutivo NA → TRUE = braço na casa/M1).
  Novo FB **`FB_RotateToHome`** (gira CCW até o HOME, parada por sensor, `i_MaxSteps`=4
  anti-laço → `o_Fault`). O estado 0 do `FB_PickPlaceSeq` referencia a rotação após Z up + X home;
  o passo 15 passou a **confirmar `RotHome`** (fecha a malha, mata deriva). `+Sts.RotHome` no
  `typeStation`, `+i_RotHome` no `FC_IoMapInputs`, fiado no `OB_Main`.
- **Safety:** ✅ **APROVADO** (não gira em estado seguro; anticolisão; anti-laço-infinito por dupla
  guarda; latch único FaultCode 3; exclusão mútua CW⊻CCW; C-1 reafirmado).
- **Status:** ✅ validado no MCP; falta criar `%I1.3` no TIA, recompilar (regenera
  `FB_PickPlaceSeq_DB`) e testar a recuperação 90°/180° no PLCSIM.
- **Verificar no §9.2:** polaridade NA real do HOME; janela do sensor vs detente de 90°; qual
  FaultCode aparece (1 timeout vs 3 sensor varrido) por modo de falha.

### Calibração confirmada nesta rodada
- `Cfg.ConvSpeed` = **6.5**, `Cfg.M1StopDelay` = **T#50ms** (recalibráveis); `Cfg.Z_place` = **6.5**.
- **Velocidade do robô** = propriedade do componente FACTORY I/O (o SCL só comanda posição); pelo
  PLC, baixar `Cfg.PosDebounce` (200 ms) corta dwell — mantendo a descida da pega moderada.

---

## G. Sinalização da torre (3ª rodada de comissionamento)

### G1 — Torre vermelha não acendia na EMERGÊNCIA (mas acendia fixa na FALHA)
- **Sintoma:** ao apertar a emergência a torre vermelha **não acendia**; numa falha a vermelha
  **acendia, porém fixa** (não piscava).
- **Causa:** `FB_MachineMode` usa `o_Red := i_ClkFast` na emergência (depende do clock) e usava
  `o_Red := TRUE` na falha (constante). O `i_ClkFast` estava **travado em FALSE** porque
  `Cfg.ClkFastHz` valia **0.0** no DB real — os start values dependiam só da **herança do UDT**,
  que **não repropaga** quando o DB é regenerado/reinicializado (e o `typeStation` mudou várias
  vezes). Clock parado → emergência apagada; falha (TRUE) acendia → assinatura exata do problema.
- **Correção:** (1) `FB_ClockGen` ganhou **fallback** — `Hz ≤ 0` usa 1 Hz/3 Hz padrão em vez de
  apagar; (2) start values **explícitos** em `StationData` (`ClkSlowHz:=1.0`, `ClkFastHz:=3.0`).
- **Status:** ✅ validado no MCP. **Ação no TIA:** reinicializar o `StationData` (ou escrever os
  Hz online) — só recompilar mantém o valor de carga 0.0.

### G2 — FALHA ficava em vermelho fixo (não piscava) → pisca lento
- **Sintoma/decisão:** o usuário queria que a falha **piscasse** e fosse perceptível.
- **Correção:** `FB_MachineMode` estado 3 → `o_Red := i_ClkSlow` (pisca lento, ~1 Hz) e
  `o_StopLite := TRUE` (FALHA = "PARADO + indicação", §3). EMERGÊNCIA segue pisca rápido (~3 Hz).
  Distinção emergência×falha pela **cadência** do mesmo LED vermelho. Formalizado no escopo §3.1
  e no `tags.md §7` (FALHA não tinha linha nas tabelas).
- **Status:** ✅ validado no MCP.

### G3 — Onda do clock podia partir em FALSE (torre muda no 1º instante)
- **Achado (safety-auditor):** `s_SlowState`/`s_FastState` começavam em FALSE → se a emergência
  ocorresse no instante de partida, antes do 1º toggle, a torre ficava apagada.
- **Correção:** inicializar `s_SlowState := TRUE` / `s_FastState := TRUE` (acende já no 1º scan).
- **Status:** ✅ validado no MCP.

> **Auditoria de TODAS as lâmpadas (scl-reviewer + safety-auditor):** 0 CRÍTICO / 0 ALTO. As 6
> luzes corretas nos 4 estados (sem lâmpada indefinida, cores exclusivas, luz de Reset conforme
> §3.2). Riscos residuais aceitos: pisca tem ~50% OFF (escopo exige pisca); lâmpada queimada/canal
> travado indetectável em lógica standard; C-1 (E-Stop F-CPU) é a pendência normativa real.

---

## Resultado

Com B1, B2, C1–C3, F1, F2 e a calibração D, o **ciclo Pick → gira 180° → deposita → retorna rodou
completo e repetido no PLCSIM**, e a **recuperação por homing (X/Z)** funcionou. Todos os blocos
(`FB_AxisPos`, `FB_PickPlaceSeq`, `FB_RotateToHome`, `FB_ClockGen`, `FC_IoMapInputs`, `typeStation`,
`OB_Main`) validam limpo no MCP; falta criar a tag `%I1.3` no TIA, recompilar e testar a
**recuperação da rotação** (90°/180°) no PLCSIM.
