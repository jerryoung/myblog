---
title: Java的包装类型
date: 2019-04-03 11:11:35
tags: Java,Java基础,Java数据类型
---
# Java的包装类型

## 概述

顾名思义，包装类型就是对基本类型的封装的对象。

基本类型 | 包装类型 |大小 |默认值
---|---|---|---
boolean|Boolean|1B|false
byte|Byte|1B|0
short|Short|2B|0
char|Character|2B|'\u0000'
int|Integer|4B|0
long|Long|8B|0L
float|Float|4B|0.0f
double|Double|8B|0.0d

## 包装类型

为啥需要包装类型？
将基本类型封装成对象，提供更多的功能，解决基础类型无法解决的问题：泛型类型参数、序列化、数据类型转换、高频区间数据缓存。
例如：

* 泛型类型参数的问题：`List<int> list;` 这种定义是否无法通过编译的，需要将`int` 转成对应的包装类型 `Integer` ，才运行添加到集合中；
* 类型转换的问题：提供 `Integer.valueOf("123")` 将字符串转成数字的功；
* 高频区间数据缓存的问题：`Integer.java` 源码中 `valueOf(int i)` 的方法，提供 `-128~127`高频区间的数据缓存。

    ```java
        public static Integer valueOf(int i) {
            if (i >= IntegerCache.low && i <= IntegerCache.high)
                return IntegerCache.cache[i + (-IntegerCache.low)];
            return new Integer(i);
        }
    ```

## 包装类型和基本类型的互相转化

JDk 5 以前没有自动拆装箱，可以通过下面的方式进行装箱和拆箱：

```java
    // 装箱
    Long wrapperLong = new Long(1);
    // 拆箱
    long aLong = wrapperLong.longValue();
```

拥有了自动拆装箱的代码，相对会简洁一些：

```java
    // 自动装箱
    Long wrapperLong = 1L;
    // 自动拆箱
    long aLong = wrapperLong;
```

## 简单的例子，说明一下它们的区别

***源代码：***

```java
/**
 * 基础类型学习，如果两个数 相等，相加后返回，否则直接返回第一个参数。
 *
 * @author wusonghui@bubi.cn
 * @since 1.0.0 2019-04-02 15:01
 */
public class PrimitiveTypeStudy {

    public static void main(String[] args) {
        // 自动装箱
        Long wrapperLong = 1L;
        // 自动拆箱
        long aLong = wrapperLong;
        add(Long.valueOf(1L), Long.valueOf(1L));
        add(Long.valueOf(1L), 1L);
        add(1L, 1L);
    }

    /**
     * 测试 所有数据都为 长整型 包装类型
     *
     * @param first  长整型 包装类型
     * @param second 长整型 包装类型
     * @return 长整型 包装类型
     */
    public static Long add(Long first, Long second) {
        if (first.equals(second)) {
            return first + second;
        }
        return first;
    }

    /**
     * 测试 second 参数为 基本类型，其他均为 包装类型
     *
     * @param first  长整型 包装类型
     * @param second 长整型 基本类型
     * @return 长整型 包装类型
     */
    public static long add(Long first, long second) {
        if (first.equals(second)) {
            return first + second;
        }
        return first;
    }

    /**
     * 测试 所有数据都为 长整型 基本类型
     *
     * @param first  长整型 基本类型
     * @param second 长整型 基本类型
     * @return 长整型 包装类型
     */
    public static long add(long first, long second) {
        if (first == second) {
            return first + second;
        }
        return first;
    }


}
```

***反编译回来的代码：***

```java
package cn.hy.study.basictype;

import java.io.PrintStream;

public class PrimitiveTypeStudy
{
  public static void main(String[] args)
  {
    Long wrapperLong = Long.valueOf(1L);
    long aLong = wrapperLong.longValue();
    add(Long.valueOf(1L), Long.valueOf(1L));
    add(Long.valueOf(1L), 1L);
    add(1L, 1L);
  }
  
  public static Long add(Long first, Long second)
  {
    if (first.equals(second)) {
      return Long.valueOf(first.longValue() + second.longValue());
    }
    return first;
  }
  
  public static long add(Long first, long second)
  {
    if (first.equals(Long.valueOf(second))) {
      return first.longValue() + second;
    }
    return first.longValue();
  }
  
  public static long add(long first, long second)
  {
    if (first == second) {
      return first + second;
    }
    return first;
  }
}

```

***通过***`javap -v -p PrimitiveTypeStudy.class` ***命令生成，字节码内容，为了对比的效果，我在前后加入反编译后的代码：***

```java
Classfile /Users/jaryoung/project/demo/javabasic/out/production/classes/cn/hy/study/basictype/PrimitiveTypeStudy.class
  Last modified Apr 3, 2019; size 1530 bytes
  MD5 checksum db6d2b4373555e4e52196d58a3ba87b5
  Compiled from "PrimitiveTypeStudy.java"
public class cn.hy.study.basictype.PrimitiveTypeStudy
  minor version: 0
  major version: 52
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:
   #1 = Methodref          #19.#44        // java/lang/Object."<init>":()V
   #2 = Class              #45            // java/lang/Long
   #3 = Methodref          #2.#46         // java/lang/Long."<init>":(J)V
   #4 = Methodref          #2.#47         // java/lang/Long.longValue:()J
   #5 = Fieldref           #48.#49        // java/lang/System.out:Ljava/io/PrintStream;
   #6 = Class              #50            // java/lang/StringBuilder
   #7 = Methodref          #6.#44         // java/lang/StringBuilder."<init>":()V
   #8 = String             #51            //
   #9 = Methodref          #6.#52         // java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
  #10 = Methodref          #6.#53         // java/lang/StringBuilder.append:(J)Ljava/lang/StringBuilder;
  #11 = Methodref          #6.#54         // java/lang/StringBuilder.toString:()Ljava/lang/String;
  #12 = Methodref          #55.#56        // java/io/PrintStream.println:(Ljava/lang/String;)V
  #13 = Methodref          #2.#57         // java/lang/Long.valueOf:(J)Ljava/lang/Long;
  #14 = Methodref          #18.#58        // cn/hy/study/basictype/PrimitiveTypeStudy.add:(Ljava/lang/Long;Ljava/lang/Long;)Ljava/lang/Long;
  #15 = Methodref          #18.#59        // cn/hy/study/basictype/PrimitiveTypeStudy.add:(Ljava/lang/Long;J)J
  #16 = Methodref          #18.#60        // cn/hy/study/basictype/PrimitiveTypeStudy.add:(JJ)J
  #17 = Methodref          #2.#61         // java/lang/Long.equals:(Ljava/lang/Object;)Z
  #18 = Class              #62            // cn/hy/study/basictype/PrimitiveTypeStudy
  #19 = Class              #63            // java/lang/Object
  #20 = Utf8               <init>
  #21 = Utf8               ()V
  #22 = Utf8               Code
  #23 = Utf8               LineNumberTable
  #24 = Utf8               LocalVariableTable
  #25 = Utf8               this
  #26 = Utf8               Lcn/hy/study/basictype/PrimitiveTypeStudy;
  #27 = Utf8               main
  #28 = Utf8               ([Ljava/lang/String;)V
  #29 = Utf8               args
  #30 = Utf8               [Ljava/lang/String;
  #31 = Utf8               wrapperLong
  #32 = Utf8               Ljava/lang/Long;
  #33 = Utf8               aLong
  #34 = Utf8               J
  #35 = Utf8               add
  #36 = Utf8               (Ljava/lang/Long;Ljava/lang/Long;)Ljava/lang/Long;
  #37 = Utf8               first
  #38 = Utf8               second
  #39 = Utf8               StackMapTable
  #40 = Utf8               (Ljava/lang/Long;J)J
  #41 = Utf8               (JJ)J
  #42 = Utf8               SourceFile
  #43 = Utf8               PrimitiveTypeStudy.java
  #44 = NameAndType        #20:#21        // "<init>":()V
  #45 = Utf8               java/lang/Long
  #46 = NameAndType        #20:#64        // "<init>":(J)V
  #47 = NameAndType        #65:#66        // longValue:()J
  #48 = Class              #67            // java/lang/System
  #49 = NameAndType        #68:#69        // out:Ljava/io/PrintStream;
  #50 = Utf8               java/lang/StringBuilder
  #51 = Utf8
  #52 = NameAndType        #70:#71        // append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
  #53 = NameAndType        #70:#72        // append:(J)Ljava/lang/StringBuilder;
  #54 = NameAndType        #73:#74        // toString:()Ljava/lang/String;
  #55 = Class              #75            // java/io/PrintStream
  #56 = NameAndType        #76:#77        // println:(Ljava/lang/String;)V
  #57 = NameAndType        #78:#79        // valueOf:(J)Ljava/lang/Long;
  #58 = NameAndType        #35:#36        // add:(Ljava/lang/Long;Ljava/lang/Long;)Ljava/lang/Long;
  #59 = NameAndType        #35:#40        // add:(Ljava/lang/Long;J)J
  #60 = NameAndType        #35:#41        // add:(JJ)J
  #61 = NameAndType        #80:#81        // equals:(Ljava/lang/Object;)Z
  #62 = Utf8               cn/hy/study/basictype/PrimitiveTypeStudy
  #63 = Utf8               java/lang/Object
  #64 = Utf8               (J)V
  #65 = Utf8               longValue
  #66 = Utf8               ()J
  #67 = Utf8               java/lang/System
  #68 = Utf8               out
  #69 = Utf8               Ljava/io/PrintStream;
  #70 = Utf8               append
  #71 = Utf8               (Ljava/lang/String;)Ljava/lang/StringBuilder;
  #72 = Utf8               (J)Ljava/lang/StringBuilder;
  #73 = Utf8               toString
  #74 = Utf8               ()Ljava/lang/String;
  #75 = Utf8               java/io/PrintStream
  #76 = Utf8               println
  #77 = Utf8               (Ljava/lang/String;)V
  #78 = Utf8               valueOf
  #79 = Utf8               (J)Ljava/lang/Long;
  #80 = Utf8               equals
  #81 = Utf8               (Ljava/lang/Object;)Z
{
  public cn.hy.study.basictype.PrimitiveTypeStudy();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 14: 0
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0       5     0  this   Lcn/hy/study/basictype/PrimitiveTypeStudy;
    /*
    public static void main(String[] args)
    {
        Long wrapperLong = Long.valueOf(1L);
        long aLong = wrapperLong.longValue();
        add(Long.valueOf(1L), Long.valueOf(1L));
        add(Long.valueOf(1L), 1L);
        add(1L, 1L);
    }
    */
  public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=4, locals=4, args_size=1
         0: new           #2                  // class java/lang/Long
         3: dup
         4: lconst_1
         5: invokespecial #3                  // Method java/lang/Long."<init>":(J)V
         8: astore_1
         9: aload_1
        10: invokevirtual #4                  // Method java/lang/Long.longValue:()J
        13: lstore_2
        14: getstatic     #5                  // Field java/lang/System.out:Ljava/io/PrintStream;
        17: new           #6                  // class java/lang/StringBuilder
        20: dup
        21: invokespecial #7                  // Method java/lang/StringBuilder."<init>":()V
        24: ldc           #8                  // String
        26: invokevirtual #9                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
        29: lload_2
        30: invokevirtual #10                 // Method java/lang/StringBuilder.append:(J)Ljava/lang/StringBuilder;
        33: invokevirtual #11                 // Method java/lang/StringBuilder.toString:()Ljava/lang/String;
        36: invokevirtual #12                 // Method java/io/PrintStream.println:(Ljava/lang/String;)V
        39: lconst_1
        40: invokestatic  #13                 // Method java/lang/Long.valueOf:(J)Ljava/lang/Long;
        43: lconst_1
        44: invokestatic  #13                 // Method java/lang/Long.valueOf:(J)Ljava/lang/Long;
        47: invokestatic  #14                 // Method add:(Ljava/lang/Long;Ljava/lang/Long;)Ljava/lang/Long;
        50: pop
        51: lconst_1
        52: invokestatic  #13                 // Method java/lang/Long.valueOf:(J)Ljava/lang/Long;
        55: lconst_1
        56: invokestatic  #15                 // Method add:(Ljava/lang/Long;J)J
        59: pop2
        60: lconst_1
        61: lconst_1
        62: invokestatic  #16                 // Method add:(JJ)J
        65: pop2
        66: return
      LineNumberTable:
        line 19: 0
        line 21: 9
        line 22: 14
        line 23: 39
        line 24: 51
        line 25: 60
        line 29: 66
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      67     0  args   [Ljava/lang/String;
            9      58     1 wrapperLong   Ljava/lang/Long;
           14      53     2 aLong   J
    /*
    public static Long add(Long first, Long second)
    {
        if (first.equals(second)) {
        return Long.valueOf(first.longValue() + second.longValue());
        }
        return first;
    }
    */
  public static java.lang.Long add(java.lang.Long, java.lang.Long);
    descriptor: (Ljava/lang/Long;Ljava/lang/Long;)Ljava/lang/Long;
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=4, locals=2, args_size=2
         0: aload_0
         1: aload_1
         2: invokevirtual #17                 // Method java/lang/Long.equals:(Ljava/lang/Object;)Z
         5: ifeq          21
         8: aload_0
         9: invokevirtual #4                  // Method java/lang/Long.longValue:()J
        12: aload_1
        13: invokevirtual #4                  // Method java/lang/Long.longValue:()J
        16: ladd
        17: invokestatic  #13                 // Method java/lang/Long.valueOf:(J)Ljava/lang/Long;
        20: areturn
        21: aload_0
        22: areturn
      LineNumberTable:
        line 39: 0
        line 40: 8
        line 42: 21
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      23     0 first   Ljava/lang/Long;
            0      23     1 second   Ljava/lang/Long;
      StackMapTable: number_of_entries = 1
        frame_type = 21 /* same */
    /*
    public static long add(Long first, long second)
    {
        if (first.equals(Long.valueOf(second))) {
        return first.longValue() + second;
        }
        return first.longValue();
    }
    */

  public static long add(java.lang.Long, long);
    descriptor: (Ljava/lang/Long;J)J
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=4, locals=3, args_size=2
         0: aload_0
         1: lload_1
         2: invokestatic  #13                 // Method java/lang/Long.valueOf:(J)Ljava/lang/Long;
         5: invokevirtual #17                 // Method java/lang/Long.equals:(Ljava/lang/Object;)Z
         8: ifeq          18
        11: aload_0
        12: invokevirtual #4                  // Method java/lang/Long.longValue:()J
        15: lload_1
        16: ladd
        17: lreturn
        18: aload_0
        19: invokevirtual #4                  // Method java/lang/Long.longValue:()J
        22: lreturn
      LineNumberTable:
        line 53: 0
        line 54: 11
        line 56: 18
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      23     0 first   Ljava/lang/Long;
            0      23     1 second   J
      StackMapTable: number_of_entries = 1
        frame_type = 18 /* same */
  /*
  public static long add(long first, long second)
  {
    if (first == second) {
      return first + second;
    }
    return first;
  }
  */
  public static long add(long, long);
    descriptor: (JJ)J
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=4, locals=4, args_size=2
         0: lload_0
         1: lload_2
         2: lcmp
         3: ifne          10
         6: lload_0
         7: lload_2
         8: ladd
         9: lreturn
        10: lload_0
        11: lreturn
      LineNumberTable:
        line 68: 0
        line 69: 6
        line 71: 10
      LocalVariableTable:
        Start  Length  Slot  Name   Signature
            0      12     0 first   J
            0      12     2 second   J
      StackMapTable: number_of_entries = 1
        frame_type = 10 /* same */
}
SourceFile: "PrimitiveTypeStudy.java"

```

## 结论

除了 POJO 类属性 和 RPC 方法的返回值和参数之外，其他情况建议使用基本类型。

----

部分内容都是引用自：
> 《码出高效》
> <https://www.baeldung.com/java-wrapper-classes>