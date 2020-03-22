---
title: 《Netty in Action》 读后感
date: 2020-02-07 21:59:12
tags: netty
---

## 开编我想说

> 刻意练习，本着课本的例子，照着我也写一遍的原则进行练习。

  基础知识真的太重要，很多基础知识是会影响我们阅读书的效果，甚至可能会误解书本的原意。就拿着当前阅读的书来说起，如果我们不知道计算机操作系统基础，不知Java网络编程基础，不知网络协议等，那么我们看书可能会举步维艰。所以，在看本书之前，我尝试查阅一些相关资料，以补充能够更好吸收书本知识。
  
  本文章，就是书本很多地方的内容，并未能深刻理解，一本书的内容也不可能全部呈现。例如，零拷贝，各种网络协议的理解，例如tcp，udp协议等。很多基础内容，都感觉相对薄弱，所以日后需要加强基础的部分。
 看完，你可能会有以下收获：
  Netty核心组件、重新认识字节、关于Netty单元测试、编码器和解码器、WebSocket简单的聊天室

## 阅读前的预习，大有裨益

- 同步和异步的概念

>同步，是一个可靠的有序操作，例如，有顺序执行操作A->操作B，如果操作A没有完成返回，操作B需要排队等候；反之，异步则相反无需等待，通常可以依靠回调或者事件的方式来进行操作的次序的问题。

- 堵塞和非堵塞

>在进行阻塞操作时，当前线程会处于阻塞状态，无法从事其他任务，只有当条件就绪才能继续，比如 ServerSocket 新连接建立完毕，或数据读取、写入操作完成；而非阻塞则是不管 IO 操作是否结束，直接返回，相应操作在后台继续处理。

- 查询常见的I/O模型：I/O堵塞;I/O非堵塞;I/O复用；信号驱动I/O；异步I/O
![1cIMQI.png](https://s2.ax1x.com/2020/02/07/1cIMQI.png)

- 用户空间和系统空间

>现在操作系统都是采用虚拟存储器，那么对32位操作系统而言，它的寻址空间（虚拟存储空间）为4G（2的32次方）。操作系统的核心是内核，独立于普通的应用程序，可以访问受保护的内存空间，也有访问底层硬件设备的所有权限。为了保证用户进程不能直接操作内核（kernel），保证内核的安全，操心系统将虚拟空间划分为两部分，一部分为内核空间，一部分为用户空间。针对linux操作系统而言，将最高的1G字节（从虚拟地址0xC0000000到0xFFFFFFFF），供内核使用，称为内核空间，而将较低的3G字节（从虚拟地址0x00000000到0xBFFFFFFF），供各个进程使用，称为用户空间。[摘抄自这里](https://yuelng.github.io/2018/03/16/computer_science/network_coding/)

- Linux 操作系统中select、poll、epoll
[详细内容可以查看](https://www.cnblogs.com/binarylei/p/11130079.html#select-api)
- High-Performance I/O Design Patterns
[详细内容可以看](https://www.artima.com/articles/io_design_patterns.html)

## 概述

> Netty is an asynchronous event-driven network application framework
for rapid development of maintainable high performance protocol servers & clients.

   从上面我抽取了三个关键词，asynchronous、event-driven、high performance。带着三个关键信息，看能够从书中摄取到三个核心的内容。

## 核心内容

### 核心组件

#### Channel

> Channel，是出入站数据的载体，或者是网络中Socket抽象代表。
> 目的：Channel为了降低直接使用Java中Socket API的复杂度。

Channel的生命周期：register->active->inactive->unregistred

#### EventLoop

> 用于处理连接的生命周期的中发生的事件

Channel、EventLoop和EventLoopGroup的关系图
![1czd5n.png](https://s2.ax1x.com/2020/02/07/1czd5n.png)

图中可以看到EventLoopGroup其实就具有多个EventLoop的组，EventLoop会在Channel的整个生命周期处理I/O事件。
三者关系如下：

- 一个EventLoopGroup包含一个或者多个EventLoop
- 一个EventLoop一个生命周期中，只和一个线程绑定
- EventLoop所有I/O处理事件，将有专用的线程处理
- 一个Channel生命周期，只会注册到一个EventLoop上
- 一个EventLoop可以会分配多个Channel

得益于EventLoop是一个固定的线程处理，给定的Channel上的I/O的处理将会在同一个线程处理，避免了不必要的线程切换上下文的开销；

下面来深入了解一下，EventLoop：
先通过类图去纵览
![1guZWT.png](https://s2.ax1x.com/2020/02/07/1guZWT.png)

- java.util.concurrent
AbstractExecutorService主要是实现了ExecutorService接口，ScheduledExecutorService则是继承了ExecutorService；
- io.netty.utilconcurrent
AbstractEventExecutor，继承了AbstractExecutorService类，并且实现EventExecutor接口，
- io.netty.channel
EventLoop，继承了OrderedEventExecutor, EventLoopGroup，只有一个：EventLoopGroup parent()方法。
SingleThreadEventLoop，继承SingleThreadEventExecutor，并且实现EventLoop接口；
重头戏来了，NioEventLoop，是继承了SingleThreadEventLoop，正如上面所说的：``一个EventLoop一个生命周期中，只和一个线程绑定``

EventLoop的执行逻辑：
![1g3qc6.png](https://s2.ax1x.com/2020/02/07/1g3qc6.png)

#### ChannelPipeline

> pipeline，意译为管道，ChannelPipeline，一看到这个名字，我们能够猜到它的作用就是类似管道的作用。
> 目的：为了提供ChannelHandler链式容器（ChannelHandler在下一节介绍）

![1gpYkj.png](https://s2.ax1x.com/2020/02/07/1gpYkj.png)

本节，需要了解pipeline它的头部和尾部的概念，入站从头部第一个ChannelHandler先入，出站的时候从尾端端第一个ChannelHandler先开始流出。

顺便提一下，Channel一旦分配为ChannelPipeline后，是永久性操作，不能被修改。
通过 DefaultChannelPipeline 和 AbstractChannel 源代码分析，也能得到上面的结论：

```java
AbstractChannel
    protected AbstractChannel(Channel parent) {
    ...
        pipeline = newChannelPipeline();// 新建分配一个ChannelPipeline
    }
```

```java
DefaultChannelPipeline
    protected DefaultChannelPipeline(Channel channel) {
    ...
        this.channel = ObjectUtil.checkNotNull(channel, "channel");
    }
```

最后，上面的设计使得，我们 **变动（增删改）** ChannelPipeline上的Handler也是相当方便的。

#### ChannelHandler

> ChannelHandler，它充当了所有处理入站和出站数据的应用程序逻辑的容器。
ChannelHandler生命周期：added->removed (excption)
通过ChannelHandler再来看出入站的概念：
入站，就是数据流要进行我们的服务前置的业务处理。出站，就是我们需要返回数据流时候的后置业务处理。当然我们还是需要谨记，上一节的pipeline的头部和尾端的概念，不然会容易出或者入站的handler出现位置不对的情况。

- ChannelInboundHandler 入站处理器接口，处理入站数据和状态变化
列出我在练习中常用的方法：

|类　　型|描　　述|
| --- | --- |
| channelRegistered |  当Channel已经注册到它的EventLoop并且能够处理I/O时被调用|
| channelUnregistered | 当Channel从它的EventLoop注销并且无法处理任何I/O时被调用 |
| channelActive |当Channel处于活动状态时被调用；Channel已经连接/绑定并且已经就绪  |
| channelInactive | 当Channel离开活动状态并且不再连接它的远程节点时被调用 |
| channelReadComplete | 当Channel上的一个读操作完成时被调用|
| channelRead | 当从Channel读取数据时被调用 |
| userEventTriggered | 当ChannelnboundHandler.fireUserEventTriggered()方法被调用时被调用，因为一个POJO被传经了ChannelPipeline |

我们可以通过继承 ChannelInboundHandlerAdapter 来编写自己的入站处理器。常用的是：SimpleChannelInboundHandler，因为它给我优化了一些常用的操作，例如，资源的自动释放等

异常处理：
exceptionCaught，这个方法在 ChannelInboundHandlerAdapter 已经标记被弃用，

- ChannelOutboundHandler 出站处理器接口，处理出站的所有数据，并且能够拦截所有的操作。
列出我在练习中常用的方法：

|类　　型|描　　述|
| --- | --- |
| bind(ChannelHandlerContext,SocketAddress,ChannelPromise) |当请求将Channel绑定到本地地址时被调用|
| connect(ChannelHandlerContext,SocketAddress,SocketAddress,ChannelPromise)当 | 请求将Channel连接到远程节点时被调用 |
| disconnect(ChannelHandlerContext,ChannelPromise) |当请求将Channel从远程节点断开时被调用|
| close(ChannelHandlerContext,ChannelPromise) | 当请求关闭Channel时被调用 |
| deregister(ChannelHandlerContext,ChannelPromise) | 当请求将Channel从它的EventLoop注销时被调用|
| read(ChannelHandlerContext) | 当请求从Channel读取更多的数据时被调用 |
| flush(ChannelHandlerContext) | 当请求通过Channel将入队数据冲刷到远程节点时被调用 |
| write(ChannelHandlerContext,Object,ChannelPromise) | 当请求通过Channel将数据写到远程节点时被调用 |

异常处理：
两种方式：

1. 在出站操作都会返回ChannelFuture，进行添加监听事件
2. 在ChannelOutboundHandler的入参都会带有ChannelPromis，进行添加监听事件
方式2更加常用，因为相对方式1相关更加简单有效。

#### ChannelHandlerContext

紧接上面，我来看一下Channel、ChannelPipeline、ChannelHandler和ChannelHandlerContext之间的关系：
![123uKf.png](https://s2.ax1x.com/2020/02/07/123uKf.png)
当ChannelHandler添加到ChannelPipeline到时候，ChannelHandlerContext将会被创建。

ChannelHandler高级用法：我们可以在使用ChannelHandler可以缓存ChannelHanlderContext，然后去完成一些复杂的操作。
但是这里是有一个前提，就是当前ChannelHandler应该是被@Sharable注释，因为一个ChannelHandler可能属于多个ChannelPipeline。在使用@Sharable之前，最好确保当前ChannelHandler是线程安全。

#### ChannelFuture

> Netty提供了ChannelFuture接口，其addListener()方法注册了一个ChannelFutureListener，以便在某个操作完成时（无论是否成功）得到通知。

#### Bootstrap

![1gyOJ0.png](https://s2.ax1x.com/2020/02/07/1gyOJ0.png)

- 引导客户端 和 无连接协议
引导流程如下：
![1g6GSf.png](https://s2.ax1x.com/2020/02/07/1g6GSf.png)

```java
public final class EchoClient {

    static final boolean SSL = System.getProperty("ssl") != null;
    static final String HOST = System.getProperty("host", "127.0.0.1");
    static final int PORT = Integer.parseInt(System.getProperty("port", "8023"));

    public static void main(String[] args) throws Exception {
        // Configure SSL.git
        final SslContext sslCtx;
        if (SSL) {
            sslCtx = SslContextBuilder.forClient()
                    .trustManager(InsecureTrustManagerFactory.INSTANCE).build();
        } else {
            sslCtx = null;
        }

        // Configure the client.
        EventLoopGroup group = new NioEventLoopGroup();
        try {
            Bootstrap b = new Bootstrap();
            b.group(group)
                    .channel(NioSocketChannel.class)
                    .handler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        public void initChannel(SocketChannel ch) throws Exception {
                            ChannelPipeline p = ch.pipeline();
                            if (sslCtx != null) {
                                p.addLast(sslCtx.newHandler(ch.alloc(), HOST, PORT));
                            }
                            p.addLast(
                                    new CustomSimpleChannelInboundHandler())
                            ;
                        }
                    });

            // 在connect方法调用后，Bootstrap类将会创建一个新的Channel
            ChannelFuture f = b.connect(HOST, PORT).sync();

            // Wait until the connection is closed.
            f.channel().closeFuture().sync();
        } finally {
            // Shut down the event loop to terminate all threads.
            group.shutdownGracefully();
        }
    }
}

```

- 引导服务器

引导流程如下：
![1g6tOg.png](https://s2.ax1x.com/2020/02/07/1g6tOg.png)

```java
public final class EchoServer {

    static final boolean SSL = System.getProperty("ssl") != null;
    static final int PORT = Integer.parseInt(System.getProperty("port", "8007"));
    public static final String SECOND_HANDLER_NAME = "second";

    public static void main(String[] args) throws Exception {
        // Configure SSL.
        final SslContext sslCtx;
        if (SSL) {
            SelfSignedCertificate ssc = new SelfSignedCertificate();
            sslCtx = SslContextBuilder.forServer(ssc.certificate(), ssc.privateKey()).build();
        } else {
            sslCtx = null;
        }

        // Configure the server.
        EventLoopGroup bossGroup = new NioEventLoopGroup(1);
        EventLoopGroup workerGroup = new NioEventLoopGroup(2);
        final EchoServerHandler serverHandler = new EchoServerHandler();
        try {
            ServerBootstrap b = new ServerBootstrap();
            b.group(bossGroup, workerGroup)
                    .channel(NioServerSocketChannel.class)
                    .option(ChannelOption.SO_BACKLOG, 100)
                    .handler(new LoggingHandler(LogLevel.INFO))
                    .childHandler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        public void initChannel(SocketChannel ch) throws Exception {
                            ChannelPipeline p = ch.pipeline();
                            if (sslCtx != null) {
                            p.addLast(sslCtx.newHandler(ch.alloc()));
                            p.addLast(serverHandler);
                        }
                    });

            // Start the server.
            ChannelFuture f = b.bind(PORT).sync();

            // Wait until the server socket is closed.
            f.channel().closeFuture().sync();
        } finally {
            // Shut down all event loops to terminate all threads.
            bossGroup.shutdownGracefully();
            workerGroup.shutdownGracefully();
        }
    }
}

```

- 引导DatagramChannel  
Netty提供了各种DatagramChannel的实现，它唯一的区别就是不能使用connect方法，只能调用bind方法。

- 如何优雅关闭客户端和服务端

> 我主要需要关闭我们创建EventLoopGroup，我们可以通过```shutdownGracefully```方法来优雅地关闭。

```java
    @Override
    public Future<?> shutdownGracefully(long quietPeriod, long timeout, TimeUnit unit) {
        for (EventExecutor l: children) {
            l.shutdownGracefully(quietPeriod, timeout, unit);
        }
        return terminationFuture();
    }
```

### 重新认识字节

> The byte is a unit of digital information that most commonly consists of eight bits. Historically, the byte was the number of bits used to encode a single character of text in a computer and for this reason it is the smallest addressable unit of memory in many computer architectures
> 记住：8 bit = 1 byte

为啥说重新认识了字节，因为自己在学习ByteBuf的时候犯了一些低级的错误（单元测试将呈现我的低级错误），反应出来自己的基础还是不够牢固。
下面这通过练习的例子，来认识一下Netty强大的字节容器：ByteBuff

> ByteBuff，实现原理有两个索引指针，一个用于读取（readerIndex），一个用于写入（writerIndex）。

下面的例子详细说，不同ByteBuff的使用模式：

```java
public class ByteBuffExample {
    public static final String HI_BYTE_BUFF = "Hi! ByteBuff.";
    private static final ByteBuf heapBuff = Unpooled.copiedBuffer(HI_BYTE_BUFF, CharsetUtil.UTF_8);
    public static final Charset UTF_8 = CharsetUtil.UTF_8;

    public static void main(String[] args) {
        // 堆缓冲区
        System.out.println("==================heap buff==================");
        heapByteBuff();
        System.out.println("==================direct buff==================");
        directByteBuff();
        System.out.println("==================composite buff==================");
        compositeByteBuff();
        System.out.println("==================read and write==================");
        readAndWrite();
        System.out.println("==================ByteBufHolder==================");
        byteBuffHolder();
    }

    /**
     * 存储在 JVM 堆空间中，这种模式被成为支撑数据（backing array）
     */
    public static void heapByteBuff() {
        if (heapBuff.hasArray()) {
            byte[] array = heapBuff.array();
            int offset = heapBuff.arrayOffset() + heapBuff.readerIndex();
            int length = heapBuff.readableBytes();
            byte[] target = new byte[length];
            System.arraycopy(array, offset, target, 0, length);
            System.out.println(new String(target));
        }
    }

    /**
     * 直接缓冲区是另外一种ByteBuf模式。
     * 我们期望用于对象创建的内存分配永远都来自于堆中，
     * 但这并不是必须的——NIO在JDK1.4中引入的ByteBuffer类允许JVM实现通过本地调用来分配内存。
     * 这主要是为了避免在每次调用本地I/O操作之前（或者之后）
     * 将缓冲区的内容复制到一个中间缓冲区（或者从中间缓冲区把内容复制到缓冲区）。
     *
     * 它的缺点主要：
     * 1. 分配和释放表昂贵
     * 2. 如果在处理预留代码的时候，可能不得不又复制一遍。
     *
     * 建议：如果在知道数据将被作为数据来访问的时候，我们更加推荐使用 堆内存 。
     *
     */
    private static void directByteBuff() {
        ByteBuf directBuffer = Unpooled.directBuffer().writeBytes(heapBuff);
        // 检查buf是否有数组，如果不是，则说明一个直接堆缓冲区
        if (!directBuffer.hasArray()) {
            int readerIndex = directBuffer.readerIndex();
            int length = directBuffer.readableBytes();
            byte[] array = new byte[length];
            directBuffer.getBytes(readerIndex, array);
            System.out.println(new String(array));
        }
    }

    /**
     * 复合缓冲区，它提供一种聚合模式给我们使用。例如我需要组合一个协议，
     * 我们需要一部分装配头部信息，一部分装配主体信息。
     */
    private static void compositeByteBuff() {
        CompositeByteBuf compositeByteBuf = Unpooled.compositeBuffer();
        ByteBuf headBuf = Unpooled.copiedBuffer("Hi! ", CharsetUtil.UTF_8);
        ByteBuf bodyBuf = Unpooled.copiedBuffer("ByteBuff.", CharsetUtil.UTF_8);
        compositeByteBuf.addComponents(headBuf, bodyBuf);
        System.out.println("compositeByteBuf.removeComponent(0) before:");
        for (ByteBuf byteBuf : compositeByteBuf) {
            System.out.println(byteBuf.toString(CharsetUtil.UTF_8));
        }
        System.out.println("compositeByteBuf.removeComponent(0) after:");
        compositeByteBuf.removeComponent(0);
        for (ByteBuf byteBuf : compositeByteBuf) {
            System.out.println(byteBuf.toString(CharsetUtil.UTF_8));
        }
    }

    /**
     * 主要是一些字节操作API的使用。
     */
    private static void readAndWrite() {
        ByteBuf byteBuf = Unpooled.copiedBuffer(HI_BYTE_BUFF, CharsetUtil.UTF_8);
        System.out.println(byteBuf.toString(CharsetUtil.UTF_8));
        // slice，分片，但是不会修改索引信息
        ByteBuf slice = byteBuf.slice(0, 3);
        // 拷贝操作，不影响原对象
        ByteBuf copy = byteBuf.copy(0, 3);
        assert !ByteBufUtil.equals(slice, copy);
        System.out.println(slice.toString(CharsetUtil.UTF_8));
        byteBuf.setByte(0, ((byte) 'J'));
        copy.setByte(0, ((byte) 'W'));
        assert byteBuf.getByte(0) == slice.getByte(0);
        assert copy.getByte(0) != byteBuf.getByte(0);
        System.out.println(((char) byteBuf.getByte(0)));
        int readerIndex = byteBuf.readerIndex();
        int writerIndex = byteBuf.writerIndex();
        byteBuf.setByte(1, ((byte) 'B'));
        System.out.println(((char) byteBuf.getByte(1)));
        assert readerIndex == byteBuf.readerIndex();
        assert writerIndex == byteBuf.writerIndex();
        // 写一个字节，将会影响writerIndex索引。
        byteBuf.writeByte(((byte) '?'));
        assert readerIndex == byteBuf.readerIndex();
        assert writerIndex != byteBuf.writerIndex();
    }

    private static void byteBuffHolder() {
        ByteBufHolder byteBufHolder = new DefaultByteBufHolder(Unpooled.copiedBuffer(HI_BYTE_BUFF, UTF_8));
        ByteBuf content = byteBufHolder.copy().content();
        content.setByte(0, ((byte) 'W'));
        System.out.println("source: " + ((char) heapBuff.getByte(0)));
        System.out.println("new: " + ((char) content.getByte(0)));
    }

}

```

### 解码器和编码器

#### 解码器

总体来说，我们有两种需求：

- 字节解码成消息，常用抽象类：ByteToMessageDecoder extends ChannelInboundHandlerAdapter
- 消息A解码成消息B，常用抽象类：MessageToMessageDecoder extends ChannelInboundHandlerAdapter
它们都是继承 ChannelInboundHandlerAdapter，又是熟悉的味道，这个又是得益Netty统一的设计。
流程图如下：
![1gv0E9.png](https://s2.ax1x.com/2020/02/07/1gv0E9.png)

#### 编码器

总体来说，我们有两种需求：

- 消息编码成消息，常用抽象类：MessageToByteEncoder extends ChannelOutboundHandlerAdapter
- 消息B编码成消息A，常用抽象类：MessageToMessageEncoder extends ChannelOutboundHandlerAdapter
它们都是继承了ChannelOutboundHandlerAdapter。
流程图如下：
![1gzNTJ.png](https://s2.ax1x.com/2020/02/07/1gzNTJ.png)

#### 抽象的编解码类

很多时候，编解码是一对，我们就想着为啥不能直接设置成一个类？Netty给我们，预设Codec。

- 字节编解码成消息，ByteToMessageCodec extend ChannelDuplexHandler
- 消息编解码成消息，MessageToMessageCodec extend ChannelDuplexHandler
ChannelDuplexHandler extends ChannelInboundHandlerAdapter implements ChannelOutboundHandler

#### HttpObjectAggregator 源码分析

```java
HttpObjectAggregator
        extends MessageAggregator<HttpObject, HttpMessage, HttpContent, FullHttpMessage>
```

核心逻辑其实是在 MessageAggregator 中 decode 方法中

```java
@Override
    protected void decode(final ChannelHandlerContext ctx, I msg, List<Object> out) throws Exception {
        assert aggregating;
        // HttpObjectAggregator.isStartMessage:
        // return msg instanceof HttpMessage;
        if (isStartMessage(msg)) {
            handlingOversizedMessage = false;
            if (currentMessage != null) {
                currentMessage.release();
                currentMessage = null;
                throw new MessageAggregationException();
            }

            @SuppressWarnings("unchecked")
            S m = (S) msg;

            // Send the continue response if necessary (e.g. 'Expect: 100-continue' header)
            // Check before content length. Failing an expectation may result in a different response being sent.
            Object continueResponse = newContinueResponse(m, maxContentLength, ctx.pipeline());
            if (continueResponse != null) {
                // Cache the write listener for reuse.
                // 缓存起来监听器方便重用，监听器作用：如果调用不成功，则调用fireExceptionCaught方法，抛出异常
                ChannelFutureListener listener = continueResponseWriteListener;
                if (listener == null) {
                    continueResponseWriteListener = listener = new ChannelFutureListener() {
                        @Override
                        public void operationComplete(ChannelFuture future) throws Exception {
                            if (!future.isSuccess()) {
                                ctx.fireExceptionCaught(future.cause());
                            }
                        }
                    };
                }

                // Make sure to call this before writing, otherwise reference counts may be invalid.
                boolean closeAfterWrite = closeAfterContinueResponse(continueResponse);
                handlingOversizedMessage = ignoreContentAfterContinueResponse(continueResponse);

                final ChannelFuture future = ctx.writeAndFlush(continueResponse).addListener(listener);

                if (closeAfterWrite) {
                    future.addListener(ChannelFutureListener.CLOSE);
                    return;
                }
                if (handlingOversizedMessage) {
                    return;
                }
            } else if (isContentLengthInvalid(m, maxContentLength)) {
                // if content length is set, preemptively close if it's too large
                invokeHandleOversizedMessage(ctx, m);
                return;
            }

            if (m instanceof DecoderResultProvider && !((DecoderResultProvider) m).decoderResult().isSuccess()) {
                O aggregated;
                if (m instanceof ByteBufHolder) {
                    // retain方法：将引用增加+1（Netty中，如果引用值为0，则会被回收），以防止被回收
                    // 开始聚合操作由子类实现对应的操作
                    aggregated = beginAggregation(m, ((ByteBufHolder) m).content().retain());
                } else {
                    aggregated = beginAggregation(m, EMPTY_BUFFER);
                }
                // 完成聚合操作，finishAggregation0 中调用了 finishAggregation,其中finishAggregation由子类实现。
                // HttpObjectAggregator中实现了，增加了rfc2616 14.13 Content-Length 判断，如果没有响应体头部那样设置 'Content-Length'，则根据 aggregated.content().readableBytes() 设置一个值
                finishAggregation0(aggregated);
                out.add(aggregated);
                return;
            }

            // A streamed message - initialize the cumulative buffer, and wait for incoming chunks.
            CompositeByteBuf content = ctx.alloc().compositeBuffer(maxCumulationBufferComponents);
            if (m instanceof ByteBufHolder) {
                appendPartialContent(content, ((ByteBufHolder) m).content());
            }
            currentMessage = beginAggregation(m, content);
        } else if (isContentMessage(msg)) {
            if (currentMessage == null) {
                // it is possible that a TooLongFrameException was already thrown but we can still discard data
                // until the begging of the next request/response.
                return;
            }

            // Merge the received chunk into the content of the current message.
            CompositeByteBuf content = (CompositeByteBuf) currentMessage.content();

            @SuppressWarnings("unchecked")
            final C m = (C) msg;
            // Handle oversized message.
            if (content.readableBytes() > maxContentLength - m.content().readableBytes()) {
                // By convention, full message type extends first message type.
                @SuppressWarnings("unchecked")
                S s = (S) currentMessage;
                invokeHandleOversizedMessage(ctx, s);
                return;
            }

            // Append the content of the chunk.
            appendPartialContent(content, m.content());

            // Give the subtypes a chance to merge additional information such as trailing headers.
            aggregate(currentMessage, m);

            final boolean last;
            // 主要判断 是否为 最后的消息了，如果是最后的消息，将进行添加输出列表out中
            if (m instanceof DecoderResultProvider) {
                DecoderResult decoderResult = ((DecoderResultProvider) m).decoderResult();
                if (!decoderResult.isSuccess()) {
                    if (currentMessage instanceof DecoderResultProvider) {
                        ((DecoderResultProvider) currentMessage).setDecoderResult(
                                DecoderResult.failure(decoderResult.cause()));
                    }
                    last = true;
                } else {
                    last = isLastContentMessage(m);
                }
            } else {
                last = isLastContentMessage(m);
            }

            if (last) {
                finishAggregation0(currentMessage);

                // All done
                out.add(currentMessage);
                currentMessage = null;
            }
        } else {
            throw new MessageAggregationException();
        }
    }
```

### 不可被忽略的单元测试

```java
/**
 * AbsIntegerEncoder 测试类
 *
 * @author wusonghui@bubi.cn
 * @date 2020-02-02 21:26
 * @since 1.0.0
 */
public class AbsIntegerEncoder extends MessageToMessageEncoder<ByteBuf> {

    @Override
    protected void encode(ChannelHandlerContext ctx, ByteBuf msg, List<Object> out) throws Exception {
            // 这里就是我犯下的低级错误，当时没有想明白，为啥是4呢？
            // 如果我们知道int是占4个字节，就很容易理解了。
            // 也是从这里，让我反思。
        while (msg.readableBytes() >= 4) {
            int value = Math.abs(msg.readInt());
            out.add(value);
        }
    }
}
```

```java
public class AbsIntegerEncoderTest {

    @Test
    public void testAbsIntegerEncoder() {
        ByteBuf byteBuf = Unpooled.buffer();
        for (int i = 0; i < 10; i++) {
            byteBuf.writeInt(i * -1);
        }
        EmbeddedChannel channel = new EmbeddedChannel(new AbsIntegerEncoder());
        Assert.assertTrue(channel.writeOutbound(byteBuf));
        Assert.assertTrue(channel.finish());
        for (int i = 0; i < 10; i++) {
            Assert.assertEquals(i, ((int) channel.readOutbound()));
        }
        Assert.assertNull(channel.readOutbound());
    }
}
```

```java
/**
 * 自定义待测试待 解码器
 *
 * @author wusonghui@bubi.cn
 * @date 2020-02-02 20:56
 * @since 1.0.0
 */
public class FixedLengthFrameDecoder extends ByteToMessageDecoder {
    private final int frameLength;

    public FixedLengthFrameDecoder(int frameLength) {
        if (frameLength <= 0) {
            throw new IllegalArgumentException("frameLength must be a positive integer: " + frameLength);
        }
        this.frameLength = frameLength;
    }

    @Override
    protected void decode(ChannelHandlerContext ctx, ByteBuf in, List<Object> out) throws Exception {
        while (in.readableBytes() >= frameLength) {
            ByteBuf buf = in.readBytes(frameLength);
            out.add(buf);
        }
    }
}

```

```java
public class FrameChunkDecoderTest {
    @Test
    public void testFrameChunkDecoderException() {
        ByteBuf byteBuf = Unpooled.buffer();
        for (int i = 0; i < 10; i++) {
            byteBuf.writeByte(i);
        }
        ByteBuf input = byteBuf.duplicate();
        EmbeddedChannel channel = new EmbeddedChannel(new FrameChunkDecoder(3));
        Assert.assertTrue(channel.writeInbound(input.readBytes(2)));
        try {
            channel.writeInbound(input.readBytes(4));
            Assert.fail();
        } catch (Exception e) {
            Assert.assertTrue(e instanceof TooLongFrameException);
        }
        Assert.assertTrue(channel.writeInbound(input.readBytes(3)));

        Assert.assertTrue(channel.finish());

        ByteBuf read = channel.readInbound();
        Assert.assertEquals(byteBuf.readSlice(2), read);
        read.release();

        read = channel.readInbound();
        Assert.assertEquals(byteBuf.skipBytes(4).readSlice(3), read);
        read.release();

        Assert.assertNull(channel.readInbound());
        byteBuf.release();
    }
}
```

## 网络协议

### 使用WebSocket

> WebSocket ，WebSocket协议是完全重新设计的协议，旨在为Web上的双向数据传输问题提供一个切实可行的解决方案，使得客户端和服务器之间可以在任意时刻传输消息，因此，这也就要求它们异步地处理消息回执。

使用WebSocket实现一个简单的聊天室，总体架构图如下：
![12ZsXj.png](https://s2.ax1x.com/2020/02/07/12ZsXj.png)
服务器的流程图如下：
![12Z6ns.png](https://s2.ax1x.com/2020/02/07/12Z6ns.png)

大概代码结构如下：

```code
src
├─main
    ├─java
        ├─handler
            ├─HttpRequestHandler
            ├─TextWebSocketFrameHandler
        ├─initializer
            ├─ChatServerInitializer
            ├─SecureChatServerInitializer
        ├─server
            ├─ChatServer
            ├─SecureChatServer
    ├─resource
    ├─index.html
├─test
├─pom.xml
```

```java
import io.netty.channel.*;
import io.netty.handler.codec.http.*;
import io.netty.handler.ssl.SslHandler;
import io.netty.handler.stream.ChunkedNioFile;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.RandomAccessFile;
import java.net.URISyntaxException;
import java.net.URL;

/**
 * HttpRequestHandler
 *
 * @author wusonghui@bubi.cn
 * @date 2020-02-05 15:25
 * @since 1.0.0
 */
public class HttpRequestHandler extends SimpleChannelInboundHandler<FullHttpRequest> {
    private final String wsUri;
    private static File INDEX;

    static {
        URL location = HttpRequestHandler.class.getProtectionDomain().getCodeSource().getLocation();
        String path;
        try {
            path = location.toURI() + "index.html";
            path = !path.contains("file:") ? path : path.substring(5);
            INDEX = new File(path);
            if (!INDEX.exists()) {
                throw new FileNotFoundException("path :" + path + " not found");
            }
        } catch (URISyntaxException | FileNotFoundException e) {
            e.printStackTrace();
        }
    }

    public HttpRequestHandler(String wsUri) {
        this.wsUri = wsUri;
    }

    @Override
    protected void channelRead0(ChannelHandlerContext ctx, FullHttpRequest request) throws Exception {
        if (wsUri.equalsIgnoreCase(request.uri())) {
            ctx.fireChannelRead(request.retain());
        } else {
            if (HttpUtil.is100ContinueExpected(request)) {
                send100Continue(ctx);
            }
            RandomAccessFile file = new RandomAccessFile(INDEX, "r");
            HttpResponse response = new DefaultHttpResponse(request.protocolVersion(), HttpResponseStatus.OK);
            response.headers().set(HttpHeaderNames.CONTENT_TYPE, "text/html; charset=UTF-8");
            boolean keepAlive = HttpUtil.isKeepAlive(request);
            if (keepAlive) {
                response.headers().set(HttpHeaderNames.CONTENT_LENGTH, file.length());
                response.headers().set(HttpHeaderNames.CONNECTION, HttpHeaderValues.KEEP_ALIVE);
            }
            ctx.write(response);
            if (ctx.pipeline().get(SslHandler.class) == null) {
                ctx.write(new DefaultFileRegion(file.getChannel(), 0, file.length()));
            } else {
                ctx.write(new ChunkedNioFile(file.getChannel()));
            }
            ChannelFuture future = ctx.writeAndFlush(LastHttpContent.EMPTY_LAST_CONTENT);
            if (!keepAlive) {
                future.addListener(ChannelFutureListener.CLOSE);
            }
        }
    }

    private static void send100Continue(ChannelHandlerContext ctx) {
        FullHttpResponse response = new DefaultFullHttpResponse(HttpVersion.HTTP_1_1, HttpResponseStatus.CONTINUE);
        ctx.writeAndFlush(response);
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        cause.printStackTrace();
        ctx.close();
    }
}

```

```java
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.SimpleChannelInboundHandler;
import io.netty.channel.group.ChannelGroup;
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame;
import io.netty.handler.codec.http.websocketx.WebSocketServerProtocolHandler;

/**
 * TextWebSocketFrameHandler
 *
 * @author wusonghui@bubi.cn
 * @date 2020-02-05 15:58
 * @since 1.0.0
 */
public class TextWebSocketFrameHandler extends SimpleChannelInboundHandler<TextWebSocketFrame> {

    private final ChannelGroup group;

    public TextWebSocketFrameHandler(ChannelGroup group) {
        this.group = group;
    }

    @Override
    public void userEventTriggered(ChannelHandlerContext ctx, Object evt) throws Exception {
        if (evt instanceof WebSocketServerProtocolHandler.HandshakeComplete) {
            ctx.pipeline().remove(HttpRequestHandler.class);
            group.writeAndFlush(new TextWebSocketFrame("Client " + ctx.channel() + " joined"));
            group.add(ctx.channel());
        } else {
            super.userEventTriggered(ctx, evt);
        }
    }

    @Override
    protected void channelRead0(ChannelHandlerContext ctx, TextWebSocketFrame msg) throws Exception {
        group.writeAndFlush(msg.retain());
    }
}

```

```java
import io.netty.channel.Channel;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelPipeline;
import io.netty.channel.group.ChannelGroup;
import io.netty.example.ws.handler.HttpRequestHandler;
import io.netty.example.ws.handler.TextWebSocketFrameHandler;
import io.netty.handler.codec.http.HttpObjectAggregator;
import io.netty.handler.codec.http.HttpServerCodec;
import io.netty.handler.codec.http.websocketx.WebSocketServerProtocolHandler;
import io.netty.handler.logging.LogLevel;
import io.netty.handler.logging.LoggingHandler;
import io.netty.handler.stream.ChunkedWriteHandler;

/**
 * ChatServerInitializer
 *
 * @author wusonghui@bubi.cn
 * @date 2020-02-05 16:08
 * @since 1.0.0
 */
public class ChatServerInitializer extends ChannelInitializer<Channel> {
    private final ChannelGroup group;

    public ChatServerInitializer(ChannelGroup group) {
        this.group = group;
    }

    @Override
    protected void initChannel(Channel ch) throws Exception {
        ChannelPipeline pipeline = ch.pipeline();
        pipeline.addLast(new HttpServerCodec())
                .addLast(new ChunkedWriteHandler())
                .addLast(new HttpObjectAggregator(64 * 1024))
                .addLast(new HttpRequestHandler("/ws"))
                .addLast(new WebSocketServerProtocolHandler("/ws"))
                .addLast(new TextWebSocketFrameHandler(group))
                .addLast(new LoggingHandler(LogLevel.INFO))
        ;
    }
}
```

```java
import io.netty.channel.Channel;
import io.netty.channel.group.ChannelGroup;
import io.netty.handler.ssl.SslContext;
import io.netty.handler.ssl.SslHandler;

import javax.net.ssl.SSLEngine;

/**
 * SecureChatServerInitializer
 *
 * @author wusonghui@bubi.cn
 * @date 2020-02-05 21:38
 * @since 1.0.0
 */
public class SecureChatServerInitializer extends ChatServerInitializer {
    private final SslContext sslContext;

    public SecureChatServerInitializer(ChannelGroup channelGroup, SslContext sslContext) {
        super(channelGroup);
        this.sslContext = sslContext;
    }

    @Override
    protected void initChannel(Channel ch) throws Exception {
        super.initChannel(ch);
        SSLEngine engine = sslContext.newHandler(ch.alloc()).engine();
        engine.setUseClientMode(false);
        ch.pipeline().addFirst(new SslHandler(engine));
    }
}
```

```java

import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.Channel;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.group.ChannelGroup;
import io.netty.channel.group.DefaultChannelGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.example.ws.initializer.ChatServerInitializer;
import io.netty.util.concurrent.ImmediateEventExecutor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.InetSocketAddress;
import java.util.Objects;

/**
 * ChatServer
 *
 * @author wusonghui@bubi.cn
 * @date 2020-02-05 16:29
 * @since 1.0.0
 */
public class ChatServer {
    private final ChannelGroup channelGroup = new DefaultChannelGroup(ImmediateEventExecutor.INSTANCE);
    private final EventLoopGroup bossGroup = new NioEventLoopGroup(1);
    private final EventLoopGroup workGroup = new NioEventLoopGroup(2);
    private Channel channel;
    protected final static String SERVER_PORT = System.getProperty("port", "9999");
    private final static Logger logger = LoggerFactory.getLogger(ChatServer.class);

    protected ChannelFuture start() {
        int port = Integer.parseInt(SERVER_PORT);
        ServerBootstrap serverBootstrap = new ServerBootstrap();
        serverBootstrap.group(bossGroup, workGroup)
                .channel(NioServerSocketChannel.class)
                .childHandler(createInitializer(channelGroup));
        ChannelFuture future = serverBootstrap.bind(new InetSocketAddress(port));
        future.syncUninterruptibly();
        channel = future.channel();
        Runtime.getRuntime().addShutdownHook(new Thread(this::destroy));
        Objects.requireNonNull(future).channel().closeFuture().syncUninterruptibly();
        if (future.isSuccess()) {
            logger.info("Chat Server start, port: {}", port);
        } else {
            logger.info("Chat Server start failed, port: {}", port);
        }
        return future;
    }

    protected ChannelInitializer<Channel> createInitializer(ChannelGroup channelGroup) {
        return new ChatServerInitializer(channelGroup);
    }

    protected void destroy() {
        if (channel != null) {
            channel.close();
        }
        channelGroup.close();
        bossGroup.shutdownGracefully();
        workGroup.shutdownGracefully();
    }

    public static void main(String[] args) {
        new ChatServer().start();
    }
}

```

```java
import io.netty.channel.Channel;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.group.ChannelGroup;
import io.netty.example.ws.initializer.SecureChatServerInitializer;
import io.netty.handler.ssl.SslContext;
import io.netty.handler.ssl.SslContextBuilder;
import io.netty.handler.ssl.util.SelfSignedCertificate;

import javax.net.ssl.SSLException;
import java.security.cert.CertificateException;

/**
 * SecureChatServer
 *
 * @author wusonghui@bubi.cn
 * @date 2020-02-05 21:35
 * @since 1.0.0
 */
public class SecureChatServer extends ChatServer {
    private final SslContext sslContext;

    public SecureChatServer(SslContext sslContext) {
        this.sslContext = sslContext;
    }

    @Override
    protected ChannelInitializer<Channel> createInitializer(ChannelGroup channelGroup) {
        return new SecureChatServerInitializer(channelGroup, sslContext);
    }

    public static void main(String[] args) {
        try {
            SelfSignedCertificate certificate = new SelfSignedCertificate();
            SslContext sslContext = SslContextBuilder.forServer(certificate.certificate(), certificate.privateKey()).build();
            new SecureChatServer(sslContext).start();
        } catch (SSLException | CertificateException e) {
            e.printStackTrace();
        }
    }
}

```

## 最后聊聊

连续差不多两周的学习，通过看书+练习的操作，让自己能够将书上的知识，真的运用起来，并且进一步加深理解。
刻意练习真的太重要，如果光看不练，就是纸上谈兵。
