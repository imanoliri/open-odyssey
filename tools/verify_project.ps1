param(
    [string]$GodotCommand = "godot"
)

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$gameRoot = Join-Path $projectRoot "game"
$projectFile = Join-Path $gameRoot "project.godot"
$mainScene = Join-Path $gameRoot "scenes\main.tscn"

$requiredFiles = @(
    $projectFile,
    $mainScene,
    (Join-Path $gameRoot "scripts\main.gd"),
    (Join-Path $gameRoot "scripts\aircraft.gd"),
    (Join-Path $gameRoot "scripts\camera_rig.gd"),
    (Join-Path $gameRoot "scripts\hud.gd"),
    (Join-Path $gameRoot "tests\smoke_test.gd")
)

$missingFiles = $requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_) }
if ($missingFiles) {
    Write-Error ("Missing required files:`n" + ($missingFiles -join "`n"))
    exit 1
}

$forbiddenFiles = Get-ChildItem -LiteralPath $projectRoot -Recurse -File |
    Where-Object {
        $_.FullName -notmatch "[\\/]\.godot[\\/]" -and
        $_.Extension -in @(".iso", ".bin", ".chd", ".elf", ".irx")
    }
if ($forbiddenFiles) {
    Write-Error ("Forbidden original-game files found:`n" + ($forbiddenFiles.FullName -join "`n"))
    exit 1
}

$godot = Get-Command $GodotCommand -ErrorAction SilentlyContinue
if (-not $godot) {
    Write-Warning "Static checks passed, but Godot was not found. Runtime verification remains pending."
    exit 0
}

& $godot.Source --headless --editor --path $gameRoot --quit
if ($LASTEXITCODE -ne 0) {
    Write-Error "Godot import/parser verification failed."
    exit $LASTEXITCODE
}

& $godot.Source --headless --path $gameRoot --script "res://tests/smoke_test.gd"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Godot physics smoke test failed."
    exit $LASTEXITCODE
}

Write-Output "Static checks, Godot import/parser verification, and physics smoke test passed."
