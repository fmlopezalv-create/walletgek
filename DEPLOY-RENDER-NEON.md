# 🚀 Desplegar walletgek en Render + Neon

Guía paso a paso para tener la app funcionando **sin depender del PC**.

---

## Parte A — Crear la base de datos en Neon

1. Entra a https://neon.tech y haz clic en **Sign up** (puedes entrar con Google/GitHub).
2. Crea un proyecto:
   - Nombre: `walletgek`
   - Región: la que quieras (más cercana a ti, ej. `US East` o `EU`).
   - PostgreSQL: deja la versión por defecto.
3. Al terminar, Neon te muestra un **connection string** parecido a:
   ```
   postgresql://usuario:contraseña@ep-xxxxx-pooler.us-east-2.aws.neon.tech/walletgek?sslmode=require
   ```
4. **Cópialo** y guárdalo. Es el valor de `DATABASE_URL`.

> ⚠️ Usa el string que **NO** dice "pooler" para las migraciones si falla el pooler
> (Prisma 6 funciona bien con ambos; si da error de "prepared statements",
> cambia al directo quitando `-pooler` del host).

---

## Parte B — Subir el código a GitHub

Render despliega desde un repositorio Git. Necesitas subir la carpeta del proyecto.

1. Ve a https://github.com y crea un repositorio **privado** llamado `walletgek`.
2. En tu PC, abre una terminal en `C:\Users\ACER\OneDrive\Desktop\deepseek\gestor-finanzas-personal\walletgek`:
   ```powershell
   git init
   git add .
   git commit -m "walletgek v1"
   git branch -M main
   git remote add origin https://github.com/TU_USUARIO/walletgek.git
   git push -u origin main
   ```
   > El `.gitignore` ya excluye `node_modules`, `build`, `.env`, etc.

---

## Parte C — Desplegar el backend en Render

### Opción 1: Blueprint (automático, recomendado)

1. Entra a https://render.com y haz clic en **Sign up** (puedes entrar con GitHub).
2. Ve a **New → Blueprint**.
3. Conecta tu repositorio `walletgek`.
4. Render detecta el archivo `backend/render.yaml` y crea el servicio web.
5. Cuando te pida `DATABASE_URL`, pega el string de Neon (Parte A).
6. En `DEEPSEEK_API_KEY`, pega tu clave de DeepSeek (o déjala vacía por ahora).
7. Espera a que termine el deploy (2–5 min). Al final te da una URL:
   ```
   https://walletgek-api.onrender.com
   ```

### Opción 2: Web Service manual

1. En Render: **New → Web Service**.
2. Conecta el repositorio `walletgek`.
3. Configura:
   - **Root Directory**: `backend`
   - **Build Command**: `npm install && npx prisma generate`
   - **Start Command**: `npx prisma migrate deploy && node src/index.js`
   - **Environment Variables**: `DATABASE_URL` (Neon), `JWT_SECRET` (cualquier texto largo), `DEEPSEEK_API_KEY` (opcional).
4. Crea el servicio y espera el deploy.

---

## Parte D — Compilar e instalar el APK apuntando a Render

Cuando tengas la URL de Render (ej. `https://walletgek-api.onrender.com`):

```powershell
cd C:\Users\ACER\OneDrive\Desktop\deepseek\gestor-finanzas-personal\walletgek\app
flutter build apk --debug --dart-define=API_BASE_URL=https://walletgek-api.onrender.com
```

Después instala en el teléfono:

```powershell
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

La app ya no necesitará cable USB ni que el PC esté encendido.

---

## Notas importantes

- **Render free tier**: los servicios gratuitos "se duermen" tras ~15 min sin uso.
  La primera petición puede tardar 30–60 s en despertar. Es normal.
- **Neon free tier**: base de datos gratuita con límites generosos para pruebas.
- **Seguridad**: el `JWT_SECRET` debe ser un valor largo y único. Render lo genera si usas el Blueprint.
- El asesor IA solo responderá si pones una `DEEPSEEK_API_KEY` válida en Render.
