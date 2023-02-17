;   Archivo:    POSTLAB_04.s
;   Dispositivo: PIC16F887
;   Autor:  Pablo Figueroa
;   Copilador: pic-as (v2.40),MPLABX v6.05
;
;   Progra: contador binario de 4 bits usando interrupciones y contador hexadecimal de 60 seg.
;   Hardware: LEDs en el puerto A, display puerto C y D. Pushbuttons en el puerto B "PULL-UP"
; 
;   Creado: 12 Feb, 2023
;   Ultima modificacion: 16 feb, 2023
    
PROCESSOR 16F887
#include <xc.inc>
    
;--------Palabras de Configuración---------
    
; configuration word 1
  CONFIG  FOSC = INTRC_NOCLKOUT   ; Oscillator Selection bits (INTOSC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; configuration word 2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
  
;-----------------MACROS----------------
restart_tmr0 macro
  banksel TMR0	;banco 00
  movlw 60	;valor inicial del TMR0
  movwf TMR0	;Se carga el valor inicial
  bcf T0IF	;Se apaga la bandera de interrupción por Overflow del TMR0
  endm
  
;---------variables a utilizar----------
  
PSECT udata_bank0 ;common memory
  cont:	    DS 1; 1 byte
  W_TEMP:   DS 1 ;Variable reservada para guardar el W Temporal
  STATUS_TEMP: DS 1 ;Variable reservada para guardar el STATUS Temporal
    
  cont_seg: DS 1 ;variable para registrar la cantidad de segundos al contar 10 en el timer0
  cont_dec: DS 1 

  
  UP EQU 0
  DOWN EQU 1
    
;--------------vector Reset-------------   
PSECT VectorReset, class=CODE, abs, delta=2
;-------------vector reset--------------
ORG 00h		;Posición 0000h para el reset
    
VectorReset:
    PAGESEL main 
    goto main
    
; ----configuracion del microcontrolador----
;PSECT code, delta=2, abs
    
;-------------Vector de Interrupción---------
    
ORG 04h			    ;posicionamiento para las interrupciones.
push:
    movwf W_TEMP	    ;guardado temporal de STATUS y W
    swapf STATUS, W 
    movwf STATUS_TEMP
isr:			    ;instrucciones de la interrupcion
    btfsc T0IF
    call inte_TMR0
    call set_PORTD
    btfsc RBIF
    call inte_portb
    call set_PORTA
pop:			    ;Retorno de los valores previos de W y STATUS
    swapf STATUS_TEMP, W
    movwf STATUS
    swapf W_TEMP, F
    swapf W_TEMP, W
    retfie

;----------SubRutinas de INTERRUPCIÓN-------
inte_portb: ;interrupcion en el puertoB
    banksel PORTB
    btfss PORTB, UP ;Si el bit 0 cambio, entonces se incrementa el portA
    incf PORTA
    btfss PORTB, DOWN	;Si el bit 1 cambio, entonces se decrementa el portA
    decf PORTA
    bcf RBIF
    return
 
set_PORTA: 
    btfsc PORTA,7   ;se revisa el 8 bit del PORTA por lo que si esta en uno se setea el valor de 15.
    goto $+4
    btfsc PORTA,4   ;se revisa el 5 bit del PORTA por lo que hay un overflow del contador de 4 bits.
    clrf PORTA
    return
    clrf PORTA
    bsf PORTA,0	    ;se setea el valor 15 encaso se decremente mas de 0.
    bsf PORTA,1
    bsf PORTA,2
    bsf PORTA,3
    return
    
inte_TMR0:
    restart_tmr0 ;macro
    decfsz cont	;decrementamos la variable cont que previamente seteamos en un valor que define los ciclos del TMR0, si el registro queda 0 se salta la siguiente linea
    return
    call set_cont ;reinicio de la variable de conteo para el TMR0.
    incf cont_seg ;incremento de la variable donde se guarda el contador en segundos.
    ;restart_tmr0 ;macro
    return
    
set_cont:
    movlw 10 ;valor de los ciclos que tiene que realizar el tmr0 para que se incremente en 1 el contador de segundos.
    movwf cont ;se carga el valor asignado.
    return


set_PORTD: 
    btfsc cont_seg,7   ;se revisa el 8 bit del cont_seg por lo que si esta en uno se setea el valor de 15.
    goto $+4
    btfsc cont_seg,4   ;se revisa el 5 bit del cont_seg por lo que hay un overflow del contador de 4 bits.
    clrf cont_seg
    return
    clrf cont_seg
    bsf cont_seg,0	    ;se setea el valor 15 encaso se decremente mas de 0.
    bsf cont_seg,1
    bsf cont_seg,2
    bsf cont_seg,3
    return    


;----------------TABLAS---------------------
    
ORG 100h		    ; posicion para la tabla
 tabla:			    ;tabla donde se retorna el valor de la suma. PARA ANODO
    clrf PCLATH
    bsf PCLATH,0
    addwf PCL,F
    retlw 11000000B ;0
    retlw 11111001B ;1
    retlw 10100100B ;2
    retlw 10110000B ;3
    retlw 10011001B ;4
    retlw 10010010B ;5
    retlw 10000010B ;6
    retlw 11111000B ;7
    retlw 10000000B ;8
    retlw 10010000B ;9
    retlw 10001000B ;10 A
    retlw 10000011B ;11 B
    retlw 11000110B ;12 C 
    retlw 10100001B ;13 D
    retlw 10000110B ;14 E
    retlw 10001110B ;15 F
    
    
    
    
ORG 200h	; posición para el código
 
 ;------configuracion-------
main:
    movlw 10
    movwf cont
    clrf cont_seg
    clrf cont_dec
    
    call config_tmr0	;Temporización: 100ms 
    call config_io	;Configuracion de los puertos ENTRADAS/SALIDAS
    call config_reloj	;Configuracion del oscilador Interno
    call config_push	;Configuracion de los pull-ups
    call config_inte	;Configuracion y habilitacion de las interrupciones
    banksel PORTA
    
    ;------loop principal-------
loop:  
    call segundos ;subrutina que muestra el valor del display0
    call dec_segundos	;subrutina que muestra el valor del display1
    goto loop
    
    ;--------sub rutinas---------  

config_push:
    banksel TRISA
    bsf IOCB,0 ; Interrupcion ON-CHANGE habilitada para el bit 0 del PORTB
    bsf IOCB,1 ; Interrupcion ON-CHANGE habilitada para el bit 1 del PORTB
    
    banksel PORTA
    movf PORTB, W   ;lectura del PORTB
    bcf RBIF	    ;Se limpia la bandera RBIF
    return
    
config_io:    
    Banksel ANSEL
    clrf ANSEL ; 0 = pines digitales, ANS<4:0> = PORTA,  ANS<7:5> = PORTE // Clear Register ANSEL
    clrf ANSELH ; 0 = pines digitales, ANS<13:8>, estos corresponden al PORTB
    
    Banksel TRISA
    clrf TRISA ; 0 = port A como salida
    clrf TRISC ; 0 = PORTC como salida
    clrf TRISD ; 0 = PORTD como salida

    ; los primeros dos bits del registro PORTB se colocan como entrada digital
    bsf TRISB, UP ; Bit set (1), BIT 1 del registro TRISB
    bsf TRISB, DOWN ; Bit set (1), BIT 0 del registro TRISB
    bsf WPUB, UP
    bsf WPUB, DOWN
    
    bcf OPTION_REG,7	;Habilitar Pull-ups
    
    Banksel PORTA
    clrf PORTA ; 0 = Apagados, todos los puertos del PORTA estan apagados.
    clrf PORTC ; 0 = Apagados, todos los puertos del PORTC estan apagados.
    clrf PORTD ; 0 = Apagados, todos los puertos del PORTD estan apagados.
    return
    
    
config_tmr0:
    Banksel TRISA
    bcf T0CS	;TMR0 como temporizador
    bcf PSA	;Preescaler en TMR0
    bsf PS2	    
    bcf PS1
    bcf PS0	;Prescaler de 1:32 (100)
    restart_tmr0
    return    

config_reloj:
    banksel OSCCON
    ; frecuencia de 250kHz
    bcf IRCF2 ; OSCCON, 6
    bsf IRCF1 ; OSCCON, 5
    bcf IRCF0 ; OSCCON, 4
    bsf SCS ; reloj interno
    return
    
config_inte: ;configuracion de las interrupciones
    bsf GIE	;Habilitacion de las interrupciones globales INTCON REGISTER
    
    bsf RBIE	;Habilitacion de interrupcion por cambio en el PORTB 
    bcf RBIF	;Apagar bandera de cambio en el PORTB.
    bsf T0IE	;Habilitacion de la interrupcion por overflow del TMR0
    bcf T0IF	;Apagar bandera de overflow del TMR0
    return
    
segundos:   ;Subrutina que muestra el valor en el display0 del contador segundos (0-9)
    movf cont_seg, W	;
    call tabla
    movwf PORTD
    call verficacion_seg
    return
    
dec_segundos: ;Subrutina que muestra el valor en el display1 del contador decenas de segundos (0-6)
    movf cont_dec, W	
    call tabla
    movwf PORTC
    return
     
verficacion_seg:
    movlw 10
    subwf cont_seg, W	;se resta el valor del contador segundos al valor 10 y si queda 0 se prende la bandera Zero
    btfss STATUS,2
    return
    call set_seg    ;Si se prendio la bandera se llama la subrutina que resetea a 0 el valor del contador segundos y incrementa el contador decenas de segundo. 
    return
 
    
set_seg:
    bcf STATUS, 2   ;Se apaga la bandera Zero
    clrf cont_seg   ;Se resetea a 0 el contador de segundos
    call verificacion_dec   ;se llama a la subrutina que incrementa el contador decenas de segundo y que verifica que este no pase más del valor de 6 para los 60 segundos.
    return
    
    
verificacion_dec:
    incf cont_dec   ;Se incrementa el contador decenas de segundos
    movlw 6
    subwf cont_dec, W	;Se resta 6 al valor del contador decenas de segundo para verificar que este no se haya pasado de 6. Si el resultado es 0 se enciende la bandera Zero.
    btfss STATUS, 2 ;Se verifica si se encendio la bandera Zero
    return
    call set_dec    ;Si se encendio la bandera Zero, se llama la subrutina que resetea a 0 el valor del contador decenas de segundo.
    return
    
set_dec:
    bcf STATUS,2    ;Si la bandera se encendio, limpia el contador decenas de segundo.
    clrf cont_dec
    return
    
END ; Finalización del código






