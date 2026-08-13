# Sprachaufnahmen der Carry Queen

Hier hinein kommen die gesprochenen Sprüche. Liegt eine Datei da, wird sie an
der passenden Stelle abgespielt; fehlt sie, bleibt die Stelle stumm - das
Spiel läuft in jedem Fall.

**Der Dateiname ist nur das Ablagefach, nicht der Text.** `spiel_vorbei` heißt
also nicht, dass sie „Spiel vorbei" sagen soll - dort gehört die Zeile hin,
die beim Spielende kommt. Was gesprochen wird, entscheidest du.

## Die Sprüche

| Datei | Wann sie kommt | Auf dem Feld steht dabei | Könnte sie sagen |
|---|---|---|---|
| `ich_bin_die_beste` | I-C-H-Bank komplett · Hurry-Up am Durchlauf kassiert · Hauptgewinn am Glücksrad (25K) | „ICH. WER SONST." | „Ich bin die Beste." |
| `mein_carry_rettet` | Carry-Save: der Ball war verloren und wird gerettet | „MEIN CARRY RETTET." – „Gern geschehen." | „Hab ich dich wieder rausgehauen." |
| `kein_skill` | Ball endgültig verloren | (nichts, die Meldung kommt erst beim nächsten Ball) | „Kein Skill." |
| `der_bericht` | Wizard startet, alle vier Disziplinen geschafft | „DER BERICHT." – „40 Sekunden lang zählt alles fünffach." | „Jetzt kommt der Bericht." |
| `koop_modus` | G-G-E-Z-Multiball startet | „G-G-E-Z: KO-OP-MULTIBALL!" | „Vier Spieler. Ein Carry. Ich." |
| `spiel_vorbei` | Game Over | Punktefenster mit Bestwert | „Gern geschehen. Und tschüss." |

Die mittlere Spalte ist so wichtig wie die rechte: Steht der Satz schon auf
dem Feld, sollte sie etwas anderes sagen - sonst liest man mit.

## Wie oft man sie hört

| Rang | Datei | Wie oft | Worauf achten |
|---|---|---|---|
| 1 | `kein_skill` | bei jedem Ballverlust, mindestens 3× je Spiel | kurz und beiläufig, sonst nervt es beim vierten Mal |
| 2 | `mein_carry_rettet` | höchstens 1× je Ball | darf triumphieren, kommt aber regelmäßig |
| 3 | `ich_bin_die_beste` | mehrmals je Spiel, aus drei Anlässen | muss zu drei verschiedenen Momenten passen |
| 4 | `spiel_vorbei` | 1× je Spiel | letzter Eindruck, ruhig etwas länger |
| 5 | `der_bericht` | oft gar nicht | Höhepunkt, darf groß klingen |
| 5 | `koop_modus` | oft gar nicht | Höhepunkt, darf groß klingen |

## Noch nicht verdrahtet

Diese drei sind vorgesehen, werden aber an keiner Stelle abgerufen. Wenn du
sie aufnimmst, sag Bescheid - dann bekommen sie ihren Platz.

| Datei | Vorschlag, wo sie hingehört | Könnte sie sagen |
|---|---|---|
| `gern_geschehen` | als Nachsatz ein paar Sekunden nach `mein_carry_rettet` | „Gern geschehen." |
| `kein_plan` | wenn eine Weile nichts getroffen wird | „Kein Plan, oder?" |
| `ohne_mich` | beim Verlust des letzten Balls, vor dem Spielende | „Ohne mich wärt ihr nichts." |

## Format

| Punkt | Vorgabe | Warum |
|---|---|---|
| Endung | `.ogg`, `.wav` oder `.mp3` | in dieser Reihenfolge gesucht; `.ogg` ist am kleinsten |
| Auflösung bei `.wav` | **16 Bit** | 24 Bit lädt Godot nicht, vorher umrechnen |
| Kanäle, Abtastrate | Mono, 44,1 kHz | mehr bringt nichts, die Stimme läuft einkanalig |
| Länge | 1 bis 2 Sekunden | länger redet sie über das nächste Ereignis hinweg |
| Hall | keiner | die Stimme läuft über einen Kanal mit Kompressor; eigener Hall kämpft dagegen an |
| Pegel | normal aussteuern, nicht anschlagen | der Kompressor holt sie ohnehin nach vorn |
| Nach dem Ablegen | `godot --headless --path . --import --quit` | sonst kennt das Projekt die neue Datei nicht |

## Was wo hingehört

| Was | Wohin | Besonderheit |
|---|---|---|
| Sprüche der Queen | `assets/voice/<name>.ogg` | Namen aus der Tabelle oben |
| Musikstück | `assets/music/loop.ogg` | läuft in Schleife, liegt 6 dB unter dem Spiel |
| Geräusche | `assets/sfx/<name>.ogg` | liegen **zusätzlich** unter dem erzeugten Klang, siehe `assets/sfx/README.md` |

Während gesprochen wird, geht die Musik automatisch um 9 dB zurück und danach
wieder hoch.
