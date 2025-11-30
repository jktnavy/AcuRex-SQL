CREATE OR ALTER PROCEDURE actuarial.sp_gpv_calc_manfaat_dan_pv
(
    @skenario_id BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UP                    DECIMAL(19,2);    -- uang pertanggungan
    DECLARE @i_bulanan             DECIMAL(18,10);   -- bunga bulanan
    DECLARE @masa_asuransi_bulan   INT;
    DECLARE @max_bulan             INT;
    DECLARE @bulan                 INT;

    DECLARE @dx                    DECIMAL(18,10);
    DECLARE @manfaat_kem           DECIMAL(19,3);
    DECLARE @pv_factor             DECIMAL(18,10);
    DECLARE @pv_manfaat            DECIMAL(19,3);
    DECLARE @pv_factor_prev        DECIMAL(18,10);
    DECLARE @pv_manfaat_prev       DECIMAL(19,3);
    DECLARE @tbd1                  DECIMAL(19,3);
    DECLARE @iuran                 DECIMAL(19,3);
    DECLARE @reas                  DECIMAL(19,3);
    DECLARE @manfaat_pd            DECIMAL(19,3);
    DECLARE @tbd2                  DECIMAL(19,3);

    -- variabel untuk cadangan_1 / CV
    DECLARE @inforce_now           DECIMAL(18,10);
    DECLARE @inforce_next          DECIMAL(18,10);
    DECLARE @cad1_next             DECIMAL(19,3);
    DECLARE @tbd2_next             DECIMAL(19,3);
    DECLARE @cad1_now              DECIMAL(19,3);
    DECLARE @tmp_cad               DECIMAL(19,10);

    ----------------------------------------------------------------
    -- Ambil parameter skenario: UP, masa_asuransi_bulan, i_bulanan
    ----------------------------------------------------------------
    SELECT 
        @UP                  = p.uang_pertanggungan,
        @masa_asuransi_bulan = p.masa_asuransi_bulan,
        @i_bulanan           = s.i_bulanan
    FROM actuarial.gpv_skenario_parameter p
    JOIN actuarial.gpv_skenario s
        ON s.skenario_id = p.skenario_id
    WHERE p.skenario_id = @skenario_id;

    IF @UP IS NULL OR @i_bulanan IS NULL OR @masa_asuransi_bulan IS NULL
    BEGIN
        RAISERROR(
            'sp_gpv_calc_manfaat_dan_pv: parameter UP / i_bulanan / masa_asuransi_bulan kosong untuk skenario_id %d.',
            16, 1, @skenario_id
        );
        RETURN;
    END;

    SELECT @max_bulan = MAX(bulan_polis_ke_)
    FROM actuarial.gpv_polis_grid
    WHERE skenario_id = @skenario_id;

    IF @max_bulan IS NULL
    BEGIN
        RAISERROR('sp_gpv_calc_manfaat_dan_pv: grid belum di-generate.', 16, 1);
        RETURN;
    END;

    -------------------------------------------------------------
    -- Reset kolom-kolom terkait (yang dihitung di prosedur ini)
    -------------------------------------------------------------
    UPDATE actuarial.gpv_polis_grid
    SET iuran_tabarru            = ISNULL(iuran_tabarru,0), -- sementara tetap 0
        kontribusi_reas          = ISNULL(kontribusi_reas,0),
        manfaat_kematian         = NULL,
        manfaat_pengunduran_diri = ISNULL(manfaat_pengunduran_diri,0),
        pv_interest              = NULL,
        pv_manfaat               = NULL,
        tbd_1                    = NULL,
        tbd_2                    = NULL,
        cadangan_1               = NULL,
        cv                       = NULL,
        cadangan_2               = NULL
    WHERE skenario_id = @skenario_id;

    -------------------------------------------------------------
    -- LOOP MAJU: Manfaat Kematian, PV, tbd_1, tbd_2
    -------------------------------------------------------------
    SET @bulan            = 1;
    SET @pv_factor_prev   = 0;
    SET @pv_manfaat_prev  = 0;

    WHILE @bulan <= @max_bulan
    BEGIN
        -- Ambil dx bulan ini
        SELECT @dx = ISNULL(dx, 0.0)
        FROM actuarial.gpv_polis_grid
        WHERE skenario_id      = @skenario_id
          AND bulan_polis_ke_  = @bulan;

        -- Manfaat kematian = -UP * dx  (risiko tetap faktor = 1)
        SET @manfaat_kem = CAST(-1.0 * @UP * @dx AS DECIMAL(19,3));

        -- PV Interest = 1 / (1 + i_bulanan)^bulan
        SET @pv_factor = CAST(1.0 / POWER(1.0 + @i_bulanan, @bulan) AS DECIMAL(18,10));

        -- PV Manfaat = manfaat_kem * pv_factor
        SET @pv_manfaat = CAST(@manfaat_kem * @pv_factor AS DECIMAL(19,3));

        -- tbd_1 = PV_manfaat_t - PV_manfaat_(t-1)
        SET @tbd1 = CAST(@pv_manfaat - @pv_manfaat_prev AS DECIMAL(19,3));

        -- tbd_2 = iuran + reas + manfaat_kematian + manfaat PD
        SELECT 
            @iuran      = ISNULL(iuran_tabarru, 0),
            @reas       = ISNULL(kontribusi_reas, 0),
            @manfaat_pd = ISNULL(manfaat_pengunduran_diri, 0)
        FROM actuarial.gpv_polis_grid
        WHERE skenario_id      = @skenario_id
          AND bulan_polis_ke_  = @bulan;

        SET @tbd2 = CAST(@iuran + @reas + @manfaat_kem + @manfaat_pd AS DECIMAL(19,3));

        -- Simpan ke grid
        UPDATE actuarial.gpv_polis_grid
        SET manfaat_kematian = @manfaat_kem,
            pv_interest      = @pv_factor,
            pv_manfaat       = @pv_manfaat,
            tbd_1            = @tbd1,
            tbd_2            = @tbd2
        WHERE skenario_id      = @skenario_id
          AND bulan_polis_ke_  = @bulan;

        -- Untuk iterasi berikutnya
        SET @pv_factor_prev   = @pv_factor;
        SET @pv_manfaat_prev  = @pv_manfaat;
        SET @bulan            = @bulan + 1;
    END;

    -------------------------------------------------------------
    -- LOOP MUNDUR: cadangan_1 (backward recursion)
    -- Excel: cadangan_1_t =
    --   IF(A16=0;0;
    --      IF(((Y17*I17 - X17)/(1 + i))/I16 < 0; 0;
    --         ((Y17*I17 - X17)/(1 + i))/I16 ))
    -------------------------------------------------------------
    SET @bulan = @max_bulan;

    WHILE @bulan >= 1
    BEGIN
        -- inforce sekarang (I16)
        SELECT @inforce_now = ISNULL(polis_inforce_akhir, 0.0)
        FROM actuarial.gpv_polis_grid
        WHERE skenario_id      = @skenario_id
          AND bulan_polis_ke_  = @bulan;

        -- nilai bulan berikutnya (Y17, I17, X17)
        SELECT
            @cad1_next    = ISNULL(cadangan_1, 0.0),
            @inforce_next = ISNULL(polis_inforce_akhir, 0.0),
            @tbd2_next    = ISNULL(tbd_2, 0.0)
        FROM actuarial.gpv_polis_grid
        WHERE skenario_id      = @skenario_id
          AND bulan_polis_ke_  = @bulan + 1;

        -- default kalau bulan terakhir (baris t+1 tidak ada) → nilainya 0
        IF @@ROWCOUNT = 0
        BEGIN
            SET @cad1_next    = 0.0;
            SET @inforce_next = 0.0;
            SET @tbd2_next    = 0.0;
        END;

        SET @cad1_now = 0;

        IF @inforce_now > 0
        BEGIN
            -- ((Y17 * I17 - X17) / (1 + i)) / I16
            SET @tmp_cad =
                ((@cad1_next * @inforce_next) - @tbd2_next)
                / (1.0 + @i_bulanan)
                / NULLIF(@inforce_now, 0.0);

            IF @tmp_cad < 0 SET @tmp_cad = 0;

            SET @cad1_now = CAST(@tmp_cad AS DECIMAL(19,3));
        END;

        UPDATE actuarial.gpv_polis_grid
        SET cadangan_1 = @cad1_now
        WHERE skenario_id      = @skenario_id
          AND bulan_polis_ke_  = @bulan;

        SET @bulan = @bulan - 1;
    END;

    -------------------------------------------------------------
    -- CV dan cadangan_2
    -- CV_t = (masa_asuransi_bulan - bulan_t) / masa_asuransi_bulan
    --        * (iuran_tabarru_t + kontribusi_reas_t)
    -- (untuk saat ini iuran_tabarru & kontribusi_reas masih 0 → CV = 0)
    -------------------------------------------------------------
    UPDATE g
    SET cv =
        CASE 
            WHEN g.bulan_polis_ke_ <= 0 THEN 0
            ELSE CAST(
                   ((@masa_asuransi_bulan - g.bulan_polis_ke_) * 1.0
                        / NULLIF(@masa_asuransi_bulan,0))
                   * (ISNULL(g.iuran_tabarru,0) + ISNULL(g.kontribusi_reas,0))
                 AS DECIMAL(19,3))
        END
    FROM actuarial.gpv_polis_grid AS g
    WHERE g.skenario_id = @skenario_id;

    -- cadangan_2 = MAX(cadangan_1, CV)
    UPDATE g
    SET cadangan_2 =
        CASE 
            WHEN ISNULL(g.cadangan_1,0) >= ISNULL(g.cv,0)
                THEN ISNULL(g.cadangan_1,0)
            ELSE ISNULL(g.cv,0)
        END
    FROM actuarial.gpv_polis_grid AS g
    WHERE g.skenario_id = @skenario_id;
END
GO
