# Documentação de Tags — Estação Pick & Place

> Projeto SCL **S7-1500 (CPU 1518T-4 PN/DP)**, simulado em **FACTORY I/O v2.5.10 ↔
> S7-PLCSIM**. Convenções: nomes de tag em **inglês** (iguais ao FACTORY I/O),
> descrições em **português**, prefixos `i_`/`o_`/`s_`/`t_` no código, E-Stop em lógica
> **NF (fail-safe)**.
>
> **Fonte da verdade do endereçamento:** `DOCS/Tags_New Scene_Siemens
> S7-PLCSIM_2026-06-16-13-16-09.xml`. **Escopo do processo:** `DOCS/ESCOPO_PickPlace.md`.
> Manter este arquivo sincronizado com a cena e com as interfaces dos blocos.

---

## 1. Convenções de polaridade (FACTORY I/O)

| Tipo de botão | Lógica | Em repouso | Acionado |
|---|---|---|---|
| **Start** (`%I0.6`) | NA (NO) | `FALSE` | `TRUE` |
| **Reset** (`%I0.4`) | NA (NO) | `FALSE` | `TRUE` (pulso → `R_TRIG`) |
| **Stop** (`%I0.7`) | **NF (NC)** | `TRUE` | `FALSE` |
| **Emergency Stop** (`%I0.3`) | **NF (NC)** | `TRUE` | `FALSE` |

> Em `Stop`/`EStop` a lógica é **fail-safe**: `FALSE` = comando ativo **ou** fio rompido →
> a máquina vai a estado seguro. ✅ **NC/NO confirmados** pela doc dos componentes
> (`Componentes_FactoryIO.md`); resta validar empiricamente no PLCSIM.

---

## 2. Entradas digitais (`%I`)

| Tag (FACTORY I/O) | Endereço | Tipo | Lógica | Descrição |
|---|---|---|---|---|
| `Emergency Stop 0` | `%I0.3` | Bool | **NF** | Emergência geral — `FALSE` = emergência/fio rompido |
| `Reset Button 0` | `%I0.4` | Bool | NA | Reset de máquina/alarmes/erros (**pulso**, `R_TRIG`) |
| `Sensor_caixa` | `%I0.5` | Bool | NA | Sensor **retrorreflexivo** na esteira **M1**: `TRUE`=feixe interrompido (caixa presente); borda de descida = caixa passou. **Espelhado** em `StationData.Station.Sts.SensorBox` via `FC_IoMapInputs` |
| `Start Button 0` | `%I0.6` | Bool | NA | Botão **Liga** |
| `Stop Button 0` | `%I0.7` | Bool | **NF** | Botão **Desliga** — `FALSE` = pressionado |
| `Two-Axis Pick & Place 0 (Rotating)` | `%I1.0` | Bool | NA | Braço em rotação (feedback de movimento) |
| `Two-Axis Pick & Place 0 (Item Detected)` | `%I1.1` | Bool | NA | Caixa detectada na ventosa/posição de pega |
| `Two-Axis Pick & Place 0 (Gripper Rotating)` | `%I1.2` | Bool | NA | Gripper em rotação (feedback) |
| `Inductive Sensor 0` | `%I1.3` | Bool | NA | Braço na orientação de casa (home) — `TRUE` = braço virado p/ M1. **Espelhado** em `StationData.Station.Sts.RotHome` via `FC_IoMapInputs` (tag `i_RotHome`). Usado para referenciamento rotacional (homing) após falha |

---

## 3. Entradas analógicas (`%ID`, Real — feedback em Volts)

| Tag | Endereço | Tipo | Faixa | Descrição |
|---|---|---|---|---|
| `Two-Axis Pick & Place 0 X Position (V)` | `%ID30` | Real | 0–10 V | Posição atual do eixo **X** (curso 1,125 m) |
| `Two-Axis Pick & Place 0 Z Position (V)` | `%ID34` | Real | 0–10 V | Posição atual do eixo **Z** (curso 0,625 m) |

> 0 V = início do curso, 10 V = fim do curso. Converter para mm/posição lógica com
> `NORM_X`/`SCALE_X` se necessário. Comparar com o setpoint para gerar "em posição"
> (tolerância + debounce).

---

## 4. Saídas digitais (`%Q`)

| Tag | Endereço | Tipo | Descrição |
|---|---|---|---|
| `Reset Button 0 (Light)` | `%Q0.3` | Bool | Luz do botão **Reset** (acende quando há condição a rearmar) |
| `Stack Light 0 (Red)` | `%Q0.4` | Bool | Torre — **vermelho** (emergência: pisca rápido) |
| `Stack Light 0 (Green)` | `%Q0.5` | Bool | Torre — **verde** (rodando: fixo) |
| `Stack Light 0 (Yellow)` | `%Q0.6` | Bool | Torre — **amarelo** (parado: pisca lento) |
| `Start Button 0 (Light)` | `%Q0.7` | Bool | Luz do botão **Liga** (acesa em RODANDO) |
| `Stop Button 0 (Light)` | `%Q1.0` | Bool | Luz do botão **Desliga** (acesa em PARADO) |
| `Two-Axis Pick & Place 0 (Grab)` | `%Q1.1` | Bool | **Vácuo** (ventosa) — `TRUE` = sugando |
| `Two-Axis Pick & Place 0 Rotate CW` | `%Q1.2` | Bool | Rotaciona **braço horário** (incrementos de 90°) |
| `Two-Axis Pick & Place 0 Gripper CW` | `%Q1.3` | Bool | Rotaciona **gripper horário** |
| `Two-Axis Pick & Place 0 Rotate CCW` | `%Q1.4` | Bool | Rotaciona **braço anti-horário** |
| `Two-Axis Pick & Place 0 Gripper CCW` | `%Q1.5` | Bool | Rotaciona **gripper anti-horário** |

> ⚠️ **Exclusão mútua:** `Rotate CW`/`Rotate CCW` e `Gripper CW`/`Gripper CCW` **nunca**
> energizados simultaneamente (intertravar no código).
>
> ℹ️ **Escrita:** todas as saídas digitais são escritas via `FC_IoMapOutputs` no fim do scan (ver
> §6.2). Luzes são repassadas sem máscara; rotação, vácuo e gripper são mascarados em estado seguro.

---

## 5. Saídas analógicas (`%QD`, Real — comando em Volts)

| Tag | Endereço | Tipo | Faixa | Descrição |
|---|---|---|---|---|
| `M1` | `%QD30` | Real | 0–10 V | **Esteira de entrada** — velocidade (0 = parada) |
| `M2` | `%QD34` | Real | 0–10 V | **Esteira de saída** — velocidade (0 = parada) |
| `Two-Axis Pick & Place 0 X Set Point (V)` | `%QD38` | Real | 0–10 V | Setpoint de posição do eixo **X** |
| `Two-Axis Pick & Place 0 Z Set Point (V)` | `%QD42` | Real | 0–10 V | Setpoint de posição do eixo **Z** |

> **M1/M2 são analógicas:** "ligar" = escrever a velocidade de regime (tensão a definir);
> "desligar" = escrever `0.0`. Não são bits on/off.
>
> ℹ️ **Escrita:** M1/M2 são mascarados em estado seguro (→ 0.0 V); setpoints de eixo (X/Z) são
> repassados sem máscara (já congelados pelo `FB_AxisPos`). Todas via `FC_IoMapOutputs` (ver §6.2).

---

## 6. Mapa de endereços (resumo)

| Faixa | Direção | Conteúdo |
|---|---|---|
| `%I0.3 – %I0.7` | Entrada digital | Emergência, Reset, Sensor_caixa, Start, Stop |
| `%I1.0 – %I1.3` | Entrada digital | Feedbacks do robô (Rotating, Item Detected, Gripper Rotating, Rot Home) |
| `%ID30`, `%ID34` | Entrada analógica | Posição X, Posição Z (Real, V) |
| `%Q0.3 – %Q1.0` | Saída digital | Luzes (botões + torre) |
| `%Q1.1 – %Q1.5` | Saída digital | Vácuo, Rotate CW/CCW, Gripper CW/CCW |
| `%QD30`, `%QD34` | Saída analógica | M1, M2 (velocidade, Real, V) |
| `%QD38`, `%QD42` | Saída analógica | Setpoint X, Setpoint Z (Real, V) |

> Bytes de entrada digital usados: `%IB0` (bits 3–7) e `%IB1` (bits 0–3).
> Bytes de saída digital usados: `%QB0` (bits 3–7) e `%QB1` (bits 0–5).

### 6.1 Roteamento centralizado de entradas (`FC_IoMapInputs`)

**Todas as entradas físicas** (`%I0.3–%I1.3`, `%ID30`, `%ID34`) são lidas num **ponto único**
no início do scan: a **função `FC_IoMapInputs`** (chamada no começo do `OB_Main`). Esta FC:

- **Lê os bits/valores brutos** das entradas físicas (sem inversão, sem condicional, sem máscara);
- **Escreve para `StationData.Station`** via `VAR_IN_OUT`:
  - `Cmd.*` (EStop, Stop, Start, Reset) — **cópia crua, NF/NA preservados**;
  - `Sts.*` (Rotating, ItemDetected, RotHome, SensorBox) — espelhos de feedback;
  - `Sts.AxisX.PV`, `Sts.AxisZ.PV` — posições (conversão `Real→LReal`).

**Garantias de segurança:** cópia fiel dos sinais de emergência (`%I0.3 EStop`, `%I0.7 Stop`),
nenhuma inversão ou condicionalidade aqui (a interpretação NF e o latch são exclusivos do
`FB_MachineMode`). Assim, a máquina **nunca esconde/atrasa uma emergência**.

**Impacto:** não há "lógica de entrada" espalhada pelo código; toda mudança em endereços
`%I`/`%ID` é feita aqui, com sincronização automática para o DB de dados.

### 6.2 Roteamento centralizado de saídas (`FC_IoMapOutputs`)

**Todas as saídas físicas** (`%Q0.3–%Q1.5`, `%QD30/34/38/42`) são **escritas num ponto único** no
fim do scan (após cálculos de processo): a função `FC_IoMapOutputs` (chamada no final do `OB_Main`).
Esta FC é a **última barreira fail-safe** de hardware, implementando:

**Máscara de estado seguro** (`i_SafeState` = `TRUE` → emergência/parado/falha):
- **Zeragem de processo:** `M1:=0.0`, `M2:=0.0`, `Grab:=FALSE`, `RotCW/RotCCW:=FALSE`.
- **Sinalização (luzes) NÃO mascarada:** `ResetLite`, `Red`, `Green`, `Yellow`, `StartLite`,
  `StopLite` são repassadas **sem filtro** (precisam indicar emergência/parado; zerar a torre em
  emergência cairia em anti-fail-safe).
- **Setpoints de eixo (X/Z) NÃO mascarados:** `FB_AxisPos` já congela o SP em sua própria saída;
  o FC só repassa. Forçar SP=0 V em emergência mandaria o eixo correr para zero (movimento
  perigoso) — incorreto.

**Exclusão mútua de rotação:** `RotCW` e `RotCCW` **nunca energizados simultaneamente** (o FC
valida: conflito → ambos FALSE, estado seguro).

**Fontes das saídas (assimetria vs. FC_IoMapInputs):**
- **VAR_INPUT (vêm direto dos FBs, repassados pelo OB):** as 6 luzes (`i_Red`, `i_Green`,
  `i_Yellow`, `i_ResetLite`, `i_StartLite`, `i_StopLite`) via `FB_MachineMode`, mais
  `i_RotCW`/`i_RotCCW` via `FB_PickPlaceSeq`. São transitórios/derivados de `Mode` — sem campo
  permanente no DB.
- **DB (`io_Station.Sts.*`):** `M1Speed`, `M2Speed`, `VacuumOn`, `AxisX.SP`, `AxisZ.SP`.
  Já existem no schema; são estado de processo que a HMI enxerga. O FC lê, converte `LReal→Real`
  (estreitamento: tensões 0–10 V cabem em Real), e escreve `%QD30/34/38/42`.

**Garantias de segurança:**
1. Em `i_SafeState`: M1/M2/Grab/RotCW/RotCCW zerados mesmo se um FB a montante falhar em
   auto-proteger.
2. Gripper (`o_GripCW`/`o_GripCCW`) intertravado: **sempre FALSE** (não usado no projeto).
3. **Sem inversion lógica** aqui: cópia fiel dos sinais brutos dos FBs; a semântica
   (E-Stop NF, máscara condicional) é gerenciada pelos FBs.

**Impacto:** todas as saídas físicas mudam num ponto único, no final do ciclo. Isolamento total do
endereçamento `%Q`/`%QD`. Garantia fail-safe mesmo com falha isolada de um FB intermediário.

---

## 7. Sinalização (torre + luzes de botão)

| Condição (estado da máquina) | Verde | Amarelo | Vermelho | Luz Liga | Luz Desliga | Luz Reset |
|---|---|---|---|---|---|---|
| **RODANDO** | **fixo** | — | — | aceso | — | — |
| **PARADO** (Stop) | — | **pisca lento** (~1 Hz) | — | — | aceso | pisca se há falha |
| **EMERGÊNCIA** | — | — | **pisca rápido** (~3 Hz) | — | — | pisca se há falha |
| **FALHA** | — | — | **pisca lento** (~1 Hz) | — | aceso | **pisca** |

> Luz de Reset (`%Q0.3`, azul IEC): **pisca** enquanto houver **falha/emergência latcheada a
> rearmar**; apaga após reset bem-sucedido. Pisca gerado no PLC (byte de clock ou TON/TOF):
> lento ~1 Hz, rápido ~3 Hz.

---

## 8. Posições e setpoints (eixos X/Z)

> Valores **iniciais** (calibrar no PLCSIM). Convenção do Z: **maior tensão = mais descido**
> (0 V = topo, 10 V = fundo).

| Parâmetro | Valor inicial | Observação |
|---|---|---|
| `X_pick` (pega) | **7,7 V** (≈ 0,866 m) | dado — centro da mesa, ponto de pega sobre M1 |
| `X_place` (depósito) | **6,8 V** (≈ 0,765 m) | dado — ponto de depósito sobre M2 |
| `X_home` (recolhido) | **0,0 V** | retração total (livre p/ rotacionar) |
| `Z_up` (repouso/subido) | **0,0 V** | Z livre p/ mover X e rotacionar |
| `Z_place` (depósito) | **7,0 V** | descida p/ depositar a caixa em M2 |
| `Z_pick` (pega) | **via `Item Detected`** | descida para no acionamento do sensor; limite de segurança ≈ **8,0 V** |
| Tolerância de posição | **0,1 V** | `ABS(SP − PV) ≤ tol` + debounce p/ "em posição" |
| Debounce "em posição" | **T#200ms** | estabilização antes de confirmar |
| Velocidade M1 / M2 | **5,0 V** (~50 %) | tensão de regime das esteiras (0 = parada) |
| Delay parada M1 | **T#500ms** | da borda de descida do `Sensor_caixa` até parar M1 |
| Pisca lento / rápido | **1 Hz / 3 Hz** | amarelo (parado) / vermelho (emergência) e luz Reset |

> Curso físico: X = 1,125 m, Z = 0,625 m; velocidade do braço/picker = 2 m/s; rotação do
> braço em **incrementos de 90°** (180° = dois incrementos, monitorar `Rotating`).

---

## 9. Notas de engenharia

- **Nomes simbólicos das tags de PLC (TIA "Tag table_1", confirmados):** os nomes da coluna
  "Tag (FACTORY I/O)" deste documento são as **tags de PLC reais** no TIA Portal (importadas do
  XML `Tags_New Scene_..._2026-06-16-13-16-09.xml`). No SCL, referenciá-las **entre aspas
  duplas** por conterem espaços/`&`/`()`, ex.: `"Start Button 0"`, `"Emergency Stop 0"`,
  `"Two-Axis Pick & Place 0 (Rotating)"`, `"Stack Light 0 (Red)"`, `"M1"`,
  `"Two-Axis Pick & Place 0 X Position (V)"`. O `OB_Main` liga essas tags ao `FC_IoMapInputs`
  (entradas) e ao `FC_IoMapOutputs` (saídas). Os **DBs de instância** dos FBs (ex.:
  `"FB_MachineMode_DB"`, `"FB_PickPlaceSeq_DB"`) são criados no TIA e referenciados na chamada.
- **Leitura centralizada de E/S:** `FC_IoMapInputs` (stateless) roteia **todas** as entradas
  (`%I`/`%ID`) para `StationData.Station` no início de cada ciclo; `FC_IoMapOutputs` escreve
  as saídas (`%Q`/`%QD`) ao final (após cálculos e máscara de segurança). Isolamento total do
  endereçamento físico.
- **Comandos de operador:** Liga/Desliga/Emergência/Reset são entradas físicas
  (`%I0.6`/`%I0.7`/`%I0.3`/`%I0.4`); Reset é pulso (`R_TRIG`).
- **Escala analógica:** posições e velocidades são tensões 0–10 V; usar `NORM_X`/`SCALE_X`
  + `LIMIT` para converter V ↔ unidade de engenharia.
- **Intertravamento de movimento (anticolisão):** rotacionar só com Z subido e X em home;
  mover X só com Z subido; não comandar eixo durante `Rotating`. **Gripper não utilizado**
  (`Gripper CW/CCW` ficam `FALSE`). Ver intertravamentos no `ESCOPO_PickPlace.md` / `CLAUDE.md`.
- **Pega (anti‑esmagamento):** na descida do Z, ao acionar `Item Detected` (`%I1.1`), parar
  a descida e ligar o vácuo (`Grab`) no mesmo instante.
- **Estado seguro:** em EMERGÊNCIA/PARADO → `M1:=0`, `M2:=0`, `Grab:=FALSE`, comandos de
  rotação desligados, sem novo setpoint de eixo.
- **Artefatos criados no TIA Portal** (não existem como `.scl` no repo): as **tags de PLC**
  (importadas do XML do FACTORY I/O) e os **DBs de instância** dos FBs.
- **Rotação por pulso:** `Rotate CW/CCW` é **por borda — 1 pulso = 90°** (o braço para no
  detente); **180° = 2 pulsos** no mesmo sentido, contando quedas de `Rotating` (`%I1.0`).
- **A validar no commissioning (§9.2 do escopo):** valores exatos dos setpoints, polaridade
  real NC/NO e largura mínima do pulso de rotação.

---

## 10. Mapa de tags da IHM (Modo MANUAL + WinCC)

> **Fase planejada — não implementado.** Blueprint do `scl-architect` (2026-06-20).
> Painel **SIMATIC TP1500 Comfort** (6AV2124-0QC24-1AX0; 15.6" touch 1366×768), projetado
> em **WinCC (TIA Portal)**, conecta via **PROFINET → CPU 1518T**. As tags abaixo são **simbólicas**
> do `StationData` — **NOT physical I/O** (`%I`/`%Q`/`%ID`/`%QD`). A IHM escreve/lê via
> binding de tags no WinCC, sem criar novos endereços físicos.
>
> **Convenção:** R = read (IHM lê), W = write (IHM escreve), RW = ambos.

### 10.1 Tags de Comando (IHM → PLC)

| Campo no `StationData.Station.Cmd` | Tipo | Dir | Descrição |
|---|---|---|---|
| `Start` | Bool | W | Botão "Liga" na tela — pulso (borda via `R_TRIG` no PLC) |
| `Stop` | Bool | W | Botão "Desliga" na tela — NF (FALSE = parar) |
| `EStop` | Bool | W | Botão "Emergência" na tela — NF (FALSE = emergência); **reforça o E-Stop físico**, não o substitui |
| `Reset` | Bool | W | Botão "Reset" na tela — pulso (borda via `R_TRIG`) |
| `AutoMode` | Bool | W | Seletor AUTO/MANUAL: `TRUE` = AUTO, `FALSE` = MANUAL |

> ⚠️ **E-Stop físico (`%I0.3`) tem prioridade máxima:** E-Stop em tela é funcional (conforto),
> mas E-Stop **físico NF** `%I0.3` é a parada de segurança. Em caso de divergência, físico vence.

### 10.2 Tags de Comando Manual (IHM → PLC — apenas em modo MANUAL)

| Campo no `StationData.Station.Cmd.Man` | Tipo | Dir | Descrição |
|---|---|---|---|
| `M1Run` | Bool | W | Jog esteira M1 — while pressionado (sem acúmulo de caixa) |
| `M2Run` | Bool | W | Jog esteira M2 — while pressionado |
| `XToPick` | Bool | W | Mover eixo X para `Cfg.X_pick` (pulso ou nível, conforme UX) |
| `XToHome` | Bool | W | Mover eixo X para `Cfg.X_home` (retração) |
| `XToPlace` | Bool | W | Mover eixo X para `Cfg.X_place` (depósito) |
| `ZToUp` | Bool | W | Mover eixo Z para `Cfg.Z_up` (repouso) |
| `ZToPlace` | Bool | W | Mover eixo Z para `Cfg.Z_place` (depósito) |
| `RotCW` | Bool | W | Girar braço 90° horário (pulso) — acumula para 180° |
| `RotCCW` | Bool | W | Girar braço 90° anti-horário (pulso) |
| `RotHome` | Bool | W | Referenciar rotação — voltar p/ casa (orientação M1) |
| `VacOn` | Bool | W | Ligar vácuo (Grab) |
| `VacOff` | Bool | W | Desligar vácuo |

> **Jog de eixos** é por **posições predefinidas** (não rampa contínua). Esteiras são **jog puro**
> (while pressionado = liga; solta = 0 V). Rotação é por **pulso** (1 pulso = 90°).
> **Intertravamentos garantem geometria segura:** jog de eixo rejeitado se Z não estiver up ou
> Rotating ativo; descida do Z bloqueada sem Item Detected anti-esmagamento.

### 10.3 Tags de Parametrização (IHM ↔ PLC — calibração)

| Campo no `StationData.Station.Cfg` | Tipo | Dir | Descrição |
|---|---|---|---|
| `Enabled` | Bool | RW | Habilita ciclo AUTO (sempre consultado; calibração de startup) |
| `X_pick` | LReal | RW | Setpoint X de pega (V) — inicial 7,7 |
| `X_place` | LReal | RW | Setpoint X de depósito (V) — inicial 6,8 |
| `X_home` | LReal | RW | Setpoint X recolhido (V) — inicial 0,0 |
| `Z_up` | LReal | RW | Setpoint Z repouso/subido (V) — inicial 0,0 |
| `Z_place` | LReal | RW | Setpoint Z depósito (V) — inicial 7,0 |
| `Z_pickLimit` | LReal | RW | Limite de descida na pega (V) — proteção — inicial 8,0 |
| `PosTol` | LReal | RW | Tolerância "em posição" (V) — inicial 0,1 |
| `PosDebounce` | Time | RW | Debounce estabilização "em posição" — inicial T#200ms |
| `ConvSpeed` | LReal | RW | Velocidade regime esteiras (V) — inicial 5,0 |
| `M1StopDelay` | Time | RW | Atraso parada M1 após sensor (ms) — inicial T#500ms |
| `SeqStepTimeout` | Time | RW | Timeout passo sequência → FALHA — inicial T#30s |
| `ClkSlowHz` | LReal | RW | Frequência pisca lento (Hz) — inicial 1,0 |
| `ClkFastHz` | LReal | RW | Frequência pisca rápido (Hz) — inicial 3,0 |

> **Calibração em runtime:** ajustar sem recompilar. Valores têm **start values** no TIA Portal
> (DB instância `StationData`); alterações na tela persistem apenas na sessão (RAM).
> Para persistir, gravar em EEPROM via hardware config da CPU ou bloco `FC_SaveRestore`.

### 10.4 Tags de Status (PLC → IHM — leitura)

| Campo no `StationData.Station.Sts` | Tipo | Dir | Descrição |
|---|---|---|---|
| `Mode` | Int | R | Estado da máquina: 0=PARADO, 1=RODANDO, 2=EMERGÊNCIA, 3=FALHA |
| `ManActive` | Bool | R | `TRUE` = modo MANUAL ativo (espelho de `FB_MachineMode.o_RunManual`); verde piscando lento |
| `Step` | Int | R | Passo atual sequência AUTO (0..16); em MANUAL fica 0 |
| `AxisX.PV` | LReal | R | Posição atual X (V) — feedback analógico |
| `AxisX.SP` | LReal | R | Setpoint X atual (V) — valor sendo perseguido |
| `AxisX.InPos` | Bool | R | `TRUE` = X em posição (dentro tolerância + debounce) |
| `AxisZ.PV` | LReal | R | Posição atual Z (V) |
| `AxisZ.SP` | LReal | R | Setpoint Z atual (V) |
| `AxisZ.InPos` | Bool | R | `TRUE` = Z em posição |
| `Rotating` | Bool | R | `TRUE` = braço em rotação (feedback `%I1.0`) |
| `RotHome` | Bool | R | `TRUE` = braço na orientação home (virado p/ M1, feedback `%I1.3`) |
| `VacuumOn` | Bool | R | `TRUE` = vácuo ligado (Grab ativo) |
| `M1Speed` | LReal | R | Velocidade M1 (V) — 0 = parada |
| `M2Speed` | LReal | R | Velocidade M2 (V) |
| `BoxAtPick` | Bool | R | **Reservado** — seria OK da esteira (caixa posicionada); ainda não integrado |
| `ItemDetected` | Bool | R | `TRUE` = caixa detectada na ventosa (feedback `%I1.1`); anti-esmagamento na descida |
| `SensorBox` | Bool | R | `TRUE` = sensor M1 retrorreflexivo acionado (caixa presente, feedback `%I0.5`) |
| `Fault` | Bool | R | `TRUE` = falha ativa (travada, requer reset) |
| `FaultCode` | Int | R | Código de falha: 0=ok, 1=timeout X/homing, 2=timeout Z, 3=timeout rotação, 4=Z no limite sem ItemDet (sem caixa), 5=reservado (aposentado) |
| `ManRejected` | Int | R | Código do **primeiro** jog bloqueado do scan (intertravamento): **0**=nenhum; **1**=conflito de jog X (>1 botão X simultâneo); **2**=jog X bloqueado por geometria (Z não up / Rotating); **3**=descida de Z bloqueada (X fora de estação X_pick/X_place / Rotating); **4**=conflito de jog Z (ZToUp+ZToPlace simultâneos); **5**=rotação bloqueada (geometria / exclusão mútua / homing sem Z up) |
| `CycleCount` | DInt | R | Contador de ciclos concluídos (incrementado ao fim do step final em AUTO) |

> **`ManRejected` é indicador de diagnóstico:** textos na tela ("Recolha Z antes de mover X",
> "X deve estar em X_pick/X_place para descer Z", "Recolha Z antes de girar/referenciar", etc.)
> mapeados por este código. Reflete o **primeiro** bloqueio do scan e re-arma a 0 a cada scan.

### 10.5 Notas de integração WinCC

1. **Sem novos endereços físicos:** todos os campos acima são do `StationData` (DB global).
   I/O física (`%I`/`%Q`/`%ID`/`%QD`) permanece **inalterada** (seções 2–5).

2. **Binding de tags no WinCC:**
   - Leitura: IHM → PLC via **input fields** ligados a `StationData.Station.Cmd.Man.*`,
     `StationData.Station.Cmd.AutoMode`, etc.
   - Escrita: PLC → IHM via **gauges/alarmes** ligados a `StationData.Station.Sts.*`.
   - **Connection:** device driver S7-PLCSIM ou PROFINET S7 (1500) no WinCC Runtime,
     apontando para a CPU via IP.

3. **Safety:**
   - E-Stop **físico** `%I0.3` é **primário** (NF, direct wire via handshake PLCSIM).
   - E-Stop **em tela** é conforto; entrada do IHM sofre latching igual (não é "autoreset").
   - Manual mode **está sujeito a intertravamentos** (guardas centralizadas em `FC_Interlocks`,
     lidas pelo `FB_ManualControl`); jog rejeitado não escreve SP/comando.

4. **Sinalização em tela:**
   - `Sts.Mode` → exibir estado (cor: verde=RODANDO, amarelo=PARADO, vermelho=EMERGÊNCIA,
     outros=FALHA).
   - `Sts.ManRejected` → avisar rejeição de jog (ícone/banner/log).
   - `Sts.Fault` + `Sts.FaultCode` → diagnóstico (ex.: "Timeout movimento X").

---