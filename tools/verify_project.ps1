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
    (Join-Path $gameRoot "scripts\aircraft_audio.gd"),
    (Join-Path $gameRoot "scripts\camera_rig.gd"),
    (Join-Path $gameRoot "scripts\hud.gd"),
    (Join-Path $gameRoot "tests\smoke_test.gd")
)

$missingFiles = $requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_) }
if ($missingFiles) {
    Write-Error ("Missing required files:`n" + ($missingFiles -join "`n"))
    exit 1
}

$git = Get-Command "git" -ErrorAction SilentlyContinue
if ($git) {
    $trackedPaths = & $git.Source -c "safe.directory=$projectRoot" -C $projectRoot ls-files
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Could not inspect tracked files with Git."
        exit $LASTEXITCODE
    }
    $forbiddenFiles = $trackedPaths |
        ForEach-Object { Get-Item -LiteralPath (Join-Path $projectRoot $_) } |
        Where-Object {
            $_.Extension -in @(".iso", ".bin", ".chd", ".elf", ".irx")
        }
} else {
    $forbiddenFiles = Get-ChildItem -LiteralPath $projectRoot -Recurse -File |
        Where-Object {
            $_.FullName -notmatch "[\\/]\.godot[\\/]" -and
            $_.Extension -in @(".iso", ".bin", ".chd", ".elf", ".irx")
        }
}
if ($forbiddenFiles) {
    Write-Error ("Forbidden tracked original-game files found:`n" + ($forbiddenFiles.FullName -join "`n"))
    exit 1
}

$godot = Get-Command $GodotCommand -ErrorAction SilentlyContinue
if (-not $godot) {
    Write-Warning "Static checks passed, but Godot was not found. Runtime verification remains pending."
    exit 0
}

$editorOutput = & $godot.Source --headless --editor --path $gameRoot --quit 2>&1
$editorExitCode = $LASTEXITCODE
$editorOutput | ForEach-Object { Write-Output $_.ToString() }
$editorText = $editorOutput -join [Environment]::NewLine
if (
    $editorExitCode -ne 0 -or
    $editorText -match "SCRIPT ERROR:" -or
    $editorText -match "Failed to load script"
) {
    Write-Error "Godot import/parser verification failed."
    exit $(if ($editorExitCode -ne 0) { $editorExitCode } else { 1 })
}

$smokeOutput = & $godot.Source --headless --path $gameRoot --script "res://tests/smoke_test.gd" 2>&1
$smokeExitCode = $LASTEXITCODE
$smokeOutput | ForEach-Object { Write-Output $_.ToString() }
$smokeText = $smokeOutput -join [Environment]::NewLine
if (
    $smokeExitCode -ne 0 -or
    $smokeText -match "SCRIPT ERROR:" -or
    $smokeText -match "Failed to load script"
) {
    Write-Error "Godot physics smoke test failed."
    exit $(if ($smokeExitCode -ne 0) { $smokeExitCode } else { 1 })
}

Write-Output "Static checks, Godot import/parser verification, and physics smoke test passed."
