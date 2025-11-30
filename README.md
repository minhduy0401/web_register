# 📋 Hệ thống đăng ký lịch làm

Hệ thống web đơn giản để quản lý đăng ký ca làm của nhân viên với phân quyền Admin và Nhân viên.

## 🚀 Tính năng

- 🔐 **Hệ thống đăng nhập** với phân quyền Admin và Nhân viên
- ✅ Đăng ký ca làm cho nhân viên
- 📊 Quản lý danh sách đăng ký (chỉ Admin)
- 🤖 Tự động phân ca từ danh sách đăng ký
- 📅 Xem lịch làm đã được sắp xếp (chỉ Admin)
- 💾 Lưu trữ dữ liệu với LocalStorage
- 📱 Giao diện responsive, đẹp mắt

## 📁 Cấu trúc file

```
web_register/
├── login.html       - Trang đăng nhập (trang chủ)
├── register.html    - Trang đăng ký ca làm (Admin & Nhân viên)
├── admin.html       - Trang quản lý đăng ký (chỉ Admin)
├── schedule.html    - Trang xem lịch đã sắp (chỉ Admin)
├── styles.css       - CSS chung (tùy chọn)
└── README.md        - Hướng dẫn
```

## 🎯 Cách sử dụng

### 0. Đăng nhập (login.html) - TRANG ĐẦU TIÊN

**Mở file `login.html` để bắt đầu**

#### Tài khoản demo:
- **Admin**: 
  - Username: `admin` / Password: `admin123`
  - Quyền: Truy cập tất cả trang (đăng ký, quản lý, lịch)
  
- **Nhân viên**:
  - Nguyễn A: `nva` / `123456`
  - Nguyễn B: `nvb` / `123456`
  - Nguyễn C: `nvc` / `123456`
  - Nguyễn D: `nvd` / `123456`
  - Quyền: Chỉ đăng ký ca làm cho chính mình

### 1. Đăng ký ca làm (register.html)

**Nhân viên:**
- Tự động chọn sẵn tên của mình (không thể đổi)
- Chọn ngày làm
- Chọn một hoặc nhiều ca (sáng/chiều/tối)
- Click "Gửi đăng ký"

**Admin:**
- Có thể chọn bất kỳ nhân viên nào để đăng ký
- Chọn ngày làm và ca
- Click "Gửi đăng ký"

### 2. Quản lý đăng ký (admin.html) - CHỈ ADMIN

- Xem tất cả đăng ký của nhân viên
- **🔄 Tải lại**: Làm mới danh sách
- **👑 Tự phân ca**: Chuyển tất cả đăng ký thành lịch làm (không tự động thêm người)
- **📊 Xem lịch đã sắp**: Chuyển sang trang xem lịch
- **🗑️ Xoá dữ liệu**: Xoá toàn bộ đăng ký và lịch (demo)

### 3. Xem lịch (schedule.html) - CHỈ ADMIN

- Hiển thị lịch làm đã được phân công
- Phân biệt các ca bằng màu sắc:
  - 🌅 Ca sáng (09:00 - 13:00) - Màu vàng
  - ☀️ Ca chiều (13:00 - 17:00) - Màu xanh dương
  - 🌙 Ca tối (17:00 - 22:00) - Màu tím

## 🔐 Phân quyền

| Trang | Admin | Nhân viên |
|-------|-------|-----------|
| login.html | ✅ | ✅ |
| register.html | ✅ (chọn bất kỳ ai) | ✅ (chỉ cho mình) |
| admin.html | ✅ | ❌ |
| schedule.html | ✅ | ❌ |

## ⚙️ Tùy chỉnh

### Thêm/sửa tài khoản

Mở `login.html` và tìm mảng `accounts`:

```javascript
const accounts = [
  {
    username: 'admin',
    password: 'admin123',
    role: 'admin',
    name: 'Quản trị viên',
    user_id: 'admin'
  },
  {
    username: 'nva',
    password: '123456',
    role: 'staff',
    name: 'Nguyễn A',
    user_id: '1'
  },
  // Thêm tài khoản mới ở đây
];
```

### Thêm/sửa nhân viên trong dropdown (Admin)

Mở `register.html` và tìm đoạn code trong phần admin:

```javascript
staffSelect.innerHTML = `
  <option value="">-- Chọn nhân viên --</option>
  <option value="1">Nguyễn A</option>
  <option value="2">Nguyễn B</option>
  <option value="3">Nguyễn C</option>
  <option value="4">Nguyễn D</option>
`;
```

### Tùy chỉnh ca làm

Trong file `register.html`, tìm đoạn:

```html
<label><input type="checkbox" name="shift" value="morning"> 🌅 Ca sáng (09:00 - 13:00)</label>
<label><input type="checkbox" name="shift" value="afternoon"> ☀️ Ca chiều (13:00 - 17:00)</label>
<label><input type="checkbox" name="shift" value="evening"> 🌙 Ca tối (17:00 - 22:00)</label>
```

Sửa thời gian theo nhu cầu của bạn.

## 🎨 Thiết kế

- **Màu chủ đạo**: Gradient tím (#667eea → #764ba2)
- **Animations**: Smooth transitions và hover effects
- **Icons**: Emoji để tăng tính trực quan
- **Responsive**: Tự động điều chỉnh trên mobile
- **UI/UX**: Modern card design với shadows và rounded corners

## 💡 Lưu ý

- ⚠️ **Dữ liệu được lưu trong LocalStorage** của trình duyệt
- ⚠️ Xoá cache/cookies sẽ mất dữ liệu
- ⚠️ Tài khoản và mật khẩu lưu trong code (không an toàn cho production)
- ✅ Để sử dụng thực tế, nên kết nối với backend và database
- ✅ Tính năng "Tự phân ca" chỉ lấy từ danh sách đăng ký, không tự động thêm người

## 🔧 Công nghệ

- HTML5
- CSS3 (Flexbox, Grid, Animations, Gradients)
- Vanilla JavaScript (ES6+)
- LocalStorage API
- Form Validation

## 📝 Workflow sử dụng

1. **Đăng nhập** tại `login.html`
2. **Nhân viên đăng ký ca** tại `register.html`
3. **Admin kiểm tra đăng ký** tại `admin.html`
4. **Admin phân ca** bằng nút "👑 Tự phân ca"
5. **Xem lịch cuối cùng** tại `schedule.html`

---

Made with ❤️

