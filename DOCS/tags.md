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
| `Sensor_caixa` | `%I0.5` | Bool | NA | Sensor **retrorreflexivo** na esteira **M1**: `TRUE`=feixe interrompido (caixa presente); borda de descida = caixa passou |
| `Start Button 0` | `%I0.6` | Bool | NA | Botão **Liga** |
| `Stop Button 0` | `%I0.7` | Bool | **NF** | Botão **Desliga** — `FALSE` = pressionado |
| `Two-Axis Pick & Place 0 (Rotating)` | `%I1.0` | Bool | NA | Braço em rotação (feedback de movimento) |
| `Two-Axis Pick & Place 0 (Item Detected)` | `%I1.1` | Bool | NA | Caixa detectada na ventosa/posição de pega |
| `Two-Axis Pick & Place 0 (Gripper Rotating)` | `%I1.2` | Bool | NA | Gripper em rotação (feedback) |

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

---

## 6. Mapa de endereços (resumo)

| Faixa | Direção | Conteúdo |
|---|---|---|
| `%I0.3 – %I0.7` | Entrada digital | Emergência, Reset, Sensor_caixa, Start, Stop |
| `%I1.0 – %I1.2` | Entrada digital | Feedbacks do robô (Rotating, Item Detected, Gripper Rotating) |
| `%ID30`, `%ID34` | Entrada analógica | Posição X, Posição Z (Real, V) |
| `%Q0.3 – %Q1.0` | Saída digital | Luzes (botões + torre) |
| `%Q1.1 – %Q1.5` | Saída digital | Vácuo, Rotate CW/CCW, Gripper CW/CCW |
| `%QD30`, `%QD34` | Saída analógica | M1, M2 (velocidade, Real, V) |
| `%QD38`, `%QD42` | Saída analógica | Setpoint X, Setpoint Z (Real, V) |

> Bytes de entrada digital usados: `%IB0` (bits 3–7) e `%IB1` (bits 0–2).
> Bytes de saída digital usados: `%QB0` (bits 3–7) e `%QB1` (bits 0–5).

---

## 7. Sinalização (torre + luzes de botão)

| Condição (estado da máquina) | Verde | Amarelo | Vermelho | Luz Liga | Luz Desliga | Luz Reset |
|---|---|---|---|---|---|---|
| **RODANDO** | **fixo** | — | — | aceso | — | — |
| **PARADO** (Stop) | — | **pisca lento** (~1 Hz) | — | — | aceso | pisca se há falha |
| **EMERGÊNCIA** | — | — | **pisca rápido** (~3 Hz) | — | — | pisca se há falha |

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