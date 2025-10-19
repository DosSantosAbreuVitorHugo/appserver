
Het $1^{ste}$ probleem: app-container gebruikt nog steeds SQLite, terwijl je een MariaDB-container draait op een andere VM. Daarom kan de app nooit verbinding maken met MariaDB.

rise.db omzetten : # Export SQLite database naar SQL
```
sqlite3 Rise.db .dump > dump.sql
Het probleem: SQLite SQL syntax is iets anders dan MariaDB. Je moet mogelijk kleine aanpassingen doen:

AUTOINCREMENT → AUTO_INCREMENT
TEXT/BLOB type correct aanpassen
Strings in quotes goed zetten

mysql -h 192.168.56.121 -u root -p mydatabase < dump.sql
```

Het $2^{de}$ probleem:
mariadb config file editen en bind addres op 172.x.x.2 zetten en port exposen en port forwarding
zodat alle verkeer dat binnenkomt bij 192.168.56.222 doorgegeven wordt aan 172.x.x.2.

App container zou sws 192.168.56.221; .1; .222 kunnen bereiken  
Als .222 kan bereiken dan laat je app container met .222 connecteren op poort dat vrijgegeven en gemapped
is door docker op db vm.

/etc/mysql/ -> config file vinden en bind addres aanpassen

```
datasource=...
vervangen door
"Server=192.168.56.222;Port=3306;Database=mydatabase;User=root;Password=supersecretpassword;"
```

Virtuele weergave van de opstelling:
- `/appserver/current.pdf`  
- `/appserver/current.odg`

