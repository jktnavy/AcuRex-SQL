CREATE OR ALTER PROCEDURE actuarial.sp_gpv_calc_manfaat_dan_pv
(
    @skenario_id BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UP           DECIMAL(19,2);   -- uang pertanggungan
    DECLARE @i_bulanan    DECIMAL(18,10);  -- bunga bulanan
    DECLARE @max_bulan    INT;
    DECLARE @bulan        INT;

    DECLARE @dx           DECIMAL(18,10);
    DECLARE @manfaat_kem  DECIMAL(19,3);
    DECLARE @pv_factor    DECIMAL(18,10);
    DECLARE @pv_factor_prev DECIMAL(18,10);
    DECLARE @pv_manfaat   DECIMAL(19,3);
    DECLARE @pv_manfaat_prev DECIMAL(19,3);
    DECLARE @tbd1         DECIMAL(19,3);
    DECLARE @iuran        DECIMAL(19,3);
    DECLARE @reas         DECIMAL(19,3);
    DECLARE @manfaat_pd   DECIMAL(19,3);
    DECLARE @tbd2         DECIMAL(19,3);

    -- 🔧 FIX: ambil UP dari gpv_skenario_parameter, i_bulanan dari gpv_skenario
    SELECT 
        @UP        = p.uang_pertanggungan,
        @i_bulanan = s.i_bulanan
    FROM actuarial.gpv_skenario_parameter p
    JOIN actuarial.gpv_skenario s
        ON s.skenario_id = p.skenario_id
    WHERE p.skenario_id = @skenario_id;

    IF @UP IS NULL OR @i_bulanan IS NULL
    BEGIN
        RAISERROR('sp_gpv_calc_manfaat_dan_pv: parameter UP atau i_bulanan kosong untuk skenario_id %d.', 16, 1, @skenario_id);
        RETURN;
    END

    SELECT @max_bulan = MAX(bulan_polis_ke_)
    FROM actuarial.gpv_polis_grid
    WHERE skenario_id = @skenario_id;

    IF @max_bulan IS NULL
    BEGIN
        RAISERROR('sp_gpv_calc_manfaat_dan_pv: grid belum di-generate.', 16, 1);
        RETURN;
    END

    -- Reset kolom-kolom terkait
    UPDATE actuarial.gpv_polis_grid
    SET iuran_tabarru            = 0,
        kontribusi_reas          = 0,
        manfaat_kematian         = NULL,
        manfaat_pengunduran_diri = 0,
        pv_interest              = NULL,
        pv_manfaat               = NULL,
        tbd_1                    = NULL,
        tbd_2                    = NULL
    WHERE skenario_id = @skenario_id;

    SET @bulan            = 1;
    SET @pv_factor_prev   = 0;
    SET @pv_manfaat_prev  = 0;

    WHILE @bulan <= @max_bulan
    BEGIN
        -- Ambil dx bulan ini
        SELECT @dx = ISNULL(dx, 0.0)
        FROM actuarial.gpv_polis_grid
        WHERE skenario_id = @skenario_id
          AND bulan_polis_ke_ = @bulan;

        -- Manfaat kematian = -UP * dx  (risiko tetap faktor = 1)
        SET @manfaat_kem = CAST(-1.0 * @UP * @dx AS DECIMAL(19,3));

        -- PV Interest = 1 / (1 + i_bulanan)^bulan
        SET @pv_factor = CAST(1.0 / POWER(1.0 + @i_bulanan, @bulan) AS DECIMAL(18,10));

        -- PV Manfaat
        SET @pv_manfaat = CAST(@manfaat_kem * @pv_factor AS DECIMAL(19,3));

        -- tbd_1 = PV_manfaat_t - PV_manfaat_(t-1)
        SET @tbd1 = CAST(@pv_manfaat - @pv_manfaat_prev AS DECIMAL(19,3));

        -- tbd_2 = J + K + L + M (untuk sekarang J,K,M = 0 -> tbd_2 = manfaat_kematian)
        SELECT 
            @iuran      = ISNULL(iuran_tabarru, 0),
            @reas       = ISNULL(kontribusi_reas, 0),
            @manfaat_pd = ISNULL(manfaat_pengunduran_diri, 0)
        FROM actuarial.gpv_polis_grid
        WHERE skenario_id = @skenario_id
          AND bulan_polis_ke_ = @bulan;

        SET @tbd2 = CAST(@iuran + @reas + @manfaat_kem + @manfaat_pd AS DECIMAL(19,3));

        -- Simpan
        UPDATE actuarial.gpv_polis_grid
        SET manfaat_kematian = @manfaat_kem,
            pv_interest      = @pv_factor,
            pv_manfaat       = @pv_manfaat,
            tbd_1            = @tbd1,
            tbd_2            = @tbd2
        WHERE skenario_id = @skenario_id
          AND bulan_polis_ke_ = @bulan;

        -- Untuk iterasi berikutnya
        SET @pv_factor_prev  = @pv_factor;
        SET @pv_manfaat_prev = @pv_manfaat;
        SET @bulan = @bulan + 1;
    END
END
GO
