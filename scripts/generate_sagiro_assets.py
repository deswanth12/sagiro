import os
import math
from PIL import Image, ImageDraw, ImageFont

# Brand Color Palette
DEEP_EMERALD = (11, 61, 46, 255)       # #0B3D2E
SECONDARY_EMERALD = (8, 127, 91, 255)   # #087F5B
ACCENT_LIME = (168, 224, 99, 255)      # #A8E063
DARK_BG = (7, 18, 14, 255)             # #07120E
LIGHT_BG = (247, 250, 248, 255)        # #F7FAF8
WHITE = (255, 255, 255, 255)
BLACK = (0, 0, 0, 255)
TRANSPARENT = (0, 0, 0, 0)

# Create assets directories
os.makedirs("assets/branding", exist_ok=True)
os.makedirs("assets", exist_ok=True)

def draw_sagiro_symbol(draw, cx, cy, size, color_upper=ACCENT_LIME, color_lower=SECONDARY_EMERALD, color_core=DEEP_EMERALD):
    """
    Renders the precision geometric SAGIRO symbol:
    An abstract interlocking emerald-lime S-diamond mark.
    """
    s = size / 2.0

    # Upper Ribbon (Top Right to Center)
    p_upper = [
        (cx + s * 0.15, cy - s * 0.85),
        (cx + s * 0.75, cy - s * 0.85),
        (cx + s * 0.45, cy - s * 0.15),
        (cx - s * 0.25, cy - s * 0.15),
        (cx - s * 0.65, cy - s * 0.85),
    ]

    # Lower Ribbon (Bottom Left to Center)
    p_lower = [
        (cx - s * 0.15, cy + s * 0.85),
        (cx - s * 0.75, cy + s * 0.85),
        (cx - s * 0.45, cy + s * 0.15),
        (cx + s * 0.25, cy + s * 0.15),
        (cx + s * 0.65, cy + s * 0.85),
    ]

    # Center Interlocking Core (Diamond Flow)
    p_core = [
        (cx - s * 0.25, cy - s * 0.15),
        (cx + s * 0.45, cy - s * 0.15),
        (cx + s * 0.25, cy + s * 0.15),
        (cx - s * 0.45, cy + s * 0.15),
    ]

    # Draw lower loop
    draw.polygon(p_lower, fill=color_lower)
    # Draw upper loop
    draw.polygon(p_upper, fill=color_upper)
    # Draw core diamond accent
    draw.polygon(p_core, fill=color_core)

def create_icon(size=1024, bg_color=DARK_BG, symbol_upper=ACCENT_LIME, symbol_lower=SECONDARY_EMERALD, symbol_core=WHITE, padding_ratio=0.25):
    img = Image.new("RGBA", (size, size), bg_color)
    draw = ImageDraw.Draw(img)
    cx, cy = size / 2.0, size / 2.0
    symbol_size = size * (1.0 - 2 * padding_ratio)
    draw_sagiro_symbol(draw, cx, cy, symbol_size, symbol_upper, symbol_lower, symbol_core)
    return img

def create_adaptive_foreground(size=1024, safe_ratio=0.58):
    """
    Creates Android Adaptive Icon Foreground:
    Transparent background, centered emblem inside 66% safe-zone viewport.
    """
    img = Image.new("RGBA", (size, size), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    cx, cy = size / 2.0, size / 2.0
    symbol_size = size * safe_ratio
    draw_sagiro_symbol(draw, cx, cy, symbol_size, ACCENT_LIME, SECONDARY_EMERALD, WHITE)
    return img

def main():
    print("Generating SAGIRO Brand Assets...")

    # 1. Standalone Symbol 1024x1024 & 512x512
    sym_1024 = create_icon(1024, TRANSPARENT, ACCENT_LIME, SECONDARY_EMERALD, DEEP_EMERALD, padding_ratio=0.15)
    sym_1024.save("assets/branding/sagiro_symbol_1024.png")
    sym_512 = sym_1024.resize((512, 512), Image.Resampling.LANCZOS)
    sym_512.save("assets/branding/sagiro_symbol_512.png")

    # 2. Primary App Icon (Dark Background) 1024x1024 & 512x512
    app_icon_1024 = create_icon(1024, DARK_BG, ACCENT_LIME, SECONDARY_EMERALD, WHITE, padding_ratio=0.22)
    app_icon_1024.save("assets/branding/sagiro_icon_1024.png")
    app_icon_1024.save("assets/sagiro_launcher_full.png")
    app_icon_512 = app_icon_1024.resize((512, 512), Image.Resampling.LANCZOS)
    app_icon_512.save("assets/branding/sagiro_icon_512.png")

    # 3. Light Background Version 1024x1024
    light_1024 = create_icon(1024, LIGHT_BG, DEEP_EMERALD, SECONDARY_EMERALD, ACCENT_LIME, padding_ratio=0.22)
    light_1024.save("assets/branding/sagiro_light_1024.png")

    # 4. Dark Background Version 1024x1024
    dark_1024 = create_icon(1024, DARK_BG, ACCENT_LIME, SECONDARY_EMERALD, WHITE, padding_ratio=0.22)
    dark_1024.save("assets/branding/sagiro_dark_1024.png")

    # 5. Monochrome Version (White on Dark) 1024x1024
    mono_1024 = create_icon(1024, DARK_BG, WHITE, (200, 200, 200, 255), (100, 100, 100, 255), padding_ratio=0.22)
    mono_1024.save("assets/branding/sagiro_monochrome_1024.png")

    # 6. Android Adaptive Icon Foreground (Transparent, Safe Zone Padded)
    fg_1024 = create_adaptive_foreground(1024, safe_ratio=0.58)
    fg_1024.save("assets/sagiro_launcher_foreground.png")

    # 7. Scalable SVG Files
    svg_symbol = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="100%" height="100%">
  <rect width="512" height="512" rx="128" fill="#07120E"/>
  <g transform="translate(256, 256)">
    <!-- Lower Ribbon -->
    <polygon points="-24,136 -120,136 -72,24 40,24 104,136" fill="#087F5B"/>
    <!-- Upper Ribbon -->
    <polygon points="24,-136 120,-136 72,-24 -40,-24 -104,-136" fill="#A8E063"/>
    <!-- Core Diamond Flow -->
    <polygon points="-40,-24 72,-24 40,24 -72,24" fill="#FFFFFF"/>
  </g>
</svg>'''
    with open("assets/branding/sagiro_symbol.svg", "w", encoding="utf-8") as f:
        f.write(svg_symbol)

    svg_wordmark = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 120" width="100%" height="100%">
  <text x="50%" y="55%" dominant-baseline="middle" text-anchor="middle" fill="#E8F5F0" font-family="system-ui, -apple-system, sans-serif" font-weight="900" font-size="64" letter-spacing="12">SAGIRO</text>
  <text x="50%" y="88%" dominant-baseline="middle" text-anchor="middle" fill="#A8E063" font-family="system-ui, -apple-system, sans-serif" font-weight="600" font-size="16" letter-spacing="4">YOUR MONEY, SIMPLIFIED.</text>
</svg>'''
    with open("assets/branding/sagiro_wordmark.svg", "w", encoding="utf-8") as f:
        f.write(svg_wordmark)

    svg_horizontal = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 200" width="100%" height="100%">
  <rect width="800" height="200" rx="32" fill="#07120E"/>
  <g transform="translate(120, 100) scale(0.45)">
    <polygon points="-24,136 -120,136 -72,24 40,24 104,136" fill="#087F5B"/>
    <polygon points="24,-136 120,-136 72,-24 -40,-24 -104,-136" fill="#A8E063"/>
    <polygon points="-40,-24 72,-24 40,24 -72,24" fill="#FFFFFF"/>
  </g>
  <text x="240" y="95" fill="#FFFFFF" font-family="system-ui, -apple-system, sans-serif" font-weight="900" font-size="54" letter-spacing="10">SAGIRO</text>
  <text x="242" y="135" fill="#A8E063" font-family="system-ui, -apple-system, sans-serif" font-weight="600" font-size="16" letter-spacing="3">YOUR MONEY, SIMPLIFIED.</text>
</svg>'''
    with open("assets/branding/sagiro_horizontal_logo.svg", "w", encoding="utf-8") as f:
        f.write(svg_horizontal)

    print("All SAGIRO Brand Assets Successfully Generated!")

if __name__ == "__main__":
    main()
