-- how to running the store procedure

DECLARE @skenario_id BIGINT = (
    SELECT TOP(1) skenario_id 
    FROM actuarial.gpv_skenario 
    WHERE kode_skenario = 'GPV_PEMBIAYAAN_TETAP_10_SEP2023'
);

EXEC actuarial.sp_gpv_init_grid          @skenario_id;
EXEC actuarial.sp_gpv_calc_qx_lapse      @skenario_id;
EXEC actuarial.sp_gpv_calc_inforce_dx_dw @skenario_id;
EXEC actuarial.sp_gpv_calc_manfaat_dan_pv @skenario_id;
EXEC actuarial.sp_gpv_calc_premi_dan_cadangan @skenario_id;

SELECT 
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
    pv_manfaat,      -- ⚠️ sesuai permintaan: PV Manfaat dulu
    pv_interest,     -- lalu PV Interest
    tbd_1,
    tbd_2,
    cadangan_1,
    cv,
    cadangan_2
FROM actuarial.gpv_polis_grid
WHERE skenario_id = @skenario_id
ORDER BY bulan_polis_ke_;
