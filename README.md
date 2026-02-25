# Caso Práctico 1.2 - CI/CD Avanzado y DevOps

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
