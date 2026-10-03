# Google Play store graphics

The finished graphics live in [`store/play/`](../../store/play):

| File | Size | Play Console field |
|---|---|---|
| `screenshots/1-subscriptions.png` … `6-backup.png` | 1080 × 1920 | Phone screenshots, in this order |
| `feature-graphic.png` | 1024 × 500 | Feature graphic |
| `icon-512.png` | 512 × 512 | App icon |

All the data in the screenshots is fictional: Streamly, Tunebox, Nova Bank and so on. No real brand appears in the listing.

## Regenerate after UI changes

1. **Load the sample data on a phone.** Create the file:

   ```bash
   python tool/store_graphics/sample_backup.py one-spend-store-sample.json
   ```

   Copy it to the phone's Downloads. In the app, go to Settings › Backup & data › Restore from backup and choose **Replace everything**. Use a debug build, so nothing is sent to Firebase.
2. **Capture the six screens** at full resolution with `adb exec-out screencap -p > file.png`:
   - the Subscriptions tab (top);
   - the Upcoming tab (top);
   - Analytics, scrolled to the yearly-cost hero;
   - Analytics, scrolled to "By category";
   - Streamly's detail page, at "Spend & Billing";
   - Backup & data.

   Save them over the files in `captures/` with the same names.
3. **Clean and render:**

   ```bash
   python tool/store_graphics/clean_captures.py
   ```

   This paints out Samsung's Edge panel handle. Then render:

   ```bash
   powershell -ExecutionPolicy Bypass -File tool/store_graphics/render.ps1
   ```

   This needs Chrome or Edge, plus Python with Pillow.

## How it's built

- **`template.html`**: one slide per URL hash (`#1`–`#6`, `#feature`). Headline copy, accent colours, phone position (`top`) and capture offset (`shift`) are set in the `slides` table at the bottom.
- **`render.ps1`**: screenshots each slide with headless Chrome at exact pixel sizes.
- **`finish.py`**: flattens the images to opaque PNGs, which Play requires for the feature graphic, checks their sizes, and writes the 512 px icon.
- **The status bar is drawn**, always showing 9:41 with full battery and signal. The captured one is covered rather than changing the phone's demo mode.
