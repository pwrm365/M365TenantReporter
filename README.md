# M365TenantReporter

Automatyczna dokumentacja tenanta Microsoft 365 — generuje czytelny raport HTML/PDF opisujący
faktyczną konfigurację tenanta (Entra ID, Intune, Exchange Online, Microsoft Teams,
SharePoint/OneDrive, Purview, Windows 365, Universal Print). Obsługuje wiele tenantów —
przydatne dla firm obsługujących wielu klientów M365.

To jest **dokumentacja konfiguracji**, nie audyt bezpieczeństwa ani skaner podatności — narzędzie
opisuje, jak tenant jest skonfigurowany (jakie polityki, jakie ustawienia, jakie licencje), bez
formułowania rekomendacji czy ocen ryzyka. Celowo nie pobiera pełnych list obiektów (wszystkich
użytkowników, urządzeń, skrzynek) — tylko ustawienia i polityki na poziomie tenanta, plus wąskie
wyjątki tam, gdzie sama lista JEST konfiguracją administracyjną (np. kto ma rolę uprzywilejowaną).

## Wymagania

- **PowerShell 7.x** (`pwsh`)
- Moduły PowerShell (instalowane automatycznie / wymagane przy pierwszym użyciu):
  - `MSAL.PS` — logowanie do Microsoft Graph
  - `ExchangeOnlineManagement` w wersji dokładnie **3.7.2** (nowsze wydania 3.9.x/3.10.x mają
    błędny pakiet — patrz [Znane problemy](#znane-problemy-środowiskowe))
  - `MicrosoftTeams`
- Konto z rolą **Global Administrator** (lub Privileged Role Administrator + Application
  Administrator) w tenancie, który ma być udokumentowany — potrzebne **tylko jednorazowo**, przy
  konfiguracji dostępu (`Setup-AppPermissions.ps1`)
- Microsoft Edge lub Google Chrome (do eksportu HTML → PDF w trybie headless)

## Szybki start

### 1. Jednorazowa konfiguracja dostępu dla nowego tenanta

```powershell
.\Setup-AppPermissions.ps1
```

Poprosi o zalogowanie się (Global Administrator) do tenanta, który ma być dokumentowany. Tworzy
dedykowaną rejestrację aplikacji Azure AD z uprawnieniami tylko-do-odczytu, nadaje zgodę
administratora, generuje certyfikat do uwierzytelniania Exchange Online/Teams i zapisuje
poświadczenia lokalnie (`.credentials\`, kluczowane po TenantId). Można uruchomić wielokrotnie —
dla każdego kolejnego klienta osobno, bez utraty poprzednich konfiguracji.

### 2. Generowanie raportu

```powershell
.\Start-Report.ps1
```

Jeśli skonfigurowano więcej niż jednego klienta, pojawi się menu wyboru tenanta. Raport
(`{Tenant}_M365Report_{data}.html` i `.pdf`) trafia do `Output\`.

Automatyzacja / CI (bez interakcji, konkretny tenant):

```powershell
.\Start-Report.ps1 -TenantId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -NonInteractive
```

## Co zbiera

| Obszar | Przykładowe sekcje |
|---|---|
| **Entra ID** | Conditional Access, Security Defaults, nazwane lokalizacje, role uprzywilejowane + MFA, licencje, Secure Score, synchronizacja z lokalnym AD, aplikacje z uprawnieniami wysokiego ryzyka |
| **Intune** | Profile konfiguracyjne, zgodność, rejestracja urządzeń per platforma, Autopilot, aplikacje mobilne |
| **Exchange Online** | Anti-phishing/spam/malware, Safe Links/Safe Attachments (Defender for Office 365), SPF/DKIM/DMARC, reguły transportu, zasady uwierzytelniania (Basic Auth), audyt |
| **Microsoft Teams** | Zasady spotkań/wiadomości, federacja z innymi organizacjami, dostęp zewnętrzny |
| **SharePoint/OneDrive** | Ustawienia udostępniania na poziomie tenanta |
| **Purview** | Etykiety poufności (w tym domyślna etykieta), DLP, retencja, ochrona RMS/IRM |
| **Windows 365 / Universal Print** | Jeśli wykupione/skonfigurowane w tenancie |

Sekcje, których nie udało się zebrać (brak licencji/uprawnień), trafiają do załącznika na końcu
raportu zamiast zaśmiecać główną treść — a całe działy bez żadnych danych (np. Windows 365 w
tenancie bez tej licencji) są pomijane w treści głównej.

## Architektura (skrót)

- `Collectors\*.ps1` — jeden plik = jeden kolektor. Konwencja nazw plików `Komponent.Sekcja.ps1`
  mapuje się automatycznie na funkcję `Get-Collector_Komponent_Sekcja` — dodanie nowego kolektora
  to tylko dodanie pliku, bez rejestrowania go gdziekolwiek indziej.
- Kolektory Graph działają w głównym procesie (`Invoke-M365TRCollection.ps1`).
- Kolektory Exchange/Purview i Teams działają w **osobnych, izolowanych procesach**
  (`Collect-Exchange.ps1`, `Collect-Teams.ps1`) — patrz niżej, dlaczego.
- `Report\Templates\` — szablon HTML (`report-template.html`, tokeny `{{...}}`) + arkusz stylów
  (`report.css.txt`), oddzielone od logiki generatora (`New-M365TRHtmlReport.ps1`).

## Znane problemy środowiskowe

- **`ExchangeOnlineManagement` 3.9.x/3.10.x** mają błędnie zapakowany `Microsoft.Identity.Client.dll`,
  który koliduje z wersją oczekiwaną przez `MSAL.PS` w tym samym procesie (`FileLoadException`).
  Wersja **3.7.2** działa poprawnie — dlatego kolektory Exchange/Purview/Teams uruchamiane są w
  osobnych procesach potomnych, każdy ze swoim, niezależnym zestawem załadowanych modułów.
- Certyfikat do uwierzytelniania app-only jest współdzielony między Exchange Online i Microsoft
  Teams PowerShell (ten sam plik, dwa różne API) — nie trzeba generować dwóch osobnych.

## Bezpieczeństwo

- Poświadczenia (`.credentials\`) i wygenerowane raporty (`Output\`) **nigdy nie są commitowane**
  (patrz `.gitignore`) — zawierają realne dane konfiguracyjne klientów.
- Certyfikat aplikacji przechowywany jest w lokalnym magazynie certyfikatów Windows
  (`Cert:\CurrentUser\My`), nie w plikach na dysku.
- Aplikacja Azure AD tworzona przez `Setup-AppPermissions.ps1` ma **wyłącznie uprawnienia
  do odczytu** (`*.Read.All`) — narzędzie niczego w tenancie nie zmienia.
- Wygenerowane raporty zawierają wrażliwe informacje o konfiguracji i stanie zabezpieczeń klienta
  — traktuj je jak każdy inny dokument poufny.

## Licencja

MIT — zobacz [LICENSE](LICENSE).
