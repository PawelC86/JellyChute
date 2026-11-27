$ErrorActionPreference = 'Stop'
$build = Join-Path $PSScriptRoot '../build'
$gradle = Join-Path $build 'build.gradle'
$manifest = Join-Path $build 'src/main/AndroidManifest.xml'
if (!(Test-Path $gradle)) { throw 'Install the Godot Android build template first.' }
$text = [IO.File]::ReadAllText($gradle)
$line = "apply from: '../updates/updates.gradle'"
if (!$text.Contains($line)) { [IO.File]::WriteAllText($gradle, $text + "`n" + $line + "`n") }
$text = [IO.File]::ReadAllText($manifest)
if (!$text.Contains('org.godotengine.plugin.v2.JellyChuteAppUpdates')) {
    $text = $text.Replace('</application>', '<meta-data android:name="org.godotengine.plugin.v2.JellyChuteAppUpdates" android:value="com.godot.game.JellyChuteAppUpdates" /></application>')
    [IO.File]::WriteAllText($manifest, $text)
}

$text = [IO.File]::ReadAllText($manifest)
if (!$text.Contains('org.godotengine.plugin.v2.JellyChuteAppReview')) {
    $text = $text.Replace('</application>', '<meta-data android:name="org.godotengine.plugin.v2.JellyChuteAppReview" android:value="com.godot.game.JellyChuteAppReview" /></application>')
    [IO.File]::WriteAllText($manifest, $text)
}
