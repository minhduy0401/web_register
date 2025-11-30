-- =============================================
-- HỆ THỐNG ĐĂNG KÝ CA LÀM VIỆC
-- Phiên bản: 2.0
-- Ngày tạo: 2025-11-30
-- =============================================

CREATE DATABASE web_register;
GO

USE web_register; 
GO

-- =============================================
-- BẢNG 1: USERS (Người dùng)
-- Quản lý thông tin đăng nhập và vai trò
-- =============================================
CREATE TABLE Users (
    user_id INT PRIMARY KEY IDENTITY(1,1),
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL, -- Nên mã hóa bằng bcrypt/hash
    full_name NVARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(15),
    role VARCHAR(20) NOT NULL DEFAULT 'staff', -- 'admin' hoặc 'staff'
    status NVARCHAR(20) DEFAULT N'Đang hoạt động',
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE(),
    
    CONSTRAINT CHK_Role CHECK (role IN ('admin', 'staff'))
);
GO

-- =============================================
-- BẢNG 2: SHIFT_REGISTRATIONS (Đăng ký ca làm)
-- Lưu các đăng ký ca làm với giờ tùy chỉnh
-- =============================================
CREATE TABLE Shift_Registrations (
    id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT NOT NULL,
    user_name NVARCHAR(100) NOT NULL, -- Lưu tên để dễ hiển thị
    date DATE NOT NULL,
    shift VARCHAR(20) DEFAULT 'custom', -- 'custom', 'morning', 'afternoon', 'evening' (legacy)
    shift_time VARCHAR(50), -- Format: "09:00 - 17:00"
    start_time TIME NOT NULL, -- Giờ bắt đầu
    end_time TIME NOT NULL, -- Giờ kết thúc
    work_hours DECIMAL(4, 2), -- Tổng số giờ làm việc
    created_at DATETIME DEFAULT GETDATE(),
    
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    
    -- Ràng buộc: Giờ kết thúc phải sau giờ bắt đầu
    CONSTRAINT CHK_Time CHECK (end_time > start_time),
    
    -- Ràng buộc: Mỗi ca không quá 12 giờ
    CONSTRAINT CHK_WorkHours CHECK (work_hours <= 12),
    
    -- Index để tìm kiếm nhanh
    INDEX IDX_User_Date (user_id, date),
    INDEX IDX_Date (date)
);
GO

-- =============================================
-- BẢNG 3: SHIFT_SCHEDULES (Lịch làm việc đã phân)
-- Lịch làm đã được admin phê duyệt/phân ca
-- =============================================
CREATE TABLE Shift_Schedules (
    id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT NOT NULL,
    user_name NVARCHAR(100) NOT NULL,
    date DATE NOT NULL,
    shift VARCHAR(20) DEFAULT 'custom',
    shift_time VARCHAR(50),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    work_hours DECIMAL(4, 2),
    assigned_at DATETIME DEFAULT GETDATE(),
    assigned_by NVARCHAR(100), -- Người phân ca (admin hoặc 'phân ca tự động')
    status NVARCHAR(30) DEFAULT N'Đã phân ca', -- 'Đã phân ca', 'Đã hoàn thành', 'Đã hủy'
    
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    
    CONSTRAINT CHK_Schedule_Time CHECK (end_time > start_time),
    CONSTRAINT CHK_Schedule_Hours CHECK (work_hours <= 12),
    
    INDEX IDX_Schedule_User_Date (user_id, date),
    INDEX IDX_Schedule_Date (date)
);
GO

-- =============================================
-- BẢNG 4: AUDIT_HISTORY (Lịch sử & nhật ký)
-- Ghi lại mọi thao tác quan trọng trong hệ thống
-- =============================================
CREATE TABLE Audit_History (
    id INT PRIMARY KEY IDENTITY(1,1),
    action VARCHAR(50) NOT NULL, -- 'create', 'update', 'delete', 'assign', 'login', 'logout'
    description NVARCHAR(500) NOT NULL,
    user_name NVARCHAR(100), -- Người thực hiện
    target_user NVARCHAR(100), -- Người bị tác động (nếu có)
    metadata NVARCHAR(MAX), -- JSON data chứa chi tiết
    ip_address VARCHAR(50),
    created_at DATETIME DEFAULT GETDATE(),
    
    INDEX IDX_Action (action),
    INDEX IDX_CreatedAt (created_at),
    INDEX IDX_User (user_name)
);
GO

-- =============================================
-- BẢNG 5: SYSTEM_CONFIG (Cấu hình hệ thống)
-- Lưu các thiết lập như số slot ca làm, giới hạn giờ
-- =============================================
CREATE TABLE System_Config (
    config_key VARCHAR(100) PRIMARY KEY,
    config_value NVARCHAR(500),
    description NVARCHAR(500),
    updated_at DATETIME DEFAULT GETDATE(),
    updated_by NVARCHAR(100)
);
GO

-- =============================================
-- STORED PROCEDURES
-- =============================================

-- SP1: Kiểm tra xung đột thời gian
CREATE PROCEDURE SP_CheckTimeConflict
    @user_id INT,
    @date DATE,
    @start_time TIME,
    @end_time TIME,
    @exclude_id INT = NULL
AS
BEGIN
    SELECT COUNT(*) AS conflict_count
    FROM Shift_Registrations
    WHERE user_id = @user_id
      AND date = @date
      AND (@exclude_id IS NULL OR id != @exclude_id)
      AND (
          (@start_time >= start_time AND @start_time < end_time) OR
          (@end_time > start_time AND @end_time <= end_time) OR
          (@start_time <= start_time AND @end_time >= end_time)
      );
END;
GO

-- SP2: Tính tổng giờ làm trong ngày
CREATE PROCEDURE SP_GetDailyWorkHours
    @user_id INT,
    @date DATE,
    @exclude_id INT = NULL
AS
BEGIN
    SELECT ISNULL(SUM(work_hours), 0) AS total_hours
    FROM Shift_Registrations
    WHERE user_id = @user_id
      AND date = @date
      AND (@exclude_id IS NULL OR id != @exclude_id);
END;
GO

-- SP3: Lấy danh sách đăng ký theo ngày
CREATE PROCEDURE SP_GetRegistrationsByDate
    @start_date DATE,
    @end_date DATE
AS
BEGIN
    SELECT 
        r.*,
        u.full_name,
        u.email
    FROM Shift_Registrations r
    INNER JOIN Users u ON r.user_id = u.user_id
    WHERE r.date BETWEEN @start_date AND @end_date
    ORDER BY r.date, r.start_time, u.full_name;
END;
GO

-- SP4: Tự động phân ca (chuyển đăng ký sang lịch làm)
CREATE PROCEDURE SP_AutoAssignShifts
    @assigned_by NVARCHAR(100)
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Xóa lịch cũ (tùy chọn)
        -- DELETE FROM Shift_Schedules;
        
        -- Chuyển tất cả đăng ký sang lịch làm
        INSERT INTO Shift_Schedules (user_id, user_name, date, shift, shift_time, start_time, end_time, work_hours, assigned_by)
        SELECT user_id, user_name, date, shift, shift_time, start_time, end_time, work_hours, @assigned_by
        FROM Shift_Registrations;
        
        -- Ghi log
        INSERT INTO Audit_History (action, description, user_name)
        VALUES ('assign', N'Tự động phân ca cho ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' đăng ký', @assigned_by);
        
        COMMIT TRANSACTION;
        
        SELECT @@ROWCOUNT AS schedules_created;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- =============================================
-- DỮ LIỆU MẪU (DEMO DATA)
-- =============================================

-- Thêm users mẫu
INSERT INTO Users (username, password_hash, full_name, email, phone, role) VALUES
('admin', 'admin123', N'Quản trị viên', 'admin@restaurant.com', '0901234567', 'admin'),
('nva', '123456', N'Nguyễn Văn A', 'nva@restaurant.com', '0901234568', 'staff'),
('nvb', '123456', N'Nguyễn Văn B', 'nvb@restaurant.com', '0901234569', 'staff'),
('nvc', '123456', N'Nguyễn Văn C', 'nvc@restaurant.com', '0901234570', 'staff'),
('nvd', '123456', N'Nguyễn Văn D', 'nvd@restaurant.com', '0901234571', 'staff');
GO

-- Thêm cấu hình hệ thống
INSERT INTO System_Config (config_key, config_value, description) VALUES
('max_hours_per_day', '8', N'Tối đa số giờ làm việc trong 1 ngày'),
('max_hours_per_shift', '12', N'Tối đa số giờ cho 1 ca làm'),
('allow_overlap', 'false', N'Cho phép đăng ký ca trùng giờ'),
('auto_cleanup_days', '30', N'Tự động xóa lịch sử sau N ngày');
GO

-- =============================================
-- VIEWS (Các view hữu ích)
-- =============================================

-- View: Thống kê đăng ký theo nhân viên
CREATE VIEW VW_RegistrationStats AS
SELECT 
    u.user_id,
    u.full_name,
    COUNT(r.id) AS total_registrations,
    SUM(r.work_hours) AS total_hours,
    MIN(r.date) AS first_date,
    MAX(r.date) AS last_date
FROM Users u
LEFT JOIN Shift_Registrations r ON u.user_id = r.user_id
WHERE u.role = 'staff'
GROUP BY u.user_id, u.full_name;
GO

-- View: Lịch làm theo tuần
CREATE VIEW VW_WeeklySchedule AS
SELECT 
    s.*,
    u.email,
    u.phone,
    DATENAME(WEEKDAY, s.date) AS day_of_week
FROM Shift_Schedules s
INNER JOIN Users u ON s.user_id = u.user_id
WHERE s.date >= DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0)
  AND s.date < DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()) + 1, 0);
GO

-- View: Phát hiện xung đột thời gian
CREATE VIEW VW_TimeConflicts AS
SELECT 
    r1.user_id,
    r1.user_name,
    r1.date,
    r1.shift_time AS shift1,
    r2.shift_time AS shift2,
    'CONFLICT' AS status
FROM Shift_Registrations r1
INNER JOIN Shift_Registrations r2 
    ON r1.user_id = r2.user_id 
    AND r1.date = r2.date 
    AND r1.id < r2.id
WHERE (r1.start_time >= r2.start_time AND r1.start_time < r2.end_time)
   OR (r1.end_time > r2.start_time AND r1.end_time <= r2.end_time)
   OR (r1.start_time <= r2.start_time AND r1.end_time >= r2.end_time);
GO

-- =============================================
-- TRIGGERS
-- =============================================

-- Trigger: Tự động tính work_hours khi insert/update
CREATE TRIGGER TRG_CalcWorkHours_Registration
ON Shift_Registrations
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE Shift_Registrations
    SET work_hours = DATEDIFF(MINUTE, i.start_time, i.end_time) / 60.0,
        shift_time = FORMAT(i.start_time, 'HH:mm') + ' - ' + FORMAT(i.end_time, 'HH:mm')
    FROM Shift_Registrations r
    INNER JOIN inserted i ON r.id = i.id;
END;
GO

-- Trigger: Tự động tính work_hours cho lịch làm
CREATE TRIGGER TRG_CalcWorkHours_Schedule
ON Shift_Schedules
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE Shift_Schedules
    SET work_hours = DATEDIFF(MINUTE, i.start_time, i.end_time) / 60.0,
        shift_time = FORMAT(i.start_time, 'HH:mm') + ' - ' + FORMAT(i.end_time, 'HH:mm')
    FROM Shift_Schedules s
    INNER JOIN inserted i ON s.id = i.id;
END;
GO

-- =============================================
-- INDEXES BỔ SUNG (Tối ưu hiệu suất)
-- =============================================
CREATE INDEX IDX_Users_Username ON Users(username);
CREATE INDEX IDX_Users_Role ON Users(role);
CREATE INDEX IDX_History_Date ON Audit_History(created_at DESC);
GO

PRINT N'✅ Database web_register đã được tạo thành công!';
PRINT N'📊 Bảng: Users, Shift_Registrations, Shift_Schedules, Audit_History, System_Config';
PRINT N'🔧 Stored Procedures: 4 procedures';
PRINT N'👁️ Views: 3 views (Stats, Weekly, Conflicts)';
PRINT N'⚡ Triggers: 2 triggers (Auto calc hours)';
PRINT N'📝 Dữ liệu demo: 5 users (1 admin + 4 staff)';
GO