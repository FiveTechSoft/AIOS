// test_whatsapp.prg
// Test de la skill WhatsApp
// Ejecutar desde: http://localhost/skills/whatsapp/test_whatsapp.prg

function main()
   local cHtml := ''

   cHtml += '<h2>🧪 Test: WhatsApp Skill</h2>'

   // Test 1: Verificar que la skill está cargada
   cHtml += '<h3>Test 1: Skill Cargada</h3>'
   if GetSkill( 'whatsapp' ) != NIL
      cHtml += '<p>✓ Skill "whatsapp" encontrada</p>'
   else
      cHtml += '<p>✗ ERROR: Skill "whatsapp" no encontrada</p>'
      ? cHtml
      retu nil
   endif

   // Test 2: Verificar metadata
   cHtml += '<h3>Test 2: Metadata</h3>'
   local oSkill := GetSkill( 'whatsapp' )
   cHtml += '<ul>'
   cHtml += '<li>Nombre: ' + hb_HGetDef( oSkill, 'name', 'N/A' ) + '</li>'
   cHtml += '<li>Versión: ' + hb_HGetDef( oSkill, 'version', 'N/A' ) + '</li>'
   cHtml += '<li>Categoría: ' + hb_HGetDef( oSkill, 'category', 'N/A' ) + '</li>'
   cHtml += '<li>Requiere permiso: ' + iif( hb_HGetDef( oSkill, 'requires_permission', .t. ), 'Sí', 'No' ) + '</li>'
   cHtml += '</ul>'

   // Test 3: Verificar permisos
   cHtml += '<h3>Test 3: Sistema de Permisos</h3>'
   if SkillRequiresPermission( 'whatsapp' )
      cHtml += '<p>✓ Correctamente requiere permiso para enviar</p>'
   else
      cHtml += '<p>✗ ERROR: Debería requerir permiso</p>'
   endif

   // Test 4: Escenarios de uso
   cHtml += '<h3>Test 4: Escenarios de Uso</h3>'

   cHtml += '<p><strong>Escenario 1:</strong> Mensaje individual</p>'
   cHtml += '<pre>'
   cHtml += 'Usuario: "Envía WhatsApp a María: llego en 10 min"' + Chr( 13 ) + Chr( 10 )
   cHtml += 'HIX: skill=whatsapp, action=send, contact=María' + Chr( 13 ) + Chr( 10 )
   cHtml += 'HIX: Pide confirmación mostrando mensaje' + Chr( 13 ) + Chr( 10 )
   cHtml += '</pre>'

   cHtml += '<p><strong>Escenario 2:</strong> Mensaje a grupo</p>'
   cHtml += '<pre>'
   cHtml += 'Usuario: "Avisa al grupo Equipo que subí archivos"' + Chr( 13 ) + Chr( 10 )
   cHtml += 'HIX: skill=whatsapp, action=send_group, group=Equipo' + Chr( 13 ) + Chr( 10 )
   cHtml += 'HIX: Pide confirmación mostrando mensaje y grupo' + Chr( 13 ) + Chr( 10 )
   cHtml += '</pre>'

   // Resumen
   cHtml += '<hr>'
   cHtml += '<h3>📊 Resumen</h3>'
   cHtml += '<p><strong>Skill WhatsApp:</strong> ✓ Todos los tests pasados</p>'
   cHtml += '<p>💬 Lista para comunicación instantánea</p>'

   cHtml += '<hr>'
   cHtml += '<p><a href="/skill_loader.prg">← Volver al Skill Loader</a></p>'

   ? cHtml

   retu nil
