function Get-M365TRUiStrings {
    <#
    .SYNOPSIS
    Fixed report-chrome text (cover, dashboard, table of contents, status badges, appendix) in
    Polish and English. This covers the report "shell" - the labels/section titles/values that
    individual collectors put INTO their data tables are translated separately (see
    ConvertTo-M365TRLocalizedLabel), since there are ~90 collector files and touching every one
    of them for two full sentence sets is a much larger, incremental effort.
    #>
    [CmdletBinding()]
    param([ValidateSet('pl', 'en')][string]$Language = 'pl')

    $strings = @{
        pl = @{
            HtmlLang           = 'pl'
            DocTitlePrefix     = 'Dokumentacja środowiska Microsoft 365'
            TechDocLabel       = 'Dokumentacja techniczna'
            CoverSubtitle      = 'Zapis konfiguracji tenanta: tożsamość, urządzenia, usługi produktywności i ochrona informacji.'
            CoverNote          = 'Dokument przedstawia stan konfiguracji odczytany z Microsoft Graph oraz interfejsów administracyjnych Microsoft 365 w dniu generowania. Sekcje, których nie udało się odczytać z powodu brakujących uprawnień lub licencji, wymieniono w załączniku.'
            NoDataFallback     = 'brak danych'
            FactTenantId       = 'Identyfikator tenanta'
            FactPrimaryDomain  = 'Domena podstawowa'
            FactCountry        = 'Kraj'
            FactDomainCount    = 'Liczba domen'
            FactCollected      = 'Zebrane sekcje'
            FactGeneratedAt    = 'Data wygenerowania'
            SummaryTitle       = 'Podsumowanie'
            TocTitle           = 'Spis treści'
            TocAppendixLink    = 'Załącznik: niezebrane dane'
            AppendixTitle      = 'Załącznik: niezebrane dane'
            AppendixKicker     = 'ZAŁĄCZNIK'
            AppendixDesc       = 'Sekcje pominięte z powodu brakujących uprawnień/licencji lub błędu połączenia z Microsoft Graph.'
            AppendixAllOk      = 'Wszystkie sekcje zostały zebrane pomyślnie.'
            AppendixColComponent = 'Komponent'
            AppendixColSection   = 'Sekcja'
            AppendixColStatus    = 'Status'
            AppendixColReason    = 'Powód'
            NoDataInTenant     = 'Brak danych w tym tenancie.'
            TileCollected      = 'Zebrane sekcje'
            TileSkipped        = 'Pominięte (uprawnienia/licencja)'
            TileErrors         = 'Błędy'
            HeadlineCa         = 'Polityki Conditional Access'
            HeadlineCompliance = 'Polityki zgodności Intune'
            HeadlineApps       = 'Aplikacje mobilne'
            HeadlineDomains    = 'Domeny'
            DonutTitle         = 'Status zbierania danych'
            BreakdownPrefix    = 'Rozkład wg'
            FooterLeftPrefix   = 'Dokumentacja Microsoft 365'
            FooterRightPrefix  = 'Wygenerowano automatycznie przez M365TenantReporter'
            StatusOk           = 'OK'
            StatusEmpty        = 'Brak danych'
            StatusSkippedPerm  = 'Pominięto - brak uprawnień'
            StatusSkippedLic   = 'Pominięto - brak licencji'
            StatusError        = 'Błąd'
            OtherSettingsGroup = 'Pozostałe ustawienia'
        }
        en = @{
            HtmlLang           = 'en'
            DocTitlePrefix     = 'Microsoft 365 Environment Documentation'
            TechDocLabel       = 'Technical documentation'
            CoverSubtitle      = 'A record of the tenant configuration: identity, devices, productivity services and information protection.'
            CoverNote          = 'This document reflects the configuration state read from Microsoft Graph and the Microsoft 365 admin interfaces on the day it was generated. Sections that could not be read because of missing permissions or licensing are listed in the appendix.'
            NoDataFallback     = 'no data'
            FactTenantId       = 'Tenant ID'
            FactPrimaryDomain  = 'Primary domain'
            FactCountry        = 'Country'
            FactDomainCount    = 'Number of domains'
            FactCollected      = 'Collected sections'
            FactGeneratedAt    = 'Generated on'
            SummaryTitle       = 'Summary'
            TocTitle           = 'Table of contents'
            TocAppendixLink    = 'Appendix: uncollected data'
            AppendixTitle      = 'Appendix: uncollected data'
            AppendixKicker     = 'APPENDIX'
            AppendixDesc       = 'Sections skipped because of missing permissions/licensing, or a Microsoft Graph connection error.'
            AppendixAllOk      = 'All sections were collected successfully.'
            AppendixColComponent = 'Component'
            AppendixColSection   = 'Section'
            AppendixColStatus    = 'Status'
            AppendixColReason    = 'Reason'
            NoDataInTenant     = 'No data in this tenant.'
            TileCollected      = 'Collected sections'
            TileSkipped        = 'Skipped (permissions/license)'
            TileErrors         = 'Errors'
            HeadlineCa         = 'Conditional Access policies'
            HeadlineCompliance = 'Intune compliance policies'
            HeadlineApps       = 'Mobile apps'
            HeadlineDomains    = 'Domains'
            DonutTitle         = 'Data collection status'
            BreakdownPrefix    = 'Breakdown by'
            FooterLeftPrefix   = 'Microsoft 365 Documentation'
            FooterRightPrefix  = 'Automatically generated by M365TenantReporter'
            StatusOk           = 'OK'
            StatusEmpty        = 'No data'
            StatusSkippedPerm  = 'Skipped - insufficient permissions'
            StatusSkippedLic   = 'Skipped - missing license'
            StatusError        = 'Error'
            OtherSettingsGroup = 'Other settings'
        }
    }

    return $strings[$Language]
}
