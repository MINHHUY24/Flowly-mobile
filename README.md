# Flowly Mobile

![Flutter](https://img.shields.io/badge/Flutter-Mobile-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2.svg)
![Express](https://img.shields.io/badge/Express-Backend-black.svg)
![Supabase](https://img.shields.io/badge/Supabase-Auth%20%26%20Database-3ECF8E.svg)
![Gemini](https://img.shields.io/badge/Gemini-AI%20Assistant-orange.svg)

Flowly là ứng dụng quản lý công việc và lịch trình được xây dựng bằng Flutter, đi kèm backend API Node.js/Express và Supabase cho xác thực, lưu trữ dữ liệu theo từng người dùng. Ứng dụng tập trung vào trải nghiệm mobile trước, có giao diện tối/sáng, hỗ trợ tablet và có Flowly Bot để tạo nhanh task hoặc lịch từ câu nhập tự nhiên.

## Giới thiệu

Flowly gom các thao tác quản lý công việc hằng ngày vào một nơi duy nhất. Người dùng có thể tạo nhiệm vụ, xem lịch tháng, quản lý lịch trình theo giờ, đổi ngôn ngữ, đổi giao diện và dùng Flowly Bot để tạo task hoặc lịch bằng câu tự nhiên.

Thay vì phải nhập từng nhiệm vụ thủ công, người dùng có thể viết:

```text
Hôm nay tôi cần làm: học bài, đi họp, làm thêm
```

Flowly Bot sẽ phân tích câu nhập và tạo các nhiệm vụ tương ứng cho ngày hôm nay.

## Mục tiêu dự án

- Xây dựng một ứng dụng quản lý công việc có giao diện mobile hiện đại.
- Thực hành Flutter, Express và Supabase trong một dự án full-stack thực tế.
- Tích hợp xác thực email/password và OAuth.
- Xây dựng API backend có xác thực bằng Supabase access token.
- Tích hợp AI để hỗ trợ tạo task/lịch nhanh hơn.
- Tối ưu trải nghiệm cho cả điện thoại và tablet.

## Tính năng chính

- Đăng nhập, đăng ký, quên mật khẩu và OAuth qua Supabase.
- Quản lý nhiệm vụ theo ngày, trạng thái và mức ưu tiên.
- Lịch trình theo ngày/tuần, giờ bắt đầu/kết thúc, màu lịch và lặp lịch.
- Dashboard tổng quan số việc hôm nay, lịch dự kiến và việc khẩn cấp.
- Flowly Bot tạo task/lịch từ câu nhập tiếng Việt hoặc tiếng Anh.
- Giao diện sáng/tối/tự động theo hệ thống.
- Hỗ trợ bố cục điện thoại và tablet.
- Đa ngôn ngữ cơ bản: Tiếng Việt và English.

## Cách sử dụng ứng dụng

1. Đăng ký hoặc đăng nhập bằng email/password, Google hoặc Facebook.
2. Ở trang Home, xem tổng quan công việc hôm nay, lịch dự kiến và task theo ngày.
3. Bấm nút thêm để tạo nhiệm vụ nhanh với tên, mô tả và ngày thực hiện.
4. Ở trang Lịch trình, tạo lịch theo ngày, giờ bắt đầu, giờ kết thúc, màu và lặp lịch nếu cần.
5. Ở trang Nhiệm vụ, theo dõi task theo trạng thái: Mới, Đang thực hiện, Tạm hoãn, Đã xử lý, Đã hủy.
6. Mở Flowly Bot và nhập yêu cầu bằng ngôn ngữ tự nhiên để tạo task hoặc lịch tự động.

Ví dụ Flowly Bot:

```text
Ngày 20/6 tôi có lịch phỏng vấn lúc 10h
```

Kết quả: Flowly tạo một lịch ngày `20-06`, bắt đầu lúc `10:00`; nếu không có giờ kết thúc, hệ thống tự đặt kết thúc sau 1 tiếng.

## Công nghệ

- Flutter / Dart cho ứng dụng Android và iOS.
- Node.js / Express cho REST API.
- Supabase Auth và Supabase Database.
- Gemini API qua `@google/genai` cho Flowly Bot.
- `date-holidays` để lấy dữ liệu ngày lễ.

## Cấu trúc dự án

```text
flowly-mobile/
├── mobile/                 # Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   └── src/
│   │       ├── core/        # Config, API client, theme, l10n, repository
│   │       ├── models/      # Task và schedule models
│   │       ├── pages/       # Auth, home, schedule, tasks, app shell
│   │       └── widgets/     # Shared UI widgets
│   └── assets/
│       ├── images/
│       └── config/app.env   # Config public cho Flutter
├── server/                 # Express API
│   ├── controllers/
│   ├── middleware/
│   ├── routes/
│   ├── services/
│   └── index.js
├── package.json            # Scripts chạy backend và mobile
└── README.md
```

## Yêu cầu môi trường

- Flutter SDK tương thích Dart `^3.11.5`.
- Node.js 18+.
- Tài khoản Supabase.
- Gemini API key nếu dùng Flowly Bot.
- Android Studio hoặc Xcode để chạy simulator/emulator.

## Cài đặt

Clone project và cài dependencies backend:

```bash
git clone <repository-url>
cd flowly-mobile
npm install
```

Cài dependencies Flutter:

```bash
cd mobile
flutter pub get
```

## Cấu hình backend

Tạo file `.env` ở thư mục root:

```env
PORT=3000
SUPABASE_URL=your_supabase_url
SUPABASE_PUBLISHABLE_KEY=your_supabase_publishable_key
GEMINI_API_KEY=your_gemini_api_key
SESSION_SECRET=your_session_secret
```

Các biến môi trường backend:

| Biến | Ý nghĩa |
| --- | --- |
| `PORT` | Port chạy Express API |
| `SUPABASE_URL` | URL Supabase project |
| `SUPABASE_PUBLISHABLE_KEY` | Public key của Supabase |
| `GEMINI_API_KEY` | API key dùng cho Flowly Bot |
| `SESSION_SECRET` | Secret dùng cho phiên hoặc cấu hình server |

Chạy API:

```bash
npm run dev:server
```

API mặc định chạy tại:

```text
http://localhost:3000
```

Các endpoint chính:

```text
GET    /api/config
GET    /api/holidays/:year
GET    /api/tasks
POST   /api/tasks
PUT    /api/tasks/:id
PATCH  /api/tasks/:id/status
DELETE /api/tasks/:id
GET    /api/schedules
POST   /api/schedules
PUT    /api/schedules/:id
DELETE /api/schedules/:id
POST   /api/ai/parse
```

Các endpoint dữ liệu yêu cầu Supabase access token qua header:

```text
Authorization: Bearer <supabase_access_token>
```

## Cấu hình Flutter

Flutter đọc config theo thứ tự:

1. `--dart-define`
2. `mobile/assets/config/app.env`
3. API `/api/config`

Ví dụ `mobile/assets/config/app.env`:

```env
FLOWLY_API_BASE_URL=http://localhost:3000
SUPABASE_URL=your_supabase_url
SUPABASE_PUBLISHABLE_KEY=your_supabase_publishable_key
```

Khi chạy Android emulator, app tự dùng API mặc định:

```text
http://10.0.2.2:3000
```

Với iOS simulator, mặc định là:

```text
http://localhost:3000
```

Hoặc truyền trực tiếp khi chạy:

```bash
flutter run \
  --dart-define=FLOWLY_API_BASE_URL=http://localhost:3000 \
  --dart-define=SUPABASE_URL=your_supabase_url \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your_supabase_publishable_key
```

## Chạy ứng dụng

Chạy backend ở thư mục root:

```bash
npm run dev:server
```

Chạy app Flutter:

```bash
cd mobile
flutter run
```

Hoặc chạy backend và Flutter cùng lúc từ root:

```bash
npm run dev:mobile
```

## Supabase OAuth redirect

Nếu dùng Google/Facebook login, thêm redirect URL sau trong Supabase Dashboard:

```text
Authentication > URL Configuration > Additional Redirect URLs
flowly://login-callback
```

Provider Google/Facebook vẫn dùng callback URL của Supabase. Deep link `flowly://login-callback` dùng để đưa người dùng quay lại app sau khi xác thực.

## Database tham khảo

Flowly hiện dùng hai bảng chính là `tasks` và `schedules`. Tên cột dưới đây khớp với payload backend đang sử dụng.

```sql
create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  title text not null,
  description text,
  task_type text not null,
  task_date date,
  status text default 'pending',
  priority text default 'normal',
  tag_color text default 'orange',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
```

```sql
create table if not exists public.schedules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  title text not null,
  description text default '',
  schedule_date date not null,
  start_time time not null,
  end_time time not null,
  color text default 'blue',
  status text default 'pending',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
```

Khi public app, nên bật Row Level Security trong Supabase và chỉ cho phép người dùng thao tác dữ liệu có `user_id` của chính họ.

## Kiểm tra chất lượng code

Chạy trong thư mục `mobile/`:

```bash
flutter analyze
flutter test
```

Format Dart:

```bash
dart format lib test
```

## Ghi chú bảo mật

- Không commit file `.env` chứa secret thật.
- `SUPABASE_PUBLISHABLE_KEY` là public key dành cho client, nhưng vẫn nên quản lý cấu hình theo môi trường.
- `GEMINI_API_KEY` chỉ nên nằm ở backend.
- Các API thao tác task/schedule đều lọc theo `user_id` từ Supabase token.

## Trạng thái dự án

Flowly hiện tập trung vào bản mobile Android/iOS. Backend Express đóng vai trò API trung gian cho Supabase, ngày lễ và Flowly Bot.
