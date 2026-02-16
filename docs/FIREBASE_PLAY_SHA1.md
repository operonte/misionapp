# Inicio de sesión con Google falla (app instalada desde Play Store)

Si la app instalada **desde Google Play** muestra "Sign in failed" o "PlatformException" al pulsar "Entrar con Google", la causa habitual es que **falta el SHA-1 del certificado de Play** en Firebase.

Google Play firma la app con su propio certificado (Play App Signing). Firebase debe tener registrada esa huella para aceptar el inicio de sesión.

## Pasos para solucionarlo

### 1. Obtener el SHA-1 de Play App Signing

1. Entra en [Google Play Console](https://play.google.com/console).
2. Selecciona la app **MisionApp**.
3. Ve a **Release** → **Setup** → **App integrity** (o **Configuración** → **Integridad de la app**).
4. En **App signing key certificate** verás **SHA-1 certificate fingerprint**. Cópialo (formato tipo `AB:CD:EF:...`).

### 2. Añadir el SHA-1 a Firebase

**Opción A – Consola de Firebase**

1. [Firebase Console](https://console.firebase.google.com) → proyecto **misionapp-f4d93**.
2. ⚙️ **Configuración del proyecto** → pestaña **General**.
3. En **Tus apps**, selecciona la app Android (**com.operonte.misionapp**).
4. Pulsa **Añadir huella digital** y pega el SHA-1 de Play. Guardar.

**Opción B – Línea de comandos**

Con el SHA-1 copiado (ej. `AB:CD:EF:12:34:...`):

```bash
cd /ruta/a/misionapp
firebase apps:android:sha:create 1:700679867705:android:65a3e13becb839abe9ace8 "TU_SHA1_DE_PLAY_AQUI" --project misionapp-f4d93
```

Sustituye `TU_SHA1_DE_PLAY_AQUI` por el valor que copiaste de Play Console.

### 3. Comprobar

No hace falta volver a compilar. Los usuarios que tengan la app desde Play Store pueden intentar de nuevo "Entrar con Google"; en unos minutos debería funcionar.

---

**Resumen:** En Firebase deben estar registrados tanto el SHA-1 de tu **keystore de subida** (release local) como el SHA-1 del **certificado de firma de Play** (app descargada desde la tienda).
