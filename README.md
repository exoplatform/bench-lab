# bench-lab quick and dirty commands 

- [bench-lab quick and dirty commands](#bench-lab-quick-and-dirty-commands)
  - [Prepare mysql dataset](#prepare-mysql-dataset)
    - [Prepare partitions](#prepare-partitions)
    - [Restore dataset](#restore-dataset)
    - [Database preparation](#database-preparation)
    - [Backup](#backup)
  - [Restore an already prepared mysql dataset](#restore-an-already-prepared-mysql-dataset)
  - [Restore the indexes, values and files (for standalone)](#restore-the-indexes-values-and-files-for-standalone)
  - [Restore the indexes (for cluster)](#restore-the-indexes-for-cluster)
  - [Restore elasticsearch content](#restore-elasticsearch-content)
  - [Restore mongodb](#restore-mongodb)
  - [Create the docker-compose file for standalone execution](#create-the-docker-compose-file-for-standalone-execution)
  - [Create the docker-compose file for cluster execution](#create-the-docker-compose-file-for-cluster-execution)

## Prepare mysql dataset

INFO: This has to be done only one time when a new dump is retrieved from the TN TQA

Actions :
* Restore TN dataset
* Move IDM database on the JCR database
* Execute optimize
* Create one database archive

Estimated duration : 1h30mn

### Prepare partitions

```
export DS=/srv/DS/DB-INT2/<dataset directory>

umount /srv/bench/db
mkfs.ext4 /dev/vg-nvme/bench-db
mount /dev/vg-nvme/bench-db /srv/bench/db
```

### Restore dataset

```
export DS=/srv/DS/DB-INT2/<dataset directory>

time pv ${DS}/mysql-data/mysql.tar | tar x -C /srv/bench/db/
chown -R 999:999 /srv/bench/db/mysql
mv /srv/bench/db/mysql/5.1/data/* /srv/bench/db/mysql
rm -rf /srv/bench/db/mysql/5.1

$ # In one terminal
docker run -ti --rm --name db -v /opt/bench/config/mysql/my.cnf:/etc/mysql/conf.d/bench.cnf -v /opt/bench/config/mysql/admin-mode.cnf:/etc/mysql/conf.d/zz-admin-mode.cnf -v /srv/bench/db/mysql:/var/lib/mysql -p 127.0.0.1:3306:3306 --net plf mysql:5.5

$ # In a second terminal
docker exec -ti db bash

mysql -uroot -p<tn root password>

GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY PASSWORD '*4A3ECC3667C707E151CC8B8EBA85DC1E5FE4A923' WITH GRANT OPTION;
set password for 'plf'@'%' = PASSWORD('plf');
```

### Database preparation

With the container still running

```

docker exec -ti db bash
$ # dump 
mysqldump -uroot -p<tn root password> PLF_35X_INTLOT2_IDM > /tmp/idm.sql
$ # restore
cat /tmp/idm.sql | mysql -uroot -p<tn root password> PLF_35X_INTLOT2_JCR

$ # Optimize
time mysqlcheck -uroot -p<tn root password> -A -o -v
$ # Duration around 1h10
```

### Backup

```
docker exec -ti db mysqladmin -u root -p<tn root password> shutdown
cd /srv/bench/db/
time tar -c -C /srv/bench/db mysql | pv --size $(du -sh /srv/bench/db/mysql |awk '{print $1}') > $DS/mysql-data/mysql-onedatabase.tar
$ # Duration ~10mn
```

## Restore an already prepared mysql dataset

* Clone this repo and checkout the branch ``ITOP_3476_dirty``
* Execute the mysql restore script
```
export DS=/srv/DS/DB-INT2/<dataset directory>
bin/dataset/restore-mysql-singledatabase.sh
```
Actions performed :
* Stop any container declared on ``/srv/tmp/docker-compose.yml`` file
* Umount and format and remount the dedicated lvm volume
* Uncompress the mysql directory

## Restore the indexes, values and files (for standalone)

* Clone this repo and checkout the branch ``ITOP_3476_dirty``
* Execute the values restore script
```
export DS=/srv/DS/DB-INT2/<dataset directory>
bin/dataset/restore-values.sh
```
Actions performed :
* Stop any container declared on ``/srv/tmp/docker-compose.yml`` file
* Umount and format and remount the dedicated lvm volume
* Uncompress the value storage directory

## Restore the indexes (for cluster)

TODO: script
```
lvcreate -L99G --name bench-indexes vg-nvme
mkfs.ext4 /dev/vg-nvme/bench-indexes
mount /dev/vg-nvme/bench-indexes indexes
mkdir -p /srv/bench/indexes/index01
mkdir -p /srv/bench/indexes/index02
chown -R 999:999 /srv/bench/indexes

rsync -avP --delete /srv/bench/data/jcr/index/ /srv/bench/indexes/index01
rsync -avP --delete /srv/bench/data/jcr/index/ /srv/bench/indexes/index02
```


## Restore elasticsearch content
* Clone this repo and checkout the branch ``ITOP_3476_dirty``
* Execute the elasticsearch restore script
```
export DS=/srv/DS/DB-INT2/<dataset directory>
bin/dataset/restore-elasticsearch.sh
```
Actions performed :
* Stop any container declared on ``/srv/tmp/docker-compose.yml`` file
* Umount and format and remount the dedicated lvm volume
* Start an elasticsearch in a docker container (the script needs to be adapted to start the container from the docker-compose file)
* Initialize the snapshot directory
* Restore the snapshot content
* Launch the snapshot restoration
* Clean all unecessary indexes
* Stop the docker container

## Restore mongodb

* Clone this repo and checkout the branch ``ITOP_3476_dirty``
* Execute the mongodb restore script
```
export DS=/srv/DS/DB-INT2/<dataset directory>
bin/dataset/restore-mongodb.sh
```
Actions performed :
* Stop any container declared on ``/srv/tmp/docker-compose.yml`` file
* Umount and format and remount the dedicated lvm volume

INFO: there is no mongodb backup on the TN dataset

## Create the docker-compose file for standalone execution

On the ``tqa-prebuilt`` directory :
```
docker-compose -f docker-compose-plf.yml -f docker-compose-elasticsearch.yml -f docker-compose-ldap.yml -f docker-compose-mongo.yml -f docker-compose-mysql.yml -f docker-compose-apache-standalone.yml config > /tmp/docker-compose.yml

rsync -avP /tmp/docker-compose.yml <server>:/srv/tmp
```

## Create the docker-compose file for cluster execution


On the ``tqa-prebuilt`` directory :
```
docker-compose -f docker-compose-plf01.yml -f docker-compose-plf02.yml -f docker-compose-elasticsearch.yml -f docker-compose-ldap.yml -f docker-compose-mongo.yml -f docker-compose-mysql.yml -f docker-compose-apache-cluster.yml  config > /tmp/docker-compose.yml 

rsync -avP /tmp/docker-compose.yml <server>:/srv/tmp
```