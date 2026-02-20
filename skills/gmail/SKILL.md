---
name: "gmail"
version: "1.0.0"
description: "Gestiona correos electrónicos mediante Gmail API"
category: "communication"
author: "HIX Team"
requires_permission: true
dangerous: false
---

# Gmail Skill

## Overview
Esta skill permite a HIX interactuar con Gmail para enviar, leer, buscar y gestionar correos electrónicos. Requiere autenticación OAuth2 y permisos explícitos del usuario.

## Capabilities
- Enviar correos electrónicos
- Leer correos (inbox, sent, drafts)
- Buscar correos por remitente, asunto, fecha
- Marcar como leído/no leído
- Archivar o eliminar correos
- Gestionar etiquetas
- Responder o reenviar correos

## Parameters

### Required
- `action` (string): La acción a realizar (`send`, `read`, `search`, `delete`, etc.)
- `credentials` (object): Credenciales OAuth2 de Gmail

### Optional
- `to` (string): Destinatario del correo (para `send`)
- `subject` (string): Asunto del correo (para `send`)
- `body` (string): Cuerpo del mensaje (para `send`)
- `query` (string): Consulta de búsqueda (para `search`)
- `limit` (number): Límite de resultados, default: `10`
- `unread_only` (boolean): Solo no leídos, default: `false`

## Usage Examples

### Example 1: Enviar Email Simple
**User Intent**: "Envía un email a juan@example.com diciéndole que la reunión es mañana a las 3pm"

**HIX Understanding**:
```json
{
  "skill": "gmail",
  "action": "send",
  "parameters": {
    "to": "juan@example.com",
    "subject": "Recordatorio: Reunión mañana",
    "body": "Hola Juan,\n\nTe recuerdo que tenemos reunión mañana a las 3pm.\n\nSaludos"
  }
}
```

**HIX Asks Permission**: 
> 📧 **Permiso requerido**
> 
> Voy a enviar un email a juan@example.com con el asunto "Recordatorio: Reunión mañana"
> 
> ¿Procedo? (sí/no)

**Expected Output**: ✓ Email enviado correctamente

### Example 2: Leer Correos No Leídos
**User Intent**: "¿Tengo correos nuevos?"

**HIX Understanding**:
```json
{
  "skill": "gmail",
  "action": "read",
  "parameters": {
    "unread_only": true,
    "limit": 5
  }
}
```

**Expected Output**: 
```
📬 Tienes 3 correos nuevos:

1. De: Maria Lopez <maria@example.com>
   Asunto: Propuesta de proyecto
   Fecha: Hoy, 10:30 AM

2. De: LinkedIn <noreply@linkedin.com>
   Asunto: Tienes 5 nuevas notificaciones
   Fecha: Hoy, 9:15 AM

3. De: Carlos Ruiz <carlos@example.com>
   Asunto: Re: Presupuesto Q1
   Fecha: Ayer, 6:45 PM
```

### Example 3: Buscar Emails
**User Intent**: "Busca todos los emails de Antonio de la última semana"

**HIX Understanding**:
```json
{
  "skill": "gmail",
  "action": "search",
  "parameters": {
    "query": "from:antonio after:2026/02/08",
    "limit": 10
  }
}
```

## Actions

### send
**Description**: Envía un correo electrónico

**Parameters**:
- `to` (required): Email del destinatario
- `subject` (required): Asunto del mensaje
- `body` (required): Contenido del mensaje
- `cc` (optional): Copia
- `bcc` (optional): Copia oculta
- `attachments` (optional): Array de archivos a adjuntar

**Returns**: Confirmation message con mensaje ID

**Requires Permission**: ✓ Siempre

### read
**Description**: Lee correos del inbox

**Parameters**:
- `unread_only` (optional): Solo no leídos
- `limit` (optional): Número máximo de emails
- `label` (optional): Filtrar por etiqueta

**Returns**: Lista de correos con remitente, asunto, fecha

**Requires Permission**: ✗ No destructivo

### search
**Description**: Busca correos usando sintaxis de Gmail

**Parameters**:
- `query` (required): Query de búsqueda (Gmail syntax)
- `limit` (optional): Máximo de resultados

**Returns**: Lista de correos que coinciden

**Requires Permission**: ✗ No destructivo

### delete
**Description**: Elimina correos (mueve a papelera)

**Parameters**:
- `message_id` (required): ID del mensaje a eliminar

**Returns**: Confirmation message

**Requires Permission**: ✓ Acción destructiva

### archive
**Description**: Archiva correos

**Parameters**:
- `message_id` (required): ID del mensaje

**Returns**: Confirmation message

**Requires Permission**: ✗ Reversible

## Safety & Permissions

### When to Ask Permission
- **send**: SIEMPRE - Muestra a quién se envía y el asunto
- **delete**: SIEMPRE - Acción destructiva
- **modify**: SIEMPRE - Al cambiar etiquetas importantes
- **read/search**: NO - Solo lectura, no destructivo

### Safety Checks
- Validar formato de email antes de enviar
- Confirmar múltiples destinatarios (>3)
- Advertir si hay archivos adjuntos grandes (>10MB)
- Prevenir envío a listas de distribución sin confirmación

## Error Handling

### Common Errors
1. **AUTH_FAILED**: Credenciales inválidas → Reautenticar
2. **QUOTA_EXCEEDED**: Límite de envío alcanzado → Esperar o notificar
3. **INVALID_EMAIL**: Formato de email inválido → Validar y corregir
4. **ATTACHMENT_TOO_LARGE**: Adjunto excede límite → Usar Google Drive
5. **NETWORK_ERROR**: Sin conexión → Reintentar con backoff

## Implementation Notes

### Dependencies
- `google-api-python-client` >= 2.0
- `google-auth` >= 2.0
- `google-auth-oauthlib` >= 1.0

### Configuration
```json
{
  "gmail": {
    "client_id": "YOUR_CLIENT_ID.apps.googleusercontent.com",
    "client_secret": "YOUR_CLIENT_SECRET",
    "scopes": [
      "https://www.googleapis.com/auth/gmail.send",
      "https://www.googleapis.com/auth/gmail.readonly",
      "https://www.googleapis.com/auth/gmail.modify"
    ],
    "token_path": ".credentials/gmail_token.json"
  }
}
```

### File Structure
```
skills/gmail/
├── SKILL.md           # Este archivo
├── gmail_api.py       # Implementación principal
├── auth.py            # Manejo de OAuth2
├── config.json        # Configuración
└── test_gmail.prg     # Test en Harbour (ejecutar vía HIX)
```

## Testing

### Manual Test
**Ejecutar**: `http://localhost/skills/gmail/test_gmail.prg`

El test verifica:
1. Que la skill está cargada correctamente
2. Metadata (nombre, versión, categoría)
3. Sistema de permisos configurado
4. Simulación de escenarios de uso

### Test desde HIX
```
# Test individual
http://localhost/skills/gmail/test_gmail.prg

# Test de todas las skills
http://localhost/skills/test_all_skills.prg
```

## Changelog

### v1.0.0 (2026-02-15)
- Envío de emails básico
- Lectura de inbox
- Búsqueda de correos
- Gestión de permisos

## Related Skills
- `calendar`: Para agendar reuniones mencionadas en emails
- `whatsapp`: Para notificar sobre emails importantes
- `filesystem`: Para guardar adjuntos

## Resources
- [Gmail API Docs](https://developers.google.com/gmail/api)
- [OAuth2 Setup](https://developers.google.com/gmail/api/auth/about-auth)
