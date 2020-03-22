---
title: Hystrix 是如何工作？（翻译）
date: 2020-03-08 20:43:57
tags: Hystrix
---
> [原文链接](https://github.com/Netflix/Hystrix/wiki/How-it-Works)

## Hystrix-流程图

下图显示了通过Hystrix向服务依赖项请求时发生的情况：
![3zdwSU.png](https://s2.ax1x.com/2020/03/08/3zdwSU.png)

以下各节将更详细地说明此流程：

[1.构造一个HystrixCommand或HystrixObservableCommand对象](#1.构造一个HystrixCommand或HystrixObservableCommand对象)

[2.执行Command](#2.执行Command)

[3.响应是否缓存](#3.响应是否缓存)

[4.电路是否已经开路](#4.电路是否已经开路)

[5.线程池/队列/信号量是否已经满](#5.线程池/队列/信号量是否已经满)

[6.HystrixObservableCommand.construct()或者HystrixCommand.run()](#6.HystrixObservableCommand.construct()或者HystrixCommand.run())

[7.计算电路健康](#7.计算电路健康)

[8.获取后备](#8.获取后备)

[9.返回成功的响应](#9.返回成功的响应)

### 1.构造一个HystrixCommand或HystrixObservableCommand对象

第一步，是构造一个`HystrixCommand`或`HystrixObservableCommand`对象，以表示您对依赖项的请求。向构造函数传递发出请求时所需的任何参数。

如果期待依赖返回单个响应，则构造一个 [`HystrixCommand`](http://netflix.github.com/Hystrix/javadoc/index.html?com/netflix/hystrix/HystrixCommand.html)对象，例如

```java
HystrixCommand command = new HystrixCommand(arg1, arg2);
```

如果期待依赖项返回一个可发出响应的Observable，则构造一个  [`HystrixObservableCommand`](http://netflix.github.com/Hystrix/javadoc/index.html?com/netflix/hystrix/HystrixObservableCommand.html) 对象，例如

```java
HystrixObservableCommand command = new HystrixObservableCommand(arg1, arg2);
```

### 2.执行Command

使用Hystrix命令对象的以下四种方法之一，可以执行命令的方式有四种（前两种仅适用于简单的`HystrixCommand`对象，而不适用于`HystrixObservableCommand`）：

- [`execute()`](http://netflix.github.io/Hystrix/javadoc/com/netflix/hystrix/HystrixCommand.html#execute()) — 代码块，然后返回从依赖项收到单个响应（发生错误的情况下引发的异常）
- [`queue()`](http://netflix.github.io/Hystrix/javadoc/com/netflix/hystrix/HystrixCommand.html#queue()) — 返回一个 `Future` ，您可以使用它从依赖项获得单个响应
- [`observe()`](http://netflix.github.io/Hystrix/javadoc/com/netflix/hystrix/HystrixObservableCommand.html#observe()) — 订阅表示来自 依赖项的`Observable` 的响应，并返回复制源 `Observable` 的 `Observable`
- [`toObservable()`](http://netflix.github.io/Hystrix/javadoc/com/netflix/hystrix/HystrixObservableCommand.html#toObservable()) — 返回一个 `Observable` ,当您订阅它的时候，它将会执行Hystrix命令并发出其响应

```java
K             value   = command.execute();
Future<K>     fValue  = command.queue();
Observable<K> ohValue = command.observe();         //hot observable
Observable<K> ocValue = command.toObservable();    //cold observable
```

同步调用 `execute()` ，调用 `queue().get()`. `queue()` 依次调用`toObservable().toBlocking().toFuture()`. 就是说，最终每个 `HystrixCommand` 都由一个 [`Observable`](http://reactivex.io/documentation/observable.html) 实现, 即使那些只是想返回单个简单的命令也是如此

### 3.响应是否缓存

如果为此命令启用了请求缓存，并且如果对请求的响应在缓存中可用，则该缓存的响应将立即以`Observable` 的形式返回。  (See ["Request Caching"](http://localhost:4000/2020/03/08/Hystrix-How-it-Works/#请求缓存) below.)

### 4.电路是否已经开路

> 维基百科：[开路](https://zh.wikipedia.org/wiki/开路)
>
> 电路三种状态：
>
> ![电路三种状态](https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1583859175204&di=1633e5307bcabc79aed491ca0edf1c50&imgtype=0&src=http%3A%2F%2Fd.hiphotos.baidu.com%2Fzhidao%2Fwh%3D450%2C600%2Fsign%3Da148305f7af40ad115b1cfe7621c3de9%2Fb7fd5266d0160924002ba57cd50735fae6cd344e.jpg)

当你执行这个命令，`Hystrix` 会检查断路器，以查看断路器是否是`open`。

如果电路是`open`（或跳闸），然后`Hystrix`将不会执行这个命令，但将会路由路由到`8. Get the Fallback`。

如果电路是闭合的，则流程到`5. Semaphore/Thread pool rejected.`，以检查是否有可用于运行该命令的容量。

### 5.线程池/队列/信号量是否已经满

如果与该命令关联的线程池和队列（或信号量，如果没有运行在线程上）已满，则`Hystrix`将不会执行该命令，但会马上返回`8. Get the Fallback`

### 6.HystrixObservableCommand.construct()或者HystrixCommand.run()

在这里， `Hystrix` 通过为此目的编写方法（以下之一）调用对依赖项的请求:

- [`HystrixCommand.run()`](http://netflix.github.io/Hystrix/javadoc/com/netflix/hystrix/HystrixCommand.html#run()) — 返回单个响应或抛出异常
- [`HystrixObservableCommand.construct()`](http://netflix.github.io/Hystrix/javadoc/com/netflix/hystrix/HystrixObservableCommand.html#construct()) — 返回一个`Observable` ，它发出响应或发送`onError` 通知

If the `run()` or `construct()` method exceeds the command’s timeout value, the thread will throw a `TimeoutException` (or a separate timer thread will, if the command itself is not running in its own thread). In that case Hystrix routes the response through 8. Get the Fallback, and it discards the eventual return value `run()` or `construct()` method if that method does not cancel/interrupt.

如果`run（）`或`construct（）`方法的值超过了命令的超时的数值，则线程将抛出“ TimeoutException”（或者，如果命令本身未在其自己的线程中运行，则线程将抛出单独的计时器线程）。在那种情况下，Hystrix将响应路由到`8. Get the Fallback`，如果该方法没有取消/中断，则它会丢弃最终的返回值`run()` 或者`construct()` 方法。

请注意，没有办法强制潜在线程停止工作-Hystrix在JVM上可以做的最好的事情就是将其抛出InterruptedException。如果Hystrix封装的工作不遵守InterruptedExceptions，尽管客户端已经收到TimeoutException，Hystrix线程池中的线程仍将继续工作。尽管负载已“正确释放”，但此行为可能会使Hystrix线程池饱和。大多数Java HTTP客户端库不解释InterruptedExceptions。因此，请确保在HTTP客户端上正确配置连接和读取/写入超时。如果命令没有抛出任何异常，然后它会返回一个响应，则`Hystrix`在执行一些日志记录和监控报告后将返回此响应。对于`run`，`Hystrix`返回一个`Observable`，它发出单个响应，然后发出一个 `onCompleted`通知；对于 `construct()` ，`Hystrix`返回的是 `construct()`返回的`Observable`。

### 7.计算电路健康

`Hystrix` 向断路器 报告成功，失败，拒绝和超时，断路器保持滚动一个计数器来计算统计信息。它使用这些统计信息来确定断路器什么时候应该跳闸，这时他会将随后所有请求短路，直到经过恢复期为止，在此之后，在首先检查某些运行状况检查后，它将在此闭合电路。

### 8. 获取后备（Get the Fallback）

Hystrix tried to revert to your fallback whenever a command execution fails:

`Hystrix`尝试在命令执行失败时回复到您的后备状态：

- 当`construct（）`或`run（）`抛出异常时（6.）
- 当命令由于电路断开而短路时（4.）
- 命令的线程池和队列或信号量达到最大容量（5.）
- 命令超过其超时长度时。

编写您的后备，以从内存缓存中或者通过其他的静态逻辑提供通用的响应，而无需任何网络依赖性。如果你在后备中必须使用网络调用，您应该通过`HystrixCommand` 或 `HystrixObservableCommand` 来使用。

对于 `HystrixCommand`，要提供后备逻辑，请实现[`HystrixCommand.getFallback()`](http://netflix.github.io/Hystrix/javadoc/com/netflix/hystrix/HystrixCommand.html#getFallback())，它将会返回一个后备值。

对于`HystrixObservableCommand`，要提供后备逻辑，您可以实现[`HystrixObservableCommand.resumeWithFallback()`](http://netflix.github.io/Hystrix/javadoc/com/netflix/hystrix/HystrixObservableCommand.html#resumeWithFallback ())，它返回一个Observable，它可能会发出一个或多个后备值。

如果fallback方法返回响应，则Hystrix将将此响应返回给调用方。如果是`HystrixCommand.getFallback()`，它将返回一个Observable，该Observable发出从方法返回的值。对于`HystrixObservableCommand.resumeWithFallback()`，它将返回从方法返回的相同Observable。

如果尚未为`Hystrix`命令实现后备方法，或者后备本身引发异常，则Hystrix仍会返回一个Observable，但它不发出任何内容并立即以`onError`通知终止。通过此`onError`通知，导致命令失败的异常被发送回调用者。 （实施回退实现可能会失败，这是一个糟糕的做法。您应该实施回退，以使其不执行任何可能失败的逻辑。）

后备失败或不存在的后备结果将因调用`Hystrix`命令的方式而异：

- `execute()` — 抛出异常
- `queue()` — 成功返回 `Future`，但是这个 `Future`如果调用`get()`方法时候将会抛出异常
- `observe()` — 返回一个 `Observable` ，当你订阅它时，将通过调用订阅者的`onError` 方法立刻终止
- `toObservable()` — 返回一个 `Observable` ，当您订阅它时，将通过调用订阅者的`onError` 方法终止

### 9.返回成功的响应

如果`Hystrix`命令成功执行，它将以`Observable`的形式将一个或多个响应返回给调用方。根据您在上述第2步中调用命令的方式，此`Observable`可能会在返回给您之前进行转换：

[![8yU8AK.png](https://s1.ax1x.com/2020/03/19/8yU8AK.png)](https://imgchr.com/i/8yU8AK)

- `execute()` —  以与`.queue()` 相同的方式获取`Future`，然后在此`Future`调用`get`以获取`Observable` 发出的单个值。
- `queue()` — 将 `Observable` 转换为 `BlockingObservable` ，以便于可以将其转换成一个 `Future`，然后返回`Future`。
- `observe()` — 立即定于 `Observable` 并开始执行命令的流程；返回一个 `Observable` ，当您 `subscribe（订阅）` 它时候，将重新发出和通知。
- `toObservable()` — 不变地返回 `Observable` ； 您必须 `subscribe（订阅）` 它，才能真正开始真正执行命令的流程。

## 时序图

@adrianb11 has kindly provided a [sequence diagram](https://design.codelytics.io/hystrix/how-it-works) demonstrating the above flows.（Note: 需要梯子喔。）

参考上面，自己也有手撸了一个：

![86icFS.png](https://s1.ax1x.com/2020/03/19/86icFS.png)

## 断路器（熔断器）

下面展示了 `HystrixCommand` 或者 `HystrixObservableCommand` 如何与 [`HystrixCircuitBreaker`](http://netflix.github.io/Hystrix/javadoc/index.html?com/netflix/hystrix/HystrixCircuitBreaker.html) 交互，以及其逻辑和决策流程，包括计数器在断路器中的行为方式。

![86kkNT.png](https://s1.ax1x.com/2020/03/19/86kkNT.png)

电路打开和闭合的精确方式如下：

1. 假设电路上的容量达到某个阈值(`HystrixCommandProperties.circuitBreakerRequestVolumeThreshold()`)...
2. 并假设误差百分比超过阈值误差百分比(`HystrixCommandProperties.circuitBreakerErrorThresholdPercentage()`)...
3. 断路器从 `CLOSED` 状态转换成 `OPEN`状态。
4. 当它断开时，它会使针对该断路器的所有请求短路。
5. 一段时间后(`HystrixCommandProperties.circuitBreakerSleepWindowInMilliseconds()`)，下一个单个请求被允许通过（这是`HALF-OPEN(半开)`状态）。如果请求失败，断路器将在睡眠窗口期间返回`OPEN`状态。如果请求成功，断路器将切换到`CLOSED` 然后回到1.中的逻辑。

## 隔离（Isolation）

Hystrix使用隔板模式将依赖关系彼此隔离，并限制对其中任何一个的并发访问。

![82UKHA.png](https://s1.ax1x.com/2020/03/20/82UKHA.png)

## 线程和线程池

客户端（库，网络调用等）在单独的线程上执行。这样可以将它们与调用线程（Tomcat线程池）隔离，以便调用者可以“摆脱”花费太长时间的依赖项调用。

Hystrix使用单独的，每个依赖关系的线程池作为约束任何给定依赖关系的方式，因此对基础执行的延迟将仅使该池中的可用线程饱和。

![82aUxO.png](https://s1.ax1x.com/2020/03/20/82aUxO.png)

您可以在不使用线程池的情况下防止失败，但这需要信任的客户端非常快速地失败（网络连接/读取超时和重试配置），并且始终表现良好。

Netflix在Hystrix的设计中选择使用线程和线程池来实现隔离的原因很多，其中包括：

- 许多应用程序会针对许多不同团队开发的数十种不同服务执行数十种（有时甚至超过100种）不同的后端服务调用。
- 每个服务都提供自己的客户端库。
- 客户端库一直在变化
- 客户端库逻辑可以更改以添加新的网络调用。
- 客户端库可以包含诸如重试，数据解析，缓存（内存中或跨网络）之类的逻辑，以及其他此类行为。
- 客户端库往往是“黑匣子”-用户对其实现细节，网络访问模式，配置默认值等不透明。
- 在实际的几次生产中断中，确定为“哦，某些更改并且应该调整属性”或“客户端库更改了其行为”。
- 即使客户端本身没有变化，服务本身也会发生变化，从而影响性能特征，进而导致客户端配置无效
- 传递依赖关系可能会引入其他意外的客户端库，这些客户端库可能不是预期的，而且配置可能不正确。
- 大部分的网络访问是同步进行。
- 故障和延迟也可能在客户端代码中发生，而不仅仅是在网络调用中。

### 线程池的好处

通过自己线程池中的线程进行隔离的好处是：

- 该应用程序受到完全保护，不受客户端库的攻击。给定依赖库的池可以填满，而不会影响应用程序的其余部分。
- 该应用程序可以接受风险更低的新客户端库。如果发生问题，它将隔离到库中，并且不会影响其他所有问题。
- 当发生故障的客户端再次恢复正常运行时，线程池将被清除，应用程序将立即恢复运行正常的性能，与整个Tomcat容器不堪重负的长时间恢复相反。
- 如果客户端库配置错误，线程池的运行状况将迅速证明这一点（通过增加错误，延迟，超时，拒绝等），您可以处理它（通常通过动态属性实时进行）而不会影响应用程序功能。
- 如果客户端服务更改了性能特征（通常会经常出现问题），进而导致需要调整属性（增加/减少超时，更改重试次数等），则可以通过线程池指标（错误，延迟）再次看到该特征，超时，拒绝），并且可以在不影响其他客户端，请求或用户的情况下进行处理。
- 除了隔离优势之外，拥有专用线程池还可以提供内置的并发性，可以利用这些并发性在同步客户端库之上构建异步外观（类似于Netflix API如何在Hystrix命令之上构建一个reactive，采用完全异步的Java API）。

![8207FA.png](https://s1.ax1x.com/2020/03/20/8207FA.png)

简而言之，线程池提供的隔离允许客户端库和子系统性能特征的不断变化和动态组合得到优雅处理，而不会造成中断。

注意：尽管有单独的线程提供了隔离，但您的基础客户端代码也应具有超时和/或对线程中断的响应，因此它不能无限期地阻塞并使Hystrix线程池饱和。

### 线程池的缺点

线程池的主要缺点是它们增加了计算开销。每个命令执行都涉及在单独的线程上运行命令所涉及的队列，调度和上下文切换。

Netflix API使用线程隔离每天处理10+亿次Hystrix Command执行。每个API实例有40多个线程池，每个线程池中有5-20个线程（大多数设置为10）。

### 线程的成本

![thread-cost-60rps-original.png](https://github.com/Netflix/Hystrix/wiki/images/thread-cost-60rps-original.png)

在中位数（或更低）处，拥有一个单独的线程没有成本。

在第90个百分位数处，拥有一个单独的线程需要花费3ms的时间。

在第99个百分位数处，拥有一个单独的线程要花费9ms。但是请注意，成本的增加远远小于单独线程（网络请求）的执行时间的增加，后者从2跳到28，而成本从0跳到9。

对于这样的电路，这种开销在90％或更高的百分比上被认为对于大多数Netflix用例都是可以接受的，以实现所具有的弹性。

对于包装延迟非常低的请求的电路（例如那些主要访问内存缓存的请求），开销可能会过高，在这种情况下，您可以使用另一种方法，例如可尝试的信号量，尽管它们不允许超时，提供最大的弹性优势，而没有开销。但是，总的来说开销很小，以至于Netflix实际上通常比这种技术更喜欢使用单独线程的隔离优势。

### 信号灯（Semaphores）

您可以使用信号量（或计数器）将并发调用的数量限制为任何给定的依赖项，而不是使用线程池/队列大小。这使Hystrix无需使用线程池就可以减轻负载，但它不允许超时和退出。如果您信任客户端，并且只希望减少负载，则可以使用这种方法。

`HystrixCommand` and `HystrixObservableCommand` 在2个地方支持信号灯:

- **Fallback:** Hystrix检索回退时，总是在调用Tomcat线程上进行回退。
- **Execution:** 如果将属性`execution.isolation.strategy`设置为`SEMAPHORE`，则Hystrix将使用信号量而不是线程来限制调用该命令的并发父线程的数量

您可以通过定义可以执行多少个并发线程的动态属性来配置信号灯的这两种用法。您应该使用与确定线程池大小时相似的计算方法来确定它们的大小（在不到毫秒的时间内返回的内存中调用的性能可以超过5000rps，并且信号量仅为1或2…但默认值为10）。

注意：如果依赖关系被信号量隔离，然后变为潜在状态，则父线程将保持阻塞状态，直到基础网络调用超时为止。

一旦达到限制，信号灯拒绝将开始，但是填充信号灯的线程无法终止。

## 请求折叠（Request Collapsing）

您可以在`HystrixCommand`前面加上请求折叠程序（[`HystrixCollapser`](http://netflix.github.io/Hystrix/javadoc/index.html?com/netflix/hystrix/HystrixCollapser.html)是抽象父级），您可以将多个请求折叠为一个后端依赖项调用。

下图显示了两种情况下的线程和网络连接数：首先是没有连接，然后是请求折叠（假设所有连接在较短的时间范围内（在这种情况下为10ms）在“并发”状态）。

![82RCtS.png](https://s1.ax1x.com/2020/03/20/82RCtS.png)

### 请求折叠-时序图

@adrianb11 has kindly provided a [sequence diagram](https://design.codelytics.io/hystrix/request-collapsing) of request-collapsing（Note: 需要梯子喔。）
同样手撸一个图，如果想了解大概流程，可以参考上面的链接：
![8ICSXT.png](https://s1.ax1x.com/2020/03/22/8ICSXT.png)

### 为什么使用请求折叠

使用请求折叠可减少执行并发`HystrixCommand`执行所需的线程数和网络连接数。请求折叠以一种自动化的方式完成，不会强制所有代码库的开发人员协调手动的请求批处理。

#### 全局上下文 (Across All Tomcat Threads)

理想的折叠类型是在全局应用程序级别完成的，因此可以将来自任何Tomcat线程上任何用户的请求一起折叠。

例如，如果将`HystrixCommand`配置为支持对检索电影分级的依赖项的所有用户的批处理，则当同一JVM中的任何用户线程发出这样的请求时，Hystrix都会将其请求与其他任何请求一起添加到同一JVM中网络通话崩溃。

请注意，折叠器会将单个`HystrixRequestContext`对象传递给折叠的网络调用，因此下游系统必须处理这种情况才能使其成为有效的选择。

#### 用户请求的上下文 (Single Tomcat Thread)

如果将`HystrixCommand`配置为仅处理单个用户的批处理请求，则Hystrix可以折叠单个Tomcat线程（请求）中的请求。

例如，如果用户想为300个视频对象加载书签，而不是执行300个网络调用，Hystrix可以将它们全部合并为一个。

#### 对象建模和代码复杂度

有时，当您创建对对象的使用者具有逻辑意义的对象模型时，与对象的生产者的有效资源利用并不十分匹配。

例如，给定一个300个视频对象的列表，对其进行迭代并在每个对象上调用`getSomeAttribute()`是一个显而易见的对象模型，但是如果天真地实现了，则可能会导致300个网络调用之间相互之间的毫秒数（并且很可能会占用资源）。

有一些手动方法可以处理此问题，例如在允许用户调用`getSomeAttribute()`之前，要求他们声明要为其获取属性的视频对象，以便可以全部提取它们。

或者，您可以划分对象模型，以便用户必须从一个地方获取视频列表，然后从其他地方询问该视频列表的属性。

这些方法可能导致笨拙的API和对象模型与思维模型和使用模式不匹配。当多个开发人员在一个代码库上工作时，它们还可能导致简单的错误和效率低下，因为针对一个用例进行的优化可能会因另一用例的实现和代码的新路径而中断。

通过将折叠逻辑推到Hystrix层，无论如何创建对象模型，以什么顺序进行调用，或者不同的开发人员是否知道已完成优化或什至需要完成优化都无关紧要.

可以将`getSomeAttribute()`方法放在最合适的位置，并以适合使用模式的任何方式调用它，然后折叠器将自动将调用批量处理到时间窗口中。

#### 请求折叠的成本是多少

启用请求折叠的代价是在执行实际命令之前增加了等待时间。最大成本是批处理窗口的大小。

如果您有一条命令需要花费5ms的中位数执行时间和10ms的批处理窗口，则在最坏的情况下执行时间可能变为15ms。通常，一个请求不会在打开时就被提交到窗口，因此中值损失是窗口时间的一半，在这种情况下为5ms。

确定此成本是否值得取决于所执行的命令。高延迟命令不会受到少量额外平均延迟的影响。同样，给定命令的并发量很关键：如果很少有超过1或2个请求被批处理在一起，那么付出代价是没有意义的。实际上，在单线程顺序迭代中，折叠将是主要的性能瓶颈，因为每次迭代将等待10ms的批处理窗口时间。

但是，如果特定命令被大量同时使用，并且可以将数十个甚至数百个呼叫分批处理。然后，由于Hystrix减少了所需的线程数以及与依存关系的网络连接数，因此获得的吞吐量通常远远超过了成本。

#### 折叠流程图

![82TSJ0.png](https://s1.ax1x.com/2020/03/20/82TSJ0.png)

## 请求缓存

`HystrixCommand`和`HystrixObservableCommand`实现可以定义一个缓存键，然后将其用于以并发感知的方式对请求上下文中的重复数据进行重复数据删除。

这是一个示例流程，涉及一个HTTP请求生命周期和两个在该请求中工作的线程：

请求缓存的好处是：

- 不同的代码路径可以执行Hystrix命令，而无需担心重复的工作。

这在大型代码库中特别有用，在该代码库中许多开发人员正在实现不同的功能。

例如，所有需要获得用户的`Account`对象的代码的多个路径都可以这样请求：

```java
Account account = new UserGetAccount(accountId).execute();

//or

Observable<Account> accountObservable = new UserGetAccount(accountId).observe();
```

Hystrix `RequestCache`将一次且仅执行一次基础`run()`方法，并且尽管实例化了不同的实例，但执行`HystrixCommand`的两个线程仍将接收相同的数据。

- 整个请求中的数据检索都是一致的。

不是每次执行命令时都可能返回不同的值（或回退），而是对同一请求内的所有后续调用进行缓存并返回第一个响应。

- 消除重复线程执行

由于请求缓存位于`construct()`或`run()`方法调用的前面，因此Hystrix可以在导致线程执行之前对重复数据删除重复数据。

如果Hystrix没有实现请求缓存功能，则每个命令都需要自己在`construct()`或`run()`方法内部实现它，这会将其放在线程排队和执行之后。
