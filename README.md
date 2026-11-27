# أطلس التراث الفلسطيني

**[جرّب الموقع مباشرة](https://palestine-heritage-atlas-main.wael2yasser3.chatgpt.site)** · **[اقرأ التقرير (PDF)](https://github.com/momenarman-max/Multi-Database-Design-for-a-Heritage-Tourism-Platform/blob/main/hosted-site/Heritage-Atlas-Report.pdf)** · **[اعرض الشرائح (PDF)](https://github.com/momenarman-max/Multi-Database-Design-for-a-Heritage-Tourism-Platform/blob/main/hosted-site/Heritage-Atlas-Presentation.pdf)**

**Multi-Database Design for a Heritage Tourism Platform**

منصة عرض محلية تربط مواقع تراثية فلسطينية بمرشدين وجولات وبيوت ضيافة. يمكن للمشغّل تسجيل زائر، طلب جولة أو إقامة، تأكيدها وإكمالها، إضافة تقييم وقراءة تحليلات الزيارة. تجمع صفحة الموقع بيانات PostgreSQL وMongoDB وNeo4j في استجابة واحدة وتستخدم Redis لتسريع الطلب التالي.

[شرائح العرض PDF](https://github.com/momenarman-max/Multi-Database-Design-for-a-Heritage-Tourism-Platform/blob/main/project/slides/heritage-atlas.pdf) · [سيناريو العرض](https://github.com/momenarman-max/Multi-Database-Design-for-a-Heritage-Tourism-Platform/blob/main/project/docs/demo.md) · [التصميم](https://github.com/momenarman-max/Multi-Database-Design-for-a-Heritage-Tourism-Platform/blob/main/project/docs/architecture.md) · [المستودع](https://github.com/momenarman-max/Multi-Database-Design-for-a-Heritage-Tourism-Platform)

## تشغيل واجهة الويب على جهاز جديد

نزّل المستودع وفك الضغط عنه، أو استنسخه باستخدام Git. إذا انقطع الاستنساخ برسالة `RPC failed` أو `early EOF` بسبب حجم الصور، أعد المحاولة بالخيار `--depth 1`.

```sh
git clone YOUR-FORK-URL atlas-team
cd atlas-team
```

ثبّت Docker مع Compose v2 الذي يدعم الخيار `--wait`، وشغّل Docker بحاويات Linux. تأكد أن `docker compose version` يعمل قبل المتابعة. افتح الطرفية في المجلد الذي يحتوي على `compose.yaml`.

1. أنشئ ملف الإعداد المحلي مرة واحدة. على Windows استخدم `Copy-Item .env.example .env` في PowerShell، وعلى Linux أو macOS استخدم `cp .env.example .env`.
2. نفّذ الأوامر التالية بالترتيب. يجهّز أمر `seed` المواقع والجولات والزائرة التجريبية نور.

```sh
docker compose build app web
docker compose up -d --wait postgres mongo graph redis
docker compose run --rm app seed
docker compose up -d --wait web
```

3. افتح [أطلس التراث على جهازك](http://127.0.0.1:8765) بنفس العنوان. لتشغيله مرة أخرى بعد إيقافه استخدم `docker compose up -d --wait web redis`. عند الانتهاء استخدم `docker compose down` للاحتفاظ بالحجوزات والتقييمات في وحدات التخزين.

### جرّب الحجز والتقييم

1. ابحث في **دليل الوجهات** حسب المدينة أو نوع التراث، ثم افتح موقعًا لقراءة وصفه والتعرّف إلى المرشدين والخدمات القريبة.
2. من البلدة القديمة في الخليل اختر **احجز الجولة** أو **احجز الإقامة**. أنشئ حساب زائر أو سجّل الدخول.
3. اختر تجربة فورية أو حدّد موعدًا مستقبليًا. للإقامة المجدولة حدّد الوصول والمغادرة.
4. في **حجوزاتي** تابع حالة الطلب. يمكنك إلغاؤه أو محاكاة تأكيد مقدم الخدمة. بعد حلول الموعد أو نهاية الإقامة اختر **تسجيل اكتمال الزيارة** ثم **قيّم الخدمة**.
5. افتح **إحصاءات السياحة** لمشاهدة الزيارات المكتملة ومواسم الذروة وتقييمات المرشدين والمواقع ونسبة رضا الزوار.

الواجهة مخصّصة للعرض المحلي. للاستعلام عن حالة الخدمات استخدم `docker compose ps`، ولتشخيص مشكلة تشغيل استخدم `docker compose logs --tail=50 web`. إذا ظهرت الصفحة دون جولات فتحقّق من نجاح أمر `seed`. عند تعارض المنفذ 8765 أغلق النسخة المحلية السابقة قبل بدء خادم آخر.

### شاهد أثر Redis

بعد `seed` مباشرة، وقبل فتح تفاصيل الموقع، اقرأ الموقع مرتين خلال 90 ثانية من النافذة نفسها. تظهر `cache_status` بقيمة miss ثم hit. السطر الأول يحفظ العربية سليمة عند تمرير الناتج في Windows PowerShell 5.1.
```powershell
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$site = docker compose run --rm app id site 1 | ConvertFrom-Json
docker compose run --rm app site $site
docker compose run --rm app site $site
docker compose run --rm app cache-info $site
```
لتجربة توقف Redis وحدها، أوقفها واقرأ الموقع ثم أعدها. تظهر bypass مع بيانات الموقع والمرشدين والمراجعات، ويبقى تصفّح الواجهة متاحًا. يتوقف الدخول والحجز حتى تعود لأن الجلسات محفوظة فيها، وقد يلزم تسجيل الدخول من جديد.
```powershell
docker compose stop redis
docker compose run --rm --no-deps app site $site
docker compose start redis
```
على التشغيل الأصلي أوقف العملية بأمر `redis-cli -p 56379 shutdown nosave`، ويعيدها أي أمر من `.\local.ps1`. لتشغيل استعلامات SQL المذكورة في دليل العرض استخدم `docker compose exec postgres psql -U atlas -d atlas`. النتائج المقاسة في [التصميم](https://github.com/momenarman-max/Multi-Database-Design-for-a-Heritage-Tourism-Platform/blob/main/project/docs/architecture.md).

في الواجهة يعرض قسم **كيف وصلتك هذه الصفحة؟** أسفل صفحة الموقع حالة الذاكرة وزمن كل قراءة، وزر لإعادة القراءة.

## التشغيل على الجهاز المجهّز
من PowerShell داخل المجلد الذي يحتوي README.md:
```powershell
.\local.ps1 audit
.\local.ps1 site 00000000-0000-0000-0000-0000001e8481
.\local.ps1 analytics
.\local.ps1 test
.\local.ps1 web
```
يشغّل local.ps1 الخدمات المحلية عند الحاجة ويستخدم بيانات العرض المهيأة. أدلة البرامج والبيانات خارج مجلد الرفع، في مجلد work الخاص بهذه الجلسة. إذا نقلت المشروع أو استنسخته في مجلد آخر، عيّن ATLAS_RUNTIME إلى المسار الكامل لذلك المجلد قبل أول أمر، مثل `$env:ATLAS_RUNTIME='C:\path\to\work'`. ظهور خطأ `Resolve-Path : Cannot find path` يعني أن المتغير غير معيّن. منفذ Neo4j Browser المحلي 57474 ومنفذ Bolt المحلي 57687.
يشغّل الأمر `web` واجهة الموقع على http://127.0.0.1:8765 عند توقفها. تُكتشف نسخة Java المحلية في مجلد `work/java` تلقائيًا لتشغيل Neo4j.

## اختبارات سطر الأوامر باستخدام Docker Compose
يتطلب Docker مع Compose v2 وحاويات Linux. من جذر المستودع:
```powershell
Copy-Item .env.example .env
docker compose build app
docker compose up -d --wait postgres mongo graph redis
docker compose run --rm app seed
docker compose run --rm app audit
docker compose run --rm app site 00000000-0000-0000-0000-0000001e8481
docker compose run --rm --entrypoint python app project/tests/integration.py
```
على Linux أو macOS استخدم `cp .env.example .env` في الخطوة الأولى. شغّل الاختبارات على قاعدة العرض المزروعة قبل إضافة زيارات يدوية، لأن بعضها يقارن أرقام العينة بنتائج محسوبة مسبقًا. أعد تنفيذ seed لإكمال تهيئة انقطعت؛ يحتفظ بالعمليات والتعديلات الموجودة. لإيقاف الحاويات مع حفظ البيانات استخدم `docker compose down`. يدخل Neo4j Browser من http://localhost:7474 باستخدام neo4j وكلمة GRAPH_PASSWORD المحلية. في نسخة Compose تُعرض منافذ الرسم على loopback فقط.

## تشغيل أصلي بديل
تستخدم التجربة Python 3.11 وPostgreSQL 16.6 وMongoDB 7.0.28 وNeo4j Community 5.26.0 وRedis. استخدم Redis 7.4 مع Compose. تم اختبار التشغيل الأصلي على Windows مع Redis 5.0.14.1. أنشئ قاعدة PostgreSQL فارغة، وثبّت المكتبات في بيئة افتراضية، ثم عرّف اتصالات الخدمات. أمثلة PowerShell لجهاز محلي ذي منافذ افتراضية:
```powershell
python -m venv .venv
.\.venv\Scripts\python -m pip install -r requirements.txt
$env:PGHOST='localhost'
$env:PGDATABASE='atlas'
$env:PGUSER='atlas'
$env:PGPASSWORD=Read-Host 'Local PostgreSQL password'
$env:MONGO_URI='mongodb://localhost:27017'
$env:GRAPH_URI='bolt://localhost:7687'
$env:GRAPH_PASSWORD=Read-Host 'Local Neo4j password'
$env:REDIS_URL='redis://localhost:6379/0'
$env:PYTHONUTF8='1'
.\.venv\Scripts\python project/app/atlas.py seed
.\.venv\Scripts\python project/app/atlas.py --help
.\.venv\Scripts\python project/web/server.py
```

## جولة سريعة
كل سطر أدناه أمر بعد `docker compose run --rm app` أو `.\local.ps1`. يعيد request-booking معرّف الحجز. في أوامر المثال اللاحقة استبدل BOOKING_ID بتلك القيمة دون علامات الاقتباس.
```text
site 00000000-0000-0000-0000-0000001e8481
listing 00000000-0000-0000-0000-0000001e8481
request-booking 00000000-0000-0000-0000-0000005b8d81 tours 00000000-0000-0000-0000-0000004c4b41
confirm-booking BOOKING_ID
complete-booking BOOKING_ID
add-review BOOKING_ID 5 "أعجبني شرح المرشدة لتفاصيل السوق"
booking BOOKING_ID
analytics
```
عند حذف الموعد من الطلب يُحجز موعد فوري مناسب للعرض. لحجز مستقبلي استخدم ‎`--at 2027-05-18T10:00:00+03:00`. يمكن إلغاء الحجز المطلوب أو المؤكد بـcancel-booking. لإقامة استخدم guesthouses ومعرّف بيت الضيافة. لتفاصيل سجل العرض واختبارات الفشل راجع [دليل العرض](https://github.com/momenarman-max/Multi-Database-Design-for-a-Heritage-Tourism-Platform/blob/main/project/docs/demo.md).

## دليل الملفات
| المسار | المحتوى |
|---|---|
| project/web | واجهة عربية للحجز والتقييم وخادم HTTP يتصل بطبقة التطبيق |
| project/app | واجهة سطر الأوامر، خدمة الحجز والصفحة، بيانات العينة، التحقق من المراجع |
| project/db | SQL وCypher وMongoDB وLua وأمثلة CRUD |
| project/tests | اختبارات تكامل على خدمات فعلية |
| project/docs | [المتطلبات](https://github.com/momenarman-max/Multi-Database-Design-for-a-Heritage-Tourism-Platform/blob/main/project/docs/requirements.md)، [نموذج البيانات](https://github.com/momenarman-max/Multi-Database-Design-for-a-Heritage-Tourism-Platform/blob/main/project/docs/data-model.md)، [القرارات والمقايضات](https://github.com/momenarman-max/Multi-Database-Design-for-a-Heritage-Tourism-Platform/blob/main/project/docs/decisions.md)، [معرفات العينة](https://github.com/momenarman-max/Multi-Database-Design-for-a-Heritage-Tourism-Platform/blob/main/project/docs/sample-ids.md) |
| project/slides | عرض PDF والنسخة القابلة للتعديل والطباعة |
| CONTRIBUTIONS.md | خطة العرض وسجل المساهمات الفعلية |

النموذج مخصص لعرض محلي ببيانات مصطنعة. إصدارات الأدوات مثبتة لتكرار التجربة. تحتفظ PostgreSQL بالحجوزات والتقييمات وبصمات كلمات المرور المملّحة، وتحفظ Redis جلسات تسجيل الدخول لمدة ساعتين.

## معرض الصور
يعرض الموقع معرضًا تحريريًا غير متماثل من بيانات المواقع الحالية، مع بحث وتصفية حسب المدينة والتراث. يتغيّر مشهد المدن مع التمرير على الشاشات الكبيرة، وتظهر المدن عموديًا على الهاتف. الصور والخطوط محفوظة محليًا؛ لا تُستخدم صور مولدة لتمثيل مواقع حقيقية. يدعم زر اللغة العربية وRTL والإنجليزية، وتحترم الحركات إعداد تقليل الحركة. تفاصيل الهوية واختبارات الواجهة في [دليل تصميم الواجهة](https://github.com/momenarman-max/Multi-Database-Design-for-a-Heritage-Tourism-Platform/blob/main/project/docs/frontend-design.md).

- [الحرم الإبراهيمي في الخليل](https://commons.wikimedia.org/wiki/File:Hebron_Cave_of_the_Patriarchs.jpg) — Djampa، [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
- [كنيسة المهد في بيت لحم](https://commons.wikimedia.org/wiki/File:Church_of_the_Nativity_(7703592746).jpg) — Neil Ward، [CC BY 2.0](https://creativecommons.org/licenses/by/2.0/).
- [مئذنة الجامع الكبير في نابلس](https://commons.wikimedia.org/wiki/File:Nablus_Great_Mosque.jpg) — K. A. C. Creswell، ملكية عامة.
- [دير مار سابا](https://commons.wikimedia.org/wiki/File:Palestine-2013-Aerial-Mar_Saba_Monastery.jpg) — Godot13، [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
- [Hebron market old city.jpg](https://commons.wikimedia.org/wiki/File:Hebron_market_old_city.jpg) — Makbula Nassar، CC BY-SA 4.0 https://creativecommons.org/licenses/by-sa/4.0
- [Interior of peasant home at Beit Sahur LOC matpc.04150.jpg](https://commons.wikimedia.org/wiki/File:Interior_of_peasant_home_at_Beit_Sahur_LOC_matpc.04150.jpg) — Matson Collection، Public domain 
- [Manger Square.jpg](https://commons.wikimedia.org/wiki/File:Manger_Square.jpg) — Alexey Goral، CC BY-SA 4.0 https://creativecommons.org/licenses/by-sa/4.0
- [Nablus old city 24.jpg](https://commons.wikimedia.org/wiki/File:Nablus_old_city_24.jpg) — Mohammad Hijjawi، CC BY-SA 4.0 https://creativecommons.org/licenses/by-sa/4.0
- [Nablus old city 25.jpg](https://commons.wikimedia.org/wiki/File:Nablus_old_city_25.jpg) — Mohammad Hijjawi، CC BY-SA 4.0 https://creativecommons.org/licenses/by-sa/4.0
- [Traces of the Western Purity Pool discovered at Tel Rumeida in the city of Hebron.jpg](https://commons.wikimedia.org/wiki/File:Traces_of_the_Western_Purity_Pool_discovered_at_Tel_Rumeida_in_the_city_of_Hebron.jpg) — MohmmadRjab، CC BY-SA 4.0 https://creativecommons.org/licenses/by-sa/4.0
- [View of star street.JPG](https://commons.wikimedia.org/wiki/File:View_of_star_street.JPG) — Tiamat، CC BY-SA 3.0 https://creativecommons.org/licenses/by-sa/3.0
- [حارة العقابة في الخليل التاريخية.jpg](https://commons.wikimedia.org/wiki/File:%D8%AD%D8%A7%D8%B1%D8%A9_%D8%A7%D9%84%D8%B9%D9%82%D8%A7%D8%A8%D8%A9_%D9%81%D9%8A_%D8%A7%D9%84%D8%AE%D9%84%D9%8A%D9%84_%D8%A7%D9%84%D8%AA%D8%A7%D8%B1%D9%8A%D8%AE%D9%8A%D8%A9.jpg) — Madosophy Ahmad، CC BY-SA 4.0 https://creativecommons.org/licenses/by-sa/4.0
- [Hebron glass display](https://commons.wikimedia.org/wiki/File:Hebron_glass_display.jpg) — FlightlessTofu، [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).
