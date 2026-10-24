;  =========================================================================
; |           Sonic the Hedgehog Disassembly for Sega Mega Drive            |
;  =========================================================================
;
; Disassembly created by Hivebrain
; thanks to drx, Stealth and Esrael L.G. Neto
; ---------------------------------------------------------------------------
; NOTE:
; Set your editor's tab width to 8 characters wide for viewing this file.

; ===========================================================================
; ASSEMBLY OPTIONS:

Revision = 1
; 	| If 0, build the original version of the game, dubbed REV00
; 	| If 1, build the later version, dubbed REV01, which includes various bugfixes and enhancements
; 	| If 2, build the hacked version from Sonic Mega Collection, dubbed REVXB,
;	|       which (sloppily) fixes the infamous "spike bug" -- not recommended

FixBugs = 0
;	| If 1, enables various bugfixes across the game and sound driver
;	|       (see also the "_Fixed Binary Files" folder, and FixMusicAndSFXDataBugs)

CheatsEnabled = 0
;	| If 1, all in-game cheats (Level Select, Debug Mode, Slow-Motion, Japanese Credits)
;	|       will be enabled by default, without requiring any title screen button inputs

AllOptimizations = 0
;	| If 1, enables all optimizations
SkipChecksumCheck = 0|AllOptimizations
;	| If 1, disables the slow bootup checksum calculation
ZeroOffsetOptimization = 0|AllOptimizations
;	| If 1, makes a handful of zero-offset instructions smaller
PaddingOptimization = 0|AllOptimizations
;	| If 1, removes about 3 KB of various superfluous padding

EnableSRAM = 0
;	| If 1, enable SRAM support
BackupSRAM = 1
;	| 0 = no saving (read-only SRAM); 1 = allow saving
AddressSRAM = 3
;	| 0 = odd+even; 2 = even only; 3 = odd only
;	| (odd only is the most common setting)

ZoneCount = 6
;	| Used for the "zonewarning" macro. Do not change, unless more zones get added.
;	| Discrete zones are: GHZ, LZ, MZ, SLZ, SYZ, and SBZ

; ===========================================================================
; AS-specific macros and assembler settings
	cpu 68000
	include "Define/Macros (Assembler Specifc).asm" 

; ===========================================================================
; Simplifying macros and functions
	include	"Define/Macros (General).asm"

; ===========================================================================
; Equates section - Names for constants
	include	"Define/Constants.asm"

; ===========================================================================
; Equates section - Names for variables
	include	"Define/Variables.asm"

; ===========================================================================
; Expressing sprite mappings and DPLCs in a portable and human-readable form
SonicMappingsVer = 1
SonicDplcVer = 1
	include	"Define/Macros (Sprites).asm"

; ===========================================================================
; start of ROM

StartOfRom:
	if * <> 0
		fatal "StartOfRom was $\{*} but it should be 0"
	endif

Vectors:
		dc.l v_systemstack&$FFFFFF			; Initial stack pointer value
		dc.l EntryPoint					; Start of program
		dc.l BusError					; Bus error
		dc.l AddressError				; Address error (4)
		dc.l IllegalInstr				; Illegal instruction
		dc.l ZeroDivide					; Division by zero
		dc.l ChkInstr					; CHK exception
		dc.l TrapvInstr					; TRAPV exception (8)
		dc.l PrivilegeViol				; Privilege violation
		dc.l Trace					; TRACE exception
		dc.l Line1010Emu				; Line-A emulator
		dc.l Line1111Emu				; Line-F emulator (12)
		dc.l ErrorExcept				; Unused (reserved)
		dc.l ErrorExcept				; Unused (reserved)
		dc.l ErrorExcept				; Unused (reserved)
		dc.l ErrorExcept				; Unused (reserved) (16)
		dc.l ErrorExcept				; Unused (reserved)
		dc.l ErrorExcept				; Unused (reserved)
		dc.l ErrorExcept				; Unused (reserved)
		dc.l ErrorExcept				; Unused (reserved) (20)
		dc.l ErrorExcept				; Unused (reserved)
		dc.l ErrorExcept				; Unused (reserved)
		dc.l ErrorExcept				; Unused (reserved)
		dc.l ErrorExcept				; Unused (reserved) (24)
		dc.l ErrorExcept				; Spurious exception
		dc.l ErrorTrap					; IRQ level 1
		dc.l ErrorTrap					; IRQ level 2
		dc.l ErrorTrap					; IRQ level 3 (28)
		dc.l HBlank					; IRQ level 4 (horizontal retrace interrupt)
		dc.l ErrorTrap					; IRQ level 5
		dc.l VBlank					; IRQ level 6 (vertical retrace interrupt)
		dc.l ErrorTrap					; IRQ level 7 (32)
		dc.l ErrorTrap					; TRAP #00 exception
		dc.l ErrorTrap					; TRAP #01 exception
		dc.l ErrorTrap					; TRAP #02 exception
		dc.l ErrorTrap					; TRAP #03 exception (36)
		dc.l ErrorTrap					; TRAP #04 exception
		dc.l ErrorTrap					; TRAP #05 exception
		dc.l ErrorTrap					; TRAP #06 exception
		dc.l ErrorTrap					; TRAP #07 exception (40)
		dc.l ErrorTrap					; TRAP #08 exception
		dc.l ErrorTrap					; TRAP #09 exception
		dc.l ErrorTrap					; TRAP #10 exception
		dc.l ErrorTrap					; TRAP #11 exception (44)
		dc.l ErrorTrap					; TRAP #12 exception
		dc.l ErrorTrap					; TRAP #13 exception
		dc.l ErrorTrap					; TRAP #14 exception
		dc.l ErrorTrap					; TRAP #15 exception (48)
		dc.l ErrorTrap					; Unused (reserved)
		dc.l ErrorTrap					; Unused (reserved)
		dc.l ErrorTrap					; Unused (reserved)
		dc.l ErrorTrap					; Unused (reserved)
		dc.l ErrorTrap					; Unused (reserved)
		dc.l ErrorTrap					; Unused (reserved)
		dc.l ErrorTrap					; Unused (reserved)
		dc.l ErrorTrap					; Unused (reserved)
	if Revision<>2|FixBugs
		if (Revision=2)&(FixBugs=1)&(MOMPASS=1)
			warning "'Revision = 2' is unnecessary with 'FixBugs' enabled (use 'Revision = 1' instead)."
		endif
		dc.l ErrorTrap					; Unused (reserved)
		dc.l ErrorTrap					; Unused (reserved)
		dc.l ErrorTrap					; Unused (reserved)
		dc.l ErrorTrap					; Unused (reserved)
		dc.l ErrorTrap					; Unused (reserved)
	else
		; loc_E0:
	Rev02_SpikeBugFix:
		; Relocated code from Spik_Hurt. REVXB was a nasty hex-edit.
		; See Objects/36 Spikes/36 Spikes.asm for more info.
		move.l	obY(a0),d3				; get Sonic's Y-position (with subpixels)
		move.w	obVelY(a0),d0				; get Sonic's Y-velocity
		ext.l	d0					; extend velocity to longword
		asl.l	#8,d0					; shift velocity to upper word (16.16 fixed point)
		jmp	(Rev02_SpikeBugFix_Return).l		; return to main spikes logic
		dc.w ErrorTrap					; Unused (reserved)
	endif
		dc.l ErrorTrap					; Unused (reserved)
		dc.l ErrorTrap					; Unused (reserved)
		dc.l ErrorTrap					; Unused (reserved)

		dc.b "SEGA MEGA DRIVE "				; Hardware system ID (Console name)
		dc.b "(C)SEGA 1991.APR"				; Copyright holder and release date (generally year)
	rept 2
		 ; Name (identical for domestic and overseas version)
		dc.b "SONIC THE               HEDGEHOG                "
	endr

	if Revision=0
		dc.b "GM 00001009-00"				; Serial/version number (Rev 0)
	else
		dc.b "GM 00004049-01"				; Serial/version number (Rev non-0)
	endif

Checksum:		; Checksum is hardcoded to make it easier to check for ROM correctness
	if Revision=0
		dc.w $264A
	else
		dc.w $AFC7
	endif

		dc.b "J               "				; I/O support
		dc.l StartOfRom					; Start address of ROM
RomEndLoc:	dc.l EndOfRom-1					; End address of ROM
		dc.l $FF0000					; Start address of RAM
		dc.l $FFFFFF					; End address of RAM
	if EnableSRAM=1
		dc.b "RA", $A0+(BackupSRAM<<6)+(AddressSRAM<<3), $20 ; SRAM support
		dc.l sram_start					; SRAM start
		dc.l sram_end-1					; SRAM end
	else
		dc.b "    "
		dc.b "    "
		dc.b "    "
	endif
		dc.b "                                                    " ; Notes (unused, anything can be put in this space, but it has to be 52 bytes)
		dc.b "JUE             "				; Region (Country code)
EndOfHeader:

; ===========================================================================
; Crash/Freeze the 68000. Unlike Sonic 2, Sonic 1 uses the 68000 for playing music, so it stops too
ErrorTrap:
		nop						; no operation
		nop						; ''
		bra.s	ErrorTrap				; loop forever
; ===========================================================================

; ---------------------------------------------------------------------------
; Entry point for the game on boot or soft-reset
; (This section from a standard Mega Drive devkit library)
; ---------------------------------------------------------------------------

EntryPoint:
		tst.l	(port_1_control_hi).l			; test port A & B control registers
		bne.s	PortA_Ok				; if either of them are already initialized, branch
		tst.w	(expansion_control_hi).l		; test port C control register
PortA_Ok:	bne.s	SkipSetup				; if any port was already initialized, skip the VDP and Z80 setup code (this is a soft-reset)

		lea	SetupValues(pc),a5			; load setup values array address
		movem.w	(a5)+,d5-d7				; d5 = VDP register start number; d6 = size of RAM/4; d7 = VDP register diff
		movem.l	(a5)+,a0-a4				; a0 = start of Z80 RAM; a1 = Z80 bus request; a2 = Z80 reset; a3 = VDP data; a4 = VDP control

		move.b	-$10FF(a1),d0				; get hardware version (from $A10001)
		andi.b	#$F,d0					; only look at Mega Drive version
		beq.s	SkipSecurity				; if the console has no TMSS, skip the security stuff
		move.l	#'SEGA',$2F00(a1)			; write "SEGA" to TMSS security register ($A14000)

SkipSecurity:
		move.w	(a4),d0					; clear write-pending flag in VDP (prevents issues if 68k was reset while writing a command to VDP)
		moveq	#0,d0					; clear d0
		movea.l	d0,a6					; clear a6
		move.l	a6,usp					; set usp to $0

		moveq	#SetupValues_VDP_End-SetupValues_VDP-1,d1 ; write to all VDP registers
VDPInitLoop:	move.b	(a5)+,d5				; add $8000 to value
		move.w	d5,(a4)					; write value to VDP register
		add.w	d7,d5					; next register
		dbf	d1,VDPInitLoop				; loop until all registers are set up

		move.l	(a5)+,(a4)				; write DMA destination to VDP (VRAM 0000)
		move.w	d0,(a3)					; set DMA fill value to 00 (DMA starts here, clears entire VRAM)

		move.w	d7,(a1)					; stop the Z80
		move.w	d7,(a2)					; reset the Z80
WaitForZ80:	btst	d0,(a1)					; has the Z80 stopped?
		bne.s	WaitForZ80				; if not, loop until it has

		moveq	#SetupValues_Z80_End-SetupValues_Z80-1,d2 ; write all Z80 boot code
Z80InitLoop:	move.b	(a5)+,(a0)+				; write boot code to Z80 RAM
		dbf	d2,Z80InitLoop				; loop until all boot code has been written

		move.w	d0,(a2)					; set Z80 reset on
		move.w	d0,(a1)					; set Z80 stop off
		move.w	d7,(a2)					; set Z80 reset off

ClrRAMLoop:	move.l	d0,-(a6)				; clear 4 bytes of RAM
		dbf	d6,ClrRAMLoop				; repeat until the entire RAM is cleared

		move.l	(a5)+,(a4)				; set VDP display mode and increment mode

		move.l	(a5)+,(a4)				; set VDP to CRAM write
		moveq	#(v_palette_end-v_palette)/4-1,d3	; set repeat times to cover full CRAM
ClrCRAMLoop:	move.l	d0,(a3)					; clear 2 colors
		dbf	d3,ClrCRAMLoop				; repeat until the entire CRAM is clear

		move.l	(a5)+,(a4)				; set VDP to VSRAM write
		moveq	#$14-1,d4
ClrVSRAMLoop:	move.l	d0,(a3)					; clear 4 bytes of VSRAM
		dbf	d4,ClrVSRAMLoop				; repeat until the entire VSRAM is clear

		moveq	#SetupValues_PSG_End-SetupValues_PSG-1,d5 ; write to all PSG registers
PSGInitLoop:	move.b	(a5)+,$11(a3)				; write PSG volume values to PSG port ($C00011)
		dbf	d5,PSGInitLoop				; repeat for all channels

		move.w	d0,(a2)					; set Z80 reset on
		movem.l	(a6),d0-a6				; clear all registers
		disable_ints					; disable interrupts

SkipSetup:
		bra.s	GameProgram				; begin actual game
; ===========================================================================

SetupValues:	dc.w vreg_mode1					; VDP register start number
		dc.w (v_ram_end-v_ram_start_def/4)-1		; size of RAM/4 ($3FFF)
		dc.w $100					; VDP register diff

		dc.l z80_ram					; start of Z80 RAM
		dc.l z80_bus_request				; Z80 bus request
		dc.l z80_reset					; Z80 reset
		dc.l vdp_data_port				; VDP data
		dc.l vdp_control_port				; VDP control

	SetupValues_VDP:
		; Note that most of these are immediately overwritten again in VDPSetupArray
		dc.b %000100					; VDP $80 - 8-colour mode
		dc.b %00010100					; VDP $81 - Mega Drive mode, DMA enable
		dc.b ($C000>>10)				; VDP $82 - foreground nametable address
		dc.b ($F000>>10)				; VDP $83 - window nametable address
		dc.b ($E000>>13)				; VDP $84 - background nametable address
		dc.b ($D800>>9)					; VDP $85 - sprite table address
		dc.b 0						; VDP $86 - unused
		dc.b 0<<4|0					; VDP $87 - background colour
		dc.b 0						; VDP $88 - unused
		dc.b 0						; VDP $89 - unused
		dc.b 255					; VDP $8A - HBlank register
		dc.b %0000					; VDP $8B - full screen scroll
		dc.b %10000001					; VDP $8C - 40 cell display
		dc.b ($DC00>>10)				; VDP $8D - h-scroll table address
		dc.b 0						; VDP $8E - unused
		dc.b 1						; VDP $8F - VDP increment
		dc.b %000001					; VDP $90 - 64 cell h-scroll size
		dc.b 0						; VDP $91 - window h position
		dc.b 0						; VDP $92 - window v position
		dc.w $FFFF					; VDP $93/94 - DMA length
		dc.w $0000					; VDP $95/96 - DMA source
		dc.b $80					; VDP $97 - DMA fill VRAM
	SetupValues_VDP_End:
		dc.l $40000080					; DMA fill destination (VRAM 0000)

	SetupValues_Z80:
		; Z80 instructions (not the sound driver; that gets loaded later)
		save
		CPU Z80						; start assembling Z80 code
		phase 0						; pretend we're at address 0

		xor	a					; clear a to 0
		ld	bc,((z80_ram_end-z80_ram)-zStartupCodeEndLoc)-1 ; prepare to loop this many times
		ld	de,zStartupCodeEndLoc+1			; initial destination address
		ld	hl,zStartupCodeEndLoc			; initial source address
		ld	sp,hl					; set the address the stack starts at
		ld	(hl),a					; set first byte of the stack to 0
		ldir						; loop to fill the stack (entire remaining available Z80 RAM) with 0
		pop	ix					; clear ix
		pop	iy					; clear iy
		ld	i,a					; clear i
		ld	r,a					; clear r
		pop	de					; clear de
		pop	hl					; clear hl
		pop	af					; clear af
		ex	af,af'					; swap af with af'
		exx						; swap bc/de/hl with their shadow registers too
		pop	bc					; clear bc
		pop	de					; clear de
		pop	hl					; clear hl
		pop	af					; clear af
		ld	sp,hl					; clear sp
		di						; clear iff1 (for interrupt handler)
		im	1					; interrupt handling mode = 1
		ld	(hl),0E9h				; replace the first instruction with a jump to itself
		jp	(hl)	 				; jump to the first instruction (to stay there forever)
	zStartupCodeEndLoc:
		dephase						; stop pretending
		restore
		padding off					; unfortunately our flags got reset so we have to set them again...
	SetupValues_Z80_End:

		dc.w vreg_mode2|%00000100			; VDP display mode
		dc.w vreg_autoinc|2				; VDP increment
		dc.l $C0000000					; CRAM write mode
		dc.l $40000010					; VSRAM address 0

	SetupValues_PSG:
		dc.b $9F, $BF, $DF, $FF				; values for PSG channel volumes
	SetupValues_PSG_End:
; End of SetupValues


; ===========================================================================
; ---------------------------------------------------------------------------
; Proper game entry point for Sonic the Hedgehog after initialization
; ---------------------------------------------------------------------------

GameProgram:
		tst.w	(vdp_control_port).l			; clear write-pending flag in VDP (prevents issues if 68k was reset while writing a command to VDP)
		btst	#6,(expansion_control).l		; has port C been initialized?
		beq.s	CheckSumCheck				; if not, branch
		cmpi.l	#'init',(v_init).w			; has checksum routine already run?
		beq.w	GameInit				; if yes, branch

CheckSumCheck:
	if SkipChecksumCheck=0
		movea.l	#EndOfHeader,a0				; start checking bytes after the header ($200)
		movea.l	#RomEndLoc,a1				; stop at end of ROM
		move.l	(a1),d0					; retrieve long of ROM end
		moveq	#0,d1					; clear d1
	.loop:	add.w	(a0)+,d1				; add next byte value of ROM word
		cmp.l	a0,d0					; has iterator reached end of ROM?
		bhs.s	.loop					; if not, loop until so

		movea.l	#Checksum,a1				; read the checksum
		cmp.w	(a1),d1					; compare calculated value with checksum in ROM header
		bne.w	CheckSumError				; if they don't match, a checksum error has occurred
	endif

CheckSumOk:
		lea	(v_crossresetram).w,a6			; load cross-reset RAM location
		moveq	#0,d7					; overwrite with 0
		move.w	#(v_ram_end-v_crossresetram)/4-1,d6	; write to all of cross-reset RAM ($FE00-$FFFF)
.clearRAM:	move.l	d7,(a6)+				; clear RAM
		dbf	d6,.clearRAM				; loop until done

		move.b	(console_version).l,d0			; get hardware information from console
		andi.b	#%11000000,d0				; filter to only overseas flag and PAL flag
		move.b	d0,(v_megadrive).w			; store region settings

		move.l	#'init',(v_init).w			; set flag so checksum won't run again

GameInit:
		lea	(v_ram_start).l,a6			; load start location of RAM
		moveq	#0,d7					; overwrite with 0
		move.w	#(v_crossresetram-v_ram_start_def)/4-1,d6 ; write to all of RAM except cross-reset RAM ($0000-$FDFF)
.clearRAM:	move.l	d7,(a6)+				; clear RAM
		dbf	d6,.clearRAM				; loop until done

		bsr.w	VDPSetupGame				; initialize (proper) VDP registers
		bsr.w	DACDriverLoad				; initialize Z80 DAC driver
		bsr.w	JoypadInit				; initialize controller ports
		move.b	#id_Sega,(v_gamemode).w			; set first Game Mode to Sega Screen

	if CheatsEnabled=1
		moveq	#1,d0					; enable all cheats by default
		move.b	d0,(f_levselcheat).w			; enable level select cheat
		move.b	d0,(f_slomocheat).w			; enable slow-motion cheat
		move.b	d0,(f_debugcheat).w			; enable debug mode cheat
		move.b	d0,(f_creditscheat).w			; enable hidden Japanese credits cheat
	endif

MainGameLoop:
		move.b	(v_gamemode).w,d0			; load Game Mode
		andi.w	#$1C,d0					; limit Game Mode value to $1C max (change to a maximum of 7C to add more game modes)
		jsr	GameModeArray(pc,d0.w)			; jump to apt location in ROM
		bra.s	MainGameLoop				; loop indefinitely

; ---------------------------------------------------------------------------
; Main game mode array
; ---------------------------------------------------------------------------

GameModeArray:

gmptr:		macro gamemode,{INTLABEL}
__LABEL__:	label	*-GameModeArray
		bra.w	gamemode
		endm

id_Sega:	gmptr	GM_Sega					; Sega Screen ($00)
id_Title:	gmptr	GM_Title				; Title Screen ($04)
id_Demo:	gmptr	GM_Level				; Demo Mode ($08)
id_Level:	gmptr	GM_Level				; Normal Level ($0C)
id_Special:	gmptr	GM_Special				; Special Stage ($10)
id_Continue:	gmptr	GM_Continue				; Continue Screen ($14)
id_Ending:	gmptr	GM_Ending				; End of game sequence ($18)
id_Credits:	gmptr	GM_Credits				; Credits ($1C)

		rts						; redundant rts


; ===========================================================================
; ---------------------------------------------------------------------------
; Error handler
; ---------------------------------------------------------------------------

	if SkipChecksumCheck=0
CheckSumError:
		bsr.w	VDPSetupGame				; restore all VDP registers
		move.l	#$C0000000,(vdp_control_port).l		; set VDP to CRAM write
		moveq	#(v_palette_end-v_palette)/2-1,d7	; write to entire palette
.fillred:	move.w	#cRed,(vdp_data_port).l			; fill palette with red
		dbf	d7,.fillred				; repeat until CRAM is filled
		bra.s	*					; endless loop to itself
	endif
; ===========================================================================

BusError:	move.b	#2,(v_errortype).w			; set error code
		bra.s	ErrorHandler_WithAddress		; continue to handler (with pc value)
; ---------------------------------------------------------------------------
AddressError:	move.b	#4,(v_errortype).w			; set error code
		bra.s	ErrorHandler_WithAddress		; continue to handler (with pc value)
; ---------------------------------------------------------------------------
IllegalInstr:	move.b	#6,(v_errortype).w			; set error code
		addq.l	#2,2(sp)				; skip over illegal instruction on recovery
		bra.s	ErrorHandler_WithoutAddress		; continue to handler
; ---------------------------------------------------------------------------
ZeroDivide:	move.b	#8,(v_errortype).w			; set error code
		bra.s	ErrorHandler_WithoutAddress		; continue to handler
; ---------------------------------------------------------------------------
ChkInstr:	move.b	#$A,(v_errortype).w			; set error code
		bra.s	ErrorHandler_WithoutAddress		; continue to handler
; ---------------------------------------------------------------------------
TrapvInstr:	move.b	#$C,(v_errortype).w			; set error code
		bra.s	ErrorHandler_WithoutAddress		; continue to handler
; ---------------------------------------------------------------------------
PrivilegeViol:	move.b	#$E,(v_errortype).w			; set error code
		bra.s	ErrorHandler_WithoutAddress		; continue to handler
; ---------------------------------------------------------------------------
Trace:		move.b	#$10,(v_errortype).w			; set error code
		bra.s	ErrorHandler_WithoutAddress		; continue to handler
; ---------------------------------------------------------------------------
Line1010Emu:	move.b	#$12,(v_errortype).w			; set error code
		addq.l	#2,2(sp)				; skip over illegal instruction on recovery
		bra.s	ErrorHandler_WithoutAddress		; continue to handler
; ---------------------------------------------------------------------------
Line1111Emu:	move.b	#$14,(v_errortype).w			; set error code
		addq.l	#2,2(sp)				; skip over illegal instruction on recovery
		bra.s	ErrorHandler_WithoutAddress		; continue to handler
; ---------------------------------------------------------------------------
ErrorExcept:	move.b	#0,(v_errortype).w			; set error code (generic fallback error)
		bra.s	ErrorHandler_WithoutAddress		; continue to handler
; ===========================================================================

; loc_43A:
ErrorHandler_WithAddress:
		disable_ints					; disable interrupts so we stay here
		addq.w	#2,sp					; skip sr value
		move.l	(sp)+,(v_spbuffer).w			; retrieve pc value from before the crash
		addq.w	#2,sp					; skip second sr value
		movem.l	d0-a7,(v_regbuffer).w			; backup all registers values from before the crash

		bsr.w	ShowErrorMessage			; write error text to screen
		move.l	2(sp),d0				; get error address
		bsr.w	ShowErrorValue				; write value to screen
		move.l	(v_spbuffer).w,d0			; get origin pc value
		bsr.w	ShowErrorValue				; write value to screen
		bra.s	ErrorHandler_TryRecovery		; skip over
; ===========================================================================

; loc_462:
ErrorHandler_WithoutAddress:
		disable_ints					; disable interrupts so we stay here
		movem.l	d0-a7,(v_regbuffer).w			; backup all registers values from before the crash

		bsr.w	ShowErrorMessage			; write error text to screen
		move.l	2(sp),d0				; load error address
		bsr.w	ShowErrorValue				; write value to screen
; ---------------------------------------------------------------------------

; loc_478:
ErrorHandler_TryRecovery:
		bsr.w	ErrorWaitForC				; loop until C has been pressed
		movem.l	(v_regbuffer).w,d0-a7			; restore registers before exception
		enable_ints					; enable ints
		rte						; try resuming normal operation (may or may not work, depending on type of crash)
; ===========================================================================

ShowErrorMessage:
		lea	(vdp_data_port).l,a6			; set VDP data port
		locVRAM	ArtTile_Error_Handler_Font*tile_size	; set target VRAM location for error text font
		lea	(Art_Text).l,a0				; load error text font
		move.w	#(Art_Text_end-Art_Text-tile_size)/2-1,d1 ; load font (strangely, this does not load the final tile)
.loadgfx:	move.w	(a0)+,(a6)				; dump graphics to VRAM
		dbf	d1,.loadgfx				; loop until font has been loaded

		moveq	#0,d0					; clear d0
		move.b	(v_errortype).w,d0			; load error code
		move.w	ErrorText(pc,d0.w),d0			; find offset in error texts array
		lea	ErrorText(pc,d0.w),a0			; load error text for error code
		locVRAM	vram_fg+(12*$80)+(2*2)			; write error message directly to plane A nametable (row 12 + column 2 = $C04)
		moveq	#19-1,d1				; number of characters in error text message (minus 1)
.showchars:	moveq	#0,d0					; clear d0
		move.b	(a0)+,d0				; get next character from error text
		addi.w	#-'0'+ArtTile_Error_Handler_Font,d0	; rebase from ASCII to a VRAM index
		move.w	d0,(a6)					; write to VRAM
		dbf	d1,.showchars				; repeat for number of characters
		rts						; return
; End of function ShowErrorMessage
; ===========================================================================

ErrorText:	dc.w .exception-ErrorText			; 0
		dc.w .bus-ErrorText				; 2
		dc.w .address-ErrorText				; 4
		dc.w .illinstruct-ErrorText			; 6
		dc.w .zerodivide-ErrorText			; 8
		dc.w .chkinstruct-ErrorText			; $A
		dc.w .trapv-ErrorText				; $C
		dc.w .privilege-ErrorText			; $E
		dc.w .trace-ErrorText				; $10
		dc.w .line1010-ErrorText			; $12
		dc.w .line1111-ErrorText			; $14

.exception:	dc.b "ERROR EXCEPTION    "
.bus:		dc.b "BUS ERROR          "
.address:	dc.b "ADDRESS ERROR      "
.illinstruct:	dc.b "ILLEGAL INSTRUCTION"
.zerodivide:	dc.b "@ERO DIVIDE        "			; Note: @ is Z due to the font arrangement
.chkinstruct:	dc.b "CHK INSTRUCTION    "
.trapv:		dc.b "TRAPV INSTRUCTION  "
.privilege:	dc.b "PRIVILEGE VIOLATION"
.trace:		dc.b "TRACE              "
.line1010:	dc.b "LINE 1010 EMULATOR "
.line1111:	dc.b "LINE 1111 EMULATOR "
		even

; ===========================================================================

; Input: d0 = number to write (8 digits)
ShowErrorValue:
		move.w	#ArtTile_Error_Handler_Font+$A,(a6)	; display "$" symbol
		moveq	#8-1,d2					; write 8 digits
	.loop:	rol.l	#4,d0					; shift to next digit
		bsr.s	.writeDigit				; write number to VRAM
		dbf	d2,.loop				; loop until done
		rts						; return
; ---------------------------------------------------------------------------

.writeDigit:
		move.w	d0,d1					; make a copy (need to preserve d0 for the loop)
		andi.w	#$F,d1					; limit digit to one nybble
		cmpi.w	#$A,d1					; is digit $A-$F?
		blo.s	.write					; if not, branch
		addq.w	#7,d1					; adjust tile offset for hex letters
	.write:	addi.w	#ArtTile_Error_Handler_Font,d1		; add art tile offset
		move.w	d1,(a6)					; write to VRAM nametable
		rts						; return
; End of function ShowErrorValue
; ===========================================================================

ErrorWaitForC:
		bsr.w	ReadJoypads				; keep reading joypads
		cmpi.b	#btnC,(v_jpadpress1).w			; has button C been pressed?
		bne.w	ErrorWaitForC				; if not, keep looping
		rts						; return to try recovering execution
; End of function ErrorWaitForC
; End of error handler (as a whole)


; ===========================================================================
; ---------------------------------------------------------------------------
; Uncompressed art text for debug mode, level select, and errors
; (formerly "menutext.bin")
; ---------------------------------------------------------------------------

Art_Text:	bincludeEndMarker	"Modes/Cells/Level Select & Debug Text.unc"


; ===========================================================================
; ---------------------------------------------------------------------------
; Vertical interrupt
; ---------------------------------------------------------------------------
id_VBlank_Lag:		equ $00					; (lag frame)
id_VBlank_Sega:		equ $02					; Sega Screen
id_VBlank_Title:	equ $04					; Title Screen, Credits
id_VBlank_Unused06:	equ $06					; (unused)
id_VBlank_Levels:	equ $08					; Levels, Demos
id_VBlank_SpecialStage:	equ $0A					; Special Stages
id_VBlank_TitleCards:	equ $0C					; Title Cards
id_VBlank_Unused0E:	equ $0E					; (unused)
id_VBlank_Paused:	equ $10					; Paused
id_VBlank_PaletteFade:	equ $12					; Palette Fade
id_VBlank_SegaPCM:	equ $14					; Sega Screen PCM
id_VBlank_Continue:	equ $16					; Continue Screen
id_VBlank_Ending:	equ $18					; Ending Sequence
; ---------------------------------------------------------------------------

; loc_B10: VBla:
VBlank:
		movem.l	d0-a6,-(sp)				; backup all registers except stack pointer (a7)

		tst.b	(v_vblank_routine).w			; was a VBlank routine set?
		beq.s	VBlank_Lag				; if not, this is a lag frame, branch

		move.w	(vdp_control_port).l,d0			; clear write-pending flag in VDP (prevents issues if 68k was reset while writing a command to VDP)
		move.l	#$40000010,(vdp_control_port).l		; set VDP to VSRAM write mode
		move.l	(v_scrposy_vdp).w,(vdp_data_port).l	; send screen y-axis pos. to VSRAM

		; Wait here in a loop doing nothing for a while. This seems to be a pretty harsh attempt
		; to push CRAM dots outside of the visible view area, due to Sonic 1 not using all
		; the available screen space PAL offers, as they would otherwise be seen at the bottom.
		btst	#6,(v_megadrive).w			; is Mega Drive PAL?
		beq.s	.notPAL					; if not, branch
		move.w	#$700,d0				; set to waste a bunch of cycles
	.waitPAL:
		dbf	d0,.waitPAL				; loop until cycles have been wasted

.notPAL:
		move.b	(v_vblank_routine).w,d0			; copy specified VBlank routine to d0
		move.b	#id_VBlank_Lag,(v_vblank_routine).w	; reset actual routine to lag frame (which ideally should get set again in the next frame)
		move.w	#1,(f_hblank_pal).w			; set HBlank palette swap flag (only relevant for LZ)
		andi.w	#$3E,d0					; mask out irrelevant bits in VBlank routine
		move.w	VBlank_Index(pc,d0.w),d0		; load address to relevant VBlank routine
		jsr	VBlank_Index(pc,d0.w)			; jump to VBlank routine and then return here

VBlank_Music:
		jsr	(UpdateMusic).l				; run sound driver to advance music

VBlank_Exit:
		addq.l	#1,(v_vblank_count).w			; increment VBlank counter
		movem.l	(sp)+,d0-a6				; restore all backed-up registers
		rte						; return from interrupt and resume normal operation

; ===========================================================================
; VBla_Index:
VBlank_Index:	dc.w VBlank_Lag-VBlank_Index			; $00 - (lag frame)
		dc.w VBlank_Sega-VBlank_Index			; $02 - Sega Screen
		dc.w VBlank_Title-VBlank_Index			; $04 - Title Screen, Credits, Try Again
		dc.w VBlank_Unused06-VBlank_Index		; $06 - (unused)
		dc.w VBlank_Levels-VBlank_Index			; $08 - Levels, Demos
		dc.w VBlank_SpecialStage-VBlank_Index		; $0A - Special Stages
		dc.w VBlank_TitleCards-VBlank_Index		; $0C - Title Cards
		dc.w VBlank_Unused0E-VBlank_Index		; $0E - (unused)
		dc.w VBlank_Paused-VBlank_Index			; $10 - Paused
		dc.w VBlank_PaletteFade-VBlank_Index		; $12 - Palette Fade
		dc.w VBlank_SegaPCM-VBlank_Index		; $14 - Sega Screen PCM
		dc.w VBlank_Continue-VBlank_Index		; $16 - Continue Screen, SS Finish
		dc.w VBlank_Ending-VBlank_Index			; $18 - Ending Sequence
; ===========================================================================

; ===========================================================================
; ---------------------------------------------------------------------------
; VBlank 00 - Lag frame (VBlank occurred before call to WaitForVBlank)
; ---------------------------------------------------------------------------

; loc_B88: VBla_00:
VBlank_Lag:
		cmpi.b	#$80+id_Level,(v_gamemode).w		; is pre level sequence active?
		beq.s	.isLevel				; if not, just update sound driver and resume operation
		cmpi.b	#id_Level,(v_gamemode).w		; is game on a level?
		bne.w	VBlank_Music				; if not, just update sound driver and resume operation

.isLevel:
		cmpi.b	#id_LZ,(v_zone).w			; is level LZ?
		bne.w	VBlank_Music				; if not, just update sound driver and resume operation

		; --- A lag frame has occurred while in Labyrinth Zone ---

		move.w	(vdp_control_port).l,d0			; clear write-pending flag in VDP (prevents issues if 68k was reset while writing a command to VDP)

		; Same as in the opening block of the VBlank routine, this time during a lag frame.
		; This only happens if the level is LZ (note, Sonic 2/3/&K would change this so it runs in any level).
		btst	#6,(v_megadrive).w			; is Mega Drive PAL?
		beq.s	.paletteTransfer			; if not, branch
		move.w	#$700,d0				; set to waste a bunch of cycles
	.waitPAL:
		dbf	d0,.waitPAL				; loop until cycles have been wasted

.paletteTransfer:
		move.w	#1,(f_hblank_pal).w			; set HBlank flag
		stopZ80						; stop Z80 for CRAM transfers
		waitZ80						; wait until Z80 has stopped
		tst.b	(f_wtr_state).w				; is the screen completely underwater?
		bne.s	.waterAbove 				; if not, branch
		writeCRAM	v_palette,0			; write regular palette buffer to CRAM
		bra.s	.waterBelow				; skip over
	.waterAbove:
		writeCRAM	v_palette_water,0		; write water palette buffer to CRAM
	.waterBelow:
		move.w	(v_hblank_hreg).w,(a5)			; write HBlank trigger scan line for water palette swap to VDP
		startZ80					; restart Z80

		bra.w	VBlank_Music				; branch back to update sound driver and resume operation

; ===========================================================================
; ---------------------------------------------------------------------------
; VBlank 02 - Sega Screen
; ---------------------------------------------------------------------------

; loc_C32: VBla_02:
VBlank_Sega:
		bsr.w	VBlank_StandardTransfers		; do standard screen transfers
		; fall-through...

; ---------------------------------------------------------------------------
; VBlank 14 - Sega Screen while the PCM sample is playing
; ---------------------------------------------------------------------------

; loc_C36: VBla_14:
VBlank_SegaPCM:
		tst.w	(v_generictimer).w			; is generic timer set?
		beq.w	.end					; if not, branch
		subq.w	#1,(v_generictimer).w			; decrement generic timer
	.end:
		rts						; return

; ===========================================================================
; ---------------------------------------------------------------------------
; VBlank 04 - Title Screen, Level Select, Credits, "Try Again" screen
; ---------------------------------------------------------------------------

; loc_C44: VBla_04:
VBlank_Title:
		bsr.w	VBlank_StandardTransfers		; do standard screen transfers
		bsr.w	LoadTilesAsYouMove_BGOnly		; update background tiles as title screen scrolls
		bsr.w	ProcessPLC_9Tiles			; decompress up to 9 Nemesis-compressed tiles

		tst.w	(v_generictimer).w			; is generic timer set?
		beq.w	.end					; if not, branch
		subq.w	#1,(v_generictimer).w			; decrement generic timer
	.end:
		rts						; return

; ===========================================================================
; ---------------------------------------------------------------------------
; VBlank 06 - Unused and unknown purpose
; ---------------------------------------------------------------------------

; loc_C5E: VBla_06:
VBlank_Unused06:
		bsr.w	VBlank_StandardTransfers		; do standard screen transfers...
		rts						; ...and nothing else

; ===========================================================================
; ---------------------------------------------------------------------------
; VBlank 10 - While game is paused
; ---------------------------------------------------------------------------

; loc_C64: VBla_10:
VBlank_Paused:
		cmpi.b	#id_Special,(v_gamemode).w		; is game on special stage?
		beq.w	VBlank_SpecialStage			; if yes, branch
		; fall-through...

; ---------------------------------------------------------------------------
; VBlank 08 - Levels and Demos
; ---------------------------------------------------------------------------

; loc_C6E: VBla_08:
VBlank_Levels:
		stopZ80						; request Z80 stop
		waitZ80						; wait until Z80 has stopped
		bsr.w	ReadJoypads				; read joypads and update buffered inputs in RAM

		tst.b	(f_wtr_state).w				; is the screen completely underwater?
		bne.s	.waterAbove 				; if not, branch
		writeCRAM	v_palette,0			; write regular palette buffer to CRAM
		bra.s	.waterBelow				; skip over
	.waterAbove:
		writeCRAM	v_palette_water,0		; write water palette buffer to CRAM
	.waterBelow:
		move.w	(v_hblank_hreg).w,(a5)			; write HBlank trigger scan line for water palette swap to VDP

		writeVRAM	v_hscrolltablebuffer,vram_hscroll ; transfer H-scroll buffer table to actual H-scroll VRAM
		writeVRAM	v_spritetablebuffer,vram_sprites  ; transfer sprite buffer table to actual sprites VRAM

		tst.b	(f_sonframechg).w			; has Sonic's sprite changed?
		beq.s	.nochg					; if not, branch
		writeVRAM	v_sgfx_buffer,ArtTile_Sonic*tile_size ; load new Sonic gfx
		move.b	#0,(f_sonframechg).w			; clear Sonic gfx update flag
	.nochg:

		startZ80					; restart Z80

		movem.l	(v_screenposx).w,d0-d7			; copy everything from v_screenposx to v_bg3screenposy...
		movem.l	d0-d7,(v_screenposx_dup).w		; ...to backup RAM (used in LoadTilesAsYouMove)
		movem.l	(v_fg_scroll_flags).w,d0-d1		; copy FG and BG scroll flags...
		movem.l	d0-d1,(v_fg_scroll_flags_dup).w		; ...to backup RAM

		; The following code handles an awkward visual glitch for the LZ water surface.
		; If the surface is near the top of the screen (within 96 pixels), the VDP would not have
		; enough time to do all the transfers in VBlank_UpdateScreen before the palette needs to get
		; changed for the water. Without this special check, the water surface would violently flicker
		; whenever it's near the top of the screen. It's a rather dirty workaround, but it works.
		cmpi.b	#96,(v_hblank_line).w			; is LZ water surface within 96 pixels of the top of the screen?
		bhs.s	VBlank_UpdateScreen			; if not, do screen updates now
		move.b	#1,(f_doupdatesinhblank).w		; otherwise, we don't have enough time to do them now before HBlank hits, defer updates to then
		addq.l	#4,sp					; skip return address (i.e. postpone updating the sound driver as well)
		bra.w	VBlank_Exit				; go straight back to to the VBlank exit

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to update various screen elements during interrupts.
; Also deducts the generic timer that controls the length of a Demo.
; ---------------------------------------------------------------------------

; Demo_Time: VBla_UpdateScreen:
VBlank_UpdateScreen:
		bsr.w	LoadTilesAsYouMove			; update level tiles while screen is moving
		jsr	(AnimateLevelGfx).l			; updated animated tiles
		jsr	(HUD_Update).l				; update HUD data
		bsr.w	ProcessPLC_3Tiles			; decompress up to 3 Nemesis-compressed tiles (instead of the usual 9)

		tst.w	(v_generictimer).w			; is generic timer set?
		beq.w	.end					; if not, branch
		subq.w	#1,(v_generictimer).w			; decrement generic timer
	.end:
		rts						; return
; End of function VBlank_UpdateScreen

; ===========================================================================
; ---------------------------------------------------------------------------
; VBlank 0A - Special Stages
; ---------------------------------------------------------------------------

; loc_DA6: VBla_0A:
VBlank_SpecialStage:
		stopZ80						; request Z80 stop
		waitZ80						; wait until Z80 has stopped
		bsr.w	ReadJoypads				; read joypads and update buffered inputs in RAM
		writeCRAM	v_palette,0			; write regular palette buffer to CRAM
		writeVRAM	v_spritetablebuffer,vram_sprites  ; transfer sprite buffer table to actual sprites VRAM
		writeVRAM	v_hscrolltablebuffer,vram_hscroll ; transfer H-scroll buffer table to actual H-scroll VRAM
		startZ80					; restart Z80

		bsr.w	PalCycle_SS				; advance special stage palette cycle and animate bird/fish graphics

		tst.b	(f_sonframechg).w			; has Sonic's sprite changed?
		beq.s	.nochg					; if not, branch
		writeVRAM	v_sgfx_buffer,ArtTile_Sonic*tile_size ; load new Sonic gfx
		move.b	#0,(f_sonframechg).w			; clear Sonic gfx update flag
	.nochg:

		tst.w	(v_generictimer).w			; is generic timer set?
		beq.w	.end					; if not, branch
		subq.w	#1,(v_generictimer).w			; decrement generic timer
	.end:
		rts						; return

; ===========================================================================
; ---------------------------------------------------------------------------
; VBlank 0C - While title cards are displayed (Levels and SS Results)
; VBlank 18 - During the Ending Sequence
; ---------------------------------------------------------------------------

; loc_E72: VBla_0C: VBla_18:
VBlank_TitleCards:
VBlank_Ending:
		stopZ80						; request Z80 stop
		waitZ80						; wait until Z80 has stopped
		bsr.w	ReadJoypads				; read joypads and update buffered inputs in RAM

		tst.b	(f_wtr_state).w				; is the screen completely underwater?
		bne.s	.waterAbove 				; if not, branch
		writeCRAM	v_palette,0			; write regular palette buffer to CRAM
		bra.s	.waterBelow				; skip over
	.waterAbove:
		writeCRAM	v_palette_water,0		; write water palette buffer to CRAM
	.waterBelow:
		move.w	(v_hblank_hreg).w,(a5)			; write HBlank trigger scan line for water palette swap to VDP

		writeVRAM	v_hscrolltablebuffer,vram_hscroll ; transfer H-scroll buffer table to actual H-scroll VRAM
		writeVRAM	v_spritetablebuffer,vram_sprites  ; transfer sprite buffer table to actual sprites VRAM

		tst.b	(f_sonframechg).w			; has Sonic's sprite changed?
		beq.s	.nochg					; if not, branch
		writeVRAM	v_sgfx_buffer,ArtTile_Sonic*tile_size ; load new Sonic gfx
		move.b	#0,(f_sonframechg).w			; clear Sonic gfx update flag
	.nochg:

		startZ80					; restart Z80

		movem.l	(v_screenposx).w,d0-d7			; copy everything from v_screenposx to v_bg3screenposy...
		movem.l	d0-d7,(v_screenposx_dup).w		; ...to backup RAM (used in LoadTilesAsYouMove)
		movem.l	(v_fg_scroll_flags).w,d0-d1		; copy FG and BG scroll flags...
		movem.l	d0-d1,(v_fg_scroll_flags_dup).w		; ...to backup RAM

		bsr.w	LoadTilesAsYouMove			; update rendered
		jsr	(AnimateLevelGfx).l			; animate uncompressed level graphics (e.g. MZ lava)
		jsr	(HUD_Update).l				; update HUD numbers
		bsr.w	ProcessPLC_9Tiles			; decompress up to 9 Nemesis-compressed tiles
		rts						; return

; ===========================================================================
; ---------------------------------------------------------------------------
; VBlank 0E - Unused (possibly once used as a lag frame counter?)
; ---------------------------------------------------------------------------

; loc_F8A: VBla_0E:
VBlank_Unused0E:
		bsr.w	VBlank_StandardTransfers		; do standard screen transfers
		addq.b	#1,(v_vblank_0e_counter).w		; increment some counter (unused besides this one write...)
		move.b	#id_VBlank_Unused0E,(v_vblank_routine).w ; set itself to land back here again if not further altered
		rts						; return

; ===========================================================================
; ---------------------------------------------------------------------------
; VBlank 12 - During palette fades
; ---------------------------------------------------------------------------

; loc_F9A: VBla_12:
VBlank_PaletteFade:
		bsr.w	VBlank_StandardTransfers		; do standard screen transfers
		move.w	(v_hblank_hreg).w,(a5)			; write HBlank trigger scan line for water palette swap to VDP
		bra.w	ProcessPLC_9Tiles			; decompress up to 9 Nemesis-compressed tiles

; ===========================================================================
; ---------------------------------------------------------------------------
; VBlank 16 - Continue Screen and Special Stage finish loop
; ---------------------------------------------------------------------------

; loc_FA6: VBla_16:
VBlank_Continue:
		stopZ80						; request Z80 stop
		waitZ80						; wait until Z80 has stopped
		bsr.w	ReadJoypads				; read joypads and update buffered inputs in RAM

		writeCRAM	v_palette,0			; write regular palette buffer to CRAM
		writeVRAM	v_spritetablebuffer,vram_sprites  ; transfer sprite buffer table to actual sprites VRAM
		writeVRAM	v_hscrolltablebuffer,vram_hscroll ; transfer H-scroll buffer table to actual H-scroll VRAM
		startZ80					; restart Z80

		tst.b	(f_sonframechg).w			; has Sonic's sprite changed?
		beq.s	.nochg					; if not, branch
		writeVRAM	v_sgfx_buffer,ArtTile_Sonic*tile_size ; load new Sonic gfx
		move.b	#0,(f_sonframechg).w			; clear Sonic gfx update flag
	.nochg:

		tst.w	(v_generictimer).w			; is generic timer set?
		beq.w	.end					; if not, branch
		subq.w	#1,(v_generictimer).w			; decrement generic timer
	.end:
		rts						; return

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to perform standard VRAM transfers (palette, sprites, H-scroll)
; ---------------------------------------------------------------------------

; sub_106E:
VBlank_StandardTransfers:
		stopZ80						; request Z80 stop
		waitZ80						; wait until Z80 has stopped
		bsr.w	ReadJoypads				; read joypads and update buffered inputs in RAM

		tst.b	(f_wtr_state).w				; is the screen completely underwater?
		bne.s	.waterAbove 				; if not, branch
		writeCRAM	v_palette,0			; write regular palette buffer to CRAM
		bra.s	.waterBelow				; skip over
	.waterAbove:
		writeCRAM	v_palette_water,0		; write water palette buffer to CRAM
	.waterBelow:

		writeVRAM	v_spritetablebuffer,vram_sprites  ; transfer sprite buffer table to actual sprites VRAM
		writeVRAM	v_hscrolltablebuffer,vram_hscroll ; transfer H-scroll buffer table to actual H-scroll VRAM

		startZ80					; restart Z80
		rts						; return
; End of function VBlank_StandardTransfers
; End of VBlank (as a whole)


; ===========================================================================
; ---------------------------------------------------------------------------
; Horizontal interrupt (exclusively used for the LZ water palette effect)
; ---------------------------------------------------------------------------

; PalToCRAM: <-- old misnomer
HBlank:
		disable_ints					; disable interrupts (VBlank in this context)
		tst.w	(f_hblank_pal).w			; is palette set to change?
		beq.s	.nochg					; if not, branch
		move.w	#0,(f_hblank_pal).w			; clear palette change flag

		movem.l	a0-a1,-(sp)				; backup a0 and a1 registers
		lea	(vdp_data_port).l,a1			; load VDP data port to a1
		lea	(v_palette_water).w,a0			; get water palette from RAM
		move.l	#$C0000000,4(a1)			; set VDP to CRAM write
		rept (4*$10)/2					; overwrite full palette (4 rows, 2 colors per move)
			move.l	(a0)+,(a1)			; move water palette to CRAM
		endr						; repeat at assembly time
		move.w	#vreg_hintrate|223,4(a1)			; reset horizontal interrupt counter
		movem.l	(sp)+,a0-a1				; restore a0 and a1

		tst.b	(f_doupdatesinhblank).w			; was frame update delayed by water surface being near the top of the screen?
		bne.s	.delayed_transfer			; if yes, resume transfer now

.nochg:
		rte						; return from horizontal interrupt and resume normal operation
; ===========================================================================

; loc_119E:
.delayed_transfer:
		clr.b	(f_doupdatesinhblank).w			; clear delayed updates flag
		movem.l	d0-a6,-(sp)				; backup all registers except stack pointer (a7)
		bsr.w	VBlank_UpdateScreen			; do all the screen updates that were skipped during VBlank now
		jsr	(UpdateMusic).l				; update the sound driver
		movem.l	(sp)+,d0-a6				; restore registers
		rte						; return from horizontal interrupt and resume normal operation
; End of function HBlank


; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to initialise joypads (run once during boot)
; ---------------------------------------------------------------------------

JoypadInit:
		stopZ80						; request Z80 stop on
		waitZ80						; wait until it has stopped
		moveq	#$40,d0					; prepare initialise value
		move.b	d0,(port_1_control).l			; init port 1 (joypad 1)
		move.b	d0,(port_2_control).l			; init port 2 (joypad 2)
		move.b	d0,(expansion_control).l		; init port 3 (expansion/extra)
		startZ80					; request Z80 stop off
		rts						; return
; End of function JoypadInit

; ---------------------------------------------------------------------------
; Subroutine to read joypad input, and send it to the RAM (read every VBlank)
; ---------------------------------------------------------------------------

ReadJoypads:
		lea	(v_jpadhold1).w,a0			; address where joypad states are written
		lea	(port_1_data).l,a1			; first joypad port
		bsr.s	.read					; do the first joypad
		addq.w	#2,a1					; do the second joypad (port_2_data)

.read:
		move.b	#0,(a1)					; read A and Start input (TH poll low)
		nop						; wait a bit
		nop						; ''
		move.b	(a1),d0					; write A and Start input states to d0

		lsl.b	#2,d0					; move A and Start to topmost bits
		andi.b	#%11000000,d0				; clear all other inputs from the poll

		move.b	#$40,(a1)				; read D-Pad, B, and C input (TH poll high)
		nop						; wait a bit
		nop						; ''
		move.b	(a1),d1					; write D-Pad, B, and C input states to d1

		andi.b	#%00111111,d1				; clear all other inputs from the poll
		or.b	d1,d0					; merge but poll results into d0
		not.b	d0					; flip bits so that 0=released and 1=pressed

		move.b	(a0),d1					; get buttons pressed the previous frame
		eor.b	d0,d1					; XOR with buttons pressed this frame

		move.b	d0,(a0)+				; write HELD buttons
		and.b	d0,d1					; find buttons pressed this frame
		move.b	d1,(a0)+				; write PRESSED buttons
		rts						; return to VBlank routine
; End of function ReadJoypads


; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to setup the VDP with values used for the game itself
; ---------------------------------------------------------------------------

VDPSetupGame:
		lea	(vdp_control_port).l,a0			; load VDP control port
		lea	(vdp_data_port).l,a1			; load VDP data port
		lea	(VDPSetupArray).l,a2			; load address of register values
		moveq	#(VDPSetupArray_End-VDPSetupArray)/2-1,d7 ; set repeat times
.setreg:
		move.w	(a2)+,(a0)				; save register value to VDP
		dbf	d7,.setreg				; repeat until all register values have been sent

		move.w	(VDPSetupArray+2).l,d0			; get second entry of VDPSetupArray
		move.w	d0,(v_vdp_buffer1).w			; buffer register $81 (used for enabling/disabling display)

		move.w	#vreg_hintrate|223,(v_hblank_hreg).w		; HBlank every 224th scanline

		moveq	#cBlack,d0				; set d0 to 0 (black)
		move.l	#$C0000000,(vdp_control_port).l		; set VDP to CRAM write
		move.w	#($80)/2-1,d7				; set repeat times to cover full CRAM
.clrCRAM:
		move.w	d0,(a1)					; clear colours
		dbf	d7,.clrCRAM				; repeat until the entire palette is clear (black)

		clr.l	(v_scrposy_vdp).w			; clear single vertical scroll buffer
		clr.l	(v_scrposx_vdp).w			; clear single horizontal scroll buffer
		move.l	d1,-(sp)				; store d1 data in the stack for now
		fillVRAM 0,0,$10000				; clear the entirety of VRAM
		move.l	(sp)+,d1				; reload d1 data back out of the stack
		rts						; return
; End of function VDPSetupGame

; ---------------------------------------------------------------------------
; VDP register settings to use for the game. Do note that a handful of these
; are getting rewritten for every game mode change, though the majority
; will stay at their initial settings defined in this array.
; ---------------------------------------------------------------------------
; See here for details on VDP registers:
; https://segaretro.org/Sega_Mega_Drive/VDP_registers
; ---------------------------------------------------------------------------

VDPSetupArray:
		dc.w vreg_mode1|%000100				; 8-color mode
		dc.w vreg_mode2|%00110100			; vertical interrupts, DMA, Mega Drive display
		dc.w vreg_fgvram|(vram_fg>>10)			; foreground nametable address
		dc.w vreg_winvram|(vram_win>>10)		; window nametable address
		dc.w vreg_bgvram|(vram_bg>>13)			; background nametable address
		dc.w vreg_spritevram|(vram_sprites>>9)		; sprite table address
		dc.w $8600					; (unused, only relevant for 128KB VRAM mode)
		dc.w vreg_bgcolor|0<<4|0			; background colour (palette line 0, entry 0)
		dc.w $8800					; (unused, only relevant for Master System)
		dc.w $8900					; (unused, only relevant for Master System)
		dc.w vreg_hintrate|$00				; horizontal interrupt register
		dc.w vreg_mode3|%0000				; full-screen vertical scrolling
		dc.w vreg_mode4|%10000001			; 40-cell display mode
		dc.w vreg_hscrollvram|(vram_hscroll>>10)	; background H-scroll address
		dc.w $8E00					; (unused, only relevant for 128KB VRAM mode)
		dc.w vreg_autoinc|2				; VDP auto-increment size (2)
		dc.w vreg_planesize|%000001			; 64-cell H-scroll size
		dc.w vreg_winxpos|0				; window horizontal position
		dc.w vreg_winypos|0				; window vertical position
VDPSetupArray_End:


; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to clear the screen (plane mappings, sprites, and scroll data)
; ---------------------------------------------------------------------------

ClearScreen:
		fillVRAM 0, vram_fg, vram_fg+plane_size_64x32	; clear foreground namespace
		fillVRAM 0, vram_bg, vram_bg+plane_size_64x32	; clear background namespace

	if Revision=0
		move.l	#0,(v_scrposy_vdp).w			; clear single vertical scroll buffer
		move.l	#0,(v_scrposx_vdp).w			; clear single horizontal scroll buffer
	else
		; REV01 changed this from moving 0 to clears, but functionally identical
		clr.l	(v_scrposy_vdp).w			; clear single vertical scroll buffer
		clr.l	(v_scrposx_vdp).w			; clear single horizontal scroll buffer
	endif

	if FixBugs
		clearRAM v_spritetablebuffer,v_spritetablebuffer_end ; clear sprite table buffer
		clearRAM v_hscrolltablebuffer,v_hscrolltablebuffer_end_padded ; clear H-Scroll table buffer
	else
		; Both of these clear loops clear one more longwords than they should.
		; This will clear the first 4 bytes of v_palette_water and v_objspace, respectively.
		clearRAM v_spritetablebuffer,v_spritetablebuffer_end+4 ; clear sprite table buffer
		clearRAM v_hscrolltablebuffer,v_hscrolltablebuffer_end_padded+4 ; clear H-Scroll table buffer
	endif

		rts						; return
; End of function ClearScreen

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to load the DAC driver
; ---------------------------------------------------------------------------

; SoundDriverLoad: <-- old misnomer
DACDriverLoad:
		nop						; delay
		stopZ80						; request Z80 stop on
		deassertZ80Reset				; request Z80 reset off
		lea	(DACDriver).l,a0			; load compressed DAC driver address as source
		lea	(z80_ram).l,a1				; set Z80 RAM address as target
		bsr.w	KosDec					; decompress the DAC driver into Z80 RAM
		assertZ80Reset					; request Z80 reset on
		nop						; delay (while the Z80 resets)
		nop						; ''
		nop						; ''
		nop						; ''
		deassertZ80Reset				; request Z80 reset off
		startZ80					; request Z80 stop off
		rts						; return
; End of function DACDriverLoad

; ===========================================================================
; >>> Subroutines to queue sound commands to be executed by the sound driver during VBlank
	; includes QueueSound1, QueueSound2, QueueSound3
	; (formerly called PlaySound, PlaySound_Special, PlaySound_Unknown)
	include	"Libraries/Queue Sound Routines.asm"


; ===========================================================================
; >>> Subroutine to allow pausing the game
	include	"Libraries/PauseGame.asm"


; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to copy a tile map from RAM to VRAM namespace

; input:
;	a1 = tile map address
;	d0 = VRAM address
;	d1 = width (cells)
;	d2 = height (cells)
; ---------------------------------------------------------------------------

TilemapToVRAM:
		lea	(vdp_data_port).l,a6			; load VDP data port address
		move.l	#$800000,d4				; prepare plane width size for VDP address advancing (row)

Tilemap_Line:
		move.l	d0,4(a6)				; set the VDP the VRAM write mode with address
		move.w	d1,d3					; load width of rectangle

Tilemap_Cell:
		move.w	(a1)+,(a6)				; copy tile map to VRAM plane space
		dbf	d3,Tilemap_Cell				; repeat for the entire width
		add.l	d4,d0					; advance VDP value address to the next row
		dbf	d2,Tilemap_Line				; repeat for the entire height
		rts						; return
; End of function TilemapToVRAM

; ===========================================================================
; >>> Nemesis decompression algorithm, primarily (but not exclusively) used for PLCs
	include	"Libraries/Decompression/Nemesis Decompression.asm"

; ---------------------------------------------------------------------------
; Subroutine to add entries from a given Pattern Load Cue list ID to the
; PLC decompression queue (decompressed later during VBlank)
; ---------------------------------------------------------------------------
; ARGUMENTS
; d0 = index of PLC list
; ---------------------------------------------------------------------------
; NOTICE: This subroutine does not check for buffer overruns. The programmer
;         (or hacker) is responsible for making sure that no more than
;         16 load requests are copied into the buffer.
;         _________DO NOT PUT MORE THAN 16 LOAD REQUESTS IN A LIST!__________
;         (or if you change the size of Plc_Buffer, the limit becomes (Plc_Buffer_Only_End-Plc_Buffer)/plc_slot_size)
; ---------------------------------------------------------------------------

; LoadPLC:
AddPLC:
		movem.l	a1-a2,-(sp)				; store register data
		lea	(ArtLoadCues).l,a1			; load PLC list address
		add.w	d0,d0					; double for word-based indexing
		move.w	(a1,d0.w),d0				; load correct relative add address
		lea	(a1,d0.w),a1				; add and load actual address of list
		lea	(v_plc_buffer).w,a2			; load PLC process list

.findspace:
		tst.l	(a2)					; is this slot taken?
		beq.s	.copytoRAM				; if not, branch
		addq.w	#plc_slot_size,a2			; advance to next slot
		bra.s	.findspace				; recheck
; ===========================================================================

.copytoRAM:
		move.w	(a1)+,d0				; load size of list
		bmi.s	.return					; if there is no list, branch

.loop:
		move.l	(a1)+,(a2)+				; copy Nemesis art address
		move.w	(a1)+,(a2)+				; copy VRAM location to dump to
		dbf	d0,.loop				; repeat for all entries

.return:
		movem.l	(sp)+,a1-a2				; restore register data
		rts						; return
; End of function AddPLC

; ===========================================================================
; ---------------------------------------------------------------------------
; Identical to AddPLC, but also stops the current PLC process, and loads
; a brand new queue. (The same 16th entry warning as above applies!)
; ---------------------------------------------------------------------------

; LoadPLC2:
NewPLC:
		movem.l	a1-a2,-(sp)				; store register data
		lea	(ArtLoadCues).l,a1			; load PLC list address
		add.w	d0,d0					; double for word-based indexing
		move.w	(a1,d0.w),d0				; load correct relative add address
		lea	(a1,d0.w),a1				; add and load actual address of list
		bsr.s	ClearPLC				; clear the current PLC entries first
		lea	(v_plc_buffer).w,a2			; load PLC process list
		move.w	(a1)+,d0				; load size of list
		bmi.s	.return					; if there is no list, branch

.loop:
		move.l	(a1)+,(a2)+				; copy Nemesis art address
		move.w	(a1)+,(a2)+				; copy VRAM location to dump to
		dbf	d0,.loop				; repeat for all entries

.return:
		movem.l	(sp)+,a1-a2				; restore register data
		rts						; return
; End of function NewPLC

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to clear the pattern load cues
; Clear the pattern load queue ($FFF680 - $FFF700)
; ---------------------------------------------------------------------------

ClearPLC:
		lea	(v_plc_buffer).w,a2			; load PLC process list
		moveq	#(v_plc_buffer_end-v_plc_buffer)/4-1,d0	; set size of list

.loop:
		clr.l	(a2)+					; clear PLC process list
		dbf	d0,.loop				; repeat until entire list is cleared
		rts						; return
; End of function ClearPLC

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to	check the PLC buffer and begin decompression if it contains
; anything. ProcessPLC handles the actual decompression during VBlank
; ---------------------------------------------------------------------------

RunPLC:
		tst.l	(v_plc_buffer).w			; are there any PLC entries left to process?
		beq.s	.return					; if not, branch
		tst.w	(v_plc_patternsleft).w			; is a section counter already set (is art already being decompressed)?
		bne.s	.return					; if so, branch

		movea.l	(v_plc_buffer).w,a0			; load address of first entry's art
		lea	(NemPCD_WriteRowToVDP).l,a3		; load address of dumping routine to use (VDP variant)
		lea	(v_ngfx_buffer).w,a1			; load RLE huffman buffer
		move.w	(a0)+,d2				; load number of sections to decompress (Each section is $20 bytes)
		bpl.s	.skipXor				; if this data doesn't use XOR variant, branch
		adda.w	#NemPCD_WriteRowToVDP_XOR-NemPCD_WriteRowToVDP,a3 ; advance to XOR variant
; loc_160E:
.skipXor:
		andi.w	#$7FFF,d2				; clear XOR flag

	if FixBugs=0
		; Relocated to bugfix below
		move.w	d2,(v_plc_patternsleft).w		; save section counter
	endif
		bsr.w	NemDec_BuildCodeTable			; decompress the huffman tree RLE table
		move.b	(a0)+,d5				; load lookup field
		asl.w	#8,d5					; ''
		move.b	(a0)+,d5				; ''
		moveq	#$10,d6					; prepare bit shift counter (shifting up to a word in size)
		moveq	#0,d0					; clear d0
		move.l	a0,(v_plc_buffer).w			; store current entry address
		move.l	a3,(v_plc_ptrnemcode).w			; store dumping routine (XOR/Non-XOR)
		move.l	d0,(v_plc_repeatcount).w		; clear RLE dump counter
		move.l	d0,(v_plc_paletteindex).w		; clear RLE dump nybble
		move.l	d0,(v_plc_previousrow).w		; clear previous XOR dump
		move.l	d5,(v_plc_dataword).w			; store lookup field
		move.l	d6,(v_plc_shiftvalue).w			; store bit shift counter
	if FixBugs
		; Fix a race condition with Pattern Load Cues
		; https://info.sonicretro.org/SCHG_How-to:Fix_a_race_condition_with_Pattern_Load_Cues
		move.w	d2,(v_plc_patternsleft).w		; save section counter
	endif

.return:
		rts						; return
; End of function RunPLC

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to decompress and dump a specified number of Nemesis-compressed
; PLC tiles from the PLC process list to VRAM. These are called from VBlank,
; probably done to smooth out level loading because of how slow Nemesis is.
; (Note: Process"D"PLC is an old misnomer!)
; ---------------------------------------------------------------------------

; sub_1642: ProcessDPLC_9Tiles:
ProcessPLC_9Tiles:
		tst.w	(v_plc_patternsleft).w			; is a section counter set (is art being decompressed)?
		beq.w	ProcessPLC_Return			; if not, branch (nothing to decompress)

		move.w	#9,(v_plc_framepatternsleft).w		; set tile counter to 9 (number of tiles to decompress in a frame)
		moveq	#0,d0					; clear d0
		move.w	(v_plc_buffer_dest).w,d0		; load VRAM address for this frame
		addi.w	#9*tile_size,(v_plc_buffer_dest).w	; increase address for next frame
		bra.s	ProcessPLC				; continue
; ===========================================================================

; sub_165E: ProcessDPLC2: ProcessPLC_3Tiles:
ProcessPLC_3Tiles:
		tst.w	(v_plc_patternsleft).w			; is a section counter set (is art being decompressed)?
		beq.s	ProcessPLC_Return			; if not, branch (nothing to decompress)

		move.w	#3,(v_plc_framepatternsleft).w		; set tile counter to 3 (number of tiles to decompress in a frame)
		moveq	#0,d0					; clear d0
		move.w	(v_plc_buffer_dest).w,d0		; load VRAM address for this frame
		addi.w	#3*tile_size,(v_plc_buffer_dest).w	; increase address for next frame
		; fall-through to ProcessPLC...
; ---------------------------------------------------------------------------

; loc_1676: ProcessPLC:
ProcessPLC:
		lea	(vdp_control_port).l,a4			; load VDP control port address
		lsl.l	#2,d0					; get address MSB bits and send to LSB of long-word
		lsr.w	#2,d0					; send rest back
		ori.w	#$4000,d0				; set mode bits
		swap	d0					; align for VDP port
		move.l	d0,(a4)					; set VDP address/mode
		subq.w	#4,a4					; move a4 down to VDP data port
		movea.l	(v_plc_buffer).w,a0			; load current entry address
		movea.l	(v_plc_ptrnemcode).w,a3			; load dumping routine to use (XOR/Non-XOR)
		move.l	(v_plc_repeatcount).w,d0		; load RLE dump counter
		move.l	(v_plc_paletteindex).w,d1		; load RLE dump nybble
		move.l	(v_plc_previousrow).w,d2		; load previous XOR dump
		move.l	(v_plc_dataword).w,d5			; load lookup field
		move.l	(v_plc_shiftvalue).w,d6			; load bit shift counter
		lea	(v_ngfx_buffer).w,a1			; load RLE huffman buffer

; loc_16AA:
.loop:
		movea.w	#8,a5					; set size of data to decompress (20 bytes, 1 tile)
		bsr.w	NemPCD_NewRow				; continue the decompression
		subq.w	#1,(v_plc_patternsleft).w		; decrease section count by 1
		beq.s	ProcessPLC_ShiftCue			; if decompression is finished, branch
		subq.w	#1,(v_plc_framepatternsleft).w		; decrease tile counter
		bne.s	.loop					; if still running, branch to decompress another tile

		move.l	a0,(v_plc_buffer).w			; store current entry address
		move.l	a3,(v_plc_ptrnemcode).w			; store dumping routine to use (XOR/Non-XOR)
		move.l	d0,(v_plc_repeatcount).w		; store RLE dump counter
		move.l	d1,(v_plc_paletteindex).w		; store RLE dump nybble
		move.l	d2,(v_plc_previousrow).w		; store previous XOR dump
		move.l	d5,(v_plc_dataword).w			; store lookup field
		move.l	d6,(v_plc_shiftvalue).w			; store bit shift counter

ProcessPLC_Return:
		rts						; return
; ===========================================================================

; loc_16DC:
ProcessPLC_ShiftCue:
		lea	(v_plc_buffer).w,a0			; load PLC process list
		moveq	#(v_plc_buffer_only_end-v_plc_buffer-plc_slot_size)/4-1,d0 ; set size of list

; loc_16E2:
.loop:
		move.l	plc_slot_size(a0),(a0)+			; shift contents of PLC buffer up 6 bytes
		dbf	d0,.loop				; repeat til done

	if FixBugs
		; The above code does not properly 'pop' the 16th PLC entry.
		; Because of this, occupying the 16th slot will cause it to
		; be repeatedly decompressed infinitely.
		; Granted, this could be considered more of an optimisation
		; than a bug: treating the 16th entry as a dummy that
		; should never be occupied makes this code unnecessary.
		; Still, the overhead of this code is minimal.
		if (v_plc_buffer_only_end-v_plc_buffer-plc_slot_size)&2
			move.w	plc_slot_size(a0),(a0)
		endif
		clr.l	(v_plc_buffer_only_end-plc_slot_size).w
	endif

		rts						; return
; End of function ProcessPLC

; ===========================================================================
; ---------------------------------------------------------------------------
; Like AddPLC, but instead of adding entries to a queue to be processed later,
; this will decompress and transfer all entries of the given PLC ID's list
; immediately, blocking until it is done. Does not use or affect the queue.
; ---------------------------------------------------------------------------

QuickPLC:
		lea	(ArtLoadCues).l,a1			; load PLC list address
		add.w	d0,d0					; double for word-based indexing
		move.w	(a1,d0.w),d0				; load correct relative add address
		lea	(a1,d0.w),a1				; add and load actual address of list
		move.w	(a1)+,d1				; load size of list

.loop:
		movea.l	(a1)+,a0				; load Nemesis art address
		moveq	#0,d0					; clear d0
		move.w	(a1)+,d0				; load VRAM dump address
		lsl.l	#2,d0					; get address MSB bits and send to LSB of long-word
		lsr.w	#2,d0					; send rest back
		ori.w	#$4000,d0				; set mode bits
		swap	d0					; align for VDP port
		move.l	d0,(vdp_control_port).l			; set VDP address/mode
		bsr.w	NemDec					; decompress the entire entry
		dbf	d1,.loop				; repeat for all entries in the list
		rts						; return
; End of function QuickPLC

; ===========================================================================
; >>> Other decompression algorithms
	include	"Libraries/Decompression/Enigma Decompression.asm"
	include	"Libraries/Decompression/Kosinski Decompression.asm"


; ===========================================================================
; >>> Palette logic routines
	include	"Libraries/PaletteCycle.asm"
	include	"Libraries/Palette Fading.asm" ; includes "PaletteFadeIn", "PaletteFadeOut", "PaletteWhiteIn", and "PaletteWhiteOut"


; ===========================================================================
; ---------------------------------------------------------------------------
; Palette cycling routine - Sega logo
; ---------------------------------------------------------------------------

PalCycle_Sega:
		tst.b	(v_pcyc_time+1).w			; is light scanning effect done?
		bne.s	PCycSega_FadeIn				; if yes, branch

; ---------------------------------------------------------------------------
; First part of the Sega screen palette cycle (the "light scan effect")
; ---------------------------------------------------------------------------

		lea	(v_palette_line_2).w,a1			; set target start palette line (affects line 2-4 overall)
		lea	(Pal_Sega1).l,a0			; get palette cycle colors for the light scanning effect
		moveq	#(Pal_Sega1_end-Pal_Sega1)/2-1,d1	; set size of colors to write (6 in total)
		move.w	(v_pcyc_num).w,d0			; load current palcycle position (initialized to -$A)

; loc_2020:
.findScanStart:
		bpl.s	.doLightScan				; has start position been found? if yes, branch (d0 >= 0)
		addq.w	#2,a0					; get next color in Pal_Sega1
		subq.w	#1,d1					; set to load one less color
		addq.w	#2,d0					; go to next starting color for light effect
		bra.s	.findScanStart				; loop until current position has been found
; ===========================================================================

; loc_202A:
.doLightScan:
		move.w	d0,d2					; get current target position
		andi.w	#$1E,d2					; limit to one palette line ($20 bytes)
		bne.s	.notTransparent1			; is it the first (transparent) color? if not, branch
		addq.w	#2,d0					; skip over transparent color

; loc_2034:
.notTransparent1:
		cmpi.w	#v_palette_line_4-v_palette_line_1,d0	; (=$60) would we write past the last palette entry?
		bhs.s	.writeNoMore				; if yes, do not write new color
		move.w	(a0)+,(a1,d0.w)				; write current light scan color to palette buffer

; loc_203E:
.writeNoMore:
		addq.w	#2,d0					; go to next starting color for light effect
		dbf	d1,.doLightScan				; loop until all colors have been written

		; Palette dumping is done, update next offset or set to next part
		move.w	(v_pcyc_num).w,d0			; load current palcycle position
		addq.w	#2,d0					; go to next starting color
		move.w	d0,d2					; get current target position
		andi.w	#$1E,d2					; limit to one palette line ($20 bytes)
		bne.s	.notTransparent2			; is it the first (transparent) color? if not, branch
		addq.w	#2,d0					; skip over transparent color

; loc_2054:
.notTransparent2:
		cmpi.w	#v_palette_line_4-v_palette_line_1+4,d0	; (=$64) has light scan effect finished?
		blt.s	.scanNotDone				; if not, branch
		move.w	#(4<<8)+1,(v_pcyc_time).w		; set delay between fade-in increments (high byte) and "light scan done" flag (low byte)
		moveq	#-6*2,d0				; set starting offset for fade-in palette (gets set to 0 for first fade-in step)

; loc_2062:
.scanNotDone:
		move.w	d0,(v_pcyc_num).w
		moveq	#1,d0					; clear Z-flag (possibly for a return signal, but now unsued)
		rts						; return
; ===========================================================================

; ---------------------------------------------------------------------------
; Second part of the Sega screen palette cycle (the fade-in)
; ---------------------------------------------------------------------------

; loc_206A:
PCycSega_FadeIn:
		subq.b	#1,(v_pcyc_time).w			; decrement delay until next brightness increase
		bpl.s	.delayFadeIn				; does delay time remain? if yes, branch

		move.b	#4,(v_pcyc_time).w			; reset delay between fade-in increments
		move.w	(v_pcyc_num).w,d0			; get current fade-in position
		addi.w	#6*2,d0					; go to next set of colors
		cmpi.w	#(6*2)*4,d0				; have four color sets been done?
		blo.s	.doFadeIn				; if not, do next fade-in step

		moveq	#0,d0					; set Z-flag (possibly for a return signal, but now unsued)
		rts						; return
; ===========================================================================

; loc_2088:
.doFadeIn:
		move.w	d0,(v_pcyc_num).w			; remember position for next fade-in increment
		lea	(Pal_Sega2).l,a0			; get palette cycle colors for the fade-in effect
		lea	(a0,d0.w),a0				; go to relevant color data
		lea	(v_palette_line_1+$04).w,a1		; set to write past transparent and pure-white color
		move.l	(a0)+,(a1)+				; write colors 1 and 2 to buffer
		move.l	(a0)+,(a1)+				; write colors 3 and 4 to buffer
		move.w	(a0)+,(a1)				; write color 5 to buffer

		; Main palette dumping is done, fill remaining palette buffer with 6th color
		lea	(v_palette_line_2).w,a1			; start from second palette line (up to fourth one)
		moveq	#0,d0					; clear d0
		moveq	#((v_palette_line_4-v_palette_line_1)/2)-3-1,d1 ; (=$2C) write 3 lines, minus skipped transparent colors, minus 1

; loc_20A8:
.fillRest:
		move.w	d0,d2					; get current target position
		andi.w	#$1E,d2					; limit to one palette line ($20 bytes)
		bne.s	.notTransparent3			; is it the first (transparent) color? if not, branch
		addq.w	#2,d0					; skip over transparent color

; loc_20B2:
.notTransparent3:
		move.w	(a0),(a1,d0.w)				; write fill color to current palette slot (and don't advance index)
		addq.w	#2,d0					; go to next palette target
		dbf	d1,.fillRest				; loop until remaining palette has been filled completely

; loc_20BC:
.delayFadeIn:
		moveq	#1,d0					; clear Z-flag (possibly for a return signal, but now unsued)
		rts						; return
; End of function PalCycle_Sega

; ===========================================================================
; >>> Palette cycle data used for Sega screen
Pal_Sega1:	bincludeEndMarker	"Modes/Palettes/SEGA 1.bin"	; used during the light scanning effect
Pal_Sega2:	bincludeEndMarker	"Modes/Palettes/SEGA 2.bin"	; used during the fade-in (three color sets, 5+1 colors each)


; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to load main palettes into the fading buffer.
; These get displayed once PaletteFadeIn/PaletteWhiteIn is called.

; input:
; d0 = index number for palette
; ---------------------------------------------------------------------------

PalLoad_Fade:
		lea	(Pal_Index).l,a1			; get palette pointers
		lsl.w	#3,d0					; multiply input ID by 8 (size of one palette index entry)
		adda.w	d0,a1					; add to palette index pointer to get relevant palette entry
		movea.l	(a1)+,a2				; get palette data address
		movea.w	(a1)+,a3				; get target RAM address
		adda.w	#v_palette_fading-v_palette,a3		; load to palette fade-in buffer instead of active palette buffer (+$80)
		move.w	(a1)+,d7				; get length of palette data

.loop:
		move.l	(a2)+,(a3)+				; move two colors from palette data to palette buffer RAM
		dbf	d7,.loop				; loop until all colors are loaded
		rts						; return
; End of function PalLoad_Fade

; ---------------------------------------------------------------------------
; Subroutine to directly load main palettes to the active palette.
; Same as PalLoad_Fade, but without adding $80.
; ---------------------------------------------------------------------------

PalLoad:
		lea	(Pal_Index).l,a1			; get palette pointers
		lsl.w	#3,d0					; multiply input ID by 8 (size of one palette index entry)
		adda.w	d0,a1					; add to palette index pointer to get relevant palette entry
		movea.l	(a1)+,a2				; get palette data address
		movea.w	(a1)+,a3				; get target RAM address
		move.w	(a1)+,d7				; get length of palette data

.loop:
		move.l	(a2)+,(a3)+				; move two colors from palette data to palette buffer RAM
		dbf	d7,.loop				; loop until all colors are loaded
		rts						; return
; End of function PalLoad

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to load underwater palettes into the water fading buffer.
; These get displayed once PaletteFadeIn/PaletteWhiteIn is called.
; ---------------------------------------------------------------------------

PalLoad_Fade_Water:
		lea	(Pal_Index).l,a1			; get palette pointers
		lsl.w	#3,d0					; multiply input ID by 8 (size of one palette index entry)
		adda.w	d0,a1					; add to palette index pointer to get relevant palette entry
		movea.l	(a1)+,a2				; get palette data address
		movea.w	(a1)+,a3				; get target RAM address
		suba.w	#v_palette-v_palette_water,a3		; load to (water) palette fade-in buffer instead of active palette buffer
		move.w	(a1)+,d7				; get length of palette data

.loop:
		move.l	(a2)+,(a3)+				; move two colors from palette data to palette buffer RAM
		dbf	d7,.loop				; loop until all colors are loaded
		rts						; return
; End of function PalLoad_Fade_Water

; ---------------------------------------------------------------------------
; Subroutine to directly load underwater palettes to the active palette.
; Same as PalLoad_Fade_Water, but writing $80 before it.
; ---------------------------------------------------------------------------

PalLoad_Water:
		lea	(Pal_Index).l,a1			; get palette pointers
		lsl.w	#3,d0					; multiply input ID by 8 (size of one palette index entry)
		adda.w	d0,a1					; add to palette index pointer to get relevant palette entry
		movea.l	(a1)+,a2				; get palette data address
		movea.w	(a1)+,a3				; get target RAM address
		suba.w	#v_palette-v_palette_water_fading,a3	; load to active (water) palette buffer instead of main active palette buffer
		move.w	(a1)+,d7				; get length of palette data

.loop:
		move.l	(a2)+,(a3)+				; move two colors from palette data to palette buffer RAM
		dbf	d7,.loop				; loop until all colors are loaded
		rts						; return
; End of function PalLoad_Water

; ===========================================================================
; >>> Palette pointers and palette binary includes
	include	"Libraries/Palette Index.asm"


; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to wait for VBlank routines to complete
; ---------------------------------------------------------------------------

; DelayProgram: <-- old misnomer
; WaitForVBla: <-- old name
WaitForVBlank:
		enable_ints					; enable interrupts so vertical interrupts can occur

.wait:
		tst.b	(v_vblank_routine).w			; has VBlank routine finished?
		bne.s	.wait					; if not, loop until it has
		rts						; resume normal operation
; End of function WaitForVBlank

; ===========================================================================
; >>> Subroutines for generic calculations
	include	"Objects/shared/sub RandomNumber.asm"
	include	"Objects/shared/sub CalcSine.asm"
    if Revision=0
		; Only in REV00, and even there it was never used
	include	"Objects/shared/sub CalcSqrt.asm"
    endif
	include	"Objects/shared/sub CalcAngle.asm"


; ===========================================================================
	include	"Modes/SEGA.asm"
; ===========================================================================
	include	"Modes/Title Screen.asm"
; ===========================================================================
	include	"Modes/Zone.asm"
; ===========================================================================
	include	"Modes/Special Stage.asm"
; ===========================================================================
	include	"Modes/Continue Screen.asm"
; ===========================================================================
	include	"Modes/End Cutscene.asm"
; ===========================================================================
	include	"Modes/Credits.asm"
; ===========================================================================
	include	"Modes/End Screen.asm"
; ===========================================================================
; ---------------------------------------------------------------------------
; >> END OF MAIN GAME LOGIC - Everything below this point is file includes <<
; ---------------------------------------------------------------------------
; ===========================================================================


; Where possible, includes to _maps and _anim were appended to the _incObj
; file includes themselves. However, in some cases this wasn't possible,
; as the developers weren't very consistent with the placement, especially
; during the early stages of production. Those includes are still here.


; ===========================================================================
; >>> Level rendering, loading, and updating
		include	"Libraries/LevelSizeLoad & BgScrollSpeed.asm" ; merged with "LevelSizeLoad & BgScrollSpeed (JP1).asm"
	if Revision=0
		include	"Libraries/DeformLayers (REV00).asm"
		include	"Libraries/Level Drawing (REV00).asm"
	else
		include	"Libraries/DeformLayers (REV01).asm"
		include	"Libraries/Level Drawing (REV01).asm"
	endif
		include	"Libraries/LevelLayoutLoad.asm" ; includes LevelDataLoad, LevelLayoutLoad, and LevelLayoutLoad2

		include	"Libraries/DynamicLevelEvents.asm"


; ===========================================================================
; >>> Various level objects
		include	"Objects/Zone/GHZ/Bridge.asm"
		include	"Objects/Zone/Shared/Swinging Platform and Spike.asm" ; includes "MvSonicOnPtfm" subroutine
		include	"Objects/Zone/GHZ/Spiked Pole Helix.asm"
		include	"Objects/Zone/Shared/Platform.asm"
		include	"Objects/Unused/GHZ Ball.asm" ; prototype leftover
Map_GBall:	include	"Objects/Unused/Mappings/GHZ Ball.map"
		include	"Objects/Zone/Shared/Collapsing Geometry.asm" ; includes "SlopeObject_AssumeStoodOn" subroutine
		include	"Objects/Zone/Shared/Scenery.asm"
		include	"Objects/Unused/Switch.asm"
		include	"Objects/Zone/SBZ/Small Door.asm"
		include	"Objects/shared/sub SolidWall.asm"


; ===========================================================================
; >>> Badniks, explosions, and Badnik-related objects
		include	"Objects/Badniks/Ball Hog and Cannonball.asm"
		include	"Objects/Unused/Small Explosion.asm"
		include	"Objects/Effects/Explosion.asm"
		include	"Objects/Badniks/Animations/Ball Hog.ani"
Map_Hog:	include	"Objects/Badniks/Mappings/Ball Hog.map"
Map_UnkExplode:	include	"Objects/Unused/Mappings/Small Explosion.map"
		include	"Objects/Effects/Mappings/Explosion.map"
		include	"Objects/Effects/Animal and Points.asm"
		include	"Objects/Badniks/Crabmeat.asm"
		include	"Objects/Badniks/Buzz Bomber and Missile.asm"


; ===========================================================================
; >>> Rings
		include	"Objects/Global/Ring.asm"
		include	"Objects/Global/Giant Ring.asm"
		include	"Objects/Global/Animations/Ring.ani"
Map_Ring:   if Revision=0
		include	"Objects/Global/Mappings/Ring (REV00).map"
	    else
		; REV01 added an extra blank frame, possibly to mitigate
		; rings occasionally popping up in the sign post sparkles
		include	"Objects/Global/Mappings/Ring (REV01).map"
	    endif
Map_GRing:	include	"Objects/Global/Mappings/Giant Ring.map"
Map_Flash:	include	"Objects/Global/Mappings/Giant Ring Flash.map"


; ===========================================================================
; >>> Monitors
		include	"Objects/Global/Monitor.asm"


; ===========================================================================
; >>> Title screen objects (includes AnimateSprite)
		include	"Objects/Cards/Title Screen Pieces.asm"


; ===========================================================================
; >>> More Badniks and level objects
		include	"Objects/Badniks/Chopper.asm"
		include	"Objects/Badniks/Jaws.asm"
		include	"Objects/Badniks/Burrobot.asm"
		include	"Objects/Zone/MZ/Large Grassy Platforms and Burning Grass.asm"
Map_Fire:	include	"Objects/Zone/Shared/Mappings/Fireball.map"
		include	"Objects/Zone/MZ/Large Green Glass Blocks.asm"
		include	"Objects/Zone/MZ/Chained Stompers.asm"
		include	"Objects/Unused/MZ Sideways Stomper.asm"
Map_CStom:	include	"Objects/Zone/MZ/Mappings/Chained Stompers.map"
Map_SStom:	include	"Objects/Unused/Mappings/MZ Sideways Stomper.map"
		include	"Objects/Zone/Shared/Button.asm"
		include	"Objects/Zone/Shared/Pushable Blocks.asm"


; ===========================================================================
; >>> Title card objects
		include	"Objects/Cards/Title Cards.asm"
		include	"Objects/Cards/Game Over Text.asm"
		include	"Objects/Cards/Got Through Card.asm"
		include	"Objects/Cards/Special Stage Results.asm"
		include	"Objects/Cards/Mappings/Title Cards.map" ; includes "Map_Card", "Map_Over", "Map_Got", and "Map_SSR"
Map_SSRC:	include	"Objects/Cards/Mappings/Emeralds (Results).map"


; ===========================================================================
; >>> More level objects
		include	"Objects/Global/Spike.asm"
		include	"Objects/Zone/GHZ/Purple Rock.asm"
		include	"Objects/Zone/GHZ/Waterfall Sound.asm"
Map_PRock:	include	"Objects/Zone/GHZ/Mappings/Purple Rock.map"
		include	"Objects/Zone/Shared/Breakable Wall.asm" ; includes SmashObject


; ===========================================================================
; Subroutines to run, render, and update objects
		include	"Libraries/ExecuteObjects.asm"
		include	"Libraries/Object Pointers.asm" ; includes Obj_Index
		include	"Objects/shared/sub ObjectFall & SpeedToPos.asm"
		include	"Objects/shared/sub DisplaySprite.asm"
		include	"Objects/shared/sub DeleteObject.asm"
		include	"Libraries/BuildSprites.asm"
		include	"Objects/shared/sub ChkObjectVisible.asm"
		include	"Libraries/ObjPosLoad.asm"
		include	"Objects/shared/sub FindFreeObj.asm"


; ===========================================================================
; >>> More level objects
		include	"Objects/Global/Spring.asm"
		include	"Objects/Badniks/Newtron.asm"
		include	"Objects/Badniks/Roller.asm"
		include	"Objects/Zone/GHZ/Edge Walls.asm"
		include	"Objects/Zone/Shared/Fireball and Maker.asm"
		include	"Objects/Zone/SBZ/Flamethrower.asm"
		include	"Objects/Zone/MZ/Bricks.asm"
		include	"Objects/Zone/SYZ/Search Light.asm"
		include	"Objects/Zone/SYZ/Bumper.asm"
		include	"Objects/Global/Signpost.asm" ; includes "GotThroughAct" subroutine
		include	"Objects/Zone/MZ/Lava Geyser and Maker.asm"
		include	"Objects/Zone/MZ/Wall of Lava.asm"
		include	"Objects/Zone/MZ/Invisible Lava Tag.asm"
		include	"Objects/Zone/MZ/Animations/Lava Geyser.ani"
		include	"Objects/Zone/MZ/Animations/Wall of Lava.ani"
Map_Geyser:	include	"Objects/Zone/MZ/Mappings/Lava Geyser.map"
Map_LWall:	include	"Objects/Zone/MZ/Mappings/Wall of Lava.map"
		include	"Objects/Badniks/Moto Bug.asm" ; includes "Objects/shared/sub RememberState.asm" subroutine
		include	"Objects/Unused/Splats.asm" ; this was Splats in the prototype
		include	"Objects/Badniks/Yadrin.asm"
		include	"Objects/shared/sub SolidObject.asm"
		include	"Objects/Zone/MZ/Smashable Green Block.asm"
		include	"Objects/Zone/Shared/Moving Block.asm"
		include	"Objects/Badniks/Basaran.asm"
		include	"Objects/Zone/Shared/Floating Blocks and Doors.asm"
		include	"Objects/Zone/Shared/Spiked Ball and Chain.asm"
		include	"Objects/Zone/SYZ/Big Spiked Ball.asm"
		include	"Objects/Zone/SLZ/Elevators.asm"
		include	"Objects/Zone/SLZ/Circling Platform.asm"
		include	"Objects/Zone/SLZ/Staircase.asm"
		include	"Objects/Zone/SLZ/Foreground Pylon.asm"
		include	"Objects/Zone/LZ/Water Surface.asm"
		include	"Objects/Zone/LZ/Breakable Pole.asm"
		include	"Objects/Zone/LZ/Flapping Door.asm"
		include	"Objects/Global/Invisible Barrier.asm"
		include	"Objects/Zone/SLZ/Fan.asm"
		include	"Objects/Zone/SLZ/Seesaw.asm"
		include	"Objects/Badniks/Walking Bomb.asm"
		include	"Objects/Badniks/Orbinaut.asm"
		include	"Objects/Zone/LZ/Harpoon.asm"
		include	"Objects/Zone/LZ/Block.asm"
		include	"Objects/Zone/LZ/Gargoyle.asm"
		include	"Objects/Zone/LZ/Conveyor.asm"
		include	"Objects/Zone/LZ/Air Bubble.asm"
		include	"Objects/Zone/LZ/Waterfall.asm"


; ===========================================================================
; >>> Main Sonic player object
		include	"Objects/Global/Sonic.asm"


; ===========================================================================
; >>> Various unique objects
		include	"Objects/Zone/LZ/Drowning Countdown.asm" ; includes ResumeMusic
		include	"Objects/Effects/Shield and Invincibility.asm"
		include	"Objects/Unused/Special Stage Entry.asm"
		include	"Objects/Zone/LZ/Water Splash.asm"
		include	"Objects/Effects/Animations/Shield and Invincibility.ani"
Map_Shield:	include	"Objects/Effects/Mappings/Shield and Invincibility.map"
		include	"Objects/Unused/Animations/Special Stage Entry.ani"
Map_Vanish:	include	"Objects/Unused/Mappings/Special Stage Entry.map"
		include	"Objects/Zone/LZ/Animations/Water Splash.ani"
Map_Splash:	include	"Objects/Zone/LZ/Mappings/Water Splash.map"


; ===========================================================================
; >>> Collision subroutines for Sonic and other objects
		include	"Objects/Global/Sonic (Ground Collision).asm"
		include	"Objects/shared/sub FindNearestTile & FindFloor & FindWall.asm"
		include "Libraries/ConvertCollisionArray (Unused).asm"
		include	"Objects/Global/Sonic (Collision Detection).asm"


; ===========================================================================
; >>> SBZ level objects
		include	"Objects/Zone/SBZ/Rotating Junction.asm"
		include	"Objects/Zone/SBZ/Running Disc.asm"
		include	"Objects/Zone/SBZ/Conveyor Belt.asm"
		include	"Objects/Zone/SBZ/Spinning Platforms and Trapdoors.asm"
		include	"Objects/Zone/SBZ/Saws and Pizza Cutters.asm"
		include	"Objects/Zone/SBZ/Stomper and Sliding Door.asm"
		include	"Objects/Zone/SBZ/Vanishing Platforms.asm"
		include	"Objects/Zone/SBZ/Electrocuter.asm"
		include	"Objects/Zone/SBZ/Spin Platform Conveyor.asm"
		include	"Objects/Zone/SBZ/Girder Block.asm"
		include	"Objects/Zone/SBZ/Teleporter.asm"

; ===========================================================================
; >>> Misc objects
		include	"Objects/Badniks/Caterkiller.asm"
		include	"Objects/Global/Lamppost.asm"
		include	"Objects/Effects/Hidden Points.asm"
		include	"Objects/Cards/Credit Text.asm"


; ===========================================================================
; >>> Bosses and related objects
		include	"Objects/Bosses/Egg Wrecker.asm" ; includes "BossDefeated" and "BossMove" subroutines
		include	"Objects/Bosses/Animations/Eggman.ani"
Map_Eggman:	include	"Objects/Bosses/Mappings/Eggman.map"
Map_BossItems:	include	"Objects/Bosses/Mappings/Boss Items.map"
		include	"Objects/Bosses/Egg Mobile.asm"
		include	"Objects/Bosses/Egg Scorcher.asm"
		include	"Objects/Bosses/Egg Spiker.asm"
		include	"Objects/Bosses/Egg Stinger.asm"
		include	"Objects/Zone/SBZ/Eggman Cutscene and Crumbling Floor.asm"
		include	"Objects/Bosses/Egg Crusher.asm"
		include	"Objects/Global/Prison Capsule.asm"


; ===========================================================================
; >>> Object-to-object touch response handler for Sonic
		include	"Objects/Global/Sonic (Object Reactions).asm"


; ===========================================================================
; >>> Special Stage rendering and objects
		; The following includes "SS_ShowLayout", "SS_AniWallsRings",
		; "SS_FindFreeAnimationSlot", "SS_AniItems", and "SS_Load"
		include	"Modes/Special Stage (Renderer).asm"
Map_SS_Shared:	include	"Levels/Special/Mappings/Shared.asm"
Map_SS_Glass:	include	"Levels/Special/Mappings/Glass.asm"
Map_SS_Up:	include	"Levels/Special/Mappings/UP.asm"
Map_SS_Down:	include	"Levels/Special/Mappings/DOWN.asm"
Map_SS_Chaos:	include	"Levels/Special/Mappings/Chaos Emeralds.asm"
		include	"Objects/Global/Sonic (Special Stage).asm"


; ===========================================================================
; >>> Deleted, blank object that is randomly mixed in here
		include	"Objects/Unused/Animation Test.asm" ; this was an animation test object for Sonic in the prototype


; ===========================================================================
; >>> Subroutine for in-place level animations in VRAM
		include	"Libraries/AnimateLevelGfx.asm"


; ===========================================================================
; >>> HUD objects
		include	"Objects/Cards/HUD.asm"
		include	"Objects/shared/sub AddPoints.asm"
		include	"Libraries/HUD Update.asm" ; includes "ContScrCounter" subroutine

Art_Hud:	binclude "Objects/Cards/Cells/Numerals.unc" ; 8x16 pixel numbers on HUD
		even
Art_LivesNums:	binclude "Objects/Cards/Cells/Life Numerals.unc" ; 8x8 pixel numbers on lives counter
		even


; ===========================================================================
; >>> Debug Mode
		include	"Objects/shared/DebugMode.asm"


; ===========================================================================
; >>> Level definitions
		include	"Libraries/LevelHeaders.asm"
		include	"Libraries/Pattern Load Cues.asm"


; ===========================================================================

; ---------------------------------------------------------------------------
; >> END OF PRIMARY INCLUDES - Everything below this point is art includes <<
; ---------------------------------------------------------------------------

		; Nem_SegaLogo has a bunch of padding before it that differs between revisions:
		; - in rev00, it starts at $1DC00, which amounts to $EE bytes
		; - in rev01/rev02, it starts at $1E700, which amounts to $48E bytes
		; From a technical standpoint, this padding serves no purpose.
	if PaddingOptimization=0
		align	$200
		if Revision<>0
			dcb.b	$300,$FF
		endif
	endif

; ===========================================================================
; ---------------------------------------------------------------------------
; Compressed graphics and mappings - Sega screen
; ---------------------------------------------------------------------------
	if Revision=0
Nem_SegaLogo:	binclude	"Modes/Cells/SEGA (REV00).nem" ; large Sega logo
		even
Eni_SegaLogo:	binclude	"Modes/Maps/SEGA (REV00).eni" ; large Sega logo (mappings)
		even
	else
Nem_SegaLogo:	binclude	"Modes/Cells/SEGA (REV01).nem" ; large Sega logo
		even
Eni_SegaLogo:	binclude	"Modes/Maps/SEGA (REV01).eni" ; large Sega logo (mappings)
		even
	endif

; ---------------------------------------------------------------------------
; Compressed graphics and mappings - Title screen
; ---------------------------------------------------------------------------
Eni_Title:	binclude	"Modes/Maps/Title Screen.eni" ; title screen foreground (mappings)
		even
Nem_TitleFg:	binclude	"Modes/Cells/Title Foreground.nem"
		even
Nem_TitleSonic:	binclude	"Modes/Cells/Sonic (Title Screen).nem"
		even
Nem_TitleTM:	binclude	"Modes/Cells/TM.nem"
		even
Eni_JapNames:	binclude	"Modes/Maps/Hidden Japanese Credits.eni" ; Japanese credits (mappings)
		even
Nem_JapNames:	binclude	"Modes/Cells/Hidden Japanese Credits.nem"
		even

; ---------------------------------------------------------------------------
; Uncompressed graphics - Sonic
; ---------------------------------------------------------------------------
Map_Sonic:	include	"Objects/Global/Mappings/Sonic.map"

SonicDynPLC:	include	"Objects/Global/DPLCs/Sonic.dplc"

Art_Sonic:	binclude	"Objects/Global/Cells/Sonic.unc"
		even

; ---------------------------------------------------------------------------
; Compressed graphics - various
; ---------------------------------------------------------------------------
	if Revision=0
Nem_Smoke:	binclude	"Objects/Unused/Cells/Smoke.nem"
		even
Nem_SyzSparkle:	binclude	"Levels/SYZ/Cells/Unused/Sparkles.nem"
		even
	endif

Nem_Shield:	binclude	"Objects/Effects/Cells/Shield.nem"
		even
Nem_Stars:	binclude	"Objects/Effects/Cells/Invincibility Stars.nem"
		even

	if Revision=0
Nem_LzSonic:	binclude	"Levels/LZ/Cells/Unused/Sonic.nem" ; Sonic holding his breath
		even
Nem_UnkFire:	binclude	"Objects/Unused/Cells/Fireball.nem" ; unused fireball
		even
Nem_Warp:	binclude	"Levels/Special/Cells/Unused/Flash.nem" ; entry to special stage flash
		even
Nem_Goggle:	binclude	"Objects/Unused/Cells/Goggles.nem" ; unused goggles
		even
	endif

; ---------------------------------------------------------------------------
; Compressed graphics - special stage
; ---------------------------------------------------------------------------
Map_SSWalls:	include	"Levels/Special/Mappings/Walls.asm"

Nem_SSWalls:	binclude	"Levels/Special/Cells/Walls.nem" ; special stage walls
		even
Eni_SSBg1:	binclude	"Levels/Special/Maps/Birds and Fish.eni" ; special stage background (mappings)
		even
Nem_SSBgFish:	binclude	"Levels/Special/Cells/Birds and Fish.nem" ; special stage birds and fish background
		even
Eni_SSBg2:	binclude	"Levels/Special/Maps/Clouds and Bubbles.eni" ; special stage background (mappings)
		even
Nem_SSBgCloud:	binclude	"Levels/Special/Cells/Clouds.nem" ; special stage clouds background
		even
Nem_SSGOAL:	binclude	"Levels/Special/Cells/GOAL.nem" ; special stage GOAL block
		even
Nem_SSRBlock:	binclude	"Levels/Special/Cells/R.nem" ; special stage R block
		even
Nem_SS1UpBlock:	binclude	"Levels/Special/Cells/1UP.nem" ; special stage 1UP block
		even
Nem_SSEmStars:	binclude	"Levels/Special/Cells/Emerald Twinkle.nem" ; special stage stars from a collected emerald
		even
Nem_SSRedWhite:	binclude	"Levels/Special/Cells/Red-White.nem" ; special stage red/white block
		even
Nem_SSZone1:	binclude	"Levels/Special/Cells/ZONE1.nem" ; special stage ZONE1 block
		even
Nem_SSZone2:	binclude	"Levels/Special/Cells/ZONE2.nem" ; ZONE2 block
		even
Nem_SSZone3:	binclude	"Levels/Special/Cells/ZONE3.nem" ; ZONE3 block
		even
Nem_SSZone4:	binclude	"Levels/Special/Cells/ZONE4.nem" ; ZONE4 block
		even
Nem_SSZone5:	binclude	"Levels/Special/Cells/ZONE5.nem" ; ZONE5 block
		even
Nem_SSZone6:	binclude	"Levels/Special/Cells/ZONE6.nem" ; ZONE6 block
		even
Nem_SSUpDown:	binclude	"Levels/Special/Cells/UP-DOWN.nem" ; special stage UP/DOWN block
		even
Nem_SSEmerald:	binclude	"Levels/Special/Cells/Emeralds.nem" ; special stage chaos emeralds
		even
Nem_SSGhost:	binclude	"Levels/Special/Cells/Ghost.nem" ; special stage ghost block
		even
Nem_SSWBlock:	binclude	"Levels/Special/Cells/W.nem" ; special stage W block
		even
Nem_SSGlass:	binclude	"Levels/Special/Cells/Glass.nem" ; special stage destroyable glass block
		even
Nem_ResultEm:	binclude	"Levels/Special/Cells/Result Emeralds.nem" ; chaos emeralds on special stage results screen
		even

; ---------------------------------------------------------------------------
; Compressed graphics - GHZ stuff
; ---------------------------------------------------------------------------
Nem_Stalk:	binclude	"Levels/GHZ/Cells/Stalk.nem"
		even
Nem_Swing:	binclude	"Objects/Zone/GHZ/Cells/Swinging Platform.nem"
		even
Nem_Bridge:	binclude	"Objects/Zone/GHZ/Cells/Bridge.nem"
		even
Nem_GhzUnkBlock:binclude	"Levels/GHZ/Cells/Unused/Block.nem"
		even
Nem_Ball:	binclude	"Objects/Unused/Cells/GHZ Ball.nem"
		even
Nem_Spikes:	binclude	"Objects/Global/Cells/Spike.nem"
		even
Nem_GhzLog:	binclude	"Levels/GHZ/Cells/Unused/Log.nem"
		even
Nem_SpikePole:	binclude	"Objects/Zone/GHZ/Cells/Spiked Log.nem"
		even
Nem_PplRock:	binclude	"Objects/Zone/GHZ/Cells/Purple Rock.nem"
		even
Nem_GhzWall1:	binclude	"Objects/Zone/GHZ/Cells/Breakable Wall.nem"
		even
Nem_GhzWall2:	binclude	"Objects/Zone/GHZ/Cells/Edge Wall.nem"
		even

; ---------------------------------------------------------------------------
; Compressed graphics - LZ stuff
; ---------------------------------------------------------------------------
Nem_Water:	binclude	"Objects/Zone/LZ/Cells/Water Surface.nem"
		even
Nem_Splash:	binclude	"Objects/Zone/LZ/Cells/Water & Splashes.nem"
		even
Nem_LzSpikeBall:binclude	"Objects/Zone/LZ/Cells/Spiked Ball and Chain.nem"
		even
Nem_FlapDoor:	binclude	"Objects/Zone/LZ/Cells/Flapping Door.nem"
		even
Nem_Bubbles:	binclude	"Objects/Zone/LZ/Cells/Bubbles & Countdown.nem"
		even
Nem_LzBlock3:	binclude	"Objects/Zone/LZ/Cells/32x16 Block.nem"
		even
Nem_LzDoor1:	binclude	"Objects/Zone/LZ/Cells/Vertical Door.nem"
		even
Nem_Harpoon:	binclude	"Objects/Zone/LZ/Cells/Harpoon.nem"
		even
Nem_LzPole:	binclude	"Objects/Zone/LZ/Cells/Breakable Pole.nem"
		even
Nem_LzDoor2:	binclude	"Objects/Zone/LZ/Cells/Horizontal Door.nem"
		even
Nem_LzWheel:	binclude	"Objects/Zone/LZ/Cells/Wheel.nem"
		even
Nem_Gargoyle:	binclude	"Objects/Zone/LZ/Cells/Gargoyle & Fireball.nem"
		even
Nem_LzBlock2:	binclude	"Objects/Zone/LZ/Cells/Blocks.nem"
		even
Nem_LzPlatfm:	binclude	"Levels/LZ/Cells/Rising Platform.nem"
		even
Nem_Cork:	binclude	"Levels/LZ/Cells/Cork.nem"
		even
Nem_LzBlock1:	binclude	"Objects/Zone/LZ/Cells/32x32 Block.nem"
		even

; ---------------------------------------------------------------------------
; Compressed graphics - MZ stuff
; ---------------------------------------------------------------------------
Nem_MzMetal:	binclude	"Levels/MZ/Cells/Metal Blocks.nem"
		even
Nem_MzSwitch:	binclude	"Objects/Zone/MZ/Cells/Switch.nem"
		even
Nem_MzGlass:	binclude	"Objects/Zone/MZ/Cells/Green Glass Block.nem"
		even
Nem_UnkGrass:	binclude	"Levels/GHZ/Cells/Unused/Grass.nem"
		even
Nem_MzFire:	binclude	"Objects/Zone/Shared/Cells/Fireballs.nem"
		even
Nem_Lava:	binclude	"Levels/MZ/Cells/Lava.nem"
		even
Nem_MzBlock:	binclude	"Objects/Zone/MZ/Cells/Green Pushable Block.nem"
		even
Nem_MzUnkBlock:	binclude	"Levels/MZ/Cells/Unused/Background.nem"
		even

; ---------------------------------------------------------------------------
; Compressed graphics - SLZ stuff
; ---------------------------------------------------------------------------
Nem_Seesaw:	binclude	"Objects/Zone/SLZ/Cells/Seesaw.nem"
		even
Nem_SlzSpike:	binclude	"Levels/SLZ/Cells/Little Spikeball.nem"
		even
Nem_Fan:	binclude	"Objects/Zone/SLZ/Cells/Fan.nem"
		even
Nem_SlzWall:	binclude	"Objects/Zone/SLZ/Cells/Breakable Wall.nem"
		even
Nem_Pylon:	binclude	"Objects/Zone/SLZ/Cells/Pylon.nem"
		even
Nem_SlzSwing:	binclude	"Objects/Zone/SLZ/Cells/Swinging Platform.nem"
		even
Nem_SlzBlock:	binclude	"Levels/SLZ/Cells/32x32 Block.nem"
		even
Nem_SlzCannon:	binclude	"Objects/Zone/SLZ/Cells/Cannon.nem"
		even

; ---------------------------------------------------------------------------
; Compressed graphics - SYZ stuff
; ---------------------------------------------------------------------------
Nem_Bumper:	binclude	"Objects/Zone/SYZ/Cells/Bumper.nem"
		even
Nem_SyzSpike2:	binclude	"Objects/Zone/SYZ/Cells/Small Spikeball.nem"
		even
Nem_LzSwitch:	binclude	"Objects/Zone/Shared/Cells/Switch.nem"
		even
Nem_SyzSpike1:	binclude	"Objects/Zone/SYZ/Cells/Large Spikeball.nem"
		even

; ---------------------------------------------------------------------------
; Compressed graphics - SBZ stuff
; ---------------------------------------------------------------------------
Nem_SbzWheel1:	binclude	"Objects/Zone/SBZ/Cells/Running Disc.nem"
		even
Nem_SbzWheel2:	binclude	"Objects/Zone/SBZ/Cells/Junction Wheel.nem"
		even
Nem_Cutter:	binclude	"Objects/Zone/SBZ/Cells/Pizza Cutter.nem"
		even
Nem_Stomper:	binclude	"Objects/Zone/SBZ/Cells/Stomper.nem"
		even
Nem_SpinPform:	binclude	"Objects/Zone/SBZ/Cells/Spinning Platform.nem"
		even
Nem_TrapDoor:	binclude	"Objects/Zone/SBZ/Cells/Trapdoor.nem"
		even
Nem_SbzFloor:	binclude	"Objects/Zone/SBZ/Cells/Collapsing Floor.nem"
		even
Nem_Electric:	binclude	"Objects/Zone/SBZ/Cells/Electrocuter.nem"
		even
Nem_SbzBlock:	binclude	"Objects/Zone/SBZ/Cells/Vanishing Block.nem"
		even
Nem_FlamePipe:	binclude	"Objects/Zone/SBZ/Cells/Flaming Pipe.nem"
		even
Nem_SbzDoor1:	binclude	"Objects/Zone/SBZ/Cells/Small Vertical Door.nem"
		even
Nem_SlideFloor:	binclude	"Levels/SBZ/Cells/Sliding Floor Trap.nem"
		even
Nem_SbzDoor2:	binclude	"Objects/Zone/SBZ/Cells/Large Horizontal Door.nem"
		even
Nem_Girder:	binclude	"Objects/Zone/SBZ/Cells/Crushing Girder.nem"
		even

; ---------------------------------------------------------------------------
; Compressed graphics - enemies
; ---------------------------------------------------------------------------
Nem_BallHog:	binclude	"Objects/Badniks/Cells/Ball Hog.nem"
		even
Nem_Crabmeat:	binclude	"Objects/Badniks/Cells/Crabmeat.nem"
		even
Nem_Buzz:	binclude	"Objects/Badniks/Cells/Buzz Bomber.nem"
		even
Nem_UnkExplode:	binclude	"Objects/Unused/Cells/Explosion.nem"
		even
Nem_Burrobot:	binclude	"Objects/Badniks/Cells/Burrobot.nem"
		even
Nem_Chopper:	binclude	"Objects/Badniks/Cells/Chopper.nem"
		even
Nem_Jaws:	binclude	"Objects/Badniks/Cells/Jaws.nem"
		even
Nem_Roller:	binclude	"Objects/Badniks/Cells/Roller.nem"
		even
Nem_Motobug:	binclude	"Objects/Badniks/Cells/Motobug.nem"
		even
Nem_Newtron:	binclude	"Objects/Badniks/Cells/Newtron.nem"
		even
Nem_Yadrin:	binclude	"Objects/Badniks/Cells/Yadrin.nem"
		even
Nem_Basaran:	binclude	"Objects/Badniks/Cells/Basaran.nem"
		even
Nem_Splats:	binclude	"Objects/Unused/Cells/Splats.nem"
		even
Nem_Bomb:	binclude	"Objects/Badniks/Cells/Bomb.nem"
		even
Nem_Orbinaut:	binclude	"Objects/Badniks/Cells/Orbinaut.nem"
		even
Nem_Cater:	binclude	"Objects/Badniks/Cells/Caterkiller.nem"
		even

; ---------------------------------------------------------------------------
; Compressed graphics - various
; ---------------------------------------------------------------------------
Nem_TitleCard:	binclude	"Objects/Cards/Cells/Title Cards.nem"
		even
Nem_Hud:	binclude	"Objects/Cards/Cells/HUD Text.nem" ; HUD (rings, time, score)
		even
Nem_Lives:	binclude	"Objects/Cards/Cells/Life Icon.nem"
		even
Nem_Ring:	binclude	"Objects/Global/Cells/Ring.nem"
		even
Nem_Monitors:	binclude	"Objects/Global/Cells/Monitor.nem"
		even
Nem_Explode:	binclude	"Objects/Effects/Cells/Explosion.nem"
		even
Nem_Points:	binclude	"Objects/Effects/Cells/Points.nem" ; points from destroyed enemy or object
		even
Nem_GameOver:	binclude	"Objects/Cards/Cells/Game Over.nem" ; game over / time over
		even
Nem_HSpring:	binclude	"Objects/Global/Cells/Spring Horizontal.nem"
		even
Nem_VSpring:	binclude	"Objects/Global/Cells/Spring Vertical.nem"
		even
Nem_SignPost:	binclude	"Objects/Global/Cells/Signpost.nem" ; end of level signpost
		even
Nem_Lamp:	binclude	"Objects/Global/Cells/Lamppost.nem"
		even
Nem_BigFlash:	binclude	"Objects/Global/Cells/Giant Ring Flash.nem"
		even
Nem_Bonus:	binclude	"Objects/Effects/Cells/Hidden Points.nem" ; hidden bonuses at end of a level
		even

; ---------------------------------------------------------------------------
; Compressed graphics - continue screen
; ---------------------------------------------------------------------------
Nem_ContSonic:	binclude	"Modes/Cells/Sonic (Continue Screen).nem"
		even
Nem_MiniSonic:	binclude	"Modes/Cells/Continue Screen.nem"
		even

; ---------------------------------------------------------------------------
; Compressed graphics - animals
; ---------------------------------------------------------------------------
Nem_Rabbit:	binclude	"Objects/Effects/Cells/Animal Rabbit.nem"
		even
Nem_Chicken:	binclude	"Objects/Effects/Cells/Animal Chicken.nem"
		even
Nem_Penguin:	binclude	"Objects/Effects/Cells/Animal Penguin.nem"
		even
Nem_Seal:	binclude	"Objects/Effects/Cells/Animal Seal.nem"
		even
Nem_Pig:	binclude	"Objects/Effects/Cells/Animal Pig.nem"
		even
Nem_Flicky:	binclude	"Objects/Effects/Cells/Animal Flicky.nem"
		even
Nem_Squirrel:	binclude	"Objects/Effects/Cells/Animal Squirrel.nem"
		even

; ---------------------------------------------------------------------------
; Compressed graphics - primary patterns and block mappings
; ---------------------------------------------------------------------------
Blk16_GHZ:	binclude	"Levels/GHZ/Blocks.eni"
		even
Nem_GHZ_1st:	binclude	"Levels/GHZ/Cells.nem"
		even
Nem_GHZ_2nd:	binclude	"Levels/GHZ/Cells/2nd Cells.nem"
		even
Blk256_GHZ:	binclude	"Levels/GHZ/Chunks.kos"
		even

Blk16_LZ:	binclude	"Levels/LZ/Blocks.eni"
		even
Nem_LZ:		binclude	"Levels/LZ/Cells.nem"
		even
Blk256_LZ:	binclude	"Levels/LZ/Chunks.kos"
		even

Blk16_MZ:	binclude	"Levels/MZ/Blocks.eni"
		even
Nem_MZ:		binclude	"Levels/MZ/Cells.nem"
		even
Blk256_MZ:
	if Revision=0
		binclude	"Levels/MZ/Chunks (REV00).kos"
		even
	else
		binclude	"Levels/MZ/Chunks (REV01).kos"
		even
	endif

Blk16_SLZ:	binclude	"Levels/SLZ/Blocks.eni"
		even
Nem_SLZ:	binclude	"Levels/SLZ/Cells.nem"
		even
Blk256_SLZ:	binclude	"Levels/SLZ/Chunks.kos"
		even

Blk16_SYZ:	binclude	"Levels/SYZ/Blocks.eni"
		even
Nem_SYZ:	binclude	"Levels/SYZ/Cells.nem"
		even
Blk256_SYZ:	binclude	"Levels/SYZ/Chunks.kos"
		even

Blk16_SBZ:	binclude	"Levels/SBZ/Blocks.eni"
		even
Nem_SBZ:	binclude	"Levels/SBZ/Cells.nem"
		even
Blk256_SBZ:
	if Revision=0
		binclude	"Levels/SBZ/Chunks (REV00).kos"
		even
	else
		binclude	"Levels/SBZ/Chunks (REV01).kos"
		even
	endif

; ---------------------------------------------------------------------------
; Compressed graphics - bosses and ending sequence
; ---------------------------------------------------------------------------
Nem_Eggman:	binclude	"Objects/Bosses/Cells/Main.nem"
		even
Nem_Weapons:	binclude	"Objects/Bosses/Cells/Weapons.nem"
		even
Nem_Prison:	binclude	"Objects/Global/Cells/Prison Capsule.nem"
		even
Nem_Sbz2Eggman:	binclude	"Objects/Bosses/Cells/Eggman (SBZ2 & FZ).nem"
		even
Nem_FzBoss:	binclude	"Objects/Bosses/Cells/Egg Crusher.nem"
		even
Nem_FzEggman:	binclude	"Objects/Bosses/Cells/Eggman (After Crusher).nem"
		even
Nem_Exhaust:	binclude	"Objects/Bosses/Cells/Exhaust Flame.nem"
		even
Nem_EndEm:	binclude	"Modes/Cells/End Emeralds.nem"
		even
Nem_EndSonic:	binclude	"Modes/Cells/Sonic (End Cutscene).nem"
		even
Nem_TryAgain:	binclude	"Modes/Cells/Try Again.nem"
		even
	if Revision=0
Nem_EndEggman:
		binclude	"Modes/Cells/Unused/End Eggman.nem"
		even
	endif
Kos_EndFlowers:	binclude	"Levels/GHZ/Cells/End Cutscene Flowers.kos" ; ending sequence animated flowers
		even
Nem_EndFlower:	binclude	"Levels/GHZ/Cells/End Flowers.nem"
		even
Nem_CreditText:	binclude	"Modes/Cells/Credits.nem"
		even
Nem_EndStH:	binclude	"Modes/Cells/STH Logo.nem"
		even

; ---------------------------------------------------------------------------

		; AngleMap starts at $62900 in all revisions, which amounts
		; to $104 bytes of padding for rev00 and $40 for rev01/rev02.
		; From a technical standpoint, this padding serves no purpose.
	if PaddingOptimization=0
		if Revision=0
			dcb.b	$104,$FF
		else
			dcb.b	$40,$FF
		endif
	endif

; ---------------------------------------------------------------------------
; Collision data
; ---------------------------------------------------------------------------
AngleMap:	binclude	"Levels/Collision/Angle Map.bin"
		even
CollArray1:	binclude	"Levels/Collision/Collision Array (Normal).bin"
		even
CollArray2:	binclude	"Levels/Collision/Collision Array (Rotated).bin"
		even
Col_GHZ:	binclude	"Levels/GHZ/Collision.bin" ; GHZ index
		even
Col_LZ:		binclude	"Levels/LZ/Collision.bin" ; LZ index
		even
Col_MZ:		binclude	"Levels/MZ/Collision.bin" ; MZ index
		even
Col_SLZ:	binclude	"Levels/SLZ/Collision.bin" ; SLZ index
		even
Col_SYZ:	binclude	"Levels/SYZ/Collision.bin" ; SYZ index
		even
Col_SBZ:	binclude	"Levels/SBZ/Collision.bin" ; SBZ index
		even

; ---------------------------------------------------------------------------
; Special Stage layouts
; ---------------------------------------------------------------------------
SS_1:		binclude	"Levels/Special/Layouts/1.eni"
		even
SS_2:		binclude	"Levels/Special/Layouts/2.eni"
		even
SS_3:		binclude	"Levels/Special/Layouts/3.eni"
		even
SS_4:		binclude	"Levels/Special/Layouts/4.eni"
		even
	if Revision=0
SS_5:		binclude	"Levels/Special/Layouts/5 (REV00).eni"
		even
SS_6:		binclude	"Levels/Special/Layouts/6 (REV00).eni"
		even
	else
		; SS 5 and 6 had broken objects outside the accessible Layout;
		; REV01 removes those - remaining Layouts stay unchanged.
SS_5:		binclude	"Levels/Special/Layouts/5 (REV01).eni"
		even
SS_6:		binclude	"Levels/Special/Layouts/6 (REV01).eni"
		even
	endif

; ---------------------------------------------------------------------------
; Animated uncompressed graphics
; ---------------------------------------------------------------------------
Art_GhzWater:	binclude	"Levels/GHZ/Cells/Waterfall.unc"
		even
Art_GhzFlower1:	binclude	"Levels/GHZ/Cells/Sunflower.unc"
		even
Art_GhzFlower2:	binclude	"Levels/GHZ/Cells/Small Flower.unc"
		even
Art_MzLava1:	binclude	"Levels/MZ/Cells/Lava Surface.unc"
		even
Art_MzLava2:	binclude	"Levels/MZ/Cells/Lava.unc"
		even
Art_MzTorch:	binclude	"Levels/MZ/Cells/Background Torch.unc"
		even
Art_SbzSmoke:	binclude	"Levels/SBZ/Cells/Background Smoke.unc"
		even

; ---------------------------------------------------------------------------
; Level layout index
; Format: foreground, background, leftover/unused
; ---------------------------------------------------------------------------
Level_Index:
		; GHZ
		dc.w Level_GHZ1-Level_Index, Level_GHZbg-Level_Index, Level_GHZ1Unk-Level_Index
		dc.w Level_GHZ2-Level_Index, Level_GHZbg-Level_Index, Level_GHZ2Unk-Level_Index
		dc.w Level_GHZ3-Level_Index, Level_GHZbg-Level_Index, Level_GHZ3Unk-Level_Index
		dc.w Level_GHZ4Unk-Level_Index, Level_GHZ4Unk-Level_Index, Level_GHZ4Unk-Level_Index
		; LZ
		dc.w Level_LZ1-Level_Index, Level_LZbg-Level_Index, Level_LZ1Unk-Level_Index
		dc.w Level_LZ2-Level_Index, Level_LZbg-Level_Index, Level_LZ2Unk-Level_Index
		dc.w Level_LZ3-Level_Index, Level_LZbg-Level_Index, Level_LZ3Unk-Level_Index
		dc.w Level_SBZ3-Level_Index, Level_LZbg-Level_Index, Level_SBZ3Unk-Level_Index
		; MZ
		dc.w Level_MZ1-Level_Index, Level_MZ1bg-Level_Index, Level_MZ1-Level_Index
		dc.w Level_MZ2-Level_Index, Level_MZ2bg-Level_Index, Level_MZ2Unk-Level_Index
		dc.w Level_MZ3-Level_Index, Level_MZ3bg-Level_Index, Level_MZ3Unk-Level_Index
		dc.w Level_MZ4Unk-Level_Index, Level_MZ4Unk-Level_Index, Level_MZ4Unk-Level_Index
		; SLZ
		dc.w Level_SLZ1-Level_Index, Level_SLZbg-Level_Index, Level_SLZ1Unk-Level_Index
		dc.w Level_SLZ2-Level_Index, Level_SLZbg-Level_Index, Level_SLZ1Unk-Level_Index
		dc.w Level_SLZ3-Level_Index, Level_SLZbg-Level_Index, Level_SLZ1Unk-Level_Index
		dc.w Level_SLZ1Unk-Level_Index, Level_SLZ1Unk-Level_Index, Level_SLZ1Unk-Level_Index
		; SYZ
		dc.w Level_SYZ1-Level_Index, Level_SYZbg-Level_Index, Level_SYZ1Unk-Level_Index
		dc.w Level_SYZ2-Level_Index, Level_SYZbg-Level_Index, Level_SYZ2Unk-Level_Index
		dc.w Level_SYZ3-Level_Index, Level_SYZbg-Level_Index, Level_SYZ3Unk-Level_Index
		dc.w Level_SYZ4Unk-Level_Index, Level_SYZ4Unk-Level_Index, Level_SYZ4Unk-Level_Index
		; SBZ
		dc.w Level_SBZ1-Level_Index, Level_SBZ1bg-Level_Index, Level_SBZ1bg-Level_Index
		dc.w Level_SBZ2-Level_Index, Level_SBZ2bg-Level_Index, Level_SBZ2bg-Level_Index
		dc.w Level_SBZ2-Level_Index, Level_SBZ2bg-Level_Index, Level_SBZ2Unk-Level_Index
		dc.w Level_SBZ4Unk-Level_Index, Level_SBZ4Unk-Level_Index, Level_SBZ4Unk-Level_Index
		zonewarning Level_Index,24
		; Ending
		dc.w Level_End-Level_Index, Level_GHZbg-Level_Index, Level_EndUnk-Level_Index
		dc.w Level_End-Level_Index, Level_GHZbg-Level_Index, Level_EndUnk-Level_Index
		dc.w Level_EndUnk-Level_Index, Level_EndUnk-Level_Index, Level_EndUnk-Level_Index
		dc.w Level_EndUnk-Level_Index, Level_EndUnk-Level_Index, Level_EndUnk-Level_Index

Level_GHZ1:	binclude	"Levels/GHZ/Act 1/Layout.bin"
		even
Level_GHZ1Unk:	dc.l 0
Level_GHZ2:	binclude	"Levels/GHZ/Act 2/Layout.bin"
		even
Level_GHZ2Unk:	dc.l 0
Level_GHZ3:	binclude	"Levels/GHZ/Act 3/Layout.bin"
		even
Level_GHZbg:	binclude	"Levels/GHZ/Background.bin"
		even
Level_GHZ3Unk:	dc.l 0
Level_GHZ4Unk:	dc.l 0

Level_LZ1:	binclude	"Levels/LZ/Act 1/Layout.bin"
		even
Level_LZbg:	binclude	"Levels/LZ/Background.bin"
		even
Level_LZ1Unk:	dc.l 0
Level_LZ2:	binclude	"Levels/LZ/Act 2/Layout.bin"
		even
Level_LZ2Unk:	dc.l 0
Level_LZ3:	binclude	"Levels/LZ/Act 3/Layout.bin"
		even
Level_LZ3Unk:	dc.l 0
Level_SBZ3:	binclude	"Levels/SBZ/Act 3/Layout.bin"
		even
Level_SBZ3Unk:	dc.l 0

Level_MZ1:	binclude	"Levels/MZ/Act 1/Layout.bin"
		even
Level_MZ1bg:	binclude	"Levels/MZ/Act 1/Background.bin"
		even
Level_MZ2:	binclude	"Levels/MZ/Act 2/Layout.bin"
		even
Level_MZ2bg:	binclude	"Levels/MZ/Act 2/Background.bin"
		even
Level_MZ2Unk:	dc.l 0
Level_MZ3:	binclude	"Levels/MZ/Act 3/Layout.bin"
		even
Level_MZ3bg:	binclude	"Levels/MZ/Act 3/Background.bin"
		even
Level_MZ3Unk:	dc.l 0
Level_MZ4Unk:	dc.l 0

Level_SLZ1:	binclude	"Levels/SLZ/Act 1/Layout.bin"
		even
Level_SLZbg:	binclude	"Levels/SLZ/Background.bin"
		even
Level_SLZ2:	binclude	"Levels/SLZ/Act 2/Layout.bin"
		even
Level_SLZ3:	binclude	"Levels/SLZ/Act 3/Layout.bin"
		even
Level_SLZ1Unk:	dc.l 0

Level_SYZ1:	binclude	"Levels/SYZ/Act 1/Layout.bin"
		even
Level_SYZbg:
	if Revision=0
		binclude	"Levels/SYZ/Background (REV00).bin"
	else
		binclude	"Levels/SYZ/Background (REV01).bin"
	endif
		even
Level_SYZ1Unk:	dc.l 0
Level_SYZ2:	binclude	"Levels/SYZ/Act 2/Layout.bin"
		even
Level_SYZ2Unk:	dc.l 0
Level_SYZ3:	binclude	"Levels/SYZ/Act 3/Layout.bin"
		even
Level_SYZ3Unk:	dc.l 0
Level_SYZ4Unk:	dc.l 0

Level_SBZ1:	binclude	"Levels/SBZ/Act 1/Layout.bin"
		even
Level_SBZ1bg:	binclude	"Levels/SBZ/Act 1/Background.bin"
		even
Level_SBZ2:	binclude	"Levels/SBZ/Act 2/Layout.bin"
		even
Level_SBZ2bg:	binclude	"Levels/SBZ/Act 2/Background.bin"
		even
Level_SBZ2Unk:	dc.l 0
Level_SBZ4Unk:	dc.l 0
Level_End:	binclude	"Levels/GHZ/Ending/Layout.bin"
		even
Level_EndUnk:	dc.l 0

; ---------------------------------------------------------------------------
; Uncompressed graphics - Giant Rings
; ---------------------------------------------------------------------------
Art_BigRing:	binclude	"Objects/Global/Cells/Giant Ring.unc"
Art_BigRing_size:	equ	*-Art_BigRing
		even

; ---------------------------------------------------------------------------

		; ObjPos_Index starts at $6B000 in all revisions, which amounts
		; to $9C bytes of padding for rev00 and $DC for rev01/rev02.
		; From a technical standpoint, this padding serves no purpose.
	if PaddingOptimization=0
		align	$100
	endif

; ---------------------------------------------------------------------------
; Sprite locations index
; ---------------------------------------------------------------------------
ObjPos_Index:
		; GHZ
		dc.w ObjPos_GHZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_GHZ2-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_GHZ3-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_GHZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		; LZ
		dc.w ObjPos_LZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_LZ2-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_LZ3-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SBZ3-ObjPos_Index, ObjPos_Null-ObjPos_Index
		; MZ
		dc.w ObjPos_MZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_MZ2-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_MZ3-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_MZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		; SLZ
		dc.w ObjPos_SLZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SLZ2-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SLZ3-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SLZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		; SYZ
		dc.w ObjPos_SYZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SYZ2-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SYZ3-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SYZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		; SBZ
		dc.w ObjPos_SBZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SBZ2-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_FZ-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SBZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		zonewarning ObjPos_Index,$10
		; Ending
		dc.w ObjPos_End-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_End-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_End-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_End-ObjPos_Index, ObjPos_Null-ObjPos_Index
		; --- Put extra object data here. ---
ObjPosLZPlatform_Index:
		dc.w ObjPos_LZ1pf1-ObjPos_Index, ObjPos_LZ1pf2-ObjPos_Index
		dc.w ObjPos_LZ2pf1-ObjPos_Index, ObjPos_LZ2pf2-ObjPos_Index
		dc.w ObjPos_LZ3pf1-ObjPos_Index, ObjPos_LZ3pf2-ObjPos_Index
		dc.w ObjPos_LZ1pf1-ObjPos_Index, ObjPos_LZ1pf2-ObjPos_Index
ObjPosSBZPlatform_Index:
		dc.w ObjPos_SBZ1pf1-ObjPos_Index, ObjPos_SBZ1pf2-ObjPos_Index
		dc.w ObjPos_SBZ1pf3-ObjPos_Index, ObjPos_SBZ1pf4-ObjPos_Index
		dc.w ObjPos_SBZ1pf5-ObjPos_Index, ObjPos_SBZ1pf6-ObjPos_Index
		dc.w ObjPos_SBZ1pf1-ObjPos_Index, ObjPos_SBZ1pf2-ObjPos_Index
		dc.b $FF, $FF, 0, 0, 0,	0

ObjPos_GHZ1:	binclude	"Levels/GHZ/Act 1/Objects.bin"
		even
ObjPos_GHZ2:	binclude	"Levels/GHZ/Act 2/Objects.bin"
		even
ObjPos_GHZ3:
	if Revision=0
		binclude	"Levels/GHZ/Act 3/Objects (REV00).bin"
		even
	else
		binclude	"Levels/GHZ/Act 3/Objects (REV01).bin"
		even
	endif

ObjPos_LZ1:
	if Revision=0
		binclude	"Levels/LZ/Act 1/Objects (REV00).bin"
		even
	else
		binclude	"Levels/LZ/Act 1/Objects (REV01).bin"
		even
	endif
ObjPos_LZ2:	binclude	"Levels/LZ/Act 2/Objects.bin"
		even
ObjPos_LZ3:
	if Revision=0
		binclude	"Levels/LZ/Act 3/Objects (REV00).bin"
		even
	else
		binclude	"Levels/LZ/Act 3/Objects (REV01).bin"
		even
	endif
ObjPos_SBZ3:	binclude	"Levels/SBZ/Act 3/Objects.bin"
		even

ObjPos_LZ1pf1:	binclude	"Levels/LZ/Act 1/Platforms/1.bin"
		even
ObjPos_LZ1pf2:	binclude	"Levels/LZ/Act 1/Platforms/2.bin"
		even
ObjPos_LZ2pf1:	binclude	"Levels/LZ/Act 2/Platforms/1.bin"
		even
ObjPos_LZ2pf2:	binclude	"Levels/LZ/Act 2/Platforms/2.bin"
		even
ObjPos_LZ3pf1:	binclude	"Levels/LZ/Act 3/Platforms/1.bin"
		even
ObjPos_LZ3pf2:	binclude	"Levels/LZ/Act 3/Platforms/2.bin"
		even

ObjPos_MZ1:
	if Revision=0
		binclude	"Levels/MZ/Act 1/Objects (REV00).bin"
		even
	else
		binclude	"Levels/MZ/Act 1/Objects (REV01).bin"
		even
	endif
ObjPos_MZ2:	binclude	"Levels/MZ/Act 2/Objects.bin"
		even
ObjPos_MZ3:	binclude	"Levels/MZ/Act 3/Objects.bin"
		even

ObjPos_SLZ1:	binclude	"Levels/SLZ/Act 1/Objects.bin"
		even
ObjPos_SLZ2:	binclude	"Levels/SLZ/Act 2/Objects.bin"
		even
ObjPos_SLZ3:	binclude	"Levels/SLZ/Act 3/Objects.bin"
		even
ObjPos_SYZ1:	binclude	"Levels/SYZ/Act 1/Objects.bin"
		even
ObjPos_SYZ2:	binclude	"Levels/SYZ/Act 2/Objects.bin"
		even
ObjPos_SYZ3:
	if Revision=0
		binclude	"Levels/SYZ/Act 3/Objects (REV00).bin"
		even
	else
		binclude	"Levels/SYZ/Act 3/Objects (REV01).bin"
		even
	endif

ObjPos_SBZ1:
	if Revision=0
		binclude	"Levels/SBZ/Act 1/Objects (REV00).bin"
		even
	else
		binclude	"Levels/SBZ/Act 1/Objects (REV01).bin"
		even
	endif
ObjPos_SBZ2:	binclude	"Levels/SBZ/Act 2/Objects.bin"
		even
ObjPos_FZ:	binclude	"Levels/SBZ/Final/Objects.bin"
		even

ObjPos_SBZ1pf1:	binclude	"Levels/SBZ/Act 1/Platforms/1.bin"
		even
ObjPos_SBZ1pf2:	binclude	"Levels/SBZ/Act 1/Platforms/2.bin"
		even
ObjPos_SBZ1pf3:	binclude	"Levels/SBZ/Act 1/Platforms/3.bin"
		even
ObjPos_SBZ1pf4:	binclude	"Levels/SBZ/Act 1/Platforms/4.bin"
		even
ObjPos_SBZ1pf5:	binclude	"Levels/SBZ/Act 1/Platforms/5.bin"
		even
ObjPos_SBZ1pf6:	binclude	"Levels/SBZ/Act 1/Platforms/6.bin"
		even

ObjPos_End:	binclude	"Levels/GHZ/Ending/Objects.bin"
		even

ObjPos_Null:	dc.b $FF, $FF, 0, 0, 0,	0

; ---------------------------------------------------------------------------

		; SoundDriver starts at $71990 in all revisions, which amounts
		; to $62A bytes of padding for rev00 and $63C for rev01/rev02.
		; It appears to be placed in such a way that the sound driver
		; ends right on the $80000 mark in the ROM in all revisions.
		; From a technical standpoint, this padding serves no purpose.
	if PaddingOptimization=0
		if Revision=0
			dcb.b	$62A,$FF
		else
			dcb.b	$63C,$FF
		endif
	endif

; ---------------------------------------------------------------------------

SoundDriver:	include "Sound/Driver.asm"
		even

; ---------------------------------------------------------------------------

; end of 'ROM'
EndOfRom:

		END
