  node 'node.c.graceful-matter-161422.internal' {
    class {'install_required_packages':}
    class { 'cassandra': }
  }
  node 'node2.c.graceful-matter-161422.internal' {
    class {'install_required_packages':}
    class { 'cassandra': }
  }
  node 'node3.c.graceful-matter-161422.internal' {
    class {'install_required_packages':}
    class { 'cassandra': }
  }
  node 'spark.c.graceful-matter-161422.internal' {
    class {'install_required_packages':}
    class {'install_java':}
    class {'install_python':}
    class {'install_spark':}     
  }

  class install_required_packages {
    $requiredpackages = ['git','maven']
    package { $requiredpackages:
      ensure => 'installed',
    }
  }

  class install_spark {
    include wget
    $user_home="/home/terry/"
    wget::fetch { "download spark":
      source      => 'https://d3kbcqa49mib13.cloudfront.net/spark-2.1.1-bin-hadoop2.7.tgz',
      destination => $user_home,
      no_cookies => true,
      nocheckcertificate => true,
      timeout => 0,
      verbose => false,
      #require => Package['jdk1.8.0_131.x86_64'],
      require => Class['install_java','install_python'],
    }

    $spark_user_and_group = 'spark'
    group { $spark_user_and_group:
      ensure => 'present',
    }
    user { 'spark':
      ensure => 'present',
      home => "/home/${spark_user_and_group}",
      groups => "${spark_user_and_group}",
      shell => '/bin/bash',
      require => Group[$spark_user_and_group]
    }

    file { "/home/${spark_user_and_group}":
      ensure => directory,
      owner  => "${spark_user_and_group}",
      group  => "${spark_user_and_group}",
      require => [Group[$spark_user_and_group], User[$spark_user_and_group]],
    }    
   
    $spark_dirname = 'spark-2.1.1-bin-hadoop2.7'
    $spark_filename = "${spark_dirname}.tgz"
    $spark_docs_gz_path  = "${user_home}${spark_filename}"
    $spark_extract_dir = "/opt/"
    $spark_install_path = "${spark_extract_dir}${spark_dirname}"
    $spark_link_path = "${spark_extract_dir}apache-spark"
    notify{"spark_filename: ${spark_filename}": }
    notify{"spark_docs_gz_path: ${spark_docs_gz_path}": }
    notify{"spark_extract_dir: ${spark_extract_dir}": }
    notify{"spark_install_path: ${spark_install_path}": }
    notify{"spark_link_path: ${spark_link_path}": }

    file { $spark_install_path:
      ensure => directory,
      owner  => "${spark_user_and_group}",
      group  => "${spark_user_and_group}",
      mode   => '0755',
      require => [Group[$spark_user_and_group], User[$spark_user_and_group]],
    }

    file { $spark_link_path:
      ensure => 'link',
      target => $spark_install_path,
      owner  => "${spark_user_and_group}",
      group  => "${spark_user_and_group}",
      require => [Group[$spark_user_and_group], User[$spark_user_and_group]],
    }

    /************************************ Extract Spark ***********************************/

    # Then expand the archive where you need it to go
    archive { $spark_docs_gz_path:
      path          => $spark_docs_gz_path,
      extract       => true,
      extract_path  => $spark_extract_dir,
      creates       => "${spark_install_path}/bin",
      cleanup       => 'true',
      require       => [ Wget::Fetch['download spark'],  File[$spark_install_path] ],
    }
    
    # clean repos - in case we update and want to rerun the puppet code
    file { "/home/terry/vodafone-load-generator":
      ensure => absent,
      recurse => true,
      purge => true,
      force => true,
      path => "/home/terry/vodafone-load-generator",
    }
    file { "/home/terry/vodafone-source-data-load":
      ensure => absent,
      recurse => true,
      purge => true,
      force => true,
      path => "/home/terry/vodafone-source-data-load",
    }

    exec { 'clone-vodafone-source-data-load':
      command => 'git clone https://cleverbitsio@bitbucket.org/cleverbitsio/vodafone-source-data-load.git /home/terry/vodafone-source-data-load',  
      path =>  '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
      require => [ Package[$requiredpackages], Archive[$spark_docs_gz_path], File["/home/terry/vodafone-load-generator"], File["/home/terry/vodafone-source-data-load"]],
    }
    exec { 'build-clone-vodafone-source-data-load':
      command => 'sudo mvn package -f /home/terry/vodafone-source-data-load/pom.xml',
      path =>  '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
      require => Exec['clone-vodafone-source-data-load'],
    }

    exec { 'clone-vodafone-load-generator':
      command => 'git clone https://cleverbitsio@bitbucket.org/cleverbitsio/vodafone-load-generator.git /home/terry/vodafone-load-generator',  
      path =>  '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
      require => [ Package[$requiredpackages], Archive[$spark_docs_gz_path], Exec['clone-vodafone-source-data-load'], File["/home/terry/vodafone-load-generator"], File["/home/terry/vodafone-source-data-load"] ],
    }
    exec { 'build-vodafone-load-generator':
      command => 'sudo mvn package -f /home/terry/vodafone-load-generator/pom.xml',
      path =>  '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
      require => Exec['clone-vodafone-load-generator'],
    }    
  }

  class install_java {
    file { '/info.txt':
      ensure => 'present',
      content => inline_template("created by puppet at <%= Time.now %>\n"),
    }

    /************************************ Download Java SDK ***********************************/
    include wget
    $user_home="/home/terry/"
    wget::fetch { "download Oracle JDK":
      source      => 'http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm',
      destination => $user_home,
      no_cookies => true,
      nocheckcertificate => true,
      headers => ['Cookie: oraclelicense=accept-securebackup-cookie'],
      timeout => 0,
      verbose => false,
      before => Package['jdk1.8.0_131.x86_64'],
    }

    /************************************ Install Java SDK ***********************************/
    
    $java_rpm = 'jdk-8u131-linux-x64.rpm'
    $java_package = 'jdk1.8.0_131.x86_64' #The package name can be derived from the java_rpm by this command:  rpm -qa | grep jdk or  yum list installed | grep jdk
    package { $java_package:  #the name needs to be the same as the package we want to install https://ask.puppet.com/question/1385/esure-package-installed-fails-if-it-is-installed/
     provider => rpm,
     install_options => ['-ivh'], 
     #install_options => ['-Uvh'], #I tried this upgrade flag to stop error message if it was already installed - however what solved it was using the package name 
     source => "${user_home}${java_rpm}",
     ensure => installed,
    }


    /************************************ Set JAVA_HOME ***********************************/

    $bash_profile = '${user_home}.bash_profile'
    $java_home = '/usr/java/jdk1.8.0_131/' # you can get this via /usr/libexec/java_home on mac - not sure how to on linux

    file { '/etc/profile.d/my_environment_variables.sh':
      content => "export JAVA_HOME=${java_home}",
      mode    => '755',
      require => Package[$java_package],
    }

/************************************ Reboot to set $JAVA_HOME ***********************************/

    # exec { 'reboot':
    #   command => "sudo reboot",
    #   path => [ "/usr/bin", "/bin", "/usr/sbin/"],
    #   require => Archive[$docs_gz_path],
    # }

  }

  class install_python {
    package { python:  #the name needs to be the same as the package we want to install https://ask.puppet.com/question/1385/esure-package-installed-fails-if-it-is-installed/
     ensure => installed,
    }
    notify{"install_python": }
  }

  class cassandra {
    file { '/info.txt':
      ensure => 'present',
      content => inline_template("created by puppet at <%= Time.now %>\n"),
    }

    /************************************ Download Java SDK ***********************************/
    include wget
    $user_home="/home/terry/"
    wget::fetch { "download Oracle JDK":
      source      => 'http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm',
      destination => $user_home,
      no_cookies => true,
      nocheckcertificate => true,
      headers => ['Cookie: oraclelicense=accept-securebackup-cookie'],
      timeout => 0,
      verbose => false,
      before => Package['jdk1.8.0_131.x86_64'],
    }

    /************************************ Install Java SDK ***********************************/
    
    $java_rpm = 'jdk-8u131-linux-x64.rpm'
    $java_package = 'jdk1.8.0_131.x86_64' #The package name can be derived from the java_rpm by this command:  rpm -qa | grep jdk or  yum list installed | grep jdk
    package { $java_package:  #the name needs to be the same as the package we want to install https://ask.puppet.com/question/1385/esure-package-installed-fails-if-it-is-installed/
     provider => rpm,
     install_options => ['-ivh'], 
     #install_options => ['-Uvh'], #I tried this upgrade flag to stop error message if it was already installed - however what solved it was using the package name 
     source => "${user_home}${java_rpm}",
     ensure => installed,
    }


    /************************************ Set JAVA_HOME ***********************************/

    $bash_profile = '${user_home}.bash_profile'
    $java_home = '/usr/java/jdk1.8.0_131/' # you can get this via /usr/libexec/java_home on mac - not sure how to on linux

    file { '/etc/profile.d/my_environment_variables.sh':
      content => "export JAVA_HOME=${java_home}",
      mode    => '755',
      require => Package[$java_package],
    }

    /************************************ Install Python ***********************************/
    
    package { python:  #the name needs to be the same as the package we want to install https://ask.puppet.com/question/1385/esure-package-installed-fails-if-it-is-installed/
     ensure => installed,
    }

    wget::fetch { "download cassandra":
      source      => 'http://apache.mirror.anlx.net/cassandra/3.11.0/apache-cassandra-3.11.0-bin.tar.gz',
      destination => $user_home,
      timeout => 0,
      verbose => false,
      no_cookies => true,
      nocheckcertificate => true,
      headers => ['Cookie: gsScrollPos-547=0'],
      require => Package['jdk1.8.0_131.x86_64', 'python'],
    }

    /************************************ Create Cassandra user and group ***********************************/

    #https://docs.puppet.com/puppet/4.10/quick_start_user_group.html
    $cassandra_user_and_group = 'cassandra'
    group { $cassandra_user_and_group:
      ensure => 'present',
    }
    user { 'cassandra':
      ensure => 'present',
      home => "/home/${cassandra_user_and_group}",
      groups => "${cassandra_user_and_group}",
      shell => '/bin/bash',
      require => Group[$cassandra_user_and_group]
    }

    file { "/home/${cassandra_user_and_group}":
      ensure => directory,
      owner  => "${cassandra_user_and_group}",
      group  => "${cassandra_user_and_group}",
      require => [Group[$cassandra_user_and_group], User[$cassandra_user_and_group]],
    }

    /************************************ Setup cassandra archive variables ***********************************/
    
    #$dirname = 'apache-cassandra-3.10'
    $dirname = 'apache-cassandra-3.11.0'
    $filename = "${dirname}-bin.tar.gz"
    $docs_gz_path  = "${user_home}${filename}"
    $extract_dir = "/opt/"
    $install_path = "${extract_dir}${dirname}"
    $link_path = "${extract_dir}apache-cassandra"
    notify{"filename: ${filename}": }
    notify{"docs_gz_path: ${docs_gz_path}": }
    notify{"extract_dir: ${extract_dir}": }
    notify{"install_path: ${install_path}": }
    notify{"link_path: ${link_path}": }

    file { $install_path:
      ensure => directory,
      owner  => "${cassandra_user_and_group}",
      group  => "${cassandra_user_and_group}",
      mode   => '0755',
      require => [Group[$cassandra_user_and_group], User[$cassandra_user_and_group]],
    }

    file { $link_path:
      ensure => 'link',
      target => $install_path,
      owner  => "${cassandra_user_and_group}",
      group  => "${cassandra_user_and_group}",
      require => [Group[$cassandra_user_and_group], User[$cassandra_user_and_group]],
    }

/************************************ Extract cassandra ***********************************/

    # Then expand the archive where you need it to go
    archive { $docs_gz_path:
      path          => $docs_gz_path,
      extract       => true,
      extract_path  => $extract_dir,
      creates       => "$install_path/bin",
      cleanup       => 'true',
      require       => [ Wget::Fetch['download cassandra'],  File[$install_path] ],
    }

/************************************ Download cassandra yaml files  ***********************************/

    if $facts['gce']['instance']['hostname'] == 'node.c.graceful-matter-161422.internal' { 
      exec { 'clone node1 yaml':
        command => 'git clone https://cleverbitsio@bitbucket.org/snippets/cleverbitsio/MERRk/cassandra-node1yaml.git',
        path =>  '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
        require => Archive[$docs_gz_path],
      }
      exec { 'replace node1 yaml':
        command => 'sudo mv cassandra-node1yaml/cassandra-node1.yaml /opt/apache-cassandra/conf/cassandra.yaml',
        path =>  '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
        require => Exec['clone node1 yaml'],
      }
    }
    elsif $facts['gce']['instance']['hostname'] == 'node2.c.graceful-matter-161422.internal' { 
      exec { 'clone node2 yaml':
        command => 'git clone https://cleverbitsio@bitbucket.org/snippets/cleverbitsio/AkRaE/cassandra-node2yaml.git',
        path =>  '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
        require => Archive[$docs_gz_path],        
      }
      exec { 'replace node2 yaml':
        command => 'sudo mv cassandra-node2yaml/cassandra-node2.yaml /opt/apache-cassandra/conf/cassandra.yaml',
        path =>  '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
        require => Exec['clone node2 yaml'],        
      }
    }
    elsif $facts['gce']['instance']['hostname'] == 'node3.c.graceful-matter-161422.internal' {
      exec { 'clone node3 yaml':
        command => 'git clone https://cleverbitsio@bitbucket.org/snippets/cleverbitsio/Lk9an/cassandra-node3yaml.git',
        path =>  '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
        require => Archive[$docs_gz_path],
      }
      exec { 'replace node3 yaml':
        command => 'sudo mv cassandra-node3yaml/cassandra-node3.yaml /opt/apache-cassandra/conf/cassandra.yaml',
        path =>  '/usr/bin:/usr/sbin:/bin:/usr/local/bin',
        require => Exec['clone node3 yaml'],        
      }
    }

/************************************ Update cassandra permission ***********************************/

    exec { 'cassandra permission':
      command   => "chown -R ${cassandra_user_and_group}:${cassandra_user_and_group} $install_path",
      path      => $::path,
      subscribe => Archive[$docs_gz_path], #TO DO - Why do I use subscribe and not require?
    }

/************************************ Firewalld configuration for cassandra ***********************************/

    firewalld_port { 'cassandra port 7000 on public zone': #experiment with private zone
      ensure   => present,
      zone     => 'public',
      port => 7000,
      protocol => 'tcp',
    }

    firewalld_port { 'cassandra port 9042 on public zone': #experiment with private zone
      ensure   => present,
      zone     => 'public',
      port => 9042,
      protocol => 'tcp',
    }
    
/************************************ Reboot to set $JAVA_HOME ***********************************/

    # exec { 'reboot':
    #   command => "sudo reboot",
    #   path => [ "/usr/bin", "/bin", "/usr/sbin/"],
    #   require => Archive[$docs_gz_path],
    # }
    
  }