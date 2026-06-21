# Pick & Place — Estação Two-Axis (Siemens S7-1500 · SCL)

Projeto de automação de uma estação **Two-Axis Pick & Place** programada em **SCL
(Structured Control Language)** para PLC **Siemens S7-1500**, desenvolvida no **TIA Portal**
e simulada em **FACTORY I/O ↔ S7-PLCSIM**.

O robô executa o ciclo **pega → gira 180° → deposita → retorna**, transferindo caixas da
esteira de entrada (**M1**) para a de saída (**M2**), com torre de sinalização, botoeiras
(Liga/Desliga/Emergência/Reset) e intertravamentos de segurança em lógica *standard*.

> **Status:** ✅ **validado e rodando no PLCSIM** — ciclo completo, torre piscando, rotação e
> recuperação por *homing* funcionando.

---

## 🎯 Visão geral

- **Eixos X/Z:** posicionamento **analógico** (setpoint/feedback em tensão 0–10 V), **não**
  Technology Objects / `MC_*`.
- **Rotação do braço:** por **pulso** (`Rotate CW/CCW` por borda; 1 pulso = 90°; **180° = 2
  pulsos**), com referenciamento absoluto por sensor **HOME** indutivo.
- **Segurança:** lógica *standard* (sem F-CPU) — E-Stop NF com prioridade máxima, estado seguro
  propagado a todos os blocos, anticolisão e exclusão mútua de saídas.
- **Sinalização:** pisca da torre gerado pelo **byte de clock da CPU** (determinístico, imune ao
  tempo de scan).

---

## 🧰 Stack

| Item | Detalhe |
|---|---|
| **PLC** | Siemens S7-1500 **CPU 1518T-4 PN/DP** (Technology), FW V3.1 |
| **IDE** | TIA Portal (blocos SCL) |
| **Simulação** | **S7-PLCSIM** ↔ **FACTORY I/O v2.5.10** (cena "New Scene") |
| **Linguagem** | SCL — comentários em PT, tags em EN, acesso otimizado |

---

## 🏗️ Arquitetura

Blocos (um por arquivo `.scl`), organizados por tipo:

```
OBs/   OB_Main          — orquestrador (OB1): roteia I/O e encadeia os blocos
FBs/   FB_MachineMode   — modos PARADO/RODANDO/EMERGÊNCIA/FALHA + sinalização
       FB_PickPlaceSeq  — máquina de estados do ciclo (passos 0–16)
       FB_AxisPos       — eixo analógico genérico (SP/PV/"em posição"/freeze)
       FB_Rotate180     — rotação 180° por 2 pulsos de 90°
       FB_RotateToHome  — referenciamento da rotação até o sensor HOME
       FB_Conveyor      — esteira analógica (M1 com sensor+delay / M2)
FCs/   FC_ScaleVolt     — conversão V ↔ engenharia (NORM_X/SCALE_X + LIMIT)
       FC_IoMapInputs   — entradas físicas (%I/%ID) → StationData
       FC_IoMapOutputs  — StationData → saídas (%Q/%QD) + máscara de estado seguro
DBs/   StationData      — DB global (Station : typeStation)
UDTs/  typeAxis         — molde de eixo (SP/PV/Tol/Debounce/InPos)
       typeStation      — Cmd / Cfg / Sts da estação
```

### Ordem de execução no `OB_Main` (cada scan)

```
1. FC_IoMapInputs   — %I/%ID → StationData
2. byte de clock    — lê %M0.5 (1 Hz) e %M0.2 (2,5 Hz) p/ o pisca  (sem FB)
3. FB_MachineMode   — modo + latch + sinalização → produz o_Run e o_SafeState
4. FB_Conveyor (M1) — sensor + delay → BoxAtPick
5. FB_Conveyor (M2) — pausa durante o depósito
6. FB_PickPlaceSeq  — passos 0–16 (multi-instancia AxisX/Z e Rotate CW/CCW)
7. FC_IoMapOutputs  — StationData → %Q/%QD (zera M1/M2/Grab/Rotate no estado seguro)
```

### Ciclo do robô (`FB_PickPlaceSeq`)

```mermaid
stateDiagram-v2
    [*] --> IDLE
    IDLE --> PEGA: RODANDO + caixa no Sensor_caixa + braço no HOME
    state PEGA {
        [*] --> MoveX_pick --> DesceZ --> Vacuo_ON --> SobeZ
    }
    PEGA --> GIRA_CW: Z up & X home
    GIRA_CW --> MoveX_place: 180° concluído
    MoveX_place --> DesceZ_place --> Vacuo_OFF --> SobeZ_place
    SobeZ_place --> GIRA_CCW: Z up & X home
    GIRA_CCW --> CICLO_OK: 180° + HOME confirmado
    CICLO_OK --> IDLE
    PEGA --> FALHA: timeout / sem caixa
    FALHA --> IDLE: Reset (com E-Stop rearmado)
```

Plano completo em [`DOCS/ARQUITETURA_PickPlace.md`](DOCS/ARQUITETURA_PickPlace.md);
especificação do processo em [`DOCS/ESCOPO_PickPlace.md`](DOCS/ESCOPO_PickPlace.md).

---

## 🔌 Mapa de I/O

**Entradas**

| Tag | Endereço | Tipo | Observação |
|---|---|---|---|
| Emergency Stop 0 | `%I0.3` | Bool | **NF** (FALSE = emergência) |
| Reset Button 0 | `%I0.4` | Bool | NO (pulso) |
| Sensor_caixa | `%I0.5` | Bool | retrorreflexivo (TRUE = caixa) |
| Start Button 0 | `%I0.6` | Bool | NO |
| Stop Button 0 | `%I0.7` | Bool | **NF** |
| Rotating | `%I1.0` | Bool | feedback de rotação |
| Item Detected | `%I1.1` | Bool | anti-esmagamento na descida do Z |
| **Inductive Sensor 0 (HOME)** | `%I1.3` | Bool | indutivo NO (TRUE = braço na casa/M1) |
| X / Z Position (V) | `%ID30` / `%ID34` | Real | feedback de posição (0–10 V) |

**Saídas**

| Tag | Endereço | Tipo |
|---|---|---|
| Reset/Stack(R/G/Y)/Start/Stop lights | `%Q0.3`–`%Q1.0` | Bool |
| Grab (vácuo) | `%Q1.1` | Bool |
| Rotate CW / CCW | `%Q1.2` / `%Q1.4` | Bool |
| Gripper CW / CCW | `%Q1.3` / `%Q1.5` | Bool (não usados) |
| M1 / M2 (velocidade) | `%QD30` / `%QD34` | Real |
| X / Z Set Point (V) | `%QD38` / `%QD42` | Real |

Detalhes e polaridades em [`DOCS/tags.md`](DOCS/tags.md). Fonte da verdade do endereçamento:
o export da cena em `DOCS/Tags_New Scene_*.xml`.

---

## 🛡️ Segurança e intertravamentos (lógica standard)

- **E-Stop NF (`%I0.3`)** tem prioridade máxima: força estado seguro (M1=0, M2=0, `Grab`=FALSE,
  sem novo movimento), **latcheado**; só libera com emergência rearmada **+ borda de Reset**.
- **Eixo no estado seguro congela no PV** (não vai a 0 V nem ao destino).
- **Anticolisão:** rotaciona só com **Z subido e X recolhido**; move X só com Z subido; não
  comanda X/Z enquanto `Rotating` está ativo.
- **Exclusão mútua:** `Rotate CW` ⊻ `Rotate CCW` nunca juntos; gripper sempre FALSE; esteiras só
  em RODANDO. Dupla barreira (FB + máscara final no `FC_IoMapOutputs`).

> ⚠️ **Nota normativa:** a parada de emergência é funcional, por software, **canal único**. Se
> houver acesso de pessoas à zona de movimento, a análise de risco (EN ISO 13849 / IEC 62061)
> pode exigir **F-CPU + PROFIsafe + STO** — não coberto por esta lógica standard.

---

## ▶️ Como rodar (TIA Portal + S7-PLCSIM + FACTORY I/O)

> ⚠️ **Pré-requisitos OBRIGATÓRIOS** — sem eles o FACTORY I/O **não conecta** / a torre **não
> pisca** (foram os pontos que mais custaram a descobrir):

1. **Handshake do template S7-PLCSIM** no OB cíclico — heartbeat em `QB511` (+1/scan) + espelho
   das entradas (periferia → imagem de processo) + DWords de handshake. É o código do **template
   oficial** da FACTORY I/O para S7-1500; sem ele o driver recusa com *"correct project template /
   S7-PLCSIM run mode"* mesmo com a CPU em RUN. **Não modificar** — é protocolo do fornecedor.
2. **Clock memory byte habilitado em `MB0`** (CPU → *System and clock memory*): `%M0.5` = 1 Hz
   (pisca lento) e `%M0.2` = 2,5 Hz (pisca rápido). Sem isso a torre não pisca. Ver
   [`DOCS/img.png`](DOCS/img.png).

**Passos:**
1. Abrir o projeto no **TIA Portal**, importar/gerar os blocos `.scl` (fontes externas) e atribuir
   o `OB_Main` ao **OB1**.
2. Configurar o hardware de I/O cobrindo todos os endereços (`%I/%Q/%ID/%QD`) + clock byte (MB0).
3. **Compilar** (hardware + software) → **Download** para o **S7-PLCSIM** → CPU em **RUN**.
4. No **FACTORY I/O**: driver **Siemens S7-PLCSIM** → **Connect**.

> Mudar a config de hardware (ex.: habilitar o clock byte) **derruba a conexão** → recompilar
> hardware, baixar de novo, RUN e **reconectar** no FACTORY I/O.

---

## 📚 Documentação (`DOCS/`)

| Doc | Conteúdo |
|---|---|
| `ESCOPO_PickPlace.md` | Especificação do processo: I/O, estados, sequência, intertravamentos |
| `ARQUITETURA_PickPlace.md` | Blueprint dos blocos, interfaces, FSMs, ordem de chamada |
| `tags.md` | Mapa de I/O (endereços, polaridades, setpoints) |
| `Componentes_FactoryIO.md` | Componentes da cena FACTORY I/O (NC/NO, cores IEC) |
| `LEVANTAMENTO_ERROS.md` | Erros encontrados/corrigidos no comissionamento (TIA + PLCSIM) |
| `PROJECT_STATE.md` | Histórico cronológico de decisões e sessões |
| `compass_artifact_*.md` | Por que o pisca por TON falha em SCL → byte de clock |

---

## 📝 Convenções de código

- Comentários em **português**, tags em **inglês**.
- Acesso otimizado (`{ S7_Optimized_Access := 'TRUE' }`); lógica agrupada em `REGION`.
- Detecção de borda com `R_TRIG`/`F_TRIG`.
- `LREAL` em cálculos críticos; conversão `V ↔ eng.` com `NORM_X`/`SCALE_X`/`LIMIT`.
- **Atenção (TIA):** não existe `LREAL_TO_TIME` no compilador — usar
  `DINT_TO_TIME(LREAL_TO_DINT(ms))`. O linter pode aceitar; **a compilação no TIA é a validação
  definitiva**.

---

## 📄 Licença

Projeto educacional/de estudo. Sem licença definida — uso conforme acordado com o autor.