$ErrorActionPreference = 'SilentlyContinue'
$roots = @(
  "$HOME\Desktop",
  "$HOME\Documents",
  "$HOME\Downloads",
  "$HOME\Pictures",
  "$HOME\Videos",
  "$HOME\Music"
) | Where-Object { Test-Path $_ }
$rows = foreach ($root in $roots) {
  $files = Get-ChildItem $root -File -Recurse -Force -ErrorAction SilentlyContinue
  [pscustomobject]@{
    Root = $root
    Files = $files.Count
    Bytes = ($files | Measure-Object Length -Sum).Sum
    GiB = [math]::Round((($files | Measure-Object Length -Sum).Sum / 1GB), 2)
  }
}
$rows | Format-Table -AutoSize
$total = ($rows | Measure-Object Bytes -Sum).Sum
"TOTAL_GIB=$([math]::Round($total/1GB,2))"
"NOTE=Inventory only; no files copied or deleted."
