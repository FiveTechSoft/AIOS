---
name: "filesystem"
version: "1.0.0"
description: "Gestiona archivos y directorios del sistema de archivos"
category: "filesystem"
author: "HIX Team"
requires_permission: true
dangerous: true
---

# FileSystem Skill

## Overview
Esta skill permite a HIX interactuar con el sistema de archivos para leer, escribir, mover, copiar y eliminar archivos y directorios. **CUIDADO**: Esta skill puede realizar operaciones destructivas.

## Capabilities
- Listar archivos y directorios
- Buscar archivos por nombre o contenido
- Leer contenido de archivos
- Crear, mover, copiar archivos
- Eliminar archivos y directorios
- Obtener información de archivos (tamaño, fecha, etc.)

## Parameters

### Required
- `action` (string): Acción a realizar

### Optional
- `path` (string): Ruta del archivo o directorio
- `pattern` (string): Patrón de búsqueda
- `destination` (string): Destino para mover/copiar
- `recursive` (boolean): Operación recursiva

## Usage Examples

### Example 1: Buscar Archivos
**User Intent**: "Busca todos los archivos PDF del proyecto Alpha"

**HIX Understanding**:
```json
{
  "skill": "filesystem",
  "action": "search",
  "parameters": {
    "path": "c:\\proyectos\\alpha",
    "pattern": "*.pdf",
    "recursive": true
  }
}
```

**Expected Output**:
```
📁 Encontrados 5 archivos PDF en c:\proyectos\alpha:

1. propuesta.pdf (245 KB) - Modificado: 15/02/2026 10:30
2. presupuesto.pdf (128 KB) - Modificado: 14/02/2026 16:45
3. contratos\contrato_final.pdf (512 KB) - Modificado: 13/02/2026 09:00
4. docs\manual.pdf (1.2 MB) - Modificado: 10/02/2026 14:20
5. presentacion.pdf (3.4 MB) - Modificado: 08/02/2026 11:15
```

### Example 2: Mover Archivos
**User Intent**: "Mueve los archivos del proyecto Alpha a la carpeta compartida"

**HIX Understanding**:
```json
{
  "skill": "filesystem",
  "action": "move",
  "parameters": {
    "source": "c:\\proyectos\\alpha\\*.docx",
    "destination": "c:\\compartido\\alpha\\"
  }
}
```

**HIX Asks Permission**: 
> ⚠️ **OPERACIÓN DESTRUCTIVA - Permiso requerido**
> 
> Voy a mover 5 archivos:
> - informe.docx
> - notas.docx
> - resumen.docx
> - analisis.docx
> - conclusiones.docx
> 
> Desde: `c:\proyectos\alpha\`
> Hacia: `c:\compartido\alpha\`
> 
> Esta operación MOVERÁ los archivos (no los copiará)
> 
> ¿Procedo? (sí/no/copiar en su lugar)

**Expected Output**: ✓ 5 archivos movidos correctamente

### Example 3: Leer Archivo
**User Intent**: "¿Qué dice el archivo readme.txt?"

**HIX Understanding**:
```json
{
  "skill": "filesystem",
  "action": "read",
  "parameters": {
    "path": "c:\\hix\\readme.txt"
  }
}
```

**Expected Output**: Contenido del archivo formateado

## Actions

### list
**Description**: Lista archivos en un directorio

**Parameters**:
- `path` (required): Ruta del directorio
- `pattern` (optional): Filtro (ej: *.txt)
- `recursive` (optional): Incluir subdirectorios

**Returns**: Lista de archivos con metadata

**Requires Permission**: ✗ Solo lectura

### search
**Description**: Busca archivos por nombre o contenido

**Parameters**:
- `path` (required): Directorio raíz de búsqueda
- `pattern` (required): Patrón de búsqueda
- `content` (optional): Buscar dentro del contenido
- `recursive` (optional): Buscar en subdirectorios

**Returns**: Lista de archivos encontrados

**Requires Permission**: ✗ Solo lectura

### read
**Description**: Lee el contenido de un archivo

**Parameters**:
- `path` (required): Ruta del archivo
- `encoding` (optional): Codificación (default: UTF-8)

**Returns**: Contenido del archivo

**Requires Permission**: ✗ Solo lectura

### write
**Description**: Escribe o crea un archivo

**Parameters**:
- `path` (required): Ruta del archivo
- `content` (required): Contenido a escribir
- `append` (optional): Añadir al final o sobrescribir

**Returns**: Confirmation

**Requires Permission**: ✓ Modifica sistema de archivos

### move
**Description**: Mueve archivos/directorios

**Parameters**:
- `source` (required): Origen
- `destination` (required): Destino

**Returns**: Confirmation con lista de archivos movidos

**Requires Permission**: ✓ SIEMPRE - Operación destructiva

### copy
**Description**: Copia archivos/directorios

**Parameters**:
- `source` (required): Origen
- `destination` (required): Destino
- `recursive` (optional): Copiar subdirectorios

**Returns**: Confirmation con lista de archivos copiados

**Requires Permission**: ✓ Puede llenar el disco

### delete
**Description**: Elimina archivos/directorios

**Parameters**:
- `path` (required): Ruta a eliminar
- `recursive` (optional): Eliminar subdirectorios

**Returns**: Confirmation

**Requires Permission**: ✓ SIEMPRE - IRREVERSIBLE

### info
**Description**: Obtiene información de un archivo

**Parameters**:
- `path` (required): Ruta del archivo

**Returns**: Tamaño, fechas, permisos, tipo

**Requires Permission**: ✗ Solo lectura

## Safety & Permissions

### When to Ask Permission
- **write**: SIEMPRE si sobrescribe archivo existente
- **move**: SIEMPRE - Muestra origen y destino
- **copy**: SI si el destino existe
- **delete**: SIEMPRE - Operación IRREVERSIBLE
- **list/read/search/info**: NO - Solo lectura

### Safety Checks
- ⛔ **NUNCA** eliminar sin confirmación explícita
- ⚠️ Advertir si se van a eliminar >10 archivos
- ⚠️ Advertir si archivos son >100MB
- ✓ Validar que el destino existe antes de mover
- ✓ Detectar si hay conflictos de nombres
- 🔒 No permitir operaciones fuera de directorios permitidos

### Protected Directories
HIX NO puede modificar (sin confirmación extra):
- `C:\Windows\`
- `C:\Program Files\`
- Archivos del sistema
- Directorio de HIX (`c:\hix\hix.exe`, `hix.json`)

## Error Handling

### Common Errors
1. **FILE_NOT_FOUND**: Archivo no existe → Sugerir búsqueda
2. **ACCESS_DENIED**: Sin permisos → Ejecutar como admin
3. **FILE_IN_USE**: Archivo bloqueado → Esperar o forzar cierre
4. **DISK_FULL**: Sin espacio → Limpiar archivos temporales
5. **INVALID_PATH**: Ruta inválida → Validar sintaxis

## Implementation Notes

### Dependencies
- `os`, `shutil`, `pathlib` (Python stdlib)
- `send2trash` para eliminar a papelera (opcional)

### Configuration
```json
{
  "filesystem": {
    "allowed_paths": [
      "c:\\proyectos\\",
      "c:\\compartido\\",
      "c:\\users\\antonio\\documentos\\"
    ],
    "protected_paths": [
      "c:\\windows\\",
      "c:\\program files\\",
      "c:\\hix\\hix.exe"
    ],
    "trash_instead_of_delete": true
  }
}
```

### File Structure
```
skills/filesystem/
├── SKILL.md
├── fs_manager.py
├── search.py
├── safety.py
└── test_filesystem.prg    # Test en Harbour
```

## Testing

### Manual Test
**Ejecutar**: `http://localhost/skills/filesystem/test_filesystem.prg`

El test verifica:
1. Skill marcada correctamente como PELIGROSA
2. Sistema de permisos activo
3. Escenarios de uso (búsqueda, mover, eliminar)
4. Rutas protegidas del sistema

### Test desde HIX
```
http://localhost/skills/filesystem/test_filesystem.prg
```

**IMPORTANTE**: Este test NO ejecuta operaciones reales de archivos,
solo verifica la configuración de seguridad de la skill.

## Changelog

### v1.0.0 (2026-02-15)
- Operaciones básicas CRUD
- Búsqueda de archivos
- Sistema de permisos
- Directorios protegidos

## Related Skills
- `gmail`: Para enviar archivos por email
- `whatsapp`: Para enviar archivos por WhatsApp
- `database`: Para indexar contenido de archivos

## Resources
- [Python pathlib](https://docs.python.org/3/library/pathlib.html)
- [Python shutil](https://docs.python.org/3/library/shutil.html)
