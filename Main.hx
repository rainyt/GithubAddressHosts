import python.Lib;
import sys.io.Process;
import sys.io.File;
import haxe.Http;
import python.lib.urllib.Parse;

class Main {
	static function main() {
		// 需要获取的网页内容
		var content = Requests.get("http://ipaddress.com/website/github.com");
		File.saveContent("content.txt", content.text);
		// 分析IP地址
		var startText = '<th>IP Address</th><td><ul class="comma-separated"><li>';
		var ip = content.text.substr(content.text.indexOf(startText) + startText.length);
		ip = ip.substr(0, ip.indexOf("<"));
		trace("获得到IP：", ip);
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
			if (str.indexOf("github.com") != -1) {
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
			// 如果不存在github.com，则追加ip
			hosts += "\n" + ip + " github.com";
		}
		trace("更新hosts:\n" + hosts);
		File.saveContent("/etc/hosts", hosts);
		trace("请求结果", content.status_code);
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
