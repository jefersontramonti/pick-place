# Hook PostToolUse (Write|Edit): se um arquivo .scl foi alterado, lembra o agente de
# validar via MCP. Hooks nao chamam MCP diretamente, entao reforcamos por contexto.
$raw = [Console]::In.ReadToEnd()
try { $j = $raw | ConvertFrom-Json } catch { exit 0 }
$fp = $j.tool_input.file_path
if ($fp -and ($fp -match '\.scl$')) {
    $msg = "Bloco .scl alterado ($fp). Valide com mcp__webstorm__scl_validate_file e " +
           "corrija erros/avisos antes de marcar como concluido."
    $out = @{ hookSpecificOutput = @{ hookEventName = 'PostToolUse'; additionalContext = $msg } } | ConvertTo-Json -Compress
    Write-Output $out
}
exit 0
