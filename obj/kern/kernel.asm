
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
f010004e:	c7 04 24 a0 3c 10 f0 	movl   $0xf0103ca0,(%esp)
f0100055:	e8 f8 2b 00 00       	call   f0102c52 <cprintf>
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
f010008b:	c7 04 24 bc 3c 10 f0 	movl   $0xf0103cbc,(%esp)
f0100092:	e8 bb 2b 00 00       	call   f0102c52 <cprintf>
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
f01000c0:	e8 ef 36 00 00       	call   f01037b4 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 83 05 00 00       	call   f010064d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 d7 3c 10 f0 	movl   $0xf0103cd7,(%esp)
f01000d9:	e8 74 2b 00 00       	call   f0102c52 <cprintf>

	// Lab 2 memory management initialization functions
	i386_detect_memory();
f01000de:	e8 6d 09 00 00       	call   f0100a50 <i386_detect_memory>
	i386_vm_init();
f01000e3:	e8 e2 0e 00 00       	call   f0100fca <i386_vm_init>



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
f010011b:	c7 04 24 f2 3c 10 f0 	movl   $0xf0103cf2,(%esp)
f0100122:	e8 2b 2b 00 00       	call   f0102c52 <cprintf>

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
f0100134:	e8 e6 2a 00 00       	call   f0102c1f <vcprintf>
	cprintf("\n");
f0100139:	c7 04 24 8d 49 10 f0 	movl   $0xf010498d,(%esp)
f0100140:	e8 0d 2b 00 00       	call   f0102c52 <cprintf>
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
f0100167:	c7 04 24 0a 3d 10 f0 	movl   $0xf0103d0a,(%esp)
f010016e:	e8 df 2a 00 00       	call   f0102c52 <cprintf>
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
f0100180:	e8 9a 2a 00 00       	call   f0102c1f <vcprintf>
	cprintf("\n");
f0100185:	c7 04 24 8d 49 10 f0 	movl   $0xf010498d,(%esp)
f010018c:	e8 c1 2a 00 00       	call   f0102c52 <cprintf>
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
f0100202:	0f b6 82 60 3d 10 f0 	movzbl -0xfefc2a0(%edx),%eax
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
f010023f:	0f b6 90 60 3d 10 f0 	movzbl -0xfefc2a0(%eax),%edx
f0100246:	0b 15 b0 63 11 f0    	or     0xf01163b0,%edx
	shift ^= togglecode[data];
f010024c:	0f b6 88 60 3e 10 f0 	movzbl -0xfefc1a0(%eax),%ecx
f0100253:	31 ca                	xor    %ecx,%edx
f0100255:	89 15 b0 63 11 f0    	mov    %edx,0xf01163b0

	c = charcode[shift & (CTL | SHIFT)][data];
f010025b:	89 d1                	mov    %edx,%ecx
f010025d:	83 e1 03             	and    $0x3,%ecx
f0100260:	8b 0c 8d 60 3f 10 f0 	mov    -0xfefc0a0(,%ecx,4),%ecx
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
f010029c:	c7 04 24 24 3d 10 f0 	movl   $0xf0103d24,(%esp)
f01002a3:	e8 aa 29 00 00       	call   f0102c52 <cprintf>
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
f01005f0:	e8 e3 31 00 00       	call   f01037d8 <memmove>
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
f0100666:	c7 04 24 30 3d 10 f0 	movl   $0xf0103d30,(%esp)
f010066d:	e8 e0 25 00 00       	call   f0102c52 <cprintf>
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
f01006b6:	c7 04 24 70 3f 10 f0 	movl   $0xf0103f70,(%esp)
f01006bd:	e8 90 25 00 00       	call   f0102c52 <cprintf>
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
f01006c2:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006c9:	00 
f01006ca:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006d1:	f0 
f01006d2:	c7 04 24 18 40 10 f0 	movl   $0xf0104018,(%esp)
f01006d9:	e8 74 25 00 00       	call   f0102c52 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006de:	c7 44 24 08 9d 3c 10 	movl   $0x103c9d,0x8(%esp)
f01006e5:	00 
f01006e6:	c7 44 24 04 9d 3c 10 	movl   $0xf0103c9d,0x4(%esp)
f01006ed:	f0 
f01006ee:	c7 04 24 3c 40 10 f0 	movl   $0xf010403c,(%esp)
f01006f5:	e8 58 25 00 00       	call   f0102c52 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006fa:	c7 44 24 08 70 63 11 	movl   $0x116370,0x8(%esp)
f0100701:	00 
f0100702:	c7 44 24 04 70 63 11 	movl   $0xf0116370,0x4(%esp)
f0100709:	f0 
f010070a:	c7 04 24 60 40 10 f0 	movl   $0xf0104060,(%esp)
f0100711:	e8 3c 25 00 00       	call   f0102c52 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100716:	c7 44 24 08 10 6a 11 	movl   $0x116a10,0x8(%esp)
f010071d:	00 
f010071e:	c7 44 24 04 10 6a 11 	movl   $0xf0116a10,0x4(%esp)
f0100725:	f0 
f0100726:	c7 04 24 84 40 10 f0 	movl   $0xf0104084,(%esp)
f010072d:	e8 20 25 00 00       	call   f0102c52 <cprintf>
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
f010074d:	c7 04 24 a8 40 10 f0 	movl   $0xf01040a8,(%esp)
f0100754:	e8 f9 24 00 00       	call   f0102c52 <cprintf>
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
f010076c:	c7 04 24 89 3f 10 f0 	movl   $0xf0103f89,(%esp)
f0100773:	e8 da 24 00 00       	call   f0102c52 <cprintf>
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
f0100787:	bb 84 41 10 f0       	mov    $0xf0104184,%ebx
unsigned read_eip();

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
f010078c:	be a8 41 10 f0       	mov    $0xf01041a8,%esi
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100791:	8b 03                	mov    (%ebx),%eax
f0100793:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100797:	8b 43 fc             	mov    -0x4(%ebx),%eax
f010079a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010079e:	c7 04 24 92 3f 10 f0 	movl   $0xf0103f92,(%esp)
f01007a5:	e8 a8 24 00 00       	call   f0102c52 <cprintf>
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
f01007ec:	c7 04 24 d4 40 10 f0 	movl   $0xf01040d4,(%esp)
f01007f3:	e8 5a 24 00 00       	call   f0102c52 <cprintf>
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
f0100812:	c7 04 24 f8 40 10 f0 	movl   $0xf01040f8,(%esp)
f0100819:	e8 34 24 00 00       	call   f0102c52 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010081e:	c7 04 24 1c 41 10 f0 	movl   $0xf010411c,(%esp)
f0100825:	e8 28 24 00 00       	call   f0102c52 <cprintf>


	while (1) {
		buf = readline("K> ");
f010082a:	c7 04 24 9b 3f 10 f0 	movl   $0xf0103f9b,(%esp)
f0100831:	e8 ea 2c 00 00       	call   f0103520 <readline>
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
f010085e:	c7 04 24 9f 3f 10 f0 	movl   $0xf0103f9f,(%esp)
f0100865:	e8 f0 2e 00 00       	call   f010375a <strchr>
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
f0100880:	c7 04 24 a4 3f 10 f0 	movl   $0xf0103fa4,(%esp)
f0100887:	e8 c6 23 00 00       	call   f0102c52 <cprintf>
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
f01008af:	c7 04 24 9f 3f 10 f0 	movl   $0xf0103f9f,(%esp)
f01008b6:	e8 9f 2e 00 00       	call   f010375a <strchr>
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
f01008d1:	bf 80 41 10 f0       	mov    $0xf0104180,%edi
f01008d6:	be 00 00 00 00       	mov    $0x0,%esi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008db:	8b 07                	mov    (%edi),%eax
f01008dd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008e1:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008e4:	89 04 24             	mov    %eax,(%esp)
f01008e7:	e8 ea 2d 00 00       	call   f01036d6 <strcmp>
f01008ec:	85 c0                	test   %eax,%eax
f01008ee:	75 24                	jne    f0100914 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f01008f0:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01008f3:	8b 55 08             	mov    0x8(%ebp),%edx
f01008f6:	89 54 24 08          	mov    %edx,0x8(%esp)
f01008fa:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008fd:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100901:	89 1c 24             	mov    %ebx,(%esp)
f0100904:	ff 14 85 88 41 10 f0 	call   *-0xfefbe78(,%eax,4)


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
f0100926:	c7 04 24 c1 3f 10 f0 	movl   $0xf0103fc1,(%esp)
f010092d:	e8 20 23 00 00       	call   f0102c52 <cprintf>
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

f0100950 <boot_alloc>:
// This function may ONLY be used during initialization,
// before the page_free_list has been set up.
// 
static void*
boot_alloc(uint32_t n, uint32_t align)
{
f0100950:	55                   	push   %ebp
f0100951:	89 e5                	mov    %esp,%ebp
f0100953:	83 ec 0c             	sub    $0xc,%esp
f0100956:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100959:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010095c:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010095f:	89 c7                	mov    %eax,%edi
f0100961:	89 d1                	mov    %edx,%ecx
	// Initialize boot_freemem if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment -
	// i.e., the first virtual address that the linker
	// did _not_ assign to any kernel code or global variables.
	if (boot_freemem == 0)
f0100963:	83 3d d4 65 11 f0 00 	cmpl   $0x0,0xf01165d4
f010096a:	75 0a                	jne    f0100976 <boot_alloc+0x26>
		boot_freemem = end;
f010096c:	c7 05 d4 65 11 f0 10 	movl   $0xf0116a10,0xf01165d4
f0100973:	6a 11 f0 
	// LAB 2: Your code here:
	//	Step 1: round boot_freemem up to be aligned properly
	//	Step 2: save current value of boot_freemem as allocated chunk
	//	Step 3: increase boot_freemem to record allocation
	//	Step 4: return allocated chunk
	boot_freemem =  ROUNDUP	(boot_freemem,align);
f0100976:	a1 d4 65 11 f0       	mov    0xf01165d4,%eax
f010097b:	8d 5c 08 ff          	lea    -0x1(%eax,%ecx,1),%ebx
f010097f:	89 d8                	mov    %ebx,%eax
f0100981:	ba 00 00 00 00       	mov    $0x0,%edx
f0100986:	f7 f1                	div    %ecx
f0100988:	89 de                	mov    %ebx,%esi
f010098a:	29 d6                	sub    %edx,%esi
	v = boot_freemem;
	boot_freemem+=  ROUNDUP(n,align);
f010098c:	8d 5c 0f ff          	lea    -0x1(%edi,%ecx,1),%ebx
f0100990:	89 d8                	mov    %ebx,%eax
f0100992:	ba 00 00 00 00       	mov    $0x0,%edx
f0100997:	f7 f1                	div    %ecx
f0100999:	29 d3                	sub    %edx,%ebx
f010099b:	01 f3                	add    %esi,%ebx
f010099d:	89 1d d4 65 11 f0    	mov    %ebx,0xf01165d4
	return v;
}
f01009a3:	89 f0                	mov    %esi,%eax
f01009a5:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01009a8:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01009ab:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01009ae:	89 ec                	mov    %ebp,%esp
f01009b0:	5d                   	pop    %ebp
f01009b1:	c3                   	ret    

f01009b2 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f01009b2:	89 d1                	mov    %edx,%ecx
f01009b4:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f01009b7:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f01009ba:	a8 01                	test   $0x1,%al
f01009bc:	74 5a                	je     f0100a18 <check_va2pa+0x66>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01009be:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009c3:	89 c1                	mov    %eax,%ecx
f01009c5:	c1 e9 0c             	shr    $0xc,%ecx
f01009c8:	3b 0d 00 6a 11 f0    	cmp    0xf0116a00,%ecx
f01009ce:	72 26                	jb     f01009f6 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_boot_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01009d0:	55                   	push   %ebp
f01009d1:	89 e5                	mov    %esp,%ebp
f01009d3:	83 ec 18             	sub    $0x18,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01009d6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009da:	c7 44 24 08 a4 41 10 	movl   $0xf01041a4,0x8(%esp)
f01009e1:	f0 
f01009e2:	c7 44 24 04 ab 01 00 	movl   $0x1ab,0x4(%esp)
f01009e9:	00 
f01009ea:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01009f1:	e8 00 f7 ff ff       	call   f01000f6 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f01009f6:	c1 ea 0c             	shr    $0xc,%edx
f01009f9:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009ff:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a06:	89 c2                	mov    %eax,%edx
f0100a08:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a0b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a10:	83 fa 01             	cmp    $0x1,%edx
f0100a13:	19 d2                	sbb    %edx,%edx
f0100a15:	09 d0                	or     %edx,%eax
f0100a17:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a18:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a1d:	c3                   	ret    

f0100a1e <nvram_read>:
	sizeof(gdt) - 1, (unsigned long) gdt
};

static int
nvram_read(int r)
{
f0100a1e:	55                   	push   %ebp
f0100a1f:	89 e5                	mov    %esp,%ebp
f0100a21:	83 ec 18             	sub    $0x18,%esp
f0100a24:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100a27:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100a2a:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a2c:	89 04 24             	mov    %eax,(%esp)
f0100a2f:	e8 ac 21 00 00       	call   f0102be0 <mc146818_read>
f0100a34:	89 c6                	mov    %eax,%esi
f0100a36:	83 c3 01             	add    $0x1,%ebx
f0100a39:	89 1c 24             	mov    %ebx,(%esp)
f0100a3c:	e8 9f 21 00 00       	call   f0102be0 <mc146818_read>
f0100a41:	c1 e0 08             	shl    $0x8,%eax
f0100a44:	09 f0                	or     %esi,%eax
}
f0100a46:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100a49:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100a4c:	89 ec                	mov    %ebp,%esp
f0100a4e:	5d                   	pop    %ebp
f0100a4f:	c3                   	ret    

f0100a50 <i386_detect_memory>:

void
i386_detect_memory(void)
{
f0100a50:	55                   	push   %ebp
f0100a51:	89 e5                	mov    %esp,%ebp
f0100a53:	83 ec 18             	sub    $0x18,%esp
	// CMOS tells us how many kilobytes there are
	basemem = ROUNDDOWN(nvram_read(NVRAM_BASELO)*1024, PGSIZE);
f0100a56:	b8 15 00 00 00       	mov    $0x15,%eax
f0100a5b:	e8 be ff ff ff       	call   f0100a1e <nvram_read>
f0100a60:	c1 e0 0a             	shl    $0xa,%eax
f0100a63:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a68:	a3 c8 65 11 f0       	mov    %eax,0xf01165c8
	extmem = ROUNDDOWN(nvram_read(NVRAM_EXTLO)*1024, PGSIZE);
f0100a6d:	b8 17 00 00 00       	mov    $0x17,%eax
f0100a72:	e8 a7 ff ff ff       	call   f0100a1e <nvram_read>
f0100a77:	c1 e0 0a             	shl    $0xa,%eax
f0100a7a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a7f:	a3 cc 65 11 f0       	mov    %eax,0xf01165cc

	// Calculate the maximum physical address based on whether
	// or not there is any extended memory.  See comment in <inc/mmu.h>.
	if (extmem)
f0100a84:	85 c0                	test   %eax,%eax
f0100a86:	74 0c                	je     f0100a94 <i386_detect_memory+0x44>
		maxpa = EXTPHYSMEM + extmem;
f0100a88:	05 00 00 10 00       	add    $0x100000,%eax
f0100a8d:	a3 d0 65 11 f0       	mov    %eax,0xf01165d0
f0100a92:	eb 0a                	jmp    f0100a9e <i386_detect_memory+0x4e>
	else
		maxpa = basemem;
f0100a94:	a1 c8 65 11 f0       	mov    0xf01165c8,%eax
f0100a99:	a3 d0 65 11 f0       	mov    %eax,0xf01165d0

	npage = maxpa / PGSIZE;
f0100a9e:	a1 d0 65 11 f0       	mov    0xf01165d0,%eax
f0100aa3:	89 c2                	mov    %eax,%edx
f0100aa5:	c1 ea 0c             	shr    $0xc,%edx
f0100aa8:	89 15 00 6a 11 f0    	mov    %edx,0xf0116a00

	cprintf("Physical memory: %dK available, ", (int)(maxpa/1024));
f0100aae:	c1 e8 0a             	shr    $0xa,%eax
f0100ab1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ab5:	c7 04 24 c8 41 10 f0 	movl   $0xf01041c8,(%esp)
f0100abc:	e8 91 21 00 00       	call   f0102c52 <cprintf>
	cprintf("base = %dK, extended = %dK\n", (int)(basemem/1024), (int)(extmem/1024));
f0100ac1:	a1 cc 65 11 f0       	mov    0xf01165cc,%eax
f0100ac6:	c1 e8 0a             	shr    $0xa,%eax
f0100ac9:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100acd:	a1 c8 65 11 f0       	mov    0xf01165c8,%eax
f0100ad2:	c1 e8 0a             	shr    $0xa,%eax
f0100ad5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ad9:	c7 04 24 5f 47 10 f0 	movl   $0xf010475f,(%esp)
f0100ae0:	e8 6d 21 00 00       	call   f0102c52 <cprintf>
}
f0100ae5:	c9                   	leave  
f0100ae6:	c3                   	ret    

f0100ae7 <page_init>:
	//     Some of it is in use, some is free. Where is the kernel?
	//     Which pages are used for page tables and other data structures?
	//
	// Change the code to reflect this.
	int i;
	LIST_INIT(&page_free_list);
f0100ae7:	c7 05 d8 65 11 f0 00 	movl   $0x0,0xf01165d8
f0100aee:	00 00 00 

	pages[0].pp_ref = 1;
f0100af1:	a1 0c 6a 11 f0       	mov    0xf0116a0c,%eax
f0100af6:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
	
	for (i = 1; i < npage; i++) {
f0100afc:	83 3d 00 6a 11 f0 01 	cmpl   $0x1,0xf0116a00
f0100b03:	0f 86 ef 00 00 00    	jbe    f0100bf8 <page_init+0x111>
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100b09:	55                   	push   %ebp
f0100b0a:	89 e5                	mov    %esp,%ebp
f0100b0c:	57                   	push   %edi
f0100b0d:	56                   	push   %esi
f0100b0e:	53                   	push   %ebx
f0100b0f:	83 ec 2c             	sub    $0x2c,%esp
	for (i = 1; i < npage; i++) {
		if((i >= IOPHYSMEM /PGSIZE)&& (i< EXTPHYSMEM/PGSIZE)){
			pages[i].pp_ref = 1;
			continue;
		}
		if( (i>= EXTPHYSMEM/PGSIZE)&&(i<PADDR(boot_freemem)/PGSIZE)){
f0100b12:	8b 3d d4 65 11 f0    	mov    0xf01165d4,%edi
f0100b18:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100b1e:	c1 e8 0c             	shr    $0xc,%eax
f0100b21:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	int i;
	LIST_INIT(&page_free_list);

	pages[0].pp_ref = 1;
	
	for (i = 1; i < npage; i++) {
f0100b24:	ba 01 00 00 00       	mov    $0x1,%edx
f0100b29:	b8 01 00 00 00       	mov    $0x1,%eax
		if((i >= IOPHYSMEM /PGSIZE)&& (i< EXTPHYSMEM/PGSIZE)){
f0100b2e:	8d 8a 60 ff ff ff    	lea    -0xa0(%edx),%ecx
f0100b34:	83 f9 5f             	cmp    $0x5f,%ecx
f0100b37:	77 17                	ja     f0100b50 <page_init+0x69>
			pages[i].pp_ref = 1;
f0100b39:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100b3c:	c1 e2 02             	shl    $0x2,%edx
f0100b3f:	03 15 0c 6a 11 f0    	add    0xf0116a0c,%edx
f0100b45:	66 c7 42 08 01 00    	movw   $0x1,0x8(%edx)
			continue;
f0100b4b:	e9 90 00 00 00       	jmp    f0100be0 <page_init+0xf9>
		}
		if( (i>= EXTPHYSMEM/PGSIZE)&&(i<PADDR(boot_freemem)/PGSIZE)){
f0100b50:	3d ff 00 00 00       	cmp    $0xff,%eax
f0100b55:	7e 41                	jle    f0100b98 <page_init+0xb1>
f0100b57:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f0100b5d:	77 20                	ja     f0100b7f <page_init+0x98>
f0100b5f:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0100b63:	c7 44 24 08 ec 41 10 	movl   $0xf01041ec,0x8(%esp)
f0100b6a:	f0 
f0100b6b:	c7 44 24 04 d7 01 00 	movl   $0x1d7,0x4(%esp)
f0100b72:	00 
f0100b73:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0100b7a:	e8 77 f5 ff ff       	call   f01000f6 <_panic>
f0100b7f:	39 55 e4             	cmp    %edx,-0x1c(%ebp)
f0100b82:	76 14                	jbe    f0100b98 <page_init+0xb1>
			pages[i].pp_ref = 1;
f0100b84:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100b87:	c1 e2 02             	shl    $0x2,%edx
f0100b8a:	03 15 0c 6a 11 f0    	add    0xf0116a0c,%edx
f0100b90:	66 c7 42 08 01 00    	movw   $0x1,0x8(%edx)
			continue;
f0100b96:	eb 48                	jmp    f0100be0 <page_init+0xf9>
		}
		pages[i].pp_ref = 0;
f0100b98:	8d 34 52             	lea    (%edx,%edx,2),%esi
f0100b9b:	8d 14 b5 00 00 00 00 	lea    0x0(,%esi,4),%edx
f0100ba2:	8b 1d 0c 6a 11 f0    	mov    0xf0116a0c,%ebx
f0100ba8:	66 c7 44 13 08 00 00 	movw   $0x0,0x8(%ebx,%edx,1)
		LIST_INSERT_HEAD(&page_free_list, &pages[i], pp_link);
f0100baf:	8b 0d d8 65 11 f0    	mov    0xf01165d8,%ecx
f0100bb5:	89 0c b3             	mov    %ecx,(%ebx,%esi,4)
f0100bb8:	85 c9                	test   %ecx,%ecx
f0100bba:	74 11                	je     f0100bcd <page_init+0xe6>
f0100bbc:	8b 1d 0c 6a 11 f0    	mov    0xf0116a0c,%ebx
f0100bc2:	01 d3                	add    %edx,%ebx
f0100bc4:	8b 0d d8 65 11 f0    	mov    0xf01165d8,%ecx
f0100bca:	89 59 04             	mov    %ebx,0x4(%ecx)
f0100bcd:	03 15 0c 6a 11 f0    	add    0xf0116a0c,%edx
f0100bd3:	89 15 d8 65 11 f0    	mov    %edx,0xf01165d8
f0100bd9:	c7 42 04 d8 65 11 f0 	movl   $0xf01165d8,0x4(%edx)
	int i;
	LIST_INIT(&page_free_list);

	pages[0].pp_ref = 1;
	
	for (i = 1; i < npage; i++) {
f0100be0:	83 c0 01             	add    $0x1,%eax
f0100be3:	89 c2                	mov    %eax,%edx
f0100be5:	3b 05 00 6a 11 f0    	cmp    0xf0116a00,%eax
f0100beb:	0f 82 3d ff ff ff    	jb     f0100b2e <page_init+0x47>
		}
		pages[i].pp_ref = 0;
		LIST_INSERT_HEAD(&page_free_list, &pages[i], pp_link);
	}

}
f0100bf1:	83 c4 2c             	add    $0x2c,%esp
f0100bf4:	5b                   	pop    %ebx
f0100bf5:	5e                   	pop    %esi
f0100bf6:	5f                   	pop    %edi
f0100bf7:	5d                   	pop    %ebp
f0100bf8:	f3 c3                	repz ret 

f0100bfa <page_alloc>:
//   -E_NO_MEM -- otherwise 
//
// Hint: use LIST_FIRST, LIST_REMOVE, and page_initpp
int
page_alloc(struct Page **pp_store)
{
f0100bfa:	55                   	push   %ebp
f0100bfb:	89 e5                	mov    %esp,%ebp
f0100bfd:	8b 55 08             	mov    0x8(%ebp),%edx
	// Fill this function in
	if(!LIST_FIRST(&page_free_list)){
f0100c00:	a1 d8 65 11 f0       	mov    0xf01165d8,%eax
f0100c05:	85 c0                	test   %eax,%eax
f0100c07:	74 1e                	je     f0100c27 <page_alloc+0x2d>
	    return -E_NO_MEM;
    }
    else{
        *pp_store = LIST_FIRST(&page_free_list);
f0100c09:	89 02                	mov    %eax,(%edx)
        LIST_REMOVE(*pp_store, pp_link);
f0100c0b:	8b 08                	mov    (%eax),%ecx
f0100c0d:	85 c9                	test   %ecx,%ecx
f0100c0f:	74 06                	je     f0100c17 <page_alloc+0x1d>
f0100c11:	8b 40 04             	mov    0x4(%eax),%eax
f0100c14:	89 41 04             	mov    %eax,0x4(%ecx)
f0100c17:	8b 02                	mov    (%edx),%eax
f0100c19:	8b 50 04             	mov    0x4(%eax),%edx
f0100c1c:	8b 00                	mov    (%eax),%eax
f0100c1e:	89 02                	mov    %eax,(%edx)
        return 0;
f0100c20:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c25:	eb 05                	jmp    f0100c2c <page_alloc+0x32>
int
page_alloc(struct Page **pp_store)
{
	// Fill this function in
	if(!LIST_FIRST(&page_free_list)){
	    return -E_NO_MEM;
f0100c27:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    else{
        *pp_store = LIST_FIRST(&page_free_list);
        LIST_REMOVE(*pp_store, pp_link);
        return 0;
    }
}
f0100c2c:	5d                   	pop    %ebp
f0100c2d:	c3                   	ret    

f0100c2e <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0100c2e:	55                   	push   %ebp
f0100c2f:	89 e5                	mov    %esp,%ebp
f0100c31:	53                   	push   %ebx
f0100c32:	83 ec 14             	sub    $0x14,%esp
f0100c35:	8b 5d 08             	mov    0x8(%ebp),%ebx
// Note that the corresponding physical page is NOT initialized!
//
static void
page_initpp(struct Page *pp)
{
	memset(pp, 0, sizeof(*pp));
f0100c38:	c7 44 24 08 0c 00 00 	movl   $0xc,0x8(%esp)
f0100c3f:	00 
f0100c40:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100c47:	00 
f0100c48:	89 1c 24             	mov    %ebx,(%esp)
f0100c4b:	e8 64 2b 00 00       	call   f01037b4 <memset>
void
page_free(struct Page *pp)
{
	// Fill this function in
    page_initpp(pp);
 	pp->pp_ref = 0;
f0100c50:	66 c7 43 08 00 00    	movw   $0x0,0x8(%ebx)
	LIST_INSERT_HEAD(&page_free_list, pp, pp_link);
f0100c56:	a1 d8 65 11 f0       	mov    0xf01165d8,%eax
f0100c5b:	89 03                	mov    %eax,(%ebx)
f0100c5d:	85 c0                	test   %eax,%eax
f0100c5f:	74 08                	je     f0100c69 <page_free+0x3b>
f0100c61:	a1 d8 65 11 f0       	mov    0xf01165d8,%eax
f0100c66:	89 58 04             	mov    %ebx,0x4(%eax)
f0100c69:	89 1d d8 65 11 f0    	mov    %ebx,0xf01165d8
f0100c6f:	c7 43 04 d8 65 11 f0 	movl   $0xf01165d8,0x4(%ebx)
   
}
f0100c76:	83 c4 14             	add    $0x14,%esp
f0100c79:	5b                   	pop    %ebx
f0100c7a:	5d                   	pop    %ebp
f0100c7b:	c3                   	ret    

f0100c7c <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0100c7c:	55                   	push   %ebp
f0100c7d:	89 e5                	mov    %esp,%ebp
f0100c7f:	83 ec 18             	sub    $0x18,%esp
f0100c82:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100c85:	0f b7 50 08          	movzwl 0x8(%eax),%edx
f0100c89:	83 ea 01             	sub    $0x1,%edx
f0100c8c:	66 89 50 08          	mov    %dx,0x8(%eax)
f0100c90:	66 85 d2             	test   %dx,%dx
f0100c93:	75 08                	jne    f0100c9d <page_decref+0x21>
		page_free(pp);
f0100c95:	89 04 24             	mov    %eax,(%esp)
f0100c98:	e8 91 ff ff ff       	call   f0100c2e <page_free>
}
f0100c9d:	c9                   	leave  
f0100c9e:	c3                   	ret    

f0100c9f <pgdir_walk>:
// and the page table, so it's safe to leave permissions in the page
// more permissive than strictly necessaryi.

pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{  
f0100c9f:	55                   	push   %ebp
f0100ca0:	89 e5                	mov    %esp,%ebp
f0100ca2:	56                   	push   %esi
f0100ca3:	53                   	push   %ebx
f0100ca4:	83 ec 20             	sub    $0x20,%esp
f0100ca7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct Page * ss;
    pte_t *pte_addr_v;

    if(*(pgdir+PDX(va))  &&  PTE_P){
f0100caa:	89 de                	mov    %ebx,%esi
f0100cac:	c1 ee 16             	shr    $0x16,%esi
f0100caf:	c1 e6 02             	shl    $0x2,%esi
f0100cb2:	03 75 08             	add    0x8(%ebp),%esi
f0100cb5:	8b 06                	mov    (%esi),%eax
f0100cb7:	85 c0                	test   %eax,%eax
f0100cb9:	74 47                	je     f0100d02 <pgdir_walk+0x63>
            pte_addr_v = (pte_t *)KADDR(PTE_ADDR(pgdir[PDX(va)]));
f0100cbb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100cc0:	89 c2                	mov    %eax,%edx
f0100cc2:	c1 ea 0c             	shr    $0xc,%edx
f0100cc5:	3b 15 00 6a 11 f0    	cmp    0xf0116a00,%edx
f0100ccb:	72 20                	jb     f0100ced <pgdir_walk+0x4e>
f0100ccd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100cd1:	c7 44 24 08 a4 41 10 	movl   $0xf01041a4,0x8(%esp)
f0100cd8:	f0 
f0100cd9:	c7 44 24 04 3f 02 00 	movl   $0x23f,0x4(%esp)
f0100ce0:	00 
f0100ce1:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0100ce8:	e8 09 f4 ff ff       	call   f01000f6 <_panic>
        	return  &pte_addr_v[PTX(va)];
f0100ced:	c1 eb 0a             	shr    $0xa,%ebx
f0100cf0:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0100cf6:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f0100cfd:	e9 ee 00 00 00       	jmp    f0100df0 <pgdir_walk+0x151>
    }
    	else{
        if(create){
f0100d02:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100d06:	0f 84 d8 00 00 00    	je     f0100de4 <pgdir_walk+0x145>
            if( page_alloc(&ss) == 0 ){
f0100d0c:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100d0f:	89 04 24             	mov    %eax,(%esp)
f0100d12:	e8 e3 fe ff ff       	call   f0100bfa <page_alloc>
f0100d17:	85 c0                	test   %eax,%eax
f0100d19:	0f 85 cc 00 00 00    	jne    f0100deb <pgdir_walk+0x14c>
                ss ->pp_ref = 1;
f0100d1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100d22:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0100d28:	2b 05 0c 6a 11 f0    	sub    0xf0116a0c,%eax
f0100d2e:	c1 f8 02             	sar    $0x2,%eax
f0100d31:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0100d37:	c1 e0 0c             	shl    $0xc,%eax
                memset(KADDR(page2pa(ss)),0,PGSIZE);
f0100d3a:	89 c2                	mov    %eax,%edx
f0100d3c:	c1 ea 0c             	shr    $0xc,%edx
f0100d3f:	3b 15 00 6a 11 f0    	cmp    0xf0116a00,%edx
f0100d45:	72 20                	jb     f0100d67 <pgdir_walk+0xc8>
f0100d47:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d4b:	c7 44 24 08 a4 41 10 	movl   $0xf01041a4,0x8(%esp)
f0100d52:	f0 
f0100d53:	c7 44 24 04 46 02 00 	movl   $0x246,0x4(%esp)
f0100d5a:	00 
f0100d5b:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0100d62:	e8 8f f3 ff ff       	call   f01000f6 <_panic>
f0100d67:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100d6e:	00 
f0100d6f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100d76:	00 
f0100d77:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d7c:	89 04 24             	mov    %eax,(%esp)
f0100d7f:	e8 30 2a 00 00       	call   f01037b4 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0100d84:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100d87:	2b 05 0c 6a 11 f0    	sub    0xf0116a0c,%eax
f0100d8d:	c1 f8 02             	sar    $0x2,%eax
f0100d90:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0100d96:	c1 e0 0c             	shl    $0xc,%eax
                pgdir[PDX(va)] = page2pa(ss) | PTE_U|PTE_W|PTE_P;
f0100d99:	89 c2                	mov    %eax,%edx
f0100d9b:	83 ca 07             	or     $0x7,%edx
f0100d9e:	89 16                	mov    %edx,(%esi)
                pte_addr_v = (pte_t*)KADDR(PTE_ADDR(pgdir[PDX(va)]));
f0100da0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100da5:	89 c2                	mov    %eax,%edx
f0100da7:	c1 ea 0c             	shr    $0xc,%edx
f0100daa:	3b 15 00 6a 11 f0    	cmp    0xf0116a00,%edx
f0100db0:	72 20                	jb     f0100dd2 <pgdir_walk+0x133>
f0100db2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100db6:	c7 44 24 08 a4 41 10 	movl   $0xf01041a4,0x8(%esp)
f0100dbd:	f0 
f0100dbe:	c7 44 24 04 48 02 00 	movl   $0x248,0x4(%esp)
f0100dc5:	00 
f0100dc6:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0100dcd:	e8 24 f3 ff ff       	call   f01000f6 <_panic>
                return &pte_addr_v[PTX(va)];
f0100dd2:	c1 eb 0a             	shr    $0xa,%ebx
f0100dd5:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0100ddb:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f0100de2:	eb 0c                	jmp    f0100df0 <pgdir_walk+0x151>
            }
            else
                return NULL;
        }
        else
            return NULL;
f0100de4:	b8 00 00 00 00       	mov    $0x0,%eax
f0100de9:	eb 05                	jmp    f0100df0 <pgdir_walk+0x151>
                pgdir[PDX(va)] = page2pa(ss) | PTE_U|PTE_W|PTE_P;
                pte_addr_v = (pte_t*)KADDR(PTE_ADDR(pgdir[PDX(va)]));
                return &pte_addr_v[PTX(va)];
            }
            else
                return NULL;
f0100deb:	b8 00 00 00 00       	mov    $0x0,%eax
        }
        else
            return NULL;
    }
}
f0100df0:	83 c4 20             	add    $0x20,%esp
f0100df3:	5b                   	pop    %ebx
f0100df4:	5e                   	pop    %esi
f0100df5:	5d                   	pop    %ebp
f0100df6:	c3                   	ret    

f0100df7 <boot_map_segment>:
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, physaddr_t pa, 
					int perm)
{
f0100df7:	55                   	push   %ebp
f0100df8:	89 e5                	mov    %esp,%ebp
f0100dfa:	57                   	push   %edi
f0100dfb:	56                   	push   %esi
f0100dfc:	53                   	push   %ebx
f0100dfd:	83 ec 2c             	sub    $0x2c,%esp
f0100e00:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Fill this function in
	uint32_t i ;
	pte_t * pte;
	for(i = 0 ; i <  size ; i += PGSIZE) {
f0100e03:	85 c9                	test   %ecx,%ecx
f0100e05:	74 4c                	je     f0100e53 <boot_map_segment+0x5c>
f0100e07:	89 c7                	mov    %eax,%edi
f0100e09:	89 d3                	mov    %edx,%ebx
f0100e0b:	be 00 00 00 00       	mov    $0x0,%esi
		pte = pgdir_walk(pgdir, (void *)(la + i), 1) ;
		*pte = (pa + i) | perm | PTE_P ;
f0100e10:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e13:	83 c8 01             	or     $0x1,%eax
f0100e16:	89 45 e0             	mov    %eax,-0x20(%ebp)
{
	// Fill this function in
	uint32_t i ;
	pte_t * pte;
	for(i = 0 ; i <  size ; i += PGSIZE) {
		pte = pgdir_walk(pgdir, (void *)(la + i), 1) ;
f0100e19:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0100e20:	00 
f0100e21:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e25:	89 3c 24             	mov    %edi,(%esp)
f0100e28:	e8 72 fe ff ff       	call   f0100c9f <pgdir_walk>
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, physaddr_t pa, 
f0100e2d:	8b 55 08             	mov    0x8(%ebp),%edx
f0100e30:	01 f2                	add    %esi,%edx
	// Fill this function in
	uint32_t i ;
	pte_t * pte;
	for(i = 0 ; i <  size ; i += PGSIZE) {
		pte = pgdir_walk(pgdir, (void *)(la + i), 1) ;
		*pte = (pa + i) | perm | PTE_P ;
f0100e32:	0b 55 e0             	or     -0x20(%ebp),%edx
f0100e35:	89 10                	mov    %edx,(%eax)
		pgdir[PDX(la + i)] |= perm ;
f0100e37:	89 d8                	mov    %ebx,%eax
f0100e39:	c1 e8 16             	shr    $0x16,%eax
f0100e3c:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100e3f:	09 14 87             	or     %edx,(%edi,%eax,4)
					int perm)
{
	// Fill this function in
	uint32_t i ;
	pte_t * pte;
	for(i = 0 ; i <  size ; i += PGSIZE) {
f0100e42:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100e48:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100e4e:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
f0100e51:	77 c6                	ja     f0100e19 <boot_map_segment+0x22>
		pte = pgdir_walk(pgdir, (void *)(la + i), 1) ;
		*pte = (pa + i) | perm | PTE_P ;
		pgdir[PDX(la + i)] |= perm ;
	}
}
f0100e53:	83 c4 2c             	add    $0x2c,%esp
f0100e56:	5b                   	pop    %ebx
f0100e57:	5e                   	pop    %esi
f0100e58:	5f                   	pop    %edi
f0100e59:	5d                   	pop    %ebp
f0100e5a:	c3                   	ret    

f0100e5b <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100e5b:	55                   	push   %ebp
f0100e5c:	89 e5                	mov    %esp,%ebp
f0100e5e:	53                   	push   %ebx
f0100e5f:	83 ec 14             	sub    $0x14,%esp
f0100e62:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t * pte_addr_v;

    pte_addr_v = pgdir_walk(pgdir,va, 0);
f0100e65:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100e6c:	00 
f0100e6d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e70:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e74:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e77:	89 04 24             	mov    %eax,(%esp)
f0100e7a:	e8 20 fe ff ff       	call   f0100c9f <pgdir_walk>
    
    if(!pte_addr_v) 
f0100e7f:	85 c0                	test   %eax,%eax
f0100e81:	74 3c                	je     f0100ebf <page_lookup+0x64>
        return 0;
    if(pte_store != NULL)
f0100e83:	85 db                	test   %ebx,%ebx
f0100e85:	74 02                	je     f0100e89 <page_lookup+0x2e>
            *pte_store = pte_addr_v;
f0100e87:	89 03                	mov    %eax,(%ebx)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PPN(pa) >= npage)
f0100e89:	8b 00                	mov    (%eax),%eax
f0100e8b:	c1 e8 0c             	shr    $0xc,%eax
f0100e8e:	3b 05 00 6a 11 f0    	cmp    0xf0116a00,%eax
f0100e94:	72 1c                	jb     f0100eb2 <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f0100e96:	c7 44 24 08 10 42 10 	movl   $0xf0104210,0x8(%esp)
f0100e9d:	f0 
f0100e9e:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0100ea5:	00 
f0100ea6:	c7 04 24 7b 47 10 f0 	movl   $0xf010477b,(%esp)
f0100ead:	e8 44 f2 ff ff       	call   f01000f6 <_panic>
	return &pages[PPN(pa)];
f0100eb2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100eb5:	a1 0c 6a 11 f0       	mov    0xf0116a0c,%eax
f0100eba:	8d 04 90             	lea    (%eax,%edx,4),%eax
    return pa2page(*pte_addr_v);
f0100ebd:	eb 05                	jmp    f0100ec4 <page_lookup+0x69>
	pte_t * pte_addr_v;

    pte_addr_v = pgdir_walk(pgdir,va, 0);
    
    if(!pte_addr_v) 
        return 0;
f0100ebf:	b8 00 00 00 00       	mov    $0x0,%eax
    if(pte_store != NULL)
            *pte_store = pte_addr_v;
    return pa2page(*pte_addr_v);
}
f0100ec4:	83 c4 14             	add    $0x14,%esp
f0100ec7:	5b                   	pop    %ebx
f0100ec8:	5d                   	pop    %ebp
f0100ec9:	c3                   	ret    

f0100eca <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100eca:	55                   	push   %ebp
f0100ecb:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100ecd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ed0:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0100ed3:	5d                   	pop    %ebp
f0100ed4:	c3                   	ret    

f0100ed5 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100ed5:	55                   	push   %ebp
f0100ed6:	89 e5                	mov    %esp,%ebp
f0100ed8:	83 ec 28             	sub    $0x28,%esp
f0100edb:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100ede:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100ee1:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100ee4:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
    pte_t *pte_addr_v;
    struct Page *pg;
    pg=page_lookup(pgdir,va,&pte_addr_v);
f0100ee7:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100eea:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100eee:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ef2:	89 1c 24             	mov    %ebx,(%esp)
f0100ef5:	e8 61 ff ff ff       	call   f0100e5b <page_lookup>
    if(!pg)
f0100efa:	85 c0                	test   %eax,%eax
f0100efc:	74 21                	je     f0100f1f <page_remove+0x4a>
        return;
    else
        page_decref(pg);
f0100efe:	89 04 24             	mov    %eax,(%esp)
f0100f01:	e8 76 fd ff ff       	call   f0100c7c <page_decref>

    if(pte_addr_v)
f0100f06:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f09:	85 c0                	test   %eax,%eax
f0100f0b:	74 06                	je     f0100f13 <page_remove+0x3e>
        *pte_addr_v = 0;
f0100f0d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    tlb_invalidate(pgdir,va);     
f0100f13:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f17:	89 1c 24             	mov    %ebx,(%esp)
f0100f1a:	e8 ab ff ff ff       	call   f0100eca <tlb_invalidate>

}
f0100f1f:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100f22:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100f25:	89 ec                	mov    %ebp,%esp
f0100f27:	5d                   	pop    %ebp
f0100f28:	c3                   	ret    

f0100f29 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm) 
{
f0100f29:	55                   	push   %ebp
f0100f2a:	89 e5                	mov    %esp,%ebp
f0100f2c:	83 ec 28             	sub    $0x28,%esp
f0100f2f:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100f32:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100f35:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100f38:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100f3b:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100f3e:	8b 75 10             	mov    0x10(%ebp),%esi
	// Fill this function in
	pte_t * pte = pgdir_walk(pgdir, va, 0) ;
f0100f41:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100f48:	00 
f0100f49:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f4d:	89 1c 24             	mov    %ebx,(%esp)
f0100f50:	e8 4a fd ff ff       	call   f0100c9f <pgdir_walk>
	// Increment ref-count here so that we cannot accidentally 
	// free a page that's mapped again to the same virtual address
	pp->pp_ref++;
f0100f55:	66 83 47 08 01       	addw   $0x1,0x8(%edi)
	// If there is already a page mapped at 'va', it should be page_remove()d.
	if (pte && (*pte & PTE_P))
f0100f5a:	85 c0                	test   %eax,%eax
f0100f5c:	74 11                	je     f0100f6f <page_insert+0x46>
f0100f5e:	f6 00 01             	testb  $0x1,(%eax)
f0100f61:	74 0c                	je     f0100f6f <page_insert+0x46>
		page_remove(pgdir, va) ;
f0100f63:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f67:	89 1c 24             	mov    %ebx,(%esp)
f0100f6a:	e8 66 ff ff ff       	call   f0100ed5 <page_remove>
	
	pte = pgdir_walk(pgdir, va, 1) ;
f0100f6f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0100f76:	00 
f0100f77:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f7b:	89 1c 24             	mov    %ebx,(%esp)
f0100f7e:	e8 1c fd ff ff       	call   f0100c9f <pgdir_walk>
	
	if (pte) {
f0100f83:	85 c0                	test   %eax,%eax
f0100f85:	74 2c                	je     f0100fb3 <page_insert+0x8a>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0100f87:	2b 3d 0c 6a 11 f0    	sub    0xf0116a0c,%edi
f0100f8d:	c1 ff 02             	sar    $0x2,%edi
f0100f90:	69 ff ab aa aa aa    	imul   $0xaaaaaaab,%edi,%edi
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0100f96:	c1 e7 0c             	shl    $0xc,%edi
		*pte = page2pa(pp) | perm | PTE_P ;
f0100f99:	8b 55 14             	mov    0x14(%ebp),%edx
f0100f9c:	83 ca 01             	or     $0x1,%edx
f0100f9f:	09 d7                	or     %edx,%edi
f0100fa1:	89 38                	mov    %edi,(%eax)
		pgdir[PDX(va)] |= perm ;
f0100fa3:	c1 ee 16             	shr    $0x16,%esi
f0100fa6:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fa9:	09 04 b3             	or     %eax,(%ebx,%esi,4)
		return 0 ;
f0100fac:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fb1:	eb 0a                	jmp    f0100fbd <page_insert+0x94>
	}
	
	--(pp->pp_ref) ;
f0100fb3:	66 83 6f 08 01       	subw   $0x1,0x8(%edi)
	return -E_NO_MEM ;
f0100fb8:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
f0100fbd:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100fc0:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100fc3:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100fc6:	89 ec                	mov    %ebp,%esp
f0100fc8:	5d                   	pop    %ebp
f0100fc9:	c3                   	ret    

f0100fca <i386_vm_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read (or write). 
void
i386_vm_init(void)
{
f0100fca:	55                   	push   %ebp
f0100fcb:	89 e5                	mov    %esp,%ebp
f0100fcd:	57                   	push   %edi
f0100fce:	56                   	push   %esi
f0100fcf:	53                   	push   %ebx
f0100fd0:	83 ec 5c             	sub    $0x5c,%esp
	// Delete this line:
	// panic("i386_vm_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	pgdir = boot_alloc(PGSIZE, PGSIZE);
f0100fd3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0100fd8:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100fdd:	e8 6e f9 ff ff       	call   f0100950 <boot_alloc>
f0100fe2:	89 45 bc             	mov    %eax,-0x44(%ebp)
	memset(pgdir, 0, PGSIZE);
f0100fe5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100fec:	00 
f0100fed:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100ff4:	00 
f0100ff5:	89 04 24             	mov    %eax,(%esp)
f0100ff8:	e8 b7 27 00 00       	call   f01037b4 <memset>
	boot_pgdir = pgdir;
f0100ffd:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0101000:	a3 08 6a 11 f0       	mov    %eax,0xf0116a08
	boot_cr3 = PADDR(pgdir);
f0101005:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010100a:	77 20                	ja     f010102c <i386_vm_init+0x62>
f010100c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101010:	c7 44 24 08 ec 41 10 	movl   $0xf01041ec,0x8(%esp)
f0101017:	f0 
f0101018:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
f010101f:	00 
f0101020:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101027:	e8 ca f0 ff ff       	call   f01000f6 <_panic>
f010102c:	8b 45 bc             	mov    -0x44(%ebp),%eax
f010102f:	05 00 00 00 10       	add    $0x10000000,%eax
f0101034:	a3 04 6a 11 f0       	mov    %eax,0xf0116a04
	// a virtual page table at virtual address VPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel RW, user NONE
	pgdir[PDX(VPT)] = PADDR(pgdir)|PTE_W|PTE_P;
f0101039:	89 c2                	mov    %eax,%edx
f010103b:	83 ca 03             	or     $0x3,%edx
f010103e:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0101041:	89 91 fc 0e 00 00    	mov    %edx,0xefc(%ecx)

	// same for UVPT
	// Permissions: kernel R, user R 
	pgdir[PDX(UVPT)] = PADDR(pgdir)|PTE_U|PTE_P;
f0101047:	83 c8 05             	or     $0x5,%eax
f010104a:	89 81 f4 0e 00 00    	mov    %eax,0xef4(%ecx)
	// array.  'npage' is the number of physical pages in memory.
	// User-level programs will get read-only access to the array as well.
	// Your code goes here:
	
	// in bytes
	n = npage * sizeof (struct Page) ;
f0101050:	a1 00 6a 11 f0       	mov    0xf0116a00,%eax
f0101055:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0101058:	c1 e0 02             	shl    $0x2,%eax
f010105b:	89 45 b8             	mov    %eax,-0x48(%ebp)
	// allocate the pages
	pages = (struct Page *)boot_alloc(n, PGSIZE) ;
f010105e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101063:	e8 e8 f8 ff ff       	call   f0100950 <boot_alloc>
f0101068:	a3 0c 6a 11 f0       	mov    %eax,0xf0116a0c
	//////////////////////////////////////////////////////////////////////
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_segment or page_insert
	page_init();
f010106d:	e8 75 fa ff ff       	call   f0100ae7 <page_init>
	struct Page_list fl;

	// if there's a page that shouldn't be on
	// the free list, try to make sure it
	// eventually causes trouble.
	LIST_FOREACH(pp0, &page_free_list, pp_link)
f0101072:	a1 d8 65 11 f0       	mov    0xf01165d8,%eax
f0101077:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010107a:	85 c0                	test   %eax,%eax
f010107c:	0f 84 89 00 00 00    	je     f010110b <i386_vm_init+0x141>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101082:	2b 05 0c 6a 11 f0    	sub    0xf0116a0c,%eax
f0101088:	c1 f8 02             	sar    $0x2,%eax
f010108b:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101091:	c1 e0 0c             	shl    $0xc,%eax
}

static inline void*
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
f0101094:	89 c2                	mov    %eax,%edx
f0101096:	c1 ea 0c             	shr    $0xc,%edx
f0101099:	3b 15 00 6a 11 f0    	cmp    0xf0116a00,%edx
f010109f:	72 41                	jb     f01010e2 <i386_vm_init+0x118>
f01010a1:	eb 1f                	jmp    f01010c2 <i386_vm_init+0xf8>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f01010a3:	2b 05 0c 6a 11 f0    	sub    0xf0116a0c,%eax
f01010a9:	c1 f8 02             	sar    $0x2,%eax
f01010ac:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f01010b2:	c1 e0 0c             	shl    $0xc,%eax
}

static inline void*
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
f01010b5:	89 c2                	mov    %eax,%edx
f01010b7:	c1 ea 0c             	shr    $0xc,%edx
f01010ba:	3b 15 00 6a 11 f0    	cmp    0xf0116a00,%edx
f01010c0:	72 20                	jb     f01010e2 <i386_vm_init+0x118>
f01010c2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01010c6:	c7 44 24 08 a4 41 10 	movl   $0xf01041a4,0x8(%esp)
f01010cd:	f0 
f01010ce:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01010d5:	00 
f01010d6:	c7 04 24 7b 47 10 f0 	movl   $0xf010477b,(%esp)
f01010dd:	e8 14 f0 ff ff       	call   f01000f6 <_panic>
		memset(page2kva(pp0), 0x97, 128);
f01010e2:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f01010e9:	00 
f01010ea:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f01010f1:	00 
f01010f2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01010f7:	89 04 24             	mov    %eax,(%esp)
f01010fa:	e8 b5 26 00 00       	call   f01037b4 <memset>
	struct Page_list fl;

	// if there's a page that shouldn't be on
	// the free list, try to make sure it
	// eventually causes trouble.
	LIST_FOREACH(pp0, &page_free_list, pp_link)
f01010ff:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101102:	8b 00                	mov    (%eax),%eax
f0101104:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101107:	85 c0                	test   %eax,%eax
f0101109:	75 98                	jne    f01010a3 <i386_vm_init+0xd9>
		memset(page2kva(pp0), 0x97, 128);

	LIST_FOREACH(pp0, &page_free_list, pp_link) {
f010110b:	a1 d8 65 11 f0       	mov    0xf01165d8,%eax
f0101110:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101113:	85 c0                	test   %eax,%eax
f0101115:	0f 84 d6 01 00 00    	je     f01012f1 <i386_vm_init+0x327>
		// check that we didn't corrupt the free list itself
		assert(pp0 >= pages);
f010111b:	8b 1d 0c 6a 11 f0    	mov    0xf0116a0c,%ebx
f0101121:	39 c3                	cmp    %eax,%ebx
f0101123:	77 4f                	ja     f0101174 <i386_vm_init+0x1aa>
		assert(pp0 < pages + npage);
f0101125:	8b 35 00 6a 11 f0    	mov    0xf0116a00,%esi
f010112b:	8d 14 76             	lea    (%esi,%esi,2),%edx
f010112e:	8d 14 93             	lea    (%ebx,%edx,4),%edx
f0101131:	89 55 c0             	mov    %edx,-0x40(%ebp)
f0101134:	39 d0                	cmp    %edx,%eax
f0101136:	73 65                	jae    f010119d <i386_vm_init+0x1d3>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101138:	89 5d c4             	mov    %ebx,-0x3c(%ebp)
f010113b:	89 c2                	mov    %eax,%edx
f010113d:	29 da                	sub    %ebx,%edx
f010113f:	c1 fa 02             	sar    $0x2,%edx
f0101142:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101148:	c1 e2 0c             	shl    $0xc,%edx

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp0) != 0);
f010114b:	85 d2                	test   %edx,%edx
f010114d:	0f 84 83 00 00 00    	je     f01011d6 <i386_vm_init+0x20c>
		assert(page2pa(pp0) != IOPHYSMEM);
f0101153:	81 fa 00 00 0a 00    	cmp    $0xa0000,%edx
f0101159:	0f 84 a3 00 00 00    	je     f0101202 <i386_vm_init+0x238>
		assert(page2pa(pp0) != EXTPHYSMEM - PGSIZE);
f010115f:	81 fa 00 f0 0f 00    	cmp    $0xff000,%edx
f0101165:	0f 85 e7 00 00 00    	jne    f0101252 <i386_vm_init+0x288>
f010116b:	e9 be 00 00 00       	jmp    f010122e <i386_vm_init+0x264>
	LIST_FOREACH(pp0, &page_free_list, pp_link)
		memset(page2kva(pp0), 0x97, 128);

	LIST_FOREACH(pp0, &page_free_list, pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp0 >= pages);
f0101170:	39 c3                	cmp    %eax,%ebx
f0101172:	76 24                	jbe    f0101198 <i386_vm_init+0x1ce>
f0101174:	c7 44 24 0c 89 47 10 	movl   $0xf0104789,0xc(%esp)
f010117b:	f0 
f010117c:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101183:	f0 
f0101184:	c7 44 24 04 32 01 00 	movl   $0x132,0x4(%esp)
f010118b:	00 
f010118c:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101193:	e8 5e ef ff ff       	call   f01000f6 <_panic>
		assert(pp0 < pages + npage);
f0101198:	3b 45 c0             	cmp    -0x40(%ebp),%eax
f010119b:	72 24                	jb     f01011c1 <i386_vm_init+0x1f7>
f010119d:	c7 44 24 0c ab 47 10 	movl   $0xf01047ab,0xc(%esp)
f01011a4:	f0 
f01011a5:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f01011ac:	f0 
f01011ad:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
f01011b4:	00 
f01011b5:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01011bc:	e8 35 ef ff ff       	call   f01000f6 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f01011c1:	89 c2                	mov    %eax,%edx
f01011c3:	2b 55 c4             	sub    -0x3c(%ebp),%edx
f01011c6:	c1 fa 02             	sar    $0x2,%edx
f01011c9:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f01011cf:	c1 e2 0c             	shl    $0xc,%edx

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp0) != 0);
f01011d2:	85 d2                	test   %edx,%edx
f01011d4:	75 24                	jne    f01011fa <i386_vm_init+0x230>
f01011d6:	c7 44 24 0c bf 47 10 	movl   $0xf01047bf,0xc(%esp)
f01011dd:	f0 
f01011de:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f01011e5:	f0 
f01011e6:	c7 44 24 04 36 01 00 	movl   $0x136,0x4(%esp)
f01011ed:	00 
f01011ee:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01011f5:	e8 fc ee ff ff       	call   f01000f6 <_panic>
		assert(page2pa(pp0) != IOPHYSMEM);
f01011fa:	81 fa 00 00 0a 00    	cmp    $0xa0000,%edx
f0101200:	75 24                	jne    f0101226 <i386_vm_init+0x25c>
f0101202:	c7 44 24 0c d1 47 10 	movl   $0xf01047d1,0xc(%esp)
f0101209:	f0 
f010120a:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101211:	f0 
f0101212:	c7 44 24 04 37 01 00 	movl   $0x137,0x4(%esp)
f0101219:	00 
f010121a:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101221:	e8 d0 ee ff ff       	call   f01000f6 <_panic>
		assert(page2pa(pp0) != EXTPHYSMEM - PGSIZE);
f0101226:	81 fa 00 f0 0f 00    	cmp    $0xff000,%edx
f010122c:	75 33                	jne    f0101261 <i386_vm_init+0x297>
f010122e:	c7 44 24 0c 30 42 10 	movl   $0xf0104230,0xc(%esp)
f0101235:	f0 
f0101236:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f010123d:	f0 
f010123e:	c7 44 24 04 38 01 00 	movl   $0x138,0x4(%esp)
f0101245:	00 
f0101246:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f010124d:	e8 a4 ee ff ff       	call   f01000f6 <_panic>
		assert(page2pa(pp0) != EXTPHYSMEM);
		assert(page2kva(pp0) != ROUNDDOWN(boot_freemem - 1, PGSIZE));
f0101252:	8b 3d d4 65 11 f0    	mov    0xf01165d4,%edi
f0101258:	83 ef 01             	sub    $0x1,%edi
f010125b:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp0) != 0);
		assert(page2pa(pp0) != IOPHYSMEM);
		assert(page2pa(pp0) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp0) != EXTPHYSMEM);
f0101261:	81 fa 00 00 10 00    	cmp    $0x100000,%edx
f0101267:	75 24                	jne    f010128d <i386_vm_init+0x2c3>
f0101269:	c7 44 24 0c eb 47 10 	movl   $0xf01047eb,0xc(%esp)
f0101270:	f0 
f0101271:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101278:	f0 
f0101279:	c7 44 24 04 39 01 00 	movl   $0x139,0x4(%esp)
f0101280:	00 
f0101281:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101288:	e8 69 ee ff ff       	call   f01000f6 <_panic>
}

static inline void*
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
f010128d:	89 d1                	mov    %edx,%ecx
f010128f:	c1 e9 0c             	shr    $0xc,%ecx
f0101292:	39 f1                	cmp    %esi,%ecx
f0101294:	72 20                	jb     f01012b6 <i386_vm_init+0x2ec>
f0101296:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010129a:	c7 44 24 08 a4 41 10 	movl   $0xf01041a4,0x8(%esp)
f01012a1:	f0 
f01012a2:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01012a9:	00 
f01012aa:	c7 04 24 7b 47 10 f0 	movl   $0xf010477b,(%esp)
f01012b1:	e8 40 ee ff ff       	call   f01000f6 <_panic>
f01012b6:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
		assert(page2kva(pp0) != ROUNDDOWN(boot_freemem - 1, PGSIZE));
f01012bc:	39 d7                	cmp    %edx,%edi
f01012be:	75 24                	jne    f01012e4 <i386_vm_init+0x31a>
f01012c0:	c7 44 24 0c 54 42 10 	movl   $0xf0104254,0xc(%esp)
f01012c7:	f0 
f01012c8:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f01012cf:	f0 
f01012d0:	c7 44 24 04 3a 01 00 	movl   $0x13a,0x4(%esp)
f01012d7:	00 
f01012d8:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01012df:	e8 12 ee ff ff       	call   f01000f6 <_panic>
	// the free list, try to make sure it
	// eventually causes trouble.
	LIST_FOREACH(pp0, &page_free_list, pp_link)
		memset(page2kva(pp0), 0x97, 128);

	LIST_FOREACH(pp0, &page_free_list, pp_link) {
f01012e4:	8b 00                	mov    (%eax),%eax
f01012e6:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01012e9:	85 c0                	test   %eax,%eax
f01012eb:	0f 85 7f fe ff ff    	jne    f0101170 <i386_vm_init+0x1a6>
		assert(page2pa(pp0) != EXTPHYSMEM);
		assert(page2kva(pp0) != ROUNDDOWN(boot_freemem - 1, PGSIZE));
	}

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
f01012f1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01012f8:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01012ff:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	assert(page_alloc(&pp0) == 0);
f0101306:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0101309:	89 04 24             	mov    %eax,(%esp)
f010130c:	e8 e9 f8 ff ff       	call   f0100bfa <page_alloc>
f0101311:	85 c0                	test   %eax,%eax
f0101313:	74 24                	je     f0101339 <i386_vm_init+0x36f>
f0101315:	c7 44 24 0c 06 48 10 	movl   $0xf0104806,0xc(%esp)
f010131c:	f0 
f010131d:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101324:	f0 
f0101325:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
f010132c:	00 
f010132d:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101334:	e8 bd ed ff ff       	call   f01000f6 <_panic>
	assert(page_alloc(&pp1) == 0);
f0101339:	8d 45 e0             	lea    -0x20(%ebp),%eax
f010133c:	89 04 24             	mov    %eax,(%esp)
f010133f:	e8 b6 f8 ff ff       	call   f0100bfa <page_alloc>
f0101344:	85 c0                	test   %eax,%eax
f0101346:	74 24                	je     f010136c <i386_vm_init+0x3a2>
f0101348:	c7 44 24 0c 1c 48 10 	movl   $0xf010481c,0xc(%esp)
f010134f:	f0 
f0101350:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101357:	f0 
f0101358:	c7 44 24 04 40 01 00 	movl   $0x140,0x4(%esp)
f010135f:	00 
f0101360:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101367:	e8 8a ed ff ff       	call   f01000f6 <_panic>
	assert(page_alloc(&pp2) == 0);
f010136c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010136f:	89 04 24             	mov    %eax,(%esp)
f0101372:	e8 83 f8 ff ff       	call   f0100bfa <page_alloc>
f0101377:	85 c0                	test   %eax,%eax
f0101379:	74 24                	je     f010139f <i386_vm_init+0x3d5>
f010137b:	c7 44 24 0c 32 48 10 	movl   $0xf0104832,0xc(%esp)
f0101382:	f0 
f0101383:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f010138a:	f0 
f010138b:	c7 44 24 04 41 01 00 	movl   $0x141,0x4(%esp)
f0101392:	00 
f0101393:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f010139a:	e8 57 ed ff ff       	call   f01000f6 <_panic>

	assert(pp0);
f010139f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01013a2:	85 c9                	test   %ecx,%ecx
f01013a4:	75 24                	jne    f01013ca <i386_vm_init+0x400>
f01013a6:	c7 44 24 0c 56 48 10 	movl   $0xf0104856,0xc(%esp)
f01013ad:	f0 
f01013ae:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f01013b5:	f0 
f01013b6:	c7 44 24 04 43 01 00 	movl   $0x143,0x4(%esp)
f01013bd:	00 
f01013be:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01013c5:	e8 2c ed ff ff       	call   f01000f6 <_panic>
	assert(pp1 && pp1 != pp0);
f01013ca:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01013cd:	85 d2                	test   %edx,%edx
f01013cf:	74 04                	je     f01013d5 <i386_vm_init+0x40b>
f01013d1:	39 d1                	cmp    %edx,%ecx
f01013d3:	75 24                	jne    f01013f9 <i386_vm_init+0x42f>
f01013d5:	c7 44 24 0c 48 48 10 	movl   $0xf0104848,0xc(%esp)
f01013dc:	f0 
f01013dd:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f01013e4:	f0 
f01013e5:	c7 44 24 04 44 01 00 	movl   $0x144,0x4(%esp)
f01013ec:	00 
f01013ed:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01013f4:	e8 fd ec ff ff       	call   f01000f6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013f9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01013fc:	85 c0                	test   %eax,%eax
f01013fe:	74 08                	je     f0101408 <i386_vm_init+0x43e>
f0101400:	39 c2                	cmp    %eax,%edx
f0101402:	74 04                	je     f0101408 <i386_vm_init+0x43e>
f0101404:	39 c1                	cmp    %eax,%ecx
f0101406:	75 24                	jne    f010142c <i386_vm_init+0x462>
f0101408:	c7 44 24 0c 8c 42 10 	movl   $0xf010428c,0xc(%esp)
f010140f:	f0 
f0101410:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101417:	f0 
f0101418:	c7 44 24 04 45 01 00 	movl   $0x145,0x4(%esp)
f010141f:	00 
f0101420:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101427:	e8 ca ec ff ff       	call   f01000f6 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f010142c:	8b 35 0c 6a 11 f0    	mov    0xf0116a0c,%esi
	assert(page2pa(pp0) < npage*PGSIZE);
f0101432:	8b 1d 00 6a 11 f0    	mov    0xf0116a00,%ebx
f0101438:	c1 e3 0c             	shl    $0xc,%ebx
f010143b:	29 f1                	sub    %esi,%ecx
f010143d:	c1 f9 02             	sar    $0x2,%ecx
f0101440:	69 c9 ab aa aa aa    	imul   $0xaaaaaaab,%ecx,%ecx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101446:	c1 e1 0c             	shl    $0xc,%ecx
f0101449:	39 d9                	cmp    %ebx,%ecx
f010144b:	72 24                	jb     f0101471 <i386_vm_init+0x4a7>
f010144d:	c7 44 24 0c 5a 48 10 	movl   $0xf010485a,0xc(%esp)
f0101454:	f0 
f0101455:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f010145c:	f0 
f010145d:	c7 44 24 04 46 01 00 	movl   $0x146,0x4(%esp)
f0101464:	00 
f0101465:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f010146c:	e8 85 ec ff ff       	call   f01000f6 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101471:	29 f2                	sub    %esi,%edx
f0101473:	c1 fa 02             	sar    $0x2,%edx
f0101476:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f010147c:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp1) < npage*PGSIZE);
f010147f:	39 d3                	cmp    %edx,%ebx
f0101481:	77 24                	ja     f01014a7 <i386_vm_init+0x4dd>
f0101483:	c7 44 24 0c 76 48 10 	movl   $0xf0104876,0xc(%esp)
f010148a:	f0 
f010148b:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101492:	f0 
f0101493:	c7 44 24 04 47 01 00 	movl   $0x147,0x4(%esp)
f010149a:	00 
f010149b:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01014a2:	e8 4f ec ff ff       	call   f01000f6 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f01014a7:	29 f0                	sub    %esi,%eax
f01014a9:	c1 f8 02             	sar    $0x2,%eax
f01014ac:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f01014b2:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npage*PGSIZE);
f01014b5:	39 c3                	cmp    %eax,%ebx
f01014b7:	77 24                	ja     f01014dd <i386_vm_init+0x513>
f01014b9:	c7 44 24 0c 92 48 10 	movl   $0xf0104892,0xc(%esp)
f01014c0:	f0 
f01014c1:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f01014c8:	f0 
f01014c9:	c7 44 24 04 48 01 00 	movl   $0x148,0x4(%esp)
f01014d0:	00 
f01014d1:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01014d8:	e8 19 ec ff ff       	call   f01000f6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01014dd:	8b 1d d8 65 11 f0    	mov    0xf01165d8,%ebx
	LIST_INIT(&page_free_list);
f01014e3:	c7 05 d8 65 11 f0 00 	movl   $0x0,0xf01165d8
f01014ea:	00 00 00 

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);
f01014ed:	8d 45 d8             	lea    -0x28(%ebp),%eax
f01014f0:	89 04 24             	mov    %eax,(%esp)
f01014f3:	e8 02 f7 ff ff       	call   f0100bfa <page_alloc>
f01014f8:	83 f8 fc             	cmp    $0xfffffffc,%eax
f01014fb:	74 24                	je     f0101521 <i386_vm_init+0x557>
f01014fd:	c7 44 24 0c ae 48 10 	movl   $0xf01048ae,0xc(%esp)
f0101504:	f0 
f0101505:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f010150c:	f0 
f010150d:	c7 44 24 04 4f 01 00 	movl   $0x14f,0x4(%esp)
f0101514:	00 
f0101515:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f010151c:	e8 d5 eb ff ff       	call   f01000f6 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101521:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101524:	89 04 24             	mov    %eax,(%esp)
f0101527:	e8 02 f7 ff ff       	call   f0100c2e <page_free>
	page_free(pp1);
f010152c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010152f:	89 04 24             	mov    %eax,(%esp)
f0101532:	e8 f7 f6 ff ff       	call   f0100c2e <page_free>
	page_free(pp2);
f0101537:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010153a:	89 04 24             	mov    %eax,(%esp)
f010153d:	e8 ec f6 ff ff       	call   f0100c2e <page_free>
	pp0 = pp1 = pp2 = 0;
f0101542:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0101549:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0101550:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	assert(page_alloc(&pp0) == 0);
f0101557:	8d 45 dc             	lea    -0x24(%ebp),%eax
f010155a:	89 04 24             	mov    %eax,(%esp)
f010155d:	e8 98 f6 ff ff       	call   f0100bfa <page_alloc>
f0101562:	85 c0                	test   %eax,%eax
f0101564:	74 24                	je     f010158a <i386_vm_init+0x5c0>
f0101566:	c7 44 24 0c 06 48 10 	movl   $0xf0104806,0xc(%esp)
f010156d:	f0 
f010156e:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101575:	f0 
f0101576:	c7 44 24 04 56 01 00 	movl   $0x156,0x4(%esp)
f010157d:	00 
f010157e:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101585:	e8 6c eb ff ff       	call   f01000f6 <_panic>
	assert(page_alloc(&pp1) == 0);
f010158a:	8d 45 e0             	lea    -0x20(%ebp),%eax
f010158d:	89 04 24             	mov    %eax,(%esp)
f0101590:	e8 65 f6 ff ff       	call   f0100bfa <page_alloc>
f0101595:	85 c0                	test   %eax,%eax
f0101597:	74 24                	je     f01015bd <i386_vm_init+0x5f3>
f0101599:	c7 44 24 0c 1c 48 10 	movl   $0xf010481c,0xc(%esp)
f01015a0:	f0 
f01015a1:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f01015a8:	f0 
f01015a9:	c7 44 24 04 57 01 00 	movl   $0x157,0x4(%esp)
f01015b0:	00 
f01015b1:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01015b8:	e8 39 eb ff ff       	call   f01000f6 <_panic>
	assert(page_alloc(&pp2) == 0);
f01015bd:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01015c0:	89 04 24             	mov    %eax,(%esp)
f01015c3:	e8 32 f6 ff ff       	call   f0100bfa <page_alloc>
f01015c8:	85 c0                	test   %eax,%eax
f01015ca:	74 24                	je     f01015f0 <i386_vm_init+0x626>
f01015cc:	c7 44 24 0c 32 48 10 	movl   $0xf0104832,0xc(%esp)
f01015d3:	f0 
f01015d4:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f01015db:	f0 
f01015dc:	c7 44 24 04 58 01 00 	movl   $0x158,0x4(%esp)
f01015e3:	00 
f01015e4:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01015eb:	e8 06 eb ff ff       	call   f01000f6 <_panic>
	assert(pp0);
f01015f0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01015f3:	85 d2                	test   %edx,%edx
f01015f5:	75 24                	jne    f010161b <i386_vm_init+0x651>
f01015f7:	c7 44 24 0c 56 48 10 	movl   $0xf0104856,0xc(%esp)
f01015fe:	f0 
f01015ff:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101606:	f0 
f0101607:	c7 44 24 04 59 01 00 	movl   $0x159,0x4(%esp)
f010160e:	00 
f010160f:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101616:	e8 db ea ff ff       	call   f01000f6 <_panic>
	assert(pp1 && pp1 != pp0);
f010161b:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010161e:	85 c9                	test   %ecx,%ecx
f0101620:	74 04                	je     f0101626 <i386_vm_init+0x65c>
f0101622:	39 ca                	cmp    %ecx,%edx
f0101624:	75 24                	jne    f010164a <i386_vm_init+0x680>
f0101626:	c7 44 24 0c 48 48 10 	movl   $0xf0104848,0xc(%esp)
f010162d:	f0 
f010162e:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101635:	f0 
f0101636:	c7 44 24 04 5a 01 00 	movl   $0x15a,0x4(%esp)
f010163d:	00 
f010163e:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101645:	e8 ac ea ff ff       	call   f01000f6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010164a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010164d:	85 c0                	test   %eax,%eax
f010164f:	74 08                	je     f0101659 <i386_vm_init+0x68f>
f0101651:	39 c1                	cmp    %eax,%ecx
f0101653:	74 04                	je     f0101659 <i386_vm_init+0x68f>
f0101655:	39 c2                	cmp    %eax,%edx
f0101657:	75 24                	jne    f010167d <i386_vm_init+0x6b3>
f0101659:	c7 44 24 0c 8c 42 10 	movl   $0xf010428c,0xc(%esp)
f0101660:	f0 
f0101661:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101668:	f0 
f0101669:	c7 44 24 04 5b 01 00 	movl   $0x15b,0x4(%esp)
f0101670:	00 
f0101671:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101678:	e8 79 ea ff ff       	call   f01000f6 <_panic>
	assert(page_alloc(&pp) == -E_NO_MEM);
f010167d:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0101680:	89 04 24             	mov    %eax,(%esp)
f0101683:	e8 72 f5 ff ff       	call   f0100bfa <page_alloc>
f0101688:	83 f8 fc             	cmp    $0xfffffffc,%eax
f010168b:	74 24                	je     f01016b1 <i386_vm_init+0x6e7>
f010168d:	c7 44 24 0c ae 48 10 	movl   $0xf01048ae,0xc(%esp)
f0101694:	f0 
f0101695:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f010169c:	f0 
f010169d:	c7 44 24 04 5c 01 00 	movl   $0x15c,0x4(%esp)
f01016a4:	00 
f01016a5:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01016ac:	e8 45 ea ff ff       	call   f01000f6 <_panic>

	// give free list back
	page_free_list = fl;
f01016b1:	89 1d d8 65 11 f0    	mov    %ebx,0xf01165d8

	// free the pages we took
	page_free(pp0);
f01016b7:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01016ba:	89 04 24             	mov    %eax,(%esp)
f01016bd:	e8 6c f5 ff ff       	call   f0100c2e <page_free>
	page_free(pp1);
f01016c2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01016c5:	89 04 24             	mov    %eax,(%esp)
f01016c8:	e8 61 f5 ff ff       	call   f0100c2e <page_free>
	page_free(pp2);
f01016cd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01016d0:	89 04 24             	mov    %eax,(%esp)
f01016d3:	e8 56 f5 ff ff       	call   f0100c2e <page_free>

	cprintf("check_page_alloc() succeeded!\n");
f01016d8:	c7 04 24 ac 42 10 f0 	movl   $0xf01042ac,(%esp)
f01016df:	e8 6e 15 00 00       	call   f0102c52 <cprintf>
	pte_t *ptep, *ptep1;
	void *va;
	int i;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
f01016e4:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01016eb:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01016f2:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
	assert(page_alloc(&pp0) == 0);
f01016f9:	8d 45 d8             	lea    -0x28(%ebp),%eax
f01016fc:	89 04 24             	mov    %eax,(%esp)
f01016ff:	e8 f6 f4 ff ff       	call   f0100bfa <page_alloc>
f0101704:	85 c0                	test   %eax,%eax
f0101706:	74 24                	je     f010172c <i386_vm_init+0x762>
f0101708:	c7 44 24 0c 06 48 10 	movl   $0xf0104806,0xc(%esp)
f010170f:	f0 
f0101710:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101717:	f0 
f0101718:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f010171f:	00 
f0101720:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101727:	e8 ca e9 ff ff       	call   f01000f6 <_panic>
	assert(page_alloc(&pp1) == 0);
f010172c:	8d 45 dc             	lea    -0x24(%ebp),%eax
f010172f:	89 04 24             	mov    %eax,(%esp)
f0101732:	e8 c3 f4 ff ff       	call   f0100bfa <page_alloc>
f0101737:	85 c0                	test   %eax,%eax
f0101739:	74 24                	je     f010175f <i386_vm_init+0x795>
f010173b:	c7 44 24 0c 1c 48 10 	movl   $0xf010481c,0xc(%esp)
f0101742:	f0 
f0101743:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f010174a:	f0 
f010174b:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
f0101752:	00 
f0101753:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f010175a:	e8 97 e9 ff ff       	call   f01000f6 <_panic>
	assert(page_alloc(&pp2) == 0);
f010175f:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0101762:	89 04 24             	mov    %eax,(%esp)
f0101765:	e8 90 f4 ff ff       	call   f0100bfa <page_alloc>
f010176a:	85 c0                	test   %eax,%eax
f010176c:	74 24                	je     f0101792 <i386_vm_init+0x7c8>
f010176e:	c7 44 24 0c 32 48 10 	movl   $0xf0104832,0xc(%esp)
f0101775:	f0 
f0101776:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f010177d:	f0 
f010177e:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0101785:	00 
f0101786:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f010178d:	e8 64 e9 ff ff       	call   f01000f6 <_panic>

	assert(pp0);
f0101792:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101795:	85 d2                	test   %edx,%edx
f0101797:	75 24                	jne    f01017bd <i386_vm_init+0x7f3>
f0101799:	c7 44 24 0c 56 48 10 	movl   $0xf0104856,0xc(%esp)
f01017a0:	f0 
f01017a1:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f01017a8:	f0 
f01017a9:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f01017b0:	00 
f01017b1:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01017b8:	e8 39 e9 ff ff       	call   f01000f6 <_panic>
	assert(pp1 && pp1 != pp0);
f01017bd:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01017c0:	85 c9                	test   %ecx,%ecx
f01017c2:	74 04                	je     f01017c8 <i386_vm_init+0x7fe>
f01017c4:	39 ca                	cmp    %ecx,%edx
f01017c6:	75 24                	jne    f01017ec <i386_vm_init+0x822>
f01017c8:	c7 44 24 0c 48 48 10 	movl   $0xf0104848,0xc(%esp)
f01017cf:	f0 
f01017d0:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f01017d7:	f0 
f01017d8:	c7 44 24 04 11 03 00 	movl   $0x311,0x4(%esp)
f01017df:	00 
f01017e0:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01017e7:	e8 0a e9 ff ff       	call   f01000f6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017ec:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01017ef:	85 c0                	test   %eax,%eax
f01017f1:	74 08                	je     f01017fb <i386_vm_init+0x831>
f01017f3:	39 c1                	cmp    %eax,%ecx
f01017f5:	74 04                	je     f01017fb <i386_vm_init+0x831>
f01017f7:	39 c2                	cmp    %eax,%edx
f01017f9:	75 24                	jne    f010181f <i386_vm_init+0x855>
f01017fb:	c7 44 24 0c 8c 42 10 	movl   $0xf010428c,0xc(%esp)
f0101802:	f0 
f0101803:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f010180a:	f0 
f010180b:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f0101812:	00 
f0101813:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f010181a:	e8 d7 e8 ff ff       	call   f01000f6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010181f:	8b 1d d8 65 11 f0    	mov    0xf01165d8,%ebx
f0101825:	89 5d c0             	mov    %ebx,-0x40(%ebp)
	LIST_INIT(&page_free_list);
f0101828:	c7 05 d8 65 11 f0 00 	movl   $0x0,0xf01165d8
f010182f:	00 00 00 

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);
f0101832:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f0101835:	89 04 24             	mov    %eax,(%esp)
f0101838:	e8 bd f3 ff ff       	call   f0100bfa <page_alloc>
f010183d:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101840:	74 24                	je     f0101866 <i386_vm_init+0x89c>
f0101842:	c7 44 24 0c ae 48 10 	movl   $0xf01048ae,0xc(%esp)
f0101849:	f0 
f010184a:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101851:	f0 
f0101852:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f0101859:	00 
f010185a:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101861:	e8 90 e8 ff ff       	call   f01000f6 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(boot_pgdir, (void *) 0x0, &ptep) == NULL);
f0101866:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101869:	89 44 24 08          	mov    %eax,0x8(%esp)
f010186d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101874:	00 
f0101875:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f010187a:	89 04 24             	mov    %eax,(%esp)
f010187d:	e8 d9 f5 ff ff       	call   f0100e5b <page_lookup>
f0101882:	85 c0                	test   %eax,%eax
f0101884:	74 24                	je     f01018aa <i386_vm_init+0x8e0>
f0101886:	c7 44 24 0c cc 42 10 	movl   $0xf01042cc,0xc(%esp)
f010188d:	f0 
f010188e:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101895:	f0 
f0101896:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f010189d:	00 
f010189e:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01018a5:	e8 4c e8 ff ff       	call   f01000f6 <_panic>

	// there is no free memory, so we can't allocate a page table 
	assert(page_insert(boot_pgdir, pp1, 0x0, 0) < 0);
f01018aa:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01018b1:	00 
f01018b2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01018b9:	00 
f01018ba:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01018bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018c1:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f01018c6:	89 04 24             	mov    %eax,(%esp)
f01018c9:	e8 5b f6 ff ff       	call   f0100f29 <page_insert>
f01018ce:	85 c0                	test   %eax,%eax
f01018d0:	78 24                	js     f01018f6 <i386_vm_init+0x92c>
f01018d2:	c7 44 24 0c 04 43 10 	movl   $0xf0104304,0xc(%esp)
f01018d9:	f0 
f01018da:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f01018e1:	f0 
f01018e2:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f01018e9:	00 
f01018ea:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01018f1:	e8 00 e8 ff ff       	call   f01000f6 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01018f6:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01018f9:	89 04 24             	mov    %eax,(%esp)
f01018fc:	e8 2d f3 ff ff       	call   f0100c2e <page_free>
	assert(page_insert(boot_pgdir, pp1, 0x0, 0) == 0);
f0101901:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101908:	00 
f0101909:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101910:	00 
f0101911:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101914:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101918:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f010191d:	89 04 24             	mov    %eax,(%esp)
f0101920:	e8 04 f6 ff ff       	call   f0100f29 <page_insert>
f0101925:	85 c0                	test   %eax,%eax
f0101927:	74 24                	je     f010194d <i386_vm_init+0x983>
f0101929:	c7 44 24 0c 30 43 10 	movl   $0xf0104330,0xc(%esp)
f0101930:	f0 
f0101931:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101938:	f0 
f0101939:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0101940:	00 
f0101941:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101948:	e8 a9 e7 ff ff       	call   f01000f6 <_panic>
	assert(PTE_ADDR(boot_pgdir[0]) == page2pa(pp0));
f010194d:	8b 1d 08 6a 11 f0    	mov    0xf0116a08,%ebx
f0101953:	8b 75 d8             	mov    -0x28(%ebp),%esi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101956:	8b 3d 0c 6a 11 f0    	mov    0xf0116a0c,%edi
f010195c:	8b 13                	mov    (%ebx),%edx
f010195e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101964:	89 f0                	mov    %esi,%eax
f0101966:	29 f8                	sub    %edi,%eax
f0101968:	c1 f8 02             	sar    $0x2,%eax
f010196b:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101971:	c1 e0 0c             	shl    $0xc,%eax
f0101974:	39 c2                	cmp    %eax,%edx
f0101976:	74 24                	je     f010199c <i386_vm_init+0x9d2>
f0101978:	c7 44 24 0c 5c 43 10 	movl   $0xf010435c,0xc(%esp)
f010197f:	f0 
f0101980:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101987:	f0 
f0101988:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f010198f:	00 
f0101990:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101997:	e8 5a e7 ff ff       	call   f01000f6 <_panic>
	assert(check_va2pa(boot_pgdir, 0x0) == page2pa(pp1));
f010199c:	ba 00 00 00 00       	mov    $0x0,%edx
f01019a1:	89 d8                	mov    %ebx,%eax
f01019a3:	e8 0a f0 ff ff       	call   f01009b2 <check_va2pa>
f01019a8:	8b 55 dc             	mov    -0x24(%ebp),%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f01019ab:	89 d1                	mov    %edx,%ecx
f01019ad:	29 f9                	sub    %edi,%ecx
f01019af:	c1 f9 02             	sar    $0x2,%ecx
f01019b2:	69 c9 ab aa aa aa    	imul   $0xaaaaaaab,%ecx,%ecx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f01019b8:	c1 e1 0c             	shl    $0xc,%ecx
f01019bb:	39 c8                	cmp    %ecx,%eax
f01019bd:	74 24                	je     f01019e3 <i386_vm_init+0xa19>
f01019bf:	c7 44 24 0c 84 43 10 	movl   $0xf0104384,0xc(%esp)
f01019c6:	f0 
f01019c7:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f01019ce:	f0 
f01019cf:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f01019d6:	00 
f01019d7:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01019de:	e8 13 e7 ff ff       	call   f01000f6 <_panic>
	assert(pp1->pp_ref == 1);
f01019e3:	66 83 7a 08 01       	cmpw   $0x1,0x8(%edx)
f01019e8:	74 24                	je     f0101a0e <i386_vm_init+0xa44>
f01019ea:	c7 44 24 0c cb 48 10 	movl   $0xf01048cb,0xc(%esp)
f01019f1:	f0 
f01019f2:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f01019f9:	f0 
f01019fa:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f0101a01:	00 
f0101a02:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101a09:	e8 e8 e6 ff ff       	call   f01000f6 <_panic>
	assert(pp0->pp_ref == 1);
f0101a0e:	66 83 7e 08 01       	cmpw   $0x1,0x8(%esi)
f0101a13:	74 24                	je     f0101a39 <i386_vm_init+0xa6f>
f0101a15:	c7 44 24 0c dc 48 10 	movl   $0xf01048dc,0xc(%esp)
f0101a1c:	f0 
f0101a1d:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101a24:	f0 
f0101a25:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f0101a2c:	00 
f0101a2d:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101a34:	e8 bd e6 ff ff       	call   f01000f6 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(boot_pgdir, pp2, (void*) PGSIZE, 0) == 0);
f0101a39:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101a40:	00 
f0101a41:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101a48:	00 
f0101a49:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101a4c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a50:	89 1c 24             	mov    %ebx,(%esp)
f0101a53:	e8 d1 f4 ff ff       	call   f0100f29 <page_insert>
f0101a58:	85 c0                	test   %eax,%eax
f0101a5a:	74 24                	je     f0101a80 <i386_vm_init+0xab6>
f0101a5c:	c7 44 24 0c b4 43 10 	movl   $0xf01043b4,0xc(%esp)
f0101a63:	f0 
f0101a64:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101a6b:	f0 
f0101a6c:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f0101a73:	00 
f0101a74:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101a7b:	e8 76 e6 ff ff       	call   f01000f6 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp2));
f0101a80:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a85:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f0101a8a:	e8 23 ef ff ff       	call   f01009b2 <check_va2pa>
f0101a8f:	8b 55 e0             	mov    -0x20(%ebp),%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101a92:	89 d1                	mov    %edx,%ecx
f0101a94:	2b 0d 0c 6a 11 f0    	sub    0xf0116a0c,%ecx
f0101a9a:	c1 f9 02             	sar    $0x2,%ecx
f0101a9d:	69 c9 ab aa aa aa    	imul   $0xaaaaaaab,%ecx,%ecx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101aa3:	c1 e1 0c             	shl    $0xc,%ecx
f0101aa6:	39 c8                	cmp    %ecx,%eax
f0101aa8:	74 24                	je     f0101ace <i386_vm_init+0xb04>
f0101aaa:	c7 44 24 0c ec 43 10 	movl   $0xf01043ec,0xc(%esp)
f0101ab1:	f0 
f0101ab2:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101ab9:	f0 
f0101aba:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0101ac1:	00 
f0101ac2:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101ac9:	e8 28 e6 ff ff       	call   f01000f6 <_panic>
	assert(pp2->pp_ref == 1);
f0101ace:	66 83 7a 08 01       	cmpw   $0x1,0x8(%edx)
f0101ad3:	74 24                	je     f0101af9 <i386_vm_init+0xb2f>
f0101ad5:	c7 44 24 0c ed 48 10 	movl   $0xf01048ed,0xc(%esp)
f0101adc:	f0 
f0101add:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101ae4:	f0 
f0101ae5:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f0101aec:	00 
f0101aed:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101af4:	e8 fd e5 ff ff       	call   f01000f6 <_panic>

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);
f0101af9:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f0101afc:	89 04 24             	mov    %eax,(%esp)
f0101aff:	e8 f6 f0 ff ff       	call   f0100bfa <page_alloc>
f0101b04:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101b07:	74 24                	je     f0101b2d <i386_vm_init+0xb63>
f0101b09:	c7 44 24 0c ae 48 10 	movl   $0xf01048ae,0xc(%esp)
f0101b10:	f0 
f0101b11:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101b18:	f0 
f0101b19:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f0101b20:	00 
f0101b21:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101b28:	e8 c9 e5 ff ff       	call   f01000f6 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(boot_pgdir, pp2, (void*) PGSIZE, 0) == 0);
f0101b2d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101b34:	00 
f0101b35:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b3c:	00 
f0101b3d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101b40:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101b44:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f0101b49:	89 04 24             	mov    %eax,(%esp)
f0101b4c:	e8 d8 f3 ff ff       	call   f0100f29 <page_insert>
f0101b51:	85 c0                	test   %eax,%eax
f0101b53:	74 24                	je     f0101b79 <i386_vm_init+0xbaf>
f0101b55:	c7 44 24 0c b4 43 10 	movl   $0xf01043b4,0xc(%esp)
f0101b5c:	f0 
f0101b5d:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101b64:	f0 
f0101b65:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f0101b6c:	00 
f0101b6d:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101b74:	e8 7d e5 ff ff       	call   f01000f6 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp2));
f0101b79:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b7e:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f0101b83:	e8 2a ee ff ff       	call   f01009b2 <check_va2pa>
f0101b88:	8b 55 e0             	mov    -0x20(%ebp),%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101b8b:	89 d1                	mov    %edx,%ecx
f0101b8d:	2b 0d 0c 6a 11 f0    	sub    0xf0116a0c,%ecx
f0101b93:	c1 f9 02             	sar    $0x2,%ecx
f0101b96:	69 c9 ab aa aa aa    	imul   $0xaaaaaaab,%ecx,%ecx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101b9c:	c1 e1 0c             	shl    $0xc,%ecx
f0101b9f:	39 c8                	cmp    %ecx,%eax
f0101ba1:	74 24                	je     f0101bc7 <i386_vm_init+0xbfd>
f0101ba3:	c7 44 24 0c ec 43 10 	movl   $0xf01043ec,0xc(%esp)
f0101baa:	f0 
f0101bab:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101bb2:	f0 
f0101bb3:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0101bba:	00 
f0101bbb:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101bc2:	e8 2f e5 ff ff       	call   f01000f6 <_panic>
	assert(pp2->pp_ref == 1);
f0101bc7:	66 83 7a 08 01       	cmpw   $0x1,0x8(%edx)
f0101bcc:	74 24                	je     f0101bf2 <i386_vm_init+0xc28>
f0101bce:	c7 44 24 0c ed 48 10 	movl   $0xf01048ed,0xc(%esp)
f0101bd5:	f0 
f0101bd6:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101bdd:	f0 
f0101bde:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f0101be5:	00 
f0101be6:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101bed:	e8 04 e5 ff ff       	call   f01000f6 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(page_alloc(&pp) == -E_NO_MEM);
f0101bf2:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f0101bf5:	89 04 24             	mov    %eax,(%esp)
f0101bf8:	e8 fd ef ff ff       	call   f0100bfa <page_alloc>
f0101bfd:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101c00:	74 24                	je     f0101c26 <i386_vm_init+0xc5c>
f0101c02:	c7 44 24 0c ae 48 10 	movl   $0xf01048ae,0xc(%esp)
f0101c09:	f0 
f0101c0a:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101c11:	f0 
f0101c12:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0101c19:	00 
f0101c1a:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101c21:	e8 d0 e4 ff ff       	call   f01000f6 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = KADDR(PTE_ADDR(boot_pgdir[PDX(PGSIZE)]));
f0101c26:	8b 15 08 6a 11 f0    	mov    0xf0116a08,%edx
f0101c2c:	8b 02                	mov    (%edx),%eax
f0101c2e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101c33:	89 c1                	mov    %eax,%ecx
f0101c35:	c1 e9 0c             	shr    $0xc,%ecx
f0101c38:	3b 0d 00 6a 11 f0    	cmp    0xf0116a00,%ecx
f0101c3e:	72 20                	jb     f0101c60 <i386_vm_init+0xc96>
f0101c40:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101c44:	c7 44 24 08 a4 41 10 	movl   $0xf01041a4,0x8(%esp)
f0101c4b:	f0 
f0101c4c:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f0101c53:	00 
f0101c54:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101c5b:	e8 96 e4 ff ff       	call   f01000f6 <_panic>
f0101c60:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101c65:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(boot_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c68:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101c6f:	00 
f0101c70:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101c77:	00 
f0101c78:	89 14 24             	mov    %edx,(%esp)
f0101c7b:	e8 1f f0 ff ff       	call   f0100c9f <pgdir_walk>
f0101c80:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101c83:	83 c2 04             	add    $0x4,%edx
f0101c86:	39 d0                	cmp    %edx,%eax
f0101c88:	74 24                	je     f0101cae <i386_vm_init+0xce4>
f0101c8a:	c7 44 24 0c 1c 44 10 	movl   $0xf010441c,0xc(%esp)
f0101c91:	f0 
f0101c92:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101c99:	f0 
f0101c9a:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f0101ca1:	00 
f0101ca2:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101ca9:	e8 48 e4 ff ff       	call   f01000f6 <_panic>

	// should be able to change permissions too.
	assert(page_insert(boot_pgdir, pp2, (void*) PGSIZE, PTE_U) == 0);
f0101cae:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0101cb5:	00 
f0101cb6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101cbd:	00 
f0101cbe:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101cc1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101cc5:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f0101cca:	89 04 24             	mov    %eax,(%esp)
f0101ccd:	e8 57 f2 ff ff       	call   f0100f29 <page_insert>
f0101cd2:	85 c0                	test   %eax,%eax
f0101cd4:	74 24                	je     f0101cfa <i386_vm_init+0xd30>
f0101cd6:	c7 44 24 0c 5c 44 10 	movl   $0xf010445c,0xc(%esp)
f0101cdd:	f0 
f0101cde:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101ce5:	f0 
f0101ce6:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f0101ced:	00 
f0101cee:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101cf5:	e8 fc e3 ff ff       	call   f01000f6 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp2));
f0101cfa:	8b 1d 08 6a 11 f0    	mov    0xf0116a08,%ebx
f0101d00:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d05:	89 d8                	mov    %ebx,%eax
f0101d07:	e8 a6 ec ff ff       	call   f01009b2 <check_va2pa>
f0101d0c:	8b 55 e0             	mov    -0x20(%ebp),%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101d0f:	89 d1                	mov    %edx,%ecx
f0101d11:	2b 0d 0c 6a 11 f0    	sub    0xf0116a0c,%ecx
f0101d17:	c1 f9 02             	sar    $0x2,%ecx
f0101d1a:	69 c9 ab aa aa aa    	imul   $0xaaaaaaab,%ecx,%ecx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101d20:	c1 e1 0c             	shl    $0xc,%ecx
f0101d23:	39 c8                	cmp    %ecx,%eax
f0101d25:	74 24                	je     f0101d4b <i386_vm_init+0xd81>
f0101d27:	c7 44 24 0c ec 43 10 	movl   $0xf01043ec,0xc(%esp)
f0101d2e:	f0 
f0101d2f:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101d36:	f0 
f0101d37:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0101d3e:	00 
f0101d3f:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101d46:	e8 ab e3 ff ff       	call   f01000f6 <_panic>
	assert(pp2->pp_ref == 1);
f0101d4b:	66 83 7a 08 01       	cmpw   $0x1,0x8(%edx)
f0101d50:	74 24                	je     f0101d76 <i386_vm_init+0xdac>
f0101d52:	c7 44 24 0c ed 48 10 	movl   $0xf01048ed,0xc(%esp)
f0101d59:	f0 
f0101d5a:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101d61:	f0 
f0101d62:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0101d69:	00 
f0101d6a:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101d71:	e8 80 e3 ff ff       	call   f01000f6 <_panic>
	assert(*pgdir_walk(boot_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101d76:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d7d:	00 
f0101d7e:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101d85:	00 
f0101d86:	89 1c 24             	mov    %ebx,(%esp)
f0101d89:	e8 11 ef ff ff       	call   f0100c9f <pgdir_walk>
f0101d8e:	f6 00 04             	testb  $0x4,(%eax)
f0101d91:	75 24                	jne    f0101db7 <i386_vm_init+0xded>
f0101d93:	c7 44 24 0c 98 44 10 	movl   $0xf0104498,0xc(%esp)
f0101d9a:	f0 
f0101d9b:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101da2:	f0 
f0101da3:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0101daa:	00 
f0101dab:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101db2:	e8 3f e3 ff ff       	call   f01000f6 <_panic>
	assert(boot_pgdir[0] & PTE_U);
f0101db7:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f0101dbc:	f6 00 04             	testb  $0x4,(%eax)
f0101dbf:	75 24                	jne    f0101de5 <i386_vm_init+0xe1b>
f0101dc1:	c7 44 24 0c fe 48 10 	movl   $0xf01048fe,0xc(%esp)
f0101dc8:	f0 
f0101dc9:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101dd0:	f0 
f0101dd1:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f0101dd8:	00 
f0101dd9:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101de0:	e8 11 e3 ff ff       	call   f01000f6 <_panic>
	
	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(boot_pgdir, pp0, (void*) PTSIZE, 0) < 0);
f0101de5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101dec:	00 
f0101ded:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101df4:	00 
f0101df5:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101df8:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101dfc:	89 04 24             	mov    %eax,(%esp)
f0101dff:	e8 25 f1 ff ff       	call   f0100f29 <page_insert>
f0101e04:	85 c0                	test   %eax,%eax
f0101e06:	78 24                	js     f0101e2c <i386_vm_init+0xe62>
f0101e08:	c7 44 24 0c cc 44 10 	movl   $0xf01044cc,0xc(%esp)
f0101e0f:	f0 
f0101e10:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101e17:	f0 
f0101e18:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f0101e1f:	00 
f0101e20:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101e27:	e8 ca e2 ff ff       	call   f01000f6 <_panic>
	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(boot_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101e2c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101e33:	00 
f0101e34:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e3b:	00 
f0101e3c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101e3f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101e43:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f0101e48:	89 04 24             	mov    %eax,(%esp)
f0101e4b:	e8 d9 f0 ff ff       	call   f0100f29 <page_insert>
f0101e50:	85 c0                	test   %eax,%eax
f0101e52:	74 24                	je     f0101e78 <i386_vm_init+0xeae>
f0101e54:	c7 44 24 0c 00 45 10 	movl   $0xf0104500,0xc(%esp)
f0101e5b:	f0 
f0101e5c:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101e63:	f0 
f0101e64:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0101e6b:	00 
f0101e6c:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101e73:	e8 7e e2 ff ff       	call   f01000f6 <_panic>
	assert(!(*pgdir_walk(boot_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e78:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e7f:	00 
f0101e80:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e87:	00 
f0101e88:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f0101e8d:	89 04 24             	mov    %eax,(%esp)
f0101e90:	e8 0a ee ff ff       	call   f0100c9f <pgdir_walk>
f0101e95:	f6 00 04             	testb  $0x4,(%eax)
f0101e98:	74 24                	je     f0101ebe <i386_vm_init+0xef4>
f0101e9a:	c7 44 24 0c 38 45 10 	movl   $0xf0104538,0xc(%esp)
f0101ea1:	f0 
f0101ea2:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101ea9:	f0 
f0101eaa:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f0101eb1:	00 
f0101eb2:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101eb9:	e8 38 e2 ff ff       	call   f01000f6 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(boot_pgdir, 0) == page2pa(pp1));
f0101ebe:	8b 3d 08 6a 11 f0    	mov    0xf0116a08,%edi
f0101ec4:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ec9:	89 f8                	mov    %edi,%eax
f0101ecb:	e8 e2 ea ff ff       	call   f01009b2 <check_va2pa>
f0101ed0:	89 c6                	mov    %eax,%esi
f0101ed2:	8b 5d dc             	mov    -0x24(%ebp),%ebx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0101ed5:	89 d8                	mov    %ebx,%eax
f0101ed7:	2b 05 0c 6a 11 f0    	sub    0xf0116a0c,%eax
f0101edd:	c1 f8 02             	sar    $0x2,%eax
f0101ee0:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0101ee6:	c1 e0 0c             	shl    $0xc,%eax
f0101ee9:	39 c6                	cmp    %eax,%esi
f0101eeb:	74 24                	je     f0101f11 <i386_vm_init+0xf47>
f0101eed:	c7 44 24 0c 70 45 10 	movl   $0xf0104570,0xc(%esp)
f0101ef4:	f0 
f0101ef5:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101efc:	f0 
f0101efd:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0101f04:	00 
f0101f05:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101f0c:	e8 e5 e1 ff ff       	call   f01000f6 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp1));
f0101f11:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f16:	89 f8                	mov    %edi,%eax
f0101f18:	e8 95 ea ff ff       	call   f01009b2 <check_va2pa>
f0101f1d:	39 c6                	cmp    %eax,%esi
f0101f1f:	74 24                	je     f0101f45 <i386_vm_init+0xf7b>
f0101f21:	c7 44 24 0c 9c 45 10 	movl   $0xf010459c,0xc(%esp)
f0101f28:	f0 
f0101f29:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101f30:	f0 
f0101f31:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0101f38:	00 
f0101f39:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101f40:	e8 b1 e1 ff ff       	call   f01000f6 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101f45:	66 83 7b 08 02       	cmpw   $0x2,0x8(%ebx)
f0101f4a:	74 24                	je     f0101f70 <i386_vm_init+0xfa6>
f0101f4c:	c7 44 24 0c 14 49 10 	movl   $0xf0104914,0xc(%esp)
f0101f53:	f0 
f0101f54:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101f5b:	f0 
f0101f5c:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f0101f63:	00 
f0101f64:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101f6b:	e8 86 e1 ff ff       	call   f01000f6 <_panic>
	assert(pp2->pp_ref == 0);
f0101f70:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101f73:	66 83 78 08 00       	cmpw   $0x0,0x8(%eax)
f0101f78:	74 24                	je     f0101f9e <i386_vm_init+0xfd4>
f0101f7a:	c7 44 24 0c 25 49 10 	movl   $0xf0104925,0xc(%esp)
f0101f81:	f0 
f0101f82:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101f89:	f0 
f0101f8a:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f0101f91:	00 
f0101f92:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101f99:	e8 58 e1 ff ff       	call   f01000f6 <_panic>

	// pp2 should be returned by page_alloc
	assert(page_alloc(&pp) == 0 && pp == pp2);
f0101f9e:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f0101fa1:	89 04 24             	mov    %eax,(%esp)
f0101fa4:	e8 51 ec ff ff       	call   f0100bfa <page_alloc>
f0101fa9:	85 c0                	test   %eax,%eax
f0101fab:	75 08                	jne    f0101fb5 <i386_vm_init+0xfeb>
f0101fad:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101fb0:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101fb3:	74 24                	je     f0101fd9 <i386_vm_init+0x100f>
f0101fb5:	c7 44 24 0c cc 45 10 	movl   $0xf01045cc,0xc(%esp)
f0101fbc:	f0 
f0101fbd:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0101fc4:	f0 
f0101fc5:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f0101fcc:	00 
f0101fcd:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0101fd4:	e8 1d e1 ff ff       	call   f01000f6 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(boot_pgdir, 0x0);
f0101fd9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101fe0:	00 
f0101fe1:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f0101fe6:	89 04 24             	mov    %eax,(%esp)
f0101fe9:	e8 e7 ee ff ff       	call   f0100ed5 <page_remove>
	assert(check_va2pa(boot_pgdir, 0x0) == ~0);
f0101fee:	8b 1d 08 6a 11 f0    	mov    0xf0116a08,%ebx
f0101ff4:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ff9:	89 d8                	mov    %ebx,%eax
f0101ffb:	e8 b2 e9 ff ff       	call   f01009b2 <check_va2pa>
f0102000:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102003:	74 24                	je     f0102029 <i386_vm_init+0x105f>
f0102005:	c7 44 24 0c f0 45 10 	movl   $0xf01045f0,0xc(%esp)
f010200c:	f0 
f010200d:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0102014:	f0 
f0102015:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f010201c:	00 
f010201d:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0102024:	e8 cd e0 ff ff       	call   f01000f6 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp1));
f0102029:	ba 00 10 00 00       	mov    $0x1000,%edx
f010202e:	89 d8                	mov    %ebx,%eax
f0102030:	e8 7d e9 ff ff       	call   f01009b2 <check_va2pa>
f0102035:	8b 55 dc             	mov    -0x24(%ebp),%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0102038:	89 d1                	mov    %edx,%ecx
f010203a:	2b 0d 0c 6a 11 f0    	sub    0xf0116a0c,%ecx
f0102040:	c1 f9 02             	sar    $0x2,%ecx
f0102043:	69 c9 ab aa aa aa    	imul   $0xaaaaaaab,%ecx,%ecx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0102049:	c1 e1 0c             	shl    $0xc,%ecx
f010204c:	39 c8                	cmp    %ecx,%eax
f010204e:	74 24                	je     f0102074 <i386_vm_init+0x10aa>
f0102050:	c7 44 24 0c 9c 45 10 	movl   $0xf010459c,0xc(%esp)
f0102057:	f0 
f0102058:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f010205f:	f0 
f0102060:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f0102067:	00 
f0102068:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f010206f:	e8 82 e0 ff ff       	call   f01000f6 <_panic>
	assert(pp1->pp_ref == 1);
f0102074:	66 83 7a 08 01       	cmpw   $0x1,0x8(%edx)
f0102079:	74 24                	je     f010209f <i386_vm_init+0x10d5>
f010207b:	c7 44 24 0c cb 48 10 	movl   $0xf01048cb,0xc(%esp)
f0102082:	f0 
f0102083:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f010208a:	f0 
f010208b:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
f0102092:	00 
f0102093:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f010209a:	e8 57 e0 ff ff       	call   f01000f6 <_panic>
	assert(pp2->pp_ref == 0);
f010209f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01020a2:	66 83 78 08 00       	cmpw   $0x0,0x8(%eax)
f01020a7:	74 24                	je     f01020cd <i386_vm_init+0x1103>
f01020a9:	c7 44 24 0c 25 49 10 	movl   $0xf0104925,0xc(%esp)
f01020b0:	f0 
f01020b1:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f01020b8:	f0 
f01020b9:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f01020c0:	00 
f01020c1:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01020c8:	e8 29 e0 ff ff       	call   f01000f6 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(boot_pgdir, (void*) PGSIZE);
f01020cd:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01020d4:	00 
f01020d5:	89 1c 24             	mov    %ebx,(%esp)
f01020d8:	e8 f8 ed ff ff       	call   f0100ed5 <page_remove>
	assert(check_va2pa(boot_pgdir, 0x0) == ~0);
f01020dd:	8b 1d 08 6a 11 f0    	mov    0xf0116a08,%ebx
f01020e3:	ba 00 00 00 00       	mov    $0x0,%edx
f01020e8:	89 d8                	mov    %ebx,%eax
f01020ea:	e8 c3 e8 ff ff       	call   f01009b2 <check_va2pa>
f01020ef:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020f2:	74 24                	je     f0102118 <i386_vm_init+0x114e>
f01020f4:	c7 44 24 0c f0 45 10 	movl   $0xf01045f0,0xc(%esp)
f01020fb:	f0 
f01020fc:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0102103:	f0 
f0102104:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f010210b:	00 
f010210c:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0102113:	e8 de df ff ff       	call   f01000f6 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == ~0);
f0102118:	ba 00 10 00 00       	mov    $0x1000,%edx
f010211d:	89 d8                	mov    %ebx,%eax
f010211f:	e8 8e e8 ff ff       	call   f01009b2 <check_va2pa>
f0102124:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102127:	74 24                	je     f010214d <i386_vm_init+0x1183>
f0102129:	c7 44 24 0c 14 46 10 	movl   $0xf0104614,0xc(%esp)
f0102130:	f0 
f0102131:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0102138:	f0 
f0102139:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f0102140:	00 
f0102141:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0102148:	e8 a9 df ff ff       	call   f01000f6 <_panic>
	assert(pp1->pp_ref == 0);
f010214d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102150:	66 83 78 08 00       	cmpw   $0x0,0x8(%eax)
f0102155:	74 24                	je     f010217b <i386_vm_init+0x11b1>
f0102157:	c7 44 24 0c 36 49 10 	movl   $0xf0104936,0xc(%esp)
f010215e:	f0 
f010215f:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0102166:	f0 
f0102167:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f010216e:	00 
f010216f:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0102176:	e8 7b df ff ff       	call   f01000f6 <_panic>
	assert(pp2->pp_ref == 0);
f010217b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010217e:	66 83 78 08 00       	cmpw   $0x0,0x8(%eax)
f0102183:	74 24                	je     f01021a9 <i386_vm_init+0x11df>
f0102185:	c7 44 24 0c 25 49 10 	movl   $0xf0104925,0xc(%esp)
f010218c:	f0 
f010218d:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0102194:	f0 
f0102195:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f010219c:	00 
f010219d:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01021a4:	e8 4d df ff ff       	call   f01000f6 <_panic>

	// so it should be returned by page_alloc
	assert(page_alloc(&pp) == 0 && pp == pp1);
f01021a9:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f01021ac:	89 04 24             	mov    %eax,(%esp)
f01021af:	e8 46 ea ff ff       	call   f0100bfa <page_alloc>
f01021b4:	85 c0                	test   %eax,%eax
f01021b6:	75 08                	jne    f01021c0 <i386_vm_init+0x11f6>
f01021b8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01021bb:	39 55 d4             	cmp    %edx,-0x2c(%ebp)
f01021be:	74 24                	je     f01021e4 <i386_vm_init+0x121a>
f01021c0:	c7 44 24 0c 3c 46 10 	movl   $0xf010463c,0xc(%esp)
f01021c7:	f0 
f01021c8:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f01021cf:	f0 
f01021d0:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f01021d7:	00 
f01021d8:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01021df:	e8 12 df ff ff       	call   f01000f6 <_panic>

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);
f01021e4:	8d 45 d4             	lea    -0x2c(%ebp),%eax
f01021e7:	89 04 24             	mov    %eax,(%esp)
f01021ea:	e8 0b ea ff ff       	call   f0100bfa <page_alloc>
f01021ef:	83 f8 fc             	cmp    $0xfffffffc,%eax
f01021f2:	74 24                	je     f0102218 <i386_vm_init+0x124e>
f01021f4:	c7 44 24 0c ae 48 10 	movl   $0xf01048ae,0xc(%esp)
f01021fb:	f0 
f01021fc:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0102203:	f0 
f0102204:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f010220b:	00 
f010220c:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0102213:	e8 de de ff ff       	call   f01000f6 <_panic>
	page_remove(boot_pgdir, 0x0);
	assert(pp2->pp_ref == 0);
#endif

	// forcibly take pp0 back
	assert(PTE_ADDR(boot_pgdir[0]) == page2pa(pp0));
f0102218:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f010221d:	8b 08                	mov    (%eax),%ecx
f010221f:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0102225:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102228:	2b 15 0c 6a 11 f0    	sub    0xf0116a0c,%edx
f010222e:	c1 fa 02             	sar    $0x2,%edx
f0102231:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f0102237:	c1 e2 0c             	shl    $0xc,%edx
f010223a:	39 d1                	cmp    %edx,%ecx
f010223c:	74 24                	je     f0102262 <i386_vm_init+0x1298>
f010223e:	c7 44 24 0c 5c 43 10 	movl   $0xf010435c,0xc(%esp)
f0102245:	f0 
f0102246:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f010224d:	f0 
f010224e:	c7 44 24 04 7a 03 00 	movl   $0x37a,0x4(%esp)
f0102255:	00 
f0102256:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f010225d:	e8 94 de ff ff       	call   f01000f6 <_panic>
	boot_pgdir[0] = 0;
f0102262:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102268:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010226b:	66 83 78 08 01       	cmpw   $0x1,0x8(%eax)
f0102270:	74 24                	je     f0102296 <i386_vm_init+0x12cc>
f0102272:	c7 44 24 0c dc 48 10 	movl   $0xf01048dc,0xc(%esp)
f0102279:	f0 
f010227a:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0102281:	f0 
f0102282:	c7 44 24 04 7c 03 00 	movl   $0x37c,0x4(%esp)
f0102289:	00 
f010228a:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0102291:	e8 60 de ff ff       	call   f01000f6 <_panic>
	pp0->pp_ref = 0;
f0102296:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
	
	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010229c:	89 04 24             	mov    %eax,(%esp)
f010229f:	e8 8a e9 ff ff       	call   f0100c2e <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(boot_pgdir, va, 1);
f01022a4:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01022ab:	00 
f01022ac:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01022b3:	00 
f01022b4:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f01022b9:	89 04 24             	mov    %eax,(%esp)
f01022bc:	e8 de e9 ff ff       	call   f0100c9f <pgdir_walk>
f01022c1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = KADDR(PTE_ADDR(boot_pgdir[PDX(va)]));
f01022c4:	8b 1d 08 6a 11 f0    	mov    0xf0116a08,%ebx
f01022ca:	8b 53 04             	mov    0x4(%ebx),%edx
f01022cd:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01022d3:	8b 0d 00 6a 11 f0    	mov    0xf0116a00,%ecx
f01022d9:	89 d6                	mov    %edx,%esi
f01022db:	c1 ee 0c             	shr    $0xc,%esi
f01022de:	39 ce                	cmp    %ecx,%esi
f01022e0:	72 20                	jb     f0102302 <i386_vm_init+0x1338>
f01022e2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01022e6:	c7 44 24 08 a4 41 10 	movl   $0xf01041a4,0x8(%esp)
f01022ed:	f0 
f01022ee:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f01022f5:	00 
f01022f6:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01022fd:	e8 f4 dd ff ff       	call   f01000f6 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102302:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102308:	39 d0                	cmp    %edx,%eax
f010230a:	74 24                	je     f0102330 <i386_vm_init+0x1366>
f010230c:	c7 44 24 0c 47 49 10 	movl   $0xf0104947,0xc(%esp)
f0102313:	f0 
f0102314:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f010231b:	f0 
f010231c:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0102323:	00 
f0102324:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f010232b:	e8 c6 dd ff ff       	call   f01000f6 <_panic>
	boot_pgdir[PDX(va)] = 0;
f0102330:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f0102337:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010233a:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f0102340:	2b 05 0c 6a 11 f0    	sub    0xf0116a0c,%eax
f0102346:	c1 f8 02             	sar    $0x2,%eax
f0102349:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f010234f:	c1 e0 0c             	shl    $0xc,%eax
}

static inline void*
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
f0102352:	89 c2                	mov    %eax,%edx
f0102354:	c1 ea 0c             	shr    $0xc,%edx
f0102357:	39 d1                	cmp    %edx,%ecx
f0102359:	77 20                	ja     f010237b <i386_vm_init+0x13b1>
f010235b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010235f:	c7 44 24 08 a4 41 10 	movl   $0xf01041a4,0x8(%esp)
f0102366:	f0 
f0102367:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010236e:	00 
f010236f:	c7 04 24 7b 47 10 f0 	movl   $0xf010477b,(%esp)
f0102376:	e8 7b dd ff ff       	call   f01000f6 <_panic>
	
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010237b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102382:	00 
f0102383:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f010238a:	00 
f010238b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102390:	89 04 24             	mov    %eax,(%esp)
f0102393:	e8 1c 14 00 00       	call   f01037b4 <memset>
	page_free(pp0);
f0102398:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010239b:	89 04 24             	mov    %eax,(%esp)
f010239e:	e8 8b e8 ff ff       	call   f0100c2e <page_free>
	pgdir_walk(boot_pgdir, 0x0, 1);
f01023a3:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01023aa:	00 
f01023ab:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01023b2:	00 
f01023b3:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f01023b8:	89 04 24             	mov    %eax,(%esp)
f01023bb:	e8 df e8 ff ff       	call   f0100c9f <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
	return pp - pages;
f01023c0:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01023c3:	2b 15 0c 6a 11 f0    	sub    0xf0116a0c,%edx
f01023c9:	c1 fa 02             	sar    $0x2,%edx
f01023cc:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
}

static inline physaddr_t
page2pa(struct Page *pp)
{
	return page2ppn(pp) << PGSHIFT;
f01023d2:	c1 e2 0c             	shl    $0xc,%edx
}

static inline void*
page2kva(struct Page *pp)
{
	return KADDR(page2pa(pp));
f01023d5:	89 d0                	mov    %edx,%eax
f01023d7:	c1 e8 0c             	shr    $0xc,%eax
f01023da:	3b 05 00 6a 11 f0    	cmp    0xf0116a00,%eax
f01023e0:	72 20                	jb     f0102402 <i386_vm_init+0x1438>
f01023e2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01023e6:	c7 44 24 08 a4 41 10 	movl   $0xf01041a4,0x8(%esp)
f01023ed:	f0 
f01023ee:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01023f5:	00 
f01023f6:	c7 04 24 7b 47 10 f0 	movl   $0xf010477b,(%esp)
f01023fd:	e8 f4 dc ff ff       	call   f01000f6 <_panic>
f0102402:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = page2kva(pp0);
f0102408:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010240b:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f0102412:	75 11                	jne    f0102425 <i386_vm_init+0x145b>
f0102414:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read (or write). 
void
i386_vm_init(void)
f010241a:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(boot_pgdir, 0x0, 1);
	ptep = page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102420:	f6 00 01             	testb  $0x1,(%eax)
f0102423:	74 24                	je     f0102449 <i386_vm_init+0x147f>
f0102425:	c7 44 24 0c 5f 49 10 	movl   $0xf010495f,0xc(%esp)
f010242c:	f0 
f010242d:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0102434:	f0 
f0102435:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f010243c:	00 
f010243d:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0102444:	e8 ad dc ff ff       	call   f01000f6 <_panic>
f0102449:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(boot_pgdir, 0x0, 1);
	ptep = page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010244c:	39 d0                	cmp    %edx,%eax
f010244e:	75 d0                	jne    f0102420 <i386_vm_init+0x1456>
		assert((ptep[i] & PTE_P) == 0);
	boot_pgdir[0] = 0;
f0102450:	a1 08 6a 11 f0       	mov    0xf0116a08,%eax
f0102455:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010245b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010245e:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)

	// give free list back
	page_free_list = fl;
f0102464:	8b 5d c0             	mov    -0x40(%ebp),%ebx
f0102467:	89 1d d8 65 11 f0    	mov    %ebx,0xf01165d8

	// free the pages we took
	page_free(pp0);
f010246d:	89 04 24             	mov    %eax,(%esp)
f0102470:	e8 b9 e7 ff ff       	call   f0100c2e <page_free>
	page_free(pp1);
f0102475:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102478:	89 04 24             	mov    %eax,(%esp)
f010247b:	e8 ae e7 ff ff       	call   f0100c2e <page_free>
	page_free(pp2);
f0102480:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102483:	89 04 24             	mov    %eax,(%esp)
f0102486:	e8 a3 e7 ff ff       	call   f0100c2e <page_free>
	
	cprintf("page_check() succeeded!\n");
f010248b:	c7 04 24 76 49 10 f0 	movl   $0xf0104976,(%esp)
f0102492:	e8 bb 07 00 00       	call   f0102c52 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	
	boot_map_segment(pgdir, UPAGES, n, PADDR(pages), PTE_U | PTE_P) ;
f0102497:	a1 0c 6a 11 f0       	mov    0xf0116a0c,%eax
f010249c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01024a1:	77 20                	ja     f01024c3 <i386_vm_init+0x14f9>
f01024a3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01024a7:	c7 44 24 08 ec 41 10 	movl   $0xf01041ec,0x8(%esp)
f01024ae:	f0 
f01024af:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
f01024b6:	00 
f01024b7:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01024be:	e8 33 dc ff ff       	call   f01000f6 <_panic>
f01024c3:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f01024ca:	00 
f01024cb:	05 00 00 00 10       	add    $0x10000000,%eax
f01024d0:	89 04 24             	mov    %eax,(%esp)
f01024d3:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f01024d6:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01024db:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01024de:	e8 14 e9 ff ff       	call   f0100df7 <boot_map_segment>
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_segment(pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, 
		PADDR(bootstack), PTE_W | PTE_P) ;
f01024e3:	bb 00 e0 10 f0       	mov    $0xf010e000,%ebx
f01024e8:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01024ee:	77 20                	ja     f0102510 <i386_vm_init+0x1546>
f01024f0:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01024f4:	c7 44 24 08 ec 41 10 	movl   $0xf01041ec,0x8(%esp)
f01024fb:	f0 
f01024fc:	c7 44 24 04 df 00 00 	movl   $0xdf,0x4(%esp)
f0102503:	00 
f0102504:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f010250b:	e8 e6 db ff ff       	call   f01000f6 <_panic>
f0102510:	c7 45 c0 00 e0 10 00 	movl   $0x10e000,-0x40(%ebp)
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_segment(pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, 
f0102517:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f010251e:	00 
f010251f:	c7 04 24 00 e0 10 00 	movl   $0x10e000,(%esp)
f0102526:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010252b:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102530:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0102533:	e8 bf e8 ff ff       	call   f0100df7 <boot_map_segment>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here: 
	boot_map_segment(pgdir, KERNBASE, 0xFFFFFFFF - KERNBASE, 0, PTE_W | PTE_P) ;
f0102538:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f010253f:	00 
f0102540:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102547:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f010254c:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102551:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0102554:	e8 9e e8 ff ff       	call   f0100df7 <boot_map_segment>
check_boot_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = boot_pgdir;
f0102559:	8b 3d 08 6a 11 f0    	mov    0xf0116a08,%edi

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
f010255f:	a1 00 6a 11 f0       	mov    0xf0116a00,%eax
f0102564:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0102567:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010256a:	8d 04 85 ff 0f 00 00 	lea    0xfff(,%eax,4),%eax
	for (i = 0; i < n; i += PGSIZE)
f0102571:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102576:	89 45 b8             	mov    %eax,-0x48(%ebp)
f0102579:	0f 84 84 00 00 00    	je     f0102603 <i386_vm_init+0x1639>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010257f:	8b 35 0c 6a 11 f0    	mov    0xf0116a0c,%esi
f0102585:	8d 96 00 00 00 10    	lea    0x10000000(%esi),%edx
f010258b:	89 55 b4             	mov    %edx,-0x4c(%ebp)
f010258e:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102593:	89 f8                	mov    %edi,%eax
f0102595:	e8 18 e4 ff ff       	call   f01009b2 <check_va2pa>
f010259a:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f01025a0:	77 20                	ja     f01025c2 <i386_vm_init+0x15f8>
f01025a2:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01025a6:	c7 44 24 08 ec 41 10 	movl   $0xf01041ec,0x8(%esp)
f01025ad:	f0 
f01025ae:	c7 44 24 04 7e 01 00 	movl   $0x17e,0x4(%esp)
f01025b5:	00 
f01025b6:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01025bd:	e8 34 db ff ff       	call   f01000f6 <_panic>

	pgdir = boot_pgdir;

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01025c2:	ba 00 00 00 00       	mov    $0x0,%edx
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read (or write). 
void
i386_vm_init(void)
f01025c7:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
f01025ca:	01 d1                	add    %edx,%ecx
	pgdir = boot_pgdir;

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01025cc:	39 c1                	cmp    %eax,%ecx
f01025ce:	74 24                	je     f01025f4 <i386_vm_init+0x162a>
f01025d0:	c7 44 24 0c 60 46 10 	movl   $0xf0104660,0xc(%esp)
f01025d7:	f0 
f01025d8:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f01025df:	f0 
f01025e0:	c7 44 24 04 7e 01 00 	movl   $0x17e,0x4(%esp)
f01025e7:	00 
f01025e8:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01025ef:	e8 02 db ff ff       	call   f01000f6 <_panic>

	pgdir = boot_pgdir;

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01025f4:	8d b2 00 10 00 00    	lea    0x1000(%edx),%esi
f01025fa:	39 75 b8             	cmp    %esi,-0x48(%ebp)
f01025fd:	0f 87 fd 01 00 00    	ja     f0102800 <i386_vm_init+0x1836>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	

	// check phys mem
	for (i = 0; i < npage * PGSIZE; i += PGSIZE)
f0102603:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102606:	c1 e1 0c             	shl    $0xc,%ecx
f0102609:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f010260c:	85 c9                	test   %ecx,%ecx
f010260e:	0f 84 cd 01 00 00    	je     f01027e1 <i386_vm_init+0x1817>
f0102614:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read (or write). 
void
i386_vm_init(void)
f0102619:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	

	// check phys mem
	for (i = 0; i < npage * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010261f:	89 f8                	mov    %edi,%eax
f0102621:	e8 8c e3 ff ff       	call   f01009b2 <check_va2pa>
f0102626:	39 c6                	cmp    %eax,%esi
f0102628:	74 24                	je     f010264e <i386_vm_init+0x1684>
f010262a:	c7 44 24 0c 94 46 10 	movl   $0xf0104694,0xc(%esp)
f0102631:	f0 
f0102632:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0102639:	f0 
f010263a:	c7 44 24 04 83 01 00 	movl   $0x183,0x4(%esp)
f0102641:	00 
f0102642:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0102649:	e8 a8 da ff ff       	call   f01000f6 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	

	// check phys mem
	for (i = 0; i < npage * PGSIZE; i += PGSIZE)
f010264e:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102654:	3b 75 c4             	cmp    -0x3c(%ebp),%esi
f0102657:	72 c0                	jb     f0102619 <i386_vm_init+0x164f>
f0102659:	e9 83 01 00 00       	jmp    f01027e1 <i386_vm_init+0x1817>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010265e:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f0102661:	74 24                	je     f0102687 <i386_vm_init+0x16bd>
f0102663:	c7 44 24 0c bc 46 10 	movl   $0xf01046bc,0xc(%esp)
f010266a:	f0 
f010266b:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0102672:	f0 
f0102673:	c7 44 24 04 87 01 00 	movl   $0x187,0x4(%esp)
f010267a:	00 
f010267b:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0102682:	e8 6f da ff ff       	call   f01000f6 <_panic>
f0102687:	81 45 c0 00 10 00 00 	addl   $0x1000,-0x40(%ebp)
	// check phys mem
	for (i = 0; i < npage * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010268e:	39 75 c0             	cmp    %esi,-0x40(%ebp)
f0102691:	0f 85 39 01 00 00    	jne    f01027d0 <i386_vm_init+0x1806>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102697:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f010269c:	89 f8                	mov    %edi,%eax
f010269e:	e8 0f e3 ff ff       	call   f01009b2 <check_va2pa>
f01026a3:	83 f8 ff             	cmp    $0xffffffff,%eax
f01026a6:	74 24                	je     f01026cc <i386_vm_init+0x1702>
f01026a8:	c7 44 24 0c 04 47 10 	movl   $0xf0104704,0xc(%esp)
f01026af:	f0 
f01026b0:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f01026b7:	f0 
f01026b8:	c7 44 24 04 88 01 00 	movl   $0x188,0x4(%esp)
f01026bf:	00 
f01026c0:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f01026c7:	e8 2a da ff ff       	call   f01000f6 <_panic>
f01026cc:	b8 00 00 00 00       	mov    $0x0,%eax

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01026d1:	8d 90 44 fc ff ff    	lea    -0x3bc(%eax),%edx
f01026d7:	83 fa 03             	cmp    $0x3,%edx
f01026da:	77 2a                	ja     f0102706 <i386_vm_init+0x173c>
		case PDX(VPT):
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i]);
f01026dc:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f01026e0:	75 7f                	jne    f0102761 <i386_vm_init+0x1797>
f01026e2:	c7 44 24 0c 8f 49 10 	movl   $0xf010498f,0xc(%esp)
f01026e9:	f0 
f01026ea:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f01026f1:	f0 
f01026f2:	c7 44 24 04 91 01 00 	movl   $0x191,0x4(%esp)
f01026f9:	00 
f01026fa:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0102701:	e8 f0 d9 ff ff       	call   f01000f6 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE))
f0102706:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010270b:	76 2a                	jbe    f0102737 <i386_vm_init+0x176d>
				assert(pgdir[i]);
f010270d:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102711:	75 4e                	jne    f0102761 <i386_vm_init+0x1797>
f0102713:	c7 44 24 0c 8f 49 10 	movl   $0xf010498f,0xc(%esp)
f010271a:	f0 
f010271b:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f0102722:	f0 
f0102723:	c7 44 24 04 95 01 00 	movl   $0x195,0x4(%esp)
f010272a:	00 
f010272b:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f0102732:	e8 bf d9 ff ff       	call   f01000f6 <_panic>
			else
				assert(pgdir[i] == 0);
f0102737:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f010273b:	74 24                	je     f0102761 <i386_vm_init+0x1797>
f010273d:	c7 44 24 0c 98 49 10 	movl   $0xf0104998,0xc(%esp)
f0102744:	f0 
f0102745:	c7 44 24 08 96 47 10 	movl   $0xf0104796,0x8(%esp)
f010274c:	f0 
f010274d:	c7 44 24 04 97 01 00 	movl   $0x197,0x4(%esp)
f0102754:	00 
f0102755:	c7 04 24 53 47 10 f0 	movl   $0xf0104753,(%esp)
f010275c:	e8 95 d9 ff ff       	call   f01000f6 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
f0102761:	83 c0 01             	add    $0x1,%eax
f0102764:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102769:	0f 85 62 ff ff ff    	jne    f01026d1 <i386_vm_init+0x1707>
			else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_boot_pgdir() succeeded!\n");
f010276f:	c7 04 24 34 47 10 f0 	movl   $0xf0104734,(%esp)
f0102776:	e8 d7 04 00 00       	call   f0102c52 <cprintf>
	// mapping, even though we are turning on paging and reconfiguring
	// segmentation.

	// Map VA 0:4MB same as VA KERNBASE, i.e. to PA 0:4MB.
	// (Limits our kernel to <4MB)
	pgdir[0] = pgdir[PDX(KERNBASE)];
f010277b:	8b 5d bc             	mov    -0x44(%ebp),%ebx
f010277e:	8b 83 00 0f 00 00    	mov    0xf00(%ebx),%eax
f0102784:	89 03                	mov    %eax,(%ebx)
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102786:	a1 04 6a 11 f0       	mov    0xf0116a04,%eax
f010278b:	0f 22 d8             	mov    %eax,%cr3

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f010278e:	0f 20 c0             	mov    %cr0,%eax
	lcr3(boot_cr3);

	// Turn on paging.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_TS|CR0_EM|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102791:	83 e0 f3             	and    $0xfffffff3,%eax
f0102794:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102799:	0f 22 c0             	mov    %eax,%cr0

	// Current mapping: KERNBASE+x => x => x.
	// (x < 4MB so uses paging pgdir[0])

	// Reload all segment registers.
	asm volatile("lgdt gdt_pd");
f010279c:	0f 01 15 20 63 11 f0 	lgdtl  0xf0116320
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01027a3:	b8 23 00 00 00       	mov    $0x23,%eax
f01027a8:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01027aa:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01027ac:	b0 10                	mov    $0x10,%al
f01027ae:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01027b0:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01027b2:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));  // reload cs
f01027b4:	ea bb 27 10 f0 08 00 	ljmp   $0x8,$0xf01027bb
	asm volatile("lldt %%ax" :: "a" (0));
f01027bb:	b0 00                	mov    $0x0,%al
f01027bd:	0f 00 d0             	lldt   %ax

	// Final mapping: KERNBASE+x => KERNBASE+x => x.

	// This mapping was only used after paging was turned on but
	// before the segment registers were reloaded.
	pgdir[0] = 0;
f01027c0:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01027c6:	a1 04 6a 11 f0       	mov    0xf0116a04,%eax
f01027cb:	0f 22 d8             	mov    %eax,%cr3
f01027ce:	eb 44                	jmp    f0102814 <i386_vm_init+0x184a>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read (or write). 
void
i386_vm_init(void)
f01027d0:	8b 55 c0             	mov    -0x40(%ebp),%edx
f01027d3:	01 da                	add    %ebx,%edx
	for (i = 0; i < npage * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01027d5:	89 f8                	mov    %edi,%eax
f01027d7:	e8 d6 e1 ff ff       	call   f01009b2 <check_va2pa>
f01027dc:	e9 7d fe ff ff       	jmp    f010265e <i386_vm_init+0x1694>
f01027e1:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f01027e6:	89 f8                	mov    %edi,%eax
f01027e8:	e8 c5 e1 ff ff       	call   f01009b2 <check_va2pa>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read (or write). 
void
i386_vm_init(void)
f01027ed:	be 00 60 11 00       	mov    $0x116000,%esi
f01027f2:	ba 00 80 bf df       	mov    $0xdfbf8000,%edx
f01027f7:	29 da                	sub    %ebx,%edx
f01027f9:	89 d3                	mov    %edx,%ebx
f01027fb:	e9 5e fe ff ff       	jmp    f010265e <i386_vm_init+0x1694>
f0102800:	81 ea 00 f0 ff 10    	sub    $0x10fff000,%edx
	pgdir = boot_pgdir;

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102806:	89 f8                	mov    %edi,%eax
f0102808:	e8 a5 e1 ff ff       	call   f01009b2 <check_va2pa>

	pgdir = boot_pgdir;

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010280d:	89 f2                	mov    %esi,%edx
f010280f:	e9 b3 fd ff ff       	jmp    f01025c7 <i386_vm_init+0x15fd>
	// before the segment registers were reloaded.
	pgdir[0] = 0;

	// Flush the TLB for good measure, to kill the pgdir[0] mapping.
	lcr3(boot_cr3);
}
f0102814:	83 c4 5c             	add    $0x5c,%esp
f0102817:	5b                   	pop    %ebx
f0102818:	5e                   	pop    %esi
f0102819:	5f                   	pop    %edi
f010281a:	5d                   	pop    %ebp
f010281b:	c3                   	ret    

f010281c <envid2env>:
//   On success, sets *penv to the environment.
//   On error, sets *penv to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010281c:	55                   	push   %ebp
f010281d:	89 e5                	mov    %esp,%ebp
f010281f:	8b 45 08             	mov    0x8(%ebp),%eax
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102822:	85 c0                	test   %eax,%eax
f0102824:	75 11                	jne    f0102837 <envid2env+0x1b>
		*env_store = curenv;
f0102826:	a1 dc 65 11 f0       	mov    0xf01165dc,%eax
f010282b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010282e:	89 02                	mov    %eax,(%edx)
		return 0;
f0102830:	b8 00 00 00 00       	mov    $0x0,%eax
f0102835:	eb 5d                	jmp    f0102894 <envid2env+0x78>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102837:	89 c2                	mov    %eax,%edx
f0102839:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010283f:	6b d2 64             	imul   $0x64,%edx,%edx
f0102842:	03 15 e0 65 11 f0    	add    0xf01165e0,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102848:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f010284c:	74 05                	je     f0102853 <envid2env+0x37>
f010284e:	39 42 4c             	cmp    %eax,0x4c(%edx)
f0102851:	74 10                	je     f0102863 <envid2env+0x47>
		*env_store = 0;
f0102853:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102856:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		return -E_BAD_ENV;
f010285c:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102861:	eb 31                	jmp    f0102894 <envid2env+0x78>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102863:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0102867:	74 21                	je     f010288a <envid2env+0x6e>
f0102869:	a1 dc 65 11 f0       	mov    0xf01165dc,%eax
f010286e:	39 c2                	cmp    %eax,%edx
f0102870:	74 18                	je     f010288a <envid2env+0x6e>
f0102872:	8b 48 4c             	mov    0x4c(%eax),%ecx
f0102875:	39 4a 50             	cmp    %ecx,0x50(%edx)
f0102878:	74 10                	je     f010288a <envid2env+0x6e>
		*env_store = 0;
f010287a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010287d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102883:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102888:	eb 0a                	jmp    f0102894 <envid2env+0x78>
	}

	*env_store = e;
f010288a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010288d:	89 11                	mov    %edx,(%ecx)
	return 0;
f010288f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102894:	5d                   	pop    %ebp
f0102895:	c3                   	ret    

f0102896 <env_init>:
// Insert in reverse order, so that the first call to env_alloc()
// returns envs[0].
//
void
env_init(void)
{
f0102896:	55                   	push   %ebp
f0102897:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f0102899:	5d                   	pop    %ebp
f010289a:	c3                   	ret    

f010289b <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f010289b:	55                   	push   %ebp
f010289c:	89 e5                	mov    %esp,%ebp
f010289e:	53                   	push   %ebx
f010289f:	83 ec 24             	sub    $0x24,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = LIST_FIRST(&env_free_list)))
f01028a2:	8b 1d e4 65 11 f0    	mov    0xf01165e4,%ebx
f01028a8:	85 db                	test   %ebx,%ebx
f01028aa:	0f 84 f8 00 00 00    	je     f01029a8 <env_alloc+0x10d>
//
static int
env_setup_vm(struct Env *e)
{
	int i, r;
	struct Page *p = NULL;
f01028b0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// Allocate a page for the page directory
	if ((r = page_alloc(&p)) < 0)
f01028b7:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01028ba:	89 04 24             	mov    %eax,(%esp)
f01028bd:	e8 38 e3 ff ff       	call   f0100bfa <page_alloc>
f01028c2:	85 c0                	test   %eax,%eax
f01028c4:	0f 88 e3 00 00 00    	js     f01029ad <env_alloc+0x112>

	// LAB 3: Your code here.

	// VPT and UVPT map the env's own page table, with
	// different permissions.
	e->env_pgdir[PDX(VPT)]  = e->env_cr3 | PTE_P | PTE_W;
f01028ca:	8b 43 5c             	mov    0x5c(%ebx),%eax
f01028cd:	8b 53 60             	mov    0x60(%ebx),%edx
f01028d0:	83 ca 03             	or     $0x3,%edx
f01028d3:	89 90 fc 0e 00 00    	mov    %edx,0xefc(%eax)
	e->env_pgdir[PDX(UVPT)] = e->env_cr3 | PTE_P | PTE_U;
f01028d9:	8b 43 5c             	mov    0x5c(%ebx),%eax
f01028dc:	8b 53 60             	mov    0x60(%ebx),%edx
f01028df:	83 ca 05             	or     $0x5,%edx
f01028e2:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01028e8:	8b 43 4c             	mov    0x4c(%ebx),%eax
f01028eb:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01028f0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f01028f5:	7f 05                	jg     f01028fc <env_alloc+0x61>
		generation = 1 << ENVGENSHIFT;
f01028f7:	b8 00 10 00 00       	mov    $0x1000,%eax
	e->env_id = generation | (e - envs);
f01028fc:	89 da                	mov    %ebx,%edx
f01028fe:	2b 15 e0 65 11 f0    	sub    0xf01165e0,%edx
f0102904:	c1 fa 02             	sar    $0x2,%edx
f0102907:	69 d2 29 5c 8f c2    	imul   $0xc28f5c29,%edx,%edx
f010290d:	09 d0                	or     %edx,%eax
f010290f:	89 43 4c             	mov    %eax,0x4c(%ebx)
	
	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102912:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102915:	89 43 50             	mov    %eax,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102918:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
	e->env_runs = 0;
f010291f:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102926:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f010292d:	00 
f010292e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102935:	00 
f0102936:	89 1c 24             	mov    %ebx,(%esp)
f0102939:	e8 76 0e 00 00       	call   f01037b4 <memset>
	// Set up appropriate initial values for the segment registers.
	// GD_UD is the user data segment selector in the GDT, and 
	// GD_UT is the user text segment selector (see inc/memlayout.h).
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.
	e->env_tf.tf_ds = GD_UD | 3;
f010293e:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102944:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f010294a:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102950:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102957:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	LIST_REMOVE(e, env_link);
f010295d:	8b 43 44             	mov    0x44(%ebx),%eax
f0102960:	85 c0                	test   %eax,%eax
f0102962:	74 06                	je     f010296a <env_alloc+0xcf>
f0102964:	8b 53 48             	mov    0x48(%ebx),%edx
f0102967:	89 50 48             	mov    %edx,0x48(%eax)
f010296a:	8b 43 48             	mov    0x48(%ebx),%eax
f010296d:	8b 53 44             	mov    0x44(%ebx),%edx
f0102970:	89 10                	mov    %edx,(%eax)
	*newenv_store = e;
f0102972:	8b 45 08             	mov    0x8(%ebp),%eax
f0102975:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102977:	8b 53 4c             	mov    0x4c(%ebx),%edx
f010297a:	a1 dc 65 11 f0       	mov    0xf01165dc,%eax
f010297f:	85 c0                	test   %eax,%eax
f0102981:	74 05                	je     f0102988 <env_alloc+0xed>
f0102983:	8b 40 4c             	mov    0x4c(%eax),%eax
f0102986:	eb 05                	jmp    f010298d <env_alloc+0xf2>
f0102988:	b8 00 00 00 00       	mov    $0x0,%eax
f010298d:	89 54 24 08          	mov    %edx,0x8(%esp)
f0102991:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102995:	c7 04 24 a6 49 10 f0 	movl   $0xf01049a6,(%esp)
f010299c:	e8 b1 02 00 00       	call   f0102c52 <cprintf>
	return 0;
f01029a1:	b8 00 00 00 00       	mov    $0x0,%eax
f01029a6:	eb 05                	jmp    f01029ad <env_alloc+0x112>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = LIST_FIRST(&env_free_list)))
		return -E_NO_FREE_ENV;
f01029a8:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
	LIST_REMOVE(e, env_link);
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f01029ad:	83 c4 24             	add    $0x24,%esp
f01029b0:	5b                   	pop    %ebx
f01029b1:	5d                   	pop    %ebp
f01029b2:	c3                   	ret    

f01029b3 <env_create>:
// By convention, envs[0] is the first environment allocated, so
// whoever calls env_create simply looks for the newly created
// environment there. 
void
env_create(uint8_t *binary, size_t size)
{
f01029b3:	55                   	push   %ebp
f01029b4:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f01029b6:	5d                   	pop    %ebp
f01029b7:	c3                   	ret    

f01029b8 <env_free>:
//
// Frees env e and all memory it uses.
// 
void
env_free(struct Env *e)
{
f01029b8:	55                   	push   %ebp
f01029b9:	89 e5                	mov    %esp,%ebp
f01029bb:	57                   	push   %edi
f01029bc:	56                   	push   %esi
f01029bd:	53                   	push   %ebx
f01029be:	83 ec 2c             	sub    $0x2c,%esp
f01029c1:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;
	
	// If freeing the current environment, switch to boot_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01029c4:	a1 dc 65 11 f0       	mov    0xf01165dc,%eax
f01029c9:	39 c7                	cmp    %eax,%edi
f01029cb:	75 09                	jne    f01029d6 <env_free+0x1e>
f01029cd:	8b 15 04 6a 11 f0    	mov    0xf0116a04,%edx
f01029d3:	0f 22 da             	mov    %edx,%cr3
		lcr3(boot_cr3);

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01029d6:	8b 57 4c             	mov    0x4c(%edi),%edx
f01029d9:	85 c0                	test   %eax,%eax
f01029db:	74 05                	je     f01029e2 <env_free+0x2a>
f01029dd:	8b 40 4c             	mov    0x4c(%eax),%eax
f01029e0:	eb 05                	jmp    f01029e7 <env_free+0x2f>
f01029e2:	b8 00 00 00 00       	mov    $0x0,%eax
f01029e7:	89 54 24 08          	mov    %edx,0x8(%esp)
f01029eb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01029ef:	c7 04 24 bb 49 10 f0 	movl   $0xf01049bb,(%esp)
f01029f6:	e8 57 02 00 00       	call   f0102c52 <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01029fb:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)

//
// Frees env e and all memory it uses.
// 
void
env_free(struct Env *e)
f0102a02:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102a05:	c1 e0 02             	shl    $0x2,%eax
f0102a08:	89 45 d8             	mov    %eax,-0x28(%ebp)
	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102a0b:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102a0e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102a11:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0102a14:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102a1a:	0f 84 ba 00 00 00    	je     f0102ada <env_free+0x122>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102a20:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
		pt = (pte_t*) KADDR(pa);
f0102a26:	89 f0                	mov    %esi,%eax
f0102a28:	c1 e8 0c             	shr    $0xc,%eax
f0102a2b:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0102a2e:	3b 05 00 6a 11 f0    	cmp    0xf0116a00,%eax
f0102a34:	72 20                	jb     f0102a56 <env_free+0x9e>
f0102a36:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102a3a:	c7 44 24 08 a4 41 10 	movl   $0xf01041a4,0x8(%esp)
f0102a41:	f0 
f0102a42:	c7 44 24 04 32 01 00 	movl   $0x132,0x4(%esp)
f0102a49:	00 
f0102a4a:	c7 04 24 d1 49 10 f0 	movl   $0xf01049d1,(%esp)
f0102a51:	e8 a0 d6 ff ff       	call   f01000f6 <_panic>

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102a56:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0102a59:	c1 e2 16             	shl    $0x16,%edx
f0102a5c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102a5f:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102a64:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102a6b:	01 
f0102a6c:	74 17                	je     f0102a85 <env_free+0xcd>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102a6e:	89 d8                	mov    %ebx,%eax
f0102a70:	c1 e0 0c             	shl    $0xc,%eax
f0102a73:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102a76:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102a7a:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102a7d:	89 04 24             	mov    %eax,(%esp)
f0102a80:	e8 50 e4 ff ff       	call   f0100ed5 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102a85:	83 c3 01             	add    $0x1,%ebx
f0102a88:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102a8e:	75 d4                	jne    f0102a64 <env_free+0xac>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102a90:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102a93:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102a96:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PPN(pa) >= npage)
f0102a9d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102aa0:	3b 05 00 6a 11 f0    	cmp    0xf0116a00,%eax
f0102aa6:	72 1c                	jb     f0102ac4 <env_free+0x10c>
		panic("pa2page called with invalid pa");
f0102aa8:	c7 44 24 08 10 42 10 	movl   $0xf0104210,0x8(%esp)
f0102aaf:	f0 
f0102ab0:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0102ab7:	00 
f0102ab8:	c7 04 24 7b 47 10 f0 	movl   $0xf010477b,(%esp)
f0102abf:	e8 32 d6 ff ff       	call   f01000f6 <_panic>
	return &pages[PPN(pa)];
f0102ac4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102ac7:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102aca:	a1 0c 6a 11 f0       	mov    0xf0116a0c,%eax
f0102acf:	8d 04 90             	lea    (%eax,%edx,4),%eax
		page_decref(pa2page(pa));
f0102ad2:	89 04 24             	mov    %eax,(%esp)
f0102ad5:	e8 a2 e1 ff ff       	call   f0100c7c <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102ada:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102ade:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0102ae5:	0f 85 17 ff ff ff    	jne    f0102a02 <env_free+0x4a>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = e->env_cr3;
f0102aeb:	8b 47 60             	mov    0x60(%edi),%eax
	e->env_pgdir = 0;
f0102aee:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	e->env_cr3 = 0;
f0102af5:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PPN(pa) >= npage)
f0102afc:	c1 e8 0c             	shr    $0xc,%eax
f0102aff:	3b 05 00 6a 11 f0    	cmp    0xf0116a00,%eax
f0102b05:	72 1c                	jb     f0102b23 <env_free+0x16b>
		panic("pa2page called with invalid pa");
f0102b07:	c7 44 24 08 10 42 10 	movl   $0xf0104210,0x8(%esp)
f0102b0e:	f0 
f0102b0f:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0102b16:	00 
f0102b17:	c7 04 24 7b 47 10 f0 	movl   $0xf010477b,(%esp)
f0102b1e:	e8 d3 d5 ff ff       	call   f01000f6 <_panic>
	return &pages[PPN(pa)];
f0102b23:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102b26:	a1 0c 6a 11 f0       	mov    0xf0116a0c,%eax
f0102b2b:	8d 04 90             	lea    (%eax,%edx,4),%eax
	page_decref(pa2page(pa));
f0102b2e:	89 04 24             	mov    %eax,(%esp)
f0102b31:	e8 46 e1 ff ff       	call   f0100c7c <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102b36:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	LIST_INSERT_HEAD(&env_free_list, e, env_link);
f0102b3d:	a1 e4 65 11 f0       	mov    0xf01165e4,%eax
f0102b42:	89 47 44             	mov    %eax,0x44(%edi)
f0102b45:	85 c0                	test   %eax,%eax
f0102b47:	74 06                	je     f0102b4f <env_free+0x197>
f0102b49:	8d 57 44             	lea    0x44(%edi),%edx
f0102b4c:	89 50 48             	mov    %edx,0x48(%eax)
f0102b4f:	89 3d e4 65 11 f0    	mov    %edi,0xf01165e4
f0102b55:	c7 47 48 e4 65 11 f0 	movl   $0xf01165e4,0x48(%edi)
}
f0102b5c:	83 c4 2c             	add    $0x2c,%esp
f0102b5f:	5b                   	pop    %ebx
f0102b60:	5e                   	pop    %esi
f0102b61:	5f                   	pop    %edi
f0102b62:	5d                   	pop    %ebp
f0102b63:	c3                   	ret    

f0102b64 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e) 
{
f0102b64:	55                   	push   %ebp
f0102b65:	89 e5                	mov    %esp,%ebp
f0102b67:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f0102b6a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b6d:	89 04 24             	mov    %eax,(%esp)
f0102b70:	e8 43 fe ff ff       	call   f01029b8 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102b75:	c7 04 24 04 4a 10 f0 	movl   $0xf0104a04,(%esp)
f0102b7c:	e8 d1 00 00 00       	call   f0102c52 <cprintf>
	while (1)
		monitor(NULL);
f0102b81:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b88:	e8 7c dc ff ff       	call   f0100809 <monitor>
f0102b8d:	eb f2                	jmp    f0102b81 <env_destroy+0x1d>

f0102b8f <env_pop_tf>:
// This exits the kernel and starts executing some environment's code.
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102b8f:	55                   	push   %ebp
f0102b90:	89 e5                	mov    %esp,%ebp
f0102b92:	83 ec 18             	sub    $0x18,%esp
	__asm __volatile("movl %0,%%esp\n"
f0102b95:	8b 65 08             	mov    0x8(%ebp),%esp
f0102b98:	61                   	popa   
f0102b99:	07                   	pop    %es
f0102b9a:	1f                   	pop    %ds
f0102b9b:	83 c4 08             	add    $0x8,%esp
f0102b9e:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0102b9f:	c7 44 24 08 dc 49 10 	movl   $0xf01049dc,0x8(%esp)
f0102ba6:	f0 
f0102ba7:	c7 44 24 04 69 01 00 	movl   $0x169,0x4(%esp)
f0102bae:	00 
f0102baf:	c7 04 24 d1 49 10 f0 	movl   $0xf01049d1,(%esp)
f0102bb6:	e8 3b d5 ff ff       	call   f01000f6 <_panic>

f0102bbb <env_run>:
// Note: if this is the first call to env_run, curenv is NULL.
//  (This function does not return.)
//
void
env_run(struct Env *e)
{
f0102bbb:	55                   	push   %ebp
f0102bbc:	89 e5                	mov    %esp,%ebp
f0102bbe:	83 ec 18             	sub    $0x18,%esp
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.
	
	// LAB 3: Your code here.

        panic("env_run not yet implemented");
f0102bc1:	c7 44 24 08 e8 49 10 	movl   $0xf01049e8,0x8(%esp)
f0102bc8:	f0 
f0102bc9:	c7 44 24 04 83 01 00 	movl   $0x183,0x4(%esp)
f0102bd0:	00 
f0102bd1:	c7 04 24 d1 49 10 f0 	movl   $0xf01049d1,(%esp)
f0102bd8:	e8 19 d5 ff ff       	call   f01000f6 <_panic>
f0102bdd:	00 00                	add    %al,(%eax)
	...

f0102be0 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102be0:	55                   	push   %ebp
f0102be1:	89 e5                	mov    %esp,%ebp
void
mc146818_write(unsigned reg, unsigned datum)
{
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102be3:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102be7:	ba 70 00 00 00       	mov    $0x70,%edx
f0102bec:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102bed:	b2 71                	mov    $0x71,%dl
f0102bef:	ec                   	in     (%dx),%al

unsigned
mc146818_read(unsigned reg)
{
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102bf0:	0f b6 c0             	movzbl %al,%eax
}
f0102bf3:	5d                   	pop    %ebp
f0102bf4:	c3                   	ret    

f0102bf5 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102bf5:	55                   	push   %ebp
f0102bf6:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102bf8:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102bfc:	ba 70 00 00 00       	mov    $0x70,%edx
f0102c01:	ee                   	out    %al,(%dx)
f0102c02:	0f b6 45 0c          	movzbl 0xc(%ebp),%eax
f0102c06:	b2 71                	mov    $0x71,%dl
f0102c08:	ee                   	out    %al,(%dx)
f0102c09:	5d                   	pop    %ebp
f0102c0a:	c3                   	ret    
	...

f0102c0c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102c0c:	55                   	push   %ebp
f0102c0d:	89 e5                	mov    %esp,%ebp
f0102c0f:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102c12:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c15:	89 04 24             	mov    %eax,(%esp)
f0102c18:	e8 57 da ff ff       	call   f0100674 <cputchar>
	*cnt++;
}
f0102c1d:	c9                   	leave  
f0102c1e:	c3                   	ret    

f0102c1f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102c1f:	55                   	push   %ebp
f0102c20:	89 e5                	mov    %esp,%ebp
f0102c22:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102c25:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102c2c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c2f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c33:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c36:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102c3a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102c3d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102c41:	c7 04 24 0c 2c 10 f0 	movl   $0xf0102c0c,(%esp)
f0102c48:	e8 8f 04 00 00       	call   f01030dc <vprintfmt>
	return cnt;
}
f0102c4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102c50:	c9                   	leave  
f0102c51:	c3                   	ret    

f0102c52 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102c52:	55                   	push   %ebp
f0102c53:	89 e5                	mov    %esp,%ebp
f0102c55:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102c58:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102c5b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102c5f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c62:	89 04 24             	mov    %eax,(%esp)
f0102c65:	e8 b5 ff ff ff       	call   f0102c1f <vcprintf>
	va_end(ap);

	return cnt;
}
f0102c6a:	c9                   	leave  
f0102c6b:	c3                   	ret    
f0102c6c:	00 00                	add    %al,(%eax)
	...

f0102c70 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102c70:	55                   	push   %ebp
f0102c71:	89 e5                	mov    %esp,%ebp
f0102c73:	57                   	push   %edi
f0102c74:	56                   	push   %esi
f0102c75:	53                   	push   %ebx
f0102c76:	83 ec 10             	sub    $0x10,%esp
f0102c79:	89 c6                	mov    %eax,%esi
f0102c7b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102c7e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102c81:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102c84:	8b 1a                	mov    (%edx),%ebx
f0102c86:	8b 09                	mov    (%ecx),%ecx
f0102c88:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102c8b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0102c92:	eb 77                	jmp    f0102d0b <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0102c94:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102c97:	01 d8                	add    %ebx,%eax
f0102c99:	b9 02 00 00 00       	mov    $0x2,%ecx
f0102c9e:	99                   	cltd   
f0102c9f:	f7 f9                	idiv   %ecx
f0102ca1:	89 c1                	mov    %eax,%ecx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102ca3:	eb 01                	jmp    f0102ca6 <stab_binsearch+0x36>
			m--;
f0102ca5:	49                   	dec    %ecx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102ca6:	39 d9                	cmp    %ebx,%ecx
f0102ca8:	7c 1d                	jl     f0102cc7 <stab_binsearch+0x57>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102caa:	6b d1 0c             	imul   $0xc,%ecx,%edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102cad:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102cb2:	39 fa                	cmp    %edi,%edx
f0102cb4:	75 ef                	jne    f0102ca5 <stab_binsearch+0x35>
f0102cb6:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102cb9:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102cbc:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0102cc0:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102cc3:	73 18                	jae    f0102cdd <stab_binsearch+0x6d>
f0102cc5:	eb 05                	jmp    f0102ccc <stab_binsearch+0x5c>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102cc7:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0102cca:	eb 3f                	jmp    f0102d0b <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102ccc:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102ccf:	89 0a                	mov    %ecx,(%edx)
			l = true_m + 1;
f0102cd1:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102cd4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102cdb:	eb 2e                	jmp    f0102d0b <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102cdd:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102ce0:	73 15                	jae    f0102cf7 <stab_binsearch+0x87>
			*region_right = m - 1;
f0102ce2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102ce5:	49                   	dec    %ecx
f0102ce6:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102ce9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102cec:	89 08                	mov    %ecx,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102cee:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102cf5:	eb 14                	jmp    f0102d0b <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102cf7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102cfa:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102cfd:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f0102cff:	ff 45 0c             	incl   0xc(%ebp)
f0102d02:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102d04:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0102d0b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102d0e:	7e 84                	jle    f0102c94 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102d10:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102d14:	75 0d                	jne    f0102d23 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0102d16:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102d19:	8b 02                	mov    (%edx),%eax
f0102d1b:	48                   	dec    %eax
f0102d1c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102d1f:	89 01                	mov    %eax,(%ecx)
f0102d21:	eb 22                	jmp    f0102d45 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102d23:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102d26:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102d28:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102d2b:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102d2d:	eb 01                	jmp    f0102d30 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102d2f:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102d30:	39 c1                	cmp    %eax,%ecx
f0102d32:	7d 0c                	jge    f0102d40 <stab_binsearch+0xd0>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102d34:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0102d37:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102d3c:	39 fa                	cmp    %edi,%edx
f0102d3e:	75 ef                	jne    f0102d2f <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102d40:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102d43:	89 02                	mov    %eax,(%edx)
	}
}
f0102d45:	83 c4 10             	add    $0x10,%esp
f0102d48:	5b                   	pop    %ebx
f0102d49:	5e                   	pop    %esi
f0102d4a:	5f                   	pop    %edi
f0102d4b:	5d                   	pop    %ebp
f0102d4c:	c3                   	ret    

f0102d4d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102d4d:	55                   	push   %ebp
f0102d4e:	89 e5                	mov    %esp,%ebp
f0102d50:	83 ec 38             	sub    $0x38,%esp
f0102d53:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0102d56:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0102d59:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0102d5c:	8b 75 08             	mov    0x8(%ebp),%esi
f0102d5f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102d62:	c7 03 3c 4a 10 f0    	movl   $0xf0104a3c,(%ebx)
	info->eip_line = 0;
f0102d68:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102d6f:	c7 43 08 3c 4a 10 f0 	movl   $0xf0104a3c,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102d76:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102d7d:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102d80:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102d87:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102d8d:	76 12                	jbe    f0102da1 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102d8f:	b8 19 d5 10 f0       	mov    $0xf010d519,%eax
f0102d94:	3d 4d af 10 f0       	cmp    $0xf010af4d,%eax
f0102d99:	0f 86 5b 01 00 00    	jbe    f0102efa <debuginfo_eip+0x1ad>
f0102d9f:	eb 1c                	jmp    f0102dbd <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102da1:	c7 44 24 08 46 4a 10 	movl   $0xf0104a46,0x8(%esp)
f0102da8:	f0 
f0102da9:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
f0102db0:	00 
f0102db1:	c7 04 24 53 4a 10 f0 	movl   $0xf0104a53,(%esp)
f0102db8:	e8 39 d3 ff ff       	call   f01000f6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102dbd:	80 3d 18 d5 10 f0 00 	cmpb   $0x0,0xf010d518
f0102dc4:	0f 85 37 01 00 00    	jne    f0102f01 <debuginfo_eip+0x1b4>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102dca:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102dd1:	b8 4c af 10 f0       	mov    $0xf010af4c,%eax
f0102dd6:	2d 70 4c 10 f0       	sub    $0xf0104c70,%eax
f0102ddb:	c1 f8 02             	sar    $0x2,%eax
f0102dde:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102de4:	83 e8 01             	sub    $0x1,%eax
f0102de7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102dea:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102dee:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102df5:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102df8:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102dfb:	b8 70 4c 10 f0       	mov    $0xf0104c70,%eax
f0102e00:	e8 6b fe ff ff       	call   f0102c70 <stab_binsearch>
	if (lfile == 0)
f0102e05:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102e08:	85 c0                	test   %eax,%eax
f0102e0a:	0f 84 f8 00 00 00    	je     f0102f08 <debuginfo_eip+0x1bb>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102e10:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102e13:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102e16:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102e19:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102e1d:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102e24:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102e27:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102e2a:	b8 70 4c 10 f0       	mov    $0xf0104c70,%eax
f0102e2f:	e8 3c fe ff ff       	call   f0102c70 <stab_binsearch>

	if (lfun <= rfun) {
f0102e34:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0102e37:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0102e3a:	7f 2e                	jg     f0102e6a <debuginfo_eip+0x11d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102e3c:	6b c7 0c             	imul   $0xc,%edi,%eax
f0102e3f:	8d 90 70 4c 10 f0    	lea    -0xfefb390(%eax),%edx
f0102e45:	8b 80 70 4c 10 f0    	mov    -0xfefb390(%eax),%eax
f0102e4b:	b9 19 d5 10 f0       	mov    $0xf010d519,%ecx
f0102e50:	81 e9 4d af 10 f0    	sub    $0xf010af4d,%ecx
f0102e56:	39 c8                	cmp    %ecx,%eax
f0102e58:	73 08                	jae    f0102e62 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102e5a:	05 4d af 10 f0       	add    $0xf010af4d,%eax
f0102e5f:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102e62:	8b 42 08             	mov    0x8(%edx),%eax
f0102e65:	89 43 10             	mov    %eax,0x10(%ebx)
f0102e68:	eb 06                	jmp    f0102e70 <debuginfo_eip+0x123>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102e6a:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102e6d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102e70:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0102e77:	00 
f0102e78:	8b 43 08             	mov    0x8(%ebx),%eax
f0102e7b:	89 04 24             	mov    %eax,(%esp)
f0102e7e:	e8 0a 09 00 00       	call   f010378d <strfind>
f0102e83:	2b 43 08             	sub    0x8(%ebx),%eax
f0102e86:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102e89:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102e8c:	39 cf                	cmp    %ecx,%edi
f0102e8e:	7c 7f                	jl     f0102f0f <debuginfo_eip+0x1c2>
	       && stabs[lline].n_type != N_SOL
f0102e90:	6b f7 0c             	imul   $0xc,%edi,%esi
f0102e93:	81 c6 70 4c 10 f0    	add    $0xf0104c70,%esi
f0102e99:	0f b6 56 04          	movzbl 0x4(%esi),%edx
f0102e9d:	80 fa 84             	cmp    $0x84,%dl
f0102ea0:	74 31                	je     f0102ed3 <debuginfo_eip+0x186>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0102ea2:	8d 47 ff             	lea    -0x1(%edi),%eax
f0102ea5:	6b c0 0c             	imul   $0xc,%eax,%eax
f0102ea8:	05 70 4c 10 f0       	add    $0xf0104c70,%eax
f0102ead:	eb 15                	jmp    f0102ec4 <debuginfo_eip+0x177>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0102eaf:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102eb2:	39 cf                	cmp    %ecx,%edi
f0102eb4:	7c 60                	jl     f0102f16 <debuginfo_eip+0x1c9>
	       && stabs[lline].n_type != N_SOL
f0102eb6:	89 c6                	mov    %eax,%esi
f0102eb8:	83 e8 0c             	sub    $0xc,%eax
f0102ebb:	0f b6 50 10          	movzbl 0x10(%eax),%edx
f0102ebf:	80 fa 84             	cmp    $0x84,%dl
f0102ec2:	74 0f                	je     f0102ed3 <debuginfo_eip+0x186>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102ec4:	80 fa 64             	cmp    $0x64,%dl
f0102ec7:	75 e6                	jne    f0102eaf <debuginfo_eip+0x162>
f0102ec9:	83 7e 08 00          	cmpl   $0x0,0x8(%esi)
f0102ecd:	74 e0                	je     f0102eaf <debuginfo_eip+0x162>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102ecf:	39 f9                	cmp    %edi,%ecx
f0102ed1:	7f 4a                	jg     f0102f1d <debuginfo_eip+0x1d0>
f0102ed3:	6b ff 0c             	imul   $0xc,%edi,%edi
f0102ed6:	8b 97 70 4c 10 f0    	mov    -0xfefb390(%edi),%edx
f0102edc:	b9 19 d5 10 f0       	mov    $0xf010d519,%ecx
f0102ee1:	81 e9 4d af 10 f0    	sub    $0xf010af4d,%ecx
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	// Your code here.

	
	return 0;
f0102ee7:	b8 00 00 00 00       	mov    $0x0,%eax
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102eec:	39 ca                	cmp    %ecx,%edx
f0102eee:	73 32                	jae    f0102f22 <debuginfo_eip+0x1d5>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102ef0:	81 c2 4d af 10 f0    	add    $0xf010af4d,%edx
f0102ef6:	89 13                	mov    %edx,(%ebx)
f0102ef8:	eb 28                	jmp    f0102f22 <debuginfo_eip+0x1d5>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102efa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102eff:	eb 21                	jmp    f0102f22 <debuginfo_eip+0x1d5>
f0102f01:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102f06:	eb 1a                	jmp    f0102f22 <debuginfo_eip+0x1d5>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102f08:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102f0d:	eb 13                	jmp    f0102f22 <debuginfo_eip+0x1d5>
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	// Your code here.

	
	return 0;
f0102f0f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f14:	eb 0c                	jmp    f0102f22 <debuginfo_eip+0x1d5>
f0102f16:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f1b:	eb 05                	jmp    f0102f22 <debuginfo_eip+0x1d5>
f0102f1d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102f22:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0102f25:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0102f28:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0102f2b:	89 ec                	mov    %ebp,%esp
f0102f2d:	5d                   	pop    %ebp
f0102f2e:	c3                   	ret    
	...

f0102f30 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102f30:	55                   	push   %ebp
f0102f31:	89 e5                	mov    %esp,%ebp
f0102f33:	57                   	push   %edi
f0102f34:	56                   	push   %esi
f0102f35:	53                   	push   %ebx
f0102f36:	83 ec 4c             	sub    $0x4c,%esp
f0102f39:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102f3c:	89 d7                	mov    %edx,%edi
f0102f3e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0102f41:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0102f44:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102f47:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102f4a:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f4f:	39 d8                	cmp    %ebx,%eax
f0102f51:	72 17                	jb     f0102f6a <printnum+0x3a>
f0102f53:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0102f56:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f0102f59:	76 0f                	jbe    f0102f6a <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102f5b:	8b 75 14             	mov    0x14(%ebp),%esi
f0102f5e:	83 ee 01             	sub    $0x1,%esi
f0102f61:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f64:	85 f6                	test   %esi,%esi
f0102f66:	7f 63                	jg     f0102fcb <printnum+0x9b>
f0102f68:	eb 75                	jmp    f0102fdf <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102f6a:	8b 5d 18             	mov    0x18(%ebp),%ebx
f0102f6d:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0102f71:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f74:	83 e8 01             	sub    $0x1,%eax
f0102f77:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102f7b:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0102f7e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102f82:	8b 44 24 08          	mov    0x8(%esp),%eax
f0102f86:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0102f8a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102f8d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102f90:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0102f97:	00 
f0102f98:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0102f9b:	89 1c 24             	mov    %ebx,(%esp)
f0102f9e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0102fa1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102fa5:	e8 16 0a 00 00       	call   f01039c0 <__udivdi3>
f0102faa:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102fad:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102fb0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102fb4:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102fb8:	89 04 24             	mov    %eax,(%esp)
f0102fbb:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102fbf:	89 fa                	mov    %edi,%edx
f0102fc1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102fc4:	e8 67 ff ff ff       	call   f0102f30 <printnum>
f0102fc9:	eb 14                	jmp    f0102fdf <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102fcb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102fcf:	8b 45 18             	mov    0x18(%ebp),%eax
f0102fd2:	89 04 24             	mov    %eax,(%esp)
f0102fd5:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102fd7:	83 ee 01             	sub    $0x1,%esi
f0102fda:	75 ef                	jne    f0102fcb <printnum+0x9b>
f0102fdc:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102fdf:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102fe3:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0102fe7:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0102fea:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102fee:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0102ff5:	00 
f0102ff6:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0102ff9:	89 1c 24             	mov    %ebx,(%esp)
f0102ffc:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0102fff:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103003:	e8 18 0b 00 00       	call   f0103b20 <__umoddi3>
f0103008:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010300c:	0f be 80 61 4a 10 f0 	movsbl -0xfefb59f(%eax),%eax
f0103013:	89 04 24             	mov    %eax,(%esp)
f0103016:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103019:	ff d0                	call   *%eax
}
f010301b:	83 c4 4c             	add    $0x4c,%esp
f010301e:	5b                   	pop    %ebx
f010301f:	5e                   	pop    %esi
f0103020:	5f                   	pop    %edi
f0103021:	5d                   	pop    %ebp
f0103022:	c3                   	ret    

f0103023 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103023:	55                   	push   %ebp
f0103024:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103026:	83 fa 01             	cmp    $0x1,%edx
f0103029:	7e 0e                	jle    f0103039 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010302b:	8b 10                	mov    (%eax),%edx
f010302d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103030:	89 08                	mov    %ecx,(%eax)
f0103032:	8b 02                	mov    (%edx),%eax
f0103034:	8b 52 04             	mov    0x4(%edx),%edx
f0103037:	eb 22                	jmp    f010305b <getuint+0x38>
	else if (lflag)
f0103039:	85 d2                	test   %edx,%edx
f010303b:	74 10                	je     f010304d <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f010303d:	8b 10                	mov    (%eax),%edx
f010303f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103042:	89 08                	mov    %ecx,(%eax)
f0103044:	8b 02                	mov    (%edx),%eax
f0103046:	ba 00 00 00 00       	mov    $0x0,%edx
f010304b:	eb 0e                	jmp    f010305b <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f010304d:	8b 10                	mov    (%eax),%edx
f010304f:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103052:	89 08                	mov    %ecx,(%eax)
f0103054:	8b 02                	mov    (%edx),%eax
f0103056:	ba 00 00 00 00       	mov    $0x0,%edx
}
f010305b:	5d                   	pop    %ebp
f010305c:	c3                   	ret    

f010305d <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f010305d:	55                   	push   %ebp
f010305e:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103060:	83 fa 01             	cmp    $0x1,%edx
f0103063:	7e 0e                	jle    f0103073 <getint+0x16>
		return va_arg(*ap, long long);
f0103065:	8b 10                	mov    (%eax),%edx
f0103067:	8d 4a 08             	lea    0x8(%edx),%ecx
f010306a:	89 08                	mov    %ecx,(%eax)
f010306c:	8b 02                	mov    (%edx),%eax
f010306e:	8b 52 04             	mov    0x4(%edx),%edx
f0103071:	eb 22                	jmp    f0103095 <getint+0x38>
	else if (lflag)
f0103073:	85 d2                	test   %edx,%edx
f0103075:	74 10                	je     f0103087 <getint+0x2a>
		return va_arg(*ap, long);
f0103077:	8b 10                	mov    (%eax),%edx
f0103079:	8d 4a 04             	lea    0x4(%edx),%ecx
f010307c:	89 08                	mov    %ecx,(%eax)
f010307e:	8b 02                	mov    (%edx),%eax
f0103080:	89 c2                	mov    %eax,%edx
f0103082:	c1 fa 1f             	sar    $0x1f,%edx
f0103085:	eb 0e                	jmp    f0103095 <getint+0x38>
	else
		return va_arg(*ap, int);
f0103087:	8b 10                	mov    (%eax),%edx
f0103089:	8d 4a 04             	lea    0x4(%edx),%ecx
f010308c:	89 08                	mov    %ecx,(%eax)
f010308e:	8b 02                	mov    (%edx),%eax
f0103090:	89 c2                	mov    %eax,%edx
f0103092:	c1 fa 1f             	sar    $0x1f,%edx
}
f0103095:	5d                   	pop    %ebp
f0103096:	c3                   	ret    

f0103097 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103097:	55                   	push   %ebp
f0103098:	89 e5                	mov    %esp,%ebp
f010309a:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010309d:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01030a1:	8b 10                	mov    (%eax),%edx
f01030a3:	3b 50 04             	cmp    0x4(%eax),%edx
f01030a6:	73 0a                	jae    f01030b2 <sprintputch+0x1b>
		*b->buf++ = ch;
f01030a8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01030ab:	88 0a                	mov    %cl,(%edx)
f01030ad:	83 c2 01             	add    $0x1,%edx
f01030b0:	89 10                	mov    %edx,(%eax)
}
f01030b2:	5d                   	pop    %ebp
f01030b3:	c3                   	ret    

f01030b4 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01030b4:	55                   	push   %ebp
f01030b5:	89 e5                	mov    %esp,%ebp
f01030b7:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01030ba:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01030bd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01030c1:	8b 45 10             	mov    0x10(%ebp),%eax
f01030c4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01030c8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030cb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01030cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01030d2:	89 04 24             	mov    %eax,(%esp)
f01030d5:	e8 02 00 00 00       	call   f01030dc <vprintfmt>
	va_end(ap);
}
f01030da:	c9                   	leave  
f01030db:	c3                   	ret    

f01030dc <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01030dc:	55                   	push   %ebp
f01030dd:	89 e5                	mov    %esp,%ebp
f01030df:	57                   	push   %edi
f01030e0:	56                   	push   %esi
f01030e1:	53                   	push   %ebx
f01030e2:	83 ec 4c             	sub    $0x4c,%esp
f01030e5:	8b 75 08             	mov    0x8(%ebp),%esi
f01030e8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01030eb:	8b 7d 10             	mov    0x10(%ebp),%edi
f01030ee:	eb 11                	jmp    f0103101 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01030f0:	85 c0                	test   %eax,%eax
f01030f2:	0f 84 93 03 00 00    	je     f010348b <vprintfmt+0x3af>
				return;
			putch(ch, putdat);
f01030f8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01030fc:	89 04 24             	mov    %eax,(%esp)
f01030ff:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103101:	0f b6 07             	movzbl (%edi),%eax
f0103104:	83 c7 01             	add    $0x1,%edi
f0103107:	83 f8 25             	cmp    $0x25,%eax
f010310a:	75 e4                	jne    f01030f0 <vprintfmt+0x14>
f010310c:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f0103110:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0103117:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f010311e:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0103125:	ba 00 00 00 00       	mov    $0x0,%edx
f010312a:	eb 2b                	jmp    f0103157 <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010312c:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f010312f:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f0103133:	eb 22                	jmp    f0103157 <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103135:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103138:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f010313c:	eb 19                	jmp    f0103157 <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010313e:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0103141:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103148:	eb 0d                	jmp    f0103157 <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010314a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010314d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103150:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103157:	0f b6 0f             	movzbl (%edi),%ecx
f010315a:	8d 47 01             	lea    0x1(%edi),%eax
f010315d:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103160:	0f b6 07             	movzbl (%edi),%eax
f0103163:	83 e8 23             	sub    $0x23,%eax
f0103166:	3c 55                	cmp    $0x55,%al
f0103168:	0f 87 f8 02 00 00    	ja     f0103466 <vprintfmt+0x38a>
f010316e:	0f b6 c0             	movzbl %al,%eax
f0103171:	ff 24 85 ec 4a 10 f0 	jmp    *-0xfefb514(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103178:	83 e9 30             	sub    $0x30,%ecx
f010317b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
f010317e:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
f0103182:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0103185:	83 f9 09             	cmp    $0x9,%ecx
f0103188:	77 57                	ja     f01031e1 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010318a:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010318d:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0103190:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103193:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0103196:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0103199:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f010319d:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f01031a0:	8d 48 d0             	lea    -0x30(%eax),%ecx
f01031a3:	83 f9 09             	cmp    $0x9,%ecx
f01031a6:	76 eb                	jbe    f0103193 <vprintfmt+0xb7>
f01031a8:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01031ab:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01031ae:	eb 34                	jmp    f01031e4 <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01031b0:	8b 45 14             	mov    0x14(%ebp),%eax
f01031b3:	8d 48 04             	lea    0x4(%eax),%ecx
f01031b6:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01031b9:	8b 00                	mov    (%eax),%eax
f01031bb:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031be:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01031c1:	eb 21                	jmp    f01031e4 <vprintfmt+0x108>

		case '.':
			if (width < 0)
f01031c3:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01031c7:	0f 88 71 ff ff ff    	js     f010313e <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031cd:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01031d0:	eb 85                	jmp    f0103157 <vprintfmt+0x7b>
f01031d2:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01031d5:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f01031dc:	e9 76 ff ff ff       	jmp    f0103157 <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031e1:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f01031e4:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01031e8:	0f 89 69 ff ff ff    	jns    f0103157 <vprintfmt+0x7b>
f01031ee:	e9 57 ff ff ff       	jmp    f010314a <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01031f3:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031f6:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01031f9:	e9 59 ff ff ff       	jmp    f0103157 <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01031fe:	8b 45 14             	mov    0x14(%ebp),%eax
f0103201:	8d 50 04             	lea    0x4(%eax),%edx
f0103204:	89 55 14             	mov    %edx,0x14(%ebp)
f0103207:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010320b:	8b 00                	mov    (%eax),%eax
f010320d:	89 04 24             	mov    %eax,(%esp)
f0103210:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103212:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103215:	e9 e7 fe ff ff       	jmp    f0103101 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010321a:	8b 45 14             	mov    0x14(%ebp),%eax
f010321d:	8d 50 04             	lea    0x4(%eax),%edx
f0103220:	89 55 14             	mov    %edx,0x14(%ebp)
f0103223:	8b 00                	mov    (%eax),%eax
f0103225:	89 c2                	mov    %eax,%edx
f0103227:	c1 fa 1f             	sar    $0x1f,%edx
f010322a:	31 d0                	xor    %edx,%eax
f010322c:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
f010322e:	83 f8 06             	cmp    $0x6,%eax
f0103231:	7f 0b                	jg     f010323e <vprintfmt+0x162>
f0103233:	8b 14 85 44 4c 10 f0 	mov    -0xfefb3bc(,%eax,4),%edx
f010323a:	85 d2                	test   %edx,%edx
f010323c:	75 20                	jne    f010325e <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
f010323e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103242:	c7 44 24 08 79 4a 10 	movl   $0xf0104a79,0x8(%esp)
f0103249:	f0 
f010324a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010324e:	89 34 24             	mov    %esi,(%esp)
f0103251:	e8 5e fe ff ff       	call   f01030b4 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103256:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103259:	e9 a3 fe ff ff       	jmp    f0103101 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010325e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103262:	c7 44 24 08 a8 47 10 	movl   $0xf01047a8,0x8(%esp)
f0103269:	f0 
f010326a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010326e:	89 34 24             	mov    %esi,(%esp)
f0103271:	e8 3e fe ff ff       	call   f01030b4 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103276:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103279:	e9 83 fe ff ff       	jmp    f0103101 <vprintfmt+0x25>
f010327e:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103281:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0103284:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103287:	8b 45 14             	mov    0x14(%ebp),%eax
f010328a:	8d 50 04             	lea    0x4(%eax),%edx
f010328d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103290:	8b 38                	mov    (%eax),%edi
f0103292:	85 ff                	test   %edi,%edi
f0103294:	75 05                	jne    f010329b <vprintfmt+0x1bf>
				p = "(null)";
f0103296:	bf 72 4a 10 f0       	mov    $0xf0104a72,%edi
			if (width > 0 && padc != '-')
f010329b:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f010329f:	74 06                	je     f01032a7 <vprintfmt+0x1cb>
f01032a1:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f01032a5:	7f 16                	jg     f01032bd <vprintfmt+0x1e1>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01032a7:	0f b6 17             	movzbl (%edi),%edx
f01032aa:	0f be c2             	movsbl %dl,%eax
f01032ad:	83 c7 01             	add    $0x1,%edi
f01032b0:	85 c0                	test   %eax,%eax
f01032b2:	0f 85 9f 00 00 00    	jne    f0103357 <vprintfmt+0x27b>
f01032b8:	e9 8b 00 00 00       	jmp    f0103348 <vprintfmt+0x26c>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01032bd:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01032c1:	89 3c 24             	mov    %edi,(%esp)
f01032c4:	e8 39 03 00 00       	call   f0103602 <strnlen>
f01032c9:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01032cc:	29 c2                	sub    %eax,%edx
f01032ce:	89 55 d8             	mov    %edx,-0x28(%ebp)
f01032d1:	85 d2                	test   %edx,%edx
f01032d3:	7e d2                	jle    f01032a7 <vprintfmt+0x1cb>
					putch(padc, putdat);
f01032d5:	0f be 45 e4          	movsbl -0x1c(%ebp),%eax
f01032d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01032dc:	89 7d cc             	mov    %edi,-0x34(%ebp)
f01032df:	89 d7                	mov    %edx,%edi
f01032e1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01032e5:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01032e8:	89 14 24             	mov    %edx,(%esp)
f01032eb:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01032ed:	83 ef 01             	sub    $0x1,%edi
f01032f0:	75 ef                	jne    f01032e1 <vprintfmt+0x205>
f01032f2:	89 7d d8             	mov    %edi,-0x28(%ebp)
f01032f5:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01032f8:	eb ad                	jmp    f01032a7 <vprintfmt+0x1cb>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01032fa:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01032fe:	74 20                	je     f0103320 <vprintfmt+0x244>
f0103300:	0f be d2             	movsbl %dl,%edx
f0103303:	83 ea 20             	sub    $0x20,%edx
f0103306:	83 fa 5e             	cmp    $0x5e,%edx
f0103309:	76 15                	jbe    f0103320 <vprintfmt+0x244>
					putch('?', putdat);
f010330b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010330e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103312:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103319:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010331c:	ff d2                	call   *%edx
f010331e:	eb 0f                	jmp    f010332f <vprintfmt+0x253>
				else
					putch(ch, putdat);
f0103320:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103323:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103327:	89 04 24             	mov    %eax,(%esp)
f010332a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010332d:	ff d0                	call   *%eax
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010332f:	83 eb 01             	sub    $0x1,%ebx
f0103332:	0f b6 17             	movzbl (%edi),%edx
f0103335:	0f be c2             	movsbl %dl,%eax
f0103338:	83 c7 01             	add    $0x1,%edi
f010333b:	85 c0                	test   %eax,%eax
f010333d:	75 24                	jne    f0103363 <vprintfmt+0x287>
f010333f:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0103342:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103345:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103348:	8b 7d e0             	mov    -0x20(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010334b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010334f:	0f 8e ac fd ff ff    	jle    f0103101 <vprintfmt+0x25>
f0103355:	eb 20                	jmp    f0103377 <vprintfmt+0x29b>
f0103357:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f010335a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010335d:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0103360:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103363:	85 f6                	test   %esi,%esi
f0103365:	78 93                	js     f01032fa <vprintfmt+0x21e>
f0103367:	83 ee 01             	sub    $0x1,%esi
f010336a:	79 8e                	jns    f01032fa <vprintfmt+0x21e>
f010336c:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f010336f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103372:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103375:	eb d1                	jmp    f0103348 <vprintfmt+0x26c>
f0103377:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010337a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010337e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103385:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103387:	83 ef 01             	sub    $0x1,%edi
f010338a:	75 ee                	jne    f010337a <vprintfmt+0x29e>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010338c:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010338f:	e9 6d fd ff ff       	jmp    f0103101 <vprintfmt+0x25>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103394:	8d 45 14             	lea    0x14(%ebp),%eax
f0103397:	e8 c1 fc ff ff       	call   f010305d <getint>
f010339c:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010339f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01033a2:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01033a7:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01033ab:	79 7d                	jns    f010342a <vprintfmt+0x34e>
				putch('-', putdat);
f01033ad:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01033b1:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01033b8:	ff d6                	call   *%esi
				num = -(long long) num;
f01033ba:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01033bd:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01033c0:	f7 d8                	neg    %eax
f01033c2:	83 d2 00             	adc    $0x0,%edx
f01033c5:	f7 da                	neg    %edx
			}
			base = 10;
f01033c7:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01033cc:	eb 5c                	jmp    f010342a <vprintfmt+0x34e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01033ce:	8d 45 14             	lea    0x14(%ebp),%eax
f01033d1:	e8 4d fc ff ff       	call   f0103023 <getuint>
			base = 10;
f01033d6:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01033db:	eb 4d                	jmp    f010342a <vprintfmt+0x34e>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap, lflag);
f01033dd:	8d 45 14             	lea    0x14(%ebp),%eax
f01033e0:	e8 78 fc ff ff       	call   f010305d <getint>
			base = 8;
f01033e5:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01033ea:	eb 3e                	jmp    f010342a <vprintfmt+0x34e>
			// pointer
		case 'p':
			putch('0', putdat);
f01033ec:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01033f0:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01033f7:	ff d6                	call   *%esi
			putch('x', putdat);
f01033f9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01033fd:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0103404:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103406:	8b 45 14             	mov    0x14(%ebp),%eax
f0103409:	8d 50 04             	lea    0x4(%eax),%edx
f010340c:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
			// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010340f:	8b 00                	mov    (%eax),%eax
f0103411:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103416:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f010341b:	eb 0d                	jmp    f010342a <vprintfmt+0x34e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010341d:	8d 45 14             	lea    0x14(%ebp),%eax
f0103420:	e8 fe fb ff ff       	call   f0103023 <getuint>
			base = 16;
f0103425:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f010342a:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f010342e:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0103432:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0103435:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103439:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010343d:	89 04 24             	mov    %eax,(%esp)
f0103440:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103444:	89 da                	mov    %ebx,%edx
f0103446:	89 f0                	mov    %esi,%eax
f0103448:	e8 e3 fa ff ff       	call   f0102f30 <printnum>
			break;
f010344d:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103450:	e9 ac fc ff ff       	jmp    f0103101 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103455:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103459:	89 0c 24             	mov    %ecx,(%esp)
f010345c:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010345e:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103461:	e9 9b fc ff ff       	jmp    f0103101 <vprintfmt+0x25>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103466:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010346a:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103471:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103473:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103477:	0f 84 84 fc ff ff    	je     f0103101 <vprintfmt+0x25>
f010347d:	83 ef 01             	sub    $0x1,%edi
f0103480:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103484:	75 f7                	jne    f010347d <vprintfmt+0x3a1>
f0103486:	e9 76 fc ff ff       	jmp    f0103101 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010348b:	83 c4 4c             	add    $0x4c,%esp
f010348e:	5b                   	pop    %ebx
f010348f:	5e                   	pop    %esi
f0103490:	5f                   	pop    %edi
f0103491:	5d                   	pop    %ebp
f0103492:	c3                   	ret    

f0103493 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103493:	55                   	push   %ebp
f0103494:	89 e5                	mov    %esp,%ebp
f0103496:	83 ec 28             	sub    $0x28,%esp
f0103499:	8b 45 08             	mov    0x8(%ebp),%eax
f010349c:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010349f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01034a2:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01034a6:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01034a9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01034b0:	85 d2                	test   %edx,%edx
f01034b2:	7e 30                	jle    f01034e4 <vsnprintf+0x51>
f01034b4:	85 c0                	test   %eax,%eax
f01034b6:	74 2c                	je     f01034e4 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01034b8:	8b 45 14             	mov    0x14(%ebp),%eax
f01034bb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034bf:	8b 45 10             	mov    0x10(%ebp),%eax
f01034c2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01034c6:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01034c9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034cd:	c7 04 24 97 30 10 f0 	movl   $0xf0103097,(%esp)
f01034d4:	e8 03 fc ff ff       	call   f01030dc <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01034d9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01034dc:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01034df:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01034e2:	eb 05                	jmp    f01034e9 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01034e4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01034e9:	c9                   	leave  
f01034ea:	c3                   	ret    

f01034eb <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01034eb:	55                   	push   %ebp
f01034ec:	89 e5                	mov    %esp,%ebp
f01034ee:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01034f1:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01034f4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034f8:	8b 45 10             	mov    0x10(%ebp),%eax
f01034fb:	89 44 24 08          	mov    %eax,0x8(%esp)
f01034ff:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103502:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103506:	8b 45 08             	mov    0x8(%ebp),%eax
f0103509:	89 04 24             	mov    %eax,(%esp)
f010350c:	e8 82 ff ff ff       	call   f0103493 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103511:	c9                   	leave  
f0103512:	c3                   	ret    
	...

f0103520 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103520:	55                   	push   %ebp
f0103521:	89 e5                	mov    %esp,%ebp
f0103523:	57                   	push   %edi
f0103524:	56                   	push   %esi
f0103525:	53                   	push   %ebx
f0103526:	83 ec 1c             	sub    $0x1c,%esp
f0103529:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010352c:	85 c0                	test   %eax,%eax
f010352e:	74 10                	je     f0103540 <readline+0x20>
		cprintf("%s", prompt);
f0103530:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103534:	c7 04 24 a8 47 10 f0 	movl   $0xf01047a8,(%esp)
f010353b:	e8 12 f7 ff ff       	call   f0102c52 <cprintf>

	i = 0;
	echoing = iscons(0);
f0103540:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103547:	e8 4c d1 ff ff       	call   f0100698 <iscons>
f010354c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010354e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103553:	e8 2f d1 ff ff       	call   f0100687 <getchar>
f0103558:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010355a:	85 c0                	test   %eax,%eax
f010355c:	79 17                	jns    f0103575 <readline+0x55>
			cprintf("read error: %e\n", c);
f010355e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103562:	c7 04 24 60 4c 10 f0 	movl   $0xf0104c60,(%esp)
f0103569:	e8 e4 f6 ff ff       	call   f0102c52 <cprintf>
			return NULL;
f010356e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103573:	eb 61                	jmp    f01035d6 <readline+0xb6>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103575:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010357b:	7f 1c                	jg     f0103599 <readline+0x79>
f010357d:	83 f8 1f             	cmp    $0x1f,%eax
f0103580:	7e 17                	jle    f0103599 <readline+0x79>
			if (echoing)
f0103582:	85 ff                	test   %edi,%edi
f0103584:	74 08                	je     f010358e <readline+0x6e>
				cputchar(c);
f0103586:	89 04 24             	mov    %eax,(%esp)
f0103589:	e8 e6 d0 ff ff       	call   f0100674 <cputchar>
			buf[i++] = c;
f010358e:	88 9e 00 66 11 f0    	mov    %bl,-0xfee9a00(%esi)
f0103594:	83 c6 01             	add    $0x1,%esi
f0103597:	eb ba                	jmp    f0103553 <readline+0x33>
		} else if (c == '\b' && i > 0) {
f0103599:	85 f6                	test   %esi,%esi
f010359b:	7e 16                	jle    f01035b3 <readline+0x93>
f010359d:	83 fb 08             	cmp    $0x8,%ebx
f01035a0:	75 11                	jne    f01035b3 <readline+0x93>
			if (echoing)
f01035a2:	85 ff                	test   %edi,%edi
f01035a4:	74 08                	je     f01035ae <readline+0x8e>
				cputchar(c);
f01035a6:	89 1c 24             	mov    %ebx,(%esp)
f01035a9:	e8 c6 d0 ff ff       	call   f0100674 <cputchar>
			i--;
f01035ae:	83 ee 01             	sub    $0x1,%esi
f01035b1:	eb a0                	jmp    f0103553 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01035b3:	83 fb 0d             	cmp    $0xd,%ebx
f01035b6:	74 05                	je     f01035bd <readline+0x9d>
f01035b8:	83 fb 0a             	cmp    $0xa,%ebx
f01035bb:	75 96                	jne    f0103553 <readline+0x33>
			if (echoing)
f01035bd:	85 ff                	test   %edi,%edi
f01035bf:	90                   	nop
f01035c0:	74 08                	je     f01035ca <readline+0xaa>
				cputchar(c);
f01035c2:	89 1c 24             	mov    %ebx,(%esp)
f01035c5:	e8 aa d0 ff ff       	call   f0100674 <cputchar>
			buf[i] = 0;
f01035ca:	c6 86 00 66 11 f0 00 	movb   $0x0,-0xfee9a00(%esi)
			return buf;
f01035d1:	b8 00 66 11 f0       	mov    $0xf0116600,%eax
		}
	}
}
f01035d6:	83 c4 1c             	add    $0x1c,%esp
f01035d9:	5b                   	pop    %ebx
f01035da:	5e                   	pop    %esi
f01035db:	5f                   	pop    %edi
f01035dc:	5d                   	pop    %ebp
f01035dd:	c3                   	ret    
	...

f01035e0 <strlen>:

#include <inc/string.h>

int
strlen(const char *s)
{
f01035e0:	55                   	push   %ebp
f01035e1:	89 e5                	mov    %esp,%ebp
f01035e3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01035e6:	80 3a 00             	cmpb   $0x0,(%edx)
f01035e9:	74 10                	je     f01035fb <strlen+0x1b>
f01035eb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01035f0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01035f3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01035f7:	75 f7                	jne    f01035f0 <strlen+0x10>
f01035f9:	eb 05                	jmp    f0103600 <strlen+0x20>
f01035fb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0103600:	5d                   	pop    %ebp
f0103601:	c3                   	ret    

f0103602 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103602:	55                   	push   %ebp
f0103603:	89 e5                	mov    %esp,%ebp
f0103605:	53                   	push   %ebx
f0103606:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103609:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010360c:	85 c9                	test   %ecx,%ecx
f010360e:	74 1c                	je     f010362c <strnlen+0x2a>
f0103610:	80 3b 00             	cmpb   $0x0,(%ebx)
f0103613:	74 1e                	je     f0103633 <strnlen+0x31>
f0103615:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f010361a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010361c:	39 ca                	cmp    %ecx,%edx
f010361e:	74 18                	je     f0103638 <strnlen+0x36>
f0103620:	83 c2 01             	add    $0x1,%edx
f0103623:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0103628:	75 f0                	jne    f010361a <strnlen+0x18>
f010362a:	eb 0c                	jmp    f0103638 <strnlen+0x36>
f010362c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103631:	eb 05                	jmp    f0103638 <strnlen+0x36>
f0103633:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0103638:	5b                   	pop    %ebx
f0103639:	5d                   	pop    %ebp
f010363a:	c3                   	ret    

f010363b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010363b:	55                   	push   %ebp
f010363c:	89 e5                	mov    %esp,%ebp
f010363e:	53                   	push   %ebx
f010363f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103642:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103645:	89 c2                	mov    %eax,%edx
f0103647:	0f b6 19             	movzbl (%ecx),%ebx
f010364a:	88 1a                	mov    %bl,(%edx)
f010364c:	83 c2 01             	add    $0x1,%edx
f010364f:	83 c1 01             	add    $0x1,%ecx
f0103652:	84 db                	test   %bl,%bl
f0103654:	75 f1                	jne    f0103647 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103656:	5b                   	pop    %ebx
f0103657:	5d                   	pop    %ebp
f0103658:	c3                   	ret    

f0103659 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103659:	55                   	push   %ebp
f010365a:	89 e5                	mov    %esp,%ebp
f010365c:	56                   	push   %esi
f010365d:	53                   	push   %ebx
f010365e:	8b 75 08             	mov    0x8(%ebp),%esi
f0103661:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103664:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103667:	85 db                	test   %ebx,%ebx
f0103669:	74 16                	je     f0103681 <strncpy+0x28>
		/* do nothing */;
	return ret;
}

char *
strncpy(char *dst, const char *src, size_t size) {
f010366b:	01 f3                	add    %esi,%ebx
f010366d:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
f010366f:	0f b6 02             	movzbl (%edx),%eax
f0103672:	88 01                	mov    %al,(%ecx)
f0103674:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103677:	80 3a 01             	cmpb   $0x1,(%edx)
f010367a:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010367d:	39 d9                	cmp    %ebx,%ecx
f010367f:	75 ee                	jne    f010366f <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103681:	89 f0                	mov    %esi,%eax
f0103683:	5b                   	pop    %ebx
f0103684:	5e                   	pop    %esi
f0103685:	5d                   	pop    %ebp
f0103686:	c3                   	ret    

f0103687 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103687:	55                   	push   %ebp
f0103688:	89 e5                	mov    %esp,%ebp
f010368a:	57                   	push   %edi
f010368b:	56                   	push   %esi
f010368c:	53                   	push   %ebx
f010368d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103690:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103693:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103696:	89 f8                	mov    %edi,%eax
f0103698:	85 f6                	test   %esi,%esi
f010369a:	74 33                	je     f01036cf <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
f010369c:	83 fe 01             	cmp    $0x1,%esi
f010369f:	74 25                	je     f01036c6 <strlcpy+0x3f>
f01036a1:	0f b6 0b             	movzbl (%ebx),%ecx
f01036a4:	84 c9                	test   %cl,%cl
f01036a6:	74 22                	je     f01036ca <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f01036a8:	83 ee 02             	sub    $0x2,%esi
f01036ab:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01036b0:	88 08                	mov    %cl,(%eax)
f01036b2:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01036b5:	39 f2                	cmp    %esi,%edx
f01036b7:	74 13                	je     f01036cc <strlcpy+0x45>
f01036b9:	83 c2 01             	add    $0x1,%edx
f01036bc:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01036c0:	84 c9                	test   %cl,%cl
f01036c2:	75 ec                	jne    f01036b0 <strlcpy+0x29>
f01036c4:	eb 06                	jmp    f01036cc <strlcpy+0x45>
f01036c6:	89 f8                	mov    %edi,%eax
f01036c8:	eb 02                	jmp    f01036cc <strlcpy+0x45>
f01036ca:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f01036cc:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01036cf:	29 f8                	sub    %edi,%eax
}
f01036d1:	5b                   	pop    %ebx
f01036d2:	5e                   	pop    %esi
f01036d3:	5f                   	pop    %edi
f01036d4:	5d                   	pop    %ebp
f01036d5:	c3                   	ret    

f01036d6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01036d6:	55                   	push   %ebp
f01036d7:	89 e5                	mov    %esp,%ebp
f01036d9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01036dc:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01036df:	0f b6 01             	movzbl (%ecx),%eax
f01036e2:	84 c0                	test   %al,%al
f01036e4:	74 15                	je     f01036fb <strcmp+0x25>
f01036e6:	3a 02                	cmp    (%edx),%al
f01036e8:	75 11                	jne    f01036fb <strcmp+0x25>
		p++, q++;
f01036ea:	83 c1 01             	add    $0x1,%ecx
f01036ed:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01036f0:	0f b6 01             	movzbl (%ecx),%eax
f01036f3:	84 c0                	test   %al,%al
f01036f5:	74 04                	je     f01036fb <strcmp+0x25>
f01036f7:	3a 02                	cmp    (%edx),%al
f01036f9:	74 ef                	je     f01036ea <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01036fb:	0f b6 c0             	movzbl %al,%eax
f01036fe:	0f b6 12             	movzbl (%edx),%edx
f0103701:	29 d0                	sub    %edx,%eax
}
f0103703:	5d                   	pop    %ebp
f0103704:	c3                   	ret    

f0103705 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103705:	55                   	push   %ebp
f0103706:	89 e5                	mov    %esp,%ebp
f0103708:	56                   	push   %esi
f0103709:	53                   	push   %ebx
f010370a:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010370d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103710:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f0103713:	85 f6                	test   %esi,%esi
f0103715:	74 29                	je     f0103740 <strncmp+0x3b>
f0103717:	0f b6 03             	movzbl (%ebx),%eax
f010371a:	84 c0                	test   %al,%al
f010371c:	74 30                	je     f010374e <strncmp+0x49>
f010371e:	3a 02                	cmp    (%edx),%al
f0103720:	75 2c                	jne    f010374e <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
f0103722:	8d 43 01             	lea    0x1(%ebx),%eax
f0103725:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
f0103727:	89 c3                	mov    %eax,%ebx
f0103729:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010372c:	39 f0                	cmp    %esi,%eax
f010372e:	74 17                	je     f0103747 <strncmp+0x42>
f0103730:	0f b6 08             	movzbl (%eax),%ecx
f0103733:	84 c9                	test   %cl,%cl
f0103735:	74 17                	je     f010374e <strncmp+0x49>
f0103737:	83 c0 01             	add    $0x1,%eax
f010373a:	3a 0a                	cmp    (%edx),%cl
f010373c:	74 e9                	je     f0103727 <strncmp+0x22>
f010373e:	eb 0e                	jmp    f010374e <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103740:	b8 00 00 00 00       	mov    $0x0,%eax
f0103745:	eb 0f                	jmp    f0103756 <strncmp+0x51>
f0103747:	b8 00 00 00 00       	mov    $0x0,%eax
f010374c:	eb 08                	jmp    f0103756 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010374e:	0f b6 03             	movzbl (%ebx),%eax
f0103751:	0f b6 12             	movzbl (%edx),%edx
f0103754:	29 d0                	sub    %edx,%eax
}
f0103756:	5b                   	pop    %ebx
f0103757:	5e                   	pop    %esi
f0103758:	5d                   	pop    %ebp
f0103759:	c3                   	ret    

f010375a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010375a:	55                   	push   %ebp
f010375b:	89 e5                	mov    %esp,%ebp
f010375d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103760:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103764:	0f b6 10             	movzbl (%eax),%edx
f0103767:	84 d2                	test   %dl,%dl
f0103769:	74 1b                	je     f0103786 <strchr+0x2c>
		if (*s == c)
f010376b:	38 ca                	cmp    %cl,%dl
f010376d:	75 06                	jne    f0103775 <strchr+0x1b>
f010376f:	eb 1a                	jmp    f010378b <strchr+0x31>
f0103771:	38 ca                	cmp    %cl,%dl
f0103773:	74 16                	je     f010378b <strchr+0x31>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103775:	83 c0 01             	add    $0x1,%eax
f0103778:	0f b6 10             	movzbl (%eax),%edx
f010377b:	84 d2                	test   %dl,%dl
f010377d:	75 f2                	jne    f0103771 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f010377f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103784:	eb 05                	jmp    f010378b <strchr+0x31>
f0103786:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010378b:	5d                   	pop    %ebp
f010378c:	c3                   	ret    

f010378d <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010378d:	55                   	push   %ebp
f010378e:	89 e5                	mov    %esp,%ebp
f0103790:	8b 45 08             	mov    0x8(%ebp),%eax
f0103793:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103797:	0f b6 10             	movzbl (%eax),%edx
f010379a:	84 d2                	test   %dl,%dl
f010379c:	74 14                	je     f01037b2 <strfind+0x25>
		if (*s == c)
f010379e:	38 ca                	cmp    %cl,%dl
f01037a0:	75 06                	jne    f01037a8 <strfind+0x1b>
f01037a2:	eb 0e                	jmp    f01037b2 <strfind+0x25>
f01037a4:	38 ca                	cmp    %cl,%dl
f01037a6:	74 0a                	je     f01037b2 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01037a8:	83 c0 01             	add    $0x1,%eax
f01037ab:	0f b6 10             	movzbl (%eax),%edx
f01037ae:	84 d2                	test   %dl,%dl
f01037b0:	75 f2                	jne    f01037a4 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f01037b2:	5d                   	pop    %ebp
f01037b3:	c3                   	ret    

f01037b4 <memset>:


void *
memset(void *v, int c, size_t n)
{
f01037b4:	55                   	push   %ebp
f01037b5:	89 e5                	mov    %esp,%ebp
f01037b7:	53                   	push   %ebx
f01037b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01037bb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01037be:	8b 5d 10             	mov    0x10(%ebp),%ebx
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f01037c1:	89 da                	mov    %ebx,%edx
f01037c3:	83 ea 01             	sub    $0x1,%edx
f01037c6:	78 0d                	js     f01037d5 <memset+0x21>
	return (char *) s;
}


void *
memset(void *v, int c, size_t n)
f01037c8:	01 c3                	add    %eax,%ebx
{
	char *p;
	int m;

	p = v;
f01037ca:	89 c2                	mov    %eax,%edx
	m = n;
	while (--m >= 0)
		*p++ = c;
f01037cc:	88 0a                	mov    %cl,(%edx)
f01037ce:	83 c2 01             	add    $0x1,%edx
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f01037d1:	39 da                	cmp    %ebx,%edx
f01037d3:	75 f7                	jne    f01037cc <memset+0x18>
		*p++ = c;

	return v;
}
f01037d5:	5b                   	pop    %ebx
f01037d6:	5d                   	pop    %ebp
f01037d7:	c3                   	ret    

f01037d8 <memmove>:

/* no memcpy - use memmove instead */

void *
memmove(void *dst, const void *src, size_t n)
{
f01037d8:	55                   	push   %ebp
f01037d9:	89 e5                	mov    %esp,%ebp
f01037db:	57                   	push   %edi
f01037dc:	56                   	push   %esi
f01037dd:	53                   	push   %ebx
f01037de:	8b 45 08             	mov    0x8(%ebp),%eax
f01037e1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01037e4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01037e7:	39 c6                	cmp    %eax,%esi
f01037e9:	72 0b                	jb     f01037f6 <memmove+0x1e>
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f01037eb:	ba 00 00 00 00       	mov    $0x0,%edx
f01037f0:	85 db                	test   %ebx,%ebx
f01037f2:	75 2b                	jne    f010381f <memmove+0x47>
f01037f4:	eb 37                	jmp    f010382d <memmove+0x55>
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01037f6:	8d 0c 1e             	lea    (%esi,%ebx,1),%ecx
f01037f9:	39 c8                	cmp    %ecx,%eax
f01037fb:	73 ee                	jae    f01037eb <memmove+0x13>
		s += n;
		d += n;
f01037fd:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
		while (n-- > 0)
f0103800:	8d 53 ff             	lea    -0x1(%ebx),%edx
f0103803:	85 db                	test   %ebx,%ebx
f0103805:	74 26                	je     f010382d <memmove+0x55>
}

/* no memcpy - use memmove instead */

void *
memmove(void *dst, const void *src, size_t n)
f0103807:	f7 db                	neg    %ebx
f0103809:	8d 34 19             	lea    (%ecx,%ebx,1),%esi
f010380c:	01 fb                	add    %edi,%ebx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
f010380e:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103812:	88 0c 13             	mov    %cl,(%ebx,%edx,1)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
f0103815:	83 ea 01             	sub    $0x1,%edx
f0103818:	83 fa ff             	cmp    $0xffffffff,%edx
f010381b:	75 f1                	jne    f010380e <memmove+0x36>
f010381d:	eb 0e                	jmp    f010382d <memmove+0x55>
			*--d = *--s;
	} else
		while (n-- > 0)
			*d++ = *s++;
f010381f:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103823:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0103826:	83 c2 01             	add    $0x1,%edx
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f0103829:	39 da                	cmp    %ebx,%edx
f010382b:	75 f2                	jne    f010381f <memmove+0x47>
			*d++ = *s++;

	return dst;
}
f010382d:	5b                   	pop    %ebx
f010382e:	5e                   	pop    %esi
f010382f:	5f                   	pop    %edi
f0103830:	5d                   	pop    %ebp
f0103831:	c3                   	ret    

f0103832 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0103832:	55                   	push   %ebp
f0103833:	89 e5                	mov    %esp,%ebp
f0103835:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103838:	8b 45 10             	mov    0x10(%ebp),%eax
f010383b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010383f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103842:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103846:	8b 45 08             	mov    0x8(%ebp),%eax
f0103849:	89 04 24             	mov    %eax,(%esp)
f010384c:	e8 87 ff ff ff       	call   f01037d8 <memmove>
}
f0103851:	c9                   	leave  
f0103852:	c3                   	ret    

f0103853 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103853:	55                   	push   %ebp
f0103854:	89 e5                	mov    %esp,%ebp
f0103856:	57                   	push   %edi
f0103857:	56                   	push   %esi
f0103858:	53                   	push   %ebx
f0103859:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010385c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010385f:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103862:	8d 78 ff             	lea    -0x1(%eax),%edi
f0103865:	85 c0                	test   %eax,%eax
f0103867:	74 36                	je     f010389f <memcmp+0x4c>
		if (*s1 != *s2)
f0103869:	0f b6 03             	movzbl (%ebx),%eax
f010386c:	0f b6 0e             	movzbl (%esi),%ecx
f010386f:	38 c8                	cmp    %cl,%al
f0103871:	75 17                	jne    f010388a <memcmp+0x37>
f0103873:	ba 00 00 00 00       	mov    $0x0,%edx
f0103878:	eb 1a                	jmp    f0103894 <memcmp+0x41>
f010387a:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f010387f:	83 c2 01             	add    $0x1,%edx
f0103882:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103886:	38 c8                	cmp    %cl,%al
f0103888:	74 0a                	je     f0103894 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f010388a:	0f b6 c0             	movzbl %al,%eax
f010388d:	0f b6 c9             	movzbl %cl,%ecx
f0103890:	29 c8                	sub    %ecx,%eax
f0103892:	eb 10                	jmp    f01038a4 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103894:	39 fa                	cmp    %edi,%edx
f0103896:	75 e2                	jne    f010387a <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103898:	b8 00 00 00 00       	mov    $0x0,%eax
f010389d:	eb 05                	jmp    f01038a4 <memcmp+0x51>
f010389f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01038a4:	5b                   	pop    %ebx
f01038a5:	5e                   	pop    %esi
f01038a6:	5f                   	pop    %edi
f01038a7:	5d                   	pop    %ebp
f01038a8:	c3                   	ret    

f01038a9 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01038a9:	55                   	push   %ebp
f01038aa:	89 e5                	mov    %esp,%ebp
f01038ac:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01038af:	89 c2                	mov    %eax,%edx
f01038b1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01038b4:	39 d0                	cmp    %edx,%eax
f01038b6:	73 15                	jae    f01038cd <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f01038b8:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f01038bc:	38 08                	cmp    %cl,(%eax)
f01038be:	75 06                	jne    f01038c6 <memfind+0x1d>
f01038c0:	eb 0b                	jmp    f01038cd <memfind+0x24>
f01038c2:	38 08                	cmp    %cl,(%eax)
f01038c4:	74 07                	je     f01038cd <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01038c6:	83 c0 01             	add    $0x1,%eax
f01038c9:	39 d0                	cmp    %edx,%eax
f01038cb:	75 f5                	jne    f01038c2 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01038cd:	5d                   	pop    %ebp
f01038ce:	66 90                	xchg   %ax,%ax
f01038d0:	c3                   	ret    

f01038d1 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01038d1:	55                   	push   %ebp
f01038d2:	89 e5                	mov    %esp,%ebp
f01038d4:	57                   	push   %edi
f01038d5:	56                   	push   %esi
f01038d6:	53                   	push   %ebx
f01038d7:	83 ec 04             	sub    $0x4,%esp
f01038da:	8b 55 08             	mov    0x8(%ebp),%edx
f01038dd:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01038e0:	0f b6 02             	movzbl (%edx),%eax
f01038e3:	3c 09                	cmp    $0x9,%al
f01038e5:	74 04                	je     f01038eb <strtol+0x1a>
f01038e7:	3c 20                	cmp    $0x20,%al
f01038e9:	75 0e                	jne    f01038f9 <strtol+0x28>
		s++;
f01038eb:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01038ee:	0f b6 02             	movzbl (%edx),%eax
f01038f1:	3c 09                	cmp    $0x9,%al
f01038f3:	74 f6                	je     f01038eb <strtol+0x1a>
f01038f5:	3c 20                	cmp    $0x20,%al
f01038f7:	74 f2                	je     f01038eb <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f01038f9:	3c 2b                	cmp    $0x2b,%al
f01038fb:	75 0a                	jne    f0103907 <strtol+0x36>
		s++;
f01038fd:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103900:	bf 00 00 00 00       	mov    $0x0,%edi
f0103905:	eb 10                	jmp    f0103917 <strtol+0x46>
f0103907:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010390c:	3c 2d                	cmp    $0x2d,%al
f010390e:	75 07                	jne    f0103917 <strtol+0x46>
		s++, neg = 1;
f0103910:	83 c2 01             	add    $0x1,%edx
f0103913:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103917:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010391d:	75 15                	jne    f0103934 <strtol+0x63>
f010391f:	80 3a 30             	cmpb   $0x30,(%edx)
f0103922:	75 10                	jne    f0103934 <strtol+0x63>
f0103924:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103928:	75 0a                	jne    f0103934 <strtol+0x63>
		s += 2, base = 16;
f010392a:	83 c2 02             	add    $0x2,%edx
f010392d:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103932:	eb 10                	jmp    f0103944 <strtol+0x73>
	else if (base == 0 && s[0] == '0')
f0103934:	85 db                	test   %ebx,%ebx
f0103936:	75 0c                	jne    f0103944 <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103938:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010393a:	80 3a 30             	cmpb   $0x30,(%edx)
f010393d:	75 05                	jne    f0103944 <strtol+0x73>
		s++, base = 8;
f010393f:	83 c2 01             	add    $0x1,%edx
f0103942:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0103944:	b8 00 00 00 00       	mov    $0x0,%eax
f0103949:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010394c:	0f b6 0a             	movzbl (%edx),%ecx
f010394f:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0103952:	89 f3                	mov    %esi,%ebx
f0103954:	80 fb 09             	cmp    $0x9,%bl
f0103957:	77 08                	ja     f0103961 <strtol+0x90>
			dig = *s - '0';
f0103959:	0f be c9             	movsbl %cl,%ecx
f010395c:	83 e9 30             	sub    $0x30,%ecx
f010395f:	eb 22                	jmp    f0103983 <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
f0103961:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0103964:	89 f3                	mov    %esi,%ebx
f0103966:	80 fb 19             	cmp    $0x19,%bl
f0103969:	77 08                	ja     f0103973 <strtol+0xa2>
			dig = *s - 'a' + 10;
f010396b:	0f be c9             	movsbl %cl,%ecx
f010396e:	83 e9 57             	sub    $0x57,%ecx
f0103971:	eb 10                	jmp    f0103983 <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
f0103973:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0103976:	89 f3                	mov    %esi,%ebx
f0103978:	80 fb 19             	cmp    $0x19,%bl
f010397b:	77 16                	ja     f0103993 <strtol+0xc2>
			dig = *s - 'A' + 10;
f010397d:	0f be c9             	movsbl %cl,%ecx
f0103980:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103983:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0103986:	7d 0f                	jge    f0103997 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
f0103988:	83 c2 01             	add    $0x1,%edx
f010398b:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f010398f:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0103991:	eb b9                	jmp    f010394c <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0103993:	89 c1                	mov    %eax,%ecx
f0103995:	eb 02                	jmp    f0103999 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103997:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0103999:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010399d:	74 05                	je     f01039a4 <strtol+0xd3>
		*endptr = (char *) s;
f010399f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01039a2:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f01039a4:	85 ff                	test   %edi,%edi
f01039a6:	74 04                	je     f01039ac <strtol+0xdb>
f01039a8:	89 c8                	mov    %ecx,%eax
f01039aa:	f7 d8                	neg    %eax
}
f01039ac:	83 c4 04             	add    $0x4,%esp
f01039af:	5b                   	pop    %ebx
f01039b0:	5e                   	pop    %esi
f01039b1:	5f                   	pop    %edi
f01039b2:	5d                   	pop    %ebp
f01039b3:	c3                   	ret    
	...

f01039c0 <__udivdi3>:
f01039c0:	83 ec 1c             	sub    $0x1c,%esp
f01039c3:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f01039c7:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01039cb:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01039cf:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f01039d3:	89 74 24 10          	mov    %esi,0x10(%esp)
f01039d7:	8b 74 24 24          	mov    0x24(%esp),%esi
f01039db:	85 c0                	test   %eax,%eax
f01039dd:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01039e1:	89 cf                	mov    %ecx,%edi
f01039e3:	89 6c 24 04          	mov    %ebp,0x4(%esp)
f01039e7:	75 37                	jne    f0103a20 <__udivdi3+0x60>
f01039e9:	39 f1                	cmp    %esi,%ecx
f01039eb:	77 73                	ja     f0103a60 <__udivdi3+0xa0>
f01039ed:	85 c9                	test   %ecx,%ecx
f01039ef:	75 0b                	jne    f01039fc <__udivdi3+0x3c>
f01039f1:	b8 01 00 00 00       	mov    $0x1,%eax
f01039f6:	31 d2                	xor    %edx,%edx
f01039f8:	f7 f1                	div    %ecx
f01039fa:	89 c1                	mov    %eax,%ecx
f01039fc:	89 f0                	mov    %esi,%eax
f01039fe:	31 d2                	xor    %edx,%edx
f0103a00:	f7 f1                	div    %ecx
f0103a02:	89 c6                	mov    %eax,%esi
f0103a04:	89 e8                	mov    %ebp,%eax
f0103a06:	f7 f1                	div    %ecx
f0103a08:	89 f2                	mov    %esi,%edx
f0103a0a:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103a0e:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103a12:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103a16:	83 c4 1c             	add    $0x1c,%esp
f0103a19:	c3                   	ret    
f0103a1a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103a20:	39 f0                	cmp    %esi,%eax
f0103a22:	77 24                	ja     f0103a48 <__udivdi3+0x88>
f0103a24:	0f bd e8             	bsr    %eax,%ebp
f0103a27:	83 f5 1f             	xor    $0x1f,%ebp
f0103a2a:	75 4c                	jne    f0103a78 <__udivdi3+0xb8>
f0103a2c:	31 d2                	xor    %edx,%edx
f0103a2e:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0103a32:	0f 86 b0 00 00 00    	jbe    f0103ae8 <__udivdi3+0x128>
f0103a38:	39 f0                	cmp    %esi,%eax
f0103a3a:	0f 82 a8 00 00 00    	jb     f0103ae8 <__udivdi3+0x128>
f0103a40:	31 c0                	xor    %eax,%eax
f0103a42:	eb c6                	jmp    f0103a0a <__udivdi3+0x4a>
f0103a44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103a48:	31 d2                	xor    %edx,%edx
f0103a4a:	31 c0                	xor    %eax,%eax
f0103a4c:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103a50:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103a54:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103a58:	83 c4 1c             	add    $0x1c,%esp
f0103a5b:	c3                   	ret    
f0103a5c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103a60:	89 e8                	mov    %ebp,%eax
f0103a62:	89 f2                	mov    %esi,%edx
f0103a64:	f7 f1                	div    %ecx
f0103a66:	31 d2                	xor    %edx,%edx
f0103a68:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103a6c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103a70:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103a74:	83 c4 1c             	add    $0x1c,%esp
f0103a77:	c3                   	ret    
f0103a78:	89 e9                	mov    %ebp,%ecx
f0103a7a:	89 fa                	mov    %edi,%edx
f0103a7c:	d3 e0                	shl    %cl,%eax
f0103a7e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103a82:	b8 20 00 00 00       	mov    $0x20,%eax
f0103a87:	29 e8                	sub    %ebp,%eax
f0103a89:	89 c1                	mov    %eax,%ecx
f0103a8b:	d3 ea                	shr    %cl,%edx
f0103a8d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0103a91:	09 ca                	or     %ecx,%edx
f0103a93:	89 e9                	mov    %ebp,%ecx
f0103a95:	d3 e7                	shl    %cl,%edi
f0103a97:	89 c1                	mov    %eax,%ecx
f0103a99:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103a9d:	89 f2                	mov    %esi,%edx
f0103a9f:	d3 ea                	shr    %cl,%edx
f0103aa1:	89 e9                	mov    %ebp,%ecx
f0103aa3:	89 14 24             	mov    %edx,(%esp)
f0103aa6:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103aaa:	d3 e6                	shl    %cl,%esi
f0103aac:	89 c1                	mov    %eax,%ecx
f0103aae:	d3 ea                	shr    %cl,%edx
f0103ab0:	89 d0                	mov    %edx,%eax
f0103ab2:	09 f0                	or     %esi,%eax
f0103ab4:	8b 34 24             	mov    (%esp),%esi
f0103ab7:	89 f2                	mov    %esi,%edx
f0103ab9:	f7 74 24 0c          	divl   0xc(%esp)
f0103abd:	89 d6                	mov    %edx,%esi
f0103abf:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103ac3:	f7 e7                	mul    %edi
f0103ac5:	39 d6                	cmp    %edx,%esi
f0103ac7:	72 2f                	jb     f0103af8 <__udivdi3+0x138>
f0103ac9:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103acd:	89 e9                	mov    %ebp,%ecx
f0103acf:	d3 e7                	shl    %cl,%edi
f0103ad1:	39 c7                	cmp    %eax,%edi
f0103ad3:	73 04                	jae    f0103ad9 <__udivdi3+0x119>
f0103ad5:	39 d6                	cmp    %edx,%esi
f0103ad7:	74 1f                	je     f0103af8 <__udivdi3+0x138>
f0103ad9:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103add:	31 d2                	xor    %edx,%edx
f0103adf:	e9 26 ff ff ff       	jmp    f0103a0a <__udivdi3+0x4a>
f0103ae4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103ae8:	b8 01 00 00 00       	mov    $0x1,%eax
f0103aed:	e9 18 ff ff ff       	jmp    f0103a0a <__udivdi3+0x4a>
f0103af2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103af8:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103afc:	31 d2                	xor    %edx,%edx
f0103afe:	83 e8 01             	sub    $0x1,%eax
f0103b01:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103b05:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103b09:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103b0d:	83 c4 1c             	add    $0x1c,%esp
f0103b10:	c3                   	ret    
	...

f0103b20 <__umoddi3>:
f0103b20:	83 ec 1c             	sub    $0x1c,%esp
f0103b23:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f0103b27:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103b2b:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103b2f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103b33:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103b37:	85 d2                	test   %edx,%edx
f0103b39:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103b3d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103b41:	89 cf                	mov    %ecx,%edi
f0103b43:	89 c5                	mov    %eax,%ebp
f0103b45:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103b49:	89 34 24             	mov    %esi,(%esp)
f0103b4c:	75 22                	jne    f0103b70 <__umoddi3+0x50>
f0103b4e:	39 f1                	cmp    %esi,%ecx
f0103b50:	76 56                	jbe    f0103ba8 <__umoddi3+0x88>
f0103b52:	89 f2                	mov    %esi,%edx
f0103b54:	f7 f1                	div    %ecx
f0103b56:	89 d0                	mov    %edx,%eax
f0103b58:	31 d2                	xor    %edx,%edx
f0103b5a:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103b5e:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103b62:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103b66:	83 c4 1c             	add    $0x1c,%esp
f0103b69:	c3                   	ret    
f0103b6a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103b70:	39 f2                	cmp    %esi,%edx
f0103b72:	77 54                	ja     f0103bc8 <__umoddi3+0xa8>
f0103b74:	0f bd c2             	bsr    %edx,%eax
f0103b77:	83 f0 1f             	xor    $0x1f,%eax
f0103b7a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b7e:	75 60                	jne    f0103be0 <__umoddi3+0xc0>
f0103b80:	39 e9                	cmp    %ebp,%ecx
f0103b82:	0f 87 08 01 00 00    	ja     f0103c90 <__umoddi3+0x170>
f0103b88:	29 cd                	sub    %ecx,%ebp
f0103b8a:	19 d6                	sbb    %edx,%esi
f0103b8c:	89 34 24             	mov    %esi,(%esp)
f0103b8f:	8b 14 24             	mov    (%esp),%edx
f0103b92:	89 e8                	mov    %ebp,%eax
f0103b94:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103b98:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103b9c:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103ba0:	83 c4 1c             	add    $0x1c,%esp
f0103ba3:	c3                   	ret    
f0103ba4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103ba8:	85 c9                	test   %ecx,%ecx
f0103baa:	75 0b                	jne    f0103bb7 <__umoddi3+0x97>
f0103bac:	b8 01 00 00 00       	mov    $0x1,%eax
f0103bb1:	31 d2                	xor    %edx,%edx
f0103bb3:	f7 f1                	div    %ecx
f0103bb5:	89 c1                	mov    %eax,%ecx
f0103bb7:	89 f0                	mov    %esi,%eax
f0103bb9:	31 d2                	xor    %edx,%edx
f0103bbb:	f7 f1                	div    %ecx
f0103bbd:	89 e8                	mov    %ebp,%eax
f0103bbf:	f7 f1                	div    %ecx
f0103bc1:	eb 93                	jmp    f0103b56 <__umoddi3+0x36>
f0103bc3:	90                   	nop
f0103bc4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103bc8:	89 f2                	mov    %esi,%edx
f0103bca:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103bce:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103bd2:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103bd6:	83 c4 1c             	add    $0x1c,%esp
f0103bd9:	c3                   	ret    
f0103bda:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103be0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103be5:	bd 20 00 00 00       	mov    $0x20,%ebp
f0103bea:	89 f8                	mov    %edi,%eax
f0103bec:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0103bf0:	d3 e2                	shl    %cl,%edx
f0103bf2:	89 e9                	mov    %ebp,%ecx
f0103bf4:	d3 e8                	shr    %cl,%eax
f0103bf6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103bfb:	09 d0                	or     %edx,%eax
f0103bfd:	89 f2                	mov    %esi,%edx
f0103bff:	89 04 24             	mov    %eax,(%esp)
f0103c02:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103c06:	d3 e7                	shl    %cl,%edi
f0103c08:	89 e9                	mov    %ebp,%ecx
f0103c0a:	d3 ea                	shr    %cl,%edx
f0103c0c:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c11:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103c15:	d3 e6                	shl    %cl,%esi
f0103c17:	89 e9                	mov    %ebp,%ecx
f0103c19:	d3 e8                	shr    %cl,%eax
f0103c1b:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c20:	09 f0                	or     %esi,%eax
f0103c22:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103c26:	f7 34 24             	divl   (%esp)
f0103c29:	d3 e6                	shl    %cl,%esi
f0103c2b:	89 74 24 08          	mov    %esi,0x8(%esp)
f0103c2f:	89 d6                	mov    %edx,%esi
f0103c31:	f7 e7                	mul    %edi
f0103c33:	39 d6                	cmp    %edx,%esi
f0103c35:	89 c7                	mov    %eax,%edi
f0103c37:	89 d1                	mov    %edx,%ecx
f0103c39:	72 41                	jb     f0103c7c <__umoddi3+0x15c>
f0103c3b:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0103c3f:	72 37                	jb     f0103c78 <__umoddi3+0x158>
f0103c41:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103c45:	29 f8                	sub    %edi,%eax
f0103c47:	19 ce                	sbb    %ecx,%esi
f0103c49:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c4e:	89 f2                	mov    %esi,%edx
f0103c50:	d3 e8                	shr    %cl,%eax
f0103c52:	89 e9                	mov    %ebp,%ecx
f0103c54:	d3 e2                	shl    %cl,%edx
f0103c56:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c5b:	09 d0                	or     %edx,%eax
f0103c5d:	89 f2                	mov    %esi,%edx
f0103c5f:	d3 ea                	shr    %cl,%edx
f0103c61:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103c65:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103c69:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103c6d:	83 c4 1c             	add    $0x1c,%esp
f0103c70:	c3                   	ret    
f0103c71:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103c78:	39 d6                	cmp    %edx,%esi
f0103c7a:	75 c5                	jne    f0103c41 <__umoddi3+0x121>
f0103c7c:	89 d1                	mov    %edx,%ecx
f0103c7e:	89 c7                	mov    %eax,%edi
f0103c80:	2b 7c 24 0c          	sub    0xc(%esp),%edi
f0103c84:	1b 0c 24             	sbb    (%esp),%ecx
f0103c87:	eb b8                	jmp    f0103c41 <__umoddi3+0x121>
f0103c89:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103c90:	39 f2                	cmp    %esi,%edx
f0103c92:	0f 82 f0 fe ff ff    	jb     f0103b88 <__umoddi3+0x68>
f0103c98:	e9 f2 fe ff ff       	jmp    f0103b8f <__umoddi3+0x6f>
