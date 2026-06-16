# Referência — Componentes FACTORY I/O (comando e sensores)

> Documentação dos componentes genéricos do **FACTORY I/O** usados nesta cena, mapeados
> para as tags reais do projeto. Fonte: manual do FACTORY I/O. Complementa
> `DOCS/tags.md` (endereçamento) e `DOCS/ESCOPO_PickPlace.md` (processo).

---

## 1. Emergency Stop (botão de emergência)

Botão cogumelo vermelho, **não iluminado**, ação de duas posições (trigger).
**Tipo de contato: NC (normally closed).**

| Tag genérico | I/O | Tipo | Descrição |
|---|---|---|---|
| `Emergency Stop #` | Input | Bool | Emergência acionada |

- **Tag do projeto:** `Emergency Stop 0` → **`%I0.3`**.
- **Uso fail‑safe (NC):** em repouso o contato está fechado → sinal presente. Tratar
  **`FALSE` = emergência** (pressionado) **ou perda de sinal/fio rompido** → estado seguro,
  **latcheado**. ⚠️ Validar empiricamente no PLCSIM que o bit vai a `FALSE` ao pressionar.

---

## 2. Push Buttons (botoeiras iluminadas)

Botoeiras iluminadas, cores conforme **IEC 60204‑1:2016**. Ação **momentânea** (pulso) ou
alternada. Disponíveis: **Start**, **Reset**, **Stop (NC)** e genéricas NO/NC.

- **Start** e **Reset:** normalmente abertas (**NO**) → `TRUE` enquanto pressionadas.
- **Stop:** **normalmente fechada (NC)** → `TRUE` em repouso, `FALSE` quando pressionada.

| Tag genérico (momentâneo) | I/O | Tipo | Descrição |
|---|---|---|---|
| `Push Button #` | Input | Bool | Pressionado |
| `Push Button # (Light)` | Output | Bool | Luz liga/desliga |

**Mapeamento no projeto:**

| Função | Entrada | Lógica | Luz (saída) |
|---|---|---|---|
| Liga (Start) | `Start Button 0` `%I0.6` | NO | `Start Button 0 (Light)` `%Q0.7` |
| Reset | `Reset Button 0` `%I0.4` | NO (**pulso**, `R_TRIG`) | `Reset Button 0 (Light)` `%Q0.3` |
| Desliga (Stop) | `Stop Button 0` `%I0.7` | **NC** | `Stop Button 0 (Light)` `%Q1.0` |

### Cores recomendadas (IEC 60204‑1:2016, por ordem de preferência)
| Atuador | Cores | Notas |
|---|---|---|
| Start/On | Branco, Cinza, Preto ou **Verde** | — |
| Reset | **Azul**, Branco, Cinza ou Preto | justifica o "azul" do botão Reset no escopo |
| Stop/Off | Preto, Cinza ou Branco | Vermelho permitido se **não** próximo a botão de emergência |
| Condições anormais | **Amarelo** | ex.: interrupção de ciclo automático |

---

## 3. Sinalização luminosa

### 3.1 Stack Light (torre de sinalização) — usada no projeto

Torre de três cores (**vermelho, amarelo, verde**), indicador visual dos estados/processos
da máquina. Cada cor é uma saída Bool independente.

| Tag genérico | I/O | Tipo | Descrição |
|---|---|---|---|
| `Stack Light # (Red)` | Output | Bool | Liga/desliga |
| `Stack Light # (Yellow)` | Output | Bool | Liga/desliga |
| `Stack Light # (Green)` | Output | Bool | Liga/desliga |

- **Tags do projeto (`Stack Light 0`):** Vermelho `%Q0.4`, Amarelo `%Q0.6`, Verde `%Q0.5`.
- **Uso (ver §3.1 e §7 do escopo):** verde = **rodando** (fixo), amarelo = **parado /
  condição anormal** (pisca lento, recomendação IEC), vermelho = **emergência** (pisca
  rápido). O efeito de pisca é gerado no PLC (byte de clock ou TON/TOF); a saída do
  componente é apenas liga/desliga.

### 3.2 Light Indicator (sinaleiro de painel) — genérico

Sinaleiro de painel de uma cor, cores conforme IEC 60204‑1:2016. Saída Bool liga/desliga.
Não usado diretamente nesta cena (a torre acima cobre a sinalização), listado para
referência.

| Tag genérico | I/O | Tipo | Descrição |
|---|---|---|---|
| `Light Indicator #` | Output | Bool | Luz liga/desliga |

---

## 4. Retroreflective Sensor (sensor retrorreflexivo) + refletor

Requer **refletor** alinhado. Dois LEDs: verde = alinhado, amarelo = feixe **não**
interrompido. Detecta **sólidos**. Alcance **0–6 m**.

| Tag genérico | I/O | Tipo | Descrição |
|---|---|---|---|
| `Retroreflective Sensor #` | Input | Bool | Feixe de luz interrompido |

- **Tag do projeto:** `Sensor_caixa` → **`%I0.5`**.
- **Interpretação:** **`TRUE` = feixe interrompido = caixa presente** no sensor;
  **`FALSE` = feixe livre**.
- **"Caixa passou completamente"** = **borda de descida** (`TRUE → FALSE`, `F_TRIG`):
  a caixa saiu do feixe. Parar **M1** após **delay** nessa borda e liberar o Pick & Place
  (ver §4 do escopo).

---

## 5. Pontos do escopo resolvidos por esta referência

| Item (escopo §9 / §4) | Antes | Agora |
|---|---|---|
| Polaridade Emergency/Stop | a confirmar | **NC confirmado** (`FALSE` = acionado) — validar no PLCSIM |
| Polaridade Start/Reset | a confirmar | **NO confirmado** (`TRUE` = pressionado; Reset = pulso) |
| Tipo do `Sensor_caixa` | a confirmar | **Retrorreflexivo**: `TRUE`=caixa presente; borda de descida = passou |
| Cor da luz de Reset | "azul" | **alinhado à IEC** (Reset = azul preferencial) |

> Rotação confirmada **por borda** (1 pulso = 90°; 180° = 2 pulsos). A validar no
> commissioning (§9.2 do escopo): valores exatos dos setpoints e a polaridade real NC/NO.
