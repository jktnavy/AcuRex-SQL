USE [acurex_sql_db];
GO

DECLARE @now DATETIME = GETDATE();
DECLARE @created_by BIGINT = 1;

INSERT INTO [reference].[tmis] ([informasi_tmi],[keterangan],[created_at],[updated_at],[deleted_at],[created_by])
VALUES (N'TMI 3', 'Seed header (rates diisi via Import Excel)', @now, NULL, NULL, @created_by);

DECLARE @tmi_id BIGINT = SCOPE_IDENTITY();

INSERT INTO [reference].[tmi_columns]
([tmi_id],[column_label],[column_key],[sort_order],[keterangan],[created_at],[updated_at],[deleted_at],[created_by])
VALUES
(@tmi_id, N'Laki-laki ( TMI 3 )', N'laki_laki_tmi_3', 1, NULL, @now, NULL, NULL, @created_by),
(@tmi_id, N'Perempuan ( TMI 3 )', N'perempuan_tmi_3', 2, NULL, @now, NULL, NULL, @created_by),
(@tmi_id, N'Unisex',              N'unisex',          3, NULL, @now, NULL, NULL, @created_by),
(@tmi_id, N'Reas - Pria',         N'reas_pria',       4, NULL, @now, NULL, NULL, @created_by),
(@tmi_id, N'Reas - Unisex',       N'reas_unisex',     5, NULL, @now, NULL, NULL, @created_by),
(@tmi_id, N'Dipakai',             N'dipakai',         6, NULL, @now, NULL, NULL, @created_by);
GO
