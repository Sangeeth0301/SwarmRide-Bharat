"""Writes images/pitch/smart_damper_concept_plain.jpg: the concept sketch with the two formula captions
(panels 2 and 3) replaced by plain words, for slides without equations.
Run from the repository root:  python tools/plain_concept_image.py
"""
from PIL import Image, ImageDraw, ImageFont

SRC = 'images/pitch/smart_damper_concept.jpg'
OUT = 'images/pitch/smart_damper_concept_plain.jpg'
im = Image.open(SRC).convert('RGB')
d = ImageDraw.Draw(im)
font = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 19)
ink = (41, 48, 60)

# (box to clear, first line position, lines) - boxes cover only the old caption text
captions = [
    ((1322, 506, 1724, 570), (1327, 513), ['The moving magnet makes electricity', 'that charges the bogie power bank']),
    ((872, 976, 1276, 1040), (877, 983), ['More coil current makes it firmer;', 'the firmness changes in milliseconds']),
]
for box, (x, y), lines in captions:
    bg = im.getpixel((box[0] + 4, box[1] - 12))      # panel background just above the caption
    d.rectangle(box, fill=bg)
    for k, line in enumerate(lines):
        d.text((x, y + 27 * k), line, font=font, fill=ink)
im.save(OUT, quality=93)
print('wrote', OUT, im.size)

# Train Brain sketch: the handwritten "warning time t = d / v" note becomes plain words
SRC2 = 'images/pitch/train_preview_concept.jpg'
OUT2 = 'images/pitch/train_preview_concept_plain.jpg'
im = Image.open(SRC2).convert('RGB')
d = ImageDraw.Draw(im)
hand = ImageFont.truetype('C:/Windows/Fonts/segoeprb.ttf', 24)
bg = im.getpixel((870, 590))
d.rectangle((870, 588, 1676, 626), fill=bg)
d.text((1662, 606), 'coaches further back get more warning time', font=hand, fill=(31, 112, 104), anchor='rm')
im.save(OUT2, quality=93)
print('wrote', OUT2, im.size)
