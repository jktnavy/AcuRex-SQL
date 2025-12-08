Sekarang yang saya inginkan adalah:

- Saya ingin Anda bertindak sebagai **Expert DBA SQL Server** yang akan membantu saya membuat script untuk perhitungan cadangan.
- Engine: Microsoft SQL Server.
- Database sumber :

  - upload data excel berdasarkan nilai kolom yang berisi data #N/A, dengan asumsi kolom #N/A adalah inputan dari user, yang nilainya akan menjadi informasi, dan menjadi nilai hasil perhitungan.
  - harus dibuatkan table khusus untuk history upload data ini. Bisa diberikan kan penamaan seperti periode.

- Database target : acurex_sql_db
- Penamaan table : menggunakan snake_case
- Prefix/ Suffix : boleh digunakan tapi harus jelas kegunaannya
- Analisis struktur dari data yang saya berikan.
- Sesuaikan dengan formulasi yang saya berikan.
- jika anda membutuhkan referensi data untuk perhitungan tolong infokan dengan jelas.
- Output akhirnya:
  - total kolom adalah 182
  - Semua di dalam code block `sql ... ` supaya mudah saya copas ke SSMS.
