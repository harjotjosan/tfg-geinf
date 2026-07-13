# Crònica de la Prova Loki 1: Resolució d'un Error de Sintaxi a Nginx

## 1. Context i Objectiu de la Prova
L'objectiu d'aquest escenari, denominat **Loki 1**, era simular un dels errors humans més comuns en l'administració de sistemes: una errada en la configuració del servidor intermediari (Proxy). En aquest cas, s'ha provocat deliberadament una fallada en el fitxer de configuració de Nginx a la màquina de Proxy, eliminant un caràcter crític (un punt i coma) per observar com reaccionava el sistema **GEMRAT**.

## 2. Provocació de l'Incident (Loki)
L'execució ha començat amb l'ús d'un script de "provocació" que ha manipulat el fitxer `nginx.conf` dins del contenidor Docker. Per assegurar que l'error fos efectiu i detectable, s'ha reiniciat el contenidor. Com a resultat, Nginx no ha pogut tornar a carregar la seva configuració i el lloc web ha quedat completament inaccessible, retornant errors de connexió als usuaris.

## 3. Detecció i Vigilància (Heimdall)
En aquesta fase, el component de detecció (**Heimdall**) ha presentat algunes dificultats. Tot i que Vector està configurat per monitorar els logs en temps real, en aquesta prova concreta no ha activat el "webhook" de forma automàtica. Per continuar amb l'experiment, s'ha optat per una activació manual del flux de treball des d'n8n, la qual cosa ha posat en marxa el procés de diagnòstic. Aquesta observació ha posat de manifest la necessitat de millorar la visibilitat interna de Heimdall per saber exactament què detecta i quan decideix silenciar una alerta.

## 4. Diagnòstic i Presa de Decisions (Odin)
Un cop activat el flux, el "cervell" del sistema (**Odin**) ha iniciat una investigació exhaustiva que ha durat aproximadament 17 minuts. Aquest procés s'ha vist alentit per problemes externs de l'API de Google (errors 500), que han obligat el sistema a reintentar les consultes i a utilitzar models de llenguatge de reserva (fallback). 

Durant aquesta fase, Odin ha gestionat un volum ingent d'informació, arribant a processar gairebé un milió de "tokens". Tot i superar la capacitat nominal del seu context de memòria, el sistema ha estat capaç de mantenir el fil del problema, identificar que el contenidor de Nginx tenia una sintaxi invàlida i proposar la solució correcta.

## 5. Execució de la Millora i Recuperació (Thor)
Amb la solució identificada, el braç executor del sistema (**Thor**) ha intervingut per restaurar la configuració original de Nginx. Malgrat que el sistema ha acabat el procés amb un cert grau de confusió (informant d'errors de connexió temporals que ja no existien), la realitat és que la intervenció ha estat un èxit. El lloc web ha tornat a estar operatiu i accessible per a l'usuari final molt abans que el workflow es donés per finalitzat.

## 6. Conclusions i Lliçons Apreses
La prova Loki 1 ha validat la resiliència del sistema GEMRAT davant d'errors complexos en infraestructures contenitzades. Les principals conclusions són:
*   **Resiliència de l'IA:** El sistema pot sobreposar-se a fallades de l'API i a limitacions de memòria per trobar l'arrel d'un problema tècnic.
*   **Punts de millora:** Cal optimitzar la finestra de context (la memòria a curt termini de l'IA) per evitar que es perdi en els passos finals de verificació.
*   **Observabilitat:** Es fa palesa la necessitat d'un registre local de deteccions per verificar el comportament de Heimdall sense dependre exclusivament dels missatges que arriben a n8n.
