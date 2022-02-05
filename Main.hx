import python.Lib;
import sys.io.Process;
import sys.io.File;
import haxe.Http;
import python.lib.urllib.Parse;

class Main {
	static function main() {
		pushIPAddress("github.com");
		pushIPAddress("github.global.ssl.fastly.net");
	}

	public static function pushIPAddress(url:String):Void {
		trace("追加映射IP的域名:" + url);
		// 需要获取的网页内容
		var content = Requests.get("http://ipaddress.com/website/" + url);
		if (content.status_code != 200) {
			trace("网络异常：", content.status_code);
			return;
		}
		// 分析IP地址
		var startText = '<th>IP Address</th><td><ul class="comma-separated"><li>';
		var ip = content.text.substr(content.text.indexOf(startText) + startText.length);
		ip = ip.substr(0, ip.indexOf("<"));
		if (ip.split(".").length < 4) {
			trace("ip格式异常：" + ip);
			return;
		}
		trace("获得到IP：", ip);
		// todo：WINDOW暂不支持更改Hosts
		if (Sys.systemName() == "Windows") {
			return;
		}
		// 判断是否能够ping通结果
		// 更换GITHUB的Hosts
		var hosts = File.getContent("/etc/hosts");
		var h = hosts.split("\n");
		var isHasGithub = false;
		// 判断当前IP是否已经存在
		for (s in h) {
			if (s.indexOf(ip) != -1) {
				trace("当前IP[" + ip + "]已经存在hosts中");
				var proess = new Process("ping -c 3 " + ip);
				var ms = proess.stdout.readAll().toString();
				// 丢失包率大于0%时，则不要这个IP了，直接更新
				if (ms.indexOf("0.0%") == -1) {
					trace("[异常]存在丢包现象");
				} else {
					trace("[检查]无丢包现象，可正常使用");
				}
				return;
			}
		}
		// 开始遍历更新
		for (index => str in h) {
			if (str.indexOf(url) != -1) {
				// 存在github.com，更新IP
				var ips = str.split(" ");
				// 判断当前IP是否可用
				trace("检查当前IP可用性：", ips[0]);
				var proess = new Process("ping -c 3 " + ips[0]);
				var ms = proess.stdout.readAll().toString();
				// 丢失包率大于0%时，则不要这个IP了，直接更新
				if (ms.indexOf("0.0%") == -1) {
					isHasGithub = true;
					ips[0] = ip;
					str = ips.join(" ");
					h[index] = str;
				} else {
					// IP
					trace("IP[" + ips[0] + "]丢包率通过");
				}
			}
		}
		hosts = h.join("\n");
		if (isHasGithub == false) {
			// 如果不存在该域名，则追加ip
			hosts += "\n" + ip + " " + url;
		}
		trace("更新hosts:\n" + hosts);
		File.saveContent("/etc/hosts", hosts);
	}
}

/**
 * Python网页请求库
 */
@:pythonImport("requests")
extern class Requests {
	public static function get(url:String):Requests;

	public var status_code:Int;

	public var text:String;
}
