$src = "c:\Users\raean\Documents\flutter\package 2"
$dst = "c:\Users\raean\Documents\flutter\temp_release\share_harbor"
$zip = "c:\Users\raean\Documents\flutter\share_harbor_v0.1.0-beta.1_clean.zip"

if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
if (Test-Path $zip) { Remove-Item $zip -Force }

Get-ChildItem -Path $src -Recurse | Where-Object {
    $_.FullName -notmatch '\\(build|\.dart_tool|\.git|\.idea|\.gradle|coverage)($|\\)' -and
    $_.Name -notmatch '^(MASTER_PROMPT.*|\.zip)$'
} | ForEach-Object {
    $rel = $_.FullName.Substring($src.Length)
    $target = Join-Path $dst $rel
    if ($_.PSIsContainer) {
        New-Item -ItemType Directory -Path $target -Force | Out-Null
    } else {
        $parent = Split-Path $target
        if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Copy-Item -Path $_.FullName -Destination $target -Force
    }
}

Compress-Archive -Path $dst -DestinationPath $zip -Force
Remove-Item "c:\Users\raean\Documents\flutter\temp_release" -Recurse -Force
Get-FileHash -Path $zip -Algorithm SHA256
