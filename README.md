# 🚗 Smart Parking Management System

![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B?style=flat&logo=flutter)
![.NET](https://img.shields.io/badge/.NET-8.0-512BD4?style=flat&logo=dotnet)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-4169E1?style=flat&logo=postgresql)
![OpenAI](https://img.shields.io/badge/AI-OpenAI-412991?style=flat&logo=openai)
![License](https://img.shields.io/badge/License-MIT-green?style=flat)

**Smart Parking** là giải pháp phần mềm toàn diện giúp tự động hóa và thông minh hóa quy trình tìm kiếm, đặt chỗ và quản lý bãi đỗ xe. Dự án được xây dựng với hệ thống Backend mạnh mẽ và Ứng dụng di động (Mobile App) tối ưu, tích hợp công nghệ **Trí tuệ Nhân tạo (AI)** để nâng tầm trải nghiệm của người dùng.

---

## ✨ Tính năng nổi bật (Key Features)

### 👤 Dành cho Khách hàng (User)
*   🎙️ **Trợ lý ảo AI (Voice Booking):** Đặt chỗ rảnh tay bằng giọng nói tự nhiên, AI tự động nhận diện thực thể (thời gian, địa điểm) để xử lý.
*   🗺️ **Bản đồ trực quan:** Định vị bãi đỗ gần nhất, hiển thị số lượng chỗ trống và giá vé theo thời gian thực.
*   🕒 **Quản lý đơn đỗ linh hoạt:** Cho phép đặt chỗ trước, thanh toán trực tuyến an toàn và hỗ trợ gia hạn thời gian đỗ dễ dàng.
*   🚗 **Quản lý phương tiện:** Lưu trữ trước biển số xe, quét mã QR nhận diện nhanh khi ra vào bãi.

### 👮 Dành cho Quản lý bãi đỗ (Manager)
*   📱 **Check-in & Check-out tốc độ cao:** Sử dụng camera điện thoại quét mã QR từ đơn đỗ của khách hàng để mở cổng/tính phí.
*   📊 **Giám sát thời gian thực:** Quản lý sơ đồ vị trí trong bãi (Trống / Đã đặt / Đang sử dụng).
*   🤝 **Hỗ trợ khách vãng lai:** Quản lý có thể tạo đơn đặt chỗ hộ cho khách hàng không sử dụng ứng dụng.
*   📈 **Dashboard Thống kê:** Cập nhật doanh thu, lưu lượng xe và các báo cáo hoạt động trong ngày.

---

## 🛠 Công nghệ sử dụng (Tech Stack)

### 📱 Mobile App (Client)
*   **Framework:** Flutter & Dart
*   **State Management:** Riverpod
*   **Networking:** Dio + Interceptors (Hỗ trợ Mock Data cho chế độ Offline Demo)
*   **Tích hợp khác:** Google Maps, Firebase (Auth & Cloud Messaging), Speech-to-Text.

### 💻 Backend (Server)
*   **Framework:** C# .NET 8 (ASP.NET Core Web API)
*   **Database:** PostgreSQL + Entity Framework Core
*   **Kiến trúc:** Clean Architecture / Repository Pattern
*   **Tích hợp khác:** OpenAI API (Xử lý NLP), JWT Authentication, SMTP Mailer.

---

## 🚀 Hướng dẫn cài đặt nhanh (Quick Start)

*(Xem tài liệu chi tiết tại tệp `HUONG_DAN_CAI_DAT.md`)*

### 1. Chạy Backend (.NET Core)
1. Cài đặt **PostgreSQL** và tạo cơ sở dữ liệu `smart_parking`.
2. Mở Solution bằng Visual Studio 2022.
3. Thay đổi chuỗi kết nối DB trong `appsettings.json`.
4. Cập nhật cơ sở dữ liệu bằng lệnh `Update-Database`.
5. Bấm `F5` hoặc gõ `dotnet run` để khởi chạy máy chủ.

### 2. Chạy Mobile App (Flutter)
1. Clone dự án và mở thư mục `SmartParking_mobile`.
2. Tải các gói thư viện phụ thuộc:
   ```bash
   flutter pub get
   ```
3. **Cấu hình IP Backend:** Mở tệp `lib/core/constants/api_endpoints.dart` và cập nhật biến `baseUrl` thành IP mạng LAN thực tế của máy tính bạn. (VD: `http://192.168.2.15:5161`).
4. Khởi chạy ứng dụng lên thiết bị thật hoặc máy ảo:
   ```bash
   flutter run
   ```

---

## 📸 Hình ảnh minh họa (Screenshots)

*(Bạn hãy thay thế các link ảnh dưới đây bằng ảnh chụp màn hình thật của ứng dụng)*

<p align="center">
  <img src="https://via.placeholder.com/250x500.png?text=Home+Screen" width="220" />
  &nbsp;&nbsp;&nbsp;
  <img src="https://via.placeholder.com/250x500.png?text=AI+Voice+Booking" width="220" />
  &nbsp;&nbsp;&nbsp;
  <img src="https://via.placeholder.com/250x500.png?text=QR+Scanner" width="220" />
</p>

---

## 🤝 Đóng góp (Contributing)
Dự án được xây dựng và phát triển để phục vụ Đồ án Tốt nghiệp ngành CNTT. Mọi ý kiến đóng góp, báo cáo lỗi (issues) hoặc đề xuất cải tiến (pull requests) đều được hoan nghênh để sản phẩm ngày càng hoàn thiện.

## 📄 Giấy phép (License)
Dự án được phân phối dưới giấy phép MIT License. Khuyến khích sử dụng cho mục đích học tập và tham khảo.
