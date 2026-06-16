# Escopo — Estação Pick & Place com Esteiras (FACTORY I/O)

> **Cena:** `New Scene` exportada do **FACTORY I/O v2.5.10** → **Siemens S7‑PLCSIM**
> (export em `DOCS/Tags_New Scene_Siemens S7-PLCSIM_2026-06-16-13-16-09.xml`).
> **CPU alvo:** S7‑1500 1518T‑4 PN/DP. **Convenções do projeto:** nomes de tag em
> **inglês**, comentários/descrições em **português**, prefixos `i_`/`o_`/`s_`/`t_`,
> lógica de segurança **fail‑safe (NF)**.
>
> Este é o **subsistema novo** (estação de paletização/transferência), **independente**
> dos subsistemas anteriores do repositório (20 motores, 2 reguladores ITV). Ele tem seu
> próprio conjunto de E/S, abaixo.

---

## 1. Descrição geral do processo

Uma esteira de entrada (**M1**) traz caixas. Quando uma caixa passa completamente pelo
**Sensor_caixa**, a esteira para (após um atraso) e libera o **Two‑Axis Pick & Place**,
que pega a caixa numa posição da mesa, gira 180°, deposita do outro lado sobre a esteira
de saída (**M2**), e retorna para aguardar a próxima caixa. Em paralelo, M1 volta a correr
para já trazer a caixa seguinte (processo **pipelinado**).

A máquina tem comandos de **Liga / Desliga / Emergência / Reset** com sinalização por
**torre luminosa** (vermelho/verde/amarelo) e **luzes nos botões**.

---

## 2. Mapa de I/O

### 2.1 Entradas digitais (`%I`)

| Tag (FACTORY I/O) | Endereço | Convenção | Função |
|---|---|---|---|
| `Emergency Stop 0` | `%I0.3` | **NF** (NC — `FALSE` = pressionado/emergência) | Emergência geral |
| `Reset Button 0` | `%I0.4` | NA (NO — `TRUE` = pressionado) | Reset de máquina/alarmes (**pulso**, usar `R_TRIG`) |
| `Sensor_caixa` | `%I0.5` | NA | Detecta caixa passando na esteira M1 |
| `Start Button 0` | `%I0.6` | NA | Botão **Liga** |
| `Stop Button 0` | `%I0.7` | **NF** (NC — `FALSE` = pressionado) | Botão **Desliga** |
| `Two-Axis Pick & Place 0 (Rotating)` | `%I1.0` | NA | Braço em rotação (feedback) |
| `Two-Axis Pick & Place 0 (Item Detected)` | `%I1.1` | NA | Caixa detectada no gripper/posição |
| `Two-Axis Pick & Place 0 (Gripper Rotating)` | `%I1.2` | NA | Gripper em rotação (feedback) |

> **Convenção FACTORY I/O:** botões **Start/Reset** são **NA** (`TRUE` enquanto pressionado);
> **Stop/Emergency Stop** são **NF/NC** (`TRUE` em repouso, `FALSE` quando pressionado).
> Isso já casa com a lógica fail‑safe do projeto: `Stop`/`EStop` em **falso** = comando
> ativo (ou fio rompido) → estado seguro. **Confirmar a polaridade no FACTORY I/O** antes
> de codar.

### 2.2 Entradas analógicas (`%ID`, Real — feedback em Volts)

| Tag | Endereço | Faixa | Função |
|---|---|---|---|
| `... X Position (V)` | `%ID30` | 0–10 V | Posição atual do eixo **X** (curso 1,125 m) |
| `... Z Position (V)` | `%ID34` | 0–10 V | Posição atual do eixo **Z** (curso 0,625 m) |

### 2.3 Saídas digitais (`%Q`)

| Tag | Endereço | Função |
|---|---|---|
| `Reset Button 0 (Light)` | `%Q0.3` | Luz do botão Reset (o texto chama de "azul") |
| `Stack Light 0 (Red)` | `%Q0.4` | Torre — **vermelho** |
| `Stack Light 0 (Green)` | `%Q0.5` | Torre — **verde** |
| `Stack Light 0 (Yellow)` | `%Q0.6` | Torre — **amarelo** |
| `Start Button 0 (Light)` | `%Q0.7` | Luz do botão Liga (verde) |
| `Stop Button 0 (Light)` | `%Q1.0` | Luz do botão Desliga (vermelho) |
| `... (Grab)` | `%Q1.1` | **Vácuo** (ventosa) |
| `... Rotate CW` | `%Q1.2` | Rotaciona braço **horário** (incrementos de 90°) |
| `... Gripper CW` | `%Q1.3` | Rotaciona gripper horário |
| `... Rotate CCW` | `%Q1.4` | Rotaciona braço **anti‑horário** |
| `... Gripper CCW` | `%Q1.5` | Rotaciona gripper anti‑horário |

### 2.4 Saídas analógicas (`%QD`, Real — comando em Volts)

| Tag | Endereço | Faixa | Função |
|---|---|---|---|
| `M1` | `%QD30` | 0–10 V (velocidade) | **Esteira de entrada** (traz caixas até o ponto de pega) |
| `M2` | `%QD34` | 0–10 V (velocidade) | **Esteira de saída** (evacua a caixa depositada) |
| `... X Set Point (V)` | `%QD38` | 0–10 V | Setpoint de posição do eixo **X** |
| `... Z Set Point (V)` | `%QD42` | 0–10 V | Setpoint de posição do eixo **Z** |

> **M1/M2 são analógicas (Real):** "ligar" = escrever uma velocidade (ex.: tensão de
> regime, a definir); "desligar" = escrever `0.0`. Não são bits on/off.

---

## 3. Estados da máquina (lógica principal)

Máquina de estados de **modo de operação** (independente da sequência do robô):

| Estado | Como entra | Saídas / efeito |
|---|---|---|
| **EMERGÊNCIA** | `EStop` pressionado (`%I0.3 = FALSE`) | Desliga **tudo** (M1, M2, vácuo, movimento); torre **vermelha piscando rápido**; trava (latch) até rearmar emergência **+** pulso de Reset |
| **PARADO** | `Stop` pressionado (`%I0.7 = FALSE`) ou pós‑reset | Desliga tudo; torre **amarela piscando lento**; luz do botão Desliga acesa |
| **RODANDO** | `Start` (`%I0.6`↑) a partir de PARADO, sem emergência/falha | Liga **M1 e M2**; torre **verde fixa**; luz do botão Liga acesa; habilita a sequência do robô |
| **FALHA** *(opcional)* | erro de processo (ex.: caixa não detectada, timeout de eixo) | Igual a PARADO + indicação; sai com Reset |

**"Desligar tudo"** = `M1 := 0`, `M2 := 0`, `Grab := FALSE`, cancela comandos de rotação,
congela/segura os eixos (não comandar novo setpoint), e zera a sequência do robô para o
passo inicial.

### 3.1 Sinalização (torre + botões)

| Condição | Verde (torre) | Amarelo (torre) | Vermelho (torre) | Luz Liga | Luz Desliga | Luz Reset |
|---|---|---|---|---|---|---|
| Rodando | **fixo** | — | — | aceso | — | — |
| Parado (Stop) | — | **pisca lento** (~1 Hz) | — | — | aceso | pisca se há falha a rearmar |
| Emergência | — | — | **pisca rápido** (~3 Hz) | — | — | pisca se há falha a rearmar |

> **Pisca:** gerar por memória de clock (byte de clock da CPU) ou TON/TOF alternado.
> Sugestão: lento ≈ 1 Hz, rápido ≈ 3 Hz (a confirmar).

### 3.2 Botão/Luz de Reset

- **Reset é um pulso** (`R_TRIG` sobre `%I0.4`): rearma falhas/alarmes, destrava
  emergência (se já rearmada fisicamente) e leva a máquina ao estado **PARADO** limpo.
- Luz do botão Reset (`%Q0.3`, azul conforme IEC): **pisca enquanto houver falha/emergência
  latcheada a rearmar**, orientando o operador, e **apaga após o reset bem‑sucedido**.

---

## 4. Esteira e sensor (M1)

1. Em **RODANDO**, **M1** corre e leva as caixas até o fim da esteira.
2. **Sensor_caixa** (`%I0.5`) detecta a caixa. Quando a caixa termina de passar
   (borda de descida do sensor), inicia‑se um **atraso (TON)** e então **M1 para**,
   deixando a caixa posicionada no ponto de pega.
3. Com a caixa posicionada, envia‑se um **sinal de OK** (interno) liberando o ciclo do
   **Pick & Place**.
4. Durante o ciclo do robô, **M1 é religada** (passo da §5) para já trazer a próxima caixa,
   que será novamente parada pelo sensor — operação **pipelinada**.

> **Confirmado** (`Componentes_FactoryIO.md` §4): `Sensor_caixa` é **retrorreflexivo** —
> `TRUE` = feixe interrompido = caixa presente. Logo, "caixa passou completamente" = **borda
> de descida** (`TRUE → FALSE`, `F_TRIG`) + delay (TON) para parar M1. *Resta confirmar só
> se o ponto de pega fica logo após o sensor.*

---

## 5. Sequência do Two‑Axis Pick & Place

Liberada quando a máquina está **RODANDO** e há **OK da esteira** (caixa posicionada).
Cada passo só avança quando o anterior conclui (eixo **em posição** / rotação concluída /
delay cumprido). Estrutura de **máquina de estados (passo a passo)**.

### 5.1 Pegar (PICK)

A presença da caixa já está **garantida** pelo `Sensor_caixa` da esteira. O sensor
**`Item Detected`** (`%I1.1`), **fixo no picker**, atua como **anti‑esmagamento**: durante a
descida do Z, ao acionar significa que a caixa está próxima → **para a descida e liga o
vácuo no mesmo instante** (não desce mais para não amassar a caixa).

| # | Ação | Condição de avanço |
|---|---|---|
| 1 | Mover **X → 7,7 V** (centro da mesa, ponto de pega) | X em posição (±tolerância) |
| 2 | **Descer Z** em direção à caixa (comando Z p/ baixo, até o limite de segurança) | até **`Item Detected`** (`%I1.1`) = TRUE |
| 3 | Ao acionar `Item Detected`: **parar a descida** (segura Z na posição atual) **e ligar o vácuo** (`Grab`) | vácuo ligado |
| 4 | **Subir Z** (repouso) com a caixa presa pela ventosa | Z em posição |
| 5 | **Religar esteira M1** (traz a próxima caixa) | — |
| 6 | **Recuar X** (home) | X em posição |
| 7 | **Rotacionar 180° CW** = **2 pulsos** de `Rotate CW` (1 pulso = 90°) | 2º `Rotating` (`%I1.0`) caiu (= 180°) |

### 5.2 Colocar (PLACE)

| # | Ação | Condição de avanço |
|---|---|---|
| 8 | Mover **X → 6,8 V** (ponto de depósito sobre M2) | X em posição |
| 9 | **Pausar esteira M2** (caixa será depositada parada) | — |
| 10 | **Descer Z** (setpoint Z de depósito) | Z em posição |
| 11 | **Desligar vácuo** (`Grab := FALSE`) — solta a caixa; `Item Detected` → FALSE confirma | caixa liberada |
| 12 | **Subir Z** | Z em posição |
| 13 | **Religar esteira M2** (evacua a caixa depositada) | — |
| 14 | **Recolher X** (home) | X em posição |
| 15 | **Rotacionar 180° CCW** = **2 pulsos** de `Rotate CCW` (1 pulso = 90°) | 2º `Rotating` caiu (= 180°) |
| 16 | **Fim do ciclo** → aguarda próximo OK da esteira | — |

> **Posições/setpoints (Volts, range 0–10 V) — valores iniciais, calibrar no PLCSIM:**
> - X pega = **7,7 V** ≈ 0,866 m · X depósito = **6,8 V** ≈ 0,765 m · X home = **0,0 V**
> - Z repouso (subido) = **0,0 V** · Z depósito = **7,0 V** · Z pega = **via `Item Detected`**
>   (limite de descida de segurança ≈ **8,0 V**)
> - Convenção adotada: **maior tensão = mais descido** (0 V = topo, 10 V = fundo).
> - Tabela completa de parâmetros em `tags.md` §8.

---

## 6. Eixos X/Z — posicionamento analógico

- Os eixos são comandados por **setpoint de tensão** (`%QD38` X, `%QD42` Z) e realimentados
  por **posição em tensão** (`%ID30` X, `%ID34` Z). **Não usam Technology Objects / `MC_*`** —
  é posicionamento simples por comparação setpoint × feedback.
- **"Em posição"** = `ABS(Setpoint − Posição) ≤ tolerância` por um tempo de estabilização
  (ex.: tolerância ≈ 0,05–0,1 V; debounce com TON). Tolerância e tempo a calibrar.
- Velocidade do braço/picker = **2 m/s** (fixa no modelo). **Rotação por pulso (confirmado):**
  cada **borda de subida** de `Rotate CW`/`Rotate CCW` gira **exatamente 90°** e o braço para
  no detente; um novo pulso gira mais 90°. **Não varre continuamente** segurando o comando.
  - **Primitiva de 180°:** dar **2 pulsos** no mesmo sentido, cada um separado por uma queda
    de `Rotating` (`%I1.0`) — i.e.: pulso → espera `Rotating` subir e cair (90° feito) →
    pulso → espera cair de novo (180° feito). Encapsular num FB `FB_Rotate180(i_Trig, i_Dir,
    o_Busy, o_Done)` para isolar essa lógica da sequência.
- **Gripper não utilizado:** `Gripper CW/CCW` permanecem `FALSE`; `Gripper Rotating` ignorado.
- **Convenção do Z adotada:** **maior tensão = mais descido** (0 V = topo, 10 V = fundo).
  *Validar no sim.*

---

## 7. Intertravamentos (interlocks)

Lógica **standard, sem F‑CPU** — a segurança é responsabilidade do código. Prioridades de
cima para baixo (a regra de cima vence a de baixo no mesmo scan).

### 7.1 Segurança (prioridade máxima)

- **E‑Stop (`%I0.3 = FALSE`)** sobrepõe qualquer comando e força **estado seguro** em todos
  os blocos no mesmo scan: `M1:=0`, `M2:=0`, `Grab:=FALSE`, `Rotate CW/CCW:=FALSE`,
  `Gripper CW/CCW:=FALSE`, **sem novo setpoint de eixo**. Condição **latcheada**.
- **Stop (`%I0.7 = FALSE`)** leva a **PARADO** com as mesmas saídas desligadas (não latcheia
  falha, mas exige novo **Start** para voltar a RODANDO).
- **Fio rompido** em Stop/EStop (NF) = mesmo efeito do acionamento (**fail‑safe**).
- **Start inibido** enquanto **EMERGÊNCIA** ou **FALHA** estiver ativa — só após **Reset**
  (borda) com a emergência fisicamente rearmada.

### 7.2 Exclusão mútua de saídas

- `Rotate CW` ⊻ `Rotate CCW` — **nunca** energizados juntos (um inibe o outro).
- `Gripper CW`/`Gripper CCW` — **não utilizados** (mantidos `FALSE`).
- `M1`/`M2` só recebem velocidade > 0 em **RODANDO**.

### 7.3 Anticolisão mecânica (o mais crítico)

Antes de qualquer movimento, checar o estado dos demais eixos:

- **Rotacionar o braço só com `Z` em repouso (subido) E `X` recolhido (home).** Girar com o
  braço estendido ou Z abaixado pode colidir com esteiras / mesa / positioning bars.
- **Mover `X` só com `Z` subido** (não arrastar a caixa/picker pela mesa).
- **Não comandar `X` nem `Z`** enquanto `Rotating` (`%I1.0`) ou `Gripper Rotating` (`%I1.2`)
  estiver ativo — esperar a rotação concluir.
- **Descer `Z` só com `X` na posição‑alvo** (pega 7,7 V / depósito 6,8 V) já estabilizada
  ("em posição").

### 7.4 Handshake da sequência

- O ciclo do robô só **inicia** com: estado **RODANDO** + **OK da esteira** (caixa parada no
  `Sensor_caixa`, §4) — a presença da caixa fica **garantida** pelo sensor da esteira.
  O `Item Detected` (`%I1.1`) **não** é gate de início; é usado na descida do Z como
  anti‑esmagamento (§5.1).
- **Avanço passo a passo:** cada passo só libera o próximo após confirmar sua condição
  (em posição / rotação concluída / delay cumprido) — proibido "pular" estados.
- **Reinício após PARADO/EMERGÊNCIA:** a sequência volta ao **passo inicial** (não retoma no
  meio), evitando movimento inesperado no rearme.

### 7.5 Processo (vácuo e esteiras)

- **Vácuo:** ligar no instante em que `Item Detected` aciona durante a descida na pega
  (anti‑esmagamento, §5.1); desligar (soltar a caixa) **só** com `Z` na posição de depósito —
  nunca soltar a caixa no ar ou fora do ponto.
- **M1:** para ao detectar caixa (até o robô liberar); só religa no passo previsto
  (§5.1, passo 5).
- **M2:** pausada durante o depósito (§5.2, passos 9–13) para a caixa cair parada; religa
  para evacuar.

> Implementar estes intertravamentos nos FBs (`FB_PickPlaceSeq`, `FB_AxisPos`,
> `FB_MachineMode`, `FB_Conveyor`) e auditar com `/safety-check` antes de concluir.

---

## 8. Lista de comandos por botão (resumo dos requisitos 1–4)

1. **Liga** → luz verde do botão Liga + **verde fixo** na torre + liga esteiras **M1 e M2**
   (estado **RODANDO**).
2. **Desliga** → luz vermelha do botão Desliga + **amarelo piscando lento** na torre +
   **desliga tudo** (estado **PARADO**).
3. **Emergência** → **desliga tudo** + **vermelho piscando rápido** na torre
   (estado **EMERGÊNCIA**, latcheado).
4. **Reset** (pulso) → rearma máquina/alarmes/erros; a luz do botão Reset **pisca** enquanto
   houver falha a rearmar e apaga após o reset (ver §3.2).

---

## 9. Pontos em aberto / decisões a confirmar

### 9.1 Decisões fechadas

1. **M2 (esteira de saída):** corre por padrão em **RODANDO** (ligada junto com M1 no
   Start); é **pausada** no depósito (§5.2, passo 9) e **religada** no passo 13.
2. **`Item Detected` (`%I1.1`) = anti‑esmagamento:** a presença da caixa é garantida pelo
   `Sensor_caixa` da esteira. Durante a descida do Z, ao acionar `Item Detected` a caixa está
   próxima → **para a descida e liga o vácuo** (§5.1). Não há aborto por "caixa ausente".
3. **Luz do botão Reset (`%Q0.3`, azul IEC):** **pisca** enquanto houver falha/emergência
   latcheada a rearmar; apaga após o reset bem‑sucedido.
4. **Polaridade:** `Emergency Stop`/`Stop` = **NC** (`FALSE` = acionado/fio rompido);
   `Start`/`Reset` = **NO** (`TRUE` = pressionado). *Validar no PLCSIM.*
5. **Gripper não utilizado:** apenas rotação do braço (`Rotate CW/CCW`); `Gripper CW/CCW`
   ficam `FALSE`, `Gripper Rotating` ignorado.
6. **Rotação por pulso (confirmado):** `Rotate CW/CCW` é **por borda — 1 pulso = 90°** e o
   braço para no detente. **180° = 2 pulsos** no mesmo sentido (separados por queda de
   `Rotating`). Encapsular num FB `FB_Rotate180` (ver §6 e §10).
7. **Direção do Z:** **maior tensão = mais descido** (0 V = topo, 10 V = fundo).
8. **Setpoints iniciais** (X/Z, tolerância, velocidades, delays, pisca): valores propostos em
   §5 e em `tags.md` §8 — ajustáveis no commissioning.

### 9.2 A validar no PLCSIM (commissioning)

- Valores exatos: X home, Z depósito, limite de descida na pega, tolerância de posição,
  velocidade das esteiras, delays (parada de M1, estabilização) e taxas de pisca.
- Polaridade real NC/NO dos botões.
- Se o ponto de pega fica logo após o `Sensor_caixa`.
- Largura mínima do pulso de `Rotate CW/CCW` para o modelo registrar a borda (1 scan basta?).

---

## 10. Sugestão de arquitetura de blocos (a detalhar quando começar)

Seguindo o padrão do projeto (UDT → DB → FB chamado por OB), uma divisão possível:

- **`OB_Main` (OB1)** — orquestra: lê comandos, roda a máquina de modo e a sequência.
- **`FB_MachineMode`** — máquina de estados PARADO/RODANDO/EMERGÊNCIA/FALHA + sinalização
  (torre e luzes de botão, incluindo a lógica de pisca).
- **`FB_PickPlaceSeq`** — máquina de estados do ciclo do robô (passos 1–16).
- **`FB_AxisPos`** (reutilizável, 1 por eixo X/Z) — escreve setpoint, lê feedback, gera
  "em posição" com tolerância/debounce.
- **`FB_Rotate180`** — primitiva de rotação: a partir de um trigger, dá **2 pulsos** de
  `Rotate CW`/`CCW` (1 = 90°), contando quedas de `Rotating`, e sinaliza `o_Done` ao
  completar 180°.
- **`FB_Conveyor`** (reutilizável, M1/M2) — liga/desliga (escreve velocidade), integra o
  sensor + delay no caso de M1.
- **UDTs/DB** — `typeStation` (Cmd/Cfg/Sts) e DB global para a HMI/diagnóstico.

> O E‑Stop (`%I0.3`) é a entrada de segurança transversal, lida em todos os FBs (mesmo
> papel do `EStop %I0.0` nos outros subsistemas, mas **aqui o endereço é `%I0.3`**).

---

> **Status:** documento de escopo (especificação). Nenhum código SCL foi escrito ainda.
> Próximo passo sugerido: fechar os "pontos em aberto" (§9) e então projetar/implementar
> os blocos (§10), validando cada um no linter.