# Tuna P4测试例子：同网段主机带防火墙互ping

## 介绍
该例子用于验证网卡的防火墙功能（黑名单），以同网段主机的相互ping通的功能来进行验证。

## 模拟器验证
通过make TOPO=topology.json指定执行的topo，可以扩展支持更多场景的bmv2验证。
- topology.json：3个nic通过1个bridge互连
```bash
   主机1 ─── 网卡1 ───
                    │
   主机2 ─── 网卡2 ─── Linux Bridge
                    │
   主机3 ─── 网卡3 ───
```
