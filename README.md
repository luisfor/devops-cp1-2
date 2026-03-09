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

- **Unit (Pruebas Unitarias y Cobertura):** Siguiendo mejores prácticas de eficiencia, esta etapa ahora utiliza `python3 -m coverage run -m pytest`. Esto permite ejecutar los tests y recolectar datos de cobertura en un solo paso, evitando duplicidad de ejecuciones. Se ha eliminado la instalación de dependencias vía `pip` dentro del pipeline para favorecer el uso de agentes pre-configurados.
- **Rest (Pruebas de Integración):** Inicia la API y su mock usando `run_rest.sh`. Lanza peticiones de integración para verificar la comunicación. Almacena el resultado en XML JUnit.
- **Static (Análisis de Código Estático):** Empleamos **Flake8** para evaluar la calidad y formato del código. Se eliminó la instalación ad-hoc de la herramienta, asumiendo su presencia en el nodo.
- **Security Test (Bandit):** Usamos **Bandit** para auditar vulnerabilidades. Al igual que en las etapas anteriores, se eliminó la instalación manual dentro del script para optimizar el tiempo de build.
- **Coverage (Reporte):** La etapa de cobertura se ha simplificado para actuar únicamente como generador de reporte (`coverage xml`). Ya no vuelve a lanzar los tests, sino que consume los datos generados en la etapa de Unit, garantizando que las pruebas solo se ejecuten una vez como solicitó el tutor.
*   **Performance (Rendimiento):** En la última etapa, arranca Flask en el puerto `5000` (corrigiendo el puerto original en los scripts base para alinear a JMeter). JMeter lanza un plan de 20 hilos realizando múltiples llamadas.
    *   *Solución de error fundamental:* Se configuró el script `run_performance.sh` para eliminar activamente los reportes CSV y carpetas HTML anteriores (`rm -rf test-reports/jmeter-html-report`) garantizando que JMeter no explote por "Directorios no vacíos" en ejecuciones continuas.

### Resultado del Reto 1
El Pipeline finaliza probando todo con éxito. Queda en estado **UNSTABLE** (amarillo) como comportamiento deseado comprobando el sistema de Quality Gates, ya que Flake8 detona 9 errores de estilo superando el límite inestable (8) sin llegar al fallo total (10). Ninguna etapa rompe violentamente la ejecución y todos los gráficos poblados son visibles tras cada construcción de Jenkins.

## Reto 2: Distribución de Agentes (Completado)

El segundo objetivo consistió en optimizar el tiempo de ejecución mediante la paralelización de etapas que no dependen entre sí, así como comprender en detalle el sistema de gestión de cargas de trabajo de Jenkins usando múltiples ejecutores.

### 1. Creación del Pipeline de Agentes
Se redactó el archivo `Jenkinsfile_agentes` el cual reescribió el flujo secuencial usando la sintaxis de `parallel {}`. En esta configuración:
- El nivel superior define `agent none` para exigir que cada etapa defina su contexto.
- En la etapa `Get Code`, usamos `stash` (empaquetado del código fuente temporal en el maestro).
- Se crearon ejes paralelos diferenciados: **Unit**, **Coverage**, **Rest Integration** y **Quality Gates (Static & Security)**.
- Se separaron las etapas de **Unit** y **Coverage** (anteriormente unificadas) para permitir el uso de *Quality Gates* independientes y mejorar la visibilidad del flujo de CI en la interfaz de Jenkins.
- Cada eje concurrente debe usar `unstash` para descargar el repositorio fuente extraído. Los datos de cobertura se pasan entre nodos mediante `stash` de los archivos `.coverage`.
- Se eliminaron las instalaciones manuales de software (`pip install`) para cumplir con la norma de no descargar dependencias externas durante el pipeline.

### 2. Emulación de Límite de Ejecutores (Cuello de Botella)
En la demostración técnica final:
*   Se probó primero el flujo paralelo en el nodo principal (Master) provisto de **número de ejecutores (executors) múltiples**, evidenciando cómo simultáneamente se lanzan las tareas agilizando tiempos de CI.
*   Luego, configurando Jenkins para asignar **1 único ejecutor**, se demostró cómo las etapas declaradas en `parallel` efectivamente intentan ejecutarse pero la plataforma las ubica en **cola de espera (Queue)** provocando de nuevo un comportamiento similar al secuencial dependiente, siendo esta limitante la principal razón práctica por la que contar con múltiples Virtual Machines / contenedores Docker esclavos incrementa dramáticamente el potencial CI Empresarial.

## Reto 3: Mejora de Cobertura (Completado)

El último reto exigía escalar del 43% original (con fallos lógicos no testeados) a un **100% absoluto** de cobertura de código, limitándonos a modificar exclusivamente los tests unitarios (`calc_test.py`) sin alterar el código de desarrollo ni usar `pragma: no cover`.

### Explicación del problema y solución
*   **El Problema:** Al observar el reporte de cobertura interactivo, notamos que las últimas líneas de las funciones `divide()` y `check_types()` dentro de `app/calc.py` nunca se iluminaban de verde. El código fuente original sí contenía protecciones (`raise TypeError`) para "División por cero" y para "Tipos de datos inválidos (Strings, None)", pero la suite original de pruebas unitarias provista nunca ponía a prueba estos fallos, por ende, el porcentaje global se desplomaba.
*   **La Solución (Uso de GitFlow):** Acatando el requisito de no alterar Producción (`master`), creamos una nueva rama aislada llamada `feature_fix_coverage`. En ella, redactamos tres lotes de pruebas asertivas nuevas (`test_divide_method_fails_with_division_by_zero` y `test_check_types_fails_with_invalid_types`) inyectando conscientemente ceros, strings nulos y objetos irreconocibles para forzar la detonación de dichos errores y así recorrer el 100% de la lógica interna de `app/calc.py`. Este flujo demuestra la implementación segura del branching para evaluación continua de features.
*   **Resultado:** Tras la compilación paralela, el plugin `Code Coverage API` demostró matemáticamente un incremento a 100% en *Line Coverage* y *Branch Coverage* en el sumario estricto de archivos filtrados de la aplicación.

---

## Mejores Prácticas de CI/CD Aplicadas (Revisión Final)

Tras la revisión del tutor, el proyecto se ha actualizado para cumplir con estándares industriales de DevOps:

1. **Eficiencia de Pruebas**: Se eliminó la redundancia. Las pruebas unitarias solo se ejecutan una vez, recolectando la cobertura en ese mismo instante.
2. **Inmutabilidad del Entorno**: Se eliminaron los comandos `pip3 install` del pipeline. Se asume que los agentes/nodos de Jenkins son entornos controlados y pre-configurados con las herramientas necesarias (`pytest`, `flake8`, `bandit`, `coverage`).
3. **Claridad en el Pipeline Paralelo**: En el Reto 2, se dividieron las etapas para que la monitorización visual sea inmediata y precisa, permitiendo identificar fallos de lógica (`Unit`) independientemente de fallos en métricas (`Coverage`).
