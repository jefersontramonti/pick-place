# IHM TP1500 Comfort — Projeto de Telas (Pick & Place)

> Projeto das telas (screens) da IHM para a estação **Two-Axis Pick & Place**.
> Painel **SIMATIC TP1500 Comfort** (`6AV2124-0QC24-1AX0`), 15.6" touch, **1366×768**, projetado
> no **WinCC (TIA Portal)**, comunicação **PROFINET → CPU 1518T**. Toda a IHM é **DB-cêntrica**:
> lê/escreve tags simbólicas do `StationData` (sem I/O física nova). Mapa de tags em
> **`tags.md` §10**; processo em `ESCOPO_PickPlace.md`; modos/mux em `ARQUITETURA_PickPlace.md`.
>
> **Estado:** documento de **projeto/protótipo** — as telas ainda serão criadas no WinCC.
> Os protótipos ASCII abaixo são esquemáticos (proporções aproximadas, não pixel-perfeito).

---

## 1. Resumo executivo

- **6 telas** (screens) + **1 template** (área permanente: cabeçalho + barra de navegação) +
  **2 janelas pop-up** (login, confirmação). O teclado numérico/alfanumérico é **nativo** do WinCC.
- Navegação por **barra inferior fixa** (6 botões), sempre visível, + atalhos contextuais
  (sino de alarme no cabeçalho → Alarmes; botão LIGAR no Sinótico → Automático).
- **3 níveis de acesso** (grupos de usuário WinCC): Operador, Manutenção, Administrador.
- **Pré-requisito de PLC** (§5): a IHM só comanda Liga/Para/Reset após pequena alteração no
  `FC_IoMapInputs` (hoje os botões físicos sobrescrevem `Cmd.*`). `Cmd.AutoMode`/`Cmd.Man.*`
  já funcionam direto.

---

## 2. Layout-base (grade 1366×768)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  CABEÇALHO (área permanente do template)                          altura ~64 px │
│  [logo] ESTAÇÃO PICK & PLACE     « título da tela »     MODO  ESTADO  🔔  hh:mm │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│                         ÁREA DE TRABALHO DA TELA                               │
│                              (~1366 × 632 px)                                  │
│                                                                                │
├──────────────────────────────────────────────────────────────────────────────┤
│  BARRA DE NAVEGAÇÃO (área permanente)                             altura ~72 px │
│  [ Início ] [ Automático ] [ Manual ] [ Parâmetros 🔒] [ Alarmes ] [ Sistema 🔒]│
└──────────────────────────────────────────────────────────────────────────────┘
```

**Cabeçalho (template, sempre visível):**
- **MODO** — campo de texto: `AUTO` (verde) / `MANUAL` (azul) — de `Sts.ManActive` (TRUE=MANUAL) +
  `Cmd.AutoMode`. (Lembrar: `ManActive` = MANUAL **e** RODANDO; em repouso mostrar o modo
  selecionado por `Cmd.AutoMode`.)
- **ESTADO** — `PARADO` (amarelo) / `RODANDO` (verde) / `EMERGÊNCIA` (vermelho pisca) / `FALHA`
  (vermelho) — de `Sts.Mode` (0/1/2/3).
- **🔔 sino** — pisca quando `Sts.Fault` OU `Sts.ManRejected ≠ 0`; toque → tela Alarmes.
- Relógio (runtime), logo/título.

**Barra de navegação (template):** 6 botões; o botão da tela ativa fica destacado. 🔒 = exige login.

---

## 3. Inventário de telas

| # | Tela | Função | Acesso | Principais tags |
|---|------|--------|--------|-----------------|
| **T00** | *Template* (cabeçalho + nav) | Moldura permanente, indicadores globais | — | `Sts.Mode`, `Sts.ManActive`, `Sts.Fault`, `Sts.ManRejected` |
| **T01** | **Início / Sinótico** | Visão geral animada da estação | Operador | leitura geral `Sts.*` |
| **T02** | **Automático** | Operar o ciclo automático (Liga/Para/Reset, passo) | Operador | `Cmd.Start/Stop/Reset/AutoMode`, `Sts.Step`, `Sts.CycleCount` |
| **T03** | **Manual** | Jog de eixos/esteiras/rotação/vácuo | Operador | `Cmd.Man.*`, `Sts.AxisX/Z`, `Sts.ManRejected` |
| **T04** | **Parâmetros / Calibração** | Editar `Cfg.*` (setpoints) | Manutenção 🔒 | `Cfg.*` |
| **T05** | **Alarmes & Diagnóstico** | Lista de alarmes + diagnóstico de I/O | Operador (ack) / Manut. (reset) | `Sts.Fault/FaultCode/ManRejected`, sensores |
| **T06** | **Sistema** | Idioma, brilho, usuários, info do painel | Manutenção/Admin 🔒 | (runtime/WinCC) |
| **P01** | *Pop-up* Login | Autenticação de usuário | — | (WinCC user mgmt) |
| **P02** | *Pop-up* Confirmação | Confirmar ações críticas (sim/não) | — | — |

---

## 4. Mapa de navegação (qual tela chama qual)

```
                         ┌───────────────────────────────────────────┐
                         │   BARRA DE NAVEGAÇÃO (fixa em todas)        │
                         │   alcança T01..T06 de qualquer tela         │
                         └───────────────────────────────────────────┘
                                          │
   ┌──────────────┬───────────────┬───────┴────────┬───────────────┬───────────────┐
   ▼              ▼               ▼                ▼               ▼               ▼
┌────────┐   ┌──────────┐    ┌────────┐     ┌────────────┐   ┌──────────┐   ┌─────────┐
│  T01   │   │   T02    │    │  T03   │     │    T04     │   │   T05    │   │  T06    │
│ Início │──▶│Automático│◀──▶│ Manual │     │ Parâmetros │   │ Alarmes  │   │ Sistema │
│Sinótico│   │          │    │        │     │  🔒        │   │          │   │  🔒     │
└───┬────┘   └────┬─────┘    └───┬────┘     └─────┬──────┘   └────┬─────┘   └────┬────┘
    │             │              │                │                │              │
    │ [LIGAR]     │ seletor      │ seletor        │ exige login    │             exige login
    │  ▶ T02      │ AUTO/MANUAL  │ AUTO/MANUAL    │  ▼             │              ▼
    │             │  alterna     │  alterna       │ ┌─────────┐    │         ┌─────────┐
    │ 🔔 alarme   │  T02 ⇄ T03   │  T02 ⇄ T03     │ │  P01    │    │         │  P01    │
    └─────────────┴──────────────┴───▶ T05 ◀───────┘ │ Login   │    │         │ Login   │
              (sino do cabeçalho, qualquer tela)      └─────────┘    │         └─────────┘
                                                                     │
   Ações críticas (Restaurar padrão em T04, trocar modo em ciclo) ──▶ P02 (Confirmação)
```

**Regras de navegação:**
- A **barra inferior** dá acesso direto a T01–T06 de qualquer tela (navegação plana, sem
  submenus profundos — boa prática para operação com luva/touch).
- **Sino 🔔** do cabeçalho → **T05 Alarmes** (atalho global).
- **T01 Início**: botão **LIGAR** leva a **T02 Automático** (fluxo natural do operador).
- **Seletor AUTO/MANUAL** aparece em **T02** e **T03**; alterna o destino lógico e a tela
  correspondente. A troca só é aceita pelo PLC com `Sts.Step = 0` (gate do `FB_MachineMode`) — a
  tela deve sinalizar "troca de modo só com a máquina em repouso" se ignorada.
- **T04 Parâmetros** e **T06 Sistema** exigem **login** (P01) → se não autenticado, abre P01.
- **P02 Confirmação** intercepta ações destrutivas/críticas (restaurar padrões, etc.).

---

## 5. Pré-requisitos de integração PLC ↔ IHM (LER ANTES de criar as telas)

> Sem estes ajustes, parte dos botões da IHM **não terá efeito**. São mudanças mínimas e
> localizadas (não tocam a lógica de processo).

1. **Liga/Para/Reset da IHM — exige alteração no `FC_IoMapInputs`.** Hoje a FC copia
   `Cmd.Start/Stop/Reset` **crus dos botões físicos** (`%I0.6/%I0.7/%I0.4`) no início do scan,
   **sobrescrevendo** qualquer escrita da IHM. ✅ **IMPLEMENTADO (2026-06-21):** adicionados os bits
   `Cmd.HmiStart/HmiStopReq/HmiReset` no `typeStation` e a mescla no `FC_IoMapInputs`:
   - `Cmd.Start := i_Start OR Cmd.HmiStart` (NA — OR é seguro)
   - `Cmd.Reset := i_Reset OR Cmd.HmiReset` (NA — OR é seguro) → rearme de **FALHA**
   - `Cmd.Stop  := i_Stop AND NOT Cmd.HmiStopReq` (Stop é **NF**: TRUE=ok; a IHM força parada
     funcional levando o sinal a FALSE — só **adiciona** parada, nunca destrava)
   - A IHM **pulsa** o bit HMI ("set bit while key pressed"; Start/Reset geram borda no `FB_MachineMode`).
2. **E-Stop NÃO é botão de tela.** A parada de emergência **segura** é só a física NF `%I0.3`.
   A IHM **não escreve** `Cmd.EStop` — apenas **exibe** o estado (`Sts.Mode = 2` / `Cmd.EStop`
   espelhado). Nunca rotular um botão de tela como "Emergência".
   ✅ **Decisão C-1 (2026-06-21) — rearme separado, IMPLEMENTADO:** sair de **EMERGÊNCIA** exige
   **Reset FÍSICO** co-localizado (novo `Cmd.ResetPhys` = `%I0.4` cru → `FB_MachineMode`); o reset
   da tela (`HmiReset`) reseta **só FALHA** funcional. O reset físico destrava ambos.
   ⚠ **Partida remota (`HmiStart`) ACEITA sob C-1:** dá RODANDO sem linha de visão da zona — risco
   residual registrado; parada/partida seguras com pessoas na zona exigiriam F-CPU/PROFIsafe/STO.
3. **`Cmd.AutoMode` e `Cmd.Man.*` já funcionam direto** — não têm origem física e o
   `FC_IoMapInputs` não os toca. A IHM escreve/limpa livremente.
4. **Jog manual só atua com `Sts.ManActive = TRUE`** (MANUAL **e** RODANDO). A tela T03 deve
   **desabilitar/escurecer** os botões de jog quando `ManActive = FALSE` e orientar o operador
   (selecionar MANUAL + LIGAR).
5. **Calibração**: escritas em `Cfg.*` são **ao vivo** (binding direto). Para os novos valores
   **persistirem** como *start values*, lembrar do **reinit do `StationData`** no TIA.
6. ✅ **`tags.md` §10.1 ATUALIZADO:** `Cmd.EStop` → **R**; `Cmd.Start/Stop/Reset` → derivados
   (não bindar); `Cmd.HmiStart/HmiStopReq/HmiReset` → **W**; `Cmd.ResetPhys` → físico (não bindar).

---

## 6. Especificação tela a tela + protótipos

### T01 — Início / Sinótico  *(Operador)*

**Função:** visão geral animada da estação, num relance. Sem comandos críticos (exceto atalho LIGAR).

**Elementos (todos leitura):**
- Mímico animado: esteira **M1** (entrada) → ponto de **pega** → braço (**X/Z**) → **rotação** →
  esteira **M2** (saída). Animar por `Sts.M1Speed/M2Speed` (cor/seta de movimento),
  `Sts.AxisX.PV`/`AxisZ.PV` (posição do braço), `Sts.Rotating`/`Sts.RotHome` (orientação),
  `Sts.VacuumOn` (garra), `Sts.SensorBox`/`Sts.BoxAtPick`/`Sts.ItemDetected` (caixa/peça).
- Painel lateral: **Estado** (`Sts.Mode`), **Passo** (`Sts.Step`), **Ciclos** (`Sts.CycleCount`),
  X PV/SP, Z PV/SP, vácuo.
- Botão **LIGAR** (atalho → T02) e **RESET** (visível só se `Sts.Fault`).

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ [logo] ESTAÇÃO PICK & PLACE          « Início / Sinótico »   AUTO  RODANDO 🔔 14:22 │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                            ┌──────────────────┐ │
│   M1 ═══▶ □caixa        ╔═══╗ rotação 180°                │ Estado:  RODANDO │ │
│  ░░░░░░░░░░░░░░░       ║ ▲ ║◀── braço (X,Z)               │ Passo:   7/16    │ │
│        │ pega          ║ Z ║                              │ Ciclos:  128     │ │
│        ▼               ╚═╤═╝            □                 │ ───────────────  │ │
│     [ventosa ●]   X ───┘            ▶═══ M2 (saída)       │ X: 7.70 / 7.70 V │ │
│                                                          │ Z: 0.00 / 0.00 V │ │
│   Vácuo: ● LIGADO     Home: ◯       Rotando: ◯           │ Vácuo:  LIGADO   │ │
│                                                          └──────────────────┘ │
│                                          [  ▶ LIGAR  ]   [ ⟳ RESET (se falha) ] │
├──────────────────────────────────────────────────────────────────────────────┤
│ [ Início ] [ Automático ] [ Manual ] [ Parâmetros 🔒] [ Alarmes ] [ Sistema 🔒]│
└──────────────────────────────────────────────────────────────────────────────┘
```

---

### T02 — Automático  *(Operador)*

**Função:** operar o ciclo automático.

**Botões de ação:**
| Botão | Tag (ação) | Tipo | Habilitação |
|------|------------|------|-------------|
| **▶ LIGAR** | `Cmd.HmiStart` (pulso) | momentâneo | modo AUTO; não em EMERGÊNCIA |
| **■ PARAR** | `Cmd.HmiStopReq` (pulso/nível) | momentâneo | sempre |
| **⟳ RESET** | `Cmd.HmiReset` (pulso) | momentâneo | há falha/emergência rearmada |
| **Seletor AUTO/MANUAL** | `Cmd.AutoMode` (TRUE=AUTO) | chave | só efetiva com `Sts.Step=0` |

**Indicadores:** barra de **passo** (`Sts.Step` 0..16 com rótulos PICK 1–7 / PLACE 8–16),
X/Z PV·SP·InPos, `Sts.Rotating`/`RotHome`, `VacuumOn`, `M1Speed`/`M2Speed`, `BoxAtPick`/
`SensorBox`/`ItemDetected`, `CycleCount`, `FaultCode` (texto).

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ [logo] ESTAÇÃO PICK & PLACE            « Automático »       AUTO  RODANDO 🔔 14:23 │
├──────────────────────────────────────────────────────────────────────────────┤
│  Modo: ( ● AUTO   ◯ MANUAL )   ← troca só com a máquina em repouso (Passo 0)    │
│                                                                                │
│  Passo:  [1▮2▮3▮4▮5▮6▮7▮ 8 9 10 11 12 13 14 15 16]   « 7: girar 180° »          │
│                                                                                │
│  ┌── Eixos ──────────────┐  ┌── Processo ───────────┐  ┌── Esteiras ────────┐  │
│  │ X  PV 7.70  SP 7.70 ✓ │  │ Rotando:  ◯           │  │ M1: ███ 5.0 V      │  │
│  │ Z  PV 0.00  SP 0.00 ✓ │  │ Home:     ◯           │  │ M2: ░░░ 0.0 V      │  │
│  └───────────────────────┘  │ Vácuo:    ● LIGADO    │  │ Sensor caixa: ●    │  │
│   Ciclos: 128   Falha: —    │ Item:     ●           │  └────────────────────┘  │
│                             └───────────────────────┘                          │
│        [  ▶ LIGAR  ]        [  ■ PARAR  ]        [  ⟳ RESET  ]                  │
├──────────────────────────────────────────────────────────────────────────────┤
│ [ Início ] [ Automático ] [ Manual ] [ Parâmetros 🔒] [ Alarmes ] [ Sistema 🔒]│
└──────────────────────────────────────────────────────────────────────────────┘
```

---

### T03 — Manual  *(Operador)* — **tela central da nova fase**

**Função:** jog manual. Jog dos eixos por **posições predefinidas**; esteiras em **jog puro**
(enquanto pressionado); rotação **por pulso**; vácuo on/off. Tudo intertravado (anticolisão §7).

**Pré-condição (banner no topo):** os botões de jog só atuam com `Sts.ManActive = TRUE`
(selecione **MANUAL** + **LIGAR**). Se `ManActive=FALSE`, escurecer o bloco de jog.

**Botões de ação (todos escrevem `Cmd.Man.*`):**
| Grupo | Botão | Tag | Tipo |
|------|-------|-----|------|
| Modo | Seletor MANUAL | `Cmd.AutoMode:=FALSE` | chave (gate Step=0) |
| Modo | ▶ LIGAR / ■ PARAR | `Cmd.HmiStart`/`HmiStopReq` | momentâneo |
| Eixo X | → Pega / → Casa / → Depósito | `Man.XToPick` / `Man.XToHome` / `Man.XToPlace` | momentâneo |
| Eixo Z | ↑ Subir / ↓ Descer | `Man.ZToUp` / `Man.ZToPlace` | momentâneo |
| Rotação | ↻ CW / ↺ CCW / ⌂ Referenciar | `Man.RotCW` / `Man.RotCCW` / `Man.RotHome` | momentâneo (pulso) |
| Esteiras | M1 ▶ / M2 ▶ | `Man.M1Run` / `Man.M2Run` | **manter pressionado** |
| Vácuo | Ligar / Soltar | `Man.VacOn` / `Man.VacOff` | momentâneo (latch no PLC) |

**Feedback:** X/Z PV·SP·InPos ao vivo, `Rotating`/`RotHome`, `VacuumOn`; e **banner de rejeição**
grande, dirigido por `Sts.ManRejected` (texto por código — ver §7). Some quando `ManRejected=0`.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ [logo] ESTAÇÃO PICK & PLACE               « Manual »      MANUAL  RODANDO 🔔 14:25 │
├──────────────────────────────────────────────────────────────────────────────┤
│  Modo: ( ◯ AUTO  ● MANUAL )   [ ▶ LIGAR ] [ ■ PARAR ]     Manual ATIVO: ● SIM   │
│  ⚠ BLOQUEIO: "Recolha Z antes de mover X"        (banner some se ManRejected=0) │
│                                                                                │
│  ┌─ Eixo X ───────────────┐  ┌─ Eixo Z ──────────┐  ┌─ Rotação ─────────────┐ │
│  │ [ → Pega   X_pick ]    │  │ [  ↑ Subir Z_up ] │  │ [ ↻ CW ]  [ ↺ CCW ]   │ │
│  │ [ → Casa   X_home ]    │  │ [  ↓ Descer    ] │  │ [ ⌂ Referenciar HOME ]│ │
│  │ [ → Depós. X_place]    │  │   Z_place        │  │  Rotando ◯  Home ◯    │ │
│  │  PV 7.70  SP 7.70  ✓   │  │ PV 0.00 SP 0.00 ✓│  └───────────────────────┘ │
│  └────────────────────────┘  └──────────────────┘  ┌─ Vácuo ───────────────┐ │
│  ┌─ Esteiras (manter) ─────────────────────────┐    │ [ Ligar ] [ Soltar ]  │ │
│  │ [ M1 ▶ (segurar) ]   [ M2 ▶ (segurar) ]     │    │  Estado: ● LIGADO     │ │
│  └─────────────────────────────────────────────┘    └───────────────────────┘ │
├──────────────────────────────────────────────────────────────────────────────┤
│ [ Início ] [ Automático ] [ Manual ] [ Parâmetros 🔒] [ Alarmes ] [ Sistema 🔒]│
└──────────────────────────────────────────────────────────────────────────────┘
```

---

### T04 — Parâmetros / Calibração  *(Manutenção 🔒)*

**Função:** editar os setpoints `Cfg.*` (campos de E/S numérica R/W, teclado nativo). Login exigido.

**Campos:**
| Grupo | Tag | Unid. | Padrão |
|------|-----|-------|--------|
| Posições X | `Cfg.X_pick` / `X_home` / `X_place` | V | 7.7 / 0.0 / 6.8 |
| Posições Z | `Cfg.Z_up` / `Z_place` / `Z_pickLimit` | V | 0.0 / 7.0 / 8.0 |
| Tolerância | `Cfg.PosTol` / `PosDebounce` | V / ms | 0.1 / 200 |
| Esteiras | `Cfg.ConvSpeed` / `M1StopDelay` | V / ms | 5.0 / 500 |
| Sequência | `Cfg.SeqStepTimeout` | s | 30 |
| Pisca (info) | `Cfg.ClkSlowHz` / `ClkFastHz` | Hz | 1.0 / 3.0 *(hoje sem uso — pisca via MB0)* |
| Habilita | `Cfg.Enabled` | bool | TRUE |

**Botões:** **Restaurar padrão** (→ P02 confirmação), **Voltar**. (Sem "Salvar": binding ao vivo;
nota na tela sobre **reinit no TIA** para persistir como *start value*.)
**Aviso de segurança:** alterar `Z_pickLimit`/posições afeta a **anticolisão** — só pessoal treinado.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ [logo] ESTAÇÃO PICK & PLACE        « Parâmetros / Calibração »  PARADO 🔒 14:30 │
├──────────────────────────────────────────────────────────────────────────────┤
│  ⚠ Altera anticolisão — pessoal treinado. Valores ao vivo (reinit no TIA p/ salvar). │
│  ┌─ Posições X (V) ──────┐  ┌─ Posições Z (V) ──────┐  ┌─ Tolerância ────────┐ │
│  │ Pega    [  7.70 ]     │  │ Subido   [  0.00 ]    │  │ PosTol   [ 0.10 ] V │ │
│  │ Casa    [  0.00 ]     │  │ Depósito [  7.00 ]    │  │ Debounce [ 200  ] ms│ │
│  │ Depós.  [  6.80 ]     │  │ Lim.pega [  8.00 ]    │  └─────────────────────┘ │
│  └───────────────────────┘  └───────────────────────┘  ┌─ Esteiras ──────────┐ │
│  ┌─ Sequência ───────────┐  ┌─ Habilita ────────────┐  │ Veloc.  [ 5.0 ] V   │ │
│  │ Timeout [  30 ] s      │  │ Ciclo  [ ✓ Habilitado]│  │ Atraso M1 [500] ms  │ │
│  └───────────────────────┘  └───────────────────────┘  └─────────────────────┘ │
│                              [ Restaurar padrão ]      [ Voltar ]               │
├──────────────────────────────────────────────────────────────────────────────┤
│ [ Início ] [ Automático ] [ Manual ] [ Parâmetros 🔒] [ Alarmes ] [ Sistema 🔒]│
└──────────────────────────────────────────────────────────────────────────────┘
```

---

### T05 — Alarmes & Diagnóstico  *(Operador: reconhecer / Manutenção: reset)*

**Função:** lista de alarmes (WinCC Alarm Control: ativos + histórico) e diagnóstico de I/O.

- **Alarmes** a partir de `Sts.Fault` (discreto) + `Sts.FaultCode` (1..4) + `Sts.ManRejected` (1..5)
  — mapeamento em §7.
- **Diagnóstico (leitura):** E-Stop (`Cmd.EStop`/`Sts.Mode=2`), Stop, sensores (`SensorBox`,
  `ItemDetected`, `Rotating`, `RotHome`), tensões cruas X/Z (`AxisX/Z.PV`).
- **Botões:** **Reconhecer** (ack do Alarm Control), **⟳ RESET** (`Cmd.HmiReset`, exige Manutenção).

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ [logo] ESTAÇÃO PICK & PLACE         « Alarmes & Diagnóstico »   FALHA 🔔 14:31 │
├──────────────────────────────────────────────────────────────────────────────┤
│  ┌─ Alarmes ─────────────────────────────────────────────────────────────────┐ │
│  │ Hora     Estado  Texto                                                    │ │
│  │ 14:31:02  ATIVO  FALHA 3: timeout de rotação                              │ │
│  │ 14:28:10  ✓ ack  REJEIÇÃO 5: rotação bloqueada (recolha Z)               │ │
│  │ 14:10:55  ido    FALHA 2: timeout de Z                                    │ │
│  └───────────────────────────────────────────────────────────────────────────┘ │
│  ┌─ Diagnóstico de I/O ──────────────────────────────────────────────────────┐ │
│  │ E-Stop: ● OK   Stop: ● OK   Sensor caixa: ◯   Item: ◯   Rotando: ◯  Home:●│ │
│  │ X cru: 7.70 V    Z cru: 0.00 V                                            │ │
│  └───────────────────────────────────────────────────────────────────────────┘ │
│                       [ Reconhecer ]        [ ⟳ RESET (Manut.) ]                │
├──────────────────────────────────────────────────────────────────────────────┤
│ [ Início ] [ Automático ] [ Manual ] [ Parâmetros 🔒] [ Alarmes ] [ Sistema 🔒]│
└──────────────────────────────────────────────────────────────────────────────┘
```

---

### T06 — Sistema  *(Manutenção/Admin 🔒)*

**Função (recursos nativos do WinCC):** trocar **idioma**, ajustar **brilho**, **limpar tela**
(bloqueio de toque temporário), **gestão de usuários** (Admin), **login/logout**, **info do painel**
(TP1500 Comfort `6AV2124-0QC24-1AX0`, versão de runtime). Tela majoritariamente de objetos
de sistema do WinCC; sem tags de processo.

---

### Pop-ups

- **P01 — Login:** campos usuário/senha (teclado nativo); abre ao tocar tela 🔒 sem sessão.
- **P02 — Confirmação:** "Confirmar a ação?" com botões **Sim** / **Não**; usado em Restaurar padrão (T04)
  e qualquer comando potencialmente perturbador.

---

## 7. Lista de alarmes / textos (mapeamento de códigos)

**`Sts.FaultCode`** (falhas travadas — classe *Erro*, exigem RESET):
| Código | Texto na IHM |
|-------:|--------------|
| 0 | (sem falha) |
| 1 | FALHA 1: timeout de X / homing |
| 2 | FALHA 2: timeout de Z |
| 3 | FALHA 3: timeout de rotação |
| 4 | FALHA 4: Z no limite sem peça (sem caixa) |

**`Sts.ManRejected`** (jog manual bloqueado — classe *Aviso*, some sozinho):
| Código | Texto na IHM |
|-------:|--------------|
| 0 | (nenhum) |
| 1 | REJEIÇÃO: conflito de jog X (mais de um botão) |
| 2 | REJEIÇÃO: mova X só com Z recolhido (ou sem rotação) |
| 3 | REJEIÇÃO: para descer Z, X deve estar em Pega/Depósito |
| 4 | REJEIÇÃO: conflito de jog Z (subir e descer juntos) |
| 5 | REJEIÇÃO: rotação bloqueada (recolha Z / em rotação / homing) |

> `ManRejected` reflete o **primeiro** bloqueio do scan e re-arma a 0 a cada scan; usar como
> *trigger* de mensagem efêmera (toast/banner), não alarme travado.

---

## 8. Níveis de acesso (grupos de usuário WinCC)

| Nível | Grupo | Pode | Telas |
|------:|-------|------|-------|
| 1 | **Operador** | Liga/Para/Reset, jog manual, reconhecer alarmes | T01, T02, T03, T05 |
| 2 | **Manutenção** | + editar `Cfg.*`, resetar/limpar alarmes, sistema | + T04, T06 |
| 3 | **Administrador** | + gestão de usuários, idioma/runtime | + admin em T06 |

---

## 9. Convenções visuais (IEC 60204-1 / projeto)

- **Verde** = RODANDO / ligado / OK · **Amarelo** = PARADO / atenção · **Vermelho** =
  EMERGÊNCIA / FALHA · **Azul** = modo MANUAL / botão de jog · **Cinza** = desabilitado.
- Botões de ação **grandes** (mín. ~14 mm) para toque com luva. Estados de botão: normal /
  pressionado / desabilitado (escurecido).
- Indicadores piscantes seguem a torre: pisca **lento** = atenção (PARADO/FALHA), pisca
  **rápido** = EMERGÊNCIA. Não inventar piscas novos na IHM além desses.

---

## 10. Checklist de implementação no WinCC

- [ ] Criar **device HMI** TP1500 Comfort + conexão PROFINET com a CPU 1518T.
- [ ] Importar/conectar as **tags simbólicas** do `StationData` (mapa em `tags.md` §10).
- [ ] Aplicar **pré-requisitos §5** no PLC (bits `Cmd.Hmi*` + ajuste do `FC_IoMapInputs`); E-Stop
      permanece só físico.
- [ ] Criar **template** (cabeçalho + barra de navegação) e aplicar a todas as telas.
- [ ] Criar **T01–T06** + pop-ups **P01/P02** conforme §6.
- [ ] Configurar **Alarm Control** com os textos da §7 (classes Erro/Aviso).
- [ ] Configurar **grupos de usuário** e proteção 🔒 das telas (§8).
- [ ] Animações do sinótico (T01) e barra de passo (T02) ligadas a `Sts.*`.
- [ ] Testar no **PLCSIM/Runtime**: navegação, gating de modo (Step=0), jog + `ManRejected`,
      bloqueio de jog quando `ManActive=FALSE`, alarmes e RESET.
