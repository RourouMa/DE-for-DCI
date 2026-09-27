# 四圈 top 的 dlog 方程

采用 J=T I，原始top为完整88原子列表的 I1。

```wl
J1 = (-1 + x)*(1 + x)*(-1 + y)^4*(1 + y)^4*DCIBasis`I[1]
I_top = DCIBasis`J[1]/((-1 + x)*(1 + x)*(-1 + y)^4*(1 + y)^4)
```

其微分方程按字母为：

```wl
dLog[x] * (2*DCIBasis`J[24])
```

```wl
dLog[y] * (4*DCIBasis`J[2] + 4*DCIBasis`J[3])
```

将上面各项相加即为 dJ1；所有括号内系数都是常数。该方程给出top与新基其他分量的微分关系，本身不等同于已完成top积分函数的求解。
