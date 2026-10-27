# Grupo Velsen en Turbo EA

Este codespace descarga las imágenes publicadas de Turbo EA, levanta la
plataforma y carga el modelo del holding Grupo Velsen. La primera vez
tarda entre 5 y 10 minutos.

Al terminar, **abre el puerto `8920`** en el navegador (el panel *Ports*
lo abre solo la primera vez).

## Acceso

| Campo      | Valor               |
| ---------- | ------------------- |
| Correo     | `admin@velsen.demo` |
| Contraseña | `Holding!2026demo`  |

Cambia la contraseña al entrar. Los demás usuarios tienen correos de
prueba `@grupo-velsen.mx` y no pueden iniciar sesión.

## Qué se carga

- 347 fichas: empresas, áreas, 117 procesos, 33 sistemas, 18 inmuebles y
  24 obras e iniciativas, con 589 relaciones.
- Diagramas BPMN, riesgos, decisiones, principios y tareas de proyecto.
- El archivo es `.devcontainer/velsen/grupo-velsen-workspace.zip`; lo
  importa `.devcontainer/velsen/import-velsen.sh` la primera vez.

## Importante

El codespace es temporal: se apaga tras 30 minutos sin uso y los datos se
conservan mientras no lo borres. Para que lo use el equipo hace falta un
servidor propio.

## Comandos útiles

```bash
docker compose logs -f     # ver registros
docker compose restart     # reiniciar
docker compose down        # detener
```
