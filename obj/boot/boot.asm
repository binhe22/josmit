
obj/boot/boot.out:     file format elf32-i386


Disassembly of section .text:

00007c00 <start>:
.set CR0_PE_ON,      0x1         # protected mode enable flag

.globl start
start:
  .code16                     # Assemble for 16-bit mode
  cli                         # Disable interrupts
    7c00:	fa                   	cli    
  cld                         # String operations increment
    7c01:	fc                   	cld    

  # Set up the important data segment registers (DS, ES, SS).
  xorw    %ax,%ax             # Segment number zero
    7c02:	31 c0                	xor    %eax,%eax
  movw    %ax,%ds             # -> Data Segment
    7c04:	8e d8                	mov    %eax,%ds
  movw    %ax,%es             # -> Extra Segment
    7c06:	8e c0                	mov    %eax,%es
  movw    %ax,%ss             # -> Stack Segment
    7c08:	8e d0                	mov    %eax,%ss

00007c0a <seta20.1>:
  # Enable A20:
  #   For backwards compatibility with the earliest PCs, physical
  #   address line 20 is tied low, so that addresses higher than
  #   1MB wrap around to zero by default.  This code undoes this.
seta20.1:
  inb     $0x64,%al               # Wait for not busy
    7c0a:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7c0c:	a8 02                	test   $0x2,%al
  jnz     seta20.1
    7c0e:	75 fa                	jne    7c0a <seta20.1>

  movb    $0xd1,%al               # 0xd1 -> port 0x64
    7c10:	b0 d1                	mov    $0xd1,%al
  outb    %al,$0x64
    7c12:	e6 64                	out    %al,$0x64

00007c14 <seta20.2>:

seta20.2:
  inb     $0x64,%al               # Wait for not busy
    7c14:	e4 64                	in     $0x64,%al
  testb   $0x2,%al
    7c16:	a8 02                	test   $0x2,%al
  jnz     seta20.2
    7c18:	75 fa                	jne    7c14 <seta20.2>

  movb    $0xdf,%al               # 0xdf -> port 0x60
    7c1a:	b0 df                	mov    $0xdf,%al
  outb    %al,$0x60
    7c1c:	e6 60                	out    %al,$0x60

  # Switch from real to protected mode, using a bootstrap GDT
  # and segment translation that makes virtual addresses 
  # identical to their physical addresses, so that the 
  # effective memory map does not change during the switch.
  lgdt    gdtdesc
    7c1e:	0f 01 16             	lgdtl  (%esi)
    7c21:	64                   	fs
    7c22:	7c 0f                	jl     7c33 <protcseg+0x1>
  movl    %cr0, %eax
    7c24:	20 c0                	and    %al,%al
  orl     $CR0_PE_ON, %eax
    7c26:	66 83 c8 01          	or     $0x1,%ax
  movl    %eax, %cr0
    7c2a:	0f 22 c0             	mov    %eax,%cr0
  
  # Jump to next instruction, but in 32-bit code segment.
  # Switches processor into 32-bit mode.
  ljmp    $PROT_MODE_CSEG, $protcseg
    7c2d:	ea 32 7c 08 00 66 b8 	ljmp   $0xb866,$0x87c32

00007c32 <protcseg>:

  .code32                     # Assemble for 32-bit mode
protcseg:
  # Set up the protected-mode data segment registers
  movw    $PROT_MODE_DSEG, %ax    # Our data segment selector
    7c32:	66 b8 10 00          	mov    $0x10,%ax
  movw    %ax, %ds                # -> DS: Data Segment
    7c36:	8e d8                	mov    %eax,%ds
  movw    %ax, %es                # -> ES: Extra Segment
    7c38:	8e c0                	mov    %eax,%es
  movw    %ax, %fs                # -> FS
    7c3a:	8e e0                	mov    %eax,%fs
  movw    %ax, %gs                # -> GS
    7c3c:	8e e8                	mov    %eax,%gs
  movw    %ax, %ss                # -> SS: Stack Segment
    7c3e:	8e d0                	mov    %eax,%ss
  
  # Set up the stack pointer and call into C.
  movl    $start, %esp
    7c40:	bc 00 7c 00 00       	mov    $0x7c00,%esp
  call bootmain
    7c45:	e8 ab 00 00 00       	call   7cf5 <bootmain>

00007c4a <spin>:

  # If bootmain returns (it shouldn't), loop.
spin:
  jmp spin
    7c4a:	eb fe                	jmp    7c4a <spin>

00007c4c <gdt>:
	...
    7c54:	ff                   	(bad)  
    7c55:	ff 00                	incl   (%eax)
    7c57:	00 00                	add    %al,(%eax)
    7c59:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
    7c60:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

00007c64 <gdtdesc>:
    7c64:	17                   	pop    %ss
    7c65:	00 4c 7c 00          	add    %cl,0x0(%esp,%edi,2)
    7c69:	00 90 90 55 89 e5    	add    %dl,-0x1a76aa70(%eax)

00007c6c <readseg>:

// Read 'count' bytes at 'offset' from kernel into virtual address 'va'.
// Might copy more than asked
static void
 readseg(uint32_t va, uint32_t count, uint32_t offset)
{
    7c6c:	55                   	push   %ebp
    7c6d:	89 e5                	mov    %esp,%ebp
    7c6f:	57                   	push   %edi
    7c70:	56                   	push   %esi

	va &= 0xFFFFFF;
	end_va = va + count;
	
	// round down to sector boundary
	va &= ~(SECTSIZE - 1);
    7c71:	89 c6                	mov    %eax,%esi

// Read 'count' bytes at 'offset' from kernel into virtual address 'va'.
// Might copy more than asked
static void
 readseg(uint32_t va, uint32_t count, uint32_t offset)
{
    7c73:	53                   	push   %ebx

	va &= 0xFFFFFF;
	end_va = va + count;
	
	// round down to sector boundary
	va &= ~(SECTSIZE - 1);
    7c74:	81 e6 00 fe ff 00    	and    $0xfffe00,%esi

// Read 'count' bytes at 'offset' from kernel into virtual address 'va'.
// Might copy more than asked
static void
 readseg(uint32_t va, uint32_t count, uint32_t offset)
{
    7c7a:	53                   	push   %ebx
	uint32_t end_va;

	va &= 0xFFFFFF;
    7c7b:	89 c3                	mov    %eax,%ebx
    7c7d:	81 e3 ff ff ff 00    	and    $0xffffff,%ebx
	end_va = va + count;
    7c83:	01 d3                	add    %edx,%ebx
	
	// round down to sector boundary
	va &= ~(SECTSIZE - 1);

	// translate from bytes to sectors, and kernel starts at sector 1
	offset = (offset / SECTSIZE) + 1;
    7c85:	c1 e9 09             	shr    $0x9,%ecx
 readseg(uint32_t va, uint32_t count, uint32_t offset)
{
	uint32_t end_va;

	va &= 0xFFFFFF;
	end_va = va + count;
    7c88:	89 5d f0             	mov    %ebx,-0x10(%ebp)
	
	// round down to sector boundary
	va &= ~(SECTSIZE - 1);

	// translate from bytes to sectors, and kernel starts at sector 1
	offset = (offset / SECTSIZE) + 1;
    7c8b:	8d 59 01             	lea    0x1(%ecx),%ebx

	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (va < end_va) {
    7c8e:	eb 5a                	jmp    7cea <readseg+0x7e>

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
    7c90:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7c95:	ec                   	in     (%dx),%al

static void
waitdisk(void)
{
	// wait for disk reaady
	while ((inb(0x1F7) & 0xC0) != 0x40)
    7c96:	83 e0 c0             	and    $0xffffffc0,%eax
    7c99:	3c 40                	cmp    $0x40,%al
    7c9b:	75 f3                	jne    7c90 <readseg+0x24>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
    7c9d:	b2 f2                	mov    $0xf2,%dl
    7c9f:	b0 01                	mov    $0x1,%al
    7ca1:	ee                   	out    %al,(%dx)
	// wait for disk to be ready
	waitdisk();

	// read a sector
	insl(0x1F0, dst, SECTSIZE/4);
}
    7ca2:	0f b6 c3             	movzbl %bl,%eax
    7ca5:	b2 f3                	mov    $0xf3,%dl
    7ca7:	ee                   	out    %al,(%dx)
    7ca8:	0f b6 c7             	movzbl %bh,%eax
    7cab:	b2 f4                	mov    $0xf4,%dl
    7cad:	ee                   	out    %al,(%dx)
	waitdisk();

	outb(0x1F2, 1);		// count = 1
	outb(0x1F3, offset);
	outb(0x1F4, offset >> 8);
	outb(0x1F5, offset >> 16);
    7cae:	89 d8                	mov    %ebx,%eax
    7cb0:	b2 f5                	mov    $0xf5,%dl
    7cb2:	c1 e8 10             	shr    $0x10,%eax
	// wait for disk to be ready
	waitdisk();

	// read a sector
	insl(0x1F0, dst, SECTSIZE/4);
}
    7cb5:	25 ff 00 00 00       	and    $0xff,%eax
    7cba:	ee                   	out    %al,(%dx)
    7cbb:	89 d8                	mov    %ebx,%eax
    7cbd:	b2 f6                	mov    $0xf6,%dl
    7cbf:	c1 e8 18             	shr    $0x18,%eax
    7cc2:	0c e0                	or     $0xe0,%al
    7cc4:	ee                   	out    %al,(%dx)
    7cc5:	b0 20                	mov    $0x20,%al
    7cc7:	b2 f7                	mov    $0xf7,%dl
    7cc9:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
    7cca:	ba f7 01 00 00       	mov    $0x1f7,%edx
    7ccf:	ec                   	in     (%dx),%al

static void
waitdisk(void)
{
	// wait for disk reaady
	while ((inb(0x1F7) & 0xC0) != 0x40)
    7cd0:	83 e0 c0             	and    $0xffffffc0,%eax
    7cd3:	3c 40                	cmp    $0x40,%al
    7cd5:	75 f3                	jne    7cca <readseg+0x5e>
}

static __inline void
insl(int port, void *addr, int cnt)
{
	__asm __volatile("cld\n\trepne\n\tinsl"			:
    7cd7:	89 f7                	mov    %esi,%edi
    7cd9:	b9 80 00 00 00       	mov    $0x80,%ecx
    7cde:	b2 f0                	mov    $0xf0,%dl
    7ce0:	fc                   	cld    
    7ce1:	f2 6d                	repnz insl (%dx),%es:(%edi)
	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (va < end_va) {
		readsect((uint8_t*) va, offset);
		va += SECTSIZE;
    7ce3:	81 c6 00 02 00 00    	add    $0x200,%esi
		offset++;
    7ce9:	43                   	inc    %ebx
	offset = (offset / SECTSIZE) + 1;

	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	while (va < end_va) {
    7cea:	3b 75 f0             	cmp    -0x10(%ebp),%esi
    7ced:	72 a1                	jb     7c90 <readseg+0x24>
		readsect((uint8_t*) va, offset);
		va += SECTSIZE;
		offset++;
	}
}
    7cef:	58                   	pop    %eax
    7cf0:	5b                   	pop    %ebx
    7cf1:	5e                   	pop    %esi
    7cf2:	5f                   	pop    %edi
    7cf3:	5d                   	pop    %ebp
    7cf4:	c3                   	ret    

00007cf5 <bootmain>:
 
static void readseg(uint32_t, uint32_t, uint32_t);

void
bootmain(void)
{
    7cf5:	55                   	push   %ebp
	struct Proghdr *ph, *eph;

	// read 1st page off disk
	readseg((uint32_t) ELFHDR, SECTSIZE*8, 0);
    7cf6:	31 c9                	xor    %ecx,%ecx
 
static void readseg(uint32_t, uint32_t, uint32_t);

void
bootmain(void)
{
    7cf8:	89 e5                	mov    %esp,%ebp
	struct Proghdr *ph, *eph;

	// read 1st page off disk
	readseg((uint32_t) ELFHDR, SECTSIZE*8, 0);
    7cfa:	ba 00 10 00 00       	mov    $0x1000,%edx
 
static void readseg(uint32_t, uint32_t, uint32_t);

void
bootmain(void)
{
    7cff:	56                   	push   %esi
	struct Proghdr *ph, *eph;

	// read 1st page off disk
	readseg((uint32_t) ELFHDR, SECTSIZE*8, 0);
    7d00:	b8 00 00 01 00       	mov    $0x10000,%eax
 
static void readseg(uint32_t, uint32_t, uint32_t);

void
bootmain(void)
{
    7d05:	53                   	push   %ebx
	struct Proghdr *ph, *eph;

	// read 1st page off disk
	readseg((uint32_t) ELFHDR, SECTSIZE*8, 0);
    7d06:	e8 61 ff ff ff       	call   7c6c <readseg>

	// is this a valid ELF?
	if (ELFHDR->e_magic != ELF_MAGIC)
    7d0b:	81 3d 00 00 01 00 7f 	cmpl   $0x464c457f,0x10000
    7d12:	45 4c 46 
    7d15:	75 3c                	jne    7d53 <bootmain+0x5e>
		goto bad;

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
    7d17:	8b 1d 1c 00 01 00    	mov    0x1001c,%ebx
	eph = ph + ELFHDR->e_phnum;
    7d1d:	0f b7 05 2c 00 01 00 	movzwl 0x1002c,%eax
	// is this a valid ELF?
	if (ELFHDR->e_magic != ELF_MAGIC)
		goto bad;

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
    7d24:	81 c3 00 00 01 00    	add    $0x10000,%ebx
	eph = ph + ELFHDR->e_phnum;
    7d2a:	c1 e0 05             	shl    $0x5,%eax
    7d2d:	8d 34 03             	lea    (%ebx,%eax,1),%esi
	for (; ph < eph; ph++)
    7d30:	eb 11                	jmp    7d43 <bootmain+0x4e>
		readseg(ph->p_va, ph->p_memsz, ph->p_offset);
    7d32:	8b 4b 04             	mov    0x4(%ebx),%ecx
    7d35:	8b 53 14             	mov    0x14(%ebx),%edx
    7d38:	8b 43 08             	mov    0x8(%ebx),%eax
		goto bad;

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;
	for (; ph < eph; ph++)
    7d3b:	83 c3 20             	add    $0x20,%ebx
		readseg(ph->p_va, ph->p_memsz, ph->p_offset);
    7d3e:	e8 29 ff ff ff       	call   7c6c <readseg>
		goto bad;

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;
	for (; ph < eph; ph++)
    7d43:	39 f3                	cmp    %esi,%ebx
    7d45:	72 eb                	jb     7d32 <bootmain+0x3d>
		readseg(ph->p_va, ph->p_memsz, ph->p_offset);

	// call the entry point from the ELF header
	// note: does not return!
	((void (*)(void)) (ELFHDR->e_entry & 0xFFFFFF))();
    7d47:	a1 18 00 01 00       	mov    0x10018,%eax
    7d4c:	25 ff ff ff 00       	and    $0xffffff,%eax
    7d51:	ff d0                	call   *%eax
}

static __inline void
outw(int port, uint16_t data)
{
	__asm __volatile("outw %0,%w1" : : "a" (data), "d" (port));
    7d53:	ba 00 8a 00 00       	mov    $0x8a00,%edx
    7d58:	b8 00 8a ff ff       	mov    $0xffff8a00,%eax
    7d5d:	66 ef                	out    %ax,(%dx)
    7d5f:	b8 00 8e ff ff       	mov    $0xffff8e00,%eax
    7d64:	66 ef                	out    %ax,(%dx)
    7d66:	eb fe                	jmp    7d66 <bootmain+0x71>
