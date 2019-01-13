title "Assembler Program for PIC Microcontroller"

; =============================================================================
; Author: Kyle Pinto
; Date:
;
; Hardware I/O Configuration:
; SPI Data IO: RB5
; SPI Clock: RB6
; SPI Slave Select: RB7
; Potentiometer: RA4 (AN3)
; Button: RA5
;
; Program Description:
; This is the SPI Master controller code.  Data is sent and receive on the SDIO
; pin (RB5).  Unlike conventional SPI, entire bytes of data are sent before the
; new byte is received.  The slave select pin (RB7) enables SPI transfer when 
; driven low and disables it when high.  The clock pin (RB6) is driven in pulses
; to schedule the transfer of each bit of data between the slave and the master.
; Data is sent on the falling edge and received on the rising edge. Data is sent 
; bi-directionally on the same wire by alterating the tristate of the SDIO pin 
; between input and output.  This program demos this verison of the SPI protocol.
; The user can select the 8-bit number they wish to send using a potentiometer.
; Pressing the button will shift the data over to the slave using the SPI protocol.
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

; SPI Pins ;

#define SDIO PORTB,5
#define SDIOTRIS TRISB,5
#define SCK PORTB,6
#define SS PORTB,7

; -----------------------------------------------------------------------------
PAGE

; MAIN PROGRAM ;

; INIT ;

org 0
call INIT_HARDWARE
clrw
clrf REGISTER
banksel PORTC
clrf PORTC
call RUN_TIMER

; MAIN LOOP ;

START

WAIT_FOR_BUTTON_DOWN
call USER_INPUT
banksel PORTA
btfss PORTA,5
goto WAIT_FOR_BUTTON_DOWN

WAIT_FOR_BUTTON_UP
banksel PORTA
btfsc PORTA,5
goto WAIT_FOR_BUTTON_UP

movf ADRESH,W
movwf REGISTER

banksel PORTB
bcf SS

call RUN_SPI_SEND

banksel PORTB
bsf SS

call RUN_TIMER
call RUN_TIMER
call RUN_TIMER

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
movlw b'00110000'
movwf TRISA

banksel TRISB
movlw b'00000000'
movwf TRISB

banksel TRISC
movlw b'00000000'
movwf TRISC

; SET DIGITAL / ANALOGUE ;
; Digital = 0, Analogue = 1

banksel ANSEL
movlw b'00001000'
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

; ADC SETUP ;

banksel ADCON0
movlw b'00001101'
movwf ADCON0

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
movlw 32
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

RUN_ADC
; ~~~~~~~~~~~~~~ ;
banksel ADCON0
bsf ADCON0,1
WAIT_FOR_ADC
btfsc ADCON0,1
goto WAIT_FOR_ADC
return
; ~~~~~~~~~~~~~~ ;

USER_INPUT
; ~~~~~~~~~~~~~~ ;
call RUN_ADC
movf ADRESH,W
banksel PORTC
movwf PORTC
return
; ~~~~~~~~~~~~~~ ;

;--------------------------------------------------SPI----------------------------------------------;

SEND_DATA
; ~~~~~~~~~~~~~~ ;
rlf REGISTER,F
bcf REGISTER,0
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
movf REGISTER,W
banksel PORTC
movwf PORTC
return
; ~~~~~~~~~~~~~~ ;

RUN_SPI_SEND
; ~~~~~~~~~~~~~~ ;
movlw 8
movwf CLOCK

banksel TRISB
bcf SDIOTRIS

bsf SCK
call RUN_TIMER

SEND_SLAVE_DATA

movf CLOCK,F
btfsc STATUS,Z
goto DONE_SENDING

decf CLOCK,F

bcf SCK
call RUN_TIMER

call SEND_DATA
call RUN_TIMER

bsf SCK
call RUN_TIMER

goto SEND_SLAVE_DATA

DONE_SENDING
clrf PORTC
return
; ~~~~~~~~~~~~~~ ;

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

RUN_SPI_RECEIVE
; ~~~~~~~~~~~~~~ ;
movlw 8
movwf CLOCK

banksel TRISB
bsf SDIOTRIS

bsf SCK
call RUN_TIMER

RECEIVE_SLAVE_DATA

movf CLOCK,F
btfsc STATUS,Z
goto DONE_RECEIVING

decf CLOCK,F

bcf SCK
call RUN_TIMER

bsf SCK
call RUN_TIMER

call RECEIVE_DATA
call RUN_TIMER

goto RECEIVE_SLAVE_DATA

DONE_RECEIVING
return
; ~~~~~~~~~~~~~~ ;

end