"""Writes images/oil_damper_today.jpg: the CC0 photo of an LHB air spring (pdf/photos/air_spring.jpg) with the
oil damper and the air spring marked, and the camera watermark cropped off.
Run from the repository root:  python tools/label_oil_damper_photo.py   (needs the Segoe UI fonts, Windows)
"""
from PIL import Image, ImageDraw, ImageFont

src = Image.open('pdf/photos/air_spring.jpg').convert('RGB').crop((0, 0, 1280, 850))  # drop the camera watermark
W, H = 1280, 850 + 150
im = Image.new('RGB', (W, H), 'white')
im.paste(src, (0, 0))
d = ImageDraw.Draw(im)


def font(n, bold=False):
    return ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf' if bold else 'C:/Windows/Fonts/segoeui.ttf', n)


ORG, BLU, INK, MUT = (221, 107, 32), (43, 108, 176), (26, 32, 44), (90, 100, 115)
d.rounded_rectangle((150, 222, 302, 846), radius=16, outline=ORG, width=7)     # oil damper
d.rounded_rectangle((302, 418, 1010, 642), radius=22, outline=BLU, width=6)    # air spring


def marker(x, y, n, col):
    d.ellipse((x - 30, y - 30, x + 30, y + 30), fill=col, outline='white', width=4)
    d.text((x, y - 3), n, font=font(34, True), fill='white', anchor='mm')


marker(226, 180, '1', ORG)
marker(1050, 530, '2', BLU)
y0 = 850
d.rectangle((0, y0, W, H), fill=(247, 250, 252))
d.line((0, y0, W, y0), fill=(226, 232, 240), width=2)


def legend(x, n, col, title, sub):
    d.ellipse((x, y0 + 38, x + 44, y0 + 82), fill=col)
    d.text((x + 22, y0 + 58), n, font=font(26, True), fill='white', anchor='mm')
    d.text((x + 62, y0 + 30), title, font=font(30, True), fill=INK)
    d.text((x + 62, y0 + 72), sub, font=font(24), fill=MUT)


legend(40, '1', ORG, "Oil damper (today)", "fixed setting · bounce → heat")
legend(660, '2', BLU, "Air spring", "carries the coach weight")
im.save('images/oil_damper_today.jpg', quality=92)
print('wrote images/oil_damper_today.jpg', im.size)
