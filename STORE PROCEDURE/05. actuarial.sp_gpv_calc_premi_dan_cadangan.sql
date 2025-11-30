CREATE OR ALTER PROCEDURE actuarial.sp_gpv_calc_premi_dan_cadangan
(
    @skenario_id BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;

    ----------------------------------------------------------------
    -- 1. Ambil parameter skenario dari gpv_skenario_parameter
    ----------------------------------------------------------------
    DECLARE @UP                    DECIMAL(19,2);    -- uang pertanggungan
    DECLARE @masa_asuransi_bulan   INT;
    DECLARE @tabarru_rate_per_mille DECIMAL(18,10);
    DECLARE @tabarru_diskon        DECIMAL(18,10);
    DECLARE @reas_rate_per_mille   DECIMAL(18,10);

    -- faktor manfaat pengunduran diri (L4 di Excel)
    DECLARE @faktor_pd             DECIMAL(18,10) = 0.0;   

    SELECT
        @UP                     = p.uang_pertanggungan,
        @masa_asuransi_bulan    = p.masa_asuransi_bulan,
        @tabarru_rate_per_mille = p.tabarru_rate_per_mille,
        @tabarru_diskon         = p.tabarru_diskon,
        @reas_rate_per_mille    = p.reas_rate_per_mille
    FROM actuarial.gpv_skenario_parameter p
    WHERE p.skenario_id = @skenario_id;

    IF @UP IS NULL OR @masa_asuransi_bulan IS NULL
    BEGIN
        RAISERROR('sp_gpv_calc_premi_dan_cadangan: parameter skenario_id %d tidak lengkap.', 16, 1, @skenario_id);
        RETURN;
    END

    ----------------------------------------------------------------
    -- 2. Siapkan loop bulan & reset kolom-kolom terkait
    ----------------------------------------------------------------
    DECLARE @max_bulan INT;
    SELECT @max_bulan = MAX(bulan_polis_ke_)
    FROM actuarial.gpv_polis_grid
    WHERE skenario_id = @skenario_id;

    IF @max_bulan IS NULL
    BEGIN
        RAISERROR('sp_gpv_calc_premi_dan_cadangan: grid belum di-generate untuk skenario_id %d.', 16, 1, @skenario_id);
        RETURN;
    END

    UPDATE actuarial.gpv_polis_grid
    SET iuran_tabarru            = 0,
        kontribusi_reas          = 0,
        manfaat_pengunduran_diri = 0,
        cadangan                 = NULL,
        kenaikan_cadangan        = NULL,
        surplus_underwriting     = 0,
        dana_tabarru             = 0,
        peserta                  = 0,
        pengelola                = 0
    WHERE skenario_id = @skenario_id;

    ----------------------------------------------------------------
    -- 3. Loop pertama: Iuran Tabarru, Reas, Manfaat PD, Cadangan, Kenaikan
    ----------------------------------------------------------------
    DECLARE @bulan            INT = 1;
    DECLARE @dx               DECIMAL(18,10);
    DECLARE @dw               DECIMAL(18,10);
    DECLARE @inforce_akhir    DECIMAL(18,10);
    DECLARE @cadangan1        DECIMAL(19,6);
    DECLARE @cadangan_total   DECIMAL(19,3);
    DECLARE @cadangan_prev    DECIMAL(19,3) = 0;
    DECLARE @kenaikan         DECIMAL(19,3);
    DECLARE @iuran            DECIMAL(19,3);
    DECLARE @reas             DECIMAL(19,3);
    DECLARE @manfaat_pd       DECIMAL(19,3);

    WHILE @bulan <= @max_bulan
    BEGIN
        SELECT 
            @dx            = ISNULL(dx, 0),
            @dw            = ISNULL(dw, 0),
            @inforce_akhir = ISNULL(polis_inforce_akhir, 0),
            @cadangan1     = ISNULL(cadangan_1, 0)
        FROM actuarial.gpv_polis_grid
        WHERE skenario_id = @skenario_id
          AND bulan_polis_ke_ = @bulan;

        -- Iuran Tabarru' (bulan 1 saja)
        IF @bulan = 1
        BEGIN
            SET @iuran = ROUND(
                  (@UP * @tabarru_rate_per_mille / 1000.0)
                * (1.0 - ISNULL(@tabarru_diskon,0.0))
            , 3);
        END
        ELSE
        BEGIN
            SET @iuran = 0;
        END

        -- Kontribusi Reas: bulan 1 = 0, sisanya -UP * reas_rate/1000
        IF @bulan <= 1
        BEGIN
            SET @reas = 0;
        END
        ELSE
        BEGIN
            SET @reas = ROUND(
                -1.0 * @UP * ISNULL(@reas_rate_per_mille,0.0) / 1000.0
            , 3);
        END

        -- Manfaat Pengunduran Diri
        IF @bulan = 0
           OR @masa_asuransi_bulan = 0
           OR @dw = 0
           OR @iuran = 0
           OR @faktor_pd = 0
        BEGIN
            SET @manfaat_pd = 0;
        END
        ELSE
        BEGIN
            -- L4 * -J16 * (Term - bulan)/Term * dw
            SET @manfaat_pd = ROUND(
                  @faktor_pd
                * (-1.0 * @iuran)
                * (@masa_asuransi_bulan - @bulan) / CAST(@masa_asuransi_bulan AS DECIMAL(18,10))
                * @dw
            , 3);
        END

        -- Cadangan total = cadangan_1 * polis_inforce_akhir
        IF @bulan = 0
        BEGIN
            SET @cadangan_total = 0;
        END
        ELSE
        BEGIN
            SET @cadangan_total = ROUND(
                @cadangan1 * @inforce_akhir
            , 3);
        END

        -- Kenaikan Cadangan = cad_prev - cad_ sekarang
        SET @kenaikan = ROUND(@cadangan_prev - @cadangan_total, 3);

        UPDATE actuarial.gpv_polis_grid
        SET iuran_tabarru            = @iuran,
            kontribusi_reas          = @reas,
            manfaat_pengunduran_diri = @manfaat_pd,
            cadangan                 = @cadangan_total,
            kenaikan_cadangan        = @kenaikan
        WHERE skenario_id = @skenario_id
          AND bulan_polis_ke_ = @bulan;

        SET @cadangan_prev = @cadangan_total;
        SET @bulan = @bulan + 1;
    END

    ----------------------------------------------------------------
    -- 4. Loop kedua: Surplus Underwriting + Dana/Peserta/Pengelola
    ----------------------------------------------------------------
    DECLARE @m                INT = 1;
    DECLARE @monthly_contrib  DECIMAL(19,3);
    DECLARE @surplus          DECIMAL(19,3);
    DECLARE @from_bulan       INT;
    DECLARE @to_bulan         INT;
    DECLARE @sum_contrib      DECIMAL(19,3);
    DECLARE @cad_before       DECIMAL(19,3);
    DECLARE @cad_after        DECIMAL(19,3);
    DECLARE @manfaat_kem      DECIMAL(19,3);   -- NEW: perbaikan

    SET @m = 1;
    WHILE @m <= @max_bulan
    BEGIN
        SELECT 
            @iuran       = ISNULL(iuran_tabarru, 0),
            @manfaat_kem = ISNULL(manfaat_kematian, 0),
            @manfaat_pd  = ISNULL(manfaat_pengunduran_diri, 0),
            @kenaikan    = ISNULL(kenaikan_cadangan, 0)
        FROM actuarial.gpv_polis_grid
        WHERE skenario_id = @skenario_id
          AND bulan_polis_ke_ = @m;

        SET @monthly_contrib = @iuran + @manfaat_kem + @manfaat_pd + @kenaikan;

        IF @m < 12
        BEGIN
            SET @surplus = 0;
        END
        ELSE
        BEGIN
            IF (@m % 12) = 1
            BEGIN
                SET @from_bulan = @m;
                SET @to_bulan   = CASE 
                                    WHEN @m + 11 > @max_bulan THEN @max_bulan 
                                    ELSE @m + 11 
                                  END;

                SELECT 
                    @sum_contrib = ISNULL(SUM(
                        iuran_tabarru 
                      + manfaat_kematian 
                      + manfaat_pengunduran_diri 
                      + kenaikan_cadangan
                    ), 0)
                FROM actuarial.gpv_polis_grid
                WHERE skenario_id     = @skenario_id
                  AND bulan_polis_ke_ BETWEEN @from_bulan AND @to_bulan;

                SELECT @cad_before = ISNULL(cadangan, 0)
                FROM actuarial.gpv_polis_grid
                WHERE skenario_id = @skenario_id
                  AND bulan_polis_ke_ = @from_bulan - 1;

                IF @from_bulan = 1
                    SET @cad_before = 0;

                SELECT @cad_after = ISNULL(cadangan, 0)
                FROM actuarial.gpv_polis_grid
                WHERE skenario_id = @skenario_id
                  AND bulan_polis_ke_ = @to_bulan;

                SET @surplus = ROUND(@sum_contrib + @cad_before - @cad_after, 3);
            END
            ELSE
            BEGIN
                SET @surplus = ROUND(@monthly_contrib, 3);
            END
        END

        UPDATE actuarial.gpv_polis_grid
        SET surplus_underwriting = @surplus,
            dana_tabarru         = ROUND(@surplus * 0.40, 3),
            peserta              = ROUND(@surplus * 0.30, 3),
            pengelola            = ROUND(@surplus * 0.30, 3)
        WHERE skenario_id = @skenario_id
          AND bulan_polis_ke_ = @m;

        SET @m = @m + 1;
    END
END
GO
