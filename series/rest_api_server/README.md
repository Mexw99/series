# Series REST API Server

โฟลเดอร์นี้เป็นเซิร์ฟเวอร์ REST API สำหรับแท็บ `ซีรีส์ออนไลน์ (REST API)`

## คำสั่งเริ่มเซิร์ฟเวอร์

```bash
cd rest_api_server
npm install
npm start
```

เซิร์ฟเวอร์จะทำงานที่ `http://localhost:3000`

ถ้าไม่กำหนด `DATABASE_URL` server จะใช้ `data/series.json` สำหรับทดสอบในเครื่อง
เมื่อ deploy จริง ให้กำหนด `DATABASE_URL` ของ Supabase ใน Environment Variables
ของ Render เพื่อให้ข้อมูลเก็บใน PostgreSQL ออนไลน์

## Endpoint ที่ใช้ในแอป

```text
GET    /api/series?ownerId=รหัสผู้ใช้
GET    /api/series/:id
POST   /api/series
PUT    /api/series/:id
DELETE /api/series/:id?ownerId=รหัสผู้ใช้
```

ข้อมูลจะถูกเก็บไว้ใน `data/series.json` เพื่อให้เห็นการทำงานของ CRUD ได้ง่าย

## URL สำหรับรันแอป

- macOS: `http://127.0.0.1:3000/api`
- Android Emulator: `http://10.0.2.2:3000/api`
- iPhone Simulator: `http://127.0.0.1:3000/api`
- โทรศัพท์จริง: ใช้ IP ของ Mac ในเครือข่าย Wi-Fi เดียวกัน เช่น `http://192.168.1.10:3000/api`

ตัวอย่าง:

```bash
flutter run --dart-define=REST_API_BASE_URL=http://192.168.1.10:3000/api
```
