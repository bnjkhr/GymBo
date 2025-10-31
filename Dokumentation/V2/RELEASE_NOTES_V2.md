# GymBo Version 2.0 - Release Notes

## 🎉 Hauptfeatures

### Neu in Version 2

**Training Management**
- ✅ **Superset & Circuit Training** - Trainiere in Supersätzen (2 Übungen) oder Zirkeln (3+ Übungen) mit automatischer Runden-Verwaltung
- ✅ **Aufwärmsätze** - Automatische Berechnung von Warmup-Sets mit 3 Strategien (Standard, Konservativ, Minimal)
- ✅ **Quick-Setup Workout-Erstellung** - KI-basierter 3-Schritt-Wizard für schnelle Workout-Generierung (perfekt für Hotels/fremde Gyms)
- ✅ **Übungen tauschen** - Übungen während des Workouts einfach austauschen (permanent oder temporär)
- ✅ **Workout-Ordner** - Organisiere deine Workouts in farbigen Kategorien

**Session History & Statistiken**
- ✅ **Umfassende Workout-Historie** - Alle vergangenen Sessions mit detaillierten Statistiken
- ✅ **Streak-Tracking** - Verfolge aktuelle und längste Trainings-Streaks
- ✅ **Zeitraum-Filter** - Statistiken nach Woche, Monat, 3 Monaten, Jahr oder gesamt
- ✅ **Volumen & Zeit-Tracking** - Gesamtvolumen, Sätze, Wiederholungen, Dauer

**Apple Health Integration**
- ✅ **HealthKit-Integration** - Automatischer Sync von Workouts, Gewicht, Größe
- ✅ **Körpermetriken-Import** - Importiere Gewicht & Größe aus Apple Health
- ✅ **Kalorienbergechnung** - Präzise Berechnung basierend auf echten Körperdaten

**UI/UX Verbesserungen**
- ✅ **Brand Color** #F77E2D - Durchgängiges GymBo-Orange
- ✅ **Per-Set Pausenzeiten** - Individuelle Rest-Times für jeden Satz
- ✅ **Difficulty Levels** - 3 Schwierigkeitsgrade (Anfänger 🍃, Fortgeschritten 🔥, Profi ⚡)
- ✅ **Equipment Labels** - Klare Kennzeichnung (Maschine, Freie Gewichte, Gemischt)
- ✅ **Collapsible Sections** - Aufklappbare Bereiche für Favoriten & Ordner
- ✅ **Wöchentliches Trainingsziel** - Konfigurierbares Ziel (1-7 Tage/Woche)

**Übungsverwaltung**
- ✅ **145+ Übungen** aus CSV-Katalog
- ✅ **Eigene Übungen erstellen** - Multi-Select Muskelgruppen, Equipment, Schwierigkeit
- ✅ **Übungen löschen** - Katalog-Übungen geschützt, nur eigene löschbar
- ✅ **Exercise Reordering** - Drag & Drop mit permanentem Speichern

## 🏗️ Architektur & Technik

**Clean Architecture**
- ✅ 4-Layer Architecture (Domain, Data, Presentation, Infrastructure)
- ✅ 32 Use Cases für saubere Business Logic
- ✅ Repository Pattern mit Mappern
- ✅ Dependency Injection Container
- ✅ 13 SwiftData Entities + 10 Domain Entities

**Datenbank**
- ✅ SwiftData Migration V1 → V6
- ✅ Automatische Schema-Migration
- ✅ Daten-Persistenz mit in-place Updates

**Feature-Highlights**
- ✅ **Feature Flags System** - Experimentelle Features togglebar
- ✅ **Session Persistence** - Workouts überleben App-Neustarts
- ✅ **Progressive Overload** - Letzte Gewichte automatisch vorausgefüllt
- ✅ **Auto-Finish** - Übungen werden automatisch ausgeblendet nach Completion

## 📊 Content

**Sample Workouts**
- ✅ 6 umfassende Beispiel-Workouts
  - 2x Maschinen (Ganzkörper, Oberkörper)
  - 2x Freie Gewichte (Push Day, Pull Day)
  - 2x Gemischt (Beine Push/Pull, Oberkörper Hybrid)

## 🔧 v1.0 → v2.0 Migration

**Wichtig für v1.0 Nutzer:**
- ⚠️ **Datenbank-Reset erforderlich** - Alte Daten können nicht übernommen werden
- ✅ **Neue Features** rechtfertigen Clean Start
- ✅ **Migration-Alert** informiert User über Änderungen
- ✅ **Seed-Daten** mit 6 professionellen Workouts vorinstalliert

## 🎯 Was kommt als Nächstes? (v2.1+)

**Geplante Features:**
- 📱 **Live Activities** - Lock Screen Integration für aktive Sessions
- 📊 **Progression System** - Automatische Gewichtssteigerung & Tracking
- 📱 **iOS Widgets** - Home Screen Widgets für schnellen Zugriff
- 📥 **Workout Import** - Workouts von anderen Plattformen importieren
- 🎨 **Superset/Circuit UI** - UI für Erstellung (Backend bereits fertig!)

---

**Version:** 2.6.0+
**Build:** Production Ready
**Mindest-iOS:** 17.0
**Status:** ✅ MVP Complete - All Core Features Implemented
