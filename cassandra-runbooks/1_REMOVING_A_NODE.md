## Removing a node for maintenance

These are the steps you need to take to remove a node

These steps will be made while load is being generated on the cluster to prove that Cassandra is highly available

* ssh to Node 1 (node.c.graceful-matter-161422.internal) and check the current status of the cluster

```
[terry@node ~]$ /opt/apache-cassandra/bin/nodetool -p 7199 status
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load       Tokens       Owns (effective)  Host ID                               Rack
UN  10.128.0.3  39.45 KiB  256          63.8%             ecd4f0b6-3fb9-4175-a088-90332074a47a  rack1
UN  10.128.0.5  1.72 MiB   256          69.7%             0a37dbe0-967f-453c-926e-6d4ff2887da9  rack1
UN  10.128.0.6  1.78 MiB   256          66.5%             eba6db25-5f41-4ae3-9a2c-4025cc91e02a  rack1
```

* Also check that we are running our load generator using cqlsh

```
cqlsh> SELECT COUNT(*) FROM vodafone.load ;
	
count
-------
14824
	
(1 rows)	
```

* ssh to Node 3 (node3.c.graceful-matter-161422.internal)
* we will remove Node 3 from the cluster using nodetool command, dec

```
[terry@node3 ~]$ /opt/apache-cassandra/bin/nodetool -p 7199 decommission
```
	
* check node tool status on Node 1

```
[terry@node ~]$ /opt/apache-cassandra/bin/nodetool -p 7199 status
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load       Tokens       Owns (effective)  Host ID                               Rack
UL  10.128.0.3  1.17 MiB   256          63.8%             ecd4f0b6-3fb9-4175-a088-90332074a47a  rack1
UN  10.128.0.5  1.88 MiB   256          69.7%             0a37dbe0-967f-453c-926e-6d4ff2887da9  rack1
UN  10.128.0.6  2.14 MiB   256          66.5%             eba6db25-5f41-4ae3-9a2c-4025cc91e02a  rack1
``` 
	
As you can see Node 3's status has changed from ``UN`` (up and normal) to ``UL`` (up and leaving)
	
Continue to check nodetool status on Node1. Eventually you'll see something like this:
	
```
[terry@node ~]$ /opt/apache-cassandra/bin/nodetool -p 7199 status
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load       Tokens       Owns (effective)  Host ID                               Rack
UN  10.128.0.5  2.39 MiB   256          100.0%            0a37dbe0-967f-453c-926e-6d4ff2887da9  rack1
UN  10.128.0.6  2.55 MiB   256          100.0%            eba6db25-5f41-4ae3-9a2c-4025cc91e02a  rack1
```
	
As you can see, Node 3 has successfully left the cluster
	
* Finally check that we are running our load generator using cqlsh. The count should have increased

```
cqlsh> SELECT COUNT(*) FROM vodafone.load ;
	
count
-------
28805
	
(1 rows)	
```