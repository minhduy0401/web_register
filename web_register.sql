create database web_register

USE web_register; 
GO

CREATE TABLE Lich_NhanVien (
    MaNhanVien INT PRIMARY KEY IDENTITY(1,1),
    HoTen NVARCHAR(100) NOT NULL,
    PhongBan NVARCHAR(50),
    ChucVu NVARCHAR(50),
    Email VARCHAR(100) UNIQUE,
    SoDienThoai VARCHAR(15),
    TrangThai NVARCHAR(20) DEFAULT N'Đang làm việc'
);
GO

CREATE TABLE Lich_CaLam (
    MaCaLam INT PRIMARY KEY IDENTITY(1,1),
    TenCaLam NVARCHAR(50) NOT NULL UNIQUE, 
    GioBatDau TIME NOT NULL,
    GioKetThuc TIME NOT NULL,
    TongSoGio DECIMAL(4, 2) NOT NULL,
    SoNhanVienYeuCau INT DEFAULT 1
);
GO

CREATE TABLE Lich_DangKy (
    MaDangKy INT PRIMARY KEY IDENTITY(1,1), -- Khóa chính, tự tăng
    MaNhanVien INT NOT NULL,
    MaCaLam INT NOT NULL,
    NgayLamViec DATE NOT NULL,
    ThoiGianDangKy DATETIME DEFAULT GETDATE(), -- Thời điểm đăng ký lịch
    TrangThai NVARCHAR(30) DEFAULT N'Đã Xác Nhận', -- Ví dụ: Đã Xác Nhận, Chờ Duyệt, Đã Hủy
    GhiChu NVARCHAR(255),

    -- Thiết lập Khóa ngoại (Foreign Keys)
    FOREIGN KEY (MaNhanVien) REFERENCES Lich_NhanVien(MaNhanVien),
    FOREIGN KEY (MaCaLam) REFERENCES Lich_CaLam(MaCaLam),

    -- Ràng buộc (Constraint) đảm bảo một nhân viên không làm 2 ca trong cùng 1 ngày
    CONSTRAINT UQ_NhanVien_NgayLam UNIQUE (MaNhanVien, NgayLamViec)
);
GO