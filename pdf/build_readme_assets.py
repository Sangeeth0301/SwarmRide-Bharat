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
    """White banner: title, one sentence, and three real photos."""
    W, H = 1920, 900
    im = Image.new("RGB", (W, H), WHITE)
    d = ImageDraw.Draw(im)

    # title, centred: "SwarmRide" navy + "Bharat" orange
    ft = font(104, True)
    a, b = "SwarmRide ", "Bharat"
    wa, wb = d.textlength(a, font=ft), d.textlength(b, font=ft)
    x = (W - wa - wb) / 2
    d.text((x, 40), a, font=ft, fill=NAVY)
    d.text((x + wa, 40), b, font=ft, fill=ORANGE)
    fs = font(36)
    line = "Self-powered, load-adaptive, train-synchronised suspension for Indian Railways"
    d.text(((W - d.textlength(line, font=fs)) / 2, 192), line, font=fs, fill=(74, 85, 104))

    # three photos in a row
    pw, ph, gap, y = 590, 440, 35, 300
    x0 = (W - 3 * pw - 2 * gap) // 2
    pics = [cover(Image.open(PHOTOS / "casnub.jpg").convert("RGB"), pw, ph, 0.5, 0.62),
            cover(Image.open(PHOTOS / "vande_bharat.jpg").convert("RGB"), pw, ph, 0.80, 0.55),
            cover(Image.open(PHOTOS / "air_spring.jpg").convert("RGB"), pw, ph, 0.5, 0.5)]
    caps = ["Goods: Casnub bogie, BOXN wagon", "Passenger: Vande Bharat", "Coach bogie: LHB air spring"]
    for k, pic in enumerate(pics):
        px = x0 + k * (pw + gap)
        sh = Image.new("RGBA", (pw + 40, ph + 40), (0, 0, 0, 0))
        ImageDraw.Draw(sh).rounded_rectangle((20, 24, pw + 20, ph + 24), 20, fill=(19, 35, 58, 70))
        sh = sh.filter(ImageFilter.GaussianBlur(12))
        im.paste(sh, (px - 20, y - 20), sh)
        r = rounded(pic, 20)
        im.paste(r, (px, y), r)
        fc = font(26, True)
        d.text((px + (pw - d.textlength(caps[k], font=fc)) / 2, y + ph + 26), caps[k], font=fc, fill=NAVY)

    fn = font(17)
    note = "Photos: Wikimedia Commons (CC BY-SA / CC0) and project archive, cropped. Credits: pdf/photos/CREDITS.md"
    d.text(((W - d.textlength(note, font=fn)) / 2, H - 42), note, font=fn, fill=(138, 147, 160))
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
