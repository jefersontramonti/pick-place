# Handoff: StationData (DB global)

**Decisão de arquitetura:** DB **global** único da estação, repositório central de dados
acessado pela HMI e por todos os FBs/FCs por referência (`IN_OUT`). Contém **um** membro
`Station : "typeStation"` (UDT já criado), conforme o argumento do `/new-block`. Acesso dos
consumidores: `"StationData".Station.Cmd.*` / `.Cfg.*` / `.Sts.*`. Fonte:
`DOCS/ARQUITETURA_PickPlace.md` §1 (linha do `StationData`) e §2.2 (`typeStation`).

> ⚠️ Convenção de acesso: a §6 da arquitetura escreve atalhos como `StationData.Cmd`/`.Sts`
> — leia como `StationData.Station.Cmd`/`.Sts` (há o wrapper `Station`). Os FCs/FBs futuros
> (`FC_IoMap*`, `OB_Main`) devem usar `"StationData".Station.<campo>`.

Estrutura a implementar:
```
DATA_BLOCK "StationData"
{ S7_Optimized_Access := 'TRUE' }
VERSION : 0.1
   STRUCT
      Station : "typeStation";   // dados da estação: Cmd / Cfg / Sts
   END_STRUCT;
BEGIN
   // Start values herdados de typeStation.Cfg (Enabled:=TRUE, setpoints X/Z, tolerancias,
   // velocidades, delays, pisca). Para customizar por deployment, descomente e ajuste, ex.:
   // Station.Cfg.ConvSpeed   := 5.0;
   // Station.Cfg.SeqStepTimeout := T#30s;
END_DATA_BLOCK
```
Regras: `{ S7_Optimized_Access := 'TRUE' }`, `VERSION : 0.1`, comentários PT, nomes EN.
Arquivo: `DBs/StationData.scl`. Depende de `UDTs/typeStation.scl` (→ `typeAxis.scl`), ambos
já existem e validam. **Não** preencher start values agora (os defaults do UDT já servem);
deixar BEGIN com os exemplos comentados, no padrão dos DBs do projeto.

**Restrições de safety:** nenhuma direta — DB é dado, sem lógica. Observação para os
consumidores (não para este bloco): `Station.Cmd.EStop`/`Stop` são **NF** e `Station.Cfg.
Enabled` default **TRUE** (estação habilita o ciclo por padrão — diferente do projeto antigo
de motores, onde Enabled era FALSE). O safety-auditor valida o tratamento NF no
`FB_MachineMode`, não aqui. Safety **não aplicável** ao DB em si.

**Tags I/O reservadas:** nenhuma — o DB não tem endereço físico (acesso simbólico pela HMI).
O mapeamento das tags físicas (`%I0.3–%I1.1`, `%ID30/34`, `%Q*`, `%QD*`) vive em
`FC_IoMapInputs`/`FC_IoMapOutputs`. Tag-io-documenter: nada a catalogar neste bloco.
`FB_StationData` **não** existe — é DB global (não DB de instância), criado a partir do UDT.

**Casos de teste pendentes:** nenhum isolado — o DB é exercitado pelos FBs que o consomem.
O test-sim-engineer cobre lá (estados, sequência, intertravamentos).
