CREATE OR ALTER PROCEDURE actuarial.sp_gpv_init_grid
(
    @skenario_id BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @masa_asuransi_bulan SMALLINT;
    DECLARE @usia_masuk          TINYINT;

    -- Ambil parameter skenario
    SELECT 
        @masa_asuransi_bulan = p.masa_asuransi_bulan,
        @usia_masuk          = p.usia_masuk
    FROM actuarial.gpv_skenario_parameter p
    WHERE p.skenario_id = @skenario_id;

    IF @masa_asuransi_bulan IS NULL OR @usia_masuk IS NULL
    BEGIN
        RAISERROR(
            'sp_gpv_init_grid: Parameter skenario_id %d tidak ditemukan di gpv_skenario_parameter.',
            16, 1, @skenario_id
        );
        RETURN;
    END

    -- Bersihkan grid jika sudah pernah di-generate
    DELETE FROM actuarial.gpv_polis_grid
    WHERE skenario_id = @skenario_id;

    ;WITH n AS (
        SELECT 1 AS bulan_polis_ke_
        UNION ALL
        SELECT bulan_polis_ke_ + 1
        FROM n
        WHERE bulan_polis_ke_ < @masa_asuransi_bulan
    )
    INSERT INTO actuarial.gpv_polis_grid (
        skenario_id,
        bulan_polis_ke_,
        tahun_polis_ke_,
        usia,
        qx,
        lapse_rate,
        dx,
        dw,
        polis_inforce_awal,
        polis_inforce_akhir,
        iuran_tabarru,
        kontribusi_reas,
        manfaat_kematian,
        manfaat_pengunduran_diri,
        cadangan,
        kenaikan_cadangan,
        surplus_underwriting,
        dana_tabarru,
        peserta,
        pengelola,
        pv_manfaat,
        pv_interest,
        tbd_1,
        tbd_2,
        cadangan_1,
        cv,
        cadangan_2
    )
    SELECT
        @skenario_id                                        AS skenario_id,
        n.bulan_polis_ke_                                   AS bulan_polis_ke_,
        CEILING(n.bulan_polis_ke_ / 12.0)                   AS tahun_polis_ke_,
        @usia_masuk + CEILING(n.bulan_polis_ke_ / 12.0) - 1 AS usia,
        NULL,   -- qx
        NULL,   -- lapse_rate
        NULL,   -- dx
        NULL,   -- dw
        NULL,   -- polis_inforce_awal
        NULL,   -- polis_inforce_akhir
        NULL,   -- iuran_tabarru
        NULL,   -- kontribusi_reas
        NULL,   -- manfaat_kematian
        NULL,   -- manfaat_pengunduran_diri
        NULL,   -- cadangan
        NULL,   -- kenaikan_cadangan
        NULL,   -- surplus_underwriting
        NULL,   -- dana_tabarru
        NULL,   -- peserta
        NULL,   -- pengelola
        NULL,   -- pv_manfaat
        NULL,   -- pv_interest
        NULL,   -- tbd_1
        NULL,   -- tbd_2
        NULL,   -- cadangan_1
        NULL,   -- cv
        NULL    -- cadangan_2
    FROM n
    OPTION (MAXRECURSION 1000);
END
GO
