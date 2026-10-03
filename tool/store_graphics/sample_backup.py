"""Writes a One Spend backup file full of fictional subscriptions for store screenshots.

Every service, bank and card here is made up, so no real brand appears in the Play
listing. Dates are relative to today, so the data always looks current.

Usage:  python tool/store_graphics/sample_backup.py  [output.json]
Then restore it in the app: Settings > Backup & data > Restore from backup > Replace everything.
"""

import json
import sys
from datetime import date, datetime, timedelta

TODAY = date.today()


def at_nine(d: date) -> str:
    return datetime(d.year, d.month, d.day, 9).isoformat()


def months_back(d: date, n: int) -> date:
    """The same day n months earlier, clamped to the month's length."""
    y, m = divmod(d.year * 12 + (d.month - 1) - n, 12)
    m += 1
    for day in (d.day, 30, 29, 28):
        try:
            return date(y, m, day)
        except ValueError:
            continue
    raise ValueError(d)


# Material icon code points from the app's icon set (supportedSubscriptionIcons).
ICON = {
    "movie": 0xF8E7, "music": 0xF8ED, "cloud": 0xF650, "ai": 0xF596, "palette": 0xF0041,
    "code": 0xF653, "games": 0xF01BC, "fitness": 0xF767, "news": 0xF0358, "email": 0xF705,
    "school": 0xF012E, "shield": 0xF016B,
}

CARDS = [
    {"id": "card_nova", "nickname": "Nova Bank", "type": "creditCard", "brand": "visa", "last4": "4821",
     "expiryDate": f"08/{(TODAY.year + 3) % 100:02d}", "cardColor": 0xFF2E3A8C, "isDefault": True, "statementDay": 5},
    {"id": "card_orbit", "nickname": "Orbit", "type": "debitCard", "brand": "mastercard", "last4": "1937",
     "expiryDate": f"03/{(TODAY.year + 2) % 100:02d}", "cardColor": 0xFF1F1F24, "isDefault": False, "statementDay": 20},
]

# name, description, price (USD), cycle, category, colour, icon, days until next charge, card, extras
SERVICES = [
    ("Streamly", "4K plan, 4 screens", 15.99, "monthly", "entertainment", 0xFFE5484D, "movie", 2, "card_nova",
     {"annualPlanPrice": 159.0, "notes": "Family account", "accountUrl": "https://streamly.example/account"}),
    ("Tunebox", "Premium Duo", 11.99, "monthly", "music", 0xFF1DB97A, "music", 3, "card_orbit", {}),
    ("CloudVault", "2 TB storage", 9.99, "monthly", "cloud", 0xFF3B82F6, "cloud", 9, "card_nova",
     {"annualPlanPrice": 99.99}),
    ("Lumen AI", "Pro assistant", 20.00, "monthly", "productivity", 0xFF8B5CF6, "ai", 6, "card_nova", {}),
    ("Pixelcraft Studio", "Design suite", 12.99, "monthly", "design", 0xFFF97316, "palette", 14, "card_orbit", {}),
    ("Codeforge", "Dev tools, Team", 10.00, "monthly", "developer", 0xFF64748B, "code", 18, "card_nova", {}),
    ("PlayArc", "Game pass", 8.99, "monthly", "gaming", 0xFF22C55E, "games", 11, "card_orbit", {}),
    ("FitPulse", "Coaching + plans", 7.99, "monthly", "health", 0xFFEC4899, "fitness", 21, "card_orbit", {}),
    ("Newsline", "Digital edition", 4.99, "monthly", "utilities", 0xFFEAB308, "news", 25, "card_nova", {}),
    ("Mailbox Pro", "Private email", 39.00, "yearly", "productivity", 0xFF0EA5E9, "email", 47, "card_nova", {}),
    ("Learnly", "Courses, paused for summer", 12.00, "monthly", "utilities", 0xFF14B8A6, "school", 19, "card_orbit",
     {"status": "paused"}),
]


def subscription(i, name, desc, price, cycle, category, color, icon, days, card, extra):
    next_date = TODAY + timedelta(days=days)
    if cycle == "monthly":
        history = [at_nine(months_back(next_date, n)) for n in range(1, 13)]
    else:  # yearly
        history = [at_nine(months_back(next_date, 12))]
    sub = {
        "id": f"sample_{i:02d}",
        "name": name,
        "description": desc,
        "price": price,
        "currency": "USD",
        "billingCycle": cycle,
        "category": category,
        "brandColor": color,
        "iconCodePoint": ICON[icon],
        "iconFontFamily": "MaterialIcons",
        "nextBillingDate": at_nine(next_date),
        "status": extra.get("status", "active"),
        "paymentMethod": "",
        "paymentMethodId": card,
        "reminderDays": 2,
        "isPopular": False,
        "notes": extra.get("notes", ""),
        "paymentHistory": [h for h in history if h < at_nine(TODAY)],
        "accountUrl": extra.get("accountUrl", ""),
        "logoUrl": None,
        "brandPresetId": None,
        "autoRenew": True,
        "anchorDay": next_date.day,
        "reminderTimeMinutes": None,
        "logoTransform": None,
        "annualPlanPrice": extra.get("annualPlanPrice"),
    }
    return sub


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "one-spend-store-sample.json"
    subs = [subscription(i, *s) for i, s in enumerate(SERVICES, start=1)]
    backup = {
        "format": "onespend.backup",
        "version": 2,
        "createdAt": datetime.now().isoformat(),
        "appVersion": "1.0.0-alpha.1 (1)",
        "counts": {"subscriptions": len(subs), "paymentMethods": len(CARDS)},
        "data": {
            "subscriptions": subs,
            "paymentMethods": CARDS,
            "settings": {
                "monthlyBudget": 150.0,
                "currency": "USD",
                "defaultReminderDays": 2,
                "defaultReminderTimeMinutes": 9 * 60,
                "notificationsEnabled": True,
                "sortOption": "renewalAsc",
                "groupByDate": False,
            },
            "appearance": {},
            "customCategories": [],
        },
    }
    with open(out, "w", encoding="utf-8") as f:
        json.dump(backup, f, indent=2)
    monthly = sum(p if c == "monthly" else p / 12 for _, _, p, c, *_r, e in SERVICES if e.get("status") != "paused")
    print(f"Wrote {out}: {len(subs)} subscriptions, about ${monthly:.2f}/month")


if __name__ == "__main__":
    main()
