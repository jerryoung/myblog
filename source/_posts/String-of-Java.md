---
title: String of Java
date: 2019-08-25 23:56:36
tags: Java,Java基础,hash
---

## String 概括

> string 名次，意思可以翻译为：线，弦，细绳；一串，一行等

再来看看String的类图，String的value是不是感觉很应景呢？一个个字符，串起来变成我们熟悉的字符串。
[![mgkwsH.md.png](https://s2.ax1x.com/2019/08/25/mgkwsH.md.png)](https://imgchr.com/i/mgkwsH)
这里有两个关键的field：value和hash。

## String 三连击

### String变量到底存储在哪里？（JDK8)
```java
public class StringDemo {
    public static void main(String[] args) {
            String hello = "hello";
    }
```
通过命令 ` javap -v StringDemo.class` 对编译后的文件进行编码，会看到以下内容：

```java
public class cn.hy.study.string.StringDemo
  minor version: 0
  major version: 52
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:
   #1 = Methodref          #4.#20         // java/lang/Object."<init>":()V
   #2 = String             #16            // hello
```

可以看到，`hello` 这个字符串被存在了常量池（Constant pool）中，那么常量池又会存在哪里呢？

通过下面代码，我们来看看jdk 1.8 的常量池是存在哪一块：
```java
        String hello = "hello";
        ArrayList list = new ArrayList();
        for (; ; ) {
            String tmp = hello + new Random().nextInt();
            hello = tmp;
            list.add(tmp.intern());
        }
```
jvm参数添加：` -Xmx2m -XX:+PrintGCDetails ` 之后，运行不到一会儿，估计就会有下面的提醒了：

```java
1.8
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
	at java.util.Arrays.copyOf(Arrays.java:3332)
	at ...
```

```java
1.7
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
	at java.util.Arrays.copyOf(Arrays.java:2367)
```

```java
1.6
Exception in thread "main" java.lang.OutOfMemoryError: PermGen space
	at java.lang.String.intern(Native Method)
```

堆的内存分布：

```java
1.8
Heap
 PSYoungGen      total 1024K, used 17K [...)
  eden space 512K, 3% used [...)
  from space 512K, 0% used [...)
  to   space 512K, 0% used [...)
 ParOldGen       total 512K, used 401K [...)
  object space 512K, 78% used [...)
 Metaspace       used 2728K, capacity 4486K, committed 4864K, reserved 1056768K
  class space    used 291K, capacity 386K, committed 512K, reserved 1048576K

1.7
Heap
 PSYoungGen      total 2048K, used 22K [...)
  eden space 1024K, 2% used [...)
  from space 1024K, 0% used [...)
  to   space 1024K, 0% used [...)
 ParOldGen       total 4096K, used 267K [...)
  object space 4096K, 6% used [...)
 PSPermGen       total 21504K, used 2652K [...)
  object space 21504K, 12% used [...)

1.6
Heap
 par new generation   total 1152K, used 41K [...)
  eden space 1024K,   4% used [...)
  from space 128K,   0% used [...)
  to   space 128K,   0% used [...)
 concurrent mark-sweep generation total 5312K, used 279K [...)
 concurrent-mark-sweep perm gen total 83968K, used 4693K [...) 
```
我们知道jvm的内存结构，分为，堆、栈、方法区。从上面，我可以看到jdk 1.8 中字符串常量池存在于jvm的堆内存中。
综上所诉，可以看到

> 注：PermGen space 全程 Permanent Generation space 永久的产生的空间，也就是常说的永久代，在1.8以后已经被Meta space所代替。


### String哪个方法最重要？
从问题一我们可以知道，字符串是保存到常量池中，但是常量池中保存到字符串是如何快速返回字符串给调用方呢？如果让我来设计，我会将它放在哈希表中，通过合理设计hash函数，使得字符串合理分布在哈希表中，使得我们能迅速获取已经存在常量池中的字符串。
下面是String的hashCode方法：

```java
    /** Cache the hash code for the string */
    private int hash; // Default to 0
    public int hashCode() {
        int h = hash;
        if (h == 0 && value.length > 0) {
            char val[] = value;

            for (int i = 0; i < value.length; i++) {
                h = 31 * h + val[i];
            }
            hash = h;
        }
        return h;
    }
```

这里最难理解就是：

```java
    for (int i = 0; i < value.length; i++) {
        h = 31 * h + val[i];
    }
    --> s[0]*31^(n-1) + s[1]*31^(n-2) + ... + s[n-1]
```

这里为啥是`31 * h`
根据资料查阅，加上自己的一些理解，我觉得比较合理的解释：

- ` 31 * h == (h << 5) - h `，VM优化成位运算，使得计算hash code 性能更好

- 31 是一个不大不小的奇质数，也可以使得 `hashCode` 尽可能均匀分布。

除了以上，我们还可以发现一个有趣的地方 ` if (h == 0 && value.length > 0) ` ，这里用到了*闪存散列代码（caching the hash code）*，无需二次计算 `hash code`，是一个比较典型空间换时间的应用，它之所以行之有效，其实有一个大前提就是String是final/immutable。

> 哈希表，搜索的平均时间复杂度为：O(1)，最坏的时间复杂度：O(n)。
> 质数（Prime number），又称素数，指在大于1的自然数中，除了1和该数自身外，无法被其他自然数整除的数（也可定义为只有1与该数本身两个正因数的数）。

### String哪个方法体逻辑最难懂，分享出来。
个人觉得 `split` 方法是在String中相对比较难懂。
```java
        /* fastpath if the regex is a
         (1)one-char String and this character is not one of the 
            RegEx's meta characters ".$|()[{^?*+\\", or
         (2)two-char String and the first char is the backslash and
            the second is not the ascii digit or ascii letter.
         */
if (((regex.value.length == 1 &&
             ".$|()[{^?*+\\".indexOf(ch = regex.charAt(0)) == -1) ||
             (regex.length() == 2 &&
              regex.charAt(0) == '\\' &&
              (((ch = regex.charAt(1))-'0')|('9'-ch)) < 0 &&
              ((ch-'a')|('z'-ch)) < 0 &&
              ((ch-'A')|('Z'-ch)) < 0)) &&
            (ch < Character.MIN_HIGH_SURROGATE ||
             ch > Character.MAX_LOW_SURROGATE))
        {
```
这个if语句想判断 `regex` 是否为 `fastpath` 而不是正则表达式，否则直接跑下面的代码:
```java
        return Pattern.compile(regex).split(this, limit);
```
所以用这个API的时候，我们最好不要使用 `".$|()[{^?*+\\"` 中的字符来进行分割，如果实在要用 需要通过 `\\` 来转义。举个栗子：
```java
        String s = "A,b|中,c";
        for (String word :
                s.split("\\|")) {
            System.out.println(word);
        }
        
```
输出结果为：
```java
A,b
中,c
```
分析完，感觉最困难的`        return Pattern.compile(regex).split(this, limit);
` 并没有分析到，下次如果有深入了解正则表达式的想法可以死磕一波。

## 参考
- [Java 中的 String.hashCode\(\) 方法可能有问题？](https://www.infoq.cn/article/2018/08/java-stringhashcode-plenty)
- [why-does-javas-hashcode-in-string-use-31-as-a-multiplier](https://stackoverflow.com/questions/299304/why-does-javas-hashcode-in-string-use-31-as-a-multiplier)
- [科普：为什么 String hashCode 方法选择数字31作为乘子](https://segmentfault.com/a/1190000010799123)
- Effective Java
- 数据结构与算法分析 Java语言描述
