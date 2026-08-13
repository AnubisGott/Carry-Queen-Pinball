# Eigene Klangdateien

Alles in diesem Ordner hat Vorrang vor dem erzeugten Klang. Legt man hier eine
Datei mit dem Namen eines Klangs ab, wird sie statt der Synthese verwendet -
alles andere bleibt synthetisch. Man kann also einzelne Geräusche austauschen
und den Rest lassen.

**Formate:** `.ogg`, `.wav` oder `.mp3`, in dieser Reihenfolge gesucht.
Beispiel: `assets/sfx/flip.ogg` ersetzt das Flipper-Geräusch.

Nach dem Ablegen einmal `godot --headless --path . --import --quit` laufen
lassen. Beim Start meldet das Spiel in der Konsole, welche Dateien es
gefunden hat (`Sfx: eigene Dateien fuer ...`), und `tools/diag_audio`
markiert sie in seiner Liste.

**Wichtig:** Für jede Datei gehört ein Eintrag in `CREDITS.md` - Quelle, Autor
und Lizenz. Das Repo ist öffentlich.

## Die Namen

| Name | Wann | Dauer | Worauf achten |
|---|---|---|---|
| `flip` | Flipperhebel gedrückt | 50-120 ms | Spulen-Klack, trocken, kein Hall |
| `bump_w` `bump_a` `bump_s` `bump_d` | die vier Bumper | 150-250 ms | vier **unterschiedliche** Tonhöhen, S am tiefsten, D am höchsten |
| `sling` | Slingshot | 60-120 ms | schnappt, härter als der Flipper |
| `spin` | Spinner, je Umdrehung | 20-50 ms | sehr kurz, sonst überlagert es sich |
| `target` | Drop-Target getroffen | 80-150 ms | |
| `standup` | Standup-Target getroffen | 80-150 ms | heller als `target` |
| `rail` | Kugel prallt an eine Bande | 20-60 ms | leise, kommt oft |
| `roll` | **Dauerschleife**, rollende Kugel | 1-2 s | muss nahtlos loopen, dunkel, wenig Zischen |
| `rakete` | **Dauerschleife**, Feder spannen | 1-2 s | muss nahtlos loopen, Tonhöhe wird im Spiel 0,7-1,5fach verstellt |
| `wisch` | Abschuss | 400-700 ms | Vorbeiflug-Wisch |
| `launch` | Abschuss, mechanischer Schlag | 150-300 ms | |
| `crank` | Ratsche beim Spannen | 20-40 ms | sehr kurz, kommt zwölfmal |
| `lock` | Kugel wird von der Mulde gefangen | 200-400 ms | |
| `eject` | Mulde wirft aus | 100-250 ms | |
| `drain` | Ball verloren | 500-900 ms | Absturz |
| `save` | Carry-Save | 300-600 ms | heldenhaft |
| `rumble` | Grollen vor dem Carry-Save | ~500 ms | tief |
| `mode` | Modus startet | 400-700 ms | |
| `jackpot` | Jackpot | 600-900 ms | |
| `ego_up` | Ego-Level steigt | 400-600 ms | aufsteigend |
| `count` | Countdown-Ziffer | ~100 ms | |
| `count_go` | Countdown-Ende | 200-300 ms | |
| `tick` | Ticken (Gassen, Glücksrad) | 10-30 ms | sehr leise und kurz |
| `over` | Game Over | 800-1000 ms | |

Sprache und Musik liegen weiterhin in `assets/voice/` und `assets/music/`
(siehe Haupt-README).
