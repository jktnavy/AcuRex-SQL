USE [acurex_sql_db];
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'reference')
BEGIN
    EXEC('CREATE SCHEMA reference');
END
GO

-- MASTER
IF OBJECT_ID('reference.penurunan_risiko', 'U') IS NULL
BEGIN
    CREATE TABLE reference.penurunan_risiko (
        id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        informasi_penurunan_risiko VARCHAR(100) NOT NULL,

        created_at DATETIME NOT NULL CONSTRAINT DF_reference_penurunan_risiko_created_at DEFAULT (GETDATE()),
        updated_at DATETIME NULL,
        deleted_at DATETIME NULL,
        created_by BIGINT NOT NULL CONSTRAINT DF_reference_penurunan_risiko_created_by DEFAULT (1),
        keterangan VARCHAR(255) NULL
    );
END
GO

-- COLUMNS (dinamis dari header Excel)
IF OBJECT_ID('reference.penurunan_risiko_column', 'U') IS NULL
BEGIN
    CREATE TABLE reference.penurunan_risiko_column (
        id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        penurunan_risiko_id BIGINT NOT NULL,
        nama_kolom VARCHAR(100) NOT NULL,
        urutan INT NOT NULL,

        created_at DATETIME NOT NULL CONSTRAINT DF_reference_penurunan_risiko_column_created_at DEFAULT (GETDATE()),
        updated_at DATETIME NULL,
        deleted_at DATETIME NULL,
        created_by BIGINT NOT NULL CONSTRAINT DF_reference_penurunan_risiko_column_created_by DEFAULT (1),
        keterangan VARCHAR(255) NULL
    );

    ALTER TABLE reference.penurunan_risiko_column
      ADD CONSTRAINT FK_reference_penurunan_risiko_column_master
      FOREIGN KEY (penurunan_risiko_id) REFERENCES reference.penurunan_risiko(id);

    CREATE INDEX IX_reference_penurunan_risiko_column_master
      ON reference.penurunan_risiko_column(penurunan_risiko_id, urutan);
END
GO

-- RATES (nilai per trot x kolom)
IF OBJECT_ID('reference.penurunan_risiko_rate', 'U') IS NULL
BEGIN
    CREATE TABLE reference.penurunan_risiko_rate (
        id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        penurunan_risiko_id BIGINT NOT NULL,
        penurunan_risiko_column_id BIGINT NOT NULL,
        trot INT NOT NULL,
        nilai DECIMAL(18,8) NULL,

        created_at DATETIME NOT NULL CONSTRAINT DF_reference_penurunan_risiko_rate_created_at DEFAULT (GETDATE()),
        updated_at DATETIME NULL,
        deleted_at DATETIME NULL,
        created_by BIGINT NOT NULL CONSTRAINT DF_reference_penurunan_risiko_rate_created_by DEFAULT (1),
        keterangan VARCHAR(255) NULL
    );

    ALTER TABLE reference.penurunan_risiko_rate
      ADD CONSTRAINT FK_reference_penurunan_risiko_rate_master
      FOREIGN KEY (penurunan_risiko_id) REFERENCES reference.penurunan_risiko(id);

    ALTER TABLE reference.penurunan_risiko_rate
      ADD CONSTRAINT FK_reference_penurunan_risiko_rate_column
      FOREIGN KEY (penurunan_risiko_column_id) REFERENCES reference.penurunan_risiko_column(id);

    CREATE INDEX IX_reference_penurunan_risiko_rate_master_trot
      ON reference.penurunan_risiko_rate(penurunan_risiko_id, trot);

    CREATE INDEX IX_reference_penurunan_risiko_rate_master_column
      ON reference.penurunan_risiko_rate(penurunan_risiko_id, penurunan_risiko_column_id);
END
GO
