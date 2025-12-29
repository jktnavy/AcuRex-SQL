USE [acurex_sql_db];
GO

-- Schema
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'reference')
BEGIN
    EXEC('CREATE SCHEMA reference');
END
GO

/* =========================
   MASTER
========================= */
IF OBJECT_ID('reference.penurunan_risiko_tetap', 'U') IS NULL
BEGIN
    CREATE TABLE reference.penurunan_risiko_tetap (
        id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        informasi_penurunan_risiko_tetap VARCHAR(150) NOT NULL,

        -- standar wajib
        created_at DATETIME NOT NULL,
        updated_at DATETIME NULL,
        deleted_at DATETIME NULL,
        created_by BIGINT NOT NULL,
        keterangan VARCHAR(255) NULL
    );
END
GO

/* =========================
   COLUMNS (dinamis)
========================= */
IF OBJECT_ID('reference.penurunan_risiko_tetap_columns', 'U') IS NULL
BEGIN
    CREATE TABLE reference.penurunan_risiko_tetap_columns (
        id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        penurunan_risiko_tetap_id BIGINT NOT NULL,
        name VARCHAR(128) NOT NULL,
        position INT NOT NULL,

        -- standar wajib
        created_at DATETIME NOT NULL,
        updated_at DATETIME NULL,
        deleted_at DATETIME NULL,
        created_by BIGINT NOT NULL,
        keterangan VARCHAR(255) NULL,

        CONSTRAINT FK_prt_columns_master
            FOREIGN KEY (penurunan_risiko_tetap_id)
            REFERENCES reference.penurunan_risiko_tetap(id)
    );
END
GO

-- unique per master (filtered, ignore soft-deleted rows)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'UX_prt_columns_master_name_active'
      AND object_id = OBJECT_ID('reference.penurunan_risiko_tetap_columns')
)
BEGIN
    EXEC('CREATE UNIQUE INDEX UX_prt_columns_master_name_active
          ON reference.penurunan_risiko_tetap_columns(penurunan_risiko_tetap_id, name)
          WHERE deleted_at IS NULL');
END
GO

/* =========================
   RATES (per sel)
========================= */
IF OBJECT_ID('reference.penurunan_risiko_tetap_rates', 'U') IS NULL
BEGIN
    CREATE TABLE reference.penurunan_risiko_tetap_rates (
        id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        penurunan_risiko_tetap_id BIGINT NOT NULL,
        trot INT NOT NULL,
        column_id BIGINT NOT NULL,
        nilai DECIMAL(18,6) NOT NULL,

        -- standar wajib
        created_at DATETIME NOT NULL,
        updated_at DATETIME NULL,
        deleted_at DATETIME NULL,
        created_by BIGINT NOT NULL,
        keterangan VARCHAR(255) NULL,

        CONSTRAINT FK_prt_rates_master
            FOREIGN KEY (penurunan_risiko_tetap_id)
            REFERENCES reference.penurunan_risiko_tetap(id),

        CONSTRAINT FK_prt_rates_column
            FOREIGN KEY (column_id)
            REFERENCES reference.penurunan_risiko_tetap_columns(id)
    );
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'UX_prt_rates_unique_active'
      AND object_id = OBJECT_ID('reference.penurunan_risiko_tetap_rates')
)
BEGIN
    EXEC('CREATE UNIQUE INDEX UX_prt_rates_unique_active
          ON reference.penurunan_risiko_tetap_rates(penurunan_risiko_tetap_id, trot, column_id)
          WHERE deleted_at IS NULL');
END
GO

/* =========================
   SEEDER CONTOH DATA (SSMS)
========================= */
DECLARE @now DATETIME = GETDATE();
DECLARE @createdBy BIGINT = 1;

-- master
IF NOT EXISTS (SELECT 1 FROM reference.penurunan_risiko_tetap WHERE informasi_penurunan_risiko_tetap = '3-2025')
BEGIN
    INSERT INTO reference.penurunan_risiko_tetap
    (informasi_penurunan_risiko_tetap, created_at, updated_at, deleted_at, created_by, keterangan)
    VALUES
    ('3-2025', @now, NULL, NULL, @createdBy, 'Contoh seed');
END

DECLARE @masterId BIGINT = (
    SELECT TOP 1 id FROM reference.penurunan_risiko_tetap
    WHERE informasi_penurunan_risiko_tetap = '3-2025' AND deleted_at IS NULL
);

-- columns: 1..5 contoh
IF NOT EXISTS (SELECT 1 FROM reference.penurunan_risiko_tetap_columns WHERE penurunan_risiko_tetap_id = @masterId AND name='1' AND deleted_at IS NULL)
BEGIN
    INSERT INTO reference.penurunan_risiko_tetap_columns
    (penurunan_risiko_tetap_id, name, position, created_at, updated_at, deleted_at, created_by, keterangan)
    VALUES
    (@masterId, '1', 1, @now, NULL, NULL, @createdBy, NULL),
    (@masterId, '2', 2, @now, NULL, NULL, @createdBy, NULL),
    (@masterId, '3', 3, @now, NULL, NULL, @createdBy, NULL),
    (@masterId, '4', 4, @now, NULL, NULL, @createdBy, NULL),
    (@masterId, '5', 5, @now, NULL, NULL, @createdBy, NULL);
END

-- rates contoh trot 0..2 untuk 1..5
;WITH cols AS (
    SELECT id, name, position
    FROM reference.penurunan_risiko_tetap_columns
    WHERE penurunan_risiko_tetap_id = @masterId AND deleted_at IS NULL
)
INSERT INTO reference.penurunan_risiko_tetap_rates
(penurunan_risiko_tetap_id, trot, column_id, nilai, created_at, updated_at, deleted_at, created_by, keterangan)
SELECT
    @masterId,
    t.trot,
    c.id,
    CAST(1000.0 - (t.trot * 2.5) - ((c.position-1) * 3.0) AS DECIMAL(18,6)) AS nilai,
    @now, NULL, NULL, @createdBy, NULL
FROM (VALUES (0),(1),(2)) t(trot)
CROSS JOIN cols c
WHERE NOT EXISTS (
    SELECT 1
    FROM reference.penurunan_risiko_tetap_rates r
    WHERE r.penurunan_risiko_tetap_id=@masterId AND r.trot=t.trot AND r.column_id=c.id AND r.deleted_at IS NULL
);
GO
