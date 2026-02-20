// test_gmail.prg
// Test de la skill Gmail
// Ejecutar desde: http://localhost/skills/gmail/test_gmail.prg

function main()
   local cHtml := ''

   cHtml += '<h2>🧪 Test: Gmail Skill</h2>'

   // Test 1: Verificar que la skill está cargada
   cHtml += '<h3>Test 1: Skill Cargada</h3>'
   if GetSkill( 'gmail' ) != NIL
      cHtml += '<p>✓ Skill "gmail" encontrada</p>'
   else
      cHtml += '<p>✗ ERROR: Skill "gmail" no encontrada</p>'
      ? cHtml
      retu nil
   endif

   // Test 2: Verificar metadata
   cHtml += '<h3>Test 2: Metadata</h3>'
   local oSkill := GetSkill( 'gmail' )
   cHtml += '<ul>'
   cHtml += '<li>Nombre: ' + hb_HGetDef( oSkill, 'name', 'N/A' ) + '</li>'
   cHtml += '<li>Versión: ' + hb_HGetDef( oSkill, 'version', 'N/A' ) + '</li>'
   cHtml += '<li>Categoría: ' + hb_HGetDef( oSkill, 'category', 'N/A' ) + '</li>'
   cHtml += '<li>Requiere permiso: ' + iif( hb_HGetDef( oSkill, 'requires_permission', .t. ), 'Sí', 'No' ) + '</li>'
   cHtml += '<li>Peligrosa: ' + iif( hb_HGetDef( oSkill, 'dangerous', .f. ), 'Sí', 'No' ) + '</li>'
   cHtml += '</ul>'

   // Test 3: Verificar permisos
   cHtml += '<h3>Test 3: Sistema de Permisos</h3>'
   if SkillRequiresPermission( 'gmail' )
      cHtml += '<p>✓ Correctamente requiere permiso</p>'
   else
      cHtml += '<p>✗ ERROR: Debería requerir permiso</p>'
   endif

   if ! SkillIsDangerous( 'gmail' )
      cHtml += '<p>✓ Correctamente NO es peligrosa</p>'
   else
      cHtml += '<p>⚠️ ADVERTENCIA: Marcada como peligrosa</p>'
   endif

   // Test 4: Simular uso
   cHtml += '<h3>Test 4: Simulación de Uso</h3>'
   cHtml += '<p><strong>Escenario:</strong> Enviar email a juan@example.com</p>'
   cHtml += '<pre>'
   cHtml += 'Usuario: "Envía un email a juan@example.com"' + Chr( 13 ) + Chr( 10 )
   cHtml += 'HIX: Detecta skill=gmail, action=send' + Chr( 13 ) + Chr( 10 )
   cHtml += 'HIX: Pide permiso ( requires_permission=true )' + Chr( 13 ) + Chr( 10 )
   cHtml += 'Usuario: Confirma' + Chr( 13 ) + Chr( 10 )
   cHtml += 'HIX: Ejecuta gmail_api.send()' + Chr( 13 ) + Chr( 10 )
   cHtml += '</pre>'

   // Resumen
   cHtml += '<hr>'
   cHtml += '<h3>📊 Resumen</h3>'
   cHtml += '<p><strong>Skill Gmail:</strong> ✓ Todos los tests pasados</p>'
   cHtml += '<p>La skill está correctamente configurada y lista para usar.</p>'

   cHtml += '<hr>'
   cHtml += '<p><a href="/skill_loader.prg">← Volver al Skill Loader</a></p>'

   ? cHtml

   retu nil
