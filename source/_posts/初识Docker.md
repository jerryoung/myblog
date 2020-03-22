---
title: 初识Docker（针对开发人员）
date: 2019-03-31 00:47:47
tags: docker
---


## 概括

Docker 是世界领先的软件容器平台。开发人员利用 Docker 可以解决，“在我的机器上可正常工作的啊！！！”的问题

## 容器又是什么东西？

容器是一种标准化的软件单元。
容器镜像是轻量的、可执行的独立软件包，包含软件运行所需的所有内容：代码、运行时环境、系统工具、系统库和设置。
![ADavjK.png](https://s2.ax1x.com/2019/03/30/ADavjK.png)
> 图片出自：<https://www.docker-cn.com/what-container>

### 容器和虚拟机

> 容器和虚拟机具有相似的资源隔离和分配优势，但功能有所不同，因为容器虚拟化的是操作系统，而不是硬件，因此容器更容易移植，效率也更高。

#### 容器和虚拟机对比

**容器** | **虚拟机**
---|---
容器是一个应用层抽象，用于将代码和依赖资源打包在一起。多个容器可以在同一台机器上运行，共享操作系统内核，但各自作为独立的进程在用户空间中运行。与虚拟机相比，容器占用的空间较少（容器镜像大小通常只有几十兆），瞬间就能完成启动。 | 虚拟机 (VM) 是一个物理硬件层抽象，用于将一台服务器变成多台服务器。管理程序允许多个 VM 在一台机器上运行。每个 VM 都包含一整套操作系统、一个或多个应用、必要的二进制文件和库资源，因
[![ADwWLT.md.png](https://s2.ax1x.com/2019/03/30/ADwWLT.md.png)](https://imgchr.com/i/ADwWLT)图片出自：<https://www.docker-cn.com/what-container>|[![ADwRyV.md.png](https://s2.ax1x.com/2019/03/30/ADwRyV.md.png)](https://imgchr.com/i/ADwRyV) 图片出自：<https://www.docker-cn.com/what-container>

#### 容器和虚拟机共用

> 将容器和虚拟机配合使用，为应用的部署和管理提供极大的灵活性。

![ADdmDS.png](https://s2.ax1x.com/2019/03/30/ADdmDS.png)
> 图片出自：<https://www.docker-cn.com/what-container>

## 获取docker（针对Mac 用户）

1. 建议注册一个账户
2. 然后通过官网链接下载桌面版的Docker，[官网超链接](https://www.docker.com/products/docker-desktop)，如果想快一点可以试试看这个[链接](https://download.docker.com/mac/stable/Docker.dmg) 。(默认最新稳定版)

[![AD0J7F.md.png](https://s2.ax1x.com/2019/03/30/AD0J7F.md.png)](https://imgchr.com/i/AD0J7F)
3. 下载完，安装好，配置一下Docker 中国官方镜像加速源 `http://registry.docker-cn.com`，当然你也是可以选择其他的加速源例如阿里，网易等等。配置完，记得点击**Apply&Restart**。
![AD0zuV.png](https://s2.ax1x.com/2019/03/30/AD0zuV.png)
4. 打开Terminal ，输入一下命令 `docker info`
![ADBWaF.png](https://s2.ax1x.com/2019/03/30/ADBWaF.png)

安装工具，到此结束了，是不是想说So easy？其实就是如此轻松，马上可以享受到Docker带来的快感吧！

## 使用Docker

我习惯上来先查一下，help（不想看，直接跳过哈，下面会开始讲，我目前经常使用的一些命令。）

```shell
docker help
Usage: docker [OPTIONS] COMMAND

A self-sufficient runtime for containers

Options:
      --config string      Location of client config files (default "/Users/jaryoung/.docker")
  -D, --debug              Enable debug mode
  -H, --host list          Daemon socket(s) to connect to
  -l, --log-level string   Set the logging level ("debug"|"info"|"warn"|"error"|"fatal") (default "info")
      --tls                Use TLS; implied by --tlsverify
      --tlscacert string   Trust certs signed only by this CA (default "/Users/jaryoung/.docker/ca.pem")
      --tlscert string     Path to TLS certificate file (default "/Users/jaryoung/.docker/cert.pem")
      --tlskey string      Path to TLS key file (default "/Users/jaryoung/.docker/key.pem")
      --tlsverify          Use TLS and verify the remote
  -v, --version            Print version information and quit

Management Commands:
  builder     Manage builds
  config      Manage Docker configs
  container   Manage containers
  image       Manage images
  network     Manage networks
  node        Manage Swarm nodes
  plugin      Manage plugins
  secret      Manage Docker secrets
  service     Manage services
  stack       Manage Docker stacks
  swarm       Manage Swarm
  system      Manage Docker
  trust       Manage trust on Docker images
  volume      Manage volumes

Commands:
  attach      Attach local standard input, output, and error streams to a running container
  build       Build an image from a Dockerfile
  commit      Create a new image from a container's changes
  cp          Copy files/folders between a container and the local filesystem
  create      Create a new container
  diff        Inspect changes to files or directories on a container's filesystem
  events      Get real time events from the server
  exec        Run a command in a running container
  export      Export a container's filesystem as a tar archive
  history     Show the history of an image
  images      List images
  import      Import the contents from a tarball to create a filesystem image
  info        Display system-wide information
  inspect     Return low-level information on Docker objects
  kill        Kill one or more running containers
  load        Load an image from a tar archive or STDIN
  login       Log in to a Docker registry
  logout      Log out from a Docker registry
  logs        Fetch the logs of a container
  pause       Pause all processes within one or more containers
  port        List port mappings or a specific mapping for the container
  ps          List containers
  pull        Pull an image or a repository from a registry
  push        Push an image or a repository to a registry
  rename      Rename a container
  restart     Restart one or more containers
  rm          Remove one or more containers
  rmi         Remove one or more images
  run         Run a command in a new container
  save        Save one or more images to a tar archive (streamed to STDOUT by default)
  search      Search the Docker Hub for images
  start       Start one or more stopped containers
  stats       Display a live stream of container(s) resource usage statistics
  stop        Stop one or more running containers
  tag         Create a tag TARGET_IMAGE that refers to SOURCE_IMAGE
  top         Display the running processes of a container
  unpause     Unpause all processes within one or more containers
  update      Update configuration of one or more containers
  version     Show the Docker version information
  wait        Block until one or more containers stop, then print their exit codes

Run 'docker COMMAND --help' for more information on a command.


```

### docker search

```shell
docker search --help

Usage: docker search [OPTIONS] TERM

Search the Docker Hub for images，为了在Docker Hub上面搜 **资源**（你们都懂得）

Options:
  -f, --filter filter   Filter output based on conditions provided
      --format string   Pretty-print search using a Go template
      --limit int       Max number of search results (default 25)
      --no-trunc        Don't truncate output
```

例如，我需要搜索一下上面有哪些mysql镜像，我们可以看到下面到信息：

```shell
docker search mysql
NAME（名称）                                           DESCRIPTION（描述）                             STARS（多少次好评） OFFICIAL（官方）    AUTOMATED（自动化）
mysql                                                  MySQL is a widely used, open-source relation…   7964                [OK]
mariadb                                                MariaDB is a community-developed fork of MyS…   2665                [OK]
mysql/mysql-server                                     Optimized MySQL Server Docker images. Create…   598                                     [OK]
...
```

### docker pull

```shell
docker pull --help

Usage: docker pull [OPTIONS] NAME[:TAG|@DIGEST]

Pull an image or a repository from a registry

Options:
  -a, --all-tags                Download all tagged images in the repository
      --disable-content-trust   Skip image verification (default true)
```

例如，我们可以通过 `docker pull mysql` , 来下载最新版的mysql镜像。如果需要带上TAG，例如 `docker pull mysql:5.7`

### docker run

```shell
docker run --help

Usage: docker run [OPTIONS] IMAGE [COMMAND] [ARG...]

Run a command in a new container

Options(删除了一部分，详细的情况，可以自己查询):
      --add-host list                  Add a custom host-to-IP mapping (host:ip)
  -d, --detach                         Run container in background and print container ID
      --detach-keys string             Override the key sequence for detaching a container
      --device list                    Add a host device to the container
      --device-cgroup-rule list        Add a rule to the cgroup allowed devices list
      --device-read-bps list           Limit read rate (bytes per second) from a device (default [])
      --device-read-iops list          Limit read rate (IO per second) from a device (default [])
      --device-write-bps list          Limit write rate (bytes per second) to a device (default [])
      --device-write-iops list         Limit write rate (IO per second) to a device (default [])
      --disable-content-trust          Skip image verification (default true)
      --dns list                       Set custom DNS servers
      --dns-option list                Set DNS options
      --dns-search list                Set custom DNS search domains
      --entrypoint string              Overwrite the default ENTRYPOINT of the image
  -e, --env list                       Set environment variables
      --env-file list                  Read in a file of environment variables
      --expose list                    Expose a port or a range of ports
      --group-add list                 Add additional groups to join
      --health-cmd string              Command to run to check health
      --health-interval duration       Time between running the check (ms|s|m|h) (default 0s)
      --health-retries int             Consecutive failures needed to report unhealthy
      --health-start-period duration   Start period for the container to initialize before starting health-retries countdown (ms|s|m|h) (default 0s)
      --health-timeout duration        Maximum time to allow one check to run (ms|s|m|h) (default 0s)
      --help                           Print usage
  -h, --hostname string                Container host name
      --init                           Run an init inside the container that forwards signals and reaps processes
  -p, --publish list                   Publish a container's port(s) to the host
  -P, --publish-all                    Publish all exposed ports to random ports
      --read-only                      Mount the container's root filesystem as read only
      --restart string                 Restart policy to apply when a container exits (default "no")
      --rm                             Automatically remove the container when it exits
      --runtime string                 Runtime to use for this container
      --security-opt list              Security Options
      --shm-size bytes                 Size of /dev/shm
      --sig-proxy                      Proxy received signals to the process (default true)
      --stop-signal string             Signal to stop a container (default "SIGTERM")
      --stop-timeout int               Timeout (in seconds) to stop a container
      --storage-opt list               Storage driver options for the container
      --sysctl map                     Sysctl options (default map[])
      --tmpfs list                     Mount a tmpfs directory
  -t, --tty                            Allocate a pseudo-TTY
      --ulimit ulimit                  Ulimit options (default [])
  ...
  -v, --volume list                    Bind mount a volume
      --volume-driver string           Optional volume driver for the container
      --volumes-from list              Mount volumes from the specified container(s)
  -w, --workdir string                 Working directory inside the container
```

#### Mysql

```shell
docker run -p 3306:3306 --name mysql -v $PWD/conf:/etc/mysql/conf.d -v $PWD/logs:/logs -v $PWD/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=123456 -d mysql:5.6.43
```

- -p 3306:3306：将容器的 3306 端口映射到主机的 3306 端口。
- -v $PWD/conf:/etc/mysql/conf.d：将主机当前目录下的 conf/my.cnf 挂载到容器的 /etc/mysql/my.cnf。
- -v $PWD/logs:/logs：将主机当前目录下的 logs 目录挂载到容器的 /logs。
- -v $PWD/data:/var/lib/mysql ：将主机当前目录下的data目录挂载到容器的 /var/lib/mysql 。
- -e MYSQL_ROOT_PASSWORD=123456：初始化 root 用户的密码。

---

#### Redis

```shell
docker run -p 6379:6379 -v $PWD/data:/data --name redis  -d redis redis-server --appendonly yes
```

命令说明：

- -p 6379:6379 : 将容器的6379端口映射到主机的6379端口
- -v $PWD/data:/data : 将主机中当前目录下的data挂载到容器的/data
- redis-server --appendonly yes : 在容器执行redis-server启动命令，并打开redis持久化配置

---

#### Nginx

首先，我需要创建一下，文件夹,用于主宿机之间做映射使用。

```shell
mkdir -p {conf.d,html,logs}
```

```shell
docker run -p 80:80 -p 84:84 -p 82:82 --name nginx -v $PWD/www:/www -v $PWD/html:/usr/share/nginx/html -v $PWD/logs:/www/logs -v $PWD/conf.d:/etc/nginx/conf.d -d nginx
```

命令说明：

- -p 80:80：主机80到容器80，-p 84:84，同理（主机 -> 宿机）
- --name mynginx：将容器命名为nginx
- -v $PWD/www:/www：将主机中当前目录下的www挂载到容器的/www
- -v $PWD/conf/conf.d:/etc/nginx/conf.d：将主机中当前目录下的conf.d挂载到容器的/etc/nginx/conf.d 不能挂载文件，只能挂载文件夹
    > 注意如果提醒你，是否不应该将一个文件夹挂载到文件下面，我需要自己手动创建一个nginx.conf配置文件，并放置到主机的映射配置文件夹中（$PWD/conf），重新执行即可。如果出现了没有访问你配置的静态资源，很可能是访问到默认的配置（conf.d/default.conf）,可以选择删除它，也可以选择覆盖/etc/nginx/nginx.conf，但是前提需要备份原来的nginx.conf或者在原nginx.conf上做修改会更加适合。
- -v $PWD/html:/usr/share/nginx/html，讲主机中当前的目录下的文件夹挂载到容器中
    > 这里映射不正确，很有可能导致访问403     拒绝访问的情况，如果你的html不是资源访问的跟路径，请配置正确的根路径，例如，资源是放在html/hello的文件中，需要配置到$PWD/html/hello，而不是$PWD/html。
- -v $PWD/logs:/wwwlogs：将主机中当前目录下的logs挂载到容器的/wwwlogs

### docker ps

```shell
docker ps --help

Usage: docker ps [OPTIONS]

List containers

Options:
  -a, --all             Show all containers (default shows just running)
  -f, --filter filter   Filter output based on conditions provided
      --format string   Pretty-print containers using a Go template
  -n, --last int        Show n last created containers (includes all states) (default -1)
  -l, --latest          Show the latest created container (includes all states)
      --no-trunc        Don't truncate output
  -q, --quiet           Only display numeric IDs
  -s, --size            Display total file sizes
```

例如，我们可以运行 `docker ps -a` ,查询一下我们容器中启动的镜像的情况：

```shell
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                   PORTS               NAMES
4b9f565ae5ad        nginx               "nginx -g 'daemon of…"   8 hours ago         Up 4 minutes                0.0.0.0:84->80/tcp       nginx
46519e512d58        redis               "docker-entrypoint.s…"   10 hours ago        Up 5 minutes                0.0.0.0:6379->6379/tcp   redis
293c9831f58a        mysql:5.6.43        "docker-entrypoint.s…"   10 hours ago        Up 4 minutes                0.0.0.0:3306->3306/tcp   mysql
```

命令说明：

- -a Show all containers (default shows just running)，会显示所有存在的，默认是之后显示当前容器启动的镜像。

### docker stop

```shell
docker stop --help

Usage: docker stop [OPTIONS] CONTAINER [CONTAINER...]

Stop one or more running containers

Options:
  -t, --time int   Seconds to wait for stop before killing it (default 10)
```

### docker start

```shell
docker start --help

Usage: docker start [OPTIONS] CONTAINER [CONTAINER...]

Start one or more stopped containers，可以启动一个或者多个容器

Options:
  -a, --attach               Attach STDOUT/STDERR and forward signals
      --detach-keys string   Override the key sequence for detaching a container
  -i, --interactive          Attach container's STDIN
```

例如，我们可以通过 `docker start nginx mysql` ，同时启动两个容器

### docker exec

```shell
docker exec --help

Usage: docker exec [OPTIONS] CONTAINER COMMAND [ARG...]

Run a command in a running container

Options:
  -d, --detach               Detached mode: run command in the background
      --detach-keys string   Override the key sequence for detaching a container
  -e, --env list             Set environment variables
  -i, --interactive          Keep STDIN open even if not attached
      --privileged           Give extended privileges to the command
  -t, --tty                  Allocate a pseudo-TTY
  -u, --user string          Username or UID (format: <name|uid>[:<group|gid>])
  -w, --workdir string       Working directory inside the container
```

例如，我们可以通过命令快速进入到redis-cli，`docker exec -it redis redis-cli`
，输入`exit` 就可以推出

---

很多内容都是引用自：
> <http://www.runoob.com/docker/docker-tutorial.html>
> <https://www.docker-cn.com>