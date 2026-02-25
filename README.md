# Caso Práctico 1.2 - CI Avanzado, Agentes y Cobertura (DevOps)

## Contexto y Origen del Código Base (CP1.1)
El código fuente utilizado en esta práctica consiste en una **API REST (Microservicio) desarrollada en Python con Flask**, capaz de realizar operaciones matemáticas básicas (Suma, Resta, Multiplicación, División).

**Es fundamental aclarar que este código base (la lógica de la calculadora) fue heredado del ejercicio previo del máster (Caso Práctico 1.1).** El objetivo académico de este CP1.2 **no** es la programación de la aplicación en sí misma, sino la implementación de una arquitectura DevOps madura a su alrededor. Por ello, el trabajo documentado a continuación se centra de forma exclusiva en la creación de pipelines de Integración Continua (CI), el manejo de Nodos/Agentes paralelos en Jenkins, el análisis de código estático/dinámico y garantizar el 100% de cobertura en las pruebas unitarias.

---

Este repositorio contiene la solución completa al Caso Práctico 1.2, enfocado en la implementación de un pipeline avanzado de Integración Continua (CI) usando Jenkins, Python, y múltiples herramientas de análisis estático, seguridad, cobertura y rendimiento.

## Reto 1: Pipeline Avanzado (Completado)

El primer objetivo logrado fue la configuración del `Jenkinsfile` principal que se encuentra en la raíz, asegurando que todas las herramientas funcionen de forma fluida bajo una ejecución tipo pipeline continuo en Mac OS.

### 1. Preparación del Entorno
*   Se clonó el código base (API Flask calculadora) y se creó un nuevo repositorio en GitHub.
*   Resolvimos los problemas de rutas y permisos de ejecución local de los scripts bash (`run_rest.sh` y `run_performance.sh`).
*   Se configuró un trabajo de tipo **Pipeline** en Jenkins enlazado a este repositorio (`devops-cp1-2`).

### 2. Etapas del Pipeline

A continuación, la explicación paso a paso de lo configurado en el pipeline:

*   **Get Code:** Jenkins descarga el código directamente desde GitHub en cada ejecución utilizando la directiva `checkout scm`.
*   **Unit (Pruebas Unitarias):** En esta etapa se instalan las dependencias definidas en `requirements.txt`. El script levanta un entorno con `pytest` y evalúa únicamente la lógica matemática en `test/unit`. Guarda un reporte formato XML JUnit.
*   **Rest (Pruebas de Integración):** Inicia la API y su mock usando `run_rest.sh`. Lanza peticiones de integración para verificar la comunicación. De igual modo que la anterior, almacena el resultado en XML JUnit.
*   **Static (Análisis de Código Estático):** Empleamos **Flake8** para evaluar la calidad y formato del código en la carpeta `app/`. Mediante el plugin *Warnings Next Generation Plugin (Warnings-NG)* de Jenkins, interpretamos la salida de Flake8.
    *   *Configuración de umbrales:* Se estipuló que si hay 8 hallazgos o más, la build sea "Inestable" (Unstable), y 10 o más sea "Failure" (roja). Con 9 hallazgos actuales, la build pasa a estado Inestable pero no cancela la ejecución.
*   **Security Test (Bandit):** Usamos la herramienta **Bandit** para auditar posibles vulnerabilidades. Para que Warnings-NG pudiera interpretarla, definimos un formato idéntico al de Flake8 pasándolo como argumento a Bandit.
    *   *Configuración de umbrales:* El límite inestable se configuró en 2 errores, y fallido en 4.
*   **Coverage (Cobertura de Código):** Inicialmente, el plugin antiguo de Jenkins para Cobertura lanzaba errores críticos de compatibilidad con Java (`hudson.util.IOException2`). Se resolvió utilizando el plugin moderno **Code Coverage API plugin**, llamándolo mediante la instrucción `recordCoverage`. Esto lee con éxito el reporte XML generado previamente por la directiva `coverage`.
*   **Performance (Rendimiento):** En la última etapa, arranca Flask en el puerto `5000` (corrigiendo el puerto original en los scripts base para alinear a JMeter). JMeter lanza un plan de 20 hilos realizando múltiples llamadas.
    *   *Solución de error fundamental:* Se configuró el script `run_performance.sh` para eliminar activamente los reportes CSV y carpetas HTML anteriores (`rm -rf test-reports/jmeter-html-report`) garantizando que JMeter no explote por "Directorios no vacíos" en ejecuciones continuas.

### Resultado del Reto 1
El Pipeline finaliza probando todo con éxito. Queda en estado **UNSTABLE** (amarillo) como comportamiento deseado comprobando el sistema de Quality Gates, ya que Flake8 detona 9 errores de estilo superando el límite inestable (8) sin llegar al fallo total (10). Ninguna etapa rompe violentamente la ejecución y todos los gráficos poblados son visibles tras cada construcción de Jenkins.

## Reto 2: Distribución de Agentes (Completado)

El segundo objetivo consistió en optimizar el tiempo de ejecución mediante la paralelización de etapas que no dependen entre sí, así como comprender en detalle el sistema de gestión de cargas de trabajo de Jenkins usando múltiples ejecutores.

### 1. Creación del Pipeline de Agentes
Se redactó el archivo `Jenkinsfile_agentes` el cual reescribió el flujo secuencial usando la sintaxis de `parallel {}`. En esta configuración:
*   El nivel superior define `agent none` para exigir que cada etapa defina su contexto.
*   En la etapa `Get Code`, usamos `stash` (empaquetado del código fuente temporal en el maestro).
*   Se crearon tres ejes paralelos: **Unit & Coverage**, **Rest Integration** y **Quality Gates (Static & Security)**.
*   Cada eje concurrente debe usar `unstash` para descargar el repositorio fuente extraído.
*   Se inyectó el comando obligatoriamente exigido (`whoami`, `hostname`, y `echo $WORKSPACE`) al inicio de cada proceso, para documentar el nodo donde se ejecutaron.
*   Finalmente, la fase **Performance** ejecuta después tras converger el éxito parcial.

### 2. Emulación de Límite de Ejecutores (Cuello de Botella)
En la demostración técnica final:
*   Se probó primero el flujo paralelo en el nodo principal (Master) provisto de **número de ejecutores (executors) múltiples**, evidenciando cómo simultáneamente se lanzan las tareas agilizando tiempos de CI.
*   Luego, configurando Jenkins para asignar **1 único ejecutor**, se demostró cómo las etapas declaradas en `parallel` efectivamente intentan ejecutarse pero la plataforma las ubica en **cola de espera (Queue)** provocando de nuevo un comportamiento similar al secuencial dependiente, siendo esta limitante la principal razón práctica por la que contar con múltiples Virtual Machines / contenedores Docker esclavos incrementa dramáticamente el potencial CI Empresarial.

## Reto 3: Mejora de Cobertura (Completado)

El último reto exigía escalar del 43% original (con fallos lógicos no testeados) a un **100% absoluto** de cobertura de código, limitándonos a modificar exclusivamente los tests unitarios (`calc_test.py`) sin alterar el código de desarrollo ni usar `pragma: no cover`.

### Explicación del problema y solución
*   **El Problema:** Al observar el reporte de cobertura interactivo, notamos que las últimas líneas de las funciones `divide()` y `check_types()` dentro de `app/calc.py` nunca se iluminaban de verde. El código fuente original sí contenía protecciones (`raise TypeError`) para "División por cero" y para "Tipos de datos inválidos (Strings, None)", pero la suite original de pruebas unitarias provista nunca ponía a prueba estos fallos, por ende, el porcentaje global se desplomaba.
*   **La Solución:** Mediante una nueva rama llamada `feature_fix_coverage`, redactamos tres lotes de pruebas asertivas nuevas (`test_divide_method_fails_with_division_by_zero` y `test_check_types_fails_with_invalid_types`) inyectando conscientemente ceros, strings nulos y objetos irreconocibles para forzar la detonación de dichos errores y así recorrer el 100% de la lógica interna de `app/calc.py`.
*   **Resultado:** Tras la compilación paralela, el plugin `Code Coverage API` demostró matemáticamente un incremento a 100% en *Line Coverage* y *Branch Coverage* en el sumario estricto de archivos filtrados de la aplicación.
