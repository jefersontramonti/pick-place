# Arquitetura de Agentes — Projeto SCL S7-1500

> Documento de design. Define **como** a automação com Claude Code deve ser montada
> para este projeto (PLC Siemens 1518T-4 PN/DP, SCL/TIA Portal). É o blueprint a ser
> implementado — não o código final.

---

## 1. Filosofia

O objetivo é um **time de subagentes especializados**, orquestrados, cada um com:

- **Escopo único** (faz uma coisa bem feita — princípio Unix);
- **Contexto isolado** (cada subagente tem sua própria janela de contexto, evita
  poluir a conversa principal);
- **Ferramentas mínimas** (só o que o papel exige — princípio do menor privilégio);
- **Modelo adequado ao custo/complexidade** (Opus para arquitetura/revisão crítica,
  Sonnet para execução, Haiku para tarefas mecânicas).

Pilares da plataforma Claude Code usados:

| Recurso | Papel na arquitetura |
|---|---|
| **Subagentes** (`.claude/agents/*.md`) | O time de especialistas |
| **Skills** (`.claude/skills/*/SKILL.md`) | Conhecimento sob demanda (auto-invocado) |
| **Slash commands** (`.claude/commands/*.md`) | Workflows repetíveis e orquestração |
| **Hooks** (`settings.json`) | Automação determinística (validar, formatar, registrar) |
| **MCP WebStorm SCL** | Validação, geração e introspecção real dos blocos SCL |
| **CLAUDE.md** | Contexto central sempre carregado |
| **Memory** (`.claude/projects/.../memory`) | Fatos persistentes entre sessões |

---

## 2. Estrutura de diretórios alvo

```
aula01/
├─ CLAUDE.md                      ← contexto central (já existe)
├─ .claude/
│  ├─ settings.json               ← hooks + permissões (versionado no git)
│  ├─ settings.local.json         ← overrides locais (não versionado)
│  ├─ agents/                     ← os subagentes
│  │  ├─ scl-architect.md
│  │  ├─ scl-developer.md
│  │  ├─ scl-reviewer.md
│  │  ├─ safety-auditor.md
│  │  ├─ motion-specialist.md
│  │  ├─ tag-io-documenter.md
│  │  └─ test-sim-engineer.md
│  └─ commands/                   ← workflows
│     ├─ new-block.md
│     ├─ review-block.md
│     ├─ safety-check.md
│     └─ io-sync.md
├─ OBs/  FBs/  FCs/  DBs/  UDTs/   ← código SCL
└─ DOCS/                           ← manuais + este documento
```

---

## 3. O time de subagentes

Cada subagente é um arquivo Markdown com frontmatter YAML. Campos: `name`,
`description` (quando invocar — o orquestrador usa isto para rotear), `tools`
(omitir = herda todas), `model`.

### 3.1 `scl-architect` — Arquiteto de blocos
- **Modelo:** `opus` · **Quando:** antes de escrever código novo.
- **Faz:** decide a estrutura de blocos (OB/FB/FC/DB/UDT), modela máquinas de estado,
  define interfaces (VAR_INPUT/OUTPUT/IN_OUT), particiona responsabilidades, planeja
  ordem de chamada no OB cíclico. **Não escreve a implementação** — entrega um plano.
- **Tools:** `Read, Grep, Glob, mcp__webstorm__scl_project_summary,
  mcp__webstorm__scl_list_blocks, mcp__webstorm__scl_get_interface`

### 3.2 `scl-developer` — Desenvolvedor SCL
- **Modelo:** `sonnet` · **Quando:** implementar/editar blocos a partir do plano.
- **Faz:** escreve SCL idiomático Siemens (REGION, R_TRIG/F_TRIG, acesso otimizado),
  segue convenções do CLAUDE.md, valida cada bloco no MCP antes de concluir.
- **Tools:** `Read, Write, Edit, Grep, Glob, mcp__webstorm__scl_validate_file,
  mcp__webstorm__scl_generate_fb, mcp__webstorm__scl_get_interface`

### 3.3 `scl-reviewer` — Revisor de código
- **Modelo:** `opus` · **Quando:** após implementação, antes de "concluído".
- **Faz:** caça bugs de **ciclo de scan** (uso de valor antes de atribuir, dependência
  de ordem), condições de corrida, estados não tratados no CASE, divisão por zero,
  overflow de tipos, conversões implícitas perigosas (REAL/LREAL, constantes), tags
  estáticas não inicializadas. Verifica aderência ao IEC 61131-3 e à norma Siemens.
- **Tools:** `Read, Grep, Glob, mcp__webstorm__scl_validate_file,
  mcp__webstorm__scl_get_interface` (read-only — revisa, não corrige).

### 3.4 `safety-auditor` — Auditor de segurança
- **Modelo:** `opus` · **Quando:** qualquer lógica com E-Stop, intertravamento, modo
  de falha, ou função relacionada à segurança.
- **Faz:** valida E-Stop em lógica NF (fail-safe), prioridade emergência > falha >
  operação, exigência de reset deliberado, ausência de auto-rearme perigoso, estados
  seguros na energização e na perda de comunicação. Sinaliza o que exigiria F-CPU/
  blocos F (safety) vs. lógica standard.
- **Tools:** `Read, Grep, Glob` (read-only).

### 3.5 `motion-specialist` — Especialista em Motion Control
- **Modelo:** `sonnet` · **Quando:** eixos, posicionamento, sincronismo, cames.
- **Faz:** aproveita a variante **"T"** da CPU 1518T — Technology Objects
  (`TO_PositioningAxis`, `TO_SynchronousAxis`) e instruções `MC_*` (`MC_Power`,
  `MC_Home`, `MC_MoveAbsolute`, `MC_MoveRelative`, `MC_MoveJog`, `MC_GearIn`...).
  Gerencia DBs de instância dos blocos MC, tratamento de `Done/Busy/Error/Status`.
- **Tools:** `Read, Write, Edit, Grep, Glob, mcp__webstorm__scl_validate_file`

### 3.6 `tag-io-documenter` — Documentador de tags / I/O
- **Modelo:** `haiku` · **Quando:** criar/atualizar listas de tags e mapeamento de E/S.
- **Faz:** mantém a tabela de tags simbólicas, lista de I/O, convenção de nomes
  (`i_`/`o_`/`s_`/`t_`), e a coerência entre símbolos e endereços absolutos.
- **Tools:** `Read, Write, Edit, Grep, Glob, mcp__webstorm__scl_read_io_list,
  mcp__webstorm__scl_project_summary`

### 3.7 `test-sim-engineer` — Engenheiro de teste/simulação
- **Modelo:** `sonnet` · **Quando:** projetar casos de teste e cenários de simulação.
- **Faz:** deriva casos de teste por estado/transição da FSM, define sequências de
  estímulo para **PLCSIM Advanced**, tabelas de força (watch/force), critérios de
  aceitação. Documenta cobertura.
- **Tools:** `Read, Write, Grep, Glob, mcp__webstorm__scl_get_interface`

---

## 4. Slash commands (workflows orquestrados)

Comandos em `.claude/commands/` encapsulam fluxos multi-agente repetíveis.

### `/new-block <tipo> <nome> "<descrição>"`
Orquestra a criação completa de um bloco:
1. `scl-architect` → plano de interface e lógica;
2. `scl-developer` → implementa e valida no MCP;
3. `scl-reviewer` → revisa;
4. se houver E-Stop/intertravamento → `safety-auditor`;
5. `tag-io-documenter` → atualiza tags.

### `/review-block <arquivo>`
Dispara `scl-reviewer` + `safety-auditor` em paralelo sobre um bloco e consolida.

### `/safety-check`
Varre todos os blocos com lógica de segurança via `safety-auditor`.

### `/io-sync`
`tag-io-documenter` reconcilia a lista de I/O com os blocos existentes (MCP).

---

## 4-bis. Skills (conhecimento sob demanda)

Diferente dos slash commands (você digita), **skills são auto-invocadas pelo Claude**
quando a `description` casa com a tarefa, e usam **divulgação progressiva** (só puxam o
detalhe quando preciso) — ideais para transformar os manuais grandes do `DOCS/` em
conhecimento cirúrgico sem reler arquivos de 277 KB.

| Skill | Dispara quando | Conteúdo |
|---|---|---|
| `scl-syntax` | escrever/editar/revisar `.scl` | regras de sintaxe Siemens, tipos, controle, operadores, bordas, chamadas; aponta p/ `DOCS/scl4.md` |
| `motion-control` | eixos, posicionamento, sincronismo | Technology Objects + instruções `MC_*` da 1518T |
| `scl-troubleshooting` | bloco não compila/valida ou se comporta mal | erros comuns, bugs de scan, precisão REAL/LREAL, uso do MCP |

Skills e subagentes se complementam: o **subagente** é *quem* faz (contexto isolado,
ferramentas); a **skill** é *o conhecimento* que ele puxa quando relevante. Ex.: o
`scl-developer` aciona `scl-syntax` ao codar; o `motion-specialist` aciona `motion-control`.

## 5. Hooks (automação determinística)

Configurados em `.claude/settings.json`. Hooks rodam código real do harness — não
dependem do julgamento do modelo.

| Evento | Gatilho | Ação |
|---|---|---|
| `PostToolUse` | após `Write`/`Edit` em `*.scl` | rodar `scl_validate_file` (MCP) e devolver erros ao agente |
| `PostToolUse` | após `Write`/`Edit` em `*.scl` | reformatar via WebStorm (`reformat_file`) |
| `PreToolUse` | `Edit`/`Write` fora de `OBs|FBs|FCs|DBs|UDTs` | exigir confirmação (protege manuais/config) |
| `UserPromptSubmit` | sempre | injetar lembrete do target real (1518T V3.1) |
| `Stop` | fim de turno | rodar validação do projeto inteiro, reportar pendências |

> Princípio: o **hook valida** (determinístico, sempre roda); o **subagente raciocina**.
> Não confie no agente para lembrar de validar — o hook garante.

---

## 6. Camada MCP (WebStorm SCL)

O servidor MCP do WebStorm expõe ferramentas que dão aos agentes **percepção real** do
projeto SCL (em vez de só manipular texto):

| Ferramenta | Uso |
|---|---|
| `scl_project_summary` | Visão geral: CPU, blocos, I/O — **sempre primeiro** |
| `scl_list_blocks` | Inventário de OB/FB/FC com caminhos |
| `scl_get_interface` | Interface (VAR_*) de um bloco para chamadas corretas |
| `scl_validate_file` | Valida sintaxe/semântica de um `.scl` |
| `scl_generate_fb` | Gera esqueleto de FB |
| `scl_read_io_list` | Lê a lista de I/O |

> ✅ **Target confirmado: S7-1500.** Configurado em `.idea/sclCpuSettings.xml`
> (`cpuFamily=S7_1500`, `firmwareVersion=S7_1500_ANY`) e `.idea/sclHardwareTarget.xml`
> (`target=S7_1500`). O MCP `scl_project_summary` confirma "Family: S7-1500". Para
> verificar/alterar: WebStorm `Settings → SCL` (seletor de CPU) ou o resumo do MCP.

---

## 7. CLAUDE.md como contexto central

O `CLAUDE.md` (já existente) é carregado em toda sessão e em todo subagente. Mantém:
hardware alvo, convenções de código, recursos S7-1500, cuidados. **Toda decisão de
arquitetura que vire regra permanente deve ser promovida ao CLAUDE.md**, não ficar só
no histórico de chat.

---

## 8. Permissões (settings.json)

Allowlist sugerida para reduzir prompts sem abrir mão de segurança:

- **Permitir:** ferramentas MCP `scl_*` (read/validate), `Read`/`Grep`/`Glob`.
- **Confirmar:** `Write`/`Edit` em `.scl`, `scl_generate_fb`.
- **Bloquear/confirmar sempre:** comandos destrutivos, escrita fora das pastas de código.

---

## 9. Fluxo orquestrado (exemplo end-to-end)

```
Usuário: "implemente o controle do transportador com partida/parada e E-Stop"
   │
   ├─ scl-architect  → plano: FB_Conveyor (FSM) + DB inst, chamada no OB_Main,
   │                    interface de tags, intertravamentos
   ├─ scl-developer  → escreve FB_Conveyor.scl, valida no MCP (hook reforça)
   ├─ scl-reviewer   → revisa ciclo de scan, CASE completo, conversões  ┐ paralelo
   ├─ safety-auditor → E-Stop NF, prioridade, reset deliberado          ┘
   ├─ tag-io-documenter → atualiza lista de tags/I-O
   └─ test-sim-engineer → casos de teste por transição p/ PLCSIM
   │
   └─ Orquestrador consolida e reporta ao usuário
```

A conversa principal atua como **orquestrador**: roteia para os subagentes pela
`description` de cada um, agrega resultados, e só traz ao usuário o que importa.

---

## 10. Roadmap de implementação

1. Criar `.claude/agents/` com os 7 subagentes acima.
2. Criar `.claude/commands/` com os 4 workflows.
3. Configurar `.claude/settings.json`: hooks de validação/format + permissões.
4. Corrigir o target do projeto para S7-1500/1518T no WebStorm/MCP.
5. Promover regras estáveis ao `CLAUDE.md`.
6. Validar o fluxo com um bloco piloto (`/new-block FB FB_Pilot "teste"`).

---

### Decisões em aberto (precisam do usuário)
- Confirmar os 7 papéis — algum a mais/menos? (ex.: agente de documentação técnica,
  agente de comunicação PROFINET/PROFIBUS).
- Nível de segurança: o projeto usará **F-CPU / blocos F (Safety)** ou só lógica
  standard? Isso define o peso do `safety-auditor`.
- Idioma dos artefatos gerados (código/comentários em PT; nomes de tags em EN?).
```