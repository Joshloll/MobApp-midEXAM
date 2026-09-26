# Deploying with DuckDNS (XAMPP on your own PC)

DuckDNS gives you a free name like `mydrygoods.duckdns.org` that always points at your home internet
connection. Your PC stays the server: XAMPP serves the PHP API and the Flutter web app, and anyone can reach
them at:

- Web app: `https://mydrygoods.duckdns.org/MobApp-midEXAM/app/`
- API: `https://mydrygoods.duckdns.org/MobApp-midEXAM/backend/api/dry_goods.php`

Replace `mydrygoods` with your own subdomain everywhere below.

> **The PC must be on for the site to work.** If it sleeps, shuts down, or XAMPP is stopped, the site is down.

---

## Step 0 — Check your internet can accept incoming connections (CGNAT)

Many home ISPs share one public IP between customers (called **CGNAT**). If yours does, port forwarding
cannot work and DuckDNS alone will not be enough.

1. Open your router's admin page (usually `http://192.168.1.1` or `http://192.168.0.1`) and find the
   **WAN IP** / **Internet IP**.
2. Open <https://www.whatismyip.com> and compare.

| Result | Meaning |
|---|---|
| Both IPs are the same | ✅ You have a public IP. Continue. |
| The WAN IP starts with `100.64`–`100.127`, `10.`, or `192.168.`, or is different | ❌ CGNAT. Ask your ISP for a **public IP** (sometimes a paid add-on), or use a tunnel instead (see the end of this guide). |

---

## Step 1 — Create the DuckDNS subdomain

1. Go to <https://www.duckdns.org> and sign in (Google/GitHub/etc.).
2. Type a subdomain name and click **add domain**. It fills in your current public IP automatically.
3. Copy your **token** from the top of the page. Keep it private, because anyone with it can change your domain.

## Step 2 — Keep the IP up to date automatically

Home IPs change. Make Windows tell DuckDNS your IP every 5 minutes.

Open **PowerShell as Administrator** and run (put in your subdomain and token):

```powershell
$domain = "mydrygoods"
$token  = "YOUR-DUCKDNS-TOKEN"
$action  = New-ScheduledTaskAction -Execute "curl.exe" -Argument "-s `"https://www.duckdns.org/update?domains=$domain&token=$token&ip=`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)
Register-ScheduledTask -TaskName "DuckDNS Update" -Action $action -Trigger $trigger -User "SYSTEM" -RunLevel Highest
```

Test it once by hand; it must print `OK`:

```powershell
curl.exe "https://www.duckdns.org/update?domains=mydrygoods&token=YOUR-DUCKDNS-TOKEN&ip="
```

## Step 3 — Give your PC a fixed local IP

1. Run `ipconfig` and note your **IPv4 Address** (e.g. `192.168.1.25`).
2. In the router, find **DHCP reservation** / **Static lease / Address reservation** and reserve that IP for
   your PC, so port forwarding doesn't break after a restart.

## Step 4 — Forward ports on the router

In the router's **Port Forwarding** / **Virtual Server** / **NAT** page, add:

| Name | External port | Internal IP | Internal port | Protocol |
|---|---|---|---|---|
| HTTP | 80 | 192.168.1.25 | 80 | TCP |
| HTTPS | 443 | 192.168.1.25 | 443 | TCP |

**Do not** forward 3306 (MySQL). The app never needs it from outside.

## Step 5 — Allow Apache through Windows Firewall

PowerShell as Administrator:

```powershell
New-NetFirewallRule -DisplayName "Apache HTTP/HTTPS" -Direction Inbound -Protocol TCP -LocalPort 80,443 -Action Allow
```

## Step 6 — Test from outside your network

Turn **Wi-Fi off on your phone** (use mobile data) and open:

`http://mydrygoods.duckdns.org/MobApp-midEXAM/backend/api/dry_goods.php`

You should see the product JSON. If it doesn't load:
- Check that Apache is running in XAMPP.
- Check that `curl.exe` from Step 2 prints `OK`.
- Re-check the port forward IP.
- Some ISPs block incoming port 80. In that case, skip ahead and use HTTPS (Step 7) with DNS validation.

Testing from inside your own Wi-Fi may fail even when everything is correct (many routers don't support
"NAT loopback"), so always test with mobile data.

## Step 7 — Add HTTPS (free Let's Encrypt certificate)

HTTPS is needed so browsers don't show "Not secure" and so the web app can call the API.

Use **win-acme** (free Let's Encrypt client for Windows):

1. Download it from <https://www.win-acme.com> and unzip to `C:\win-acme`.
2. Run `wacs.exe` as Administrator and choose the options to create a certificate with **full options**:
   - **Domain:** enter `mydrygoods.duckdns.org` manually.
   - **Validation:** HTTP validation that saves files to a local path, with path `C:\xampp\htdocs`. Port 80
     must be forwarded for this to work.
   - **Store:** PEM-encoded files, saved to `C:\xampp\apache\conf\ssl`.
   - **Installation:** no additional steps.
3. win-acme creates a scheduled task that renews the certificate automatically.

Now point Apache at the certificate. Open `C:\xampp\apache\conf\extra\httpd-ssl.conf` and inside
`<VirtualHost _default_:443>` set (file names match what win-acme created in that folder):

```apache
ServerName mydrygoods.duckdns.org:443
SSLCertificateFile    "conf/ssl/mydrygoods.duckdns.org-crt.pem"
SSLCertificateKeyFile "conf/ssl/mydrygoods.duckdns.org-key.pem"
SSLCertificateChainFile "conf/ssl/mydrygoods.duckdns.org-chain.pem"
```

Comment out the old `SSLCertificateFile "conf/ssl.crt/server.crt"` and
`SSLCertificateKeyFile "conf/ssl.key/server.key"` lines, then restart Apache in XAMPP.

Test (mobile data): `https://mydrygoods.duckdns.org/MobApp-midEXAM/backend/api/dry_goods.php`

## Step 8 — Publish the web app

From the project folder:

```powershell
flutter build web --release --base-href /MobApp-midEXAM/app/
Remove-Item -Recurse -Force C:\xampp\htdocs\MobApp-midEXAM\app -ErrorAction SilentlyContinue
Copy-Item -Recurse build\web C:\xampp\htdocs\MobApp-midEXAM\app
```

Open `https://mydrygoods.duckdns.org/MobApp-midEXAM/app/`. The web app automatically calls the API on the same
domain, so no settings change is needed.

Re-run these three commands every time you change the Flutter code.

## Step 9 — Build the Android app for the public server

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://mydrygoods.duckdns.org/MobApp-midEXAM/backend/api
```

The APK is at `build\app\outputs\flutter-apk\app-release.apk`. Installed copies of the app can also be switched
at any time from **Server settings** (gear icon) → paste the URL above → **Test connection** → **Save**.

---

## Security checklist (read before sharing the link)

Once the site is public, anyone on the internet can reach it.

- [x] **Source files are hidden.** The `.htaccess` in the project root returns 404 for `.git`, `lib/`,
      `database/`, `backend/config/`, etc. Only `backend/api/` and `app/` are public. Make sure `.htaccess` and
      `backend/config/.htaccess` exist in `C:\xampp\htdocs\MobApp-midEXAM`.
- [x] **phpMyAdmin is local-only.** XAMPP's default `Require local` blocks it from outside. Don't change that.
- [ ] **Set a MySQL root password** (phpMyAdmin → User accounts → root → Change password), then update
      `backend/config/db.local.php` and `C:\xampp\phpMyAdmin\config.inc.php` to match.
- [ ] **The API has no login.** Anyone who knows the URL can add, edit or delete products. That's fine for a
      short demo, but don't leave it online permanently without adding authentication.
- [ ] Turn the site off (stop Apache or remove the port forwards) when you don't need it.

## If you're behind CGNAT (Step 0 failed)

Port forwarding cannot work behind CGNAT. Options:
- Ask your ISP for a public/static IP.
- Use a tunnel that makes an outgoing connection instead, such as **Cloudflare Tunnel** (needs a domain you
  own), **ngrok**, or **Tailscale Funnel**. These give you a public HTTPS URL without router changes; DuckDNS
  isn't needed in that case. Use that URL in place of `mydrygoods.duckdns.org` in Steps 8–9.
