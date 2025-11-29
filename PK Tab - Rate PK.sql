-- KOLOM DW

-- excel:start
=IF(DH14=0;(1+((30-DI14)/30))*HLOOKUP(O14;'C:\Laporan Cadangan\2023\Cadangan Bulan September 2023\Digunakan\GPV NON CAPTIVE\PK'' (Margin 10%)\[Pembiayaan Tetap Margin 10%.xlsx]GPV 36'!$CG$15:$EG$817;DH14+2;0);IF(DI14=0;HLOOKUP(O14;'C:\Laporan Cadangan\2023\Cadangan Bulan September 2023\Digunakan\GPV NON CAPTIVE\PK'' (Margin 10%)\[Pembiayaan Tetap Margin 10%.xlsx]GPV 36'!$CG$15:$EG$817;DH14+1;0);HLOOKUP(O14;'C:\Laporan Cadangan\2023\Cadangan Bulan September 2023\Digunakan\GPV NON CAPTIVE\PK'' (Margin 10%)\[Pembiayaan Tetap Margin 10%.xlsx]GPV 36'!$CG$15:$EG$817;DH14+1;0)-(DI14/30*(HLOOKUP(O14;'C:\Laporan Cadangan\2023\Cadangan Bulan September 2023\Digunakan\GPV NON CAPTIVE\PK'' (Margin 10%)\[Pembiayaan Tetap Margin 10%.xlsx]GPV 36'!$CG$15:$EG$817;DH14+1;0)-HLOOKUP(O14;'C:\Laporan Cadangan\2023\Cadangan Bulan September 2023\Digunakan\GPV NON CAPTIVE\PK'' (Margin 10%)\[Pembiayaan Tetap Margin 10%.xlsx]GPV 36'!$CG$15:$EG$817;DH14+2;0)))))
-- excel:end

= IF(
     DH14 = 0;
     (1 + ((30 - DI14) / 30)) *
     HLOOKUP(
             O14;
             'C:\Laporan Cadangan\2023\Cadangan Bulan September 2023\Digunakan\GPV NON CAPTIVE\PK'' (Margin 10%)\[Pembiayaan Tetap Margin 10%.xlsx]GPV 36'!$CG$15:$EG$817;
             DH14 + 2;
             0
     );
     IF(
        DI14 = 0;
        HLOOKUP(
                O14;
                'C:\Laporan Cadangan\2023\Cadangan Bulan September 2023\Digunakan\GPV NON CAPTIVE\PK'' (Margin 10%)\[Pembiayaan Tetap Margin 10%.xlsx]GPV 36'!$CG$15:$EG$817;
                DH14 + 1;
                0
        );
        HLOOKUP(
                O14;
                'C:\Laporan Cadangan\2023\Cadangan Bulan September 2023\Digunakan\GPV NON CAPTIVE\PK'' (Margin 10%)\[Pembiayaan Tetap Margin 10%.xlsx]GPV 36'!$CG$15:$EG$817;
                DH14 + 1;
                0
        ) - (DI14 / 30 * (
        HLOOKUP(
                O14;
                'C:\Laporan Cadangan\2023\Cadangan Bulan September 2023\Digunakan\GPV NON CAPTIVE\PK'' (Margin 10%)\[Pembiayaan Tetap Margin 10%.xlsx]GPV 36'!$CG$15:$EG$817;
                DH14 + 1;
                0
        ) -
        HLOOKUP(
                O14;
                'C:\Laporan Cadangan\2023\Cadangan Bulan September 2023\Digunakan\GPV NON CAPTIVE\PK'' (Margin 10%)\[Pembiayaan Tetap Margin 10%.xlsx]GPV 36'!$CG$15:$EG$817;
                DH14 + 2;
                0
        )))
     )
  )






=IF(A16=0;0;1-((1-VLOOKUP(C16;'[Asumsi Perhitungan GPV Margin 10%.xlsx]TMI.3'!$A$6:$H$117;8;0))^(1/12)))

= IF(
     A16 = 0;
     0;
     1 - ((1 -
     VLOOKUP(
             C16;
             '[Asumsi Perhitungan GPV Margin 10%.xlsx]TMI.3'!$A$6:$H$117;
             8;
             0
     )) ^ (1 / 12))
  )


A16 = bulanPolisKe_
B16 = tahunPolisKe_
C16 = usia
VLOOKUP(C16;'[Asumsi Perhitungan GPV Margin 10%.xlsx]TMI.3'!$A$6:$H$117;8;0 = 0,000726 = 


Hasil = IF(A16=0;0;1-((1-VLOOKUP(C16;'[Asumsi Perhitungan GPV Margin 10%.xlsx]TMI.3'!$A$6:$H$117;8;0))^(1/12)))





A16 = 1
B16 = 1
C16 = 30
VLOOKUP(C16;'[Asumsi Perhitungan GPV Margin 10%.xlsx]TMI.3'!$A$6:$H$117;8;0 = 0,000726


Hasil = IF(A16=0;0;1-((1-VLOOKUP(C16;'[Asumsi Perhitungan GPV Margin 10%.xlsx]TMI.3'!$A$6:$H$117;8;0))^(1/12))) 
Hasil = 0,00006052 atau 0,000061

D16 = IF(
     A16 = 0;
     0;
     1 - ((1 -
     VLOOKUP(
             C16;
             '[Asumsi Perhitungan GPV Margin 10%.xlsx]TMI.3'!$A$6:$H$117;
             8;
             0
     )) ^ (1 / 12))
  )


declare @mortalita varchar(50) = 'reas-unisex'

@bulanPolisKe_ = A16
@usia = C16
'[Asumsi Perhitungan GPV Margin 10%.xlsx]TMI.3'!$A$6:$H$117; = ( select trot, laki_laki, perempuan, unisex, reas_pria, reas_unisex, rate_yang_digunakan from #asumsi_perhitungan_gpv_margin_10 )

Asumsi!$F$14 = @mortalita
Asumsi!$D$16 = @faktorPengaliMortalita
A6 = select trot from #asumsi_perhitungan_gpv_margin_10
B6 = select Laki_laki from #asumsi_perhitungan_gpv_margin_10
C7 = select Perempuan from #asumsi_perhitungan_gpv_margin_10
D7 = select Unisex from #asumsi_perhitungan_gpv_margin_10
E7 = select Reas_Pria from #asumsi_perhitungan_gpv_margin_10
F7 = select Reas_Unisex from #asumsi_perhitungan_gpv_margin_10


= IF(
     Asumsi!$D$16 = 0;
     IF(
        Asumsi!$F$14 = "pria";
        B6;
        IF(
           Asumsi!$F$14 = "unisex";
           D6;
           IF(
              Asumsi!$F$14 = "reas - pria";
              E6;
              F6
           )
        )
     );
     IF(
        Asumsi!$F$14 = "pria";
        B6;
        IF(
           Asumsi!$F$14 = "unisex";
           D6;
           IF(
              Asumsi!$F$14 = "reas - pria";
              E6;
              F6
           )
        )
     ) * Asumsi!$D$16
  )