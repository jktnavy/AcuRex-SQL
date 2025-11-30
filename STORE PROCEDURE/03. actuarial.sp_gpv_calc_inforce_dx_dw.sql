CREATE OR ALTER PROCEDURE actuarial.sp_gpv_calc_inforce_dx_dw
(
    @skenario_id BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @masa_asuransi_bulan SMALLINT;
    DECLARE @bulan SMALLINT;
    DECLARE @max_bulan SMALLINT;

    DECLARE @inforce_awal  DECIMAL(18,10);
    DECLARE @qx            DECIMAL(18,10);
    DECLARE @lapse         DECIMAL(18,10);
    DECLARE @dx            DECIMAL(18,10);
    DECLARE @dw            DECIMAL(18,10);
    DECLARE @inforce_akhir DECIMAL(18,10);

    -- Ambil masa asuransi
    SELECT @masa_asuransi_bulan = masa_asuransi_bulan
    FROM actuarial.gpv_skenario_parameter
    WHERE skenario_id = @skenario_id;

    IF @masa_asuransi_bulan IS NULL
    BEGIN
        RAISERROR('sp_gpv_calc_inforce_dx_dw: skenario_id %d tidak punya parameter.', 16, 1, @skenario_id);
        RETURN;
    END

    SELECT @max_bulan = MAX(bulan_polis_ke_)
    FROM actuarial.gpv_polis_grid
    WHERE skenario_id = @skenario_id;

    IF @max_bulan IS NULL
    BEGIN
        RAISERROR('sp_gpv_calc_inforce_dx_dw: grid belum di-generate untuk skenario_id %d.', 16, 1, @skenario_id);
        RETURN;
    END

    -- Reset kolom terkait dulu (optional)
    UPDATE actuarial.gpv_polis_grid
    SET polis_inforce_awal  = NULL,
        polis_inforce_akhir = NULL,
        dx = NULL,
        dw = NULL
    WHERE skenario_id = @skenario_id;

    SET @bulan = 1;
    SET @inforce_awal = 1.0;      -- sesuai Excel: bulan polis ke-1 dan tahun ke-1 = 1 polis

    WHILE @bulan <= @max_bulan
    BEGIN
        -- Ambil qx dan lapse_rate baris ini
        SELECT 
            @qx    = ISNULL(qx, 0),
            @lapse = ISNULL(lapse_rate, 0)
        FROM actuarial.gpv_polis_grid
        WHERE skenario_id = @skenario_id
          AND bulan_polis_ke_ = @bulan;

        -- Hitung dx, dw, inforce akhir
        SET @dx = @qx * @inforce_awal;
        SET @dw = @lapse * @inforce_awal;
        SET @inforce_akhir = @inforce_awal - @dx - @dw;

        -- Simpan ke tabel
        UPDATE actuarial.gpv_polis_grid
        SET polis_inforce_awal  = @inforce_awal,
            dx                  = @dx,
            dw                  = @dw,
            polis_inforce_akhir = @inforce_akhir
        WHERE skenario_id = @skenario_id
          AND bulan_polis_ke_ = @bulan;

        -- Persiapan ke bulan berikutnya
        SET @inforce_awal = @inforce_akhir;
        SET @bulan = @bulan + 1;
    END
END
GO
