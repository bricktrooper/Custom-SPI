title "Assembler Program for PIC Microcontroller"

; =============================================================================
; Author: Kyle Pinto
; Date:
;
; Hardware I/O Configuration:
;
; Program Description:
; This is the SPI Slave controller code.  Data is sent and received on the SDIO
; pin (RB5).  Unlike conventional SPI, entire bytes of data are sent before the
; new byte is received.  The slave will only receive data when the master drives
; the slave select pin low. Data is sent on the falling edge and received on the 
; rising edge.  Data is sent bi-directionally on the same wire by alterating the
; tristate of the SDIO pin between input and output.
; =============================================================================

; -----------------------------------------------------------------------------

; SETUP ;

list R=DEC
include "p16f690.inc"

__config (_INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _BOR_OFF & _IESO_OFF & _FCMEN_OFF)

; -----------------------------------------------------------------------------

; VARIABLES ;
cblock 0x20
DELAY1
DELAY2
CLOCK
REGISTER
endc

#define SDIO PORTB,5
#define SDIOTRIS TRISB,5
#define SCK PORTB,6
#define SS PORTB,7

; -----------------------------------------------------------------------------
PAGE

; MAIN PROGRAM ;
org 0
call INIT_HARDWARE
clrw
clrf REGISTER

START

banksel PORTB
WAIT_FOR_SS_LOW
btfsc SS
goto WAIT_FOR_SS_LOW

WAIT_FOR_SS_HIGH
call RUN_SPI_RECEIVE
banksel PORTB
btfss SS
goto WAIT_FOR_SS_HIGH

goto START

goto $
	
; -----------------------------------------------------------------------------
PAGE

; SUBROUTINES ;

INIT_HARDWARE
; ~~~~~~~~~~~~~~ ;

; SET I/O PINS ;
; Output = 0, Input = 1

banksel TRISA
movlw b'00000000'
movwf TRISA

banksel TRISB
movlw b'11000000'
movwf TRISB

banksel TRISC
movlw b'00000000'
movwf TRISC

; SET DIGITAL / ANALOGUE ;
; Digital = 0, Analogue = 1

banksel ANSEL
movlw b'00000000'
movwf ANSEL

banksel ANSELH
movlw b'00000000'
movwf ANSELH

; INTIALIZE REGISTERS ;

banksel PORTA
movlw b'00000000'
movwf PORTA

banksel PORTB
movlw b'00000000'
movwf PORTB

banksel PORTC
movlw b'00000000'
movwf PORTC

call STARTUP_INDICATION

return
; ~~~~~~~~~~~~~~ ;

STARTUP_INDICATION
; ~~~~~~~~~~~~~~ ;
call RUN_TIMER
banksel PORTC
movlw b'00000000'
movwf PORTC

call RUN_TIMER
banksel PORTC
movlw b'00000001'
movwf PORTC

call RUN_TIMER
banksel PORTC
movlw b'00000011'
movwf PORTC

call RUN_TIMER
banksel PORTC
movlw b'00000111'
movwf PORTC

call RUN_TIMER
banksel PORTC
movlw b'00001111'
movwf PORTC

call RUN_TIMER
banksel PORTC
movlw b'00011111'
movwf PORTC

call RUN_TIMER
banksel PORTC
movlw b'00111111'
movwf PORTC

call RUN_TIMER
banksel PORTC
movlw b'01111111'
movwf PORTC

call RUN_TIMER
banksel PORTC
movlw b'11111111'
movwf PORTC

call RUN_TIMER
banksel PORTC
movlw b'00000000'
movwf PORTC

call RUN_TIMER
banksel PORTC
movlw b'11111111'
movwf PORTC

call RUN_TIMER
banksel PORTC
movlw b'00000000'
movwf PORTC

call RUN_TIMER
banksel PORTC
movlw b'11111111'
movwf PORTC

call RUN_TIMER
banksel PORTC
movlw b'00000000'
movwf PORTC

call RUN_TIMER
banksel PORTC
movlw b'11111111'
movwf PORTC

call RUN_TIMER
banksel PORTC
movlw b'0000000'
movwf PORTC

return
; ~~~~~~~~~~~~~~ ;

RESET_TIMER
; ~~~~~~~~~~~~~~ ;
movlw 255
movwf DELAY1
movlw 1
movwf DELAY2
return
; ~~~~~~~~~~~~~~ ;

RUN_TIMER
; ~~~~~~~~~~~~~~ ;
call RESET_TIMER
COUNTDOWN
decfsz DELAY1,F
goto COUNTDOWN
decfsz DELAY2,F
goto COUNTDOWN
return
; ~~~~~~~~~~~~~~ ;

;------------------------------SPI--------------------------------;

RECEIVE_DATA
; ~~~~~~~~~~~~~~ ;
banksel PORTB
btfsc SDIO
goto IN1
goto IN0

IN1
bsf STATUS,C
goto IN_DONE

IN0
bcf STATUS,C
goto IN_DONE

IN_DONE
rlf REGISTER,F
movf REGISTER,W
movwf PORTC
return
; ~~~~~~~~~~~~~~ ;

SEND_DATA
; ~~~~~~~~~~~~~~ ;
rlf REGISTER,F
btfsc STATUS,C
goto OUT1
goto OUT0

OUT1
banksel PORTB
bsf SDIO
goto OUT_DONE

OUT0
banksel PORTB
bcf SDIO
goto OUT_DONE

OUT_DONE
return
; ~~~~~~~~~~~~~~ ;

WAIT_FOR_SCK_FALL
; ~~~~~~~~~~~~~~ ;
banksel PORTB
btfsc SCK
goto WAIT_FOR_SCK_FALL
return
; ~~~~~~~~~~~~~~ ;

WAIT_FOR_SCK_RISE
; ~~~~~~~~~~~~~~ ;
banksel PORTB
btfss SCK
goto WAIT_FOR_SCK_RISE
return
; ~~~~~~~~~~~~~~ ;

RUN_SPI_RECEIVE
; ~~~~~~~~~~~~~~ ;
movlw 8
movwf CLOCK

banksel TRISB
bsf SDIOTRIS

RECEIVE_MASTER_DATA

movf CLOCK,F
btfsc STATUS,Z
return

decf CLOCK,F

call WAIT_FOR_SCK_FALL
call WAIT_FOR_SCK_RISE
call RECEIVE_DATA

goto RECEIVE_MASTER_DATA
; ~~~~~~~~~~~~~~ ;

RUN_SPI_SEND
; ~~~~~~~~~~~~~~ ;
movlw 8
movwf CLOCK

banksel TRISB
bcf SDIOTRIS

SEND_SLAVE_DATA

movf CLOCK,F
btfsc STATUS,Z
return

decf CLOCK,F

call WAIT_FOR_SCK_FALL
call SEND_DATA
call WAIT_FOR_SCK_RISE

goto SEND_SLAVE_DATA
; ~~~~~~~~~~~~~~ ;

end