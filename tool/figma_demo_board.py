from __future__ import annotations

import math
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


OUT = Path(os.environ.get("TEMP", ".")) / "mystery_malaysia_ui_demo.png"
ROOT = Path(__file__).resolve().parents[1]
LOGO = ROOT / "assets" / "images" / "mystery_malaysia_logo-v2.png"

INK = "#13233A"
MUTED = "#627086"
CANVAS = "#FFFBF2"
WHITE = "#FFFFFF"
OUTLINE = "#E4E8ED"
TEAL = "#0FAF9A"
DARK_TEAL = "#087F74"
PALE_TEAL = "#D9F8F2"
MANGO = "#FFC83D"
PALE_MANGO = "#FFF2B8"
HIBISCUS = "#FF5C75"
PALE_HIBISCUS = "#FFE1E6"
PURPLE = "#7559E9"
SKY = "#48B9F2"
GREEN = "#2DBE78"
STRAITS = "#075985"

PHONE_W, PHONE_H = 390, 844
COLS, ROWS = 5, 4
GAP_X, GAP_Y = 70, 120
MARGIN_X, MARGIN_Y = 90, 210
BOARD_W = MARGIN_X * 2 + COLS * PHONE_W + (COLS - 1) * GAP_X
BOARD_H = MARGIN_Y + ROWS * PHONE_H + (ROWS - 1) * GAP_Y + 120


def font(size: int, bold: bool = False):
    paths = [
        Path("C:/Windows/Fonts/seguisb.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf"),
        Path("C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf"),
    ]
    for path in paths:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


F10, F11, F12, F13, F14 = (font(n) for n in (10, 11, 12, 13, 14))
F15B, F16B, F18B, F20B, F24B, F28B, F34B = (font(n, True) for n in (15, 16, 18, 20, 24, 28, 34))


def rr(d, xy, radius=16, fill=WHITE, outline=None, width=1):
    d.rounded_rectangle(xy, radius, fill=fill, outline=outline, width=width)


def txt(d, xy, value, fill=INK, f=F14, anchor=None, spacing=4):
    d.multiline_text(xy, value, fill=fill, font=f, anchor=anchor, spacing=spacing)


def wrap(value: str, chars: int):
    words, lines, line = value.split(), [], ""
    for word in words:
        candidate = f"{line} {word}".strip()
        if len(candidate) <= chars:
            line = candidate
        else:
            if line:
                lines.append(line)
            line = word
    if line:
        lines.append(line)
    return "\n".join(lines)


def pill(d, x, y, label, fill=PALE_TEAL, color=DARK_TEAL, w=None):
    if w is None:
        w = max(64, int(d.textlength(label, font=F11)) + 22)
    rr(d, (x, y, x + w, y + 25), 13, fill)
    txt(d, (x + w / 2, y + 12), label, color, F11, "mm")


def button(d, x, y, w, label, fill=TEAL, color=WHITE, outline=None):
    rr(d, (x, y, x + w, y + 48), 16, fill, outline)
    txt(d, (x + w / 2, y + 24), label, color, F15B, "mm")


def field(d, x, y, w, label, value="", disabled=False, error=""):
    txt(d, (x, y), label, MUTED, F11)
    rr(d, (x, y + 17, x + w, y + 63), 12, "#F5F6F7" if disabled else WHITE, OUTLINE)
    txt(d, (x + 14, y + 40), value or label, MUTED if disabled or not value else INK, F13, "lm")
    if error:
        txt(d, (x, y + 67), error, HIBISCUS, F10)


def card(d, x, y, w, h, fill=WHITE, outline=OUTLINE, radius=18):
    rr(d, (x, y, x + w, y + h), radius, fill, outline)


def appbar(d, title, back=False, right=""):
    if back:
        txt(d, (28, 50), "‹", INK, F34B, "mm")
    txt(d, (56 if back else 24, 50), title, INK, F20B, "lm")
    if right:
        txt(d, (362, 50), right, TEAL, F13, "rm")


def nav(d, active=0):
    rr(d, (16, 775, 374, 827), 20, WHITE, OUTLINE)
    items = [("Home", "⌂"), ("Explore", "◇"), ("Mission", "◎"), ("Passport", "▣"), ("Profile", "○")]
    for i, (label, icon) in enumerate(items):
        x = 52 + i * 71
        color = TEAL if i == active else MUTED
        txt(d, (x, 792), icon, color, F18B, "mm")
        txt(d, (x, 815), label, color, F10, "mm")


def flower(d, cx, cy, r=12, color=HIBISCUS):
    for a in range(0, 360, 72):
        x = cx + math.cos(math.radians(a)) * r
        y = cy + math.sin(math.radians(a)) * r
        d.ellipse((x - r * .65, y - r * .65, x + r * .65, y + r * .65), fill=color)
    d.ellipse((cx - r * .35, cy - r * .35, cx + r * .35, cy + r * .35), fill=MANGO)


def mystery_box(d, cx, cy, scale=1.0):
    w, h = 150 * scale, 112 * scale
    rr(d, (cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2), int(18 * scale), PURPLE)
    d.polygon([(cx - w / 2, cy - h / 2), (cx, cy - h * .82), (cx + w / 2, cy - h / 2), (cx, cy - h * .18)], fill="#8D73F2")
    rr(d, (cx - 12 * scale, cy - h / 2, cx + 12 * scale, cy + h / 2), int(5 * scale), MANGO)
    d.ellipse((cx - 12 * scale, cy - 14 * scale, cx + 12 * scale, cy + 10 * scale), fill=INK)
    txt(d, (cx, cy - 3 * scale), "?", WHITE, font(int(18 * scale), True), "mm")


def phone_base(label, index):
    im = Image.new("RGB", (PHONE_W, PHONE_H), CANVAS)
    d = ImageDraw.Draw(im)
    rr(d, (1, 1, PHONE_W - 2, PHONE_H - 2), 35, CANVAS, "#CED5DC", 2)
    d.rounded_rectangle((144, 10, 246, 34), 15, fill=INK)
    txt(d, (24, 18), "9:41", INK, F10)
    txt(d, (365, 18), "●  ▰", INK, F10, "ra")
    return im, d


def screen_welcome(d, im):
    for i, c in enumerate([PALE_MANGO, PALE_TEAL, PALE_HIBISCUS]):
        d.ellipse((-100 + i * 160, 80 + i * 60, 210 + i * 180, 420 + i * 70), fill=c)
    logo = Image.open(LOGO).convert("RGBA")
    logo.thumbnail((245, 245))
    im.paste(logo, ((PHONE_W - logo.width) // 2, 150), logo)
    txt(d, (195, 430), "Malaysia is full of stories.\nFind the ones hiding nearby.", INK, F18B, "mm", 7)
    pill(d, 105, 508, "3 stops • one mystery", PALE_TEAL, DARK_TEAL, 180)
    button(d, 36, 620, 318, "Start the adventure")
    txt(d, (195, 692), "Already exploring?  Sign in", STRAITS, F13, "mm")
    flower(d, 330, 744, 15)


def screen_signin(d, im):
    appbar(d, "Welcome back", True)
    txt(d, (28, 92), "Continue your Malaysian mystery", MUTED, F14)
    field(d, 28, 150, 334, "Email", "traveller@email.com")
    field(d, 28, 235, 334, "Password", "••••••••")
    txt(d, (362, 320), "Forgot password?", TEAL, F12, "ra")
    button(d, 28, 365, 334, "Sign in")
    txt(d, (195, 442), "or", MUTED, F12, "mm")
    button(d, 28, 474, 334, "Continue with Google", WHITE, INK, OUTLINE)
    card(d, 28, 555, 334, 64, PALE_MANGO, None)
    txt(d, (44, 572), "Email not verified? Check your inbox, then\nreturn here to sign in.", INK, F12)
    txt(d, (195, 694), "New traveller?  Create account", TEAL, F13, "mm")


def screen_register(d, im):
    appbar(d, "Create account", True)
    field(d, 28, 100, 334, "Display name", "Nur Traveller")
    field(d, 28, 180, 334, "Email", "nur@example.com")
    field(d, 28, 260, 334, "Password", "••••••••")
    field(d, 28, 340, 334, "Confirm password", "••••••••")
    card(d, 28, 440, 334, 78, PALE_TEAL, None)
    txt(d, (44, 456), "After registration, open the branded Mystery\nMalaysia verification email before signing in.", DARK_TEAL, F12)
    button(d, 28, 548, 334, "Create my account")
    txt(d, (195, 626), "Errors appear below the relevant field", MUTED, F11, "mm")


def screen_home(d, im):
    txt(d, (24, 55), "Hello, traveller!", INK, F24B, "lm")
    txt(d, (24, 84), "Ready to uncover somewhere unexpected?", MUTED, F12)
    d.ellipse((328, 44, 366, 82), fill=PALE_HIBISCUS)
    txt(d, (347, 63), "●", HIBISCUS, F15B, "mm")
    card(d, 20, 118, 350, 172, STRAITS, None, 24)
    pill(d, 38, 136, "ACTIVE • STOP 2 OF 3", MANGO, INK, 154)
    txt(d, (38, 180), "Cipher of the\nValley Escarpment", WHITE, F24B)
    txt(d, (38, 244), "Continue the mystery without revealing the route.", "#CDECF7", F11)
    button(d, 235, 224, 116, "Continue", MANGO, INK)
    txt(d, (24, 329), "Your adventures", INK, F18B)
    card(d, 20, 358, 170, 134, PALE_TEAL, None)
    txt(d, (36, 376), "◇", DARK_TEAL, F28B)
    txt(d, (36, 418), "Begin a new\nmystery", INK, F15B)
    card(d, 200, 358, 170, 134, PALE_MANGO, None)
    txt(d, (216, 376), "▤", INK, F28B)
    txt(d, (216, 418), "Mission\nhistory", INK, F15B)
    txt(d, (24, 535), "Recently completed", INK, F18B)
    card(d, 20, 564, 350, 104)
    flower(d, 58, 616, 13)
    txt(d, (86, 589), "Echoes of Old Kuala Lumpur", INK, F14, None)
    txt(d, (86, 616), "3 stops • diary ready", MUTED, F12)
    pill(d, 265, 630, "Completed", PALE_TEAL, DARK_TEAL, 86)
    nav(d, 0)


def screen_explore(d, im):
    appbar(d, "Explore", False)
    txt(d, (24, 90), "A hidden route is waiting near you.", MUTED, F13)
    card(d, 20, 130, 350, 486, WHITE, OUTLINE, 28)
    for r, col in [(105, PALE_TEAL), (82, PALE_MANGO), (62, PALE_HIBISCUS)]:
        d.ellipse((195-r, 250-r, 195+r, 250+r), fill=col)
    mystery_box(d, 195, 264, .9)
    txt(d, (195, 398), "Begin your enigmatic\nodyssey", INK, F24B, "mm", 6)
    txt(d, (195, 468), "Tap the mystery box. Your location helps\nGemini create three safe, lesser-known stops.", MUTED, F12, "mm")
    pill(d, 103, 535, "Tap to awaken the mystery", PURPLE, WHITE, 184)
    card(d, 20, 642, 350, 90, PALE_TEAL, None)
    flower(d, 48, 685, 10, TEAL)
    txt(d, (72, 661), "Malaysia clue", DARK_TEAL, F13, None)
    txt(d, (72, 686), "Batik motifs often carry regional stories.", INK, F11)
    nav(d, 1)


def screen_constraints(d, im):
    appbar(d, "Plan your mystery", True)
    txt(d, (24, 88), "Only the essentials—your current location\nsets the starting area automatically.", MUTED, F12)
    field(d, 24, 142, 164, "Date", "12 Aug 2026")
    field(d, 202, 142, 164, "Start time", "9:30 AM")
    field(d, 24, 230, 342, "Budget", "RM 80 per person")
    field(d, 24, 318, 342, "Maximum travel distance", "15 km")
    field(d, 24, 406, 342, "Duration", "4 hours")
    card(d, 24, 510, 342, 96, PALE_MANGO, None)
    txt(d, (42, 528), "Duration warning", INK, F14, None)
    txt(d, (42, 554), "Opening times and realistic travel time are\nchecked before the three-stop route is offered.", MUTED, F11)
    button(d, 24, 638, 342, "Generate 3 missions", PURPLE)
    nav(d, 1)


def mission_card(d, y, title, briefing, diff, accent):
    card(d, 20, y, 350, 180)
    d.rounded_rectangle((20, y, 29, y + 180), 5, fill=accent)
    txt(d, (42, y + 18), title, INK, F16B)
    pill(d, 274, y + 15, diff, PALE_MANGO if diff == "Easy" else PALE_HIBISCUS, INK, 76)
    txt(d, (42, y + 50), wrap(briefing, 45), MUTED, F11)
    for i in range(3):
        x = 43 + i * 72
        rr(d, (x, y + 107, x + 56, y + 151), 12, "#EEF1F4")
        txt(d, (x + 28, y + 129), "?", accent, F18B, "mm")
    txt(d, (274, y + 129), "3 hidden stops", MUTED, F11, "mm")
    txt(d, (350, y + 158), "Preview  ›", TEAL, F12, "ra")


def screen_generated(d, im):
    appbar(d, "Choose a mystery", True, "Regenerate all")
    txt(d, (24, 88), "Three different missions, each with three hidden stops.", MUTED, F11)
    mission_card(d, 116, "Echoes Behind the River", "Trace overlooked stories through craft, community and water.", "Easy", TEAL)
    mission_card(d, 310, "The Lantern Keeper's Trail", "Follow bright cultural signs before venues close for the day.", "Medium", PURPLE)
    mission_card(d, 504, "Secrets of the Limestone", "A longer route balancing heritage, safety and quiet places.", "Hard", HIBISCUS)
    nav(d, 1)


def stop_preview(d, y, n, briefing, warning):
    card(d, 24, y, 342, 112)
    rr(d, (38, y + 18, 84, y + 64), 14, PALE_TEAL)
    txt(d, (61, y + 41), str(n), DARK_TEAL, F18B, "mm")
    txt(d, (98, y + 17), f"Hidden stop {n}", INK, F14, None)
    txt(d, (98, y + 43), wrap(briefing, 38), MUTED, F11)
    txt(d, (98, y + 85), warning, HIBISCUS if "Closes" in warning else DARK_TEAL, F10)
    txt(d, (350, y + 88), "↻", PURPLE, F20B, "ra")


def screen_preview(d, im):
    appbar(d, "Mission preview", True)
    txt(d, (24, 88), "The Lantern Keeper's Trail", INK, F20B)
    txt(d, (24, 120), "Three cultural signals form one story—without\nrevealing their names or route.", MUTED, F12)
    pill(d, 24, 164, "Medium", PALE_HIBISCUS, INK, 82)
    pill(d, 114, 164, "≈ 4 hours", PALE_MANGO, INK, 96)
    card(d, 24, 204, 342, 58, PALE_HIBISCUS, None)
    txt(d, (42, 220), "Duration warning: begin before 2:00 PM", HIBISCUS, F12)
    stop_preview(d, 282, 1, "Handmade patterns preserve a riverside memory.", "Open 9:00 AM–5:00 PM")
    stop_preview(d, 404, 2, "A public landmark tells a lesser-known civic story.", "Closes at 4:30 PM")
    stop_preview(d, 526, 3, "A quiet green threshold completes the final cipher.", "Outdoor • daylight recommended")
    button(d, 24, 672, 342, "Save this mission")
    nav(d, 1)


def history_row(d, y, title, status, color, action):
    card(d, 20, y, 350, 112)
    d.ellipse((36, y + 20, 86, y + 70), fill=color)
    txt(d, (61, y + 45), "◇", WHITE, F20B, "mm")
    txt(d, (100, y + 18), title, INK, F14, None)
    pill(d, 100, y + 48, status, color if status in ("Active", "Paused") else PALE_TEAL, WHITE if status in ("Active", "Paused") else DARK_TEAL, 82)
    txt(d, (350, y + 88), action, TEAL, F13, "ra")


def screen_history(d, im):
    appbar(d, "Mission history", True)
    pill(d, 20, 88, "All", TEAL, WHITE, 62)
    pill(d, 90, 88, "Not started", WHITE, MUTED, 94)
    pill(d, 192, 88, "Paused", WHITE, MUTED, 76)
    pill(d, 276, 88, "Completed", WHITE, MUTED, 94)
    history_row(d, 132, "Lantern Keeper's Trail", "Not started", SKY, "Start mission  ›")
    history_row(d, 258, "Cipher of the Valley", "Paused", PURPLE, "Resume mission  ›")
    history_row(d, 384, "Echoes of Old KL", "Active", TEAL, "Continue  ›")
    history_row(d, 510, "Whispers of the Jetty", "Completed", GREEN, "View memories  ›")
    nav(d, 2)


def map_panel(d, x, y, w, h):
    rr(d, (x, y, x + w, y + h), 24, "#DDF2E4")
    for i in range(5):
        d.line((x + 20, y + 25 + i * 38, x + w - 15, y + 4 + i * 39), fill=WHITE, width=12)
    for i in range(4):
        d.line((x + 38 + i * 75, y + 10, x + 5 + i * 82, y + h - 10), fill="#B7DCC8", width=4)
    d.ellipse((x + w / 2 - 22, y + h / 2 - 22, x + w / 2 + 22, y + h / 2 + 22), fill="#B8E4FA")
    d.ellipse((x + w / 2 - 9, y + h / 2 - 9, x + w / 2 + 9, y + h / 2 + 9), fill=SKY)
    d.ellipse((x + w / 2 - 4, y + h / 2 - 4, x + w / 2 + 4, y + h / 2 + 4), fill=WHITE)


def screen_active(d, im):
    appbar(d, "Active mission", True, "•••")
    txt(d, (24, 88), "Cipher of the Valley", INK, F18B)
    txt(d, (24, 116), "Stop 2 of 3", MUTED, F12)
    for i in range(3):
        x = 72 + i * 122
        d.ellipse((x - 13, 142, x + 13, 168), fill=TEAL if i <= 1 else OUTLINE)
        txt(d, (x, 155), "✓" if i == 0 else str(i + 1), WHITE if i <= 1 else MUTED, F11, "mm")
        if i < 2:
            d.line((x + 16, 155, x + 106, 155), fill=TEAL if i == 0 else OUTLINE, width=4)
    map_panel(d, 20, 190, 350, 240)
    pill(d, 36, 210, "Your location only", WHITE, DARK_TEAL, 130)
    card(d, 20, 450, 350, 128, PALE_MANGO, None)
    txt(d, (38, 468), "Current clue", INK, F13B if 'F13B' in globals() else F14)
    txt(d, (38, 496), "Find the riverside cultural centre where\ntraditional pewter craft is demonstrated.", INK, F14)
    txt(d, (38, 548), "Open clue & hint  ›", PURPLE, F12)
    card(d, 20, 598, 350, 60, PALE_TEAL, None)
    txt(d, (38, 615), "Arrival verifies automatically when you enter\nthe safe destination radius.", DARK_TEAL, F11)
    button(d, 20, 680, 168, "Pause", WHITE, INK, OUTLINE)
    button(d, 202, 680, 168, "Abandon", PALE_HIBISCUS, HIBISCUS)
    nav(d, 2)


def screen_clue(d, im):
    appbar(d, "Clue & hint", True)
    pill(d, 24, 88, "STOP 2 OF 3", PURPLE, WHITE, 104)
    card(d, 20, 128, 350, 210, PALE_MANGO, None, 24)
    txt(d, (42, 150), "Your clue", INK, F16B)
    txt(d, (42, 188), "Find the riverside cultural centre\nwhere visitors can watch artisans\nshape Malaysia's famous pewter,\nnear Jalan Usahawan.", INK, F18B, None, 8)
    txt(d, (42, 302), "Obvious enough to identify one place—\nwithout displaying its name on the map.", MUTED, F10)
    card(d, 20, 360, 350, 142, WHITE, OUTLINE)
    txt(d, (42, 380), "Additional hint", INK, F15B)
    txt(d, (42, 414), "You may request this once for this stop.", MUTED, F12)
    button(d, 42, 444, 306, "Reveal one additional hint", PURPLE)
    card(d, 20, 526, 350, 96, PALE_TEAL, None)
    txt(d, (42, 546), "No guessing form", DARK_TEAL, F14)
    txt(d, (42, 574), "Walk there naturally. GPS verifies arrival\nautomatically; the map reveals no route.", INK, F11)
    button(d, 20, 656, 350, "Return to mission", TEAL)
    nav(d, 2)


def screen_arrival(d, im):
    appbar(d, "Destination unlocked", True)
    card(d, 20, 88, 350, 112, TEAL, None, 24)
    txt(d, (44, 112), "✓  Location verified", WHITE, F15B)
    txt(d, (44, 148), "Royal Selangor Visitor Centre", WHITE, F20B)
    pill(d, 244, 165, "STOP 2 COMPLETE", MANGO, INK, 110)
    card(d, 20, 220, 350, 74, PALE_HIBISCUS, None)
    txt(d, (42, 238), "Opening hours warning", HIBISCUS, F13)
    txt(d, (42, 264), "Open today 9:00 AM–5:00 PM • 42 min left", INK, F11)
    sections = [
        ("History", "A former tin-mining craft became a Malaysian design icon.", PALE_MANGO),
        ("Cultural etiquette", "Ask before photographing artisans; keep workshop paths clear.", PALE_TEAL),
        ("Safety & access", "Indoor, staffed venue • step-free main entrance • public facilities.", "#E8F5EC"),
        ("Interesting fact", "The giant tankard here is recognised as the world's largest.", "#EDE8FF"),
    ]
    y = 314
    for title, body, fill in sections:
        card(d, 20, y, 350, 78, fill, None)
        txt(d, (40, y + 14), title, INK, F13)
        txt(d, (40, y + 40), wrap(body, 52), MUTED, F10)
        y += 88
    button(d, 20, 682, 350, "Collect piece & continue to stop 3", TEAL)
    nav(d, 2)


def screen_passport(d, im):
    appbar(d, "My passport", False)
    txt(d, (24, 86), "Every completed stop builds a unique mission stamp.", MUTED, F11)
    card(d, 20, 116, 350, 212, STRAITS, None, 24)
    txt(d, (40, 136), "Cipher of the Valley", WHITE, F16B)
    txt(d, (40, 165), "1 of 3 pieces collected", "#D1EFF9", F12)
    cx, cy = 196, 246
    d.ellipse((cx-64, cy-64, cx+64, cy+64), fill="#FFFFFF22", outline=MANGO, width=4)
    d.pieslice((cx-58, cy-58, cx+58, cy+58), 210, 330, fill=MANGO)
    flower(d, cx, cy, 20, HIBISCUS)
    txt(d, (330, 300), "AI-themed stamp", "#D1EFF9", F10, "ra")
    txt(d, (24, 360), "Achievements", INK, F18B)
    for i, (name, col) in enumerate([("Trailblazer", PURPLE), ("Culture Keeper", TEAL), ("Quiet Explorer", HIBISCUS)]):
        x = 20 + i * 118
        card(d, x, 392, 108, 120)
        d.ellipse((x+29, 406, x+79, 456), fill=col)
        txt(d, (x+54, 431), "✦", WHITE, F18B, "mm")
        txt(d, (x+54, 484), name.replace(" ", "\n"), INK, F11, "mm")
    txt(d, (24, 544), "Travel statistics", INK, F18B)
    stats = [("6", "Stops"), ("2", "Missions"), ("18 km", "Explored")]
    for i, (value, label) in enumerate(stats):
        x = 20 + i * 118
        card(d, x, 576, 108, 86, PALE_TEAL if i == 0 else WHITE)
        txt(d, (x+54, 604), value, DARK_TEAL, F18B, "mm")
        txt(d, (x+54, 638), label, MUTED, F10, "mm")
    nav(d, 3)


def screen_diary(d, im):
    appbar(d, "Travel diary", True)
    card(d, 20, 88, 350, 104, PALE_MANGO, None)
    txt(d, (40, 106), "AI diary is generated here", INK, F15B)
    txt(d, (40, 136), "Only completed eligible missions appear.\nConfirm your reflection before generation.", MUTED, F11)
    txt(d, (24, 224), "Eligible missions", INK, F18B)
    card(d, 20, 256, 350, 122)
    flower(d, 54, 304, 12)
    txt(d, (84, 274), "Echoes of Old Kuala Lumpur", INK, F14)
    pill(d, 84, 306, "3/3 stops", PALE_TEAL, DARK_TEAL, 82)
    txt(d, (350, 348), "Reflect  ›", TEAL, F12, "ra")
    card(d, 20, 402, 350, 184, WHITE, OUTLINE)
    txt(d, (40, 420), "Your confirmed reflection", INK, F15B)
    txt(d, (40, 452), wrap("The riverside craft workshop made me notice how living heritage can stay relevant without becoming crowded.", 48), MUTED, F12)
    pill(d, 40, 528, "Confirmed", GREEN, WHITE, 88)
    button(d, 20, 612, 350, "Generate AI travel diary", PURPLE)
    button(d, 20, 672, 168, "Copy", WHITE, INK, OUTLINE)
    button(d, 202, 672, 168, "Share", TEAL)
    nav(d, 3)


def member(d, y, initial, name, role, state, color, action=""):
    card(d, 20, y, 350, 76)
    d.ellipse((36, y+16, 80, y+60), fill=color)
    txt(d, (58, y+38), initial, WHITE, F15B, "mm")
    txt(d, (94, y+16), name, INK, F14)
    pill(d, 94, y+42, role, PALE_HIBISCUS if role == "Host" else PALE_TEAL, HIBISCUS if role == "Host" else DARK_TEAL, 58)
    txt(d, (280, y+38), state, MUTED, F11, "rm")
    if action:
        txt(d, (352, y+38), action, HIBISCUS, F11, "rm")


def screen_crew(d, im):
    appbar(d, "Travel crew", True, "Invite")
    card(d, 20, 88, 350, 112, "#EDE8FF", None, 24)
    txt(d, (40, 108), "Share this mystery", INK, F16B)
    txt(d, (40, 138), "Invite by email—friendship is not required.\nUnregistered emails receive an app invitation.", MUTED, F11)
    field(d, 20, 220, 350, "Friend's email", "friend@example.com")
    button(d, 20, 302, 350, "Send invitation", PURPLE)
    txt(d, (24, 382), "Crew members", INK, F18B)
    member(d, 418, "N", "Nur Traveller", "Host", "Ready", HIBISCUS)
    member(d, 506, "J", "Jessica", "Guest", "Accepted", TEAL, "Kick")
    member(d, 594, "A", "Amir", "Guest", "Waiting", SKY, "Kick")
    card(d, 20, 690, 350, 60, PALE_TEAL, None)
    txt(d, (40, 707), "Host may remove members even after the shared\nmission starts.", DARK_TEAL, F11)
    nav(d, 2)


def screen_lobby(d, im):
    appbar(d, "Shared mission lobby", True)
    card(d, 20, 88, 350, 190, STRAITS, None, 26)
    pill(d, 40, 108, "WAITING", MANGO, INK, 86)
    txt(d, (40, 154), "Cipher of the Valley\nEscarpment", WHITE, F22B if 'F22B' in globals() else F20B)
    txt(d, (40, 216), "The same hidden route, clue, additional hint\nand progress are synchronised.", "#CDECF7", F11)
    txt(d, (24, 318), "Your travel crew", INK, F18B)
    member(d, 352, "N", "Nur Traveller", "Host", "Ready", HIBISCUS)
    member(d, 440, "J", "Jessica", "Guest", "Waiting", TEAL, "Kick")
    card(d, 20, 540, 350, 86, PALE_TEAL, None)
    txt(d, (40, 558), "Shared rules", DARK_TEAL, F14)
    txt(d, (40, 585), "Hint usage is shared. Host controls start, pause\nand abandon; every member confirms diary reflection.", INK, F10)
    button(d, 20, 652, 168, "Mark ready", WHITE, INK, OUTLINE)
    button(d, 202, 652, 168, "Start", TEAL)
    nav(d, 2)


def screen_profile(d, im):
    appbar(d, "Profile", False, "Edit")
    d.ellipse((145, 92, 245, 192), fill=PALE_HIBISCUS)
    flower(d, 195, 142, 22)
    txt(d, (195, 218), "Nur Traveller", INK, F20B, "mm")
    txt(d, (195, 246), "Malaysia mystery explorer", MUTED, F12, "mm")
    txt(d, (24, 290), "Profile information", INK, F18B)
    field(d, 24, 326, 342, "Display name", "Nur Traveller")
    field(d, 24, 414, 342, "Email", "nur@example.com", True)
    txt(d, (24, 500), "The email cannot be edited.", HIBISCUS, F10)
    field(d, 24, 526, 342, "Bio", "I love local culture and quiet places.")
    button(d, 24, 632, 342, "Save profile")
    txt(d, (195, 704), "No duplicate username or email summary below", MUTED, F10, "mm")
    nav(d, 4)


def screen_notifications(d, im):
    appbar(d, "Notifications", True, "Mark all read")
    card(d, 20, 90, 350, 128, PALE_TEAL, None)
    d.ellipse((38, 108, 78, 148), fill=TEAL)
    txt(d, (58, 128), "✓", WHITE, F15B, "mm")
    txt(d, (94, 108), "Mission invitation accepted", INK, F14)
    txt(d, (94, 138), "Jessica joined Cipher of the Valley.", MUTED, F11)
    txt(d, (94, 172), "2 min ago", DARK_TEAL, F10)
    txt(d, (24, 254), "Notification details", INK, F18B)
    card(d, 20, 286, 350, 262, WHITE, OUTLINE, 24)
    pill(d, 42, 308, "COLLABORATIVE TRAVEL", PURPLE, WHITE, 158)
    txt(d, (42, 354), "Jessica is ready to explore", INK, F20B)
    txt(d, (42, 402), wrap("Your registered travel partner accepted the in-app invitation. Open the shared lobby to review the crew and start when everyone is ready.", 47), MUTED, F12)
    button(d, 42, 476, 306, "Open shared mission", TEAL)
    card(d, 20, 572, 350, 86, PALE_MANGO, None)
    txt(d, (40, 590), "Clean, readable detail screen", INK, F14)
    txt(d, (40, 618), "No black background or oversized fallback text.", MUTED, F11)
    nav(d, 0)


def screen_map(d, im):
    appbar(d, "Your location", True)
    map_panel(d, 0, 78, 390, 650)
    rr(d, (24, 104, 366, 158), 18, WHITE)
    txt(d, (44, 131), "Location only • destination stays hidden", INK, F13, "lm")
    d.ellipse((165, 345, 225, 405), fill="#B8E4FA")
    d.ellipse((180, 360, 210, 390), fill=SKY)
    d.ellipse((189, 369, 201, 381), fill=WHITE)
    card(d, 20, 644, 350, 94, WHITE, None, 24)
    txt(d, (42, 662), "You're near Kuala Lumpur", INK, F15B)
    txt(d, (42, 692), "No route, destination marker or team locations.\nArrival is checked automatically in the background.", MUTED, F10)
    nav(d, 2)


def screen_loading(d, im):
    txt(d, (195, 90), "Crafting your mystery", INK, F24B, "mm")
    txt(d, (195, 126), "Balancing safety, opening hours and quieter places…", MUTED, F11, "mm")
    for r, c, start in [(76, PALE_MANGO, 0), (58, PALE_TEAL, 120), (40, PALE_HIBISCUS, 240)]:
        d.arc((195-r, 248-r, 195+r, 248+r), start, start+235, fill=c, width=14)
    flower(d, 195, 248, 21)
    txt(d, (195, 356), "Weaving three stops like a batik story", PURPLE, F15B, "mm")
    card(d, 24, 410, 342, 188, PALE_TEAL, None, 24)
    flower(d, 64, 452, 14, TEAL)
    txt(d, (94, 432), "Malaysia knowledge", DARK_TEAL, F15B)
    txt(d, (44, 486), wrap("The hibiscus, or bunga raya, became Malaysia's national flower in 1960. Its five petals are often connected with the five principles of the Rukun Negara.", 46), INK, F13, None, 6)
    pill(d, 89, 622, "Checking real-world opening times", PALE_MANGO, INK, 214)
    txt(d, (195, 695), "Fun cultural loading moments appear across the app", MUTED, F10, "mm")


SCREENS = [
    ("01 — Welcome", screen_welcome),
    ("02 — Sign in", screen_signin),
    ("03 — Create account", screen_register),
    ("04 — Home dashboard", screen_home),
    ("05 — Explore mystery", screen_explore),
    ("06 — Travel constraints", screen_constraints),
    ("07 — Generated missions", screen_generated),
    ("08 — Mission preview", screen_preview),
    ("09 — Mission history", screen_history),
    ("10 — Active mission", screen_active),
    ("11 — Clue & hint", screen_clue),
    ("12 — Arrival guidance", screen_arrival),
    ("13 — Passport & stamps", screen_passport),
    ("14 — AI travel diary", screen_diary),
    ("15 — Travel crew", screen_crew),
    ("16 — Shared mission lobby", screen_lobby),
    ("17 — Profile", screen_profile),
    ("18 — Notifications", screen_notifications),
    ("19 — Location-only map", screen_map),
    ("20 — Malaysia loading", screen_loading),
]


board = Image.new("RGB", (BOARD_W, BOARD_H), "#F4F6F8")
bd = ImageDraw.Draw(board)
bd.rectangle((0, 0, BOARD_W, 152), fill=STRAITS)
txt(bd, (MARGIN_X, 48), "Mystery Malaysia — Current Mobile App UI", WHITE, F34B)
txt(bd, (MARGIN_X, 100), "20-screen tutor demo • Flutter implementation mirrored • bright Malaysian tourism theme", "#CDECF7", F16B)
for i, (label, render) in enumerate(SCREENS):
    row, col = divmod(i, COLS)
    x = MARGIN_X + col * (PHONE_W + GAP_X)
    y = MARGIN_Y + row * (PHONE_H + GAP_Y)
    phone, draw = phone_base(label, i)
    render(draw, phone)
    board.paste(phone, (x, y))
    txt(bd, (x, y - 36), label, INK, F16B)

board.save(OUT, optimize=True)
print(OUT)
print(f"{BOARD_W}x{BOARD_H} {OUT.stat().st_size} bytes")
