use ĐỒ_ÁN_CSDL
go

--TRIGGER 1: Ràng buộc kiểm tra đơn hàng thanh toán online nhưng đơn bị hủy hoặc giao thất bại => print hoàn tiền
CREATE TRIGGER trg_hoantien
ON DON_HANG
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INSERTED I
        JOIN THANH_TOAN T ON I.MaDH = T.MaDH
        WHERE I.TrangThai = N'Hủy'
          AND T.DaThanhToan = 1
          AND T.HinhThuc IN (N'ShopeePay', N'Thẻ tín dụng/ghi nợ', N'Chuyển khoản ngân hàng')
    )
    BEGIN
        PRINT N'Đơn hàng thất bại, tiền sẽ được hoàn lại cho khách hàng trong vài ngày tới, xin cảm ơn.'
    END
END

/*NOTE: INSERT INTO DON_HANG (MaDH, MaKH, NgayDat, TongTien, TrangThai, SoDienThoaiNhan, NguoiNhan, DiaChiGiao)
VALUES (999, 1, '2025-05-21', 950000, N'Xác nhận', '0909123456', N'Nguyễn Văn A', N'123 Lê Lợi, Q1');
INSERT INTO THANH_TOAN (MaTT, MaDH, HinhThuc, DaThanhToan)
VALUES (999, 999, N'Chuyển khoản ngân hàng', 1);
UPDATE DON_HANG
SET TrangThai = N'Hủy'
WHERE MaDH = 999; */

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

--TRIGGER 2: Ràng buộc update thêm dữ liệu mới vào bảng HOAN_TIEN nếu "Đơn hàng bị hủy"
--và đơn hàng ĐÃ ĐƯỢC TRẢ TIỀN TRƯỚC
DROP TRIGGER IF EXISTS trg_HoanTien_DonBiHuy;

CREATE TRIGGER trg_HoanTien_DonBiHuy
ON DON_HANG
AFTER UPDATE
AS
BEGIN
    PRINT N'>>> Trigger trg_HoanTien_DonBiHuy đã chạy <<<';

    INSERT INTO HOAN_TIEN (MaDH, SoTien, HinhThuc, LyDo)
    SELECT 
        I.MaDH,
        D.TongTien,
        T.HinhThuc,
        N'Đơn hàng bị hủy'
    FROM INSERTED I
    JOIN DON_HANG D ON I.MaDH = D.MaDH
    JOIN THANH_TOAN T ON D.MaDH = T.MaDH
    WHERE I.TrangThai = N'Hủy'
      AND T.DaThanhToan = 1
      AND T.HinhThuc IN (N'ShopeePay', N'Thẻ tín dụng/ghi nợ', N'Chuyển khoản ngân hàng')
      AND NOT EXISTS (
          SELECT 1 FROM HOAN_TIEN H WHERE H.MaDH = I.MaDH
      );
END;
GO

/*NOTE:
-- Thêm khách hàng (nếu chưa có)
INSERT INTO KHACH_HANG (MaKH, HoTen, GioiTinh, NgaySinh, SoDienThoai, Email, CCCD, NgayTao, TrangThai)
VALUES (13, N'Nguyễn Thúc Thùy Tiên', N'Nữ', '1990-05-27', '0907654321', 't@gmail.com', '123654789', DEFAULT, DEFAULT);
-- Thêm đơn hàng
INSERT INTO DON_HANG (MaDH, MaKH, NgayDat, TongTien, TrangThai, SoDienThoaiNhan, NguoiNhan, DiaChiGiao)
VALUES (901, 13, '2025-05-21', 850000, N'Xác nhận', '0907654321', N'Nguyễn Thúc Thùy Tiên', N'75 Bình Chánh, TPHCM');
-- Thêm thanh toán trả trước
INSERT INTO THANH_TOAN (MaTT, MaDH, HinhThuc, DaThanhToan)
VALUES (901, 901, N'ShopeePay', 1);
UPDATE DON_HANG
SET TrangThai = N'Hủy'
WHERE MaDH = 901; */

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

--TRIGGER 3: Chỉ cho phép tạo tài khoản từ 1 số điện thoại
CREATE TRIGGER trg_dktk_1sdt
ON KHACH_HANG
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INSERTED I
        JOIN KHACH_HANG K ON I.SoDienThoai = K.SoDienThoai
        WHERE I.MaKH <> K.MaKH -- loại trừ cập nhật chính mình
    )
    BEGIN
        PRINT N'Số điện thoại này đã được sử dụng để đăng ký tài khoản khác. Vui lòng dùng số điện thoại khác.'
        RETURN;
    END
END;

/*NOTE:
INSERT INTO KHACH_HANG (MaKH, HoTen, GioiTinh, NgaySinh, SoDienThoai, Email, CCCD, NgayTao, TrangThai)
VALUES (111, N'Bùi Xuân Nghi', N'Nữ', '2006-01-14', '0911223344', 'ngh@gmail.com', '987654321098', DEFAULT, DEFAULT );*/

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------


--TRIGGER 4: Không cho phép shop "ngưng hoạt động" nếu còn đơn hàng đang xử lý
CREATE TRIGGER trg_KhongDuocNgungHoatDongNeuConDon
ON NGUOI_BAN
INSTEAD OF UPDATE
AS
BEGIN
    -- Kiểm tra các dòng cập nhật trạng thái sang "Ngưng hoạt động"
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.TrangThai = N'Ngưng hoạt động'
        AND EXISTS (
            SELECT 1
            FROM SAN_PHAM sp
            JOIN CHI_TIET_DON_HANG ct ON sp.MaSP = ct.MaSP
            JOIN DON_HANG dh ON dh.MaDH = ct.MaDH
            WHERE sp.MaNB = i.MaNB
              AND dh.TrangThai NOT IN (N'Hoàn tất', N'Hủy')
        )
    )
    BEGIN
        PRINT (N'Không thể ngưng hoạt động: Shop vẫn còn đơn hàng chưa xử lý!');
        RETURN;
    END
END

/*NOTE: 
UPDATE NGUOI_BAN
SET TrangThai = N'Ngưng hoạt động'
WHERE MaNB = 1; */

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

--TRIGGER 5: Chỉ cho phép NVGH nghỉ việc khi không còn đang hàng nào "Đang giao" hay "Đang xử lý"
CREATE TRIGGER trg_NghiViecKhiKhongConDonDangGiao
ON NHAN_VIEN_GIAO_HANG
AFTER UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INSERTED I
        WHERE I.TrangThai = N'Nghỉ việc'
        AND EXISTS (
            SELECT 1
            FROM GIAO_HANG GH
            WHERE GH.MaNVGH = I.MaNVGH
              AND GH.TinhTrang IN (N'Đang giao', N'Chờ lấy hàng')
        )
    )
    BEGIN
        PRINT N'Lỗi: Nhân viên còn đơn hàng chưa hoàn tất. Không thể cho nghỉ việc.'
		ROLLBACK TRAN; --Có lỗi The transaction ended in the trigger. The batch has been aborted. Trigger chặn thêm dữ liệu
        RETURN;
    END
END
/*NOTE:
UPDATE NHAN_VIEN_GIAO_HANG
SET TrangThai = N'Đang hoạt động'
WHERE MaNVGH = 1;

UPDATE NHAN_VIEN_GIAO_HANG
SET TrangThai = N'Nghỉ việc'
WHERE MaNVGH = 1;*/

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

--TRIGGER 6: Không cho phép xoá KHACH_HANG nếu họ có đơn hàng liên quan
CREATE TRIGGER trg_PreventDeleteKhachHang
ON KHACH_HANG
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM DON_HANG dh
        JOIN DELETED d ON dh.MaKH = d.MaKH
    )
    BEGIN
        Print(N'Không thể xoá khách hàng vì đã có đơn hàng liên quan.');
        RETURN;
    END
end

/* NOTE: DELETE FROM KHACH_HANG WHERE MaKH = 1*/

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

--TRIGGER 7: Không cho cập nhật đơn hàng đã hoàn tất hoặc đã hủy
CREATE TRIGGER trg_KhongSuaDonHoanTatHoacHuy
ON DON_HANG
INSTEAD OF UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM INSERTED I
        JOIN DON_HANG D ON I.MaDH = D.MaDH
        WHERE D.TrangThai IN (N'Hoàn tất', N'Hủy')
    )
    BEGIN
        PRINT (N'Không thể cập nhật đơn hàng đã hoàn tất hoặc đã hủy.');
        RETURN;
    END

    -- Nếu không vi phạm, tiến hành cập nhật như bình thường
    UPDATE D
    SET
        D.NgayDat = I.NgayDat,
        D.TongTien = I.TongTien,
        D.TrangThai = I.TrangThai,
        D.SoDienThoaiNhan = I.SoDienThoaiNhan,
        D.NguoiNhan = I.NguoiNhan,
        D.DiaChiGiao = I.DiaChiGiao,
        D.MaKH = I.MaKH
    FROM DON_HANG D
    JOIN INSERTED I ON D.MaDH = I.MaDH;
END;

/* NOTE: 
UPDATE DON_HANG
SET NguoiNhan = N'Người nhận mới ( Ví dụ: Trịnh Trần Phương Tuấn )'
WHERE MaDH = 104;  -- Đơn đã "Hoàn tất" */

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

--TRIGGER 8: Tự động tăng độ phổ biến theo loại hàng
CREATE TRIGGER trg_TangDoPhoBien_LoaiHang
ON CHI_TIET_DON_HANG
AFTER INSERT
AS
BEGIN
    -- Cập nhật độ phổ biến cho loại hàng từ sản phẩm vừa thêm
    UPDATE LH
    SET LH.DoPhoBien = LH.DoPhoBien + SL.TongSL
    FROM LOAI_HANG LH
    JOIN (
        SELECT SP.MaLoai, SUM(I.SoLuong) AS TongSL
        FROM INSERTED I
        JOIN SAN_PHAM SP ON I.MaSP = SP.MaSP
        GROUP BY SP.MaLoai
    ) SL ON LH.MaLoai = SL.MaLoai;
END;
GO
/*NOTE
SELECT MaLoai, TenLoai, DoPhoBien FROM LOAI_HANG ORDER BY DoPhoBien DESC;
--Ví dụ thêm 2 tai nghe bluetooth (MaSP = 2, loại 2):
INSERT INTO CHI_TIET_DON_HANG (MaDH, MaSP, SoLuong, DonGia)
VALUES (105, 2, 2, 200000); 
SELECT MaLoai, TenLoai, DoPhoBien FROM LOAI_HANG ORDER BY DoPhoBien DESC; */

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

--TRIGGER 9: Khi giao hàng thất bại, nếu khách hàng có địa chỉ phụ, thì cập nhật DON_HANG.DiaChiGiao sang địa chỉ phụ
CREATE TRIGGER trg_ThuLaiDiaChiPhuNeuGiaoThatBai
ON GIAO_HANG
AFTER INSERT, UPDATE
AS
BEGIN
    -- Kiểm tra nếu giao hàng thất bại
    IF EXISTS (
        SELECT 1
        FROM INSERTED i
        JOIN DON_HANG dh ON i.MaDH = dh.MaDH
        JOIN KHACH_HANG kh ON kh.MaKH = dh.MaKH
        WHERE i.TinhTrang = N'Thất bại'
    )
    BEGIN
        UPDATE dh
        SET DiaChiGiao = dc.DiaChi
        FROM DON_HANG dh
        JOIN INSERTED i ON dh.MaDH = i.MaDH
        JOIN KHACH_HANG kh ON kh.MaKH = dh.MaKH
        JOIN DIA_CHI dc ON dc.MaKH = kh.MaKH
        WHERE i.TinhTrang = N'Thất bại'
          AND dc.MacDinh = 0; -- Địa chỉ phụ

        PRINT N'Địa chỉ giao hàng thất bại, đã chuyển sang địa chỉ phụ để thử lại.';
    END
END;

/*NOTE:
-- Giao thất bại đơn 101 (KH 1 có 2 địa chỉ)
UPDATE GIAO_HANG
SET TinhTrang = N'Thất bại'
WHERE MaDH = 101;

SELECT MaDH, DiaChiGiao FROM DON_HANG WHERE MaDH = 101;

UPDATE GIAO_HANG
SET TinhTrang = N'Đang giao'
WHERE MaDH = 101;
UPDATE DON_HANG
SET DiaChiGiao = N'100 Trần Hưng Đạo, Quận 1'
WHERE MaDH = 101; */

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

-- DÙNG CON TRỎ CURSOR ĐỂ TÍNH TỔNG DOANH THU 

DECLARE @MaKH INT;
DECLARE @HoTen NVARCHAR(100);
DECLARE @TongDoanhThu MONEY;

-- Cursor duyệt từng khách hàng
DECLARE csr_DoanhThuTheoKhachHang CURSOR FOR
SELECT MaKH, HoTen
FROM KHACH_HANG;

-- Mở cursor
OPEN csr_DoanhThuTheoKhachHang;

-- Lấy dòng đầu tiên
FETCH NEXT FROM csr_DoanhThuTheoKhachHang INTO @MaKH, @HoTen;

-- Duyệt từng khách hàng
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Tính tổng doanh thu từ đơn hàng
    SELECT @TongDoanhThu = SUM(TongTien)
    FROM DON_HANG
    WHERE MaKH = @MaKH;

    -- Nếu khách hàng có đơn hàng
    IF @TongDoanhThu IS NOT NULL
    BEGIN
        PRINT N'Khách hàng: ' + @HoTen + 
              N' | Mã KH: ' + CAST(@MaKH AS NVARCHAR) + 
              N' | Tổng doanh thu: ' + CAST(@TongDoanhThu AS NVARCHAR);
    END
    ELSE
    BEGIN
        PRINT N'Khách hàng: ' + @HoTen + 
              N' | Mã KH: ' + CAST(@MaKH AS NVARCHAR) + 
              N' | Tổng doanh thu: 0';
    END

    FETCH NEXT FROM csr_DoanhThuTheoKhachHang INTO @MaKH, @HoTen;
END

-- Đóng cursor
CLOSE csr_DoanhThuTheoKhachHang;
DEALLOCATE csr_DoanhThuTheoKhachHang;

/*NOTE ĐỂ TRUY VẤN
SELECT KH.MaKH, KH.HoTen, ISNULL(SUM(DH.TongTien), 0) AS TongDoanhThu
FROM KHACH_HANG KH
LEFT JOIN DON_HANG DH ON KH.MaKH = DH.MaKH
GROUP BY KH.MaKH, KH.HoTen; */
