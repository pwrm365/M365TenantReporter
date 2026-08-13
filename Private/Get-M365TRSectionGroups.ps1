function Get-M365TRSectionGroups {
    <#
    .SYNOPSIS
    Tematyczne pogrupowanie sekcji wewnątrz każdego rozdziału (komponentu) - zamiast plaskiej,
    alfabetycznej listy kilkunastu sekcji na raz. Sekcje nienależące do żadnej zdefiniowanej
    grupy (np. nowy kolektor, o ktorym zapomniano tu dopisać) trafiają na koniec do grupy
    "Pozostałe ustawienia", więc nic nigdy nie znika z raportu - najwyżej nie jest jeszcze
    ładnie skategoryzowane.
    #>
    [ordered]@{
        EntraID = @(
            @{ Name = 'Tożsamość i uwierzytelnianie'; Sections = @(
                'Polityki Conditional Access', 'Nazwane lokalizacje (Named Locations)',
                'Polityka metod uwierzytelniania', 'Security Defaults',
                'Polityka dostępu między tenantami (Cross-Tenant Access)', 'Ustawienia użytkowników i gości'
            ) }
            @{ Name = 'Administracja i uprawnienia'; Sections = @(
                'Role katalogowe', 'Administratorzy uprzywilejowani i MFA',
                'Uprawnienia PIM (Privileged Identity Management)', 'Jednostki administracyjne',
                'Aplikacje z uprawnieniami wysokiego ryzyka'
            ) }
            @{ Name = 'Organizacja i licencjonowanie'; Sections = @(
                'Organizacja', 'Domeny', 'Licencje', 'Synchronizacja z lokalnym Active Directory'
            ) }
            @{ Name = 'Governance i zgodność'; Sections = @(
                'Zarządzanie uprawnieniami (Entitlement Management)', 'Warunki korzystania (Terms of Use)',
                'Ustawienia grup Microsoft 365'
            ) }
            @{ Name = 'Ocena zabezpieczeń'; Sections = @('Secure Score') }
        )
        Intune = @(
            @{ Name = 'Rejestracja urządzeń'; Sections = @(
                'Konfiguracje rejestracji urządzeń', 'Ograniczenia rejestracji per platforma',
                'Profile Windows Autopilot', 'Filtry przypisań (Assignment Filters)'
            ) }
            @{ Name = 'Konfiguracja i zgodność urządzeń'; Sections = @(
                'Profile konfiguracyjne urządzeń', 'Polityki zgodności', 'Zasady Settings Catalog',
                'Bazowe konfiguracje zabezpieczeń (Security Baselines)', 'Skrypty PowerShell (Device Management Scripts)'
            ) }
            @{ Name = 'Aplikacje'; Sections = @(
                'Aplikacje mobilne', 'Zasady konfiguracji aplikacji (App Configuration)', 'Zasady ochrony aplikacji (App Protection)'
            ) }
            @{ Name = 'Role i administracja'; Sections = @('Role RBAC w Intune') }
        )
        Exchange = @(
            @{ Name = 'Ochrona poczty'; Sections = @(
                'Zasady Anti-Phishing', 'Zasady Anti-Spam (Content Filter)', 'Zasady Anti-Malware',
                'Zasady Safe Links (Defender for Office 365)', 'Zasady Safe Attachments (Defender for Office 365)',
                'Uwierzytelnianie poczty (SPF / DKIM / DMARC)'
            ) }
            @{ Name = 'Przepływ poczty'; Sections = @(
                'Konektory przychodzące (Inbound Connectors)', 'Konektory wychodzące (Outbound Connectors)',
                'Reguły transportu (Transport Rules)'
            ) }
            @{ Name = 'Konfiguracja organizacji'; Sections = @(
                'Konfiguracja organizacji', 'Domeny akceptowane (Accepted Domains)',
                'Zasady urządzeń mobilnych (Mobile Device Mailbox Policies)', 'Zasady udostępniania (Sharing Policies)',
                'Zasady uwierzytelniania (Basic Auth)', 'Rejestrowanie zdarzeń (Unified Audit Log)'
            ) }
        )
        Purview = @(
            @{ Name = 'Etykiety poufności'; Sections = @(
                'Etykiety poufności (Sensitivity Labels)', 'Zasady etykiet poufności (Label Policies)',
                'Ochrona praw do informacji (RMS/IRM)'
            ) }
            @{ Name = 'Zapobieganie utracie danych i retencja'; Sections = @(
                'Zasady DLP (Data Loss Prevention)', 'Zasady retencji', 'Etykiety retencji'
            ) }
        )
    }
}
