Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$Base = Resolve-Path (Join-Path $PSScriptRoot "..")
$Catalogo = Join-Path $Base "Catalogo"
$Fotos = Join-Path $Catalogo "Fotos"
$Revision = Join-Path $Catalogo "Revision"
$TemplatePath = Join-Path $Catalogo "Plantilla elegante para servicios funerarios.png"
$LogoPath = Join-Path $Base "Logos\logo funeraria la orquidea.jpg"
$PdfPath = Join-Path $Catalogo "Funeraria_La_Orquidea_Catalogo_2026_vFinal.pdf"
$RunId = [System.Guid]::NewGuid().ToString("N")

New-Item -ItemType Directory -Force -Path $Revision | Out-Null

$W = 1240
$H = 1754
$Navy = [System.Drawing.Color]::FromArgb(17, 35, 68)
$Navy2 = [System.Drawing.Color]::FromArgb(24, 48, 82)
$Gold = [System.Drawing.Color]::FromArgb(184, 148, 70)
$Gray = [System.Drawing.Color]::FromArgb(60, 68, 78)
$Light = [System.Drawing.Color]::FromArgb(247, 248, 250)
$White = [System.Drawing.Color]::White

function Font-Of($name, $size, $style = [System.Drawing.FontStyle]::Regular) {
    return [System.Drawing.Font]::new($name, $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
}

function New-Format($align = "Near", $lineAlign = "Near") {
    $fmt = [System.Drawing.StringFormat]::new()
    $fmt.Alignment = [System.Drawing.StringAlignment]::$align
    $fmt.LineAlignment = [System.Drawing.StringAlignment]::$lineAlign
    $fmt.Trimming = [System.Drawing.StringTrimming]::Word
    return $fmt
}

function Draw-CoverImage($g, $path, [float]$x, [float]$y, [float]$w, [float]$h, $radius = 0) {
    $img = [System.Drawing.Image]::FromFile($path)
    try {
        $scale = [Math]::Max($w / $img.Width, $h / $img.Height)
        $sw = $w / $scale
        $sh = $h / $scale
        $sx = ($img.Width - $sw) / 2
        $sy = ($img.Height - $sh) / 2
        $dest = [System.Drawing.RectangleF]::new($x, $y, $w, $h)
        $src = [System.Drawing.RectangleF]::new($sx, $sy, $sw, $sh)
        if ($radius -gt 0) {
            $pathClip = Rounded-Rect $x $y $w $h $radius
            $oldClip = $g.Clip
            $g.SetClip($pathClip)
            $g.DrawImage($img, $dest, $src, [System.Drawing.GraphicsUnit]::Pixel)
            $g.Clip = $oldClip
            $pathClip.Dispose()
        } else {
            $g.DrawImage($img, $dest, $src, [System.Drawing.GraphicsUnit]::Pixel)
        }
    } finally {
        $img.Dispose()
    }
}

function Draw-ContainImage($g, $path, [float]$x, [float]$y, [float]$w, [float]$h) {
    $img = [System.Drawing.Image]::FromFile($path)
    try {
        $scale = [Math]::Min($w / $img.Width, $h / $img.Height)
        $dw = $img.Width * $scale
        $dh = $img.Height * $scale
        $dx = $x + (($w - $dw) / 2)
        $dy = $y + (($h - $dh) / 2)
        $g.DrawImage($img, [System.Drawing.RectangleF]::new($dx, $dy, $dw, $dh))
    } finally {
        $img.Dispose()
    }
}

function Rounded-Rect([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

function Fill-Rounded($g, $brush, [float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = Rounded-Rect $x $y $w $h $r
    $g.FillPath($brush, $p)
    $p.Dispose()
}

function Stroke-Rounded($g, $pen, [float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = Rounded-Rect $x $y $w $h $r
    $g.DrawPath($pen, $p)
    $p.Dispose()
}

function Draw-Text($g, $text, $font, $color, [float]$x, [float]$y, [float]$w, [float]$h, $align = "Near") {
    $brush = [System.Drawing.SolidBrush]::new($color)
    $fmt = New-Format $align "Near"
    $g.DrawString($text, $font, $brush, [System.Drawing.RectangleF]::new($x, $y, $w, $h), $fmt)
    $brush.Dispose()
    $fmt.Dispose()
}

function Measure-TextHeight($g, $text, $font, [float]$w) {
    $fmt = New-Format
    $size = $g.MeasureString($text, $font, [int]$w, $fmt)
    $fmt.Dispose()
    return $size.Height
}

function Draw-Paragraph($g, [ref]$y, $text, $font, $color, [float]$x, [float]$w, [float]$gap = 16) {
    $h = Measure-TextHeight $g $text $font $w
    Draw-Text $g $text $font $color $x $y.Value $w ($h + 8)
    $y.Value += $h + $gap
}

function Draw-Bullets($g, [ref]$y, $items, [float]$x, [float]$w, $font, $bulletColor, $textColor, [float]$lineGap = 16) {
    foreach ($item in $items) {
        $brushBullet = [System.Drawing.SolidBrush]::new($bulletColor)
        $g.FillEllipse($brushBullet, $x, $y.Value + 8, 10, 10)
        $brushBullet.Dispose()
        $h = Measure-TextHeight $g $item $font ($w - 28)
        Draw-Text $g $item $font $textColor ($x + 28) $y.Value ($w - 28) ($h + 8)
        $y.Value += [Math]::Max(30, $h + $lineGap)
    }
}

function Draw-CheckList($g, [ref]$y, $items, [float]$x, [float]$w, $font, [float]$lineGap = 16) {
    foreach ($item in $items) {
        Draw-Text $g "✓" (Font-Of "Segoe UI Symbol" 30 ([System.Drawing.FontStyle]::Bold)) $Gold $x ($y.Value - 3) 34 38
        $h = Measure-TextHeight $g $item $font ($w - 42)
        Draw-Text $g $item $font $Gray ($x + 42) $y.Value ($w - 42) ($h + 8)
        $y.Value += [Math]::Max(34, $h + $lineGap)
    }
}

function Draw-Base($g, $pageNo) {
    Draw-CoverImage $g $TemplatePath 0 0 $W $H 0
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(218, 255, 255, 255))
    Fill-Rounded $g $brush 82 190 1076 1326 18
    $brush.Dispose()
    $pen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(70, 184, 148, 70), 2)
    Stroke-Rounded $g $pen 82 190 1076 1326 18
    $pen.Dispose()
    Draw-Text $g "Funeraria La Orquídea | Ibarra, Ecuador | 0993130913 - 0997138260" (Font-Of "Segoe UI" 18) $Navy 96 1600 860 30
    Draw-Text $g ("{0:00}" -f $pageNo) (Font-Of "Georgia" 20 ([System.Drawing.FontStyle]::Bold)) $Gold 1060 1598 80 34 "Far"
}

function Draw-Header($g, $title, $subtitle, $pageNo) {
    Draw-Base $g $pageNo
    Draw-Text $g $title (Font-Of "Georgia" 52 ([System.Drawing.FontStyle]::Bold)) $Navy 124 236 720 78
    if ($subtitle) {
        Draw-Text $g $subtitle (Font-Of "Segoe UI" 23) $Gold 128 314 840 78
    }
    $pen = [System.Drawing.Pen]::new($Gold, 4)
    $g.DrawLine($pen, 128, 408, 520, 408)
    $pen.Dispose()
}

function Draw-PhotoCard($g, $path, [float]$x, [float]$y, [float]$w, [float]$h) {
    $shadow = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(42, 0, 0, 0))
    Fill-Rounded $g $shadow ($x + 10) ($y + 12) $w $h 22
    $shadow.Dispose()
    Draw-CoverImage $g $path $x $y $w $h 22
    $pen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(190, 184, 148, 70), 3)
    Stroke-Rounded $g $pen $x $y $w $h 22
    $pen.Dispose()
}

function Save-Page($bmp, $pageNo) {
    $path = Join-Path $Revision ("Pagina_{0:00}.jpg" -f $pageNo)
    $tmpPath = Join-Path $Revision ("Pagina_{0:00}.{1}.tmp.jpg" -f $pageNo, $RunId)
    $enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
    $params = [System.Drawing.Imaging.EncoderParameters]::new(1)
    $params.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new([System.Drawing.Imaging.Encoder]::Quality, 94L)
    $bmp.Save($tmpPath, $enc, $params)
    $params.Dispose()
    for ($attempt = 1; $attempt -le 12; $attempt++) {
        try {
            if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
            Move-Item -LiteralPath $tmpPath -Destination $path
            break
        } catch {
            if ($attempt -eq 12) { throw }
            Start-Sleep -Milliseconds 500
        }
    }
    return $path
}

function New-PageBitmap() {
    $bmp = [System.Drawing.Bitmap]::new($W, $H)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    return @($bmp, $g)
}

function Render-Page1 {
    $pair = New-PageBitmap; $bmp=$pair[0]; $g=$pair[1]
    Draw-CoverImage $g $TemplatePath 0 0 $W $H 0
    Draw-PhotoCard $g (Join-Path $Fotos "Flores Orquideas.jfif") 120 790 465 465
    Draw-Text $g "FUNERARIA" (Font-Of "Georgia" 58 ([System.Drawing.FontStyle]::Bold)) $Navy 126 330 700 84
    Draw-Text $g "La Orquídea" (Font-Of "Georgia" 70 ([System.Drawing.FontStyle]::Italic)) $Gold 126 400 760 96
    Draw-Text $g "Planes de previsión familiar 2026" (Font-Of "Segoe UI" 31) $Navy 132 514 760 50
    $pen = [System.Drawing.Pen]::new($Gold, 5); $g.DrawLine($pen, 132, 585, 690, 585); $pen.Dispose()
    Draw-Text $g "Más que un servicio funerario, somos el acompañamiento que tu familia necesita." (Font-Of "Georgia" 31) $Gray 132 635 850 150
    $items = @("Atención 24/7", "Planes prepago", "Cobertura provincial", "Acompañamiento humano", "Servicios dignos y profesionales")
    $y=[ref]1325; Draw-Bullets $g $y $items 132 850 (Font-Of "Segoe UI" 24) $Gold $Navy 14
    Draw-Text $g "Acompañamos tu despedida con respeto, amor y dignidad." (Font-Of "Segoe UI" 22 ([System.Drawing.FontStyle]::Italic)) $Gold 132 1578 830 40
    $g.Dispose(); $out=Save-Page $bmp 1; $bmp.Dispose(); return $out
}

function Render-StandardPage($pageNo, $title, $subtitle, $body, $benefits, $image, $layout = "right") {
    $pair = New-PageBitmap; $bmp=$pair[0]; $g=$pair[1]
    Draw-Header $g $title $subtitle $pageNo
    if ($layout -eq "right") {
        Draw-PhotoCard $g $image 690 465 360 460
        $x=130; $w=500
    } else {
        Draw-PhotoCard $g $image 130 1040 520 320
        $x=130; $w=890
    }
    $y=[ref]440
    Draw-Paragraph $g $y $body (Font-Of "Segoe UI" 25) $Gray $x $w 28
    $labelBrush = [System.Drawing.SolidBrush]::new($Navy)
    Fill-Rounded $g $labelBrush $x ($y.Value+18) $w 54 14
    $labelBrush.Dispose()
    Draw-Text $g "BENEFICIOS DESTACADOS" (Font-Of "Segoe UI" 20 ([System.Drawing.FontStyle]::Bold)) $White ($x+24) ($y.Value+30) ($w-48) 32
    $y.Value += 96
    Draw-CheckList $g $y $benefits $x $w (Font-Of "Segoe UI" 22) 11
    $g.Dispose(); $out=Save-Page $bmp $pageNo; $bmp.Dispose(); return $out
}

function Render-Page3 {
    $pair = New-PageBitmap; $bmp=$pair[0]; $g=$pair[1]
    Draw-Header $g "¿Por qué elegir" "Atención humana, profesional y cercana para las familias de Imbabura" 3
    Draw-Text $g "Funeraria La Orquídea?" (Font-Of "Georgia" 48 ([System.Drawing.FontStyle]::Bold)) $Navy 126 292 850 72
    $band = [System.Drawing.SolidBrush]::new($Navy)
    Fill-Rounded $g $band 128 400 840 66 16
    $band.Dispose()
    Draw-Text $g "Más de lo que tu familia necesita, cuando más lo necesita." (Font-Of "Segoe UI" 24 ([System.Drawing.FontStyle]::Bold)) $White 154 415 790 38
    Draw-PhotoCard $g (Join-Path $Fotos "fachada.jpg") 690 530 360 460
    $y=[ref]520
    Draw-Paragraph $g $y "En La Orquídea entendemos que cada familia necesita algo más que un servicio: necesita orientación, respeto y compañía. Por eso ofrecemos atención personalizada, asesoría permanente, cobertura provincial y servicios integrales diseñados para honrar la vida con dignidad." (Font-Of "Segoe UI" 24) $Gray 130 500 26
    $items = @("Atención inmediata 24 horas", "Sala de velación propia", "Servicio de cremación", "Convenios institucionales", "Cobertura provincial", "Asesoría permanente")
    $y.Value += 18
    Draw-CheckList $g $y $items 130 520 (Font-Of "Segoe UI" 23) 10
    $g.Dispose(); $out=Save-Page $bmp 3; $bmp.Dispose(); return $out
}

function Render-PlanPage($pageNo, $title, $subtitle, $body, $price, $benefit, $items, $image) {
    $pair = New-PageBitmap; $bmp=$pair[0]; $g=$pair[1]
    Draw-Header $g $title $subtitle $pageNo
    Draw-PhotoCard $g $image 720 480 330 330
    $y=[ref]455
    Draw-Paragraph $g $y $body (Font-Of "Segoe UI" 23) $Gray 130 520 18
    if ($benefit) {
        $b = [System.Drawing.SolidBrush]::new($Navy)
        Fill-Rounded $g $b 130 $y.Value 520 58 14
        $b.Dispose()
        Draw-Text $g $benefit (Font-Of "Segoe UI" 22 ([System.Drawing.FontStyle]::Bold)) $White 154 ($y.Value+14) 480 32
        $y.Value += 78
    }
    Draw-Text $g "Inversión:" (Font-Of "Segoe UI" 24) $Gray 132 $y.Value 150 38
    Draw-Text $g $price (Font-Of "Georgia" 48 ([System.Drawing.FontStyle]::Bold)) $Gold 280 ($y.Value-16) 230 62
    $y.Value += 78
    Draw-Text $g "INCLUYE:" (Font-Of "Segoe UI" 25 ([System.Drawing.FontStyle]::Bold)) $Navy 132 $y.Value 300 42
    $y.Value += 58
    if ($pageNo -eq 4) {
        $left = @("Sala de velación durante 24 horas", "Cofre de madera lineal", "Preparación estética y formolización", "Dos arreglos florales")
        $right = @("Cafetería permanente", "Fotografía tamaño A4", "Libro de condolencias", "Traslado local y autocarroza", "Asesoría en trámites")
        $yl=[ref]$y.Value; $yr=[ref]$y.Value
        Draw-CheckList $g $yl $left 132 470 (Font-Of "Segoe UI" 21) 9
        Draw-CheckList $g $yr $right 620 470 (Font-Of "Segoe UI" 21) 9
    } else {
        Draw-CheckList $g $y $items 132 880 (Font-Of "Segoe UI" 22) 9
    }
    $g.Dispose(); $out=Save-Page $bmp $pageNo; $bmp.Dispose(); return $out
}

function Render-Page8 {
    $pair = New-PageBitmap; $bmp=$pair[0]; $g=$pair[1]
    Draw-Header $g "Comparativo de planes" "Elige el nivel de protección que tu familia necesita" 8
    Draw-Text $g "Todos nuestros planes han sido diseñados para brindar tranquilidad, acompañamiento y una atención digna. La diferencia está en el nivel de personalización, cobertura y detalles ceremoniales que cada familia desea incluir." (Font-Of "Segoe UI" 22) $Gray 130 425 920 110
    $x=120; $y=575; $rowH=82
    $cols = @(310, 190, 170, 170, 220)
    $headers = @("Beneficio","Serenidad","Armonía","Legado","Trascendencia")
    $rows = @(
        @("Sala de velación","✓","✓","✓","✓"),
        @("Cofre de madera","✓","✓","✓","Velación"),
        @("Arreglos florales","2","3","Premium","Premium"),
        @("Servicio religioso","","✓","✓","Opcional"),
        @("Tanatopraxia","","","✓",""),
        @("Cremación","","","","✓"),
        @("Fotografía enmarcada","","✓","✓","✓"),
        @("Asesoría en trámites","✓","✓","✓","✓")
    )
    $navyBrush=[System.Drawing.SolidBrush]::new($Navy)
    Fill-Rounded $g $navyBrush $x $y 1060 $rowH 14
    $navyBrush.Dispose()
    $cx=$x
    for ($i=0; $i -lt $headers.Count; $i++) {
        Draw-Text $g $headers[$i] (Font-Of "Segoe UI" 20 ([System.Drawing.FontStyle]::Bold)) $White ($cx+14) ($y+26) ($cols[$i]-18) 32 "Center"
        $cx += $cols[$i]
    }
    $y += $rowH
    foreach ($r in $rows) {
        $fill = if ((($y/$rowH)%2) -eq 0) { [System.Drawing.Color]::FromArgb(247,248,250) } else { [System.Drawing.Color]::FromArgb(255,255,255) }
        $b=[System.Drawing.SolidBrush]::new($fill); $g.FillRectangle($b, $x, $y, 1060, $rowH); $b.Dispose()
        $cx=$x
        for ($i=0; $i -lt 5; $i++) {
            $color = if ($i -eq 0) { $Navy } elseif ($r[$i] -eq "✓") { $Gold } else { $Gray }
            $font = if ($i -eq 0) { Font-Of "Segoe UI" 21 ([System.Drawing.FontStyle]::Bold) } elseif ($r[$i] -eq "✓") { Font-Of "Segoe UI Symbol" 28 ([System.Drawing.FontStyle]::Bold) } else { Font-Of "Segoe UI" 20 }
            $align = if ($i -eq 0) { "Near" } else { "Center" }
            Draw-Text $g $r[$i] $font $color ($cx+12) ($y+23) ($cols[$i]-24) 34 $align
            $cx += $cols[$i]
        }
        $pen=[System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(230,225,215),1)
        $g.DrawLine($pen,$x,$y+ $rowH, $x+1060, $y+$rowH); $pen.Dispose()
        $y += $rowH
    }
    Draw-Text $g "Serenidad: protección esencial  |  Armonía: ceremonia más cálida  |  Legado: homenaje premium  |  Trascendencia: velación y cremación integral" (Font-Of "Segoe UI" 19) $Navy 132 1410 980 72 "Center"
    $g.Dispose(); $out=Save-Page $bmp 8; $bmp.Dispose(); return $out
}

function Render-Page9 {
    $pair = New-PageBitmap; $bmp=$pair[0]; $g=$pair[1]
    Draw-Header $g "Formas de pago" "Te ayudamos a elegir el plan adecuado para tu familia" 9
    Draw-Text $g "y asesoría" (Font-Of "Georgia" 50 ([System.Drawing.FontStyle]::Bold)) $Navy 128 292 520 68
    Draw-PhotoCard $g (Join-Path $Fotos "Guia de trámites.jfif") 725 450 320 420
    $y=[ref]430
    Draw-Paragraph $g $y "En La Orquídea orientamos a cada familia de forma personalizada para que pueda elegir un plan de previsión acorde a sus necesidades. Nuestro equipo brinda asesoría clara, atención inmediata y acompañamiento en trámites, convenios y coordinación del servicio." (Font-Of "Segoe UI" 23) $Gray 130 520 24
    $band=[System.Drawing.SolidBrush]::new($Navy)
    Fill-Rounded $g $band 130 760 910 105 18
    $band.Dispose()
    Draw-Text $g "Solicita una asesoría sin compromiso y descubre cuál es el plan ideal para proteger a tu familia." (Font-Of "Segoe UI" 25 ([System.Drawing.FontStyle]::Bold)) $White 164 784 840 64 "Center"
    Draw-Text $g "¿Cómo contratar?" (Font-Of "Georgia" 40 ([System.Drawing.FontStyle]::Bold)) $Navy 132 930 520 56
    $steps=@("Solicita asesoría.","Elige tu plan.","Firma tu contrato.","Protege a tu familia.")
    $sx=132
    for ($i=0; $i -lt 4; $i++) {
        $b=[System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(248,248,248))
        Fill-Rounded $g $b ($sx+($i*240)) 1010 210 170 18
        $b.Dispose()
        $p=[System.Drawing.Pen]::new($Gold,2); Stroke-Rounded $g $p ($sx+($i*240)) 1010 210 170 18; $p.Dispose()
        Draw-Text $g ([string]($i+1)) (Font-Of "Georgia" 42 ([System.Drawing.FontStyle]::Bold)) $Gold ($sx+($i*240)) 1024 210 58 "Center"
        Draw-Text $g $steps[$i] (Font-Of "Segoe UI" 21 ([System.Drawing.FontStyle]::Bold)) $Navy ($sx+18+($i*240)) 1090 174 70 "Center"
    }
    $items=@("Asesoría personalizada","Orientación en planes prepago","Atención 24/7","Convenios con instituciones","Acompañamiento documental","Información clara antes de decidir")
    $y2=[ref]1250
    Draw-Bullets $g $y2 $items 132 850 (Font-Of "Segoe UI" 22) $Gold $Gray 8
    $g.Dispose(); $out=Save-Page $bmp 9; $bmp.Dispose(); return $out
}

function Render-Page10 {
    $pair = New-PageBitmap; $bmp=$pair[0]; $g=$pair[1]
    Draw-CoverImage $g $TemplatePath 0 0 $W $H 0
    Draw-Text $g "Estamos contigo" (Font-Of "Georgia" 52 ([System.Drawing.FontStyle]::Bold)) $Navy 132 315 760 70
    Draw-Text $g "cuando más nos necesitas" (Font-Of "Georgia" 50 ([System.Drawing.FontStyle]::Bold)) $Navy 132 380 850 70
    Draw-Text $g "Funeraria La Orquídea | Ibarra, Ecuador" (Font-Of "Segoe UI" 28) $Gold 136 468 760 46
    Draw-Text $g "Protegemos la tranquilidad de las familias de Imbabura con atención humana, servicios integrales y planes de previsión diseñados para acompañar cada despedida con respeto, amor y dignidad." (Font-Of "Segoe UI" 24) $Gray 136 550 840 130
    $band=[System.Drawing.SolidBrush]::new($Navy)
    Fill-Rounded $g $band 136 730 880 96 20
    $band.Dispose()
    Draw-Text $g "Emergencias y atención inmediata 24/7" (Font-Of "Segoe UI" 32 ([System.Drawing.FontStyle]::Bold)) $White 160 753 830 50 "Center"
    Draw-PhotoCard $g (Join-Path $Fotos "QR La Orquidea FINAL.png") 150 900 330 385
    Draw-PhotoCard $g (Join-Path $Fotos "Ubicación foto 3.jpeg") 590 900 410 385
    $items=@("Gonzalo Gómez Jurado y Luis Vargas Torres","0993130913 / 0997138260","Facebook: Funeraria La Orquídea","Atención 24 horas","Cobertura provincial")
    $y=[ref]1345
    Draw-CheckList $g $y $items 150 860 (Font-Of "Segoe UI" 24) 10
    Draw-Text $g "Acompañamos tu despedida con respeto, amor y dignidad." (Font-Of "Georgia" 27 ([System.Drawing.FontStyle]::Italic)) $Gold 138 1580 900 50 "Center"
    $g.Dispose(); $out=Save-Page $bmp 10; $bmp.Dispose(); return $out
}

function Escape-PdfText([string]$s) {
    return $s.Replace("\", "\\").Replace("(", "\(").Replace(")", "\)")
}

function Write-PdfFromJpegs($jpgs, $outPath) {
    $enc = [System.Text.Encoding]::ASCII
    $ms = [System.IO.MemoryStream]::new()
    function W([string]$s) {
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($s)
        $script:ms.Write($bytes,0,$bytes.Length)
    }
    $script:ms = $ms
    $offsets = New-Object System.Collections.Generic.List[int64]
    W "%PDF-1.4`n%Final Catalogo La Orquidea`n"
    $objCount = 2 + ($jpgs.Count * 3)
    $catalogObj = 1
    $pagesObj = 2
    $pageObjs = @()
    for ($i=0; $i -lt $jpgs.Count; $i++) { $pageObjs += 3 + ($i*3) }
    $offsets.Add($ms.Position); W "1 0 obj`n<< /Type /Catalog /Pages 2 0 R >>`nendobj`n"
    $kids = ($pageObjs | ForEach-Object { "$_ 0 R" }) -join " "
    $offsets.Add($ms.Position); W "2 0 obj`n<< /Type /Pages /Kids [ $kids ] /Count $($jpgs.Count) >>`nendobj`n"
    for ($i=0; $i -lt $jpgs.Count; $i++) {
        $pageObj = 3 + ($i*3); $imgObj=$pageObj+1; $contentObj=$pageObj+2
        $offsets.Add($ms.Position)
        W "$pageObj 0 obj`n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595.28 841.89] /Resources << /XObject << /Im$i $imgObj 0 R >> >> /Contents $contentObj 0 R >>`nendobj`n"
        $bytes = [System.IO.File]::ReadAllBytes($jpgs[$i])
        $offsets.Add($ms.Position)
        W "$imgObj 0 obj`n<< /Type /XObject /Subtype /Image /Width $W /Height $H /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length $($bytes.Length) >>`nstream`n"
        $ms.Write($bytes,0,$bytes.Length)
        W "`nendstream`nendobj`n"
        $content = "q`n595.28 0 0 841.89 0 0 cm`n/Im$i Do`nQ`n"
        $offsets.Add($ms.Position)
        W "$contentObj 0 obj`n<< /Length $($content.Length) >>`nstream`n$content`nendstream`nendobj`n"
    }
    $xref = $ms.Position
    W "xref`n0 $($objCount+1)`n"
    W "0000000000 65535 f `n"
    foreach ($o in $offsets) { W ("{0:0000000000} 00000 n `n" -f $o) }
    W "trailer`n<< /Size $($objCount+1) /Root 1 0 R >>`nstartxref`n$xref`n%%EOF"
    [System.IO.File]::WriteAllBytes($outPath, $ms.ToArray())
    $ms.Dispose()
}

$jpgs = @()
$jpgs += Render-Page1
$jpgs += Render-StandardPage 2 "¿Por qué planificar hoy?" "La tranquilidad de tu familia empieza con una decisión responsable" "Planificar con anticipación permite proteger a quienes más amas, evitar decisiones difíciles en momentos sensibles y asegurar una despedida digna, organizada y respetuosa. La previsión funeraria no trata de anticipar la tristeza, sino de cuidar a la familia con amor, responsabilidad y serenidad." @("Evita gastos imprevistos","Reduce la carga emocional","Garantiza atención inmediata","Protege el presupuesto familiar","Permite decidir con calma") (Join-Path $Fotos "Familia.jfif") "right"
$jpgs += Render-Page3
$jpgs += Render-PlanPage 4 "Plan Serenidad" "Una despedida digna, organizada y acompañada" "Diseñado para familias que desean contar con un servicio completo, humano y confiable. El Plan Serenidad brinda los elementos esenciales para una despedida respetuosa, con atención profesional y apoyo en cada paso." '$699' "Protección esencial para tu familia" @() (Join-Path $Fotos "Sala de Velaciones foto.jpeg")
$jpgs += Render-PlanPage 5 "Plan Armonía" "Más acompañamiento para una ceremonia serena y significativa" "El Plan Armonía integra los beneficios del Plan Serenidad y suma detalles pensados para brindar mayor calidez a la ceremonia. Es una alternativa ideal para familias que desean una despedida más personalizada, con acompañamiento religioso y coordinación cuidadosa del servicio." '$999' $null @("Incluye todo lo del Plan Serenidad","Fotografía enmarcada","Un arreglo floral adicional","Rosario de oración","Servicio religioso","Coordinación personalizada del servicio") (Join-Path $Fotos "Capilla Ardiente 2.jpg")
$jpgs += Render-PlanPage 6 "Plan Legado" "Un homenaje completo para honrar la vida y acompañar el recuerdo" "El Plan Legado está pensado para familias que desean una ceremonia más completa, solemne y cuidadosamente coordinada. Combina atención profesional, detalles premium y acompañamiento integral para que cada momento se realice con respeto, amor y dignidad." '$1.299' $null @("Incluye todo lo del Plan Armonía","Tanatopraxia profesional","Arreglo floral premium","Coordinación integral de ceremonia","Cobertura ampliada de traslado","Fotografía conmemorativa enmarcada") (Join-Path $Fotos "Capilla Ardiente 1.jpg")
$jpgs += Render-PlanPage 7 "Plan Trascendencia" "Una opción integral de velación y cremación con acompañamiento profesional" "Para las familias que optan por la cremación, el Plan Trascendencia ofrece un servicio completo que integra velación, asesoría, permisos, traslado, cremación y urna cineraria. Incluye todo el acompañamiento de una velación tradicional más el proceso integral de cremación." '$1.499' $null @("Sala de velación 24 horas","Cofre para velación","Preparación estética","Formolización","Arreglos florales premium","Cafetería permanente","Fotografía enmarcada","Libro de condolencias","Asesoría en trámites","Trámites y permisos de cremación","Traslado al crematorio","Servicio de cremación","Urna cineraria","Certificado de cremación") (Join-Path $Fotos "Urnas cinerarias.jfif")
$jpgs += Render-Page8
$jpgs += Render-Page9
$jpgs += Render-Page10

Write-PdfFromJpegs $jpgs $PdfPath

Write-Host "PDF: $PdfPath"
Write-Host "JPG:"
$jpgs | ForEach-Object { Write-Host $_ }







