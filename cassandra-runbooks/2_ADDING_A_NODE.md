## Adding a node to an existing cluster

These are the steps for adding a new node to a cluster

Note - I will reuse Node 3 (which was removed in the previous runbook)

* Since we are re-using Node 3, we need to stop the Cassandra process and delete the Cassandra data before the node can rejoin the cluster

* To stop the Cassandra process, first identify the PID (process id) for Cassandra

```
ps -aux | grep "cassandra"
```
Running this command will output something like the following 

```
[terry@node3 ~]$ ps -aux | grep "cassandra"
	
cassand+  3148  4.2 35.0 2973004 1327912 ?     Sl   11:38   1:07 /usr/java/jdk1.8.0_131//bin/java -Xloggc:/opt/apache-cassandra/bin/../logs/gc.log -ea -XX:+UseThreadPriorities -XX:ThreadPriorityPolicy=42 -XX:+HeapDumpOnOutOfMemoryError -Xss256k -XX:StringTableSize=1000003 -XX:+AlwaysPreTouch -XX:-UseBiasedLocking -XX:+UseTLAB -XX:+ResizeTLAB -XX:+UseNUMA -XX:+PerfDisableSharedMem -Djava.net.preferIPv4Stack=true -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:SurvivorRatio=8 -XX:MaxTenuringThreshold=1 -XX:CMSInitiatingOccupancyFraction=75 -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSWaitDuration=10000 -XX:+CMSParallelInitialMarkEnabled -XX:+CMSEdenChunksRecordAlways -XX:+CMSClassUnloadingEnabled -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintHeapAtGC -XX:+PrintTenuringDistribution -XX:+PrintGCApplicationStoppedTime -XX:+PrintPromotionFailure -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=10M -Xms1024M -Xmx1024M -Xmn100M -XX:+UseCondCardMark -XX:CompileCommandFile=/opt/apache-cassandra/bin/../conf/hotspot_compiler -javaagent:/opt/apache-cassandra/bin/../lib/jamm-0.3.0.jar -Dcassandra.jmx.local.port=7199 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.password.file=/etc/cassandra/jmxremote.password -Djava.library.path=/opt/apache-cassandra/bin/../lib/sigar-bin -Dlogback.configurationFile=logback.xml -Dcassandra.logdir=/opt/apache-cassandra/bin/../logs -Dcassandra.storagedir=/opt/apache-cassandra/bin/../data -cp /opt/apache-cassandra/bin/../conf:/opt/apache-cassandra/bin/../build/classes/main:/opt/apache-cassandra/bin/../build/classes/thrift:/opt/apache-cassandra/bin/../lib/airline-0.6.jar:/opt/apache-cassandra/bin/../lib/antlr-runtime-3.5.2.jar:/opt/apache-cassandra/bin/../lib/apache-cassandra-3.11.0.jar:/opt/apache-cassandra/bin/../lib/apache-cassandra-thrift-3.11.0.jar:/opt/apache-cassandra/bin/../lib/asm-5.0.4.jar:/opt/apache-cassandra/bin/../lib/caffeine-2.2.6.jar:/opt/apache-cassandra/bin/../lib/cassandra-driver-core-3.0.1-shaded.jar:/opt/apache-cassandra/bin/../lib/commons-cli-1.1.jar:/opt/apache-cassandra/bin/../lib/commons-codec-1.9.jar:/opt/apache-cassandra/bin/../lib/commons-lang3-3.1.jar:/opt/apache-cassandra/bin/../lib/commons-math3-3.2.jar:/opt/apache-cassandra/bin/../lib/compress-lzf-0.8.4.jar:/opt/apache-cassandra/bin/../lib/concurrentlinkedhashmap-lru-1.4.jar:/opt/apache-cassandra/bin/../lib/concurrent-trees-2.4.0.jar:/opt/apache-cassandra/bin/../lib/disruptor-3.0.1.jar:/opt/apache-cassandra/bin/../lib/ecj-4.4.2.jar:/opt/apache-cassandra/bin/../lib/guava-18.0.jar:/opt/apache-cassandra/bin/../lib/HdrHistogram-2.1.9.jar:/opt/apache-cassandra/bin/../lib/high-scale-lib-1.0.6.jar:/opt/apache-cassandra/bin/../lib/hppc-0.5.4.jar:/opt/apache-cassandra/bin/../lib/jackson-core-asl-1.9.2.jar:/opt/apache-cassandra/bin/../lib/jackson-mapper-asl-1.9.2.jar:/opt/apache-cassandra/bin/../lib/jamm-0.3.0.jar:/opt/apache-cassandra/bin/../lib/javax.inject.jar:/opt/apache-cassandra/bin/../lib/jbcrypt-0.3m.jar:/opt/apache-cassandra/bin/../lib/jcl-over-slf4j-1.7.7.jar:/opt/apache-cassandra/bin/../lib/jctools-core-1.2.1.jar:/opt/apache-cassandra/bin/../lib/jflex-1.6.0.jar:/opt/apache-cassandra/bin/../lib/jna-4.4.0.jar:/opt/apache-cassandra/bin/../lib/joda-time-2.4.jar:/opt/apache-cassandra/bin/../lib/json-simple-1.1.jar:/opt/apache-cassandra/bin/../lib/jstackjunit-0.0.1.jar:/opt/apache-cassandra/bin/../lib/libthrift-0.9.2.jar:/opt/apache-cassandra/bin/../lib/log4j-over-slf4j-1.7.7.jar:/opt/apache-cassandra/bin/../lib/logback-classic-1.1.3.jar:/opt/apache-cassandra/bin/../lib/logback-core-1.1.3.jar:/opt/apache-cassandra/bin/../lib/lz4-1.3.0.jar:/opt/apache-cassandra/bin/../lib/metrics-core-3.1.0.jar:/opt/apache-cassandra/bin/../lib/metrics-jvm-3.1.0.jar:/opt/apache-cassandra/bin/../lib/metrics-logback-3.1.0.jar:/opt/apache-cassandra/bin/../lib/netty-all-4.0.44.Final.jar:/opt/apache-cassandra/bin/../lib/ohc-core-0.4.4.jar:/opt/apache-cassandra/bin/../lib/ohc-core-j8-0.4.4.jar:/opt/apache-cassandra/bin/../lib/reporter-config3-3.0.3.jar:/opt/apache-cassandra/bin/../lib/reporter-config-base-3.0.3.jar:/opt/apache-cassandra/bin/../lib/sigar-1.6.4.jar:/opt/apache-cassandra/bin/../lib/slf4j-api-1.7.7.jar:/opt/apache-cassandra/bin/../lib/snakeyaml-1.11.jar:/opt/apache-cassandra/bin/../lib/snappy-java-1.1.1.7.jar:/opt/apache-cassandra/bin/../lib/snowball-stemmer-1.3.0.581.1.jar:/opt/apache-cassandra/bin/../lib/ST4-4.0.8.jar:/opt/apache-cassandra/bin/../lib/stream-2.5.2.jar:/opt/apache-cassandra/bin/../lib/thrift-server-0.3.7.jar:/opt/apache-cassandra/bin/../lib/jsr223/*/*.jar org.apache.cassandra.service.CassandraDaemon
terry     3422  0.0  0.0 114692   960 pts/0    R+   12:04   0:00 grep --color=auto cassandra
```
Here we can see that the Cassandra process has a PID of 3148.
	
To stop the process do the following
	
```
sudo kill -9 3148
```

* Now delete the data directory

```
sudo rm -rf /opt/apache-cassandra/data/*
```
	
* Now Node 3 can rejoin the cluster

* Before we rejoin Node 3, take a look at nodetool status and the current count of rows for ``vodafone.load``

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

* Since Node 3 already has Cassandra installed and the cassandra.yaml file is already configured, we simply need to restart the Cassandra process for it to rejoin the cluster

```
sudo su - cassandra -c "/opt/apache-cassandra/bin/cassandra"
```
	
* After a while check node status and the count or rows in ``vodafone.load``

```
[terry@node ~]$ /opt/apache-cassandra/bin/nodetool -p 7199 status

Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load       Tokens       Owns (effective)  Host ID                               Rack
UN  10.128.0.3  2.23 MiB   256          69.3%             61a6db2d-7757-4d5e-8df2-80c88e588816  rack1
UN  10.128.0.5  3.67 MiB   256          68.6%             0a37dbe0-967f-453c-926e-6d4ff2887da9  rack1
UN  10.128.0.6  3.68 MiB   256          62.2%             eba6db25-5f41-4ae3-9a2c-4025cc91e02a  rack1
```
	
```
[terry@node]$ /opt/apache-cassandra/bin/cqlsh node.c.graceful-matter-161422.internal
	
cqlsh> SELECT COUNT(*) FROM vodafone.load ;
	
 count
-------
 53160
	
(1 rows)	
```

As you can see we now have 3 nodes and the count has increased
	
Note - in production, you probably would not rejoin old servers (like we did with Node 3). Instead, you would  install cassandra and configure the ``cassandra.yaml`` on a new server.