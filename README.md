# minios
操作系统


## 加载启动内核

```shell
cd boot
# 编译mbr和loader
nasm -I include -o loader.bin loader.asm
nasm -I include -o mbr.bin mbr.asm

# 创建虚拟镜像
qemu-img create -f raw vm1.raw 1G

# 写入Mbr
dd if=mbr.bin of=vm1.raw bs=512 count=1 conv=notrunc
# 写入loader
dd if=loader.bin of=vm1.raw bs=512 count=1 seek=2 conv=notrunc

# 启动程序
qemu-system-x86_64 vm1.raw 
```