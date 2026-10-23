# Cómo contribuir

¡Gracias por tu interés en Buky-Mapas! El proyecto lo mantiene Butake SpA y acepta
pull requests.

## Antes de abrir un PR

1. Abre un *issue* para cambios grandes, así lo conversamos antes de que inviertas tiempo.
2. Trabaja en una rama desde `develop` y abre el PR hacia `develop` (`main` es producción).
3. Verifica que todo siga funcionando:
   ```bash
   ./scripts/smoke.sh .env
   for f in scripts/*.sh manage.sh; do bash -n "$f"; done
   ```
4. Si cambias estilos, regenera con `python3 scripts/gen-styles.py` y no edites
   `data/styles/*.json` a mano.

## Mensajes de commit

Conventional commits en español: `<tipo>(<módulo>): <descripción>`, por ejemplo
`fix(rutas): corrige el perfil car_custom`. Tipos: `feat`, `fix`, `docs`, `chore`,
`refactor`, `ci`, `test`, `perf`, `style`.

## Licencia de los aportes

Al enviar un PR aceptas que tu aporte se publique bajo la [Licencia Apache 2.0](LICENSE)
del proyecto (sección 5 de la licencia). Conservas el crédito de tu aporte en el historial;
el aviso de copyright del proyecto (`NOTICE`) se mantiene a nombre de Butake SpA.
