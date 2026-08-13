# Sprachaufnahmen der Carry Queen

Hier hinein kommen die gesprochenen Sprüche. Liegt eine Datei da, wird sie an
der passenden Stelle abgespielt; fehlt sie, bleibt die Stelle stumm - das
Spiel läuft in jedem Fall.

**Dateiname = Name aus der Tabelle**, Endung `.ogg`, `.wav` oder `.mp3`
(in dieser Reihenfolge gesucht). Beispiel: `assets/voice/ich_bin_die_beste.ogg`

Nach dem Ablegen einmal `godot --headless --path . --import --quit` laufen
lassen.

## Die Sprüche und wann sie kommen

Die dritte Spalte ist der Text, der dabei auf dem Spielfeld steht. Die
Aufnahme sollte dazu passen, aber nicht dasselbe sagen - sonst liest man mit.

| Datei | Wann sie kommt | Steht dabei auf dem Feld |
|---|---|---|
| `ich_bin_die_beste` | I-C-H-Bank komplett · Hurry-Up am Durchlauf kassiert · Hauptgewinn am Glücksrad (25K) | „ICH. WER SONST." / „KILL KASSIERT." / „CHALLENGER!" |
| `mein_carry_rettet` | Carry-Save: der Ball war verloren und wird gerettet | „MEIN CARRY RETTET." – „Gern geschehen." |
| `kein_skill` | Ball endgültig verloren | (nichts, die Meldung kommt erst beim nächsten Ball) |
| `der_bericht` | Wizard startet, alle vier Disziplinen geschafft | „DER BERICHT." – „40 Sekunden lang zählt alles fünffach." |
| `koop_modus` | G-G-E-Z-Multiball startet | „G-G-E-Z: KO-OP-MULTIBALL!" – „Vier Spieler. Ein Carry. Ich." |
| `outro` | Game Over | Punktefenster mit Bestwert |

**Wie oft man sie hört**, von oft nach selten:

1. `kein_skill` – bei jedem Ballverlust, also mindestens dreimal je Spiel
2. `mein_carry_rettet` – höchstens einmal je Ball
3. `ich_bin_die_beste` – mehrmals je Spiel, aus drei verschiedenen Anlässen
4. `outro` – einmal je Spiel
5. `der_bericht` und `koop_modus` – die beiden Höhepunkte, oft gar nicht

Die beiden letzten dürfen entsprechend groß klingen. `kein_skill` dagegen
hört man am häufigsten - kurz und beiläufig ist dort besser als eine
Vorstellung, die beim vierten Mal nervt.

## Noch nicht verdrahtet

Diese drei sind vorgesehen, werden aber an keiner Stelle abgerufen. Wenn du
sie aufnimmst, sag Bescheid - dann bekommen sie ihren Platz:

| Datei | Vorschlag, wo sie hingehört |
|---|---|
| `gern_geschehen` | als Nachsatz nach der Rettung, ein paar Sekunden nach `mein_carry_rettet` |
| `kein_plan` | wenn eine Weile nichts getroffen wird |
| `ohne_mich` | beim Verlust des letzten Balls, vor dem Game Over |

## Format

- **`.ogg` ist am besten** - klein und ohne Einschränkungen.
- `.wav` geht auch, aber nur **16 Bit**. 24-Bit-Aufnahmen lädt Godot nicht;
  vorher umrechnen.
- Mono reicht, 44,1 kHz.
- **Kurz halten**: ein bis zwei Sekunden. Länger redet sie über das nächste
  Ereignis hinweg.
- Trocken aufnehmen, ohne Hall: Die Stimme läuft über einen eigenen Kanal mit
  Kompressor, damit sie sich gegen das Spiel durchsetzt.
- Während gesprochen wird, geht die Musik automatisch um 9 dB zurück und
  danach wieder hoch. Ein eigener Hall in der Aufnahme kämpft dagegen an.

## Musik

Ein Musikstück gehört nicht hierher, sondern nach `assets/music/loop.ogg`
(oder `.mp3`). Es läuft in Schleife und liegt 6 dB unter dem Spiel.
