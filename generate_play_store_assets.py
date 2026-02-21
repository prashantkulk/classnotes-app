#!/usr/bin/env python3
"""
Generate Play Store assets for ClassNotes Android app:
1. App icon: 512x512 PNG (reuses existing icon design)
2. Feature graphic: 1024x500 PNG (banner with icon + app name)
"""

from PIL import Image, ImageDraw, ImageFont
import math


def lerp(a, b, t):
    return a + (b - a) * t


def create_rounded_rectangle(draw, xy, radius, fill):
    x0, y0, x1, y1 = xy
    r = min(radius, (x1 - x0) // 2, (y1 - y0) // 2)
    draw.rectangle([x0 + r, y0, x1 - r, y1], fill=fill)
    draw.rectangle([x0, y0 + r, x1, y1 - r], fill=fill)
    draw.pieslice([x0, y0, x0 + 2 * r, y0 + 2 * r], 180, 270, fill=fill)
    draw.pieslice([x1 - 2 * r, y0, x1, y0 + 2 * r], 270, 360, fill=fill)
    draw.pieslice([x0, y1 - 2 * r, x0 + 2 * r, y1], 90, 180, fill=fill)
    draw.pieslice([x1 - 2 * r, y1 - 2 * r, x1, y1], 0, 90, fill=fill)


def draw_teal_gradient(draw, width, height):
    """Draw the teal gradient background matching the app icon."""
    base_r, base_g, base_b = 0.200, 0.604, 0.737
    top_r = int(min(255, (base_r + 0.12) * 255))
    top_g = int(min(255, (base_g + 0.10) * 255))
    top_b = int(min(255, (base_b + 0.08) * 255))
    bot_r = int(max(0, (base_r - 0.06) * 255))
    bot_g = int(max(0, (base_g - 0.10) * 255))
    bot_b = int(max(0, (base_b - 0.06) * 255))

    for y in range(height):
        t = y / (height - 1)
        r = int(lerp(top_r, bot_r, t))
        g = int(lerp(top_g, bot_g, t))
        b = int(lerp(top_b, bot_b, t))
        draw.line([(0, y), (width - 1, y)], fill=(r, g, b))

    return (top_r, top_g, top_b), (bot_r, bot_g, bot_b)


def draw_notebook_icon(img_rgba, cx, cy, scale=1.0):
    """Draw the notebook icon centered at (cx, cy) with given scale."""
    base_r, base_g, base_b = 0.200, 0.604, 0.737

    # Get gradient colors for dog-ear
    top_r = int(min(255, (base_r + 0.12) * 255))
    top_g = int(min(255, (base_g + 0.10) * 255))
    top_b = int(min(255, (base_b + 0.08) * 255))
    bot_r = int(max(0, (base_r - 0.06) * 255))
    bot_g = int(max(0, (base_g - 0.10) * 255))
    bot_b = int(max(0, (base_b - 0.06) * 255))

    s = scale
    page_w = int(420 * s)
    page_h = int(500 * s)
    page_offset_x = int(20 * s)
    page_left = cx - page_w // 2 + page_offset_x
    page_top = cy - page_h // 2
    page_right = page_left + page_w
    page_bottom = page_top + page_h

    size = img_rgba.size[1]

    # Shadow
    shadow_img = Image.new("RGBA", img_rgba.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_img)
    so = int(6 * s)
    create_rounded_rectangle(
        shadow_draw,
        (page_left + so, page_top + so, page_right + so, page_bottom + so),
        radius=int(28 * s), fill=(0, 0, 0, 40),
    )
    img_rgba = Image.alpha_composite(img_rgba, shadow_img)

    # Back page
    back_img = Image.new("RGBA", img_rgba.size, (0, 0, 0, 0))
    back_draw = ImageDraw.Draw(back_img)
    bo = int(14 * s)
    create_rounded_rectangle(
        back_draw,
        (page_left + bo, page_top - bo + int(6 * s),
         page_right + bo, page_bottom - bo + int(6 * s)),
        radius=int(28 * s), fill=(235, 240, 242, 200),
    )
    img_rgba = Image.alpha_composite(img_rgba, back_img)

    # Main page
    page_img = Image.new("RGBA", img_rgba.size, (0, 0, 0, 0))
    page_draw = ImageDraw.Draw(page_img)
    create_rounded_rectangle(
        page_draw,
        (page_left, page_top, page_right, page_bottom),
        radius=int(24 * s), fill=(255, 255, 255, 255),
    )
    img_rgba = Image.alpha_composite(img_rgba, page_img)

    final_draw = ImageDraw.Draw(img_rgba)

    # Dog-ear
    fold_size = int(52 * s)
    fold_x = page_right - fold_size
    t_fold = page_top / max(1, (size - 1))
    fold_bg_r = int(lerp(top_r, bot_r, t_fold))
    fold_bg_g = int(lerp(top_g, bot_g, t_fold))
    fold_bg_b = int(lerp(top_b, bot_b, t_fold))
    final_draw.polygon(
        [(fold_x, page_top), (page_right, page_top), (page_right, page_top + fold_size)],
        fill=(fold_bg_r, fold_bg_g, fold_bg_b, 255),
    )
    final_draw.polygon(
        [(fold_x, page_top), (fold_x, page_top + fold_size), (page_right, page_top + fold_size)],
        fill=(220, 225, 230, 255),
    )

    # Notebook lines
    line_color = (180, 210, 215, 180)
    lml = page_left + int(65 * s)
    lmr = page_right - int(45 * s)
    first_y = page_top + int(120 * s)
    spacing = int(52 * s)

    for i in range(6):
        ly = first_y + i * spacing
        if ly < page_bottom - int(50 * s):
            final_draw.line([(lml, ly), (lmr, ly)], fill=line_color, width=max(1, int(3 * s)))

    # Text blocks
    text_color = (int(base_r * 255), int(base_g * 255), int(base_b * 255), 160)
    text_widths = [0.85, 0.65, 0.78, 0.50]
    th = int(10 * s)

    for i, tw in enumerate(text_widths):
        ly = first_y + i * spacing
        if ly < page_bottom - int(50 * s):
            avail_w = lmr - lml
            block_w = int(avail_w * tw)
            create_rounded_rectangle(
                final_draw,
                (lml, ly - th - int(4 * s), lml + block_w, ly - int(4 * s)),
                radius=max(1, int(4 * s)), fill=text_color,
            )

    # Margin line
    margin_x = page_left + int(50 * s)
    final_draw.line(
        [(margin_x, page_top + int(20 * s)), (margin_x, page_bottom - int(20 * s))],
        fill=(220, 100, 100, 120), width=max(1, int(3 * s)),
    )

    # Binding dots
    binding_x = page_left - int(8 * s)
    dot_r = int(7 * s)
    dot_start = page_top + int(60 * s)
    dot_end = page_bottom - int(60 * s)
    dot_spacing = (dot_end - dot_start) / 4

    for i in range(5):
        dy = int(dot_start + i * dot_spacing)
        final_draw.ellipse(
            [binding_x - dot_r, dy - dot_r, binding_x + dot_r, dy + dot_r],
            fill=(255, 255, 255, 200),
        )

    # Pencil
    ptx = page_right - int(60 * s)
    pty = page_bottom - int(55 * s)
    plen = int(90 * s)
    angle = math.radians(45)
    pex = ptx - plen * math.cos(angle)
    pey = pty - plen * math.sin(angle)
    pw = int(5 * s)
    dx = pw * math.sin(angle)
    dy = pw * math.cos(angle)
    bsx = ptx - int(18 * s) * math.cos(angle)
    bsy = pty - int(18 * s) * math.sin(angle)

    final_draw.polygon(
        [(bsx - dx, bsy + dy), (bsx + dx, bsy - dy),
         (pex + dx, pey - dy), (pex - dx, pey + dy)],
        fill=(255, 255, 255, 180),
    )
    final_draw.polygon(
        [(ptx, pty), (bsx - dx, bsy + dy), (bsx + dx, bsy - dy)],
        fill=(255, 220, 150, 200),
    )

    return img_rgba


def generate_app_icon():
    """Generate 512x512 app icon for Play Store."""
    size = 512
    img = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(img)
    draw_teal_gradient(draw, size, size)

    img_rgba = img.convert("RGBA")
    img_rgba = draw_notebook_icon(img_rgba, size // 2, size // 2, scale=0.5)

    final_rgb = img_rgba.convert("RGB")
    output = "/Users/prashant/Projects/ClassNotes/screenshots/android-screenshots/app-icon-512.png"
    final_rgb.save(output, "PNG")
    print(f"App icon saved to {output} ({final_rgb.size[0]}x{final_rgb.size[1]})")
    return output


def generate_feature_graphic():
    """Generate 1024x500 feature graphic for Play Store."""
    width, height = 1024, 500
    img = Image.new("RGB", (width, height))
    draw = ImageDraw.Draw(img)
    draw_teal_gradient(draw, width, height)

    img_rgba = img.convert("RGBA")

    # Draw the notebook icon on the left side, scaled down
    icon_cx = 280
    icon_cy = height // 2
    img_rgba = draw_notebook_icon(img_rgba, icon_cx, icon_cy, scale=0.38)

    final_draw = ImageDraw.Draw(img_rgba)

    # App name text on the right side
    # Try to find a good system font
    font_large = None
    font_small = None
    font_paths = [
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/SFNSDisplay.ttf",
        "/System/Library/Fonts/SFNS.ttf",
        "/Library/Fonts/Arial.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]

    for fp in font_paths:
        try:
            font_large = ImageFont.truetype(fp, 72)
            font_small = ImageFont.truetype(fp, 28)
            break
        except (IOError, OSError):
            continue

    if font_large is None:
        font_large = ImageFont.load_default()
        font_small = ImageFont.load_default()

    # "ClassNotes" title
    title = "ClassNotes"
    text_x = 500
    title_y = height // 2 - 50

    # Draw text shadow
    final_draw.text((text_x + 2, title_y + 2), title,
                    fill=(0, 0, 0, 60), font=font_large)
    # Draw text
    final_draw.text((text_x, title_y), title,
                    fill=(255, 255, 255, 255), font=font_large)

    # Tagline
    tagline = "Share & request class notes"
    tag_y = title_y + 85
    final_draw.text((text_x + 2, tag_y + 1), tagline,
                    fill=(0, 0, 0, 40), font=font_small)
    final_draw.text((text_x, tag_y), tagline,
                    fill=(255, 255, 255, 220), font=font_small)

    final_rgb = img_rgba.convert("RGB")
    output = "/Users/prashant/Projects/ClassNotes/screenshots/android-screenshots/feature-graphic-1024x500.png"
    final_rgb.save(output, "PNG")
    print(f"Feature graphic saved to {output} ({final_rgb.size[0]}x{final_rgb.size[1]})")
    return output


if __name__ == "__main__":
    generate_app_icon()
    generate_feature_graphic()
