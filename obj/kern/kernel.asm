
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
f0100015:	0f 01 15 18 60 11 00 	lgdtl  0x116018

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
f0100033:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

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
f010004e:	c7 04 24 a0 3d 10 f0 	movl   $0xf0103da0,(%esp)
f0100055:	e8 e8 2c 00 00       	call   f0102d42 <cprintf>
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
f010008b:	c7 04 24 bc 3d 10 f0 	movl   $0xf0103dbc,(%esp)
f0100092:	e8 ab 2c 00 00       	call   f0102d42 <cprintf>
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
f01000a3:	b8 10 6a 11 f0       	mov    $0xf0116a10,%eax
f01000a8:	2d 70 63 11 f0       	sub    $0xf0116370,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 70 63 11 f0 	movl   $0xf0116370,(%esp)
f01000c0:	e8 df 37 00 00       	call   f01038a4 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 83 05 00 00       	call   f010064d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 d7 3d 10 f0 	movl   $0xf0103dd7,(%esp)
f01000d9:	e8 64 2c 00 00       	call   f0102d42 <cprintf>

	// Lab 2 memory management initialization functions
	i386_detect_memory();
f01000de:	e8 5d 0a 00 00       	call   f0100b40 <i386_detect_memory>
	i386_vm_init();
f01000e3:	e8 d2 0f 00 00       	call   f01010ba <i386_vm_init>



	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000e8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ef:	e8 00 08 00 00       	call   f01008f4 <monitor>
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
f01000fc:	83 3d 80 63 11 f0 00 	cmpl   $0x0,0xf0116380
f0100103:	75 40                	jne    f0100145 <_panic+0x4f>
		goto dead;
	panicstr = fmt;
f0100105:	8b 45 10             	mov    0x10(%ebp),%eax
f0100108:	a3 80 63 11 f0       	mov    %eax,0xf0116380

	va_start(ap, fmt);
	cprintf("kernel panic at %s:%d: ", file, line);
f010010d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100110:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100114:	8b 45 08             	mov    0x8(%ebp),%eax
f0100117:	89 44 24 04          	mov    %eax,0x4(%esp)
f010011b:	c7 04 24 f2 3d 10 f0 	movl   $0xf0103df2,(%esp)
f0100122:	e8 1b 2c 00 00       	call   f0102d42 <cprintf>

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
f0100134:	e8 d6 2b 00 00       	call   f0102d0f <vcprintf>
	cprintf("\n");
f0100139:	c7 04 24 d9 4a 10 f0 	movl   $0xf0104ad9,(%esp)
f0100140:	e8 fd 2b 00 00       	call   f0102d42 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100145:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010014c:	e8 a3 07 00 00       	call   f01008f4 <monitor>
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
f0100167:	c7 04 24 0a 3e 10 f0 	movl   $0xf0103e0a,(%esp)
f010016e:	e8 cf 2b 00 00       	call   f0102d42 <cprintf>
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
f0100180:	e8 8a 2b 00 00       	call   f0102d0f <vcprintf>
	cprintf("\n");
f0100185:	c7 04 24 d9 4a 10 f0 	movl   $0xf0104ad9,(%esp)
f010018c:	e8 b1 2b 00 00       	call   f0102d42 <cprintf>
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
f01001da:	83 0d b0 63 11 f0 40 	orl    $0x40,0xf01163b0
		return 0;
f01001e1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01001e6:	e9 cf 00 00 00       	jmp    f01002ba <kbd_proc_data+0xfe>
	} else if (data & 0x80) {
f01001eb:	84 c0                	test   %al,%al
f01001ed:	79 34                	jns    f0100223 <kbd_proc_data+0x67>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001ef:	8b 0d b0 63 11 f0    	mov    0xf01163b0,%ecx
f01001f5:	f6 c1 40             	test   $0x40,%cl
f01001f8:	75 05                	jne    f01001ff <kbd_proc_data+0x43>
f01001fa:	89 c2                	mov    %eax,%edx
f01001fc:	83 e2 7f             	and    $0x7f,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001ff:	0f b6 d2             	movzbl %dl,%edx
f0100202:	0f b6 82 60 3e 10 f0 	movzbl -0xfefc1a0(%edx),%eax
f0100209:	83 c8 40             	or     $0x40,%eax
f010020c:	0f b6 c0             	movzbl %al,%eax
f010020f:	f7 d0                	not    %eax
f0100211:	21 c1                	and    %eax,%ecx
f0100213:	89 0d b0 63 11 f0    	mov    %ecx,0xf01163b0
		return 0;
f0100219:	bb 00 00 00 00       	mov    $0x0,%ebx
f010021e:	e9 97 00 00 00       	jmp    f01002ba <kbd_proc_data+0xfe>
	} else if (shift & E0ESC) {
f0100223:	8b 0d b0 63 11 f0    	mov    0xf01163b0,%ecx
f0100229:	f6 c1 40             	test   $0x40,%cl
f010022c:	74 0e                	je     f010023c <kbd_proc_data+0x80>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010022e:	89 c2                	mov    %eax,%edx
f0100230:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100233:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100236:	89 0d b0 63 11 f0    	mov    %ecx,0xf01163b0
	}

	shift |= shiftcode[data];
f010023c:	0f b6 c2             	movzbl %dl,%eax
f010023f:	0f b6 90 60 3e 10 f0 	movzbl -0xfefc1a0(%eax),%edx
f0100246:	0b 15 b0 63 11 f0    	or     0xf01163b0,%edx
	shift ^= togglecode[data];
f010024c:	0f b6 88 60 3f 10 f0 	movzbl -0xfefc0a0(%eax),%ecx
f0100253:	31 ca                	xor    %ecx,%edx
f0100255:	89 15 b0 63 11 f0    	mov    %edx,0xf01163b0

	c = charcode[shift & (CTL | SHIFT)][data];
f010025b:	89 d1                	mov    %edx,%ecx
f010025d:	83 e1 03             	and    $0x3,%ecx
f0100260:	8b 0c 8d 60 40 10 f0 	mov    -0xfefbfa0(,%ecx,4),%ecx
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
f010029c:	c7 04 24 24 3e 10 f0 	movl   $0xf0103e24,(%esp)
f01002a3:	e8 9a 2a 00 00       	call   f0102d42 <cprintf>
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
f0100313:	a3 a0 63 11 f0       	mov    %eax,0xf01163a0
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
f010034d:	c7 05 a4 63 11 f0 b4 	movl   $0x3b4,0xf01163a4
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
f0100365:	c7 05 a4 63 11 f0 d4 	movl   $0x3d4,0xf01163a4
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
f0100374:	8b 0d a4 63 11 f0    	mov    0xf01163a4,%ecx
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
f0100399:	89 3d a8 63 11 f0    	mov    %edi,0xf01163a8
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010039f:	0f b6 d8             	movzbl %al,%ebx
f01003a2:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01003a4:	66 89 35 ac 63 11 f0 	mov    %si,0xf01163ac
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
f01003cd:	8b 15 c4 65 11 f0    	mov    0xf01165c4,%edx
f01003d3:	88 82 c0 63 11 f0    	mov    %al,-0xfee9c40(%edx)
f01003d9:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01003dc:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01003e1:	0f 94 c2             	sete   %dl
f01003e4:	0f b6 d2             	movzbl %dl,%edx
f01003e7:	83 ea 01             	sub    $0x1,%edx
f01003ea:	21 d0                	and    %edx,%eax
f01003ec:	a3 c4 65 11 f0       	mov    %eax,0xf01165c4
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
f0100412:	83 3d a0 63 11 f0 00 	cmpl   $0x0,0xf01163a0
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
f0100440:	8b 15 c0 65 11 f0    	mov    0xf01165c0,%edx
f0100446:	3b 15 c4 65 11 f0    	cmp    0xf01165c4,%edx
f010044c:	74 23                	je     f0100471 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f010044e:	0f b6 82 c0 63 11 f0 	movzbl -0xfee9c40(%edx),%eax
f0100455:	83 c2 01             	add    $0x1,%edx
f0100458:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010045e:	0f 94 c1             	sete   %cl
f0100461:	0f b6 c9             	movzbl %cl,%ecx
f0100464:	83 e9 01             	sub    $0x1,%ecx
f0100467:	21 ca                	and    %ecx,%edx
f0100469:	89 15 c0 65 11 f0    	mov    %edx,0xf01165c0
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
f0100518:	0f b7 15 ac 63 11 f0 	movzwl 0xf01163ac,%edx
f010051f:	66 85 d2             	test   %dx,%dx
f0100522:	0f 84 f0 00 00 00    	je     f0100618 <cga_putc+0x13e>
			crt_pos--;
f0100528:	83 ea 01             	sub    $0x1,%edx
f010052b:	66 89 15 ac 63 11 f0 	mov    %dx,0xf01163ac
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100532:	0f b7 d2             	movzwl %dx,%edx
f0100535:	b0 00                	mov    $0x0,%al
f0100537:	83 c8 20             	or     $0x20,%eax
f010053a:	8b 0d a8 63 11 f0    	mov    0xf01163a8,%ecx
f0100540:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100544:	e9 82 00 00 00       	jmp    f01005cb <cga_putc+0xf1>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100549:	66 83 05 ac 63 11 f0 	addw   $0x50,0xf01163ac
f0100550:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100551:	0f b7 05 ac 63 11 f0 	movzwl 0xf01163ac,%eax
f0100558:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010055e:	c1 e8 16             	shr    $0x16,%eax
f0100561:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100564:	c1 e0 04             	shl    $0x4,%eax
f0100567:	66 a3 ac 63 11 f0    	mov    %ax,0xf01163ac
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
f01005ad:	0f b7 15 ac 63 11 f0 	movzwl 0xf01163ac,%edx
f01005b4:	0f b7 da             	movzwl %dx,%ebx
f01005b7:	8b 0d a8 63 11 f0    	mov    0xf01163a8,%ecx
f01005bd:	66 89 04 59          	mov    %ax,(%ecx,%ebx,2)
f01005c1:	83 c2 01             	add    $0x1,%edx
f01005c4:	66 89 15 ac 63 11 f0 	mov    %dx,0xf01163ac
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005cb:	66 81 3d ac 63 11 f0 	cmpw   $0x7cf,0xf01163ac
f01005d2:	cf 07 
f01005d4:	76 42                	jbe    f0100618 <cga_putc+0x13e>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005d6:	a1 a8 63 11 f0       	mov    0xf01163a8,%eax
f01005db:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01005e2:	00 
f01005e3:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005e9:	89 54 24 04          	mov    %edx,0x4(%esp)
f01005ed:	89 04 24             	mov    %eax,(%esp)
f01005f0:	e8 d3 32 00 00       	call   f01038c8 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005f5:	8b 15 a8 63 11 f0    	mov    0xf01163a8,%edx
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
f0100610:	66 83 2d ac 63 11 f0 	subw   $0x50,0xf01163ac
f0100617:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100618:	8b 0d a4 63 11 f0    	mov    0xf01163a4,%ecx
f010061e:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100623:	89 ca                	mov    %ecx,%edx
f0100625:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100626:	0f b7 1d ac 63 11 f0 	movzwl 0xf01163ac,%ebx
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
f010065d:	83 3d a0 63 11 f0 00 	cmpl   $0x0,0xf01163a0
f0100664:	75 0c                	jne    f0100672 <cons_init+0x25>
		cprintf("Serial port does not exist!\n");
f0100666:	c7 04 24 30 3e 10 f0 	movl   $0xf0103e30,(%esp)
f010066d:	e8 d0 26 00 00       	call   f0102d42 <cprintf>
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
f01006b6:	c7 04 24 70 40 10 f0 	movl   $0xf0104070,(%esp)
f01006bd:	e8 80 26 00 00       	call   f0102d42 <cprintf>
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
f01006c2:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006c9:	00 
f01006ca:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006d1:	f0 
f01006d2:	c7 04 24 6c 41 10 f0 	movl   $0xf010416c,(%esp)
f01006d9:	e8 64 26 00 00       	call   f0102d42 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006de:	c7 44 24 08 8d 3d 10 	movl   $0x103d8d,0x8(%esp)
f01006e5:	00 
f01006e6:	c7 44 24 04 8d 3d 10 	movl   $0xf0103d8d,0x4(%esp)
f01006ed:	f0 
f01006ee:	c7 04 24 90 41 10 f0 	movl   $0xf0104190,(%esp)
f01006f5:	e8 48 26 00 00       	call   f0102d42 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006fa:	c7 44 24 08 70 63 11 	movl   $0x116370,0x8(%esp)
f0100701:	00 
f0100702:	c7 44 24 04 70 63 11 	movl   $0xf0116370,0x4(%esp)
f0100709:	f0 
f010070a:	c7 04 24 b4 41 10 f0 	movl   $0xf01041b4,(%esp)
f0100711:	e8 2c 26 00 00       	call   f0102d42 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100716:	c7 44 24 08 10 6a 11 	movl   $0x116a10,0x8(%esp)
f010071d:	00 
f010071e:	c7 44 24 04 10 6a 11 	movl   $0xf0116a10,0x4(%esp)
f0100725:	f0 
f0100726:	c7 04 24 d8 41 10 f0 	movl   $0xf01041d8,(%esp)
f010072d:	e8 10 26 00 00       	call   f0102d42 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-_start+1023)/1024);
f0100732:	b8 0f 6e 11 f0       	mov    $0xf0116e0f,%eax
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
f010074d:	c7 04 24 fc 41 10 f0 	movl   $0xf01041fc,(%esp)
f0100754:	e8 e9 25 00 00       	call   f0102d42 <cprintf>
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
f010076c:	c7 04 24 89 40 10 f0 	movl   $0xf0104089,(%esp)
f0100773:	e8 ca 25 00 00       	call   f0102d42 <cprintf>
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
f0100787:	bb c4 42 10 f0       	mov    $0xf01042c4,%ebx
unsigned read_eip();

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
f010078c:	be f4 42 10 f0       	mov    $0xf01042f4,%esi
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100791:	8b 03                	mov    (%ebx),%eax
f0100793:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100797:	8b 43 fc             	mov    -0x4(%ebx),%eax
f010079a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010079e:	c7 04 24 92 40 10 f0 	movl   $0xf0104092,(%esp)
f01007a5:	e8 98 25 00 00       	call   f0102d42 <cprintf>
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
f01007bd:	89 e8                	mov    %ebp,%eax
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
    unsigned int ebp;                                                                                                                                                        ebp = read_ebp();                                                             
    while(ebp > 0)                                                                
f01007bf:	85 c0                	test   %eax,%eax
f01007c1:	0f 84 27 01 00 00    	je     f01008ee <mon_backtrace+0x131>
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007c7:	55                   	push   %ebp
f01007c8:	89 e5                	mov    %esp,%ebp
f01007ca:	57                   	push   %edi
f01007cb:	56                   	push   %esi
f01007cc:	53                   	push   %ebx
f01007cd:	81 ec bc 00 00 00    	sub    $0xbc,%esp
f01007d3:	89 c6                	mov    %eax,%esi
		cprintf("%s\t",debug_info.eip_file);
		cprintf("%d\t",debug_info.eip_line);
		for(i=0;i<debug_info.eip_fn_namelen;i++)
			name[i] = debug_info.eip_fn_name[i];
		name[i] = '\0';
		cprintf("%s+%x\t",name,debug_info.eip_fn_addr);
f01007d5:	8d 5d 84             	lea    -0x7c(%ebp),%ebx
        
	int i;
	char name[100];
	struct Eipdebuginfo debug_info;

	if( debuginfo_eip(*((unsigned int*)ebp+1) ,&debug_info) >= 0)
f01007d8:	8d 7e 04             	lea    0x4(%esi),%edi
f01007db:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
f01007e1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007e5:	8b 46 04             	mov    0x4(%esi),%eax
f01007e8:	89 04 24             	mov    %eax,(%esp)
f01007eb:	e8 4d 26 00 00       	call   f0102e3d <debuginfo_eip>
f01007f0:	85 c0                	test   %eax,%eax
f01007f2:	0f 88 a5 00 00 00    	js     f010089d <mon_backtrace+0xe0>
	{
		cprintf("%s\t",debug_info.eip_file);
f01007f8:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
f01007fe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100802:	c7 04 24 9b 40 10 f0 	movl   $0xf010409b,(%esp)
f0100809:	e8 34 25 00 00       	call   f0102d42 <cprintf>
		cprintf("%d\t",debug_info.eip_line);
f010080e:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
f0100814:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100818:	c7 04 24 9f 40 10 f0 	movl   $0xf010409f,(%esp)
f010081f:	e8 1e 25 00 00       	call   f0102d42 <cprintf>
		for(i=0;i<debug_info.eip_fn_namelen;i++)
f0100824:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
f010082a:	85 d2                	test   %edx,%edx
f010082c:	7e 36                	jle    f0100864 <mon_backtrace+0xa7>
			name[i] = debug_info.eip_fn_name[i];
f010082e:	8b 8d 74 ff ff ff    	mov    -0x8c(%ebp),%ecx

	if( debuginfo_eip(*((unsigned int*)ebp+1) ,&debug_info) >= 0)
	{
		cprintf("%s\t",debug_info.eip_file);
		cprintf("%d\t",debug_info.eip_line);
		for(i=0;i<debug_info.eip_fn_namelen;i++)
f0100834:	b8 00 00 00 00       	mov    $0x0,%eax
f0100839:	89 95 64 ff ff ff    	mov    %edx,-0x9c(%ebp)
			name[i] = debug_info.eip_fn_name[i];
f010083f:	0f b6 14 01          	movzbl (%ecx,%eax,1),%edx
f0100843:	88 14 18             	mov    %dl,(%eax,%ebx,1)

	if( debuginfo_eip(*((unsigned int*)ebp+1) ,&debug_info) >= 0)
	{
		cprintf("%s\t",debug_info.eip_file);
		cprintf("%d\t",debug_info.eip_line);
		for(i=0;i<debug_info.eip_fn_namelen;i++)
f0100846:	83 c0 01             	add    $0x1,%eax
f0100849:	3b 85 64 ff ff ff    	cmp    -0x9c(%ebp),%eax
f010084f:	7c ee                	jl     f010083f <mon_backtrace+0x82>
f0100851:	8b 95 64 ff ff ff    	mov    -0x9c(%ebp),%edx
f0100857:	89 d0                	mov    %edx,%eax
f0100859:	85 d2                	test   %edx,%edx
f010085b:	7f 0c                	jg     f0100869 <mon_backtrace+0xac>
f010085d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100862:	eb 05                	jmp    f0100869 <mon_backtrace+0xac>
f0100864:	b8 00 00 00 00       	mov    $0x0,%eax
			name[i] = debug_info.eip_fn_name[i];
		name[i] = '\0';
f0100869:	c6 44 05 84 00       	movb   $0x0,-0x7c(%ebp,%eax,1)
		cprintf("%s+%x\t",name,debug_info.eip_fn_addr);
f010086e:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
f0100874:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100878:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010087c:	c7 04 24 a3 40 10 f0 	movl   $0xf01040a3,(%esp)
f0100883:	e8 ba 24 00 00       	call   f0102d42 <cprintf>
		cprintf("args_num: %d\n",debug_info.eip_fn_narg);
f0100888:	8b 45 80             	mov    -0x80(%ebp),%eax
f010088b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010088f:	c7 04 24 aa 40 10 f0 	movl   $0xf01040aa,(%esp)
f0100896:	e8 a7 24 00 00       	call   f0102d42 <cprintf>
f010089b:	eb 0c                	jmp    f01008a9 <mon_backtrace+0xec>
	}
	else
	{
		cprintf("debuginfo_eip failed\n");
f010089d:	c7 04 24 b8 40 10 f0 	movl   $0xf01040b8,(%esp)
f01008a4:	e8 99 24 00 00       	call   f0102d42 <cprintf>
	}	    
	cprintf("ebp %x eip %x args %08x %08x %08x\n",ebp,*((unsigned int*)ebp+1),
f01008a9:	8b 46 10             	mov    0x10(%esi),%eax
f01008ac:	89 44 24 14          	mov    %eax,0x14(%esp)
f01008b0:	8b 46 0c             	mov    0xc(%esi),%eax
f01008b3:	89 44 24 10          	mov    %eax,0x10(%esp)
f01008b7:	8b 46 08             	mov    0x8(%esi),%eax
f01008ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01008be:	8b 07                	mov    (%edi),%eax
f01008c0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008c4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01008c8:	c7 04 24 28 42 10 f0 	movl   $0xf0104228,(%esp)
f01008cf:	e8 6e 24 00 00       	call   f0102d42 <cprintf>
                *((unsigned int *)ebp+2),*((unsigned int *)ebp+3),*((unsigned int*)ebp+4));
        ebp = *( unsigned int *)ebp;       
f01008d4:	8b 36                	mov    (%esi),%esi
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
    unsigned int ebp;                                                                                                                                                        ebp = read_ebp();                                                             
    while(ebp > 0)                                                                
f01008d6:	85 f6                	test   %esi,%esi
f01008d8:	0f 85 fa fe ff ff    	jne    f01007d8 <mon_backtrace+0x1b>
    



    return 0;
}
f01008de:	b8 00 00 00 00       	mov    $0x0,%eax
f01008e3:	81 c4 bc 00 00 00    	add    $0xbc,%esp
f01008e9:	5b                   	pop    %ebx
f01008ea:	5e                   	pop    %esi
f01008eb:	5f                   	pop    %edi
f01008ec:	5d                   	pop    %ebp
f01008ed:	c3                   	ret    
f01008ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01008f3:	c3                   	ret    

f01008f4 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008f4:	55                   	push   %ebp
f01008f5:	89 e5                	mov    %esp,%ebp
f01008f7:	57                   	push   %edi
f01008f8:	56                   	push   %esi
f01008f9:	53                   	push   %ebx
f01008fa:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008fd:	c7 04 24 4c 42 10 f0 	movl   $0xf010424c,(%esp)
f0100904:	e8 39 24 00 00       	call   f0102d42 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100909:	c7 04 24 70 42 10 f0 	movl   $0xf0104270,(%esp)
f0100910:	e8 2d 24 00 00       	call   f0102d42 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100915:	c7 04 24 ce 40 10 f0 	movl   $0xf01040ce,(%esp)
f010091c:	e8 ef 2c 00 00       	call   f0103610 <readline>
f0100921:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100923:	85 c0                	test   %eax,%eax
f0100925:	74 ee                	je     f0100915 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100927:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010092e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100933:	eb 06                	jmp    f010093b <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100935:	c6 06 00             	movb   $0x0,(%esi)
f0100938:	83 c6 01             	add    $0x1,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010093b:	0f b6 06             	movzbl (%esi),%eax
f010093e:	84 c0                	test   %al,%al
f0100940:	74 6a                	je     f01009ac <monitor+0xb8>
f0100942:	0f be c0             	movsbl %al,%eax
f0100945:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100949:	c7 04 24 d2 40 10 f0 	movl   $0xf01040d2,(%esp)
f0100950:	e8 f5 2e 00 00       	call   f010384a <strchr>
f0100955:	85 c0                	test   %eax,%eax
f0100957:	75 dc                	jne    f0100935 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100959:	80 3e 00             	cmpb   $0x0,(%esi)
f010095c:	74 4e                	je     f01009ac <monitor+0xb8>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010095e:	83 fb 0f             	cmp    $0xf,%ebx
f0100961:	75 16                	jne    f0100979 <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100963:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010096a:	00 
f010096b:	c7 04 24 d7 40 10 f0 	movl   $0xf01040d7,(%esp)
f0100972:	e8 cb 23 00 00       	call   f0102d42 <cprintf>
f0100977:	eb 9c                	jmp    f0100915 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100979:	89 74 9d a8          	mov    %esi,-0x58(%ebp,%ebx,4)
f010097d:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f0100980:	0f b6 06             	movzbl (%esi),%eax
f0100983:	84 c0                	test   %al,%al
f0100985:	75 0c                	jne    f0100993 <monitor+0x9f>
f0100987:	eb b2                	jmp    f010093b <monitor+0x47>
			buf++;
f0100989:	83 c6 01             	add    $0x1,%esi
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010098c:	0f b6 06             	movzbl (%esi),%eax
f010098f:	84 c0                	test   %al,%al
f0100991:	74 a8                	je     f010093b <monitor+0x47>
f0100993:	0f be c0             	movsbl %al,%eax
f0100996:	89 44 24 04          	mov    %eax,0x4(%esp)
f010099a:	c7 04 24 d2 40 10 f0 	movl   $0xf01040d2,(%esp)
f01009a1:	e8 a4 2e 00 00       	call   f010384a <strchr>
f01009a6:	85 c0                	test   %eax,%eax
f01009a8:	74 df                	je     f0100989 <monitor+0x95>
f01009aa:	eb 8f                	jmp    f010093b <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f01009ac:	c7 44 9d a8 00 00 00 	movl   $0x0,-0x58(%ebp,%ebx,4)
f01009b3:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009b4:	85 db                	test   %ebx,%ebx
f01009b6:	0f 84 59 ff ff ff    	je     f0100915 <monitor+0x21>
f01009bc:	bf c0 42 10 f0       	mov    $0xf01042c0,%edi
f01009c1:	be 00 00 00 00       	mov    $0x0,%esi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009c6:	8b 07                	mov    (%edi),%eax
f01009c8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009cc:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01009cf:	89 04 24             	mov    %eax,(%esp)
f01009d2:	e8 ef 2d 00 00       	call   f01037c6 <strcmp>
f01009d7:	85 c0                	test   %eax,%eax
f01009d9:	75 24                	jne    f01009ff <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f01009db:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01009de:	8b 55 08             	mov    0x8(%ebp),%edx
f01009e1:	89 54 24 08          	mov    %edx,0x8(%esp)
f01009e5:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01009e8:	89 54 24 04          	mov    %edx,0x4(%esp)
f01009ec:	89 1c 24             	mov    %ebx,(%esp)
f01009ef:	ff 14 85 c8 42 10 f0 	call   *-0xfefbd38(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01009f6:	85 c0                	test   %eax,%eax
f01009f8:	78 28                	js     f0100a22 <monitor+0x12e>
f01009fa:	e9 16 ff ff ff       	jmp    f0100915 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01009ff:	83 c6 01             	add    $0x1,%esi
f0100a02:	83 c7 0c             	add    $0xc,%edi
f0100a05:	83 fe 04             	cmp    $0x4,%esi
f0100a08:	75 bc                	jne    f01009c6 <monitor+0xd2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a0a:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a0d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a11:	c7 04 24 f4 40 10 f0 	movl   $0xf01040f4,(%esp)
f0100a18:	e8 25 23 00 00       	call   f0102d42 <cprintf>
f0100a1d:	e9 f3 fe ff ff       	jmp    f0100915 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a22:	83 c4 5c             	add    $0x5c,%esp
f0100a25:	5b                   	pop    %ebx
f0100a26:	5e                   	pop    %esi
f0100a27:	5f                   	pop    %edi
f0100a28:	5d                   	pop    %ebp
f0100a29:	c3                   	ret    

f0100a2a <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100a2a:	55                   	push   %ebp
f0100a2b:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f0100a2d:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100a30:	5d                   	pop    %ebp
f0100a31:	c3                   	ret    
	...

f0100a40 <boot_alloc>:
// This function may ONLY be used during initialization,
// before the page_free_list has been set up.
// 
static void*
boot_alloc(uint32_t n, uint32_t align)
{
f0100a40:	55                   	push   %ebp
f0100a41:	89 e5                	mov    %esp,%ebp
f0100a43:	83 ec 0c             	sub    $0xc,%esp
f0100a46:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100a49:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100a4c:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100a4f:	89 c7                	mov    %eax,%edi
f0100a51:	89 d1                	mov    %edx,%ecx
	// Initialize boot_freemem if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment -
	// i.e., the first virtual address that the linker
	// did _not_ assign to any kernel code or global variables.
	if (boot_freemem == 0)
f0100a53:	83 3d d4 65 11 f0 00 	cmpl   $0x0,0xf01165d4
f0100a5a:	75 0a                	jne    f0100a66 <boot_alloc+0x26>
		boot_freemem = end;
f0100a5c:	c7 05 d4 65 11 f0 10 	movl   $0xf0116a10,0xf01165d4
f0100a63:	6a 11 f0 
	// LAB 2: Your code here:
	//	Step 1: round boot_freemem up to be aligned properly
	//	Step 2: save current value of boot_freemem as allocated chunk
	//	Step 3: increase boot_freemem to record allocation
	//	Step 4: return allocated chunk
	boot_freemem =  ROUNDUP	(boot_freemem,align);
f0100a66:	a1 d4 65 11 f0       	mov    0xf01165d4,%eax
f0100a6b:	8d 5c 08 ff          	lea    -0x1(%eax,%ecx,1),%ebx
f0100a6f:	89 d8                	mov    %ebx,%eax
f0100a71:	ba 00 00 00 00       	mov    $0x0,%edx
f0100a76:	f7 f1                	div    %ecx
f0100a78:	89 de                	mov    %ebx,%esi
f0100a7a:	29 d6                	sub    %edx,%esi
	v = boot_freemem;
	boot_freemem+=  ROUNDUP(n,align);
f0100a7c:	8d 5c 0f ff          	lea    -0x1(%edi,%ecx,1),%ebx
f0100a80:	89 d8                	mov    %ebx,%eax
f0100a82:	ba 00 00 00 00       	mov    $0x0,%edx
f0100a87:	f7 f1                	div    %ecx
f0100a89:	29 d3                	sub    %edx,%ebx
f0100a8b:	01 f3                	add    %esi,%ebx
f0100a8d:	89 1d d4 65 11 f0    	mov    %ebx,0xf01165d4
	return v;
}
f0100a93:	89 f0                	mov    %esi,%eax
f0100a95:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100a98:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100a9b:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100a9e:	89 ec                	mov    %ebp,%esp
f0100aa0:	5d                   	pop    %ebp
f0100aa1:	c3                   	ret    

f0100aa2 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100aa2:	89 d1                	mov    %edx,%ecx
f0100aa4:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100aa7:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100aaa:	a8 01                	test   $0x1,%al
f0100aac:	74 5a                	je     f0100b08 <check_va2pa+0x66>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100aae:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100ab3:	89 c1                	mov    %eax,%ecx
f0100ab5:	c1 e9 0c             	shr    $0xc,%ecx
f0100ab8:	3b 0d 00 6a 11 f0    	cmp    0xf0116a00,%ecx
f0100abe:	72 26                	jb     f0100ae6 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_boot_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100ac0:	55                   	push   %ebp
f0100ac1:	89 e5                	mov    %esp,%ebp
f0100ac3:	83 ec 18             	sub    $0x18,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100ac6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100aca:	c7 44 24 08 f0 42 10 	movl   $0xf01042f0,0x8(%esp)
f0100ad1:	f0 
f0100ad2:	c7 44 24 04 ab 01 00 	movl   $0x1ab,0x4(%esp)
f0100ad9:	00 
f0100ada:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0100ae1:	e8 10 f6 ff ff       	call   f01000f6 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100ae6:	c1 ea 0c             	shr    $0xc,%edx
f0100ae9:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100aef:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100af6:	89 c2                	mov    %eax,%edx
f0100af8:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100afb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b00:	83 fa 01             	cmp    $0x1,%edx
f0100b03:	19 d2                	sbb    %edx,%edx
f0100b05:	09 d0                	or     %edx,%eax
f0100b07:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b08:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b0d:	c3                   	ret    

f0100b0e <nvram_read>:
	sizeof(gdt) - 1, (unsigned long) gdt
};

static int
nvram_read(int r)
{
f0100b0e:	55                   	push   %ebp
f0100b0f:	89 e5                	mov    %esp,%ebp
f0100b11:	83 ec 18             	sub    $0x18,%esp
f0100b14:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100b17:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100b1a:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100b1c:	89 04 24             	mov    %eax,(%esp)
f0100b1f:	e8 ac 21 00 00       	call   f0102cd0 <mc146818_read>
f0100b24:	89 c6                	mov    %eax,%esi
f0100b26:	83 c3 01             	add    $0x1,%ebx
f0100b29:	89 1c 24             	mov    %ebx,(%esp)
f0100b2c:	e8 9f 21 00 00       	call   f0102cd0 <mc146818_read>
f0100b31:	c1 e0 08             	shl    $0x8,%eax
f0100b34:	09 f0                	or     %esi,%eax
}
f0100b36:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100b39:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100b3c:	89 ec                	mov    %ebp,%esp
f0100b3e:	5d                   	pop    %ebp
f0100b3f:	c3                   	ret    

f0100b40 <i386_detect_memory>:

void
i386_detect_memory(void)
{
f0100b40:	55                   	push   %ebp
f0100b41:	89 e5                	mov    %esp,%ebp
f0100b43:	83 ec 18             	sub    $0x18,%esp
	// CMOS tells us how many kilobytes there are
	basemem = ROUNDDOWN(nvram_read(NVRAM_BASELO)*1024, PGSIZE);
f0100b46:	b8 15 00 00 00       	mov    $0x15,%eax
f0100b4b:	e8 be ff ff ff       	call   f0100b0e <nvram_read>
f0100b50:	c1 e0 0a             	shl    $0xa,%eax
f0100b53:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b58:	a3 c8 65 11 f0       	mov    %eax,0xf01165c8
	extmem = ROUNDDOWN(nvram_read(NVRAM_EXTLO)*1024, PGSIZE);
f0100b5d:	b8 17 00 00 00       	mov    $0x17,%eax
f0100b62:	e8 a7 ff ff ff       	call   f0100b0e <nvram_read>
f0100b67:	c1 e0 0a             	shl    $0xa,%eax
f0100b6a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b6f:	a3 cc 65 11 f0       	mov    %eax,0xf01165cc

	// Calculate the maximum physical address based on whether
	// or not there is any extended memory.  See comment in <inc/mmu.h>.
	if (extmem)
f0100b74:	85 c0                	test   %eax,%eax
f0100b76:	74 0c                	je     f0100b84 <i386_detect_memory+0x44>
		maxpa = EXTPHYSMEM + extmem;
f0100b78:	05 00 00 10 00       	add    $0x100000,%eax
f0100b7d:	a3 d0 65 11 f0       	mov    %eax,0xf01165d0
f0100b82:	eb 0a                	jmp    f0100b8e <i386_detect_memory+0x4e>
	else
		maxpa = basemem;
f0100b84:	a1 c8 65 11 f0       	mov    0xf01165c8,%eax
f0100b89:	a3 d0 65 11 f0       	mov    %eax,0xf01165d0

	npage = maxpa / PGSIZE;
f0100b8e:	a1 d0 65 11 f0       	mov    0xf01165d0,%eax
f0100b93:	89 c2                	mov    %eax,%edx
f0100b95:	c1 ea 0c             	shr    $0xc,%edx
f0100b98:	89 15 00 6a 11 f0    	mov    %edx,0xf0116a00

	cprintf("Physical memory: %dK available, ", (int)(maxpa/1024));
f0100b9e:	c1 e8 0a             	shr    $0xa,%eax
f0100ba1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ba5:	c7 04 24 14 43 10 f0 	movl   $0xf0104314,(%esp)
f0100bac:	e8 91 21 00 00       	call   f0102d42 <cprintf>
	cprintf("base = %dK, extended = %dK\n", (int)(basemem/1024), (int)(extmem/1024));
f0100bb1:	a1 cc 65 11 f0       	mov    0xf01165cc,%eax
f0100bb6:	c1 e8 0a             	shr    $0xa,%eax
f0100bb9:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100bbd:	a1 c8 65 11 f0       	mov    0xf01165c8,%eax
f0100bc2:	c1 e8 0a             	shr    $0xa,%eax
f0100bc5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bc9:	c7 04 24 ab 48 10 f0 	movl   $0xf01048ab,(%esp)
f0100bd0:	e8 6d 21 00 00       	call   f0102d42 <cprintf>
}
f0100bd5:	c9                   	leave  
f0100bd6:	c3                   	ret    

f0100bd7 <page_init>:
	//     Some of it is in use, some is free. Where is the kernel?
	//     Which pages are used for page tables and other data structures?
	//
	// Change the code to reflect this.
	int i;
	LIST_INIT(&page_free_list);
f0100bd7:	c7 05 d8 65 11 f0 00 	movl   $0x0,0xf01165d8
f0100bde:	00 00 00 

	pages[0].pp_ref = 1;
f0100be1:	a1 0c 6a 11 f0       	mov    0xf0116a0c,%eax
f0100be6:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
	
	for (i = 1; i < npage; i++) {
f0100bec:	83 3d 00 6a 11 f0 01 	cmpl   $0x1,0xf0116a00
f0100bf3:	0f 86 ef 00 00 00    	jbe    f0100ce8 <page_init+0x111>
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100bf9:	55                   	push   %ebp
f0100bfa:	89 e5                	mov    %esp,%ebp
f0100bfc:	57                   	push   %edi
f0100bfd:	56                   	push   %esi
f0100bfe:	53                   	push   %ebx
f0100bff:	83 ec 2c             	sub    $0x2c,%esp
	for (i = 1; i < npage; i++) {
		if((i >= IOPHYSMEM /PGSIZE)&& (i< EXTPHYSMEM/PGSIZE)){
			pages[i].pp_ref = 1;
			continue;
		}
		if( (i>= EXTPHYSMEM/PGSIZE)&&(i<PADDR(boot_freemem)/PGSIZE)){
f0100c02:	8b 3d d4 65 11 f0    	mov    0xf01165d4,%edi
f0100c08:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100c0e:	c1 e8 0c             	shr    $0xc,%eax
f0100c11:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	int i;
	LIST_INIT(&page_free_list);

	pages[0].pp_ref = 1;
	
	for (i = 1; i < npage; i++) {
f0100c14:	ba 01 00 00 00       	mov    $0x1,%edx
f0100c19:	b8 01 00 00 00       	mov    $0x1,%eax
		if((i >= IOPHYSMEM /PGSIZE)&& (i< EXTPHYSMEM/PGSIZE)){
f0100c1e:	8d 8a 60 ff ff ff    	lea    -0xa0(%edx),%ecx
f0100c24:	83 f9 5f             	cmp    $0x5f,%ecx
f0100c27:	77 17                	ja     f0100c40 <page_init+0x69>
			pages[i].pp_ref = 1;
f0100c29:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100c2c:	c1 e2 02             	shl    $0x2,%edx
f0100c2f:	03 15 0c 6a 11 f0    	add    0xf0116a0c,%edx
f0100c35:	66 c7 42 08 01 00    	movw   $0x1,0x8(%edx)
			continue;
f0100c3b:	e9 90 00 00 00       	jmp    f0100cd0 <page_init+0xf9>
		}
		if( (i>= EXTPHYSMEM/PGSIZE)&&(i<PADDR(boot_freemem)/PGSIZE)){
f0100c40:	3d ff 00 00 00       	cmp    $0xff,%eax
f0100c45:	7e 41                	jle    f0100c88 <page_init+0xb1>
f0100c47:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f0100c4d:	77 20                	ja     f0100c6f <page_init+0x98>
f0100c4f:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0100c53:	c7 44 24 08 38 43 10 	movl   $0xf0104338,0x8(%esp)
f0100c5a:	f0 
f0100c5b:	c7 44 24 04 d7 01 00 	movl   $0x1d7,0x4(%esp)
f0100c62:	00 
f0100c63:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0100c6a:	e8 87 f4 ff ff       	call   f01000f6 <_panic>
f0100c6f:	39 55 e4             	cmp    %edx,-0x1c(%ebp)
f0100c72:	76 14                	jbe    f0100c88 <page_init+0xb1>
			pages[i].pp_ref = 1;
f0100c74:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100c77:	c1 e2 02             	shl    $0x2,%edx
f0100c7a:	03 15 0c 6a 11 f0    	add    0xf0116a0c,%edx
f0100c80:	66 c7 42 08 01 00    	movw   $0x1,0x8(%edx)
			continue;
f0100c86:	eb 48                	jmp    f0100cd0 <page_init+0xf9>
		}
		pages[i].pp_ref = 0;
f0100c88:	8d 34 52             	lea    (%edx,%edx,2),%esi
f0100c8b:	8d 14 b5 00 00 00 00 	lea    0x0(,%esi,4),%edx
f0100c92:	8b 1d 0c 6a 11 f0    	mov    0xf0116a0c,%ebx
f0100c98:	66 c7 44 13 08 00 00 	movw   $0x0,0x8(%ebx,%edx,1)
		LIST_INSERT_HEAD(&page_free_list, &pages[i], pp_link);
f0100c9f:	8b 0d d8 65 11 f0    	mov    0xf01165d8,%ecx
f0100ca5:	89 0c b3             	mov    %ecx,(%ebx,%esi,4)
f0100ca8:	85 c9                	test   %ecx,%ecx
f0100caa:	74 11                	je     f0100cbd <page_init+0xe6>
f0100cac:	8b 1d 0c 6a 11 f0    	mov    0xf0116a0c,%ebx
f0100cb2:	01 d3                	add    %edx,%ebx
f0100cb4:	8b 0d d8 65 11 f0    	mov    0xf01165d8,%ecx
f0100cba:	89 59 04             	mov    %ebx,0x4(%ecx)
f0100cbd:	03 15 0c 6a 11 f0    	add    0xf0116a0c,%edx
f0100cc3:	89 15 d8 65 11 f0    	mov    %edx,0xf01165d8
f0100cc9:	c7 42 04 d8 65 11 f0 	movl   $0xf01165d8,0x4(%edx)
	int i;
	LIST_INIT(&page_free_list);

	pages[0].pp_ref = 1;
	
	for (i = 1; i < npage; i++) {
f0100cd0:	83 c0 01             	add    $0x1,%eax
f0100cd3:	89 c2                	mov    %eax,%edx
f0100cd5:	3b 05 00 6a 11 f0    	cmp    0xf0116a00,%eax
f0100cdb:	0f 82 3d ff ff ff    	jb     f0100c1e <page_init+0x47>
		}
		pages[i].pp_ref = 0;
		LIST_INSERT_HEAD(&page_free_list, &pages[i], pp_link);
	}

}
f0100ce1:	83 c4 2c             	add    $0x2c,%esp
f0100ce4:	5b                   	pop    %ebx
f0100ce5:	5e                   	pop    %esi
f0100ce6:	5f                   	pop    %edi
f0100ce7:	5d                   	pop    %ebp
f0100ce8:	f3 c3                	repz ret 

f0100cea <page_alloc>:
//   -E_NO_MEM -- otherwise 
//
// Hint: use LIST_FIRST, LIST_REMOVE, and page_initpp
int
page_alloc(struct Page **pp_store)
{
f0100cea:	55                   	push   %ebp
f0100ceb:	89 e5                	mov    %esp,%ebp
f0100ced:	8b 55 08             	mov    0x8(%ebp),%edx
	// Fill this function in
	if(!LIST_FIRST(&page_free_list)){
f0100cf0:	a1 d8 65 11 f0       	mov    0xf01165d8,%eax
f0100cf5:	85 c0                	test   %eax,%eax
f0100cf7:	74 1e                	je     f0100d17 <page_alloc+0x2d>
	    return -E_NO_MEM;
    }
    else{
        *pp_store = LIST_FIRST(&page_free_list);
f0100cf9:	89 02                	mov    %eax,(%edx)
        LIST_REMOVE(*pp_store, pp_link);
f0100cfb:	8b 08                	mov    (%eax),%ecx
f0100cfd:	85 c9                	test   %ecx,%ecx
f0100cff:	74 06                	je     f0100d07 <page_alloc+0x1d>
f0100d01:	8b 40 04             	mov    0x4(%eax),%eax
f0100d04:	89 41 04             	mov    %eax,0x4(%ecx)
f0100d07:	8b 02                	mov    (%edx),%eax
f0100d09:	8b 50 04             	mov    0x4(%eax),%edx
f0100d0c:	8b 00                	mov    (%eax),%eax
f0100d0e:	89 02                	mov    %eax,(%edx)
        return 0;
f0100d10:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d15:	eb 05                	jmp    f0100d1c <page_alloc+0x32>
int
page_alloc(struct Page **pp_store)
{
	// Fill this function in
	if(!LIST_FIRST(&page_free_list)){
	    return -E_NO_MEM;
f0100d17:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    else{
        *pp_store = LIST_FIRST(&page_free_list);
        LIST_REMOVE(*pp_store, pp_link);
        return 0;
    }
}
f0100d1c:	5d                   	pop    %ebp
f0100d1d:	c3                   	ret    

f0100d1e <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0100d1e:	55                   	push   %ebp
f0100d1f:	89 e5                	mov    %esp,%ebp
f0100d21:	53                   	push   %ebx
f0100d22:	83 ec 14             	sub    $0x14,%esp
f0100d25:	8b 5d 08             	mov    0x8(%ebp),%ebx
// Note that the corresponding physical page is NOT initialized!
//
static void
page_initpp(struct Page *pp)
{
	memset(pp, 0, sizeof(*pp));
f0100d28:	c7 44 24 08 0c 00 00 	movl   $0xc,0x8(%esp)
f0100d2f:	00 
f0100d30:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100d37:	00 
f0100d38:	89 1c 24             	mov    %ebx,(%esp)
f0100d3b:	e8 64 2b 00 00       	call   f01038a4 <memset>
void
page_free(struct Page *pp)
{
	// Fill this function in
    page_initpp(pp);
 	pp->pp_ref = 0;
f0100d40:	66 c7 43 08 00 00    	movw   $0x0,0x8(%ebx)
	LIST_INSERT_HEAD(&page_free_list, pp, pp_link);
f0100d46:	a1 d8 65 11 f0       	mov    0xf01165d8,%eax
f0100d4b:	89 03                	mov    %eax,(%ebx)
f0100d4d:	85 c0                	test   %eax,%eax
f0100d4f:	74 08                	je     f0100d59 <page_free+0x3b>
f0100d51:	a1 d8 65 11 f0       	mov    0xf01165d8,%eax
f0100d56:	89 58 04             	mov    %ebx,0x4(%eax)
f0100d59:	89 1d d8 65 11 f0    	mov    %ebx,0xf01165d8
f0100d5f:	c7 43 04 d8 65 11 f0 	movl   $0xf01165d8,0x4(%ebx)
   
}
f0100d66:	83 c4 14             	add    $0x14,%esp
f0100d69:	5b                   	pop    %ebx
f0100d6a:	5d                   	pop    %ebp
f0100d6b:	c3                   	ret    

f0100d6c <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0100d6c:	55                   	push   %ebp
f0100d6d:	89 e5                	mov    %esp,%ebp
f0100d6f:	83 ec 18             	sub    $0x18,%esp
f0100d72:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100d75:	0f b7 50 08          	movzwl 0x8(%eax),%edx
f0100d79:	83 ea 01             	sub    $0x1,%edx
f0100d7c:	66 89 50 08          	mov    %dx,0x8(%eax)
f0100d80:	66 85 d2             	test   %dx,%dx
f0100d83:	75 08                	jne    f0100d8d <page_decref+0x21>
		page_free(pp);
f0100d85:	89 04 24             	mov    %eax,(%esp)
f0100d88:	e8 91 ff ff ff       	call   f0100d1e <page_free>
}
f0100d8d:	c9                   	leave  
f0100d8e:	c3                   	ret    

f0100d8f <pgdir_walk>:
// and the page table, so it's safe to leave permissions in the page
// more permissive than strictly necessaryi.

pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{  
f0100d8f:	55                   	push   %ebp
f0100d90:	89 e5                	mov    %esp,%ebp
f0100d92:	56                   	push   %esi
f0100d93:	53                   	push   %ebx
f0100d94:	83 ec 20             	sub    $0x20,%esp
f0100d97:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct Page * ss;
    pte_t *pte_addr_v;

    if(*(pgdir+PDX(va))  &&  PTE_P){
f0100d9a:	89 de                	mov    %ebx,%esi
f0100d9c:	c1 ee 16             	shr    $0x16,%esi
f0100d9f:	c1 e6 02             	shl    $0x2,%esi
f0100da2:	03 75 08             	add    0x8(%ebp),%esi
f0100da5:	8b 06                	mov    (%esi),%eax
f0100da7:	85 c0                	test   %eax,%eax
f0100da9:	74 47                	je     f0100df2 <pgdir_walk+0x63>
            pte_addr_v = (pte_t *)KADDR(PTE_ADDR(pgdir[PDX(va)]));
f0100dab:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100db0:	89 c2                	mov    %eax,%edx
f0100db2:	c1 ea 0c             	shr    $0xc,%edx
f0100db5:	3b 15 00 6a 11 f0    	cmp    0xf0116a00,%edx
f0100dbb:	72 20                	jb     f0100ddd <pgdir_walk+0x4e>
f0100dbd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100dc1:	c7 44 24 08 f0 42 10 	movl   $0xf01042f0,0x8(%esp)
f0100dc8:	f0 
f0100dc9:	c7 44 24 04 3f 02 00 	movl   $0x23f,0x4(%esp)
f0100dd0:	00 
f0100dd1:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0100dd8:	e8 19 f3 ff ff       	call   f01000f6 <_panic>
        	return  &pte_addr_v[PTX(va)];
f0100ddd:	c1 eb 0a             	shr    $0xa,%ebx
f0100de0:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0100de6:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f0100ded:	e9 ee 00 00 00       	jmp    f0100ee0 <pgdir_walk+0x151>
    }
    	else{
        if(create){
f0100df2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100df6:	0f 84 d8 00 00 00    	je     f0100ed4 <pgdir_walk+0x145>
            if( page_alloc(&ss) == 0 ){
f0100dfc:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100dff:	89 04 24             	mov    %eax,(%esp)
f0100e02:	e8 e3 fe ff ff       	call   f0100cea <page_alloc>
f0100e07:	85 c0                	test   %eax,%eax
f0100e09:	0f 85 cc 00 00 00    	jne    f0100edb <pgdir_walk+0x14c>
                ss ->pp_ref = 1;
f0100e0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100e12:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0100e18:	2b 05 0c 6a 11 f0    	sub    0xf0116a0c,%eax
f0100e1e:	c1 f8 02             	sar    $0x2,%eax
f0100e21:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0100e27:	c1 e0 0c             	shl    $0xc,%eax
                memset(KADDR(page2pa(ss)),0,PGSIZE);
f0100e2a:	89 c2                	mov    %eax,%edx
f0100e2c:	c1 ea 0c             	shr    $0xc,%edx
f0100e2f:	3b 15 00 6a 11 f0    	cmp    0xf0116a00,%edx
f0100e35:	72 20                	jb     f0100e57 <pgdir_walk+0xc8>
f0100e37:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e3b:	c7 44 24 08 f0 42 10 	movl   $0xf01042f0,0x8(%esp)
f0100e42:	f0 
f0100e43:	c7 44 24 04 46 02 00 	movl   $0x246,0x4(%esp)
f0100e4a:	00 
f0100e4b:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0100e52:	e8 9f f2 ff ff       	call   f01000f6 <_panic>
f0100e57:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100e5e:	00 
f0100e5f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100e66:	00 
f0100e67:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e6c:	89 04 24             	mov    %eax,(%esp)
f0100e6f:	e8 30 2a 00 00       	call   f01038a4 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0100e74:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100e77:	2b 05 0c 6a 11 f0    	sub    0xf0116a0c,%eax
f0100e7d:	c1 f8 02             	sar    $0x2,%eax
f0100e80:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0100e86:	c1 e0 0c             	shl    $0xc,%eax
                pgdir[PDX(va)] = page2pa(ss) | PTE_U|PTE_W|PTE_P;
f0100e89:	89 c2                	mov    %eax,%edx
f0100e8b:	83 ca 07             	or     $0x7,%edx
f0100e8e:	89 16                	mov    %edx,(%esi)
                pte_addr_v = (pte_t*)KADDR(PTE_ADDR(pgdir[PDX(va)]));
f0100e90:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100e95:	89 c2                	mov    %eax,%edx
f0100e97:	c1 ea 0c             	shr    $0xc,%edx
f0100e9a:	3b 15 00 6a 11 f0    	cmp    0xf0116a00,%edx
f0100ea0:	72 20                	jb     f0100ec2 <pgdir_walk+0x133>
f0100ea2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ea6:	c7 44 24 08 f0 42 10 	movl   $0xf01042f0,0x8(%esp)
f0100ead:	f0 
f0100eae:	c7 44 24 04 48 02 00 	movl   $0x248,0x4(%esp)
f0100eb5:	00 
f0100eb6:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0100ebd:	e8 34 f2 ff ff       	call   f01000f6 <_panic>
                return &pte_addr_v[PTX(va)];
f0100ec2:	c1 eb 0a             	shr    $0xa,%ebx
f0100ec5:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0100ecb:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f0100ed2:	eb 0c                	jmp    f0100ee0 <pgdir_walk+0x151>
            }
            else
                return NULL;
        }
        else
            return NULL;
f0100ed4:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ed9:	eb 05                	jmp    f0100ee0 <pgdir_walk+0x151>
                pgdir[PDX(va)] = page2pa(ss) | PTE_U|PTE_W|PTE_P;
                pte_addr_v = (pte_t*)KADDR(PTE_ADDR(pgdir[PDX(va)]));
                return &pte_addr_v[PTX(va)];
            }
            else
                return NULL;
f0100edb:	b8 00 00 00 00       	mov    $0x0,%eax
        }
        else
            return NULL;
    }
}
f0100ee0:	83 c4 20             	add    $0x20,%esp
f0100ee3:	5b                   	pop    %ebx
f0100ee4:	5e                   	pop    %esi
f0100ee5:	5d                   	pop    %ebp
f0100ee6:	c3                   	ret    

f0100ee7 <boot_map_segment>:
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, physaddr_t pa, 
					int perm)
{
f0100ee7:	55                   	push   %ebp
f0100ee8:	89 e5                	mov    %esp,%ebp
f0100eea:	57                   	push   %edi
f0100eeb:	56                   	push   %esi
f0100eec:	53                   	push   %ebx
f0100eed:	83 ec 2c             	sub    $0x2c,%esp
f0100ef0:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	uint32_t i ;
	pte_t * pte;
	for(i = 0 ; i <  size ; i += PGSIZE) {
f0100ef3:	85 c9                	test   %ecx,%ecx
f0100ef5:	74 4c                	je     f0100f43 <boot_map_segment+0x5c>
f0100ef7:	89 c7                	mov    %eax,%edi
f0100ef9:	89 d3                	mov    %edx,%ebx
f0100efb:	be 00 00 00 00       	mov    $0x0,%esi
		pte = pgdir_walk(pgdir, (void *)(la + i), 1) ;
		*pte = (pa + i) | perm | PTE_P ;
f0100f00:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f03:	83 c8 01             	or     $0x1,%eax
f0100f06:	89 45 e0             	mov    %eax,-0x20(%ebp)
{
	// Fill this function in
	uint32_t i ;
	pte_t * pte;
	for(i = 0 ; i <  size ; i += PGSIZE) {
		pte = pgdir_walk(pgdir, (void *)(la + i), 1) ;
f0100f09:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0100f10:	00 
f0100f11:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f15:	89 3c 24             	mov    %edi,(%esp)
f0100f18:	e8 72 fe ff ff       	call   f0100d8f <pgdir_walk>
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, physaddr_t pa, 
f0100f1d:	8b 55 08             	mov    0x8(%ebp),%edx
f0100f20:	01 f2                	add    %esi,%edx
	// Fill this function in
	uint32_t i ;
	pte_t * pte;
	for(i = 0 ; i <  size ; i += PGSIZE) {
		pte = pgdir_walk(pgdir, (void *)(la + i), 1) ;
		*pte = (pa + i) | perm | PTE_P ;
f0100f22:	0b 55 e0             	or     -0x20(%ebp),%edx
f0100f25:	89 10                	mov    %edx,(%eax)
		pgdir[PDX(la + i)] |= perm ;
f0100f27:	89 d8                	mov    %ebx,%eax
f0100f29:	c1 e8 16             	shr    $0x16,%eax
f0100f2c:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100f2f:	09 14 87             	or     %edx,(%edi,%eax,4)
					int perm)
{
	// Fill this function in
	uint32_t i ;
	pte_t * pte;
	for(i = 0 ; i <  size ; i += PGSIZE) {
f0100f32:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100f38:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f3e:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
f0100f41:	77 c6                	ja     f0100f09 <boot_map_segment+0x22>
		pte = pgdir_walk(pgdir, (void *)(la + i), 1) ;
		*pte = (pa + i) | perm | PTE_P ;
		pgdir[PDX(la + i)] |= perm ;
	}
}
f0100f43:	83 c4 2c             	add    $0x2c,%esp
f0100f46:	5b                   	pop    %ebx
f0100f47:	5e                   	pop    %esi
f0100f48:	5f                   	pop    %edi
f0100f49:	5d                   	pop    %ebp
f0100f4a:	c3                   	ret    

f0100f4b <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f4b:	55                   	push   %ebp
f0100f4c:	89 e5                	mov    %esp,%ebp
f0100f4e:	53                   	push   %ebx
f0100f4f:	83 ec 14             	sub    $0x14,%esp
f0100f52:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t * pte_addr_v;

    pte_addr_v = pgdir_walk(pgdir,va, 0);
f0100f55:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100f5c:	00 
f0100f5d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f60:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f64:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f67:	89 04 24             	mov    %eax,(%esp)
f0100f6a:	e8 20 fe ff ff       	call   f0100d8f <pgdir_walk>
    
    if(!pte_addr_v) 
f0100f6f:	85 c0                	test   %eax,%eax
f0100f71:	74 3c                	je     f0100faf <page_lookup+0x64>
        return 0;
    if(pte_store != NULL)
f0100f73:	85 db                	test   %ebx,%ebx
f0100f75:	74 02                	je     f0100f79 <page_lookup+0x2e>
            *pte_store = pte_addr_v;
f0100f77:	89 03                	mov    %eax,(%ebx)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PPN(pa) >= npage)
f0100f79:	8b 00                	mov    (%eax),%eax
f0100f7b:	c1 e8 0c             	shr    $0xc,%eax
f0100f7e:	3b 05 00 6a 11 f0    	cmp    0xf0116a00,%eax
f0100f84:	72 1c                	jb     f0100fa2 <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f0100f86:	c7 44 24 08 5c 43 10 	movl   $0xf010435c,0x8(%esp)
f0100f8d:	f0 
f0100f8e:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0100f95:	00 
f0100f96:	c7 04 24 c7 48 10 f0 	movl   $0xf01048c7,(%esp)
f0100f9d:	e8 54 f1 ff ff       	call   f01000f6 <_panic>
	return &pages[PPN(pa)];
f0100fa2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100fa5:	a1 0c 6a 11 f0       	mov    0xf0116a0c,%eax
f0100faa:	8d 04 90             	lea    (%eax,%edx,4),%eax
    return pa2page(*pte_addr_v);
f0100fad:	eb 05                	jmp    f0100fb4 <page_lookup+0x69>
	pte_t * pte_addr_v;

    pte_addr_v = pgdir_walk(pgdir,va, 0);
    
    if(!pte_addr_v) 
        return 0;
f0100faf:	b8 00 00 00 00       	mov    $0x0,%eax
    if(pte_store != NULL)
            *pte_store = pte_addr_v;
    return pa2page(*pte_addr_v);
}
f0100fb4:	83 c4 14             	add    $0x14,%esp
f0100fb7:	5b                   	pop    %ebx
f0100fb8:	5d                   	pop    %ebp
f0100fb9:	c3                   	ret    

f0100fba <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100fba:	55                   	push   %ebp
f0100fbb:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100fbd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fc0:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0100fc3:	5d                   	pop    %ebp
f0100fc4:	c3                   	ret    

f0100fc5 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100fc5:	55                   	push   %ebp
f0100fc6:	89 e5                	mov    %esp,%ebp
f0100fc8:	83 ec 28             	sub    $0x28,%esp
f0100fcb:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100fce:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100fd1:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100fd4:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
    pte_t *pte_addr_v;
    struct Page *pg;
    pg=page_lookup(pgdir,va,&pte_addr_v);
f0100fd7:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100fda:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100fde:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100fe2:	89 1c 24             	mov    %ebx,(%esp)
f0100fe5:	e8 61 ff ff ff       	call   f0100f4b <page_lookup>
    if(!pg)
f0100fea:	85 c0                	test   %eax,%eax
f0100fec:	74 21                	je     f010100f <page_remove+0x4a>
        return;
    else
        page_decref(pg);
f0100fee:	89 04 24             	mov    %eax,(%esp)
f0100ff1:	e8 76 fd ff ff       	call   f0100d6c <page_decref>

    if(pte_addr_v)
f0100ff6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100ff9:	85 c0                	test   %eax,%eax
f0100ffb:	74 06                	je     f0101003 <page_remove+0x3e>
        *pte_addr_v = 0;
f0100ffd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    tlb_invalidate(pgdir,va);     
f0101003:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101007:	89 1c 24             	mov    %ebx,(%esp)
f010100a:	e8 ab ff ff ff       	call   f0100fba <tlb_invalidate>

}
f010100f:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0101012:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0101015:	89 ec                	mov    %ebp,%esp
f0101017:	5d                   	pop    %ebp
f0101018:	c3                   	ret    

f0101019 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm) 
{
f0101019:	55                   	push   %ebp
f010101a:	89 e5                	mov    %esp,%ebp
f010101c:	83 ec 28             	sub    $0x28,%esp
f010101f:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0101022:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101025:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101028:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010102b:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010102e:	8b 75 10             	mov    0x10(%ebp),%esi
	// Fill this function in
	pte_t * pte = pgdir_walk(pgdir, va, 0) ;
f0101031:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101038:	00 
f0101039:	89 74 24 04          	mov    %esi,0x4(%esp)
f010103d:	89 1c 24             	mov    %ebx,(%esp)
f0101040:	e8 4a fd ff ff       	call   f0100d8f <pgdir_walk>
	// Increment ref-count here so that we cannot accidentally 
	// free a page that's mapped again to the same virtual address
	pp->pp_ref++;
f0101045:	66 83 47 08 01       	addw   $0x1,0x8(%edi)
	// If there is already a page mapped at 'va', it should be page_remove()d.
	if (pte && (*pte & PTE_P))
f010104a:	85 c0                	test   %eax,%eax
f010104c:	74 11                	je     f010105f <page_insert+0x46>
f010104e:	f6 00 01             	testb  $0x1,(%eax)
f0101051:	74 0c                	je     f010105f <page_insert+0x46>
		page_remove(pgdir, va) ;
f0101053:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101057:	89 1c 24             	mov    %ebx,(%esp)
f010105a:	e8 66 ff ff ff       	call   f0100fc5 <page_remove>
	
	pte = pgdir_walk(pgdir, va, 1) ;
f010105f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101066:	00 
f0101067:	89 74 24 04          	mov    %esi,0x4(%esp)
f010106b:	89 1c 24             	mov    %ebx,(%esp)
f010106e:	e8 1c fd ff ff       	call   f0100d8f <pgdir_walk>
	
	if (pte) {
f0101073:	85 c0                	test   %eax,%eax
f0101075:	74 2c                	je     f01010a3 <page_insert+0x8a>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101077:	2b 3d 0c 6a 11 f0    	sub    0xf0116a0c,%edi
f010107d:	c1 ff 02             	sar    $0x2,%edi
f0101080:	69 ff ab aa aa aa    	imul   $0xaaaaaaab,%edi,%edi
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101086:	c1 e7 0c             	shl    $0xc,%edi
		*pte = page2pa(pp) | perm | PTE_P ;
f0101089:	8b 55 14             	mov    0x14(%ebp),%edx
f010108c:	83 ca 01             	or     $0x1,%edx
f010108f:	09 d7                	or     %edx,%edi
f0101091:	89 38                	mov    %edi,(%eax)
		pgdir[PDX(va)] |= perm ;
f0101093:	c1 ee 16             	shr    $0x16,%esi
f0101096:	8b 45 14             	mov    0x14(%ebp),%eax
f0101099:	09 04 b3             	or     %eax,(%ebx,%esi,4)
		return 0 ;
f010109c:	b8 00 00 00 00       	mov    $0x0,%eax
f01010a1:	eb 0a                	jmp    f01010ad <page_insert+0x94>
	}
	
	--(pp->pp_ref) ;
f01010a3:	66 83 6f 08 01       	subw   $0x1,0x8(%edi)
	return -E_NO_MEM ;
f01010a8:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f01010ad:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01010b0:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01010b3:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01010b6:	89 ec                	mov    %ebp,%esp
f01010b8:	5d                   	pop    %ebp
f01010b9:	c3                   	ret    

f01010ba <i386_vm_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read (or write). 
void
i386_vm_init(void)
{
f01010ba:	55                   	push   %ebp
f01010bb:	89 e5                	mov    %esp,%ebp
f01010bd:	57                   	push   %edi
f01010be:	56                   	push   %esi
f01010bf:	53                   	push   %ebx
f01010c0:	83 ec 5c             	sub    $0x5c,%esp
	// Delete this line:
	// panic("i386_vm_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	pgdir = boot_alloc(PGSIZE, PGSIZE);
f01010c3:	ba 00 10 00 00       	mov    $0x1000,%edx
f01010c8:	b8 00 10 00 00       	mov    $0x1000,%eax
f01010cd:	e8 6e f9 ff ff       	call   f0100a40 <boot_alloc>
f01010d2:	89 45 bc             	mov    %eax,-0x44(%ebp)
	memset(pgdir, 0, PGSIZE);
f01010d5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01010dc:	00 
f01010dd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01010e4:	00 
f01010e5:	89 04 24             	mov    %eax,(%esp)
f01010e8:	e8 b7 27 00 00       	call   f01038a4 <memset>
	boot_pgdir = pgdir;
f01010ed:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01010f0:	a3 08 6a 11 f0       	mov    %eax,0xf0116a08
	boot_cr3 = PADDR(pgdir);
f01010f5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01010fa:	77 20                	ja     f010111c <i386_vm_init+0x62>
f01010fc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101100:	c7 44 24 08 38 43 10 	movl   $0xf0104338,0x8(%esp)
f0101107:	f0 
f0101108:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
f010110f:	00 
f0101110:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101117:	e8 da ef ff ff       	call   f01000f6 <_panic>
f010111c:	8b 45 bc             	mov    -0x44(%ebp),%eax
f010111f:	05 00 00 00 10       	add    $0x10000000,%eax
f0101124:	a3 04 6a 11 f0       	mov    %eax,0xf0116a04
	// a virtual page table at virtual address VPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel RW, user NONE
	pgdir[PDX(VPT)] = PADDR(pgdir)|PTE_W|PTE_P;
f0101129:	89 c2                	mov    %eax,%edx
f010112b:	83 ca 03             	or     $0x3,%edx
f010112e:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0101131:	89 91 fc 0e 00 00    	mov    %edx,0xefc(%ecx)

	// same for UVPT
	// Permissions: kernel R, user R 
	pgdir[PDX(UVPT)] = PADDR(pgdir)|PTE_U|PTE_P;
f0101137:	83 c8 05             	or     $0x5,%eax
f010113a:	89 81 f4 0e 00 00    	mov    %eax,0xef4(%ecx)
	// array.  'npage' is the number of physical pages in memory.
	// User-level programs will get read-only access to the array as well.
	// Your code goes here:
	
	// in bytes
	n = npage * sizeof (struct Page) ;
f0101140:	a1 00 6a 11 f0       	mov    0xf0116a00,%eax
f0101145:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0101148:	c1 e0 02             	shl    $0x2,%eax
f010114b:	89 45 b8             	mov    %eax,-0x48(%ebp)
	// allocate the pages
	pages = (struct Page *)boot_alloc(n, PGSIZE) ;
f010114e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101153:	e8 e8 f8 ff ff       	call   f0100a40 <boot_alloc>
f0101158:	a3 0c 6a 11 f0       	mov    %eax,0xf0116a0c
	//////////////////////////////////////////////////////////////////////
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_segment or page_insert
	page_init();
f010115d:	e8 75 fa ff ff       	call   f0100bd7 <page_init>
	struct Page_list fl;

	// if there's a page that shouldn't be on
	// the free list, try to make sure it
	// eventually causes trouble.
	LIST_FOREACH(pp0, &page_free_list, pp_link)
f0101162:	a1 d8 65 11 f0       	mov    0xf01165d8,%eax
f0101167:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010116a:	85 c0                	test   %eax,%eax
f010116c:	0f 84 89 00 00 00    	je     f01011fb <i386_vm_init+0x141>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101172:	2b 05 0c 6a 11 f0    	sub    0xf0116a0c,%eax
f0101178:	c1 f8 02             	sar    $0x2,%eax
f010117b:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101181:	c1 e0 0c             	shl    $0xc,%eax
}

static inline void*
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
f0101184:	89 c2                	mov    %eax,%edx
f0101186:	c1 ea 0c             	shr    $0xc,%edx
f0101189:	3b 15 00 6a 11 f0    	cmp    0xf0116a00,%edx
f010118f:	72 41                	jb     f01011d2 <i386_vm_init+0x118>
f0101191:	eb 1f                	jmp    f01011b2 <i386_vm_init+0xf8>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101193:	2b 05 0c 6a 11 f0    	sub    0xf0116a0c,%eax
f0101199:	c1 f8 02             	sar    $0x2,%eax
f010119c:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f01011a2:	c1 e0 0c             	shl    $0xc,%eax
}

static inline void*
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
f01011a5:	89 c2                	mov    %eax,%edx
f01011a7:	c1 ea 0c             	shr    $0xc,%edx
f01011aa:	3b 15 00 6a 11 f0    	cmp    0xf0116a00,%edx
f01011b0:	72 20                	jb     f01011d2 <i386_vm_init+0x118>
f01011b2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011b6:	c7 44 24 08 f0 42 10 	movl   $0xf01042f0,0x8(%esp)
f01011bd:	f0 
f01011be:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01011c5:	00 
f01011c6:	c7 04 24 c7 48 10 f0 	movl   $0xf01048c7,(%esp)
f01011cd:	e8 24 ef ff ff       	call   f01000f6 <_panic>
		memset(page2kva(pp0), 0x97, 128);
f01011d2:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f01011d9:	00 
f01011da:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f01011e1:	00 
f01011e2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01011e7:	89 04 24             	mov    %eax,(%esp)
f01011ea:	e8 b5 26 00 00       	call   f01038a4 <memset>
	struct Page_list fl;

	// if there's a page that shouldn't be on
	// the free list, try to make sure it
	// eventually causes trouble.
	LIST_FOREACH(pp0, &page_free_list, pp_link)
f01011ef:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01011f2:	8b 00                	mov    (%eax),%eax
f01011f4:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01011f7:	85 c0                	test   %eax,%eax
f01011f9:	75 98                	jne    f0101193 <i386_vm_init+0xd9>
		memset(page2kva(pp0), 0x97, 128);

	LIST_FOREACH(pp0, &page_free_list, pp_link) {
f01011fb:	a1 d8 65 11 f0       	mov    0xf01165d8,%eax
f0101200:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101203:	85 c0                	test   %eax,%eax
f0101205:	0f 84 d6 01 00 00    	je     f01013e1 <i386_vm_init+0x327>
		// check that we didn't corrupt the free list itself
		assert(pp0 >= pages);
f010120b:	8b 1d 0c 6a 11 f0    	mov    0xf0116a0c,%ebx
f0101211:	39 c3                	cmp    %eax,%ebx
f0101213:	77 4f                	ja     f0101264 <i386_vm_init+0x1aa>
		assert(pp0 < pages + npage);
f0101215:	8b 35 00 6a 11 f0    	mov    0xf0116a00,%esi
f010121b:	8d 14 76             	lea    (%esi,%esi,2),%edx
f010121e:	8d 14 93             	lea    (%ebx,%edx,4),%edx
f0101221:	89 55 c0             	mov    %edx,-0x40(%ebp)
f0101224:	39 d0                	cmp    %edx,%eax
f0101226:	73 65                	jae    f010128d <i386_vm_init+0x1d3>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101228:	89 5d c4             	mov    %ebx,-0x3c(%ebp)
f010122b:	89 c2                	mov    %eax,%edx
f010122d:	29 da                	sub    %ebx,%edx
f010122f:	c1 fa 02             	sar    $0x2,%edx
f0101232:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101238:	c1 e2 0c             	shl    $0xc,%edx

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp0) != 0);
f010123b:	85 d2                	test   %edx,%edx
f010123d:	0f 84 83 00 00 00    	je     f01012c6 <i386_vm_init+0x20c>
		assert(page2pa(pp0) != IOPHYSMEM);
f0101243:	81 fa 00 00 0a 00    	cmp    $0xa0000,%edx
f0101249:	0f 84 a3 00 00 00    	je     f01012f2 <i386_vm_init+0x238>
		assert(page2pa(pp0) != EXTPHYSMEM - PGSIZE);
f010124f:	81 fa 00 f0 0f 00    	cmp    $0xff000,%edx
f0101255:	0f 85 e7 00 00 00    	jne    f0101342 <i386_vm_init+0x288>
f010125b:	e9 be 00 00 00       	jmp    f010131e <i386_vm_init+0x264>
	LIST_FOREACH(pp0, &page_free_list, pp_link)
		memset(page2kva(pp0), 0x97, 128);

	LIST_FOREACH(pp0, &page_free_list, pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp0 >= pages);
f0101260:	39 c3                	cmp    %eax,%ebx
f0101262:	76 24                	jbe    f0101288 <i386_vm_init+0x1ce>
f0101264:	c7 44 24 0c d5 48 10 	movl   $0xf01048d5,0xc(%esp)
f010126b:	f0 
f010126c:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101273:	f0 
f0101274:	c7 44 24 04 32 01 00 	movl   $0x132,0x4(%esp)
f010127b:	00 
f010127c:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101283:	e8 6e ee ff ff       	call   f01000f6 <_panic>
		assert(pp0 < pages + npage);
f0101288:	3b 45 c0             	cmp    -0x40(%ebp),%eax
f010128b:	72 24                	jb     f01012b1 <i386_vm_init+0x1f7>
f010128d:	c7 44 24 0c f7 48 10 	movl   $0xf01048f7,0xc(%esp)
f0101294:	f0 
f0101295:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f010129c:	f0 
f010129d:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
f01012a4:	00 
f01012a5:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01012ac:	e8 45 ee ff ff       	call   f01000f6 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f01012b1:	89 c2                	mov    %eax,%edx
f01012b3:	2b 55 c4             	sub    -0x3c(%ebp),%edx
f01012b6:	c1 fa 02             	sar    $0x2,%edx
f01012b9:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f01012bf:	c1 e2 0c             	shl    $0xc,%edx

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp0) != 0);
f01012c2:	85 d2                	test   %edx,%edx
f01012c4:	75 24                	jne    f01012ea <i386_vm_init+0x230>
f01012c6:	c7 44 24 0c 0b 49 10 	movl   $0xf010490b,0xc(%esp)
f01012cd:	f0 
f01012ce:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f01012d5:	f0 
f01012d6:	c7 44 24 04 36 01 00 	movl   $0x136,0x4(%esp)
f01012dd:	00 
f01012de:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01012e5:	e8 0c ee ff ff       	call   f01000f6 <_panic>
		assert(page2pa(pp0) != IOPHYSMEM);
f01012ea:	81 fa 00 00 0a 00    	cmp    $0xa0000,%edx
f01012f0:	75 24                	jne    f0101316 <i386_vm_init+0x25c>
f01012f2:	c7 44 24 0c 1d 49 10 	movl   $0xf010491d,0xc(%esp)
f01012f9:	f0 
f01012fa:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101301:	f0 
f0101302:	c7 44 24 04 37 01 00 	movl   $0x137,0x4(%esp)
f0101309:	00 
f010130a:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101311:	e8 e0 ed ff ff       	call   f01000f6 <_panic>
		assert(page2pa(pp0) != EXTPHYSMEM - PGSIZE);
f0101316:	81 fa 00 f0 0f 00    	cmp    $0xff000,%edx
f010131c:	75 33                	jne    f0101351 <i386_vm_init+0x297>
f010131e:	c7 44 24 0c 7c 43 10 	movl   $0xf010437c,0xc(%esp)
f0101325:	f0 
f0101326:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f010132d:	f0 
f010132e:	c7 44 24 04 38 01 00 	movl   $0x138,0x4(%esp)
f0101335:	00 
f0101336:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f010133d:	e8 b4 ed ff ff       	call   f01000f6 <_panic>
		assert(page2pa(pp0) != EXTPHYSMEM);
		assert(page2kva(pp0) != ROUNDDOWN(boot_freemem - 1, PGSIZE));
f0101342:	8b 3d d4 65 11 f0    	mov    0xf01165d4,%edi
f0101348:	83 ef 01             	sub    $0x1,%edi
f010134b:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp0) != 0);
		assert(page2pa(pp0) != IOPHYSMEM);
		assert(page2pa(pp0) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp0) != EXTPHYSMEM);
f0101351:	81 fa 00 00 10 00    	cmp    $0x100000,%edx
f0101357:	75 24                	jne    f010137d <i386_vm_init+0x2c3>
f0101359:	c7 44 24 0c 37 49 10 	movl   $0xf0104937,0xc(%esp)
f0101360:	f0 
f0101361:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101368:	f0 
f0101369:	c7 44 24 04 39 01 00 	movl   $0x139,0x4(%esp)
f0101370:	00 
f0101371:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101378:	e8 79 ed ff ff       	call   f01000f6 <_panic>
}

static inline void*
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
f010137d:	89 d1                	mov    %edx,%ecx
f010137f:	c1 e9 0c             	shr    $0xc,%ecx
f0101382:	39 f1                	cmp    %esi,%ecx
f0101384:	72 20                	jb     f01013a6 <i386_vm_init+0x2ec>
f0101386:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010138a:	c7 44 24 08 f0 42 10 	movl   $0xf01042f0,0x8(%esp)
f0101391:	f0 
f0101392:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101399:	00 
f010139a:	c7 04 24 c7 48 10 f0 	movl   $0xf01048c7,(%esp)
f01013a1:	e8 50 ed ff ff       	call   f01000f6 <_panic>
f01013a6:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
		assert(page2kva(pp0) != ROUNDDOWN(boot_freemem - 1, PGSIZE));
f01013ac:	39 d7                	cmp    %edx,%edi
f01013ae:	75 24                	jne    f01013d4 <i386_vm_init+0x31a>
f01013b0:	c7 44 24 0c a0 43 10 	movl   $0xf01043a0,0xc(%esp)
f01013b7:	f0 
f01013b8:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f01013bf:	f0 
f01013c0:	c7 44 24 04 3a 01 00 	movl   $0x13a,0x4(%esp)
f01013c7:	00 
f01013c8:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01013cf:	e8 22 ed ff ff       	call   f01000f6 <_panic>
	// the free list, try to make sure it
	// eventually causes trouble.
	LIST_FOREACH(pp0, &page_free_list, pp_link)
		memset(page2kva(pp0), 0x97, 128);

	LIST_FOREACH(pp0, &page_free_list, pp_link) {
f01013d4:	8b 00                	mov    (%eax),%eax
f01013d6:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01013d9:	85 c0                	test   %eax,%eax
f01013db:	0f 85 7f fe ff ff    	jne    f0101260 <i386_vm_init+0x1a6>
		assert(page2pa(pp0) != EXTPHYSMEM);
		assert(page2kva(pp0) != ROUNDDOWN(boot_freemem - 1, PGSIZE));
	}

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
f01013e1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01013e8:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01013ef:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	assert(page_alloc(&pp0) == 0);
f01013f6:	8d 45 dc             	lea    -0x24(%ebp),%eax
f01013f9:	89 04 24             	mov    %eax,(%esp)
f01013fc:	e8 e9 f8 ff ff       	call   f0100cea <page_alloc>
f0101401:	85 c0                	test   %eax,%eax
f0101403:	74 24                	je     f0101429 <i386_vm_init+0x36f>
f0101405:	c7 44 24 0c 52 49 10 	movl   $0xf0104952,0xc(%esp)
f010140c:	f0 
f010140d:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101414:	f0 
f0101415:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
f010141c:	00 
f010141d:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101424:	e8 cd ec ff ff       	call   f01000f6 <_panic>
	assert(page_alloc(&pp1) == 0);
f0101429:	8d 45 e0             	lea    -0x20(%ebp),%eax
f010142c:	89 04 24             	mov    %eax,(%esp)
f010142f:	e8 b6 f8 ff ff       	call   f0100cea <page_alloc>
f0101434:	85 c0                	test   %eax,%eax
f0101436:	74 24                	je     f010145c <i386_vm_init+0x3a2>
f0101438:	c7 44 24 0c 68 49 10 	movl   $0xf0104968,0xc(%esp)
f010143f:	f0 
f0101440:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101447:	f0 
f0101448:	c7 44 24 04 40 01 00 	movl   $0x140,0x4(%esp)
f010144f:	00 
f0101450:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101457:	e8 9a ec ff ff       	call   f01000f6 <_panic>
	assert(page_alloc(&pp2) == 0);
f010145c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010145f:	89 04 24             	mov    %eax,(%esp)
f0101462:	e8 83 f8 ff ff       	call   f0100cea <page_alloc>
f0101467:	85 c0                	test   %eax,%eax
f0101469:	74 24                	je     f010148f <i386_vm_init+0x3d5>
f010146b:	c7 44 24 0c 7e 49 10 	movl   $0xf010497e,0xc(%esp)
f0101472:	f0 
f0101473:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f010147a:	f0 
f010147b:	c7 44 24 04 41 01 00 	movl   $0x141,0x4(%esp)
f0101482:	00 
f0101483:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f010148a:	e8 67 ec ff ff       	call   f01000f6 <_panic>

	assert(pp0);
f010148f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101492:	85 c9                	test   %ecx,%ecx
f0101494:	75 24                	jne    f01014ba <i386_vm_init+0x400>
f0101496:	c7 44 24 0c a2 49 10 	movl   $0xf01049a2,0xc(%esp)
f010149d:	f0 
f010149e:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f01014a5:	f0 
f01014a6:	c7 44 24 04 43 01 00 	movl   $0x143,0x4(%esp)
f01014ad:	00 
f01014ae:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01014b5:	e8 3c ec ff ff       	call   f01000f6 <_panic>
	assert(pp1 && pp1 != pp0);
f01014ba:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01014bd:	85 d2                	test   %edx,%edx
f01014bf:	74 04                	je     f01014c5 <i386_vm_init+0x40b>
f01014c1:	39 d1                	cmp    %edx,%ecx
f01014c3:	75 24                	jne    f01014e9 <i386_vm_init+0x42f>
f01014c5:	c7 44 24 0c 94 49 10 	movl   $0xf0104994,0xc(%esp)
f01014cc:	f0 
f01014cd:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f01014d4:	f0 
f01014d5:	c7 44 24 04 44 01 00 	movl   $0x144,0x4(%esp)
f01014dc:	00 
f01014dd:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01014e4:	e8 0d ec ff ff       	call   f01000f6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014e9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01014ec:	85 c0                	test   %eax,%eax
f01014ee:	74 08                	je     f01014f8 <i386_vm_init+0x43e>
f01014f0:	39 c2                	cmp    %eax,%edx
f01014f2:	74 04                	je     f01014f8 <i386_vm_init+0x43e>
f01014f4:	39 c1                	cmp    %eax,%ecx
f01014f6:	75 24                	jne    f010151c <i386_vm_init+0x462>
f01014f8:	c7 44 24 0c d8 43 10 	movl   $0xf01043d8,0xc(%esp)
f01014ff:	f0 
f0101500:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101507:	f0 
f0101508:	c7 44 24 04 45 01 00 	movl   $0x145,0x4(%esp)
f010150f:	00 
f0101510:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101517:	e8 da eb ff ff       	call   f01000f6 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f010151c:	8b 35 0c 6a 11 f0    	mov    0xf0116a0c,%esi
	assert(page2pa(pp0) < npage*PGSIZE);
f0101522:	8b 1d 00 6a 11 f0    	mov    0xf0116a00,%ebx
f0101528:	c1 e3 0c             	shl    $0xc,%ebx
f010152b:	29 f1                	sub    %esi,%ecx
f010152d:	c1 f9 02             	sar    $0x2,%ecx
f0101530:	69 c9 ab aa aa aa    	imul   $0xaaaaaaab,%ecx,%ecx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101536:	c1 e1 0c             	shl    $0xc,%ecx
f0101539:	39 d9                	cmp    %ebx,%ecx
f010153b:	72 24                	jb     f0101561 <i386_vm_init+0x4a7>
f010153d:	c7 44 24 0c a6 49 10 	movl   $0xf01049a6,0xc(%esp)
f0101544:	f0 
f0101545:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f010154c:	f0 
f010154d:	c7 44 24 04 46 01 00 	movl   $0x146,0x4(%esp)
f0101554:	00 
f0101555:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f010155c:	e8 95 eb ff ff       	call   f01000f6 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101561:	29 f2                	sub    %esi,%edx
f0101563:	c1 fa 02             	sar    $0x2,%edx
f0101566:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f010156c:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp1) < npage*PGSIZE);
f010156f:	39 d3                	cmp    %edx,%ebx
f0101571:	77 24                	ja     f0101597 <i386_vm_init+0x4dd>
f0101573:	c7 44 24 0c c2 49 10 	movl   $0xf01049c2,0xc(%esp)
f010157a:	f0 
f010157b:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101582:	f0 
f0101583:	c7 44 24 04 47 01 00 	movl   $0x147,0x4(%esp)
f010158a:	00 
f010158b:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101592:	e8 5f eb ff ff       	call   f01000f6 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101597:	29 f0                	sub    %esi,%eax
f0101599:	c1 f8 02             	sar    $0x2,%eax
f010159c:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f01015a2:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npage*PGSIZE);
f01015a5:	39 c3                	cmp    %eax,%ebx
f01015a7:	77 24                	ja     f01015cd <i386_vm_init+0x513>
f01015a9:	c7 44 24 0c de 49 10 	movl   $0xf01049de,0xc(%esp)
f01015b0:	f0 
f01015b1:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f01015b8:	f0 
f01015b9:	c7 44 24 04 48 01 00 	movl   $0x148,0x4(%esp)
f01015c0:	00 
f01015c1:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01015c8:	e8 29 eb ff ff       	call   f01000f6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01015cd:	8b 1d d8 65 11 f0    	mov    0xf01165d8,%ebx
	LIST_INIT(&page_free_list);
f01015d3:	c7 05 d8 65 11 f0 00 	movl   $0x0,0xf01165d8
f01015da:	00 00 00 

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);
f01015dd:	8d 45 d8             	lea    -0x28(%ebp),%eax
f01015e0:	89 04 24             	mov    %eax,(%esp)
f01015e3:	e8 02 f7 ff ff       	call   f0100cea <page_alloc>
f01015e8:	83 f8 fc             	cmp    $0xfffffffc,%eax
f01015eb:	74 24                	je     f0101611 <i386_vm_init+0x557>
f01015ed:	c7 44 24 0c fa 49 10 	movl   $0xf01049fa,0xc(%esp)
f01015f4:	f0 
f01015f5:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f01015fc:	f0 
f01015fd:	c7 44 24 04 4f 01 00 	movl   $0x14f,0x4(%esp)
f0101604:	00 
f0101605:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f010160c:	e8 e5 ea ff ff       	call   f01000f6 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101611:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101614:	89 04 24             	mov    %eax,(%esp)
f0101617:	e8 02 f7 ff ff       	call   f0100d1e <page_free>
	page_free(pp1);
f010161c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010161f:	89 04 24             	mov    %eax,(%esp)
f0101622:	e8 f7 f6 ff ff       	call   f0100d1e <page_free>
	page_free(pp2);
f0101627:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010162a:	89 04 24             	mov    %eax,(%esp)
f010162d:	e8 ec f6 ff ff       	call   f0100d1e <page_free>
	pp0 = pp1 = pp2 = 0;
f0101632:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0101639:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0101640:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	assert(page_alloc(&pp0) == 0);
f0101647:	8d 45 dc             	lea    -0x24(%ebp),%eax
f010164a:	89 04 24             	mov    %eax,(%esp)
f010164d:	e8 98 f6 ff ff       	call   f0100cea <page_alloc>
f0101652:	85 c0                	test   %eax,%eax
f0101654:	74 24                	je     f010167a <i386_vm_init+0x5c0>
f0101656:	c7 44 24 0c 52 49 10 	movl   $0xf0104952,0xc(%esp)
f010165d:	f0 
f010165e:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101665:	f0 
f0101666:	c7 44 24 04 56 01 00 	movl   $0x156,0x4(%esp)
f010166d:	00 
f010166e:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101675:	e8 7c ea ff ff       	call   f01000f6 <_panic>
	assert(page_alloc(&pp1) == 0);
f010167a:	8d 45 e0             	lea    -0x20(%ebp),%eax
f010167d:	89 04 24             	mov    %eax,(%esp)
f0101680:	e8 65 f6 ff ff       	call   f0100cea <page_alloc>
f0101685:	85 c0                	test   %eax,%eax
f0101687:	74 24                	je     f01016ad <i386_vm_init+0x5f3>
f0101689:	c7 44 24 0c 68 49 10 	movl   $0xf0104968,0xc(%esp)
f0101690:	f0 
f0101691:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101698:	f0 
f0101699:	c7 44 24 04 57 01 00 	movl   $0x157,0x4(%esp)
f01016a0:	00 
f01016a1:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01016a8:	e8 49 ea ff ff       	call   f01000f6 <_panic>
	assert(page_alloc(&pp2) == 0);
f01016ad:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01016b0:	89 04 24             	mov    %eax,(%esp)
f01016b3:	e8 32 f6 ff ff       	call   f0100cea <page_alloc>
f01016b8:	85 c0                	test   %eax,%eax
f01016ba:	74 24                	je     f01016e0 <i386_vm_init+0x626>
f01016bc:	c7 44 24 0c 7e 49 10 	movl   $0xf010497e,0xc(%esp)
f01016c3:	f0 
f01016c4:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f01016cb:	f0 
f01016cc:	c7 44 24 04 58 01 00 	movl   $0x158,0x4(%esp)
f01016d3:	00 
f01016d4:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01016db:	e8 16 ea ff ff       	call   f01000f6 <_panic>
	assert(pp0);
f01016e0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01016e3:	85 d2                	test   %edx,%edx
f01016e5:	75 24                	jne    f010170b <i386_vm_init+0x651>
f01016e7:	c7 44 24 0c a2 49 10 	movl   $0xf01049a2,0xc(%esp)
f01016ee:	f0 
f01016ef:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f01016f6:	f0 
f01016f7:	c7 44 24 04 59 01 00 	movl   $0x159,0x4(%esp)
f01016fe:	00 
f01016ff:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101706:	e8 eb e9 ff ff       	call   f01000f6 <_panic>
	assert(pp1 && pp1 != pp0);
f010170b:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010170e:	85 c9                	test   %ecx,%ecx
f0101710:	74 04                	je     f0101716 <i386_vm_init+0x65c>
f0101712:	39 ca                	cmp    %ecx,%edx
f0101714:	75 24                	jne    f010173a <i386_vm_init+0x680>
f0101716:	c7 44 24 0c 94 49 10 	movl   $0xf0104994,0xc(%esp)
f010171d:	f0 
f010171e:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101725:	f0 
f0101726:	c7 44 24 04 5a 01 00 	movl   $0x15a,0x4(%esp)
f010172d:	00 
f010172e:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101735:	e8 bc e9 ff ff       	call   f01000f6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010173a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010173d:	85 c0                	test   %eax,%eax
f010173f:	74 08                	je     f0101749 <i386_vm_init+0x68f>
f0101741:	39 c1                	cmp    %eax,%ecx
f0101743:	74 04                	je     f0101749 <i386_vm_init+0x68f>
f0101745:	39 c2                	cmp    %eax,%edx
f0101747:	75 24                	jne    f010176d <i386_vm_init+0x6b3>
f0101749:	c7 44 24 0c d8 43 10 	movl   $0xf01043d8,0xc(%esp)
f0101750:	f0 
f0101751:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101758:	f0 
f0101759:	c7 44 24 04 5b 01 00 	movl   $0x15b,0x4(%esp)
f0101760:	00 
f0101761:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101768:	e8 89 e9 ff ff       	call   f01000f6 <_panic>
	assert(page_alloc(&pp) == -E_NO_MEM);
f010176d:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0101770:	89 04 24             	mov    %eax,(%esp)
f0101773:	e8 72 f5 ff ff       	call   f0100cea <page_alloc>
f0101778:	83 f8 fc             	cmp    $0xfffffffc,%eax
f010177b:	74 24                	je     f01017a1 <i386_vm_init+0x6e7>
f010177d:	c7 44 24 0c fa 49 10 	movl   $0xf01049fa,0xc(%esp)
f0101784:	f0 
f0101785:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f010178c:	f0 
f010178d:	c7 44 24 04 5c 01 00 	movl   $0x15c,0x4(%esp)
f0101794:	00 
f0101795:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f010179c:	e8 55 e9 ff ff       	call   f01000f6 <_panic>

	// give free list back
	page_free_list = fl;
f01017a1:	89 1d d8 65 11 f0    	mov    %ebx,0xf01165d8

	// free the pages we took
	page_free(pp0);
f01017a7:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01017aa:	89 04 24             	mov    %eax,(%esp)
f01017ad:	e8 6c f5 ff ff       	call   f0100d1e <page_free>
	page_free(pp1);
f01017b2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01017b5:	89 04 24             	mov    %eax,(%esp)
f01017b8:	e8 61 f5 ff ff       	call   f0100d1e <page_free>
	page_free(pp2);
f01017bd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01017c0:	89 04 24             	mov    %eax,(%esp)
f01017c3:	e8 56 f5 ff ff       	call   f0100d1e <page_free>

	cprintf("check_page_alloc() succeeded!\n");
f01017c8:	c7 04 24 f8 43 10 f0 	movl   $0xf01043f8,(%esp)
f01017cf:	e8 6e 15 00 00       	call   f0102d42 <cprintf>
	pte_t *ptep, *ptep1;
	void *va;
	int i;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
f01017d4:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01017db:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01017e2:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
	assert(page_alloc(&pp0) == 0);
f01017e9:	8d 45 d8             	lea    -0x28(%ebp),%eax
f01017ec:	89 04 24             	mov    %eax,(%esp)
f01017ef:	e8 f6 f4 ff ff       	call   f0100cea <page_alloc>
f01017f4:	85 c0                	test   %eax,%eax
f01017f6:	74 24                	je     f010181c <i386_vm_init+0x762>
f01017f8:	c7 44 24 0c 52 49 10 	movl   $0xf0104952,0xc(%esp)
f01017ff:	f0 
f0101800:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101807:	f0 
f0101808:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f010180f:	00 
f0101810:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101817:	e8 da e8 ff ff       	call   f01000f6 <_panic>
	assert(page_alloc(&pp1) == 0);
f010181c:	8d 45 dc             	lea    -0x24(%ebp),%eax
f010181f:	89 04 24             	mov    %eax,(%esp)
f0101822:	e8 c3 f4 ff ff       	call   f0100cea <page_alloc>
f0101827:	85 c0                	test   %eax,%eax
f0101829:	74 24                	je     f010184f <i386_vm_init+0x795>
f010182b:	c7 44 24 0c 68 49 10 	movl   $0xf0104968,0xc(%esp)
f0101832:	f0 
f0101833:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f010183a:	f0 
f010183b:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
f0101842:	00 
f0101843:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f010184a:	e8 a7 e8 ff ff       	call   f01000f6 <_panic>
	assert(page_alloc(&pp2) == 0);
f010184f:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0101852:	89 04 24             	mov    %eax,(%esp)
f0101855:	e8 90 f4 ff ff       	call   f0100cea <page_alloc>
f010185a:	85 c0                	test   %eax,%eax
f010185c:	74 24                	je     f0101882 <i386_vm_init+0x7c8>
f010185e:	c7 44 24 0c 7e 49 10 	movl   $0xf010497e,0xc(%esp)
f0101865:	f0 
f0101866:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f010186d:	f0 
f010186e:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0101875:	00 
f0101876:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f010187d:	e8 74 e8 ff ff       	call   f01000f6 <_panic>

	assert(pp0);
f0101882:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101885:	85 d2                	test   %edx,%edx
f0101887:	75 24                	jne    f01018ad <i386_vm_init+0x7f3>
f0101889:	c7 44 24 0c a2 49 10 	movl   $0xf01049a2,0xc(%esp)
f0101890:	f0 
f0101891:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101898:	f0 
f0101899:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f01018a0:	00 
f01018a1:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01018a8:	e8 49 e8 ff ff       	call   f01000f6 <_panic>
	assert(pp1 && pp1 != pp0);
f01018ad:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01018b0:	85 c9                	test   %ecx,%ecx
f01018b2:	74 04                	je     f01018b8 <i386_vm_init+0x7fe>
f01018b4:	39 ca                	cmp    %ecx,%edx
f01018b6:	75 24                	jne    f01018dc <i386_vm_init+0x822>
f01018b8:	c7 44 24 0c 94 49 10 	movl   $0xf0104994,0xc(%esp)
f01018bf:	f0 
f01018c0:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f01018c7:	f0 
f01018c8:	c7 44 24 04 11 03 00 	movl   $0x311,0x4(%esp)
f01018cf:	00 
f01018d0:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01018d7:	e8 1a e8 ff ff       	call   f01000f6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018dc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01018df:	85 c0                	test   %eax,%eax
f01018e1:	74 08                	je     f01018eb <i386_vm_init+0x831>
f01018e3:	39 c1                	cmp    %eax,%ecx
f01018e5:	74 04                	je     f01018eb <i386_vm_init+0x831>
f01018e7:	39 c2                	cmp    %eax,%edx
f01018e9:	75 24                	jne    f010190f <i386_vm_init+0x855>
f01018eb:	c7 44 24 0c d8 43 10 	movl   $0xf01043d8,0xc(%esp)
f01018f2:	f0 
f01018f3:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f01018fa:	f0 
f01018fb:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f0101902:	00 
f0101903:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f010190a:	e8 e7 e7 ff ff       	call   f01000f6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010190f:	8b 1d d8 65 11 f0    	mov    0xf01165d8,%ebx
f0101915:	89 5d c0             	mov    %ebx,-0x40(%ebp)
	LIST_INIT(&page_free_list);
f0101918:	c7 05 d8 65 11 f0 00 	movl   $0x0,0xf01165d8
f010191f:	00 00 00 

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);
f0101922:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f0101925:	89 04 24             	mov    %eax,(%esp)
f0101928:	e8 bd f3 ff ff       	call   f0100cea <page_alloc>
f010192d:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101930:	74 24                	je     f0101956 <i386_vm_init+0x89c>
f0101932:	c7 44 24 0c fa 49 10 	movl   $0xf01049fa,0xc(%esp)
f0101939:	f0 
f010193a:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101941:	f0 
f0101942:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f0101949:	00 
f010194a:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101951:	e8 a0 e7 ff ff       	call   f01000f6 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(boot_pgdir, (void *) 0x0, &ptep) == NULL);
f0101956:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101959:	89 44 24 08          	mov    %eax,0x8(%esp)
f010195d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101964:	00 
f0101965:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f010196a:	89 04 24             	mov    %eax,(%esp)
f010196d:	e8 d9 f5 ff ff       	call   f0100f4b <page_lookup>
f0101972:	85 c0                	test   %eax,%eax
f0101974:	74 24                	je     f010199a <i386_vm_init+0x8e0>
f0101976:	c7 44 24 0c 18 44 10 	movl   $0xf0104418,0xc(%esp)
f010197d:	f0 
f010197e:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101985:	f0 
f0101986:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f010198d:	00 
f010198e:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101995:	e8 5c e7 ff ff       	call   f01000f6 <_panic>

	// there is no free memory, so we can't allocate a page table 
	assert(page_insert(boot_pgdir, pp1, 0x0, 0) < 0);
f010199a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01019a1:	00 
f01019a2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01019a9:	00 
f01019aa:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01019ad:	89 44 24 04          	mov    %eax,0x4(%esp)
f01019b1:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f01019b6:	89 04 24             	mov    %eax,(%esp)
f01019b9:	e8 5b f6 ff ff       	call   f0101019 <page_insert>
f01019be:	85 c0                	test   %eax,%eax
f01019c0:	78 24                	js     f01019e6 <i386_vm_init+0x92c>
f01019c2:	c7 44 24 0c 50 44 10 	movl   $0xf0104450,0xc(%esp)
f01019c9:	f0 
f01019ca:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f01019d1:	f0 
f01019d2:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f01019d9:	00 
f01019da:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01019e1:	e8 10 e7 ff ff       	call   f01000f6 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019e6:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01019e9:	89 04 24             	mov    %eax,(%esp)
f01019ec:	e8 2d f3 ff ff       	call   f0100d1e <page_free>
	assert(page_insert(boot_pgdir, pp1, 0x0, 0) == 0);
f01019f1:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01019f8:	00 
f01019f9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a00:	00 
f0101a01:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101a04:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a08:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f0101a0d:	89 04 24             	mov    %eax,(%esp)
f0101a10:	e8 04 f6 ff ff       	call   f0101019 <page_insert>
f0101a15:	85 c0                	test   %eax,%eax
f0101a17:	74 24                	je     f0101a3d <i386_vm_init+0x983>
f0101a19:	c7 44 24 0c 7c 44 10 	movl   $0xf010447c,0xc(%esp)
f0101a20:	f0 
f0101a21:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101a28:	f0 
f0101a29:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0101a30:	00 
f0101a31:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101a38:	e8 b9 e6 ff ff       	call   f01000f6 <_panic>
	assert(PTE_ADDR(boot_pgdir[0]) == page2pa(pp0));
f0101a3d:	8b 1d 08 6a 11 f0    	mov    0xf0116a08,%ebx
f0101a43:	8b 75 d8             	mov    -0x28(%ebp),%esi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101a46:	8b 3d 0c 6a 11 f0    	mov    0xf0116a0c,%edi
f0101a4c:	8b 13                	mov    (%ebx),%edx
f0101a4e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a54:	89 f0                	mov    %esi,%eax
f0101a56:	29 f8                	sub    %edi,%eax
f0101a58:	c1 f8 02             	sar    $0x2,%eax
f0101a5b:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101a61:	c1 e0 0c             	shl    $0xc,%eax
f0101a64:	39 c2                	cmp    %eax,%edx
f0101a66:	74 24                	je     f0101a8c <i386_vm_init+0x9d2>
f0101a68:	c7 44 24 0c a8 44 10 	movl   $0xf01044a8,0xc(%esp)
f0101a6f:	f0 
f0101a70:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101a77:	f0 
f0101a78:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f0101a7f:	00 
f0101a80:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101a87:	e8 6a e6 ff ff       	call   f01000f6 <_panic>
	assert(check_va2pa(boot_pgdir, 0x0) == page2pa(pp1));
f0101a8c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a91:	89 d8                	mov    %ebx,%eax
f0101a93:	e8 0a f0 ff ff       	call   f0100aa2 <check_va2pa>
f0101a98:	8b 55 dc             	mov    -0x24(%ebp),%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101a9b:	89 d1                	mov    %edx,%ecx
f0101a9d:	29 f9                	sub    %edi,%ecx
f0101a9f:	c1 f9 02             	sar    $0x2,%ecx
f0101aa2:	69 c9 ab aa aa aa    	imul   $0xaaaaaaab,%ecx,%ecx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101aa8:	c1 e1 0c             	shl    $0xc,%ecx
f0101aab:	39 c8                	cmp    %ecx,%eax
f0101aad:	74 24                	je     f0101ad3 <i386_vm_init+0xa19>
f0101aaf:	c7 44 24 0c d0 44 10 	movl   $0xf01044d0,0xc(%esp)
f0101ab6:	f0 
f0101ab7:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101abe:	f0 
f0101abf:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0101ac6:	00 
f0101ac7:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101ace:	e8 23 e6 ff ff       	call   f01000f6 <_panic>
	assert(pp1->pp_ref == 1);
f0101ad3:	66 83 7a 08 01       	cmpw   $0x1,0x8(%edx)
f0101ad8:	74 24                	je     f0101afe <i386_vm_init+0xa44>
f0101ada:	c7 44 24 0c 17 4a 10 	movl   $0xf0104a17,0xc(%esp)
f0101ae1:	f0 
f0101ae2:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101ae9:	f0 
f0101aea:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f0101af1:	00 
f0101af2:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101af9:	e8 f8 e5 ff ff       	call   f01000f6 <_panic>
	assert(pp0->pp_ref == 1);
f0101afe:	66 83 7e 08 01       	cmpw   $0x1,0x8(%esi)
f0101b03:	74 24                	je     f0101b29 <i386_vm_init+0xa6f>
f0101b05:	c7 44 24 0c 28 4a 10 	movl   $0xf0104a28,0xc(%esp)
f0101b0c:	f0 
f0101b0d:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101b14:	f0 
f0101b15:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f0101b1c:	00 
f0101b1d:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101b24:	e8 cd e5 ff ff       	call   f01000f6 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(boot_pgdir, pp2, (void*) PGSIZE, 0) == 0);
f0101b29:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101b30:	00 
f0101b31:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b38:	00 
f0101b39:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101b3c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101b40:	89 1c 24             	mov    %ebx,(%esp)
f0101b43:	e8 d1 f4 ff ff       	call   f0101019 <page_insert>
f0101b48:	85 c0                	test   %eax,%eax
f0101b4a:	74 24                	je     f0101b70 <i386_vm_init+0xab6>
f0101b4c:	c7 44 24 0c 00 45 10 	movl   $0xf0104500,0xc(%esp)
f0101b53:	f0 
f0101b54:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101b5b:	f0 
f0101b5c:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f0101b63:	00 
f0101b64:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101b6b:	e8 86 e5 ff ff       	call   f01000f6 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp2));
f0101b70:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b75:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f0101b7a:	e8 23 ef ff ff       	call   f0100aa2 <check_va2pa>
f0101b7f:	8b 55 e0             	mov    -0x20(%ebp),%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101b82:	89 d1                	mov    %edx,%ecx
f0101b84:	2b 0d 0c 6a 11 f0    	sub    0xf0116a0c,%ecx
f0101b8a:	c1 f9 02             	sar    $0x2,%ecx
f0101b8d:	69 c9 ab aa aa aa    	imul   $0xaaaaaaab,%ecx,%ecx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101b93:	c1 e1 0c             	shl    $0xc,%ecx
f0101b96:	39 c8                	cmp    %ecx,%eax
f0101b98:	74 24                	je     f0101bbe <i386_vm_init+0xb04>
f0101b9a:	c7 44 24 0c 38 45 10 	movl   $0xf0104538,0xc(%esp)
f0101ba1:	f0 
f0101ba2:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101ba9:	f0 
f0101baa:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0101bb1:	00 
f0101bb2:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101bb9:	e8 38 e5 ff ff       	call   f01000f6 <_panic>
	assert(pp2->pp_ref == 1);
f0101bbe:	66 83 7a 08 01       	cmpw   $0x1,0x8(%edx)
f0101bc3:	74 24                	je     f0101be9 <i386_vm_init+0xb2f>
f0101bc5:	c7 44 24 0c 39 4a 10 	movl   $0xf0104a39,0xc(%esp)
f0101bcc:	f0 
f0101bcd:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101bd4:	f0 
f0101bd5:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f0101bdc:	00 
f0101bdd:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101be4:	e8 0d e5 ff ff       	call   f01000f6 <_panic>

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);
f0101be9:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f0101bec:	89 04 24             	mov    %eax,(%esp)
f0101bef:	e8 f6 f0 ff ff       	call   f0100cea <page_alloc>
f0101bf4:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101bf7:	74 24                	je     f0101c1d <i386_vm_init+0xb63>
f0101bf9:	c7 44 24 0c fa 49 10 	movl   $0xf01049fa,0xc(%esp)
f0101c00:	f0 
f0101c01:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101c08:	f0 
f0101c09:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f0101c10:	00 
f0101c11:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101c18:	e8 d9 e4 ff ff       	call   f01000f6 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(boot_pgdir, pp2, (void*) PGSIZE, 0) == 0);
f0101c1d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101c24:	00 
f0101c25:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c2c:	00 
f0101c2d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101c30:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101c34:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f0101c39:	89 04 24             	mov    %eax,(%esp)
f0101c3c:	e8 d8 f3 ff ff       	call   f0101019 <page_insert>
f0101c41:	85 c0                	test   %eax,%eax
f0101c43:	74 24                	je     f0101c69 <i386_vm_init+0xbaf>
f0101c45:	c7 44 24 0c 00 45 10 	movl   $0xf0104500,0xc(%esp)
f0101c4c:	f0 
f0101c4d:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101c54:	f0 
f0101c55:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f0101c5c:	00 
f0101c5d:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101c64:	e8 8d e4 ff ff       	call   f01000f6 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp2));
f0101c69:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c6e:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f0101c73:	e8 2a ee ff ff       	call   f0100aa2 <check_va2pa>
f0101c78:	8b 55 e0             	mov    -0x20(%ebp),%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101c7b:	89 d1                	mov    %edx,%ecx
f0101c7d:	2b 0d 0c 6a 11 f0    	sub    0xf0116a0c,%ecx
f0101c83:	c1 f9 02             	sar    $0x2,%ecx
f0101c86:	69 c9 ab aa aa aa    	imul   $0xaaaaaaab,%ecx,%ecx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101c8c:	c1 e1 0c             	shl    $0xc,%ecx
f0101c8f:	39 c8                	cmp    %ecx,%eax
f0101c91:	74 24                	je     f0101cb7 <i386_vm_init+0xbfd>
f0101c93:	c7 44 24 0c 38 45 10 	movl   $0xf0104538,0xc(%esp)
f0101c9a:	f0 
f0101c9b:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101ca2:	f0 
f0101ca3:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0101caa:	00 
f0101cab:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101cb2:	e8 3f e4 ff ff       	call   f01000f6 <_panic>
	assert(pp2->pp_ref == 1);
f0101cb7:	66 83 7a 08 01       	cmpw   $0x1,0x8(%edx)
f0101cbc:	74 24                	je     f0101ce2 <i386_vm_init+0xc28>
f0101cbe:	c7 44 24 0c 39 4a 10 	movl   $0xf0104a39,0xc(%esp)
f0101cc5:	f0 
f0101cc6:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101ccd:	f0 
f0101cce:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f0101cd5:	00 
f0101cd6:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101cdd:	e8 14 e4 ff ff       	call   f01000f6 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(page_alloc(&pp) == -E_NO_MEM);
f0101ce2:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f0101ce5:	89 04 24             	mov    %eax,(%esp)
f0101ce8:	e8 fd ef ff ff       	call   f0100cea <page_alloc>
f0101ced:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101cf0:	74 24                	je     f0101d16 <i386_vm_init+0xc5c>
f0101cf2:	c7 44 24 0c fa 49 10 	movl   $0xf01049fa,0xc(%esp)
f0101cf9:	f0 
f0101cfa:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101d01:	f0 
f0101d02:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0101d09:	00 
f0101d0a:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101d11:	e8 e0 e3 ff ff       	call   f01000f6 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = KADDR(PTE_ADDR(boot_pgdir[PDX(PGSIZE)]));
f0101d16:	8b 15 08 6a 11 f0    	mov    0xf0116a08,%edx
f0101d1c:	8b 02                	mov    (%edx),%eax
f0101d1e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101d23:	89 c1                	mov    %eax,%ecx
f0101d25:	c1 e9 0c             	shr    $0xc,%ecx
f0101d28:	3b 0d 00 6a 11 f0    	cmp    0xf0116a00,%ecx
f0101d2e:	72 20                	jb     f0101d50 <i386_vm_init+0xc96>
f0101d30:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d34:	c7 44 24 08 f0 42 10 	movl   $0xf01042f0,0x8(%esp)
f0101d3b:	f0 
f0101d3c:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f0101d43:	00 
f0101d44:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101d4b:	e8 a6 e3 ff ff       	call   f01000f6 <_panic>
f0101d50:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d55:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(boot_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d58:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d5f:	00 
f0101d60:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101d67:	00 
f0101d68:	89 14 24             	mov    %edx,(%esp)
f0101d6b:	e8 1f f0 ff ff       	call   f0100d8f <pgdir_walk>
f0101d70:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101d73:	83 c2 04             	add    $0x4,%edx
f0101d76:	39 d0                	cmp    %edx,%eax
f0101d78:	74 24                	je     f0101d9e <i386_vm_init+0xce4>
f0101d7a:	c7 44 24 0c 68 45 10 	movl   $0xf0104568,0xc(%esp)
f0101d81:	f0 
f0101d82:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101d89:	f0 
f0101d8a:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f0101d91:	00 
f0101d92:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101d99:	e8 58 e3 ff ff       	call   f01000f6 <_panic>

	// should be able to change permissions too.
	assert(page_insert(boot_pgdir, pp2, (void*) PGSIZE, PTE_U) == 0);
f0101d9e:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0101da5:	00 
f0101da6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101dad:	00 
f0101dae:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101db1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101db5:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f0101dba:	89 04 24             	mov    %eax,(%esp)
f0101dbd:	e8 57 f2 ff ff       	call   f0101019 <page_insert>
f0101dc2:	85 c0                	test   %eax,%eax
f0101dc4:	74 24                	je     f0101dea <i386_vm_init+0xd30>
f0101dc6:	c7 44 24 0c a8 45 10 	movl   $0xf01045a8,0xc(%esp)
f0101dcd:	f0 
f0101dce:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101dd5:	f0 
f0101dd6:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f0101ddd:	00 
f0101dde:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101de5:	e8 0c e3 ff ff       	call   f01000f6 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp2));
f0101dea:	8b 1d 08 6a 11 f0    	mov    0xf0116a08,%ebx
f0101df0:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101df5:	89 d8                	mov    %ebx,%eax
f0101df7:	e8 a6 ec ff ff       	call   f0100aa2 <check_va2pa>
f0101dfc:	8b 55 e0             	mov    -0x20(%ebp),%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101dff:	89 d1                	mov    %edx,%ecx
f0101e01:	2b 0d 0c 6a 11 f0    	sub    0xf0116a0c,%ecx
f0101e07:	c1 f9 02             	sar    $0x2,%ecx
f0101e0a:	69 c9 ab aa aa aa    	imul   $0xaaaaaaab,%ecx,%ecx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101e10:	c1 e1 0c             	shl    $0xc,%ecx
f0101e13:	39 c8                	cmp    %ecx,%eax
f0101e15:	74 24                	je     f0101e3b <i386_vm_init+0xd81>
f0101e17:	c7 44 24 0c 38 45 10 	movl   $0xf0104538,0xc(%esp)
f0101e1e:	f0 
f0101e1f:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101e26:	f0 
f0101e27:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0101e2e:	00 
f0101e2f:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101e36:	e8 bb e2 ff ff       	call   f01000f6 <_panic>
	assert(pp2->pp_ref == 1);
f0101e3b:	66 83 7a 08 01       	cmpw   $0x1,0x8(%edx)
f0101e40:	74 24                	je     f0101e66 <i386_vm_init+0xdac>
f0101e42:	c7 44 24 0c 39 4a 10 	movl   $0xf0104a39,0xc(%esp)
f0101e49:	f0 
f0101e4a:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101e51:	f0 
f0101e52:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0101e59:	00 
f0101e5a:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101e61:	e8 90 e2 ff ff       	call   f01000f6 <_panic>
	assert(*pgdir_walk(boot_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e66:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e6d:	00 
f0101e6e:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e75:	00 
f0101e76:	89 1c 24             	mov    %ebx,(%esp)
f0101e79:	e8 11 ef ff ff       	call   f0100d8f <pgdir_walk>
f0101e7e:	f6 00 04             	testb  $0x4,(%eax)
f0101e81:	75 24                	jne    f0101ea7 <i386_vm_init+0xded>
f0101e83:	c7 44 24 0c e4 45 10 	movl   $0xf01045e4,0xc(%esp)
f0101e8a:	f0 
f0101e8b:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101e92:	f0 
f0101e93:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0101e9a:	00 
f0101e9b:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101ea2:	e8 4f e2 ff ff       	call   f01000f6 <_panic>
	assert(boot_pgdir[0] & PTE_U);
f0101ea7:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f0101eac:	f6 00 04             	testb  $0x4,(%eax)
f0101eaf:	75 24                	jne    f0101ed5 <i386_vm_init+0xe1b>
f0101eb1:	c7 44 24 0c 4a 4a 10 	movl   $0xf0104a4a,0xc(%esp)
f0101eb8:	f0 
f0101eb9:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101ec0:	f0 
f0101ec1:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f0101ec8:	00 
f0101ec9:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101ed0:	e8 21 e2 ff ff       	call   f01000f6 <_panic>
	
	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(boot_pgdir, pp0, (void*) PTSIZE, 0) < 0);
f0101ed5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101edc:	00 
f0101edd:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101ee4:	00 
f0101ee5:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101ee8:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101eec:	89 04 24             	mov    %eax,(%esp)
f0101eef:	e8 25 f1 ff ff       	call   f0101019 <page_insert>
f0101ef4:	85 c0                	test   %eax,%eax
f0101ef6:	78 24                	js     f0101f1c <i386_vm_init+0xe62>
f0101ef8:	c7 44 24 0c 18 46 10 	movl   $0xf0104618,0xc(%esp)
f0101eff:	f0 
f0101f00:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101f07:	f0 
f0101f08:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f0101f0f:	00 
f0101f10:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101f17:	e8 da e1 ff ff       	call   f01000f6 <_panic>
	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(boot_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101f1c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101f23:	00 
f0101f24:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f2b:	00 
f0101f2c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101f2f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101f33:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f0101f38:	89 04 24             	mov    %eax,(%esp)
f0101f3b:	e8 d9 f0 ff ff       	call   f0101019 <page_insert>
f0101f40:	85 c0                	test   %eax,%eax
f0101f42:	74 24                	je     f0101f68 <i386_vm_init+0xeae>
f0101f44:	c7 44 24 0c 4c 46 10 	movl   $0xf010464c,0xc(%esp)
f0101f4b:	f0 
f0101f4c:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101f53:	f0 
f0101f54:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0101f5b:	00 
f0101f5c:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101f63:	e8 8e e1 ff ff       	call   f01000f6 <_panic>
	assert(!(*pgdir_walk(boot_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f68:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f6f:	00 
f0101f70:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f77:	00 
f0101f78:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f0101f7d:	89 04 24             	mov    %eax,(%esp)
f0101f80:	e8 0a ee ff ff       	call   f0100d8f <pgdir_walk>
f0101f85:	f6 00 04             	testb  $0x4,(%eax)
f0101f88:	74 24                	je     f0101fae <i386_vm_init+0xef4>
f0101f8a:	c7 44 24 0c 84 46 10 	movl   $0xf0104684,0xc(%esp)
f0101f91:	f0 
f0101f92:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101f99:	f0 
f0101f9a:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f0101fa1:	00 
f0101fa2:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101fa9:	e8 48 e1 ff ff       	call   f01000f6 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(boot_pgdir, 0) == page2pa(pp1));
f0101fae:	8b 3d 08 6a 11 f0    	mov    0xf0116a08,%edi
f0101fb4:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fb9:	89 f8                	mov    %edi,%eax
f0101fbb:	e8 e2 ea ff ff       	call   f0100aa2 <check_va2pa>
f0101fc0:	89 c6                	mov    %eax,%esi
f0101fc2:	8b 5d dc             	mov    -0x24(%ebp),%ebx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101fc5:	89 d8                	mov    %ebx,%eax
f0101fc7:	2b 05 0c 6a 11 f0    	sub    0xf0116a0c,%eax
f0101fcd:	c1 f8 02             	sar    $0x2,%eax
f0101fd0:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101fd6:	c1 e0 0c             	shl    $0xc,%eax
f0101fd9:	39 c6                	cmp    %eax,%esi
f0101fdb:	74 24                	je     f0102001 <i386_vm_init+0xf47>
f0101fdd:	c7 44 24 0c bc 46 10 	movl   $0xf01046bc,0xc(%esp)
f0101fe4:	f0 
f0101fe5:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0101fec:	f0 
f0101fed:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0101ff4:	00 
f0101ff5:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0101ffc:	e8 f5 e0 ff ff       	call   f01000f6 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp1));
f0102001:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102006:	89 f8                	mov    %edi,%eax
f0102008:	e8 95 ea ff ff       	call   f0100aa2 <check_va2pa>
f010200d:	39 c6                	cmp    %eax,%esi
f010200f:	74 24                	je     f0102035 <i386_vm_init+0xf7b>
f0102011:	c7 44 24 0c e8 46 10 	movl   $0xf01046e8,0xc(%esp)
f0102018:	f0 
f0102019:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0102020:	f0 
f0102021:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0102028:	00 
f0102029:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0102030:	e8 c1 e0 ff ff       	call   f01000f6 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102035:	66 83 7b 08 02       	cmpw   $0x2,0x8(%ebx)
f010203a:	74 24                	je     f0102060 <i386_vm_init+0xfa6>
f010203c:	c7 44 24 0c 60 4a 10 	movl   $0xf0104a60,0xc(%esp)
f0102043:	f0 
f0102044:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f010204b:	f0 
f010204c:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f0102053:	00 
f0102054:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f010205b:	e8 96 e0 ff ff       	call   f01000f6 <_panic>
	assert(pp2->pp_ref == 0);
f0102060:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102063:	66 83 78 08 00       	cmpw   $0x0,0x8(%eax)
f0102068:	74 24                	je     f010208e <i386_vm_init+0xfd4>
f010206a:	c7 44 24 0c 71 4a 10 	movl   $0xf0104a71,0xc(%esp)
f0102071:	f0 
f0102072:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0102079:	f0 
f010207a:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f0102081:	00 
f0102082:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0102089:	e8 68 e0 ff ff       	call   f01000f6 <_panic>

	// pp2 should be returned by page_alloc
	assert(page_alloc(&pp) == 0 && pp == pp2);
f010208e:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f0102091:	89 04 24             	mov    %eax,(%esp)
f0102094:	e8 51 ec ff ff       	call   f0100cea <page_alloc>
f0102099:	85 c0                	test   %eax,%eax
f010209b:	75 08                	jne    f01020a5 <i386_vm_init+0xfeb>
f010209d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01020a0:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01020a3:	74 24                	je     f01020c9 <i386_vm_init+0x100f>
f01020a5:	c7 44 24 0c 18 47 10 	movl   $0xf0104718,0xc(%esp)
f01020ac:	f0 
f01020ad:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f01020b4:	f0 
f01020b5:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f01020bc:	00 
f01020bd:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01020c4:	e8 2d e0 ff ff       	call   f01000f6 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(boot_pgdir, 0x0);
f01020c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01020d0:	00 
f01020d1:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f01020d6:	89 04 24             	mov    %eax,(%esp)
f01020d9:	e8 e7 ee ff ff       	call   f0100fc5 <page_remove>
	assert(check_va2pa(boot_pgdir, 0x0) == ~0);
f01020de:	8b 1d 08 6a 11 f0    	mov    0xf0116a08,%ebx
f01020e4:	ba 00 00 00 00       	mov    $0x0,%edx
f01020e9:	89 d8                	mov    %ebx,%eax
f01020eb:	e8 b2 e9 ff ff       	call   f0100aa2 <check_va2pa>
f01020f0:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020f3:	74 24                	je     f0102119 <i386_vm_init+0x105f>
f01020f5:	c7 44 24 0c 3c 47 10 	movl   $0xf010473c,0xc(%esp)
f01020fc:	f0 
f01020fd:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0102104:	f0 
f0102105:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f010210c:	00 
f010210d:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0102114:	e8 dd df ff ff       	call   f01000f6 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp1));
f0102119:	ba 00 10 00 00       	mov    $0x1000,%edx
f010211e:	89 d8                	mov    %ebx,%eax
f0102120:	e8 7d e9 ff ff       	call   f0100aa2 <check_va2pa>
f0102125:	8b 55 dc             	mov    -0x24(%ebp),%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0102128:	89 d1                	mov    %edx,%ecx
f010212a:	2b 0d 0c 6a 11 f0    	sub    0xf0116a0c,%ecx
f0102130:	c1 f9 02             	sar    $0x2,%ecx
f0102133:	69 c9 ab aa aa aa    	imul   $0xaaaaaaab,%ecx,%ecx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0102139:	c1 e1 0c             	shl    $0xc,%ecx
f010213c:	39 c8                	cmp    %ecx,%eax
f010213e:	74 24                	je     f0102164 <i386_vm_init+0x10aa>
f0102140:	c7 44 24 0c e8 46 10 	movl   $0xf01046e8,0xc(%esp)
f0102147:	f0 
f0102148:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f010214f:	f0 
f0102150:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f0102157:	00 
f0102158:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f010215f:	e8 92 df ff ff       	call   f01000f6 <_panic>
	assert(pp1->pp_ref == 1);
f0102164:	66 83 7a 08 01       	cmpw   $0x1,0x8(%edx)
f0102169:	74 24                	je     f010218f <i386_vm_init+0x10d5>
f010216b:	c7 44 24 0c 17 4a 10 	movl   $0xf0104a17,0xc(%esp)
f0102172:	f0 
f0102173:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f010217a:	f0 
f010217b:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
f0102182:	00 
f0102183:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f010218a:	e8 67 df ff ff       	call   f01000f6 <_panic>
	assert(pp2->pp_ref == 0);
f010218f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102192:	66 83 78 08 00       	cmpw   $0x0,0x8(%eax)
f0102197:	74 24                	je     f01021bd <i386_vm_init+0x1103>
f0102199:	c7 44 24 0c 71 4a 10 	movl   $0xf0104a71,0xc(%esp)
f01021a0:	f0 
f01021a1:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f01021a8:	f0 
f01021a9:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f01021b0:	00 
f01021b1:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01021b8:	e8 39 df ff ff       	call   f01000f6 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(boot_pgdir, (void*) PGSIZE);
f01021bd:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01021c4:	00 
f01021c5:	89 1c 24             	mov    %ebx,(%esp)
f01021c8:	e8 f8 ed ff ff       	call   f0100fc5 <page_remove>
	assert(check_va2pa(boot_pgdir, 0x0) == ~0);
f01021cd:	8b 1d 08 6a 11 f0    	mov    0xf0116a08,%ebx
f01021d3:	ba 00 00 00 00       	mov    $0x0,%edx
f01021d8:	89 d8                	mov    %ebx,%eax
f01021da:	e8 c3 e8 ff ff       	call   f0100aa2 <check_va2pa>
f01021df:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021e2:	74 24                	je     f0102208 <i386_vm_init+0x114e>
f01021e4:	c7 44 24 0c 3c 47 10 	movl   $0xf010473c,0xc(%esp)
f01021eb:	f0 
f01021ec:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f01021f3:	f0 
f01021f4:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f01021fb:	00 
f01021fc:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0102203:	e8 ee de ff ff       	call   f01000f6 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == ~0);
f0102208:	ba 00 10 00 00       	mov    $0x1000,%edx
f010220d:	89 d8                	mov    %ebx,%eax
f010220f:	e8 8e e8 ff ff       	call   f0100aa2 <check_va2pa>
f0102214:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102217:	74 24                	je     f010223d <i386_vm_init+0x1183>
f0102219:	c7 44 24 0c 60 47 10 	movl   $0xf0104760,0xc(%esp)
f0102220:	f0 
f0102221:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0102228:	f0 
f0102229:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f0102230:	00 
f0102231:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0102238:	e8 b9 de ff ff       	call   f01000f6 <_panic>
	assert(pp1->pp_ref == 0);
f010223d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102240:	66 83 78 08 00       	cmpw   $0x0,0x8(%eax)
f0102245:	74 24                	je     f010226b <i386_vm_init+0x11b1>
f0102247:	c7 44 24 0c 82 4a 10 	movl   $0xf0104a82,0xc(%esp)
f010224e:	f0 
f010224f:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0102256:	f0 
f0102257:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f010225e:	00 
f010225f:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0102266:	e8 8b de ff ff       	call   f01000f6 <_panic>
	assert(pp2->pp_ref == 0);
f010226b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010226e:	66 83 78 08 00       	cmpw   $0x0,0x8(%eax)
f0102273:	74 24                	je     f0102299 <i386_vm_init+0x11df>
f0102275:	c7 44 24 0c 71 4a 10 	movl   $0xf0104a71,0xc(%esp)
f010227c:	f0 
f010227d:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0102284:	f0 
f0102285:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f010228c:	00 
f010228d:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0102294:	e8 5d de ff ff       	call   f01000f6 <_panic>

	// so it should be returned by page_alloc
	assert(page_alloc(&pp) == 0 && pp == pp1);
f0102299:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f010229c:	89 04 24             	mov    %eax,(%esp)
f010229f:	e8 46 ea ff ff       	call   f0100cea <page_alloc>
f01022a4:	85 c0                	test   %eax,%eax
f01022a6:	75 08                	jne    f01022b0 <i386_vm_init+0x11f6>
f01022a8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01022ab:	39 55 d4             	cmp    %edx,-0x2c(%ebp)
f01022ae:	74 24                	je     f01022d4 <i386_vm_init+0x121a>
f01022b0:	c7 44 24 0c 88 47 10 	movl   $0xf0104788,0xc(%esp)
f01022b7:	f0 
f01022b8:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f01022bf:	f0 
f01022c0:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f01022c7:	00 
f01022c8:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01022cf:	e8 22 de ff ff       	call   f01000f6 <_panic>

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);
f01022d4:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f01022d7:	89 04 24             	mov    %eax,(%esp)
f01022da:	e8 0b ea ff ff       	call   f0100cea <page_alloc>
f01022df:	83 f8 fc             	cmp    $0xfffffffc,%eax
f01022e2:	74 24                	je     f0102308 <i386_vm_init+0x124e>
f01022e4:	c7 44 24 0c fa 49 10 	movl   $0xf01049fa,0xc(%esp)
f01022eb:	f0 
f01022ec:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f01022f3:	f0 
f01022f4:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f01022fb:	00 
f01022fc:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0102303:	e8 ee dd ff ff       	call   f01000f6 <_panic>
	page_remove(boot_pgdir, 0x0);
	assert(pp2->pp_ref == 0);
#endif

	// forcibly take pp0 back
	assert(PTE_ADDR(boot_pgdir[0]) == page2pa(pp0));
f0102308:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f010230d:	8b 08                	mov    (%eax),%ecx
f010230f:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0102315:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102318:	2b 15 0c 6a 11 f0    	sub    0xf0116a0c,%edx
f010231e:	c1 fa 02             	sar    $0x2,%edx
f0102321:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0102327:	c1 e2 0c             	shl    $0xc,%edx
f010232a:	39 d1                	cmp    %edx,%ecx
f010232c:	74 24                	je     f0102352 <i386_vm_init+0x1298>
f010232e:	c7 44 24 0c a8 44 10 	movl   $0xf01044a8,0xc(%esp)
f0102335:	f0 
f0102336:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f010233d:	f0 
f010233e:	c7 44 24 04 7a 03 00 	movl   $0x37a,0x4(%esp)
f0102345:	00 
f0102346:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f010234d:	e8 a4 dd ff ff       	call   f01000f6 <_panic>
	boot_pgdir[0] = 0;
f0102352:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102358:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010235b:	66 83 78 08 01       	cmpw   $0x1,0x8(%eax)
f0102360:	74 24                	je     f0102386 <i386_vm_init+0x12cc>
f0102362:	c7 44 24 0c 28 4a 10 	movl   $0xf0104a28,0xc(%esp)
f0102369:	f0 
f010236a:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0102371:	f0 
f0102372:	c7 44 24 04 7c 03 00 	movl   $0x37c,0x4(%esp)
f0102379:	00 
f010237a:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0102381:	e8 70 dd ff ff       	call   f01000f6 <_panic>
	pp0->pp_ref = 0;
f0102386:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
	
	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010238c:	89 04 24             	mov    %eax,(%esp)
f010238f:	e8 8a e9 ff ff       	call   f0100d1e <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(boot_pgdir, va, 1);
f0102394:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010239b:	00 
f010239c:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01023a3:	00 
f01023a4:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f01023a9:	89 04 24             	mov    %eax,(%esp)
f01023ac:	e8 de e9 ff ff       	call   f0100d8f <pgdir_walk>
f01023b1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = KADDR(PTE_ADDR(boot_pgdir[PDX(va)]));
f01023b4:	8b 1d 08 6a 11 f0    	mov    0xf0116a08,%ebx
f01023ba:	8b 53 04             	mov    0x4(%ebx),%edx
f01023bd:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01023c3:	8b 0d 00 6a 11 f0    	mov    0xf0116a00,%ecx
f01023c9:	89 d6                	mov    %edx,%esi
f01023cb:	c1 ee 0c             	shr    $0xc,%esi
f01023ce:	39 ce                	cmp    %ecx,%esi
f01023d0:	72 20                	jb     f01023f2 <i386_vm_init+0x1338>
f01023d2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01023d6:	c7 44 24 08 f0 42 10 	movl   $0xf01042f0,0x8(%esp)
f01023dd:	f0 
f01023de:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f01023e5:	00 
f01023e6:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01023ed:	e8 04 dd ff ff       	call   f01000f6 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01023f2:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f01023f8:	39 d0                	cmp    %edx,%eax
f01023fa:	74 24                	je     f0102420 <i386_vm_init+0x1366>
f01023fc:	c7 44 24 0c 93 4a 10 	movl   $0xf0104a93,0xc(%esp)
f0102403:	f0 
f0102404:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f010240b:	f0 
f010240c:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0102413:	00 
f0102414:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f010241b:	e8 d6 dc ff ff       	call   f01000f6 <_panic>
	boot_pgdir[PDX(va)] = 0;
f0102420:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f0102427:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010242a:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0102430:	2b 05 0c 6a 11 f0    	sub    0xf0116a0c,%eax
f0102436:	c1 f8 02             	sar    $0x2,%eax
f0102439:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f010243f:	c1 e0 0c             	shl    $0xc,%eax
}

static inline void*
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
f0102442:	89 c2                	mov    %eax,%edx
f0102444:	c1 ea 0c             	shr    $0xc,%edx
f0102447:	39 d1                	cmp    %edx,%ecx
f0102449:	77 20                	ja     f010246b <i386_vm_init+0x13b1>
f010244b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010244f:	c7 44 24 08 f0 42 10 	movl   $0xf01042f0,0x8(%esp)
f0102456:	f0 
f0102457:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010245e:	00 
f010245f:	c7 04 24 c7 48 10 f0 	movl   $0xf01048c7,(%esp)
f0102466:	e8 8b dc ff ff       	call   f01000f6 <_panic>
	
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010246b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102472:	00 
f0102473:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f010247a:	00 
f010247b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102480:	89 04 24             	mov    %eax,(%esp)
f0102483:	e8 1c 14 00 00       	call   f01038a4 <memset>
	page_free(pp0);
f0102488:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010248b:	89 04 24             	mov    %eax,(%esp)
f010248e:	e8 8b e8 ff ff       	call   f0100d1e <page_free>
	pgdir_walk(boot_pgdir, 0x0, 1);
f0102493:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010249a:	00 
f010249b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01024a2:	00 
f01024a3:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f01024a8:	89 04 24             	mov    %eax,(%esp)
f01024ab:	e8 df e8 ff ff       	call   f0100d8f <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f01024b0:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01024b3:	2b 15 0c 6a 11 f0    	sub    0xf0116a0c,%edx
f01024b9:	c1 fa 02             	sar    $0x2,%edx
f01024bc:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f01024c2:	c1 e2 0c             	shl    $0xc,%edx
}

static inline void*
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
f01024c5:	89 d0                	mov    %edx,%eax
f01024c7:	c1 e8 0c             	shr    $0xc,%eax
f01024ca:	3b 05 00 6a 11 f0    	cmp    0xf0116a00,%eax
f01024d0:	72 20                	jb     f01024f2 <i386_vm_init+0x1438>
f01024d2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01024d6:	c7 44 24 08 f0 42 10 	movl   $0xf01042f0,0x8(%esp)
f01024dd:	f0 
f01024de:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01024e5:	00 
f01024e6:	c7 04 24 c7 48 10 f0 	movl   $0xf01048c7,(%esp)
f01024ed:	e8 04 dc ff ff       	call   f01000f6 <_panic>
f01024f2:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = page2kva(pp0);
f01024f8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01024fb:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f0102502:	75 11                	jne    f0102515 <i386_vm_init+0x145b>
f0102504:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read (or write). 
void
i386_vm_init(void)
f010250a:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(boot_pgdir, 0x0, 1);
	ptep = page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102510:	f6 00 01             	testb  $0x1,(%eax)
f0102513:	74 24                	je     f0102539 <i386_vm_init+0x147f>
f0102515:	c7 44 24 0c ab 4a 10 	movl   $0xf0104aab,0xc(%esp)
f010251c:	f0 
f010251d:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0102524:	f0 
f0102525:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f010252c:	00 
f010252d:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0102534:	e8 bd db ff ff       	call   f01000f6 <_panic>
f0102539:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(boot_pgdir, 0x0, 1);
	ptep = page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010253c:	39 d0                	cmp    %edx,%eax
f010253e:	75 d0                	jne    f0102510 <i386_vm_init+0x1456>
		assert((ptep[i] & PTE_P) == 0);
	boot_pgdir[0] = 0;
f0102540:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f0102545:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010254b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010254e:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)

	// give free list back
	page_free_list = fl;
f0102554:	8b 5d c0             	mov    -0x40(%ebp),%ebx
f0102557:	89 1d d8 65 11 f0    	mov    %ebx,0xf01165d8

	// free the pages we took
	page_free(pp0);
f010255d:	89 04 24             	mov    %eax,(%esp)
f0102560:	e8 b9 e7 ff ff       	call   f0100d1e <page_free>
	page_free(pp1);
f0102565:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102568:	89 04 24             	mov    %eax,(%esp)
f010256b:	e8 ae e7 ff ff       	call   f0100d1e <page_free>
	page_free(pp2);
f0102570:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102573:	89 04 24             	mov    %eax,(%esp)
f0102576:	e8 a3 e7 ff ff       	call   f0100d1e <page_free>
	
	cprintf("page_check() succeeded!\n");
f010257b:	c7 04 24 c2 4a 10 f0 	movl   $0xf0104ac2,(%esp)
f0102582:	e8 bb 07 00 00       	call   f0102d42 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	
	boot_map_segment(pgdir, UPAGES, n, PADDR(pages), PTE_U | PTE_P) ;
f0102587:	a1 0c 6a 11 f0       	mov    0xf0116a0c,%eax
f010258c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102591:	77 20                	ja     f01025b3 <i386_vm_init+0x14f9>
f0102593:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102597:	c7 44 24 08 38 43 10 	movl   $0xf0104338,0x8(%esp)
f010259e:	f0 
f010259f:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
f01025a6:	00 
f01025a7:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01025ae:	e8 43 db ff ff       	call   f01000f6 <_panic>
f01025b3:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f01025ba:	00 
f01025bb:	05 00 00 00 10       	add    $0x10000000,%eax
f01025c0:	89 04 24             	mov    %eax,(%esp)
f01025c3:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f01025c6:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01025cb:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01025ce:	e8 14 e9 ff ff       	call   f0100ee7 <boot_map_segment>
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_segment(pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, 
		PADDR(bootstack), PTE_W | PTE_P) ;
f01025d3:	bb 00 e0 10 f0       	mov    $0xf010e000,%ebx
f01025d8:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01025de:	77 20                	ja     f0102600 <i386_vm_init+0x1546>
f01025e0:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01025e4:	c7 44 24 08 38 43 10 	movl   $0xf0104338,0x8(%esp)
f01025eb:	f0 
f01025ec:	c7 44 24 04 df 00 00 	movl   $0xdf,0x4(%esp)
f01025f3:	00 
f01025f4:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01025fb:	e8 f6 da ff ff       	call   f01000f6 <_panic>
f0102600:	c7 45 c0 00 e0 10 00 	movl   $0x10e000,-0x40(%ebp)
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_segment(pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, 
f0102607:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f010260e:	00 
f010260f:	c7 04 24 00 e0 10 00 	movl   $0x10e000,(%esp)
f0102616:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010261b:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102620:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0102623:	e8 bf e8 ff ff       	call   f0100ee7 <boot_map_segment>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here: 
	boot_map_segment(pgdir, KERNBASE, 0xFFFFFFFF - KERNBASE, 0, PTE_W | PTE_P) ;
f0102628:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f010262f:	00 
f0102630:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102637:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010263c:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102641:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0102644:	e8 9e e8 ff ff       	call   f0100ee7 <boot_map_segment>
check_boot_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = boot_pgdir;
f0102649:	8b 3d 08 6a 11 f0    	mov    0xf0116a08,%edi

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
f010264f:	a1 00 6a 11 f0       	mov    0xf0116a00,%eax
f0102654:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0102657:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010265a:	8d 04 85 ff 0f 00 00 	lea    0xfff(,%eax,4),%eax
	for (i = 0; i < n; i += PGSIZE)
f0102661:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102666:	89 45 b8             	mov    %eax,-0x48(%ebp)
f0102669:	0f 84 84 00 00 00    	je     f01026f3 <i386_vm_init+0x1639>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010266f:	8b 35 0c 6a 11 f0    	mov    0xf0116a0c,%esi
f0102675:	8d 96 00 00 00 10    	lea    0x10000000(%esi),%edx
f010267b:	89 55 b4             	mov    %edx,-0x4c(%ebp)
f010267e:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102683:	89 f8                	mov    %edi,%eax
f0102685:	e8 18 e4 ff ff       	call   f0100aa2 <check_va2pa>
f010268a:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102690:	77 20                	ja     f01026b2 <i386_vm_init+0x15f8>
f0102692:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102696:	c7 44 24 08 38 43 10 	movl   $0xf0104338,0x8(%esp)
f010269d:	f0 
f010269e:	c7 44 24 04 7e 01 00 	movl   $0x17e,0x4(%esp)
f01026a5:	00 
f01026a6:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01026ad:	e8 44 da ff ff       	call   f01000f6 <_panic>

	pgdir = boot_pgdir;

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01026b2:	ba 00 00 00 00       	mov    $0x0,%edx
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read (or write). 
void
i386_vm_init(void)
f01026b7:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
f01026ba:	01 d1                	add    %edx,%ecx
	pgdir = boot_pgdir;

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01026bc:	39 c1                	cmp    %eax,%ecx
f01026be:	74 24                	je     f01026e4 <i386_vm_init+0x162a>
f01026c0:	c7 44 24 0c ac 47 10 	movl   $0xf01047ac,0xc(%esp)
f01026c7:	f0 
f01026c8:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f01026cf:	f0 
f01026d0:	c7 44 24 04 7e 01 00 	movl   $0x17e,0x4(%esp)
f01026d7:	00 
f01026d8:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01026df:	e8 12 da ff ff       	call   f01000f6 <_panic>

	pgdir = boot_pgdir;

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01026e4:	8d b2 00 10 00 00    	lea    0x1000(%edx),%esi
f01026ea:	39 75 b8             	cmp    %esi,-0x48(%ebp)
f01026ed:	0f 87 fd 01 00 00    	ja     f01028f0 <i386_vm_init+0x1836>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	

	// check phys mem
	for (i = 0; i < npage * PGSIZE; i += PGSIZE)
f01026f3:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f01026f6:	c1 e1 0c             	shl    $0xc,%ecx
f01026f9:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f01026fc:	85 c9                	test   %ecx,%ecx
f01026fe:	0f 84 cd 01 00 00    	je     f01028d1 <i386_vm_init+0x1817>
f0102704:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read (or write). 
void
i386_vm_init(void)
f0102709:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	

	// check phys mem
	for (i = 0; i < npage * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010270f:	89 f8                	mov    %edi,%eax
f0102711:	e8 8c e3 ff ff       	call   f0100aa2 <check_va2pa>
f0102716:	39 c6                	cmp    %eax,%esi
f0102718:	74 24                	je     f010273e <i386_vm_init+0x1684>
f010271a:	c7 44 24 0c e0 47 10 	movl   $0xf01047e0,0xc(%esp)
f0102721:	f0 
f0102722:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0102729:	f0 
f010272a:	c7 44 24 04 83 01 00 	movl   $0x183,0x4(%esp)
f0102731:	00 
f0102732:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0102739:	e8 b8 d9 ff ff       	call   f01000f6 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	

	// check phys mem
	for (i = 0; i < npage * PGSIZE; i += PGSIZE)
f010273e:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102744:	3b 75 c4             	cmp    -0x3c(%ebp),%esi
f0102747:	72 c0                	jb     f0102709 <i386_vm_init+0x164f>
f0102749:	e9 83 01 00 00       	jmp    f01028d1 <i386_vm_init+0x1817>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010274e:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f0102751:	74 24                	je     f0102777 <i386_vm_init+0x16bd>
f0102753:	c7 44 24 0c 08 48 10 	movl   $0xf0104808,0xc(%esp)
f010275a:	f0 
f010275b:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0102762:	f0 
f0102763:	c7 44 24 04 87 01 00 	movl   $0x187,0x4(%esp)
f010276a:	00 
f010276b:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0102772:	e8 7f d9 ff ff       	call   f01000f6 <_panic>
f0102777:	81 45 c0 00 10 00 00 	addl   $0x1000,-0x40(%ebp)
	// check phys mem
	for (i = 0; i < npage * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010277e:	39 75 c0             	cmp    %esi,-0x40(%ebp)
f0102781:	0f 85 39 01 00 00    	jne    f01028c0 <i386_vm_init+0x1806>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102787:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f010278c:	89 f8                	mov    %edi,%eax
f010278e:	e8 0f e3 ff ff       	call   f0100aa2 <check_va2pa>
f0102793:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102796:	74 24                	je     f01027bc <i386_vm_init+0x1702>
f0102798:	c7 44 24 0c 50 48 10 	movl   $0xf0104850,0xc(%esp)
f010279f:	f0 
f01027a0:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f01027a7:	f0 
f01027a8:	c7 44 24 04 88 01 00 	movl   $0x188,0x4(%esp)
f01027af:	00 
f01027b0:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01027b7:	e8 3a d9 ff ff       	call   f01000f6 <_panic>
f01027bc:	b8 00 00 00 00       	mov    $0x0,%eax

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01027c1:	8d 90 44 fc ff ff    	lea    -0x3bc(%eax),%edx
f01027c7:	83 fa 03             	cmp    $0x3,%edx
f01027ca:	77 2a                	ja     f01027f6 <i386_vm_init+0x173c>
		case PDX(VPT):
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i]);
f01027cc:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f01027d0:	75 7f                	jne    f0102851 <i386_vm_init+0x1797>
f01027d2:	c7 44 24 0c db 4a 10 	movl   $0xf0104adb,0xc(%esp)
f01027d9:	f0 
f01027da:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f01027e1:	f0 
f01027e2:	c7 44 24 04 91 01 00 	movl   $0x191,0x4(%esp)
f01027e9:	00 
f01027ea:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f01027f1:	e8 00 d9 ff ff       	call   f01000f6 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE))
f01027f6:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01027fb:	76 2a                	jbe    f0102827 <i386_vm_init+0x176d>
				assert(pgdir[i]);
f01027fd:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102801:	75 4e                	jne    f0102851 <i386_vm_init+0x1797>
f0102803:	c7 44 24 0c db 4a 10 	movl   $0xf0104adb,0xc(%esp)
f010280a:	f0 
f010280b:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f0102812:	f0 
f0102813:	c7 44 24 04 95 01 00 	movl   $0x195,0x4(%esp)
f010281a:	00 
f010281b:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f0102822:	e8 cf d8 ff ff       	call   f01000f6 <_panic>
			else
				assert(pgdir[i] == 0);
f0102827:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f010282b:	74 24                	je     f0102851 <i386_vm_init+0x1797>
f010282d:	c7 44 24 0c e4 4a 10 	movl   $0xf0104ae4,0xc(%esp)
f0102834:	f0 
f0102835:	c7 44 24 08 e2 48 10 	movl   $0xf01048e2,0x8(%esp)
f010283c:	f0 
f010283d:	c7 44 24 04 97 01 00 	movl   $0x197,0x4(%esp)
f0102844:	00 
f0102845:	c7 04 24 9f 48 10 f0 	movl   $0xf010489f,(%esp)
f010284c:	e8 a5 d8 ff ff       	call   f01000f6 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
f0102851:	83 c0 01             	add    $0x1,%eax
f0102854:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102859:	0f 85 62 ff ff ff    	jne    f01027c1 <i386_vm_init+0x1707>
			else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_boot_pgdir() succeeded!\n");
f010285f:	c7 04 24 80 48 10 f0 	movl   $0xf0104880,(%esp)
f0102866:	e8 d7 04 00 00       	call   f0102d42 <cprintf>
	// mapping, even though we are turning on paging and reconfiguring
	// segmentation.

	// Map VA 0:4MB same as VA KERNBASE, i.e. to PA 0:4MB.
	// (Limits our kernel to <4MB)
	pgdir[0] = pgdir[PDX(KERNBASE)];
f010286b:	8b 5d bc             	mov    -0x44(%ebp),%ebx
f010286e:	8b 83 00 0f 00 00    	mov    0xf00(%ebx),%eax
f0102874:	89 03                	mov    %eax,(%ebx)
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102876:	a1 04 6a 11 f0       	mov    0xf0116a04,%eax
f010287b:	0f 22 d8             	mov    %eax,%cr3

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f010287e:	0f 20 c0             	mov    %cr0,%eax
	lcr3(boot_cr3);

	// Turn on paging.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_TS|CR0_EM|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102881:	83 e0 f3             	and    $0xfffffff3,%eax
f0102884:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102889:	0f 22 c0             	mov    %eax,%cr0

	// Current mapping: KERNBASE+x => x => x.
	// (x < 4MB so uses paging pgdir[0])

	// Reload all segment registers.
	asm volatile("lgdt gdt_pd");
f010288c:	0f 01 15 20 63 11 f0 	lgdtl  0xf0116320
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102893:	b8 23 00 00 00       	mov    $0x23,%eax
f0102898:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f010289a:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f010289c:	b0 10                	mov    $0x10,%al
f010289e:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01028a0:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01028a2:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));  // reload cs
f01028a4:	ea ab 28 10 f0 08 00 	ljmp   $0x8,$0xf01028ab
	asm volatile("lldt %%ax" :: "a" (0));
f01028ab:	b0 00                	mov    $0x0,%al
f01028ad:	0f 00 d0             	lldt   %ax

	// Final mapping: KERNBASE+x => KERNBASE+x => x.

	// This mapping was only used after paging was turned on but
	// before the segment registers were reloaded.
	pgdir[0] = 0;
f01028b0:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01028b6:	a1 04 6a 11 f0       	mov    0xf0116a04,%eax
f01028bb:	0f 22 d8             	mov    %eax,%cr3
f01028be:	eb 44                	jmp    f0102904 <i386_vm_init+0x184a>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read (or write). 
void
i386_vm_init(void)
f01028c0:	8b 55 c0             	mov    -0x40(%ebp),%edx
f01028c3:	01 da                	add    %ebx,%edx
	for (i = 0; i < npage * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01028c5:	89 f8                	mov    %edi,%eax
f01028c7:	e8 d6 e1 ff ff       	call   f0100aa2 <check_va2pa>
f01028cc:	e9 7d fe ff ff       	jmp    f010274e <i386_vm_init+0x1694>
f01028d1:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f01028d6:	89 f8                	mov    %edi,%eax
f01028d8:	e8 c5 e1 ff ff       	call   f0100aa2 <check_va2pa>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read (or write). 
void
i386_vm_init(void)
f01028dd:	be 00 60 11 00       	mov    $0x116000,%esi
f01028e2:	ba 00 80 bf df       	mov    $0xdfbf8000,%edx
f01028e7:	29 da                	sub    %ebx,%edx
f01028e9:	89 d3                	mov    %edx,%ebx
f01028eb:	e9 5e fe ff ff       	jmp    f010274e <i386_vm_init+0x1694>
f01028f0:	81 ea 00 f0 ff 10    	sub    $0x10fff000,%edx
	pgdir = boot_pgdir;

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01028f6:	89 f8                	mov    %edi,%eax
f01028f8:	e8 a5 e1 ff ff       	call   f0100aa2 <check_va2pa>

	pgdir = boot_pgdir;

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01028fd:	89 f2                	mov    %esi,%edx
f01028ff:	e9 b3 fd ff ff       	jmp    f01026b7 <i386_vm_init+0x15fd>
	// before the segment registers were reloaded.
	pgdir[0] = 0;

	// Flush the TLB for good measure, to kill the pgdir[0] mapping.
	lcr3(boot_cr3);
}
f0102904:	83 c4 5c             	add    $0x5c,%esp
f0102907:	5b                   	pop    %ebx
f0102908:	5e                   	pop    %esi
f0102909:	5f                   	pop    %edi
f010290a:	5d                   	pop    %ebp
f010290b:	c3                   	ret    

f010290c <envid2env>:
//   On success, sets *penv to the environment.
//   On error, sets *penv to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010290c:	55                   	push   %ebp
f010290d:	89 e5                	mov    %esp,%ebp
f010290f:	8b 45 08             	mov    0x8(%ebp),%eax
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102912:	85 c0                	test   %eax,%eax
f0102914:	75 11                	jne    f0102927 <envid2env+0x1b>
		*env_store = curenv;
f0102916:	a1 dc 65 11 f0       	mov    0xf01165dc,%eax
f010291b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010291e:	89 02                	mov    %eax,(%edx)
		return 0;
f0102920:	b8 00 00 00 00       	mov    $0x0,%eax
f0102925:	eb 5d                	jmp    f0102984 <envid2env+0x78>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102927:	89 c2                	mov    %eax,%edx
f0102929:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010292f:	6b d2 64             	imul   $0x64,%edx,%edx
f0102932:	03 15 e0 65 11 f0    	add    0xf01165e0,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102938:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f010293c:	74 05                	je     f0102943 <envid2env+0x37>
f010293e:	39 42 4c             	cmp    %eax,0x4c(%edx)
f0102941:	74 10                	je     f0102953 <envid2env+0x47>
		*env_store = 0;
f0102943:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102946:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		return -E_BAD_ENV;
f010294c:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102951:	eb 31                	jmp    f0102984 <envid2env+0x78>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102953:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0102957:	74 21                	je     f010297a <envid2env+0x6e>
f0102959:	a1 dc 65 11 f0       	mov    0xf01165dc,%eax
f010295e:	39 c2                	cmp    %eax,%edx
f0102960:	74 18                	je     f010297a <envid2env+0x6e>
f0102962:	8b 48 4c             	mov    0x4c(%eax),%ecx
f0102965:	39 4a 50             	cmp    %ecx,0x50(%edx)
f0102968:	74 10                	je     f010297a <envid2env+0x6e>
		*env_store = 0;
f010296a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010296d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102973:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102978:	eb 0a                	jmp    f0102984 <envid2env+0x78>
	}

	*env_store = e;
f010297a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010297d:	89 11                	mov    %edx,(%ecx)
	return 0;
f010297f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102984:	5d                   	pop    %ebp
f0102985:	c3                   	ret    

f0102986 <env_init>:
// Insert in reverse order, so that the first call to env_alloc()
// returns envs[0].
//
void
env_init(void)
{
f0102986:	55                   	push   %ebp
f0102987:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f0102989:	5d                   	pop    %ebp
f010298a:	c3                   	ret    

f010298b <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f010298b:	55                   	push   %ebp
f010298c:	89 e5                	mov    %esp,%ebp
f010298e:	53                   	push   %ebx
f010298f:	83 ec 24             	sub    $0x24,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = LIST_FIRST(&env_free_list)))
f0102992:	8b 1d e4 65 11 f0    	mov    0xf01165e4,%ebx
f0102998:	85 db                	test   %ebx,%ebx
f010299a:	0f 84 f8 00 00 00    	je     f0102a98 <env_alloc+0x10d>
//
static int
env_setup_vm(struct Env *e)
{
	int i, r;
	struct Page *p = NULL;
f01029a0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// Allocate a page for the page directory
	if ((r = page_alloc(&p)) < 0)
f01029a7:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01029aa:	89 04 24             	mov    %eax,(%esp)
f01029ad:	e8 38 e3 ff ff       	call   f0100cea <page_alloc>
f01029b2:	85 c0                	test   %eax,%eax
f01029b4:	0f 88 e3 00 00 00    	js     f0102a9d <env_alloc+0x112>

	// LAB 3: Your code here.

	// VPT and UVPT map the env's own page table, with
	// different permissions.
	e->env_pgdir[PDX(VPT)]  = e->env_cr3 | PTE_P | PTE_W;
f01029ba:	8b 43 5c             	mov    0x5c(%ebx),%eax
f01029bd:	8b 53 60             	mov    0x60(%ebx),%edx
f01029c0:	83 ca 03             	or     $0x3,%edx
f01029c3:	89 90 fc 0e 00 00    	mov    %edx,0xefc(%eax)
	e->env_pgdir[PDX(UVPT)] = e->env_cr3 | PTE_P | PTE_U;
f01029c9:	8b 43 5c             	mov    0x5c(%ebx),%eax
f01029cc:	8b 53 60             	mov    0x60(%ebx),%edx
f01029cf:	83 ca 05             	or     $0x5,%edx
f01029d2:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01029d8:	8b 43 4c             	mov    0x4c(%ebx),%eax
f01029db:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01029e0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01029e5:	7f 05                	jg     f01029ec <env_alloc+0x61>
		generation = 1 << ENVGENSHIFT;
f01029e7:	b8 00 10 00 00       	mov    $0x1000,%eax
	e->env_id = generation | (e - envs);
f01029ec:	89 da                	mov    %ebx,%edx
f01029ee:	2b 15 e0 65 11 f0    	sub    0xf01165e0,%edx
f01029f4:	c1 fa 02             	sar    $0x2,%edx
f01029f7:	69 d2 29 5c 8f c2    	imul   $0xc28f5c29,%edx,%edx
f01029fd:	09 d0                	or     %edx,%eax
f01029ff:	89 43 4c             	mov    %eax,0x4c(%ebx)
	
	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102a02:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a05:	89 43 50             	mov    %eax,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102a08:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
	e->env_runs = 0;
f0102a0f:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102a16:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0102a1d:	00 
f0102a1e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102a25:	00 
f0102a26:	89 1c 24             	mov    %ebx,(%esp)
f0102a29:	e8 76 0e 00 00       	call   f01038a4 <memset>
	// Set up appropriate initial values for the segment registers.
	// GD_UD is the user data segment selector in the GDT, and 
	// GD_UT is the user text segment selector (see inc/memlayout.h).
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.
	e->env_tf.tf_ds = GD_UD | 3;
f0102a2e:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102a34:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102a3a:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102a40:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102a47:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	LIST_REMOVE(e, env_link);
f0102a4d:	8b 43 44             	mov    0x44(%ebx),%eax
f0102a50:	85 c0                	test   %eax,%eax
f0102a52:	74 06                	je     f0102a5a <env_alloc+0xcf>
f0102a54:	8b 53 48             	mov    0x48(%ebx),%edx
f0102a57:	89 50 48             	mov    %edx,0x48(%eax)
f0102a5a:	8b 43 48             	mov    0x48(%ebx),%eax
f0102a5d:	8b 53 44             	mov    0x44(%ebx),%edx
f0102a60:	89 10                	mov    %edx,(%eax)
	*newenv_store = e;
f0102a62:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a65:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102a67:	8b 53 4c             	mov    0x4c(%ebx),%edx
f0102a6a:	a1 dc 65 11 f0       	mov    0xf01165dc,%eax
f0102a6f:	85 c0                	test   %eax,%eax
f0102a71:	74 05                	je     f0102a78 <env_alloc+0xed>
f0102a73:	8b 40 4c             	mov    0x4c(%eax),%eax
f0102a76:	eb 05                	jmp    f0102a7d <env_alloc+0xf2>
f0102a78:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a7d:	89 54 24 08          	mov    %edx,0x8(%esp)
f0102a81:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102a85:	c7 04 24 f2 4a 10 f0 	movl   $0xf0104af2,(%esp)
f0102a8c:	e8 b1 02 00 00       	call   f0102d42 <cprintf>
	return 0;
f0102a91:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a96:	eb 05                	jmp    f0102a9d <env_alloc+0x112>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = LIST_FIRST(&env_free_list)))
		return -E_NO_FREE_ENV;
f0102a98:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
	LIST_REMOVE(e, env_link);
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102a9d:	83 c4 24             	add    $0x24,%esp
f0102aa0:	5b                   	pop    %ebx
f0102aa1:	5d                   	pop    %ebp
f0102aa2:	c3                   	ret    

f0102aa3 <env_create>:
// By convention, envs[0] is the first environment allocated, so
// whoever calls env_create simply looks for the newly created
// environment there. 
void
env_create(uint8_t *binary, size_t size)
{
f0102aa3:	55                   	push   %ebp
f0102aa4:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f0102aa6:	5d                   	pop    %ebp
f0102aa7:	c3                   	ret    

f0102aa8 <env_free>:
//
// Frees env e and all memory it uses.
// 
void
env_free(struct Env *e)
{
f0102aa8:	55                   	push   %ebp
f0102aa9:	89 e5                	mov    %esp,%ebp
f0102aab:	57                   	push   %edi
f0102aac:	56                   	push   %esi
f0102aad:	53                   	push   %ebx
f0102aae:	83 ec 2c             	sub    $0x2c,%esp
f0102ab1:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;
	
	// If freeing the current environment, switch to boot_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102ab4:	a1 dc 65 11 f0       	mov    0xf01165dc,%eax
f0102ab9:	39 c7                	cmp    %eax,%edi
f0102abb:	75 09                	jne    f0102ac6 <env_free+0x1e>
f0102abd:	8b 15 04 6a 11 f0    	mov    0xf0116a04,%edx
f0102ac3:	0f 22 da             	mov    %edx,%cr3
		lcr3(boot_cr3);

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102ac6:	8b 57 4c             	mov    0x4c(%edi),%edx
f0102ac9:	85 c0                	test   %eax,%eax
f0102acb:	74 05                	je     f0102ad2 <env_free+0x2a>
f0102acd:	8b 40 4c             	mov    0x4c(%eax),%eax
f0102ad0:	eb 05                	jmp    f0102ad7 <env_free+0x2f>
f0102ad2:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ad7:	89 54 24 08          	mov    %edx,0x8(%esp)
f0102adb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102adf:	c7 04 24 07 4b 10 f0 	movl   $0xf0104b07,(%esp)
f0102ae6:	e8 57 02 00 00       	call   f0102d42 <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102aeb:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)

//
// Frees env e and all memory it uses.
// 
void
env_free(struct Env *e)
f0102af2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102af5:	c1 e0 02             	shl    $0x2,%eax
f0102af8:	89 45 d8             	mov    %eax,-0x28(%ebp)
	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102afb:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102afe:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102b01:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102b04:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102b0a:	0f 84 ba 00 00 00    	je     f0102bca <env_free+0x122>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102b10:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
		pt = (pte_t*) KADDR(pa);
f0102b16:	89 f0                	mov    %esi,%eax
f0102b18:	c1 e8 0c             	shr    $0xc,%eax
f0102b1b:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0102b1e:	3b 05 00 6a 11 f0    	cmp    0xf0116a00,%eax
f0102b24:	72 20                	jb     f0102b46 <env_free+0x9e>
f0102b26:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102b2a:	c7 44 24 08 f0 42 10 	movl   $0xf01042f0,0x8(%esp)
f0102b31:	f0 
f0102b32:	c7 44 24 04 32 01 00 	movl   $0x132,0x4(%esp)
f0102b39:	00 
f0102b3a:	c7 04 24 1d 4b 10 f0 	movl   $0xf0104b1d,(%esp)
f0102b41:	e8 b0 d5 ff ff       	call   f01000f6 <_panic>

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102b46:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102b49:	c1 e2 16             	shl    $0x16,%edx
f0102b4c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102b4f:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102b54:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102b5b:	01 
f0102b5c:	74 17                	je     f0102b75 <env_free+0xcd>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102b5e:	89 d8                	mov    %ebx,%eax
f0102b60:	c1 e0 0c             	shl    $0xc,%eax
f0102b63:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102b66:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102b6a:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102b6d:	89 04 24             	mov    %eax,(%esp)
f0102b70:	e8 50 e4 ff ff       	call   f0100fc5 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102b75:	83 c3 01             	add    $0x1,%ebx
f0102b78:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102b7e:	75 d4                	jne    f0102b54 <env_free+0xac>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102b80:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102b83:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102b86:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PPN(pa) >= npage)
f0102b8d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102b90:	3b 05 00 6a 11 f0    	cmp    0xf0116a00,%eax
f0102b96:	72 1c                	jb     f0102bb4 <env_free+0x10c>
		panic("pa2page called with invalid pa");
f0102b98:	c7 44 24 08 5c 43 10 	movl   $0xf010435c,0x8(%esp)
f0102b9f:	f0 
f0102ba0:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0102ba7:	00 
f0102ba8:	c7 04 24 c7 48 10 f0 	movl   $0xf01048c7,(%esp)
f0102baf:	e8 42 d5 ff ff       	call   f01000f6 <_panic>
	return &pages[PPN(pa)];
f0102bb4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102bb7:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102bba:	a1 0c 6a 11 f0       	mov    0xf0116a0c,%eax
f0102bbf:	8d 04 90             	lea    (%eax,%edx,4),%eax
		page_decref(pa2page(pa));
f0102bc2:	89 04 24             	mov    %eax,(%esp)
f0102bc5:	e8 a2 e1 ff ff       	call   f0100d6c <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102bca:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102bce:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0102bd5:	0f 85 17 ff ff ff    	jne    f0102af2 <env_free+0x4a>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = e->env_cr3;
f0102bdb:	8b 47 60             	mov    0x60(%edi),%eax
	e->env_pgdir = 0;
f0102bde:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	e->env_cr3 = 0;
f0102be5:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PPN(pa) >= npage)
f0102bec:	c1 e8 0c             	shr    $0xc,%eax
f0102bef:	3b 05 00 6a 11 f0    	cmp    0xf0116a00,%eax
f0102bf5:	72 1c                	jb     f0102c13 <env_free+0x16b>
		panic("pa2page called with invalid pa");
f0102bf7:	c7 44 24 08 5c 43 10 	movl   $0xf010435c,0x8(%esp)
f0102bfe:	f0 
f0102bff:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0102c06:	00 
f0102c07:	c7 04 24 c7 48 10 f0 	movl   $0xf01048c7,(%esp)
f0102c0e:	e8 e3 d4 ff ff       	call   f01000f6 <_panic>
	return &pages[PPN(pa)];
f0102c13:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102c16:	a1 0c 6a 11 f0       	mov    0xf0116a0c,%eax
f0102c1b:	8d 04 90             	lea    (%eax,%edx,4),%eax
	page_decref(pa2page(pa));
f0102c1e:	89 04 24             	mov    %eax,(%esp)
f0102c21:	e8 46 e1 ff ff       	call   f0100d6c <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102c26:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	LIST_INSERT_HEAD(&env_free_list, e, env_link);
f0102c2d:	a1 e4 65 11 f0       	mov    0xf01165e4,%eax
f0102c32:	89 47 44             	mov    %eax,0x44(%edi)
f0102c35:	85 c0                	test   %eax,%eax
f0102c37:	74 06                	je     f0102c3f <env_free+0x197>
f0102c39:	8d 57 44             	lea    0x44(%edi),%edx
f0102c3c:	89 50 48             	mov    %edx,0x48(%eax)
f0102c3f:	89 3d e4 65 11 f0    	mov    %edi,0xf01165e4
f0102c45:	c7 47 48 e4 65 11 f0 	movl   $0xf01165e4,0x48(%edi)
}
f0102c4c:	83 c4 2c             	add    $0x2c,%esp
f0102c4f:	5b                   	pop    %ebx
f0102c50:	5e                   	pop    %esi
f0102c51:	5f                   	pop    %edi
f0102c52:	5d                   	pop    %ebp
f0102c53:	c3                   	ret    

f0102c54 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e) 
{
f0102c54:	55                   	push   %ebp
f0102c55:	89 e5                	mov    %esp,%ebp
f0102c57:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f0102c5a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c5d:	89 04 24             	mov    %eax,(%esp)
f0102c60:	e8 43 fe ff ff       	call   f0102aa8 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102c65:	c7 04 24 50 4b 10 f0 	movl   $0xf0104b50,(%esp)
f0102c6c:	e8 d1 00 00 00       	call   f0102d42 <cprintf>
	while (1)
		monitor(NULL);
f0102c71:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102c78:	e8 77 dc ff ff       	call   f01008f4 <monitor>
f0102c7d:	eb f2                	jmp    f0102c71 <env_destroy+0x1d>

f0102c7f <env_pop_tf>:
// This exits the kernel and starts executing some environment's code.
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102c7f:	55                   	push   %ebp
f0102c80:	89 e5                	mov    %esp,%ebp
f0102c82:	83 ec 18             	sub    $0x18,%esp
	__asm __volatile("movl %0,%%esp\n"
f0102c85:	8b 65 08             	mov    0x8(%ebp),%esp
f0102c88:	61                   	popa   
f0102c89:	07                   	pop    %es
f0102c8a:	1f                   	pop    %ds
f0102c8b:	83 c4 08             	add    $0x8,%esp
f0102c8e:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102c8f:	c7 44 24 08 28 4b 10 	movl   $0xf0104b28,0x8(%esp)
f0102c96:	f0 
f0102c97:	c7 44 24 04 69 01 00 	movl   $0x169,0x4(%esp)
f0102c9e:	00 
f0102c9f:	c7 04 24 1d 4b 10 f0 	movl   $0xf0104b1d,(%esp)
f0102ca6:	e8 4b d4 ff ff       	call   f01000f6 <_panic>

f0102cab <env_run>:
// Note: if this is the first call to env_run, curenv is NULL.
//  (This function does not return.)
//
void
env_run(struct Env *e)
{
f0102cab:	55                   	push   %ebp
f0102cac:	89 e5                	mov    %esp,%ebp
f0102cae:	83 ec 18             	sub    $0x18,%esp
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.
	
	// LAB 3: Your code here.

        panic("env_run not yet implemented");
f0102cb1:	c7 44 24 08 34 4b 10 	movl   $0xf0104b34,0x8(%esp)
f0102cb8:	f0 
f0102cb9:	c7 44 24 04 83 01 00 	movl   $0x183,0x4(%esp)
f0102cc0:	00 
f0102cc1:	c7 04 24 1d 4b 10 f0 	movl   $0xf0104b1d,(%esp)
f0102cc8:	e8 29 d4 ff ff       	call   f01000f6 <_panic>
f0102ccd:	00 00                	add    %al,(%eax)
	...

f0102cd0 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102cd0:	55                   	push   %ebp
f0102cd1:	89 e5                	mov    %esp,%ebp
void
mc146818_write(unsigned reg, unsigned datum)
{
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102cd3:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102cd7:	ba 70 00 00 00       	mov    $0x70,%edx
f0102cdc:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102cdd:	b2 71                	mov    $0x71,%dl
f0102cdf:	ec                   	in     (%dx),%al

unsigned
mc146818_read(unsigned reg)
{
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102ce0:	0f b6 c0             	movzbl %al,%eax
}
f0102ce3:	5d                   	pop    %ebp
f0102ce4:	c3                   	ret    

f0102ce5 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102ce5:	55                   	push   %ebp
f0102ce6:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102ce8:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102cec:	ba 70 00 00 00       	mov    $0x70,%edx
f0102cf1:	ee                   	out    %al,(%dx)
f0102cf2:	0f b6 45 0c          	movzbl 0xc(%ebp),%eax
f0102cf6:	b2 71                	mov    $0x71,%dl
f0102cf8:	ee                   	out    %al,(%dx)
f0102cf9:	5d                   	pop    %ebp
f0102cfa:	c3                   	ret    
	...

f0102cfc <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102cfc:	55                   	push   %ebp
f0102cfd:	89 e5                	mov    %esp,%ebp
f0102cff:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102d02:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d05:	89 04 24             	mov    %eax,(%esp)
f0102d08:	e8 67 d9 ff ff       	call   f0100674 <cputchar>
	*cnt++;
}
f0102d0d:	c9                   	leave  
f0102d0e:	c3                   	ret    

f0102d0f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102d0f:	55                   	push   %ebp
f0102d10:	89 e5                	mov    %esp,%ebp
f0102d12:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102d15:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102d1c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d1f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d23:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d26:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102d2a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102d2d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d31:	c7 04 24 fc 2c 10 f0 	movl   $0xf0102cfc,(%esp)
f0102d38:	e8 8f 04 00 00       	call   f01031cc <vprintfmt>
	return cnt;
}
f0102d3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102d40:	c9                   	leave  
f0102d41:	c3                   	ret    

f0102d42 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102d42:	55                   	push   %ebp
f0102d43:	89 e5                	mov    %esp,%ebp
f0102d45:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102d48:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102d4b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d4f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d52:	89 04 24             	mov    %eax,(%esp)
f0102d55:	e8 b5 ff ff ff       	call   f0102d0f <vcprintf>
	va_end(ap);

	return cnt;
}
f0102d5a:	c9                   	leave  
f0102d5b:	c3                   	ret    
f0102d5c:	00 00                	add    %al,(%eax)
	...

f0102d60 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102d60:	55                   	push   %ebp
f0102d61:	89 e5                	mov    %esp,%ebp
f0102d63:	57                   	push   %edi
f0102d64:	56                   	push   %esi
f0102d65:	53                   	push   %ebx
f0102d66:	83 ec 10             	sub    $0x10,%esp
f0102d69:	89 c6                	mov    %eax,%esi
f0102d6b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102d6e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102d71:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102d74:	8b 1a                	mov    (%edx),%ebx
f0102d76:	8b 09                	mov    (%ecx),%ecx
f0102d78:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102d7b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0102d82:	eb 77                	jmp    f0102dfb <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0102d84:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102d87:	01 d8                	add    %ebx,%eax
f0102d89:	b9 02 00 00 00       	mov    $0x2,%ecx
f0102d8e:	99                   	cltd   
f0102d8f:	f7 f9                	idiv   %ecx
f0102d91:	89 c1                	mov    %eax,%ecx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d93:	eb 01                	jmp    f0102d96 <stab_binsearch+0x36>
			m--;
f0102d95:	49                   	dec    %ecx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d96:	39 d9                	cmp    %ebx,%ecx
f0102d98:	7c 1d                	jl     f0102db7 <stab_binsearch+0x57>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102d9a:	6b d1 0c             	imul   $0xc,%ecx,%edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d9d:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102da2:	39 fa                	cmp    %edi,%edx
f0102da4:	75 ef                	jne    f0102d95 <stab_binsearch+0x35>
f0102da6:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102da9:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102dac:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0102db0:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102db3:	73 18                	jae    f0102dcd <stab_binsearch+0x6d>
f0102db5:	eb 05                	jmp    f0102dbc <stab_binsearch+0x5c>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102db7:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0102dba:	eb 3f                	jmp    f0102dfb <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102dbc:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102dbf:	89 0a                	mov    %ecx,(%edx)
			l = true_m + 1;
f0102dc1:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102dc4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102dcb:	eb 2e                	jmp    f0102dfb <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102dcd:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102dd0:	73 15                	jae    f0102de7 <stab_binsearch+0x87>
			*region_right = m - 1;
f0102dd2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102dd5:	49                   	dec    %ecx
f0102dd6:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102dd9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ddc:	89 08                	mov    %ecx,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102dde:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102de5:	eb 14                	jmp    f0102dfb <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102de7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102dea:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102ded:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f0102def:	ff 45 0c             	incl   0xc(%ebp)
f0102df2:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102df4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0102dfb:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102dfe:	7e 84                	jle    f0102d84 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102e00:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102e04:	75 0d                	jne    f0102e13 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0102e06:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e09:	8b 02                	mov    (%edx),%eax
f0102e0b:	48                   	dec    %eax
f0102e0c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102e0f:	89 01                	mov    %eax,(%ecx)
f0102e11:	eb 22                	jmp    f0102e35 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e13:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102e16:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102e18:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e1b:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e1d:	eb 01                	jmp    f0102e20 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102e1f:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e20:	39 c1                	cmp    %eax,%ecx
f0102e22:	7d 0c                	jge    f0102e30 <stab_binsearch+0xd0>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102e24:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0102e27:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102e2c:	39 fa                	cmp    %edi,%edx
f0102e2e:	75 ef                	jne    f0102e1f <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102e30:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e33:	89 02                	mov    %eax,(%edx)
	}
}
f0102e35:	83 c4 10             	add    $0x10,%esp
f0102e38:	5b                   	pop    %ebx
f0102e39:	5e                   	pop    %esi
f0102e3a:	5f                   	pop    %edi
f0102e3b:	5d                   	pop    %ebp
f0102e3c:	c3                   	ret    

f0102e3d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102e3d:	55                   	push   %ebp
f0102e3e:	89 e5                	mov    %esp,%ebp
f0102e40:	83 ec 38             	sub    $0x38,%esp
f0102e43:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0102e46:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0102e49:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0102e4c:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e4f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102e52:	c7 03 88 4b 10 f0    	movl   $0xf0104b88,(%ebx)
	info->eip_line = 0;
f0102e58:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102e5f:	c7 43 08 88 4b 10 f0 	movl   $0xf0104b88,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102e66:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102e6d:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102e70:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102e77:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102e7d:	76 12                	jbe    f0102e91 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102e7f:	b8 7a d7 10 f0       	mov    $0xf010d77a,%eax
f0102e84:	3d 7d b1 10 f0       	cmp    $0xf010b17d,%eax
f0102e89:	0f 86 5b 01 00 00    	jbe    f0102fea <debuginfo_eip+0x1ad>
f0102e8f:	eb 1c                	jmp    f0102ead <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102e91:	c7 44 24 08 92 4b 10 	movl   $0xf0104b92,0x8(%esp)
f0102e98:	f0 
f0102e99:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
f0102ea0:	00 
f0102ea1:	c7 04 24 9f 4b 10 f0 	movl   $0xf0104b9f,(%esp)
f0102ea8:	e8 49 d2 ff ff       	call   f01000f6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102ead:	80 3d 79 d7 10 f0 00 	cmpb   $0x0,0xf010d779
f0102eb4:	0f 85 37 01 00 00    	jne    f0102ff1 <debuginfo_eip+0x1b4>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102eba:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102ec1:	b8 7c b1 10 f0       	mov    $0xf010b17c,%eax
f0102ec6:	2d bc 4d 10 f0       	sub    $0xf0104dbc,%eax
f0102ecb:	c1 f8 02             	sar    $0x2,%eax
f0102ece:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102ed4:	83 e8 01             	sub    $0x1,%eax
f0102ed7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102eda:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102ede:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102ee5:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102ee8:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102eeb:	b8 bc 4d 10 f0       	mov    $0xf0104dbc,%eax
f0102ef0:	e8 6b fe ff ff       	call   f0102d60 <stab_binsearch>
	if (lfile == 0)
f0102ef5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ef8:	85 c0                	test   %eax,%eax
f0102efa:	0f 84 f8 00 00 00    	je     f0102ff8 <debuginfo_eip+0x1bb>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102f00:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102f03:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102f06:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102f09:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f0d:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102f14:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102f17:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102f1a:	b8 bc 4d 10 f0       	mov    $0xf0104dbc,%eax
f0102f1f:	e8 3c fe ff ff       	call   f0102d60 <stab_binsearch>

	if (lfun <= rfun) {
f0102f24:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0102f27:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0102f2a:	7f 2e                	jg     f0102f5a <debuginfo_eip+0x11d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102f2c:	6b c7 0c             	imul   $0xc,%edi,%eax
f0102f2f:	8d 90 bc 4d 10 f0    	lea    -0xfefb244(%eax),%edx
f0102f35:	8b 80 bc 4d 10 f0    	mov    -0xfefb244(%eax),%eax
f0102f3b:	b9 7a d7 10 f0       	mov    $0xf010d77a,%ecx
f0102f40:	81 e9 7d b1 10 f0    	sub    $0xf010b17d,%ecx
f0102f46:	39 c8                	cmp    %ecx,%eax
f0102f48:	73 08                	jae    f0102f52 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102f4a:	05 7d b1 10 f0       	add    $0xf010b17d,%eax
f0102f4f:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102f52:	8b 42 08             	mov    0x8(%edx),%eax
f0102f55:	89 43 10             	mov    %eax,0x10(%ebx)
f0102f58:	eb 06                	jmp    f0102f60 <debuginfo_eip+0x123>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102f5a:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102f5d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102f60:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0102f67:	00 
f0102f68:	8b 43 08             	mov    0x8(%ebx),%eax
f0102f6b:	89 04 24             	mov    %eax,(%esp)
f0102f6e:	e8 0a 09 00 00       	call   f010387d <strfind>
f0102f73:	2b 43 08             	sub    0x8(%ebx),%eax
f0102f76:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102f79:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102f7c:	39 cf                	cmp    %ecx,%edi
f0102f7e:	7c 7f                	jl     f0102fff <debuginfo_eip+0x1c2>
	       && stabs[lline].n_type != N_SOL
f0102f80:	6b f7 0c             	imul   $0xc,%edi,%esi
f0102f83:	81 c6 bc 4d 10 f0    	add    $0xf0104dbc,%esi
f0102f89:	0f b6 56 04          	movzbl 0x4(%esi),%edx
f0102f8d:	80 fa 84             	cmp    $0x84,%dl
f0102f90:	74 31                	je     f0102fc3 <debuginfo_eip+0x186>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0102f92:	8d 47 ff             	lea    -0x1(%edi),%eax
f0102f95:	6b c0 0c             	imul   $0xc,%eax,%eax
f0102f98:	05 bc 4d 10 f0       	add    $0xf0104dbc,%eax
f0102f9d:	eb 15                	jmp    f0102fb4 <debuginfo_eip+0x177>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0102f9f:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102fa2:	39 cf                	cmp    %ecx,%edi
f0102fa4:	7c 60                	jl     f0103006 <debuginfo_eip+0x1c9>
	       && stabs[lline].n_type != N_SOL
f0102fa6:	89 c6                	mov    %eax,%esi
f0102fa8:	83 e8 0c             	sub    $0xc,%eax
f0102fab:	0f b6 50 10          	movzbl 0x10(%eax),%edx
f0102faf:	80 fa 84             	cmp    $0x84,%dl
f0102fb2:	74 0f                	je     f0102fc3 <debuginfo_eip+0x186>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102fb4:	80 fa 64             	cmp    $0x64,%dl
f0102fb7:	75 e6                	jne    f0102f9f <debuginfo_eip+0x162>
f0102fb9:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f0102fbd:	74 e0                	je     f0102f9f <debuginfo_eip+0x162>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102fbf:	39 f9                	cmp    %edi,%ecx
f0102fc1:	7f 4a                	jg     f010300d <debuginfo_eip+0x1d0>
f0102fc3:	6b ff 0c             	imul   $0xc,%edi,%edi
f0102fc6:	8b 97 bc 4d 10 f0    	mov    -0xfefb244(%edi),%edx
f0102fcc:	b9 7a d7 10 f0       	mov    $0xf010d77a,%ecx
f0102fd1:	81 e9 7d b1 10 f0    	sub    $0xf010b17d,%ecx
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	// Your code here.

	
	return 0;
f0102fd7:	b8 00 00 00 00       	mov    $0x0,%eax
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102fdc:	39 ca                	cmp    %ecx,%edx
f0102fde:	73 32                	jae    f0103012 <debuginfo_eip+0x1d5>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102fe0:	81 c2 7d b1 10 f0    	add    $0xf010b17d,%edx
f0102fe6:	89 13                	mov    %edx,(%ebx)
f0102fe8:	eb 28                	jmp    f0103012 <debuginfo_eip+0x1d5>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102fea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102fef:	eb 21                	jmp    f0103012 <debuginfo_eip+0x1d5>
f0102ff1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102ff6:	eb 1a                	jmp    f0103012 <debuginfo_eip+0x1d5>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102ff8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102ffd:	eb 13                	jmp    f0103012 <debuginfo_eip+0x1d5>
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	// Your code here.

	
	return 0;
f0102fff:	b8 00 00 00 00       	mov    $0x0,%eax
f0103004:	eb 0c                	jmp    f0103012 <debuginfo_eip+0x1d5>
f0103006:	b8 00 00 00 00       	mov    $0x0,%eax
f010300b:	eb 05                	jmp    f0103012 <debuginfo_eip+0x1d5>
f010300d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103012:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103015:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103018:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010301b:	89 ec                	mov    %ebp,%esp
f010301d:	5d                   	pop    %ebp
f010301e:	c3                   	ret    
	...

f0103020 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103020:	55                   	push   %ebp
f0103021:	89 e5                	mov    %esp,%ebp
f0103023:	57                   	push   %edi
f0103024:	56                   	push   %esi
f0103025:	53                   	push   %ebx
f0103026:	83 ec 4c             	sub    $0x4c,%esp
f0103029:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010302c:	89 d7                	mov    %edx,%edi
f010302e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103031:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0103034:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103037:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010303a:	b8 00 00 00 00       	mov    $0x0,%eax
f010303f:	39 d8                	cmp    %ebx,%eax
f0103041:	72 17                	jb     f010305a <printnum+0x3a>
f0103043:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0103046:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f0103049:	76 0f                	jbe    f010305a <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010304b:	8b 75 14             	mov    0x14(%ebp),%esi
f010304e:	83 ee 01             	sub    $0x1,%esi
f0103051:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103054:	85 f6                	test   %esi,%esi
f0103056:	7f 63                	jg     f01030bb <printnum+0x9b>
f0103058:	eb 75                	jmp    f01030cf <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010305a:	8b 5d 18             	mov    0x18(%ebp),%ebx
f010305d:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0103061:	8b 45 14             	mov    0x14(%ebp),%eax
f0103064:	83 e8 01             	sub    $0x1,%eax
f0103067:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010306b:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010306e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103072:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103076:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010307a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010307d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103080:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0103087:	00 
f0103088:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f010308b:	89 1c 24             	mov    %ebx,(%esp)
f010308e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103091:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103095:	e8 16 0a 00 00       	call   f0103ab0 <__udivdi3>
f010309a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010309d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01030a0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01030a4:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01030a8:	89 04 24             	mov    %eax,(%esp)
f01030ab:	89 54 24 04          	mov    %edx,0x4(%esp)
f01030af:	89 fa                	mov    %edi,%edx
f01030b1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01030b4:	e8 67 ff ff ff       	call   f0103020 <printnum>
f01030b9:	eb 14                	jmp    f01030cf <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01030bb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030bf:	8b 45 18             	mov    0x18(%ebp),%eax
f01030c2:	89 04 24             	mov    %eax,(%esp)
f01030c5:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01030c7:	83 ee 01             	sub    $0x1,%esi
f01030ca:	75 ef                	jne    f01030bb <printnum+0x9b>
f01030cc:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01030cf:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030d3:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01030d7:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01030da:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01030de:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01030e5:	00 
f01030e6:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01030e9:	89 1c 24             	mov    %ebx,(%esp)
f01030ec:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01030ef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01030f3:	e8 18 0b 00 00       	call   f0103c10 <__umoddi3>
f01030f8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030fc:	0f be 80 ad 4b 10 f0 	movsbl -0xfefb453(%eax),%eax
f0103103:	89 04 24             	mov    %eax,(%esp)
f0103106:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103109:	ff d0                	call   *%eax
}
f010310b:	83 c4 4c             	add    $0x4c,%esp
f010310e:	5b                   	pop    %ebx
f010310f:	5e                   	pop    %esi
f0103110:	5f                   	pop    %edi
f0103111:	5d                   	pop    %ebp
f0103112:	c3                   	ret    

f0103113 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103113:	55                   	push   %ebp
f0103114:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103116:	83 fa 01             	cmp    $0x1,%edx
f0103119:	7e 0e                	jle    f0103129 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010311b:	8b 10                	mov    (%eax),%edx
f010311d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103120:	89 08                	mov    %ecx,(%eax)
f0103122:	8b 02                	mov    (%edx),%eax
f0103124:	8b 52 04             	mov    0x4(%edx),%edx
f0103127:	eb 22                	jmp    f010314b <getuint+0x38>
	else if (lflag)
f0103129:	85 d2                	test   %edx,%edx
f010312b:	74 10                	je     f010313d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f010312d:	8b 10                	mov    (%eax),%edx
f010312f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103132:	89 08                	mov    %ecx,(%eax)
f0103134:	8b 02                	mov    (%edx),%eax
f0103136:	ba 00 00 00 00       	mov    $0x0,%edx
f010313b:	eb 0e                	jmp    f010314b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f010313d:	8b 10                	mov    (%eax),%edx
f010313f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103142:	89 08                	mov    %ecx,(%eax)
f0103144:	8b 02                	mov    (%edx),%eax
f0103146:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010314b:	5d                   	pop    %ebp
f010314c:	c3                   	ret    

f010314d <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f010314d:	55                   	push   %ebp
f010314e:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103150:	83 fa 01             	cmp    $0x1,%edx
f0103153:	7e 0e                	jle    f0103163 <getint+0x16>
		return va_arg(*ap, long long);
f0103155:	8b 10                	mov    (%eax),%edx
f0103157:	8d 4a 08             	lea    0x8(%edx),%ecx
f010315a:	89 08                	mov    %ecx,(%eax)
f010315c:	8b 02                	mov    (%edx),%eax
f010315e:	8b 52 04             	mov    0x4(%edx),%edx
f0103161:	eb 22                	jmp    f0103185 <getint+0x38>
	else if (lflag)
f0103163:	85 d2                	test   %edx,%edx
f0103165:	74 10                	je     f0103177 <getint+0x2a>
		return va_arg(*ap, long);
f0103167:	8b 10                	mov    (%eax),%edx
f0103169:	8d 4a 04             	lea    0x4(%edx),%ecx
f010316c:	89 08                	mov    %ecx,(%eax)
f010316e:	8b 02                	mov    (%edx),%eax
f0103170:	89 c2                	mov    %eax,%edx
f0103172:	c1 fa 1f             	sar    $0x1f,%edx
f0103175:	eb 0e                	jmp    f0103185 <getint+0x38>
	else
		return va_arg(*ap, int);
f0103177:	8b 10                	mov    (%eax),%edx
f0103179:	8d 4a 04             	lea    0x4(%edx),%ecx
f010317c:	89 08                	mov    %ecx,(%eax)
f010317e:	8b 02                	mov    (%edx),%eax
f0103180:	89 c2                	mov    %eax,%edx
f0103182:	c1 fa 1f             	sar    $0x1f,%edx
}
f0103185:	5d                   	pop    %ebp
f0103186:	c3                   	ret    

f0103187 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103187:	55                   	push   %ebp
f0103188:	89 e5                	mov    %esp,%ebp
f010318a:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010318d:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103191:	8b 10                	mov    (%eax),%edx
f0103193:	3b 50 04             	cmp    0x4(%eax),%edx
f0103196:	73 0a                	jae    f01031a2 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103198:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010319b:	88 0a                	mov    %cl,(%edx)
f010319d:	83 c2 01             	add    $0x1,%edx
f01031a0:	89 10                	mov    %edx,(%eax)
}
f01031a2:	5d                   	pop    %ebp
f01031a3:	c3                   	ret    

f01031a4 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01031a4:	55                   	push   %ebp
f01031a5:	89 e5                	mov    %esp,%ebp
f01031a7:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01031aa:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01031ad:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01031b1:	8b 45 10             	mov    0x10(%ebp),%eax
f01031b4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01031b8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031bb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01031c2:	89 04 24             	mov    %eax,(%esp)
f01031c5:	e8 02 00 00 00       	call   f01031cc <vprintfmt>
	va_end(ap);
}
f01031ca:	c9                   	leave  
f01031cb:	c3                   	ret    

f01031cc <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01031cc:	55                   	push   %ebp
f01031cd:	89 e5                	mov    %esp,%ebp
f01031cf:	57                   	push   %edi
f01031d0:	56                   	push   %esi
f01031d1:	53                   	push   %ebx
f01031d2:	83 ec 4c             	sub    $0x4c,%esp
f01031d5:	8b 75 08             	mov    0x8(%ebp),%esi
f01031d8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01031db:	8b 7d 10             	mov    0x10(%ebp),%edi
f01031de:	eb 11                	jmp    f01031f1 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01031e0:	85 c0                	test   %eax,%eax
f01031e2:	0f 84 93 03 00 00    	je     f010357b <vprintfmt+0x3af>
				return;
			putch(ch, putdat);
f01031e8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01031ec:	89 04 24             	mov    %eax,(%esp)
f01031ef:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01031f1:	0f b6 07             	movzbl (%edi),%eax
f01031f4:	83 c7 01             	add    $0x1,%edi
f01031f7:	83 f8 25             	cmp    $0x25,%eax
f01031fa:	75 e4                	jne    f01031e0 <vprintfmt+0x14>
f01031fc:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f0103200:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0103207:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f010320e:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0103215:	ba 00 00 00 00       	mov    $0x0,%edx
f010321a:	eb 2b                	jmp    f0103247 <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010321c:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f010321f:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f0103223:	eb 22                	jmp    f0103247 <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103225:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103228:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f010322c:	eb 19                	jmp    f0103247 <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010322e:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0103231:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103238:	eb 0d                	jmp    f0103247 <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010323a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010323d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103240:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103247:	0f b6 0f             	movzbl (%edi),%ecx
f010324a:	8d 47 01             	lea    0x1(%edi),%eax
f010324d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103250:	0f b6 07             	movzbl (%edi),%eax
f0103253:	83 e8 23             	sub    $0x23,%eax
f0103256:	3c 55                	cmp    $0x55,%al
f0103258:	0f 87 f8 02 00 00    	ja     f0103556 <vprintfmt+0x38a>
f010325e:	0f b6 c0             	movzbl %al,%eax
f0103261:	ff 24 85 38 4c 10 f0 	jmp    *-0xfefb3c8(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103268:	83 e9 30             	sub    $0x30,%ecx
f010326b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
f010326e:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
f0103272:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0103275:	83 f9 09             	cmp    $0x9,%ecx
f0103278:	77 57                	ja     f01032d1 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010327a:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010327d:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0103280:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103283:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0103286:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0103289:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f010328d:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0103290:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0103293:	83 f9 09             	cmp    $0x9,%ecx
f0103296:	76 eb                	jbe    f0103283 <vprintfmt+0xb7>
f0103298:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010329b:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010329e:	eb 34                	jmp    f01032d4 <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01032a0:	8b 45 14             	mov    0x14(%ebp),%eax
f01032a3:	8d 48 04             	lea    0x4(%eax),%ecx
f01032a6:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01032a9:	8b 00                	mov    (%eax),%eax
f01032ab:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032ae:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01032b1:	eb 21                	jmp    f01032d4 <vprintfmt+0x108>

		case '.':
			if (width < 0)
f01032b3:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01032b7:	0f 88 71 ff ff ff    	js     f010322e <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032bd:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01032c0:	eb 85                	jmp    f0103247 <vprintfmt+0x7b>
f01032c2:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01032c5:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f01032cc:	e9 76 ff ff ff       	jmp    f0103247 <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032d1:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f01032d4:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01032d8:	0f 89 69 ff ff ff    	jns    f0103247 <vprintfmt+0x7b>
f01032de:	e9 57 ff ff ff       	jmp    f010323a <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01032e3:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032e6:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01032e9:	e9 59 ff ff ff       	jmp    f0103247 <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01032ee:	8b 45 14             	mov    0x14(%ebp),%eax
f01032f1:	8d 50 04             	lea    0x4(%eax),%edx
f01032f4:	89 55 14             	mov    %edx,0x14(%ebp)
f01032f7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01032fb:	8b 00                	mov    (%eax),%eax
f01032fd:	89 04 24             	mov    %eax,(%esp)
f0103300:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103302:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103305:	e9 e7 fe ff ff       	jmp    f01031f1 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010330a:	8b 45 14             	mov    0x14(%ebp),%eax
f010330d:	8d 50 04             	lea    0x4(%eax),%edx
f0103310:	89 55 14             	mov    %edx,0x14(%ebp)
f0103313:	8b 00                	mov    (%eax),%eax
f0103315:	89 c2                	mov    %eax,%edx
f0103317:	c1 fa 1f             	sar    $0x1f,%edx
f010331a:	31 d0                	xor    %edx,%eax
f010331c:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
f010331e:	83 f8 06             	cmp    $0x6,%eax
f0103321:	7f 0b                	jg     f010332e <vprintfmt+0x162>
f0103323:	8b 14 85 90 4d 10 f0 	mov    -0xfefb270(,%eax,4),%edx
f010332a:	85 d2                	test   %edx,%edx
f010332c:	75 20                	jne    f010334e <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
f010332e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103332:	c7 44 24 08 c5 4b 10 	movl   $0xf0104bc5,0x8(%esp)
f0103339:	f0 
f010333a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010333e:	89 34 24             	mov    %esi,(%esp)
f0103341:	e8 5e fe ff ff       	call   f01031a4 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103346:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103349:	e9 a3 fe ff ff       	jmp    f01031f1 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010334e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103352:	c7 44 24 08 f4 48 10 	movl   $0xf01048f4,0x8(%esp)
f0103359:	f0 
f010335a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010335e:	89 34 24             	mov    %esi,(%esp)
f0103361:	e8 3e fe ff ff       	call   f01031a4 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103366:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103369:	e9 83 fe ff ff       	jmp    f01031f1 <vprintfmt+0x25>
f010336e:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103371:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0103374:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103377:	8b 45 14             	mov    0x14(%ebp),%eax
f010337a:	8d 50 04             	lea    0x4(%eax),%edx
f010337d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103380:	8b 38                	mov    (%eax),%edi
f0103382:	85 ff                	test   %edi,%edi
f0103384:	75 05                	jne    f010338b <vprintfmt+0x1bf>
				p = "(null)";
f0103386:	bf be 4b 10 f0       	mov    $0xf0104bbe,%edi
			if (width > 0 && padc != '-')
f010338b:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f010338f:	74 06                	je     f0103397 <vprintfmt+0x1cb>
f0103391:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0103395:	7f 16                	jg     f01033ad <vprintfmt+0x1e1>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103397:	0f b6 17             	movzbl (%edi),%edx
f010339a:	0f be c2             	movsbl %dl,%eax
f010339d:	83 c7 01             	add    $0x1,%edi
f01033a0:	85 c0                	test   %eax,%eax
f01033a2:	0f 85 9f 00 00 00    	jne    f0103447 <vprintfmt+0x27b>
f01033a8:	e9 8b 00 00 00       	jmp    f0103438 <vprintfmt+0x26c>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01033ad:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01033b1:	89 3c 24             	mov    %edi,(%esp)
f01033b4:	e8 39 03 00 00       	call   f01036f2 <strnlen>
f01033b9:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01033bc:	29 c2                	sub    %eax,%edx
f01033be:	89 55 d8             	mov    %edx,-0x28(%ebp)
f01033c1:	85 d2                	test   %edx,%edx
f01033c3:	7e d2                	jle    f0103397 <vprintfmt+0x1cb>
					putch(padc, putdat);
f01033c5:	0f be 45 e4          	movsbl -0x1c(%ebp),%eax
f01033c9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01033cc:	89 7d cc             	mov    %edi,-0x34(%ebp)
f01033cf:	89 d7                	mov    %edx,%edi
f01033d1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01033d5:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01033d8:	89 14 24             	mov    %edx,(%esp)
f01033db:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01033dd:	83 ef 01             	sub    $0x1,%edi
f01033e0:	75 ef                	jne    f01033d1 <vprintfmt+0x205>
f01033e2:	89 7d d8             	mov    %edi,-0x28(%ebp)
f01033e5:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01033e8:	eb ad                	jmp    f0103397 <vprintfmt+0x1cb>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01033ea:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01033ee:	74 20                	je     f0103410 <vprintfmt+0x244>
f01033f0:	0f be d2             	movsbl %dl,%edx
f01033f3:	83 ea 20             	sub    $0x20,%edx
f01033f6:	83 fa 5e             	cmp    $0x5e,%edx
f01033f9:	76 15                	jbe    f0103410 <vprintfmt+0x244>
					putch('?', putdat);
f01033fb:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01033fe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103402:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103409:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010340c:	ff d2                	call   *%edx
f010340e:	eb 0f                	jmp    f010341f <vprintfmt+0x253>
				else
					putch(ch, putdat);
f0103410:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103413:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103417:	89 04 24             	mov    %eax,(%esp)
f010341a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010341d:	ff d0                	call   *%eax
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010341f:	83 eb 01             	sub    $0x1,%ebx
f0103422:	0f b6 17             	movzbl (%edi),%edx
f0103425:	0f be c2             	movsbl %dl,%eax
f0103428:	83 c7 01             	add    $0x1,%edi
f010342b:	85 c0                	test   %eax,%eax
f010342d:	75 24                	jne    f0103453 <vprintfmt+0x287>
f010342f:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0103432:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103435:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103438:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010343b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010343f:	0f 8e ac fd ff ff    	jle    f01031f1 <vprintfmt+0x25>
f0103445:	eb 20                	jmp    f0103467 <vprintfmt+0x29b>
f0103447:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f010344a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010344d:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0103450:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103453:	85 f6                	test   %esi,%esi
f0103455:	78 93                	js     f01033ea <vprintfmt+0x21e>
f0103457:	83 ee 01             	sub    $0x1,%esi
f010345a:	79 8e                	jns    f01033ea <vprintfmt+0x21e>
f010345c:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f010345f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103462:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103465:	eb d1                	jmp    f0103438 <vprintfmt+0x26c>
f0103467:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010346a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010346e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103475:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103477:	83 ef 01             	sub    $0x1,%edi
f010347a:	75 ee                	jne    f010346a <vprintfmt+0x29e>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010347c:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010347f:	e9 6d fd ff ff       	jmp    f01031f1 <vprintfmt+0x25>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103484:	8d 45 14             	lea    0x14(%ebp),%eax
f0103487:	e8 c1 fc ff ff       	call   f010314d <getint>
f010348c:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010348f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103492:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103497:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f010349b:	79 7d                	jns    f010351a <vprintfmt+0x34e>
				putch('-', putdat);
f010349d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01034a1:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01034a8:	ff d6                	call   *%esi
				num = -(long long) num;
f01034aa:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01034ad:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01034b0:	f7 d8                	neg    %eax
f01034b2:	83 d2 00             	adc    $0x0,%edx
f01034b5:	f7 da                	neg    %edx
			}
			base = 10;
f01034b7:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01034bc:	eb 5c                	jmp    f010351a <vprintfmt+0x34e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01034be:	8d 45 14             	lea    0x14(%ebp),%eax
f01034c1:	e8 4d fc ff ff       	call   f0103113 <getuint>
			base = 10;
f01034c6:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01034cb:	eb 4d                	jmp    f010351a <vprintfmt+0x34e>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap, lflag);
f01034cd:	8d 45 14             	lea    0x14(%ebp),%eax
f01034d0:	e8 78 fc ff ff       	call   f010314d <getint>
			base = 8;
f01034d5:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01034da:	eb 3e                	jmp    f010351a <vprintfmt+0x34e>
			// pointer
		case 'p':
			putch('0', putdat);
f01034dc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01034e0:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01034e7:	ff d6                	call   *%esi
			putch('x', putdat);
f01034e9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01034ed:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01034f4:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01034f6:	8b 45 14             	mov    0x14(%ebp),%eax
f01034f9:	8d 50 04             	lea    0x4(%eax),%edx
f01034fc:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
			// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01034ff:	8b 00                	mov    (%eax),%eax
f0103501:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103506:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f010350b:	eb 0d                	jmp    f010351a <vprintfmt+0x34e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010350d:	8d 45 14             	lea    0x14(%ebp),%eax
f0103510:	e8 fe fb ff ff       	call   f0103113 <getuint>
			base = 16;
f0103515:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f010351a:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f010351e:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0103522:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0103525:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103529:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010352d:	89 04 24             	mov    %eax,(%esp)
f0103530:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103534:	89 da                	mov    %ebx,%edx
f0103536:	89 f0                	mov    %esi,%eax
f0103538:	e8 e3 fa ff ff       	call   f0103020 <printnum>
			break;
f010353d:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103540:	e9 ac fc ff ff       	jmp    f01031f1 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103545:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103549:	89 0c 24             	mov    %ecx,(%esp)
f010354c:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010354e:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103551:	e9 9b fc ff ff       	jmp    f01031f1 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103556:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010355a:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103561:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103563:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103567:	0f 84 84 fc ff ff    	je     f01031f1 <vprintfmt+0x25>
f010356d:	83 ef 01             	sub    $0x1,%edi
f0103570:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103574:	75 f7                	jne    f010356d <vprintfmt+0x3a1>
f0103576:	e9 76 fc ff ff       	jmp    f01031f1 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010357b:	83 c4 4c             	add    $0x4c,%esp
f010357e:	5b                   	pop    %ebx
f010357f:	5e                   	pop    %esi
f0103580:	5f                   	pop    %edi
f0103581:	5d                   	pop    %ebp
f0103582:	c3                   	ret    

f0103583 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103583:	55                   	push   %ebp
f0103584:	89 e5                	mov    %esp,%ebp
f0103586:	83 ec 28             	sub    $0x28,%esp
f0103589:	8b 45 08             	mov    0x8(%ebp),%eax
f010358c:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010358f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103592:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103596:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103599:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01035a0:	85 d2                	test   %edx,%edx
f01035a2:	7e 30                	jle    f01035d4 <vsnprintf+0x51>
f01035a4:	85 c0                	test   %eax,%eax
f01035a6:	74 2c                	je     f01035d4 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01035a8:	8b 45 14             	mov    0x14(%ebp),%eax
f01035ab:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035af:	8b 45 10             	mov    0x10(%ebp),%eax
f01035b2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01035b6:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01035b9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035bd:	c7 04 24 87 31 10 f0 	movl   $0xf0103187,(%esp)
f01035c4:	e8 03 fc ff ff       	call   f01031cc <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01035c9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01035cc:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01035cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01035d2:	eb 05                	jmp    f01035d9 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01035d4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01035d9:	c9                   	leave  
f01035da:	c3                   	ret    

f01035db <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01035db:	55                   	push   %ebp
f01035dc:	89 e5                	mov    %esp,%ebp
f01035de:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01035e1:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01035e4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035e8:	8b 45 10             	mov    0x10(%ebp),%eax
f01035eb:	89 44 24 08          	mov    %eax,0x8(%esp)
f01035ef:	8b 45 0c             	mov    0xc(%ebp),%eax
f01035f2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035f6:	8b 45 08             	mov    0x8(%ebp),%eax
f01035f9:	89 04 24             	mov    %eax,(%esp)
f01035fc:	e8 82 ff ff ff       	call   f0103583 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103601:	c9                   	leave  
f0103602:	c3                   	ret    
	...

f0103610 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103610:	55                   	push   %ebp
f0103611:	89 e5                	mov    %esp,%ebp
f0103613:	57                   	push   %edi
f0103614:	56                   	push   %esi
f0103615:	53                   	push   %ebx
f0103616:	83 ec 1c             	sub    $0x1c,%esp
f0103619:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010361c:	85 c0                	test   %eax,%eax
f010361e:	74 10                	je     f0103630 <readline+0x20>
		cprintf("%s", prompt);
f0103620:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103624:	c7 04 24 f4 48 10 f0 	movl   $0xf01048f4,(%esp)
f010362b:	e8 12 f7 ff ff       	call   f0102d42 <cprintf>

	i = 0;
	echoing = iscons(0);
f0103630:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103637:	e8 5c d0 ff ff       	call   f0100698 <iscons>
f010363c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010363e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103643:	e8 3f d0 ff ff       	call   f0100687 <getchar>
f0103648:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010364a:	85 c0                	test   %eax,%eax
f010364c:	79 17                	jns    f0103665 <readline+0x55>
			cprintf("read error: %e\n", c);
f010364e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103652:	c7 04 24 ac 4d 10 f0 	movl   $0xf0104dac,(%esp)
f0103659:	e8 e4 f6 ff ff       	call   f0102d42 <cprintf>
			return NULL;
f010365e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103663:	eb 61                	jmp    f01036c6 <readline+0xb6>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103665:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010366b:	7f 1c                	jg     f0103689 <readline+0x79>
f010366d:	83 f8 1f             	cmp    $0x1f,%eax
f0103670:	7e 17                	jle    f0103689 <readline+0x79>
			if (echoing)
f0103672:	85 ff                	test   %edi,%edi
f0103674:	74 08                	je     f010367e <readline+0x6e>
				cputchar(c);
f0103676:	89 04 24             	mov    %eax,(%esp)
f0103679:	e8 f6 cf ff ff       	call   f0100674 <cputchar>
			buf[i++] = c;
f010367e:	88 9e 00 66 11 f0    	mov    %bl,-0xfee9a00(%esi)
f0103684:	83 c6 01             	add    $0x1,%esi
f0103687:	eb ba                	jmp    f0103643 <readline+0x33>
		} else if (c == '\b' && i > 0) {
f0103689:	85 f6                	test   %esi,%esi
f010368b:	7e 16                	jle    f01036a3 <readline+0x93>
f010368d:	83 fb 08             	cmp    $0x8,%ebx
f0103690:	75 11                	jne    f01036a3 <readline+0x93>
			if (echoing)
f0103692:	85 ff                	test   %edi,%edi
f0103694:	74 08                	je     f010369e <readline+0x8e>
				cputchar(c);
f0103696:	89 1c 24             	mov    %ebx,(%esp)
f0103699:	e8 d6 cf ff ff       	call   f0100674 <cputchar>
			i--;
f010369e:	83 ee 01             	sub    $0x1,%esi
f01036a1:	eb a0                	jmp    f0103643 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01036a3:	83 fb 0d             	cmp    $0xd,%ebx
f01036a6:	74 05                	je     f01036ad <readline+0x9d>
f01036a8:	83 fb 0a             	cmp    $0xa,%ebx
f01036ab:	75 96                	jne    f0103643 <readline+0x33>
			if (echoing)
f01036ad:	85 ff                	test   %edi,%edi
f01036af:	90                   	nop
f01036b0:	74 08                	je     f01036ba <readline+0xaa>
				cputchar(c);
f01036b2:	89 1c 24             	mov    %ebx,(%esp)
f01036b5:	e8 ba cf ff ff       	call   f0100674 <cputchar>
			buf[i] = 0;
f01036ba:	c6 86 00 66 11 f0 00 	movb   $0x0,-0xfee9a00(%esi)
			return buf;
f01036c1:	b8 00 66 11 f0       	mov    $0xf0116600,%eax
		}
	}
}
f01036c6:	83 c4 1c             	add    $0x1c,%esp
f01036c9:	5b                   	pop    %ebx
f01036ca:	5e                   	pop    %esi
f01036cb:	5f                   	pop    %edi
f01036cc:	5d                   	pop    %ebp
f01036cd:	c3                   	ret    
	...

f01036d0 <strlen>:

#include <inc/string.h>

int
strlen(const char *s)
{
f01036d0:	55                   	push   %ebp
f01036d1:	89 e5                	mov    %esp,%ebp
f01036d3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01036d6:	80 3a 00             	cmpb   $0x0,(%edx)
f01036d9:	74 10                	je     f01036eb <strlen+0x1b>
f01036db:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01036e0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01036e3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01036e7:	75 f7                	jne    f01036e0 <strlen+0x10>
f01036e9:	eb 05                	jmp    f01036f0 <strlen+0x20>
f01036eb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01036f0:	5d                   	pop    %ebp
f01036f1:	c3                   	ret    

f01036f2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01036f2:	55                   	push   %ebp
f01036f3:	89 e5                	mov    %esp,%ebp
f01036f5:	53                   	push   %ebx
f01036f6:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01036f9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01036fc:	85 c9                	test   %ecx,%ecx
f01036fe:	74 1c                	je     f010371c <strnlen+0x2a>
f0103700:	80 3b 00             	cmpb   $0x0,(%ebx)
f0103703:	74 1e                	je     f0103723 <strnlen+0x31>
f0103705:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f010370a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010370c:	39 ca                	cmp    %ecx,%edx
f010370e:	74 18                	je     f0103728 <strnlen+0x36>
f0103710:	83 c2 01             	add    $0x1,%edx
f0103713:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0103718:	75 f0                	jne    f010370a <strnlen+0x18>
f010371a:	eb 0c                	jmp    f0103728 <strnlen+0x36>
f010371c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103721:	eb 05                	jmp    f0103728 <strnlen+0x36>
f0103723:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0103728:	5b                   	pop    %ebx
f0103729:	5d                   	pop    %ebp
f010372a:	c3                   	ret    

f010372b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010372b:	55                   	push   %ebp
f010372c:	89 e5                	mov    %esp,%ebp
f010372e:	53                   	push   %ebx
f010372f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103732:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103735:	89 c2                	mov    %eax,%edx
f0103737:	0f b6 19             	movzbl (%ecx),%ebx
f010373a:	88 1a                	mov    %bl,(%edx)
f010373c:	83 c2 01             	add    $0x1,%edx
f010373f:	83 c1 01             	add    $0x1,%ecx
f0103742:	84 db                	test   %bl,%bl
f0103744:	75 f1                	jne    f0103737 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103746:	5b                   	pop    %ebx
f0103747:	5d                   	pop    %ebp
f0103748:	c3                   	ret    

f0103749 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103749:	55                   	push   %ebp
f010374a:	89 e5                	mov    %esp,%ebp
f010374c:	56                   	push   %esi
f010374d:	53                   	push   %ebx
f010374e:	8b 75 08             	mov    0x8(%ebp),%esi
f0103751:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103754:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103757:	85 db                	test   %ebx,%ebx
f0103759:	74 16                	je     f0103771 <strncpy+0x28>
		/* do nothing */;
	return ret;
}

char *
strncpy(char *dst, const char *src, size_t size) {
f010375b:	01 f3                	add    %esi,%ebx
f010375d:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
f010375f:	0f b6 02             	movzbl (%edx),%eax
f0103762:	88 01                	mov    %al,(%ecx)
f0103764:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103767:	80 3a 01             	cmpb   $0x1,(%edx)
f010376a:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010376d:	39 d9                	cmp    %ebx,%ecx
f010376f:	75 ee                	jne    f010375f <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103771:	89 f0                	mov    %esi,%eax
f0103773:	5b                   	pop    %ebx
f0103774:	5e                   	pop    %esi
f0103775:	5d                   	pop    %ebp
f0103776:	c3                   	ret    

f0103777 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103777:	55                   	push   %ebp
f0103778:	89 e5                	mov    %esp,%ebp
f010377a:	57                   	push   %edi
f010377b:	56                   	push   %esi
f010377c:	53                   	push   %ebx
f010377d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103780:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103783:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103786:	89 f8                	mov    %edi,%eax
f0103788:	85 f6                	test   %esi,%esi
f010378a:	74 33                	je     f01037bf <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
f010378c:	83 fe 01             	cmp    $0x1,%esi
f010378f:	74 25                	je     f01037b6 <strlcpy+0x3f>
f0103791:	0f b6 0b             	movzbl (%ebx),%ecx
f0103794:	84 c9                	test   %cl,%cl
f0103796:	74 22                	je     f01037ba <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0103798:	83 ee 02             	sub    $0x2,%esi
f010379b:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01037a0:	88 08                	mov    %cl,(%eax)
f01037a2:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01037a5:	39 f2                	cmp    %esi,%edx
f01037a7:	74 13                	je     f01037bc <strlcpy+0x45>
f01037a9:	83 c2 01             	add    $0x1,%edx
f01037ac:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01037b0:	84 c9                	test   %cl,%cl
f01037b2:	75 ec                	jne    f01037a0 <strlcpy+0x29>
f01037b4:	eb 06                	jmp    f01037bc <strlcpy+0x45>
f01037b6:	89 f8                	mov    %edi,%eax
f01037b8:	eb 02                	jmp    f01037bc <strlcpy+0x45>
f01037ba:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f01037bc:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01037bf:	29 f8                	sub    %edi,%eax
}
f01037c1:	5b                   	pop    %ebx
f01037c2:	5e                   	pop    %esi
f01037c3:	5f                   	pop    %edi
f01037c4:	5d                   	pop    %ebp
f01037c5:	c3                   	ret    

f01037c6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01037c6:	55                   	push   %ebp
f01037c7:	89 e5                	mov    %esp,%ebp
f01037c9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01037cc:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01037cf:	0f b6 01             	movzbl (%ecx),%eax
f01037d2:	84 c0                	test   %al,%al
f01037d4:	74 15                	je     f01037eb <strcmp+0x25>
f01037d6:	3a 02                	cmp    (%edx),%al
f01037d8:	75 11                	jne    f01037eb <strcmp+0x25>
		p++, q++;
f01037da:	83 c1 01             	add    $0x1,%ecx
f01037dd:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01037e0:	0f b6 01             	movzbl (%ecx),%eax
f01037e3:	84 c0                	test   %al,%al
f01037e5:	74 04                	je     f01037eb <strcmp+0x25>
f01037e7:	3a 02                	cmp    (%edx),%al
f01037e9:	74 ef                	je     f01037da <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01037eb:	0f b6 c0             	movzbl %al,%eax
f01037ee:	0f b6 12             	movzbl (%edx),%edx
f01037f1:	29 d0                	sub    %edx,%eax
}
f01037f3:	5d                   	pop    %ebp
f01037f4:	c3                   	ret    

f01037f5 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01037f5:	55                   	push   %ebp
f01037f6:	89 e5                	mov    %esp,%ebp
f01037f8:	56                   	push   %esi
f01037f9:	53                   	push   %ebx
f01037fa:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01037fd:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103800:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f0103803:	85 f6                	test   %esi,%esi
f0103805:	74 29                	je     f0103830 <strncmp+0x3b>
f0103807:	0f b6 03             	movzbl (%ebx),%eax
f010380a:	84 c0                	test   %al,%al
f010380c:	74 30                	je     f010383e <strncmp+0x49>
f010380e:	3a 02                	cmp    (%edx),%al
f0103810:	75 2c                	jne    f010383e <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
f0103812:	8d 43 01             	lea    0x1(%ebx),%eax
f0103815:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
f0103817:	89 c3                	mov    %eax,%ebx
f0103819:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010381c:	39 f0                	cmp    %esi,%eax
f010381e:	74 17                	je     f0103837 <strncmp+0x42>
f0103820:	0f b6 08             	movzbl (%eax),%ecx
f0103823:	84 c9                	test   %cl,%cl
f0103825:	74 17                	je     f010383e <strncmp+0x49>
f0103827:	83 c0 01             	add    $0x1,%eax
f010382a:	3a 0a                	cmp    (%edx),%cl
f010382c:	74 e9                	je     f0103817 <strncmp+0x22>
f010382e:	eb 0e                	jmp    f010383e <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103830:	b8 00 00 00 00       	mov    $0x0,%eax
f0103835:	eb 0f                	jmp    f0103846 <strncmp+0x51>
f0103837:	b8 00 00 00 00       	mov    $0x0,%eax
f010383c:	eb 08                	jmp    f0103846 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010383e:	0f b6 03             	movzbl (%ebx),%eax
f0103841:	0f b6 12             	movzbl (%edx),%edx
f0103844:	29 d0                	sub    %edx,%eax
}
f0103846:	5b                   	pop    %ebx
f0103847:	5e                   	pop    %esi
f0103848:	5d                   	pop    %ebp
f0103849:	c3                   	ret    

f010384a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010384a:	55                   	push   %ebp
f010384b:	89 e5                	mov    %esp,%ebp
f010384d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103850:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103854:	0f b6 10             	movzbl (%eax),%edx
f0103857:	84 d2                	test   %dl,%dl
f0103859:	74 1b                	je     f0103876 <strchr+0x2c>
		if (*s == c)
f010385b:	38 ca                	cmp    %cl,%dl
f010385d:	75 06                	jne    f0103865 <strchr+0x1b>
f010385f:	eb 1a                	jmp    f010387b <strchr+0x31>
f0103861:	38 ca                	cmp    %cl,%dl
f0103863:	74 16                	je     f010387b <strchr+0x31>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103865:	83 c0 01             	add    $0x1,%eax
f0103868:	0f b6 10             	movzbl (%eax),%edx
f010386b:	84 d2                	test   %dl,%dl
f010386d:	75 f2                	jne    f0103861 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f010386f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103874:	eb 05                	jmp    f010387b <strchr+0x31>
f0103876:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010387b:	5d                   	pop    %ebp
f010387c:	c3                   	ret    

f010387d <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010387d:	55                   	push   %ebp
f010387e:	89 e5                	mov    %esp,%ebp
f0103880:	8b 45 08             	mov    0x8(%ebp),%eax
f0103883:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103887:	0f b6 10             	movzbl (%eax),%edx
f010388a:	84 d2                	test   %dl,%dl
f010388c:	74 14                	je     f01038a2 <strfind+0x25>
		if (*s == c)
f010388e:	38 ca                	cmp    %cl,%dl
f0103890:	75 06                	jne    f0103898 <strfind+0x1b>
f0103892:	eb 0e                	jmp    f01038a2 <strfind+0x25>
f0103894:	38 ca                	cmp    %cl,%dl
f0103896:	74 0a                	je     f01038a2 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0103898:	83 c0 01             	add    $0x1,%eax
f010389b:	0f b6 10             	movzbl (%eax),%edx
f010389e:	84 d2                	test   %dl,%dl
f01038a0:	75 f2                	jne    f0103894 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f01038a2:	5d                   	pop    %ebp
f01038a3:	c3                   	ret    

f01038a4 <memset>:


void *
memset(void *v, int c, size_t n)
{
f01038a4:	55                   	push   %ebp
f01038a5:	89 e5                	mov    %esp,%ebp
f01038a7:	53                   	push   %ebx
f01038a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01038ab:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01038ae:	8b 5d 10             	mov    0x10(%ebp),%ebx
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f01038b1:	89 da                	mov    %ebx,%edx
f01038b3:	83 ea 01             	sub    $0x1,%edx
f01038b6:	78 0d                	js     f01038c5 <memset+0x21>
	return (char *) s;
}


void *
memset(void *v, int c, size_t n)
f01038b8:	01 c3                	add    %eax,%ebx
{
	char *p;
	int m;

	p = v;
f01038ba:	89 c2                	mov    %eax,%edx
	m = n;
	while (--m >= 0)
		*p++ = c;
f01038bc:	88 0a                	mov    %cl,(%edx)
f01038be:	83 c2 01             	add    $0x1,%edx
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f01038c1:	39 da                	cmp    %ebx,%edx
f01038c3:	75 f7                	jne    f01038bc <memset+0x18>
		*p++ = c;

	return v;
}
f01038c5:	5b                   	pop    %ebx
f01038c6:	5d                   	pop    %ebp
f01038c7:	c3                   	ret    

f01038c8 <memmove>:

/* no memcpy - use memmove instead */

void *
memmove(void *dst, const void *src, size_t n)
{
f01038c8:	55                   	push   %ebp
f01038c9:	89 e5                	mov    %esp,%ebp
f01038cb:	57                   	push   %edi
f01038cc:	56                   	push   %esi
f01038cd:	53                   	push   %ebx
f01038ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01038d1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01038d4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01038d7:	39 c6                	cmp    %eax,%esi
f01038d9:	72 0b                	jb     f01038e6 <memmove+0x1e>
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f01038db:	ba 00 00 00 00       	mov    $0x0,%edx
f01038e0:	85 db                	test   %ebx,%ebx
f01038e2:	75 2b                	jne    f010390f <memmove+0x47>
f01038e4:	eb 37                	jmp    f010391d <memmove+0x55>
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01038e6:	8d 0c 1e             	lea    (%esi,%ebx,1),%ecx
f01038e9:	39 c8                	cmp    %ecx,%eax
f01038eb:	73 ee                	jae    f01038db <memmove+0x13>
		s += n;
		d += n;
f01038ed:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
		while (n-- > 0)
f01038f0:	8d 53 ff             	lea    -0x1(%ebx),%edx
f01038f3:	85 db                	test   %ebx,%ebx
f01038f5:	74 26                	je     f010391d <memmove+0x55>
}

/* no memcpy - use memmove instead */

void *
memmove(void *dst, const void *src, size_t n)
f01038f7:	f7 db                	neg    %ebx
f01038f9:	8d 34 19             	lea    (%ecx,%ebx,1),%esi
f01038fc:	01 fb                	add    %edi,%ebx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
f01038fe:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103902:	88 0c 13             	mov    %cl,(%ebx,%edx,1)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
f0103905:	83 ea 01             	sub    $0x1,%edx
f0103908:	83 fa ff             	cmp    $0xffffffff,%edx
f010390b:	75 f1                	jne    f01038fe <memmove+0x36>
f010390d:	eb 0e                	jmp    f010391d <memmove+0x55>
			*--d = *--s;
	} else
		while (n-- > 0)
			*d++ = *s++;
f010390f:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103913:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0103916:	83 c2 01             	add    $0x1,%edx
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f0103919:	39 da                	cmp    %ebx,%edx
f010391b:	75 f2                	jne    f010390f <memmove+0x47>
			*d++ = *s++;

	return dst;
}
f010391d:	5b                   	pop    %ebx
f010391e:	5e                   	pop    %esi
f010391f:	5f                   	pop    %edi
f0103920:	5d                   	pop    %ebp
f0103921:	c3                   	ret    

f0103922 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0103922:	55                   	push   %ebp
f0103923:	89 e5                	mov    %esp,%ebp
f0103925:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103928:	8b 45 10             	mov    0x10(%ebp),%eax
f010392b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010392f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103932:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103936:	8b 45 08             	mov    0x8(%ebp),%eax
f0103939:	89 04 24             	mov    %eax,(%esp)
f010393c:	e8 87 ff ff ff       	call   f01038c8 <memmove>
}
f0103941:	c9                   	leave  
f0103942:	c3                   	ret    

f0103943 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103943:	55                   	push   %ebp
f0103944:	89 e5                	mov    %esp,%ebp
f0103946:	57                   	push   %edi
f0103947:	56                   	push   %esi
f0103948:	53                   	push   %ebx
f0103949:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010394c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010394f:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103952:	8d 78 ff             	lea    -0x1(%eax),%edi
f0103955:	85 c0                	test   %eax,%eax
f0103957:	74 36                	je     f010398f <memcmp+0x4c>
		if (*s1 != *s2)
f0103959:	0f b6 03             	movzbl (%ebx),%eax
f010395c:	0f b6 0e             	movzbl (%esi),%ecx
f010395f:	38 c8                	cmp    %cl,%al
f0103961:	75 17                	jne    f010397a <memcmp+0x37>
f0103963:	ba 00 00 00 00       	mov    $0x0,%edx
f0103968:	eb 1a                	jmp    f0103984 <memcmp+0x41>
f010396a:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f010396f:	83 c2 01             	add    $0x1,%edx
f0103972:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103976:	38 c8                	cmp    %cl,%al
f0103978:	74 0a                	je     f0103984 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f010397a:	0f b6 c0             	movzbl %al,%eax
f010397d:	0f b6 c9             	movzbl %cl,%ecx
f0103980:	29 c8                	sub    %ecx,%eax
f0103982:	eb 10                	jmp    f0103994 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103984:	39 fa                	cmp    %edi,%edx
f0103986:	75 e2                	jne    f010396a <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103988:	b8 00 00 00 00       	mov    $0x0,%eax
f010398d:	eb 05                	jmp    f0103994 <memcmp+0x51>
f010398f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103994:	5b                   	pop    %ebx
f0103995:	5e                   	pop    %esi
f0103996:	5f                   	pop    %edi
f0103997:	5d                   	pop    %ebp
f0103998:	c3                   	ret    

f0103999 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103999:	55                   	push   %ebp
f010399a:	89 e5                	mov    %esp,%ebp
f010399c:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010399f:	89 c2                	mov    %eax,%edx
f01039a1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01039a4:	39 d0                	cmp    %edx,%eax
f01039a6:	73 15                	jae    f01039bd <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f01039a8:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f01039ac:	38 08                	cmp    %cl,(%eax)
f01039ae:	75 06                	jne    f01039b6 <memfind+0x1d>
f01039b0:	eb 0b                	jmp    f01039bd <memfind+0x24>
f01039b2:	38 08                	cmp    %cl,(%eax)
f01039b4:	74 07                	je     f01039bd <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01039b6:	83 c0 01             	add    $0x1,%eax
f01039b9:	39 d0                	cmp    %edx,%eax
f01039bb:	75 f5                	jne    f01039b2 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01039bd:	5d                   	pop    %ebp
f01039be:	66 90                	xchg   %ax,%ax
f01039c0:	c3                   	ret    

f01039c1 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01039c1:	55                   	push   %ebp
f01039c2:	89 e5                	mov    %esp,%ebp
f01039c4:	57                   	push   %edi
f01039c5:	56                   	push   %esi
f01039c6:	53                   	push   %ebx
f01039c7:	83 ec 04             	sub    $0x4,%esp
f01039ca:	8b 55 08             	mov    0x8(%ebp),%edx
f01039cd:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01039d0:	0f b6 02             	movzbl (%edx),%eax
f01039d3:	3c 09                	cmp    $0x9,%al
f01039d5:	74 04                	je     f01039db <strtol+0x1a>
f01039d7:	3c 20                	cmp    $0x20,%al
f01039d9:	75 0e                	jne    f01039e9 <strtol+0x28>
		s++;
f01039db:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01039de:	0f b6 02             	movzbl (%edx),%eax
f01039e1:	3c 09                	cmp    $0x9,%al
f01039e3:	74 f6                	je     f01039db <strtol+0x1a>
f01039e5:	3c 20                	cmp    $0x20,%al
f01039e7:	74 f2                	je     f01039db <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f01039e9:	3c 2b                	cmp    $0x2b,%al
f01039eb:	75 0a                	jne    f01039f7 <strtol+0x36>
		s++;
f01039ed:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01039f0:	bf 00 00 00 00       	mov    $0x0,%edi
f01039f5:	eb 10                	jmp    f0103a07 <strtol+0x46>
f01039f7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01039fc:	3c 2d                	cmp    $0x2d,%al
f01039fe:	75 07                	jne    f0103a07 <strtol+0x46>
		s++, neg = 1;
f0103a00:	83 c2 01             	add    $0x1,%edx
f0103a03:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103a07:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103a0d:	75 15                	jne    f0103a24 <strtol+0x63>
f0103a0f:	80 3a 30             	cmpb   $0x30,(%edx)
f0103a12:	75 10                	jne    f0103a24 <strtol+0x63>
f0103a14:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103a18:	75 0a                	jne    f0103a24 <strtol+0x63>
		s += 2, base = 16;
f0103a1a:	83 c2 02             	add    $0x2,%edx
f0103a1d:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103a22:	eb 10                	jmp    f0103a34 <strtol+0x73>
	else if (base == 0 && s[0] == '0')
f0103a24:	85 db                	test   %ebx,%ebx
f0103a26:	75 0c                	jne    f0103a34 <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103a28:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103a2a:	80 3a 30             	cmpb   $0x30,(%edx)
f0103a2d:	75 05                	jne    f0103a34 <strtol+0x73>
		s++, base = 8;
f0103a2f:	83 c2 01             	add    $0x1,%edx
f0103a32:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0103a34:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a39:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103a3c:	0f b6 0a             	movzbl (%edx),%ecx
f0103a3f:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0103a42:	89 f3                	mov    %esi,%ebx
f0103a44:	80 fb 09             	cmp    $0x9,%bl
f0103a47:	77 08                	ja     f0103a51 <strtol+0x90>
			dig = *s - '0';
f0103a49:	0f be c9             	movsbl %cl,%ecx
f0103a4c:	83 e9 30             	sub    $0x30,%ecx
f0103a4f:	eb 22                	jmp    f0103a73 <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
f0103a51:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0103a54:	89 f3                	mov    %esi,%ebx
f0103a56:	80 fb 19             	cmp    $0x19,%bl
f0103a59:	77 08                	ja     f0103a63 <strtol+0xa2>
			dig = *s - 'a' + 10;
f0103a5b:	0f be c9             	movsbl %cl,%ecx
f0103a5e:	83 e9 57             	sub    $0x57,%ecx
f0103a61:	eb 10                	jmp    f0103a73 <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
f0103a63:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0103a66:	89 f3                	mov    %esi,%ebx
f0103a68:	80 fb 19             	cmp    $0x19,%bl
f0103a6b:	77 16                	ja     f0103a83 <strtol+0xc2>
			dig = *s - 'A' + 10;
f0103a6d:	0f be c9             	movsbl %cl,%ecx
f0103a70:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103a73:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0103a76:	7d 0f                	jge    f0103a87 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
f0103a78:	83 c2 01             	add    $0x1,%edx
f0103a7b:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0103a7f:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0103a81:	eb b9                	jmp    f0103a3c <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0103a83:	89 c1                	mov    %eax,%ecx
f0103a85:	eb 02                	jmp    f0103a89 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103a87:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0103a89:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103a8d:	74 05                	je     f0103a94 <strtol+0xd3>
		*endptr = (char *) s;
f0103a8f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a92:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0103a94:	85 ff                	test   %edi,%edi
f0103a96:	74 04                	je     f0103a9c <strtol+0xdb>
f0103a98:	89 c8                	mov    %ecx,%eax
f0103a9a:	f7 d8                	neg    %eax
}
f0103a9c:	83 c4 04             	add    $0x4,%esp
f0103a9f:	5b                   	pop    %ebx
f0103aa0:	5e                   	pop    %esi
f0103aa1:	5f                   	pop    %edi
f0103aa2:	5d                   	pop    %ebp
f0103aa3:	c3                   	ret    
	...

f0103ab0 <__udivdi3>:
f0103ab0:	83 ec 1c             	sub    $0x1c,%esp
f0103ab3:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0103ab7:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103abb:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103abf:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0103ac3:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103ac7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103acb:	85 c0                	test   %eax,%eax
f0103acd:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103ad1:	89 cf                	mov    %ecx,%edi
f0103ad3:	89 6c 24 04          	mov    %ebp,0x4(%esp)
f0103ad7:	75 37                	jne    f0103b10 <__udivdi3+0x60>
f0103ad9:	39 f1                	cmp    %esi,%ecx
f0103adb:	77 73                	ja     f0103b50 <__udivdi3+0xa0>
f0103add:	85 c9                	test   %ecx,%ecx
f0103adf:	75 0b                	jne    f0103aec <__udivdi3+0x3c>
f0103ae1:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ae6:	31 d2                	xor    %edx,%edx
f0103ae8:	f7 f1                	div    %ecx
f0103aea:	89 c1                	mov    %eax,%ecx
f0103aec:	89 f0                	mov    %esi,%eax
f0103aee:	31 d2                	xor    %edx,%edx
f0103af0:	f7 f1                	div    %ecx
f0103af2:	89 c6                	mov    %eax,%esi
f0103af4:	89 e8                	mov    %ebp,%eax
f0103af6:	f7 f1                	div    %ecx
f0103af8:	89 f2                	mov    %esi,%edx
f0103afa:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103afe:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103b02:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103b06:	83 c4 1c             	add    $0x1c,%esp
f0103b09:	c3                   	ret    
f0103b0a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103b10:	39 f0                	cmp    %esi,%eax
f0103b12:	77 24                	ja     f0103b38 <__udivdi3+0x88>
f0103b14:	0f bd e8             	bsr    %eax,%ebp
f0103b17:	83 f5 1f             	xor    $0x1f,%ebp
f0103b1a:	75 4c                	jne    f0103b68 <__udivdi3+0xb8>
f0103b1c:	31 d2                	xor    %edx,%edx
f0103b1e:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0103b22:	0f 86 b0 00 00 00    	jbe    f0103bd8 <__udivdi3+0x128>
f0103b28:	39 f0                	cmp    %esi,%eax
f0103b2a:	0f 82 a8 00 00 00    	jb     f0103bd8 <__udivdi3+0x128>
f0103b30:	31 c0                	xor    %eax,%eax
f0103b32:	eb c6                	jmp    f0103afa <__udivdi3+0x4a>
f0103b34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103b38:	31 d2                	xor    %edx,%edx
f0103b3a:	31 c0                	xor    %eax,%eax
f0103b3c:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103b40:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103b44:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103b48:	83 c4 1c             	add    $0x1c,%esp
f0103b4b:	c3                   	ret    
f0103b4c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103b50:	89 e8                	mov    %ebp,%eax
f0103b52:	89 f2                	mov    %esi,%edx
f0103b54:	f7 f1                	div    %ecx
f0103b56:	31 d2                	xor    %edx,%edx
f0103b58:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103b5c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103b60:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103b64:	83 c4 1c             	add    $0x1c,%esp
f0103b67:	c3                   	ret    
f0103b68:	89 e9                	mov    %ebp,%ecx
f0103b6a:	89 fa                	mov    %edi,%edx
f0103b6c:	d3 e0                	shl    %cl,%eax
f0103b6e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103b72:	b8 20 00 00 00       	mov    $0x20,%eax
f0103b77:	29 e8                	sub    %ebp,%eax
f0103b79:	89 c1                	mov    %eax,%ecx
f0103b7b:	d3 ea                	shr    %cl,%edx
f0103b7d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0103b81:	09 ca                	or     %ecx,%edx
f0103b83:	89 e9                	mov    %ebp,%ecx
f0103b85:	d3 e7                	shl    %cl,%edi
f0103b87:	89 c1                	mov    %eax,%ecx
f0103b89:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103b8d:	89 f2                	mov    %esi,%edx
f0103b8f:	d3 ea                	shr    %cl,%edx
f0103b91:	89 e9                	mov    %ebp,%ecx
f0103b93:	89 14 24             	mov    %edx,(%esp)
f0103b96:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103b9a:	d3 e6                	shl    %cl,%esi
f0103b9c:	89 c1                	mov    %eax,%ecx
f0103b9e:	d3 ea                	shr    %cl,%edx
f0103ba0:	89 d0                	mov    %edx,%eax
f0103ba2:	09 f0                	or     %esi,%eax
f0103ba4:	8b 34 24             	mov    (%esp),%esi
f0103ba7:	89 f2                	mov    %esi,%edx
f0103ba9:	f7 74 24 0c          	divl   0xc(%esp)
f0103bad:	89 d6                	mov    %edx,%esi
f0103baf:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103bb3:	f7 e7                	mul    %edi
f0103bb5:	39 d6                	cmp    %edx,%esi
f0103bb7:	72 2f                	jb     f0103be8 <__udivdi3+0x138>
f0103bb9:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103bbd:	89 e9                	mov    %ebp,%ecx
f0103bbf:	d3 e7                	shl    %cl,%edi
f0103bc1:	39 c7                	cmp    %eax,%edi
f0103bc3:	73 04                	jae    f0103bc9 <__udivdi3+0x119>
f0103bc5:	39 d6                	cmp    %edx,%esi
f0103bc7:	74 1f                	je     f0103be8 <__udivdi3+0x138>
f0103bc9:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103bcd:	31 d2                	xor    %edx,%edx
f0103bcf:	e9 26 ff ff ff       	jmp    f0103afa <__udivdi3+0x4a>
f0103bd4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103bd8:	b8 01 00 00 00       	mov    $0x1,%eax
f0103bdd:	e9 18 ff ff ff       	jmp    f0103afa <__udivdi3+0x4a>
f0103be2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103be8:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103bec:	31 d2                	xor    %edx,%edx
f0103bee:	83 e8 01             	sub    $0x1,%eax
f0103bf1:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103bf5:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103bf9:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103bfd:	83 c4 1c             	add    $0x1c,%esp
f0103c00:	c3                   	ret    
	...

f0103c10 <__umoddi3>:
f0103c10:	83 ec 1c             	sub    $0x1c,%esp
f0103c13:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f0103c17:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103c1b:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103c1f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103c23:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103c27:	85 d2                	test   %edx,%edx
f0103c29:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103c2d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103c31:	89 cf                	mov    %ecx,%edi
f0103c33:	89 c5                	mov    %eax,%ebp
f0103c35:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103c39:	89 34 24             	mov    %esi,(%esp)
f0103c3c:	75 22                	jne    f0103c60 <__umoddi3+0x50>
f0103c3e:	39 f1                	cmp    %esi,%ecx
f0103c40:	76 56                	jbe    f0103c98 <__umoddi3+0x88>
f0103c42:	89 f2                	mov    %esi,%edx
f0103c44:	f7 f1                	div    %ecx
f0103c46:	89 d0                	mov    %edx,%eax
f0103c48:	31 d2                	xor    %edx,%edx
f0103c4a:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103c4e:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103c52:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103c56:	83 c4 1c             	add    $0x1c,%esp
f0103c59:	c3                   	ret    
f0103c5a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103c60:	39 f2                	cmp    %esi,%edx
f0103c62:	77 54                	ja     f0103cb8 <__umoddi3+0xa8>
f0103c64:	0f bd c2             	bsr    %edx,%eax
f0103c67:	83 f0 1f             	xor    $0x1f,%eax
f0103c6a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c6e:	75 60                	jne    f0103cd0 <__umoddi3+0xc0>
f0103c70:	39 e9                	cmp    %ebp,%ecx
f0103c72:	0f 87 08 01 00 00    	ja     f0103d80 <__umoddi3+0x170>
f0103c78:	29 cd                	sub    %ecx,%ebp
f0103c7a:	19 d6                	sbb    %edx,%esi
f0103c7c:	89 34 24             	mov    %esi,(%esp)
f0103c7f:	8b 14 24             	mov    (%esp),%edx
f0103c82:	89 e8                	mov    %ebp,%eax
f0103c84:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103c88:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103c8c:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103c90:	83 c4 1c             	add    $0x1c,%esp
f0103c93:	c3                   	ret    
f0103c94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103c98:	85 c9                	test   %ecx,%ecx
f0103c9a:	75 0b                	jne    f0103ca7 <__umoddi3+0x97>
f0103c9c:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ca1:	31 d2                	xor    %edx,%edx
f0103ca3:	f7 f1                	div    %ecx
f0103ca5:	89 c1                	mov    %eax,%ecx
f0103ca7:	89 f0                	mov    %esi,%eax
f0103ca9:	31 d2                	xor    %edx,%edx
f0103cab:	f7 f1                	div    %ecx
f0103cad:	89 e8                	mov    %ebp,%eax
f0103caf:	f7 f1                	div    %ecx
f0103cb1:	eb 93                	jmp    f0103c46 <__umoddi3+0x36>
f0103cb3:	90                   	nop
f0103cb4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103cb8:	89 f2                	mov    %esi,%edx
f0103cba:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103cbe:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103cc2:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103cc6:	83 c4 1c             	add    $0x1c,%esp
f0103cc9:	c3                   	ret    
f0103cca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103cd0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103cd5:	bd 20 00 00 00       	mov    $0x20,%ebp
f0103cda:	89 f8                	mov    %edi,%eax
f0103cdc:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0103ce0:	d3 e2                	shl    %cl,%edx
f0103ce2:	89 e9                	mov    %ebp,%ecx
f0103ce4:	d3 e8                	shr    %cl,%eax
f0103ce6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103ceb:	09 d0                	or     %edx,%eax
f0103ced:	89 f2                	mov    %esi,%edx
f0103cef:	89 04 24             	mov    %eax,(%esp)
f0103cf2:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103cf6:	d3 e7                	shl    %cl,%edi
f0103cf8:	89 e9                	mov    %ebp,%ecx
f0103cfa:	d3 ea                	shr    %cl,%edx
f0103cfc:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103d01:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103d05:	d3 e6                	shl    %cl,%esi
f0103d07:	89 e9                	mov    %ebp,%ecx
f0103d09:	d3 e8                	shr    %cl,%eax
f0103d0b:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103d10:	09 f0                	or     %esi,%eax
f0103d12:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103d16:	f7 34 24             	divl   (%esp)
f0103d19:	d3 e6                	shl    %cl,%esi
f0103d1b:	89 74 24 08          	mov    %esi,0x8(%esp)
f0103d1f:	89 d6                	mov    %edx,%esi
f0103d21:	f7 e7                	mul    %edi
f0103d23:	39 d6                	cmp    %edx,%esi
f0103d25:	89 c7                	mov    %eax,%edi
f0103d27:	89 d1                	mov    %edx,%ecx
f0103d29:	72 41                	jb     f0103d6c <__umoddi3+0x15c>
f0103d2b:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0103d2f:	72 37                	jb     f0103d68 <__umoddi3+0x158>
f0103d31:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103d35:	29 f8                	sub    %edi,%eax
f0103d37:	19 ce                	sbb    %ecx,%esi
f0103d39:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103d3e:	89 f2                	mov    %esi,%edx
f0103d40:	d3 e8                	shr    %cl,%eax
f0103d42:	89 e9                	mov    %ebp,%ecx
f0103d44:	d3 e2                	shl    %cl,%edx
f0103d46:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103d4b:	09 d0                	or     %edx,%eax
f0103d4d:	89 f2                	mov    %esi,%edx
f0103d4f:	d3 ea                	shr    %cl,%edx
f0103d51:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103d55:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103d59:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103d5d:	83 c4 1c             	add    $0x1c,%esp
f0103d60:	c3                   	ret    
f0103d61:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103d68:	39 d6                	cmp    %edx,%esi
f0103d6a:	75 c5                	jne    f0103d31 <__umoddi3+0x121>
f0103d6c:	89 d1                	mov    %edx,%ecx
f0103d6e:	89 c7                	mov    %eax,%edi
f0103d70:	2b 7c 24 0c          	sub    0xc(%esp),%edi
f0103d74:	1b 0c 24             	sbb    (%esp),%ecx
f0103d77:	eb b8                	jmp    f0103d31 <__umoddi3+0x121>
f0103d79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103d80:	39 f2                	cmp    %esi,%edx
f0103d82:	0f 82 f0 fe ff ff    	jb     f0103c78 <__umoddi3+0x68>
f0103d88:	e9 f2 fe ff ff       	jmp    f0103c7f <__umoddi3+0x6f>
