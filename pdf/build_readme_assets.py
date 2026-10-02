"""Builds the README visuals: images/hero.jpg (banner) and images/casnub_annotated.jpg.

Photos come from pdf/photos (credits in pdf/photos/CREDITS.md). Requires Pillow and Windows fonts
(Segoe UI); falls back to Arial if Segoe UI is missing.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).resolve().parent
PHOTOS = HERE / "photos"
OUT = HERE.parent / "images"
OUT.mkdir(exist_ok=True)

NAVY = (19, 35, 58)
NAVY2 = (30, 53, 87)
ORANGE = (224, 122, 31)
TEAL = (42, 157, 143)
WHITE = (255, 255, 255)
MUTED = (190, 200, 214)


def font(size, bold=False):
    names = ["segoeuib.ttf", "arialbd.ttf"] if bold else ["segoeui.ttf", "arial.ttf"]
    for n in names:
        try:
            return ImageFont.truetype(str(Path("C:/Windows/Fonts") / n), size)
        except OSError:
            continue
    return ImageFont.load_default()


def cover(img, w, h, fx=0.5, fy=0.5):
    """Crop-and-scale an image to exactly w x h, keeping the focus point (fx, fy) in view."""
    s = max(w / img.width, h / img.height)
    img = img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)
    x = round((img.width - w) * fx)
    y = round((img.height - h) * fy)
    return img.crop((x, y, x + w, y + h))


def rounded(img, r):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, img.width - 1, img.height - 1), r, fill=255)
    out = Image.new("RGBA", img.size)
    out.paste(img, (0, 0), mask)
    return out


# ---------------------------------------------------------------- hero banner
def hero():
    W, H = 1920, 760
    im = Image.new("RGB", (W, H), NAVY)
    d = ImageDraw.Draw(im)
    for y in range(H):                       # subtle vertical gradient
        t = y / H
        d.line([(0, y), (W, y)], fill=tuple(round(NAVY[i] * (1 - t) + NAVY2[i] * t) for i in range(3)))

    # photos on the right: Casnub bogie (large) + Vande Bharat + LHB air spring
    cas = cover(Image.open(PHOTOS / "casnub.jpg").convert("RGB"), 820, 400, 0.5, 0.62)
    vb = cover(Image.open(PHOTOS / "vande_bharat.jpg").convert("RGB"), 400, 225, 0.82, 0.5)
    air = cover(Image.open(PHOTOS / "air_spring.jpg").convert("RGB"), 400, 225, 0.5, 0.5)
    for pic, (x, y) in [(cas, (1040, 60)), (vb, (1040, 490)), (air, (1460, 490))]:
        sh = Image.new("RGBA", (pic.width + 30, pic.height + 30), (0, 0, 0, 0))
        ImageDraw.Draw(sh).rounded_rectangle((15, 15, pic.width + 15, pic.height + 15), 18, fill=(0, 0, 0, 110))
        im.paste(sh.filter(ImageFilter.GaussianBlur(10)), (x - 15, y - 5), sh.filter(ImageFilter.GaussianBlur(10)))
        im.paste(rounded(pic, 16), (x, y), rounded(pic, 16))

    # text block
    x0 = 110
    tag = "INDIAN RAILWAYS · DEEP TECH"
    tw = d.textlength(tag, font=font(21, True))
    d.rounded_rectangle((x0, 118, x0 + tw + 44, 158), 20, fill=(224, 122, 31))
    d.text((x0 + 22, 121), tag, font=font(21, True), fill=WHITE)
    d.text((x0 - 4, 180), "SwarmRide", font=font(118, True), fill=WHITE)
    d.text((x0 - 2, 315), "Bharat", font=font(118, True), fill=ORANGE)
    d.text((x0, 470), "Self-powered, load-adaptive, train-synchronised", font=font(34), fill=WHITE)
    d.text((x0, 515), "suspension for passenger and freight trains", font=font(34), fill=WHITE)

    chips = [("HARVEST", "track bumps → bogie power"), ("CONTROL", "ride tuned to live load"),
             ("PROTECT", "self-powered safety sensors")]
    cx = x0
    for title, sub in chips:
        d.rounded_rectangle((cx, 600, cx + 278, 680), 14, outline=(78, 101, 133), width=2, fill=(24, 44, 72))
        d.ellipse((cx + 18, 618, cx + 30, 630), fill=TEAL if title != "HARVEST" else ORANGE)
        d.text((cx + 40, 608), title, font=font(22, True), fill=WHITE)
        d.text((cx + 18, 642), sub, font=font(18), fill=MUTED)
        cx += 296

    d.text((1040, H - 34), "Photos: Wikimedia Commons (CC BY-SA / CC0) and project archive, cropped. Credits: pdf/photos/CREDITS.md",
           font=font(15), fill=(140, 152, 170))
    im.save(OUT / "hero.jpg", quality=90)


# ---------------------------------------------------------- annotated bogie
def label(d, box, num, title, lines, colour):
    x0, y0, x1, y1 = box
    d.rounded_rectangle(box, 16, fill=(19, 35, 58, 232), outline=(*colour, 255), width=3)
    d.ellipse((x0 + 18, y0 + 18, x0 + 62, y0 + 62), fill=(*colour, 255))
    f = font(28, True)
    tw = d.textlength(str(num), font=f)
    d.text((x0 + 40 - tw / 2, y0 + 20), str(num), font=f, fill=WHITE)
    d.text((x0 + 78, y0 + 18), title, font=font(30, True), fill=WHITE)
    for k, ln in enumerate(lines):
        d.text((x0 + 78, y0 + 60 + 34 * k), ln, font=font(24), fill=(214, 222, 232))


def leader(d, p0, p1, colour):
    d.line([p0, p1], fill=(255, 255, 255, 255), width=7)
    d.line([p0, p1], fill=(*colour, 255), width=4)
    x, y = p1
    d.ellipse((x - 16, y - 16, x + 16, y + 16), outline=(255, 255, 255, 255), width=6)
    d.ellipse((x - 14, y - 14, x + 14, y + 14), outline=(*colour, 255), width=4)
    d.ellipse((x - 5, y - 5, x + 5, y + 5), fill=(*colour, 255))


def annotated():
    base = Image.open(PHOTOS / "casnub.jpg").convert("RGBA")
    ov = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    RED = (214, 69, 65)
    items = [
        # (box, anchor on box, target point, number, title, lines, colour)
        ((640, 1090, 1290, 1262), (965, 1090), (955, 880), 1, "Secondary suspension",
         ["SwarmRide smart damper fits here:", "harvests energy and controls the ride"], ORANGE),
        ((620, 30, 1300, 168), (960, 168), (958, 655), 2, "Friction wedges today",
         ["all suspension motion becomes heat", "(about 210 W per loaded bogie, simulated)"], RED),
        ((30, 30, 590, 168), (300, 168), (312, 728), 3, "Axle box",
         ["self-powered hot-axle and", "wheel-impact sensor"], TEAL),
        ((1330, 30, 1890, 168), (1600, 168), (1300, 770), 4, "Side frame",
         ["bogie power bank + controller", "(no wiring to the locomotive)"], TEAL),
        ((30, 1120, 560, 1258), (300, 1120), (300, 1030), 5, "Rail",
         ["track condition recorded", "by every train, every run"], TEAL),
    ]
    for box, a, t, n, title, lines, col in items:
        leader(d, a, t, col)
    for box, a, t, n, title, lines, col in items:
        label(d, box, n, title, lines, col)
    out = Image.alpha_composite(base, ov).convert("RGB")
    out.save(OUT / "casnub_annotated.jpg", quality=90)


if __name__ == "__main__":
    hero()
    annotated()
    print("Saved images/hero.jpg and images/casnub_annotated.jpg")
