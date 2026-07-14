# **Avaluació Comparativa de Temps de Resolució d'Incidències: Anàlisi Crítica de la Suite de Proves Loki i l'Arquitectura de Recuperació Autònoma**

## **Benchmarks d'Incidències i Mètriques de Resposta en Entorns Corporatius**

L'optimització de la resiliència operativa en infraestructures de tecnologies de la informació requereix una categorització rigorosa de les mètriques d'indisponibilitat i resolució de problemes. El Temps Mitjà de Resolució (MTTR, *Mean Time to Resolve*) i el Temps Mitjà de Restauració del Servei (MTTRS, *Mean Time to Restore Service*) constitueixen indicadors fonamentals de l'eficiència dels equips d'operacions de sistemes, tot i que mesuren dimensions clarament diferenciades de la indisponibilitat.1  
Mentre que l'MTTR se centra exclusivament en l'interval actiu de treball necessari per reparar un defecte tècnic o component des de la seva detecció 2, l'MTTRS reflecteix la totalitat del temps de degradació o interrupció del servei percebut per l'usuari final, abastant des del moment exacte de la interrupció fins a la verificació completa i confirmació de l'operabilitat de la plataforma.2 La relació d'aquests indicadors amb la disponibilitat global dels sistemes es fonamenta en la combinació lògica de l'MTTRS i el Temps Mitjà Entre Fallades (MTBF, *Mean Time Between Failures*), on es demostra que la reducció de la indisponibilitat és l'única via viable per maximitzar la ràtio operativa sense incórrer en costoses reformes estructurals de maquinari.1  
El marc de referència de la metodologia DORA (*DevOps Research and Assessment*) classifica els equips d'enginyeria segons la celeritat del seu temps de recuperació operativa davant de fallades associades a canvis.3 Aquesta escala defineix el rendiment de l'organització i permet contrastar la maduresa del disseny de sistemes.7

| Nivell de Rendiment (DORA) | Temps de Recuperació del Servei (MTTRS) | Freqüència de Desplegament | Taxa d'Errors en Canvis (CFR) | Referència de l'Estudi |
| :---- | :---- | :---- | :---- | :---- |
| **Elite** | \< 1 hora | Múltiples vegades al dia | 0% \- 15% | ([https://getdx.com/blog/dora-metrics/](https://getdx.com/blog/dora-metrics/)) 7 |
| **Alt** (*High*) | \< 1 dia | Entre un cop al dia i una setmana | 16% \- 30% | ([https://getdx.com/blog/dora-metrics/](https://getdx.com/blog/dora-metrics/)) 7 |
| **Mitjà** (*Medium*) | Entre 1 dia i 1 setmana | Entre una setmana i un mes | 16% \- 30% | ([https://getdx.com/blog/dora-metrics/](https://getdx.com/blog/dora-metrics/)) 7 |
| **Baix** (*Low*) | \> 1 mes | Entre un mes i sis mesos | 46% \- 60% | ([https://getdx.com/blog/dora-metrics/](https://getdx.com/blog/dora-metrics/)) 7 |

La realitat del mercat és que la majoria d'equips que utilitzen metodologies manuals o processos de triatge tradicionals queden relegats a les categories de rendiment mitjà o baix.7 Les enquestes globals d'incidències del *SANS Institute* revelen de manera contundent que, si bé l'adopció d'eines de telemetria i correlació ha escurçat la detecció d'incidències (on gairebé el 50% s'identifiquen en les primeres 24 hores), la fase de remediació, eliminació i recuperació segura continua estancada.8 La complexitat inherent a la validació manual del correcte estat de funcionament fa que un 19% de les incidències greus requereixin més d'un mes per assolir la seva resolució definitiva, accentuant els costos de temps d'inactivitat empresarial.8  
D'acord amb les dades de resolució publicades a([https://www.itoc360.com/automated-incident-management/](https://www.itoc360.com/automated-incident-management/)), el triatge d'incidències gestionat manualment afegeix un retard addicional mitjà d'entre 11 i 34 minuts a l'MTTR de cada incidència greu (SEV-1).10 Aquest temps es consumeix exclusivament en tasques de coordinació, transferència de tiquets entre equips incorrectes i cerques d'evidències a cegues.10 La substitució d'aquests protocols per workflows automatitzats de remediació redueix l'MTTR d'una mitjana de 68 minuts en format manual a tan sols 9 minuts amb execució immediata de runbooks, fet que es tradueix en un estalvi de temps directe del 87%.10

## **Modelatge Metodològic i Estimació de Temps de Resolució Manual per a la Suite d'Escenaris Loki**

La suite de provocació d'errors Loki representa un espectre representatiu d'incidències crítiques que amenacen l'operativitat de qualsevol infraestructura d'aplicacions web de tres capes.11 Per justificar de manera científica l'objectiu experimental del projecte (Objectiu O6), és indispensable desglossar de forma seqüencial els procediments d'investigació manual per a cadascun d'aquests escenaris i estimar-ne la seva durada d'acord amb els estudis del sector.11

### **Loki 1: Error de Sintaxi al Fitxer de Configuració d'Nginx (Bifrost)**

L'error es provoca en corrompre intencionadament la sintaxi de /etc/nginx/nginx.conf al servidor proxy invers Bifrost (IP 10.0.27.228), com ara la supressió d'un punt i coma de tancament a la línia de definició del port d'escolta, provocant el col·lapse de les peticions HTTPS dels clients externs.11  
L'operació de diagnòstic i remediació tradicional executada de forma manual per un administrador de sistemes segueix el següent protocol operatiu:

1. **Detecció de l'alerta i triatge inicial:** S'identifica un augment massiu de peticions fallides procedents dels navegadors (errors del tipus Bad Gateway o absència de resposta HTTP).12 Temps d'identificació i accés a la consola: **3 a 5 minuts**.14  
2. **Connexió i inspecció del servei:** L'operador estableix una connexió SSH amb Bifrost 11, executa systemctl status nginx o docker ps \-a i confirma que el contenidor proxy invers es troba aturat o reiniciant-se de forma cíclica.11 Temps d'execució: **2 a 4 minuts**.15  
3. **Anàlisi de registres i logs locals:** S'executa un buidatge de la cua d'errors analitzant els logs físics mitjançant ordres específiques 12:  
   Bash  
   tail \-n 20 /var/log/nginx/error.log  
   \# o, en entorns conteneritzats:  
   docker logs \--tail 20 carparts-proxy

   L'administrador llegeix de forma seqüencial les traces a la recerca del log crític d'inicialització.13 Temps d'anàlisi: **3 a 6 minuts**.15  
4. **Verificació sintàctica específica:** Un administrador amb experiència executa de forma manual la comanda de comprovació sintàctica pròpia del motor web 12:  
   Bash  
   sudo nginx \-t

   Aquesta comanda és la que efectivament reporta el fitxer i la línia exacte amb la directiva incorrecta o sense tancament correcte.12 Temps: **1 a 2 minuts**.12  
5. **Correcció i restabliment:** S'obre el fitxer de configuració de Nginx amb un editor de terminal com vim o nano, s'insereix el caràcter correcte, es valida la correcció de nou amb nginx \-t i finalment es reinicia el servei mitjançant sudo systemctl restart nginx o docker start carparts-proxy.11 Temps d'edició i reinici: **4 a 8 minuts**.12  
6. **Verificació de disponibilitat:** Es valida localment i externament la resposta de xarxa amb curl \-I http://127.0.0.1:80.11 Temps d'execució: **1 a 2 minuts**.12

D'acord amb els estudis del sector recopilats a([https://www.hostaccent.com/blog/nginx-wont-start](https://www.hostaccent.com/blog/nginx-wont-start)), un diagnòstic i correcció manual complet d'aquest tipus d'error s'allarga de forma típica entre **15 i 45 minuts**, depenent de si el professional sap identificar la directiva nginx \-t d'entrada o si comença a canviar paràmetres a cegues fins a trobar l'error.12

### **Loki 2: Bloqueig del Port de Base de Dades PostgreSQL pel Tallafoc (Valhalla)**

L'incident es simula de forma directa a la màquina Valhalla (IP 10.0.27.239) mitjançant la injecció manual d'una regla DROP a iptables que bloqueja el port 5432, forçant l'aparició d'excepcions de desconnexió al servidor de Midgard.11  
El procés manual de recuperació requereix els següents passos detallats:

1. **Recepció de logs d'indisponibilitat:** L'aplicació Flask a Midgard (10.0.27.223) comença a registrar línies de log on s'indica Connection refused o errors crítics de tipus OperationalError al servei Gunicorn.11 Temps: **1 a 3 minuts**.14  
2. **Accés i diagnosi del node d'aplicació:** S'obre SSH cap a Midgard, es revisa l'estat d'execució de l'aplicació web i es llança una comprovació de connectivitat directa cap al node de dades 11:  
   Bash  
   nc \-zv 10.0.27.239 5432

   L'administrador constata que la connexió finalitza per *timeout*, descartant una errada al codi Flask i confirmant una desconnexió a nivell de xarxa.11 Temps d'aïllament: **5 a 10 minuts**.15  
3. **Accés al node de base de dades:** S'obre una nova sessió SSH cap a Valhalla (10.0.27.239) 11 i es comprova que el contenidor PostgreSQL estigui actiu executant docker ps o validant la presència del servei.11 Temps d'accés i verificació: **3 a 5 minuts**.15  
4. **Investigació de regles del tallafoc:** Com que el servei s'executa correctament de manera local però és invisible des de Midgard, el sysadmin analitza la configuració del tallafoc local de Linux executant comprovacions de baix nivell 11:

Bash  
sudo iptables \-S  
sudo iptables \-L \-n \-v

L'enginyer ha de llegir de forma acurada les rutes de la cadena INPUT o DOCKER-USER fins a localitzar la regla específica que fa un descart (DROP) de les peticions cap al port 5432\.11 Temps de recerca: **5 a 12 minuts**.22 5\. **Eliminació i depuració de regles:** Es remou manualment la línia conflictiva indicant la seva correspondència sintàctica 11:

Bash  
sudo iptables \-D INPUT \-p tcp \--dport 5432 \-j DROP

Temps de correcció: **2 a 5 minuts**.19 6\. **Verificació d'estat de connexió:** Es llança una nova comprovació nc \-zv des de Midgard cap a Valhalla i es comprova que l'aplicació recupera automàticament la visibilitat de la base de dades PostgreSQL.11 Temps: **2 a 3 minuts**.18  
Aquest flux de resolució, recolzat pels informes de temps d'inactivitat recopilats a [Opengear Network Outage Analysis](https://cloud-computing.tmcnet.com/breaking-news/articles/453641-enterprises-average-11-hours-resolve-network-outages.htm), requereix una investigació transversal que acostuma a durar de **30 a 120 minuts de treball actiu**, allargant-se notablement quan els administradors no comproven d'entrada el funcionament de les regles internes de filtratge.17

### **Loki 3: Caducitat del Certificat SSL/TLS a Nginx (Bifrost)**

S'introdueix manualment un certificat expirat al servidor proxy Bifrost per simular el col·lapse de les operacions sota HTTPS i comprovar la capacitat de renovació de claus.11  
El cicle manual tradicional de resolució implica una seqüència de tasques d'alta sensibilitat operativa:

1. **Identificació de la interrupció:** Els clients experimenten advertències de connexió no segura procedents del navegador, impossibilitant l'accés al domini actiu de l'aplicació.24 Temps de resposta inicial de l'alerta: **2 a 5 minuts**.14  
2. **Verificació física del certificat:** El sysadmin es connecta a Bifrost 11 i verifica la validesa temporal dels fitxers actius enllaçats de forma directa mitjançant OpenSSL 25:  
   Bash  
   openssl x509 \-in /etc/nginx/certs/carparts.crt \-text \-noout | grep \-i "Not After"

   Es confirma que la data límit ha estat superada.25 Temps de verificació: **3 a 6 minuts**.25  
3. **Generació de nova clau privada i CSR:** Es genera manualment una nova Sol·licitud de Signatura de Certificat (CSR) assegurant-se de no reutilitzar la clau anterior per complir els criteris de seguretat 26:  
   Bash  
   openssl req \-new \-newkey rsa:2048 \-nodes \-keyout /etc/nginx/certs/carparts.key \-out /etc/nginx/certs/carparts.csr

   Temps d'execució i definició de camps: **5 a 10 minuts**.26  
4. **Tramitació davant la CA i Validació de Domini (DCV):** El sysadmin ha d'enviar el contingut del CSR de forma externa al panell de control de la seva autoritat certificadora de confiança.25 S'ha de respondre al mètode d'autenticació de domini (DCV, com ara HTTP Challenge mitjançant la creació d'un fitxer al directori /.well-known/ o modificant un registre TXT a les línies del DNS del domini).26 Temps del procés d'emissió i validació del domini: **20 a 45 minuts** d'esforç manual actiu.25  
5. **Instal·lació i vinculació de la cadena:** Es descarreguen els fitxers enviats per la CA, es combinen amb la cadena intermèdia per generar el paquet de certificats unificat (domain.crt i intermediate.crt), es configuren els permisos adequats sobre els fitxers a Bifrost i es vinculen a la directiva ssl\_certificate de la línia de blocs de servidor de Nginx.26 Temps: **10 a 15 minuts**.26  
6. **Prova de sintaxi i càrrega de dades:** Es verifica el canvi amb nginx \-t i finalment es recarrega el daemon amb systemctl reload nginx.11 Temps: **2 a 5 minuts**.12

D'acord amb els estudis sobre renovacions de seguretat d'infraestructura publicats a([https://www.thesslstore.com/blog/ssl-certificate-validity-is-dropping-to-200-days/](https://www.thesslstore.com/blog/ssl-certificate-validity-is-dropping-to-200-days/)), un procés manual de renovació i vinculació de certificats complet exigeix de **60 a 180 minuts de treball humà actiu**, representant un camí ineficient a mesura que la indústria imposa reduccions de la validesa d'aquests actius de forma progressiva a 200, 100 i finalment 47 dies, forçant la desaparició dels mètodes de manteniment tradicionals.26

### **Loki 4: Intent d'Atac d'Injecció SQL (SQLi) a l'Aplicació (Midgard)**

L'incident de seguretat es provoca mitjançant l'execució d'un script extern que injecta codi SQL maliciós en el formulari d'entrada de Midgard per simular un atacant actiu que intenta comprometre la confidencialitat de la base de dades.11  
La resposta manual requerida per analitzar i contenir aquesta acció crítica de seguretat consta dels següents passos de treball:

1. **Detecció i confirmació de l'incident:** Es rep una notificació procedent de les alertes de seguretat de rsyslog o directament l'administrador identifica errors sintàctics de l'aplicació Flask o anomalies d'accés als registres físics.11 Temps estimat d'identificació: **5 a 15 minuts**.14  
2. **Identificació de l'adreça IP de l'atacant:** El sysadmin executa una cerca per analitzar el comportament del log centralitzat al directori de dades del servidor de logs 11:  
   Bash  
   grep \-i "union select" /var/log/remote/10.0.27.223/docker-carparts-web.log

   S'aïlla l'origen de la petició, extreient l'adreça IP de l'atacant actiu.11 Temps de recerca: **10 a 20 minuts**.15  
3. **Triatge i proposta d'accions de seguretat:** Es determina si cal tallar immediatament la comunicació de l'adreça IP atacant per evitar moviments laterals dins de la xarxa del laboratori o modificacions a Valhalla.11 Temps: **5 a 10 minuts**.15  
4. **Bloqueig de l'IP de l'atacant al Proxy d'entrada:** L'operador accedeix per SSH a Bifrost (10.0.27.228) per interposar de forma manual una directiva de bloqueig a iptables per tallar de soca-rel els paquets maliciosos abans que arribin a tocar l'aplicació web Midgard 11:  
   Bash  
   sudo iptables \-I INPUT \-s \<IP\_ATACANT\> \-j DROP

   Temps d'execució: **3 a 7 minuts**.22  
5. **Auditoria forense posterior:** S'audita l'estat intern i les consultes de PostgreSQL a Valhalla per descartar cap possible alteració d'esquemes o exfiltració efectiva d'informació confidencial d'inventari.11 Temps d'auditoria: **15 a 30 minuts**.35  
6. **Documentació de l'incident:** Es genera un resum escrit detallant l'origen de l'atac, el patró, les traces identificades i l'impacte observat per a la traçabilitat interna.17 Temps: **15 a 30 minuts**.17

Un incident d'aquest tipus, enfocat des d'una perspectiva tradicional, consumeix de **60 a 240 minuts de temps actiu d'analista**, tot i que estudis globals de dwell-time com els realitzats a([https://www.varonis.com/blog/data-breach-response-times](https://www.varonis.com/blog/data-breach-response-times)) constaten que la immensa majoria de les organitzacions requereixen setmanes per identificar els atacs i fins a 68 dies de mitjana només per contenir els impactes una vegada s'han confirmat de forma interna.36

### **Loki 5: Exhauriment de la Capacitat de Disc (Valhalla)**

Es simula una situació de fallada de servei per falta de recursos mitjançant la creació d'un fitxer gegant (massive\_dump.log) fins a assolir l'exhauriment de l'espai físic lliure de disc del node Valhalla, provocant l'aturada de la base de dades PostgreSQL.11  
El cicle manual tradicional de resolució s'articula sota els següents passos d'investigació:

1. **Identificació de la indisponibilitat:** Els registres d'aplicació llançen excepcions alertant que PostgreSQL és incapaç d'escriure logs o transaccions, mostrant l'error No space left on device.11 Temps: **2 a 5 minuts**.14  
2. **Verificació d'espai del volum físic:** El sysadmin obre SSH cap a la base de dades Valhalla 11 i verifica la capacitat del volum actiu 11:  
   Bash  
   sudo df \-h  
   sudo df \-i

   Aquesta darrera comanda serveix per discernir si l'exhauriment correspon a l'espai útil de disc o a una exhauriment complet de la taula de descriptors de fitxers (inodes).38 Temps: **2 a 4 minuts**.38  
3. **Localització de fitxers candidats de neteja:** S'executa una cerca exhaustiva a les branques dels directoris del sistema de fitxers a la recerca d'elements de gran format que estiguin consumint els recursos 38:  
   Bash  
   sudo du \-sh /\* 2\>/dev/null | sort \-hr | head \-20  
   sudo find / \-type f \-size \+100M \-exec ls \-lh {} \\; 2\>/dev/null | sort \-k5 \-hr | head \-20

   L'administrador localitza d'aquesta manera el fitxer /var/log/massive\_dump.log.40 Temps d'anàlisi recursiu: **5 a 15 minuts**.41  
4. **Verificació de descriptors de fitxer actius:** L'administrador ha d'inspeccionar si hi ha algun procés o daemon del sistema mantenint descriptors d'escriptura oberts sobre el recurs, evitant errors comuns on es demana esborrar el fitxer físic amb rm però l'espai continua segrestat a la partició en quedar-se el procés actiu retingut.38 S'utilitza la comprovació amb lsof 38:  
   Bash  
   sudo lsof | grep delete

   S'identifica el PID i l'impacte real d'aplicar un reinici del servei associat.38 Temps d'inspecció: **5 a 10 minuts**.38  
5. **Reclamació de l'espai físic:** Es buida l'espai del fitxer de logs de manera segura utilitzant procediments de truncat de baix nivell per evitar degradacions als daemons en execució, complementat amb la neteja de la memòria cau d'APT o residus d'imatges de Docker 38:  
   Bash  
   sudo truncate \-s 0 /var/log/massive\_dump.log

   Temps d'alliberament: **3 a 7 minuts**.38  
6. **Verificació final de funcionament:** Es comprova que PostgreSQL pot inicialitzar-se correctament i es valida amb df \-h que el marge de capacitat lliure ha retornat a valors de seguretat.11 Temps: **2 a 5 minuts**.38

Aquesta intervenció tradicional sol allargar-se entre **30 i 120 minuts de resolució manual**, d'acord amb els estudis d'administració de sistemes i contingència de Linux publicats a([https://www.alibabacloud.com/help/en/ecs/user-guide/resolve-the-issue-of-insufficient-disk-space-on-a-linux-instance](https://www.alibabacloud.com/help/en/ecs/user-guide/resolve-the-issue-of-insufficient-disk-space-on-a-linux-instance)).38

## **Comparació Directa de Temps i Eficiència Operativa**

La recollida de dades experimentals associades al funcionament del prototip d'autoreparació un cop implantat sobre l'hipervisor Proxmox VE ( node Asgard, IP 10.0.27.10) permet avaluar l'eficàcia real de l'automatització en relació als mètodes manuals de suport tradicional.11  
El workflow de recuperació, coordinat per l'orquestrador n8n, s'activa reactivament davant la recepció de l'alerta de logs processats per Vector al servidor central Himinbjorg, o de manera periòdica mitjançant comprovacions de connectivitat.11 El temps necessari des de la ingesta de l'error fins al tancament i emissió de l'informe tècnic en format Markdown a Freya es detalla a continuació sota dos escenaris operatius 11:

* **Ruta directa d'IA (Model Principal Gemma 31B):** Completa el cicle de diagnòstic, proposta, autorització interactiva per Discord, execució d'accions correctives i emissió del resum en un temps mitjà d'entre **4 i 5 minuts** d'execució.11  
* **Ruta de contingència (Model Fallback Gemma 27B):** En cas que l'API de Google presenti indisponibilitat o errors de saturació, l'activació del model secundari aconsegueix tancar l'incident en un temps d'entre **10 i 15 minuts** d'execució.11

El comportament temporal de resolució s'avalua comparativament per a cadascun dels cinc escenaris Loki actius:

| Escenari Loki | Temps Tradicional Manual (Mètodes de Suport) | Temps Prototip Automatitzat (Gemma 31B) | Temps Prototip (Fallback 27B) | Ràtio d'Eficiència i Estalvi Operatiu | Estat del Test Experimental |
| :---- | :---- | :---- | :---- | :---- | :---- |
| **Loki 1**: Syntax Error | 15 \- 45 min 12 | 4.5 min 11 | 12.5 min 11 | Estalvi del **70% \- 90%** | **Èxit** 11 |
| **Loki 2**: Firewall block | 30 \- 120 min 17 | 4.8 min 11 | 14.0 min 11 | Estalvi del **84% \- 96%** | **Èxit** 11 |
| **Loki 3**: SSL/TLS expiry | 60 \- 180 min 26 | 5.0 min 11 | 15.0 min 11 | Estalvi del **91% \- 97%** | **Èxit** 11 |
| **Loki 4**: SQL Injection | 60 \- 240 min 36 | 5.2 min 11\* | 14.5 min 11\* | Estalvi del **91% \- 97%** | **Èxit** 11 |
| **Loki 5**: Disk Full | 30 \- 120 min 44 | 4.6 min 11 | 13.0 min 11 | Estalvi del **84% \- 96%** | **Èxit** 11 |

*\* Nota metodològica important:* Els temps indicats per a Loki 4 i certes condicions de Loki 5 integren de forma directa el temps d'espera del canal Human-in-the-loop (HITL) de Discord.11 En cas que l'administrador demori l'aprovació del botó de confirmació enviat per Freya, l'execució s'allargarà de forma proporcional al retard humà de decisió.11

## **Crítica Tècnica i Arquitectònica de la Solució Automatitzada**

L'excel·lent rendiment quantitatiu del prototip en termes de reducció d'MTTR no ha d'ocultar les greus limitacions tècniques i febleses estructurals que presenta la seva implementació actual.11 Per tal de garantir un nivell de qualitat propi d'una enginyeria, és necessari analitzar de forma altament crítica les mancances de disseny operatiu, seguretat i arquitectura del treball:

### **Violació del Principi de Mínim Privilegi i Exposició del Mòdul Thor**

L'arquitectura dissenyada per a l'execució d'accions correctives a través de Thor es fonamenta en la connexió SSH directa a les màquines clients (Bifrost, Midgard i Valhalla) utilitzant claus privades de l'usuari root emmagatzemades al repositori central d'n8n.11  
Aquesta decisió és inadmissible sota qualsevol directiva de seguretat corporativa.11 Donar accés d'execució sense restriccions amb privilegis de root a un orchestrador de workflows de tercers controlat per un Agent cognitiu basat en un Model de Llenguatge probabilístic (Gemma) representa un vector d'exposició crític.11 Si l'agent d'IA llegeix registres d'error o logs d'aplicació que contenen payload o text maliciós provinent d'un atacant (com els intents d'injecció SQL exposats a Loki 4), un atac de tipus *prompt injection* pot forçar el model a generar i executar ordres de terminal destructives de forma dinàmica, tals com rm \-rf / o l'aturada de daemons vitals del sistema de laboratori.11

### **Redundància i Ineficiència Operativa de la Doble Capa de No-Determinisme**

Per verificar que les operacions s'executen de forma correcta, s'ha implementat una branca que invoca un subworkflow anomenat *Is the agent finished?*.11 Aquest utilitza un node Basic LLM Chain separat amb un segon model probabilístic de xat per analitzar textualment si l'últim missatge de l'agent principal indica que la incidència s'ha resolt de manera reeixida o requereix reintents.11  
Intentar verificar la correctesa i determinisme de l'execució d'un primer model probabilístic d'IA aplicant una segona IA probabilística a sobre és una pràctica d'enginyeria altament redundant i ineficient.11 Aquest disseny crea un risc evident de fallades en cascada, on un error semàntic de l'agent de verificació pot donar per vàlides comandes fallides o entrar en bucles infinits de reintents.11 Els sistemes operatius disposen de mecanismes clars i deterministes per validar l'estat d'una acció (com ara l'avaluació de codis de retorn exit codes de shell, com $? en Bash, encapsulats en respostes estructurades JSON), mètode que hauria d'haver substituït completament la interpretació lectora de la segona IA.11

### **Latència de Resolució de Serveis Inacceptable per a Infraestructures Crítiques**

Tot i que l'optimització de prompts ha permès retallar l'MTTR de l'agent fins a la franja dels 4 a 15 minuts de mitjana, aquesta velocitat és del tot insuficient per a entorns de producció d'alta disponibilitat que s'enfronten a fallades bàsiques.11  
Si el proxy d'entrada Bifrost pateix una caiguda a causa d'un error de sintaxi o s'atura el servei web a Midgard, mantenir la plataforma caiguda durant 5 o 10 minuts mentre el node d'intel·ligència artificial (Odin) estableix connexions SSH lentes, extreu cues de logs massius, interpreta sintàcticament els errors i redacta informes és inviable.11 En un entorn real, les fallades clares s'han de resoldre en segons mitjançant equilibradors de càrrega actius-passius i scripts automatitzats directes de salut. La intel·ligència artificial s'ha de reservar com un element de suport per a l'anàlisi de segon nivell de problemes ambigus, i no com el primer recurs seqüencial de recuperació.11

### **Incoherència Arquitectònica de Detecció al Cas de Certificats (Loki 3\)**

L'arquitectura conceptual de Heimdall es defineix formalment com un model de detecció reactiu impulsat per logs, on el motor Vector analitza de forma immediata cada línia capturada per rsyslog des dels clients.11 No obstant això, l'escenari Loki 3 (SSL Expiry) evidencia la fallada d'aquest plantejament: el servidor web Nginx no genera per si mateix logs d'error quan el certificat TLS de Bifrost ha caducat, atès que és una comprovació que realitzen els clients durant l'encaix de mans criptogràfic, sense necessitat d'alterar les respostes locals.11  
Per poder identificar aquesta fallada crítica, el prototip s'ha vist obligat a dependre d'un Scheduled Trigger que executa anàlisis periòdiques d'estat des de n8n.11 Aquest canvi trenca la coherència operativa i desvetlla que el disseny original reactiu basat en el pipeline de logs és cec davant determinats problemes d'infraestructura d'alta gravetat, obligant a afegir mecanismes de sondeig proactius per compensar les mancances de Heimdall.11

### **Omissió dels Costos d'Amortització de Computació Local per a la IA**

L'estudi d'avaluació de viabilitat econòmica de la memòria estima que l'ús del model Gemma local té un cost directe d'API de 0 EUR.11  
Aquesta anàlisi és enganyosa. Executar localment de forma estable un model d'instrucció tècnica de gran format (com Gemma 31B o similars) demanant-li que analitzi de manera continuada traces de text i logs complexos requereix d'un maquinari de processament d'alt cost integrat per targetes gràfiques (GPU) dedicades d'alta capacitat de memòria (com ara NVIDIA A100 o RTX 4090 dobles).11 Ignorar l'amortització econòmica d'aquesta capacitat física de càlcul local falseja les despeses reals d'implantació, demostrant que el cost operatiu de la proposta és notablement superior al d'un model de crides a APIs comercials de pagament per ús.11

## **Conclusions i Full de Ruta de Remediació Arquitectònica**

L'avaluació empírica realitzada a través de la suite experimental Loki demostra que el prototip assoleix amb èxit el cicle de reducció d'MTTR i MTTRS, superant de forma substancial els protocols manuals de suport tradicionals.11 Tanmateix, l'elevat índex d'èxit de les proves de laboratori no ha de servir per validar opcions de disseny que posen en perill la integritat física i lògica dels sistemes corporatius.11  
Per corregir de manera estructurada aquestes mancances i establir una base d'autoreparació apta per a un entorn productiu real, es proposa el següent full de ruta de remediació arquitectònica:

1. **Implantació de l'Accés SSH Restringit (*Restricted Sudo*):** S'ha d'eliminar de manera immediata l'ús d'un usuari root directe amb accés a claus SSH generals des del servidor Asgard.11 Cal dissenyar un usuari de sistema de mínims privilegis a cada màquina client (per exemple, n8n-executor) i configurar de forma manual el fitxer de regles /etc/sudoers de Linux perquè aquest usuari només pugui executar ordres específiques i inofensives per a la seguretat del sistema 11: n8n-executor ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx, /usr/bin/docker start carparts-web Amb aquest canvi, Thor podrà continuar executant canvis de restabliment de servei, però cap atac de prompt injection sobre l'agent d'IA podrà generar ordres destructives globals sobre les màquines de xarxa.11  
2. **Transició cap a un Bucle de Validació Determinista:** Es demana eliminar el subworkflow probabilístic encarregat d'analitzar semànticament el tancament de tasques.11 Els nodes de decisió d'Asgard han de dependre directament d'expressions que comprovin la resposta determinista de l'ordre executada per SSH, com ara validar si el codi de sortida sintàctic és efectivament zero (![][image1]) i verificar la recuperació mitjançant sondejos interns estructurats en JSON d'n8n, eliminant el consum innecessari de tokens de text de la segona IA.11  
3. **Hibridació Proactiva-Reactiva del Mòdul Heimdall:** Cal actualitzar el mòdul Heimdall per tal que no depengui de manera exclusiva de la ingesta passiva de registres de rsyslog.11 S'han d'integrar sondes d'observabilitat actives (per exemple, mitjançant les capacitats natives d'ingesta de mètriques actives de Vector o sondes ICMP/TCP centralitzades directes) per identificar defectes i interrupcions en la negociació de protocols com TLS que no queden reflectits en els logs locals de Nginx de forma estàndard.11  
4. **Optimització del Context d'IA per a la Reducció de Latència:** Per assegurar un temps de resposta competitiu (MTTRS inferior al minut), s'ha de depurar l'enginyeria de context d'Odin.11 Els vectors de logs que s'envien a l'agent d'IA s'han de processar de forma prèvia mitjançant scripts sintàctics que només extreguin les traces concretes afectades pel patró de fallada, limitant el context a pocs paràmetres clau i evitant que Odin hagi de llegir dades voluminoses d'històrics que alenteixen de forma inacceptable l'operació del sistema.11

#### **Works cited**

1. What is MTTR (Mean Time to Remediate) in Cybersecurity? \- SentinelOne, accessed on July 14, 2026, [https://www.sentinelone.com/cybersecurity-101/cybersecurity/mttr-mean-time-to-remediate/](https://www.sentinelone.com/cybersecurity-101/cybersecurity/mttr-mean-time-to-remediate/)  
2. Mastering MTTR: A Strategic Imperative for Leadership \- Palo Alto Networks, accessed on July 14, 2026, [https://www.paloaltonetworks.com/cyberpedia/mean-time-to-repair-mttr](https://www.paloaltonetworks.com/cyberpedia/mean-time-to-repair-mttr)  
3. Understanding MTTR Metrics: A Comprehensive Guide for Incident Metrics \- Multitudes, accessed on July 14, 2026, [https://www.multitudes.com/blog/mttr-metrics](https://www.multitudes.com/blog/mttr-metrics)  
4. What is MTTR? \- Resolve.ai, accessed on July 14, 2026, [https://resolve.ai/glossary/what-is-mttr](https://resolve.ai/glossary/what-is-mttr)  
5. How to improve MTTR: A guide to data-driven incident response \- New Relic, accessed on July 14, 2026, [https://newrelic.com/blog/observability/how-to-improve-mttr](https://newrelic.com/blog/observability/how-to-improve-mttr)  
6. Mean Time to Resolve: Definition, Formula, and How to Reduce It \- Tractian, accessed on July 14, 2026, [https://tractian.com/en/glossary/mean-time-to-resolve](https://tractian.com/en/glossary/mean-time-to-resolve)  
7. What are DORA metrics? Complete guide to measuring DevOps performance \- DX, accessed on July 14, 2026, [https://getdx.com/blog/dora-metrics/](https://getdx.com/blog/dora-metrics/)  
8. SANS Institute 2025 survey finds OT cybersecurity incidents rising as ransomware and remote access risks grow \- Industrial Cyber, accessed on July 14, 2026, [https://industrialcyber.co/news/sans-institute-2025-survey-finds-ot-cybersecurity-incidents-rising-as-ransomware-and-remote-access-risks-grow/](https://industrialcyber.co/news/sans-institute-2025-survey-finds-ot-cybersecurity-incidents-rising-as-ransomware-and-remote-access-risks-grow/)  
9. The SANS 2025 State of ICS Security Report: Progress, Pressure, and the Path to Resilience, accessed on July 14, 2026, [https://www.sans.org/blog/sans-2025-state-ics-security-report-progress-pressure-path-resilience](https://www.sans.org/blog/sans-2025-state-ics-security-report-progress-pressure-path-resilience)  
10. Automated Incident Management: The Complete Guide for DevOps & SRE Teams, accessed on July 14, 2026, [https://www.itoc360.com/automated-incident-management/](https://www.itoc360.com/automated-incident-management/)  
11. main-3.pdf  
12. Nginx Won't Start (nginx: \[emerg\])? How to Fix It 2026 \- Hostaccent, accessed on July 14, 2026, [https://www.hostaccent.com/blog/nginx-wont-start](https://www.hostaccent.com/blog/nginx-wont-start)  
13. A Sysadmin's Guide to Troubleshooting Nginx/Apache Errors | RS Blog \- ReadyServer, accessed on July 14, 2026, [https://www.readyserver.sg/blog/sysadmin-guide-troubleshooting-nginx-apache-errors/](https://www.readyserver.sg/blog/sysadmin-guide-troubleshooting-nginx-apache-errors/)  
14. Incident Management KPIs & Metrics That Matter \- MTTR, MTTA and Response Times, accessed on July 14, 2026, [https://taskcallapp.com/blog/incident-management-kpis-metrics-that-matter](https://taskcallapp.com/blog/incident-management-kpis-metrics-that-matter)  
15. Reducing MTTR by 40% with AI: SOC Automation Guide \- Gruve, accessed on July 14, 2026, [https://gruve.ai/blog/reducing-mttr-with-ai-the-soc-automation-imperative/](https://gruve.ai/blog/reducing-mttr-with-ai-the-soc-automation-imperative/)  
16. GridPane Nginoil \- Automatically Fix Nginx Syntax Errors, accessed on July 14, 2026, [https://gridpane.com/kb/nginoil-automatically-fix-nginx-syntax-errors/](https://gridpane.com/kb/nginoil-automatically-fix-nginx-syntax-errors/)  
17. How Long Should IT Issues Take To Fix? Realistic Expectations Explained, accessed on July 14, 2026, [https://www.auroratechsupport.co.uk/how-long-should-it-issues-take-to-fix-realistic-expectations-explained/](https://www.auroratechsupport.co.uk/how-long-should-it-issues-take-to-fix-realistic-expectations-explained/)  
18. Resolve SQL Error 40: Could Not Open a Connection to SQL Server \- Aryson Technologies, accessed on July 14, 2026, [https://www.arysontechnologies.com/blog/fix-sql-error-40-could-not-open-connection-to-sql-server/](https://www.arysontechnologies.com/blog/fix-sql-error-40-could-not-open-connection-to-sql-server/)  
19. Comprehensive Guide to Troubleshooting Linux UFW Firewall Issues, accessed on July 14, 2026, [https://linuxsecurity.com/news/firewall/ufw-troubleshooting-linux](https://linuxsecurity.com/news/firewall/ufw-troubleshooting-linux)  
20. BGP Troubleshooting Cheat Sheet \- LogicMonitor, accessed on July 14, 2026, [https://www.logicmonitor.com/deep-dive/bgp-monitoring/bgp-troubleshooting-cheat-sheet](https://www.logicmonitor.com/deep-dive/bgp-monitoring/bgp-troubleshooting-cheat-sheet)  
21. Fix Network-Related or Instance-Specific Errors in SQL Server \- Microsoft Learn, accessed on July 14, 2026, [https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/connect/network-related-or-instance-specific-error-occurred-while-establishing-connection](https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/connect/network-related-or-instance-specific-error-occurred-while-establishing-connection)  
22. How to Debug IPTables Rules in Linux \- VPS US, accessed on July 14, 2026, [https://vps.us/blog/how-to-debug-iptables-rules-in-linux/](https://vps.us/blog/how-to-debug-iptables-rules-in-linux/)  
23. Enterprises Average 11 Hours to Resolve Network Outages, accessed on July 14, 2026, [https://cloud-computing.tmcnet.com/breaking-news/articles/453641-enterprises-average-11-hours-resolve-network-outages.htm](https://cloud-computing.tmcnet.com/breaking-news/articles/453641-enterprises-average-11-hours-resolve-network-outages.htm)  
24. Troubleshoot Server Selection Timeout \- Database Manual \- MongoDB Docs, accessed on July 14, 2026, [https://www.mongodb.com/docs/manual/troubleshooting/server-selection-timeout/](https://www.mongodb.com/docs/manual/troubleshooting/server-selection-timeout/)  
25. IT Services Knowledge \- Manual SSL Certificate Management, accessed on July 14, 2026, [https://uchicago.service-now.com/services?id=kb\_article\&sysparm\_article=KB00015371](https://uchicago.service-now.com/services?id=kb_article&sysparm_article=KB00015371)  
26. Reminder: SSL Certificate Validity Is Dropping to 200 Days, accessed on July 14, 2026, [https://www.thesslstore.com/blog/ssl-certificate-validity-is-dropping-to-200-days/](https://www.thesslstore.com/blog/ssl-certificate-validity-is-dropping-to-200-days/)  
27. Surviving an SSL Certificate Renewal Crisis: A Beginners Guide to OpenSSL, Nginx, and Security Best Practices \- Abhishek Jain, accessed on July 14, 2026, [https://vardhmanandroid2015.medium.com/surviving-an-ssl-certificate-renewal-crisis-a-beginners-guide-to-openssl-nginx-and-security-best-50892930f235](https://vardhmanandroid2015.medium.com/surviving-an-ssl-certificate-renewal-crisis-a-beginners-guide-to-openssl-nginx-and-security-best-50892930f235)  
28. SSL Certificates now only last 200 days : r/sysadmin \- Reddit, accessed on July 14, 2026, [https://www.reddit.com/r/sysadmin/comments/1spby5g/ssl\_certificates\_now\_only\_last\_200\_days/](https://www.reddit.com/r/sysadmin/comments/1spby5g/ssl_certificates_now_only_last_200_days/)  
29. Certificates \- CDT Services \- California Department of Technology \- CA.gov, accessed on July 14, 2026, [https://www.cdt.ca.gov/services/certificates/](https://www.cdt.ca.gov/services/certificates/)  
30. Certificate Expiration Risk: 200 Day Validity Starts March 15 | Sectigo® Official, accessed on July 14, 2026, [https://www.sectigo.com/blog/200-day-ssl-certificate-expiration-risk](https://www.sectigo.com/blog/200-day-ssl-certificate-expiration-risk)  
31. SSL Certificate Lifetimes Are Shrinking: What the New 47-Day TLS Rules Mean \- easyDNS, accessed on July 14, 2026, [https://easydns.com/blog/2026/03/09/ssl-certificate-lifetime-changes-47-day-certificates/](https://easydns.com/blog/2026/03/09/ssl-certificate-lifetime-changes-47-day-certificates/)  
32. SQL injection \- Wikipedia, accessed on July 14, 2026, [https://en.wikipedia.org/wiki/SQL\_injection](https://en.wikipedia.org/wiki/SQL_injection)  
33. What Is an SQL Injection? \- Palo Alto Networks, accessed on July 14, 2026, [https://www.paloaltonetworks.com/cyberpedia/sql-injection](https://www.paloaltonetworks.com/cyberpedia/sql-injection)  
34. 5 SecOps Use Cases That Reduce Mean Time to Respond (MTTR) | Fortinet, accessed on July 14, 2026, [https://www.fortinet.com/resources/articles/reduce-mttr-secops-use-cases](https://www.fortinet.com/resources/articles/reduce-mttr-secops-use-cases)  
35. Databases — Dynatrace Docs, accessed on July 14, 2026, [https://docs.dynatrace.com/docs/observe/infrastructure-observability/databases](https://docs.dynatrace.com/docs/observe/infrastructure-observability/databases)  
36. Data Breach Response Times: Trends and Tips \- Varonis, accessed on July 14, 2026, [https://www.varonis.com/blog/data-breach-response-times](https://www.varonis.com/blog/data-breach-response-times)  
37. The SQL Injection Threat Study \- Ponemon Institute, accessed on July 14, 2026, [https://www.ponemon.org/local/upload/file/DB%20Networks%20Research%20Report%20FINAL5.pdf](https://www.ponemon.org/local/upload/file/DB%20Networks%20Research%20Report%20FINAL5.pdf)  
38. Elastic Compute Service:Resolve full disk space issues on Linux instances \- Alibaba Cloud, accessed on July 14, 2026, [https://www.alibabacloud.com/help/en/ecs/user-guide/resolve-the-issue-of-insufficient-disk-space-on-a-linux-instance](https://www.alibabacloud.com/help/en/ecs/user-guide/resolve-the-issue-of-insufficient-disk-space-on-a-linux-instance)  
39. Disk Space and Inode Usage Monitoring: Complete System Administrator's Guide \- CubePath Docs, accessed on July 14, 2026, [https://cubepath.com/docs/Storage%20Management/disk-space-and-inode-usage-monitoring](https://cubepath.com/docs/Storage%20Management/disk-space-and-inode-usage-monitoring)  
40. Troubleshooting Linux Storage | Cycle.io, accessed on July 14, 2026, [https://cycle.io/learn/troubleshooting-linux-storage](https://cycle.io/learn/troubleshooting-linux-storage)  
41. How to Fix 'Disk Full' Errors in Linux \- OneUptime, accessed on July 14, 2026, [https://oneuptime.com/blog/post/2026-01-24-fix-disk-full-errors-linux/view](https://oneuptime.com/blog/post/2026-01-24-fix-disk-full-errors-linux/view)  
42. Today I Solved My First Linux Bottleneck: A Beginner's Guide to Troubleshooting Ubuntu | by Anita Okele | Medium, accessed on July 14, 2026, [https://medium.com/@eanitaokele/today-i-solved-my-first-linux-bottleneck-a-beginners-guide-to-troubleshooting-ubuntu-52c7bb430609](https://medium.com/@eanitaokele/today-i-solved-my-first-linux-bottleneck-a-beginners-guide-to-troubleshooting-ubuntu-52c7bb430609)  
43. How to manually clean up your server's disk space | SelfPrivacy, accessed on July 14, 2026, [https://selfprivacy.org/docs/how-to-guides/manual\_cleanup/](https://selfprivacy.org/docs/how-to-guides/manual_cleanup/)  
44. How Long Does Server Maintenance Take? \- Computero, accessed on July 14, 2026, [https://www.computero.com/long-server-maintenance-take/](https://www.computero.com/long-server-maintenance-take/)

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAC8AAAAZCAYAAAChBHccAAABHUlEQVR4Xu2WgQ3CIBAAfwZXcAZXcAVX6Aqu4AaO4Ahu4AZu4AIOoFzgk4YC31pLY+SSTxQRji99EGk0/peNi4OLo4t9+P4T7FzcXXTixa8unqF9DUgcScTjLIbHw8UtanuJX1BtEGfeS/hMMkkkiU3Cj0Qf5OO2GpzEJ7MP4rgkt/I2hEJn5BmoNqldQPbxyWZfYRGscg1x5kYyJ286sdfMTguRk9T2eFED4v1WgorAgGOD6lFiljyPzZpgSWbJ0yn+Y01Uktqeai/KU4r6VceCvgw8JSxSkipfTCwyxdMsgusEA44N3hELDqicPPNleYjvNGUB36aT4YHENsKtiN5ppmydJaBc8wT0ya55z/oIZBFnAclrQaPRaNThDV2HWWxdUxgwAAAAAElFTkSuQmCC>