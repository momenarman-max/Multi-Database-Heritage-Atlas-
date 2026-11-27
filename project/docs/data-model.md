# نموذج البيانات والفهارس
| المصدر | الكيان والمفاتيح | الحقول التي تخدم الطلب |
|---|---|---|
| SQL | visitors.id UUID وemail فريد | name نص، interests وlanguages مصفوفتان نصيتان |
| SQL | bookings.id وvisitor_id | offering_id/type، site_id وguide_id، status، وثلاثة أختام زمنية |
| SQL | visit_events.id وbooking_id فريد | site_id، visited_at، projected |
| SQL | reviews.id وbooking_id فريد | site_id، guide_id اختياري، rating، body، created_at |
| MongoDB | sites._id نص UUID، city_id | name_ar وdescription_ar وopening_info نصوص؛ tags وlanguages مصفوفتان وphoto_metadata مصفوفة أوصاف |
| MongoDB | guides وguesthouses | اللغات والخدمات، أو الموقع والغرف والمرافق؛ اسم ووصف وبيانات صور |
| MongoDB | tours._id وguide_id | site_ids مصفوفة، price_ils عدد، languages |
| Neo4j | Site، City، Guide، Provider، Visitor | id فريد لكل نوع؛ name، وinterests على Visitor لتقاطع الاهتمامات |
| Redis | جلسة وصفحة وقائمة | تفاصيل القيم ومدد الصلاحية في db/redis/keys.md |

**اتجاه العلاقات.** Site → LOCATED_IN → City، وGuide → COVERS → Site، وProvider → PROVIDES → Site لاستضافة الزوار قرب الموقع، وVisitor → VISITED → Site مع آخر وقت زيارة. تُقرأ NEAR في الاتجاهين. القرب داخل العينة اقتران اختاره مصمم المسار، دون افتراض مسافة جغرافية دقيقة.

**مسارات الفهرسة.** يخدم (site_id,visited_at) تعداد الزيارات أو ترتيب آخر الزيارات داخل موقع. يخدم reviews(site_id) قراءة التقييمات. يفيد bookings(visitor_id,status) تتبع حجوزات زائر، وservice_at قائمة مواعيد الفترة. في MongoDB يخدم (city_id,tags) مرحلة المطابقة، وتفحص اللغة بعد تضييق النتائج، ويخدم tours.site_ids الربط بصفحة الموقع. تبحث قائمة الإقامات بـguesthouses.site_id والمرشدون بحسب languages. يوفر قيد تفرد معرّف كل عقدة نقطة الدخول إلى المسار من دون مسح الرسم.

**قراءة EXPLAIN.** في تشغيل العينة استخدم PostgreSQL ‏Bitmap Index Scan على visits_site_time ثم قرأ كتلة الجدول ورتب ثلاث زيارات. العينة صغيرة ويستطيع المخطّط اختيار مسح تسلسلي بعد ANALYZE أو تغير الإحصاءات. لم نقسّن زمنًا إنتاجيًا من هذه النتيجة.

## تجربة البحث عن عمارة الخليل بالعربية

في 27 نوفمبر 2026 شغّلنا الاستعلام التالي في `mongosh` على قاعدة العيّنة المحلية `heritage`. يختار المواقع بحسب المدينة والوسم واللغة، ثم يعدّ الجولات التي يشير حقل `site_ids` فيها إلى كل موقع.

لتجربة الاستعلام من الصفر، نزّل [نسخة المشروع التي تحتوي على ملفات التشغيل](https://github.com/momenarman-max/Multi-Database-Design-for-a-Heritage-Tourism-Platform/tree/8451d4502dcd27b4d978746b1c966f2134223ff1)، واتّبع [خطوات تجهيز بيانات العيّنة](../../README.md#تشغيل-واجهة-الويب-على-جهاز-جديد) من مجلد `compose.yaml` حتى ينجح أمر `docker compose run --rm app seed`. افتح جلسة MongoDB بالأمر `docker compose exec mongo mongosh heritage` ثم شغّل الاستعلام التالي.

```javascript
const atlas = db.getSiblingDB("heritage");
const pipeline = [
  {$match: {city_id: "00000000-0000-0000-0000-0000000f4241", tags: "عمارة", languages: "ar"}},
  {$lookup: {from: "tours", localField: "_id", foreignField: "site_ids", as: "offers"}},
  {$project: {name_ar: 1, tours: {$size: "$offers"}}},
  {$sort: {tours: -1, _id: 1}}
];
printjson(atlas.sites.aggregate(pipeline).toArray());
printjson(atlas.sites.explain("executionStats").aggregate(pipeline).stages);
```

| الموقع | المعرّف | عدد الجولات |
|---|---|---:|
| البلدة القديمة في الخليل | `00000000-0000-0000-0000-0000001e8481` | 2 |
| حارة العقابة | `00000000-0000-0000-0000-0000001e8483` | 0 |

أظهرت خطة التنفيذ أن `IXSCAN` استخدم الفهرس المركّب `city_id_1_tags_1` وفحص مفتاحين. قرأت مرحلة `FETCH` وثيقتَي موقع للتحقق من اللغة وأعادت الموقعين. وفي مرحلة `$lookup` استُخدم فهرس `site_ids_1` وفُحصت وثيقتا جولة، مع `collectionScans: 0`. بقيت حارة العقابة في النتيجة لأن شروط البحث تنطبق عليها وعدد الجولات المطابقة لها صفر.
