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
enviar sus transacciones a todos, para tener redundancia. Las transacciones se generan con un UUID, de esta manera
podremos identificarlas para luego persistirlas. 

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
Ambos estan implementados usando la interfaz GenServer, entonces pueden reiniciarse tranquilamente.

Implementamos una función de ejemplo `crash()` que simula una excepción inesperada. Cuando esto ocurre, el proceso llama
a un _callback_ llamado `terminate` que escribe el último estado en el caché, entonces este proceso puede terminar
tranquilo. Mientras tanto, el Supervisor se va a encargar de restartear el proceso, apuntando al proceso de caché que
sigue funcionando, y con el estado actualizado. Ejemplo del output de nuestro programa:

```
EXPENDEDOR              159 interno 8           Finalizando proceso!
### cache write, expendedor %Expendedor{nombre: "159 interno 8", servidores: [#PID<0.188.0>], transacciones: []}
### cache read, expendedor %Expendedor{nombre: "159 interno 8", servidores: [#PID<0.188.0>], transacciones: []}
** (exit) exited in: GenServer.call(#PID<0.187.0>, {:status}, 5000)
    ** (EXIT) an exception was raised:
        ** (ArithmeticError) bad argument in arithmetic expression
```

Aquí se puede observar que el mismo proceso se "dio cuenta" de que estaba siendo finalizado, entonces guardó lo último
que tenía en la caché, ocurrió el reinicio, volvió a tomar lo que tenía de la caché y continuó con el mismo estado que
tenía antes. A través del observer de procesos pudimos ver cómo se generaba un nuevo PID y verificar que efectivamente
ese nuevo PID tenía en su poder el estado anterior de la app.

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
* **Eliminar la duplicacion**: En todo momento intentamos mantener las buenas prácticas de no repetir código y que el
código sea lo más expresivo posible. Un ejemplo de esto es el módulo `EventLogger`. Este módulo emergió una vez que
teníamos varios procesos que escribían información a modo de logs, que nos eran útiles para entender el funcionamiento
de la app. Lo que hicimos fue darle un poco de formato, y separar la interface (función `log_event`) de la implementación
(bien simple, con `IO.puts`) pero podría tener una mejor implementación en el futuro, y sólo hay que cambiar ese módulo.
Incluso se lo puede integrar con el trabajo `loggly` que ya realizamos para tener loggeo de eventos con un orden total.
* **Encapsulamiento**: Creacion de structs a través de un solo punto, usar el módulo como centralización de todo lo
que corresponde al concepto que estamos modelando: como construir una instancia, cómo iniciar su procesamiento, cuál es
su API de cliente y servidor. Transparencia entre un proceso base y un proceso supervisor. Para el usuario da lo mismo.
Cuando introdujimos procesos supervisados con caché para recuperarse de terminaciones de procesos, solo cambiamos la
implementación de `iniciar()` para que cree el arbol de procesos (y retorne, para nuestra comodidad, el proceso
supervisor y el supervisado en una tupla) en lugar de un solo proceso. 
* **Observer de procesos**: Con solo llamar a `:observer.start()` podíamos ver los procesos actuales y poder
manipularlos. Esto resultó muy útil para hacer pruebas como la siguiente: matar el proceso de un Expendedor y ver como
"spawnea" solo y recupera los datos de su caché.

### Referencias

1. [Ex Matchers](https://github.com/10Pines/ex_matchers): Para escribir mejores aserciones con Elixir
2. [GenServer](https://hexdocs.pm/elixir/GenServer.html): Para entender la interfaz de GenServer y cómo implementar la
mensajería sincrónica/asincrónica
3. [Tutorial de GenServers](https://elixir-lang.org/getting-started/mix-otp/genserver.html): tutorial oficial que
muestra un ejemplo de implementación de GenServer.
4. [Supervisión de procesos con caché](https://medium.com/blackode/how-to-retrieve-genserver-state-after-termination-the-practical-guide-1bafcff780bb):
De aquí tomamos la idea de hacer que algunos procesos guarden su estado en otro, para poder recuperarse si llegan a
fallar.