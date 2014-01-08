
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start-0xc>:
.long MULTIBOOT_HEADER_FLAGS
.long CHECKSUM

.globl		_start
_start:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 03 00    	add    0x31bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fb                   	sti    
f0100009:	4f                   	dec    %edi
f010000a:	52                   	push   %edx
f010000b:	e4 66                	in     $0x66,%al

f010000c <_start>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 

	# Establish our own GDT in place of the boot loader's temporary GDT.
	lgdt	RELOC(mygdtdesc)		# load descriptor table
f0100015:	0f 01 15 18 20 11 00 	lgdtl  0x112018

	# Immediately reload all segment registers (including CS!)
	# with segment selectors from the new GDT.
	movl	$DATA_SEL, %eax			# Data segment selector
f010001c:	b8 10 00 00 00       	mov    $0x10,%eax
	movw	%ax,%ds				# -> DS: Data Segment
f0100021:	8e d8                	mov    %eax,%ds
	movw	%ax,%es				# -> ES: Extra Segment
f0100023:	8e c0                	mov    %eax,%es
	movw	%ax,%ss				# -> SS: Stack Segment
f0100025:	8e d0                	mov    %eax,%ss
	ljmp	$CODE_SEL,$relocated		# reload CS by jumping
f0100027:	ea 2e 00 10 f0 08 00 	ljmp   $0x8,$0xf010002e

f010002e <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002e:	bd 00 00 00 00       	mov    $0x0,%ebp

        # Set the stack pointer
	movl	$(bootstacktop),%esp
f0100033:	bc 00 20 11 f0       	mov    $0xf0112000,%esp

	# now to C code
	call	i386_init
f0100038:	e8 60 00 00 00       	call   f010009d <i386_init>

f010003d <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003d:	eb fe                	jmp    f010003d <spin>
	...

f0100040 <test_backtrace>:
#include <kern/kclock.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 80 1f 10 f0 	movl   $0xf0101f80,(%esp)
f0100055:	e8 d8 0e 00 00       	call   f0100f32 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 36 07 00 00       	call   f01007bd <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 9c 1f 10 f0 	movl   $0xf0101f9c,(%esp)
f0100092:	e8 9b 0e 00 00       	call   f0100f32 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 10 2a 11 f0       	mov    $0xf0112a10,%eax
f01000a8:	2d 70 23 11 f0       	sub    $0xf0112370,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 70 23 11 f0 	movl   $0xf0112370,(%esp)
f01000c0:	e8 cf 19 00 00       	call   f0101a94 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 83 05 00 00       	call   f010064d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 b7 1f 10 f0 	movl   $0xf0101fb7,(%esp)
f01000d9:	e8 54 0e 00 00       	call   f0100f32 <cprintf>

	// Lab 2 memory management initialization functions
	i386_detect_memory();
f01000de:	e8 97 08 00 00       	call   f010097a <i386_detect_memory>
	i386_vm_init();
f01000e3:	e8 29 09 00 00       	call   f0100a11 <i386_vm_init>



	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000e8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ef:	e8 15 07 00 00       	call   f0100809 <monitor>
f01000f4:	eb f2                	jmp    f01000e8 <i386_init+0x4b>

f01000f6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f6:	55                   	push   %ebp
f01000f7:	89 e5                	mov    %esp,%ebp
f01000f9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	if (panicstr)
f01000fc:	83 3d 80 23 11 f0 00 	cmpl   $0x0,0xf0112380
f0100103:	75 40                	jne    f0100145 <_panic+0x4f>
		goto dead;
	panicstr = fmt;
f0100105:	8b 45 10             	mov    0x10(%ebp),%eax
f0100108:	a3 80 23 11 f0       	mov    %eax,0xf0112380

	va_start(ap, fmt);
	cprintf("kernel panic at %s:%d: ", file, line);
f010010d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100110:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100114:	8b 45 08             	mov    0x8(%ebp),%eax
f0100117:	89 44 24 04          	mov    %eax,0x4(%esp)
f010011b:	c7 04 24 d2 1f 10 f0 	movl   $0xf0101fd2,(%esp)
f0100122:	e8 0b 0e 00 00       	call   f0100f32 <cprintf>

	if (panicstr)
		goto dead;
	panicstr = fmt;

	va_start(ap, fmt);
f0100127:	8d 45 14             	lea    0x14(%ebp),%eax
	cprintf("kernel panic at %s:%d: ", file, line);
	vcprintf(fmt, ap);
f010012a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010012e:	8b 45 10             	mov    0x10(%ebp),%eax
f0100131:	89 04 24             	mov    %eax,(%esp)
f0100134:	e8 c6 0d 00 00       	call   f0100eff <vcprintf>
	cprintf("\n");
f0100139:	c7 04 24 0e 20 10 f0 	movl   $0xf010200e,(%esp)
f0100140:	e8 ed 0d 00 00       	call   f0100f32 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100145:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010014c:	e8 b8 06 00 00       	call   f0100809 <monitor>
f0100151:	eb f2                	jmp    f0100145 <_panic+0x4f>

f0100153 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100153:	55                   	push   %ebp
f0100154:	89 e5                	mov    %esp,%ebp
f0100156:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
	cprintf("kernel warning at %s:%d: ", file, line);
f0100159:	8b 45 0c             	mov    0xc(%ebp),%eax
f010015c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100160:	8b 45 08             	mov    0x8(%ebp),%eax
f0100163:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100167:	c7 04 24 ea 1f 10 f0 	movl   $0xf0101fea,(%esp)
f010016e:	e8 bf 0d 00 00       	call   f0100f32 <cprintf>
void
_warn(const char *file, int line, const char *fmt,...)
{
	va_list ap;

	va_start(ap, fmt);
f0100173:	8d 45 14             	lea    0x14(%ebp),%eax
	cprintf("kernel warning at %s:%d: ", file, line);
	vcprintf(fmt, ap);
f0100176:	89 44 24 04          	mov    %eax,0x4(%esp)
f010017a:	8b 45 10             	mov    0x10(%ebp),%eax
f010017d:	89 04 24             	mov    %eax,(%esp)
f0100180:	e8 7a 0d 00 00       	call   f0100eff <vcprintf>
	cprintf("\n");
f0100185:	c7 04 24 0e 20 10 f0 	movl   $0xf010200e,(%esp)
f010018c:	e8 a1 0d 00 00       	call   f0100f32 <cprintf>
	va_end(ap);
}
f0100191:	c9                   	leave  
f0100192:	c3                   	ret    
	...

f01001a0 <serial_proc_data>:

static bool serial_exists;

int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 14             	sub    $0x14,%esp
f01001c3:	ba 64 00 00 00       	mov    $0x64,%edx
f01001c8:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001c9:	a8 01                	test   $0x1,%al
f01001cb:	0f 84 e4 00 00 00    	je     f01002b5 <kbd_proc_data+0xf9>
f01001d1:	b2 60                	mov    $0x60,%dl
f01001d3:	ec                   	in     (%dx),%al
f01001d4:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001d6:	3c e0                	cmp    $0xe0,%al
f01001d8:	75 11                	jne    f01001eb <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001da:	83 0d b0 23 11 f0 40 	orl    $0x40,0xf01123b0
		return 0;
f01001e1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01001e6:	e9 cf 00 00 00       	jmp    f01002ba <kbd_proc_data+0xfe>
	} else if (data & 0x80) {
f01001eb:	84 c0                	test   %al,%al
f01001ed:	79 34                	jns    f0100223 <kbd_proc_data+0x67>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001ef:	8b 0d b0 23 11 f0    	mov    0xf01123b0,%ecx
f01001f5:	f6 c1 40             	test   $0x40,%cl
f01001f8:	75 05                	jne    f01001ff <kbd_proc_data+0x43>
f01001fa:	89 c2                	mov    %eax,%edx
f01001fc:	83 e2 7f             	and    $0x7f,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001ff:	0f b6 d2             	movzbl %dl,%edx
f0100202:	0f b6 82 40 20 10 f0 	movzbl -0xfefdfc0(%edx),%eax
f0100209:	83 c8 40             	or     $0x40,%eax
f010020c:	0f b6 c0             	movzbl %al,%eax
f010020f:	f7 d0                	not    %eax
f0100211:	21 c1                	and    %eax,%ecx
f0100213:	89 0d b0 23 11 f0    	mov    %ecx,0xf01123b0
		return 0;
f0100219:	bb 00 00 00 00       	mov    $0x0,%ebx
f010021e:	e9 97 00 00 00       	jmp    f01002ba <kbd_proc_data+0xfe>
	} else if (shift & E0ESC) {
f0100223:	8b 0d b0 23 11 f0    	mov    0xf01123b0,%ecx
f0100229:	f6 c1 40             	test   $0x40,%cl
f010022c:	74 0e                	je     f010023c <kbd_proc_data+0x80>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010022e:	89 c2                	mov    %eax,%edx
f0100230:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100233:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100236:	89 0d b0 23 11 f0    	mov    %ecx,0xf01123b0
	}

	shift |= shiftcode[data];
f010023c:	0f b6 c2             	movzbl %dl,%eax
f010023f:	0f b6 90 40 20 10 f0 	movzbl -0xfefdfc0(%eax),%edx
f0100246:	0b 15 b0 23 11 f0    	or     0xf01123b0,%edx
	shift ^= togglecode[data];
f010024c:	0f b6 88 40 21 10 f0 	movzbl -0xfefdec0(%eax),%ecx
f0100253:	31 ca                	xor    %ecx,%edx
f0100255:	89 15 b0 23 11 f0    	mov    %edx,0xf01123b0

	c = charcode[shift & (CTL | SHIFT)][data];
f010025b:	89 d1                	mov    %edx,%ecx
f010025d:	83 e1 03             	and    $0x3,%ecx
f0100260:	8b 0c 8d 40 22 10 f0 	mov    -0xfefddc0(,%ecx,4),%ecx
f0100267:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f010026b:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f010026e:	f6 c2 08             	test   $0x8,%dl
f0100271:	74 1a                	je     f010028d <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f0100273:	89 d8                	mov    %ebx,%eax
f0100275:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100278:	83 f9 19             	cmp    $0x19,%ecx
f010027b:	77 05                	ja     f0100282 <kbd_proc_data+0xc6>
			c += 'A' - 'a';
f010027d:	83 eb 20             	sub    $0x20,%ebx
f0100280:	eb 0b                	jmp    f010028d <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f0100282:	83 e8 41             	sub    $0x41,%eax
f0100285:	83 f8 19             	cmp    $0x19,%eax
f0100288:	77 03                	ja     f010028d <kbd_proc_data+0xd1>
			c += 'a' - 'A';
f010028a:	83 c3 20             	add    $0x20,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010028d:	f7 d2                	not    %edx
f010028f:	f6 c2 06             	test   $0x6,%dl
f0100292:	75 26                	jne    f01002ba <kbd_proc_data+0xfe>
f0100294:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010029a:	75 1e                	jne    f01002ba <kbd_proc_data+0xfe>
		cprintf("Rebooting!\n");
f010029c:	c7 04 24 04 20 10 f0 	movl   $0xf0102004,(%esp)
f01002a3:	e8 8a 0c 00 00       	call   f0100f32 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002a8:	ba 92 00 00 00       	mov    $0x92,%edx
f01002ad:	b8 03 00 00 00       	mov    $0x3,%eax
f01002b2:	ee                   	out    %al,(%dx)
f01002b3:	eb 05                	jmp    f01002ba <kbd_proc_data+0xfe>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002b5:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002ba:	89 d8                	mov    %ebx,%eax
f01002bc:	83 c4 14             	add    $0x14,%esp
f01002bf:	5b                   	pop    %ebx
f01002c0:	5d                   	pop    %ebp
f01002c1:	c3                   	ret    

f01002c2 <serial_init>:
		cons_intr(serial_proc_data);
}

void
serial_init(void)
{
f01002c2:	55                   	push   %ebp
f01002c3:	89 e5                	mov    %esp,%ebp
f01002c5:	53                   	push   %ebx
f01002c6:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01002cb:	b8 00 00 00 00       	mov    $0x0,%eax
f01002d0:	89 da                	mov    %ebx,%edx
f01002d2:	ee                   	out    %al,(%dx)
f01002d3:	b2 fb                	mov    $0xfb,%dl
f01002d5:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01002da:	ee                   	out    %al,(%dx)
f01002db:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f01002e0:	b8 0c 00 00 00       	mov    $0xc,%eax
f01002e5:	89 ca                	mov    %ecx,%edx
f01002e7:	ee                   	out    %al,(%dx)
f01002e8:	b2 f9                	mov    $0xf9,%dl
f01002ea:	b8 00 00 00 00       	mov    $0x0,%eax
f01002ef:	ee                   	out    %al,(%dx)
f01002f0:	b2 fb                	mov    $0xfb,%dl
f01002f2:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f7:	ee                   	out    %al,(%dx)
f01002f8:	b2 fc                	mov    $0xfc,%dl
f01002fa:	b8 00 00 00 00       	mov    $0x0,%eax
f01002ff:	ee                   	out    %al,(%dx)
f0100300:	b2 f9                	mov    $0xf9,%dl
f0100302:	b8 01 00 00 00       	mov    $0x1,%eax
f0100307:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100308:	b2 fd                	mov    $0xfd,%dl
f010030a:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010030b:	3c ff                	cmp    $0xff,%al
f010030d:	0f 95 c0             	setne  %al
f0100310:	0f b6 c0             	movzbl %al,%eax
f0100313:	a3 a0 23 11 f0       	mov    %eax,0xf01123a0
f0100318:	89 da                	mov    %ebx,%edx
f010031a:	ec                   	in     (%dx),%al
f010031b:	89 ca                	mov    %ecx,%edx
f010031d:	ec                   	in     (%dx),%al
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

}
f010031e:	5b                   	pop    %ebx
f010031f:	5d                   	pop    %ebp
f0100320:	c3                   	ret    

f0100321 <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
cga_init(void)
{
f0100321:	55                   	push   %ebp
f0100322:	89 e5                	mov    %esp,%ebp
f0100324:	83 ec 0c             	sub    $0xc,%esp
f0100327:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010032a:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010032d:	89 7d fc             	mov    %edi,-0x4(%ebp)
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100330:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100337:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010033e:	5a a5 
	if (*cp != 0xA55A) {
f0100340:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100347:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010034b:	74 11                	je     f010035e <cga_init+0x3d>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010034d:	c7 05 a4 23 11 f0 b4 	movl   $0x3b4,0xf01123a4
f0100354:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100357:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f010035c:	eb 16                	jmp    f0100374 <cga_init+0x53>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010035e:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100365:	c7 05 a4 23 11 f0 d4 	movl   $0x3d4,0xf01123a4
f010036c:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010036f:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100374:	8b 0d a4 23 11 f0    	mov    0xf01123a4,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010037a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010037f:	89 ca                	mov    %ecx,%edx
f0100381:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100382:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100385:	89 da                	mov    %ebx,%edx
f0100387:	ec                   	in     (%dx),%al
f0100388:	0f b6 f0             	movzbl %al,%esi
f010038b:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010038e:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100393:	89 ca                	mov    %ecx,%edx
f0100395:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100396:	89 da                	mov    %ebx,%edx
f0100398:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100399:	89 3d a8 23 11 f0    	mov    %edi,0xf01123a8
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010039f:	0f b6 d8             	movzbl %al,%ebx
f01003a2:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01003a4:	66 89 35 ac 23 11 f0 	mov    %si,0xf01123ac
}
f01003ab:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01003ae:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01003b1:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01003b4:	89 ec                	mov    %ebp,%esp
f01003b6:	5d                   	pop    %ebp
f01003b7:	c3                   	ret    

f01003b8 <kbd_init>:
	cons_intr(kbd_proc_data);
}

void
kbd_init(void)
{
f01003b8:	55                   	push   %ebp
f01003b9:	89 e5                	mov    %esp,%ebp
}
f01003bb:	5d                   	pop    %ebp
f01003bc:	c3                   	ret    

f01003bd <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
f01003bd:	55                   	push   %ebp
f01003be:	89 e5                	mov    %esp,%ebp
f01003c0:	53                   	push   %ebx
f01003c1:	83 ec 04             	sub    $0x4,%esp
f01003c4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01003c7:	eb 28                	jmp    f01003f1 <cons_intr+0x34>
		if (c == 0)
f01003c9:	85 c0                	test   %eax,%eax
f01003cb:	74 24                	je     f01003f1 <cons_intr+0x34>
			continue;
		cons.buf[cons.wpos++] = c;
f01003cd:	8b 15 c4 25 11 f0    	mov    0xf01125c4,%edx
f01003d3:	88 82 c0 23 11 f0    	mov    %al,-0xfeedc40(%edx)
f01003d9:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01003dc:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01003e1:	0f 94 c2             	sete   %dl
f01003e4:	0f b6 d2             	movzbl %dl,%edx
f01003e7:	83 ea 01             	sub    $0x1,%edx
f01003ea:	21 d0                	and    %edx,%eax
f01003ec:	a3 c4 25 11 f0       	mov    %eax,0xf01125c4
void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01003f1:	ff d3                	call   *%ebx
f01003f3:	83 f8 ff             	cmp    $0xffffffff,%eax
f01003f6:	75 d1                	jne    f01003c9 <cons_intr+0xc>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01003f8:	83 c4 04             	add    $0x4,%esp
f01003fb:	5b                   	pop    %ebx
f01003fc:	5d                   	pop    %ebp
f01003fd:	c3                   	ret    

f01003fe <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01003fe:	55                   	push   %ebp
f01003ff:	89 e5                	mov    %esp,%ebp
f0100401:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
f0100404:	c7 04 24 bc 01 10 f0 	movl   $0xf01001bc,(%esp)
f010040b:	e8 ad ff ff ff       	call   f01003bd <cons_intr>
}
f0100410:	c9                   	leave  
f0100411:	c3                   	ret    

f0100412 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100412:	83 3d a0 23 11 f0 00 	cmpl   $0x0,0xf01123a0
f0100419:	74 13                	je     f010042e <serial_intr+0x1c>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010041b:	55                   	push   %ebp
f010041c:	89 e5                	mov    %esp,%ebp
f010041e:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100421:	c7 04 24 a0 01 10 f0 	movl   $0xf01001a0,(%esp)
f0100428:	e8 90 ff ff ff       	call   f01003bd <cons_intr>
}
f010042d:	c9                   	leave  
f010042e:	f3 c3                	repz ret 

f0100430 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100430:	55                   	push   %ebp
f0100431:	89 e5                	mov    %esp,%ebp
f0100433:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100436:	e8 d7 ff ff ff       	call   f0100412 <serial_intr>
	kbd_intr();
f010043b:	e8 be ff ff ff       	call   f01003fe <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100440:	8b 15 c0 25 11 f0    	mov    0xf01125c0,%edx
f0100446:	3b 15 c4 25 11 f0    	cmp    0xf01125c4,%edx
f010044c:	74 23                	je     f0100471 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f010044e:	0f b6 82 c0 23 11 f0 	movzbl -0xfeedc40(%edx),%eax
f0100455:	83 c2 01             	add    $0x1,%edx
f0100458:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010045e:	0f 94 c1             	sete   %cl
f0100461:	0f b6 c9             	movzbl %cl,%ecx
f0100464:	83 e9 01             	sub    $0x1,%ecx
f0100467:	21 ca                	and    %ecx,%edx
f0100469:	89 15 c0 25 11 f0    	mov    %edx,0xf01125c0
f010046f:	eb 05                	jmp    f0100476 <cons_getc+0x46>
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f0100471:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100476:	c9                   	leave  
f0100477:	c3                   	ret    

f0100478 <cons_putc>:

// output a character to the console
void
cons_putc(int c)
{
f0100478:	55                   	push   %ebp
f0100479:	89 e5                	mov    %esp,%ebp
f010047b:	57                   	push   %edi
f010047c:	56                   	push   %esi
f010047d:	53                   	push   %ebx
f010047e:	83 ec 1c             	sub    $0x1c,%esp
f0100481:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100484:	ba 79 03 00 00       	mov    $0x379,%edx
f0100489:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010048a:	84 c0                	test   %al,%al
f010048c:	78 21                	js     f01004af <cons_putc+0x37>
f010048e:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100493:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100498:	be 79 03 00 00       	mov    $0x379,%esi
f010049d:	89 ca                	mov    %ecx,%edx
f010049f:	ec                   	in     (%dx),%al
f01004a0:	ec                   	in     (%dx),%al
f01004a1:	ec                   	in     (%dx),%al
f01004a2:	ec                   	in     (%dx),%al
f01004a3:	89 f2                	mov    %esi,%edx
f01004a5:	ec                   	in     (%dx),%al
f01004a6:	84 c0                	test   %al,%al
f01004a8:	78 05                	js     f01004af <cons_putc+0x37>
f01004aa:	83 eb 01             	sub    $0x1,%ebx
f01004ad:	75 ee                	jne    f010049d <cons_putc+0x25>
		delay();
	outb(0x378+0, c);
f01004af:	89 f8                	mov    %edi,%eax
f01004b1:	25 ff 00 00 00       	and    $0xff,%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004b6:	ba 78 03 00 00       	mov    $0x378,%edx
f01004bb:	ee                   	out    %al,(%dx)
f01004bc:	b2 7a                	mov    $0x7a,%dl
f01004be:	b8 0d 00 00 00       	mov    $0xd,%eax
f01004c3:	ee                   	out    %al,(%dx)
f01004c4:	b8 08 00 00 00       	mov    $0x8,%eax
f01004c9:	ee                   	out    %al,(%dx)
// output a character to the console
void
cons_putc(int c)
{
	lpt_putc(c);
	cga_putc(c);
f01004ca:	89 3c 24             	mov    %edi,(%esp)
f01004cd:	e8 08 00 00 00       	call   f01004da <cga_putc>
}
f01004d2:	83 c4 1c             	add    $0x1c,%esp
f01004d5:	5b                   	pop    %ebx
f01004d6:	5e                   	pop    %esi
f01004d7:	5f                   	pop    %edi
f01004d8:	5d                   	pop    %ebp
f01004d9:	c3                   	ret    

f01004da <cga_putc>:



void
cga_putc(int c)
{
f01004da:	55                   	push   %ebp
f01004db:	89 e5                	mov    %esp,%ebp
f01004dd:	56                   	push   %esi
f01004de:	53                   	push   %ebx
f01004df:	83 ec 10             	sub    $0x10,%esp
f01004e2:	8b 45 08             	mov    0x8(%ebp),%eax
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01004e5:	a9 00 ff ff ff       	test   $0xffffff00,%eax
f01004ea:	75 03                	jne    f01004ef <cga_putc+0x15>
		c |= 0x0700;
f01004ec:	80 cc 07             	or     $0x7,%ah

	switch (c & 0xff) {
f01004ef:	0f b6 d0             	movzbl %al,%edx
f01004f2:	83 fa 09             	cmp    $0x9,%edx
f01004f5:	74 78                	je     f010056f <cga_putc+0x95>
f01004f7:	83 fa 09             	cmp    $0x9,%edx
f01004fa:	7f 0b                	jg     f0100507 <cga_putc+0x2d>
f01004fc:	83 fa 08             	cmp    $0x8,%edx
f01004ff:	0f 85 a8 00 00 00    	jne    f01005ad <cga_putc+0xd3>
f0100505:	eb 11                	jmp    f0100518 <cga_putc+0x3e>
f0100507:	83 fa 0a             	cmp    $0xa,%edx
f010050a:	74 3d                	je     f0100549 <cga_putc+0x6f>
f010050c:	83 fa 0d             	cmp    $0xd,%edx
f010050f:	90                   	nop
f0100510:	0f 85 97 00 00 00    	jne    f01005ad <cga_putc+0xd3>
f0100516:	eb 39                	jmp    f0100551 <cga_putc+0x77>
	case '\b':
		if (crt_pos > 0) {
f0100518:	0f b7 15 ac 23 11 f0 	movzwl 0xf01123ac,%edx
f010051f:	66 85 d2             	test   %dx,%dx
f0100522:	0f 84 f0 00 00 00    	je     f0100618 <cga_putc+0x13e>
			crt_pos--;
f0100528:	83 ea 01             	sub    $0x1,%edx
f010052b:	66 89 15 ac 23 11 f0 	mov    %dx,0xf01123ac
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100532:	0f b7 d2             	movzwl %dx,%edx
f0100535:	b0 00                	mov    $0x0,%al
f0100537:	83 c8 20             	or     $0x20,%eax
f010053a:	8b 0d a8 23 11 f0    	mov    0xf01123a8,%ecx
f0100540:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100544:	e9 82 00 00 00       	jmp    f01005cb <cga_putc+0xf1>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100549:	66 83 05 ac 23 11 f0 	addw   $0x50,0xf01123ac
f0100550:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100551:	0f b7 05 ac 23 11 f0 	movzwl 0xf01123ac,%eax
f0100558:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010055e:	c1 e8 16             	shr    $0x16,%eax
f0100561:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100564:	c1 e0 04             	shl    $0x4,%eax
f0100567:	66 a3 ac 23 11 f0    	mov    %ax,0xf01123ac
		break;
f010056d:	eb 5c                	jmp    f01005cb <cga_putc+0xf1>
	case '\t':
		cons_putc(' ');
f010056f:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100576:	e8 fd fe ff ff       	call   f0100478 <cons_putc>
		cons_putc(' ');
f010057b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100582:	e8 f1 fe ff ff       	call   f0100478 <cons_putc>
		cons_putc(' ');
f0100587:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010058e:	e8 e5 fe ff ff       	call   f0100478 <cons_putc>
		cons_putc(' ');
f0100593:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010059a:	e8 d9 fe ff ff       	call   f0100478 <cons_putc>
		cons_putc(' ');
f010059f:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01005a6:	e8 cd fe ff ff       	call   f0100478 <cons_putc>
		break;
f01005ab:	eb 1e                	jmp    f01005cb <cga_putc+0xf1>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01005ad:	0f b7 15 ac 23 11 f0 	movzwl 0xf01123ac,%edx
f01005b4:	0f b7 da             	movzwl %dx,%ebx
f01005b7:	8b 0d a8 23 11 f0    	mov    0xf01123a8,%ecx
f01005bd:	66 89 04 59          	mov    %ax,(%ecx,%ebx,2)
f01005c1:	83 c2 01             	add    $0x1,%edx
f01005c4:	66 89 15 ac 23 11 f0 	mov    %dx,0xf01123ac
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005cb:	66 81 3d ac 23 11 f0 	cmpw   $0x7cf,0xf01123ac
f01005d2:	cf 07 
f01005d4:	76 42                	jbe    f0100618 <cga_putc+0x13e>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005d6:	a1 a8 23 11 f0       	mov    0xf01123a8,%eax
f01005db:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01005e2:	00 
f01005e3:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005e9:	89 54 24 04          	mov    %edx,0x4(%esp)
f01005ed:	89 04 24             	mov    %eax,(%esp)
f01005f0:	e8 c3 14 00 00       	call   f0101ab8 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005f5:	8b 15 a8 23 11 f0    	mov    0xf01123a8,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005fb:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100600:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100606:	83 c0 01             	add    $0x1,%eax
f0100609:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f010060e:	75 f0                	jne    f0100600 <cga_putc+0x126>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100610:	66 83 2d ac 23 11 f0 	subw   $0x50,0xf01123ac
f0100617:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100618:	8b 0d a4 23 11 f0    	mov    0xf01123a4,%ecx
f010061e:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100623:	89 ca                	mov    %ecx,%edx
f0100625:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100626:	0f b7 1d ac 23 11 f0 	movzwl 0xf01123ac,%ebx
f010062d:	8d 71 01             	lea    0x1(%ecx),%esi
f0100630:	89 d8                	mov    %ebx,%eax
f0100632:	66 c1 e8 08          	shr    $0x8,%ax
f0100636:	89 f2                	mov    %esi,%edx
f0100638:	ee                   	out    %al,(%dx)
f0100639:	b8 0f 00 00 00       	mov    $0xf,%eax
f010063e:	89 ca                	mov    %ecx,%edx
f0100640:	ee                   	out    %al,(%dx)
f0100641:	89 d8                	mov    %ebx,%eax
f0100643:	89 f2                	mov    %esi,%edx
f0100645:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
	outb(addr_6845 + 1, crt_pos);
}
f0100646:	83 c4 10             	add    $0x10,%esp
f0100649:	5b                   	pop    %ebx
f010064a:	5e                   	pop    %esi
f010064b:	5d                   	pop    %ebp
f010064c:	c3                   	ret    

f010064d <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010064d:	55                   	push   %ebp
f010064e:	89 e5                	mov    %esp,%ebp
f0100650:	83 ec 18             	sub    $0x18,%esp
	cga_init();
f0100653:	e8 c9 fc ff ff       	call   f0100321 <cga_init>
	kbd_init();
	serial_init();
f0100658:	e8 65 fc ff ff       	call   f01002c2 <serial_init>

	if (!serial_exists)
f010065d:	83 3d a0 23 11 f0 00 	cmpl   $0x0,0xf01123a0
f0100664:	75 0c                	jne    f0100672 <cons_init+0x25>
		cprintf("Serial port does not exist!\n");
f0100666:	c7 04 24 10 20 10 f0 	movl   $0xf0102010,(%esp)
f010066d:	e8 c0 08 00 00       	call   f0100f32 <cprintf>
}
f0100672:	c9                   	leave  
f0100673:	c3                   	ret    

f0100674 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100674:	55                   	push   %ebp
f0100675:	89 e5                	mov    %esp,%ebp
f0100677:	83 ec 18             	sub    $0x18,%esp
	cons_putc(c);
f010067a:	8b 45 08             	mov    0x8(%ebp),%eax
f010067d:	89 04 24             	mov    %eax,(%esp)
f0100680:	e8 f3 fd ff ff       	call   f0100478 <cons_putc>
}
f0100685:	c9                   	leave  
f0100686:	c3                   	ret    

f0100687 <getchar>:

int
getchar(void)
{
f0100687:	55                   	push   %ebp
f0100688:	89 e5                	mov    %esp,%ebp
f010068a:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010068d:	e8 9e fd ff ff       	call   f0100430 <cons_getc>
f0100692:	85 c0                	test   %eax,%eax
f0100694:	74 f7                	je     f010068d <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100696:	c9                   	leave  
f0100697:	c3                   	ret    

f0100698 <iscons>:

int
iscons(int fdnum)
{
f0100698:	55                   	push   %ebp
f0100699:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010069b:	b8 01 00 00 00       	mov    $0x1,%eax
f01006a0:	5d                   	pop    %ebp
f01006a1:	c3                   	ret    
	...

f01006b0 <mon_kerninfo>:



int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006b0:	55                   	push   %ebp
f01006b1:	89 e5                	mov    %esp,%ebp
f01006b3:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006b6:	c7 04 24 50 22 10 f0 	movl   $0xf0102250,(%esp)
f01006bd:	e8 70 08 00 00       	call   f0100f32 <cprintf>
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
f01006c2:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006c9:	00 
f01006ca:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006d1:	f0 
f01006d2:	c7 04 24 f8 22 10 f0 	movl   $0xf01022f8,(%esp)
f01006d9:	e8 54 08 00 00       	call   f0100f32 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006de:	c7 44 24 08 7d 1f 10 	movl   $0x101f7d,0x8(%esp)
f01006e5:	00 
f01006e6:	c7 44 24 04 7d 1f 10 	movl   $0xf0101f7d,0x4(%esp)
f01006ed:	f0 
f01006ee:	c7 04 24 1c 23 10 f0 	movl   $0xf010231c,(%esp)
f01006f5:	e8 38 08 00 00       	call   f0100f32 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006fa:	c7 44 24 08 70 23 11 	movl   $0x112370,0x8(%esp)
f0100701:	00 
f0100702:	c7 44 24 04 70 23 11 	movl   $0xf0112370,0x4(%esp)
f0100709:	f0 
f010070a:	c7 04 24 40 23 10 f0 	movl   $0xf0102340,(%esp)
f0100711:	e8 1c 08 00 00       	call   f0100f32 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100716:	c7 44 24 08 10 2a 11 	movl   $0x112a10,0x8(%esp)
f010071d:	00 
f010071e:	c7 44 24 04 10 2a 11 	movl   $0xf0112a10,0x4(%esp)
f0100725:	f0 
f0100726:	c7 04 24 64 23 10 f0 	movl   $0xf0102364,(%esp)
f010072d:	e8 00 08 00 00       	call   f0100f32 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-_start+1023)/1024);
f0100732:	b8 0f 2e 11 f0       	mov    $0xf0112e0f,%eax
f0100737:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010073c:	89 c2                	mov    %eax,%edx
f010073e:	c1 fa 1f             	sar    $0x1f,%edx
f0100741:	c1 ea 16             	shr    $0x16,%edx
f0100744:	01 d0                	add    %edx,%eax
f0100746:	c1 f8 0a             	sar    $0xa,%eax
f0100749:	89 44 24 04          	mov    %eax,0x4(%esp)
f010074d:	c7 04 24 88 23 10 f0 	movl   $0xf0102388,(%esp)
f0100754:	e8 d9 07 00 00       	call   f0100f32 <cprintf>
		(end-_start+1023)/1024);
	return 0;
}
f0100759:	b8 00 00 00 00       	mov    $0x0,%eax
f010075e:	c9                   	leave  
f010075f:	c3                   	ret    

f0100760 <mon_readebp>:
	return 0;
}

int
mon_readebp(int argc, char **argv, struct Trapframe *tf)
{
f0100760:	55                   	push   %ebp
f0100761:	89 e5                	mov    %esp,%ebp
f0100763:	83 ec 18             	sub    $0x18,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100766:	89 e8                	mov    %ebp,%eax
	unsigned int ebp;                                                                                                                                                                                                                             ebp = read_ebp();
	cprintf("ebp:%08x",ebp);
f0100768:	89 44 24 04          	mov    %eax,0x4(%esp)
f010076c:	c7 04 24 69 22 10 f0 	movl   $0xf0102269,(%esp)
f0100773:	e8 ba 07 00 00       	call   f0100f32 <cprintf>
	return 0;	
}
f0100778:	b8 00 00 00 00       	mov    $0x0,%eax
f010077d:	c9                   	leave  
f010077e:	c3                   	ret    

f010077f <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010077f:	55                   	push   %ebp
f0100780:	89 e5                	mov    %esp,%ebp
f0100782:	56                   	push   %esi
f0100783:	53                   	push   %ebx
f0100784:	83 ec 10             	sub    $0x10,%esp
f0100787:	bb 64 24 10 f0       	mov    $0xf0102464,%ebx
unsigned read_eip();

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
f010078c:	be 88 24 10 f0       	mov    $0xf0102488,%esi
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100791:	8b 03                	mov    (%ebx),%eax
f0100793:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100797:	8b 43 fc             	mov    -0x4(%ebx),%eax
f010079a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010079e:	c7 04 24 72 22 10 f0 	movl   $0xf0102272,(%esp)
f01007a5:	e8 88 07 00 00       	call   f0100f32 <cprintf>
f01007aa:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f01007ad:	39 f3                	cmp    %esi,%ebx
f01007af:	75 e0                	jne    f0100791 <mon_help+0x12>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f01007b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01007b6:	83 c4 10             	add    $0x10,%esp
f01007b9:	5b                   	pop    %ebx
f01007ba:	5e                   	pop    %esi
f01007bb:	5d                   	pop    %ebp
f01007bc:	c3                   	ret    

f01007bd <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007bd:	55                   	push   %ebp
f01007be:	89 e5                	mov    %esp,%ebp
f01007c0:	53                   	push   %ebx
f01007c1:	83 ec 24             	sub    $0x24,%esp
f01007c4:	89 e8                	mov    %ebp,%eax
f01007c6:	89 c3                	mov    %eax,%ebx
	// Your code here.
    unsigned int ebp;                                                                                                                                                                                                                         
    ebp = read_ebp();                                                             
    int a=0;                                                                      
    while(ebp>0)                                                                
f01007c8:	85 c0                	test   %eax,%eax
f01007ca:	74 32                	je     f01007fe <mon_backtrace+0x41>
    {                                                                             
        cprintf("ebp %x eip %x args %08x %08x %08x\n",ebp,*((unsigned int*)ebp+1),
f01007cc:	8b 43 10             	mov    0x10(%ebx),%eax
f01007cf:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007d3:	8b 43 0c             	mov    0xc(%ebx),%eax
f01007d6:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007da:	8b 43 08             	mov    0x8(%ebx),%eax
f01007dd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007e1:	8b 43 04             	mov    0x4(%ebx),%eax
f01007e4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007e8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01007ec:	c7 04 24 b4 23 10 f0 	movl   $0xf01023b4,(%esp)
f01007f3:	e8 3a 07 00 00       	call   f0100f32 <cprintf>
                *((unsigned int *)ebp+2),*((unsigned int *)ebp+3),*((unsigned int*)ebp+4));
        ebp = *( unsigned int *)ebp;                                              
f01007f8:	8b 1b                	mov    (%ebx),%ebx
{
	// Your code here.
    unsigned int ebp;                                                                                                                                                                                                                         
    ebp = read_ebp();                                                             
    int a=0;                                                                      
    while(ebp>0)                                                                
f01007fa:	85 db                	test   %ebx,%ebx
f01007fc:	75 ce                	jne    f01007cc <mon_backtrace+0xf>
        cprintf("ebp %x eip %x args %08x %08x %08x\n",ebp,*((unsigned int*)ebp+1),
                *((unsigned int *)ebp+2),*((unsigned int *)ebp+3),*((unsigned int*)ebp+4));
        ebp = *( unsigned int *)ebp;                                              
    }                 
    return 0;
}
f01007fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0100803:	83 c4 24             	add    $0x24,%esp
f0100806:	5b                   	pop    %ebx
f0100807:	5d                   	pop    %ebp
f0100808:	c3                   	ret    

f0100809 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100809:	55                   	push   %ebp
f010080a:	89 e5                	mov    %esp,%ebp
f010080c:	57                   	push   %edi
f010080d:	56                   	push   %esi
f010080e:	53                   	push   %ebx
f010080f:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100812:	c7 04 24 d8 23 10 f0 	movl   $0xf01023d8,(%esp)
f0100819:	e8 14 07 00 00       	call   f0100f32 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010081e:	c7 04 24 fc 23 10 f0 	movl   $0xf01023fc,(%esp)
f0100825:	e8 08 07 00 00       	call   f0100f32 <cprintf>


	while (1) {
		buf = readline("K> ");
f010082a:	c7 04 24 7b 22 10 f0 	movl   $0xf010227b,(%esp)
f0100831:	e8 ca 0f 00 00       	call   f0101800 <readline>
f0100836:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100838:	85 c0                	test   %eax,%eax
f010083a:	74 ee                	je     f010082a <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010083c:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100843:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100848:	eb 06                	jmp    f0100850 <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010084a:	c6 06 00             	movb   $0x0,(%esi)
f010084d:	83 c6 01             	add    $0x1,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100850:	0f b6 06             	movzbl (%esi),%eax
f0100853:	84 c0                	test   %al,%al
f0100855:	74 6a                	je     f01008c1 <monitor+0xb8>
f0100857:	0f be c0             	movsbl %al,%eax
f010085a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010085e:	c7 04 24 7f 22 10 f0 	movl   $0xf010227f,(%esp)
f0100865:	e8 d0 11 00 00       	call   f0101a3a <strchr>
f010086a:	85 c0                	test   %eax,%eax
f010086c:	75 dc                	jne    f010084a <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f010086e:	80 3e 00             	cmpb   $0x0,(%esi)
f0100871:	74 4e                	je     f01008c1 <monitor+0xb8>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100873:	83 fb 0f             	cmp    $0xf,%ebx
f0100876:	75 16                	jne    f010088e <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100878:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010087f:	00 
f0100880:	c7 04 24 84 22 10 f0 	movl   $0xf0102284,(%esp)
f0100887:	e8 a6 06 00 00       	call   f0100f32 <cprintf>
f010088c:	eb 9c                	jmp    f010082a <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f010088e:	89 74 9d a8          	mov    %esi,-0x58(%ebp,%ebx,4)
f0100892:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f0100895:	0f b6 06             	movzbl (%esi),%eax
f0100898:	84 c0                	test   %al,%al
f010089a:	75 0c                	jne    f01008a8 <monitor+0x9f>
f010089c:	eb b2                	jmp    f0100850 <monitor+0x47>
			buf++;
f010089e:	83 c6 01             	add    $0x1,%esi
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008a1:	0f b6 06             	movzbl (%esi),%eax
f01008a4:	84 c0                	test   %al,%al
f01008a6:	74 a8                	je     f0100850 <monitor+0x47>
f01008a8:	0f be c0             	movsbl %al,%eax
f01008ab:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008af:	c7 04 24 7f 22 10 f0 	movl   $0xf010227f,(%esp)
f01008b6:	e8 7f 11 00 00       	call   f0101a3a <strchr>
f01008bb:	85 c0                	test   %eax,%eax
f01008bd:	74 df                	je     f010089e <monitor+0x95>
f01008bf:	eb 8f                	jmp    f0100850 <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f01008c1:	c7 44 9d a8 00 00 00 	movl   $0x0,-0x58(%ebp,%ebx,4)
f01008c8:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008c9:	85 db                	test   %ebx,%ebx
f01008cb:	0f 84 59 ff ff ff    	je     f010082a <monitor+0x21>
f01008d1:	bf 60 24 10 f0       	mov    $0xf0102460,%edi
f01008d6:	be 00 00 00 00       	mov    $0x0,%esi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008db:	8b 07                	mov    (%edi),%eax
f01008dd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008e1:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008e4:	89 04 24             	mov    %eax,(%esp)
f01008e7:	e8 ca 10 00 00       	call   f01019b6 <strcmp>
f01008ec:	85 c0                	test   %eax,%eax
f01008ee:	75 24                	jne    f0100914 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f01008f0:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01008f3:	8b 55 08             	mov    0x8(%ebp),%edx
f01008f6:	89 54 24 08          	mov    %edx,0x8(%esp)
f01008fa:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008fd:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100901:	89 1c 24             	mov    %ebx,(%esp)
f0100904:	ff 14 85 68 24 10 f0 	call   *-0xfefdb98(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010090b:	85 c0                	test   %eax,%eax
f010090d:	78 28                	js     f0100937 <monitor+0x12e>
f010090f:	e9 16 ff ff ff       	jmp    f010082a <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100914:	83 c6 01             	add    $0x1,%esi
f0100917:	83 c7 0c             	add    $0xc,%edi
f010091a:	83 fe 03             	cmp    $0x3,%esi
f010091d:	75 bc                	jne    f01008db <monitor+0xd2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010091f:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100922:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100926:	c7 04 24 a1 22 10 f0 	movl   $0xf01022a1,(%esp)
f010092d:	e8 00 06 00 00       	call   f0100f32 <cprintf>
f0100932:	e9 f3 fe ff ff       	jmp    f010082a <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100937:	83 c4 5c             	add    $0x5c,%esp
f010093a:	5b                   	pop    %ebx
f010093b:	5e                   	pop    %esi
f010093c:	5f                   	pop    %edi
f010093d:	5d                   	pop    %ebp
f010093e:	c3                   	ret    

f010093f <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f010093f:	55                   	push   %ebp
f0100940:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f0100942:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100945:	5d                   	pop    %ebp
f0100946:	c3                   	ret    
	...

f0100948 <nvram_read>:
	sizeof(gdt) - 1, (unsigned long) gdt
};

static int
nvram_read(int r)
{
f0100948:	55                   	push   %ebp
f0100949:	89 e5                	mov    %esp,%ebp
f010094b:	83 ec 18             	sub    $0x18,%esp
f010094e:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100951:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100954:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100956:	89 04 24             	mov    %eax,(%esp)
f0100959:	e8 62 05 00 00       	call   f0100ec0 <mc146818_read>
f010095e:	89 c6                	mov    %eax,%esi
f0100960:	83 c3 01             	add    $0x1,%ebx
f0100963:	89 1c 24             	mov    %ebx,(%esp)
f0100966:	e8 55 05 00 00       	call   f0100ec0 <mc146818_read>
f010096b:	c1 e0 08             	shl    $0x8,%eax
f010096e:	09 f0                	or     %esi,%eax
}
f0100970:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100973:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100976:	89 ec                	mov    %ebp,%esp
f0100978:	5d                   	pop    %ebp
f0100979:	c3                   	ret    

f010097a <i386_detect_memory>:

void
i386_detect_memory(void)
{
f010097a:	55                   	push   %ebp
f010097b:	89 e5                	mov    %esp,%ebp
f010097d:	83 ec 18             	sub    $0x18,%esp
	// CMOS tells us how many kilobytes there are
	basemem = ROUNDDOWN(nvram_read(NVRAM_BASELO)*1024, PGSIZE);
f0100980:	b8 15 00 00 00       	mov    $0x15,%eax
f0100985:	e8 be ff ff ff       	call   f0100948 <nvram_read>
f010098a:	c1 e0 0a             	shl    $0xa,%eax
f010098d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100992:	a3 c8 25 11 f0       	mov    %eax,0xf01125c8
	extmem = ROUNDDOWN(nvram_read(NVRAM_EXTLO)*1024, PGSIZE);
f0100997:	b8 17 00 00 00       	mov    $0x17,%eax
f010099c:	e8 a7 ff ff ff       	call   f0100948 <nvram_read>
f01009a1:	c1 e0 0a             	shl    $0xa,%eax
f01009a4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009a9:	a3 cc 25 11 f0       	mov    %eax,0xf01125cc

	// Calculate the maximum physical address based on whether
	// or not there is any extended memory.  See comment in <inc/mmu.h>.
	if (extmem)
f01009ae:	85 c0                	test   %eax,%eax
f01009b0:	74 0c                	je     f01009be <i386_detect_memory+0x44>
		maxpa = EXTPHYSMEM + extmem;
f01009b2:	05 00 00 10 00       	add    $0x100000,%eax
f01009b7:	a3 d0 25 11 f0       	mov    %eax,0xf01125d0
f01009bc:	eb 0a                	jmp    f01009c8 <i386_detect_memory+0x4e>
	else
		maxpa = basemem;
f01009be:	a1 c8 25 11 f0       	mov    0xf01125c8,%eax
f01009c3:	a3 d0 25 11 f0       	mov    %eax,0xf01125d0

	npage = maxpa / PGSIZE;
f01009c8:	a1 d0 25 11 f0       	mov    0xf01125d0,%eax
f01009cd:	89 c2                	mov    %eax,%edx
f01009cf:	c1 ea 0c             	shr    $0xc,%edx
f01009d2:	89 15 00 2a 11 f0    	mov    %edx,0xf0112a00

	cprintf("Physical memory: %dK available, ", (int)(maxpa/1024));
f01009d8:	c1 e8 0a             	shr    $0xa,%eax
f01009db:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009df:	c7 04 24 84 24 10 f0 	movl   $0xf0102484,(%esp)
f01009e6:	e8 47 05 00 00       	call   f0100f32 <cprintf>
	cprintf("base = %dK, extended = %dK\n", (int)(basemem/1024), (int)(extmem/1024));
f01009eb:	a1 cc 25 11 f0       	mov    0xf01125cc,%eax
f01009f0:	c1 e8 0a             	shr    $0xa,%eax
f01009f3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009f7:	a1 c8 25 11 f0       	mov    0xf01125c8,%eax
f01009fc:	c1 e8 0a             	shr    $0xa,%eax
f01009ff:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a03:	c7 04 24 d5 24 10 f0 	movl   $0xf01024d5,(%esp)
f0100a0a:	e8 23 05 00 00       	call   f0100f32 <cprintf>
}
f0100a0f:	c9                   	leave  
f0100a10:	c3                   	ret    

f0100a11 <i386_vm_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read (or write). 
void
i386_vm_init(void)
{
f0100a11:	55                   	push   %ebp
f0100a12:	89 e5                	mov    %esp,%ebp
f0100a14:	83 ec 18             	sub    $0x18,%esp
	pde_t* pgdir;
	uint32_t cr0;
	size_t n;

	// Delete this line:
	panic("i386_vm_init: This function is not finished\n");
f0100a17:	c7 44 24 08 a8 24 10 	movl   $0xf01024a8,0x8(%esp)
f0100a1e:	f0 
f0100a1f:	c7 44 24 04 94 00 00 	movl   $0x94,0x4(%esp)
f0100a26:	00 
f0100a27:	c7 04 24 f1 24 10 f0 	movl   $0xf01024f1,(%esp)
f0100a2e:	e8 c3 f6 ff ff       	call   f01000f6 <_panic>

f0100a33 <page_init>:
	//     Some of it is in use, some is free. Where is the kernel?
	//     Which pages are used for page tables and other data structures?
	//
	// Change the code to reflect this.
	int i;
	LIST_INIT(&page_free_list);
f0100a33:	c7 05 d4 25 11 f0 00 	movl   $0x0,0xf01125d4
f0100a3a:	00 00 00 
	for (i = 0; i < npage; i++) {
f0100a3d:	83 3d 00 2a 11 f0 00 	cmpl   $0x0,0xf0112a00
f0100a44:	74 67                	je     f0100aad <page_init+0x7a>
// to allocate and deallocate physical memory via the page_free_list,
// and NEVER use boot_alloc()
//
void
page_init(void)
{
f0100a46:	55                   	push   %ebp
f0100a47:	89 e5                	mov    %esp,%ebp
f0100a49:	56                   	push   %esi
f0100a4a:	53                   	push   %ebx
	//     Which pages are used for page tables and other data structures?
	//
	// Change the code to reflect this.
	int i;
	LIST_INIT(&page_free_list);
	for (i = 0; i < npage; i++) {
f0100a4b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100a50:	b8 00 00 00 00       	mov    $0x0,%eax
		pages[i].pp_ref = 0;
f0100a55:	8d 34 52             	lea    (%edx,%edx,2),%esi
f0100a58:	8d 14 b5 00 00 00 00 	lea    0x0(,%esi,4),%edx
f0100a5f:	8b 1d 0c 2a 11 f0    	mov    0xf0112a0c,%ebx
f0100a65:	66 c7 44 13 08 00 00 	movw   $0x0,0x8(%ebx,%edx,1)
		LIST_INSERT_HEAD(&page_free_list, &pages[i], pp_link);
f0100a6c:	8b 0d d4 25 11 f0    	mov    0xf01125d4,%ecx
f0100a72:	89 0c b3             	mov    %ecx,(%ebx,%esi,4)
f0100a75:	85 c9                	test   %ecx,%ecx
f0100a77:	74 11                	je     f0100a8a <page_init+0x57>
f0100a79:	8b 1d 0c 2a 11 f0    	mov    0xf0112a0c,%ebx
f0100a7f:	01 d3                	add    %edx,%ebx
f0100a81:	8b 0d d4 25 11 f0    	mov    0xf01125d4,%ecx
f0100a87:	89 59 04             	mov    %ebx,0x4(%ecx)
f0100a8a:	03 15 0c 2a 11 f0    	add    0xf0112a0c,%edx
f0100a90:	89 15 d4 25 11 f0    	mov    %edx,0xf01125d4
f0100a96:	c7 42 04 d4 25 11 f0 	movl   $0xf01125d4,0x4(%edx)
	//     Which pages are used for page tables and other data structures?
	//
	// Change the code to reflect this.
	int i;
	LIST_INIT(&page_free_list);
	for (i = 0; i < npage; i++) {
f0100a9d:	83 c0 01             	add    $0x1,%eax
f0100aa0:	89 c2                	mov    %eax,%edx
f0100aa2:	3b 05 00 2a 11 f0    	cmp    0xf0112a00,%eax
f0100aa8:	72 ab                	jb     f0100a55 <page_init+0x22>
		pages[i].pp_ref = 0;
		LIST_INSERT_HEAD(&page_free_list, &pages[i], pp_link);
	}
}
f0100aaa:	5b                   	pop    %ebx
f0100aab:	5e                   	pop    %esi
f0100aac:	5d                   	pop    %ebp
f0100aad:	f3 c3                	repz ret 

f0100aaf <page_alloc>:
//
// Hint: use LIST_FIRST, LIST_REMOVE, and page_initpp
// Hint: pp_ref should not be incremented 
int
page_alloc(struct Page **pp_store)
{
f0100aaf:	55                   	push   %ebp
f0100ab0:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return -E_NO_MEM;
}
f0100ab2:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0100ab7:	5d                   	pop    %ebp
f0100ab8:	c3                   	ret    

f0100ab9 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0100ab9:	55                   	push   %ebp
f0100aba:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0100abc:	5d                   	pop    %ebp
f0100abd:	c3                   	ret    

f0100abe <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0100abe:	55                   	push   %ebp
f0100abf:	89 e5                	mov    %esp,%ebp
f0100ac1:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100ac4:	66 83 68 08 01       	subw   $0x1,0x8(%eax)
		page_free(pp);
}
f0100ac9:	5d                   	pop    %ebp
f0100aca:	c3                   	ret    

f0100acb <pgdir_walk>:
//
// Hint: you can turn a Page * into the physical address of the
// page it refers to with page2pa() from kern/pmap.h.
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100acb:	55                   	push   %ebp
f0100acc:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100ace:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ad3:	5d                   	pop    %ebp
f0100ad4:	c3                   	ret    

f0100ad5 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm) 
{
f0100ad5:	55                   	push   %ebp
f0100ad6:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100ad8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100add:	5d                   	pop    %ebp
f0100ade:	c3                   	ret    

f0100adf <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100adf:	55                   	push   %ebp
f0100ae0:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100ae2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ae7:	5d                   	pop    %ebp
f0100ae8:	c3                   	ret    

f0100ae9 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100ae9:	55                   	push   %ebp
f0100aea:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0100aec:	5d                   	pop    %ebp
f0100aed:	c3                   	ret    

f0100aee <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100aee:	55                   	push   %ebp
f0100aef:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100af1:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100af4:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0100af7:	5d                   	pop    %ebp
f0100af8:	c3                   	ret    
f0100af9:	00 00                	add    %al,(%eax)
	...

f0100afc <envid2env>:
//   On success, sets *penv to the environment.
//   On error, sets *penv to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0100afc:	55                   	push   %ebp
f0100afd:	89 e5                	mov    %esp,%ebp
f0100aff:	8b 45 08             	mov    0x8(%ebp),%eax
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0100b02:	85 c0                	test   %eax,%eax
f0100b04:	75 11                	jne    f0100b17 <envid2env+0x1b>
		*env_store = curenv;
f0100b06:	a1 d8 25 11 f0       	mov    0xf01125d8,%eax
f0100b0b:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100b0e:	89 02                	mov    %eax,(%edx)
		return 0;
f0100b10:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b15:	eb 5d                	jmp    f0100b74 <envid2env+0x78>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0100b17:	89 c2                	mov    %eax,%edx
f0100b19:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b1f:	6b d2 64             	imul   $0x64,%edx,%edx
f0100b22:	03 15 dc 25 11 f0    	add    0xf01125dc,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0100b28:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f0100b2c:	74 05                	je     f0100b33 <envid2env+0x37>
f0100b2e:	39 42 4c             	cmp    %eax,0x4c(%edx)
f0100b31:	74 10                	je     f0100b43 <envid2env+0x47>
		*env_store = 0;
f0100b33:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0100b36:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		return -E_BAD_ENV;
f0100b3c:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0100b41:	eb 31                	jmp    f0100b74 <envid2env+0x78>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0100b43:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100b47:	74 21                	je     f0100b6a <envid2env+0x6e>
f0100b49:	a1 d8 25 11 f0       	mov    0xf01125d8,%eax
f0100b4e:	39 c2                	cmp    %eax,%edx
f0100b50:	74 18                	je     f0100b6a <envid2env+0x6e>
f0100b52:	8b 48 4c             	mov    0x4c(%eax),%ecx
f0100b55:	39 4a 50             	cmp    %ecx,0x50(%edx)
f0100b58:	74 10                	je     f0100b6a <envid2env+0x6e>
		*env_store = 0;
f0100b5a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100b5d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0100b63:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0100b68:	eb 0a                	jmp    f0100b74 <envid2env+0x78>
	}

	*env_store = e;
f0100b6a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0100b6d:	89 11                	mov    %edx,(%ecx)
	return 0;
f0100b6f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100b74:	5d                   	pop    %ebp
f0100b75:	c3                   	ret    

f0100b76 <env_init>:
// Insert in reverse order, so that the first call to env_alloc()
// returns envs[0].
//
void
env_init(void)
{
f0100b76:	55                   	push   %ebp
f0100b77:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f0100b79:	5d                   	pop    %ebp
f0100b7a:	c3                   	ret    

f0100b7b <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0100b7b:	55                   	push   %ebp
f0100b7c:	89 e5                	mov    %esp,%ebp
f0100b7e:	53                   	push   %ebx
f0100b7f:	83 ec 24             	sub    $0x24,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = LIST_FIRST(&env_free_list)))
f0100b82:	8b 1d e0 25 11 f0    	mov    0xf01125e0,%ebx
f0100b88:	85 db                	test   %ebx,%ebx
f0100b8a:	0f 84 f8 00 00 00    	je     f0100c88 <env_alloc+0x10d>
//
static int
env_setup_vm(struct Env *e)
{
	int i, r;
	struct Page *p = NULL;
f0100b90:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// Allocate a page for the page directory
	if ((r = page_alloc(&p)) < 0)
f0100b97:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100b9a:	89 04 24             	mov    %eax,(%esp)
f0100b9d:	e8 0d ff ff ff       	call   f0100aaf <page_alloc>
f0100ba2:	85 c0                	test   %eax,%eax
f0100ba4:	0f 88 e3 00 00 00    	js     f0100c8d <env_alloc+0x112>

	// LAB 3: Your code here.

	// VPT and UVPT map the env's own page table, with
	// different permissions.
	e->env_pgdir[PDX(VPT)]  = e->env_cr3 | PTE_P | PTE_W;
f0100baa:	8b 43 5c             	mov    0x5c(%ebx),%eax
f0100bad:	8b 53 60             	mov    0x60(%ebx),%edx
f0100bb0:	83 ca 03             	or     $0x3,%edx
f0100bb3:	89 90 fc 0e 00 00    	mov    %edx,0xefc(%eax)
	e->env_pgdir[PDX(UVPT)] = e->env_cr3 | PTE_P | PTE_U;
f0100bb9:	8b 43 5c             	mov    0x5c(%ebx),%eax
f0100bbc:	8b 53 60             	mov    0x60(%ebx),%edx
f0100bbf:	83 ca 05             	or     $0x5,%edx
f0100bc2:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0100bc8:	8b 43 4c             	mov    0x4c(%ebx),%eax
f0100bcb:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0100bd0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100bd5:	7f 05                	jg     f0100bdc <env_alloc+0x61>
		generation = 1 << ENVGENSHIFT;
f0100bd7:	b8 00 10 00 00       	mov    $0x1000,%eax
	e->env_id = generation | (e - envs);
f0100bdc:	89 da                	mov    %ebx,%edx
f0100bde:	2b 15 dc 25 11 f0    	sub    0xf01125dc,%edx
f0100be4:	c1 fa 02             	sar    $0x2,%edx
f0100be7:	69 d2 29 5c 8f c2    	imul   $0xc28f5c29,%edx,%edx
f0100bed:	09 d0                	or     %edx,%eax
f0100bef:	89 43 4c             	mov    %eax,0x4c(%ebx)
	
	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0100bf2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100bf5:	89 43 50             	mov    %eax,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0100bf8:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
	e->env_runs = 0;
f0100bff:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0100c06:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0100c0d:	00 
f0100c0e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100c15:	00 
f0100c16:	89 1c 24             	mov    %ebx,(%esp)
f0100c19:	e8 76 0e 00 00       	call   f0101a94 <memset>
	// Set up appropriate initial values for the segment registers.
	// GD_UD is the user data segment selector in the GDT, and 
	// GD_UT is the user text segment selector (see inc/memlayout.h).
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.
	e->env_tf.tf_ds = GD_UD | 3;
f0100c1e:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0100c24:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0100c2a:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0100c30:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0100c37:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	LIST_REMOVE(e, env_link);
f0100c3d:	8b 43 44             	mov    0x44(%ebx),%eax
f0100c40:	85 c0                	test   %eax,%eax
f0100c42:	74 06                	je     f0100c4a <env_alloc+0xcf>
f0100c44:	8b 53 48             	mov    0x48(%ebx),%edx
f0100c47:	89 50 48             	mov    %edx,0x48(%eax)
f0100c4a:	8b 43 48             	mov    0x48(%ebx),%eax
f0100c4d:	8b 53 44             	mov    0x44(%ebx),%edx
f0100c50:	89 10                	mov    %edx,(%eax)
	*newenv_store = e;
f0100c52:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c55:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0100c57:	8b 53 4c             	mov    0x4c(%ebx),%edx
f0100c5a:	a1 d8 25 11 f0       	mov    0xf01125d8,%eax
f0100c5f:	85 c0                	test   %eax,%eax
f0100c61:	74 05                	je     f0100c68 <env_alloc+0xed>
f0100c63:	8b 40 4c             	mov    0x4c(%eax),%eax
f0100c66:	eb 05                	jmp    f0100c6d <env_alloc+0xf2>
f0100c68:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c6d:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100c71:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c75:	c7 04 24 fd 24 10 f0 	movl   $0xf01024fd,(%esp)
f0100c7c:	e8 b1 02 00 00       	call   f0100f32 <cprintf>
	return 0;
f0100c81:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c86:	eb 05                	jmp    f0100c8d <env_alloc+0x112>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = LIST_FIRST(&env_free_list)))
		return -E_NO_FREE_ENV;
f0100c88:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
	LIST_REMOVE(e, env_link);
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0100c8d:	83 c4 24             	add    $0x24,%esp
f0100c90:	5b                   	pop    %ebx
f0100c91:	5d                   	pop    %ebp
f0100c92:	c3                   	ret    

f0100c93 <env_create>:
// By convention, envs[0] is the first environment allocated, so
// whoever calls env_create simply looks for the newly created
// environment there. 
void
env_create(uint8_t *binary, size_t size)
{
f0100c93:	55                   	push   %ebp
f0100c94:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f0100c96:	5d                   	pop    %ebp
f0100c97:	c3                   	ret    

f0100c98 <env_free>:
//
// Frees env e and all memory it uses.
// 
void
env_free(struct Env *e)
{
f0100c98:	55                   	push   %ebp
f0100c99:	89 e5                	mov    %esp,%ebp
f0100c9b:	57                   	push   %edi
f0100c9c:	56                   	push   %esi
f0100c9d:	53                   	push   %ebx
f0100c9e:	83 ec 2c             	sub    $0x2c,%esp
f0100ca1:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;
	
	// If freeing the current environment, switch to boot_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0100ca4:	a1 d8 25 11 f0       	mov    0xf01125d8,%eax
f0100ca9:	39 c7                	cmp    %eax,%edi
f0100cab:	75 09                	jne    f0100cb6 <env_free+0x1e>
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0100cad:	8b 15 04 2a 11 f0    	mov    0xf0112a04,%edx
f0100cb3:	0f 22 da             	mov    %edx,%cr3
		lcr3(boot_cr3);

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0100cb6:	8b 57 4c             	mov    0x4c(%edi),%edx
f0100cb9:	85 c0                	test   %eax,%eax
f0100cbb:	74 05                	je     f0100cc2 <env_free+0x2a>
f0100cbd:	8b 40 4c             	mov    0x4c(%eax),%eax
f0100cc0:	eb 05                	jmp    f0100cc7 <env_free+0x2f>
f0100cc2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cc7:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100ccb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ccf:	c7 04 24 12 25 10 f0 	movl   $0xf0102512,(%esp)
f0100cd6:	e8 57 02 00 00       	call   f0100f32 <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0100cdb:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)

//
// Frees env e and all memory it uses.
// 
void
env_free(struct Env *e)
f0100ce2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ce5:	c1 e0 02             	shl    $0x2,%eax
f0100ce8:	89 45 d8             	mov    %eax,-0x28(%ebp)
	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0100ceb:	8b 47 5c             	mov    0x5c(%edi),%eax
f0100cee:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100cf1:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0100cf4:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0100cfa:	0f 84 ba 00 00 00    	je     f0100dba <env_free+0x122>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0100d00:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
		pt = (pte_t*) KADDR(pa);
f0100d06:	89 f0                	mov    %esi,%eax
f0100d08:	c1 e8 0c             	shr    $0xc,%eax
f0100d0b:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100d0e:	3b 05 00 2a 11 f0    	cmp    0xf0112a00,%eax
f0100d14:	72 20                	jb     f0100d36 <env_free+0x9e>
f0100d16:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d1a:	c7 44 24 08 6c 25 10 	movl   $0xf010256c,0x8(%esp)
f0100d21:	f0 
f0100d22:	c7 44 24 04 32 01 00 	movl   $0x132,0x4(%esp)
f0100d29:	00 
f0100d2a:	c7 04 24 28 25 10 f0 	movl   $0xf0102528,(%esp)
f0100d31:	e8 c0 f3 ff ff       	call   f01000f6 <_panic>

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0100d36:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100d39:	c1 e2 16             	shl    $0x16,%edx
f0100d3c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0100d3f:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0100d44:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0100d4b:	01 
f0100d4c:	74 17                	je     f0100d65 <env_free+0xcd>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0100d4e:	89 d8                	mov    %ebx,%eax
f0100d50:	c1 e0 0c             	shl    $0xc,%eax
f0100d53:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0100d56:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d5a:	8b 47 5c             	mov    0x5c(%edi),%eax
f0100d5d:	89 04 24             	mov    %eax,(%esp)
f0100d60:	e8 84 fd ff ff       	call   f0100ae9 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0100d65:	83 c3 01             	add    $0x1,%ebx
f0100d68:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0100d6e:	75 d4                	jne    f0100d44 <env_free+0xac>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0100d70:	8b 47 5c             	mov    0x5c(%edi),%eax
f0100d73:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100d76:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PPN(pa) >= npage)
f0100d7d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d80:	3b 05 00 2a 11 f0    	cmp    0xf0112a00,%eax
f0100d86:	72 1c                	jb     f0100da4 <env_free+0x10c>
		panic("pa2page called with invalid pa");
f0100d88:	c7 44 24 08 90 25 10 	movl   $0xf0102590,0x8(%esp)
f0100d8f:	f0 
f0100d90:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0100d97:	00 
f0100d98:	c7 04 24 33 25 10 f0 	movl   $0xf0102533,(%esp)
f0100d9f:	e8 52 f3 ff ff       	call   f01000f6 <_panic>
	return &pages[PPN(pa)];
f0100da4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100da7:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100daa:	a1 0c 2a 11 f0       	mov    0xf0112a0c,%eax
f0100daf:	8d 04 90             	lea    (%eax,%edx,4),%eax
		page_decref(pa2page(pa));
f0100db2:	89 04 24             	mov    %eax,(%esp)
f0100db5:	e8 04 fd ff ff       	call   f0100abe <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0100dba:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0100dbe:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0100dc5:	0f 85 17 ff ff ff    	jne    f0100ce2 <env_free+0x4a>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = e->env_cr3;
f0100dcb:	8b 47 60             	mov    0x60(%edi),%eax
	e->env_pgdir = 0;
f0100dce:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	e->env_cr3 = 0;
f0100dd5:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PPN(pa) >= npage)
f0100ddc:	c1 e8 0c             	shr    $0xc,%eax
f0100ddf:	3b 05 00 2a 11 f0    	cmp    0xf0112a00,%eax
f0100de5:	72 1c                	jb     f0100e03 <env_free+0x16b>
		panic("pa2page called with invalid pa");
f0100de7:	c7 44 24 08 90 25 10 	movl   $0xf0102590,0x8(%esp)
f0100dee:	f0 
f0100def:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0100df6:	00 
f0100df7:	c7 04 24 33 25 10 f0 	movl   $0xf0102533,(%esp)
f0100dfe:	e8 f3 f2 ff ff       	call   f01000f6 <_panic>
	return &pages[PPN(pa)];
f0100e03:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100e06:	a1 0c 2a 11 f0       	mov    0xf0112a0c,%eax
f0100e0b:	8d 04 90             	lea    (%eax,%edx,4),%eax
	page_decref(pa2page(pa));
f0100e0e:	89 04 24             	mov    %eax,(%esp)
f0100e11:	e8 a8 fc ff ff       	call   f0100abe <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0100e16:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	LIST_INSERT_HEAD(&env_free_list, e, env_link);
f0100e1d:	a1 e0 25 11 f0       	mov    0xf01125e0,%eax
f0100e22:	89 47 44             	mov    %eax,0x44(%edi)
f0100e25:	85 c0                	test   %eax,%eax
f0100e27:	74 06                	je     f0100e2f <env_free+0x197>
f0100e29:	8d 57 44             	lea    0x44(%edi),%edx
f0100e2c:	89 50 48             	mov    %edx,0x48(%eax)
f0100e2f:	89 3d e0 25 11 f0    	mov    %edi,0xf01125e0
f0100e35:	c7 47 48 e0 25 11 f0 	movl   $0xf01125e0,0x48(%edi)
}
f0100e3c:	83 c4 2c             	add    $0x2c,%esp
f0100e3f:	5b                   	pop    %ebx
f0100e40:	5e                   	pop    %esi
f0100e41:	5f                   	pop    %edi
f0100e42:	5d                   	pop    %ebp
f0100e43:	c3                   	ret    

f0100e44 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e) 
{
f0100e44:	55                   	push   %ebp
f0100e45:	89 e5                	mov    %esp,%ebp
f0100e47:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f0100e4a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e4d:	89 04 24             	mov    %eax,(%esp)
f0100e50:	e8 43 fe ff ff       	call   f0100c98 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0100e55:	c7 04 24 b0 25 10 f0 	movl   $0xf01025b0,(%esp)
f0100e5c:	e8 d1 00 00 00       	call   f0100f32 <cprintf>
	while (1)
		monitor(NULL);
f0100e61:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100e68:	e8 9c f9 ff ff       	call   f0100809 <monitor>
f0100e6d:	eb f2                	jmp    f0100e61 <env_destroy+0x1d>

f0100e6f <env_pop_tf>:
// This exits the kernel and starts executing some environment's code.
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0100e6f:	55                   	push   %ebp
f0100e70:	89 e5                	mov    %esp,%ebp
f0100e72:	83 ec 18             	sub    $0x18,%esp
	__asm __volatile("movl %0,%%esp\n"
f0100e75:	8b 65 08             	mov    0x8(%ebp),%esp
f0100e78:	61                   	popa   
f0100e79:	07                   	pop    %es
f0100e7a:	1f                   	pop    %ds
f0100e7b:	83 c4 08             	add    $0x8,%esp
f0100e7e:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0100e7f:	c7 44 24 08 41 25 10 	movl   $0xf0102541,0x8(%esp)
f0100e86:	f0 
f0100e87:	c7 44 24 04 69 01 00 	movl   $0x169,0x4(%esp)
f0100e8e:	00 
f0100e8f:	c7 04 24 28 25 10 f0 	movl   $0xf0102528,(%esp)
f0100e96:	e8 5b f2 ff ff       	call   f01000f6 <_panic>

f0100e9b <env_run>:
// Note: if this is the first call to env_run, curenv is NULL.
//  (This function does not return.)
//
void
env_run(struct Env *e)
{
f0100e9b:	55                   	push   %ebp
f0100e9c:	89 e5                	mov    %esp,%ebp
f0100e9e:	83 ec 18             	sub    $0x18,%esp
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.
	
	// LAB 3: Your code here.

        panic("env_run not yet implemented");
f0100ea1:	c7 44 24 08 4d 25 10 	movl   $0xf010254d,0x8(%esp)
f0100ea8:	f0 
f0100ea9:	c7 44 24 04 83 01 00 	movl   $0x183,0x4(%esp)
f0100eb0:	00 
f0100eb1:	c7 04 24 28 25 10 f0 	movl   $0xf0102528,(%esp)
f0100eb8:	e8 39 f2 ff ff       	call   f01000f6 <_panic>
f0100ebd:	00 00                	add    %al,(%eax)
	...

f0100ec0 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0100ec0:	55                   	push   %ebp
f0100ec1:	89 e5                	mov    %esp,%ebp
void
mc146818_write(unsigned reg, unsigned datum)
{
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0100ec3:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100ec7:	ba 70 00 00 00       	mov    $0x70,%edx
f0100ecc:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100ecd:	b2 71                	mov    $0x71,%dl
f0100ecf:	ec                   	in     (%dx),%al

unsigned
mc146818_read(unsigned reg)
{
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0100ed0:	0f b6 c0             	movzbl %al,%eax
}
f0100ed3:	5d                   	pop    %ebp
f0100ed4:	c3                   	ret    

f0100ed5 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0100ed5:	55                   	push   %ebp
f0100ed6:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0100ed8:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100edc:	ba 70 00 00 00       	mov    $0x70,%edx
f0100ee1:	ee                   	out    %al,(%dx)
f0100ee2:	0f b6 45 0c          	movzbl 0xc(%ebp),%eax
f0100ee6:	b2 71                	mov    $0x71,%dl
f0100ee8:	ee                   	out    %al,(%dx)
f0100ee9:	5d                   	pop    %ebp
f0100eea:	c3                   	ret    
	...

f0100eec <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100eec:	55                   	push   %ebp
f0100eed:	89 e5                	mov    %esp,%ebp
f0100eef:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100ef2:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ef5:	89 04 24             	mov    %eax,(%esp)
f0100ef8:	e8 77 f7 ff ff       	call   f0100674 <cputchar>
	*cnt++;
}
f0100efd:	c9                   	leave  
f0100efe:	c3                   	ret    

f0100eff <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100eff:	55                   	push   %ebp
f0100f00:	89 e5                	mov    %esp,%ebp
f0100f02:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100f05:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100f0c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f0f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f13:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f16:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100f1a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100f1d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f21:	c7 04 24 ec 0e 10 f0 	movl   $0xf0100eec,(%esp)
f0100f28:	e8 8f 04 00 00       	call   f01013bc <vprintfmt>
	return cnt;
}
f0100f2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f30:	c9                   	leave  
f0100f31:	c3                   	ret    

f0100f32 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100f32:	55                   	push   %ebp
f0100f33:	89 e5                	mov    %esp,%ebp
f0100f35:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100f38:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100f3b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f3f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f42:	89 04 24             	mov    %eax,(%esp)
f0100f45:	e8 b5 ff ff ff       	call   f0100eff <vcprintf>
	va_end(ap);

	return cnt;
}
f0100f4a:	c9                   	leave  
f0100f4b:	c3                   	ret    
f0100f4c:	00 00                	add    %al,(%eax)
	...

f0100f50 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100f50:	55                   	push   %ebp
f0100f51:	89 e5                	mov    %esp,%ebp
f0100f53:	57                   	push   %edi
f0100f54:	56                   	push   %esi
f0100f55:	53                   	push   %ebx
f0100f56:	83 ec 10             	sub    $0x10,%esp
f0100f59:	89 c6                	mov    %eax,%esi
f0100f5b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100f5e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100f61:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100f64:	8b 1a                	mov    (%edx),%ebx
f0100f66:	8b 09                	mov    (%ecx),%ecx
f0100f68:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100f6b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0100f72:	eb 77                	jmp    f0100feb <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100f74:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f77:	01 d8                	add    %ebx,%eax
f0100f79:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100f7e:	99                   	cltd   
f0100f7f:	f7 f9                	idiv   %ecx
f0100f81:	89 c1                	mov    %eax,%ecx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100f83:	eb 01                	jmp    f0100f86 <stab_binsearch+0x36>
			m--;
f0100f85:	49                   	dec    %ecx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100f86:	39 d9                	cmp    %ebx,%ecx
f0100f88:	7c 1d                	jl     f0100fa7 <stab_binsearch+0x57>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100f8a:	6b d1 0c             	imul   $0xc,%ecx,%edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100f8d:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100f92:	39 fa                	cmp    %edi,%edx
f0100f94:	75 ef                	jne    f0100f85 <stab_binsearch+0x35>
f0100f96:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100f99:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100f9c:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100fa0:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100fa3:	73 18                	jae    f0100fbd <stab_binsearch+0x6d>
f0100fa5:	eb 05                	jmp    f0100fac <stab_binsearch+0x5c>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100fa7:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100faa:	eb 3f                	jmp    f0100feb <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100fac:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100faf:	89 0a                	mov    %ecx,(%edx)
			l = true_m + 1;
f0100fb1:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100fb4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100fbb:	eb 2e                	jmp    f0100feb <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100fbd:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100fc0:	73 15                	jae    f0100fd7 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100fc2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100fc5:	49                   	dec    %ecx
f0100fc6:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100fc9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100fcc:	89 08                	mov    %ecx,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100fce:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100fd5:	eb 14                	jmp    f0100feb <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100fd7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100fda:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100fdd:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f0100fdf:	ff 45 0c             	incl   0xc(%ebp)
f0100fe2:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100fe4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100feb:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100fee:	7e 84                	jle    f0100f74 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100ff0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100ff4:	75 0d                	jne    f0101003 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100ff6:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100ff9:	8b 02                	mov    (%edx),%eax
f0100ffb:	48                   	dec    %eax
f0100ffc:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100fff:	89 01                	mov    %eax,(%ecx)
f0101001:	eb 22                	jmp    f0101025 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101003:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101006:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0101008:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010100b:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010100d:	eb 01                	jmp    f0101010 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010100f:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101010:	39 c1                	cmp    %eax,%ecx
f0101012:	7d 0c                	jge    f0101020 <stab_binsearch+0xd0>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0101014:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0101017:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f010101c:	39 fa                	cmp    %edi,%edx
f010101e:	75 ef                	jne    f010100f <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0101020:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0101023:	89 02                	mov    %eax,(%edx)
	}
}
f0101025:	83 c4 10             	add    $0x10,%esp
f0101028:	5b                   	pop    %ebx
f0101029:	5e                   	pop    %esi
f010102a:	5f                   	pop    %edi
f010102b:	5d                   	pop    %ebp
f010102c:	c3                   	ret    

f010102d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010102d:	55                   	push   %ebp
f010102e:	89 e5                	mov    %esp,%ebp
f0101030:	83 ec 38             	sub    $0x38,%esp
f0101033:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0101036:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101039:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010103c:	8b 75 08             	mov    0x8(%ebp),%esi
f010103f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0101042:	c7 03 e8 25 10 f0    	movl   $0xf01025e8,(%ebx)
	info->eip_line = 0;
f0101048:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010104f:	c7 43 08 e8 25 10 f0 	movl   $0xf01025e8,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0101056:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010105d:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0101060:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0101067:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010106d:	76 12                	jbe    f0101081 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010106f:	b8 a5 96 10 f0       	mov    $0xf01096a5,%eax
f0101074:	3d 61 72 10 f0       	cmp    $0xf0107261,%eax
f0101079:	0f 86 5b 01 00 00    	jbe    f01011da <debuginfo_eip+0x1ad>
f010107f:	eb 1c                	jmp    f010109d <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0101081:	c7 44 24 08 f2 25 10 	movl   $0xf01025f2,0x8(%esp)
f0101088:	f0 
f0101089:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
f0101090:	00 
f0101091:	c7 04 24 ff 25 10 f0 	movl   $0xf01025ff,(%esp)
f0101098:	e8 59 f0 ff ff       	call   f01000f6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010109d:	80 3d a4 96 10 f0 00 	cmpb   $0x0,0xf01096a4
f01010a4:	0f 85 37 01 00 00    	jne    f01011e1 <debuginfo_eip+0x1b4>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01010aa:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01010b1:	b8 60 72 10 f0       	mov    $0xf0107260,%eax
f01010b6:	2d 20 28 10 f0       	sub    $0xf0102820,%eax
f01010bb:	c1 f8 02             	sar    $0x2,%eax
f01010be:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01010c4:	83 e8 01             	sub    $0x1,%eax
f01010c7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01010ca:	89 74 24 04          	mov    %esi,0x4(%esp)
f01010ce:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01010d5:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01010d8:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01010db:	b8 20 28 10 f0       	mov    $0xf0102820,%eax
f01010e0:	e8 6b fe ff ff       	call   f0100f50 <stab_binsearch>
	if (lfile == 0)
f01010e5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010e8:	85 c0                	test   %eax,%eax
f01010ea:	0f 84 f8 00 00 00    	je     f01011e8 <debuginfo_eip+0x1bb>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01010f0:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01010f3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010f6:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01010f9:	89 74 24 04          	mov    %esi,0x4(%esp)
f01010fd:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0101104:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0101107:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010110a:	b8 20 28 10 f0       	mov    $0xf0102820,%eax
f010110f:	e8 3c fe ff ff       	call   f0100f50 <stab_binsearch>

	if (lfun <= rfun) {
f0101114:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0101117:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f010111a:	7f 2e                	jg     f010114a <debuginfo_eip+0x11d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010111c:	6b c7 0c             	imul   $0xc,%edi,%eax
f010111f:	8d 90 20 28 10 f0    	lea    -0xfefd7e0(%eax),%edx
f0101125:	8b 80 20 28 10 f0    	mov    -0xfefd7e0(%eax),%eax
f010112b:	b9 a5 96 10 f0       	mov    $0xf01096a5,%ecx
f0101130:	81 e9 61 72 10 f0    	sub    $0xf0107261,%ecx
f0101136:	39 c8                	cmp    %ecx,%eax
f0101138:	73 08                	jae    f0101142 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010113a:	05 61 72 10 f0       	add    $0xf0107261,%eax
f010113f:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0101142:	8b 42 08             	mov    0x8(%edx),%eax
f0101145:	89 43 10             	mov    %eax,0x10(%ebx)
f0101148:	eb 06                	jmp    f0101150 <debuginfo_eip+0x123>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010114a:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010114d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0101150:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0101157:	00 
f0101158:	8b 43 08             	mov    0x8(%ebx),%eax
f010115b:	89 04 24             	mov    %eax,(%esp)
f010115e:	e8 0a 09 00 00       	call   f0101a6d <strfind>
f0101163:	2b 43 08             	sub    0x8(%ebx),%eax
f0101166:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101169:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010116c:	39 cf                	cmp    %ecx,%edi
f010116e:	7c 7f                	jl     f01011ef <debuginfo_eip+0x1c2>
	       && stabs[lline].n_type != N_SOL
f0101170:	6b f7 0c             	imul   $0xc,%edi,%esi
f0101173:	81 c6 20 28 10 f0    	add    $0xf0102820,%esi
f0101179:	0f b6 56 04          	movzbl 0x4(%esi),%edx
f010117d:	80 fa 84             	cmp    $0x84,%dl
f0101180:	74 31                	je     f01011b3 <debuginfo_eip+0x186>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0101182:	8d 47 ff             	lea    -0x1(%edi),%eax
f0101185:	6b c0 0c             	imul   $0xc,%eax,%eax
f0101188:	05 20 28 10 f0       	add    $0xf0102820,%eax
f010118d:	eb 15                	jmp    f01011a4 <debuginfo_eip+0x177>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f010118f:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101192:	39 cf                	cmp    %ecx,%edi
f0101194:	7c 60                	jl     f01011f6 <debuginfo_eip+0x1c9>
	       && stabs[lline].n_type != N_SOL
f0101196:	89 c6                	mov    %eax,%esi
f0101198:	83 e8 0c             	sub    $0xc,%eax
f010119b:	0f b6 50 10          	movzbl 0x10(%eax),%edx
f010119f:	80 fa 84             	cmp    $0x84,%dl
f01011a2:	74 0f                	je     f01011b3 <debuginfo_eip+0x186>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01011a4:	80 fa 64             	cmp    $0x64,%dl
f01011a7:	75 e6                	jne    f010118f <debuginfo_eip+0x162>
f01011a9:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f01011ad:	74 e0                	je     f010118f <debuginfo_eip+0x162>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01011af:	39 f9                	cmp    %edi,%ecx
f01011b1:	7f 4a                	jg     f01011fd <debuginfo_eip+0x1d0>
f01011b3:	6b ff 0c             	imul   $0xc,%edi,%edi
f01011b6:	8b 97 20 28 10 f0    	mov    -0xfefd7e0(%edi),%edx
f01011bc:	b9 a5 96 10 f0       	mov    $0xf01096a5,%ecx
f01011c1:	81 e9 61 72 10 f0    	sub    $0xf0107261,%ecx
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	// Your code here.

	
	return 0;
f01011c7:	b8 00 00 00 00       	mov    $0x0,%eax
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01011cc:	39 ca                	cmp    %ecx,%edx
f01011ce:	73 32                	jae    f0101202 <debuginfo_eip+0x1d5>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01011d0:	81 c2 61 72 10 f0    	add    $0xf0107261,%edx
f01011d6:	89 13                	mov    %edx,(%ebx)
f01011d8:	eb 28                	jmp    f0101202 <debuginfo_eip+0x1d5>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01011da:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01011df:	eb 21                	jmp    f0101202 <debuginfo_eip+0x1d5>
f01011e1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01011e6:	eb 1a                	jmp    f0101202 <debuginfo_eip+0x1d5>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01011e8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01011ed:	eb 13                	jmp    f0101202 <debuginfo_eip+0x1d5>
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	// Your code here.

	
	return 0;
f01011ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01011f4:	eb 0c                	jmp    f0101202 <debuginfo_eip+0x1d5>
f01011f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01011fb:	eb 05                	jmp    f0101202 <debuginfo_eip+0x1d5>
f01011fd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101202:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101205:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101208:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010120b:	89 ec                	mov    %ebp,%esp
f010120d:	5d                   	pop    %ebp
f010120e:	c3                   	ret    
	...

f0101210 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101210:	55                   	push   %ebp
f0101211:	89 e5                	mov    %esp,%ebp
f0101213:	57                   	push   %edi
f0101214:	56                   	push   %esi
f0101215:	53                   	push   %ebx
f0101216:	83 ec 4c             	sub    $0x4c,%esp
f0101219:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010121c:	89 d7                	mov    %edx,%edi
f010121e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101221:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0101224:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101227:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010122a:	b8 00 00 00 00       	mov    $0x0,%eax
f010122f:	39 d8                	cmp    %ebx,%eax
f0101231:	72 17                	jb     f010124a <printnum+0x3a>
f0101233:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0101236:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f0101239:	76 0f                	jbe    f010124a <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010123b:	8b 75 14             	mov    0x14(%ebp),%esi
f010123e:	83 ee 01             	sub    $0x1,%esi
f0101241:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101244:	85 f6                	test   %esi,%esi
f0101246:	7f 63                	jg     f01012ab <printnum+0x9b>
f0101248:	eb 75                	jmp    f01012bf <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010124a:	8b 5d 18             	mov    0x18(%ebp),%ebx
f010124d:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0101251:	8b 45 14             	mov    0x14(%ebp),%eax
f0101254:	83 e8 01             	sub    $0x1,%eax
f0101257:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010125b:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010125e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101262:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101266:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010126a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010126d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101270:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101277:	00 
f0101278:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f010127b:	89 1c 24             	mov    %ebx,(%esp)
f010127e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101281:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101285:	e8 16 0a 00 00       	call   f0101ca0 <__udivdi3>
f010128a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010128d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101290:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101294:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101298:	89 04 24             	mov    %eax,(%esp)
f010129b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010129f:	89 fa                	mov    %edi,%edx
f01012a1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012a4:	e8 67 ff ff ff       	call   f0101210 <printnum>
f01012a9:	eb 14                	jmp    f01012bf <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01012ab:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01012af:	8b 45 18             	mov    0x18(%ebp),%eax
f01012b2:	89 04 24             	mov    %eax,(%esp)
f01012b5:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01012b7:	83 ee 01             	sub    $0x1,%esi
f01012ba:	75 ef                	jne    f01012ab <printnum+0x9b>
f01012bc:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01012bf:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01012c3:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01012c7:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01012ca:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01012ce:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01012d5:	00 
f01012d6:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01012d9:	89 1c 24             	mov    %ebx,(%esp)
f01012dc:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01012df:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012e3:	e8 18 0b 00 00       	call   f0101e00 <__umoddi3>
f01012e8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01012ec:	0f be 80 0d 26 10 f0 	movsbl -0xfefd9f3(%eax),%eax
f01012f3:	89 04 24             	mov    %eax,(%esp)
f01012f6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012f9:	ff d0                	call   *%eax
}
f01012fb:	83 c4 4c             	add    $0x4c,%esp
f01012fe:	5b                   	pop    %ebx
f01012ff:	5e                   	pop    %esi
f0101300:	5f                   	pop    %edi
f0101301:	5d                   	pop    %ebp
f0101302:	c3                   	ret    

f0101303 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0101303:	55                   	push   %ebp
f0101304:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0101306:	83 fa 01             	cmp    $0x1,%edx
f0101309:	7e 0e                	jle    f0101319 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010130b:	8b 10                	mov    (%eax),%edx
f010130d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0101310:	89 08                	mov    %ecx,(%eax)
f0101312:	8b 02                	mov    (%edx),%eax
f0101314:	8b 52 04             	mov    0x4(%edx),%edx
f0101317:	eb 22                	jmp    f010133b <getuint+0x38>
	else if (lflag)
f0101319:	85 d2                	test   %edx,%edx
f010131b:	74 10                	je     f010132d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f010131d:	8b 10                	mov    (%eax),%edx
f010131f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101322:	89 08                	mov    %ecx,(%eax)
f0101324:	8b 02                	mov    (%edx),%eax
f0101326:	ba 00 00 00 00       	mov    $0x0,%edx
f010132b:	eb 0e                	jmp    f010133b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f010132d:	8b 10                	mov    (%eax),%edx
f010132f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101332:	89 08                	mov    %ecx,(%eax)
f0101334:	8b 02                	mov    (%edx),%eax
f0101336:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010133b:	5d                   	pop    %ebp
f010133c:	c3                   	ret    

f010133d <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f010133d:	55                   	push   %ebp
f010133e:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0101340:	83 fa 01             	cmp    $0x1,%edx
f0101343:	7e 0e                	jle    f0101353 <getint+0x16>
		return va_arg(*ap, long long);
f0101345:	8b 10                	mov    (%eax),%edx
f0101347:	8d 4a 08             	lea    0x8(%edx),%ecx
f010134a:	89 08                	mov    %ecx,(%eax)
f010134c:	8b 02                	mov    (%edx),%eax
f010134e:	8b 52 04             	mov    0x4(%edx),%edx
f0101351:	eb 22                	jmp    f0101375 <getint+0x38>
	else if (lflag)
f0101353:	85 d2                	test   %edx,%edx
f0101355:	74 10                	je     f0101367 <getint+0x2a>
		return va_arg(*ap, long);
f0101357:	8b 10                	mov    (%eax),%edx
f0101359:	8d 4a 04             	lea    0x4(%edx),%ecx
f010135c:	89 08                	mov    %ecx,(%eax)
f010135e:	8b 02                	mov    (%edx),%eax
f0101360:	89 c2                	mov    %eax,%edx
f0101362:	c1 fa 1f             	sar    $0x1f,%edx
f0101365:	eb 0e                	jmp    f0101375 <getint+0x38>
	else
		return va_arg(*ap, int);
f0101367:	8b 10                	mov    (%eax),%edx
f0101369:	8d 4a 04             	lea    0x4(%edx),%ecx
f010136c:	89 08                	mov    %ecx,(%eax)
f010136e:	8b 02                	mov    (%edx),%eax
f0101370:	89 c2                	mov    %eax,%edx
f0101372:	c1 fa 1f             	sar    $0x1f,%edx
}
f0101375:	5d                   	pop    %ebp
f0101376:	c3                   	ret    

f0101377 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101377:	55                   	push   %ebp
f0101378:	89 e5                	mov    %esp,%ebp
f010137a:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010137d:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101381:	8b 10                	mov    (%eax),%edx
f0101383:	3b 50 04             	cmp    0x4(%eax),%edx
f0101386:	73 0a                	jae    f0101392 <sprintputch+0x1b>
		*b->buf++ = ch;
f0101388:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010138b:	88 0a                	mov    %cl,(%edx)
f010138d:	83 c2 01             	add    $0x1,%edx
f0101390:	89 10                	mov    %edx,(%eax)
}
f0101392:	5d                   	pop    %ebp
f0101393:	c3                   	ret    

f0101394 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101394:	55                   	push   %ebp
f0101395:	89 e5                	mov    %esp,%ebp
f0101397:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010139a:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010139d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01013a1:	8b 45 10             	mov    0x10(%ebp),%eax
f01013a4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01013a8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013ab:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013af:	8b 45 08             	mov    0x8(%ebp),%eax
f01013b2:	89 04 24             	mov    %eax,(%esp)
f01013b5:	e8 02 00 00 00       	call   f01013bc <vprintfmt>
	va_end(ap);
}
f01013ba:	c9                   	leave  
f01013bb:	c3                   	ret    

f01013bc <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01013bc:	55                   	push   %ebp
f01013bd:	89 e5                	mov    %esp,%ebp
f01013bf:	57                   	push   %edi
f01013c0:	56                   	push   %esi
f01013c1:	53                   	push   %ebx
f01013c2:	83 ec 4c             	sub    $0x4c,%esp
f01013c5:	8b 75 08             	mov    0x8(%ebp),%esi
f01013c8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01013cb:	8b 7d 10             	mov    0x10(%ebp),%edi
f01013ce:	eb 11                	jmp    f01013e1 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01013d0:	85 c0                	test   %eax,%eax
f01013d2:	0f 84 93 03 00 00    	je     f010176b <vprintfmt+0x3af>
				return;
			putch(ch, putdat);
f01013d8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01013dc:	89 04 24             	mov    %eax,(%esp)
f01013df:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01013e1:	0f b6 07             	movzbl (%edi),%eax
f01013e4:	83 c7 01             	add    $0x1,%edi
f01013e7:	83 f8 25             	cmp    $0x25,%eax
f01013ea:	75 e4                	jne    f01013d0 <vprintfmt+0x14>
f01013ec:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f01013f0:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f01013f7:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f01013fe:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0101405:	ba 00 00 00 00       	mov    $0x0,%edx
f010140a:	eb 2b                	jmp    f0101437 <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010140c:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f010140f:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f0101413:	eb 22                	jmp    f0101437 <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101415:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101418:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f010141c:	eb 19                	jmp    f0101437 <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010141e:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0101421:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0101428:	eb 0d                	jmp    f0101437 <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010142a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010142d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101430:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101437:	0f b6 0f             	movzbl (%edi),%ecx
f010143a:	8d 47 01             	lea    0x1(%edi),%eax
f010143d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101440:	0f b6 07             	movzbl (%edi),%eax
f0101443:	83 e8 23             	sub    $0x23,%eax
f0101446:	3c 55                	cmp    $0x55,%al
f0101448:	0f 87 f8 02 00 00    	ja     f0101746 <vprintfmt+0x38a>
f010144e:	0f b6 c0             	movzbl %al,%eax
f0101451:	ff 24 85 9c 26 10 f0 	jmp    *-0xfefd964(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0101458:	83 e9 30             	sub    $0x30,%ecx
f010145b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
f010145e:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
f0101462:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0101465:	83 f9 09             	cmp    $0x9,%ecx
f0101468:	77 57                	ja     f01014c1 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010146a:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010146d:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101470:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101473:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0101476:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0101479:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f010147d:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0101480:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0101483:	83 f9 09             	cmp    $0x9,%ecx
f0101486:	76 eb                	jbe    f0101473 <vprintfmt+0xb7>
f0101488:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010148b:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010148e:	eb 34                	jmp    f01014c4 <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101490:	8b 45 14             	mov    0x14(%ebp),%eax
f0101493:	8d 48 04             	lea    0x4(%eax),%ecx
f0101496:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0101499:	8b 00                	mov    (%eax),%eax
f010149b:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010149e:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01014a1:	eb 21                	jmp    f01014c4 <vprintfmt+0x108>

		case '.':
			if (width < 0)
f01014a3:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01014a7:	0f 88 71 ff ff ff    	js     f010141e <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01014ad:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01014b0:	eb 85                	jmp    f0101437 <vprintfmt+0x7b>
f01014b2:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01014b5:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f01014bc:	e9 76 ff ff ff       	jmp    f0101437 <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01014c1:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f01014c4:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01014c8:	0f 89 69 ff ff ff    	jns    f0101437 <vprintfmt+0x7b>
f01014ce:	e9 57 ff ff ff       	jmp    f010142a <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01014d3:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01014d6:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01014d9:	e9 59 ff ff ff       	jmp    f0101437 <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01014de:	8b 45 14             	mov    0x14(%ebp),%eax
f01014e1:	8d 50 04             	lea    0x4(%eax),%edx
f01014e4:	89 55 14             	mov    %edx,0x14(%ebp)
f01014e7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01014eb:	8b 00                	mov    (%eax),%eax
f01014ed:	89 04 24             	mov    %eax,(%esp)
f01014f0:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01014f2:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01014f5:	e9 e7 fe ff ff       	jmp    f01013e1 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01014fa:	8b 45 14             	mov    0x14(%ebp),%eax
f01014fd:	8d 50 04             	lea    0x4(%eax),%edx
f0101500:	89 55 14             	mov    %edx,0x14(%ebp)
f0101503:	8b 00                	mov    (%eax),%eax
f0101505:	89 c2                	mov    %eax,%edx
f0101507:	c1 fa 1f             	sar    $0x1f,%edx
f010150a:	31 d0                	xor    %edx,%eax
f010150c:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
f010150e:	83 f8 06             	cmp    $0x6,%eax
f0101511:	7f 0b                	jg     f010151e <vprintfmt+0x162>
f0101513:	8b 14 85 f4 27 10 f0 	mov    -0xfefd80c(,%eax,4),%edx
f010151a:	85 d2                	test   %edx,%edx
f010151c:	75 20                	jne    f010153e <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
f010151e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101522:	c7 44 24 08 25 26 10 	movl   $0xf0102625,0x8(%esp)
f0101529:	f0 
f010152a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010152e:	89 34 24             	mov    %esi,(%esp)
f0101531:	e8 5e fe ff ff       	call   f0101394 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101536:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0101539:	e9 a3 fe ff ff       	jmp    f01013e1 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010153e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101542:	c7 44 24 08 2e 26 10 	movl   $0xf010262e,0x8(%esp)
f0101549:	f0 
f010154a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010154e:	89 34 24             	mov    %esi,(%esp)
f0101551:	e8 3e fe ff ff       	call   f0101394 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101556:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101559:	e9 83 fe ff ff       	jmp    f01013e1 <vprintfmt+0x25>
f010155e:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101561:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0101564:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101567:	8b 45 14             	mov    0x14(%ebp),%eax
f010156a:	8d 50 04             	lea    0x4(%eax),%edx
f010156d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101570:	8b 38                	mov    (%eax),%edi
f0101572:	85 ff                	test   %edi,%edi
f0101574:	75 05                	jne    f010157b <vprintfmt+0x1bf>
				p = "(null)";
f0101576:	bf 1e 26 10 f0       	mov    $0xf010261e,%edi
			if (width > 0 && padc != '-')
f010157b:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f010157f:	74 06                	je     f0101587 <vprintfmt+0x1cb>
f0101581:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0101585:	7f 16                	jg     f010159d <vprintfmt+0x1e1>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101587:	0f b6 17             	movzbl (%edi),%edx
f010158a:	0f be c2             	movsbl %dl,%eax
f010158d:	83 c7 01             	add    $0x1,%edi
f0101590:	85 c0                	test   %eax,%eax
f0101592:	0f 85 9f 00 00 00    	jne    f0101637 <vprintfmt+0x27b>
f0101598:	e9 8b 00 00 00       	jmp    f0101628 <vprintfmt+0x26c>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010159d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01015a1:	89 3c 24             	mov    %edi,(%esp)
f01015a4:	e8 39 03 00 00       	call   f01018e2 <strnlen>
f01015a9:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01015ac:	29 c2                	sub    %eax,%edx
f01015ae:	89 55 d8             	mov    %edx,-0x28(%ebp)
f01015b1:	85 d2                	test   %edx,%edx
f01015b3:	7e d2                	jle    f0101587 <vprintfmt+0x1cb>
					putch(padc, putdat);
f01015b5:	0f be 45 e4          	movsbl -0x1c(%ebp),%eax
f01015b9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01015bc:	89 7d cc             	mov    %edi,-0x34(%ebp)
f01015bf:	89 d7                	mov    %edx,%edi
f01015c1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01015c5:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01015c8:	89 14 24             	mov    %edx,(%esp)
f01015cb:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01015cd:	83 ef 01             	sub    $0x1,%edi
f01015d0:	75 ef                	jne    f01015c1 <vprintfmt+0x205>
f01015d2:	89 7d d8             	mov    %edi,-0x28(%ebp)
f01015d5:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01015d8:	eb ad                	jmp    f0101587 <vprintfmt+0x1cb>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01015da:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01015de:	74 20                	je     f0101600 <vprintfmt+0x244>
f01015e0:	0f be d2             	movsbl %dl,%edx
f01015e3:	83 ea 20             	sub    $0x20,%edx
f01015e6:	83 fa 5e             	cmp    $0x5e,%edx
f01015e9:	76 15                	jbe    f0101600 <vprintfmt+0x244>
					putch('?', putdat);
f01015eb:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01015ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015f2:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01015f9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01015fc:	ff d2                	call   *%edx
f01015fe:	eb 0f                	jmp    f010160f <vprintfmt+0x253>
				else
					putch(ch, putdat);
f0101600:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101603:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101607:	89 04 24             	mov    %eax,(%esp)
f010160a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010160d:	ff d0                	call   *%eax
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010160f:	83 eb 01             	sub    $0x1,%ebx
f0101612:	0f b6 17             	movzbl (%edi),%edx
f0101615:	0f be c2             	movsbl %dl,%eax
f0101618:	83 c7 01             	add    $0x1,%edi
f010161b:	85 c0                	test   %eax,%eax
f010161d:	75 24                	jne    f0101643 <vprintfmt+0x287>
f010161f:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0101622:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101625:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101628:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010162b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010162f:	0f 8e ac fd ff ff    	jle    f01013e1 <vprintfmt+0x25>
f0101635:	eb 20                	jmp    f0101657 <vprintfmt+0x29b>
f0101637:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f010163a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010163d:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0101640:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101643:	85 f6                	test   %esi,%esi
f0101645:	78 93                	js     f01015da <vprintfmt+0x21e>
f0101647:	83 ee 01             	sub    $0x1,%esi
f010164a:	79 8e                	jns    f01015da <vprintfmt+0x21e>
f010164c:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f010164f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101652:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101655:	eb d1                	jmp    f0101628 <vprintfmt+0x26c>
f0101657:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010165a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010165e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101665:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101667:	83 ef 01             	sub    $0x1,%edi
f010166a:	75 ee                	jne    f010165a <vprintfmt+0x29e>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010166c:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010166f:	e9 6d fd ff ff       	jmp    f01013e1 <vprintfmt+0x25>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101674:	8d 45 14             	lea    0x14(%ebp),%eax
f0101677:	e8 c1 fc ff ff       	call   f010133d <getint>
f010167c:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010167f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101682:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101687:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f010168b:	79 7d                	jns    f010170a <vprintfmt+0x34e>
				putch('-', putdat);
f010168d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101691:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101698:	ff d6                	call   *%esi
				num = -(long long) num;
f010169a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010169d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01016a0:	f7 d8                	neg    %eax
f01016a2:	83 d2 00             	adc    $0x0,%edx
f01016a5:	f7 da                	neg    %edx
			}
			base = 10;
f01016a7:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01016ac:	eb 5c                	jmp    f010170a <vprintfmt+0x34e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01016ae:	8d 45 14             	lea    0x14(%ebp),%eax
f01016b1:	e8 4d fc ff ff       	call   f0101303 <getuint>
			base = 10;
f01016b6:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01016bb:	eb 4d                	jmp    f010170a <vprintfmt+0x34e>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap, lflag);
f01016bd:	8d 45 14             	lea    0x14(%ebp),%eax
f01016c0:	e8 78 fc ff ff       	call   f010133d <getint>
			base = 8;
f01016c5:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01016ca:	eb 3e                	jmp    f010170a <vprintfmt+0x34e>
			// pointer
		case 'p':
			putch('0', putdat);
f01016cc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01016d0:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01016d7:	ff d6                	call   *%esi
			putch('x', putdat);
f01016d9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01016dd:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01016e4:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01016e6:	8b 45 14             	mov    0x14(%ebp),%eax
f01016e9:	8d 50 04             	lea    0x4(%eax),%edx
f01016ec:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
			// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01016ef:	8b 00                	mov    (%eax),%eax
f01016f1:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01016f6:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01016fb:	eb 0d                	jmp    f010170a <vprintfmt+0x34e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01016fd:	8d 45 14             	lea    0x14(%ebp),%eax
f0101700:	e8 fe fb ff ff       	call   f0101303 <getuint>
			base = 16;
f0101705:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f010170a:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f010170e:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0101712:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0101715:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101719:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010171d:	89 04 24             	mov    %eax,(%esp)
f0101720:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101724:	89 da                	mov    %ebx,%edx
f0101726:	89 f0                	mov    %esi,%eax
f0101728:	e8 e3 fa ff ff       	call   f0101210 <printnum>
			break;
f010172d:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101730:	e9 ac fc ff ff       	jmp    f01013e1 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101735:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101739:	89 0c 24             	mov    %ecx,(%esp)
f010173c:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010173e:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101741:	e9 9b fc ff ff       	jmp    f01013e1 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101746:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010174a:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101751:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101753:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101757:	0f 84 84 fc ff ff    	je     f01013e1 <vprintfmt+0x25>
f010175d:	83 ef 01             	sub    $0x1,%edi
f0101760:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101764:	75 f7                	jne    f010175d <vprintfmt+0x3a1>
f0101766:	e9 76 fc ff ff       	jmp    f01013e1 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010176b:	83 c4 4c             	add    $0x4c,%esp
f010176e:	5b                   	pop    %ebx
f010176f:	5e                   	pop    %esi
f0101770:	5f                   	pop    %edi
f0101771:	5d                   	pop    %ebp
f0101772:	c3                   	ret    

f0101773 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101773:	55                   	push   %ebp
f0101774:	89 e5                	mov    %esp,%ebp
f0101776:	83 ec 28             	sub    $0x28,%esp
f0101779:	8b 45 08             	mov    0x8(%ebp),%eax
f010177c:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010177f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101782:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101786:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101789:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101790:	85 d2                	test   %edx,%edx
f0101792:	7e 30                	jle    f01017c4 <vsnprintf+0x51>
f0101794:	85 c0                	test   %eax,%eax
f0101796:	74 2c                	je     f01017c4 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101798:	8b 45 14             	mov    0x14(%ebp),%eax
f010179b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010179f:	8b 45 10             	mov    0x10(%ebp),%eax
f01017a2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01017a6:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01017a9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01017ad:	c7 04 24 77 13 10 f0 	movl   $0xf0101377,(%esp)
f01017b4:	e8 03 fc ff ff       	call   f01013bc <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01017b9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01017bc:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01017bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01017c2:	eb 05                	jmp    f01017c9 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01017c4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01017c9:	c9                   	leave  
f01017ca:	c3                   	ret    

f01017cb <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01017cb:	55                   	push   %ebp
f01017cc:	89 e5                	mov    %esp,%ebp
f01017ce:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01017d1:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01017d4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01017d8:	8b 45 10             	mov    0x10(%ebp),%eax
f01017db:	89 44 24 08          	mov    %eax,0x8(%esp)
f01017df:	8b 45 0c             	mov    0xc(%ebp),%eax
f01017e2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01017e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01017e9:	89 04 24             	mov    %eax,(%esp)
f01017ec:	e8 82 ff ff ff       	call   f0101773 <vsnprintf>
	va_end(ap);

	return rc;
}
f01017f1:	c9                   	leave  
f01017f2:	c3                   	ret    
	...

f0101800 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101800:	55                   	push   %ebp
f0101801:	89 e5                	mov    %esp,%ebp
f0101803:	57                   	push   %edi
f0101804:	56                   	push   %esi
f0101805:	53                   	push   %ebx
f0101806:	83 ec 1c             	sub    $0x1c,%esp
f0101809:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010180c:	85 c0                	test   %eax,%eax
f010180e:	74 10                	je     f0101820 <readline+0x20>
		cprintf("%s", prompt);
f0101810:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101814:	c7 04 24 2e 26 10 f0 	movl   $0xf010262e,(%esp)
f010181b:	e8 12 f7 ff ff       	call   f0100f32 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101820:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101827:	e8 6c ee ff ff       	call   f0100698 <iscons>
f010182c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010182e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101833:	e8 4f ee ff ff       	call   f0100687 <getchar>
f0101838:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010183a:	85 c0                	test   %eax,%eax
f010183c:	79 17                	jns    f0101855 <readline+0x55>
			cprintf("read error: %e\n", c);
f010183e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101842:	c7 04 24 10 28 10 f0 	movl   $0xf0102810,(%esp)
f0101849:	e8 e4 f6 ff ff       	call   f0100f32 <cprintf>
			return NULL;
f010184e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101853:	eb 61                	jmp    f01018b6 <readline+0xb6>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101855:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010185b:	7f 1c                	jg     f0101879 <readline+0x79>
f010185d:	83 f8 1f             	cmp    $0x1f,%eax
f0101860:	7e 17                	jle    f0101879 <readline+0x79>
			if (echoing)
f0101862:	85 ff                	test   %edi,%edi
f0101864:	74 08                	je     f010186e <readline+0x6e>
				cputchar(c);
f0101866:	89 04 24             	mov    %eax,(%esp)
f0101869:	e8 06 ee ff ff       	call   f0100674 <cputchar>
			buf[i++] = c;
f010186e:	88 9e 00 26 11 f0    	mov    %bl,-0xfeeda00(%esi)
f0101874:	83 c6 01             	add    $0x1,%esi
f0101877:	eb ba                	jmp    f0101833 <readline+0x33>
		} else if (c == '\b' && i > 0) {
f0101879:	85 f6                	test   %esi,%esi
f010187b:	7e 16                	jle    f0101893 <readline+0x93>
f010187d:	83 fb 08             	cmp    $0x8,%ebx
f0101880:	75 11                	jne    f0101893 <readline+0x93>
			if (echoing)
f0101882:	85 ff                	test   %edi,%edi
f0101884:	74 08                	je     f010188e <readline+0x8e>
				cputchar(c);
f0101886:	89 1c 24             	mov    %ebx,(%esp)
f0101889:	e8 e6 ed ff ff       	call   f0100674 <cputchar>
			i--;
f010188e:	83 ee 01             	sub    $0x1,%esi
f0101891:	eb a0                	jmp    f0101833 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0101893:	83 fb 0d             	cmp    $0xd,%ebx
f0101896:	74 05                	je     f010189d <readline+0x9d>
f0101898:	83 fb 0a             	cmp    $0xa,%ebx
f010189b:	75 96                	jne    f0101833 <readline+0x33>
			if (echoing)
f010189d:	85 ff                	test   %edi,%edi
f010189f:	90                   	nop
f01018a0:	74 08                	je     f01018aa <readline+0xaa>
				cputchar(c);
f01018a2:	89 1c 24             	mov    %ebx,(%esp)
f01018a5:	e8 ca ed ff ff       	call   f0100674 <cputchar>
			buf[i] = 0;
f01018aa:	c6 86 00 26 11 f0 00 	movb   $0x0,-0xfeeda00(%esi)
			return buf;
f01018b1:	b8 00 26 11 f0       	mov    $0xf0112600,%eax
		}
	}
}
f01018b6:	83 c4 1c             	add    $0x1c,%esp
f01018b9:	5b                   	pop    %ebx
f01018ba:	5e                   	pop    %esi
f01018bb:	5f                   	pop    %edi
f01018bc:	5d                   	pop    %ebp
f01018bd:	c3                   	ret    
	...

f01018c0 <strlen>:

#include <inc/string.h>

int
strlen(const char *s)
{
f01018c0:	55                   	push   %ebp
f01018c1:	89 e5                	mov    %esp,%ebp
f01018c3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01018c6:	80 3a 00             	cmpb   $0x0,(%edx)
f01018c9:	74 10                	je     f01018db <strlen+0x1b>
f01018cb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01018d0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01018d3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01018d7:	75 f7                	jne    f01018d0 <strlen+0x10>
f01018d9:	eb 05                	jmp    f01018e0 <strlen+0x20>
f01018db:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01018e0:	5d                   	pop    %ebp
f01018e1:	c3                   	ret    

f01018e2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01018e2:	55                   	push   %ebp
f01018e3:	89 e5                	mov    %esp,%ebp
f01018e5:	53                   	push   %ebx
f01018e6:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01018e9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01018ec:	85 c9                	test   %ecx,%ecx
f01018ee:	74 1c                	je     f010190c <strnlen+0x2a>
f01018f0:	80 3b 00             	cmpb   $0x0,(%ebx)
f01018f3:	74 1e                	je     f0101913 <strnlen+0x31>
f01018f5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01018fa:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01018fc:	39 ca                	cmp    %ecx,%edx
f01018fe:	74 18                	je     f0101918 <strnlen+0x36>
f0101900:	83 c2 01             	add    $0x1,%edx
f0101903:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101908:	75 f0                	jne    f01018fa <strnlen+0x18>
f010190a:	eb 0c                	jmp    f0101918 <strnlen+0x36>
f010190c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101911:	eb 05                	jmp    f0101918 <strnlen+0x36>
f0101913:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101918:	5b                   	pop    %ebx
f0101919:	5d                   	pop    %ebp
f010191a:	c3                   	ret    

f010191b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010191b:	55                   	push   %ebp
f010191c:	89 e5                	mov    %esp,%ebp
f010191e:	53                   	push   %ebx
f010191f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101922:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101925:	89 c2                	mov    %eax,%edx
f0101927:	0f b6 19             	movzbl (%ecx),%ebx
f010192a:	88 1a                	mov    %bl,(%edx)
f010192c:	83 c2 01             	add    $0x1,%edx
f010192f:	83 c1 01             	add    $0x1,%ecx
f0101932:	84 db                	test   %bl,%bl
f0101934:	75 f1                	jne    f0101927 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101936:	5b                   	pop    %ebx
f0101937:	5d                   	pop    %ebp
f0101938:	c3                   	ret    

f0101939 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101939:	55                   	push   %ebp
f010193a:	89 e5                	mov    %esp,%ebp
f010193c:	56                   	push   %esi
f010193d:	53                   	push   %ebx
f010193e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101941:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101944:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101947:	85 db                	test   %ebx,%ebx
f0101949:	74 16                	je     f0101961 <strncpy+0x28>
		/* do nothing */;
	return ret;
}

char *
strncpy(char *dst, const char *src, size_t size) {
f010194b:	01 f3                	add    %esi,%ebx
f010194d:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
f010194f:	0f b6 02             	movzbl (%edx),%eax
f0101952:	88 01                	mov    %al,(%ecx)
f0101954:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101957:	80 3a 01             	cmpb   $0x1,(%edx)
f010195a:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010195d:	39 d9                	cmp    %ebx,%ecx
f010195f:	75 ee                	jne    f010194f <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101961:	89 f0                	mov    %esi,%eax
f0101963:	5b                   	pop    %ebx
f0101964:	5e                   	pop    %esi
f0101965:	5d                   	pop    %ebp
f0101966:	c3                   	ret    

f0101967 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101967:	55                   	push   %ebp
f0101968:	89 e5                	mov    %esp,%ebp
f010196a:	57                   	push   %edi
f010196b:	56                   	push   %esi
f010196c:	53                   	push   %ebx
f010196d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101970:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101973:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101976:	89 f8                	mov    %edi,%eax
f0101978:	85 f6                	test   %esi,%esi
f010197a:	74 33                	je     f01019af <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
f010197c:	83 fe 01             	cmp    $0x1,%esi
f010197f:	74 25                	je     f01019a6 <strlcpy+0x3f>
f0101981:	0f b6 0b             	movzbl (%ebx),%ecx
f0101984:	84 c9                	test   %cl,%cl
f0101986:	74 22                	je     f01019aa <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0101988:	83 ee 02             	sub    $0x2,%esi
f010198b:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101990:	88 08                	mov    %cl,(%eax)
f0101992:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101995:	39 f2                	cmp    %esi,%edx
f0101997:	74 13                	je     f01019ac <strlcpy+0x45>
f0101999:	83 c2 01             	add    $0x1,%edx
f010199c:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01019a0:	84 c9                	test   %cl,%cl
f01019a2:	75 ec                	jne    f0101990 <strlcpy+0x29>
f01019a4:	eb 06                	jmp    f01019ac <strlcpy+0x45>
f01019a6:	89 f8                	mov    %edi,%eax
f01019a8:	eb 02                	jmp    f01019ac <strlcpy+0x45>
f01019aa:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f01019ac:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01019af:	29 f8                	sub    %edi,%eax
}
f01019b1:	5b                   	pop    %ebx
f01019b2:	5e                   	pop    %esi
f01019b3:	5f                   	pop    %edi
f01019b4:	5d                   	pop    %ebp
f01019b5:	c3                   	ret    

f01019b6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01019b6:	55                   	push   %ebp
f01019b7:	89 e5                	mov    %esp,%ebp
f01019b9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01019bc:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01019bf:	0f b6 01             	movzbl (%ecx),%eax
f01019c2:	84 c0                	test   %al,%al
f01019c4:	74 15                	je     f01019db <strcmp+0x25>
f01019c6:	3a 02                	cmp    (%edx),%al
f01019c8:	75 11                	jne    f01019db <strcmp+0x25>
		p++, q++;
f01019ca:	83 c1 01             	add    $0x1,%ecx
f01019cd:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01019d0:	0f b6 01             	movzbl (%ecx),%eax
f01019d3:	84 c0                	test   %al,%al
f01019d5:	74 04                	je     f01019db <strcmp+0x25>
f01019d7:	3a 02                	cmp    (%edx),%al
f01019d9:	74 ef                	je     f01019ca <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01019db:	0f b6 c0             	movzbl %al,%eax
f01019de:	0f b6 12             	movzbl (%edx),%edx
f01019e1:	29 d0                	sub    %edx,%eax
}
f01019e3:	5d                   	pop    %ebp
f01019e4:	c3                   	ret    

f01019e5 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01019e5:	55                   	push   %ebp
f01019e6:	89 e5                	mov    %esp,%ebp
f01019e8:	56                   	push   %esi
f01019e9:	53                   	push   %ebx
f01019ea:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01019ed:	8b 55 0c             	mov    0xc(%ebp),%edx
f01019f0:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f01019f3:	85 f6                	test   %esi,%esi
f01019f5:	74 29                	je     f0101a20 <strncmp+0x3b>
f01019f7:	0f b6 03             	movzbl (%ebx),%eax
f01019fa:	84 c0                	test   %al,%al
f01019fc:	74 30                	je     f0101a2e <strncmp+0x49>
f01019fe:	3a 02                	cmp    (%edx),%al
f0101a00:	75 2c                	jne    f0101a2e <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
f0101a02:	8d 43 01             	lea    0x1(%ebx),%eax
f0101a05:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
f0101a07:	89 c3                	mov    %eax,%ebx
f0101a09:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101a0c:	39 f0                	cmp    %esi,%eax
f0101a0e:	74 17                	je     f0101a27 <strncmp+0x42>
f0101a10:	0f b6 08             	movzbl (%eax),%ecx
f0101a13:	84 c9                	test   %cl,%cl
f0101a15:	74 17                	je     f0101a2e <strncmp+0x49>
f0101a17:	83 c0 01             	add    $0x1,%eax
f0101a1a:	3a 0a                	cmp    (%edx),%cl
f0101a1c:	74 e9                	je     f0101a07 <strncmp+0x22>
f0101a1e:	eb 0e                	jmp    f0101a2e <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101a20:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a25:	eb 0f                	jmp    f0101a36 <strncmp+0x51>
f0101a27:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a2c:	eb 08                	jmp    f0101a36 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101a2e:	0f b6 03             	movzbl (%ebx),%eax
f0101a31:	0f b6 12             	movzbl (%edx),%edx
f0101a34:	29 d0                	sub    %edx,%eax
}
f0101a36:	5b                   	pop    %ebx
f0101a37:	5e                   	pop    %esi
f0101a38:	5d                   	pop    %ebp
f0101a39:	c3                   	ret    

f0101a3a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101a3a:	55                   	push   %ebp
f0101a3b:	89 e5                	mov    %esp,%ebp
f0101a3d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a40:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101a44:	0f b6 10             	movzbl (%eax),%edx
f0101a47:	84 d2                	test   %dl,%dl
f0101a49:	74 1b                	je     f0101a66 <strchr+0x2c>
		if (*s == c)
f0101a4b:	38 ca                	cmp    %cl,%dl
f0101a4d:	75 06                	jne    f0101a55 <strchr+0x1b>
f0101a4f:	eb 1a                	jmp    f0101a6b <strchr+0x31>
f0101a51:	38 ca                	cmp    %cl,%dl
f0101a53:	74 16                	je     f0101a6b <strchr+0x31>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101a55:	83 c0 01             	add    $0x1,%eax
f0101a58:	0f b6 10             	movzbl (%eax),%edx
f0101a5b:	84 d2                	test   %dl,%dl
f0101a5d:	75 f2                	jne    f0101a51 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f0101a5f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a64:	eb 05                	jmp    f0101a6b <strchr+0x31>
f0101a66:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101a6b:	5d                   	pop    %ebp
f0101a6c:	c3                   	ret    

f0101a6d <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101a6d:	55                   	push   %ebp
f0101a6e:	89 e5                	mov    %esp,%ebp
f0101a70:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a73:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101a77:	0f b6 10             	movzbl (%eax),%edx
f0101a7a:	84 d2                	test   %dl,%dl
f0101a7c:	74 14                	je     f0101a92 <strfind+0x25>
		if (*s == c)
f0101a7e:	38 ca                	cmp    %cl,%dl
f0101a80:	75 06                	jne    f0101a88 <strfind+0x1b>
f0101a82:	eb 0e                	jmp    f0101a92 <strfind+0x25>
f0101a84:	38 ca                	cmp    %cl,%dl
f0101a86:	74 0a                	je     f0101a92 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101a88:	83 c0 01             	add    $0x1,%eax
f0101a8b:	0f b6 10             	movzbl (%eax),%edx
f0101a8e:	84 d2                	test   %dl,%dl
f0101a90:	75 f2                	jne    f0101a84 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0101a92:	5d                   	pop    %ebp
f0101a93:	c3                   	ret    

f0101a94 <memset>:


void *
memset(void *v, int c, size_t n)
{
f0101a94:	55                   	push   %ebp
f0101a95:	89 e5                	mov    %esp,%ebp
f0101a97:	53                   	push   %ebx
f0101a98:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a9b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101a9e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f0101aa1:	89 da                	mov    %ebx,%edx
f0101aa3:	83 ea 01             	sub    $0x1,%edx
f0101aa6:	78 0d                	js     f0101ab5 <memset+0x21>
	return (char *) s;
}


void *
memset(void *v, int c, size_t n)
f0101aa8:	01 c3                	add    %eax,%ebx
{
	char *p;
	int m;

	p = v;
f0101aaa:	89 c2                	mov    %eax,%edx
	m = n;
	while (--m >= 0)
		*p++ = c;
f0101aac:	88 0a                	mov    %cl,(%edx)
f0101aae:	83 c2 01             	add    $0x1,%edx
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f0101ab1:	39 da                	cmp    %ebx,%edx
f0101ab3:	75 f7                	jne    f0101aac <memset+0x18>
		*p++ = c;

	return v;
}
f0101ab5:	5b                   	pop    %ebx
f0101ab6:	5d                   	pop    %ebp
f0101ab7:	c3                   	ret    

f0101ab8 <memmove>:

/* no memcpy - use memmove instead */

void *
memmove(void *dst, const void *src, size_t n)
{
f0101ab8:	55                   	push   %ebp
f0101ab9:	89 e5                	mov    %esp,%ebp
f0101abb:	57                   	push   %edi
f0101abc:	56                   	push   %esi
f0101abd:	53                   	push   %ebx
f0101abe:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ac1:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101ac4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101ac7:	39 c6                	cmp    %eax,%esi
f0101ac9:	72 0b                	jb     f0101ad6 <memmove+0x1e>
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f0101acb:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ad0:	85 db                	test   %ebx,%ebx
f0101ad2:	75 2b                	jne    f0101aff <memmove+0x47>
f0101ad4:	eb 37                	jmp    f0101b0d <memmove+0x55>
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101ad6:	8d 0c 1e             	lea    (%esi,%ebx,1),%ecx
f0101ad9:	39 c8                	cmp    %ecx,%eax
f0101adb:	73 ee                	jae    f0101acb <memmove+0x13>
		s += n;
		d += n;
f0101add:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
		while (n-- > 0)
f0101ae0:	8d 53 ff             	lea    -0x1(%ebx),%edx
f0101ae3:	85 db                	test   %ebx,%ebx
f0101ae5:	74 26                	je     f0101b0d <memmove+0x55>
}

/* no memcpy - use memmove instead */

void *
memmove(void *dst, const void *src, size_t n)
f0101ae7:	f7 db                	neg    %ebx
f0101ae9:	8d 34 19             	lea    (%ecx,%ebx,1),%esi
f0101aec:	01 fb                	add    %edi,%ebx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
f0101aee:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0101af2:	88 0c 13             	mov    %cl,(%ebx,%edx,1)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
f0101af5:	83 ea 01             	sub    $0x1,%edx
f0101af8:	83 fa ff             	cmp    $0xffffffff,%edx
f0101afb:	75 f1                	jne    f0101aee <memmove+0x36>
f0101afd:	eb 0e                	jmp    f0101b0d <memmove+0x55>
			*--d = *--s;
	} else
		while (n-- > 0)
			*d++ = *s++;
f0101aff:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0101b03:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101b06:	83 c2 01             	add    $0x1,%edx
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f0101b09:	39 da                	cmp    %ebx,%edx
f0101b0b:	75 f2                	jne    f0101aff <memmove+0x47>
			*d++ = *s++;

	return dst;
}
f0101b0d:	5b                   	pop    %ebx
f0101b0e:	5e                   	pop    %esi
f0101b0f:	5f                   	pop    %edi
f0101b10:	5d                   	pop    %ebp
f0101b11:	c3                   	ret    

f0101b12 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0101b12:	55                   	push   %ebp
f0101b13:	89 e5                	mov    %esp,%ebp
f0101b15:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101b18:	8b 45 10             	mov    0x10(%ebp),%eax
f0101b1b:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101b1f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101b22:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101b26:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b29:	89 04 24             	mov    %eax,(%esp)
f0101b2c:	e8 87 ff ff ff       	call   f0101ab8 <memmove>
}
f0101b31:	c9                   	leave  
f0101b32:	c3                   	ret    

f0101b33 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101b33:	55                   	push   %ebp
f0101b34:	89 e5                	mov    %esp,%ebp
f0101b36:	57                   	push   %edi
f0101b37:	56                   	push   %esi
f0101b38:	53                   	push   %ebx
f0101b39:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101b3c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101b3f:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101b42:	8d 78 ff             	lea    -0x1(%eax),%edi
f0101b45:	85 c0                	test   %eax,%eax
f0101b47:	74 36                	je     f0101b7f <memcmp+0x4c>
		if (*s1 != *s2)
f0101b49:	0f b6 03             	movzbl (%ebx),%eax
f0101b4c:	0f b6 0e             	movzbl (%esi),%ecx
f0101b4f:	38 c8                	cmp    %cl,%al
f0101b51:	75 17                	jne    f0101b6a <memcmp+0x37>
f0101b53:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b58:	eb 1a                	jmp    f0101b74 <memcmp+0x41>
f0101b5a:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0101b5f:	83 c2 01             	add    $0x1,%edx
f0101b62:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0101b66:	38 c8                	cmp    %cl,%al
f0101b68:	74 0a                	je     f0101b74 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f0101b6a:	0f b6 c0             	movzbl %al,%eax
f0101b6d:	0f b6 c9             	movzbl %cl,%ecx
f0101b70:	29 c8                	sub    %ecx,%eax
f0101b72:	eb 10                	jmp    f0101b84 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101b74:	39 fa                	cmp    %edi,%edx
f0101b76:	75 e2                	jne    f0101b5a <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101b78:	b8 00 00 00 00       	mov    $0x0,%eax
f0101b7d:	eb 05                	jmp    f0101b84 <memcmp+0x51>
f0101b7f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101b84:	5b                   	pop    %ebx
f0101b85:	5e                   	pop    %esi
f0101b86:	5f                   	pop    %edi
f0101b87:	5d                   	pop    %ebp
f0101b88:	c3                   	ret    

f0101b89 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101b89:	55                   	push   %ebp
f0101b8a:	89 e5                	mov    %esp,%ebp
f0101b8c:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101b8f:	89 c2                	mov    %eax,%edx
f0101b91:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101b94:	39 d0                	cmp    %edx,%eax
f0101b96:	73 15                	jae    f0101bad <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101b98:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0101b9c:	38 08                	cmp    %cl,(%eax)
f0101b9e:	75 06                	jne    f0101ba6 <memfind+0x1d>
f0101ba0:	eb 0b                	jmp    f0101bad <memfind+0x24>
f0101ba2:	38 08                	cmp    %cl,(%eax)
f0101ba4:	74 07                	je     f0101bad <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101ba6:	83 c0 01             	add    $0x1,%eax
f0101ba9:	39 d0                	cmp    %edx,%eax
f0101bab:	75 f5                	jne    f0101ba2 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101bad:	5d                   	pop    %ebp
f0101bae:	66 90                	xchg   %ax,%ax
f0101bb0:	c3                   	ret    

f0101bb1 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101bb1:	55                   	push   %ebp
f0101bb2:	89 e5                	mov    %esp,%ebp
f0101bb4:	57                   	push   %edi
f0101bb5:	56                   	push   %esi
f0101bb6:	53                   	push   %ebx
f0101bb7:	83 ec 04             	sub    $0x4,%esp
f0101bba:	8b 55 08             	mov    0x8(%ebp),%edx
f0101bbd:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101bc0:	0f b6 02             	movzbl (%edx),%eax
f0101bc3:	3c 09                	cmp    $0x9,%al
f0101bc5:	74 04                	je     f0101bcb <strtol+0x1a>
f0101bc7:	3c 20                	cmp    $0x20,%al
f0101bc9:	75 0e                	jne    f0101bd9 <strtol+0x28>
		s++;
f0101bcb:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101bce:	0f b6 02             	movzbl (%edx),%eax
f0101bd1:	3c 09                	cmp    $0x9,%al
f0101bd3:	74 f6                	je     f0101bcb <strtol+0x1a>
f0101bd5:	3c 20                	cmp    $0x20,%al
f0101bd7:	74 f2                	je     f0101bcb <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101bd9:	3c 2b                	cmp    $0x2b,%al
f0101bdb:	75 0a                	jne    f0101be7 <strtol+0x36>
		s++;
f0101bdd:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101be0:	bf 00 00 00 00       	mov    $0x0,%edi
f0101be5:	eb 10                	jmp    f0101bf7 <strtol+0x46>
f0101be7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101bec:	3c 2d                	cmp    $0x2d,%al
f0101bee:	75 07                	jne    f0101bf7 <strtol+0x46>
		s++, neg = 1;
f0101bf0:	83 c2 01             	add    $0x1,%edx
f0101bf3:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101bf7:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101bfd:	75 15                	jne    f0101c14 <strtol+0x63>
f0101bff:	80 3a 30             	cmpb   $0x30,(%edx)
f0101c02:	75 10                	jne    f0101c14 <strtol+0x63>
f0101c04:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101c08:	75 0a                	jne    f0101c14 <strtol+0x63>
		s += 2, base = 16;
f0101c0a:	83 c2 02             	add    $0x2,%edx
f0101c0d:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101c12:	eb 10                	jmp    f0101c24 <strtol+0x73>
	else if (base == 0 && s[0] == '0')
f0101c14:	85 db                	test   %ebx,%ebx
f0101c16:	75 0c                	jne    f0101c24 <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101c18:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101c1a:	80 3a 30             	cmpb   $0x30,(%edx)
f0101c1d:	75 05                	jne    f0101c24 <strtol+0x73>
		s++, base = 8;
f0101c1f:	83 c2 01             	add    $0x1,%edx
f0101c22:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0101c24:	b8 00 00 00 00       	mov    $0x0,%eax
f0101c29:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101c2c:	0f b6 0a             	movzbl (%edx),%ecx
f0101c2f:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0101c32:	89 f3                	mov    %esi,%ebx
f0101c34:	80 fb 09             	cmp    $0x9,%bl
f0101c37:	77 08                	ja     f0101c41 <strtol+0x90>
			dig = *s - '0';
f0101c39:	0f be c9             	movsbl %cl,%ecx
f0101c3c:	83 e9 30             	sub    $0x30,%ecx
f0101c3f:	eb 22                	jmp    f0101c63 <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
f0101c41:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0101c44:	89 f3                	mov    %esi,%ebx
f0101c46:	80 fb 19             	cmp    $0x19,%bl
f0101c49:	77 08                	ja     f0101c53 <strtol+0xa2>
			dig = *s - 'a' + 10;
f0101c4b:	0f be c9             	movsbl %cl,%ecx
f0101c4e:	83 e9 57             	sub    $0x57,%ecx
f0101c51:	eb 10                	jmp    f0101c63 <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
f0101c53:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0101c56:	89 f3                	mov    %esi,%ebx
f0101c58:	80 fb 19             	cmp    $0x19,%bl
f0101c5b:	77 16                	ja     f0101c73 <strtol+0xc2>
			dig = *s - 'A' + 10;
f0101c5d:	0f be c9             	movsbl %cl,%ecx
f0101c60:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101c63:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0101c66:	7d 0f                	jge    f0101c77 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
f0101c68:	83 c2 01             	add    $0x1,%edx
f0101c6b:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0101c6f:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0101c71:	eb b9                	jmp    f0101c2c <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0101c73:	89 c1                	mov    %eax,%ecx
f0101c75:	eb 02                	jmp    f0101c79 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101c77:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101c79:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101c7d:	74 05                	je     f0101c84 <strtol+0xd3>
		*endptr = (char *) s;
f0101c7f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101c82:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101c84:	85 ff                	test   %edi,%edi
f0101c86:	74 04                	je     f0101c8c <strtol+0xdb>
f0101c88:	89 c8                	mov    %ecx,%eax
f0101c8a:	f7 d8                	neg    %eax
}
f0101c8c:	83 c4 04             	add    $0x4,%esp
f0101c8f:	5b                   	pop    %ebx
f0101c90:	5e                   	pop    %esi
f0101c91:	5f                   	pop    %edi
f0101c92:	5d                   	pop    %ebp
f0101c93:	c3                   	ret    
	...

f0101ca0 <__udivdi3>:
f0101ca0:	83 ec 1c             	sub    $0x1c,%esp
f0101ca3:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0101ca7:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101cab:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101caf:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101cb3:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101cb7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101cbb:	85 c0                	test   %eax,%eax
f0101cbd:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101cc1:	89 cf                	mov    %ecx,%edi
f0101cc3:	89 6c 24 04          	mov    %ebp,0x4(%esp)
f0101cc7:	75 37                	jne    f0101d00 <__udivdi3+0x60>
f0101cc9:	39 f1                	cmp    %esi,%ecx
f0101ccb:	77 73                	ja     f0101d40 <__udivdi3+0xa0>
f0101ccd:	85 c9                	test   %ecx,%ecx
f0101ccf:	75 0b                	jne    f0101cdc <__udivdi3+0x3c>
f0101cd1:	b8 01 00 00 00       	mov    $0x1,%eax
f0101cd6:	31 d2                	xor    %edx,%edx
f0101cd8:	f7 f1                	div    %ecx
f0101cda:	89 c1                	mov    %eax,%ecx
f0101cdc:	89 f0                	mov    %esi,%eax
f0101cde:	31 d2                	xor    %edx,%edx
f0101ce0:	f7 f1                	div    %ecx
f0101ce2:	89 c6                	mov    %eax,%esi
f0101ce4:	89 e8                	mov    %ebp,%eax
f0101ce6:	f7 f1                	div    %ecx
f0101ce8:	89 f2                	mov    %esi,%edx
f0101cea:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101cee:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101cf2:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101cf6:	83 c4 1c             	add    $0x1c,%esp
f0101cf9:	c3                   	ret    
f0101cfa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101d00:	39 f0                	cmp    %esi,%eax
f0101d02:	77 24                	ja     f0101d28 <__udivdi3+0x88>
f0101d04:	0f bd e8             	bsr    %eax,%ebp
f0101d07:	83 f5 1f             	xor    $0x1f,%ebp
f0101d0a:	75 4c                	jne    f0101d58 <__udivdi3+0xb8>
f0101d0c:	31 d2                	xor    %edx,%edx
f0101d0e:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0101d12:	0f 86 b0 00 00 00    	jbe    f0101dc8 <__udivdi3+0x128>
f0101d18:	39 f0                	cmp    %esi,%eax
f0101d1a:	0f 82 a8 00 00 00    	jb     f0101dc8 <__udivdi3+0x128>
f0101d20:	31 c0                	xor    %eax,%eax
f0101d22:	eb c6                	jmp    f0101cea <__udivdi3+0x4a>
f0101d24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101d28:	31 d2                	xor    %edx,%edx
f0101d2a:	31 c0                	xor    %eax,%eax
f0101d2c:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101d30:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101d34:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101d38:	83 c4 1c             	add    $0x1c,%esp
f0101d3b:	c3                   	ret    
f0101d3c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101d40:	89 e8                	mov    %ebp,%eax
f0101d42:	89 f2                	mov    %esi,%edx
f0101d44:	f7 f1                	div    %ecx
f0101d46:	31 d2                	xor    %edx,%edx
f0101d48:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101d4c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101d50:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101d54:	83 c4 1c             	add    $0x1c,%esp
f0101d57:	c3                   	ret    
f0101d58:	89 e9                	mov    %ebp,%ecx
f0101d5a:	89 fa                	mov    %edi,%edx
f0101d5c:	d3 e0                	shl    %cl,%eax
f0101d5e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101d62:	b8 20 00 00 00       	mov    $0x20,%eax
f0101d67:	29 e8                	sub    %ebp,%eax
f0101d69:	89 c1                	mov    %eax,%ecx
f0101d6b:	d3 ea                	shr    %cl,%edx
f0101d6d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101d71:	09 ca                	or     %ecx,%edx
f0101d73:	89 e9                	mov    %ebp,%ecx
f0101d75:	d3 e7                	shl    %cl,%edi
f0101d77:	89 c1                	mov    %eax,%ecx
f0101d79:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101d7d:	89 f2                	mov    %esi,%edx
f0101d7f:	d3 ea                	shr    %cl,%edx
f0101d81:	89 e9                	mov    %ebp,%ecx
f0101d83:	89 14 24             	mov    %edx,(%esp)
f0101d86:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101d8a:	d3 e6                	shl    %cl,%esi
f0101d8c:	89 c1                	mov    %eax,%ecx
f0101d8e:	d3 ea                	shr    %cl,%edx
f0101d90:	89 d0                	mov    %edx,%eax
f0101d92:	09 f0                	or     %esi,%eax
f0101d94:	8b 34 24             	mov    (%esp),%esi
f0101d97:	89 f2                	mov    %esi,%edx
f0101d99:	f7 74 24 0c          	divl   0xc(%esp)
f0101d9d:	89 d6                	mov    %edx,%esi
f0101d9f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101da3:	f7 e7                	mul    %edi
f0101da5:	39 d6                	cmp    %edx,%esi
f0101da7:	72 2f                	jb     f0101dd8 <__udivdi3+0x138>
f0101da9:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101dad:	89 e9                	mov    %ebp,%ecx
f0101daf:	d3 e7                	shl    %cl,%edi
f0101db1:	39 c7                	cmp    %eax,%edi
f0101db3:	73 04                	jae    f0101db9 <__udivdi3+0x119>
f0101db5:	39 d6                	cmp    %edx,%esi
f0101db7:	74 1f                	je     f0101dd8 <__udivdi3+0x138>
f0101db9:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101dbd:	31 d2                	xor    %edx,%edx
f0101dbf:	e9 26 ff ff ff       	jmp    f0101cea <__udivdi3+0x4a>
f0101dc4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101dc8:	b8 01 00 00 00       	mov    $0x1,%eax
f0101dcd:	e9 18 ff ff ff       	jmp    f0101cea <__udivdi3+0x4a>
f0101dd2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101dd8:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101ddc:	31 d2                	xor    %edx,%edx
f0101dde:	83 e8 01             	sub    $0x1,%eax
f0101de1:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101de5:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101de9:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101ded:	83 c4 1c             	add    $0x1c,%esp
f0101df0:	c3                   	ret    
	...

f0101e00 <__umoddi3>:
f0101e00:	83 ec 1c             	sub    $0x1c,%esp
f0101e03:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f0101e07:	8b 44 24 20          	mov    0x20(%esp),%eax
f0101e0b:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101e0f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101e13:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101e17:	85 d2                	test   %edx,%edx
f0101e19:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101e1d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101e21:	89 cf                	mov    %ecx,%edi
f0101e23:	89 c5                	mov    %eax,%ebp
f0101e25:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101e29:	89 34 24             	mov    %esi,(%esp)
f0101e2c:	75 22                	jne    f0101e50 <__umoddi3+0x50>
f0101e2e:	39 f1                	cmp    %esi,%ecx
f0101e30:	76 56                	jbe    f0101e88 <__umoddi3+0x88>
f0101e32:	89 f2                	mov    %esi,%edx
f0101e34:	f7 f1                	div    %ecx
f0101e36:	89 d0                	mov    %edx,%eax
f0101e38:	31 d2                	xor    %edx,%edx
f0101e3a:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101e3e:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101e42:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101e46:	83 c4 1c             	add    $0x1c,%esp
f0101e49:	c3                   	ret    
f0101e4a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101e50:	39 f2                	cmp    %esi,%edx
f0101e52:	77 54                	ja     f0101ea8 <__umoddi3+0xa8>
f0101e54:	0f bd c2             	bsr    %edx,%eax
f0101e57:	83 f0 1f             	xor    $0x1f,%eax
f0101e5a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101e5e:	75 60                	jne    f0101ec0 <__umoddi3+0xc0>
f0101e60:	39 e9                	cmp    %ebp,%ecx
f0101e62:	0f 87 08 01 00 00    	ja     f0101f70 <__umoddi3+0x170>
f0101e68:	29 cd                	sub    %ecx,%ebp
f0101e6a:	19 d6                	sbb    %edx,%esi
f0101e6c:	89 34 24             	mov    %esi,(%esp)
f0101e6f:	8b 14 24             	mov    (%esp),%edx
f0101e72:	89 e8                	mov    %ebp,%eax
f0101e74:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101e78:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101e7c:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101e80:	83 c4 1c             	add    $0x1c,%esp
f0101e83:	c3                   	ret    
f0101e84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101e88:	85 c9                	test   %ecx,%ecx
f0101e8a:	75 0b                	jne    f0101e97 <__umoddi3+0x97>
f0101e8c:	b8 01 00 00 00       	mov    $0x1,%eax
f0101e91:	31 d2                	xor    %edx,%edx
f0101e93:	f7 f1                	div    %ecx
f0101e95:	89 c1                	mov    %eax,%ecx
f0101e97:	89 f0                	mov    %esi,%eax
f0101e99:	31 d2                	xor    %edx,%edx
f0101e9b:	f7 f1                	div    %ecx
f0101e9d:	89 e8                	mov    %ebp,%eax
f0101e9f:	f7 f1                	div    %ecx
f0101ea1:	eb 93                	jmp    f0101e36 <__umoddi3+0x36>
f0101ea3:	90                   	nop
f0101ea4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ea8:	89 f2                	mov    %esi,%edx
f0101eaa:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101eae:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101eb2:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101eb6:	83 c4 1c             	add    $0x1c,%esp
f0101eb9:	c3                   	ret    
f0101eba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101ec0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101ec5:	bd 20 00 00 00       	mov    $0x20,%ebp
f0101eca:	89 f8                	mov    %edi,%eax
f0101ecc:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0101ed0:	d3 e2                	shl    %cl,%edx
f0101ed2:	89 e9                	mov    %ebp,%ecx
f0101ed4:	d3 e8                	shr    %cl,%eax
f0101ed6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101edb:	09 d0                	or     %edx,%eax
f0101edd:	89 f2                	mov    %esi,%edx
f0101edf:	89 04 24             	mov    %eax,(%esp)
f0101ee2:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101ee6:	d3 e7                	shl    %cl,%edi
f0101ee8:	89 e9                	mov    %ebp,%ecx
f0101eea:	d3 ea                	shr    %cl,%edx
f0101eec:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101ef1:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101ef5:	d3 e6                	shl    %cl,%esi
f0101ef7:	89 e9                	mov    %ebp,%ecx
f0101ef9:	d3 e8                	shr    %cl,%eax
f0101efb:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101f00:	09 f0                	or     %esi,%eax
f0101f02:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101f06:	f7 34 24             	divl   (%esp)
f0101f09:	d3 e6                	shl    %cl,%esi
f0101f0b:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101f0f:	89 d6                	mov    %edx,%esi
f0101f11:	f7 e7                	mul    %edi
f0101f13:	39 d6                	cmp    %edx,%esi
f0101f15:	89 c7                	mov    %eax,%edi
f0101f17:	89 d1                	mov    %edx,%ecx
f0101f19:	72 41                	jb     f0101f5c <__umoddi3+0x15c>
f0101f1b:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101f1f:	72 37                	jb     f0101f58 <__umoddi3+0x158>
f0101f21:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101f25:	29 f8                	sub    %edi,%eax
f0101f27:	19 ce                	sbb    %ecx,%esi
f0101f29:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101f2e:	89 f2                	mov    %esi,%edx
f0101f30:	d3 e8                	shr    %cl,%eax
f0101f32:	89 e9                	mov    %ebp,%ecx
f0101f34:	d3 e2                	shl    %cl,%edx
f0101f36:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101f3b:	09 d0                	or     %edx,%eax
f0101f3d:	89 f2                	mov    %esi,%edx
f0101f3f:	d3 ea                	shr    %cl,%edx
f0101f41:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101f45:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101f49:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101f4d:	83 c4 1c             	add    $0x1c,%esp
f0101f50:	c3                   	ret    
f0101f51:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101f58:	39 d6                	cmp    %edx,%esi
f0101f5a:	75 c5                	jne    f0101f21 <__umoddi3+0x121>
f0101f5c:	89 d1                	mov    %edx,%ecx
f0101f5e:	89 c7                	mov    %eax,%edi
f0101f60:	2b 7c 24 0c          	sub    0xc(%esp),%edi
f0101f64:	1b 0c 24             	sbb    (%esp),%ecx
f0101f67:	eb b8                	jmp    f0101f21 <__umoddi3+0x121>
f0101f69:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101f70:	39 f2                	cmp    %esi,%edx
f0101f72:	0f 82 f0 fe ff ff    	jb     f0101e68 <__umoddi3+0x68>
f0101f78:	e9 f2 fe ff ff       	jmp    f0101e6f <__umoddi3+0x6f>
