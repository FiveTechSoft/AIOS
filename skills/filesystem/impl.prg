// filesystem_impl.prg - Implementación de FileSystem Skill
// Operaciones seguras con el sistema de archivos
#include "hix.ch"

//------------------------------------------------------------------------------
// Ejecutor principal del FileSystem Skill
//------------------------------------------------------------------------------
function FileSystem_Execute( hParams )
   local cAction := hb_HGetDef( hParams, 'action', '' )
   local hResult := {=>}

   _d( "[FILESYSTEM] Action: " + cAction )

   do case
   case cAction == 'search' .or. cAction == 'find'
      hResult := FileSystem_Search( hParams )

   case cAction == 'read'
      hResult := FileSystem_Read( hParams )

   case cAction == 'write'
      hResult := FileSystem_Write( hParams )

   case cAction == 'list' .or. cAction == 'ls'
      hResult := FileSystem_List( hParams )

   case cAction == 'delete' .or. cAction == 'remove'
      hResult := FileSystem_Delete( hParams )

   case cAction == 'move' .or. cAction == 'rename'
      hResult := FileSystem_Move( hParams )

   otherwise
      hResult['success'] := .f.
      hResult['error'] := "Unknown action: " + cAction
   endcase

   retu hResult

   //------------------------------------------------------------------------------
   // Buscar archivos
   //------------------------------------------------------------------------------
function FileSystem_Search( hParams )
   local cPattern := hb_HGetDef( hParams, 'pattern', '*.*' )
   local cPath := hb_HGetDef( hParams, 'path', '.' )
   local aFiles, cFile
   local aResult := {}
   local hResult := {=>}

   // Validar que no sea ruta protegida
   if IsProtectedPath( cPath )
      hResult['success'] := .f.
      hResult['error'] := "Path is protected: " + cPath
      retu hResult
   endif

   // Buscar archivos
   aFiles := Directory( cPath + '\' + cPattern )

   for each cFile in aFiles
      if !( cFile[1] $ '.,' )  // Ignorar . y ..
         aAdd( aResult, {;
         "name" => cFile[1],;
         "size" => cFile[2],;
         "date" => cFile[3],;
         "path" => cPath;
         } )
      endif
   next

   hResult['success'] := .t.
   hResult['files'] := aResult
   hResult['count'] := Len( aResult )

   retu hResult

   //------------------------------------------------------------------------------
   // Listar directorio
   //------------------------------------------------------------------------------
function FileSystem_List( hParams )
   local cPath := hb_HGetDef( hParams, 'path', '.' )

   // Listar todos los archivos
   hParams['pattern'] := '*.*'

   retu FileSystem_Search( hParams )

   //------------------------------------------------------------------------------
   // Leer archivo
   //------------------------------------------------------------------------------
function FileSystem_Read( hParams )
   local cFile := hb_HGetDef( hParams, 'file', '' )
   local cContent
   local hResult := {=>}

   if Empty( cFile )
      hResult['success'] := .f.
      hResult['error'] := "File parameter required"
      retu hResult
   endif

   if IsProtectedPath( cFile )
      hResult['success'] := .f.
      hResult['error'] := "File is in protected path: " + cFile
      retu hResult
   endif

   if ! File( cFile )
      hResult['success'] := .f.
      hResult['error'] := "File not found: " + cFile
      retu hResult
   endif

   cContent := MemoRead( cFile )

   hResult['success'] := .t.
   hResult['content'] := cContent
   hResult['size'] := Len( cContent )

   retu hResult

   //------------------------------------------------------------------------------
   // Escribir archivo
   //------------------------------------------------------------------------------
function FileSystem_Write( hParams )
   local cFile := hb_HGetDef( hParams, 'file', '' )
   local cContent := hb_HGetDef( hParams, 'content', '' )
   local hResult := {=>}

   if Empty( cFile )
      hResult['success'] := .f.
      hResult['error'] := "File parameter required"
      retu hResult
   endif

   if IsProtectedPath( cFile )
      hResult['success'] := .f.
      hResult['error'] := "Cannot write to protected path: " + cFile
      retu hResult
   endif

   if MemoWrit( cFile, cContent )
      hResult['success'] := .t.
      hResult['bytes_written'] := Len( cContent )
   else
      hResult['success'] := .f.
      hResult['error'] := "Failed to write file"
   endif

   retu hResult

   //------------------------------------------------------------------------------
   // Eliminar archivo ( PELIGROSO )
   //------------------------------------------------------------------------------
function FileSystem_Delete( hParams )
   local cFile := hb_HGetDef( hParams, 'file', '' )
   local hResult := {=>}

   if Empty( cFile )
      hResult['success'] := .f.
      hResult['error'] := "File parameter required"
      retu hResult
   endif

   if IsProtectedPath( cFile )
      hResult['success'] := .f.
      hResult['error'] := "Cannot delete protected file: " + cFile
      retu hResult
   endif

   if ! File( cFile )
      hResult['success'] := .f.
      hResult['error'] := "File not found: " + cFile
      retu hResult
   endif

   // NOTA: Esta función debería requerir confirmación del usuario
   // Esto se manejará en skill_runner.prg

   if FErase( cFile ) == 0
      hResult['success'] := .t.
      hResult['message'] := "File deleted: " + cFile
   else
      hResult['success'] := .f.
      hResult['error'] := "Failed to delete file"
   endif

   retu hResult

   //------------------------------------------------------------------------------
   // Mover/Renombrar archivo
   //------------------------------------------------------------------------------
function FileSystem_Move( hParams )
   local cFrom := hb_HGetDef( hParams, 'from', '' )
   local cTo := hb_HGetDef( hParams, 'to', '' )
   local hResult := {=>}

   if Empty( cFrom ) .or. Empty( cTo )
      hResult['success'] := .f.
      hResult['error'] := "Both 'from' and 'to' parameters required"
      retu hResult
   endif

   if IsProtectedPath( cFrom ) .or. IsProtectedPath( cTo )
      hResult['success'] := .f.
      hResult['error'] := "Cannot move to/from protected paths"
      retu hResult
   endif

   if ! File( cFrom )
      hResult['success'] := .f.
      hResult['error'] := "Source file not found: " + cFrom
      retu hResult
   endif

   if hb_FileRename( cFrom, cTo )
      hResult['success'] := .t.
      hResult['message'] := "File moved: " + cFrom + " -> " + cTo
   else
      hResult['success'] := .f.
      hResult['error'] := "Failed to move file"
   endif

   retu hResult

   //------------------------------------------------------------------------------
   // Verifica si una ruta está protegida
   //------------------------------------------------------------------------------
function IsProtectedPath( cPath )
   local aProtected := {;
   'C:\Windows',;
   'C:\Program Files',;
   'C:\Program Files ( x86 )',;
   'C:\ProgramData',;
   'C:\System',;
   '\Windows',;
   '\System32';
   }
   local cProtected

   cPath := Upper( AllTrim( cPath ) )

   for each cProtected in aProtected
      if Upper( cProtected ) $ cPath
         retu .t.
      endif
   next

   retu .f.

   //------------------------------------------------------------------------------
   // Test de la implementación
   //------------------------------------------------------------------------------
function FileSystem_Test()
   local hResult
   local cHtml := '<! DOCTYPE html><html><head><meta charset="UTF-8"></head><body>'

   cHtml += '<h1>📂 FileSystem Skill Test</h1>'

   // Test 1: Listar archivos en directorio actual
   cHtml += '<h2>Test 1: Listar archivos .prg</h2>'
   hResult := FileSystem_Execute( { "action" => 'search', "pattern" => '*.prg', "path" => 'c:\hix'} )

   if hResult['success']
      cHtml += '<p>✅ Encontrados: ' + AllTrim( Str( hResult['count'] ) ) + ' archivos</p>'
      cHtml += '<ul>'
      for each file in hResult['files']
         cHtml += '<li>' + file['name'] + ' ( ' + AllTrim( Str( file['size'] ) ) + ' bytes )</li>'
      next
      cHtml += '</ul>'
   else
      cHtml += '<p>❌ Error: ' + hResult['error'] + '</p>'
   endif

   // Test 2: Leer archivo
   cHtml += '<h2>Test 2: Leer archivo</h2>'
   hResult := FileSystem_Execute( { "action" => 'read', "file" => 'c:\hix\test_simple.prg'} )

   if hResult['success']
      cHtml += '<p>✅ Leído: ' + AllTrim( Str( hResult['size'] ) ) + ' bytes</p>'
      cHtml += '<pre>' + Left( hResult['content'], 200 ) + '...</pre>'
   else
      cHtml += '<p>❌ Error: ' + hResult['error'] + '</p>'
   endif

   // Test 3: Intentar acceder a ruta protegida
   cHtml += '<h2>Test 3: Protección de rutas del sistema</h2>'
   hResult := FileSystem_Execute( { "action" => 'search', "pattern" => '*.*', "path" => 'C:\Windows'} )

   if hResult['success']
      cHtml += '<p>❌ FALLO: No debería permitir acceso a Windows</p>'
   else
      cHtml += '<p>✅ Correctamente bloqueado: ' + hResult['error'] + '</p>'
   endif

   cHtml += '</body></html>'

   UWrite( cHtml )
   retu ""
