%include "boot.inc"
;主引导程序
SECTION MBR vstart=0x7c00
    ; 初始化寄存器
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov sp, 0x7c00
    ;0xb800是实模式文本模式显示适配器起始地址
    mov ax, 0xb800
    mov gs, ax

    ; AH = 0x06，上卷全部行，AL = 上卷的行数，如果为0，表示全部
    mov ax,0600h
    ; BH = 上卷行属性
    mov bx,0700h
    ; (CL, CH) = 窗口左上角的位置(x,y)
    mov cx,0
    ; (DL, DH) = 窗口右下角的位置(x,f)
    mov dx,184fh
    ; 中断清屏
    int 10h

    ; 输出字符串'1 MBR'
    mov byte [gs:0x00], '1'
    mov byte [gs:0x01], 0xA4; A表示绿色背景闪烁，4代表前景为红色

    mov byte [gs:0x02], ' '
    mov byte [gs:0x03], 0xA4

    mov byte [gs:0x04], 'M'
    mov byte [gs:0x05], 0xA4

    mov byte [gs:0x06], 'B'
    mov byte [gs:0x07], 0xA4

    mov byte [gs:0x08], 'R'
    mov byte [gs:0x09], 0xA4

    ; loder的扇区位置
    mov eax, LOADER_START_SECTOR
    ; 设置loder被加载到内存以后的地址
    mov bx, LOADER_BASE_ADDR
    ; 读取的扇区数，由于我们自己编写的loader不会超过512字节，因此设置为1
    mov cx, 1
    call rd_disk_m_16

    jmp LOADER_BASE_ADDR

    ;读取硬盘第n个扇区
    rd_disk_m_16:
        mov esi, eax ;备份eax
        mov di, cx ;备份cx

        ; 第一步
        ; 设置要读取的扇区数
        mov dx, 0x1f2 ;0x1f2是端口号
        mov al, cl
        out dx, al

        mov eax, esi ;恢复eax寄存器

        ; 第二步
        ; LBA地址0~7位写入端口0x1f3
        mov dx, 0x1f3
        out dx, al

        ; LBA地址8~15位写入0x1f4
        mov cl, 8
        shr eax, cl
        mov dx, 0x1f4
        out dx, al

        ; LBA地址16~23位写入0x1f5
        shr eax, cl
        mov dx, 0x1f5
        out dx, al

        ; device端口
        shr eax, cl
        and al, 0x0f ; lba第24~27位
        or al, 0xe0 ; 设置device高4位为1110，表示LBA模式
        mov dx, 0x1f6
        out dx, al

        ; 第三步，向0x1f7端口写入读命令0x20
        mov dx, 0x1f7
        mov al, 0x20
        out dx, al

        ; 第4步 检测硬盘状态
        .not_ready:
            nop
            in al, dx
            and al, 0x88 ; 第4位为1表示硬盘控制器已准备好数据传输，第7位为1表示硬盘忙
            cmp al, 0x08
            jnz .not_ready ; 如果没有准备好，继续等

        mov ax, di ;di为要读取的扇区数
        mov dx, 256 ; 扇区有512字节，每次读入一个字（实模式下2个字节），要读取的扇区数为1，1*（512/2）,所以是di*256
        mul dx
        mov cx, ax
        mov dx, 0x1f0

        ; 循环读取数据
        .go_on_read:
            in ax, dx
            mov [bx], ax
            add bx, 2
            loop .go_on_read
            ret

    times 510 - ($-$$) db 0
    db 0x55, 0xaa
