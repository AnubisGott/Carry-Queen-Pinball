# Sprachaufnahmen der Carry Queen

Hier hinein kommen die gesprochenen Sprüche. Liegt eine Datei da, wird sie an
der passenden Stelle abgespielt; fehlt sie, bleibt die Stelle stumm - das
Spiel läuft in jedem Fall.

**Der Name sagt, wo die Aufnahme hingehört - nicht, was drin gesprochen
wird.** Ein Ordner „Multiball" bedeutet: „das ist der Satz für den Multiball".
Ob sie darin „Multiball" sagt oder „Vier Spieler, ein Carry", entscheidest du.

## So legst du eine Aufnahme ab

**Der Ordner heißt wie der gesprochene Satz** - genau so, wie er unten in der
Spalte „Sprechtext" steht. Die Nummer am Ende zählt die Fassungen:

```
assets/voice/Multiball1/Multiball1.mp3
assets/voice/Multiball2/Multiball2.mp3
assets/voice/zeig doch mal was du kannst1/zeig doch mal was du kannst1.mp3
```

Groß- und Kleinschreibung, Leerzeichen, Punkte, Bindestriche und Umlaute sind
dabei egal - „Ich bin die beste1" und „ich_bin_die_beste (1)" landen im selben
Fach. Heißt die Datei im Ordner anders als der Ordner, zählt der Ordnername.

Liegen mehrere Fassungen da, würfelt das Spiel bei jedem Mal neu und nimmt
**nie zweimal hintereinander dieselbe**. Genauso gut geht es ohne Ordner: dann
heißt die Datei wie das Fach, also `assets/voice/kein_skill.mp3`.

Was zu keinem Satz passt, bleibt einfach liegen und kostet nichts - es wird
gar nicht erst geladen. Beim Start steht dann in der Ausgabe „Stimme: ohne
Fach liegen geblieben: …", daran siehst du sofort, wenn ein Name danebengeht.

**Sie redet nicht über sich selbst.** Läuft noch ein Satz, fallen Spott,
Kanal-Antworten und Nachsätze aus; die großen Ansagen (I-C-H, Multiball,
Bericht, Carry-Save, Ballverlust, Spielende) unterbrechen dagegen.

Die letzte Spalte der Tabellen ist deine: Was dort steht, spricht sie an
dieser Stelle - leer heißt, die Stelle bleibt stumm.

| Spalte | Bedeutung |
|---|---|
| Nr | Kürzel der Zeile, z. B. „M9" |
| Wie oft | wie häufig die Zeile in einem Spiel vorkommt |
| Fach | Dateiname, falls die Zeile schon vertont werden kann; „–" heißt: Fach muss noch angelegt werden |
| **Sprechtext** | **von dir auszufüllen** - was sie hier sagen soll |

Der Text auf dem Feld ist ohne Umlaute geschrieben - die Schrift im Spiel
kennt keine. Gesprochen wird natürlich mit.

## 1. Große Meldungen in der Feldmitte

| Nr | Wann sie kommt | Große Zeile | Zweite Zeile | Wie oft | Fach | Sprechtext |
|---|---|---|---|---|---|---|
| M1 | Spielbeginn, erster Ball | „BALL 1" | „Zeig doch mal, was du kannst." | 1× je Spiel | – | „Zeig doch mal, was du kannst." |
| M2 | jeder weitere Ball | „BALL 2" / „BALL 3" | ein Spott-Spruch, siehe Abschnitt 3 | 2× je Spiel | – |  |
| M3 | vier Bumper getroffen, Hurry-Up startet | „KILL BESTAETIGT (1)" | „EGO x2 - Hurry-Up: ab durch die MITTE!" | oft, mehrmals je Ball | – |  |
| M4 | vier Bumper getroffen, Hurry-Up läuft schon | „KILL BESTAETIGT (2)" | „EGO x3. +9.000" | oft | – |  |
| M5 | Hurry-Up am mittleren Durchlauf kassiert | „KILL KASSIERT." | „+25.000" | mehrmals je Spiel | `ich_bin_die_beste` |  |
| M6 | Glücksrad zahlt 5K, 10K oder 25K | „DIAMANT!" / „MASTER!" / „CHALLENGER!" | „+5.000  Geht doch. Fast wie ich." bzw. „…  CHALLENGER. Also mein Niveau." | mehrmals je Spiel | bei 25K: `ich_bin_die_beste` |  |
| M7 | G-G-E-Z komplett, Multiball läuft schon | „G-G-E-Z." | „Waren ja auch nur vier Gassen." | gelegentlich | – |  |
| M8 | G-G-E-Z komplett, Multiball startet | „G-G-E-Z: KO-OP-MULTIBALL!" | „Vier Spieler. Ein Carry. Ich." | 0-2× je Spiel | `koop_modus` | „Multiball" |
| M9 | I-C-H-Bank komplett | „ICH. WER SONST." | „+7.500" | 1× je Ball möglich | `ich_bin_die_beste` |  |
| M10 | Jackpot im Multiball | „JACKPOT!" | „+12.000" | nur im Multiball, dann oft | – |  |
| M11 | Jackpot nach vollem Multiball-Satz | „MEGA-JACKPOT!" | „+50.000" | selten | – |  |
| M12 | I-C-H-Bank während des Multiballs | „ICH. WER SONST." | „+15.000" | nur im Multiball | `ich_bin_die_beste` |  |
| M13 | Ball im Thron geparkt (1. und 2. Ball) | „BALL GEPARKT (1/3)" | „Der Thron sammelt euch ein." | gelegentlich | – |  |
| M14 | dritter Ball geparkt, Thron-Multiball startet | „VIER SPIELER. EIN CARRY." | „ICH." | selten | `koop_modus` |  |
| M15 | Bericht startet, alle vier Disziplinen geschafft | „DER BERICHT." | „40 Sekunden lang zaehlt alles fuenffach." | oft gar nicht | `der_bericht` | „Die Ulti beginnt." |
| M16 | Bericht ist vorbei | „AM ENDE STEHT MEIN NAME." | „Eure Namen stehen nicht." | so oft wie M15 | – |  |
| M17 | Carry-Save fängt den verlorenen Ball | „MEIN CARRY RETTET." | „Gern geschehen." | höchstens 1× je Ball | `mein_carry_rettet` | „MEIN CARRY RETTET." |
| M18 | Tisch zu oft gerüttelt, Tilt | „RAGEQUIT!" | „Tilt. Flipper tot, Punkte tot. Wie dein Team." | nur wenn man rüttelt | – |  |

M19 wäre der God-Modus („GOD-MODUS AN"), der ist aber nur zum Testen da und
kommt im Spiel nicht vor.

## 2. Kleine Zeilen unter der Feldmitte

Diese laufen ohne große Überschrift durch. Sie sind der leise Kommentar - eine
Stimme darauf wirkt schnell zu wuchtig, außer du willst genau das.

| Nr | Wann sie kommt | Text | Wie oft | Fach | Sprechtext |
|---|---|---|---|---|---|
| K1 | Rütteln, letzte Warnung vor dem Tilt | „Vorsicht. Gleich gibt's einen RAGEQUIT." | nur wenn man rüttelt | – |  |
| K2 | Hurry-Up abgelaufen, ohne es zu kassieren | „Hurry-Up vorbei." + Spott-Spruch | mehrmals je Spiel | – |  |
| K3 | DAMAGE-Bank abgeräumt, Frenzy startet | „DAMAGE-FRENZY: alles x2. +6.000" | mehrmals je Spiel | – |  |
| K4 | E-G-O-Bank komplett | „E-G-O komplett. +5.000" | 1× je Ball möglich | – |  |
| K5 | Glücksrad zahlt 500, 1K oder 2K | „BRONZE: +500  Hardstuck. Wer haette das gedacht." | häufig | – |  |
| K6 | Multiball vorbei, nur noch ein Ball | „Multiball vorbei. Ihr wart Deko." | so oft wie M8/M14 | – |  |

## 3. Die Spott-Sprüche

Ein Topf mit acht Zeilen. Das Spiel greift zufällig hinein - beim Ballstart
(M2) und wenn das Hurry-Up verfällt (K2). Jede Zeile kommt also unregelmäßig,
zusammen aber sehr oft.

| Nr | Text | Sprechtext |
|---|---|---|
| S1 | „Warst du nicht gut genug?" | „Warst du nicht gut genug?" |
| S2 | „Einfach mal besser sein." | „Einfach mal besser sein." |
| S3 | „Skill-Issue. Nicht meins." | „Skill-Issue. Nicht meins." |
| S4 | „Ich haette den gehalten. Locker." | „Ich haette den gehalten. Locker." |
| S5 | „Reflexe wie ein Ladebildschirm." | „Reflexe wie ein Ladebildschirm." |
| S6 | „Soll ich das auch noch fuer dich machen?" | „Soll ich das auch noch fuer dich machen?" |
| S7 | „Uebung. Ganz viel Uebung." | „Uebung. Ganz viel Uebung." |
| S8 | „War bestimmt der Ping, ne?" | „War bestimmt der Ping, ne?" |

Hier bekommt jede ausgefüllte Zeile ein eigenes Fach - dann spricht sie genau
den Spruch, der auch dasteht. Acht Aufnahmen sind viel; drei oder vier reichen
auch, dann spricht sie nur bei diesen und schweigt sonst.

## 4. Die vier Bericht-Zeilen

Während der 40 Sekunden alle vier Sekunden eine, groß und ohne zweite Zeile.
Das ist die einzige Stelle, an der sie einen zusammenhängenden Text hält.

| Nr | Text | Sprechtext |
|---|---|---|
| B1 | „WER MACHT DEN SCHADEN? ICH." |  |
| B2 | „WER HOLT DIE KILLS? ICH." |  |
| B3 | „WER RETTET DEN KAMPF? ICH." |  |
| B4 | „WER SEID IHR? NICHTS." |  |

Als Block gesprochen der stärkste Moment im ganzen Spiel - vier kurze
Aufnahmen, die aufeinander aufbauen.

## 5. Ihre Zeilen im Chat

Alle 55 bis 100 Sekunden wirft der Chat eine Zeile über den Kanal ein, und die
Queen antwortet mit einer davon.

| Nr | Text | Sprechtext |
|---|---|---|
| C1 | „Oben ist der Kanal. Klicken. Jetzt." | „Oben ist der Kanal. Klicken. Jetzt." |
| C2 | „Abonnieren kostet nichts. Skill schon." | „Abonnieren kostet nichts. Skill schon." |
| C3 | „Im Stream mache ich das mit einer Hand." | „Im Stream mache ich das mit einer Hand." |
| C4 | „Zuschauen kannst du ja wenigstens." | „Zuschauen kannst du ja wenigstens." |
| C5 | „Der Knopf oben links. Nicht so schwer." | „Der Knopf oben links. Nicht so schwer." |

## 6. Das Endstand-Fenster

| Nr | Wo | Text | Fach | Sprechtext |
|---|---|---|---|---|
| E1 | Überschrift | „STREAM BEENDET." | `spiel_vorbei` | Du warst auch dabei, das war bestimmt schön für dich. |
| E2 | Highscore-Liste | „1. ICH … / 2. TEAM (DU) … / 3. TEAM (DU) …" | – |  |
| E3 | Zitat darunter | „Ihr wart auch dabei. Das war bestimmt schoen fuer euch. Nichts zu danken. GERN GESCHEHEN." | – |  |

E3 ist ihr Schlusswort und der einzige längere Text im Spiel. Wenn eine
Aufnahme länger als zwei Sekunden sein darf, dann diese.

## 7. Die Ablagefächer

Alle bis auf `ohne_mich` sind verdrahtet: die Aufnahme muss nur noch da sein.
Der Ordnername in der zweiten Spalte ist der, den ich aus deinem Sprechtext
erwarte - ein anderer Name geht auch, solange er nah genug dran ist.

| Fach | Ordner heißt | Gehört zu | Da liegen |
|---|---|---|---|
| `beste` | Ich bin die Beste | M5, M6 (nur 25K), M9, M12 | **3 Fassungen** |
| `koop` | Multiball | M8, M14 | **4 Fassungen** |
| `ball_start` | zeig doch mal was du kannst | M1, erster Ball | **3 Fassungen** |
| `carry_rettet` | Mein Carry rettet | M17 | – |
| `kein_skill` | Kein Skill | Ball endgültig verloren (kein Text auf dem Feld) | – |
| `bericht` | Die Ulti beginnt | M15 | – |
| `outro` | Du warst auch dabei … | E1, Spielende | – |
| `gern` | Gern geschehen | Nachsatz 2,8 s nach M17 | – |
| `kein_plan` | Kein Plan | 18 s lang nichts getroffen | – |
| `spott_1` … `spott_8` | der jeweilige Spruch, siehe Abschnitt 3 | M2, K2 | – |
| `kanal_1` … `kanal_5` | die jeweilige Zeile, siehe Abschnitt 5 | Chat-Antwort | – |
| `ohne_mich` | Ohne mich | noch nirgends - Sprechtext eintragen, dann verdrahte ich es | – |

`kein_skill` hat als einzige Zeile keinen Text auf dem Feld: beim Ballverlust
steht dort nichts, die nächste Meldung ist erst der neue Ball. Wer sie hört,
hört nur sie.

Die Spott- und Kanal-Fächer sind durchnummeriert wie die Kürzel: S3 wird zu
`spott_3`, C4 zu `kanal_4`. Du kannst den Ordner aber auch einfach nach dem
Spruch benennen - „Skill-Issue. Nicht meins.1" landet von selbst in `spott_3`.

## 8. Wie oft man sie hört

| Rang | Fach | Wie oft | Worauf achten |
|---|---|---|---|
| 1 | `beste` | mehrmals je Spiel, aus vier Anlässen | muss zu vier verschiedenen Momenten passen - hier lohnen mehrere Fassungen am meisten |
| 2 | `kein_skill` | bei jedem Ballverlust, mindestens 3× je Spiel | kurz und beiläufig, sonst nervt es beim vierten Mal |
| 3 | `spott_1` … `spott_8` | zusammen 3-6× je Spiel, einzeln selten | eine Aufnahme je Spruch; drei oder vier reichen auch |
| 4 | `kanal_1` … `kanal_5` | alle 55-100 s, davon jedes zweite Mal | Werbung, also eher beiläufig als groß |
| 5 | `carry_rettet` | höchstens 1× je Ball | darf triumphieren, kommt aber regelmäßig |
| 6 | `gern` | wie `carry_rettet`, 2,8 s danach | ganz kurz, sie hängt es nur an |
| 7 | `ball_start` | 1× je Spiel | die Begrüßung, darf Zeit lassen |
| 7 | `outro` | 1× je Spiel | letzter Eindruck, ruhig etwas länger |
| 8 | `koop` | oft gar nicht | Höhepunkt, darf groß klingen |
| 8 | `bericht` | oft gar nicht | Höhepunkt, darf groß klingen |
| 9 | `kein_plan` | nur wenn 18 s nichts getroffen wird | trockene Nachfrage |

Die Textspalten der Meldungs-Tabellen sind so wichtig wie dein Sprechtext:
Steht der Satz schon auf dem Feld, sollte sie etwas anderes sagen - sonst
liest man mit.

## 9. Format

| Punkt | Vorgabe | Warum |
|---|---|---|
| Endung | `.mp3`, `.ogg` oder `.wav` | alle drei gehen; `.mp3` mit 192 kbit/s ist das, was schon hier liegt |
| Auflösung bei `.wav` | **16 Bit** | 24 Bit lädt Godot nicht, vorher umrechnen |
| Kanäle, Abtastrate | Mono oder Stereo, 44,1 oder 48 kHz | die Stimme läuft über einen eigenen Kanal, beides passt |
| Länge | 1 bis 3 Sekunden | länger redet sie über das nächste Ereignis hinweg; die abgelegten liegen bei 1,6 bis 2,7 s |
| Hall | keiner | die Stimme läuft über einen Kanal mit Kompressor; eigener Hall kämpft dagegen an |
| Pegel | normal aussteuern, nicht anschlagen | der Kompressor holt sie ohnehin nach vorn |
| Nach dem Ablegen | nichts weiter | die Dateien werden beim Start direkt gelesen, kein Import nötig |

Dateien, deren Name zu keinem Satz passt, werden vom Spiel nicht angefasst -
sie liegen hier nur herum und werden nicht einmal geladen. Das gilt zurzeit
für die beiden Rohspuren `Vocals-Carry-Queen (Lead Vocal) (1).wav` und `(2)`.
Die beiden sind mit je 33 MB allerdings groß genug, dass sie besser außerhalb
des Spielordners liegen sollten.

## 10. Was wo hingehört

| Was | Wohin | Besonderheit |
|---|---|---|
| Sprüche der Queen | `assets/voice/<satz><nr>/<satz><nr>.mp3` | Ordnername = Sprechtext, Nummer = Fassung |
| … oder ohne Ordner | `assets/voice/<fach>.mp3` | Fachnamen aus Abschnitt 7 |
| Musikstück | `assets/music/loop.ogg` | läuft in Schleife, liegt 6 dB unter dem Spiel |
| Geräusche | `assets/sfx/<name>.ogg` | liegen **zusätzlich** unter dem erzeugten Klang, siehe `assets/sfx/README.md` |

Während gesprochen wird, geht die Musik automatisch um 9 dB zurück und danach
wieder hoch.

## Anhang: der Chat gehört nicht ihr

Im Chat links unten schreiben „Zuschauer". Diese Zeilen sind nicht von der
Queen und bekommen deshalb keine Stimme - sie stehen hier nur der
Vollständigkeit halber und haben darum auch keine Sprechtext-Spalte. Ihre
eigenen Chat-Antworten sind C1 bis C5.

| Anlass | Zeilen |
|---|---|
| Bumper | „WASD spam lol" · „POG" · „schneller als mein Ping" · „W = Content" |
| Slingshot | „die Schulterpolster leben" · „autsch" · „F" |
| Spinner | „OP OP OP" · „clip it!!" · „der Spinner dreht durch" |
| DAMAGE-Bank | „DAMAGE geht hoch" · „tank diff" · „98% dmg incoming" |
| I-C-H-Ziele | „I-C-H, wer wohl" · „sie meint sich selbst lol" |
| Kill | „KILL BESTAETIGT" · „gg ez" · „REPORTED lol" · „adc diff" |
| Ball geparkt | „Ball im Thron geparkt" · „sie sammelt uns ein…" |
| Multiball | „VIER BAELLE WTF" · „wir sind nur Deko" · „der pinke macht eh alles" |
| Jackpot | „JACKPOT POGGERS" · „Clip. Es. Jetzt." · „unfassbar (sie halt)" |
| Ballverlust | „F" · „ball diff" · „mein Ping war schuld" · „classic Team-Moment" |
| Carry-Save | „CARRY RETTET LOL" · „nichts zu danken ;)" · „sie hat schon wieder recht" |
| Frenzy | „FRENZY!! alles x2" · „DAMAGE MODUS AN" |
| Bericht | „DER BERICHT. Gaensehaut." · „ihr Name steht schon drauf" |
| Spielende | „war bestimmt schoen fuer euch" · „gern geschehen und tschuess" · „98% waren ihre, wie immer" |
| Abschuss | „da fliegt er" · „neuer Ball, gleiche Queen" |
| Tilt | „RAGEQUIT lmaooo" · „er schuettelt den Tisch, peinlich" · „tilt wie im Ranked" |
| Durchlauf | „mitten durch lol" · „einfach durchgerollt" · „Durchlauf. Wie immer sie." |
| Fang-Mulde | „kurz geparkt lol" · „rein und sofort wieder raus" · „die Fang-Mulde carried" |
| G-G-E-Z | „gg ez" · „EZ Clap" · „vier Gassen, null Gegenwehr" |
| EGO steigt | „ihr EGO skaliert besser als wir" · „x-fach?? okay" |
| Rad angestoßen | „RAD DREHT" · „ranked roulette lol" · „sie spinnt es an" |
| Rad zahlt | „gerankt lmao" · „das Rad hat gesprochen" · „PAY2WIN vibes" · „kein Skill, nur Rad" |
| Kanal | „youtube.com/@djanubis5223 - LIVE" · „@djanubis5223, Link ist oben in der Leiste" · „abonniert oder heult" · „sie streamt das grad, oben der Knopf" · „DJ Anubis hat den Sound gemacht, YT-Knopf oben" · „ich guck das lieber im Stream als hier" |
