# Geração de sinais de pisca (clock/blink) para colunas sinalizadoras em S7‑1500 (SCL): por que o padrão TON auto‑rearmado falha sob Optimized Block Access

## TL;DR
- O padrão TON auto‑rearmado (`#s_tSlow(IN := NOT #s_tSlow.Q, ...)`) falha porque, no S7‑1500/1518T sob Optimized Block Access, **Q e ET de um timer IEC são recalculados a cada acesso simbólico ao instance**, e o valor de Q é lido por `NOT #s_tSlow.Q` no próprio `IN` — criando uma dependência circular (race condition) em um único scan na execução linear do SCL; combinado com a reescrita do PT a cada scan, o timer nunca produz um pulso de Q estável de 1 scan e a saída fica congelada.
- Para sinalização industrial de frequência fixa (colunas/torres de sinalização), a abordagem correta e recomendada é o **byte de marcadores de clock da CPU** (Clock memory byte / `Clock_1Hz` etc.): zero código, zero timers, onda quadrada determinística gerada pelo firmware, independente do tempo de scan.
- O verde funcionava porque era atribuído a um valor constante TRUE (não dependia de nenhum clock), enquanto amarelo e vermelho dependiam de `o_Slow`/`o_Fast` derivados do timer quebrado — por isso só o verde acendia e os demais nunca piscavam.

## Key Findings

1. **Timers IEC no S7‑1200/1500 não são "timers" clássicos; são instâncias cujos Q/ET funcionam como "getters" recalculados a cada acesso.** A documentação oficial Siemens (TIA Portal Information System, *TON: Generate on‑delay*, STEP 7 V20) declara que os valores de Q e ET são atualizados "When the instruction is called, if the ET or Q outputs are interconnected. Or — At an access to Q or ET." Ou seja: cada vez que você lê `.Q` ou `.ET`, o firmware recalcula o estado a partir da diferença entre o tempo de sistema atual e o tempo de início. Conforme a documentação Siemens citada pela DMC, Inc.: "The instruction data is updated both when the instruction is called and also each time the outputs Q or ET [are accessed]" e "You can have multiple updates of a timer in the same scan." Se você lê `.Q` duas vezes no mesmo ciclo, pode obter dois valores diferentes.

2. **A dependência circular IN↔Q em um único scan (race condition).** Em SCL a execução é linear, sem o atraso de rede entre networks do LAD/FBD. Na linha `#s_tSlow(IN := NOT #s_tSlow.Q, ...)` o `NOT #s_tSlow.Q` é avaliado **imediatamente antes** de o instance ser chamado/atualizado. A DMC, Inc., no artigo "Troubleshooting Your Siemens SIMATIC S7‑1200 Timers", descreve verbatim o mecanismo exato: "since TON_1SecondTimer.IN is FALSE, TON_1SecondTimer.Q is immediately set FALSE. So now when Network 2 is executed, TON_1SecondTimer.Q is again evaluated as FALSE and the output is not updated. This race condition makes it incredibly unlikely that the output will ever be updated." O pulso de Q nunca permanece TRUE por um scan inteiro de forma confiável — o toggle de `#s_SlowState` quase nunca dispara, e a saída fica congelada.

3. **Reescrever PT a cada scan agrava o problema e é explicitamente perigoso.** A Siemens documenta que "The value at the PT input is written to the PT parameter in the instance data when the edge changes at the IN input" — ou seja, PT é capturado apenas na borda de subida de IN. Além disso há o aviso oficial "Danger when reinitializing the actual values: Reinitializing the actual values of an IEC timer while the time measurement is running disrupts the function of the IEC timer. Changing the actual values can result in inconsistencies between the program and the actual process. This can cause serious damage to property and personal injury." Recalcular e reescrever PT todo ciclo via conversões de ponto flutuante mexe nos valores reais do instance enquanto a contagem corre.

4. **Arredondamento de ponto flutuante faz o período oscilar.** `DINT_TO_TIME(LREAL_TO_DINT(#t_halfSlow))` converte um LREAL para DINT (ms). `LREAL_TO_DINT` arredonda, então um meio‑período de ~166,67 ms pode alternar entre 166 e 167 ms entre scans, fazendo o PT "tremer" e, combinado com a captura de PT na borda de IN, produzindo jitter no período do sinal.

5. **A solução recomendada para frequência fixa é o byte de clock da CPU.** O firmware do S7‑1500 gera 8 ondas quadradas de razão pulso/pausa 1:1 em frequências fixas, sem código e sem timers, ideal para piscar lâmpadas sinalizadoras. Conforme a base de conhecimento da Industrial Monitor Direct, "The Clock Memory Byte is a system function with negligible CPU load."

## Details

### Como o S7‑1500 executa o scan e como o timer IEC realmente funciona

No S7‑1500 (incluindo a CPU 1518T‑4 PN/DP) com Optimized Block Access, os dados são armazenados de forma simbólica e otimizada; não há endereçamento absoluto dentro do bloco. O timer IEC (TON/TOF/TP/TONR) é uma instância (IEC_TIMER) cujos dados ficam num instance DB. Diferente dos antigos timers S5 do S7‑300/400, o "andamento" do timer não é mantido por um contador de hardware dedicado: o firmware calcula o tempo decorrido como a diferença entre o tempo de sistema atual e o instante de início, e **esse cálculo é refeito sempre que Q ou ET são acessados**.

Isto é confirmado pela documentação oficial. Na página oficial do PRESET_TIMER (STEP 7 V20) a Siemens afirma: "The instruction data is updated only when the instruction is called and each time the assigned IEC timer is accessed. The query on Q or ET (for example, "MyTimer".Q or "MyTimer".ET) updates the IEC_TIMER structure." A descrição oficial do TON detalha ainda a regra de atualização: "The actual values of the Q and ET outputs are updated... When the instruction is called, if the ET or Q outputs are interconnected. Or — At an access to Q or ET. If the outputs are not interconnected and also not queried, the current time value at the Q and ET outputs is not updated."

Engenheiros que migraram do S7‑300 para o S7‑1500 descrevem o efeito em fóruns técnicos (PLCtalk): "Q and ET can be seen as getter methods from C# for example. The time values are always refreshed when you access the Q or ET value. If you do this more than once in a cycle, then you may get different Q states / ET time values." Outro relata um teste: colocando o TON numa tarefa de 100 ms e lendo ET numa tarefa de 10 ms, "the elapsed time was incrementing by 10ms and not 100ms; meaning that just accessing the memory caused the timer to increment its time."

### Por que o padrão específico do usuário falhou

O código:
```
#s_tSlow(IN := NOT #s_tSlow.Q, PT := DINT_TO_TIME(LREAL_TO_DINT(#t_halfSlow)));
IF #s_tSlow.Q THEN
    #s_SlowState := NOT #s_SlowState;
END_IF;
```

Sequência de eventos em um scan, em execução linear SCL:

1. Avalia‑se `NOT #s_tSlow.Q`. Esse acesso a `.Q` **recalcula** o estado do timer naquele instante. Enquanto ET < PT, Q=FALSE, logo IN=TRUE — o timer conta.
2. Quando ET atinge PT, no scan em que isso ocorre, o acesso `NOT #s_tSlow.Q` já enxerga Q=TRUE (recalculado). Então passa‑se IN=FALSE para a chamada do timer.
3. Com IN=FALSE, o TON é resetado imediatamente: ET→0, Q→FALSE. (Esta é exatamente a race condition descrita pela DMC: "since ...IN is FALSE, ...Q is immediately set FALSE".)
4. Na linha seguinte, `IF #s_tSlow.Q` lê Q novamente — agora recalculado como FALSE (timer resetado). O toggle de `#s_SlowState` quase nunca acontece, ou acontece de forma errática.

O resultado é que `#s_SlowState` (e portanto `o_Slow`) raramente ou nunca alterna de modo estável; a saída fica "congelada". O mesmo vale para `o_Fast`. Como o verde foi escrito como constante TRUE (não dependente de clock algum), ele permanece aceso normalmente — o que explica exatamente o sintoma observado: **verde ligado, amarelo e vermelho sem piscar**.

Liam Bee, em liambee.me ("TIA Portal – TON / TOF / TP Timers And Different Use Cases"), documenta o efeito correlato e a correção: "There is a bug in TIA Portal, which has been there since TIA V13 at least, whereby using Instance Data of the Timer's Q value to perform the same logic can result in erratic behaviour. It is always best to write Q to a Static variable and use that instead." Em LAD/FBD o mesmo padrão `IN := NOT Q` costuma funcionar porque a leitura do contato Q e a chamada do timer ocorrem em pontos diferentes da varredura e a topologia de rede introduz o atraso de 1 scan; em SCL linear esse atraso não existe.

### O efeito da reescrita do PT e do ponto flutuante

Mesmo que a dependência circular fosse resolvida, reescrever PT a cada scan é problemático:
- PT só é adotado na borda de subida de IN ("The value at the PT input is written to the PT parameter in the instance data when the edge changes at the IN input"). Mudar PT no meio da contagem não afeta o ciclo atual; para forçar recálculo é preciso a instrução PRESET_TIMER (o equivalente SCL da "PT coil"), que a própria Siemens adverte que "overwrites the current time of the specified IEC timer. This can change the timer status."
- `LREAL_TO_DINT` arredonda. Um meio‑período não inteiro (ex.: 1000/6 ≈ 166,67 ms) alterna entre 166 e 167 ms conforme o LREAL recalculado, introduzindo jitter no período.
- Escrever os valores reais do instance enquanto a contagem corre cai no aviso oficial "Danger when reinitializing the actual values... disrupts the function of the IEC timer."

### Comparação das três abordagens

**(a) Byte de marcadores de clock da CPU (Clock memory byte)**
- O que é: um byte de bit‑memory que, segundo a Siemens, "changes its binary status periodically in the pulse‑no‑pulse ratio of 1:1", gerado pelo firmware. Habilitado em Propriedades da CPU → marcadores de clock; cada bit tem uma frequência fixa.
- Tabela oficial (S7‑1500): bit 0 = 10 Hz (0,1 s), bit 1 = 5 Hz (0,2 s), bit 2 = 2,5 Hz (0,4 s), bit 3 = 2 Hz (0,5 s), bit 4 = 1,25 Hz (0,8 s), bit 5 = 1 Hz (1,0 s), bit 6 = 0,625 Hz (1,6 s), bit 7 = 0,5 Hz (2,0 s). Em S7‑1500 também há as constantes de sistema `Clock_1Hz`, `Clock_2Hz`, etc. Mapeamento confirmado por fontes nomeadas: InstrumentationTools ("if you need to use the 2Hz clock bit you will use the bit %M0.3") e Industrial Monitor Direct ("For a pulse every second, use Bit 5... If using MB0, the address is M0.5. This bit toggles every 0.5 seconds, resulting in a positive edge every 1.0 seconds.").
- Prós: zero código, zero recursos de timer; determinístico; **imune ao tempo de scan**; trivial de configurar; ideal para sinalização. Custo de CPU desprezível (Industrial Monitor Direct: "negligible CPU load").
- Contras: frequências fixas (não configuráveis livremente); duty cycle fixo em 50%; fase não controlável; assíncrono ao ciclo da CPU (a Siemens adverte: "Clock memory runs asynchronously to the CPU cycle, i.e. the status of the clock memory can change several times during a long cycle" e "The selected memory byte cannot be used for intermediate storage of data"); usa área de bit‑memory não‑otimizada, contrariando a recomendação do *Programming Guideline for S7‑1200/1500* (Entry ID 81318674), seção "No bit memory but global data blocks".
- Uso em SCL: basta `#o_Slow := "Clock_1Hz";` (ou ANDar com a condição de alarme: `#o_Red := #Alarme AND "Clock_1Hz";`).

**(b) Padrão TON auto‑rearmado em SCL**
- O que é: `Tmr(IN := NOT Tmr.Q, PT := T#500ms)` para gerar um pulso periódico.
- Prós: frequência configurável via PT; conceitualmente simples.
- Contras: como demonstrado, frágil em SCL otimizado por causa do recálculo de Q em cada acesso e da race condition num único scan; requer escrever Q numa variável Static antes de usar; o *Programming Guideline* 81318674 lista explicitamente "Avoiding of time‑processing blocks: TP, TON, TOF" como tópico (relevante sobretudo para F‑program e portabilidade); custo de CPU e de gestão de estado maiores que o byte de clock. Não recomendado para frequência fixa de sinalização.

**(c) Acumulação de tempo (somar TIME decorrido e alternar no meio‑período)**
- O que é: acumular o tempo de ciclo (ex.: usando o tempo decorrido/`OB1_PREV_CYCLE` ou o ET de um único timer livre) numa variável e alternar um bit de estado quando o acumulado atinge o meio‑período; o Q/estado é "congelado" numa variável Static antes de ser usado em qualquer condição.
- Prós: frequência totalmente configurável; determinístico se o acumulador for lido/escrito uma única vez por ciclo; controle de fase e de duty cycle; usa um único recurso de tempo. Pode usar o ET de um timer com PT alto e comparadores para múltiplas saídas.
- Contras: mais código e gestão de estado; precisão limitada pela granularidade/variação do tempo de scan; exige disciplina (ler Q/estado uma vez, guardar em Static). Boa opção quando se precisa de frequência arbitrária e determinística que o byte de clock não oferece.

### Abordagem correta/recomendada para colunas sinalizadoras

Para torres/colunas de sinalização (stack lights) com frequências de pisca fixas, a prática industrial padrão e a recomendação Siemens é usar o **byte de marcadores de clock**. Para frequências de alarme típicas, 2 Hz é uma taxa de pisca lenta comum e ~4 Hz uma taxa rápida; o byte de clock oferece 0,5 / 0,625 / 1 / 1,25 / 2 / 2,5 / 5 / 10 Hz prontos.

Padrão recomendado em SCL:
```
// Verde: aceso fixo quando em automático/rodando
#o_Green := #Auto AND #Running;
// Amarelo: pisca lento em advertência
#o_Yellow := #Warning AND "Clock_1Hz";
// Vermelho: pisca rápido em alarme não reconhecido, fixo se reconhecido
#o_Red := #Alarm AND (#Acknowledged OR "Clock_2Hz");
```
Se for necessária uma frequência que o byte de clock não fornece, ou controle de fase/duty cycle, usar a abordagem (c) de acumulação de tempo com o estado congelado em Static — não o padrão (b) auto‑rearmado em SCL.

As cores em si não têm um padrão único obrigatório (a IEC 61131‑3 cobre a linguagem, não as cores), mas convenções comuns seguem IEC 60073/IEC 60204‑1 e ANSI/NFPA 79: vermelho = falha/parada, amarelo/âmbar = advertência, verde = funcionando normalmente; piscar adiciona urgência (ex.: vermelho piscando = falha; vermelho fixo = parada).

## Recommendations

1. **Imediato — trocar o gerador de pisca pelo byte de clock da CPU.** Habilite o clock memory byte nas propriedades da CPU 1518T‑4 (ex.: MB0, dando `Clock_1Hz` em M0.5, `Clock_2Hz` em M0.3), recompile e baixe o hardware. Substitua `o_Slow`/`o_Fast` por `Clock_1Hz`/`Clock_2Hz` (ou as frequências desejadas) ANDados com as condições de estado. Isto resolve o sintoma com mínimo esforço e máxima robustez.

2. **Se precisar manter a frequência configurável** (não disponível no byte de clock): use a abordagem de acumulação de tempo (c), com um único timer livre ou acumulador de tempo de ciclo, e **congele Q/estado numa variável STATIC** lida uma única vez por ciclo. Não dependa de `NOT Tmr.Q` diretamente no `IN` em SCL.

3. **Se insistir em TON em SCL**, corrija o padrão: (i) leia `.Q` uma única vez para uma variável Static no início (`#qSlow := #s_tSlow.Q;`), use essa variável tanto para o `IN` quanto para o toggle; (ii) **não reescreva PT todo scan** — calcule PT uma vez (na partida ou quando a frequência mudar) e, se precisar mudar em runtime, use PRESET_TIMER; (iii) elimine o arredondamento LREAL→DINT do caminho de runtime, pré‑calculando o PT em TIME.

4. **Higiene geral:** mantenha o verde dependente de uma condição real de estado (já é o caso). Documente a tabela de cores/padrões de pisca conforme IEC 60204‑1/NFPA 79. Use DBs globais otimizados em vez de bit‑memory para dados de estado (recomendação do *Programming Guideline* 81318674, seção "No bit memory but global data blocks"), reservando o byte de clock apenas para os bits de clock.

**Limiares que mudariam a recomendação:** se a frequência exigida for uma das fixas do byte de clock → abordagem (a). Se exigir frequência arbitrária, fase ou duty cycle ≠ 50% → abordagem (c). O padrão (b) auto‑rearmado em SCL não é recomendado em nenhum caso de sinalização de frequência fixa.

## Caveats
- A documentação oficial Siemens descreve o mecanismo (PT capturado na borda de IN; Q/ET atualizados a cada acesso) e contém o aviso "Danger when reinitializing the actual values", mas **não há uma frase oficial dizendo literalmente "mudar PT com o timer rodando é ignorado"** — isso é uma consequência documentada implicitamente (PT só é escrito na borda de IN) e corroborada por fontes de engenharia de terceiros (ex.: liambee.me).
- A frase frequentemente citada "The instruction data is updated both when the instruction is called and also each time the outputs Q or ET are accessed" aparece atribuída ao Information System da Siemens em fontes de terceiros (DMC, Inc.); a redação oficial equivalente confirmada nas páginas Siemens é a do TON e do PRESET_TIMER citadas acima.
- O Entry ID 81318674 resolve atualmente para o conjunto "Programming Guideline / Style Guide for S7‑1200/S7‑1500"; as versões variam (v11–v20) e a numeração de páginas/seções difere entre elas.
- O comportamento exato de um pulso TON auto‑rearmado pode variar com versão de firmware/TIA Portal e com o ponto do programa onde `.Q` é lido; o ponto robusto é não depender desse padrão em SCL.
- O byte de clock é assíncrono ao ciclo e pode mudar várias vezes num ciclo longo — irrelevante para acionar lâmpadas, mas inadequado para contar pulsos sem detecção de borda.
- Convenções de cor de stack light não são padronizadas por norma única; siga a convenção do cliente/planta documentada.