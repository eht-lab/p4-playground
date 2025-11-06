# Tuna P4测试例子：不同网段主机互ping

## 介绍
该例子实现三层转发，基于IPV4目标地址修改目的MAC，实现不同网段的主机互ping功能

## ED201验证
在进行测试前，需准备两台主机A，B，每张主机带一张网卡，网卡间直连。

## 环境搭建
1. 编译P4程序，生成p4data.bin
```bash
p4c-apollo-tuna l3_forward.p4 -o build/l3_forward.json
```
* p4c-apollo-tuna:编译器，编译p4c仓库时生成
* -o build/l3_forward.json:会在已创建的build目录下生成json文件和l3_forward_firmware文件夹，firmware文件夹中存放生成的bin文件

2. 将第一步l3_forward_firmware中的p4data.bin文件打包到apollo仓库编译生成的apollo-1x200g.itb中去，A和B网卡均重新烧录该flash。（注：该步骤只是临时方案。后续正式方案会通过runtime更新bin文件。）

3. AB主机启动后，加载驱动配置ip
```bash
两台主机都执行：
insmod tunic.ko

A主机：
ifconfig enp1s0f0 up 192.168.1.3/24

// 增加default网关192.168.1.10
ip route add default via 192.168.1.10 dev enp1s0f0 metric 10

// 创建custom_table路由表
echo "100    custom_table" | sudo tee -a /etc/iproute2/rt_tables

// 在custom_table路由表中指定默认网关192.168.1.10
ip route add default via 192.168.1.10 dev enp1s0f0 metric 10 table custom_table

// 添加路由规则：让发往10.0.1.2的流量使用自定义custom_table路由表
ip rule add to 10.0.1.2 lookup custom_table

// arp提前缓存网关的mac
arp -i enp1s0f0 -s 192.168.1.10 c2:0c:20:4a:23:65

B主机：
ifconfig enp2s0f0 up  10.0.1.2/24

// 增加default网关10.0.1.10
ip route add default via 10.0.1.10 dev enp2s0f0 metric 10

// 创建custom_table路由表
echo "100    custom_table" | sudo tee -a /etc/iproute2/rt_tables

// 在custom_table路由表中指定默认网关10.0.1.10
ip route add default via 10.0.1.10 dev enp2s0f0 metric 10 table custom_table

// 添加路由规则：让发往192.168.1.3的流量使用自定义custom_table路由表
ip rule add to 192.168.1.3 lookup custom_table

// arp提前缓存网关的mac
arp -i enp2s0f0 -s 10.0.1.10 62:9b:0c:db:ac:20
```
* A主机配置ip为192.168.1.3， 配置网关IP为192.168.1.10。B主机配置为10.0.1.2，配置网关IP为10.0.1.10，ARP提前缓存每个网关对应的MAC，MAC地址和主机相同。后面一些路由表规则的配置是为了让特定IP的流量走特定网卡，不配置的话报文就会发到默认的网卡上，无法经过P4模块。

4. 运行
```bash
A主机：
ping 10.0.1.2
B主机：
ping 192.168.1.3
```
* 预期结果为双方互ping均能通

## bmv2调通l3_forward操作记录
- 不同主机需要配置网关/路由表等配置，可以直接在topology.json上通过commands进行配置
```json
"commands": [
    "ip route add default via 192.168.1.10 dev eth0 metric 10",
    "echo \"100    custom_table\" | sudo tee -a /etc/iproute2/rt_tables",
    "ip route add default via 192.168.1.10 dev eth0 metric 10 table custom_table",
    "ip rule add to 10.0.1.2 lookup custom_table",
    "arp -i eth0 -s 192.168.1.10 c2:0c:20:4a:23:65"
]
```
- ipv4_lpm需要配置entry，当前暂未支持runtime，因此通过const entries方式静态编译出entry，lpm和ternary的格式相同，都是value &&& mask的格式
```c
const entries = {
    (0x0a000102 &&& 0xFFFFFF00) : ipv4_forward(0x629b0cdbac20);
    (0xc0a80103 &&& 0xFFFFFF00) : ipv4_forward(0xc20c204a2365);
}
```
