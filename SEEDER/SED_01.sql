BEGIN TRAN;

DECLARE @produk_id INT;
DECLARE @mortalita_id INT;
DECLARE @lapse_pattern_id INT;
DECLARE @yield_curve_id INT;
DECLARE @risiko_tetap_id INT;
DECLARE @skenario_id BIGINT;


/* =====================================================================
   1. PRODUK & DEFAULT PARAMETER
   =====================================================================*/
INSERT INTO actuarial.m_produk (kode_produk, nama_produk, deskripsi)
VALUES ('JMA_PEMBIAYAAN_TETAP_10', 'JMA Pembiayaan Tetap Margin 10%', 'Contoh produk pembiayaan tetap margin 10%');

SET @produk_id = SCOPE_IDENTITY();

INSERT INTO actuarial.m_produk_parameter (
    produk_id,
    umur_masuk_default,
    masa_asuransi_bulan,
    uang_pertanggungan,
    tingkat_marjin_premi,
    quota_share_jmas,
    quota_share_reas,
    tabarru_rate_per_mille,
    tabarru_diskon,
    reas_rate_per_mille
)
VALUES (
    @produk_id,
    30,                 -- umur masuk default
    30,                 -- masa asuransi 30 bulan
    100000000.00,       -- UP 100 juta
    0.10,               -- 10%
    0.00,
    0.00,
    0.000000,           -- tabarru per mille (kalau ada isi disini)
    0.000000,           -- diskon tabarru
    0.000000            -- reas per mille
);


/* =====================================================================
   2. MORTALITA (TMI.3 REAS-UNISEX) - CONTOH USIA 30-32
   (Silakan lengkapi dengan usia 0-111 pakai script yang sudah Anda punya)
   =====================================================================*/
INSERT INTO actuarial.m_mortalita (kode_mortalita, deskripsi)
VALUES ('TMI3_REAS_UNISEX', 'TMI.3 reas-unisex (contoh)');

SET @mortalita_id = SCOPE_IDENTITY();

/* contoh data mortalita usia 30-32, diambil dari script Anda:
   (30, 0.00076, 0.00054), (31, 0.00080, 0.00057), (32, 0.00083, 0.00060)
   unisex = (laki+perempuan)/2, reas_pria= laki_laki, reas_unisex = unisex
*/
INSERT INTO actuarial.m_mortalita_detail (
    mortalita_id, usia, laki_laki, perempuan, unisex, reas_pria, reas_unisex
)
VALUES
    (@mortalita_id, 30, 0.00076, 0.00054, (0.00076 + 0.00054)/2.0, 0.00076, (0.00076 + 0.00054)/2.0),
    (@mortalita_id, 31, 0.00080, 0.00057, (0.00080 + 0.00057)/2.0, 0.00080, (0.00080 + 0.00057)/2.0),
    (@mortalita_id, 32, 0.00083, 0.00060, (0.00083 + 0.00060)/2.0, 0.00083, (0.00083 + 0.00060)/2.0);

/* >>> Di sini sebaiknya Anda lanjutkan sendiri INSERT untuk usia 0..111         <<<
   >>> pakai list TMI.3 yang sudah ada di script sebelumnya                      <<< */


/* =====================================================================
   3. LAPSE PATTERN 1% per tahun (tahun 1-5 dst)
   =====================================================================*/
INSERT INTO actuarial.m_lapse_pattern (nama_pattern)
VALUES ('LAPSE_1PCT_FLAT');

SET @lapse_pattern_id = SCOPE_IDENTITY();

INSERT INTO actuarial.m_lapse_pattern_detail (lapse_pattern_id, tahun_polis_ke, lapse_annual)
VALUES
    (@lapse_pattern_id, 1, 0.01),
    (@lapse_pattern_id, 2, 0.01),
    (@lapse_pattern_id, 3, 0.01),
    (@lapse_pattern_id, 4, 0.01),
    (@lapse_pattern_id, 5, 0.01);
/* kalau mau lebih detail bisa lanjut tahun 6,7,... */


/* =====================================================================
   4. YIELD CURVE (contoh: tenor 36 bulan rate 4.96%)
   =====================================================================*/
INSERT INTO actuarial.m_yield_curve (nama_curve, tanggal_efektif)
VALUES ('YIELD_SEP2023', '2023-09-30');

SET @yield_curve_id = SCOPE_IDENTITY();

INSERT INTO actuarial.m_yield_curve_detail (yield_curve_id, tenor_bulan, rate_tahunan)
VALUES
    (@yield_curve_id, 36, 0.049600);  -- 4.96%

/* kalau mau, tenor lain (12,24,60,...) bisa ditambah di sini */


/* =====================================================================
   5. RISIKO TETAP: faktor = 1000 untuk masa 3 tahun & 30 bulan
   (dari sheet Risiko Tetap yang isinya 1.000 untuk semua bulan)
   =====================================================================*/
INSERT INTO actuarial.m_risiko_tetap (nama_pattern)
VALUES ('RISIKO_TETAP_3THN');

SET @risiko_tetap_id = SCOPE_IDENTITY();

/* Isi faktor=1000 untuk bulan 1..30, masa_asuransi_thn=3 */
;WITH n AS (
    SELECT 1 AS i
    UNION ALL
    SELECT i + 1 FROM n WHERE i < 30
)
INSERT INTO actuarial.m_risiko_tetap_detail (
    risiko_tetap_id, bulan_polis_ke, masa_asuransi_thn, faktor
)
SELECT
    @risiko_tetap_id,
    i,
    3,          -- masa asuransi 3 tahun
    1000.000
FROM n
OPTION (MAXRECURSION 1000);


/* =====================================================================
   6. SKENARIO GPV (Pembiayaan Tetap 10%)
   =====================================================================*/
-- i_bulanan contoh: 0.0040422430 (4.042243%/bulan)
INSERT INTO actuarial.gpv_skenario (
    kode_skenario,
    produk_id,
    tanggal_valuasi,
    mortalita_id,
    mortalita_tipe,
    faktor_mortalita,
    lapse_pattern_id,
    yield_curve_id,
    risiko_tetap_id,
    i_bulanan
)
VALUES (
    'GPV_PEMBIAYAAN_TETAP_10_SEP2023',
    @produk_id,
    '2023-09-30',
    @mortalita_id,
    'reas-unisex',
    1.10,
    @lapse_pattern_id,
    @yield_curve_id,
    @risiko_tetap_id,
    0.0040422430
);

SET @skenario_id = SCOPE_IDENTITY();


/* =====================================================================
   7. PARAMETER PER SKENARIO
   =====================================================================*/
INSERT INTO actuarial.gpv_skenario_parameter (
    skenario_id,
    usia_masuk,
    masa_asuransi_bulan,
    uang_pertanggungan,
    quota_share_jmas,
    quota_share_reas,
    tabarru_rate_per_mille,
    tabarru_diskon,
    reas_rate_per_mille
)
VALUES (
    @skenario_id,
    30,
    30,
    100000000.00,   -- 100 juta
    0.00,
    0.00,
    0.000000,
    0.000000,
    0.000000
);


COMMIT TRAN;
-- Kalau mau test dulu, ganti COMMIT jadi ROLLBACK terlebih dahulu
