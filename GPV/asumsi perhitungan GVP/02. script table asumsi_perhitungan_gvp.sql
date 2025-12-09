USE [acurex_sql_db];
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'reference')
BEGIN
    EXEC('CREATE SCHEMA reference');
END;
GO

/* MASTER: Asumsi Perhitungan GPV (REVISI FAKTOR PENGALI) */
IF OBJECT_ID('reference.asumsi_perhitungan_gpv', 'U') IS NOT NULL
BEGIN
    DROP TABLE reference.asumsi_perhitungan_gpv;
END;
GO

CREATE TABLE [reference].[asumsi_perhitungan_gpv] (
    [id]                         BIGINT IDENTITY(1,1) NOT NULL,
    [kode]                       VARCHAR(50) NOT NULL,
    [nama]                       VARCHAR(150) NOT NULL,
    [jenis_mortalita]            VARCHAR(20) NOT NULL,
    [rate_asumsi_gpv]            DECIMAL(9,4) NOT NULL, -- persen: 0–100 (mis: 5.00 = 5%)
    [faktor_pengali_mortalita]   AS (
        CONVERT(DECIMAL(9,4), 100.0 + [rate_asumsi_gpv])
    ) PERSISTED,
    [faktor_pengali_mortalita_reas] AS (
        CONVERT(DECIMAL(9,4), 100.0 + [rate_asumsi_gpv])
    ) PERSISTED,
    [is_aktif]                   BIT NOT NULL CONSTRAINT [DF_asumsi_perhitungan_gpv_is_aktif] DEFAULT (1),

    [created_at]                 DATETIME NOT NULL CONSTRAINT [DF_asumsi_perhitungan_gpv_created_at] DEFAULT (GETDATE()),
    [updated_at]                 DATETIME NULL,
    [deleted_at]                 DATETIME NULL,
    [created_by]                 BIGINT NOT NULL,
    [keterangan]                 VARCHAR(255) NULL,

    CONSTRAINT [PK_asumsi_perhitungan_gpv] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [UQ_asumsi_perhitungan_gpv_kode] UNIQUE ([kode]),
    CONSTRAINT [CK_asumsi_perhitungan_gpv_jenis_mortalita]
        CHECK ([jenis_mortalita] IN ('Pria', 'Unisex', 'Reas-Pria', 'Reas-Unisex')),
    CONSTRAINT [CK_asumsi_perhitungan_gpv_rate_asumsi_gpv]
        CHECK ([rate_asumsi_gpv] >= 0 AND [rate_asumsi_gpv] <= 100)
);
GO

CREATE NONCLUSTERED INDEX [IX_asumsi_perhitungan_gpv_jenis_aktif]
    ON [reference].[asumsi_perhitungan_gpv] ([jenis_mortalita], [is_aktif]);
GO

/* DETAIL TETAP SAMA (tidak berubah) */
IF OBJECT_ID('reference.asumsi_perhitungan_gpv_lapse_rate', 'U') IS NOT NULL
BEGIN
    DROP TABLE reference.asumsi_perhitungan_gpv_lapse_rate;
END;
GO

CREATE TABLE [reference].[asumsi_perhitungan_gpv_lapse_rate] (
    [id]                          BIGINT IDENTITY(1,1) NOT NULL,
    [asumsi_perhitungan_gpv_id]   BIGINT NOT NULL,
    [tahun_ke]                    INT NOT NULL,
    [is_berlaku_seterusnya]       BIT NOT NULL CONSTRAINT [DF_asumsi_gpv_lapse_is_berlaku_seterusnya] DEFAULT (0),
    [lapse_rate]                  DECIMAL(9,4) NOT NULL, -- persen: 0–100

    [created_at]                  DATETIME NOT NULL CONSTRAINT [DF_asumsi_gpv_lapse_created_at] DEFAULT (GETDATE()),
    [updated_at]                  DATETIME NULL,
    [deleted_at]                  DATETIME NULL,
    [created_by]                  BIGINT NOT NULL,
    [keterangan]                  VARCHAR(255) NULL,

    CONSTRAINT [PK_asumsi_perhitungan_gpv_lapse_rate] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK_asumsi_perhitungan_gpv_lapse_rate_master]
        FOREIGN KEY ([asumsi_perhitungan_gpv_id])
        REFERENCES [reference].[asumsi_perhitungan_gpv]([id]),
    CONSTRAINT [UQ_asumsi_gpv_lapse_master_tahun]
        UNIQUE ([asumsi_perhitungan_gpv_id], [tahun_ke]),
    CONSTRAINT [CK_asumsi_gpv_lapse_tahun]
        CHECK ([tahun_ke] >= 1),
    CONSTRAINT [CK_asumsi_gpv_lapse_rate]
        CHECK ([lapse_rate] >= 0 AND [lapse_rate] <= 100)
);
GO

CREATE NONCLUSTERED INDEX [IX_asumsi_gpv_lapse_master_tahun]
    ON [reference].[asumsi_perhitungan_gpv_lapse_rate] ([asumsi_perhitungan_gpv_id], [tahun_ke]);
GO

/* SEED CONTOH: APGPV5
   - Rate Asumsi GPV = 5.00
   - Faktor Pengali Mortalita = 105.00 (105,00%)
   - Faktor Pengali Mortalita Reas = 105.00 (105,00%)
*/
DECLARE @AsumsiId BIGINT;

INSERT INTO [reference].[asumsi_perhitungan_gpv] (
    [kode],
    [nama],
    [jenis_mortalita],
    [rate_asumsi_gpv],
    [is_aktif],
    [created_at],
    [created_by],
    [keterangan]
)
VALUES (
    'APGPV5',
    'Asumsi Perhitungan GPV 5%',
    'Unisex',
    5.00,
    1,
    GETDATE(),
    1,
    'Seed contoh asumsi GPV 5%'
);

SET @AsumsiId = SCOPE_IDENTITY();

/* Lapse rate 1% semua tahun, 5 dst berlaku seterusnya */
INSERT INTO [reference].[asumsi_perhitungan_gpv_lapse_rate] (
    [asumsi_perhitungan_gpv_id],
    [tahun_ke],
    [is_berlaku_seterusnya],
    [lapse_rate],
    [created_at],
    [created_by],
    [keterangan]
)
VALUES
(@AsumsiId, 1, 0, 1.00, GETDATE(), 1, 'Tahun ke-1'),
(@AsumsiId, 2, 0, 1.00, GETDATE(), 1, 'Tahun ke-2'),
(@AsumsiId, 3, 0, 1.00, GETDATE(), 1, 'Tahun ke-3'),
(@AsumsiId, 4, 0, 1.00, GETDATE(), 1, 'Tahun ke-4'),
(@AsumsiId, 5, 1, 1.00, GETDATE(), 1, 'Tahun ke-5 dst');
GO
