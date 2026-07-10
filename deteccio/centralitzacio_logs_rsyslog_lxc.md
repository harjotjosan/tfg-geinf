# Centralització de logs des de LXC cap a servidor rsyslog central

## Objectiu

Configurar contenidors LXC perquè enviïn logs cap a un servidor central mitjançant `rsyslog`.

Arquitectura final:

```text
LXC monitoritzat
  ├── logs del sistema
  ├── logs propis del TFG
  └── logs de Docker exportats a fitxer
        ↓
rsyslog imfile + omfwd
        ↓
Servidor rsyslog central
        ↓
/var/log/remote/<IP_CLIENT>/<programa>.log
```

---

# 1. Configuració del servidor rsyslog central

## 1.1 Instal·lar rsyslog

```bash
sudo apt update
sudo apt install -y rsyslog
sudo systemctl enable rsyslog
sudo systemctl start rsyslog
```

## 1.2 Crear configuració per rebre logs remots

Crear el fitxer:

```bash
sudo nano /etc/rsyslog.d/10-central-server.conf
```

Contingut:

```conf
module(load="imtcp")

template(
  name="RemoteLogs"
  type="string"
  string="/var/log/remote/%fromhost-ip%/%programname%.log"
)

ruleset(name="remote") {
  action(type="omfile" dynaFile="RemoteLogs")
  stop
}

input(type="imtcp" port="514" ruleset="remote")
```

## 1.3 Crear directori de logs remots

```bash
sudo mkdir -p /var/log/remote
sudo chown -R syslog:adm /var/log/remote
```

## 1.4 Validar i reiniciar rsyslog

```bash
sudo rsyslogd -N1
sudo systemctl restart rsyslog
```

## 1.5 Comprovar que escolta al port 514

```bash
sudo ss -lntup | grep 514
```

Resultat esperat:

```text
LISTEN 0 25 0.0.0.0:514
LISTEN 0 25 [::]:514
```

## 1.6 Obrir firewall si cal

```bash
sudo ufw allow 514/tcp
```

---

# 2. Configuració d’un LXC client

Aquests passos s’han de repetir a cada LXC que es vulgui monitoritzar.

## 2.1 Instal·lar rsyslog

```bash
sudo apt update
sudo apt install -y rsyslog
sudo systemctl enable rsyslog
sudo systemctl start rsyslog
```

---

# 3. Configurar enviament cap al servidor central

Crear el fitxer:

```bash
sudo nano /etc/rsyslog.d/01-forward-to-central.conf
```

Contingut:

```conf
*.* action(
  type="omfwd"
  target="IP_DEL_SERVIDOR_RSYSLOG"
  port="514"
  protocol="tcp"
  action.resumeRetryCount="-1"
  queue.type="LinkedList"
  queue.size="10000"
)
```

Exemple:

```conf
*.* action(
  type="omfwd"
  target="10.0.27.162"
  port="514"
  protocol="tcp"
  action.resumeRetryCount="-1"
  queue.type="LinkedList"
  queue.size="10000"
)
```

Validar:

```bash
sudo rsyslogd -N1
sudo systemctl restart rsyslog
```

---

# 4. Configurar logs propis del TFG amb imfile

Aquesta part permet enviar fitxers locals concrets cap al servidor central.

Crear el fitxer:

```bash
sudo nano /etc/rsyslog.d/00-tfg-inputs.conf
```

Contingut base:

```conf
module(load="imfile")

input(
  type="imfile"
  File="/var/log/tfg-agent-events.log"
  Tag="tfg-agent:"
  Severity="info"
  Facility="local2"
  PersistStateInterval="1"
  freshStartTail="off"
)
```

Crear el fitxer local:

```bash
sudo touch /var/log/tfg-agent-events.log
sudo chmod 644 /var/log/tfg-agent-events.log
```

Validar i reiniciar:

```bash
sudo rsyslogd -N1
sudo systemctl restart rsyslog
```

Prova:

```bash
echo "TEST_TFG_AGENT_EVENT $(date)" | sudo tee -a /var/log/tfg-agent-events.log
```

Al servidor central:

```bash
sudo grep -R "TEST_TFG_AGENT_EVENT" /var/log/remote/
```

---

# 5. Configurar logs d’un contenidor Docker dins del LXC

En LXC, rsyslog pot tenir problemes de permisos per llegir directament:

```text
/var/lib/docker/containers/.../*-json.log
```

Per això la solució funcional és exportar els logs de Docker a un fitxer dins de `/var/log`.

---

## 5.1 Identificar el contenidor

```bash
docker ps
```

Exemple de contenidor:

```text
carparts-web
```

---

## 5.2 Crear script exportador de logs Docker

Crear:

```bash
sudo nano /usr/local/bin/export-carparts-web-logs.sh
```

Contingut:

```bash
#!/bin/bash
docker logs -f carparts-web >> /var/log/docker-carparts-web.log 2>&1
```

Donar permisos:

```bash
sudo chmod +x /usr/local/bin/export-carparts-web-logs.sh
```

Crear fitxer de sortida:

```bash
sudo touch /var/log/docker-carparts-web.log
sudo chmod 644 /var/log/docker-carparts-web.log
```

---

## 5.3 Crear servei systemd per mantenir l’exportació activa

Crear:

```bash
sudo nano /etc/systemd/system/export-carparts-web-logs.service
```

Contingut:

```ini
[Unit]
Description=Export carparts-web Docker logs to file
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/local/bin/export-carparts-web-logs.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Activar servei:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now export-carparts-web-logs.service
```

Comprovar estat:

```bash
sudo systemctl status export-carparts-web-logs --no-pager
```

---

## 5.4 Afegir el fitxer Docker exportat a rsyslog

Editar:

```bash
sudo nano /etc/rsyslog.d/00-tfg-inputs.conf
```

Contingut final recomanat:

```conf
module(load="imfile")

input(
  type="imfile"
  File="/var/log/docker-carparts-web.log"
  Tag="docker-carparts-web:"
  Severity="info"
  Facility="local1"
  PersistStateInterval="1"
  freshStartTail="off"
)

input(
  type="imfile"
  File="/var/log/tfg-agent-events.log"
  Tag="tfg-agent:"
  Severity="info"
  Facility="local2"
  PersistStateInterval="1"
  freshStartTail="off"
)
```

Validar i reiniciar:

```bash
sudo rsyslogd -N1
sudo systemctl restart rsyslog
```

---

# 6. Proves de funcionament

## 6.1 Provar log propi del TFG

Al LXC:

```bash
echo "TEST_TFG_AGENT_EVENT $(date)" | sudo tee -a /var/log/tfg-agent-events.log
```

Al servidor central:

```bash
sudo grep -R "TEST_TFG_AGENT_EVENT" /var/log/remote/
```

---

## 6.2 Provar log del contenidor Docker

Al LXC:

```bash
docker exec carparts-web sh -c 'echo "TEST_DOCKER_EXPORT_TFG $(date)" > /proc/1/fd/1'
```

Comprovar que entra al fitxer exportat:

```bash
sudo grep "TEST_DOCKER_EXPORT_TFG" /var/log/docker-carparts-web.log
```

Al servidor central:

```bash
sudo grep -R "TEST_DOCKER_EXPORT_TFG" /var/log/remote/
```

---

# 7. Resultat esperat al servidor central

Els logs han d’aparèixer a:

```text
/var/log/remote/<IP_CLIENT>/
```

Exemple:

```text
/var/log/remote/10.0.27.223/docker-carparts-web.log
/var/log/remote/10.0.27.223/tfg-agent.log
/var/log/remote/10.0.27.223/sshd.log
/var/log/remote/10.0.27.223/sudo.log
/var/log/remote/10.0.27.223/dockerd.log
```

Per veure tots els fitxers rebuts:

```bash
sudo find /var/log/remote -type f
```

Per veure logs d’un client concret:

```bash
sudo ls -lh /var/log/remote/IP_DEL_CLIENT/
```

---

# 8. Notes importants

## No carregar imfile més d’una vegada

Només hi ha d’haver una línia:

```conf
module(load="imfile")
```

Si apareix aquest error:

```text
module 'imfile' already in this config, cannot be added
```

cal buscar duplicats:

```bash
sudo grep -R "module(load=\"imfile\")" /etc/rsyslog.d/
```

I eliminar o moure configuracions antigues:

```bash
sudo mkdir -p /etc/rsyslog.d/disabled
sudo mv /etc/rsyslog.d/NOM_FITXER.conf /etc/rsyslog.d/disabled/
```

---

## En LXC pot fallar la lectura directa dels logs Docker

Aquest error és esperable:

```text
Permission denied
/var/lib/docker/containers/.../*-json.log
```

Per això es fa servir:

```text
docker logs -f contenidor → /var/log/docker-contenidor.log → rsyslog imfile
```

---

## El warning imklog es pot ignorar en LXC

Pot aparèixer:

```text
imklog: cannot open kernel log (/proc/kmsg): Permission denied
```

En contenidors LXC és habitual i no impedeix l’enviament de logs de fitxers ni de serveis.

---

# 9. Adaptació a altres LXC

Per replicar-ho en un altre LXC:

1. Instal·lar `rsyslog`.
2. Crear `/etc/rsyslog.d/01-forward-to-central.conf`.
3. Crear `/etc/rsyslog.d/00-tfg-inputs.conf`.
4. Crear els fitxers locals que es vulguin monitoritzar.
5. Si hi ha Docker, crear un script `docker logs -f`.
6. Crear un servei systemd per mantenir l’exportació activa.
7. Reiniciar `rsyslog`.
8. Provar amb `grep` al servidor central.

Exemple per un contenidor anomenat `nginx-app`:

```bash
sudo nano /usr/local/bin/export-nginx-app-logs.sh
```

```bash
#!/bin/bash
docker logs -f nginx-app >> /var/log/docker-nginx-app.log 2>&1
```

Servei:

```ini
[Unit]
Description=Export nginx-app Docker logs to file
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/local/bin/export-nginx-app-logs.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Input rsyslog:

```conf
input(
  type="imfile"
  File="/var/log/docker-nginx-app.log"
  Tag="docker-nginx-app:"
  Severity="info"
  Facility="local1"
  PersistStateInterval="1"
  freshStartTail="off"
)
```

---

# 10. Flux final

```text
Contenidor Docker dins LXC
        ↓
docker logs -f
        ↓
/var/log/docker-servei.log
        ↓
rsyslog imfile
        ↓
rsyslog omfwd TCP 514
        ↓
servidor rsyslog central
        ↓
/var/log/remote/<IP_CLIENT>/<TAG>.log
```
