# 📊 WALLETGEK — Gestor de deudas y finanzas personales (Análisis y Requisitos)

> **Fase 1 — Planificación y análisis de requisitos** · Sprint 0
> Metodología: Agile (Scrum) · Stack base definido en `REGLAS-DESARROLLO-APLICACIONES.md`
> **Decisiones aprobadas:** app móvil nativa (Flutter) · asesor IA con DeepSeek API · idioma español + inglés

---

## 1. Visión del producto

Una aplicación que ayuda al usuario a **controlar sus ingresos y gastos, ordenar sus deudas y mantener una salud financiera correcta**, con un **asesor financiero personal de IA** entrenado que interpreta *los datos reales del usuario* y le da orientación accionable.

**Frase de visión:** *"Saber a dónde va tu dinero, pagar tus deudas con un plan claro, y tener un asesor financiero 24/7."*

---

## 2. Problema y público objetivo

### Problema que resuelve
- La gente **no sabe a dónde se va su dinero** (gastos sin registrar).
- Las **deudas se acumulan sin un plan** claro de pago.
- Las decisiones financieras se toman **sin datos ni criterio**.
- Un asesor humano es **caro e inaccesible** para la mayoría.

### Público objetivo
- Personas con **ingresos regulares** que quieren ordenar sus finanzas.
- Personas con **deudas** (tarjetas, préstamos) que buscan salir de ellas.
- Usuarios con **experiencia financiera básica** (igual que tú): la app debe educar, no abrumar.

---

## 3. Propuesta de valor

1. **Claridad total**: registro simple de ingresos/gastos con categorías.
2. **Plan de deudas concreto**: priorización automática por bola de nieve o avalancha.
3. **Salud financiera medible**: indicadores claros (tasa de ahorro, deuda/ingreso, fondo de emergencia).
4. **Asesor IA personalizado**: no respuestas genéricas, sino análisis de *tus* números.
5. **Educación financiera integrada**: cada recomendación explica el "por qué".

---

## 4. Funcionalidades

### 4.1 MVP — Núcleo (Sprints 1–3)

| # | Funcionalidad | Descripción |
|---|---|---|
| 1 | **Registro de ingresos y gastos** | Alta rápida de transacciones con fecha, monto y categoría. |
| 2 | **Presupuesto por categoría** | Límite mensual por categoría con aviso de avance (gastado vs límite). |
| 3 | **Gestión de deudas** | Alta de deudas: saldo, tasa de interés, pago mínimo, vencimiento. |
| 4 | **Plan de pago de deudas** | Estrategia **bola de nieve** (menor saldo primero) o **avalancha** (mayor interés primero) con calendario estimado de liquidación. |
| 5 | **Dashboard de salud financiera** | Indicadores: tasa de ahorro, relación deuda/ingreso, gastos vs presupuesto, fondo de emergencia. |
| 6 | **Asesor financiero IA** | Chat que analiza los datos del usuario y responde con recomendaciones personalizadas. |
| 7 | **Reportes básicos** | Gastos por categoría y evolución mensual (gráficos simples). |

### 4.2 Post-MVP — Siguiente fase

- Metas de ahorro con progreso.
- Recordatorios de pagos y vencimientos.
- Exportar reportes (PDF/CSV).
- Sincronización bancaria automática (open banking) — requiere regulación y conectores.
- Modo familiar/multiusuario.

---

## 5. Metodología financiera (reglas de negocio)

La app implementa métodos **probados** y fáciles de explicar:

| Concepto | Regla que implementa |
|---|---|
| **Presupuesto de base cero** | Asignar cada ingreso a una categoría (nada queda "sin destino"). |
| **Regla 50/30/20** (referencia) | 50% necesidades, 30% deseos, 20% ahorro/deuda. Se usa como guía, no como imposición. |
| **Tasa de ahorro** | `(Ingresos − Gastos) / Ingresos` — objetivo ≥ 20%. |
| **Relación deuda/ingreso (DTI)** | `Pagos de deuda mensuales / Ingresos mensuales` — sano ≤ 36%. |
| **Fondo de emergencia** | Objetivo: 3–6 meses de gastos esenciales. |
| **Bola de nieve** | Pagar primero la deuda de **menor saldo** (motivación psicológica, ver progreso). |
| **Avalancha** | Pagar primero la deuda de **mayor interés** (óptimo matemático, menos intereses). |

> La app dejará elegir el método y explicará la diferencia, recomendando según el perfil del usuario.

---

## 6. El Asesor Financiero IA (componente central)

### 6.1 Qué hace
- **Analiza** los hábitos del usuario: fugas de gasto, categorías desbordadas, patrones.
- **Prioriza** deudas y propone un plan de pago concreto.
- **Sugiere** presupuestos realistas basados en el historial.
- **Explica** conceptos (interés compuesto, DTI, fondo de emergencia) en lenguaje simple.
- **Acompaña**: metas, motivación y seguimiento de progreso.

### 6.2 Cómo funciona (arquitectura)
1. **Base de conocimiento**: los datos reales del usuario (transacciones, deudas, presupuesto, metas) se recuperan de la base de datos.
2. **Contexto**: se construye un resumen estructurado (últimos 3 meses, deudas activas, presupuesto) que se inyecta al modelo.
3. **Modelo (LLM)**: un modelo de lenguaje con **persona de asesor financiero educativo**, mediante un *system prompt* riguroso.
4. **Guardrails**: reglas que bloquean respuestas prohibidas (ver 6.3).
5. **Respuesta**: citando los datos del usuario (ej. "en marzo gastaste 40% más en ocio que tu presupuesto").

### 6.3 Límites y disclaimers (OBLIGATORIO y no negociable)

El asesor **NO es un asesor financiero regulado**. Debe cumplir siempre:

- ❌ **No da consejo de inversión regulado** (no recomienda acciones, fondos ni cripto específicos).
- ❌ **No promete rendimientos** ni garantiza resultados.
- ❌ **No sustituye** a un asesor certificado para decisiones legales/fiscales complejas.
- ✅ **Es educativo**: enseña, explica y orienta con los datos del usuario.
- ✅ **Disclaimer visible** en cada respuesta: *"Esto es orientación educativa, no consejo financiero regulado."*
- ✅ **Deriva a un profesional** ante temas de inversión, impuestos o legalidad.

> Fuente sobre por qué esto importa: [M1 — Why AI says "this is not financial advice"](https://m1.com/knowledge-bank/why-does-ai-say-this-is-not-financial-advice/) y [Yahoo Finance — ¿confiar en el consejo de inversión de una IA?](https://ca.finance.yahoo.com/news/personal-finance-ai-trust-chatgpt-060132588.html).

### 6.4 Riesgos del asesor IA y mitigación

| Riesgo | Mitigación |
|---|---|
| Respuestas incorrectas o "alucinadas" | El modelo **solo puede afirmar sobre datos del usuario** que se le inyectan; si no hay dato, responde "no tengo ese dato". |
| Dar consejo de inversión | Guardrails + prompt que bloquean el tema. |
| Dependencia excesiva del usuario | Mensajes que refuerzan: "verifica y decide tú". |
| Privacidad | Los datos del usuario **nunca salen de la app** salvo al proveedor de IA, con cifrado y sin entrenar el modelo con ellos (ver §9). |

---

## 7. Requisitos no funcionales (mapeo a nuestras reglas)

| Código | Requisito | Cómo se cumple aquí |
|---|---|---|
| F1 | UI/UX | Interfaz simple, dashboard claro, onboarding guiado. |
| F2 | Lógica de negocio | Reglas financieras (§5) aisladas y comprobables. |
| F3 | Datos | PostgreSQL; modelo en §8. |
| F4/C8 | Seguridad | §9 — crítico por ser datos financieros. |
| F5 | APIs | API del LLM para el asesor + (futuro) open banking. |
| F6 | Errores | Validaciones claras, estados de error, sin datos sensibles en logs. |
| F7 | Documentación | Este documento + manual de usuario al entregar. |
| C1 | Usabilidad | Onboarding + lenguaje simple. |
| C2 | Rendimiento | Dashboard y reportes < 1 s; asesor responde en streaming. |
| C3 | Fiabilidad | Respaldos diarios + observabilidad. |
| C4 | Escalabilidad | Monolito modular; escala vertical inicialmente. |
| C5 | Mantenibilidad | Capas separadas (ver §10). |
| C6 | Portabilidad | Móvil nativa (Android/iOS) — una sola base de código Flutter. |
| C7 | Accesibilidad | Contraste, teclado, lectores (WCAG 2.1 AA). |

---

## 8. Modelo de datos (borrador)

| Tabla | Campos clave | Notas |
|---|---|---|
| `User` | id, email, password_hash, nombre, moneda, país, presupuesto_mensual, is_premium | Hash con bcrypt. **Implementado**. |
| `Category` | id, usuario_id, nombre, tipo (ingreso/gasto), color, presupuesto_mensual | **Implementado** (14 por defecto). |
| `Transaction` | id, usuario_id, categoria_id, tipo, monto, fecha, nota | **Implementado**. Índice por fecha. Sin `cuenta_id`. |
| `Debt` | id, usuario_id, nombre, tipo, color, saldo, tasa_interes, pago_minimo, vencimiento, estado, cuotas, detalles | **Implementado** (JSON para campos por tipo). |
| `DebtPayment` | id, deuda_id, monto, fecha | **Implementado** (historial de pagos). |
| `cuentas` | (pendiente) | Post-MVP: efectivo/banco/tarjeta. No implementado. |
| `metas` | (pendiente) | Post-MVP: metas de ahorro. No implementado. |
| `conversaciones` | (pendiente) | Post-MVP: historial persistente del asesor. No implementado. |

**Reglas de integridad:** claves foráneas, montos validados (>0), categorías por usuario, transacciones siempre con categoría (o "sin categoría" explícito).

---

## 9. Seguridad y privacidad (datos financieros — crítico)

1. **Cifrado en tránsito**: HTTPS/TLS obligatorio.
2. **Cifrado en reposo**: base de datos cifrada; nunca guardar credenciales bancarias.
3. **Autenticación fuerte**: Argon2/bcrypt + MFA opcional + bloqueo de intentos.
4. **Autorización**: cada usuario solo ve SUS datos (verificación en servidor).
5. **Consultas parametrizadas**: contra inyección SQL.
6. **Secretos fuera del código**: variables de entorno para claves del LLM y BD.
7. **Mínimo privilegio**: el usuario de BD no tiene permisos de administración.
8. **Logs sin datos sensibles**: nunca registrar montos ni datos personales en logs.
9. **Cumplimiento de datos personales**: minimización, derecho a borrado (GDPR/LOPD).
10. **Proveedor de IA**: enviar solo lo necesario, sin datos identificables (o anonimizados), y **no permitir** que el proveedor use los datos para entrenar.

> Fuente sobre seguridad en apps financieras: [Guardsquare — Protecting financial services embedded in mobile apps](https://www.guardsquare.com/blog/protecting-financial-services-embedded-in-mobile-apps).

---

## 10. Stack tecnológico propuesto

| Capa | Tecnología | Justificación |
|---|---|---|
| **App móvil** | Flutter (Dart) | Un solo código para Android/iOS, UI nativa y rendimiento. |
| **Backend API** | Node.js + Express | Sirve a la app y actúa de **proxy del asesor IA** (la clave nunca va en el móvil). **Decidido e implementado**. |
| **Base de datos** | PostgreSQL 16 | Regla por defecto (F3); ya instalada. |
| **ORM** | Prisma (Node) o SQLAlchemy (Python) | Migraciones + consultas seguras. |
| **Asesor IA** | DeepSeek API (vía backend) + system prompt + RAG sobre datos del usuario | Persona educativa + guardrails. |
| **Charts** | fl_chart (Flutter) | Gráficos del dashboard. |
| **Autenticación** | JWT + hash Argon2/bcrypt | Sesiones seguras. |
| **Idiomas (i18n)** | flutter_localizations + intl | Español (actual) + inglés (**pendiente**). |
| **CI/CD** | GitHub Actions + Codemagic | Pruebas y compilación Android/iOS. |
| **Observabilidad** | Sentry + logs estructurados | C3 (fiabilidad). |

> Decisión de backend (Node vs Python) se cierra en el Sprint 1; ambos ya están instalados.
> ⚠️ **Arquitectura clave:** la API key de DeepSeek vive **solo en el backend**. La app móvil nunca llama directo al LLM (evita exponer la clave y permite controlar costes/guardrails en el servidor).

---

## 11. Backlog inicial y plan de sprints

| Sprint | Objetivo | Entregable |
|---|---|---|
| **0** | Definir alcance y aprobar este análisis | ✅ Este documento (pendiente de tu visto bueno) |
| **1** | Autenticación + registro de transacciones + categorías | Usuario puede registrar gastos/ingresos. |
| **2** | Presupuesto + deudas + plan de pago (snowball/avalanche) | Plan de deudas y presupuesto funcionales. |
| **3** | Dashboard de salud financiera + reportes | Indicadores y gráficos. |
| **4** | **Asesor financiero IA** (MVP) | Chat que analiza datos reales con guardrails. |
| **5** | Pulido: accesibilidad, seguridad, pruebas, despliegue | App lista para entregar (Parte 3 ✅). |

---

## 11.1 Definition of Done (DoD)

Una historia de usuario está **Done** sólo si se cumplen **todas** estas condiciones:

1. **Código en `main`** del repositorio (commit + push).
2. **Migración de BD aplicada** (si cambia el modelo) y `prisma generate` sin errores.
3. **`flutter analyze` sin issues** (cero warnings/errors).
4. **Funciona en dispositivo real** (o emulador) conectado al backend de producción.
5. **Verificada end-to-end** contra la API real (crear → leer → editar → eliminar según aplique).
6. **Sin regresiones** en las historias ya entregadas (smoke test del flujo principal).
7. **Documentada** (sólo si introduce un cambio de comportamiento visible).

**Escala de estimación:** Fibonacci modificada — 1, 2, 3, 5, 8, 13.

---

## 11.2 Backlog priorizado (MoSCoW) y estimaciones

### Leyenda de prioridad
- **Must** — imprescindible para el MVP (sin esto no se entrega).
- **Should** — importante, pero el MVP puede vivir sin ello temporalmente.
- **Could** — deseable; entra si hay tiempo (post-MVP).
- **Won't (por ahora)** — descartado explícitamente para esta fase.

### Sprint 1 — Autenticación, transacciones y categorías

| ID | Historia (como usuario…) | Criterios de aceptación | Est. | Prioridad | Estado |
|---|---|---|---|---|---|
| HU-1.1 | Quiero registrarme e iniciar sesión para tener mi cuenta privada | Registro valida email/contraseña; login devuelve JWT; sesión persiste; logout borra el token | 5 | Must | ✅ Hecho |
| HU-1.2 | Quiero registrar ingresos y gastos para saber a dónde va mi dinero | Crear con monto>0, tipo, categoría y fecha; listar ordenado por fecha; **editar** y **eliminar** | 5 | Must | ✅ Hecho |
| HU-1.3 | Quiero categorías por defecto para no partir de cero | Al registrarme se crean 14 categorías (10 gasto, 4 ingreso); puedo crear categorías propias | 3 | Must | ✅ Hecho |
| HU-1.4 | Quiero elegir mi moneda y país para ver montos en mi contexto | Perfil con moneda y país; moneda define el símbolo mostrado | 3 | Must | ✅ Hecho |

**Total Sprint 1: 16 pts.**

### Sprint 2 — Presupuesto, deudas y plan de pago

| ID | Historia (como usuario…) | Criterios de aceptación | Est. | Prioridad | Estado |
|---|---|---|---|---|---|
| HU-2.1 | Quiero presupuestos por categoría y global para controlar gastos | Límite mensual por categoría; presupuesto global; barra gastado vs límite | 5 | Must | ✅ Hecho |
| HU-2.2 | Quiero registrar mis deudas para no perderlas de vista | Alta con saldo, interés, pago mínimo y vencimiento; tipos por país (hipoteca, tarjeta, nómina…) | 8 | Must | ✅ Hecho |
| HU-2.3 | Quiero un plan de pago para salir de deudas | Estrategia bola de nieve y avalancha con orden y meses estimados de liquidación | 8 | Must | ✅ Hecho |
| HU-2.4 | Quiero registrar pagos parciales a una deuda | Registrar pago que reduce saldo y queda en historial | 5 | Should | ✅ Hecho |

**Total Sprint 2: 26 pts.**

### Sprint 3 — Dashboard de salud financiera y reportes

| ID | Historia (como usuario…) | Criterios de aceptación | Est. | Prioridad | Estado |
|---|---|---|---|---|---|
| HU-3.1 | Quiero ver mi salud financiera para saber si voy bien | Indicador 0–100% con color (verde/ámbar/coral); tasa de ahorro y DTI | 8 | Must | ✅ Hecho |
| HU-3.2 | Quiero un dashboard con mis datos clave de un vistazo | Balance, variación vs mes anterior, vencimientos, deudas, gastos y movimientos recientes | 8 | Must | ✅ Hecho |
| HU-3.3 | Quiero configurar el orden y visibilidad de secciones | Reordenar y ocultar/mostrar secciones; persistente | 3 | Should | ✅ Hecho |
| HU-3.4 | Quiero reportes de presupuesto y deudas | Resumen de presupuesto con categorías y plan de deudas | 5 | Should | ✅ Hecho |
| HU-3.5 | Quiero un fondo de emergencia con objetivo | Meta de 3–6 meses de gastos esenciales y progreso | 5 | Could | ✅ Hecho |

**Total Sprint 3: 24 pts (24 hechos).**

### Sprint 4 — Asesor financiero IA

| ID | Historia (como usuario…) | Criterios de aceptación | Est. | Prioridad | Estado |
|---|---|---|---|---|---|
| HU-4.1 | Quiero un asesor IA que analice mis datos reales | Chat que responde usando ingresos, gastos, deudas y presupuesto del usuario | 8 | Must | ✅ Hecho |
| HU-4.2 | Quiero que el asesor sea seguro y honesto | Guardrails (sin consejo de inversión, sin prometer rendimientos) y disclaimer visible | 3 | Must | ✅ Hecho |
| HU-4.3 | Quiero una suscripción Premium para desbloquear el asesor | Estado premium por usuario; activación (placeholder de pago); asesor requiere premium | 5 | Must | ✅ Hecho |
| HU-4.4 | Quiero historial de conversación persistente | Mensajes y respuestas guardados por usuario | 5 | Could | ✅ Hecho |

**Total Sprint 4: 16 pts (16 hechos).**

### Sprint 5 — Pulido, seguridad, pruebas y despliegue

| ID | Historia (como usuario…) | Criterios de aceptación | Est. | Prioridad | Estado |
|---|---|---|---|---|---|
| HU-5.1 | Quiero una identidad visual premium | Modo oscuro base, colores con significado, tipografía tabular, animaciones | 8 | Must | ✅ Hecho |
| HU-5.2 | Quiero ocultar montos por privacidad | Botón que oculta los valores de la tarjeta principal | 3 | Should | ✅ Hecho |
| HU-5.3 | Quiero copia de seguridad y restauración | Exportar JSON, restaurar desde JSON y borrar todo con confirmación | 8 | Must | ✅ Hecho |
| HU-5.4 | Quiero una foto de perfil | Elegir foto desde galería, persistente | 3 | Should | ✅ Hecho |
| HU-5.5 | Quiero la app desplegada y sin depender del PC | Backend en Render, BD en Neon, APK apuntando a la URL pública | 8 | Must | ✅ Hecho |
| HU-5.6 | Quiero la app en español e inglés (i18n) | Todos los textos traducibles y cambio de idioma | 8 | Could | ⬜ Pendiente |
| HU-5.7 | Quiero pruebas automatizadas | Tests de unidad e integración del backend y la app | 8 | Could | ⬜ Pendiente |
| HU-5.8 | Quiero CI/CD | Build y pruebas automáticas en cada push | 5 | Could | ⬜ Pendiente |

**Total Sprint 5: 30 pts (30 hechos… ver nota) + 21 pts pendientes (Could).**

> **Nota Sprint 5:** los puntos "hechos" son 30 (HU-5.1 a 5.5) y los "Could" pendientes suman 21 (HU-5.6, 5.7, 5.8).

### Resumen de velocidad y alcance

| Sprint | Pts. totales | Pts. hechos | Pendiente (Could) |
|---|---|---|---|
| 1 | 16 | 16 | 0 |
| 2 | 26 | 26 | 0 |
| 3 | 24 | 19 | 5 (fondo de emergencia) |
| 4 | 16 | 11 | 5 (historial IA) |
| 5 | 51 | 30 | 21 (i18n, tests, CI/CD) |
| **Total** | **133** | **102** | **31** |

**Post-MVP (Won't por ahora):**
- Metas de ahorro con progreso.
- Recordatorios de pagos/vencimientos (notificaciones).
- Exportar reportes (PDF/CSV).
- Sincronización bancaria automática (open banking).
- Modo familiar/multiusuario.
- Cuentas (efectivo/banco/tarjeta).
- Pago real de suscripción (Stripe).
- **Autenticación por código al correo (magic link) + "Continuar con Google/Outlook"** *(ver §13.1)*.
- **Modo offline** *(ver §13.2)*: cache local de datos + registro de transacciones sin conexión con sincronización al reconectar.
- **Módulo "Cobros"** (cuentas por cobrar / préstamos que hice) *(ver §13.3, en implementación)*.

---

## 12. Riesgos del proyecto

| Riesgo | Impacto | Mitigación |
|---|---|---|
| El asesor IA da respuestas incorrectas | Alto (confianza) | Guardrails + solo afirmar sobre datos inyectados + disclaimers. |
| Complejidad excesiva para el MVP | Medio | Empezar con núcleo (sin sincronización bancaria). |
| Seguridad de datos financieros | Alto | §9 desde el inicio, no al final. |
| Coste del LLM | Medio | Control de tokens, límite de uso, opción de modelo local. |

---

## 13. Decisiones aprobadas (Fase 1 cerrada)

| Decisión | Valor |
|---|---|
| Nombre de la app | **walletgek** |
| Plataforma | **Móvil nativa — Flutter** |
| Proveedor del asesor IA | **DeepSeek API** (vía backend) |
| Idioma | **Español** (i18n español + inglés **pendiente**) |

**Próximo paso:** configurar el entorno Flutter (SDK + Android) y arrancar el **Sprint 1** (autenticación + registro de transacciones + categorías).

---

## 13.1 Decisión de autenticación para la siguiente fase (anotada, pendiente de implementar)

**Enfoque elegido:** acceso sin contraseña mediante **código de verificación al correo (magic link)**, y opcionalmente **"Continuar con Google"** (OAuth). Las cuentas se vinculan al usuario por su **email verificado**, y todos sus registros (movimientos, deudas, presupuesto, premium) siguen guardados en la base de datos (Neon) y se recuperan al volver a entrar.

**Proveedor de envío elegido:** **Zoho ZeptoMail** (email transaccional), usando el dominio propio **treegek.com**.

**Detalles acordados:**
- Remitente sugerido: `walletgek@treegek.com` (o `no-reply@treegek.com`).
- Dominio verificado en ZeptoMail con registros SPF/DKIM.
- Código de un solo uso con expiración y rate limiting en el envío (ya existe la base del rate limiter).
- Los datos financieros **nunca se envían a Google/Zoho**: solo se usa el email para autenticar.

**Orden de implementación sugerido:**
1. **Magic link / código al correo** con Zoho ZeptoMail (Fase 1).
2. **"Continuar con Google"** (OAuth, Fase 2).
3. **Outlook/Microsoft** (OAuth, Fase 3 — opcional).

**Pendientes de verificar antes de implementar:**
- Límites y tier gratuito exactos de Zoho ZeptoMail (pueden haber cambiado).
- Vincular identidades (Google + email+contraseña) a una misma cuenta sin duplicarlas.

---

## 13.2 Decisión de modo offline (implementado)

**Objetivo:** que el usuario pueda usar la app sin conexión a internet.

**Alcance implementado:**
1. **Cache local** de los datos del usuario (movimientos, deudas, categorías, presupuesto/dashboard) en el dispositivo.
2. **Registrar movimientos sin conexión**: se guardan en una cola de pendientes y aparecen en la lista.
3. **Sincronización al recuperar internet**: se envían los pendientes al backend y se refresca la cache.
4. **Indicador visual** de estado sin conexión (banner ámbar).

**Limitaciones conocidas:**
- El asesor IA y el inicio de sesión por primera vez siempre requieren internet.
- La sincronización cubre **movimientos** (ingresos/gastos).

**Mejoras futuras anotadas (pendientes):**
- **Creación y edición de deudas sin conexión** (mayor complejidad: campos dinámicos por tipo, cálculos de cuota/interés, pagos asociados y plan de pago, manejo de conflictos al sincronizar). Se implementará en una fase posterior.
- Edición/eliminación de movimientos sin conexión.
- Sincronización bidireccional con resolución de conflictos.

**Enfoque técnico:** almacenamiento local en el dispositivo (shared_preferences con JSON) + cola de sincronización simple, manteniendo la nube (Neon) como fuente de verdad.

---

## 13.3 Módulo "Cobros" (cuentas por cobrar / préstamos que hice)

**Objetivo:** gestionar el dinero que el usuario **presta o tiene que cobrar** (lo opuesto a las deudas).

**Nombre elegido:** **"Cobros"** (corto y claro).

**Alcance:**
1. Registrar un préstamo hecho: persona, monto, nota, fecha de vencimiento (opcional).
2. Registrar **cobros parciales** que reducen el saldo pendiente.
3. Ver total pendiente de cobrar y estado (pendiente/cobrado).
4. Editar y eliminar un cobro.

**Modelo de datos:** tabla `Receivable` (persona, monto, nota, vencimiento, estado, usuario).

**Ubicación en la UI:** pantalla propia "Cobros" accesible desde Deudas y desde el dashboard.

---

## 13.4 Día de pago por deuda y notificaciones (en implementación)

**Problema detectado:** los tipos de deuda (préstamo bancario, tarjeta, hipoteca, etc.) no exponían un campo de **fecha/día de pago**, así que no era posible distinguir "el banco A cobra el 26 y el banco B el 28", ni avisar de pagos próximos/vencidos.

**Solución implementada:**
1. Campo **"Día de pago mensual"** (1–31) en todos los tipos de deuda con cuota mensual.
2. Cálculo del **próximo vencimiento** a partir de ese día.
3. **Notificación local** cuando el pago está próximo (días antes) o vencido.

**Enfoque:** notificaciones locales con `flutter_local_notifications` (sin backend de push). El día de pago se guarda como `dueDate` (primer vencimiento) y se repite mensualmente.
