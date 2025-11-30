/* =====================================================================
   0. SCHEMA
   =====================================================================*/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'actuarial')
BEGIN
    EXEC ('CREATE SCHEMA actuarial');
END
GO


/* =====================================================================
   1. MASTER PRODUK
   =====================================================================*/
CREATE TABLE actuarial.m_produk (
    produk_id       INT IDENTITY(1,1) PRIMARY KEY,
    kode_produk     VARCHAR(50)    NOT NULL UNIQUE,
    nama_produk     NVARCHAR(100)  NOT NULL,
    deskripsi       NVARCHAR(255)  NULL
);
GO

CREATE TABLE actuarial.m_produk_parameter (
    produk_id               INT             NOT NULL PRIMARY KEY
                                REFERENCES actuarial.m_produk(produk_id),
    umur_masuk_default      TINYINT         NULL,
    masa_asuransi_bulan     SMALLINT        NULL,
    uang_pertanggungan      DECIMAL(19,2)   NULL,
    tingkat_marjin_premi    DECIMAL(18,6)   NULL,
    quota_share_jmas        DECIMAL(18,6)   NULL,
    quota_share_reas        DECIMAL(18,6)   NULL,
    tabarru_rate_per_mille  DECIMAL(18,6)   NULL,
    tabarru_diskon          DECIMAL(18,6)   NULL,
    reas_rate_per_mille     DECIMAL(18,6)   NULL
);
GO


/* =====================================================================
   2. MASTER MORTALITA (TMI.3)
   =====================================================================*/
CREATE TABLE actuarial.m_mortalita (
    mortalita_id    INT IDENTITY(1,1) PRIMARY KEY,
    kode_mortalita  VARCHAR(50)   NOT NULL UNIQUE,   -- ex: 'TMI3_REAS_UNISEX'
    deskripsi       NVARCHAR(255) NULL
);
GO

CREATE TABLE actuarial.m_mortalita_detail (
    mortalita_id INT            NOT NULL,
    usia         TINYINT        NOT NULL,            -- trot
    laki_laki    DECIMAL(18,10) NULL,
    perempuan    DECIMAL(18,10) NULL,
    unisex       DECIMAL(18,10) NULL,
    reas_pria    DECIMAL(18,10) NULL,
    reas_unisex  DECIMAL(18,10) NULL,
    CONSTRAINT PK_m_mortalita_detail
        PRIMARY KEY (mortalita_id, usia),
    CONSTRAINT FK_m_mortalita_detail_m_mortalita
        FOREIGN KEY (mortalita_id) REFERENCES actuarial.m_mortalita(mortalita_id)
);
GO


/* =====================================================================
   3. MASTER LAPSE
   =====================================================================*/
CREATE TABLE actuarial.m_lapse_pattern (
    lapse_pattern_id INT IDENTITY(1,1) PRIMARY KEY,
    nama_pattern     VARCHAR(100) NOT NULL
);
GO

CREATE TABLE actuarial.m_lapse_pattern_detail (
    lapse_pattern_id INT             NOT NULL,
    tahun_polis_ke   SMALLINT        NOT NULL,
    lapse_annual     DECIMAL(18,10)  NOT NULL,    -- 0.01 = 1% per tahun
    CONSTRAINT PK_m_lapse_pattern_detail
        PRIMARY KEY (lapse_pattern_id, tahun_polis_ke),
    CONSTRAINT FK_m_lapse_pattern_detail_m_lapse_pattern
        FOREIGN KEY (lapse_pattern_id) REFERENCES actuarial.m_lapse_pattern(lapse_pattern_id)
);
GO


/* =====================================================================
   4. MASTER YIELD CURVE
   =====================================================================*/
CREATE TABLE actuarial.m_yield_curve (
    yield_curve_id   INT IDENTITY(1,1) PRIMARY KEY,
    nama_curve       VARCHAR(100) NOT NULL,
    tanggal_efektif  DATE         NOT NULL
);
GO

CREATE TABLE actuarial.m_yield_curve_detail (
    yield_curve_id  INT             NOT NULL,
    tenor_bulan     SMALLINT        NOT NULL,
    rate_tahunan    DECIMAL(18,10)  NOT NULL,    -- 0.049600 = 4.96%
    CONSTRAINT PK_m_yield_curve_detail
        PRIMARY KEY (yield_curve_id, tenor_bulan),
    CONSTRAINT FK_m_yield_curve_detail_m_yield_curve
        FOREIGN KEY (yield_curve_id) REFERENCES actuarial.m_yield_curve(yield_curve_id)
);
GO


/* =====================================================================
   5. MASTER RISIKO TETAP (MATRIX 1.000)
   =====================================================================*/
CREATE TABLE actuarial.m_risiko_tetap (
    risiko_tetap_id INT IDENTITY(1,1) PRIMARY KEY,
    nama_pattern    VARCHAR(100) NOT NULL
);
GO

CREATE TABLE actuarial.m_risiko_tetap_detail (
    risiko_tetap_id     INT             NOT NULL,
    bulan_polis_ke      SMALLINT        NOT NULL,
    masa_asuransi_thn   SMALLINT        NOT NULL,
    faktor              DECIMAL(18,6)   NOT NULL,   -- 1000.000
    CONSTRAINT PK_m_risiko_tetap_detail
        PRIMARY KEY (risiko_tetap_id, bulan_polis_ke, masa_asuransi_thn),
    CONSTRAINT FK_m_risiko_tetap_detail_m_risiko_tetap
        FOREIGN KEY (risiko_tetap_id) REFERENCES actuarial.m_risiko_tetap(risiko_tetap_id)
);
GO


/* =====================================================================
   6. HEADER SKENARIO GPV
   =====================================================================*/
CREATE TABLE actuarial.gpv_skenario (
    skenario_id         BIGINT IDENTITY(1,1) PRIMARY KEY,
    kode_skenario       VARCHAR(50)   NOT NULL UNIQUE,
    produk_id           INT           NOT NULL
        REFERENCES actuarial.m_produk(produk_id),
    tanggal_valuasi     DATE          NOT NULL,

    mortalita_id        INT           NOT NULL
        REFERENCES actuarial.m_mortalita(mortalita_id),
    mortalita_tipe      VARCHAR(50)   NOT NULL,    -- 'reas-unisex', 'unisex', dll
    faktor_mortalita    DECIMAL(18,6) NOT NULL,    -- 1.10

    lapse_pattern_id    INT           NOT NULL
        REFERENCES actuarial.m_lapse_pattern(lapse_pattern_id),
    yield_curve_id      INT           NOT NULL
        REFERENCES actuarial.m_yield_curve(yield_curve_id),
    risiko_tetap_id     INT           NOT NULL
        REFERENCES actuarial.m_risiko_tetap(risiko_tetap_id),

    i_bulanan           DECIMAL(18,10) NOT NULL,   -- 0.0040422430
    created_at          DATETIME2(3)   NOT NULL DEFAULT SYSUTCDATETIME()
);
GO


/* =====================================================================
   7. PARAMETER PER SKENARIO
   =====================================================================*/
CREATE TABLE actuarial.gpv_skenario_parameter (
    skenario_id             BIGINT         NOT NULL PRIMARY KEY
        REFERENCES actuarial.gpv_skenario(skenario_id),

    usia_masuk              TINYINT        NOT NULL,
    masa_asuransi_bulan     SMALLINT       NOT NULL,
    uang_pertanggungan      DECIMAL(19,2)  NOT NULL,

    quota_share_jmas        DECIMAL(18,6)  NULL,
    quota_share_reas        DECIMAL(18,6)  NULL,
    tabarru_rate_per_mille  DECIMAL(18,6)  NULL,
    tabarru_diskon          DECIMAL(18,6)  NULL,
    reas_rate_per_mille     DECIMAL(18,6)  NULL
);
GO


/* =====================================================================
   8. GRID HASIL BULANAN (MATCH EXCEL)
   =====================================================================*/
CREATE TABLE actuarial.gpv_polis_grid (
    skenario_id             BIGINT         NOT NULL
        REFERENCES actuarial.gpv_skenario(skenario_id),

    bulan_polis_ke_         SMALLINT       NOT NULL,   -- Bulan Polis Ke-
    tahun_polis_ke_         SMALLINT       NOT NULL,
    usia                    TINYINT        NOT NULL,

    qx                      DECIMAL(18,10) NULL,
    lapse_rate              DECIMAL(18,10) NULL,

    dx                      DECIMAL(18,10) NULL,
    dw                      DECIMAL(18,10) NULL,

    polis_inforce_awal      DECIMAL(18,10) NULL,
    polis_inforce_akhir     DECIMAL(18,10) NULL,

    iuran_tabarru           DECIMAL(19,3)  NULL,
    kontribusi_reas         DECIMAL(19,3)  NULL,

    manfaat_kematian        DECIMAL(19,3)  NULL,
    manfaat_pengunduran_diri DECIMAL(19,3) NULL,

    cadangan                DECIMAL(19,3)  NULL,
    kenaikan_cadangan       DECIMAL(19,3)  NULL,
    surplus_underwriting    DECIMAL(19,3)  NULL,

    dana_tabarru            DECIMAL(19,3)  NULL,
    peserta                 DECIMAL(19,3)  NULL,
    pengelola               DECIMAL(19,3)  NULL,

    pv_manfaat              DECIMAL(19,3)  NULL,
    pv_interest             DECIMAL(18,10) NULL,

    tbd_1                   DECIMAL(19,3)  NULL,
    tbd_2                   DECIMAL(19,3)  NULL,

    cadangan_1              DECIMAL(19,3)  NULL,
    cv                      DECIMAL(19,3)  NULL,
    cadangan_2              DECIMAL(19,3)  NULL,

    CONSTRAINT PK_gpv_polis_grid
        PRIMARY KEY (skenario_id, bulan_polis_ke_)
);
GO







-- Pastikan kolom-kolom probabilitas & inforce pakai presisi tinggi
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN qx                  DECIMAL(18,10) NULL;
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN lapse_rate          DECIMAL(18,10) NULL;
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN dx                  DECIMAL(18,10) NULL;
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN dw                  DECIMAL(18,10) NULL;
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN polis_inforce_awal  DECIMAL(18,10) NULL;
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN polis_inforce_akhir DECIMAL(18,10) NULL;

-- Kolom rupiah: pakai 3 angka di belakang koma (sesuai kebutuhan Anda)
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN iuran_tabarru           DECIMAL(19,3) NULL;
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN kontribusi_reas         DECIMAL(19,3) NULL;
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN manfaat_kematian        DECIMAL(19,3) NULL;
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN manfaat_pengunduran_diri DECIMAL(19,3) NULL;
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN cadangan               DECIMAL(19,3) NULL;
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN kenaikan_cadangan      DECIMAL(19,3) NULL;
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN surplus_underwriting   DECIMAL(19,3) NULL;
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN dana_tabarru           DECIMAL(19,3) NULL;
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN peserta                DECIMAL(19,3) NULL;
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN pengelola              DECIMAL(19,3) NULL;
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN pv_manfaat             DECIMAL(19,3) NULL;
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN pv_interest            DECIMAL(19,10) NULL; -- faktor diskonto, kecil tapi presisi
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN tbd_1                  DECIMAL(19,3) NULL;
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN tbd_2                  DECIMAL(19,3) NULL;
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN cadangan_1             DECIMAL(19,3) NULL;
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN cv                     DECIMAL(19,3) NULL;
ALTER TABLE actuarial.gpv_polis_grid ALTER COLUMN cadangan_2             DECIMAL(19,3) NULL;
