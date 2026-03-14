# 🎯 Filament Tracker

> Dein persönlicher 3D-Druck-Filament-Begleiter für Android & Windows

Hey! Ich bin PandaApez und das ist meine Filament-Verwaltung die ich für meine 3D-Druck-Projekte gebaut habe. Die App hilft mir den Überblick über meine gesamte Filament-Sammlung zu behalten - vom Restgewicht bis hin zu Labels zum Ausdrucken.

## ✨ Was die App kann

### 📦 Inventar-Verwaltung
- Filamente nach Marke, Typ und Farbe organisieren
- Restgewicht automatisch tracken
- Verbrauch protokollieren
- Niedrig-Bestand wird farblich hervorgehoben

### 🏷️ Label Creator
- QR-Code Labels für jede Filament-Spule generieren
- Als PNG exportieren zum Ausdrucken
- Perfekt für's Bastel-Regal oder die Werkstatt
- Stapel-Druck: Mehrere Labels auf einmal

### 📷 QR-Scanner
- Filamente schnell per QR-Code scannen
- Direkt zur Filament-Detailansicht
- Verbrauch sofort eintragen

### 🖨️ LEGO Creator
- STL-Dateien für LEGO-kompatible Steine generieren
- 3D-druckbar für echte LEGO-Projekte

### 📊 Statistiken
- Verbrauch im Überblick
- Welche Farbe/Type wird am meisten genutzt?
- Gesamtwert der Sammlung

### 🔄 Klipper Integration
- Direkt mit Klipper (Moonraker API) verbinden
- Drucker-Status sehen
- Temperaturen im Blick

### 📱 Android Widget
- Home-Screen Widget mit Bestand
- Schneller Überblick ohne App öffnen

### 🔔 Auto-Update
- GitHub Releases werden automatisch erkannt
- Update per Download-Link installieren

### 💾 Cloud-Sync
- Supabase Backend für sichere Datenspeicherung
- Von überall Zugriff auf deine Daten
- "Angemeldet bleiben" für schnellen Login

## 🛠️ Tech Stack

- **Flutter** - Cross-Platform (Android + Windows)
- **Supabase** - Auth & Datenbank
- **Dark Mode UI** - Modern mit Cyan-Akzent
- **QR-Code System** - Eigene Labels scannen

## 📱 Download

Die neueste APK findest du unter [Releases](https://github.com/DerMaXiM123/filament-tracker/releases)

## 🚀 Für Entwickler

```bash
# Projekt klonen
git clone https://github.com/DerMaXiM123/filament-tracker.git

# Abhängigkeiten installieren
cd filament_tracker
flutter pub get

# Android APK bauen
flutter build apk --debug

# Windows EXE bauen
flutter build windows --release
```

## 📝 Supabase einrichten

1. Neues Supabase Projekt erstellen
2. Diese Tabellen anlegen:

```sql
-- Filamente Tabelle
create table filamente (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null,
  marke text not null,
  typ text not null,
  farbe text not null,
  gewicht_gramm int not null,
  restgewicht_gramm int not null,
  preis double precision not null,
  gekauft_am timestamp with time zone default now()
);

-- Verbrauch Tabelle  
create table verbrauch (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users not null,
  filament_id uuid references filamente(id) not null,
  verbraucht_gramm int not null,
  timestamp timestamp with time zone default now()
);
```

## 🤝 Mitmachen

Falls du Ideen hast oder Bugs findest - her damit! 
Pull Requests sind willkommen.

## 📄 Lizenz

MIT License -自由的!

---

Made with ❤️ by PandaApez for the 3D-Printing Community
