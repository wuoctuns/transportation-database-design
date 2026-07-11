create database ĐỒ_ÁN_CSDL
go
use ĐỒ_ÁN_CSDL 
go 

--BẢNG KHÁCH HÀNG
CREATE TABLE KHACH_HANG (
    MaKH INT PRIMARY KEY,
    HoTen NVARCHAR(100),
    GioiTinh NVARCHAR(10),
    NgaySinh DATE,
    SoDienThoai VARCHAR(15),
    Email NVARCHAR(100),
    CCCD VARCHAR(20),
    NgayTao DATE DEFAULT GETDATE(),
    TrangThai NVARCHAR(20) DEFAULT N'Hoạt động'  -- hoặc 'Khoá'
);

--BẢNG NGƯỜI BÁN 
CREATE TABLE NGUOI_BAN (
    MaNB INT PRIMARY KEY,
    TenShop NVARCHAR(100),
    DiaChi NVARCHAR(200),
    Email NVARCHAR(100),
    SoDienThoai VARCHAR(15),
    NgayThamGia DATE DEFAULT GETDATE(),
    TrangThai NVARCHAR(20) DEFAULT N'Hoạt động',  -- Hoạt động / Ngưng hoạt động
    Mota NVARCHAR(255)                            -- Mô tả ngắn về shop
);

--BẢNG ĐƠN HÀNG
CREATE TABLE DON_HANG (
    MaDH INT PRIMARY KEY,
    MaKH INT,
    NgayDat DATE,
    TongTien MONEY,
    TrangThai NVARCHAR(50),  -- Đặt hàng, Xác nhận, Đang giao, Hoàn tất, Hủy
    SoDienThoaiNhan VARCHAR(15),
    NguoiNhan NVARCHAR(100),
    DiaChiGiao NVARCHAR(200),
    FOREIGN KEY (MaKH) REFERENCES KHACH_HANG(MaKH)
);

--BẢNG LOẠI HÀNG
CREATE TABLE LOAI_HANG (
    MaLoai INT PRIMARY KEY,
    TenLoai NVARCHAR(100),
    MoTa NVARCHAR(255),         -- Mô tả về loại hàng
    DoPhoBien INT DEFAULT 0     -- Độ phổ biến: số lượng sản phẩm thuộc loại này (hoặc rating, dùng để trigger cập nhật sau này)
);

--BẢNG SẢN PHẨM 
CREATE TABLE SAN_PHAM (
    MaSP INT PRIMARY KEY,
    TenSP NVARCHAR(100),
    DonGia MONEY,
    MaLoai INT,
    MaNB INT,
    FOREIGN KEY (MaLoai) REFERENCES LOAI_HANG(MaLoai),
    FOREIGN KEY (MaNB) REFERENCES NGUOI_BAN(MaNB)
);

--BẢNG CHI TIẾT ĐƠN HÀNG
CREATE TABLE CHI_TIET_DON_HANG (
    MaDH INT,
    MaSP INT,
    SoLuong INT,
    DonGia MONEY,
    PRIMARY KEY (MaDH, MaSP),
    FOREIGN KEY (MaDH) REFERENCES DON_HANG(MaDH),
    FOREIGN KEY (MaSP) REFERENCES SAN_PHAM(MaSP)
);

--BẢNG ĐƠN VỊ VẬN CHUYỂN 
CREATE TABLE DON_VI_VAN_CHUYEN (
    MaDVVC INT PRIMARY KEY,
    TenDVVC NVARCHAR(100)
);

--BẢNG NHÂN VIÊN GIAO HÀNG 
CREATE TABLE NHAN_VIEN_GIAO_HANG (
    MaNVGH INT PRIMARY KEY,
    TenNV NVARCHAR(100),
    GioiTinh NVARCHAR(10),
    NgaySinh DATE,
    SoDienThoai VARCHAR(15),
    CCCD VARCHAR(20),
    MaDVVC INT,
    NgayVaoLam DATE,
    TrangThai NVARCHAR(20) DEFAULT N'Đang hoạt động',  -- 'Nghỉ việc', 'Tạm ngưng'
    FOREIGN KEY (MaDVVC) REFERENCES DON_VI_VAN_CHUYEN(MaDVVC)
);

--BẢNG GIAO HÀNG
CREATE TABLE GIAO_HANG (
    MaGH INT PRIMARY KEY,
    MaDH INT,
    MaNVGH INT,
    NgayGiao DATE,
    TinhTrang NVARCHAR(100),  -- Chờ lấy hàng, Đang giao, Giao thành công, Thất bại
    MaXacNhan VARCHAR(10),     -- Ví dụ: OTP 6 số
    ThoiGianGiaoThanhCong DATETIME NULL,
    FOREIGN KEY (MaDH) REFERENCES DON_HANG(MaDH),
    FOREIGN KEY (MaNVGH) REFERENCES NHAN_VIEN_GIAO_HANG(MaNVGH)
);

--BẢNG ĐƠN HÀNG
CREATE TABLE DIA_CHI (
    MaDC INT PRIMARY KEY,
    MaKH INT,
    DiaChi NVARCHAR(200),
    ThanhPho NVARCHAR(50),
    LoaiDiaChi NVARCHAR(20),  -- Nhà riêng, Công ty, Văn phòng
    MacDinh BIT DEFAULT 0,
    FOREIGN KEY (MaKH) REFERENCES KHACH_HANG(MaKH)
);

--BẢNG THANH TOÁN
CREATE TABLE THANH_TOAN (
    MaTT INT PRIMARY KEY,
    MaDH INT,
    HinhThuc NVARCHAR(50),
    DaThanhToan BIT, --1: đã thanh toán, 0: chưa thanh toán
    FOREIGN KEY (MaDH) REFERENCES DON_HANG(MaDH)
);

--BẢNG TRẠNG THÁI GIAO HÀNG
CREATE TABLE TRANG_THAI_DON_HANG (
    MaTT INT PRIMARY KEY,
    MaDH INT,
    NgayCapNhat DATETIME,
    TrangThai NVARCHAR(100),
    FOREIGN KEY (MaDH) REFERENCES DON_HANG(MaDH)
);

CREATE TABLE HOAN_TIEN (
    MaHT INT IDENTITY(1,1) PRIMARY KEY,         -- Mã hoàn tiền tự tăng
    MaDH INT,                                   -- Mã đơn hàng được hoàn
    SoTien MONEY,                               -- Số tiền hoàn lại
    NgayHoan DATETIME DEFAULT GETDATE(),        -- Ngày hoàn tiền
    HinhThuc NVARCHAR(50),                      -- Hình thức thanh toán hoàn về
    LyDo NVARCHAR(255),                         -- Lý do hoàn tiền (ví dụ: Giao thất bại, Đơn bị hủy)
    FOREIGN KEY (MaDH) REFERENCES DON_HANG(MaDH)
);

