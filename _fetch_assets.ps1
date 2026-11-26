param([string]$AssetsRoot)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$headers = @{"User-Agent"="GodotGameSetup/1.0"}

function Download-IfMissing([string]$Url, [string]$Dest) {
    if (Test-Path $Dest) { return }
    $dir = Split-Path $Dest -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    Write-Host "  -> $(Split-Path $Dest -Leaf)"
    & curl.exe -fsSL --retry 3 $Url -o $Dest
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $Dest)) {
        throw "Failed downloading $Url"
    }
}

# 1. Terrain3D Demo PBR Textures & Rocks
$tDir = Join-Path $AssetsRoot "textures\terrain"
$t3dBase = "https://raw.githubusercontent.com/TokisanGames/Terrain3D/main/project/demo/assets"
foreach ($f in @("ground037_alb_ht.png","ground037_nrm_rgh.png","rock023_alb_ht.png","rock023_nrm_rgh.png")) {
    Download-IfMissing "$t3dBase/textures/$f" (Join-Path $tDir $f)
}
$mDir = Join-Path $AssetsRoot "models"
foreach ($f in @("RockA.glb","RockB.glb","RockC.glb")) {
    Download-IfMissing "$t3dBase/models/$f" (Join-Path $mDir $f)
}

# 2. PolyHaven 1K CC0 PBR Textures (JPGs)
$pbrDir = Join-Path $AssetsRoot "textures\pbr"
foreach ($tid in @("forrest_ground_01","coast_sand_01","marble_01","wood_planks_dirt","herringbone_parquet","american_walnut_veneer","painted_plaster_wall","fabric_leather_02","denim_fabric")) {
    $sub = Join-Path $pbrDir $tid
    $diff = Join-Path $sub "diff.jpg"
    $nor  = Join-Path $sub "nor.jpg"
    $rgh  = Join-Path $sub "rough.jpg"
    if ((Test-Path $diff) -and (Test-Path $nor) -and (Test-Path $rgh)) { continue }
    $info = Invoke-RestMethod -Uri "https://api.polyhaven.com/files/$tid" -Headers $headers
    Download-IfMissing $info.Diffuse."1k".jpg.url $diff
    Download-IfMissing $info.nor_gl."1k".jpg.url $nor
    Download-IfMissing $info.Rough."1k".jpg.url $rgh
}

# 3. PolyHaven 1K CC0 Plant / Nature GLTFs
foreach ($mid in @("fern_02","flower_gazania","grass_medium_01","boulder_01","dead_tree_trunk")) {
    $mSub = Join-Path $mDir $mid
    $gltfPath = Join-Path $mSub "$mid.gltf"
    if (Test-Path $gltfPath) { continue }
    $info = Invoke-RestMethod -Uri "https://api.polyhaven.com/files/$mid" -Headers $headers
    $g = $info.gltf."1k".gltf
    Download-IfMissing $g.url $gltfPath
    if ($g.include) {
        foreach ($prop in $g.include.PSObject.Properties) {
            $rel = $prop.Name -replace '/', '\'
            Download-IfMissing $prop.Value.url (Join-Path $mSub $rel)
        }
    }
}

# 4. Real Rigged & Animated CC0 Animal & Bird GLBs
$aDir = Join-Path $mDir "animals"
Download-IfMissing "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Fox/glTF-Binary/Fox.glb" (Join-Path $aDir "Fox.glb")
Download-IfMissing "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Duck/glTF-Binary/Duck.glb" (Join-Path $aDir "Duck.glb")
Download-IfMissing "https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/gltf/Stork.glb" (Join-Path $aDir "Stork.glb")
Download-IfMissing "https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/gltf/Parrot.glb" (Join-Path $aDir "Parrot.glb")
Download-IfMissing "https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/gltf/Flamingo.glb" (Join-Path $aDir "Flamingo.glb")
Download-IfMissing "https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/gltf/Horse.glb" (Join-Path $aDir "Horse.glb")
Download-IfMissing "https://raw.githubusercontent.com/Vuena/free-low-poly-animals-cc0/main/GLB/animal_owl.glb" (Join-Path $aDir "animal_owl.glb")
Download-IfMissing "https://raw.githubusercontent.com/Vuena/free-low-poly-animals-cc0/main/GLB/animal_fox.glb" (Join-Path $aDir "animal_fox.glb")

Write-Host "[OK] All PBR textures, nature models, and animal GLBs ready."
