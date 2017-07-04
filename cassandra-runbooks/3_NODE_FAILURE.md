## Failing a node for HA testing

This runbook will demonstrate that when a node dies (in our case we will forcefully stop Node 3) Cassandra remains highly available.

This will be demonstrated by the fact that the load-generator will continue to write to the cluster - even while Node 3 dies

* Before we kill Node 3, take a look at nodetool status and the current count of rows for ``vodafone.load`` on Node 1

```
[terry@node ~]$ /opt/apache-cassandra/bin/nodetool -p 7199 status

Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load       Tokens       Owns (effective)  Host ID                               Rack
UN  10.128.0.5  3.11 MiB   256          100.0%            0a37dbe0-967f-453c-926e-6d4ff2887da9  rack1
UN  10.128.0.6  3.29 MiB   256          100.0%            eba6db25-5f41-4ae3-9a2c-4025cc91e02a  rack1
```
	
```
[terry@node]$ /opt/apache-cassandra/bin/cqlsh node.c.graceful-matter-161422.internal

cqlsh> SELECT COUNT(*) FROM vodafone.load ;
	
count
-------
45739
	
(1 rows)	
```

* Next, ssh to Node 3 and shutdown the server ``sudo shutdown now``

* Now check the nodetool status on node 1. You shoule see something like this

```
[terry@node ~]$ /opt/apache-cassandra/bin/nodetool -p 7199 status

Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load       Tokens       Owns (effective)  Host ID                               Rack
DN  10.128.0.3  2.23 MiB   256          69.3%             61a6db2d-7757-4d5e-8df2-80c88e588816  rack1
UN  10.128.0.5  3.74 MiB   256          68.6%             0a37dbe0-967f-453c-926e-6d4ff2887da9  rack1
UN  10.128.0.6  3.68 MiB   256          62.2%             eba6db25-5f41-4ae3-9a2c-4025cc91e02a  rack1
```
	
This output indicates that theres a problem with Node 

* Its status is ``DN`` which stands for down and normal.
	
* Check the row count on ``vodafone.load``. It should be higher than the baseline we saw earlier

```
[terry@node]$ /opt/apache-cassandra/bin/cqlsh node.c.graceful-matter-161422.internal
	
cqlsh> SELECT COUNT(*) FROM vodafone.load ;
	
count
-------
63600
	
(1 rows)
```
	
* Next, remove node 3 from the cluster using nodetool using the ``Host ID``

```
[terry@node ~]$ /opt/apache-cassandra/bin/nodetool -p 7199 removenode 61a6db2d-7757-4d5e-8df2-80c88e588816
```

* Check the status using nodetool

```
[terry@node ~]$ /opt/apache-cassandra/bin/nodetool -p 7199 status

Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load       Tokens       Owns (effective)  Host ID                               Rack
UN  10.128.0.5  3.74 MiB   256          100.0%            0a37dbe0-967f-453c-926e-6d4ff2887da9  rack1
UN  10.128.0.6  3.82 MiB   256          100.0%            eba6db25-5f41-4ae3-9a2c-4025cc91e02a  rack1
```
	
As you can see the node is now removed from the cluster
	
* Finally, check the count in ``vodafone.load``. It should have increased, since our last query

```
[terry@node]$ /opt/apache-cassandra/bin/cqlsh node.c.graceful-matter-161422.internal
	
cqlsh> SELECT COUNT(*) FROM vodafone.load ;
	
count
-------
68718
	
(1 rows)
```
