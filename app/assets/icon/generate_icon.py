"""Genera el icono de Chef AI by Shinra: gorro de chef + nodos de IA, en los
colores de marca (azul tecnologico + verde Shinra). Un solo uso: produce
app_icon.png (1024x1024) que despues procesa flutter_launcher_icons."""

from PIL import Image, ImageDraw

SIZE = 1024
BLUE = (37, 99, 235, 255)      # kShinraBlue
GREEN = (34, 197, 94, 255)     # kShinraGreen
WHITE = (255, 255, 255, 255)

img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Fondo: cuadrado redondeado azul
margin = 40
draw.rounded_rectangle(
    [margin, margin, SIZE - margin, SIZE - margin],
    radius=200,
    fill=BLUE,
)

cx, cy = SIZE // 2, SIZE // 2 + 30

# Gorro de chef (silueta simple): base + "nube" de 3 lobulos arriba
band_w, band_h = 420, 110
band_top = cy + 60
draw.rounded_rectangle(
    [cx - band_w // 2, band_top, cx + band_w // 2, band_top + band_h],
    radius=18,
    fill=WHITE,
)

lobe_r = 140
lobe_y = band_top - 40
for dx in (-150, 0, 150):
    r = lobe_r if dx == 0 else int(lobe_r * 0.82)
    draw.ellipse(
        [cx + dx - r, lobe_y - r, cx + dx + r, lobe_y + r],
        fill=WHITE,
    )
# tapa esas uniones con un rectangulo para que se vea una sola forma limpia
draw.rectangle([cx - band_w // 2, lobe_y, cx + band_w // 2, band_top + 20], fill=WHITE)

# Circuito / nodos de IA sobre el gorro, en verde Shinra
node_r = 16
nodes = [(-120, -170), (0, -230), (120, -170), (0, -100)]
abs_nodes = [(cx + dx, lobe_y + dy) for dx, dy in nodes]
for a, b in [(0, 3), (1, 3), (2, 3)]:
    draw.line([abs_nodes[a], abs_nodes[b]], fill=GREEN, width=10)
for x, y in abs_nodes:
    draw.ellipse([x - node_r, y - node_r, x + node_r, y + node_r], fill=GREEN)

img.save("app_icon.png")
print("app_icon.png generado", img.size)

# Version "foreground" para Android adaptive icons: mismo dibujo pero sin el
# fondo cuadrado (el fondo lo pone adaptive_icon_background por separado), y
# un poco mas chico/centrado para no quedar recortado por la mascara del OS.
fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
fg_draw = ImageDraw.Draw(fg)
scale = 0.7
offset_y = 40

def scaled(points):
    return [
        (cx + (x - cx) * scale, cy + (y - cy) * scale + offset_y)
        for x, y in points
    ]

band_pts = scaled([
    (cx - band_w // 2, band_top),
    (cx + band_w // 2, band_top + band_h),
])
fg_draw.rounded_rectangle([*band_pts[0], *band_pts[1]], radius=18 * scale, fill=WHITE)

for dx in (-150, 0, 150):
    r = (lobe_r if dx == 0 else int(lobe_r * 0.82)) * scale
    cxs, cys = cx + dx * scale, lobe_y * scale + cy * (1 - scale) + offset_y
    fg_draw.ellipse([cxs - r, cys - r, cxs + r, cys + r], fill=WHITE)
rect_pts = scaled([(cx - band_w // 2, lobe_y), (cx + band_w // 2, band_top + 20)])
fg_draw.rectangle([*rect_pts[0], *rect_pts[1]], fill=WHITE)

abs_nodes_fg = scaled(abs_nodes)
for a, b in [(0, 3), (1, 3), (2, 3)]:
    fg_draw.line([abs_nodes_fg[a], abs_nodes_fg[b]], fill=GREEN, width=int(10 * scale))
for x, y in abs_nodes_fg:
    r = node_r * scale
    fg_draw.ellipse([x - r, y - r, x + r, y + r], fill=GREEN)

fg.save("app_icon_foreground.png")
print("app_icon_foreground.png generado", fg.size)
