# Carry Queen Pinball – „Ich bin die Beste (gern geschehen)"

Kostenloses Flipperspiel zum Song, gebaut mit der freien [Godot Engine](https://godotengine.org) (4.7, liegt in `godot-engine/` bei).

## Starten

**Direkt spielen (ohne Editor):**

```
godot-engine\Godot_v4.7.1-stable_win64.exe --path .
```

**Im Editor öffnen (zum Bearbeiten):**

```
godot-engine\Godot_v4.7.1-stable_win64.exe -e --path .
```

## Steuerung

| Aktion            | Taste                                  |
|-------------------|----------------------------------------|
| Linker Flipper    | Pfeil links oder `A`                   |
| Rechter Flipper   | Pfeil rechts oder `D`                  |
| Abschuss          | `Leertaste` halten und loslassen       |
| Anstoßen links    | `Y` (Taste unten links)                |
| Anstoßen rechts   | `M`                                    |
| Weiter (Popups)   | `Leertaste` / Klick                    |
| Touch (Mobil)     | linke/rechte Bildschirmhälfte = Flipper, unten rechts halten = Abschuss |

Zu häufiges Anstoßen kassiert einen **RAGEQUIT** (Tilt): Flipper und Punkte sind bis zum nächsten Ball tot. Eine Einweg-Klappe oben in der Abschussbahn lenkt zurückfallende Bälle ins Spielfeld – erneutes Abschießen ist praktisch nie nötig.

## Spielprinzip (= der Song)

- **Carry-Save:** Einmal pro Ball rettet die Queen die Kugel („Mein Carry rettet"). Gern geschehen.
- **Ego-Meter:** Treffer steigern den Multiplikator bis x10 („und noch besser bin ich").
- **4 Disziplinen** (oben in der Leiste): 
  - **DMG** – die D-A-M-A-G-E-Bank räumen → Frenzy (alles x2)
  - **KILLS** – 3× alle vier WASD-Bumper innerhalb von 6 Sekunden treffen
  - **CARRY** – 3 Bälle im Thron locken → Ko-op-Multiball („Vier Spieler. Ein Carry. Ich.") – nur die pinke Carry-Kugel zählt x10
  - **ICH** – die I-C-H-Targets komplett machen, dann Hurry-Up am Thron kassieren
- Alle 4 Disziplinen → Wizard-Mode **„DER BERICHT"** (alles x5, Thron = Mega-Jackpot).
- Zufällige Gefahrenphase **„KEIN HEAL. KEIN PLAN. KEIN SKILL. KEIN SIEG."**: Licht aus, kein Ego-Zuwachs, kein Carry-Save.
- Nach jedem Ball: **Match-Report** (Carry-Anteil: ICH 98 %, Team 2 %).
- Highscore-Liste: Platz 1 gehört immer **ICH** – mit genau 1 Punkt Vorsprung.

## Song-Audio einbinden (optional)

Das Spiel läuft komplett ohne Audiodateien (prozeduraler Sound). Wer den echten Song einbinden will, legt Dateien ab (`.ogg` bevorzugt, `.mp3` geht auch) – sie werden beim Start automatisch geladen:

```
assets/music/loop.ogg          <- nahtloser Instrumental-Loop (Hintergrundmusik)
assets/voice/koop_modus.ogg          "Ko-op Modus. Vier Spieler. Ein Carry. Ich."
assets/voice/ich_bin_die_beste.ogg   "Ich bin die Beste"
assets/voice/mein_carry_rettet.ogg   "Mein Carry rettet"
assets/voice/gern_geschehen.ogg      "Gern geschehen."
assets/voice/kein_skill.ogg          "Kein Skill."
assets/voice/kein_plan.ogg           "Kein Plan."
assets/voice/ohne_mich.ogg           "Ohne mich."
assets/voice/der_bericht.ogg         Spoken-Breakdown
assets/voice/outro.ogg               "Ihr wart auch dabei..."
```

## Queen-Artwork

Liegt eine freigestellte PNG unter `assets/queen.png`, erscheint sie als Stream-Avatar oben rechts.

## Projektstruktur

```
project.godot        Godot-Projektdatei (Start: scenes/main.tscn)
scenes/main.tscn     Minimale Hauptszene, alles Weitere entsteht im Code
scripts/main.gd      Spielsteuerung: Ballfluss, Modi, Plunger, Report
scripts/table.gd     Tisch-Geometrie (Wände, Bahnen, Element-Positionen)
scripts/game.gd      Autoload: Punkte, Ego, Disziplinen, Event-Bus, Highscore
scripts/sfx.gd       Autoload: prozeduraler Sound + optionale Audio-Dateien
scripts/hud.gd       Stream-Overlay: Score, Chat, Meldungen, Popups
scripts/ball.gd      Kugel (inkl. pinker Carry-Kugel)
scripts/flipper.gd   Flipperfinger
scripts/bumper.gd    WASD-Pop-Bumper
scripts/slingshot.gd Slingshots (Spike-Schulterpolster)
scripts/drop_target.gd  DAMAGE-Bank
scripts/standup.gd   I-C-H-Targets
scripts/spinner.gd   OP-Spinner
scripts/kicker.gd    Thron (Lock/Jackpot)
```

Feintuning: Physik in `project.godot` (`default_gravity`) und den Konstanten oben in den Skripten (`KICK`, `SPEED`, Punktwerte in den `_on_hit`-Funktionen).

## Export als eigenständige EXE / Web-Version

Im Editor: `Projekt → Export…` → Vorlage „Windows Desktop" bzw. „Web" hinzufügen (Godot lädt die Export-Templates einmalig herunter). Die Web-Version lässt sich als kostenlose Zugabe direkt auf itch.io o. ä. hochladen.
