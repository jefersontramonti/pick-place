---
name: motion-control
description: Controle de movimento (Motion Control) na CPU Technology S7-1500 1518T-4 PN/DP — Technology Objects (eixos, sincronismo, cames) e instruções MC_* (MC_Power, MC_Home, MC_MoveAbsolute, MC_MoveJog, MC_GearIn, etc.). Use ao programar eixos, posicionamento, velocidade, referenciamento ou sincronismo.
---

# Motion Control — S7-1500 Technology CPU (1518T)

A CPU **1518T-4 PN/DP** é Technology CPU: suporta Motion Control via Technology Objects
(TO) e instruções `MC_*`. Convenções: comentários PT, nomes EN, lógica standard.

## Technology Objects (TO)
- `TO_PositioningAxis` — eixo de posicionamento (linear/rotativo).
- `TO_SynchronousAxis` — eixo sincronizável (gearing/cam).
- `TO_ExternalEncoder` — encoder externo.
- `TO_Cam` / cames — leva eletrônica.
- O TO é configurado no TIA Portal; no código você referencia o TO pelo nome.

## Instruções MC_* (cada uma com DB de instância próprio)
| Instrução | Função |
|---|---|
| `MC_Power` | Habilita/desabilita o eixo (manter chamada cíclica enquanto ativo) |
| `MC_Home` | Referencia (homing) o eixo |
| `MC_MoveAbsolute` | Move para posição absoluta |
| `MC_MoveRelative` | Move distância relativa |
| `MC_MoveVelocity` | Move em velocidade constante |
| `MC_MoveJog` | Jog (manual, enquanto comando ativo) |
| `MC_Halt` | Para o movimento de forma controlada |
| `MC_Reset` | Confirma/limpa falhas do eixo |
| `MC_GearIn` / `MC_GearOut` | Entra/sai de sincronismo (gearing) |

## Padrão de uso (sempre)
1. **Habilitar:** `MC_Power(Axis := "Axis1", Enable := TRUE, ...)` — chamar todo scan.
2. **Referenciar:** `MC_Home(...)` antes de movimentos absolutos.
3. **Mover:** disparar `MC_MoveAbsolute`/etc. por borda em `Execute`.
4. **Tratar status SEMPRE:** `Done`, `Busy`, `Active`, `CommandAborted`, `Error`,
   `ErrorID`/`Status`. Nunca disparar novo comando sem checar `Busy`/`Done`.

```scl
"MC_Power_DB"(Axis := "Axis1", Enable := s_AxisEnable);
"MC_MoveAbsolute_DB"(Axis := "Axis1",
                     Execute := s_MoveEdge.Q,
                     Position := #t_TargetPos,
                     Velocity := #t_Vel);
IF "MC_MoveAbsolute_DB".Error THEN
    s_FaultCode := "MC_MoveAbsolute_DB".ErrorID;
END_IF;
```

## Segurança (coordenar com safety-auditor)
- Em falha/emergência: `MC_Halt` e **desabilitar `MC_Power`** (estado seguro).
- Não permitir movimento sem homing válido quando a aplicação exigir.
- Tratar `CommandAborted` quando um comando substitui outro.

Para parâmetros completos de cada `MC_*`, consultar a documentação TIA do TO/instrução.
