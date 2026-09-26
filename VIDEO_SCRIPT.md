# Video Script

## Third-Party API demo — Inventory Value Abroad (≈15 seconds)

| Time | On screen | Say |
|---|---|---|
| 0:00–0:04 | Dashboard, scroll to the **Inventory Value Abroad** card. | "This card uses a third-party API, ExchangeRate-API. It fetches live exchange rates for the Philippine Peso." |
| 0:04–0:08 | Point at the ₱ total and the USD, JPY and SGD lines. | "It takes our total inventory value and converts it to US dollars, yen and Singapore dollars, showing the rate used for each." |
| 0:08–0:12 | Tap **Refresh**. The small spinner appears inside the card, then the data returns. | "When I tap Refresh, the app sends a new GET request to the API." |
| 0:12–0:15 | Point at **Rates updated** and **Last checked**. | "'Rates updated' is the timestamp from the API's JSON, and 'Last checked' just changed to the current time, so the data is live, not hard-coded." |

Tip: ExchangeRate-API refreshes its rates about once a day, so **Rates updated** normally stays the same between
taps. **Last checked** is the value that changes on every Refresh.
