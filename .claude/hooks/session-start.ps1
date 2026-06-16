# Hook SessionStart: injeta lembrete operacional no início da sessão.
# Saída JSON com additionalContext é adicionada ao contexto do modelo.
$msg = 'Projeto SCL S7-1500. CPU real: 1518T-4 PN/DP (Technology/Motion, FW V3.1). ' +
       'Target do WebStorm/MCP confirmado como S7-1500 (config em .idea/sclCpuSettings.xml e ' +
       'sclHardwareTarget.xml). Convencoes: comentarios em PT, tags em EN, logica standard (sem F-CPU).'
$out = @{ hookSpecificOutput = @{ hookEventName = 'SessionStart'; additionalContext = $msg } } | ConvertTo-Json -Compress
Write-Output $out
exit 0
