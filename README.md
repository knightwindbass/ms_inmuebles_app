# 🏢 MS Inmuebles SaaS - App Móvil (Flutter)

Aplicación móvil minimalista multiplataforma (**Android** e **iOS**) desarrollada en **Flutter** para visualización ejecutiva de reportes, monitoreo de métricas (MRR, tasa de ocupación), catálogo de inmuebles, control de contratos y directorio de inquilinos.

---

## 🚀 Características Principales

1. **Dashboard de Inteligencia de Negocios (`/dashboard/resumen`)**:
   - **MRR (Ingreso Recurrente Mensual)** normalizado y proyectado.
   - **Tasa de Ocupación Real (%)** con visualizador circular.
   - **Estado del Inventario**: Desglose de unidades disponibles, rentadas, en mantenimiento e inactivas.
   - **Jerarquía**: Complejos matrices vs sub-unidades activas/inactivas.
   - **Gráfico Dúo Comparativo**: Relación de inmuebles libres vs ocupados por tipología (*Edificio, Bodega, Local, Oficina, Terreno*).
   - **Filtro por Complejo Matriz**: Selección de métricas globales o específicas por complejo (`padre_id`).

2. **Explorador de Inmuebles (`/inmuebles`)**:
   - Buscador en tiempo real con *debounce*.
   - Filtros instantáneos tipo *chip* por estado y tipología.
   - Ordenación por valor de renta (`renta_asc`, `renta_desc`).
   - Ficha técnica completa con soporte de sub-unidades e historial de contratos.

3. **Control de Contratos y Arrendamientos (`/contratos`)**:
   - Detección de contratos próximos a vencer con alertas semánticas de días restantes.
   - Ordenación por vencimiento (`vencimiento_asc`, `vencimiento_desc`), monto (`monto_desc`, `monto_asc`) o inquilino.
   - Detalle financiero completo y cruce de datos con inquilino e inmueble.

4. **Directorio de Inquilinos (`/inquilinos`)**:
   - Directorio de clientes con indicador de contratos vigentes (activo/inactivo).
   - Búsqueda por nombre, identificación o contacto.

5. **Seguridad Multi-Tenant**:
   - Inyección automática en cada petición de los headers obligatorios:
     - `x-api-key: <TU_API_KEY>`
     - `x-tenant-id: <TU_TENANT_ID>`
     - `Content-Type: application/json`
   - Pantalla de configuración inicial con prueba de conexión y opción de cambiar de tenant en cualquier momento.

---

## 📁 Estructura del Código

```text
lib/
├── core/
│   ├── constants/api_constants.dart      # Endpoints, catálogos y headers
│   ├── network/api_client.dart           # Cliente HTTP con interceptor multi-tenant
│   ├── network/api_exceptions.dart       # Manejo de errores HTTP (400, 401, 403, 500)
│   ├── storage/session_storage.dart      # Almacenamiento seguro de credenciales
│   ├── theme/app_theme.dart              # Tema minimalista Material 3 (Claro / Oscuro)
│   └── utils/formatters.dart             # Formato de divisas ($), fechas y porcentajes
├── data/
│   ├── models/                           # Modelos fuertemente tipados
│   │   ├── dashboard_kpi_model.dart
│   │   ├── inmueble_model.dart
│   │   ├── contrato_model.dart
│   │   └── inquilino_model.dart
│   └── repositories/                     # Capa de acceso a datos REST
│       ├── dashboard_repository.dart
│       ├── inmuebles_repository.dart
│       ├── contratos_repository.dart
│       └── inquilinos_repository.dart
├── logic/                                # Manejo de Estado (ChangeNotifier / Provider)
│   ├── auth_provider.dart
│   ├── dashboard_provider.dart
│   ├── inmuebles_provider.dart
│   ├── contratos_provider.dart
│   └── inquilinos_provider.dart
├── presentation/                         # Vistas y Widgets UI
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── tenant_setup_screen.dart
│   │   ├── main_navigation_screen.dart
│   │   ├── dashboard/dashboard_screen.dart
│   │   ├── inmuebles/inmuebles_screen.dart
│   │   ├── inmuebles/inmueble_detail_screen.dart
│   │   ├── contratos/contratos_screen.dart
│   │   ├── contratos/contrato_detail_screen.dart
│   │   └── inquilinos/inquilinos_screen.dart
│   └── widgets/                          # Componentes reutilizables
│       ├── kpi_metric_card.dart
│       ├── duo_bar_chart.dart
│       ├── status_badge.dart
│       └── custom_search_bar.dart
└── main.dart                             # Punto de entrada e inyección de dependencias
```

---

## 🛠️ Cómo Ejecutar el Proyecto

1. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```

2. **Ejecutar en tu dispositivo o emulador (Android / iOS / Web / Desktop)**:
   ```bash
   flutter run
   ```

3. **Ejecutar pruebas unitarias**:
   ```bash
   flutter test
   ```
