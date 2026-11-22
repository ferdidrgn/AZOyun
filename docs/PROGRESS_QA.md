# Progress QA kapsamı

Bu kayıt, `PROGRESS.md` içindeki geniş ve cihaz/hesap/üretim erişimi isteyen maddeleri yanlışlıkla tamamlandı olarak işaretlemeden, bu oturumda kodla doğrulanabilen on küçük adayı tanımlar. `PROGRESS.md` bilerek değiştirilmedi.

`node --test scripts/progress-qa.test.mjs` aşağıdaki on adayı denetler:

1. Ortak kural vektörlerinin on dosyada bulunması ve boş olmaması (`PROGRESS.md` 18–25).
2. Her sözleşmenin Flutter test eşinin bulunması (`PROGRESS.md` 18–25).
3. Her sözleşmenin Node test eşinin bulunması (`PROGRESS.md` 18–25).
4. Node sözleşme testlerinin yerleşik test koşucusu ve assertion kullanması (`PROGRESS.md` 18–25).
5. Dart ve Node katmanlarının aynı JSON vektörünü okuması (`PROGRESS.md` 18–25).
6. Web CI'ın bütün sözleşme testlerini çağırması (`PROGRESS.md` 29–30).
7. Web yayınlamanın test işine bağlı kalması (`PROGRESS.md` 80).
8. Android CI'ın AAB üretmeden önce Flutter testini çalıştırması (`PROGRESS.md` 70, 150).
9. Yayın kontrol belgesinin statik paket kontrolünü gerçek cihaz testinden ayırması (`PROGRESS.md` 46, 70, 134).
10. Android AAB statik denetleyicisinin hem mevcut hem de yayın belgesinde referanslı olması (`PROGRESS.md` 96, 134).

Bu kontroller fiziksel cihaz, Play Console, canlı Firebase, Flutter oda akışı veya web salonu davranışı kanıtı değildir. Bu nedenle ilgili geniş maddeler açık bırakılmalıdır.
