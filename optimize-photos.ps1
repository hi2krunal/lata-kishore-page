# Rebuilds images/photoNN.jpg from the camera originals in images/IMG_*.JPEG.
# Re-run this after dropping new originals in, then update the PHOTOS list in index.html.
# Saving through a fresh Bitmap also drops EXIF (camera model, timestamps, any GPS).

Add-Type -AssemblyName System.Drawing

$maxEdge = 900
$quality = 78L
$imagesDir = Join-Path $PSScriptRoot "images"

$encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
    Where-Object { $_.MimeType -eq "image/jpeg" }
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
    [System.Drawing.Imaging.Encoder]::Quality, $quality)

Get-ChildItem -File (Join-Path $imagesDir "photo*.jpg") | Remove-Item -Force

# The three 5908-5910 shots stay first so the small wall frames keep their photos.
$ordered = @()
$ordered += Get-ChildItem -File (Join-Path $imagesDir "IMG_59*.JPEG") | Sort-Object Name
$ordered += Get-ChildItem -File (Join-Path $imagesDir "IMG_1*.JPEG") | Sort-Object Name

$n = 0
foreach ($file in $ordered) {
    $n++
    $src = [System.Drawing.Image]::FromFile($file.FullName)

    $scale = [Math]::Min(1.0, $maxEdge / [Math]::Max($src.Width, $src.Height))
    $w = [int]([Math]::Round($src.Width * $scale))
    $h = [int]([Math]::Round($src.Height * $scale))

    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.DrawImage($src, 0, 0, $w, $h)

    $out = Join-Path $imagesDir ("photo{0:D2}.jpg" -f $n)
    $bmp.Save($out, $encoder, $encoderParams)

    $g.Dispose(); $bmp.Dispose(); $src.Dispose()

    $kb = [Math]::Round((Get-Item $out).Length / 1KB)
    Write-Output ("photo{0:D2}.jpg  {1}x{2}  {3} KB   <- {4}" -f $n, $w, $h, $kb, $file.Name)
}

Write-Output "Done: $n photos."
