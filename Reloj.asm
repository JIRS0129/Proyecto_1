;***************************
;                                                                              *
;    Filename: Clock	                                                       *
;    Date: 10/10/2018                                                          *
;    File Version:  2.0                                                        *
;    Author: Jose Ramirez                                                      *
;    Company: UVG                                                              *
;    Description:							       *
;                                                                              *
;***************************
; TODO INSERT INCLUDE CODE HERE
#include "p16f887.inc"

; CONFIG1
; __config 0xF0F1
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
;*********
GPR_VAR        UDATA
    ;	COUNTER		RES 1
	MENU_		RES 1	;CURRENT MENU VAR
	CURRENT_INC	RES 1	;CURRENT DISPLAY INCREASING (MM/HH OR DD/MM)
	SEGUNDOS	RES 1	;COUNTER TILL' 120 TO MAKE FOR A SECOND
	TRANSISTOR	RES 1	;CURRENT DISPLAY BEIGN REFRESHED
	;TIME VARS
	MINS_U		RES 1	
	MINS_D		RES 1
	HOURS_U		RES 1
	HOURS_D		RES 1
	;DATE VARS
	MONTH_U		RES 1
	MONTH_D		RES 1
	DATE_U		RES 1
	DATE_D		RES 1
	;ALARM VARS
	MINS_U_A	RES 1
	MINS_D_A	RES 1
	HOURS_U_A	RES 1
	HOURS_D_A	RES 1
	;DATE CONFIG VARS
	DATE		RES 1
	MONTH		RES 1
	;TIME CONFIG VARS
	HOURS		RES 1
	MINS		RES 1
	;ALARM CONFIG VARS
	HOURS_A		RES 1
	MINS_A		RES 1
	ALARM_E		RES 1
	ALARM_TIMER	RES 1
	;INTERRUPT BACKUP VARS
	W_TEMP		RES 1
	STATUS_TEMP	RES 1
	
	
;***************************************************************************;
;*********************************MACROS************************************;
;***************************************************************************;
	
;DISPLAYS UNIDADES_1 ON SEG0, DECENAS_1 ON SEG1 AND SO ON. 
	;TAKEN FROM JORGE LORENZANA
DISPLAY_M    MACRO   UNIDADES_1, DECENAS_1, UNIDADES_2, DECENAS_2
    LOCAL SEG0
    LOCAL SEG1
    LOCAL SEG2
    LOCAL SEG3
    LOCAL LAST
    INCF	TRANSISTOR
    CLRF	PORTC
    MOVF	TRANSISTOR, W
    ADDWF	PCL, F
    NOP
    GOTO    SEG0
    GOTO    SEG1
    GOTO    SEG2
    GOTO    SEG3
 SEG0:
    CLRF   PORTD
    MOVF    UNIDADES_1, W
    CALL    TABLA
    MOVWF   PORTC
    BSF	    PORTD, 0
    GOTO    LAST
 SEG1:
    CLRF   PORTD
    MOVF    DECENAS_1, W 
    CALL    TABLA
    MOVWF   PORTC
    BSF	    PORTD, 1
    GOTO    LAST
 SEG2:
    CLRF   PORTD
    MOVF    UNIDADES_2, W
    CALL    TABLA
    MOVWF   PORTC
    BSF	    PORTD, 2
    GOTO    LAST
 SEG3:
    CLRF   PORTD
    MOVF    DECENAS_2, W
    CALL    TABLA
    MOVWF   PORTC
    BSF	    PORTD, 3
    CLRF    TRANSISTOR
    GOTO    LAST
 LAST:
    NOP
    ENDM
    

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program
    
ISR_VECT CODE 0x004
 PUSH:
    MOVWF W_TEMP
    SWAPF STATUS,W
    MOVWF STATUS_TEMP
    
 ISR:
    BCF INTCON, GIE
    BTFSC INTCON, T0IF
    CALL INT_TMR0 
    BTFSC PIR1, TMR1IF		    
    CALL INT_TMR1
    BTFSC INTCON, RBIF
    CALL INT_RB
    BSF INTCON, GIE
    MOVLW   B'1110000'
    MOVWF   INTCON
    
 POP:
    SWAPF STATUS_TEMP,W
    MOVWF STATUS
    SWAPF W_TEMP,F
    SWAPF W_TEMP,W
    RETFIE	


MAIN_PROG CODE                      ; let linker place main program

START
    CALL	IO_CONFIG	    ;CONFIGURATION OF PORTS
    CALL	TMR0_CONFIG	    ;CONFIGURATION OF TIMER 0
    CALL	TMR1_CONFIG	    ;CONFIGURATION OF TIMER 1
    CALL	CLOCK_CONFIG	    ;CONFIGURATION OF INTERNAL CLOCK
    CALL	INT_CONFIG	    ;CONFIGURATION OF INTERRUPTS
    CALL	VAR_CONFIG	    ;CONFIGURATION FOR INITIAL VALUES IN REGISTERS
 
;***************************************************************************;
;*********************************LOOP**************************************;
;***************************************************************************;  
 LOOP
    NOP
    GOTO LOOP
    
    
;***************************************************************************;
;*********************************TABLES************************************;
;***************************************************************************;  
  TABLA:			;TABLE FOR 7 SEGMENT'S LETTERS AND NUMBERS
    ADDWF   PCL, F		;ORDER: ; H - G - F - E - D - C - B - A
    RETLW b'00111111'     	;0
    RETLW b'00000110'     	;1
    RETLW b'01011011'     	;2
    RETLW b'01001111'     	;3
    RETLW b'01100110'     	;4
    RETLW b'01101101'     	;5
    RETLW b'01111101'     	;6
    RETLW b'00000111'     	;7
    RETLW b'01111111'     	;8
    RETLW b'01101111'     	;9

TABLE_DATES:				;TABLE FOR NUMBER OF DAYS IN EACH MONTH
    ADDWF	PCL, F
    NOP
    RETLW	.32			;ENERO
    RETLW	.29			;FEBRERO
    RETLW	.32			;MARZO
    RETLW	.31			;ABRIL
    RETLW	.32			;MAYO
    RETLW	.31			;JUNIO
    RETLW	.32			;JULIO
    RETLW	.32			;AGOSTO
    RETLW	.31			;SEPTIEMBRE
    RETLW	.32			;OCTUBRE
    RETLW	.31			;NOVIEMBRE
    RETLW	.32			;DICIEMBRE
    RETURN

MENU:					;TABLE TO DETERMINE WHAT TO DISPLAY ON SEGMENTS
    ADDWF	PCL, F
    GOTO	DISPLAY_TIME
    GOTO	DISPLAY_DATE
    GOTO	CONFIG_TIME_MENU
    GOTO	CONFIG_DATE_MENU
    GOTO	CONFIG_ALARM_MENU
    RETURN
    
INC_DISP_TABLE:				;TABLE TO DETERMINE WHAT IS BEING INCREASED
    ADDWF	PCL, F
    GOTO	INC_MINS
    GOTO	INC_HOURS
    
    
;***************************************************************************;
;*********************************INTS**************************************;
;***************************************************************************;
    
INT_TMR0:
    BCF INTCON, T0IF
    MOVLW	.254
    MOVWF	TMR0
    MOVF	MENU_, W
    CALL	MENU
    RETURN

 INT_TMR1:
    MOVLW    0C2H
    MOVWF    TMR1H	
    MOVLW    0F7H
    MOVWF    TMR1L
    CALL    TOGGLE
    INCF    SEGUNDOS
    MOVLW   .120		    ; 
    XORWF   SEGUNDOS,W	     
    BTFSC   STATUS,Z
    CALL    AUMENTAR1
    CALL    ALARM
    BCF PIR1, TMR1IF
    RETURN
    
 INT_RB:
    BCF	INTCON, RBIF
    MOVLW   B'01100000'
    MOVWF   INTCON
    BTFSC   PORTB, 0
    CALL    SHOW_TIME_I
    BTFSC   PORTB, 1
    CALL    SHOW_DATE_I
    BTFSC   PORTB, 2
    CALL    CHANGE
    BTFSC   PORTB, 3
    CALL    CONFIG_TIME
    BTFSC   PORTB, 4
    CALL    CONFIG_DATE
    BTFSC   PORTB, 5
    CALL    CONFIG__ALARM
    BTFSC   PORTB, 6
    CALL    INCREASE_DISP
    BTFSC   PORTB, 7
    CALL    ALARM_E_TOGGLE
    RETURN
    
;***************************************************************************;
;*********************************CONFIG************************************;
;***************************************************************************;
VAR_CONFIG:				;INITIALIZATION OF VARIABLES AND PORTS
    BANKSEL	PORTA
    CLRF	SEGUNDOS
    CLRF	TRANSISTOR
    CLRF	MONTH_U
    CLRF	MONTH_D
    CLRF	DATE_U
    CLRF	DATE_D
    CLRF	MENU_
    CLRF	MINS
    CLRF	HOURS
    CLRF	CURRENT_INC
    CLRF	MINS_U_A	
    CLRF	MINS_D_A	
    CLRF	HOURS_U_A	
    CLRF	HOURS_D_A	
    MOVLW	.1
    MOVWF	PORTD
    MOVWF	ALARM_E
    CLRF	PORTA
    MOVWF	MONTH
    MOVWF	MONTH_U
    MOVWF	DATE_U
    MOVLW	.3
    MOVWF	DATE_D
    MOVLW	.31
    MOVWF	DATE
    MOVLW	.2
    MOVWF	HOURS_D
    MOVLW	.3
    MOVWF	HOURS_U
    MOVLW	.5
    MOVWF	MINS_D
    MOVLW	.9
    MOVWF	MINS_U
    BSF		PORTA, 2
    RETURN
    
IO_CONFIG:
    BANKSEL	PORTA
    CLRF	PORTA
    CLRF	PORTB
    CLRF	PORTC
    CLRF	PORTD
    CLRF	PORTE
    
    BANKSEL	TRISA
    CLRF	TRISA		
    MOVLW	B'11111111'
    MOVWF	TRISB
    CLRF	TRISC		
    CLRF	TRISD
    CLRF	TRISE
    
    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH
    
    RETURN
    
    
TMR0_CONFIG:
    BANKSEL	TRISA
    MOVLW	B'00000101'
    MOVWF	OPTION_REG
    
    BANKSEL	PORTA
    MOVLW	.254
    MOVWF	TMR0
    BCF		INTCON, T0IF
    
    RETURN
;******************************************************************************
;			   TOMADO DE JOSÉ EDUARDO
;******************************************************************************
TMR1_CONFIG:
    BANKSEL  PORTA
    BCF	    T1CON, TMR1GE
    BCF	    T1CON, T1CKPS1  ; PRESCALER 2:1
    BSF	    T1CON, T1CKPS0
    BCF	    T1CON, T1OSCEN  ; RELOJ INTERNO
    BCF	    T1CON, TMR1CS
    BSF	    T1CON, TMR1ON   ; PRENDEMOS TMR1
    MOVLW    0C2H
    MOVWF    TMR1H	
    MOVLW    0F7H
    MOVWF    TMR1L	    ; VALORES INICIALES DEL TIMER1
    BCF	    PIR1, TMR1IF
   RETURN 
   
INT_CONFIG:    
    BANKSEL  TRISA
    BSF	    PIE1, TMR1IE    ; HABILITAMOS INTERRUPCIONES DE TIMER 1 Y 2

    BANKSEL  IOCB
    MOVLW    B'11111000'
    MOVWF    INTCON
    MOVLW    B'11111111'
    MOVWF    IOCB

    BANKSEL  PORTA
    BCF	    PIR1, TMR1IF    ; LIMPIAMOS LAS BANDERAS
    RETURN
    
CLOCK_CONFIG:		  
    BANKSEL  OSCCON
    BCF	    OSCCON, IRCF2
    BSF	    OSCCON, IRCF1
    BCF	    OSCCON, IRCF0
    RETURN

;***************************************************************************;
;*********************************MISC F************************************;
;***************************************************************************;
    
;***************************************************************************;
;*********************************MENU F************************************;
;***************************************************************************;    
DISPLAY_TIME:				;FUNTION TO REFRESH DISPLAYS WITH MINS AND HOURS
    DISPLAY_M   MINS_U, MINS_D, HOURS_U, HOURS_D
    RETURN
	
DISPLAY_DATE:				;FUNTION TO REFRESH DISPLAYS WITH DAY AND MONTH
    DISPLAY_M   DATE_U, DATE_D, MONTH_U, MONTH_D
    RETURN
	
CONFIG_TIME_MENU:				;FUNTION TO REFRESH DISPLAYS WITH MINS AND HOURS
    GOTO DISPLAY_TIME
    
CONFIG_ALARM_MENU:				;FUNTION TO REFRESH DISPLAYS WITH MINS AND HOURS OF ALARM
    CALL TOOGLE
    DISPLAY_M   MINS_U_A, MINS_D_A, HOURS_U_A, HOURS_D_A
    RETURN
    
CONFIG_DATE_MENU:				;FUNTION TO REFRESH DISPLAYS WITH DAY AND MONTH
    GOTO    DISPLAY_DATE
	
INCREASE_DISP:					;FUNTION TO INCREASE DEPENDING ON MENU
    MOVLW	.0
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    RETURN
    MOVLW	.1
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    RETURN
    
    MOVLW	.2
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    GOTO	INC_DISP_TIME
    MOVLW	.3
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    GOTO	INC_DISP_DATE
    MOVLW	.4
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    GOTO	INC_DISP_ALARM
    RETURN
    
    
INC_DISP_TIME:
    BTFSC	CURRENT_INC, 0
    GOTO	INC_MINS
    GOTO	INC_HOURS

INC_DISP_DATE:
    BTFSC	CURRENT_INC, 0
    GOTO	INC_DATE
    GOTO	INC_MONTH
    
INC_DISP_ALARM:
    BTFSC	CURRENT_INC, 0
    GOTO	INC_MINS_A
    GOTO	INC_HOURS_A
	
CHANGE:
    MOVLW	.0
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    RETURN
    MOVLW	.1
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    RETURN
    BTFSC	CURRENT_INC, 0
    CLRF	CURRENT_INC
    INCF	CURRENT_INC
    RETURN
	

;***************************************************************************;
;********************************RB INT F***********************************;
;***************************************************************************;
	
SHOW_TIME_I:
    MOVLW	.2
    XORWF	MENU_, W    	
    BTFSC	STATUS, Z
    RETURN
    MOVLW	.3
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    RETURN	
    MOVLW	.4
    XORWF	MENU_, W    	
    BTFSC	STATUS, Z
    RETURN
    
    CLRF	MENU_
    RETURN

SHOW_DATE_I:
    MOVLW	.2	
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    RETURN	
    MOVLW	.3
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    RETURN	    
    MOVLW	.4
    XORWF	MENU_, W    	
    BTFSC	STATUS, Z
    RETURN
    
    MOVLW	.1
    MOVWF	MENU_
    RETURN
	
CONFIG_TIME:
    MOVLW	.0
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    GOTO	BEGIN_CONFIG_TIME
    MOVLW	.1
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    GOTO	BEGIN_CONFIG_TIME
    MOVLW	.3
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    RETURN
    MOVLW	.4
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    RETURN
    
    MOVLW	.1
    XORWF	CURRENT_INC, W
    BTFSS	STATUS, Z
    RETURN
    CLRF	MENU_
    RETURN
    
CONFIG_DATE:
    MOVLW	.0
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    GOTO	BEGIN_CONFIG_DATE
    MOVLW	.1
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    GOTO	BEGIN_CONFIG_DATE
    MOVLW	.2
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    RETURN
    MOVLW	.4
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    RETURN
    
    MOVLW	.1
    XORWF	CURRENT_INC, W
    BTFSS	STATUS, Z
    RETURN
    CLRF	MENU_
    RETURN
    
CONFIG__ALARM:
    MOVLW	.0
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    GOTO	BEGIN_CONFIG_ALARM
    MOVLW	.1
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    GOTO	BEGIN_CONFIG_ALARM
    MOVLW	.2
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    RETURN
    MOVLW	.3
    XORWF	MENU_, W
    BTFSC	STATUS, Z
    RETURN
    
    MOVLW	.1
    XORWF	CURRENT_INC, W
    BTFSS	STATUS, Z
    RETURN
    
    CLRF	MENU_
    
    RETURN	
;***************************************************************************;
;*************************INC TIME/DATE AUTO********************************;
;***************************************************************************;
	
AUMENTAR1:			    ;INCREASES UNITS OF MINS
    CLRF	    SEGUNDOS
    INCF	    MINS_U
    INCF	    ALARM_TIMER
    MOVLW	    .10
    XORWF	    MINS_U,W	     
    BTFSC	    STATUS,	Z
    GOTO	    AUMENTAR2
    RETURN
	
    AUMENTAR2:			    ;INCREASES TENS OF MINS
	CLRF	    MINS_U
	INCF	    MINS_D
	MOVLW	    .6
	XORWF	    MINS_D,W	     
	BTFSC	    STATUS,	Z
	GOTO	    AUMENTAR3
	RETURN

    AUMENTAR3:			    ;INCREASES UNITS OF HOURS
	CLRF	    MINS_D
	INCF	    HOURS_U
	MOVLW	    .10
	BTFSC	    HOURS_D, 1
	MOVLW	    .4
	XORWF	    HOURS_U, W	     
	BTFSC	    STATUS, Z
	GOTO	    AUMENTAR4
	RETURN
	
    AUMENTAR4:			    ;INCREASES TENS OF HOURS
	CLRF	HOURS_U
	INCF	HOURS_D
	MOVLW	.3
	XORWF	HOURS_D,W	     
	BTFSC	STATUS,Z
	GOTO	AUMENTAR5
	RETURN  
	
    AUMENTAR5:			    ;INCREASES UNITS OF DAY AND LIMITS 
	CLRF	HOURS_D
	INCF	DATE
	INCF	DATE_U
	MOVLW	.10
	XORWF	DATE_U, W
	BTFSC	STATUS, Z
	CALL	AUMENTAR6
	MOVF	MONTH, W
	CALL	TABLE_DATES
	XORWF	DATE, W
	BTFSC	STATUS, Z
	GOTO	AUMENTAR7
	RETURN
	
    AUMENTAR6:			    ;INCREASES TENS OF DAY
	MOVLW	.1
	MOVWF	DATE_U
	INCF	DATE_D
	RETURN
	
    AUMENTAR7:			    ;INCREASES UNITS OF MONTH
	CLRF	DATE_D
	CLRF	DATE
	CLRF	DATE_U
	INCF	MONTH
	INCF	MONTH_U
	BTFSC	MONTH_D, 0
	GOTO	$ + 5
	MOVLW	.10
	XORWF	MONTH_U, W
	BTFSC	STATUS, Z
	CALL	AUMENTAR8
	MOVLW	.3
	XORWF	MONTH_U, W
	BTFSC	STATUS, Z
	GOTO	RESET_TIMER
	RETURN
	
    AUMENTAR8:			    ;INCREASES TENS OF MONTH
	CLRF	MONTH_U
	INCF	MONTH_D
	RETURN
	
    RESET_TIMER:		    ;RESETS TIMER (1 YEAR)
	CLRF	MONTH
	CLRF	MONTH_U
	CLRF	MONTH_D
	RETURN
	
;***************************************************************************;
;***************************INC TIME MANUALLY*******************************;
;***************************************************************************;
	
	;MINS
    INC_MINS:
	INCF	MINS_U
	INCF	MINS
	MOVLW	.60
	XORWF	MINS, W
	BTFSC	STATUS, Z
	CALL	RESET_MINS
	MOVLW	.10
	XORWF	MINS_U, W
	BTFSC	STATUS, Z
	GOTO	MINS_DECENA
	RETURN
	
    MINS_DECENA:
	CLRF	MINS_U
	INCF	MINS_D
	RETURN
	
    RESET_MINS:
	CLRF	MINS
	CLRF	MINS_U
	CLRF	MINS_D
	RETURN
	
	;HOURS
    INC_HOURS:
	INCF	HOURS_U
	INCF	HOURS
	MOVLW	.24
	XORWF	HOURS, W
	BTFSC	STATUS, Z
	CALL	RESET_HOURS
	MOVLW	.10
	XORWF	HOURS_U, W
	BTFSC	STATUS, Z
	GOTO	HOURS_DECENA
	RETURN
	
    HOURS_DECENA:
	CLRF	HOURS_U
	INCF	HOURS_D
	RETURN
	
    RESET_HOURS:
	CLRF	HOURS
	CLRF	HOURS_U
	CLRF	HOURS_D
	RETURN
	
;***************************************************************************;
;***************************INC DATE MANUALLY*******************************;
;***************************************************************************;
	
	;MONTH
    INC_MONTH:
	INCF	MONTH
	INCF	MONTH_U
	MOVLW	.13
	XORWF	MONTH, W
	BTFSC	STATUS, Z
	CALL	RESET_MONTH
	MOVLW	.10
	XORWF	MONTH_U, W
	BTFSC	STATUS, Z
	GOTO	MONTH_DECENA
	RETURN
	
    RESET_MONTH:
	MOVLW	.1
	MOVWF	MONTH
	MOVWF	MONTH_U
	CLRF	MONTH_D
	RETURN
	
    MONTH_DECENA:
	CLRF	MONTH_U
	INCF	MONTH_D
	RETURN
	
	;DATE
    INC_DATE:
	INCF	DATE
	INCF	DATE_U
	MOVF	MONTH, W
	CALL	TABLE_DATES
	XORWF	DATE, W
	BTFSC	STATUS, Z
	CALL	RESET_DATE
	MOVLW	.10
	XORWF	DATE_U, W
	BTFSC	STATUS, Z
	GOTO	DATE_DECENA
	RETURN
	
    RESET_DATE:
	MOVLW	.1
	MOVWF	DATE
	MOVWF	DATE_U
	CLRF	DATE_D
	RETURN
	
    DATE_DECENA:
	CLRF	DATE_U
	INCF	DATE_D
	RETURN
	
;***************************************************************************;
;*************************INC ALARM MANUALLY********************************;
;***************************************************************************;
	
	;MINS
    INC_MINS_A:
	INCF	MINS_U_A
	INCF	MINS_A
	MOVLW	.60
	XORWF	MINS_A, W
	BTFSC	STATUS, Z
	CALL	RESET_MINS_A
	MOVLW	.10
	XORWF	MINS_U_A, W
	BTFSC	STATUS, Z
	GOTO	MINS_DECENA_A
	RETURN
	
    MINS_DECENA_A:
	CLRF	MINS_U_A
	INCF	MINS_D_A
	RETURN
	
    RESET_MINS_A:
	CLRF	MINS_A
	CLRF	MINS_U_A
	CLRF	MINS_D_A
	RETURN
	
	;HOURS
    INC_HOURS_A:
	INCF	HOURS_U_A
	INCF	HOURS_A
	MOVLW	.24
	XORWF	HOURS_A, W
	BTFSC	STATUS, Z
	CALL	RESET_HOURS_A
	MOVLW	.10
	XORWF	HOURS_U_A, W
	BTFSC	STATUS, Z
	GOTO	HOURS_DECENA_A
	RETURN
	
    HOURS_DECENA_A:
	CLRF	HOURS_U_A
	INCF	HOURS_D_A
	RETURN
	
    RESET_HOURS_A:
	CLRF	HOURS_A
	CLRF	HOURS_U_A
	CLRF	HOURS_D_A
	RETURN
	
    ;***************************************************************************;
    ;********************************TESTING F**********************************;
    ;***************************************************************************;
	;FUNCTIONS TO TOGGLE LEDs
    TOGGLE:			;TESTING LED
	BTFSC	PORTA, 1
	GOTO	$ + 3
	BSF	PORTA, 1
	RETURN
	BCF	PORTA, 1
	RETURN
	
    TOGGLE_E:			;ALARM LED
	BTFSC	PORTA, 2
	GOTO	$ + 3
	BSF	PORTA, 2
	RETURN
	BCF	PORTA, 2
	RETURN
	
    TOOGLE:			;TWO DOTS LED
	BTFSC	PORTA, 0
	GOTO	$ + 3
	BSF	PORTA, 0
	RETURN
	BCF	PORTA, 0
	RETURN
	
    ;***************************************************************************;
    ;**********************************ALARM F**********************************;
    ;***************************************************************************;
	
    ALARM_E_TOGGLE:		;ENABLES OR DISABLES ALARM
	BTFSC	PORTE, 0
	GOTO	DISABLE_ALARM
	MOVLW	.1
	XORWF	ALARM_E, F
	CALL	TOGGLE_E
	RETURN
	
DISABLE_ALARM:			;DISABLES ALARM
    CLRF    PORTE
    RETURN
    
    ALARM:			    ;TEST IF ALARM SHOULD BE TRIGGERED
	MOVLW	.1
	XORWF	ALARM_E, W
	BTFSS	STATUS, Z
	RETURN
	MOVLW	.10
	XORWF	ALARM_TIMER, W
	BTFSC	STATUS, Z
	CLRF	PORTE
	
	MOVF	HOURS_D_A, W
	XORWF	HOURS_D, W
	BTFSS	STATUS, Z
	RETURN
	MOVF	HOURS_U_A, W
	XORWF	HOURS_U, W
	BTFSS	STATUS, Z
	RETURN
	MOVF	MINS_D_A, W
	XORWF	MINS_D, W
	BTFSS	STATUS, Z
	RETURN
	MOVF	MINS_U_A, W
	XORWF	MINS_U, W
	BTFSS	STATUS, Z
	RETURN
	
	
	
	MOVLW	.0
	XORWF	SEGUNDOS, W
	BTFSC	STATUS, Z
	GOTO	ALARM_START
	RETURN
	
    ALARM_START:		;STATRS THE ALARM
	BSF	PORTE, 0
	CLRF	ALARM_TIMER
	RETURN
	
    BEGIN_CONFIG_TIME:		;INITIALIZES THE TIME CONFIGURATION MENU
	CLRF	HOURS
	CLRF	HOURS_U
	CLRF	HOURS_D	
	CLRF	MINS
	CLRF	MINS_U
	CLRF	MINS_D
	CLRF	CURRENT_INC
	MOVLW	.2
	MOVWF	MENU_
	RETURN
	
    BEGIN_CONFIG_DATE:		;INITIALIZES THE DATE CONFIGURATION MENU
	MOVLW	.1
	MOVWF	MONTH
	MOVWF	MONTH_U
	CLRF	MONTH_D
	MOVLW	.1
	MOVWF	DATE
	MOVWF	DATE_U
	CLRF	DATE_D
	CLRF	CURRENT_INC
	MOVLW	.3
	MOVWF	MENU_
	RETURN
	
    BEGIN_CONFIG_ALARM:		;INITIALIZES THE ALAR CONFIGURATION MENU (NOT WORKING PROPERLY)
    	CLRF	MINS_U_A
    	CLRF	MINS_D_A
    	CLRF	HOURS_U_A
    	CLRF	HOURS_D_A
	MOVLW	.4
	MOVWF	MENU_
	RETURN
	
	END  