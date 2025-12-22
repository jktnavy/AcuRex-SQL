USE [acurex_sql_db];
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'reference')
BEGIN
    EXEC('CREATE SCHEMA [reference]');
END
GO

-- =========================
-- Table: reference.tmis (header / informasi)
-- =========================
IF OBJECT_ID('[reference].[tmis]', 'U') IS NULL
BEGIN
    CREATE TABLE [reference].[tmis] (
        [id] BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [informasi_tmi] NVARCHAR(100) NOT NULL,     -- contoh: "TMI 3", "3-2025", "3-2026"
        [keterangan] VARCHAR(255) NULL,

        [created_at] DATETIME NOT NULL,
        [updated_at] DATETIME NULL,
        [deleted_at] DATETIME NULL,
        [created_by] BIGINT NOT NULL
    );

    CREATE INDEX IX_reference_tmis_deleted_at ON [reference].[tmis]([deleted_at]);
    CREATE INDEX IX_reference_tmis_informasi ON [reference].[tmis]([informasi_tmi]);
END
GO

-- =========================
-- Table: reference.tmi_columns (dynamic columns dari excel)
-- =========================
IF OBJECT_ID('[reference].[tmi_columns]', 'U') IS NULL
BEGIN
    CREATE TABLE [reference].[tmi_columns] (
        [id] BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [tmi_id] BIGINT NOT NULL,
        [column_label] NVARCHAR(255) NOT NULL,      -- persis header excel (dinamis)
        [column_key] NVARCHAR(255) NOT NULL,        -- versi aman (slug) untuk query/pivot
        [sort_order] INT NOT NULL DEFAULT(0),

        [keterangan] VARCHAR(255) NULL,
        [created_at] DATETIME NOT NULL,
        [updated_at] DATETIME NULL,
        [deleted_at] DATETIME NULL,
        [created_by] BIGINT NOT NULL,

        CONSTRAINT FK_reference_tmi_columns_tmi
            FOREIGN KEY ([tmi_id]) REFERENCES [reference].[tmis]([id])
    );

    CREATE UNIQUE INDEX UX_reference_tmi_columns_tmi_key
        ON [reference].[tmi_columns]([tmi_id], [column_key])
        WHERE [deleted_at] IS NULL;

    CREATE INDEX IX_reference_tmi_columns_tmi_id ON [reference].[tmi_columns]([tmi_id]);
END
GO

-- =========================
-- Table: reference.tmi_rates (dynamic trot & value)
-- =========================
IF OBJECT_ID('[reference].[tmi_rates]', 'U') IS NULL
BEGIN
    CREATE TABLE [reference].[tmi_rates] (
        [id] BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [tmi_id] BIGINT NOT NULL,
        [trot] INT NOT NULL,                        -- dinamis: bisa 0..111 atau berapa pun
        [tmi_column_id] BIGINT NOT NULL,
        [rate] DECIMAL(18, 6) NULL,

        [keterangan] VARCHAR(255) NULL,
        [created_at] DATETIME NOT NULL,
        [updated_at] DATETIME NULL,
        [deleted_at] DATETIME NULL,
        [created_by] BIGINT NOT NULL,

        CONSTRAINT FK_reference_tmi_rates_tmi
            FOREIGN KEY ([tmi_id]) REFERENCES [reference].[tmis]([id]),

        CONSTRAINT FK_reference_tmi_rates_column
            FOREIGN KEY ([tmi_column_id]) REFERENCES [reference].[tmi_columns]([id])
    );

    CREATE UNIQUE INDEX UX_reference_tmi_rates_unique
        ON [reference].[tmi_rates]([tmi_id], [trot], [tmi_column_id])
        WHERE [deleted_at] IS NULL;

    CREATE INDEX IX_reference_tmi_rates_tmi_trot
        ON [reference].[tmi_rates]([tmi_id], [trot]);
END
GO
