# 说明：
* 一个 IBM 账户下的两个实例合并同时跑，协议 VLESS 和 VMESS 各一个
* 两个实例均在 北京时间 周三 5：15（UTC 周二 21：15）  重启
* VMESS 默认的alterId 可以是0-64之间取整

  | Secrets变量 | 形式 |
  | --------------------- | ----------- |
  | IBM_CF_USERNAME      | IBM Cloud 邮箱地址 |
  | IBM_CF_PASSWORD | IBM Cloud 邮箱密码 |
  | IBM_CF_APP_NAME1 | 应用1程序名（VLESS)|
  | IBM_CF_APP_NAME2 | 应用2程序名（VMESS)|
  | IBM_CF_REGOIN | （选填）地区，达拉斯用`us-south`，伦敦用`eu-gb`。默认`us-south`|
  | IBM_CF_APP_MEM | （选填） 两个实例的内存大小,必须是一样,可以是`128M`或者`64M`。默认`128M` |
  | V2_UUID | （选填）自定义UUID码。默认`f3a836ba-e93b-4cf3-8ee9-ce37a1e84cd8`|
  | V2_WS_PATH |（选填） 自定义PATH路径。默认`/v2ray`|
  | V2_ALTERID |（选填） 自定义ALTERID路径。默认`64`|
   
感谢P3TERX ：https://p3terx.com/


<details>
<summary>反代代码</summary>

```js
addEventListener(
	"fetch",event => {
		let url=new URL(event.request.url);
		url.hostname="应用app名";
		url.pathname ="路径";
		let request=new Request(url,event.request);
		event. respondWith(
			fetch(request)
		)
	}
)
```
</details>
