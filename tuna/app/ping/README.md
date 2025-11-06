# Tuna P4测试例子：同网段主机互ping

## 介绍
该例子用于验证网卡之间基础收发包功能，以同网段主机的相互ping通的功能来进行验证。

## 模拟器验证
支持以下3种场景的bmv2验证，通过make TOPO=topology1.json指定执行的topo
- topology1.json：2个nic直连
```bash
   主机1 ─── 网卡1 ─── 网卡2 ─── 主机2
```
- topology2.json：3个nic通过1个bridge互连
```bash
   主机1 ─── 网卡1 ───
                    │
   主机2 ─── 网卡2 ─── Linux Bridge
                    │
   主机3 ─── 网卡3 ───
```
- topology3.json：4个nic通过2个bridge连接
```bash
   主机1 ─── 网卡1 ───                         ─── 主机3 ─── 网卡3
                    │── Bridge1 ── Bridge2 ──│
   主机2 ─── 网卡2 ───                         ─── 主机4 ─── 网卡4
```
