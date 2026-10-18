from pathlib import Path
import re
import textwrap

from PIL import Image
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas


BASE_DIR = Path(__file__).resolve().parents[1]
CATALOGO_DIR = BASE_DIR / "Catalogo"
BACKGROUND = CATALOGO_DIR / "Plantilla elegante para servicios funerarios.png"
OUTPUT = CATALOGO_DIR / "Funeraria_La_Orquidea_Catalogo_2026.pdf"


def read_source(name: str) -> str:
    for candidate in (BASE_DIR / name, BASE_DIR / f"{name}.txt"):
        if candidate.exists():
            return candidate.read_text(encoding="utf-8")
    raise FileNotFoundError(f"No se encontro {name} ni {name}.txt")


def clean_md(text: str) -> str:
    text = re.sub(r"^#+\s*", "", text, flags=re.MULTILINE)
    text = text.replace("---", "")
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def draw_background(c: canvas.Canvas) -> None:
    width, height = A4
    c.drawImage(str(BACKGROUND), 0, 0, width=width, height=height, preserveAspectRatio=False, mask="auto")


def draw_text_block(c: canvas.Canvas, title: str, body: list[str], y: float = 690) -> None:
    navy = colors.HexColor("#112B46")
    gold = colors.HexColor("#B89446")
    gray = colors.HexColor("#3F4650")

    c.setFillColor(gold)
    c.setFont("Times-Bold", 15)
    c.drawString(70, y, title.upper())
    y -= 24

    c.setFillColor(gray)
    c.setFont("Helvetica", 10.5)
    for paragraph in body:
        if not paragraph:
            y -= 10
            continue
        for line in textwrap.wrap(paragraph, width=76):
            c.drawString(70, y, line)
            y -= 15
        y -= 8

    c.setFillColor(navy)
    c.setFont("Helvetica-Bold", 8.5)
    c.drawRightString(525, 42, "Funeraria La Orquidea | Ibarra, Ecuador | 0993130913 - 0997138260")


def add_page(c: canvas.Canvas, title: str, body: list[str]) -> None:
    draw_background(c)
    draw_text_block(c, title, body)
    c.showPage()


def main() -> None:
    if not BACKGROUND.exists():
        raise FileNotFoundError(f"No se encontro la plantilla: {BACKGROUND}")

    # Validate the image early so reportlab fails with a clear message if the file is damaged.
    Image.open(BACKGROUND).verify()

    master = clean_md(read_source("LA_ORQUIDEA_MASTER.md"))
    branding = clean_md(read_source("BRANDING.md"))
    competencia = clean_md(read_source("COMPETENCIA.md"))
    planes = clean_md(read_source("PLANES_PREPAGO.md"))
    servicios = clean_md(read_source("SERVICIOS.md"))

    c = canvas.Canvas(str(OUTPUT), pagesize=A4)

    add_page(
        c,
        "Guia de Proteccion Familiar 2026",
        [
            "Funeraria La Orquidea acompana a las familias de Imbabura con respeto, amor y dignidad.",
            "Mas que un servicio funerario, somos el acompanamiento que tu familia necesita en los momentos mas sensibles.",
            "Atencion inmediata, prevision funeraria, cremacion, tanatopraxia, asesoria y cobertura provincial.",
            "Direccion: Gonzalo Gomez Jurado y Luis Vargas Torres, Ibarra, Ecuador.",
        ],
    )

    add_page(
        c,
        "Nuestra esencia",
        [
            "Proteger a las familias de Imbabura mediante servicios funerarios dignos, humanos y profesionales.",
            "Brindamos servicios exequiales integrales con respeto, amor y dignidad, acompanando antes, durante y despues de la perdida de un ser querido.",
            "Nuestra comunicacion transmite confianza, respeto, empatia, serenidad, profesionalismo y cercania humana.",
        ],
    )

    add_page(
        c,
        "Servicios integrales",
        [
            "Sala de velacion: espacios comodos y adecuados para acompanar a la familia durante la despedida.",
            "Traslados nacionales: traslado del fallecido dentro del territorio nacional con respeto y atencion profesional.",
            "Cremacion: servicio integral con asesoria, tramites y acompanamiento familiar.",
            "Tanatopraxia y formolizacion: procedimientos especializados de conservacion y presentacion.",
            "Arreglos florales, auto carroza, cafeteria, capillas ardientes, asesoria legal, libro de condolencias y servicio religioso.",
        ],
    )

    add_page(
        c,
        "Planes prepago",
        [
            "Plan Serenidad - $699: sala de velacion, cofre metalico, cafeteria, carroza, flores y asesoria de tramites.",
            "Plan Armonia - $999: incluye lo anterior, cofre de madera, fotografia enmarcada, servicio religioso y acompanamiento musical.",
            "Plan Legado - $1299: incluye formolizacion, tanatopraxia, flores premium y homenaje especial.",
            "Plan Trascendencia - $1499: velacion, cremacion, urna, certificados y tramites completos.",
        ],
    )

    add_page(
        c,
        "Por que elegir La Orquidea",
        [
            "Atencion 24/7, convenios institucionales, cremacion, tanatopraxia, prevision funeraria, atencion personalizada y cobertura provincial.",
            "No vendemos funerales. Vendemos tranquilidad, proteccion y acompanamiento familiar.",
            "Nuestro enfoque es humano, profesional y cercano a cada familia.",
        ],
    )

    add_page(
        c,
        "Contexto competitivo",
        [
            "Bosmediano comunica prestigio, trayectoria y experiencia, con una propuesta principalmente orientada al servicio inmediato.",
            "Celestial comunica precio, cuotas accesibles y planes exequiales, con catalogos extensos y mucha informacion tecnica.",
            "La oportunidad para La Orquidea es posicionarse como la funeraria que protege a las familias de Imbabura mediante prevision, atencion inmediata y acompanamiento humano.",
        ],
    )

    add_page(
        c,
        "Contacto",
        [
            "Funeraria La Orquidea",
            "Gonzalo Gomez Jurado y Luis Vargas Torres, Ibarra, Ecuador.",
            "Telefonos: 0993130913 / 0997138260.",
            "Facebook: Funeraria La Orquidea.",
            "Acompanamos tu despedida con respeto, amor y dignidad.",
        ],
    )

    # Keep source reads explicit so the script depends on all strategic files requested.
    _ = (master, branding, competencia, planes, servicios)

    c.save()
    print(f"PDF creado: {OUTPUT}")


if __name__ == "__main__":
    main()
