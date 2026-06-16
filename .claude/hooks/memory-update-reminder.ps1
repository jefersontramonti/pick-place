# Hook SessionStart (source = compact|resume): roda logo APOS uma compactacao/retomada do
# contexto — o momento em que detalhes foram resumidos. Lembra o agente de reconciliar a
# memoria persistente e o PROJECT_STATE com o estado real do projeto.
# (PreCompact nao serve: NAO injeta additionalContext no modelo; so 'decision:block'.
#  SessionStart injeta contexto e e o ponto certo para reconciliar apos a perda.)
$raw = [Console]::In.ReadToEnd()
try { $null = $raw | ConvertFrom-Json } catch { }

$mem = 'C:\Users\maninho\.claude\projects\C--Users-maninho-Desktop-aula01\memory\'
$msg = "Contexto compactado/retomado: reconcilie o estado duravel AGORA. Verifique se a " +
       "memoria ($mem MEMORY.md + arquivos) e DOCS/PROJECT_STATE.md refletem o estado real " +
       "do projeto (decisoes, blocos criados/validados, pendencias, proximos passos) e " +
       "atualize o que estiver defasado. Confira fatos contra os arquivos antes de gravar. " +
       "Ver feedback keep-context-in-sync e a secao 'Documentos vivos' do CLAUDE.md."

$out = @{ hookSpecificOutput = @{ hookEventName = 'SessionStart'; additionalContext = $msg } } | ConvertTo-Json -Compress
Write-Output $out
exit 0