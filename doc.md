## =============== FIIT Exchanger Project ===============		       
###  	      @authors: Mykhailo Sichkaruk // Vadym Tilihuzov     
## =============================================

## Otazky
1. Vysvetlite, prečo pridávanie a odoberanie likvidity na vašej burze nezmení výmenný kurz.


- Pridaním alebo odobratím likvidity sa výmenný kurz nezmení, pretože výmenný kurz je určený vzorcom konštantného súčinu $x * y = k$, a nie pomerom tokenov v poole.
Keď do poolu pridáme likviditu, pridáme rovnakú hodnotu oboch tokenov, čo znamená, že hodnota x a y vo vzorci súčinu sa zvýši o rovnakú hodnotu, pričom súčin $x * y = k$ zostane konštantný.
Podobne, keď likviditu z poolu odoberáme, odoberáme rovnakú hodnotu oboch tokenov.


2. K bonusu - Vysvetlite svoju schému odmeňovania poskytovateľov likvidity a zdôvodnite rozhodnutia o dizajne, ktoré ste urobili. Ako spĺňa požiadavky na odmeny za likviditu uvedené v sekcii 7?

- _podiel je absolútny objem vlastníctva výmeny, jeho vydelením celkovým počtom podielov môžete získať relatívne vlastníctvo (persentage) fondu._

- Keď pridávate likviditu, získavate podiel z fondu. Každá výmena(swap) zvyšuje množstvo tokenov v poole, a tým aj absolútnu hodnotu pre držiteľov podielov.  
Pri výbere prostriedkov z poolu sa vypočíta cena $share$ za $ETH$ a na základe tejto ceny vám vrátime $ETH$ v súvislosti s $share$, ktore mate, takisto poratame cenu $share$ za $ERC20$ a na základe tejto ceny vám vrátime $ERC20$.

- Keď sa vám vráti likvidita, vypočítame nové k na základe nových zostatkov.
> Pozor, tu sa používajú dva neurčité pojmy *SHARE* a *SHARES *.   
SHARE - je relatívne číslo vašej časti celého fondu, napríklad 30 %, 9 % atď.  
SHARES - je absolútna hodnota vášho počítateľného bodu, ktorý predstavuje vlastníctvo nad fondom.   
Napríklad ste získali 10 SHARES z celkového počtu 100 - potom je váš SHARE 10 %. 
- Keď získate späť svoju likviditu, vypočítame váš podiel na fonde. A svoj podiel dostanete späť z ETH a tokenov. 



3. Popíšte aspoň jednu metódu, ktorú ste použili na minimalizáciu spotreby gas pri kontrakte burzy. Prečo bola táto metóda efektívna?

- Používanie krátkych reťazcov v kontrolách revert a require.
- Vyhnut sa nadbytočným kontrolám.
- Používat menej operacií, pouzivat menej pamate/premennych.


4. Voliteľná spätná väzba:

4a. Koľko času ste strávili na zadaní?
- Dva dni.


4b. Aká je jedna vec, ktorá by bola užitočná, keby ste ju vedeli predtým ako ste začali pracovať na zadaní 2?

- ako funguje burza a všetky jeho zložitosti, napriklad fee atd., a ako funguje zabezpečenie v Solidity.

4c. Keby ste mohli zmeniť jednu vec v tomto zadaní, čo by to bolo?

- **Dorobil by som tak, aby exchange.createPool(), tak aby som dal akcie aj tvorcovi, prvemu Userovi. Nie je to fér v zadani.**


4d. Prosím pridajte nám akýkoľvek feedback alebo spätnú väzbu, ktorý máte na mysli alebo na srdci 😊.

## Zaver
 - Naucili sme sa pisat smart kontrakty v Solidity. Dozvedeli sme sa, ako funguje distribovana burza a ako funguje výmena tokenov z fee. Co je impermanent loss a ako zarabat na burze.

 - Nase resenie splna zakladne podmienky a pridali sme funkcionalitu vo forme fee a schému odmeňovania poskytovateľov likvidity.

### Zmeneno:

- Obnovili sme index.html (pridane: eth / token balance), exchange.js (bola pridana podpora funkcii zo html na zobrazenie balance)