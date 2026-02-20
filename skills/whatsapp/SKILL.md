---
name: "whatsapp"
version: "1.0.0"
description: "Envía y recibe mensajes de WhatsApp mediante WhatsApp Business API"
category: "communication"
author: "HIX Team"
requires_permission: true
dangerous: false
---

# WhatsApp Skill

## Overview
Esta skill permite a HIX interactuar con WhatsApp para enviar mensajes, gestionar grupos y recibir notificaciones. Utiliza WhatsApp Business API o integración con WhatsApp Web.

## Capabilities
- Enviar mensajes a contactos individuales
- Enviar mensajes a grupos
- Leer mensajes recibidos
- Enviar archivos, imágenes, audios
- Gestionar estado (online/offline)
- Crear y gestionar grupos

## Parameters

### Required
- `action` (string): La acción a realizar (`send`, `send_group`, `read`, etc.)
- `phone` o `group` (string): Destinatario del mensaje

### Optional
- `message` (string): Contenido del mensaje de texto
- `audio` (string): Path al archivo de audio
- `image` (string): Path a la imagen
- `file` (string): Path al archivo a enviar

## Usage Examples

### Example 1: Enviar Mensaje Individual
**User Intent**: "Envía un WhatsApp a María diciéndole que voy tarde"

**HIX Understanding**:
```json
{
  "skill": "whatsapp",
  "action": "send",
  "parameters": {
    "contact": "María",
    "message": "Hola María, voy un poco tarde. Llego en 15 minutos."
  }
}
```

**HIX Asks Permission**: 
> 💬 **Permiso requerido**
> 
> Voy a enviar WhatsApp a María García (+34 612 345 678):
> "Hola María, voy un poco tarde. Llego en 15 minutos."
> 
> ¿Procedo? (sí/no)

**Expected Output**: ✓ Mensaje enviado a María

### Example 2: Mensaje a Grupo
**User Intent**: "Avisa al grupo del equipo que he subido los archivos"

**HIX Understanding**:
```json
{
  "skill": "whatsapp",
  "action": "send_group",
  "parameters": {
    "group": "Equipo Alpha",
    "message": "📁 He subido los archivos del proyecto a la carpeta compartida"
  }
}
```

**Expected Output**: ✓ Mensaje enviado al grupo "Equipo Alpha"

### Example 3: Enviar Audio (Respuesta de Voz)
**User Intent**: (Audio) *"Responde a Antonio que sí, que mañana nos vemos"*

**HIX Understanding**:
```json
{
  "skill": "whatsapp",
  "action": "send",
  "parameters": {
    "contact": "Antonio",
    "message": "Sí, perfecto. Mañana nos vemos."
  }
}
```

## Actions

### send
**Description**: Envía un mensaje a un contacto

**Parameters**:
- `contact` (required): Nombre o número del contacto
- `message` (optional): Texto del mensaje
- `audio` (optional): Audio a enviar
- `image` (optional): Imagen a enviar

**Returns**: Confirmation con timestamp

**Requires Permission**: ✓ Siempre

### send_group
**Description**: Envía mensaje a un grupo

**Parameters**:
- `group` (required): Nombre del grupo
- `message` (required): Texto del mensaje

**Returns**: Confirmation con nombre del grupo

**Requires Permission**: ✓ Siempre

### read
**Description**: Lee mensajes recibidos

**Parameters**:
- `unread_only` (optional): Solo no leídos
- `contact` (optional): De contacto específico
- `limit` (optional): Número máximo

**Returns**: Lista de mensajes

**Requires Permission**: ✗ Solo lectura

### send_file
**Description**: Envía un archivo

**Parameters**:
- `contact` (required): Destinatario
- `file_path` (required): Ruta al archivo

**Returns**: Confirmation

**Requires Permission**: ✓ Siempre

## Safety & Permissions

### When to Ask Permission
- **send/send_group**: SIEMPRE - Muestra destinatario y mensaje
- **send_file**: SIEMPRE - Muestra archivo y destinatario
- **read**: NO - Solo lectura

### Safety Checks
- Validar que el contacto existe en la agenda
- Confirmar envío a grupos grandes (>10 personas)
- Limitar tamaño de archivos (max 16MB para WhatsApp)
- No enviar a números desconocidos sin confirmación

## Error Handling

### Common Errors
1. **CONTACT_NOT_FOUND**: Contacto no existe → Pedir número completo
2. **NOT_CONNECTED**: WhatsApp desconectado → Reconectar
3. **MESSAGE_FAILED**: Fallo al enviar → Reintentar
4. **FILE_TOO_LARGE**: Archivo excede 16MB → Comprimir o usar otro medio
5. **RATE_LIMIT**: Demasiados mensajes → Esperar

## Implementation Notes

### Dependencies
- `whatsapp-web.js` (Node.js) o `yowsup` (Python)
- `qrcode` para autenticación inicial
- `puppeteer` para WhatsApp Web automation

### Configuration
```json
{
  "whatsapp": {
    "mode": "web",
    "session_path": ".sessions/whatsapp",
    "qr_code_timeout": 60,
    "contacts_path": ".data/whatsapp_contacts.json"
  }
}
```

### File Structure
```
skills/whatsapp/
├── SKILL.md
├── whatsapp_api.py
├── contacts.py
├── config.json
└── test_whatsapp.prg    # Test en Harbour
```

## Testing

### Manual Test
**Ejecutar**: `http://localhost/skills/whatsapp/test_whatsapp.prg`

El test verifica:
1. Skill cargada correctamente
2. Metadata y configuración
3. Sistema de permisos
4. Escenarios de uso (individual, grupos)

### Test desde HIX
```
http://localhost/skills/whatsapp/test_whatsapp.prg
```

## Changelog

### v1.0.0 (2026-02-15)
- Envío de mensajes individuales
- Envío a grupos
- Lectura de mensajes
- Soporte para archivos multimedia

## Related Skills
- `gmail`: Como alternativa para comunicación formal
- `filesystem`: Para acceder a archivos a enviar
- `calendar`: Para agendar desde mensajes

## Resources
- [WhatsApp Business API](https://developers.facebook.com/docs/whatsapp)
- [whatsapp-web.js](https://github.com/pedroslopez/whatsapp-web.js)
