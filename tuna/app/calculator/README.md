# Tuna P4测试算子：calculator相关算子

## 介绍
该例子用于验证control模块的算术运算(+,-)/位运算(&,|,^,~)/逻辑运算(==,!=,>,<,>=,<=)。

## 自定义协议头
为了完成所有算子的测试，自定义了一个简单的协议头，这个协议头会通过以太类型0x1234表示，协议头格式如下：
```c
header p4calc_t {
    bit<8>  p;
    bit<8>  four;
    bit<8>  ver;
    bit<16> op;
    bit<32> operand_a;
    bit<32> operand_b;
    bit<32> res;
}
```
-  p 是字母'P' (0x50)
-  four 是数字'4' (0x34)
-  ver 当前是0.1 (0x01)
-  op 是将要执行的算子:
   -   '+' (0x2b00) res = operand_a + operand_b
   -   '-' (0x2d00) res = operand_a - operand_b
   -   '&' (0x2600) res = operand_a & operand_b
   -   '|' (0x7c00) res = operand_a | operand_b
   -   '^' (0x5e00) res = operand_a ^ operand_b
   -   '~' (0x7e00) res = ~operand_a
   -   '==' (0x3d3d) res = operand_a == operand_b
   -   '!=' (0x213d) res = operand_a != operand_b
   -   '>' (0x3e00) res = operand_a > operand_b
   -   '<' (0x3c00) res = operand_a < operand_b
   -   '>=' (0x3e3d) res = operand_a >= operand_b
   -   '<=' (0x3c3d) res = operand_a <= operand_b
- 位运算的operand_b当前只支持输入15

