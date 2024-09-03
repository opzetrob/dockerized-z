# dockerized-z
## Wat is het?
Met deze repository bouw je met één commando een complete, lokale (development) installatie van _zWaste_, in een Docker omgeving. \
De `Makefile` in deze repository biedt een aantal commando's die de handelingen rondom de installatie voor hun rekening nemen. \
Na installatie zal de site beschikbaar zijn onder: https://development.client-name.localhost
* Omdat gebruik gemaakt wordt van een _self-signed certificate_ zal je browser misschien een waarschuwing geven als je deze url voor het eerst bezoekt.
* Het is compleet veilig om dit certificaat te accepteren, waarna je de site met https kunt bezoeken.
## Nieuwe installatie
* Kopiëer `.env.example` naar `.env`
* In `.env`, vul de volgende informatie in:
```dotenv
CLIENT_NAME=[my-client]
HOST_INSTALL_PATH=[full-install-path-for-the-project]
HOST_DB_PATH=[partial-install-path-for-the-project-database] #DB zal worden bewaard in HOST_DB_PATH/CLIENT_NAME
#MAILHOG_IMAGE=jcalonso/mailhog #Optioneel: Uncomment deze regel op een M1/M2/M* Mac
```
De directory `zwaste` zal worden aangemaakt tijdens de installatie, je hoeft deze dus niet zelf te maken.
* Open een Terminal-venster en navigeer naar de folder waarin `dockerized-z` is geïnstalleerd. \
Type het commando `make` om een volledige installatie te starten:
```shell
user@My-Device dockerized-z % make
```
* Er wordt je gevraagd om de locatie uit `HOST_INSTALL_PATH` te bevestigen. Om de installatie te stoppen en de waarde in de `.env` file te corrigeren, typ **'n'**. \
  Om door te gaan, typ **'y'**.
* Er worden een _self-signed certificate_ en _key_ gecreëerd, nodig voor HTTPS toegang tot de locale site
* _zWaste_ (Laravel 10 versie) wordt gedownload vanaf `svn.loki.dev`
* `composer run copyenvfor default development` wordt gedraaid. \
  Mocht je een andere `CLIENT_NAME` en/of `ENVIRONMENT` willen gebruiken, dan kun je de waardes aanpassen in de `.env` van _dockerized-z_.
* zWaste wordt geïnstalleerd (`composer install`, `npm ci`, `artisan migrate`)
* De zWaste database wordt gevuld met wat bruikbare data (`artisan db:seed`, `artisan script:run scripts/init_opzet.script`)

Een overzicht van de meest gebruikte `make` commando's vind je onder ['Make commands'](#make-commands)

### Optioneel:
Om niet steeds `docker compose run --rm` te hoeven gebruiken bij het aanroepen van Composer, Artisan of NPM kun je het bestand `aliases.txt` gebruiken. \
In de Terminal, typ `. ./aliases.txt` en voor de duur van je Terminal-sessie kun je de container versies van Composer, Artisan of NPM direct aanroepen, \
voorbeeld:
```shell
user@My-Device dockerized-z % artisan optimize:clear # in plaats van
user@My-Device dockerized-z % docker compose run --rm artisan optimize:clear
```

## Benodigdheden:
* Voorlopig worden alleen _Apple Macs_ ondersteund.
* _GitHub_: Check deze repository uit (als je dit leest heb je deze stap waarschijnlijk al gedaan): https://github.com/opzetrob/dockerized-z.git
* [Docker Desktop](https://www.docker.com/products/docker-desktop/) geïnstalleerd en draaiend op je systeem. De installatiehandleiding vind je hier: [Mac](https://docs.docker.com/desktop/install/mac-install/), [Windows](https://docs.docker.com/desktop/install/windows-install/), [Linux](https://docs.docker.com/desktop/install/linux-install/)
* [Homebrew](https://brew.sh) geïnstalleerd en draaiend op je systeem. Voor installatie op _Windows_ of _Linux_, [check hier](https://docs.brew.sh/Homebrew-on-Linux).\
  Om te verifiëren of Homebrew al geïnstalleerd is op je systeem open je een nieuw _Terminal_-venster en run je het commando `brew -v`, \
  als alles goed is gegaan zul je ongeveer de onderstaande response zien:
```shell
user@My-Device my-dir % brew -v
Homebrew 4.2.7
user@My-Device my-dir %
```
- Een _Subversion_ client, eventueel geïnstalleerd via Homebrew met commando: `brew install subversion` \
  Om te verifiëren, run: `svn --version`
- ~~[CHECKEN] _Openssl_, eventueel geïnstalleerd via Homebrew met commando: `brew install openssl@3` \
  Om te verifiëren, run: `openssl -v`~~
- `mkcert` mkcert is een simpele tool voor het maken van locally-trusted development certificaten. Er is geen configuratie nodig.
```shell
user@My-Device my-dir % brew install mkcert
user@My-Device my-dir % brew install nss # als je gebruik maakt van Firefox
user@My-Device my-dir % mkcert -install
```
- Meer..?

## Make commands
* `make`: Volledige installatie van site en database. Gebruik dit als je een nieuwe site wilt beginnen
* `make install`: Installatie zonder de stappen `migrate` en `seed`
* `make migrate`: Voert een _migratie_ van de database uit
* `make seed`: Voert een _seed_ van de database uit, de stap `migrate` wordt eerst aangeroepen
* `make clean`: Verwijdert de certificaten, zet de waarde van `DB_HOST` terug naar `localhost`, stopt en verwijdert de gebruikte Docker _containers_, _images_ en _volumes_
