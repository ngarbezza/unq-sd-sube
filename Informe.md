## Trabajo Práctico Final - Sistemas Distribuidos

### Problema a implementar

Decidimos implementar una simulación de un sistema de cobro de viajes similar a SUBE, un problema que por su naturaleza
es distribuido, ya que no consta de un solo programa ejecutándose en un lugar, sino de diferentes "actores" realizando
tareas en paralelo: desde el usuario con su tarjeta que desea viajar, hasta las máquinas expendedoras de pasajes, y
finalmente los servidores donde se guardan las transacciones realizadas.

### Lenguaje de programación

Decidimos hacer el trabajo en Elixir ya que su sintaxis es un poco más amigable que Erlang (pero sin perder ninguna
funcionalidad de este último) y parecido al lenguaje Ruby que nos era conocido.

### Primera versión: usando send/receive

Implementamos los siguientes procesos de ejecución:

* Usuario: que puede recibir los mensajes `cargar`, `viajar`, `descontar` (sólo para ser usado por el expendedor) y `status`.
* Expendedor: que puede recibir los mensajes `cobrar`, `servidor`, y `status`.
* Servidor: que puede recibir los mensajes `sincronizar` y `status`.

Además, hicimos las estructuras de datos Tarjeta y Transaccion para poner comportamiento modularizado de dichos datos.

Los procesos inician cada uno con un nombre (esto es para identificarlos de una mejor forma que el PID), y en el caso del
usuario también se le indica cuál va a ser su tarjeta. El mensaje `status` fue agregado para detectar el correcto
funcionamiento de los procesos. Al recibir este mensaje el proceso responde mostrando en pantalla la información más
importante que posee.

Cuando un usuario quiere viajar, se le debe enviar el mensaje `viajar` indicando la tarjeta y el monto por el que se
desea viajar, el usuario luego le enviará un mensaje al expendedor, y allí se validará que el usuario realmente pueda
viajar. Si puede, entonces el usuario recibe el mensaje `descontar` y el saldo nuevo se actualiza en su tarjeta. Todo
ocurre de manera asincrónica.

El expendedor puede trabajar offline (esto es lo que sucede con muchos dispositivos SUBE), es decir sin estar conectado
a un servidor central. Entonces, el expendedor guarda las transacciones para eventualmente sincronizarse con algún
servidor que esté disponible. Hicimos que un expendedor pueda conocer varios servidores de sincronización, y que intente
enviar sus transacciones a todos, para tener redundancia.

Un problema que teníamos en este punto era, qué pasa si el proceso del expendedor se detiene por un error inesperado,
entonces se perderían las transacciones que tiene sin enviar hasta ese momento. Lo mismo ocurriría con el usuario y su
tarjeta, hasta este punto sólo el usuario sabe qué saldo tiene su tarjeta.   

### Uso de supervisores

Observamos que si enviamos un mensaje incorrecto o tenemos algún error en el programa que cause una excepción, el proceso
se termina, y esto termina siendo poco tolerante a fallas.

Es por ello que a mitad de trabajo decidimos cambiar la implementación para usar GenServer y supervisors.

Comenzamos por el Expendedor, y nos dimos cuenta que no era muy difícil parsar de los bloques de receive y una función loop
a implementar la interfaz del GenServer.

Nos sirvió para debuggear al momento de errores. Teníamos la información del último mensaje y del estado en el que se
encontraba el proceso. Ejemplo:

```
00:24:19.312 [error] GenServer #PID<0.189.0> terminating
** (ArgumentError) argument error
    :erlang.apply(#PID<0.190.0>, :nombre, [])
    (sube) lib/expendedor.ex:63: Expendedor.handle_cast/2
    (stdlib) gen_server.erl:601: :gen_server.try_dispatch/4
    (stdlib) gen_server.erl:667: :gen_server.handle_msg/5
    (stdlib) proc_lib.erl:247: :proc_lib.init_p_do_apply/3
Last message: {:"$gen_cast", {:registrar, #PID<0.190.0>}}
State: %Expendedor{nombre: "159 interno 8", servidores: [], transacciones: []}
``` 

Como mantener el estado del expendedor, ya que tiene un nombre asociado, y mas importante, una lista de transacciones
para enviar al servidor.

Es por esto que utilizamos un Supervisor con un proceso caché del estado, y el proceso propiamente dicho del expendedor.
Ambos estan implementados usando la interfaz GenServer, entonces pueden reiniciarse tranquilamente

https://hexdocs.pm/elixir/GenServer.html
https://elixir-lang.org/getting-started/mix-otp/genserver.html
https://medium.com/blackode/how-to-retrieve-genserver-state-after-termination-the-practical-guide-1bafcff780bb

### Aprendizajes

Estas son las cosas mas importantes aprendidas relacionadas a Elixir y la programación distribuida en general

* **Testing unitario**: antes de ponernos a resolver problemas de asincronismo y tolerancia a fallas, comenzamos por probar
algunas partes claves con pruebas automatizadas. Entonces nos aseguramos que cosas como validación de saldo insuficiente
y actualización de saldo, estén cubiertas, entre otras funcionalidades.
* **Structs**: Para poder tener más consistencia, y trabajar con datos válidos definimos estructuras de datos para cada
concepto del dominio: `Usuario`, `Tarjeta`, `Transaccion`, `Expendedor` y `Servidor`. Inicialmente habíamos utilizado
simplemente diccionarios pero descartamos esta opción. La ventaja aprendida de usar Structs son ciertas validaciones que
podemos hacer, por ejemplo que un dato sea provisto sí o sí. Por ejemplo: `@enforce_keys [:nombre]`. 
* **Macros**: En algunas ocasiones, queríamos que el código sea un poco más legible y agregar ciertas funciones que no
vienen por defecto en el lenguaje. Como queríamos mantener la eficiencia, las hicimos como macros que después al momento
de compilación se van a expandir en un proceso completamente transparente para el programador. Las macros implementadas
fueron: `not_nil`, `is_empty` e `if_empty`. Sus definiciones están dentro del módulo `CoreExtensions`.
* **Librería de matchers para tests**: Para que las pruebas unitarias sean un poco más legibles, especialmente las
aserciones, utilizamos una librería llamada `ex_matchers`. Los actuales tests utilizan estas aserciones.
* **Estilos de código**: Incorporamos la librería `credo` que contiene unas guías de código que nos sirvieron para
mantener un estilo consistente en todos los lugares. A través del comando `mix credo --strict` se pueden ejecutar todas
las validaciones sobre el código. 
* **Integración continua con Gitlab**: Utilizamos el servicio de integración continua que provee GitLab, configurarlo es
muy sencillo, ya que basta con definir el archivo `.gitlab.ci.yml` con los pasos del build. En nuestro caso, es bastante
simple el script ya que consta de instalar las dependencias, y luego correr los tests.
* **Eliminar la duplicacion**, DRY: por ejemplo el `EventLogger`
* **Encapsulamiento**: creacion de structs a traves de un solo punto, funcion del modulo, funciones cliente y servidor
de cada módulo

Ideas:

* Conectar a Mongo usando replica sets, https://hexdocs.pm/mongodb/readme.html

### Referencias

1. [Ex Matchers](https://github.com/10Pines/ex_matchers): Para escribir mejores aserciones con Elixir