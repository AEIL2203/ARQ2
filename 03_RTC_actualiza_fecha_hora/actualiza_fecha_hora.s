// actualiza_fecha_hora.s - Actualiza la fecha y hora del RTC
// Acceso al controlador del RTC

// Directivas para el ensamblador
// ------------------------------
.syntax unified
.cpu cortex-m3

// Declaración de funciones exportadas
// -----------------------------------
.global actualiza_fecha_hora             @ Para que la función 'actualiza_fecha_hora'
.type   actualiza_fecha_hora, %function  @   sea accesible desde los módulos externos

// Declaración de constantes
// -------------------------

// Dirección base y offsets del controlador del RTC
.equ RTC,         0x400E1A60  @ Dirección base del RTC
.equ RTC_CR,      0x00        @ Offset del Control Register
.equ RTC_MR,      0x04        @ Offset del Mode Register
.equ RTC_TIMR,    0x08        @ Offset del Time Register
.equ RTC_CALR,    0x0C        @ Offset del Calendar Register
.equ RTC_TIMALR,  0x10        @ Offset del Time Alarm Register
.equ RTC_CALALR,  0x14        @ Offset del Calendar Alarm Register
.equ RTC_SR,      0x18        @ Offset del Status Register
.equ RTC_SCCR,    0x1C        @ Offset del Status Clear Command Register
.equ RTC_IER,     0x20        @ Offset del Interrupt Enable Register
.equ RTC_IDR,     0x24        @ Offset del Interrupt Disable Register 
.equ RTC_IMR,     0x28        @ Offset del Interrupt Mask Register
.equ RTC_VER,     0x2C        @ Offset del Valid Entry Register
.equ RTC_WPMR,    0xE4        @ Offset del Write Protect Mode Register

// Máscaras para la configuración del RTC
.equ MSK_12H,     0x00000001  @ Para configurar modo de 12 horas
.equ MSK_STOP,    0x********  @ Para detener actualización contadores         [*?*]
.equ MSK_GO,      0x********  @ Para reanudar actualización contadores        [*?*]
.equ MSK_ACKUPD,  0x********  @ Para confirmar bloqueo de los contadores      [*?*]
.equ MSK_NVCAL,   0x********  @ Para ver si la fecha introducida no es válida [*?*]
.equ MSK_NVTIM,   0x********  @ Para ver si la hora introducida no es válida  [*?*]

// Fecha y hora que se quieren escribir
.equ RTC_FECHA,   0x********  @ Miércoles 1 de marzo de 2017                  [*?*]
.equ RTC_HORA,    0x00******  @ 04:18:25 PM                                   [*?*]

// Códigos de error: 0 (todo bien), 1 (error en fecha), o 2 (error en hora)
.equ ERR_NOERR,   0x********  @ Código de error: No error                     [*?*]
.equ ERR_FECHA,   0x********  @ Código de error: Error en fecha               [*?*]
.equ ERR_HORA,    0x********  @ Código de error: Error en hora                [*?*]


// Comienzo de la zona de código
// -----------------------------
.text

/*
  Subrutina 'actualiza_fecha_hora'.
  Actualiza la fecha y hora del RTC y devuelve un código de error.
  Parámetros de entrada:
    No tiene.
  Parámetros de salida:
    r0: código de error: 0 (todo bien), 1 (error en fecha), o 2 (error en hora)
  */
.thumb_func
actualiza_fecha_hora:

  // Apila los registros que se vayan a modificar
  push   {lr}                 @ Apila LR

  // Dirección base del RTC
  ldr    r1, =RTC             @ r1 <- dirección base del RTC

  // Configura modo de 12 horas (AM/PM)
  ldr    r2, =MSK_12H         @ r2 <- máscara modo 12 horas
  str    r2, [r1, #RTC_MR]    @ Configura modo 12 horas

  // Detiene los contadores de fecha y hora, poniendo un 1 en los bits 1 y 0 del RTC_CR
  mov    r2, #MSK_STOP        @ r2 <- máscara para detener actualización
  ***    r3, [r1, #RTC_CR]    @ r3 <- contenido del Control Register                [*?*]
  ***    r3, r2               @ Aplica máscara                                      [*?*]
  ***    r3, [r1, #RTC_CR]    @ Detiene contadores sobrescribiendo Control Register [*?*]
   
  // Espera hasta que el RTC confirma que ha detenido los contadores
  mov    r2, #MSK_******      @ r2 <- máscara para confirmar contadores bloqueados  [*?*]
nodetenido:
  ldr    r3, [r1, #RTC_**]    @ r3 <- RTC Status Register                           [*?*]
  ands   r3, r2               @ Comprueba bit confirmación registros bloqueados
  ***    nodetenido           @ Bit a 0, volver a comprobar                         [*?*]
   
  // Pone a 0 el bit de confirmación de contadores bloqueados
  mov    r2, #MSK_******      @ r2 <- máscara para confirmar contadores bloqueados  [*?*]
  str    r2, [r1, #RTC_****]  @ Escribe r2 en el Status Clear Command Register      [*?*]
   
  // Configura fecha actual
  mov    r0, #ERR_*****       @ r0 <- código de error en fecha (por si acaso)       [*?*]
  ldr    r3, =RTC_FECHA       @ r3 <- fecha a escribir
  str    r3, [r1, #RTC_****]  @ Escribe fecha actual                                [*?*]
  ldr    r3, [r1, #RTC_***]   @ r3 <- Valid Entry Register                          [*?*]
  mov    r2, #MSK_*****       @ r2 <- máscara para ver si la fecha no es válida     [*?*]
  ands   r3, r2               @ Aplica máscara
  ***    vuelve               @ Bit a 1, fecha no válida, volver con error          [*?*]

  // Configura hora actual
  mov    r0, #ERR_****        @ r0 <- código de error en hora (por si acaso)        [*?*]
  ldr    r3, =RTC_HORA        @ r3 <- hora a escribir
  str    r3, [r1, #RTC_****]  @ Escribe hora actual                                 [*?*]
  ldr    r3, [r1, #RTC_***]   @ r3 <- Valid Entry Register                          [*?*]
  mov    r2, #MSK_*****       @ r2 <- máscara para ver si la hora no es válida      [*?*]
  ands   r3, r2               @ Aplica máscara
  ***    vuelve               @ Bit a 1, hora no válida, volver con error           [*?*]
   
  // Todo bien, indicar en r0 que no hay errores
  mov    r0, #ERR_*****       @ r0 <- código para no hay errores                    [*?*]

vuelve:
  // Reanuda los contadores, poniendo un 0 en los bits 1 y 0 del RTC_CR
  ldr    r2, =MSK_GO          @ r2 <- máscara para reanudar los contadores
  ***    r3, [r1, #RTC_CR]    @ r3 <- contenido del Control Register                [*?*]
  ***    r3, r2               @ Aplica máscara reactivar                            [*?*]
  ***    r3, [r1, #RTC_CR]    @ Reanuda contadores sobrescribiendo Control Register [*?*]

  // Retorna
  pop    {pc}                 @ Regresa al invocador (PC <- LR)
.end

