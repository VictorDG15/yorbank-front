# yorbank-front



YBank Mobile es una app bancaria Flutter orientada a portafolio profesional. El objetivo es demostrar una experiencia mobile real conectada a un backend bancario local: autenticacion, cuentas, saldos, tarjetas, transferencias, pagos, Yape, recargas, prestamos, cronogramas y descarga de PDF.



La app consume \*\*YBank Core Banking API\*\*, un backend Spring Boot con PostgreSQL y migraciones Flyway. No es una maqueta estatica: los saldos, movimientos, cuentas, tarjetas, prestamos y pagos salen del backend.



\## Demo Local



Credenciales de prueba:



```text

Documento: 77777777

Tarjeta:   4555555555555555

Clave:     123456

```



Backend local:



```text

http://127.0.0.1:8081

```



Si se ejecuta en celular fisico por USB:



```bash

adb reverse tcp:8081 tcp:8081

flutter run

```



Importante: `flutter run` debe ejecutarse desde la raiz de la app Flutter:



```bash

cd C:\\Users\\USER\\Desktop\\ybank

flutter run

```



\## Funcionalidades



\- Splash con branding, carga inicial y onboarding mostrado una sola vez.

\- Login por segmento Personas/Empresas.

\- Validacion de tipo de documento, numero de documento y tarjeta contra backend.

\- Login con clave de internet de 6 digitos.

\- Persistencia de identidad recordada para volver directo a la pantalla de clave.

\- Manejo de token JWT con `Authorization: Bearer`.

\- Limpieza local de token cuando el backend responde 401/403.

\- Home con nombre, saldo, cuenta, tarjeta enmascarada y movimientos reales.

\- Navegacion inferior: Inicio, Operaciones, Transferencias y Perfil.

\- Operaciones con accesos a cuentas, tarjetas, prestamos, servicios, Yape y recargas.

\- Transferencias con banco destino, cuenta origen, cuenta destino, monto y descripcion.

\- Validacion real de saldo en backend antes de debitar.

\- Transferencias YBank con debito en cuenta origen y abono en cuenta destino.

\- Transferencias a bancos externos registradas como enviadas al banco.

\- Pago de servicios desde tabla de servicios.

\- Yape con contactos guardados.

\- Recarga de celular con operadores.

\- Prestamos con producto real, cuenta de desembolso, monto maximo digital S/ 10,000, plazo, fecha de desembolso, dia de pago, finalidad e ingreso declarado.

\- Cronograma de prestamo generado por backend.

\- Aceptacion de prestamo con desembolso real a la cuenta.

\- Historial de prestamos solicitados.

\- Descarga de cronograma PDF en el celular real usando Android MediaStore.



\## Stack Mobile



\- Flutter

\- Dart

\- Riverpod para estado e inyeccion de dependencias

\- GoRouter para navegacion

\- Dio para HTTP

\- Interceptor JWT para autenticacion

\- Flutter Secure Storage para tokens

\- Hive para estado local ligero

\- Local Auth preparado para biometria

\- Firebase Messaging preparado para notificaciones

\- Material 3

\- Kotlin nativo en Android para guardar PDF en Descargas



\## Stack Backend



El backend vive en el proyecto hermano:



```text

C:\\Users\\USER\\Desktop\\ybank-core-banking-api

```



Tecnologias usadas:



\- Java 21

\- Spring Boot

\- Spring Security

\- JWT

\- Spring Data JPA

\- JdbcTemplate para flujos transaccionales

\- PostgreSQL

\- Flyway para migraciones

\- Docker Compose

\- Redis

\- Kafka

\- Maven

\- Swagger/OpenAPI



\## Arquitectura Mobile



La app usa una organizacion feature-first:



```text

lib/

&#x20; app/

&#x20;   router/

&#x20;   theme/

&#x20; core/

&#x20;   http/

&#x20;   result/

&#x20;   storage/

&#x20;   widgets/

&#x20; features/

&#x20;   auth/

&#x20;   home/

&#x20;   accounts/

&#x20;   cards/

&#x20;   operations/

&#x20;   payments/

&#x20;   transfers/

&#x20;   loans/

&#x20;   profile/

&#x20;   security/

```



Capas principales:



\- `presentation`: pantallas, widgets y controladores de UI.

\- `data`: clientes HTTP y repositorios.

\- `domain`: modelos usados por la app.

\- `core`: HTTP, storage, widgets compartidos y utilidades.

\- `app`: router y tema global.



\## Flujos Backend Reales



Autenticacion:



\- `POST /api/v1/auth/login/prepare`

\- `POST /api/v1/auth/login`



Cuentas:



\- `GET /api/v1/accounts`

\- `GET /api/v1/accounts/home-summary`

\- `GET /api/v1/accounts/movements`



Transferencias:



\- `GET /api/v1/transfers/banks`

\- `POST /api/v1/transfers`

\- `GET /api/v1/transfers`



Pagos:



\- `GET /api/v1/payments/services`

\- `POST /api/v1/payments`

\- `GET /api/v1/payments/yape-contacts`

\- `POST /api/v1/payments/yape`

\- `GET /api/v1/payments/mobile-operators`

\- `POST /api/v1/payments/recharges`



Prestamos:



\- `GET /api/v1/loans/products`

\- `POST /api/v1/loans/simulate`

\- `POST /api/v1/loans/applications`

\- `GET /api/v1/loans/applications`

\- `GET /api/v1/loans/applications/{id}/schedule.pdf`



\## Modelo De Datos



El backend incluye tablas para:



\- `users`

\- `accounts`

\- `user\_cards`

\- `account\_movements`

\- `transfers`

\- `external\_banks`

\- `service\_bills`

\- `bill\_payments`

\- `yape\_contacts`

\- `yape\_payments`

\- `mobile\_operators`

\- `mobile\_recharges`

\- `loan\_products`

\- `loan\_applications`

\- `loan\_installments`

\- `notifications`

\- `beneficiaries`

\- `customer\_profiles`



\## Levantar Backend



Desde el backend:



```bash

cd C:\\Users\\USER\\Desktop\\ybank-core-banking-api

docker compose up -d --build

```



Verificar salud:



```bash

curl http://127.0.0.1:8081/actuator/health

```



Respuesta esperada:



```json

{"status":"UP"}

```



Swagger:



```text

http://127.0.0.1:8081/swagger-ui/index.html

```



Reset local de base de datos:



```bash

cd C:\\Users\\USER\\Desktop\\ybank-core-banking-api

docker compose down -v

docker compose up -d --build

```



\## Levantar App



Desde la app Flutter:



```bash

cd C:\\Users\\USER\\Desktop\\ybank

flutter pub get

flutter run

```



En celular Android fisico por USB:



```bash

adb reverse tcp:8081 tcp:8081

flutter run

```



Si se cambia codigo nativo Android, por ejemplo `MainActivity.kt`, no basta hot reload. Hay que detener la app y ejecutar de nuevo:



```bash

flutter run

```



Esto es necesario para registrar el canal nativo que guarda PDFs en Descargas.



\## Evidencias



Las capturas estan en:



```text

assets/images/evidencias/

```



Archivos normalizados:



| Evidencia | Archivo |

|---|---|

| 01 | `assets/images/evidencias/evidencia-01.jpeg` |

| 02 | `assets/images/evidencias/evidencia-02.jpeg` |

| 03 | `assets/images/evidencias/evidencia-03.jpeg` |

| 04 | `assets/images/evidencias/evidencia-04.jpeg` |

| 05 | `assets/images/evidencias/evidencia-05.jpeg` |

| 06 | `assets/images/evidencias/evidencia-06.jpeg` |

| 07 | `assets/images/evidencias/evidencia-07.jpeg` |

| 08 | `assets/images/evidencias/evidencia-08.jpeg` |

| 09 | `assets/images/evidencias/evidencia-09.jpeg` |

| 10 | `assets/images/evidencias/evidencia-10.jpeg` |



Vista rapida:



!\[Evidencia 01](assets/images/evidencias/evidencia-01.jpeg)

!\[Evidencia 02](assets/images/evidencias/evidencia-02.jpeg)

!\[Evidencia 03](assets/images/evidencias/evidencia-03.jpeg)

!\[Evidencia 04](assets/images/evidencias/evidencia-04.jpeg)

!\[Evidencia 05](assets/images/evidencias/evidencia-05.jpeg)

!\[Evidencia 06](assets/images/evidencias/evidencia-06.jpeg)

!\[Evidencia 07](assets/images/evidencias/evidencia-07.jpeg)

!\[Evidencia 08](assets/images/evidencias/evidencia-08.jpeg)

!\[Evidencia 09](assets/images/evidencias/evidencia-09.jpeg)

!\[Evidencia 10](assets/images/evidencias/evidencia-10.jpeg)



\## Puntos Fuertes Para Reclutador



\- App mobile conectada a backend real.

\- Autenticacion JWT con almacenamiento seguro.

\- Validaciones de negocio en backend, no solo en UI.

\- Transferencias con actualizacion atomica de saldos.

\- Registro de movimientos contables.

\- Pagos y recargas que descuentan saldo.

\- Prestamos con cronograma, solicitud, desembolso y PDF.

\- Migraciones versionadas con Flyway.

\- Docker Compose para levantar dependencias.

\- Separacion clara por features.

\- UI mobile preparada para celular real.



\## Roadmap



\- Refresh token real con rotacion.

\- Certificate pinning por ambiente.

\- Device binding.

\- Push notifications reales con Firebase.

\- Auditoria de login y operaciones.

\- Estados avanzados de transferencia interbancaria.

\- Pruebas unitarias de calculo financiero.

\- Pruebas de integracion backend con Testcontainers.



