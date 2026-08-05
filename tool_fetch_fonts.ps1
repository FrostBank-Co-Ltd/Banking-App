$ErrorActionPreference = 'Continue'
New-Item -ItemType Directory -Force -Path 'assets/fonts' | Out-Null

# Probe for static instances in google/fonts. Static files remove all variable-axis risk.
$base = 'https://raw.githubusercontent.com/google/fonts/main/ofl'
$probe = @(
  'outfit/static/Outfit-Regular.ttf',
  'outfit/static/Outfit-Medium.ttf',
  'outfit/static/Outfit-SemiBold.ttf',
  'outfit/static/Outfit-Bold.ttf',
  'outfit/static/Outfit-Black.ttf',
  'geist/static/Geist-Regular.ttf',
  'geist/static/Geist-Medium.ttf',
  'geist/static/Geist-SemiBold.ttf',
  'geist/static/Geist-Bold.ttf'
)

foreach ($p in $probe) {
  $url = "$base/$p"
  try {
    $r = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing
    Write-Output ("FOUND   {0}  ({1})" -f $p, $r.StatusCode)
  } catch {
    Write-Output ("MISSING {0}" -f $p)
  }
}
