CREATE OR ALTER PROCEDURE actuarial.sp_gpv_calc_qx_lapse
(
    @skenario_id BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;

    /* ============================================================
       1. Hitung qx bulanan dari mortalita tahunan
       ============================================================ */
    UPDATE g
    SET qx =
        CASE 
            WHEN ca.annual_rate IS NULL OR ca.annual_rate = 0 
                THEN 0
            ELSE CAST(1 - POWER(1 - ca.annual_rate, 1.0/12.0) AS DECIMAL(18,10))
        END
    FROM actuarial.gpv_polis_grid AS g
    JOIN actuarial.gpv_skenario AS s
        ON g.skenario_id = s.skenario_id
    JOIN actuarial.m_mortalita_detail AS md
        ON md.mortalita_id = s.mortalita_id
       AND md.usia         = g.usia
    CROSS APPLY (
        SELECT
            CASE 
                WHEN s.mortalita_tipe = 'pria'         THEN md.laki_laki
                WHEN s.mortalita_tipe = 'wanita'       THEN md.perempuan
                WHEN s.mortalita_tipe = 'unisex'       THEN md.unisex
                WHEN s.mortalita_tipe = 'reas-pria'    THEN md.reas_pria
                WHEN s.mortalita_tipe = 'reas-unisex'  THEN md.reas_unisex
                ELSE md.reas_unisex
            END AS base_rate
    ) AS r
    CROSS APPLY (
        SELECT r.base_rate * s.faktor_mortalita AS annual_rate
    ) AS ca
    WHERE g.skenario_id = @skenario_id;


    /* ============================================================
       2. Hitung Lapse Rate bulanan dari lapse annual
       ============================================================ */
    UPDATE g
    SET lapse_rate =
        CASE 
            WHEN ld.lapse_annual IS NULL OR ld.lapse_annual = 0 
                THEN 0
            ELSE CAST(1 - POWER(1 - ld.lapse_annual, 1.0/12.0) AS DECIMAL(18,10))
        END
    FROM actuarial.gpv_polis_grid AS g
    JOIN actuarial.gpv_skenario AS s
        ON g.skenario_id = s.skenario_id
    LEFT JOIN actuarial.m_lapse_pattern_detail AS ld
        ON ld.lapse_pattern_id = s.lapse_pattern_id
       AND ld.tahun_polis_ke   = g.tahun_polis_ke_
    WHERE g.skenario_id = @skenario_id;
END
GO
