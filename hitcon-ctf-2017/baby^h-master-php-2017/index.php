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
