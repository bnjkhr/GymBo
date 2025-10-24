-----
App für Übersetzung vorbereiten; localization file?
-----
Aktives Workout: wenn man lange auf den namen einer Übung drückt, will ich sie tauschen können. Schlage mir gleichwertige Übungen vor, ich will aber auch selst aussuchen können. Ich möchte dort ebenfalls über Toggle sagen können, ob die Änderung dauerhaft gespeichert werden soll.
----
Lege 6 sinnvolle Beispielworkouts an. 2 nur Maschinen, 2 nur Freie Gewichte, 2 gemischt. Füge in der StartView jedem Workout noch ein Tag "Anfänger, Fortgeschritten, Profi" hinzu. Die Einordnug erfolgt auf Grund der einthaltenen Übungen.
-----
Wir müssen sicherstellen, dass alle, die aktuell Verison 1.0 installiert haben, nach dem Testflight-Update die korrekten Daten / Datenbank haben. Vermutlich geht das nur mit Datenbank löschen und inital alles neu erstellen. Aber nur beim ersten App-Start.
----
Sobald Profil angelegt, Begrüßung mit Namen. Also zB "Hey <Name> /neue Zeile/, guten Abend."
-----
Profil:
-> Bild (Upload oder Kamera -> Berechtigungen prüfen!)
-> Name
-> Persönliche Daten:
    -> Alter
    -> Erfahrung (weniger als 1 Jahr, 1-3 Jahre, mehr als 3 Jahre)
    -> Ziel (Fitness, Gewichtsverlust, Muskelgewinnung)
Trainingsstatistiken kann raus, haben wir eigenen Tab dafür
Einstellungen:
    -> Apple Health aktivieren
    -> Auslesen: Alter, Gewicht, Trainings, Aktivität
    -> Speichern: Alter, Gewicht, Trainings, Aktivität
    -> App-Darstellung Hell, Dunkel, System
Benachrichtigungen:
    -> Aktivieren
    -> Live Activiy ja / nein


----
Workout "Ganzkörper Maschine" bearbeiten. Diese Übungen müssen rein:
Übung,Sätze,Wiederholungen,Pause (Sekunden),Gewicht (kg)
Beinpresse,3,8-12,90,
Brustpresse,3,8-12,90,
Lat-Zug zur Brust,3,8-12,90,
Schulterpresse,3,8-12,90,
Beinbeuger,3,8-12,90,
Rudermaschine,3,8-12,90,
Beinstrecker,3,8-12,90,
Trizepsmaschine,3,8-12,90,
Bauchmaschine,3,12-15,60,

Bei von-bis Angaben immer die niedrigste Zahl nehmen z.B. 8-12 wird zu 8
