# Sprachaufnahmen der Carry Queen

Hier hinein kommen die gesprochenen Sprüche. Liegt eine Datei da, wird sie an
der passenden Stelle abgespielt; fehlt sie, bleibt die Stelle stumm - das
Spiel läuft in jedem Fall.

**Dateiname = Name aus der Tabelle**, Endung `.ogg`, `.wav` oder `.mp3`
(in dieser Reihenfolge gesucht). Beispiel: `assets/voice/ich_bin_die_beste.ogg`

Nach dem Ablegen einmal `godot --headless --path . --import --quit` laufen
lassen.

## Die Sprüche und wann sie kommen

| Datei | Wann sie kommt | Wie oft |
|---|---|---|
| `ich_bin_die_beste` | ICH-Bank komplett, Hurry-Up am Durchlauf kassiert, Hauptgewinn am Glücksrad (25K) | oft - die meistgehörte Zeile |
| `mein_carry_rettet` | Carry-Save: der Ball war verloren und wird gerettet | oft |
| `kein_skill` | Ball endgültig verloren | bei jedem Ballverlust |
| `koop_modus` | Spielstart und G-G-E-Z-Multiball | einmal je Spiel plus Multiball |
| `der_bericht` | Wizard-Modus startet (alle vier Disziplinen geschafft) | selten, der große Moment |
| `outro` | Game Over | einmal je Spiel |

## Noch nicht verdrahtet

Diese drei sind vorgesehen, werden aber bisher an keiner Stelle abgerufen.
Wenn du sie aufnimmst, sag Bescheid - dann bekommen sie ihren Platz:

| Datei | Gedacht für |
|---|---|
| `gern_geschehen` | nach einer Rettung, als Nachsatz |
| `kein_plan` | wenn lange nichts getroffen wird |
| `ohne_mich` | beim Verlust des letzten Balls |

## Format

- **`.ogg` ist am besten** - klein und ohne Einschränkungen.
- `.wav` geht auch, aber nur **16 Bit**. 24-Bit-Aufnahmen lädt Godot nicht;
  vorher umrechnen.
- Mono reicht, 44,1 kHz.
- **Kurz halten**: ein bis zwei Sekunden. Länger redet sie über das nächste
  Ereignis hinweg.
- Ruhig trocken aufnehmen, ohne Hall: die Stimme läuft über einen eigenen
  Kanal mit Kompressor, damit sie sich gegen das Spiel durchsetzt.

Während gesprochen wird, geht die Musik automatisch um 9 dB zurück und
danach wieder hoch.
