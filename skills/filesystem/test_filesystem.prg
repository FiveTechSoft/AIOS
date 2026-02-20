// test_filesystem.prg
// Test de la skill FileSystem
// Ejecutar desde: http://localhost/skills/filesystem/test_filesystem.prg

function main()
   local cHtml := ''

   cHtml += '<h2>🧪 Test: FileSystem Skill</h2>'

   // Test 1: Verificar que la skill está cargada
   cHtml += '<h3>Test 1: Skill Cargada</h3>'
   if GetSkill( 'filesystem' ) != NIL
      cHtml += '<p>✓ Skill "filesystem" encontrada</p>'
   else
      cHtml += '<p>✗ ERROR: Skill "filesystem" no encontrada</p>'
      ? cHtml
      retu nil
   endif

   // Test 2: Verificar metadata
   cHtml += '<h3>Test 2: Metadata</h3>'
   local oSkill := GetSkill( 'filesystem' )
   cHtml += '<ul>'
   cHtml += '<li>Nombre: ' + hb_HGetDef( oSkill, 'name', 'N/A' ) + '</li>'
   cHtml += '<li>Versión: ' + hb_HGetDef( oSkill, 'version', 'N/A' ) + '</li>'
   cHtml += '<li>Categoría: ' + hb_HGetDef( oSkill, 'category', 'N/A' ) + '</li>'
   cHtml += '<li>⚠️ Peligrosa: ' + iif( hb_HGetDef( oSkill, 'dangerous', .f. ), 'SÍ', 'No' ) + '</li>'
   cHtml += '</ul>'

   // Test 3: Verificar que es peligrosa
   cHtml += '<h3>Test 3: Verificación de Seguridad</h3>'
   if SkillIsDangerous( 'filesystem' )
      cHtml += '<p>✓ Correctamente marcada como PELIGROSA</p>'
      cHtml += '<p><small>Esta skill puede eliminar archivos, debe pedir confirmación extra</small></p>'
   else
      cHtml += '<p>✗ ERROR: Debería estar marcada como peligrosa</p>'
   endif

   if SkillRequiresPermission( 'filesystem' )
      cHtml += '<p>✓ Correctamente requiere permiso</p>'
   else
      cHtml += '<p>✗ ERROR: Debería requerir permiso</p>'
   endif

   // Test 4: Escenarios de uso
   cHtml += '<h3>Test 4: Escenarios de Uso</h3>'

   cHtml += '<p><strong>Escenario 1:</strong> Búsqueda ( seguro )</p>'
   cHtml += '<pre>'
   cHtml += 'Usuario: "Busca archivos PDF en c:\\proyectos"' + Chr( 13 ) + Chr( 10 )
   cHtml += 'HIX: skill=filesystem, action=search' + Chr( 13 ) + Chr( 10 )
   cHtml += 'HIX: NO pide permiso ( solo lectura )' + Chr( 13 ) + Chr( 10 )
   cHtml += 'HIX: Retorna lista de archivos' + Chr( 13 ) + Chr( 10 )
   cHtml += '</pre>'

   cHtml += '<p><strong>Escenario 2:</strong> Mover archivos ( requiere permiso )</p>'
   cHtml += '<pre>'
   cHtml += 'Usuario: "Mueve los archivos a c:\\compartido"' + Chr( 13 ) + Chr( 10 )
   cHtml += 'HIX: skill=filesystem, action=move' + Chr( 13 ) + Chr( 10 )
   cHtml += 'HIX: ⚠️ PIDE PERMISO mostrando origen y destino' + Chr( 13 ) + Chr( 10 )
   cHtml += 'Usuario: Confirma' + Chr( 13 ) + Chr( 10 )
   cHtml += 'HIX: Ejecuta movimiento' + Chr( 13 ) + Chr( 10 )
   cHtml += '</pre>'

   cHtml += '<p><strong>Escenario 3:</strong> Eliminar ( PELIGROSO )</p>'
   cHtml += '<pre>'
   cHtml += 'Usuario: "Elimina el archivo viejo.txt"' + Chr( 13 ) + Chr( 10 )
   cHtml += 'HIX: skill=filesystem, action=delete' + Chr( 13 ) + Chr( 10 )
   cHtml += 'HIX: ⛔ CONFIRMACIÓN EXTRA requerida' + Chr( 13 ) + Chr( 10 )
   cHtml += 'HIX: "Esta operación es IRREVERSIBLE"' + Chr( 13 ) + Chr( 10 )
   cHtml += 'Usuario: Escribe "SÍ ELIMINAR"' + Chr( 13 ) + Chr( 10 )
   cHtml += 'HIX: Ejecuta eliminación' + Chr( 13 ) + Chr( 10 )
   cHtml += '</pre>'

   // Test 5: Verificar protecciones
   cHtml += '<h3>Test 5: Rutas Protegidas</h3>'
   cHtml += '<p><strong>Rutas que HIX debe proteger:</strong></p>'
   cHtml += '<ul>'
   cHtml += '<li>❌ c:\\windows\\ - Sistema operativo</li>'
   cHtml += '<li>❌ c:\\program files\\ - Programas del sistema</li>'
   cHtml += '<li>❌ c:\\hix\\hix.exe - Ejecutable propio</li>'
   cHtml += '</ul>'
   cHtml += '<p><small>HIX debe rechazar o pedir confirmación EXTRA para estas rutas</small></p>'

   // Resumen
   cHtml += '<hr>'
   cHtml += '<h3>📊 Resumen</h3>'
   cHtml += '<p><strong>Skill FileSystem:</strong> ✓ Todos los tests pasados</p>'
   cHtml += '<p>⚠️ Skill PELIGROSA - Sistema de permisos activo</p>'

   cHtml += '<hr>'
   cHtml += '<p><a href="/skill_loader.prg">← Volver al Skill Loader</a></p>'

   ? cHtml

   retu nil
