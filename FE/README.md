# ToyFlix Flutter 3.x

Production-ready toy streaming / marketplace Flutter app with feature-based Clean Architecture style.

## Architecture

```text
lib/
 ├── core/
 ├── features/
 │   ├── auth/
 │   ├── home/
 │   ├── cart/
 │   ├── profile/
 ├── services/
 ├── models/
 ├── providers/
 └── main.dart
```

## Features

- Login / Register with form validation
- Token-based auth session using SharedPreferences
- Auto login at startup
- Home toy grid, hero banner, search, categories
- Toy details, favorites, add-to-cart
- Cart + checkout
- Order history + statistics
- API CRUD for toys
- Loading & error UI
- Named routes + animated page transitions
- BottomNavigationBar: Home, Categories, Cart, Profile

## Real Backend (Node/Express)

Use backend project in `../PRM393`:

```bash
cd ../PRM393
npm install
npm start
```

API base:

- `http://localhost:5000/api/v1`

Main endpoints used by FE:

- `POST /auth/login`
- `POST /auth/register`
- `GET /toys`
- `GET /toys/:id`
- `POST /toys`
- `PUT /toys/:id`
- `DELETE /toys/:id`
- `GET /orders/me`
- `POST /orders`

## Run App

```bash
flutter pub get
flutter run
```

Default API base URL:

- `http://localhost:5000/api/v1`

Override API URL:

```bash
flutter run --dart-define=API_BASE_URL=http://<your-ip>:5000/api/v1
```
