
Het probleem: app-container gebruikt nog steeds SQLite, terwijl je een MariaDB-container draait op een andere VM. Daarom kan de app nooit verbinding maken met MariaDB.

```docker
docker network create --driver bridge shared_net
docker run --network shared_net --name mariadb ...
docker run --network shared_net --name rise-app ...
```

datasource=...
vervangen door
"Server=192.168.56.222;Port=3306;Database=mydatabase;User=root;Password=supersecretpassword;"

zie `/appserver/current.pdf`
nieuwe opstelling maken in `/appserver/current.odg`

laatste stap:

rise.db omzetten : # Export SQLite database naar SQL
sqlite3 Rise.db .dump > dump.sql
	Het probleem: SQLite SQL syntax is iets anders dan MariaDB. Je moet mogelijk kleine aanpassingen doen:

	AUTOINCREMENT → AUTO_INCREMENT

	TEXT/BLOB type correct aanpassen

	Strings in quotes goed zetten

mysql -h 192.168.56.121 -u root -p mydatabase < dump.sql
