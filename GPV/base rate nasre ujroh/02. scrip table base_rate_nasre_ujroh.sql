USE [acurex_sql_db];
GO

/* Buat schema reference kalau belum ada */
IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'reference'
)
BEGIN
    EXEC('CREATE SCHEMA reference');
END
GO

/* MASTER: base_rate_nasre_ujroh
   Menyimpan info Ujroh %, range usia & jangka waktu (dinamis) */
IF OBJECT_ID('reference.base_rate_nasre_ujroh', 'U') IS NOT NULL
    DROP TABLE reference.base_rate_nasre_ujroh;
GO

CREATE TABLE reference.base_rate_nasre_ujroh (
    id                 BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    kode               VARCHAR(50)  NOT NULL,          -- contoh: NASRE_UJROH_12_5
    nama               VARCHAR(150) NOT NULL,          -- contoh: Base Rate Nasre Ujroh 12.5%
    ujroh_percent      DECIMAL(5,2) NOT NULL,          -- contoh: 12.50

    usia_min           TINYINT NOT NULL,               -- contoh: 0
    usia_max           TINYINT NOT NULL,               -- contoh: 80
    jangka_waktu_min   TINYINT NOT NULL,               -- contoh: 1  (tahun)
    jangka_waktu_max   TINYINT NOT NULL,               -- contoh: 15 (tahun)

    is_active          BIT      NOT NULL CONSTRAINT DF_base_rate_nasre_ujroh_is_active DEFAULT (1),

    created_at         DATETIME NOT NULL CONSTRAINT DF_base_rate_nasre_ujroh_created_at DEFAULT (GETDATE()),
    updated_at         DATETIME NULL,
    deleted_at         DATETIME NULL,
    created_by         BIGINT   NOT NULL,
    keterangan         VARCHAR(255) NULL
);
GO

/* Unique kode per produk Ujroh */
CREATE UNIQUE NONCLUSTERED INDEX IX_base_rate_nasre_ujroh_kode
    ON reference.base_rate_nasre_ujroh (kode)
    WHERE deleted_at IS NULL;
GO

/* DETAIL: base_rate_nasre_ujroh_detail
   Menyimpan nilai rate per kombinasi usia & jangka waktu
   Contoh: usia 17, JW 1 tahun, rate = 0.38 (dari Excel) */
IF OBJECT_ID('reference.base_rate_nasre_ujroh_detail', 'U') IS NOT NULL
    DROP TABLE reference.base_rate_nasre_ujroh_detail;
GO

CREATE TABLE reference.base_rate_nasre_ujroh_detail (
    id             BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    base_rate_id   BIGINT      NOT NULL,         -- FK ke master
    usia           TINYINT     NOT NULL,         -- dinamis, contoh: 0..80
    jangka_waktu   TINYINT     NOT NULL,         -- dinamis, contoh: 1..15
    rate           DECIMAL(10,2) NOT NULL,       -- nilai rate dari Excel

    created_at     DATETIME NOT NULL CONSTRAINT DF_base_rate_nasre_ujroh_detail_created_at DEFAULT (GETDATE()),
    updated_at     DATETIME NULL,
    deleted_at     DATETIME NULL,
    created_by     BIGINT   NOT NULL,
    keterangan     VARCHAR(255) NULL,

    CONSTRAINT FK_base_rate_nasre_ujroh_detail_master
        FOREIGN KEY (base_rate_id)
        REFERENCES reference.base_rate_nasre_ujroh (id)
);
GO

/* Kombinasi base_rate_id + usia + jangka_waktu harus unik (data aktif) */
CREATE UNIQUE NONCLUSTERED INDEX IX_base_rate_nasre_ujroh_detail_unique
    ON reference.base_rate_nasre_ujroh_detail (base_rate_id, usia, jangka_waktu)
    WHERE deleted_at IS NULL;
GO
