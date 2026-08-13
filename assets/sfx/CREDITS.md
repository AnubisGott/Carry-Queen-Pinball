# Herkunft und Lizenzen der Klangdateien

Dieses Repo ist öffentlich. Jede Datei in diesem Ordner braucht deshalb einen
Eintrag hier - Quelle, Autor und Lizenz. Ohne Eintrag gehört die Datei nicht
ins Repo.

## Echte Flipper-Aufnahmen: Gottlieb Bronco, 1977

Aus dem Paket [1977 Bronco pinball](https://freesound.org/people/schafferdavid/packs/25508/)
von **schafferdavid**, **CC0**. Aufgenommen an einer Gottlieb-Bronco-Maschine
von 1977 mit zwei Neumann KM 184 in XY-Stereo über ein Scarlett 18i20.

Die Aufnahmen enthalten jeweils viele Anschläge hintereinander. Daraus sind
einzelne Treffer geschnitten und auf 16 Bit Mono bei 44,1 kHz gebracht worden
(die Originale sind 24 Bit Stereo bei 96 kHz, das lädt Godot nicht direkt).
Angegeben ist, an welcher Sekunde der Quelldatei der Schnitt beginnt.

| Datei | Quellaufnahme | Schnitt | Abspielrate |
|---|---|---|---|
| `flip.wav` | [pinball-flipper hits](https://freesound.org/s/450270/) | 3,90 s · 220 ms | 44100 |
| `bump_s.wav` | [pinball-bumper hits](https://freesound.org/s/450265/) | 1,46 s · 260 ms | 35280 |
| `bump_a.wav` | [pinball-bumper hits](https://freesound.org/s/450265/) | 1,46 s · 260 ms | 41895 |
| `bump_w.wav` | [pinball-bumper hits](https://freesound.org/s/450265/) | 1,46 s · 260 ms | 49833 |
| `bump_d.wav` | [pinball-bumper hits](https://freesound.org/s/450265/) | 1,46 s · 260 ms | 56007 |
| `launch.wav` | [pinball-ball being launched by plunger](https://freesound.org/s/450267/) | 1,36 s · 450 ms | 44100 |
| `drain.wav` | [pinball-ball falling under flippers](https://freesound.org/s/450266/) | 0,70 s · 600 ms | 44100 |
| `count.wav` | [pinball-backbox scoring mechanism](https://freesound.org/s/450268/) | 3,55 s · 180 ms | 44100 |
| `count_go.wav` | [pinball-backbox scoring mechanism](https://freesound.org/s/450268/) | 4,94 s · 260 ms | 48000 |
| `tick.wav` | [pinball-backbox scoring mechanism](https://freesound.org/s/450268/) | 0,17 s · 90 ms | 44100 |
| `crank.wav` | [pinball-backbox scoring mechanism](https://freesound.org/s/450268/) | 1,58 s · 70 ms | 44100 |

Die vier Bumper sind derselbe Anschlag, über die Abspielrate in der Tonhöhe
gestaffelt - S am tiefsten, D am höchsten, wie beim erzeugten Klang. Eine
echte Maschine hat nur eine Bumper-Sorte, die vier Tonhöhen sind unsere
Spielregel.

## Weitere Klänge

| Datei | Herkunft | Quelle | Autor | Lizenz |
|---|---|---|---|---|
| `rail.ogg` | `impactMetal_medium_004.ogg` (109 ms) | [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds) | Kenney | CC0 |
| `target.ogg` | `impactMetal_heavy_004.ogg` (134 ms) | [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds) | Kenney | CC0 |
| `standup.ogg` | `impactTin_medium_002.ogg` (134 ms) | [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds) | Kenney | CC0 |

Die Datei-Namen im Paket sind absichtlich mit vermerkt: so lässt sich jede
Datei ohne Neu-Download wiederfinden, und man sieht auf einen Blick, welche
Alternative aus derselben Reihe man ausprobieren kann.

CC0 heißt: keine Namensnennung nötig, keine Auflagen. Der Eintrag hier steht
trotzdem, damit die Herkunft nachvollziehbar bleibt.

## Was hier hinein darf

- **Sonniss #GameAudioGDC Bundle** - royalty-free, kommerziell erlaubt, keine
  Namensnennung nötig, unbegrenzt viele Projekte.
  <https://gdc.sonniss.com/> · Lizenztext: <https://sonniss.com/gdc-bundle-license/>
  Eintrag genügt als `Sonniss GDC <Jahr>, <Paketname>` / `royalty-free`.
- **Freesound.org mit Filter auf CC0** - keinerlei Pflichten.
  Direktsuche: <https://freesound.org/search/?q=pinball&f=license:%22Creative+Commons+0%22>
  Trotzdem Link und Autor eintragen, damit nachvollziehbar bleibt, woher es kommt.
- **Freesound.org CC-BY** - erlaubt, aber die Namensnennung ist Pflicht und
  muss hier **und** im Spiel-Abspann stehen.
- **OpenGameArt / Kenney (CC0)** - erlaubt, meist eher generisch.
- **Eigene Aufnahmen und selbst erzeugte Suno-Stems** - Lizenz `eigen`.

## Was hier nicht hinein darf

- **BBC Sound Effects** - nur persönlich, Bildung und Forschung, nicht für ein
  veröffentlichtes Spiel.
- **Zapsplat-Gratiskonto** - Namensnennungspflicht plus weitere Auflagen.
- **Mitschnitte von YouTube, Streams oder aus anderen Spielen** - keine Lizenz.
- Alles, dessen Herkunft man nicht mehr sicher belegen kann.

## Wonach es sich zu suchen lohnt

Ein Flipper besteht aus wenigen Bauteilen, und genau danach findet man
Aufnahmen - besser als nach "pinball":

`solenoid` · `relay click` · `contactor` · `chime bar` · `bell strike` ·
`score reel` · `metal ball rolling` · `steel ball on wood` · `ratchet` ·
`spring release` · `arcade coin`

Die Namen der einzelnen Klänge und was sie treffen sollen, stehen in
`README.md` in diesem Ordner.
