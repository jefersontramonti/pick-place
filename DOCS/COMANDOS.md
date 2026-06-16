# COMANDOS — referência de comandos manuais (aula01)

> Comandos que **você digita** no prompt do Claude Code para disparar uma ação.
> Digite `/` para ver a lista interativa; aqui estão todos descritos.
>
> Três grupos: **(1) comandos do projeto** (criados para este projeto SCL),
> **(2) skills automáticas** (o Claude invoca sozinho, mas você pode chamar),
> **(3) comandos embutidos do Claude Code** úteis no seu fluxo.

---

## 1. Comandos do projeto (SCL / S7-1500)

Ficam em `.claude/commands/`. Orquestram os subagentes do projeto.

| Comando | Argumentos | O que faz |
|---|---|---|
| `/new-block` | `<OB\|FB\|FC\|UDT> <Nome> "<descrição>"` | Cria um bloco SCL completo do zero, encadeando o time: **architect** (plano) → orquestrador grava `handoff.md` → **developer** (implementa+valida) → **reviewer** → **safety-auditor** (se houver segurança) → **motion-specialist** (se houver eixos) → **tag-io-documenter**. Não conclui com erro de validação ou achado CRÍTICO aberto. |
| `/review-block` | `<caminho ou nome do bloco>` | Revisa um bloco existente disparando **scl-reviewer** e **safety-auditor** em paralelo. Consolida achados por severidade (CRÍTICO/ALTO/MÉDIO/BAIXO) e propõe correções — **não** edita automaticamente. |
| `/safety-check` | (nenhum — varre o projeto) | Inventaria todos os blocos (`scl_list_blocks`), identifica os que têm lógica de segurança e roda o **safety-auditor** em cada um. Relatório único; destaca o que exigiria F-CPU/PROFIsafe. |
| `/io-sync` | (nenhum) | Aciona o **tag-io-documenter** para reconciliar `DOCS/tags.md` com o estado real (via `scl_project_summary` + `scl_read_io_list`). Reporta tags órfãs, usos sem declaração, divergência símbolo↔endereço e nomes fora da convenção. |
| `/wrap-session` | (nenhum) | Antes de encerrar a sessão: faz **append** de uma seção datada em `DOCS/PROJECT_STATE.md` (blocos mexidos, decisões, bugs, próximos passos). Promove decisões permanentes ao `CLAUDE.md`. É o que mantém os subagentes com contexto na próxima sessão. |

**Exemplos:**
```
/new-block FB FB_Valve "controla uma válvula com abre/fecha, fim de curso e timeout de falha"
/review-block FB_Motor
/safety-check
/io-sync
/wrap-session
```

---

## 2. Skills automáticas do projeto

Em `.claude/skills/`. O Claude as invoca sozinho quando o assunto aparece, mas você
pode forçar com `/`. São **conhecimento de referência**, não orquestração.

| Skill | Quando usar |
|---|---|
| `/scl-syntax` | Regras de sintaxe e idioma SCL Siemens (tipos, VAR/TEMP/STATIC, IF/CASE/FOR, bordas, chamada FB/FC). Consultada antes de gerar SCL. |
| `/scl-troubleshooting` | Diagnóstico de erros de compilação/runtime: sintaxe, ciclo de scan, conversão de tipo, REAL/LREAL, FB que não roda, falha de validação no MCP. |
| `/motion-control` | Controle de movimento na CPU 1518T: Technology Objects (eixos, sincronismo, cames) e instruções `MC_*`. |

---

## 3. Comandos embutidos do Claude Code (úteis aqui)

Disponíveis em qualquer projeto. Os mais relevantes para o seu fluxo:

| Comando | O que faz |
|---|---|
| `/code-review` | Revisa o diff atual em busca de bugs e limpezas. Nível por effort (low→max); `ultra` faz revisão multi-agente na nuvem. `--comment` posta em PR, `--fix` aplica. |
| `/review` | Revisa um pull request. |
| `/security-review` | Revisão de segurança das mudanças pendentes no branch. |
| `/simplify` | Revisa o código alterado buscando reuso/simplificação/eficiência e **aplica** os ajustes (só qualidade, não caça bugs). |
| `/verify` | Verifica que uma mudança realmente faz o que deveria, rodando e observando o comportamento. |
| `/run` | Sobe e dirige o app do projeto para ver uma mudança funcionando. |
| `/init` | Gera/atualiza um `CLAUDE.md` com a documentação do código. |
| `/loop` | Roda um prompt ou comando em intervalo recorrente (ex.: `/loop 5m /safety-check`). Sem intervalo = o modelo se autorregula. |
| `/schedule` | Cria/gerencia agentes em nuvem com agenda cron (tarefas recorrentes ou execução única agendada). |
| `/update-config` | Configura o harness via `settings.json`: permissões, variáveis de ambiente, hooks ("sempre que X, faça Y"). |
| `/keybindings-help` | Personaliza atalhos de teclado (`~/.claude/keybindings.json`). |
| `/fewer-permission-prompts` | Analisa o histórico e adiciona uma allowlist ao `settings.json` para reduzir prompts de permissão. |
| `/claude-api` | Referência da Claude API / SDK Anthropic (model ids, preços, streaming, tool use, MCP, caching). |

> **Comandos nativos do CLI** (não-skills, sempre disponíveis): `/help`, `/clear`,
> `/config`, `/fast` (liga/desliga o modo rápido do Opus), entre outros — digite `/`
> para ver. Para rodar um comando de shell direto na sessão, use o prefixo `!`
> (ex.: `! git status`).

---

## Como escolher rapidamente

- Vou **criar** um bloco novo → `/new-block`
- Já tenho um bloco e quero **revisar** → `/review-block <nome>`
- Quero **auditar segurança** do projeto todo → `/safety-check`
- Mexi em **E/S** e quero a doc em dia → `/io-sync`
- Vou **encerrar** a sessão → `/wrap-session`
- Dúvida de **sintaxe SCL** → `/scl-syntax`; **erro que não compila** → `/scl-troubleshooting`
- Vou mexer com **eixos/movimento** → `/motion-control`
