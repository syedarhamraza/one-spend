# Google Play store graphics

The finished graphics live in [`store/play/`](../../store/play):

| File | Size | Play Console field |
|---|---|---|
| `screenshots/1-subscriptions.png` … `8-backup.png` | 1080 × 1920 | Phone screenshots, in this order |
| `feature-graphic.png` | 1024 × 500 | Feature graphic |
| `icon-512.png` | 512 × 512 | App icon |

All the data in the screenshots is fictional: Streamly, Tunebox, Nova Bank and so on. No real brand appears in the listing.

## Regenerate after UI changes

1. **Load the sample data on a phone.** Create the file:

   ```bash
   python tool/store_graphics/sample_backup.py one-spend-store-sample.json
   ```

   Copy it to the phone's Downloads. In the app, go to Settings › Backup & data › Restore from backup and choose **Replace everything**. Use a debug build, so nothing is sent to Firebase.
2. **Capture the eight screens**, full screen, unscrolled unless noted. The current set was taken on a vivo X200 Pro at 1260 × 2800, and the frame expects that shape.
   1. the Subscriptions tab (also used for the feature graphic);
   2. the Upcoming tab;
   3. the Analytics tab;
   4. Analytics, scrolled to "By category";
   5. a subscription's detail page;
   6. a subscription's notification time;
   7. Settings › Main currency;
   8. Backup & data.

   Save them as PNGs in `captures/` under the names in `render.ps1` (`1-subscriptions.png` … `8-backup.png`).
3. **Clean and render:**

   ```bash
   python tool/store_graphics/clean_captures.py
   ```

   This paints out Samsung's Edge panel handle; it only acts on 1080 × 2340 Samsung captures. Then render:

   ```bash
   powershell -ExecutionPolicy Bypass -File tool/store_graphics/render.ps1
   ```

   This needs Chrome or Edge, plus Python with Pillow.

## How it's built

- **`template.html`**: one slide per URL hash (`#1`–`#6`, `#feature`). Headline copy, accent colours, phone position (`top`) and capture offset (`shift`) are set in the `slides` table at the bottom.
- **Two layouts:**
  - **Full phone** (`#1-full`, the default in `render.ps1`): the whole phone under a short one-line headline (`short` / `shortSub`).
  - **Close-up** (`#1`): a bigger phone running off the bottom, with a two-line headline (`title` / `sub`).
  - To switch, set `$layout` in `render.ps1`.
- **`render.ps1`**: screenshots each slide with headless Chrome at exact pixel sizes.
- **`finish.py`**: flattens the images to opaque PNGs, which Play requires for the feature graphic, checks their sizes, and writes the 512 px icon.
- **The status bar is drawn**, always showing 9:41 with full battery and signal. The captured one is covered rather than changing the phone's demo mode.
