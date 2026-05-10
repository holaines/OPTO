# Guion de presentación — Slides 11 y 12

> **Duración objetivo:** ~4 min (slide 11) + ~1 min (slide 12) = **5 minutos total**
> Las marcas de tiempo son orientativas.

---

## Slide 11 — Power Supply & Software (~4 min)

### Parte 1: Power Supply (~1 min 30 s)

> [!TIP]
> Señalar el diagrama de arriba abajo mientras hablas.

**[0:00 – 0:15] Transición e introducción**

> «Javi nos ha explicado cómo la FPGA adquiere y sincroniza los 160 canales. Ahora vamos a ver las otras dos piezas que faltan para completar el sistema: la alimentación y el software de adquisición.»

> «Empezamos por la alimentación. El sistema tiene que funcionar tanto desde una batería de 24 voltios como desde el bus DC del avión a 28 voltios, que es un entorno ruidoso eléctricamente.»

**[0:15 – 0:40] Arquitectura en cascada** *(señalar el diagrama de arriba abajo)*

> «La estrategia es una arquitectura en cascada. La entrada de 24 o 28 voltios pasa primero por una etapa de protección con fusible, TVS y un circuito de protección activa — el LTC4368 — que nos protege contra inversión de polaridad, sobretensión y sobrecorriente.»

> «Después, un convertidor buck de bajo EMI — el LT8645S con arquitectura Silent Switcher — baja la tensión a un rail intermedio de 7 voltios. Este rail de 7 V no alimenta nada sensible directamente; es solo un bus intermedio.»

**[0:40 – 1:10] Ramas analógica y digital** *(señalar las dos cajas inferiores)*

> «A partir de los 7 voltios, el diseño se separa en dos ramas independientes.»

> «La rama analógica usa un LDO de bajo ruido para generar 5 voltios analógicos — la alimentación AVCC de los AD7606C-18, los LNAs de los MEMS y las referencias del ADC. Lo crítico aquí es que esta rama tiene filtrado local en cada zona para aislar el ruido entre zonas.»

> «La rama digital genera 5 V digitales, de ahí 3.3 V para el VDRIVE de los ADCs y los I/O de la FPGA, y luego reguladores dedicados para los rails de core de la FPGA: 1.8 V y 1.0 V. Estos últimos se hacen con convertidores switching porque un LDO desde 5 o 7 voltios disiparía demasiada potencia.»

**[1:10 – 1:30] Punto clave**

> «La separación entre ramas analógica y digital es fundamental. Aunque ambos rails son nominalmente 5 voltios, los retornos de corriente tienen que estar separados para que el ruido de conmutación de la FPGA no contamine el front-end analógico de los micrófonos.»

---

### Parte 2: Software (~2 min 30 s)

> [!TIP]
> Señalar el diagrama de bloques de izquierda a derecha, siguiendo el flujo de datos.

**[1:30 – 1:50] Transición y visión general**

> «Pasamos ahora al software de adquisición — lo que ocurre en el PC. Recordad que la FPGA se encarga de todo lo que es tiempo real: el muestreo, la lectura de los ADCs, el timestamping y el empaquetado. El PC no controla los ADCs directamente; recibe los datos ya organizados por Ethernet.»

> «En este diagrama vemos el pipeline completo, de izquierda a derecha.»

**[1:50 – 2:20] Fila superior: pipeline de recepción** *(señalar bloque por bloque)*

> «El flujo empieza aquí, a la izquierda, con el stream de la FPGA: 160 canales a 18 bits, que llegan por Ethernet 2.5G usando UDP.»

> «El *Packet receiver* gestiona el socket UDP y hace el buffering de los paquetes. A continuación, el *Frame parser* busca la sync word, decodifica el header — frame counter, timestamp, tipo de frame — y extrae el payload.»

> «El *Integrity check* verifica la integridad con CRC-32, comprueba que el frame counter sea consecutivo y revisa los status flags que manda la FPGA — por ejemplo, si hubo un FIFO overflow o un ADC timeout.»

> «Finalmente, el *Channel mapper* asigna cada muestra a su rama — LF o HF — y a su zona y sensor correspondiente, según el channel map estático que hemos definido.»

**[2:20 – 2:50] Fila inferior: almacenamiento y salidas** *(señalar la fila de abajo, de derecha a izquierda)*

> «Una vez mapeados, los datos bajan al *Acquisition buffer* — un ring buffer alineado en tiempo que acumula muestras LF y HF. Desde ahí, los datos se escriben continuamente en archivos HDF5.»

> «Hemos elegido HDF5 porque soporta arrays multidimensionales grandes, compresión, y permite almacenar junto a los datos toda la metadata: el channel map, las posiciones de los sensores, las sampling rates, la configuración de los ADCs y los datos de calibración.»

**[2:50 – 3:20] Visualización y control** *(señalar los bloques de la izquierda)*

> «En paralelo al almacenamiento, hay un módulo de *Visualization* que muestra en tiempo real un subconjunto de señales temporales y espectros — no hacemos beamforming en real-time, eso queda para post-procesado.»

> «Y por último, los dos bloques de control: el *Status monitor* muestra métricas de salud del sistema — data rate actual, nivel de FIFO, contadores de errores — y el módulo de *Configuration* permite configurar la adquisición: start/stop, sampling rates, rangos del ADC, y almacenar esa configuración junto con los datos para reproducibilidad.»

**[3:20 – 3:40] Cierre de la diapositiva**

> «En resumen, la separación es clara: todo lo que es tiempo crítico — muestreo, lectura, sincronización — se queda en la FPGA. El PC se dedica a recibir, verificar, almacenar y visualizar. Esta separación nos permite que el pipeline de adquisición sea determinista y que el software del PC pueda ser más flexible sin comprometer la integridad de los datos.»

---

## Slide 12 — Verification & Conclusion (~1 min)

> [!NOTE]
> Esta diapositiva aún no tiene contenido. El guion está preparado para el contenido que vayamos a poner.

**[3:40 – 4:10] Verificación**

> «Para verificar el diseño, hemos definido tres niveles de comprobación.»

> «Primero, a nivel de **throughput**: el data rate total con muestras empaquetadas a 32 bits es de unos 786 Mbit/s. Con un 25 % de overhead para protocolo, estamos en ~983 Mbit/s. Gigabit Ethernet se queda justo, por eso hemos elegido 2.5G Ethernet, que nos da margen de sobra.»

> «Segundo, a nivel de **timing**: el readout con 4 DOUT por ADC tarda 0.6 microsegundos a 60 MHz de SCLK, muy por debajo del periodo de muestreo HF de 3.9 microsegundos. El margen es cómodo.»

> «Tercero, a nivel de **integridad de datos**: el frame counter permite detectar frames perdidos, el CRC-32 detecta corrupción, y los status flags de la FPGA reportan en tiempo real cualquier anomalía — timeouts, overflows, errores de sincronización.»

**[4:10 – 4:40] Conclusión**

> «Como conclusión del sistema completo: hemos diseñado una cadena de adquisición desde los 80 micrófonos MEMS hasta el almacenamiento en el PC.»

> «Los puntos clave del diseño son:»
> - «160 canales adquiridos simultáneamente con una referencia temporal común.»
> - «Separación estricta entre dominios analógico y digital, tanto en alimentación como en datos.»
> - «Una FPGA Artix-7 que garantiza la sincronización y el throughput determinista.»
> - «Ethernet industrial 2.5G con conector M12 para robustez mecánica.»
> - «Y un software de adquisición con verificación de integridad en cada frame y almacenamiento en HDF5 con toda la metadata necesaria para reproducir la medida.»

> «Gracias. ¿Alguna pregunta?»

---

## Notas para el presentador

- **Ritmo**: habla despacio en las transiciones y cuando señalas los diagramas. La audiencia necesita tiempo para seguir el flujo visual.
- **Diagramas**: usa un puntero o el ratón para ir señalando cada bloque a medida que lo nombras.
- **Números clave para tener en mente** (por si hay preguntas):
  - 160 canales = 80 MEMS × 2 salidas (LF + HF)
  - 20 ADCs AD7606C-18, 8 canales/ADC, 18 bits
  - HF: 256 kS/s → T = 3.9 µs | LF: 51.2 kS/s → T = 19.5 µs
  - Readout con 4 DOUT: 36 ciclos SCLK → 0.6 µs @ 60 MHz
  - Data rate raw: 442 Mbit/s | packed 32-bit: 786 Mbit/s | con overhead: ~983 Mbit/s
  - Protección input: LTC4368 + TVS SMCJ33A + fusible 10 A
  - Buck principal: LT8645S (Silent Switcher) → 7 V intermedio
